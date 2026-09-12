---
id: skill-cogni-trends-trend-report
title: "cogni-trends:trend-report"
type: entity
tags: [cogni-trends, trends, tips, skill, trend-report]
created: 2026-04-17
updated: 2026-04-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-trends/skills/trend-report/SKILL.md
status: stable
related: [plugin-cogni-trends]
---

> One of the skills inside [[plugin-cogni-trends]].

Generate a strategic TIPS trend report organized around investment themes (Handlungsfelder) with inline citations and verifiable claims. The user selects a report-level narrative arc from the 7 report-level story arcs bundled with cogni-workspace's `text-to-narrative` skill (corporate-visions, technology-futures, competitive-intelligence, strategic-foresight, industry-transformation, trend-panorama, theme-thesis) — the arc frames the executive summary, bridge paragraphs between themes, and a synthesis closing section that bind investment themes into one cohesive narrative.

**Source**: `cogni-trends:trend-report`
([SKILL.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-trends/skills/trend-report/SKILL.md))

Post-generation claim verification is handed to `cogni-workspace:claims` in submit mode.
