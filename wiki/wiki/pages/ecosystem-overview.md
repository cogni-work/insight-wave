---
id: ecosystem-overview
title: insight-wave ecosystem overview
type: summary
tags: [ecosystem, monorepo, plugin, claude-code, overview]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

insight-wave is a 13-plugin monorepo for consulting, sales, and marketing on Claude Code, Apache-2.0, with all plugins following the standard Claude Code plugin shape.

## Repository shape

Each `cogni-*` plugin sits at the repo root with the standard layout: `.claude-plugin/plugin.json` (manifest + version), `README.md` (IS/DOES/MEANS messaging), `CLAUDE.md` (developer guide), `skills/{name}/SKILL.md`, `agents/{name}.md`, `commands/{name}.md`, optional `hooks/`, `scripts/` (bash + python3 stdlib only), and `references/` (framework docs and templates). Top-level `docs/` holds user-facing material — `getting-started.md`, `plugin-guide/{name}.md` deep dives, `workflows/*.md` cross-plugin pipelines, `architecture/*` (see [[arch-design-philosophy]], [[arch-plugin-anatomy]], [[arch-er-diagram]]), and `contributing/`.

## Cross-plugin conventions

Five conventions show up everywhere in the codebase:

- All scripts return JSON in the shape `{"success": bool, "data": {...}, "error": "string"}` — see [[concept-script-output-format]].
- Agents pick model tiers by role — [[concept-agent-model-strategy]].
- Entity-producing plugins gate on a [[concept-quality-gates]] (structural + quality + stakeholder).
- Entities use kebab-case slugs, store in `{plugin}/{project-slug}/`, and are Obsidian-browsable markdown with YAML frontmatter — see [[concept-slug-based-lookups]] and [[concept-data-isolation]].
- Output language and authority sources are configurable per market across DACH, DE, FR, IT, PL, NL, ES, US, UK, EU — [[concept-multilingual-support]].

## Plugin data flow

[[plugin-cogni-research]] feeds [[plugin-cogni-narrative]] which feeds [[plugin-cogni-copywriting]] which feeds [[plugin-cogni-visual]] rendering. [[plugin-cogni-trends]] and [[plugin-cogni-portfolio]] sit at the strategic core, dispatching to [[plugin-cogni-sales]] (Why Change pitches) and [[plugin-cogni-marketing]] (content engine). [[plugin-cogni-consulting]] orchestrates the whole pipeline through Discover → Define → Develop → Deliver phases, [[plugin-cogni-claims]] verification cuts across every plugin that produces sourced assertions ([[concept-claims-propagation]], [[concept-claim-lifecycle]]), and [[plugin-cogni-workspace]] + [[plugin-cogni-help]] are foundational utilities every plugin can rely on. [[plugin-cogni-website]] assembles deployable static sites from upstream plugin output. [[plugin-cogni-wiki]] is the engine running this very wiki. The trends ↔ portfolio bridge is the most complex bidirectional integration — see [[concept-trends-portfolio-bridge]].

## Common workflows

Seven cross-plugin pipelines have dedicated wiki pages: [[workflow-consulting-engagement]] (full Double Diamond), [[workflow-content-pipeline]] (marketing → narrative → polish → visual), [[workflow-install-to-infographic]] (first-run validation), [[workflow-portfolio-to-pitch]] (Why Change deal pitch), [[workflow-portfolio-to-website]] (multi-page customer site), [[workflow-research-to-report]] (verified themed report), and [[workflow-trends-to-solutions]] (TIPS network → portfolio features).

## Versioning and maturity

Plugin versions live in `.claude-plugin/plugin.json` and are mirrored to `.claude-plugin/marketplace.json` for Claude Desktop update detection. The patch version bumps after any change to skills, agents, or structure. Maturity is hard-derived from the version itself ([[concept-plugin-maturity-model]]) — `0.0.x` Incubating through `2.x.x+` Established — and READMEs carry an auto-generated maturity callout for pre-1.0 and archived plugins.

## MCP servers

Three MCP servers ship with the marketplace: excalidraw (cogni-visual, cogni-portfolio), claude-in-chrome (cogni-claims, cogni-help, cogni-website, cogni-workspace), and pencil (cogni-visual, cogni-website). All managed by `cogni-workspace:install-mcp` — see [[concept-mcp-server-map]].

## Contributing

CLA on first PR, feature branches from main, one feature or fix per PR, and skill names validated by `cogni-workspace/scripts/check-skill-names.sh` against the [[concept-naming-conventions]] (generic verbs require a domain prefix).

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
