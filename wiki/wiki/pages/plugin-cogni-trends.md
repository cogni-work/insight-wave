---
id: plugin-cogni-trends
title: "cogni-trends (plugin)"
type: entity
tags: [cogni-trends, plugin, trends, tips, trend-scout, strategic-foresight, bilingual]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-trends/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-trends.md
status: stable
related: [concept-trends-portfolio-bridge, concept-multilingual-support]
---

> **Preview** (v0.4.5) — core skills defined but may change.

Strategic trend scouting and reporting pipeline. Combines the Smarter Service Trendradar (4-dimension structure) with the TIPS framework (Trends, Implications, Possibilities, Solutions). Multilingual trend scouting, investment theme modeling, evidence-backed CxO reports, and reusable industry catalogs.

## Layer

[[concept-four-layer-architecture|Data layer]]. Bidirectionally bridged with cogni-portfolio.

## Skills

| Skill | Purpose |
|-------|---------|
| `cogni-trends:trend-scout` | Interactive trend scouting workflow with industry selection, bilingual support (DE/EN), 4-dimension scoring |
| `cogni-trends:trend-report` | Generate strategic TIPS report organized around investment themes (Handlungsfelder), with inline citations and verifiable claims |
| `cogni-trends:value-modeler` | Build TIPS relationship networks and generate ranked Solution Templates from agreed trend candidates |
| `cogni-trends:trends-catalog` | Manage persistent industry catalogs that accumulate TIPS knowledge across pursuits |
| `cogni-trends:trends-dashboard` | Self-contained HTML dashboard showing the full TIPS project lifecycle |
| `cogni-trends:trends-resume` | Resume status — show progress and next phase |

## TIPS framework

- **Trends** — what's emerging in the market (signals)
- **Implications** — what those signals mean for the company
- **Possibilities** — what new offerings or pivots become viable
- **Solutions** — concrete solution templates (the bridge to cogni-portfolio)

## Multilingual scouting

Bilingual web research (DE/EN) by default. Per-market authority sources curated in `references/region-authority-sources.json` — see [[concept-multilingual-support]]. The `trend-web-researcher` agent runs research in both languages in parallel for European markets.

## Quality discipline

Trend candidates must come from web-sourced signals — never padded with LLM training knowledge. Headlines and "Bottom-Banners" follow strict discipline: banners must never compensate for weak action titles. Both rules are enforced by the trend-candidate-reviewer.

## Integration

Upstream: cogni-portfolio (`portfolio-context.json`). Downstream: cogni-portfolio (`portfolio-opportunities.json`, `tips-value-model.json`), cogni-marketing (TIPS strategic themes feeding GTM paths), cogni-workspace (auto-logged claims; trend-report arcs via its `text-to-narrative` skill). The bidirectional cogni-portfolio integration is documented in [[concept-trends-portfolio-bridge]].

**Source**: [cogni-trends README](https://github.com/cogni-work/insight-wave/blob/main/cogni-trends/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-trends.md)
