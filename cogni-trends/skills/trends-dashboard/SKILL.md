---
name: trends-dashboard
description: |
  Generate an interactive HTML dashboard showing the full TIPS project lifecycle.
  Use whenever the user mentions tips dashboard, trend dashboard, TIPS overview,
  "show me the trends", "visualize tips", "tips project view", TIPS status dashboard,
  or wants to see all trend scouting data in a browser — even if they don't say "dashboard".
  Also trigger at the end of heavy TIPS sessions (after trend-report, value-modeler, or
  catalog import) as a capstone visualization.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
---

# TIPS Dashboard

Generate a self-contained HTML dashboard that visualizes the entire TIPS project lifecycle — from trend scouting candidates through value modeling themes to report and catalog status. The dashboard opens in the user's browser with an interactive three-panel layout inspired by knowledge-graph explorers.

## Context Independence

This skill reads ALL required state from project files (trend-scout output, value model, report, catalog) — it does not depend on prior conversation context. If invoked after trends-resume or at the end of a heavy session, **context compaction is safe and recommended** before starting.

**Before executing Step 1**, run `/compact` to free working memory. Dashboard generation reads multiple large JSON files and produces a self-contained HTML document with embedded D3 visualizations — maximum available context ensures the full project data can be processed in one pass.

If `/compact` is unavailable or this is the first skill in the session, skip compaction and proceed directly.

## Core Concept

TIPS projects produce rich structured data across multiple phases (trend-scout → value-modeler → trend-report → catalog). This data lives in separate JSON files and markdown outputs that are hard to reason about in aggregate. The dashboard turns all of it into a single interactive visual — navigating phases, drilling into entities, and exploring TIPS relationships (Trend → Implication → Possibility → Solution) through a force-directed graph.

It complements `trends-resume` (quick text-based status check) the way `portfolio-dashboard` complements `portfolio-resume` in cogni-portfolio: one is for quick re-entry, the other for visual exploration and presentation.

## Information Architecture

The layout follows a three-panel design with phase-based navigation:

```
┌─────────────────────────────────────────────────────────────┐
│ NAVBAR: [Overview] [Scout] [Value Model] [Report] [Catalog] │
└─────────────────────────────────────────────────────────────┘
┌────────────┬──────────────────────────┬─────────────────────┐
│ LEFT       │  MAIN CONTENT            │ RIGHT PANEL         │
│ Section    │  (phase-specific)        │ ┌─────────────────┐ │
│ Index      │                          │ │   TIPS Graph    │ │
│            │                          │ │   (D3 force)    │ │
│ - item     │                          │ │   T → I → P → S │ │
│ - item     │                          │ ├─────────────────┤ │
│ - item     │                          │ │  Entity Detail  │ │
│            │                          │ │  (on click)     │ │
│            │                          │ └─────────────────┘ │
└────────────┴──────────────────────────┴─────────────────────┘
```

**Navbar** — sticky horizontal bar with phase tabs. Active tab highlighted with accent color. Hash-based routing (`#overview`, `#scout`, `#model`, `#report`, `#catalog`).

**Left Panel** — persistent section index for the active tab. In Scout: dimension list. In Value Model: investment theme list. In Report: section list. Clicking scrolls the main content. Highlights current section on scroll.

**Right Panel** — always visible, collapsible to icon rail. Top 60%: D3 force-directed graph showing TIPS entity relationships colored by dimension, grouped by investment theme. Bottom 40%: entity detail panel populated when clicking a graph node or entity card. Draggable resize handle between zones.

## Workflow

### 1. Find the Active TIPS Project

Discover TIPS projects using the discovery script:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

If multiple projects exist, ask the user which one to open. Store the resolved project directory path.

### 2. Pick Theme

Use the `cogni-workspace:pick-theme` skill to let the user select a theme. The skill returns `theme_path`, `theme_name`, and `theme_slug`.

**Skip conditions** (auto-select without prompting):
- The caller already provided a `theme_path`
- Only one theme exists in the workspace (auto-select it)

### 3. Generate Design Variables

