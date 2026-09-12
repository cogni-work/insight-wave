# Ecosystem Overview

insight-wave is a monorepo of 8 Claude Code plugins that cover the full consulting and B2B content pipeline: from raw research through strategy, content production, visual delivery, and website generation. This document describes how the plugins are organized, how data moves between them, and what infrastructure they share.

For the canonical plugin descriptions, see the individual README files. For step-by-step workflows, see [docs/workflows/](workflows/).

---

## Plugin Landscape

The 8 plugins — the same set the root [`marketplace.json`](../.claude-plugin/marketplace.json) enumerates — are grouped into eight capability areas: one horizontal area (cogni-workspace, the shared workspace layer every other plugin builds on) and seven verticals, one per business-domain plugin, each keeping its own project lifecycle.

### Workspace Infrastructure

| Plugin | What it does |
|--------|-------------|
| [cogni-workspace](../cogni-workspace/README.md) | Initializes the shared workspace: environment variables, plugin discovery, theme management, and Obsidian vault integration. The vertical business plugins consume the shared state it owns; each keeps its own project lifecycle. |
| [cogni-workspace](../cogni-workspace/README.md) — `text-to-narrative` | Transforms research reports and structured content into executive narratives using 15 story arc frameworks and 8 narrative techniques, then cuts the finished narrative into one `design-brief.md` for Claude Design (slides, document, infographic or web). Includes a TIPS-native arc for trend panoramas, a theme-thesis arc for investment narratives, and a JTBD portfolio arc for buyer-job-centric portfolio narratives. |
| [cogni-workspace](../cogni-workspace/README.md) — `copywriter` | Polishes documents using messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid). Runs parallel stakeholder persona reviews, readability optimization and JSON field polishing; the arc contract against `text-to-narrative` is now asserted by `test-arc-reference-sync.sh` rather than audited by a skill. Translate-then-polish across DE/EN/FR/IT/PL/NL/ES. |
| [cogni-workspace](../cogni-workspace/README.md) — render chain | Renders an existing presentation, web, storyboard or infographic brief — hand-authored against its `libraries/` templates or supplied by a caller — into HTML slides, PPTX, Pencil `.pen` pages and posters, or Excalidraw scenes (`render-html-slides`, `/render-infographic`, the `web`, `storyboard` and `pptx` agents), and enriches a finished report into themed HTML (`enrich-report`). |
| [cogni-workspace](../cogni-workspace/README.md) — `claims` | Verifies sourced claims against their cited URLs, detecting misquotations, unsupported conclusions, and selective omissions. Runs as a review loop inside cogni-knowledge and is callable standalone on any document with citations. |

Run `/manage-workspace` once per project directory before using any other plugin.

### Knowledge Management

| Plugin | What it does |
|--------|-------------|
| [cogni-knowledge](../cogni-knowledge/README.md) | Wiki-first research that compounds across runs. Binds each project to its own wiki knowledge base (the Karpathy-style engine is vendored in) so future runs read what prior runs filed before hitting the web. Inverted pipeline (plan → curate → fetch → ingest → distill → compose → verify → finalize) with zero-network, citation-consistent claim verification. See the [deep dive](plugin-guide/cogni-knowledge.md). |

See [Research to Report workflow](workflows/research-to-report.md) for how research output moves downstream.

### Consulting Orchestration

| Plugin | What it does |
|--------|-------------|
| [cogni-consult](../cogni-consult/README.md) | Orchestrates consulting engagements: action fields as the work-breakdown structure, a design-thinking loop per deliverable, acting stakeholder personas, and one cogni-knowledge base per engagement as the compounding research spine. See the [deep dive](plugin-guide/cogni-consult.md). |

See the [Consulting Engagement workflow](workflows/consulting-engagement.md) for how cogni-consult coordinates the other plugins.

### Trend Intelligence

| Plugin | What it does |
|--------|-------------|
| [cogni-trends](../cogni-trends/README.md) | Scouts industry trends using the Smarter Service Trendradar framework and bridges them to portfolio solutions via the TIPS content framework (Trends, Implications, Possibilities, Solutions). Produces CxO-ready trend reports with investment theme modeling. Bilingual (local + EN) research against per-market institutional authority sources across DACH/DE, FR, IT, ES, NL, PL plus UK/US. |

