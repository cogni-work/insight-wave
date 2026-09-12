---
id: arch-er-diagram
title: Entity relationships and cross-plugin data flow (architecture)
type: summary
tags: [architecture, entities, data-flow, bridge-files]
created: 2026-04-17
updated: 2026-08-13
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md
status: stable
---

The cross-plugin entity model and how data flows between plugins. Every arrow is a read-only reference resolved at runtime — never a live connection or shared write path.

## Architectural groups

cogni-workspace is the horizontal layer owning shared workspace state; the business plugins are vertical, each keeping its own project lifecycle. The role groupings below are descriptive, not a dependency ordering. See [[concept-four-layer-architecture]] for the full mapping.

- **Horizontal** — cogni-workspace (themes, env vars, vault config)
- **Orchestration** — cogni-consult (engagement state, action-field dispatch)
- **Data** — cogni-portfolio, cogni-trends, cogni-knowledge (each owns a knowledge domain)
- **Output** — cogni-sales, cogni-marketing, cogni-website (transform data-layer content into deliverables)

## Entity types per plugin

Each data-layer plugin owns a specialized domain with its own persistent entities:

- cogni-portfolio: Product, Feature, Market, Proposition, Solution, Package, Competitor, Customer (JSON in project dir)
- cogni-trends: TipsProject, TrendCandidate, TrendReport, InvestmentTheme, SolutionTemplate, Catalog (JSON + YAML)
- cogni-knowledge: sub-questions in `plan.json`, source / concept / question pages under `wiki/`, `pre_extracted_claims:` frontmatter, `citation-manifest.json` (markdown with YAML frontmatter, Obsidian-browsable)
- cogni-workspace: ClaimRecord, DeviationRecord, ResolutionRecord (JSON in the project-local `cogni-claims/` store — the directory name is historical)
- cogni-marketing, cogni-sales and cogni-consult also have their own entity types

cogni-workspace's `copywriter` skill deliberately has no persistent entities — it modifies documents in place and detects `arc_id` frontmatter for arc-aware polishing.

## Bridge files

Bridge files are explicit JSON exports written by one plugin and read by another according to a versioned contract — see [[concept-bridge-files]]. Key examples: `portfolio-context.json` (cogni-portfolio → cogni-trends, products and features for trend mapping), `portfolio-opportunities.json` (cogni-trends → cogni-portfolio, ranked growth opportunities), `tips-value-model.json` (cogni-trends → cogni-portfolio, solution templates and TIPS paths for trends-bridge import), `claims.json` (any plugin → cogni-workspace, sourced assertions for verification).

The bidirectional bridge between cogni-portfolio and cogni-trends is the most complex single integration in the ecosystem.

## YAML frontmatter contracts

Lighter than bridge files: a downstream plugin reads specific frontmatter fields from upstream files. `arc_id` (cogni-workspace's `text-to-narrative` skill → its `copywriter` skill and its render agents), `theme_path` (`manage-themes` Operation 11 → those render agents — see [[concept-theme-inheritance]]), `portfolio_path` (cogni-portfolio → cogni-sales, cogni-marketing, cogni-trends), `arc_type` (cogni-workspace internal mapping for rendering agents).

## Data isolation in practice

The diagram shows many arrows but each is read-only. cogni-workspace reads source URLs from cogni-knowledge entity files but never writes back. cogni-portfolio's proposition-generator reads trend-bridge enrichments from `portfolio-opportunities.json` but never modifies cogni-trends files. The boundary is the bridge file or frontmatter field — everything on each side is private to the owning plugin. See [[concept-data-isolation]].

## Claim lifecycle

Claims flow from data-layer plugins into cogni-workspace through a three-state lifecycle (`unverified → verified` or `unverified → deviated → resolved`). cogni-workspace owns verification logic but never generates claims itself — that boundary is enforced by design. Full detail in [[concept-claim-lifecycle]].

**Source**: [docs/architecture/er-diagram.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/architecture/er-diagram.md)
