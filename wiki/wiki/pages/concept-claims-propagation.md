---
id: concept-claims-propagation
title: Claims propagation (auto-log, verify, cascade)
type: concept
tags: [cogni-workspace, claims, propagation, source-lineage, cogni-knowledge, cogni-portfolio, cogni-trends]
created: 2026-04-17
updated: 2026-04-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

Claims propagation is the cross-plugin pattern that turns sourced assertions into a verifiable, self-correcting knowledge graph. Any data-layer plugin that produces claims (cogni-knowledge, cogni-portfolio, cogni-trends) writes them to the shared `cogni-claims/` claim store; verification corrections cascade back to entity files and downstream consumers.

## The four steps

1. **Auto-log on creation.** Research agents append claim records to `cogni-claims/claims.json` as they generate sourced assertions. Each record carries `entity_ref` provenance (the plugin entity the claim came from), `source_url`, and the asserted text. cogni-portfolio uses `scripts/append-claim.sh` for this; cogni-knowledge's ingest agents auto-log via the same pattern.
2. **Verify in cogni-workspace.** The `cogni-workspace:claims` skill walks unverified claims, groups them by source URL, and dispatches one `claim-verifier` agent per URL — that agent does the WebFetch and detects deviations between each claim and what the source actually says. Verdicts: verified / deviated / resolved (see [[concept-claim-lifecycle]]).
3. **Propagate corrections back.** When a claim is marked deviated and the user resolves it (by accepting a corrected version or removing the assertion), the correction propagates to the originating entity file via the `entity_ref` pointer.
4. **Cascade staleness downstream.** Entities that depend on the corrected entity get marked stale via `propagated_at` timestamps. Downstream skills (e.g., proposition-generator reading a corrected feature) detect stale dependencies and either refresh or warn.

## Boundary discipline

cogni-workspace owns verification logic but never generates claims itself — that boundary is enforced by design. Data-layer plugins generate; cogni-workspace verifies. This is [[concept-data-isolation]] applied to the verification domain.

## Where it shows up most

- cogni-knowledge scores a draft's citations against claims already on its wiki via `knowledge-verify`, which is a zero-network consistency check rather than live-source verification — so the heaviest users of this store are cogni-portfolio and cogni-trends.
- cogni-portfolio's `portfolio-verify` skill verifies web-sourced claims in proposition entities.
- cogni-trends's `trend-report-revisor` reads claim verdicts to decide which evidence to replace.

## Wiki integration

Claim records use UUID-v4 slugs (`claim-550e8400-...`) rather than name-derived slugs because claims have no natural name — their identifier is their identity. See [[concept-slug-based-lookups]] for the broader convention.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md) (see also [er-diagram.md](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md))

The `entity_ref` and `propagated_at` fields that make cascade propagation work ship as `cogni-workspace:claims` reference material.

The operational entry point for the propagation cycle is `cogni-workspace:claims`.
