---
name: research-report
description: |
  Generate a multi-agent research report using parallel web research with claims-verified
  review loops. Three modes: basic (fast single-pass), detailed (multi-section with outline),
  deep (recursive tree exploration). Integrates with cogni-claims for evidence-based quality gates.
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

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

**Result**: A 3000-5000 word report with inline citations, produced via:
1. Topic decomposition into 5 sub-questions
2. Parallel web research (sonnet agents, one per sub-question)
3. Context aggregation and source deduplication
4. Report compilation (sonnet writer agent)
5. Claims extraction → cogni-claims verification → evidence-based review
6. Final polished report at `output/report.md`

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
| `references/claims-integration.md` | Phase 5 — cogni-claims submission + verification |

## Workflow

### Phase 0: Project Initialization

A well-structured project directory is the foundation for resumability and cross-agent coordination. Without it, agents cannot find each other's outputs, the review loop cannot track iterations, and a crash mid-research loses all progress.

1. Determine workspace path (use current directory or ask user)
2. Detect report type from user request (basic/detailed/deep/outline/resource)
3. Parse optional parameters from user request:
   - **Tone**: If user specifies a writing style (e.g., "analytical", "persuasive"), map to a tone from `references/writing-tones.md`. Default: "objective"
   - **Citation format**: If user specifies a citation style (e.g., "use IEEE citations", "APA format"), capture it. Default: "apa". See `references/citation-formats.md`
   - **Source URLs**: If user provides specific URLs to research (e.g., "research these articles: url1, url2"), collect them
   - **Query domains**: If user wants to restrict research to specific domains (e.g., "only use .gov and .edu sources"), collect them
   - **Max subtopics**: If user specifies a sub-question count (e.g., "use 8 sub-questions"), capture it
   - **Report source**: If user provides local documents (e.g., "analyze these PDFs", "research from my files"), set to "local". If user wants both web and local: "hybrid". Default: "web"
   - **Document paths**: If report_source is "local" or "hybrid", collect paths to local files or a glob pattern
   - **Curate sources**: If user wants ranked/prioritized sources (e.g., "prioritize authoritative sources"), enable curation
   - **Generate images**: If user wants visual illustrations (e.g., "add diagrams", "make it visual"), enable image generation
4. Initialize project:
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
5. Store returned `project_path` for all subsequent phases

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

Spawn section-researcher agents in parallel batches (max 5 per batch):

**Basic/Detailed/Outline/Resource mode**:
```
For each sub-question entity in 00-sub-questions/data/:
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    LANGUAGE=<language>,
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

1. Read `references/image-generation.md` for provider options
2. Scan the draft for image placeholder markers (`<!-- IMAGE: ... -->`)
3. If cogni-visual plugin is available: delegate image generation
4. If external API key available: generate via API
5. Otherwise: leave placeholder markers for user to fill
6. Insert generated images into the draft using markdown image syntax

Skip for outline and resource report types.

### Phase 5: Claims-Verified Review Loop

**Outline and Resource modes**: Skip the full review loop. Run a single structural review pass (reviewer only, no claims extraction/verification). Accept the draft if score >= 0.65 or iterate once. Then proceed to Phase 6.

**Basic, Detailed, and Deep modes**: Full review loop as described below.

Structural review alone catches organizational and stylistic issues but misses factual errors — the most damaging kind. Claims-based review fetches the original source URLs and compares what the report says against what the source actually states, catching misquotations, unsupported conclusions, and selective omissions that would otherwise reach the reader as authoritative claims. This is a cogni-works original design replacing GPT-Researcher's human-in-the-loop review.

**Read**: `references/claims-integration.md` for cogni-claims protocol.
**Read**: `references/review-criteria.md` for scoring rubric.

Maximum 3 iterations. Each iteration:

#### 5a: Claim Extraction
```
Task(claim-extractor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  DRAFT_VERSION=N)
```

#### 5b: Claims Submission to cogni-claims
```
Skill(cogni-claims:claims, mode=submit,
  working_dir=<project_path>,
  claims=[...extracted claims...],
  submitted_by="cogni-gpt-researcher")
```

#### 5c: Claims Verification
```
Skill(cogni-claims:claims, mode=verify,
  working_dir=<project_path>)
```

#### 5d: Review
```
Task(reviewer,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  CLAIMS_DASHBOARD=<project_path>/cogni-claims/claims.json,
  REVIEW_ITERATION=N,
  LANGUAGE=<language>)
```

#### 5e: Revise (if verdict="revise" and iteration < 3)
```
Task(revisor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  VERDICT_PATH=".metadata/review-verdicts/v{N}.json",
  NEW_DRAFT_VERSION=N+1,
  LANGUAGE=<language>)
```
Then goto 5a with new draft version.

#### 5f: Accept
When verdict="accept" or iteration reaches 3: proceed to Phase 6.

**Graceful degradation**: If cogni-claims is not available, skip 5b-5c and run reviewer with structural criteria only.

### Phase 6: Finalization

1. Copy final accepted draft to `output/report.md`
2. Update `.metadata/execution-log.json` with:
   - Phase completion timestamps
   - Agent counts and durations
   - Final review score and iteration count
   - Claims verification stats
3. Report summary to user:
   - Topic and report type
   - Word count and section count
   - Sources cited
   - Claims verified / deviated / unavailable
   - Review iterations and final score
   - Path to `output/report.md`

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
| cogni-claims unavailable | Fall back to structural-only review |
| Review loop reaches max (3) | Accept current draft with quality warning |
| Local documents unreadable | Log skipped files, proceed with readable ones. If none readable, ask user for alternative paths |
| No relevant content in local docs | Suggest switching to web mode or providing different documents |
| Hybrid mode: local fails, web succeeds | Proceed with web-only context, note in report that local sources were unavailable |
| Document path glob matches nothing | Report error, ask user to verify paths |