Read the selected `theme.md` file and produce a design-variables JSON file at `<project-dir>/output/design-variables.json`.

The JSON must follow the schema at `$CLAUDE_PLUGIN_ROOT/skills/trends-dashboard/schemas/design-variables.schema.json`. See the example at `$CLAUDE_PLUGIN_ROOT/skills/trends-dashboard/examples/design-variables-cogni-work.json` for the exact format.

**What the LLM adds** beyond a raw token extraction:
- Derives `surface2` (~4% darker than `surface`) if not explicit in the theme
- Computes `accent_muted` and `accent_dark` variants if the theme only defines `accent`
- Builds a Google Fonts `@import` URL from the font families
- Adjusts shadow opacity for dark themes (higher opacity for light-on-dark)
- Ensures WCAG AA contrast between `text` and `background`, `text_light` and `surface_dark`
- Sets `radius` and `shadows` appropriate to the theme's visual style
- Adds `dimensions` color palette (4 colors for the TIPS dimensions: T, I, P, S)

**Required fields**: `theme_name`, `colors` (all 13 keys), `status` (4 keys), `fonts` (3 keys).
**Optional fields with defaults**: `google_fonts_import` (empty), `radius` ("12px"), `shadows` (standard set).

### 4. Generate the Dashboard

Run the dashboard generator script:

```bash
python3 $CLAUDE_PLUGIN_ROOT/skills/trends-dashboard/scripts/generate-dashboard.py "<project-dir>" --design-variables "<project-dir>/output/design-variables.json"
```

The script:
- Reads `tips-project.json` for project metadata
- Reads `.metadata/trend-scout-output.json` for candidates, scoring, source integrity
- Reads `tips-value-model.json` for themes, value chains, solution templates, rankings
- Reads `tips-trend-report-claims.json` for claims registry (if present)
- Reads `.metadata/value-modeler-output.json` for modeling state (if present)
- Checks for `tips-trend-report.md` and `tips-insight-summary.md` existence
- Runs `project-status.sh` for phase and progress data
- Scans catalog directory for catalog.json (if present)
- Loads the design-variables JSON for theming
- Generates a self-contained HTML file at `<project-dir>/output/trends-dashboard.html`
- Returns JSON: `{"status": "ok", "path": "<output-path>", "theme": "<name>"}`

**Legacy fallback**: The script also accepts `--theme <path-to-theme.md>` for CI/automated runs.

### 5. Open in Browser

```bash
open "<project-dir>/output/trends-dashboard.html"
```

Tell the user the dashboard is open. If they want to refresh after making changes, just rerun the script.

## Dashboard Tabs

### Tab 1: Overview

Project header with name, industry, subsector, research topic, language, and last-updated timestamp. Below that:

- **Phase Progress Bar** — visual 8-stage pipeline (Web Research → Candidate Gen → Selection → Report → Claims → Insight → Verification → Polish) with completed/active/pending states
- **Scoring Summary Cards** — average score, leading indicator %, confidence distribution (high/medium/low) as donut chart
- **Dimension × Horizon Heatmap** — 4×3 grid (dimensions as rows, horizons ACT/PLAN/OBSERVE as columns) with candidate counts per cell, color-coded by density. Click a cell to filter the graph to that dimension+horizon
- **Source Coverage** — total candidates, unique web sources, cells with/without candidates

**Left index**: Progress stages (clickable, scrolls to section).

### Tab 2: Scout

Deep dive into the web-grounded trend candidates from trend-scout:

- **Candidate Cards** — grouped by dimension, each showing: name, statement, score badge, confidence tier, signal intensity, indicator type (leading/lagging/coincident), diffusion stage, source URL, freshness date
- **Distribution Charts** — score histogram, confidence pie, indicator type breakdown, diffusion stage funnel
- **Coverage Analysis** — candidates per cell heatmap, empty cells highlighted, source diversity

**Left index**: Four dimensions (Externe Effekte, Neue Horizonte, Digitale Wertetreiber, Digitales Fundament — or EN equivalents based on project language). Click to scroll to that dimension's candidates.

