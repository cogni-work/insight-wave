---
id: concept-claim-lifecycle
title: Claim lifecycle (unverified → verified | deviated → resolved)
type: concept
tags: [cogni-claims, claims, lifecycle, verification]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

Claims in cogni-claims move through a three-state lifecycle.

```
unverified → verified (no deviation found)
          → deviated (source does not support claim)
               → resolved (user reviewed and acted on deviation)
```

## States

- **unverified** — the initial state when any data-layer plugin appends a claim record. The claim has source URL, claim text, and `entity_ref` provenance, but no verification has run.
- **verified** — `cogni-claims:claims` fetched the source, compared it to the claim text, and found no deviation. The claim text is supported by what the source actually says.
- **deviated** — verification found a mismatch: the source contradicts, weakens, or doesn't address the claim. The deviation record captures the gap.
- **resolved** — the user reviewed the deviation and acted: accepted a corrected version of the claim, removed the assertion, or marked the deviation as a non-issue (e.g., the source updated since the claim was written).

## What happens at each transition

The unverified → verified/deviated/source_unavailable transition is performed by [[agent-cogni-claims-claim-verifier]] dispatched by `cogni-claims:claims`. Deviated → resolved is a user action through the resolution dashboard. Once resolved, the [[concept-claims-propagation]] cascade fires: the originating entity file is updated, and downstream entities that referenced it get `propagated_at` timestamps so they can be re-checked.

## Why three states, not two

The deviated state matters because not every deviation warrants automatic correction. Some deviations are stylistic (the claim says "leading provider", the source says "top three"); some are factual but immaterial; some are the user's stronger reading of an ambiguous source. Holding deviations for human review preserves judgment.

## Slug discipline

Claim records use UUID-v4 slugs (`claim-550e8400-...`) — see [[concept-slug-based-lookups]]. Claims have no natural name, so their identifier is their identity.

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md)
