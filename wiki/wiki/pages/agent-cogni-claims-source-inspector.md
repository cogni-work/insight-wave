---
id: agent-cogni-claims-source-inspector
title: "cogni-claims:source-inspector (agent)"
type: entity
tags: [cogni-claims, claims, agent, sonnet]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/agents/source-inspector.md
status: stable
related: [plugin-cogni-claims, concept-agent-model-strategy, agent-cogni-claims-claim-verifier]
---

> One of the agents inside [[plugin-cogni-claims]]. Model tier: **sonnet** — see [[concept-agent-model-strategy]].

Fetch a source URL via claude-in-chrome, locate the relevant passage, and present evidence to the user. Pairs with [[agent-cogni-claims-claim-verifier]] as the cobrowse-recovery path: when WebFetch in claim-verifier fails (paywall, anti-bot, login wall), the claim is parked as `source_unavailable` and this agent picks it up via `/claims cobrowse` so a user can navigate the source interactively.

**Source**: agent definition
([source-inspector.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-claims/agents/source-inspector.md))
