# Ecosystem Overview

insight-wave is a monorepo of 12 Claude Code plugins that cover the full consulting and B2B content pipeline: from raw research through strategy, content production, and visual delivery. This document describes how the plugins are organized, how data moves between them, and what infrastructure they share.

For the canonical plugin descriptions, see the individual README files. For step-by-step workflows, see [docs/workflows/](workflows/).

---

## Plugin Landscape

The 12 plugins are grouped by the role they play in a typical engagement.

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

See [Research to Narrative workflow](workflows/research-to-narrative.md) for how research output moves downstream.

### Strategy and Portfolio

| Plugin | What it does |
|--------|-------------|
| [cogni-portfolio](../cogni-portfolio/README.md) | Structures product and service messaging using the IS/DOES/MEANS framework. Features are market-independent (IS). Advantages (DOES) and benefits (MEANS) are market-specific. Includes TAM/SAM/SOM sizing, competitor analysis, Lean Canvas bootstrapping, and eight industry taxonomies. |
| [cogni-consulting](../cogni-consulting/README.md) | Orchestrates engagements through the Double Diamond phases (Discover, Define, Develop, Deliver) by dispatching to research, trends, portfolio, and claims plugins at the right moment. Phase-gated, vision-first. |

See the [Double Diamond Engagement workflow](workflows/consulting-engagement.md) for how cogni-consulting coordinates the other plugins.

### Content Production

| Plugin | What it does |
|--------|-------------|
| [cogni-narrative](../cogni-narrative/README.md) | Transforms research reports and structured content into executive narratives using 6 story arc frameworks and 8 narrative techniques. Includes a TIPS-native arc for trend panoramas and a theme-thesis arc for investment narratives. |
| [cogni-copywriting](../cogni-copywriting/README.md) | Polishes documents using messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB). Runs parallel stakeholder persona reviews, readability optimization, JSON field polishing, and arc contract audit against cogni-narrative output. Bilingual EN/DE. |
| [cogni-marketing](../cogni-marketing/README.md) | Bridges cogni-trends strategic themes and cogni-portfolio propositions into channel-ready content across 16 formats — thought leadership, demand generation, lead generation, sales enablement, and ABM. Bilingual DE/EN. |
| [cogni-sales](../cogni-sales/README.md) | Generates B2B sales pitches using the Corporate Visions Why Change methodology. Supports named customer deals (deal-specific) and reusable segment pitches. Builds on cogni-portfolio data with optional TIPS strategic enrichment. Bilingual DE/EN. |

### Visual Delivery

| Plugin | What it does |
|--------|-------------|
| [cogni-visual](../cogni-visual/README.md) | Converts polished narratives and structured data into presentation briefs, slide decks, big-picture journey maps, Big Block solution architecture diagrams, scrollable web narratives, and poster storyboards. Supports Excalidraw, Pencil MCP, and PPTX rendering. |

### Verification

| Plugin | What it does |
|--------|-------------|
| [cogni-claims](../cogni-claims/README.md) | Verifies sourced claims against their cited URLs. Detects misquotations, unsupported conclusions, and selective omissions. Used as a review loop inside cogni-research and callable standalone on any document with citations. |

### Learning and Support

| Plugin | What it does |
|--------|-------------|
| [cogni-help](../cogni-help/README.md) | Central help hub: 11-course interactive curriculum, plugin discovery, cross-plugin workflow guides, troubleshooting, quick-reference cheatsheets, and GitHub issue filing. |

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

**Theme management.** Visual plugins (cogni-visual, cogni-narrative, cogni-marketing) call the `pick-theme` skill from cogni-workspace to resolve a brand theme. Themes live in `{workspace}/cogni-workspace/themes/` and are shared across all plugins that produce HTML or visual output.

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

  cogni-portfolio/data/{slug}/
    products/
    markets/
    propositions/
```

Downstream plugins reference upstream output by path. For example, cogni-narrative accepts `--source-path` pointing at a cogni-research output directory.

### Wikilinks

All cross-references within plugin output use workspace-relative wikilinks (`[[cogni-research/data/slug/02-sources/example]]`), making the workspace fully navigable in Obsidian.

---

## Plugin Interface Summary

A conformant insight-wave plugin requires these components:

| Component | Path | Purpose |
|-----------|------|---------|
| Plugin manifest | `.claude-plugin/plugin.json` | Declares name, version, skills, agents, and hooks |
| Skills | `skills/{name}/SKILL.md` | Markdown instructions that Claude Code loads as callable skills |
| Agents | `agents/{name}/AGENT.md` | Markdown instructions for sub-agents dispatched by skills |
| Marketplace entry | Root `.claude-plugin/marketplace.json` | Registers the plugin for `/plugin install` discovery |

Optional but standard:

| Component | Path | Purpose |
|-----------|------|---------|
| Hooks | `hooks/hooks.json` + shell scripts | Session lifecycle integration (SessionStart, PreToolCall) |
| Scripts | `scripts/*.sh` or `scripts/*.py` | Bash/Python utilities; must be stdlib-only |
| References | `references/*.md` or `references/*.json` | Reference data loaded by skills and agents |
| CLAUDE.md | `CLAUDE.md` | Development guide loaded into Claude's context when working inside the plugin directory |

For a detailed walkthrough of plugin structure, see [plugin-anatomy](architecture/plugin-anatomy.md). For how to build a new plugin, see [plugin-development](contributing/plugin-development.md).

---

## See Also

- [Getting Started](getting-started.md) — install the marketplace and run your first report
- [er-diagram.md](er-diagram.md) — cross-plugin entity relationship diagram
- Plugin guides in [docs/plugin-guide/](plugin-guide/) — per-plugin tutorials with worked examples
- Workflow guides in [docs/workflows/](workflows/) — end-to-end pipeline walkthroughs
