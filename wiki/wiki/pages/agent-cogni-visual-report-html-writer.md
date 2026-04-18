---
id: agent-cogni-visual-report-html-writer
title: "cogni-visual:report-html-writer (agent)"
type: entity
tags: [cogni-visual, visual, agent, opus]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-visual/agents/report-html-writer.md
status: stable
related: [plugin-cogni-visual, concept-agent-model-strategy]
---

> One of the agents inside [[plugin-cogni-visual]]. Model tier: **opus** — see [[concept-agent-model-strategy]].

Write a complete self-contained scroll-layout HTML file from a markdown report, enrichment plan, and design variables. Produces themed HTML with Chart.js data visualizations, inline SVG concept diagrams, sidebar navigation, and full prose preservation. Worker agent dispatched by enrich-report Phase 4a — receives serialized inputs, produces the scroll HTML, runs the Python post-processor for infographic injection and content validation, and returns JSON metrics.

**Source**: agent definition
([report-html-writer.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-visual/agents/report-html-writer.md))
