# Ecosystem Overview

insight-wave is a monorepo of 13 Claude Code plugins that cover the full consulting and B2B content pipeline: from raw research through strategy, content production, visual delivery, and website generation. This document describes how the plugins are organized, how data moves between them, and what infrastructure they share.

For the canonical plugin descriptions, see the individual README files. For step-by-step workflows, see [docs/workflows/](workflows/).

---

## Plugin Landscape

The 13 plugins are grouped by the role they play in a typical engagement.

### Foundation

| Plugin | What it does |
|--------|-------------|
| [cogni-workspace](../cogni-workspace/README.md) | Initializes the shared workspace: environment variables, plugin discovery, theme management, and Obsidian vault integration. Every other plugin depends on it. |

Run `/manage-workspace` once per project directory before using any other plugin.

### Research and Analysis

| Plugin | What it does |
|--------|-------------|
| [cogni-research](../cogni-research/README.md) | Runs a parallel multi-agent web research pipeline (STORM-inspired). Decomposes a topic into sub-questions, dispatches one agent per question, aggregates sources, writes a structured report with inline citations, and verifies claims. |
| [cogni-trends](../cogni-trends/README.md) | Scouts industry trends using the Smarter Service Trendradar framework and bridges them to portfolio solutions via the TIPS content framework (Trends, Implications, Possibilities, Solutions). Produces CxO-ready trend reports with investment theme modeling. Bilingual EN/DE, DACH-focused. |

See [Research to Report workflow](workflows/research-to-report.md) for how research output moves downstream.

### Strategy and Portfolio

| Plugin | What it does |
|--------|-------------|
| [cogni-portfolio](../cogni-portfolio/README.md) | Structures product and service messaging using the IS/DOES/MEANS framework. Features are market-independent (IS). Advantages (DOES) and benefits (MEANS) are market-specific. Includes TAM/SAM/SOM sizing, competitor analysis, Lean Canvas bootstrapping, and eight industry taxonomies. |
| [cogni-consulting](../cogni-consulting/README.md) | Orchestrates engagements through the Double Diamond phases (Discover, Define, Develop, Deliver) by dispatching to research, trends, portfolio, and claims plugins at the right moment. Phase-gated, vision-first. |

See the [Double Diamond Engagement workflow](workflows/consulting-engagement.md) for how cogni-consulting coordinates the other plugins.

### Content Production

| Plugin | What it does |
|--------|-------------|
| [cogni-narrative](../cogni-narrative/README.md) | Transforms research reports and structured content into executive narratives using 8 story arc frameworks and 8 narrative techniques. Includes a TIPS-native arc for trend panoramas, a theme-thesis arc for investment narratives, and a JTBD portfolio arc for buyer-job-centric portfolio narratives. |
| [cogni-copywriting](../cogni-copywriting/README.md) | Polishes documents using messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid). Runs parallel stakeholder persona reviews, readability optimization, JSON field polishing, and arc contract audit against cogni-narrative output. Bilingual EN/DE. |
| [cogni-marketing](../cogni-marketing/README.md) | Bridges cogni-trends strategic themes and cogni-portfolio propositions into channel-ready content across 16 formats — thought leadership, demand generation, lead generation, sales enablement, and ABM. Bilingual DE/EN. |
| [cogni-sales](../cogni-sales/README.md) | Generates B2B sales pitches using the Corporate Visions Why Change methodology. Supports named customer deals (deal-specific) and reusable segment pitches. Builds on cogni-portfolio data with optional TIPS strategic enrichment. Bilingual DE/EN. |

### Visual Delivery

| Plugin | What it does |
|--------|-------------|
| [cogni-visual](../cogni-visual/README.md) | Converts polished narratives and structured data into presentation briefs, slide decks, scrollable web narratives, poster storyboards, and single-page infographics. Supports Excalidraw, Pencil MCP, PPTX, and HTML rendering. |

### Website Generation

| Plugin | What it does |
|--------|-------------|
| [cogni-website](../cogni-website/README.md) | Assembles multi-page customer websites from portfolio, marketing, trend, and research content produced by other plugins — outputting a deployable static site with shared navigation, theming, and responsive HTML. |

See [Portfolio to Website workflow](workflows/portfolio-to-website.md) for how portfolio and theme data combine into a deployable site.

### Verification

| Plugin | What it does |
|--------|-------------|
| [cogni-claims](../cogni-claims/README.md) | Verifies sourced claims against their cited URLs. Detects misquotations, unsupported conclusions, and selective omissions. Used as a review loop inside cogni-research and callable standalone on any document with citations. |

