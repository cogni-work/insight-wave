---
name: research-report
description: |
  Generate a multi-agent research report using parallel web research with structural
  review. Three modes: basic (fast single-pass), detailed (multi-section with outline),
  deep (recursive tree exploration). Claims verification runs separately via verify-report.
  Supports configurable writing tones, auto/manual researcher roles, source URL pre-fetch,
  domain-restricted search, custom sub-question counts, and local document research.
  Four source modes: web (default), local (analyze user's documents), wiki (query cogni-wiki instances), hybrid (web + documents + wikis).
  Use when the user asks to "research report", "investigate", "deep research", "write a report",
  "gpt-researcher", "multi-agent research", "analyze these documents", "research from my files",
  "research from my wiki", "use my wiki for research", "query the wiki",
  or requests comprehensive topic analysis with citations.
  Also use when the user wants to "resume research", "continue research report", "pick up the research",
  "finish the report", "what happened to my report", or resume an interrupted research run.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, Task, Skill, AskUserQuestion
---

# Research Report Skill

When this skill loads:
1. If no topic was provided → ask: "What topic should I research?" — then STOP and wait for the user's answer
2. Once topic is known (either from the original prompt or from the user's answer to step 1):
   - Extract any options already stated (report type, tone, citations, source mode, market, etc.)
   - **ALWAYS present the full Configuration Menu** (Phase 0 Step 2) using AskUserQuestion — even if no options were detected, even if most will be defaults. The menu IS the skill's core UX; skipping it is a bug.
   - The ONLY exception: the user explicitly said "just go", "defaults are fine", "start now", or specified ALL of type + tone + citations + source mode in their prompt.
3. Never greet, re-explain capabilities, or auto-confirm defaults without showing the menu first

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

**Skill presents**:
> **Research Configuration**
> Topic: "quantum computing's impact on cryptography"
> Detected: type = basic
>
> **Depth** (research scope):
> `basic` = 3-5K words, 5 sub-questions — standard report
> `detailed` = 5-10K words, up to 10 sub-questions — comprehensive
> `deep` = 8-15K words, recursive tree — maximum depth
> `outline` = structured framework only (no prose)
> `resource` = annotated source list / bibliography
>
> **Tone**: objective *(default)* | analytical | critical | persuasive | formal | informative | explanatory | descriptive | comparative | speculative | narrative | optimistic | simple
> **Citations**: APA *(default)* | MLA | Chicago | Harvard | IEEE | Wikilink
> **Market**: global *(default)* | dach | de | us | uk | fr (localizes search queries + authority sources)
> **Sources** (where to research):
> `web` *(default)* = search the internet
> `local` = analyze your documents (PDF, DOCX, MD, CSV, ...)
> `wiki` = query your cogni-wiki knowledge bases
> `hybrid` = combine web + documents + wiki
> Advanced: output language, sub-question count, domain filter, researcher role, diagram generation — ask about any of these
>
> Reply with your choices, or "go" for defaults.

**User**: "detailed, analytical" *(or just "go")*

**Result**: A 5000-10000 word report with inline citations, produced via:
1. Topic decomposition into sub-questions
2. Parallel web research (sonnet agents, one per sub-question)
3. Context aggregation and source deduplication
4. Report compilation (sonnet writer agent)
5. Structural review and polish
6. Final report at `output/report.md`

Then run `/verify-report` to verify claims against cited sources in a fresh context window.

## Prerequisites

- Active workspace directory for project output
- cogni-claims plugin installed (for claims-verified review loop)

## Report Types

| Type | Trigger | Sub-Questions | Words | Use Case |
|------|---------|--------------|-------|----------|
| **basic** | "research report on X" | 5 | 3000-5000 | Standard research report |
| **detailed** | "detailed research report on X" | 5-10 | 5000-10000 | Comprehensive analysis |
| **deep** | "deep research on X" | 10-20 (tree) | 8000-15000 | Maximum depth + breadth |
| **outline** | "outline on X" | 5 | 1000-2000 | Structured framework, no prose |
| **resource** | "sources on X", "reading list" | 5 | 1500-3000 | Annotated bibliography |

Default: **basic** unless user specifies otherwise.

## References Index

Read these reference files when the corresponding phase needs them:

| Reference | Read When |
|-----------|-----------|
| `references/report-types.md` | Phase 1 — choosing report type and planning |
| `references/sub-question-generation.md` | Phase 1 — decomposing user query |
| `references/deep-research-tree.md` | Phase 1 (deep mode) — building research tree |
| `references/agent-roles.md` | Phase 1 — auto-selecting researcher role |
| `references/writing-tones.md` | Phase 0 — resolving tone parameter |
| `references/citation-formats.md` | Phase 0 — resolving citation format |
| `references/review-criteria.md` | Phase 5 — understanding review scoring |

## Workflow

### Phase 0: Project Initialization

A well-structured project directory is the foundation for resumability and cross-agent coordination. Without it, agents cannot find each other's outputs, the review loop cannot track iterations, and a crash mid-research loses all progress.

#### Step 1: Extract options from user's prompt

Scan the user's request and extract any options they already specified. These become "detected" settings that won't be re-asked in the configuration menu.

- **Report type**: keywords like "detailed", "deep research", "outline", "sources" → map to basic/detailed/deep/outline/resource (see `references/report-types.md`)
- **Tone**: style keywords like "analytical", "persuasive", "formal" → map to tone from `references/writing-tones.md`. Default: "objective"
- **Citation format**: "IEEE", "APA format", "Chicago style", "wikilink", "superscript citations" → capture. Default: "apa". See `references/citation-formats.md`
- **Market**: "French market", "DACH", "for Germany", "für Deutschland", "US market", "UK market" → map to region code (fr, dach, de, us, uk). Default: "global"
- **Output language**: "in German", "auf Deutsch" → "de" (+ market=dach if no explicit market). "in French", "en français" → "fr" (+ market=fr). Default: auto (derived from market)
- **Language** (legacy): "in German" → market=dach, output_language=de. Default: "en"
- **Source URLs**: any URLs in the prompt → collect for pre-fetch
- **Query domains**: "only .gov sources", "restrict to arxiv" → collect domains
- **Max subtopics**: "use 8 sub-questions", "12 dimensions" → capture count
- **Report source**: "analyze these PDFs", "research from my files" → "local"; "use my wiki", "query the wiki", "from my wiki" → "wiki"; combinations like "wiki and web" → "hybrid". Default: "web"
- **Document paths**: file paths or glob patterns for local/hybrid mode
- **Wiki paths**: paths to cogni-wiki roots (e.g., `~/cogni-wikis/my-wiki`) → collect for wiki_paths. Triggered by wiki directory paths or mentions of "wiki", "knowledge base"
- **Curate sources**: "prioritize authoritative sources" → enable
- **Project location**: "save in standard folder", "store here", "put it in ~/research" → capture. Default: ask in Step 2b (no silent default)

#### Step 2: Interactive Configuration

Present the user with a configuration menu using `AskUserQuestion` so they can see what options exist and choose before research starts. This is the heart of Phase 0 — it makes the skill's capabilities discoverable rather than hidden behind keyword detection.

**Assemble the menu dynamically:**

1. Show the detected topic
2. List any options already extracted from the prompt (e.g., "Detected: type = deep, citations = IEEE")
3. For **unset primary options**, show the compact chooser:
   - **Depth** (only if report type not yet detected): list all 5 types with word counts and one-line descriptions
   - **Tone** (only if not detected): list all 13 options, mark default
   - **Citations** (only if not detected): list all 5 formats, mark default
   - **Market** (only if not detected): global | dach | de | us | uk | fr
   - **Sources** (only if report_source not detected): show all 4 modes with one-line descriptions:
     - `web` *(default)* = search the internet
     - `local` = analyze your documents (PDF, DOCX, MD, CSV, ...)
     - `wiki` = query your cogni-wiki knowledge bases
     - `hybrid` = combine web + documents + wiki
4. Always include one line for advanced options: "Advanced: output language, sub-question count, domain filter, researcher role, diagram generation — ask about any of these"
5. End with: `Reply with your choices, or "go" for defaults.`

**Default behavior is to SHOW the menu.** The conditional skip below is the exception, not the rule. If in doubt, show the menu. A user who only provided a topic — even with a market like "DACH" or a depth like "deep" — has NOT specified all options.

**Conditional skip** (strict): Skip the interactive menu ONLY when one of these is true:
1. The user's **original prompt** (not a follow-up topic answer) explicitly specified ALL FOUR primary options: type + tone + citations + source mode
2. The user used an explicit urgency signal: "just go", "start now", "defaults are fine", "use defaults"

If neither condition is met, present the full menu. Collapse to a compact confirmation only when one of the above holds:
> "Starting **detailed** research on X — analytical tone, IEEE citations, English. Change anything? (or 'go')"

**Handling user responses:**
- "go" / "defaults" / "start" → accept detected + default values for research config
- Specific choices ("deep, analytical, IEEE") → merge with detected values
- Question about an advanced option ("what roles are available?") → read the relevant reference file (`references/agent-roles.md`, `references/writing-tones.md`, etc.), explain the option, then re-present the menu
- Partial choices ("make it detailed") → update that option, ask if anything else or proceed

After accepting configuration (first, second, or fourth branch above): if the resolved `report_source` is `local`, `wiki`, or `hybrid`, run the **Source mode follow-up** below before proceeding to Step 2b. If `report_source` is `web` (or defaulted to web), skip the follow-up and go directly to Step 2b.

**Source mode follow-up**: When the user selects `local`, `wiki`, or `hybrid` as their source mode (either in this menu or detected from the original prompt), ask the necessary follow-up questions before proceeding to Step 2b:

- **`local`**: "Which documents should I analyze? Provide file paths or glob patterns (e.g., `~/docs/*.pdf`, `./data/`)."
- **`wiki`**: "Which cogni-wiki should I query? Provide the wiki root path(s) (e.g., `~/cogni-wikis/my-wiki`)."
- **`hybrid`**: Ask for both document paths (if `document_paths` not already set) and wiki paths (if `wiki_paths` not already set). Web research is always included in hybrid mode.

If the user already provided paths in their original prompt (detected in Step 1), skip the follow-up for that path type.

#### Step 2b: Ask for project location (mandatory)

After research configuration is confirmed, **always** ask where to store the project — even if the user said "go" or "defaults". The only exception is when the user already explicitly specified a location in their original prompt or config responses (e.g., "save in standard", "put it in ~/research", "here").

Use `AskUserQuestion` to present:

> **Where should I store this project?**
> - `standard` *(recommended)* — `cogni-research/{project-slug}` (organized under plugin namespace)
> - `here` — current directory (`{cwd}/{project-slug}`)
> - Or provide a custom path

The reason this is a separate, explicit question: reports that land in the wrong directory are hard to find later and break the user's workspace organization. Asking once upfront avoids that.

**Handling location responses:**
- "standard" / "recommended" → `cogni-research/` relative to current working directory
- "here" → current working directory
- Any path → use as-is

#### Step 3: Initialize project

Once configuration is confirmed and the user has answered the location question (Step 2b), resolve the workspace path:
- "here" → current working directory
- "standard" → `cogni-research/` relative to current working directory
- custom path → use as-is

Then initialize:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/initialize-project.sh" \
  --topic "<user topic>" --type <basic|detailed|deep|outline|resource> \
  --workspace "<workspace path>" \
  [--market "<region-code>"] \
  [--output-language "<lang>"] \
  [--tone "<tone>"] \
  [--citation-format "<apa|mla|chicago|harvard|ieee>"] \
  [--source-urls "<url1,url2,...>"] \
  [--query-domains "<domain1,domain2,...>"] \
  [--max-subtopics <N>] \
  [--report-source "<web|local|hybrid>"] \
  [--document-paths "<path1,path2,...>"] \
  [--curate-sources]
```

Check the `already_exists` field in the JSON output before proceeding.

**If `already_exists` is `false`**: store the returned `project_path` and continue to Phase 0.1.

**If `already_exists` is `true`**: a project with the same slug already exists at that location. Do NOT silently continue — this would overwrite or mix into the user's prior research. Present a choice via `AskUserQuestion`:

> A research project already exists at `{project_path}`
> - **Topic**: "{existing_topic}"
> - **Completed phases**: {completed_phases}
>
> What would you like to do?
> 1. **Resume** — continue this existing project from where it left off
> 2. **New project** — create a separate project alongside the existing one
> 3. **Different location** — save the new project somewhere else

Handle the user's choice:
- **Resume**: read `.metadata/execution-log.json` from the existing project and jump to the Resumption logic (skip remaining Phase 0 steps)
- **New project**: re-run `initialize-project.sh` with `--suffix 2`. If that also collides, increment the suffix (3, 4, ...) until a fresh directory is created
- **Different location**: ask the user for a path, then re-run `initialize-project.sh` with the new `--workspace` value

### Phase 0.1: Market & Language Resolution

Read `market` and `output_language` from `project-config.json` (stored by `initialize-project.sh`). These control search localization and report output language respectively.

```bash
MARKET=$(jq -r '.market // empty' "${PROJECT_PATH}/.metadata/project-config.json" 2>/dev/null)
if [[ -z "$MARKET" ]]; then
  # Backward compat: derive market from legacy language field
  LANG=$(jq -r '.language // "en"' "${PROJECT_PATH}/.metadata/project-config.json")
  MARKET=$( [[ "$LANG" == "de" ]] && echo "dach" || echo "global" )
fi
OUTPUT_LANGUAGE=$(jq -r '.output_language // empty' "${PROJECT_PATH}/.metadata/project-config.json" 2>/dev/null)
if [[ -z "$OUTPUT_LANGUAGE" ]]; then
  # Derive from market config default_output_language
  OUTPUT_LANGUAGE=$(jq -r --arg m "$MARKET" '.[$m].default_output_language // ._default.default_output_language // "en"' "${CLAUDE_PLUGIN_ROOT}/references/market-sources.json" 2>/dev/null || echo "en")
fi
```

**`MARKET`** controls search localization for researcher agents:
- Researcher agents load `${CLAUDE_PLUGIN_ROOT}/references/market-sources.json` and use the market entry to generate intent-based bilingual queries, boost authority sources, and apply geographic modifiers
- Unknown market codes fall back to `_default` (English-only, no authority boosts)

**`OUTPUT_LANGUAGE`** controls report output for writer/reviewer/revisor:
- Writer produces the report in the specified language
- Reviewer evaluates prose quality in the output language

Available markets: `global` (default), `dach`, `de`, `us`, `uk`, `fr`. The market and output language are usually aligned (e.g., market=dach → output_language=de) but can diverge (e.g., market=fr, output_language=en for an English report about the French market).

### Phase 0.5: Preliminary Search

Before generating sub-questions, gather context about what information is actually available online. Sub-questions generated in a vacuum often target angles that have no searchable content, wasting researcher agents on dead ends.

1. Run 2-3 broad WebSearch queries on the user's topic
2. Review top 3-5 result snippets to understand the information landscape
3. Note: dominant angles, key organizations, recent developments, terminology
4. Feed these observations as context when generating sub-questions in Phase 1

### Phase 1: Sub-Question Generation

The quality of sub-questions determines the quality of the entire report. Orthogonal decomposition prevents researchers from duplicating each other's work, while collectively exhaustive coverage prevents blind spots. Poor sub-questions produce redundant contexts and missing perspectives that the review loop cannot fix — it can only catch factual errors, not structural gaps.

**Read**: `references/sub-question-generation.md` for decomposition patterns.

Use the preliminary search context from Phase 0.5 to inform sub-question generation — ensure questions target angles that have actual web content available.

**Agent Role Selection**: If `researcher_role` is already set in `project-config.json` (user-specified via `--researcher-role`), use it directly. Otherwise, auto-select the best-fit persona by reading `${CLAUDE_PLUGIN_ROOT}/references/agent-roles.md` and matching the topic's domain signals against the role catalog. Store the selected role in `project-config.json` as `researcher_role` and pass it to the writer agent as `RESEARCHER_ROLE`.

Generate sub-questions based on report type. If `max_subtopics` is set in `project-config.json`, use that count instead of the defaults below:

**Basic (default 5 sub-questions, or `max_subtopics` if set)**:
1. Decompose the topic into orthogonal research questions — more sub-questions mean more parallel researchers, which means more diverse sources and richer context for the writer
2. Each question should target a distinct aspect of the topic
3. Include: background/context, current state, key developments, challenges/limitations, implications/outlook

**Detailed (default 5-10 section outline, or `max_subtopics` if set)**:
1. Generate a multi-section outline first
2. Create one sub-question per section
3. Include: executive framing, multiple analytical angles, cross-cutting themes, recommendations

**Outline (default 5 sub-questions, or `max_subtopics` if set)**:
1. Same decomposition as basic — generate orthogonal sub-questions
2. Add `search_guidance` emphasizing key findings and structure over depth
3. Writer will produce hierarchical outline, not prose

**Resource (default 5 sub-questions, or `max_subtopics` if set)**:
1. Same decomposition as basic — generate sub-questions targeting distinct source categories
2. Add `search_guidance` emphasizing source diversity and quality over depth of individual findings
3. Writer will produce annotated bibliography, not narrative

**Deep (research tree, `max_subtopics` controls leaf count if set)**:
Read `references/deep-research-tree.md` for tree decomposition algorithm.
1. Decompose into 3-5 top-level branches
2. For each branch, generate 2-3 sub-branches
3. Create sub-question entities for all leaf nodes

For each sub-question, create entity:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "${PROJECT_PATH}" \
  --entity-type sub-question \
  --data '{"frontmatter": {"query": "...", "parent_topic": "...", "section_index": N, "report_type": "basic", "search_guidance": "...", "status": "pending"}, "content": ""}' \
  --json
```

### Phase 2: Parallel Web Research

Parallel execution is the key throughput optimization — a basic report with 5 sub-questions completes research in the time of one. All researchers use sonnet for richer source extraction and better findings quality. Batching at 4-5 agents prevents overwhelming the host with concurrent WebFetch requests and avoids rate limiting from search providers. Each agent runs independently, so a failure in one does not block the others.

Read `report_source` from `project-config.json` (default: "web"). This determines which researcher agents to spawn.

#### Web mode (report_source = "web", default)

Resolve the current year for recency-aware search queries:
```bash
CURRENT_YEAR=$(date +%Y)
```

Spawn section-researcher agents in parallel batches (max 5 per batch):

**Basic/Detailed/Outline/Resource mode**:
```
For each sub-question entity in 00-sub-questions/data/:
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    MARKET=<market>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    run_in_background=true)
```

**Deep mode**:
```
For each leaf sub-question in 00-sub-questions/data/:
  Task(deep-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    MARKET=<market>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    DEPTH=2,
    run_in_background=true)
```

#### Local mode (report_source = "local")

Spawn local-researcher agents instead of section-researchers. All sub-questions research from the same document set, but each agent extracts findings relevant to its specific sub-question.

```
For each sub-question entity in 00-sub-questions/data/:
  Task(local-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    DOCUMENT_PATHS=<from project-config.json document_paths>,
    OUTPUT_LANGUAGE=<output_language>,
    run_in_background=true)
```

Deep mode with local sources: use local-researcher (not deep-researcher). The recursive tree algorithm is designed for web search breadth — local documents don't benefit from recursive decomposition. If the user requests deep + local, run local-researchers with the deep sub-question tree but without internal recursion.

#### Wiki mode (report_source = "wiki")

Spawn wiki-researcher agents instead of section-researchers. Each agent queries all configured cogni-wiki instances for findings relevant to its sub-question. The wiki-researcher follows wiki-query's index-first discovery pattern: read `wiki/index.md`, select relevant pages, read those pages, extract grounded findings.

```
For each sub-question entity in 00-sub-questions/data/:
  Task(wiki-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    WIKI_PATHS=<comma-separated wiki roots from project-config.json wiki_paths>,
    OUTPUT_LANGUAGE=<output_language>,
    run_in_background=true)
```

Deep mode with wiki sources: use wiki-researcher (not deep-researcher), same rationale as local — the recursive tree algorithm is designed for web search breadth, not pre-synthesized knowledge.

#### Hybrid mode (report_source = "hybrid")

Run available researcher types in parallel based on configured paths, then merge all findings in Phase 3. This produces the richest context.

```
For each sub-question entity in 00-sub-questions/data/:
  # Wiki research (if wiki_paths configured)
  if wiki_paths:
    Task(wiki-researcher,
      SUB_QUESTION_PATH=<path>,
      PROJECT_PATH=<project_path>,
      WIKI_PATHS=<comma-separated wiki roots from project-config.json wiki_paths>,
      OUTPUT_LANGUAGE=<output_language>,
      run_in_background=true)

  # Local research (if document_paths configured)
  if document_paths:
    Task(local-researcher,
      SUB_QUESTION_PATH=<path>,
      PROJECT_PATH=<project_path>,
      DOCUMENT_PATHS=<from project-config.json document_paths>,
      OUTPUT_LANGUAGE=<output_language>,
      run_in_background=true)

  # Web research (always in hybrid mode)
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    MARKET=<market>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    run_in_background=true)
```

All researcher types create separate context entities for the same sub-question. The merge-context script (Phase 3) handles deduplication across wiki, local, and web sources.

Batch in groups of 4-5 to respect concurrency limits. Wait for each batch before starting next.

After all researchers complete:
- Check return values for failures
- Update sub-question entity status to "researched" or "failed"
- Log results to `.logs/phase-2-research.jsonl`

### Phase 2.5: Source Curation (conditional)

Source curation ranks sources by quality, relevance, authority, and recency before the writer sees them. This prevents the writer from treating all sources equally when some are clearly more authoritative.

**Activation rules** (check in order):
1. If `curate_sources` is explicitly `false` in project-config.json → **skip**
2. If `curate_sources` is explicitly `true` → **run** (any report type, any source count)
3. If report type is `detailed` or `deep` AND source entity count >= 8 → **run**
4. Otherwise → **skip**

When activated:
```
Task(source-curator,
  PROJECT_PATH=<project_path>,
  MARKET=<market>)
```

The source-curator produces `.metadata/curated-sources.json` with quality rankings (primary/secondary/supporting tiers) and diversity analysis. The writer agent reads this in Phase 4 to prioritize citations.

### Phase 3: Context Aggregation

Aggregation deduplicates sources and enforces a context word limit (25,000 words) to prevent writer overload. Without this step, deep reports with 15+ researchers can produce far more raw context than a single writer agent can meaningfully synthesize, leading to shallow treatment of all topics rather than deep treatment of each.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/merge-context.py" \
  --project-path "${PROJECT_PATH}" --json
```

Verify output: contexts count, sources count, total words. If too few sources (< 3), consider re-running failed sub-questions.

### Phase 4: Report Writing

Spawn writer agent:
```
Task(writer,
  PROJECT_PATH=<project_path>,
  DRAFT_VERSION=1,
  REPORT_TYPE=<type>,
  RESEARCHER_ROLE=<role from project-config.json>,
  TONE=<tone from project-config.json, default "objective">,
  CITATION_FORMAT=<citation_format from project-config.json, default "apa">,
  OUTPUT_LANGUAGE=<output_language>)
```

Verify: draft written to `output/draft-v1.md`, reasonable word count.

### Phase 5: Structural Review

This phase runs a lightweight structural-only review to catch organizational and stylistic issues before finalization. Claims verification — the factual accuracy check — runs separately via the **verify-report** skill in a dedicated context window. This architectural split ensures claims verification gets full context attention rather than competing with research data from Phases 0-4.

**Read**: `references/review-criteria.md` for scoring rubric.

**Outline and Resource modes**: Accept the draft if structural score >= 0.65 or iterate once. Then proceed to Phase 6.

**Basic, Detailed, and Deep modes**: Run one structural review iteration as described below.

#### 5a: Review (structural only)
```
Task(reviewer,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  REVIEW_ITERATION=1,
  OUTPUT_LANGUAGE=<output_language>)
```

Note: no `CLAIMS_DASHBOARD` parameter — the reviewer runs structural criteria only (completeness, coherence, source diversity, depth, clarity). The higher accept threshold (0.82) for structural-only review applies automatically.

#### 5b: Revise (if verdict="revise")
```
Task(revisor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  VERDICT_PATH=".metadata/review-verdicts/v1.json",
  NEW_DRAFT_VERSION=N+1,
  OUTPUT_LANGUAGE=<output_language>,
  MARKET=<market>)
```

Maximum 1 structural review iteration. After revision (or if the first review accepts), proceed to Phase 5.5.

### Phase 5.5: Visual Enrichment via cogni-visual (Optional)

Ask the user whether to generate a themed HTML version of the report with interactive charts and diagrams. This transforms the markdown report into a polished, presentation-ready HTML deliverable.

1. Check whether `cogni-visual:enrich-report` is available. If not installed, display a warning and skip to Phase 6.
2. Ask the user: `"Generate themed HTML with interactive charts and diagrams? (cogni-visual:enrich-report)"`
3. If the user declines, skip to Phase 6.
4. If yes, invoke the `cogni-visual:enrich-report` skill with `source_path` pointing to the final accepted draft (`output/report.md` if already copied, otherwise the latest `output/draft-v{N}.md`). The enrich-report skill handles theme selection, enrichment planning, and interactive review — do not duplicate that logic here.
5. Record the result for the Phase 6 summary.

### Phase 6: Finalization

1. Copy final accepted draft to `output/report.md`
   - Do NOT copy, symlink, or duplicate the report to the workspace root or any location outside the project folder. The canonical deliverable is `{project_path}/output/report.md` — the self-contained project directory is the unit of output (report + sources + metadata, all Obsidian-browsable). If the user wants a different format or location, the enrich-report phase (Phase 5.5) handles that.
2. **Accumulate cost estimates**: Sum `cost_estimate.estimated_usd` from all agent outputs collected during Phases 2-5. Group by agent role (researchers, writer, reviewer, revisor, claim_extractor, source_curator). Write cost summary to `execution-log.json`
3. Update `.metadata/execution-log.json` with:
   - Phase completion timestamps
   - Agent counts and durations
   - Final structural review score and iteration count
   - `phase_5_review.claims_verification: "deferred to verify-report"`
   - Cost summary: `{"total_estimated_usd": N, "breakdown": {"researchers": N, "writer": N, ...}}`
   - `enrich_report_applied`: true/false
   - `enrich_report_path`: path to enriched HTML or null
4. Report summary to user:
   - Topic and report type
   - Word count and section count
   - Sources cited
   - Structural review score
   - **Estimated cost** (total USD from cost_summary)
   - Full absolute path to `output/report.md`
   - Project folder path (for browsing sources and metadata)
4. **Recommend next steps** (in order):

> **Next steps:**
> 1. `/verify-report` — Verify claims against cited sources. Runs in a clean context window for thorough fact-checking.

## Resumption

If a project directory already exists at init:
1. Read `.metadata/execution-log.json` for phase completion state
2. Check which entity directories have data
3. Resume from the first incomplete phase
4. Report resumption status to user

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| All researchers fail | Ask user to rephrase topic or try different sub-questions |
| Most researchers fail | Proceed with available contexts, note gaps in report |
| Writer produces empty draft | Re-run with more explicit instructions |
| Claims verification needed | Handled by verify-report skill in a separate context window — not run here |
| Review loop reaches max (3) | Accept current draft with quality warning |
| Local documents unreadable | Log skipped files, proceed with readable ones. If none readable, ask user for alternative paths |
| No relevant content in local docs | Suggest switching to web mode or providing different documents |
| Hybrid mode: local fails, web succeeds | Proceed with web-only context, note in report that local sources were unavailable |
| Document path glob matches nothing | Report error, ask user to verify paths |
