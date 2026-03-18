---
name: research-report
description: |
  Generate a multi-agent research report using parallel web research with structural
  review. Three modes: basic (fast single-pass), detailed (multi-section with outline),
  deep (recursive tree exploration). Claims verification runs separately via verify-report.
  Supports configurable writing tones, auto/manual researcher roles, source URL pre-fetch,
  domain-restricted search, custom sub-question counts, and local document research.
  Three source modes: web (default), local (analyze user's documents), hybrid (web + documents).
  Use when the user asks to "research report", "investigate", "deep research", "write a report",
  "gpt-researcher", "multi-agent research", "analyze these documents", "research from my files",
  or requests comprehensive topic analysis with citations.
  Also use when the user wants to "resume research", "continue research report", "pick up the research",
  "finish the report", "what happened to my report", or resume an interrupted research run.
---

# Research Report Skill

When this skill loads:
1. If no topic was provided → ask: "What topic should I research?"
2. If topic provided → extract any options already in the user's prompt (report type, tone, citations, language, source mode, etc.), then present the **Configuration Menu** (Phase 0 Step 2) so the user can confirm or customize before research begins
3. If the user explicitly said "just go", "defaults", or specified all key options (type + tone + citations) → skip the interactive menu, show a one-line confirmation of detected settings, and proceed directly
4. Never greet or re-explain capabilities

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
> **Language**: en *(default)* | de (German with DACH sources)
> **Location**: here *(default, current dir)* | standard (`cogni-gpt-researcher/`) | custom path
>
> Advanced: sub-question count, source mode (web/local/hybrid), domain filter, researcher role, image generation — ask about any of these
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
| `references/image-generation.md` | Phase 4.5 — image generation (when enabled) |
| `references/review-criteria.md` | Phase 5 — understanding review scoring |

## Workflow

### Phase 0: Project Initialization

A well-structured project directory is the foundation for resumability and cross-agent coordination. Without it, agents cannot find each other's outputs, the review loop cannot track iterations, and a crash mid-research loses all progress.

#### Step 1: Extract options from user's prompt

Scan the user's request and extract any options they already specified. These become "detected" settings that won't be re-asked in the configuration menu.

- **Report type**: keywords like "detailed", "deep research", "outline", "sources" → map to basic/detailed/deep/outline/resource (see `references/report-types.md`)
- **Tone**: style keywords like "analytical", "persuasive", "formal" → map to tone from `references/writing-tones.md`. Default: "objective"
- **Citation format**: "IEEE", "APA format", "Chicago style", "wikilink", "superscript citations" → capture. Default: "apa". See `references/citation-formats.md`
- **Language**: "in German", "auf Deutsch" → "de". Default: "en"
- **Source URLs**: any URLs in the prompt → collect for pre-fetch
- **Query domains**: "only .gov sources", "restrict to arxiv" → collect domains
- **Max subtopics**: "use 8 sub-questions", "12 dimensions" → capture count
- **Report source**: "analyze these PDFs", "research from my files" → "local"; both web and local → "hybrid". Default: "web"
- **Document paths**: file paths or glob patterns for local/hybrid mode
- **Curate sources**: "prioritize authoritative sources" → enable
- **Generate images**: "add diagrams", "make it visual" → enable
- **Project location**: "save in standard folder", "store here", "put it in ~/research" → capture. Default: current directory

#### Step 2: Interactive Configuration

Present the user with a configuration menu using `AskUserQuestion` so they can see what options exist and choose before research starts. This is the heart of Phase 0 — it makes the skill's capabilities discoverable rather than hidden behind keyword detection.

**Assemble the menu dynamically:**

1. Show the detected topic
2. List any options already extracted from the prompt (e.g., "Detected: type = deep, citations = IEEE")
3. For **unset primary options**, show the compact chooser:
   - **Depth** (only if report type not yet detected): list all 5 types with word counts and one-line descriptions
   - **Tone** (only if not detected): list all 13 options, mark default
   - **Citations** (only if not detected): list all 5 formats, mark default
   - **Language** (only if not detected): en | de
4. **Project location** (always shown):
   - `here` = `{cwd}/{project-slug}` (current directory)
   - `standard` = `cogni-gpt-researcher/{project-slug}` (plugin workspace)
   - or provide a custom path
5. Always include one line for advanced options: "Advanced: sub-question count, source mode (web/local/hybrid), domain filter, researcher role, image generation — ask about any of these"
6. End with: `Reply with your choices, or "go" for defaults.`

**Conditional skip**: If the user's prompt already specified ALL primary options (type + tone + citations) OR included urgency signals ("just go", "start now", "defaults are fine"), collapse the menu to a compact confirmation that **always includes location**:
> "Starting **detailed** research on X — analytical tone, IEEE citations, English. Project location: current directory. Change anything? (or 'go')"

**Handling user responses:**
- "go" / "defaults" / "start" → proceed with detected + default values (location defaults to current directory)
- Specific choices ("deep, analytical, IEEE, standard") → merge with detected values, proceed
- Location choices: "here" → current directory; "standard" → `cogni-gpt-researcher/`; any path → use as-is
- Question about an advanced option ("what roles are available?") → read the relevant reference file (`references/agent-roles.md`, `references/writing-tones.md`, etc.), explain the option, then re-present the menu
- Partial choices ("make it detailed") → update that option, ask if anything else or proceed

#### Step 3: Initialize project

Once configuration is confirmed (including project location from Step 2), resolve the workspace path:
- "here" or default → current working directory
- "standard" → `cogni-gpt-researcher/` relative to current working directory
- custom path → use as-is

Then initialize:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/initialize-project.sh" \
  --topic "<user topic>" --type <basic|detailed|deep|outline|resource> \
  --workspace "<workspace path>" \
  [--tone "<tone>"] \
  [--citation-format "<apa|mla|chicago|harvard|ieee>"] \
  [--source-urls "<url1,url2,...>"] \
  [--query-domains "<domain1,domain2,...>"] \
  [--max-subtopics <N>] \
  [--report-source "<web|local|hybrid>"] \
  [--document-paths "<path1,path2,...>"] \
  [--curate-sources] \
  [--generate-images]
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

### Phase 0.1: Language Resolution

Read `language` from `project-config.json` (stored by `initialize-project.sh --language`). This controls both search behavior and output language across all agents.

```bash
LANGUAGE=$(jq -r '.language // "en"' "${PROJECT_PATH}/project-config.json" 2>/dev/null || echo "en")
```

When `LANGUAGE=de`:
- Researcher agents generate bilingual queries (English + German) with DACH site-specific searches
- Writer agent produces the report in German
- Reviewer evaluates German prose quality
- All agents reference `${CLAUDE_PLUGIN_ROOT}/references/dach-sources.md` for DACH source intelligence

When `LANGUAGE=en` (default): no change to existing behavior.

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
    LANGUAGE=<language>,
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
    LANGUAGE=<language>,
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
    LANGUAGE=<language>,
    run_in_background=true)
