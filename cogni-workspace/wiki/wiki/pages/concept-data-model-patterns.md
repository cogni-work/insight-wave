---
id: concept-data-model-patterns
title: Data model patterns (entity slugs, project dirs, FxM, source lineage)
type: concept
tags: [data-model, entities, slugs, project-structure, source-lineage, obsidian, is-does-means, fab]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

The recurring patterns across every entity-producing plugin in insight-wave.

## Entity slugs

Entity slugs are kebab-case, derived from the entity name at creation time, and serve as both the filename and the cross-plugin identifier. See [[concept-slug-based-lookups]].

## Project directory layout

Every project sits at `{plugin}/{project-slug}/` with a manifest at the root. cogni-portfolio uses `portfolio.json`, cogni-trends uses `tips-project.json`, cogni-knowledge uses `.cogni-knowledge/binding.json`, cogni-consult uses `consult-project.json`. The manifest is the lightweight index — full entity content lives in subdirectories and is loaded only when needed (see [[concept-progressive-disclosure]]).

## The Feature × Market join

In cogni-portfolio, the Feature × Market combination is the core join — it drives propositions, solutions, and competitor analysis. A `feature--market` slug (with the double-dash from [[concept-slug-based-lookups]]) identifies a paired entity that has its own messaging and pricing.

This is the structural reason cogni-portfolio's data model carries weight across the rest of the ecosystem: cogni-marketing reads FxM-keyed propositions, cogni-sales generates Why Change pitches per FxM, cogni-trends imports trend opportunities and stubs them as new FxM combinations.

## IS / DOES / MEANS messaging

Per-FxM propositions follow the FAB-derived IS/DOES/MEANS structure:

- **IS** — what the offering is (the noun)
- **DOES** — what it enables (the verb, mechanism, capability)
- **MEANS** — what it means for this specific buyer in this specific market (the value)

This same structure powers plugin READMEs ([[concept-readme-convention]]). The pattern is consistent because the consumption is consistent: a buyer reading proposition messaging and a developer reading a plugin README both want the same IS-DOES-MEANS scaffolding.

## Source lineage

Entity records include three provenance fields:

- `source_url` — where the asserted content came from
- `entity_ref` — the originating plugin entity (for cascade)
- `propagated_at` — timestamp of last cascade refresh

These three are the substrate of [[concept-claims-propagation]] — when a claim is corrected, `entity_ref` lets the correction find the originating entity, and `propagated_at` lets downstream consumers detect that they're now stale.

## Obsidian-browsability

All entity outputs are markdown with YAML frontmatter. This means the user can open the project directory in Obsidian and browse the entire knowledge graph natively — no custom tooling needed. This is one reason cogni-knowledge, cogni-marketing, cogni-trends, and cogni-workspace's `text-to-narrative` skill all default to markdown-with-frontmatter rather than pure JSON.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
