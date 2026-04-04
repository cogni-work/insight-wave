---
name: portfolio-verify
description: |
  Verify web-sourced claims in portfolio entities against their cited sources.
  Use whenever the user mentions verify, fact-check, check claims, claim status,
  review deviations, source check, "are these numbers right", "check my sources",
  or wants to validate portfolio data before generating deliverables — even if they
  don't say "verify" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Skill
---

# Portfolio Claim Verification

Verify web-sourced claims submitted by portfolio research agents against their cited sources. This is the quality gate between enrichment and communicate.

## Core Concept

Research agents (market-researcher, competitor-researcher, proposition-generator) pull data from the web — market sizes, growth rates, competitor claims, industry benchmarks. Each web-sourced fact is logged as a claim in `cogni-claims/claims.json` with its source URL. But web data goes stale, gets misread, or comes from unreliable sources.

Verification catches these problems before they propagate into deliverables. The claim-verifier agent revisits each source URL, compares what was claimed against what the source actually says, and flags deviations by severity. A "TAM of $4.2B" that the source actually quotes as $2.4B is a critical deviation — it would undermine every proposal built on that number.

This matters because downstream outputs (synthesis, exports, proposals) inherit whatever the portfolio contains. Catching a wrong number here is cheap; catching it in a client presentation is expensive. The verification gate gives the user a clear picture of data quality and the chance to correct problems while they're easy to fix.

## Prerequisites

This skill requires the `cogni-claims` plugin. If the `cogni-claims:claims` skill is not available, inform the user and provide installation guidance.

If no `cogni-claims/` directory exists in the project, no claims have been submitted yet. Research agents submit claims automatically when web search is used during market research, competitor research, and proposition generation. Suggest running those skills with web research enabled first.

## Workflow

### 0. Check Source Registry for Stale URLs

Before reviewing claims, check if the source registry has information about URL freshness. If `source-registry.json` exists, read it and identify any URL sources with `status` of `stale` or `unreachable`. If found, present them as high-priority verification targets:

> "N URL sources in the registry are marked as stale or unreachable. Claims citing these sources should be verified first, as the source content may have changed since the claims were submitted."

List the affected URLs and which claims cite them.

### 1. Show Claim Summary

Read `cogni-claims/claims.json` and present the current state:

```
Claims Summary:
- Unverified: N
- Verified: N
- Deviated: N (X critical, Y high, Z medium, W low)
- Source unavailable: N
- Resolved: N
Total: N claims from K unique sources
```

Also show breakdown by submitter (market-researcher, competitor-researcher, proposition-generator) so the user knows where claims originate.

### 2. Review with User

Before running verification, present the summary and ask:

- How many unverified claims exist and from which agents?
- Want to verify all at once, or focus on a specific submitter or entity?
- Any claims the user already knows are correct and wants to skip?

This step matters because verification hits external URLs — the user should understand the scope before proceeding.

### 3. Run Verification

When the user confirms, invoke the `cogni-claims:claims` skill with mode `verify`:

```
Use the cogni-claims:claims skill to verify all unverified claims.
Working directory: <project-dir>
```

The claims skill handles grouping by URL, parallel agent dispatch, and result collection.

### 4. Review Results

After verification completes, show the updated summary. If deviations were found:

- List claims with `high` or `critical` severity deviations
- For each, show: claim statement, deviation type, severity, and the source excerpt that contradicts it
- Suggest using `cogni-claims:claims` skill with mode `inspect` for full evidence on any specific claim

Ask explicitly:
- Any deviations that surprise you?
- Want to inspect specific claims in detail?
- Ready to resolve, or want to review more?

### 5. Resolution Guidance

If deviated claims exist, offer resolution options:

1. **Review and resolve individually** — invoke `cogni-claims:claims` with mode `resolve` for each
2. **Show dashboard** — invoke `cogni-claims:claims` with mode `dashboard` for full overview
3. **Proceed to communicate anyway** — warn that unresolved deviations will be flagged in output

Never auto-resolve deviations. The user must decide whether to correct the data, accept the deviation with justification, or flag it for later review. They know their domain best.

### 6. Communicate Gate

Present the verification status as a gate before generating deliverables:

```
Verification Gate:
- Verified: N claims (safe to use)
- Resolved: N claims (user-approved corrections)
- Deviated (unresolved): N claims (will be flagged in output)
- Unverified: N claims (will be flagged in output)

Recommendation: [Resolve remaining deviations / Ready for communicate]
```

If all claims are verified or resolved, confirm the portfolio is ready for communicate. If deviations remain, the user may still proceed — the communicate skill will mark unverified content so readers know which data points haven't been checked.

### 7. Update Source Registry

After verification completes, if `source-registry.json` exists, update URL source entries:

- For verified URLs: update `fingerprint.computed_at` and `last_checked` to today's date
- For unreachable URLs: set `status` to `"unreachable"`
- For URLs where the source content changed (verification found deviations): set `status` to `"stale"`

This keeps the source registry in sync with verification results so that `portfolio-resume` and `portfolio-lineage` can surface URL freshness alongside document freshness.

### 8. Propagate Corrections to Entity Files