### Portfolio Messaging

| Plugin | What it does |
|--------|-------------|
| [cogni-portfolio](../cogni-portfolio/README.md) | Structures product and service messaging using the IS/DOES/MEANS framework. Features are market-independent (IS). Advantages (DOES) and benefits (MEANS) are market-specific. Includes TAM/SAM/SOM sizing, competitor analysis, Lean Canvas bootstrapping, and eight industry taxonomies. |

### Content Production

| Plugin | What it does |
|--------|-------------|
| [cogni-marketing](../cogni-marketing/README.md) | Bridges cogni-trends strategic themes and cogni-portfolio propositions into channel-ready content across 16 formats — thought leadership, demand generation, lead generation, sales enablement, and ABM. Configurable brand voice; market-aware content across European and US/UK targets. |

### Sales Pitches

| Plugin | What it does |
|--------|-------------|
| [cogni-sales](../cogni-sales/README.md) | Generates B2B sales pitches using the Corporate Visions Why Change methodology. Supports named customer deals (deal-specific) and reusable segment pitches. Builds on cogni-portfolio data with optional TIPS strategic enrichment. Multilingual EN/DE/PT-BR. |

### Website Generation

| Plugin | What it does |
|--------|-------------|
| [cogni-website](../cogni-website/README.md) | Assembles multi-page customer websites from portfolio, marketing, trend, and research content produced by other plugins — outputting a deployable static site with shared navigation, theming, and responsive HTML. |

See [Portfolio to Website workflow](workflows/portfolio-to-website.md) for how portfolio and theme data combine into a deployable site.

---

## Data Flow

Most workflows follow a left-to-right pipeline. The typical path from research to deliverable:

```
cogni-knowledge
  → produces: report-draft.md + source entities

cogni-workspace (via /claims)
  → produces: verified report with claim annotations

cogni-workspace (text-to-narrative, Phases 0-6)
  → consumes: verified report
  → produces: arc-structured narrative (arc_id in frontmatter)

cogni-workspace (copywriter)
  → consumes: narrative output (auto-activated by arc_id frontmatter)
  → produces: polished document

cogni-workspace (text-to-narrative, Phase 7)
  → consumes: the finished narrative
  → produces: design-brief.md for Claude Design (slides, document, infographic or web)
```

An existing `presentation-brief.md`, `web-brief.md` or `infographic-brief.md` — hand-authored against the `cogni-workspace/libraries/` templates or supplied by a caller — still renders locally through `render-html-slides`, `/render-infographic` and the `web` / `storyboard` agents; nothing in the ecosystem produces those briefs from a narrative any more.

For B2B content, the trend and portfolio path feeds into content production:

```
cogni-trends
  → produces: TIPS themes, trend catalog, investment themes

cogni-portfolio
  → produces: IS/DOES/MEANS propositions, market targets, competitor analysis

cogni-marketing
  → consumes: TIPS themes (GTM paths) + portfolio propositions
  → produces: channel-ready content across 16 formats

cogni-sales
  → consumes: portfolio data + optional TIPS enrichment
  → produces: Why Change sales pitch per customer or segment
```

For website generation, portfolio and workspace data drive page assembly:

```
cogni-portfolio
  → produces: propositions, features, customer profiles

cogni-workspace
  → provides: brand theme, workspace environment variables

cogni-website
  → consumes: portfolio entities + theme
  → produces: deployable static site (service pages, homepage, themed assets)
  → optional enrichment: cogni-marketing (blog/lead-gen pages), cogni-trends (insights pages)
```

For consulting engagements, cogni-consult acts as the orchestrator:

```
cogni-consult (action-fields WBS)
  Scope            → SMART key question + 3-6 action fields as the WBS
  Per deliverable  → design-thinking loop (empathize→define→ideate→prototype→test)
                     research via the engagement's bound cogni-knowledge base
  Quality          → acting stakeholder personas challenge each deliverable
  Hand-off         → deliverables feed text-to-narrative, cogni-sales
```

For the entity-level diagram see [er-diagram.md](er-diagram.md).

---

## Shared Infrastructure

All plugins depend on cogni-workspace for three shared concerns:

**Environment variables.** `manage-workspace` generates `.claude/settings.local.json`, which Claude Code auto-injects at session start. Plugins resolve sibling plugin paths via these variables rather than hardcoding paths.

