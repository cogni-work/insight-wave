---
id: plugin-cogni-claims
title: "cogni-claims (plugin)"
type: entity
tags: [cogni-claims, plugin, claims, verification, fact-checking]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-claims.md
status: stable
related: [concept-claims-propagation, concept-claim-lifecycle, agent-cogni-claims-claim-verifier, agent-cogni-claims-source-inspector]
---

> **Preview** (v0.10.1) — core skills defined but may change.

cogni-claims manages the full lifecycle of sourced-claim verification within an insight-wave workspace. When another plugin (cogni-research, cogni-trends, cogni-portfolio, cogni-sales) produces content that cites sources, cogni-claims is the layer that checks whether the sources actually say what the claims assert.

## Layer

[[concept-four-layer-architecture|Data layer]]. Terminal verification service — nothing depends on it for content; verified/resolved claims feed back into the editorial process.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-claims:claims` | Verification orchestrator — submit, verify, dashboard, inspect (cobrowse), resolve |
| `cogni-claims:claim-entity` | Cross-plugin data contract — defines `ClaimRecord`, `DeviationRecord`, `ResolutionRecord` schemas |

## How it works

Implements the [[concept-claim-lifecycle]] (`unverified → verified | deviated → resolved | source_unavailable`). Verification runs one [[agent-cogni-claims-claim-verifier]] per unique source URL — WebFetch-only, claims grouped by URL so each fetch covers many claims in one pass. When sources are unreachable, [[agent-cogni-claims-source-inspector]] opens them in the user's browser via `claude-in-chrome` so the user can compare claim to source visually — see [[concept-mcp-server-map]].

## Integration

Upstream submitters: cogni-research (after report generation), cogni-trends (after trend reports), cogni-portfolio (after proposition modeling), cogni-sales (after pitch creation), cogni-consulting (Define + Deliver phase gates). The full cross-plugin pattern is documented in [[concept-claims-propagation]].

## Maturity

Preview. Core skills are stable; the cobrowse mechanism may evolve. Known issue: Chrome native messaging host conflict between Claude Desktop and Claude Code — see the docs/known-issues.md registry.

**Source**: [cogni-claims README](https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-claims.md)
