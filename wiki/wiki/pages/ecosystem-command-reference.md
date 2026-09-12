---
id: ecosystem-command-reference
title: "Command reference: how each plugin is invoked"
type: summary
tags: [ecosystem, commands, skills, cheatsheet, quick-reference, invocation]
created: 2026-08-13
updated: 2026-08-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/ecosystem-overview.md
status: stable
related: [ecosystem-plugin-selection, ecosystem-overview, arch-plugin-anatomy]
---

The quick-reference answer to "what are the commands for cogni-X" — the cheatsheet, the tldr, the one-screen refresher for a plugin you have used before but cannot remember the exact invocation for. Read this alongside [[ecosystem-plugin-selection]], which answers *which* plugin rather than *how to call it*.

## Two invocation surfaces, and most plugins use only one

Skills are the primary surface across the ecosystem. A skill is invoked by name — `cogni-trends:trend-scout`, or simply by describing the task, since each skill's description carries its own trigger phrases. Slash commands are a thin optional wrapper that only some plugins ship.

Five of the eight plugins ship **no** commands directory at all: cogni-knowledge, cogni-consult, cogni-trends, cogni-portfolio and cogni-website are skill-invoked entirely. Expecting a slash command for those is the most common source of "the command does not exist" confusion. See [[arch-plugin-anatomy]] for how the two surfaces sit on disk.

## Slash commands, by plugin

| Plugin | Slash commands |
|---|---|
| cogni-workspace | `/claims`, `/troubleshoot`, `/enrich-report`, `/render-html-slides`, `/render-infographic`, `/render-infographic-editorial`, `/render-infographic-handdrawn`, `/review-brief`, `/narrative`, `/narrative-adapt`, `/copywrite`, `/review-doc` |
| cogni-marketing | `/abm`, `/campaign`, `/content-calendar`, `/content-strategy`, `/demand-gen`, `/lead-gen`, `/marketing-dashboard`, `/marketing-resume`, `/marketing-setup`, `/sales-enablement`, `/thought-leadership` |
| cogni-sales | `/why-change` |
| cogni-knowledge, cogni-consult, cogni-trends, cogni-portfolio, cogni-website | none — skill-invoked |

## Skills, by plugin

**cogni-knowledge** — `knowledge-setup`, `knowledge-plan`, `knowledge-curate`, `knowledge-fetch`, `knowledge-ingest`, `knowledge-ingest-source`, `knowledge-distill`, `knowledge-compose`, `knowledge-verify`, `knowledge-finalize`, `knowledge-run`, `knowledge-query`, `knowledge-refresh`, `knowledge-refresh-synthesis`, `knowledge-update`, `knowledge-index`, `knowledge-prefill`, `knowledge-lint`, `knowledge-health`, `knowledge-dashboard`, `knowledge-resume`

**cogni-consult** — `consult-setup`, `consult-scope`, `consult-action-fields`, `consult-design-thinking`, `consult-personas`, `consult-project-plan`, `consult-publish`, `consult-dashboard`, `consult-resume`

**cogni-workspace** — `manage-workspace`, `workspace-status`, `workspace-dashboard`, `pick-theme`, `manage-themes`, `manage-markets`, `audit-region-sources`, `install-mcp`, `claims`, `claim-entity`, `cogni-issues`, `story-to-slides`, `story-to-web`, `story-to-infographic`, `render-html-slides`, `enrich-report`, `review-brief`, `narrative`, `copywriter`, `copy-reader`, `copy-json`

**cogni-trends** — `trend-scout`, `trend-research`, `trend-synthesis`, `trend-booklet`, `value-modeler`, `verify-trend-report`, `trends-catalog`, `trends-dashboard`, `trends-resume`

**cogni-portfolio** — `portfolio-setup`, `portfolio-scan`, `portfolio-ingest`, `portfolio-taxonomy`, `products`, `features`, `markets`, `customers`, `propositions`, `solutions`, `packages`, `compete`, `portfolio-communicate`, `portfolio-consolidate`, `portfolio-architecture`, `portfolio-canvas`, `portfolio-verify`, `portfolio-lineage`, `portfolio-dashboard`, `portfolio-resume`, `trends-bridge`

**cogni-marketing** — `marketing-setup`, `content-strategy`, `content-calendar`, `campaign-builder`, `demand-generation`, `lead-generation`, `thought-leadership`, `sales-enablement`, `abm`, `marketing-dashboard`, `marketing-resume`

**cogni-sales** — `why-change`

**cogni-website** — `website-setup`, `website-plan`, `website-build`, `website-legal`, `website-preview`, `website-resume`


## Recurring naming patterns

Once the patterns are visible, most of this table stops needing lookup — see [[concept-naming-conventions]].

- **`*-setup`** — bootstrap a project for that plugin. Always the first call.
- **`*-resume`** — the re-entry point across sessions. Shows progress and recommends the next step; the right thing to run when you do not remember where you left off.
- **`*-dashboard`** — a self-contained HTML view of current state.
- **`*-verify` / `*-lint` / `*-health`** — quality gates over already-produced entities, not producers themselves.
- **`story-to-*`** — cogni-workspace's brief producers; **`render-*`** turns a brief into an artifact.

## Where to read more

Each plugin has a full guide at `docs/plugin-guide/<plugin>.md` covering every skill in depth. This page carries the invocation surface only.

**Source**: [ecosystem overview](https://github.com/cogni-work/insight-wave/blob/main/docs/ecosystem-overview.md)