**Theme management.** Visual-output plugins (cogni-marketing, cogni-website) call the `manage-themes` skill from cogni-workspace — Operation 11, Select Theme — to resolve a brand theme, as do cogni-workspace's own rendering skills. Themes live in `{workspace}/cogni-workspace/themes/` and are shared across all plugins that produce HTML or visual output.

**Session hooks.** cogni-workspace installs an `on-session-start.sh` hook that sources workspace environment variables and validates plugin availability each time a Claude Code session opens.

**Market and language configuration.** insight-wave is European-first and multi-market: research, trend scouting, and content generation run bilingually (local language + English) against curated regional authority sources across a built-out set — DACH/DE, FR, IT, ES, NL, PL, UK, US — with 16+ output languages in native UTF-8. The canonical market registry lives in cogni-workspace; plugins read it at runtime via `get-market-config.py`. See [Supported markets & languages](../cogni-workspace/README.md#supported-markets--languages) for the full registry and the built-out-vs-registered distinction.

---

## File Conventions

Understanding these patterns makes it easier to navigate workspace output and build integrations.

### Slug patterns

Plugins use kebab-case slugs derived from user input: `ai-adoption-in-healthcare`, `smarter-service-trendradar-2025`. Slugs become directory names under the plugin's `data/` directory.

### JSON entities

Most plugins store structured data as markdown files with YAML frontmatter rather than raw JSON. This makes them readable in Obsidian while still being machine-parseable. The general shape:

```yaml
---
type: source          # entity type
slug: example-source  # unique identifier within the project
created: 2025-01-15T10:00:00Z
---
# Title
... body content ...
```

Entity files are created exclusively via `scripts/create-entity.sh` (or the plugin-specific equivalent) — never written directly by Claude. This ensures hooks run correctly and frontmatter is well-formed.

### Project directories

Each plugin that runs a multi-step workflow stores its work under a project directory:

```
{workspace}/
  cogni-knowledge/{slug}/
    .cogni-knowledge/binding.json
    .metadata/            plan, candidates, manifests
    output/draft-vN.md
    wiki/                 the bound knowledge base

  cogni-trends/data/{slug}/
    trends/
    implications/
    report.md

  cogni-portfolio/{slug}/
    products/
    markets/
    propositions/
    features/
    solutions/
    competitors/
    customers/
    portfolio.json

  cogni-website/{slug}/
    website-plan.json
    website/
```

Downstream plugins reference upstream output by path. For example, `text-to-narrative` accepts `--source-path` pointing at a cogni-knowledge output directory. cogni-website reads proposition, feature, and customer files directly from the cogni-portfolio project directory.

### Wikilinks

All cross-references within plugin output use workspace-relative wikilinks (`[[cogni-knowledge/slug/wiki/sources/example]]`), making the workspace fully navigable in Obsidian.

---

## Plugin Interface Summary

This section documents the conventions a new plugin must follow to be compatible with the insight-wave ecosystem. The conventions below are grounded in existing plugins (cogni-portfolio, cogni-workspace, and others) — not aspirational guidelines.

### Required directory structure

A conformant plugin must place files at these paths relative to its plugin root:

```
{plugin-name}/
  .claude-plugin/
    plugin.json           # required: plugin manifest
  skills/
    {skill-name}/
      SKILL.md            # required: skill instructions loaded by Claude Code
  README.md               # required: canonical plugin description
```

Optional but standard:

```
{plugin-name}/
  agents/
    {agent-name}/
      AGENT.md            # sub-agent instructions dispatched by skills
  hooks/
    hooks.json            # session lifecycle hook declarations
    *.sh                  # hook scripts referenced by hooks.json
  scripts/
    *.sh / *.py           # utility scripts (stdlib-only, no external dependencies)
  references/             # static reference data loaded by skills and agents
    *.md / *.json
  templates/              # reusable templates (e.g., taxonomy templates, entity schemas)
    */template.md
  CLAUDE.md               # development guide loaded when working inside the plugin directory
```

### Plugin manifest (`plugin.json`)

The manifest at `.claude-plugin/plugin.json` declares the plugin to Claude Code. The root `marketplace.json` at the repo root registers the plugin for `/plugin install` discovery — each entry maps `name` to a relative `source` path:

```json
{
  "name": "cogni-example",
  "source": "./cogni-example",
  "version": "1.0.0",
  "description": "One-sentence description of what this plugin does.",
  "keywords": ["relevant", "keywords", "agent"]
}
```

### Slug convention

Plugins generate slugs from user-provided names by converting to lowercase kebab-case: `"Acme Cloud Services"` → `acme-cloud`. Slugs serve as directory names under the plugin's project directory and as unique identifiers in entity filenames. Keep slugs short, human-readable, and stable — downstream plugins reference upstream project directories by slug.

### Data contracts between plugins

Plugins share data through the filesystem, not through direct calls. The pattern:

1. **Upstream plugin** writes structured output into its project directory: `{workspace}/{plugin-name}/{slug}/`
2. **Downstream plugin** reads that directory by path, either passed explicitly (e.g., `--source-path`) or resolved via environment variables set by cogni-workspace.
3. **Environment variables** (generated by `manage-workspace` into `.claude/settings.local.json`) give each plugin a `_ROOT` and `_PLUGIN` variable so paths resolve correctly regardless of workspace location.

For example, cogni-website reads from `$COGNI_PORTFOLIO_ROOT/{slug}/propositions/` and `$COGNI_WORKSPACE_ROOT/themes/`. `text-to-narrative` accepts `--source-path` pointing at a cogni-knowledge output directory.

### Skill instructions (`SKILL.md`)

Each skill is a markdown file at `skills/{name}/SKILL.md`. The YAML frontmatter declares the skill's name, description, and allowed tools:

```yaml
---
name: skill-name
description: |
  When to activate this skill. Written for Claude Code's trigger matching —
  include synonyms and natural-language phrasings the user might say.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill
---
```

The body contains the skill's instructions in plain markdown. Skills reference sibling resources via `$CLAUDE_PLUGIN_ROOT` (the environment variable pointing to the plugin root, set by cogni-workspace). Scripts are called via `bash $CLAUDE_PLUGIN_ROOT/scripts/...`.

### Plugin discovery via marketplace.json

The root `.claude-plugin/marketplace.json` is the single discovery manifest for the entire monorepo. When a user runs `/plugin marketplace add cogni-work/insight-wave`, Claude Code reads this file to enumerate available plugins. Each plugin entry points to its `source` directory, from which Claude Code reads the individual `plugin.json` manifest.

To register a new plugin, add an entry to `marketplace.json` and ensure the plugin directory contains a valid `plugin.json`.

For a detailed walkthrough of plugin structure, see [plugin-anatomy](architecture/plugin-anatomy.md). For how to build a new plugin, see [plugin-development](contributing/plugin-development.md).

---

## Workflow Guides

Seven end-to-end workflow guides document the cross-plugin pipelines:

| Workflow | Pipeline | End deliverable |
|----------|----------|-----------------|
| [Research to Report](workflows/research-to-report.md) | cogni-knowledge → cogni-workspace (claims → copywriter) | Verified, polished research report |
| [Portfolio to Pitch](workflows/portfolio-to-pitch.md) | cogni-portfolio → cogni-sales → cogni-workspace (text-to-narrative) | Sales presentation with a Claude Design slides brief |
| [Portfolio to Website](workflows/portfolio-to-website.md) | cogni-portfolio → cogni-workspace → cogni-website | Deployable multi-page customer website |
| [Trends to Solutions](workflows/trends-to-solutions.md) | cogni-trends → cogni-portfolio (bridge) → cogni-workspace (text-to-narrative / enrich-report) | Ranked solutions with visual deliverables |
| [Consulting Engagement](workflows/consulting-engagement.md) | cogni-consult → cogni-knowledge (+ persona-gated deliverables) | Full consulting deliverable package |
| [Content Pipeline](workflows/content-pipeline.md) | cogni-marketing → cogni-workspace (copywriter → text-to-narrative) | Multi-channel marketing content |

---

## See Also

- [Install to Infographic](workflows/install-to-infographic.md) — install the marketplace, set up your workspace, and produce your first infographic
- [er-diagram.md](er-diagram.md) — cross-plugin entity relationship diagram
- Plugin guides in [docs/plugin-guide/](plugin-guide/) — per-plugin tutorials with worked examples
- Workflow guides in [docs/workflows/](workflows/) — end-to-end pipeline walkthroughs