**Graph interaction**: Clicking a candidate card highlights it in the right-panel graph and shows its relationships (which implications/possibilities link to it).

### Tab 3: Value Model

Strategic themes and solution ranking from value-modeler:

- **Theme Cards** — one per strategic theme showing: name, strategic question, executive sponsor type, narrative summary, business relevance average, ranking value. Expandable to show value chains
- **Value Chain Flows** — visual T→I→P flow diagrams per theme, showing how trends connect through implications to possibilities. Each node in the flow is clickable (populates entity detail)
- **Solution Template Ranking** — sorted table of all STs with: name, category, enabler type, theme, BR score, F1+ ranking value, readiness score, linked chains count. Color-coded rows by ranking tier. Portfolio-anchored STs show an anchor badge with their feature slug. Readiness column shows the blueprint readiness score with a colored indicator (green ≥0.8, amber ≥0.5, red <0.5)
- **Solution Blueprint Panel** — multi-dimensional portfolio composition view for all STs:
  - **Taxonomy Radar Chart**: 8-spoke radar (one per B2B ICT dimension 0-7) showing aggregate blueprint coverage across all STs that have blueprints. Each spoke = mean of role-weighted coverage values for that dimension. Coverage numeric mapping: covered=1.0, partial=0.5, gap=0.0, unknown=0.0. Role weights match the readiness formula (lead=0.5, supporting=0.3, enabling=0.2). STs without blueprints are excluded from the aggregation. Immediately shows portfolio strengths and gaps at a glance
  - **Blueprint Cards per ST**: within each theme section, compact blueprint visualization:
    ```
    ST-001: Predictive Quality Analytics Platform
    ┌─────────────────────────────────────────────────┐
    │ ● Lead:  6.6 AI & Analytics    ██████████ 100%  │
    │ ◐ Supp:  1.4 IoT Connectivity  █████░░░░░  50%  │
    │ ● Supp:  4.6 Cloud-Native      ██████████ 100%  │
    │ ✗ Enab:  7.2 Digital Transform  ░░░░░░░░░░   0%  │
    │                                                   │
    │ Readiness: 0.68  Span: 4 dimensions              │
    └─────────────────────────────────────────────────┘
    ```
  - **Taxonomy Gap Heatmap**: rows are dimensions (0-7), cells are individual taxonomy categories within that dimension. Only show categories referenced by at least one ST's blueprint. Color each cell by worst coverage across any ST needing that category: red = at least one ST has it as gap, amber = worst is partial (no gaps), green = all STs have it covered. Show coverage percentage per dimension row (covered cells / total cells in row). Sparse dimensions (few categories referenced) are expected — not all 57 categories will appear
  - Only appears when at least one ST has a `solution_blueprint`
- **Portfolio Anchor Coverage** — when Solution Templates have `generation_mode: "portfolio-anchored"`, shows anchor coverage stats (anchored vs abstract STs, delivered/unmet needs), collapsible theme cards with per-ST anchor details including feature/product slugs and need pills (green = delivered, red = unmet). Quality flags are surfaced. Only appears when at least one ST is portfolio-anchored
- **SPIs & Metrics** — collapsible section showing Solution Process Improvements and success KPIs per theme

**Left index**: Theme names. Click to scroll to that theme's section.

**Graph interaction**: The right-panel graph shows the full TIPS network — Trends (amber), Implications (cyan), Possibilities (purple), Solutions (green) — connected by value chain links. Clicking a theme in the left index filters the graph to that theme's entities.

### Tab 4: Report

Full rendered trend report content from `tips-trend-report.md`, plus claims data:

- **Report Status** — metadata cards showing report/claims/insight existence, investment theme count, industry, language
- **Executive Summary** — full rendered executive summary with inline citation links, investment theme overview, and cost-of-inaction framing
- **Investment Themes** — each theme rendered as a styled card with: strategic question (blockquote), Why Change narrative, Why Now forcing functions, Why You solution capabilities, Why Pay business case. Inline citations rendered as clickable links
- **Portfolio Analysis** — theme overview tables, horizon distribution, MECE validation, evidence coverage (if present in the report)
- **Claims Registry** — table of all claims with: statement, verification status badge (verified/unverified/deviated/resolved), source URL

