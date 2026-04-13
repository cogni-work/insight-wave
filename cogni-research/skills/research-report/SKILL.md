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
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, Task, Skill
---

# Research Report Skill

This skill executes the research pipeline (Phases 0.5-6) on an initialized project. Configuration and project creation are handled by the **research-setup** skill — this skill does not present configuration menus or ask the user for preferences.

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

1. Skill checks for an initialized project (project-config.json)
2. Not found -> invokes `Skill("research-setup")` with the user's topic. Setup handles all configuration turns.
3. After setup completes, reads project-config.json and starts Phase 0.5.

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

### Phase 0: Project Prerequisite

Check for an initialized project. Look for `project-config.json` in:
1. Path provided by user (if any)
2. `cogni-research/{topic-slug}/.metadata/project-config.json` (relative to cwd)
3. `./{topic-slug}/.metadata/project-config.json`

**If project-config.json exists**: Store `PROJECT_PATH` and continue to Phase 0.1.

**If project-config.json does NOT exist**: Invoke `Skill("research-setup", args: "<user's original request>")` and STOP. Do not proceed to any research phase. The research-setup skill handles all configuration and project initialization. After setup completes, read the created `project-config.json` and continue to Phase 0.1.

### Phase 0.1: Market & Language Resolution

Read `market` and `output_language` from `project-config.json` (stored by `initialize-project.sh`). These control search localization and report output language respectively.

Backward compatibility: if `market` is absent, derive it from the legacy `language` field (`"de"` maps to `"dach"`, anything else maps to `"global"`). If `output_language` is absent, look up the market's `default_output_language` in `${CLAUDE_PLUGIN_ROOT}/references/market-sources.json`, falling back to `"en"`.

**`MARKET`** controls search localization for researcher agents:
- Researcher agents load `${CLAUDE_PLUGIN_ROOT}/references/market-sources.json` and use the market entry to generate intent-based bilingual queries, boost authority sources, and apply geographic modifiers
- Unknown market codes fall back to `_default` (English-only, no authority boosts)

**`OUTPUT_LANGUAGE`** controls report output for writer/reviewer/revisor:
- Writer produces the report in the specified language
- Reviewer evaluates prose quality in the output language

Available markets: `global` (default), `dach`, `de`, `fr`, `it`, `pl`, `nl`, `es`, `us`, `uk`, `eu`. The market and output language are usually aligned (e.g., market=dach → output_language=de, market=it → output_language=it) but can diverge (e.g., market=fr, output_language=en for an English report about the French market). The `eu` market is a composite that fans out per-country researchers — see composite dispatch below.

#### Composite Market Dispatch (market=eu)

When `market` is `"eu"`, load the market entry from `market-sources.json` and check for the `composite_markets` field. If present:

1. **Store composite context**: `COMPOSITE_MARKETS` = `["de", "fr", "it", "pl", "nl", "es"]`, `IS_COMPOSITE` = true
2. **Default output language to English**: Cross-market reports are written in English unless explicitly overridden
3. **Phase 1 sub-question generation**: Generate sub-questions with two types:
   - **Market-specific**: Questions about individual countries (e.g., "What is the regulatory landscape for LEO satellite in Italy?"). Tag with `target_market: "it"`
   - **Cross-market**: Questions comparing across countries or about EU-wide aspects (e.g., "How do European spectrum allocation policies compare across DE, FR, IT, PL, NL, ES?"). Tag with `target_market: "eu"`
4. **Phase 2 researcher dispatch**: For market-specific sub-questions, dispatch section-researcher with `MARKET=<country>`. For cross-market sub-questions, dispatch section-researcher with `MARKET=eu` (uses EU-wide authority sources + geographic modifiers for all 6 countries)
5. **EU-wide sources**: The `eu` entry in market-sources.json provides EU-level authority sources (EUR-Lex, Eurostat, ESA, BEREC, ETNO, DigitalEurope) used for cross-market questions

This approach leverages the existing parallel researcher dispatch — the composite market simply maps to more researchers with different market parameters. No new agent types needed.

### Phase 0.5: Preliminary Search

**PREREQUISITE**: `project-config.json` must exist. If it does not, STOP — invoke `Skill("research-setup")` to configure and initialize the project. Do not proceed without an initialized project.

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

Hybrid mode is additive: each channel gets the full sub-question set. If deep mode produces 8 leaf sub-questions, hybrid spawns 8 web-researchers + 8 wiki-researchers (16 total), not 4+4. Wiki and local researchers are cheap (local file reads, no rate limiting), so the added coverage justifies the extra agents. Only the batching cap (4-5 concurrent) constrains throughput.

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
2. Ask the user which visual pipeline to use:
   - **Option 1: Full visual pipeline** (recommended) — First create a dedicated infographic via `cogni-visual:story-to-infographic`, then render it via `/render-infographic`, then enrich the report via `cogni-visual:enrich-report`. Best results: the infographic header is Pencil-rendered with 10-step distillation, 4-layer validation, and reviewer agent.
   - **Option 2: Quick enrichment** — Run `cogni-visual:enrich-report` directly. It generates a simplified infographic inline (fewer validation steps, hardcoded to economist preset).
   - **Option 3: Skip** visual enrichment.
3. If the user declines (option 3), skip to Phase 6.
4. If option 1: invoke `cogni-visual:story-to-infographic` with `source_path` pointing to the final accepted draft, then `/render-infographic` to render it, then invoke `cogni-visual:enrich-report` (which will detect and reuse the infographic artifacts).
5. If option 2: invoke `cogni-visual:enrich-report` directly with `source_path` pointing to the final accepted draft (`output/report.md` if already copied, otherwise the latest `output/draft-v{N}.md`). The enrich-report skill handles theme selection, enrichment planning, and interactive review — do not duplicate that logic here.
6. Record the result for the Phase 6 summary.

### Phase 6: Finalization

1. Copy final accepted draft to `output/report.md`
   - The project directory is a self-contained unit of output — report, sources, and metadata together, all Obsidian-browsable. Keep the canonical deliverable at `{project_path}/output/report.md` and do not copy or symlink it elsewhere. If the user wants a different format or location, the enrich-report phase (Phase 5.5) handles that.
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
> 2. `/copywriter` — Polish the report for executive readability (BLUF structure, tighter prose, consistent tone).
> 3. `/story-to-infographic` + `/render-infographic` + `/enrich-report` — Create an editorial infographic first, then generate themed HTML with charts and diagrams. enrich-report detects and reuses the infographic. (Skip if already done in Phase 5.5.)

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
