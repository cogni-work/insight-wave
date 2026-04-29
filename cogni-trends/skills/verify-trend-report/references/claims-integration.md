# Claims Integration with cogni-claims

How `verify-trend-report` Phase 2 submits and verifies claims via the `cogni-claims:claims` skill. Adapted from the legacy `trend-report/references/phase-3-claim-verification.md` so the verification protocol stays unchanged when the user moves from the embedded flow to the dedicated skill.

---

## Step 1: Confirm the user wants to verify

Before invoking `cogni-claims`, confirm via `AskUserQuestion` (the user invoked `/verify-trend-report` deliberately, so this is a yes/no rather than a long menu):

```yaml
AskUserQuestion:
  question: "{total_claims} quantitative claims are registered. Run automated verification against source URLs now?"
  header: "Verify"
  options:
    - label: "Verify now (Recommended)"
      description: "Submit each claim to cogni-claims, fetch source URLs, detect deviations"
    - label: "Skip verification"
      description: "Run structural review only; no source comparison"
```

If the user picks **Skip verification**, log a note and proceed directly to Phase 4 with `structural_review_only=true`.

## Step 2: Invoke cogni-claims

```yaml
Skill:
  skill: "cogni-claims:claims"
  args: "--file-path {PROJECT_PATH}/tips-trend-report.md --claims-file {PROJECT_PATH}/tips-trend-report-claims.json --verdict-mode --language {OUTPUT_LANGUAGE}"
```

`cogni-claims` reads the claims registry, dispatches `claim-verifier` agents (one per unique source URL), fetches each source, and detects 5 deviation types (`misquotation`, `unsupported_conclusion`, `selective_omission`, `data_staleness`, `source_contradiction`) with severity per claim. Results land in `{PROJECT_PATH}/cogni-claims/claims.json`.

If the plugin is not installed, log a warning and skip — do not halt. The skill continues in structural-review-only mode.

## Step 3: Persist verdict

Parse the QualityGateResult and write `{PROJECT_PATH}/.metadata/trend-report-verification.json`:

```json
{
  "verified_at": "ISO-8601",
  "verdict": "PASS|REVIEW|FAIL",
  "total_claims": N,
  "verified": N,
  "passed": N,
  "failed": N,
  "review": N,
  "verified_by": "verify-trend-report"
}
```

The `verified_by` field distinguishes this skill from the legacy embedded `trend-report` Phase 3, which wrote `verified_by: "trend-report"`. `trends-resume` and `project-status.sh` treat both values as "verification ran".

## Step 4: Hand off to Phase 3 (interactive review)

Phase 3 of `verify-trend-report/SKILL.md` reads `cogni-claims/claims.json` directly to surface deviations to the user. No additional translation step is needed here — `cogni-claims` already writes the canonical schema.

## Graceful degradation

When `cogni-claims` is unavailable:

1. Phase 2 logs a warning and writes a partial verification record:
   ```json
   {
     "verified_at": "ISO-8601",
     "verdict": "SKIPPED",
     "reason": "cogni-claims not installed",
     "verified_by": "verify-trend-report"
   }
   ```
2. Phase 3 is skipped entirely — there are no per-claim deviations to review.
3. Phase 4 runs reviewer-only (no revisor), with iteration cap reduced to 1 (the reviewer's structural verdict alone is enough — without claims data, a second pass adds no new signal).
4. Phase 5 finalization message includes a recommendation to install `cogni-claims` for full verification.
