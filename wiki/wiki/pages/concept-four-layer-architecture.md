---
id: concept-four-layer-architecture
title: Architectural groups (horizontal workspace, orchestration, data, output)
type: concept
tags: [architecture, layers, dependencies]
created: 2026-04-17
updated: 2026-08-13
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

The ecosystem (see [[ecosystem-overview]]) splits along one line: cogni-workspace is **horizontal** infrastructure, and the business plugins are **vertical**, each keeping its own project lifecycle. The dividing rule is not the `setup → resume → dashboard` arc itself but what it is *about*: a capability owning a **project lifecycle** — many projects, each with its own state, advancing across sessions — is a vertical business plugin. cogni-workspace runs the same shape, but over configuration rather than projects: one workspace, not a portfolio of them. Owning the shape does not make a plugin vertical; owning projects does. The vertical plugins are grouped below by the role they play — that grouping is descriptive, not a dependency ordering.

```
horizontal   cogni-workspace
─────────────────────────────────────────────────────────────────
vertical     Orchestration   cogni-consult
             Data            cogni-portfolio  cogni-trends
                             cogni-knowledge
             Output          cogni-sales      cogni-marketing
                             cogni-website
```

## The groups

- **Horizontal** (cogni-workspace) — shared infrastructure: themes, environment variables, Obsidian vault configuration, MCP server installation. Every plugin that produces visual HTML output reads theme files from cogni-workspace. No plugin writes to cogni-workspace except through `manage-themes` and `manage-workspace`. It also owns the cross-plugin claim-verification gate: verification state across all sourced assertions.
- **Data** — each plugin owns a specialized knowledge domain. cogni-portfolio (products, markets, propositions, competitors). cogni-trends (TIPS paths, solution templates, catalogs). cogni-knowledge (sub-questions, contexts, sources, claims).
- **Output** — cogni-sales, cogni-marketing, cogni-website. Transforms data-group content into deliverables (slides/HTML/infographics, sales pitches, marketing campaigns, customer websites). Consumes but does not produce data-group entities. Narrative shaping and prose polish belong to this group in function but ship as the `narrative` and `copywriter` skills of the horizontal cogni-workspace, not as plugins of their own.
- **Orchestration** (cogni-consult) — manages engagement state. Dispatches to data and output plugins as each action field's deliverables require, without producing content itself. See [[concept-orchestrator-pattern]].

## Why these groups

Substitutability is the point: a data-group plugin can be rebuilt without touching output plugins (they read entities; they don't depend on internal implementation), and output plugins can be added or replaced without touching data plugins. cogni-docs is a cross-cutting utility (documentation) that reads from every plugin and is read by none.

The grouping combines with [[concept-data-isolation]] (plugins don't share writes) and [[concept-progressive-disclosure]] (each phase loads only its slice) to make the ecosystem horizontally extensible.

## Plugins outside the groups

- **cogni-docs** — utility, generates documentation by reading every plugin's structure. Maintainer-side and not one of the 12 marketplace plugins; it ships separately.

These are tools that consume the model rather than participate in it.

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md)
