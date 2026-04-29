# Structural Review + Revisor Loop

Phase 4 of `verify-trend-report` runs the cross-theme reviewer and, when needed, dispatches the revisor to apply claim corrections, remove unverifiable claims, and find replacement evidence. Consolidates content previously split across `trend-report/references/phase-2.5-structural-review.md` (review logic) and `trend-report/references/phase-5-revision.md` (revisor logic).

---

## Iteration cap

| Mode | Max iterations |
|------|----------------|
| Default (cogni-claims available) | 2 |
| Structural-review-only (cogni-claims unavailable OR user skipped Phase 2) | 1 |

The cap applies to the full review-revise pair: iteration 1 = first review, optional first revise; iteration 2 = re-review of the revised report, optional second revise.

## 4a — Review

Dispatch the existing `trend-report-reviewer` agent (no contract changes — same agent used by the legacy Phase 2.5):

```yaml
Task:
  subagent_type: "cogni-trends:trend-report-reviewer"
  description: "Structural review iteration {N}"
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    REPORT_PATH: {current_report_path}
    REVIEW_ITERATION: {N}
    OUTPUT_LANGUAGE: {OUTPUT_LANGUAGE}
```

The reviewer scores 5 dimensions (completeness, evidence density, source diversity, narrative coherence, actionability), writes `{PROJECT_PATH}/.metadata/review-verdicts/v{N}.json`, and returns:

- `verdict: "accept"` (composite ≥ 0.80) — proceed to Phase 5.
- `verdict: "revise"` with `revision_priorities[]` — proceed to 4b.

## 4b — Revise

Skip 4b when:
- The reviewer returned `accept`.
- No claims were flagged for fix/drop in Phase 3 AND the reviewer's `revision_priorities[]` is empty.
- Iteration is already at the cap (just re-review on the next pass and accept regardless).

Otherwise, create a backup and dispatch the revisor:

```bash
cp "{PROJECT_PATH}/tips-trend-report.md" "{PROJECT_PATH}/.tips-trend-report-pre-revision-v{N}.md"
```

```yaml
Task:
  subagent_type: "cogni-trends:trend-report-revisor"
  description: "Apply revision iteration {N}"
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    REPORT_PATH: {current_report_path}
    CLAIMS_PATH: {PROJECT_PATH}/cogni-claims/claims.json
    NEW_VERSION: {N+1}
    OUTPUT_LANGUAGE: {OUTPUT_LANGUAGE}
    MARKET: {MARKET}
```

The revisor surgically:
- Removes unverifiable claims from the report body and the claims-registry table (no strikethrough — clean removal).
- Corrects inaccurate claims with verified replacement text from `cogni-claims/claims.json` resolutions.
- Searches for replacement evidence via WebSearch when removals leave a gap in the argument.
- Renumbers the claims-registry table sequentially.
- Writes `{PROJECT_PATH}/tips-trend-report-v{N+1}.md`.

## 4c — Validate revisor output

Before promoting the revised file, verify:

| Check | Condition | On Failure |
|-------|-----------|------------|
| Heading preservation | H2/H3 count matches the input | Surface failure to user; do not auto-rerun |
| Claims-table integrity | Row count = original − removed; rows numbered sequentially | Surface failure |
| No strikethrough | `grep -F '~~'` in revised file returns 0 matches | Surface failure |
| No dead references | Removed claims' data points do not appear in body prose | Surface failure |
| YAML frontmatter | Frontmatter present with `revision` block | Surface failure |
| Citation count | `>= original_citations - removed_claims` | Surface failure |

The user can manually accept the v{N+1} file if validation surfaces a soft failure (e.g., one stale data reference). The backup at `.tips-trend-report-pre-revision-v{N}.md` is canonical for rollback.

## 4d — Iterate or accept

After 4b + 4c:

- Set `current_report_path = tips-trend-report-v{N+1}.md`.
- If iteration < cap: increment N and loop to 4a (re-review the revised file).
- Else: proceed to Phase 5 with `current_report_path` as final.

## Persistence per iteration

For audit and resumability:

- `{PROJECT_PATH}/.metadata/review-verdicts/v{N}.json` — reviewer output (one per iteration)
- `{PROJECT_PATH}/.tips-trend-report-pre-revision-v{N}.md` — pre-revision backup (one per iteration that ran the revisor)
- `{PROJECT_PATH}/tips-trend-report-v{N+1}.md` — revisor output (one per iteration that ran the revisor)

These files are read by Phase 0.5 resumability check on subsequent re-entries.
