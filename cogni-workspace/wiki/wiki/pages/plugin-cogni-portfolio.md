---
id: plugin-cogni-portfolio
title: "cogni-portfolio (plugin)"
type: entity
tags: [cogni-portfolio, plugin, portfolio, propositions, fab, is-does-means, b2b]
created: 2026-04-17
updated: 2026-04-18
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-portfolio.md
status: stable
related: [concept-data-model-patterns, concept-quality-gates, concept-trends-portfolio-bridge, skill-cogni-portfolio-propositions]
---

> **Preview** (v0.9.8) — core skills defined but may change.

cogni-portfolio gives B2B companies a structured way to build market-specific messaging using the IS/DOES/MEANS (FAB) framework applied at the Feature × Market level. Same feature gets different DOES/MEANS messaging for enterprise vs. mid-market because stakes, vocabulary, and priorities differ.

## Layer

[[concept-four-layer-architecture|Data layer]]. The most central data plugin — feeds cogni-sales (Why Change), cogni-marketing (content), cogni-website (site), cogni-workspace (pitch arcs via its `text-to-narrative` skill), cogni-consult (action-field deliverables).

## Core data model

The Feature × Market join is the unit of work — see [[concept-data-model-patterns]]. [[skill-cogni-portfolio-propositions|Propositions]], solutions, competitors, and packages all live at this intersection. Slugs follow the double-dash convention (`feature--market`) — see [[concept-slug-based-lookups]].

Eight pluggable industry taxonomies (b2b-ict, b2b-saas, b2b-fintech, b2b-healthtech, b2b-martech, b2b-industrial-tech, b2b-professional-services, b2b-opensource) auto-classify features and markets.

## Skills (20)

- **Core entity model**: `products`, `features`, `markets`, `propositions`, `customers`, `solutions`, `packages`, `compete`
- **Setup & ingestion**: `portfolio-setup`, `portfolio-canvas` (Lean Canvas bootstrap), `portfolio-canvas-workspace`, `portfolio-ingest` (md/docx/pptx/xlsx/pdf), `portfolio-scan` (web discovery)
- **Quality & lineage**: `portfolio-verify` (via `cogni-workspace:claims`), `portfolio-lineage` (source drift cascade)
- **Visualization**: `portfolio-dashboard`, `portfolio-architecture` (Excalidraw)
- **Communication**: `portfolio-communicate` (audience-routed deliverables)
- **Cross-plugin**: `trends-bridge` (TIPS solution templates → portfolio features)
- **Resume**: `portfolio-resume`

## Quality gates

Three-layer pipeline ([[concept-quality-gates]]) blocks downstream generation. Features must pass quality assessment before propositions can be generated; propositions must pass stakeholder review before being included in deliverables.

## Integration

Upstream: cogni-trends (`portfolio-opportunities.json`, `tips-value-model.json`), document-skills (file readers). Downstream: cogni-workspace (auto-logged claims; pitch arcs via its `text-to-narrative` skill), cogni-sales, cogni-marketing, cogni-website. The bidirectional cogni-trends integration is the most complex single integration in the ecosystem — see [[concept-trends-portfolio-bridge]].

**Source**: [cogni-portfolio README](https://github.com/cogni-work/insight-wave/blob/main/cogni-portfolio/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-portfolio.md)
