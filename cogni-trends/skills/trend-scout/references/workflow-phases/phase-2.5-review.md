# Phase 2.5: Candidate Review (Stakeholder Assessment)

This phase evaluates the 60 generated candidates as a pool before writing the final trend list. It catches set-level issues that per-candidate generation validation cannot see: duplicates across dimensions, subsector-generic filler, weak cross-dimension clustering, and scoring integrity violations.

The review follows the same 3-perspective stakeholder pattern used by cogni-portfolio's feature-review-assessor and proposition-review-assessor.

## Entry Gate

Before starting Phase 2.5, verify:

1. Phase 2 completed — `trend-generator` agent returned `ok: true`
2. `.logs/trend-generator-candidates.json` exists with 60 candidates
3. `.logs/candidates-compact.json` prepared by `prepare-phase3-data.sh`

If any check fails, halt and report the specific failure to the user.

## Step 2.5.1: Invoke Reviewer (Iteration 1)

Delegate to the `trend-candidate-reviewer` agent:

```yaml
Task:
  subagent_type: "cogni-trends:trend-candidate-reviewer"
  description: "Review 60 trend candidates (iteration 1)"
  prompt: |
    Evaluate trend candidate pool for trend-scout Phase 2.5.

    PROJECT_PATH: {{PROJECT_PATH}}
    REVIEW_ITERATION: 1
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    RESEARCH_TOPIC: {{RESEARCH_TOPIC}}
    PROJECT_LANGUAGE: {{PROJECT_LANGUAGE}}
```

## Step 2.5.2: Process Verdict

The reviewer returns compact JSON with verdict, scores, and repair guidance:

```json
{
  "ok": true,
  "verdict": "accept|revise|reject",
  "score": 82,
  "perspectives": {
    "strategic_foresight_analyst": 85,
    "industry_domain_expert": 78,
    "downstream_pipeline_consumer": 83
  },
  "set_level_issues": 1,
  "cells_to_regenerate": 0,
  "candidates_to_replace": 2,
  "scoring_fixes": 1,
  "iteration": 1,
  "verdict_path": ".metadata/candidate-review-verdicts/v1.json"
}
```

**Decision logic:**

```
if verdict == "accept":
  Log acceptance, proceed to Phase 3
elif verdict == "reject":
  Log rejection, re-invoke trend-generator with full regeneration
  (this is attempt 1 of max 2; after regeneration, re-review as iteration 2)
elif verdict == "revise":
  Proceed to Step 2.5.3 (selective repair)
```

## Step 2.5.3: Selective Repair

Read the full verdict from `{PROJECT_PATH}/.metadata/candidate-review-verdicts/v{N}.json` to get detailed `revision_guidance`. Execute three types of repair:

### A. Cell Regeneration (~5K tokens per cell)

For cells flagged as coverage blind spots, re-invoke the `trend-generator` with narrowed scope:

```yaml
Task:
  subagent_type: "cogni-trends:trend-generator"
  description: "Regenerate cell {{DIMENSION}}/{{HORIZON}}"
  prompt: |
    Execute SELECTIVE cell regeneration for trend-scout Phase 2.5 repair.

    SCOPE: single_cell
    PROJECT_PATH: {{PROJECT_PATH}}
    TARGET_DIMENSION: {{DIMENSION}}
    TARGET_HORIZON: {{HORIZON}}
    INDUSTRY_EN: {{INDUSTRY_EN}}
    INDUSTRY_DE: {{INDUSTRY_DE}}
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    RESEARCH_TOPIC: {{RESEARCH_TOPIC}}
    PROJECT_LANGUAGE: {{PROJECT_LANGUAGE}}
    WEB_RESEARCH_AVAILABLE: {{WEB_RESEARCH_AVAILABLE}}
    AVOID_THEMES: {{comma-separated list of themes to avoid from reviewer feedback}}
    REQUIRED_SUBCATEGORY_SPREAD: true

    Read the review verdict at {{PROJECT_PATH}}/.metadata/candidate-review-verdicts/v{{N}}.json
    for specific guidance on what this cell's coverage blind spot is and what diversity is needed.

    Generate 5 replacement candidates for this single cell. Write results to
    {{PROJECT_PATH}}/.logs/trend-generator-candidates.json replacing the existing
    entries for this cell (dimension + horizon match). Preserve all other candidates.
```

### B. Candidate Replacement (~2K tokens per candidate)

For duplicates or individually weak candidates identified by index, invoke the generator for single-candidate replacement:

