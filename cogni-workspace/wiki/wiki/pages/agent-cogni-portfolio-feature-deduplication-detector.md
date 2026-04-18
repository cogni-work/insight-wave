---
id: agent-cogni-portfolio-feature-deduplication-detector
title: "cogni-portfolio:feature-deduplication-detector (agent)"
type: entity
tags: [cogni-portfolio, portfolio, agent, haiku]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/agents/feature-deduplication-detector.md
status: stable
related: [plugin-cogni-portfolio, concept-agent-model-strategy]
---

> One of the agents inside [[plugin-cogni-portfolio]]. Model tier: **haiku** — see [[concept-agent-model-strategy]].

Detect set-wide duplicate features within a single product using lexical and semantic similarity — works in any language. Two modes — (1) existing-only: cluster features in `features/` for the Quality Completion Gate (Layer 0); (2) candidate mode: also pool in a staging file of freshly discovered candidates from portfolio-scan so the calling skill can merge new evidence into stable existing features instead of creating duplicates.

**Source**: agent definition
([feature-deduplication-detector.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/agents/feature-deduplication-detector.md))