```

Deep mode with local sources: use local-researcher (not deep-researcher). The recursive tree algorithm is designed for web search breadth — local documents don't benefit from recursive decomposition. If the user requests deep + local, run local-researchers with the deep sub-question tree but without internal recursion.

#### Hybrid mode (report_source = "hybrid")

Run both local and web researchers for each sub-question, then merge their findings in Phase 3. This produces the richest context but uses 2x the agents.

```
For each sub-question entity in 00-sub-questions/data/:
  # Local research first (documents)
  Task(local-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    DOCUMENT_PATHS=<from project-config.json document_paths>,
    LANGUAGE=<language>,
    run_in_background=true)

  # Web research in parallel
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    LANGUAGE=<language>,
    CURRENT_YEAR=<current_year>,
    SOURCE_URLS=<from project-config.json, if set>,
    QUERY_DOMAINS=<from project-config.json, if set>,
    run_in_background=true)
```

Both agents create separate context entities for the same sub-question. The merge-context script (Phase 3) handles deduplication across local and web sources.

Batch in groups of 4-5 to respect concurrency limits. Wait for each batch before starting next.

After all researchers complete:
- Check return values for failures
- Update sub-question entity status to "researched" or "failed"
- Log results to `.logs/phase-2-research.jsonl`

### Phase 2.5: Source Curation (optional)

When `curate_sources` is `true` in project-config.json AND the project has 10+ source entities AND the report type is `detailed` or `deep`:

```
Task(source-curator,
  PROJECT_PATH=<project_path>,
  LANGUAGE=<language>)