**Left index**: Status, Summary, each investment theme by name, Claims.

### Tab 5: Catalog

Industry catalog status (shown only if a catalog exists):

- **Catalog Header** — industry, subsector, entity counts, last updated
- **Taxonomy Coverage Heatmap** — 8 dimensions × categories grid (from b2b-ict-portfolio taxonomy). Green = mapped, red = gap. Coverage percentage chip
- **Entity Counts** — TIP entities, solution templates, SPIs, metrics, collaterals
- **Pursuit History** — timeline of contributions from different projects
- **Cross-Pursuit Analytics** — trend frequency, solution popularity, BR distribution (if multiple pursuits)

**Left index**: Taxonomy dimensions. Click to scroll to that dimension's categories.

## Right Panel: TIPS Graph

The graph is the signature element of this dashboard. It visualizes the TIPS relationship network as a D3 force-directed graph:

- **Node types** (color + shape):
  - Trend (T) — amber circle
  - Implication (I) — cyan diamond
  - Possibility (P) — purple square
  - Solution (S) — green hexagon; portfolio-anchored STs show a small anchor (⚓) overlay
- **Edges**: Value chain links (T→I, I→P, P→S) shown as directed arrows
- **Grouping**: Nodes cluster by strategic theme (force-directed with theme gravity wells)
- **Sizing**: Node radius proportional to score or BR value
- **Filters**: Toggle buttons in graph-controls to show/hide each TIPS type
- **Interaction**:
  - Hover: highlight connected edges and nodes
  - Click: populate entity-detail-zone below with full entity data
  - Drag: reposition nodes
  - Zoom/pan: mouse wheel and drag on background

**Entity Detail Zone** (below graph):
- Entity name, type badge, dimension badge
- Full statement/description
- Score, confidence, source (for candidates)
- BR score, ranking value, linked chains (for solution templates)
- Solution blueprint: building blocks with role badges, taxonomy refs, coverage indicators, readiness score with progress bar. Gap blocks highlighted as "investment opportunity" (for solution templates with blueprints)
- Related entities list (clickable, navigates graph)
- Portfolio anchor data (feature slug, product slug, delivered/undelivered needs, quality flag) for portfolio-anchored solution nodes

When no entity is selected, shows a prompt: "Click a node in the graph or an entity card to see details."

## Shared Pattern

This dashboard follows the design-variables pattern documented at `cogni-workspace/references/design-variables-pattern.md`. It uses the same 3-stage flow as `portfolio-dashboard`: pick-theme → LLM derives design-variables.json → generator consumes JSON.

## Important Notes

- The dashboard is read-only — it shows TIPS project state, it does not modify entities
- The HTML file is fully self-contained (inline CSS + JS, D3 loaded from CDN)
- Re-running the script overwrites the previous dashboard
- The dashboard lives at `output/trends-dashboard.html`
- **Graceful degradation**: Tabs for phases that haven't been completed yet show a "Not yet available" state with a recommendation to run the relevant skill. The Overview tab always works (even with just a tips-project.json)
- **Communication Language**: This skill follows the shared language resolution pattern (see `$CLAUDE_PLUGIN_ROOT/references/language-resolution.md`). Read workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD) first. If not found, fall back to project language from `tips-project.json`. Communicate with the user in this language. Technical terms, skill names, and CLI commands remain in English.

## Session Management

Dashboard generation is a capstone operation — it gives the user a complete visual overview and typically signals a natural pause point. After generating the dashboard, always recommend starting a fresh session for next steps:

> "Dashboard ready at `output/trends-dashboard.html`. For next steps like [recommend from next_actions], I'd recommend starting a fresh session with `/trends-resume`. That picks up the current state cleanly and gives you full context for the next phase."

Use the project's communication language. Frame it as helpful advice, not a limitation.
