---
name: research-report
description: |
  Generate a multi-agent research report using parallel web research with claims-verified
  review loops. Three modes: basic (fast single-pass), detailed (multi-section with outline),
  deep (recursive tree exploration). Integrates with cogni-claims for evidence-based quality gates.
  Use when the user asks to "research report", "investigate", "deep research", "write a report",
  "gpt-researcher", "multi-agent research", or requests comprehensive topic analysis with citations.
---

# Research Report Skill

## Quick Example

**User**: "Write a research report on quantum computing's impact on cryptography"

**Result**: A 3000-5000 word report with inline citations, produced via:
1. Topic decomposition into 3-5 sub-questions
2. Parallel web research (haiku agents, one per sub-question)
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
| **basic** | "research report on X" | 3-5 | Single-pass | Quick overview |
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

1. Determine workspace path (use current directory or ask user)
2. Detect report type from user request (basic/detailed/deep)
3. Initialize project:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/initialize-project.sh" \
     --topic "<user topic>" --type <basic|detailed|deep> \
     --workspace "<workspace path>"
   ```
4. Store returned `project_path` for all subsequent phases

### Phase 1: Sub-Question Generation

**Read**: `references/sub-question-generation.md` for decomposition patterns.

Generate sub-questions based on report type:

**Basic (3-5 sub-questions)**:
1. Decompose the topic into 3-5 orthogonal research questions
2. Each question should target a distinct aspect of the topic
3. Include: background/context, current state, key developments, implications/outlook

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

Spawn section-researcher agents in parallel batches (max 5 per batch):

**Basic/Detailed mode**:
```
For each sub-question entity in 00-sub-questions/data/:
  Task(section-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    run_in_background=true)
```

**Deep mode**:
```
For each leaf sub-question in 00-sub-questions/data/:
  Task(deep-researcher,
    SUB_QUESTION_PATH=<path>,
    PROJECT_PATH=<project_path>,
    DEPTH=2,
    run_in_background=true)
```

Batch in groups of 4-5 to respect concurrency limits. Wait for each batch before starting next.

After all researchers complete:
- Check return values for failures
- Update sub-question entity status to "researched" or "failed"
- Log results to `.logs/phase-2-research.jsonl`

### Phase 3: Context Aggregation

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
  REPORT_TYPE=<type>)
```

Verify: draft written to `output/draft-v1.md`, reasonable word count.

### Phase 5: Claims-Verified Review Loop

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
  REVIEW_ITERATION=N)
```

#### 5e: Revise (if verdict="revise" and iteration < 3)
```
Task(revisor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH="output/draft-v{N}.md",
  VERDICT_PATH=".metadata/review-verdicts/v{N}.json",
  NEW_DRAFT_VERSION=N+1)
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
