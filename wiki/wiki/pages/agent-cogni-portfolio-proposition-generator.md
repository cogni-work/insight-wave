---
id: agent-cogni-portfolio-proposition-generator
title: "cogni-portfolio:proposition-generator (agent)"
type: entity
tags: [cogni-portfolio, portfolio, agent, inherit]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/agents/proposition-generator.md
status: stable
related: [plugin-cogni-portfolio, concept-agent-model-strategy, skill-cogni-portfolio-propositions]
---

> One of the agents inside [[plugin-cogni-portfolio]]. Model tier: **inherit** — see [[concept-agent-model-strategy]].

Generate IS/DOES/MEANS messaging for a single Feature x Market combination. Dispatched in parallel by [[skill-cogni-portfolio-propositions]] during batch generation — one agent per Feature × Market pair, with the customer profile passed in when `customers/{market-slug}.json` exists for buyer-grounded messaging.

**Source**: agent definition
([proposition-generator.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/agents/proposition-generator.md))
