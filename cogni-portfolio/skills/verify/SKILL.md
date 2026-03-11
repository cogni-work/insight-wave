---
name: verify
description: |
  Verify web-sourced claims in portfolio entities against their cited sources.
  Use whenever the user mentions verify, fact-check, check claims, claim status,
  review deviations, source check, "are these numbers right", "check my sources",
  or wants to validate portfolio data before synthesis — even if they don't say
  "verify" explicitly.
---

# Portfolio Claim Verification

Verify web-sourced claims submitted by portfolio research agents against their cited sources. This is the quality gate between enrichment and synthesis.

## Core Concept

Research agents (market-researcher, competitor-researcher, proposition-generator) pull data from the web — market sizes, growth rates, competitor claims, industry benchmarks. Each web-sourced fact is logged as a claim in `cogni-claims/claims.json` with its source URL. But web data goes stale, gets misread, or comes from unreliable sources.

Verification catches these problems before they propagate into deliverables. The claim-verifier agent revisits each source URL, compares what was claimed against what the source actually says, and flags deviations by severity. A "TAM of $4.2B" that the source actually quotes as $2.4B is a critical deviation — it would undermine every proposal built on that number.

This matters because downstream outputs (synthesis, exports, proposals) inherit whatever the portfolio contains. Catching a wrong number here is cheap; catching it in a client presentation is expensive. The verification gate gives the user a clear picture of data quality and the chance to correct problems while they're easy to fix.

## Prerequisites

This skill requires the `cogni-claims` plugin. If the `cogni-claims:claims` skill is not available, inform the user and provide installation guidance.

If no `cogni-claims/` directory exists in the project, no claims have been submitted yet. Research agents submit claims automatically when web search is used during market research, competitor research, and proposition generation. Suggest running those skills with web research enabled first.

## Workflow

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
3. **Proceed to synthesis anyway** — warn that unresolved deviations will be flagged in output

Never auto-resolve deviations. The user must decide whether to correct the data, accept the deviation with justification, or flag it for later review. They know their domain best.

### 6. Synthesis Gate

Present the verification status as a gate before synthesis:

```
Verification Gate:
- Verified: N claims (safe to use)
- Resolved: N claims (user-approved corrections)
- Deviated (unresolved): N claims (will be flagged in output)
- Unverified: N claims (will be flagged in output)

Recommendation: [Resolve remaining deviations / Ready for synthesis]
```

If all claims are verified or resolved, confirm the portfolio is ready for synthesis. If deviations remain, the user may still proceed — the synthesize and export skills will mark unverified content so readers know which data points haven't been checked.

## Important Notes

- This skill orchestrates; `cogni-claims:claims` does the actual verification work
- Claims without web sources (internal estimates) are not submitted and do not need verification
- Re-running verification on already-verified claims is safe (re-checks the source)
- The `cogni-claims/` directory lives inside the portfolio project directory (managed by the cogni-claims plugin)
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
