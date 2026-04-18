---
id: concept-claims-propagation
title: Claims propagation (auto-log, verify, cascade)
type: concept
tags: [cogni-claims, claims, propagation, source-lineage, cogni-research, cogni-portfolio, cogni-trends]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

Claims propagation is the cross-plugin pattern that turns sourced assertions into a verifiable, self-correcting knowledge graph. Any data-layer plugin that produces claims (cogni-research, cogni-portfolio, cogni-trends) writes them to cogni-claims; verification corrections cascade back to entity files and downstream consumers.

## The four steps

1. **Auto-log on creation.** Research agents append claim records to `cogni-claims/claims.json` as they generate sourced assertions. Each record carries `entity_ref` provenance (the plugin entity the claim came from), `source_url`, and the asserted text. cogni-portfolio uses `scripts/append-claim.sh` for this; cogni-research's report agents auto-log via the same pattern.
2. **Verify in cogni-claims.** The `cogni-claims:claims` skill walks unverified claims, groups them by source URL, and dispatches one [[agent-cogni-claims-claim-verifier]] per URL — that agent does the WebFetch and detects deviations between each claim and what the source actually says. Verdicts: verified / deviated / resolved (see [[concept-claim-lifecycle]]).
3. **Propagate corrections back.** When a claim is marked deviated and the user resolves it (by accepting a corrected version or removing the assertion), the correction propagates to the originating entity file via the `entity_ref` pointer.
4. **Cascade staleness downstream.** Entities that depend on the corrected entity get marked stale via `propagated_at` timestamps. Downstream skills (e.g., proposition-generator reading a corrected feature) detect stale dependencies and either refresh or warn.

## Boundary discipline

cogni-claims owns verification logic but never generates claims itself — that boundary is enforced by design. Data-layer plugins generate; cogni-claims verifies. This is [[concept-data-isolation]] applied to the verification domain.

## Where it shows up most

- cogni-research's `verify-report` skill is the heaviest user — every ReportClaim in a research draft becomes a claim record.
- cogni-portfolio's `portfolio-verify` skill verifies web-sourced claims in proposition entities.
- cogni-trends's `trend-report-revisor` reads claim verdicts to decide which evidence to replace.

## Wiki integration

cogni-claims uses UUID-v4 slugs (`claim-550e8400-...`) rather than name-derived slugs because claims have no natural name — their identifier is their identity. See [[concept-slug-based-lookups]] for the broader convention.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md) (see also [er-diagram.md](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md))