After resolution, corrected claims need to flow back into the portfolio entity files that originally contained the wrong data. Without this step, a corrected market size stays wrong in `markets/*.json` and every proposition built on it inherits the error.

This step activates only when resolved claims exist with actions that require entity file changes (`corrected`, `discarded`, or `alternative_source`). If all resolved claims have action `disputed` or `accepted_override`, skip this step — those actions explicitly keep the original data.

**8a. Scan for propagable resolutions:**

Read `cogni-claims/claims.json` and filter for claims where:
- `status == "resolved"`
- `resolution.action` is `corrected`, `discarded`, or `alternative_source`
- `propagated_at` is null (not yet applied to entity files)

If none found, skip to the communicate gate summary.

**8b. Locate target entity files:**

For each claim, determine the target file:
- If `entity_ref` is present: use `entity_ref.file` and `entity_ref.field_path` directly
- If `entity_ref` is absent (legacy claims without provenance): run the find-text fallback:
  ```bash
  bash $CLAUDE_PLUGIN_ROOT/scripts/propagate-corrections.sh find-text "<project-dir>" "<original_statement>"
  ```
  - If exactly one match: associate the claim with that file and field path
  - If multiple matches: list all matches and ask the user which to update
  - If no matches: report the claim as "not found in entity files" — the text may have been manually edited since submission

**8c. Present propagation plan:**

Show the user what will change, grouped by entity file. This is a confirmation gate — corrections touch portfolio data, so the user must approve:

```
Propagation Plan — N corrections across M entity files:

markets/mid-market-saas-dach.json:
  [corrected] tam.value: EUR 789.9 Mrd. → EUR 68.25 Mrd. (claim-abc123)
  [corrected] tam.description: Updated source text (claim-abc124)

customers/mid-market-saas-dach.json:
  [corrected] named_customers[?name=="Sybit"].employees: 350 → 153 (claim-def456)
  [discarded] named_customers[?name=="Source Global"].positioning: Remove (claim-ghi789)

Proceed with all corrections? [yes / inspect individual / skip]
```

**8d. Apply corrections:**

After user confirmation, apply each correction using the propagation script:

- **corrected**: Replace the value at the target field path
  ```bash
  bash $CLAUDE_PLUGIN_ROOT/scripts/propagate-corrections.sh apply "<project-dir>" "<entity-file>" "<field-path>" "<corrected-value>"
  ```

- **discarded**: Remove the data point from the entity file
  ```bash
  bash $CLAUDE_PLUGIN_ROOT/scripts/propagate-corrections.sh remove "<project-dir>" "<entity-file>" "<field-path>"
  ```

- **alternative_source**: Update the source URL on the entity
  ```bash
  bash $CLAUDE_PLUGIN_ROOT/scripts/propagate-corrections.sh update-source "<project-dir>" "<entity-file>" "<field-path>" "<new-url>" "<new-title>"
  ```

For claims where `entity_ref.field_path` points to a numeric field but the `corrected_statement` is prose, extract the numeric value from the corrected statement and apply it to the value field, then apply the full corrected statement to the description field. Example: claim corrects "EUR 51.8 Mrd. Consulting 2025" to "EUR 49.0 Mrd. Consulting 2025" → update both `tam.value` (49000000000) and `tam.description`.

**8e. Mark as propagated:**

For each successfully applied correction, update `cogni-claims/claims.json`:
- Set `propagated_at` to the current ISO 8601 timestamp
- Write a `propagated` event to `cogni-claims/history/{claim-id}.json`

This prevents double-propagation if portfolio-verify is run again.

**8f. Cascade staleness to downstream entities:**

Corrections to upstream entities make downstream entities stale — their content was generated from data that has now changed. Determine the cascade:

- **Market corrected** → all propositions referencing that market slug become stale. Find them: `propositions/*--{market-slug}.json`
- **Proposition corrected** → the solution for that proposition becomes stale: `solutions/{same-slug}.json`
- **Customer corrected** → no cascade (customers are leaf entities in the dependency chain)
- **Competitor corrected** → no cascade (competitors are leaf entities)

For each stale entity, set `"lineage_status": "stale"` on the entity JSON (add the field if absent). This integrates with the existing `portfolio-lineage` refresh system.

Present the cascade:
```
Staleness cascade:
  markets/mid-market-saas-dach.json was corrected
    → 3 propositions marked stale
    → 2 solutions marked stale (downstream of stale propositions)

Run portfolio-lineage in refresh mode to regenerate stale entities.
```

**8g. Report summary:**

```
Propagation complete:
  N entity files updated
  N claims marked as propagated
  N downstream entities marked stale
  N claims could not be propagated (no entity_ref, no text match)

Next steps:
  - Run portfolio-lineage refresh to regenerate stale propositions/solutions
  - Or proceed to portfolio-communicate (stale entities will be flagged)
```

## Important Notes

- This skill orchestrates; `cogni-claims:claims` does the actual verification work
- Claims without web sources (internal estimates) are not submitted and do not need verification
- Re-running verification on already-verified claims is safe (re-checks the source)
- The `cogni-claims/` directory lives inside the portfolio project directory (managed by the cogni-claims plugin)
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
