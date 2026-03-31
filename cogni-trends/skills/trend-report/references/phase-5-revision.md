# Phase 5: Post-Verification Revision

Applies claims resolution decisions back to the report. Dispatches the `trend-report-revisor` agent to surgically correct the report body and rebuild the claims registry table.

This phase handles two entry paths:
1. **Inline flow** — user verified claims during trend-report Phase 3 and resolved deviations immediately
2. **Deferred flow** — user verified and resolved claims later via `/claims` and returns via `/trends-resume`

---

## Step 5.0: Entry Gate

Check whether revision is needed:

1. Look for cogni-claims workspace at `{PROJECT_PATH}/cogni-claims/claims.json`
2. If not found, check `.metadata/trend-report-verification.json` for verdict
3. Parse claims.json for resolved claims with `verification.resolution: remove` or `verification.resolution: correct`

```python
# Pseudo-logic for entry gate
resolved_claims = [c for c in claims if c["status"] == "resolved"]
needs_revision = any(c["verification"]["resolution"] in ("remove", "correct") for c in resolved_claims)
```

If no claims need revision (all verified clean, or all disputes/accepts), skip to Step 5.4 finalization.

## Step 5.1: Summarize Revision Scope

Present a summary to the user before dispatching the revisor:

```yaml
AskUserQuestion:
  question: "{remove_count} claims to remove, {correct_count} to correct. Revise the report now?"
  header: "Report Revision"
  options:
    - label: "Revise now (Recommended)"
      description: "Apply corrections, remove unverifiable claims, find replacement evidence"
    - label: "Skip revision"
      description: "Keep report as-is — claims table will not reflect verification results"
```

Show the user which claims will be removed and which corrected, with one-line summaries.

## Step 5.2: Dispatch Revisor

Launch the `trend-report-revisor` agent:

```yaml
Agent:
  type: trend-report-revisor
  prompt: |
    PROJECT_PATH={PROJECT_PATH}
    REPORT_PATH={PROJECT_PATH}/tips-trend-report.md
    CLAIMS_PATH={PROJECT_PATH}/cogni-claims/claims.json
    NEW_VERSION=2
    OUTPUT_LANGUAGE={LANGUAGE}
    MARKET={MARKET}
```

Before dispatching, create a backup:
```bash
cp {PROJECT_PATH}/tips-trend-report.md {PROJECT_PATH}/.tips-trend-report-pre-revision.md
```

## Step 5.3: Validate Output

When the revisor returns, verify the revised report:

1. **Heading preservation** — H2 and H3 heading count matches original (investment theme structure intact)
2. **Claims table integrity** — row count equals original minus removed claims, rows numbered sequentially
3. **No strikethrough** — grep for `~~` in the revised report; fail if found
4. **No dead references** — for each removed claim, verify its data point does not appear in the report body
5. **YAML frontmatter** — verify `revision` block was added with correct counts
6. **Citation count** — at least (original citations - removed claims) citations remain

If validation fails, report the specific failure to the user rather than re-running the revisor.

## Step 5.4: Finalize

1. Copy the accepted revision to the canonical filename:
   ```bash
   cp {PROJECT_PATH}/tips-trend-report-v2.md {PROJECT_PATH}/tips-trend-report.md
   ```

2. Update `.metadata/trend-scout-output.json`:
   ```json
   {
     "trend_report_revised": true,
     "trend_report_revision_version": 2,
     "trend_report_revision_at": "ISO-8601",
     "trend_report_claims_removed": N,
     "trend_report_claims_corrected": N
   }
   ```

3. Update `tips-trend-report-claims.json` to match the revised claims registry

4. Display completion summary:
   - Claims removed: N
   - Claims corrected: N
   - Replacement evidence added: N
   - Remaining claims: N
   - Report version: v2

5. Recommend `/trends-resume` for downstream options (visualization, polish, catalog)