```

The source-curator produces `.metadata/curated-sources.json` with quality rankings (primary/secondary/supporting tiers) and diversity analysis. The writer agent reads this in Phase 4 to prioritize citations.

Skip source curation for: basic, outline, resource report types, or when fewer than 10 sources exist.

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
  LANGUAGE=<language>)
```

Verify: draft written to `output/draft-v1.md`, reasonable word count.

#### Phase 4.5: Image Generation (optional)

When `generate_images` is `true` in project-config.json AND the report type is `basic`, `detailed`, or `deep`:

1. Read `references/image-generation.md` for provider options and style-to-provider mapping
2. Create `output/images/` directory if it doesn't exist
3. Scan the draft for image placeholder markers (`<!-- IMAGE: ... -->`)
4. For each placeholder, determine the image style from the marker (diagram, infographic, illustration)
5. **Route to the correct provider based on style**:
   - **diagram** style → Use Excalidraw MCP (`mcp__excalidraw__batch_create_elements` + `mcp__excalidraw__export_to_image`). Build the diagram elements programmatically from the description, then export as PNG
   - **illustration/infographic** style → Invoke `Skill(cogni-visual:generate-image)` if available
   - **Fallback** → Try external API if API key available, otherwise leave placeholder
6. Replace each resolved `<!-- IMAGE: ... -->` marker with `![Description](output/images/<filename>.png)` in the draft
7. Log generated vs. unresolved images to `.logs/phase-4.5-images.jsonl`

Skip for outline and resource report types.

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
  LANGUAGE=<language>)
```

Note: no `CLAIMS_DASHBOARD` parameter — the reviewer runs structural criteria only (completeness, coherence, source diversity, depth, clarity). The higher accept threshold (0.82) for structural-only review applies automatically.

#### 5b: Revise (if verdict="revise")
```
Task(revisor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  VERDICT_PATH=".metadata/review-verdicts/v1.json",
  NEW_DRAFT_VERSION=N+1,
  LANGUAGE=<language>)
```

Maximum 1 structural review iteration. After revision (or if the first review accepts), proceed to Phase 6.

### Phase 6: Finalization

1. Copy final accepted draft to `output/report.md`
   - Do NOT copy, symlink, or duplicate the report to the workspace root or any location outside the project folder. The canonical deliverable is `{project_path}/output/report.md` — the self-contained project directory is the unit of output (report + sources + metadata, all Obsidian-browsable). If the user wants a different format or location, point them to `/export-report`.
2. Update `.metadata/execution-log.json` with:
   - Phase completion timestamps
   - Agent counts and durations
   - Final structural review score and iteration count
   - `phase_5_review.claims_verification: "deferred to verify-report"`
3. Report summary to user:
   - Topic and report type
   - Word count and section count
   - Sources cited
   - Structural review score
   - Full absolute path to `output/report.md`
   - Project folder path (for browsing sources and metadata)
4. **Recommend claims verification**:

> **Next step**: Run `/verify-report` to verify claims against cited sources. This runs in a clean context window for thorough fact-checking — extracting claims, verifying each against its source URL, and revising any deviations found.

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