```yaml
Task:
  subagent_type: "cogni-trends:trend-generator"
  description: "Replace candidate #{{INDEX}}"
  prompt: |
    Execute SINGLE CANDIDATE replacement for trend-scout Phase 2.5 repair.

    SCOPE: single_candidate
    PROJECT_PATH: {{PROJECT_PATH}}
    TARGET_DIMENSION: {{DIMENSION}}
    TARGET_HORIZON: {{HORIZON}}
    TARGET_SEQUENCE: {{SEQUENCE}}
    INDUSTRY_EN: {{INDUSTRY_EN}}
    INDUSTRY_DE: {{INDUSTRY_DE}}
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    RESEARCH_TOPIC: {{RESEARCH_TOPIC}}
    PROJECT_LANGUAGE: {{PROJECT_LANGUAGE}}
    WEB_RESEARCH_AVAILABLE: {{WEB_RESEARCH_AVAILABLE}}
    MUST_DIFFER_FROM: "{{name of the candidate this is replacing and why}}"

    Read the review verdict at {{PROJECT_PATH}}/.metadata/candidate-review-verdicts/v{{N}}.json
    for context on why this candidate was flagged.

    Generate 1 replacement candidate. Write to the candidates JSON, replacing the entry
    at the specified dimension/horizon/sequence position. Preserve all other candidates.
```

### C. Scoring Fixes (Inline, No Agent)

For mechanical score cap violations, apply fixes directly with jq:

```bash
# Fix training candidate score cap violation
jq '(.tips_candidates.items[{{INDEX}}].score) = {{CORRECTED_SCORE}}' \
  "${PROJECT_PATH}/.logs/trend-generator-candidates.json" > /tmp/fixed.json && \
  mv /tmp/fixed.json "${PROJECT_PATH}/.logs/trend-generator-candidates.json"
```

### Post-Repair Cleanup

After all repairs complete:

1. Regenerate compact format:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/prepare-phase3-data.sh" "${PROJECT_PATH}"
   ```
2. Update candidate counts if cells were regenerated

## Step 2.5.4: Re-Review (Iteration 2)

If the initial verdict was "revise" and repair was performed, re-invoke the reviewer:

```yaml
Task:
  subagent_type: "cogni-trends:trend-candidate-reviewer"
  description: "Re-review trend candidates (iteration 2)"
  prompt: |
    Evaluate trend candidate pool for trend-scout Phase 2.5 (post-repair review).

    PROJECT_PATH: {{PROJECT_PATH}}
    REVIEW_ITERATION: 2
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    RESEARCH_TOPIC: {{RESEARCH_TOPIC}}
    PROJECT_LANGUAGE: {{PROJECT_LANGUAGE}}
```

**After iteration 2:**

- If verdict is "accept": proceed to Phase 3
- If verdict is still "revise" or "reject": **force accept** with remaining issues logged. Proceed to Phase 3 but record `forced_accept: true` in execution metadata. Log a warning about the remaining issues.

Max 2 review iterations. Do not loop further.

## Exit Gate

Phase 2.5 is complete when:

1. `.metadata/candidate-review-verdicts/v{final}.json` written with verdict "accept" (clean or forced)
2. `.logs/trend-generator-candidates.json` reflects any repairs
3. `.logs/candidates-compact.json` regenerated after repairs

## Execution Metadata

After Phase 2.5 completes, update `{PROJECT_PATH}/.metadata/trend-scout-output.json` execution block. Two updates are required:

**1. Add `phase-2.5` to `phases_completed`:**

```bash
jq '.execution.phases_completed += ["phase-2.5"]' \
  "${PROJECT_PATH}/.metadata/trend-scout-output.json" > /tmp/updated.json && \
  mv /tmp/updated.json "${PROJECT_PATH}/.metadata/trend-scout-output.json"
```

**2. Add `candidate_review` metadata:**

```bash
jq '.execution.candidate_review = {
  "iterations": {{ITERATIONS}},
  "final_verdict": "{{VERDICT}}",
  "final_score": {{SCORE}},
  "cells_regenerated": {{CELLS}},
  "candidates_replaced": {{REPLACED}},
  "scoring_fixes_applied": {{FIXES}},
  "forced_accept": {{FORCED}}
}' "${PROJECT_PATH}/.metadata/trend-scout-output.json" > /tmp/updated.json && \
  mv /tmp/updated.json "${PROJECT_PATH}/.metadata/trend-scout-output.json"
```

Both updates are **mandatory** — downstream skills (value-modeler, trend-report) check `phases_completed` for `phase-2.5` and read `candidate_review.forced_accept` to apply extra scrutiny to force-accepted pools.
