---
name: research-report
description: |
  Generate a multi-agent research report using parallel web research with claims-verified
  review loops. Three modes: basic (fast single-pass), detailed (multi-section with outline),
  deep (recursive tree exploration). Integrates with cogni-claims for evidence-based quality gates.
  Use when the user asks to "research report", "investigate", "deep research", "write a report",
  "gpt-researcher", "multi-agent research", or requests comprehensive topic analysis with citations.
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

| Type | Trigger | Sub-Questions | Depth | Use Case |
|------|---------|--------------|-------|----------|
| **basic** | "research report on X" | 5 | Single-pass | Quick overview |
| **detailed** | "detailed research report on X" | 5-10 | Multi-section | Comprehensive analysis |
| **deep** | "deep research on X" | 10-20 (tree) | Recursive | Maximum depth + breadth |

Default: **basic** unless user specifies otherwise.

## References Index

Read these reference files when the corresponding phase needs them:

| Reference | Read When |
|-----------|-----------|
| `references/report-types.md` | Phase 1 — choosing report type and planning |
| `references/sub-question-generation.md` | Phase 1 — decomposing user query |
| `references/deep-research-tree.md` | Phase 1 (deep mode) — building research tree |
| `references/review-criteria.md` | Phase 5 — understanding review scoring |
| `references/claims-integration.md` | Phase 5 — cogni-claims submission + verification |

## Workflow

### Phase 0: Project Initialization

A well-structured project directory is the foundation for resumability and cross-agent coordination. Without it, agents cannot find each other's outputs, the review loop cannot track iterations, and a crash mid-research loses all progress.

1. Determine workspace path (use current directory or ask user)
2. Detect report type from user request (basic/detailed/deep)
3. Initialize project:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/initialize-project.sh" \
     --topic "<user topic>" --type <basic|detailed|deep> \
     --workspace "<workspace path>"
   ```
4. Store returned `project_path` for all subsequent phases

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

**Agent Role Selection**: Based on the topic, determine an appropriate researcher persona (e.g., "Cybersecurity Analyst", "Market Research Strategist", "Scientific Literature Reviewer"). This role shapes the writer's tone, terminology, and analytical lens. Store it in `project-config.json` as `researcher_role` and pass it to the writer agent as `RESEARCHER_ROLE`.

Generate sub-questions based on report type:

**Basic (5 sub-questions)**:
1. Decompose the topic into exactly 5 orthogonal research questions — more sub-questions mean more parallel researchers, which means more diverse sources and richer context for the writer
2. Each question should target a distinct aspect of the topic
3. Include: background/context, current state, key developments, challenges/limitations, implications/outlook

**Detailed (5-10 section outline)**:
1. Generate a multi-section outline first
2. Create one sub-question per section
3. Include: executive framing, multiple analytical angles, cross-cutting themes, recommendations

**Deep (research tree)**:
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

Spawn section-researcher agents in parallel batches (max 5 per batch):

**Basic/Detailed mode**:
```
For each sub-question entity in 00-sub-questions/data/:
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    LANGUAGE=<language>,
    run_in_background=true)
```

**Deep mode**:
```
For each leaf sub-question in 00-sub-questions/data/:
  Task(deep-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    LANGUAGE=<language>,
    DEPTH=2,
    run_in_background=true)
```

Batch in groups of 4-5 to respect concurrency limits. Wait for each batch before starting next.

After all researchers complete:
- Check return values for failures
- Update sub-question entity status to "researched" or "failed"
- Log results to `.logs/phase-2-research.jsonl`

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
  LANGUAGE=<language>)
```

Verify: draft written to `output/draft-v1.md`, reasonable word count.

### Phase 5: Claims-Verified Review Loop

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
