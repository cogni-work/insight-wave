# Claims Integration Reference

## cogni-claims Submission Protocol

### Step 1: Extract Claims (claim-extractor agent)

The claim-extractor reads the draft and produces report-claim entities in `03-report-claims/data/`.
Each entity has: `statement`, `source_url`, `source_title`, `draft_version`, `section`.

### Step 2: Build Submission Batch

Collect report-claim entities and format for cogni-claims:

```json
{
  "claims": [
    {
      "statement": "NIST finalized three post-quantum encryption standards in August 2024",
      "source_url": "https://www.nist.gov/...",
      "source_title": "NIST Releases First 3 Finalized Post-Quantum Encryption Standards"
    }
  ],
  "submitted_by": "cogni-gpt-researcher"
}
```

### Step 3: Submit via Skill Tool

```
Skill(cogni-claims:claims,
  mode=submit,
  working_dir=<project_path>,
  claims=<batch JSON>,
  submitted_by="cogni-gpt-researcher")
```

This creates `cogni-claims/claims.json` in the project directory with ClaimRecord entries.

### Step 4: Verify via Skill Tool

```
Skill(cogni-claims:claims,
  mode=verify,
  working_dir=<project_path>)
```

This dispatches claim-verifier agents (one per unique source URL) that:
1. Fetch each source via WebFetch
2. Compare claims against source content
3. Detect deviations: misquotation, unsupported_conclusion, selective_omission, data_staleness, source_contradiction
4. Assign severity: low, medium, high, critical
5. Update claims.json with verification results

### Step 5: Update Report-Claim Entities

After verification, read `cogni-claims/claims.json` and update report-claim entities:
- Set `verification_status` to verified/deviated/source_unavailable
- Set `deviation_type` and `deviation_severity` if deviated
- Set `claims_submission_id` to the cogni-claims claim ID

### Step 6: Pass to Reviewer

The reviewer agent reads:
- The draft
- Updated report-claim entities with verification status
- `cogni-claims/claims.json` for full deviation details

## Graceful Degradation

If cogni-claims is not installed or the Skill call fails:
1. Skip steps 2-5
2. Run reviewer with structural criteria only (no claims data)
3. Log a warning: "cogni-claims unavailable — running structural review only"
4. Reduce max review iterations from 3 to 2

## Claim Re-extraction on Revision

When the revisor produces a new draft version:
1. Clear `03-report-claims/data/` (delete existing claim entities)
2. Re-run claim-extractor on the new draft
3. Re-submit to cogni-claims (fresh batch — revised claims may differ)
4. Re-verify

This ensures the review loop operates on the current draft's actual claims, not stale ones.