### Learning and Support

| Plugin | What it does |
|--------|-------------|
| [cogni-help](../cogni-help/README.md) | Central help hub: 12-course interactive curriculum, plugin discovery, cross-plugin workflow guides, troubleshooting, quick-reference cheatsheets, and GitHub issue filing. |

---

## Data Flow

Most workflows follow a left-to-right pipeline. The typical path from research to deliverable:

```
cogni-research
  → produces: report-draft.md + source entities

cogni-claims (via /verify-report)
  → produces: verified report with claim annotations

cogni-narrative
  → consumes: verified report
  → produces: arc-structured narrative (arc_id in frontmatter)

cogni-copywriting
  → consumes: narrative output (auto-activated by arc_id frontmatter)
  → produces: polished document

cogni-visual
  → consumes: polished narrative
  → produces: slide deck / journey map / web narrative / poster
```

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

For consulting engagements, cogni-consulting acts as the orchestrator:

```
cogni-consulting (Double Diamond phases)
  Discover → dispatches cogni-research, cogni-trends
  Define   → dispatches cogni-portfolio, cogni-consulting (Lean Canvas)
  Develop  → dispatches cogni-narrative, cogni-copywriting
  Deliver  → dispatches cogni-visual, cogni-sales
```

For the entity-level diagram see [er-diagram.md](er-diagram.md).

---

## Shared Infrastructure

All plugins depend on cogni-workspace for three shared concerns:

**Environment variables.** `manage-workspace` generates `.claude/settings.local.json`, which Claude Code auto-injects at session start. Plugins resolve sibling plugin paths via these variables rather than hardcoding paths.

**Theme management.** Visual plugins (cogni-visual, cogni-narrative, cogni-marketing, cogni-website) call the `pick-theme` skill from cogni-workspace to resolve a brand theme. Themes live in `{workspace}/cogni-workspace/themes/` and are shared across all plugins that produce HTML or visual output.

**Session hooks.** cogni-workspace installs an `on-session-start.sh` hook that sources workspace environment variables and validates plugin availability each time a Claude Code session opens.

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
  cogni-research/data/{slug}/
    00-sub-questions/
    01-contexts/
    02-sources/
    report-draft.md

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

Downstream plugins reference upstream output by path. For example, cogni-narrative accepts `--source-path` pointing at a cogni-research output directory. cogni-website reads proposition, feature, and customer files directly from the cogni-portfolio project directory.

### Wikilinks

All cross-references within plugin output use workspace-relative wikilinks (`[[cogni-research/data/slug/02-sources/example]]`), making the workspace fully navigable in Obsidian.

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

For example, cogni-website reads from `$COGNI_PORTFOLIO_ROOT/{slug}/propositions/` and `$COGNI_WORKSPACE_ROOT/themes/`. cogni-narrative accepts `--source-path` pointing at a cogni-research output directory.

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
| [Research to Report](workflows/research-to-report.md) | cogni-research → cogni-claims → cogni-copywriting | Verified, polished research report |
| [Portfolio to Pitch](workflows/portfolio-to-pitch.md) | cogni-portfolio → cogni-sales → cogni-visual | Sales presentation with slides |
| [Portfolio to Website](workflows/portfolio-to-website.md) | cogni-portfolio → cogni-workspace → cogni-website | Deployable multi-page customer website |
| [Trends to Solutions](workflows/trends-to-solutions.md) | cogni-trends → cogni-portfolio (bridge) → cogni-visual | Ranked solutions with visual deliverables |
| [Consulting Engagement](workflows/consulting-engagement.md) | cogni-consulting → (orchestrates all others) | Full consulting deliverable package |
| [Content Pipeline](workflows/content-pipeline.md) | cogni-marketing → cogni-narrative → cogni-visual | Multi-channel marketing content |
| [Wiki ↔ Research Cycle](workflows/wiki-research-cycle.md) | cogni-research ↔ cogni-wiki ↔ cogni-claims (bidirectional) | Compounding wiki with periodic citation re-verification |

---

## See Also

- [Install to Infographic](workflows/install-to-infographic.md) — install the marketplace, set up your workspace, and produce your first infographic
- [er-diagram.md](er-diagram.md) — cross-plugin entity relationship diagram
- Plugin guides in [docs/plugin-guide/](plugin-guide/) — per-plugin tutorials with worked examples
- Workflow guides in [docs/workflows/](workflows/) — end-to-end pipeline walkthroughs
