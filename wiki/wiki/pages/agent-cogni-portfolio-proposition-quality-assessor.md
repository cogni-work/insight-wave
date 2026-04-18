---
id: agent-cogni-portfolio-proposition-quality-assessor
title: "cogni-portfolio:proposition-quality-assessor (agent)"
type: entity
tags: [cogni-portfolio, portfolio, agent, haiku]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/agents/proposition-quality-assessor.md
status: stable
related: [plugin-cogni-portfolio, concept-agent-model-strategy, skill-cogni-portfolio-propositions]
---

> One of the agents inside [[plugin-cogni-portfolio]]. Model tier: **haiku** — see [[concept-agent-model-strategy]].

Assess DOES/MEANS messaging quality in propositions — works in any language. Called by [[skill-cogni-portfolio-propositions]]'s post-check across 12 dimensions: 7 for DOES (including the load-bearing **need correctness** that catches provider-lens contamination) and 5 for MEANS (outcome specificity, escalation, quantification, emotional resonance, conciseness). A "fail" verdict blocks downstream flow until the proposition is rewritten.

**Source**: agent definition
([proposition-quality-assessor.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/agents/proposition-quality-assessor.md))
