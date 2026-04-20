---
name: portfolio-dashboard
description: |
  Generate an interactive HTML dashboard showing the full portfolio status.
  Use whenever the user mentions dashboard, portfolio dashboard, portfolio view,
  "show me the portfolio", "visualize portfolio", status overview, or wants to
  see all portfolio data in a browser — even if they don't say "dashboard".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# Portfolio Dashboard

Generate a self-contained HTML dashboard that visualizes the entire portfolio — entity counts, completion progress, the Feature x Market matrix, market sizing, pricing, competitors, customer profiles, and claims status. The dashboard opens in the user's browser and supports drill-down navigation into every entity.

## Core Concept

The dashboard turns scattered JSON entity files into a single visual overview. Unlike the text-based `portfolio-resume` skill (quick status check), the dashboard is designed for visual exploration — clicking through entities, scanning the proposition matrix, comparing pricing across markets, and spotting gaps at a glance.

It matters because portfolio data lives in dozens of small JSON files that are hard to reason about in aggregate. A visual dashboard makes coverage, gaps, and relationships immediately visible without reading markdown or running shell commands.

## Workflow

### 1. Find the Active Portfolio Project

Scan the workspace for `portfolio.json` files under `cogni-portfolio/` paths. If multiple projects exist, ask the user which one to open. Store the resolved project directory path.

### 2. Pick Theme

First, check if `<project-dir>/output/design-variables.json` already exists from a previous dashboard run. If it does, ask the user: "A dashboard theme is already configured. Reuse it, or pick a new one?" Default to reuse — most re-runs just want fresh data with the same look.

- **If reusing**: skip directly to step 4 (Generate the Dashboard). Steps 2 and 3 are done.
- **If picking new** (or no design-variables exist): use the `cogni-workspace:pick-theme` skill to let the user select a theme. The skill returns `theme_path`, `theme_name`, and `theme_slug`.

**Additional skip conditions** (auto-select without prompting):
- The caller already provided a `theme_path`
- Only one theme exists in the workspace (auto-select it)

### 3. Generate Design Variables

Read the selected `theme.md` file and produce a design-variables JSON file at `<project-dir>/output/design-variables.json`.

The JSON must follow the schema at `$CLAUDE_PLUGIN_ROOT/skills/portfolio-dashboard/schemas/design-variables.schema.json`. See the example at `$CLAUDE_PLUGIN_ROOT/skills/portfolio-dashboard/examples/design-variables-cogni-work.json` for the exact format.

**What the LLM adds** beyond a raw token extraction:
- Derives `surface2` (~4% darker than `surface`) if not explicit in the theme
- Computes `accent_muted` and `accent_dark` variants if the theme only defines `accent`
- Builds a Google Fonts `@import` URL from the font families
- Adjusts shadow opacity for dark themes (higher opacity for light-on-dark)
- Ensures WCAG AA contrast between `text` and `background`, `text_light` and `surface_dark`
- Sets `radius` and `shadows` appropriate to the theme's visual style

**Required fields**: `theme_name`, `colors` (all 13 keys), `status` (4 keys), `fonts` (3 keys).
**Optional fields with defaults**: `google_fonts_import` (empty), `radius` ("12px"), `shadows` (standard set).

### 4. Generate the Dashboard

Run the dashboard generator script with the design-variables JSON:

```bash
python3 $CLAUDE_PLUGIN_ROOT/skills/portfolio-dashboard/scripts/generate-dashboard.py "<project-dir>" --design-variables "<project-dir>/output/design-variables.json"
```

The script:
- Reads `portfolio.json` and all entity directories (products, features, markets, propositions, solutions, competitors, customers)
- Reads `cogni-claims/claims.json` if present
- Discovers linked TIPS projects (via `tips_enrichment.pursuit_slug` on propositions or `cogni-trends/*/tips-project.json` with matching `portfolio_source`) and loads portfolio-anchored Solution Templates and `portfolio-opportunities.json`
- Runs `project-status.sh` for counts and completion data
- Loads the design-variables JSON for colors, typography, shadows, and radius
- Generates a self-contained HTML file at `<project-dir>/output/dashboard.html`
- Returns JSON with `{"status": "ok", "path": "<output-path>", "theme": "<name>", "design_variables": "<path>"}` on success

**Legacy fallback**: The script still accepts `--theme <path-to-theme.md>` for CI/automated runs. When used, it parses the theme.md directly via the built-in regex parser. Precedence: `--design-variables` > `--theme` > built-in defaults.

### 5. Open in Browser

```bash
open "<project-dir>/output/dashboard.html"
```

Tell the user the dashboard is open. If they want to refresh after making changes to entities, just rerun the script.

## Dashboard Sections

The generated HTML includes these sections, all in a single-page app with drill-down panels:

0. **Sticky Navigation** — Pill-style nav bar with section links, active state tracking via scroll detection, backdrop blur. Click any link to smooth-scroll to that section. Nav order follows the portfolio workflow: Overview → Products → [Provider units] → Markets → Matrix → Taxonomy → [Anchors] → Customers → Solutions → Packages → Margins → [Pipeline] → [Communicate] → Claims → Actions.
1. **Header** — Company name, industry, project slug, last updated. Bricolage Grotesque typography with gradient mesh background.
2. **Phase & Progress** — Current workflow phase with visual progress bar, completion percentages per entity type
3. **Entity Counts** — Card grid showing products, features, markets, propositions, solutions, packages, competitors, customers with counts, completion bars, and expected totals
4. **Products & Features** — Grouped by product with revenue model chip (subscription/project/partnership/hybrid), maturity stage. Features show readiness indicator (GA/Beta/Planned) with color-coded dot. When a feature has portfolio-anchored Solution Templates, an anchor badge shows the ST count (e.g., "⚓ 3 STs").
4a. **Provider units** — renders from either of two sources (scan-output takes precedence when present). Fully absent when neither source yields a provider unit.
   - **Source 1 — `scan-output` (diagnostic)**: shown when `research/.metadata/scan-output.json` v1.2.0+ exists with a non-empty `provider_units` array (portfolio was built via `portfolio-scan`). Section header reads "Provider units (scan diagnostic)". Footer shows scan date and `scan-output.json v1.2.0`. Diagnostic only — authoritative feature-to-unit mapping lives in each feature's `source_lineage`.
   - **Source 2 — `features` (authoritative)**: fallback when `scan-output.json` is absent but individual features carry a `provider_unit: {code, name, country, tier}` block (e.g., portfolios built via `portfolio-web-researcher`). Section header reads "Provider units (from feature metadata)". Each card gains a `country · tier` subline not available from scan-output. Footer shows `derived from N features` instead of scan metadata. Aggregated on the fly from per-feature `provider_unit.code`.
5. **Markets Overview** — Cards per market with TAM/SAM/SOM bars, region badge, priority badge (beachhead/expansion/aspirational), segmentation criteria. Click to see customer profiles and all propositions targeting that market
6. **Feature x Market Matrix** — Interactive grid. Each cell is color-coded (green = proposition + solution, yellow = proposition only, red = missing). When a proposition has variants, display a variant count badge on the cell (e.g., "3v" pill). When a proposition has a `quality_assessment`, display a quality badge on the cell: green dot for `"pass"`, yellow dot for `"warn"`, red dot for `"fail"`. Click a cell to expand IS/DOES/MEANS, pricing tiers (type-aware: project/subscription/partnership), unit economics, and competitor summary. The drill-down panel includes a "Quality Assessment" section (when present) showing the overall score and per-dimension pass/warn/fail for DOES and MEANS, with `assessed_at` date. Below that, a collapsible "Variants" section lists all variants with their angle label, DOES/MEANS summary, tips_ref, and quality score. Variants are sorted by variant_id. The section is collapsed by default and shows a count header (e.g., "Variants (3)"). Competitor data for each proposition also appears in this drill-down panel (not as a standalone section).
7. **Taxonomy Coverage** — (shown when `portfolio.json` has a `taxonomy` field) Heatmap grid showing all 8 dimensions x categories from the b2b-ict taxonomy. Green cells = category has mapped features, red cells = gap. Summary chip shows X of 57 covered (Y%). Below the heatmap: Gap Analysis listing uncovered categories grouped by dimension.
8. **Anchor Coverage** — (shown when linked TIPS project has portfolio-anchored STs) Per-feature cards showing which Solution Templates are anchored to each feature. Summary bar: X features anchored / Y total, Z STs, W unmet needs. Each card shows aggregated delivered needs (green pills) and undelivered needs (red pills). Quality flag badges when `quality_flag == "quality_investment_needed"`. Click-to-expand shows individual STs with theme_ref and full needs breakdown. Bottom section aggregates all unmet needs feeding the opportunity pipeline.
9. **Target Customers** (if any customer files have `named_customers`) — Per-market named company cards with fit score badges (green/yellow/red), industry, headquarters, revenue, and pain points. Click a card to expand full profile with tech stack pills, fit rationale, source URLs, and researched date. Buyer personas for the market are shown below for context. Hidden when no named customers exist.
10. **Solutions & Pricing** — Solutions grouped by type. Blueprint coverage summary shows how many solutions were generated from delivery blueprints and how many have version drift. Each solution row shows a blueprint badge: green "bp vN" when current, red "drift vN→vM" when the product's blueprint has been updated since generation. Project solutions show implementation timeline and pricing tiers (PoV/S/M/L). Subscription solutions show onboarding, subscription tiers (Free/Pro/Enterprise), and professional services. Partnership solutions show program stages and revenue-share terms.
11. **Packages** — Product bundles as clickable cards. Each package shows product->market, package type chip, positioning, and tier cards with pricing and included solution pills. Click to drill down into full tier detail with bundle savings.
12. **Margin Health** (if any solutions have `cost_model`) — Separated by solution type. Project solutions show effort-based margins per tier. Subscription solutions show unit economics (LTV/CAC, gross margin, churn). Color-coded: green for healthy, yellow for below-target, red for negative/failing. This section is marked INTERNAL/CONFIDENTIAL.
13. **Innovation Pipeline** — (shown when `portfolio-opportunities.json` exists in a linked TIPS project) Summary stats: total opportunities, estimated revenue, build/buy/partner breakdown. Opportunity cards sorted by `opportunity_score` (descending). Each card shows: opportunity name, score gauge (0-10, color gradient green/yellow/red), classification badge (build/buy/partner), priority badge (high/medium/low), revenue estimate with confidence, feature spec description, unmet needs as pills, and source ST reference. Hidden when no opportunities file exists.
14. **Portfolio Communications** — (shown when `output/communicate/` has files) Rich content section grouped by use case (Customer Narratives, Pitches, Proposals, Market Briefs, Repository Documentation, Workbooks). Coverage summary bar shows market/proposition coverage per use case (e.g., "Narratives: 3/5 markets", "Proposals: 8/15 propositions"). Each card shows: title from YAML frontmatter (fallback to filename), scope chip (Overview/Market/Customer), date created, source entity counts (products, features, propositions used), content preview snippet (~150 chars), review verdict badge with per-perspective mini-scorecard. Pitch files show arc_id chip. Workbook files show XLSX badge with file size. Unknown use cases appear in an "Other" group. Hidden when no communicate output exists.
15. **Claims Status** — Verification summary (verified, unverified, deviated, resolved) with progress bar
16. **Next Actions** — Recommended next skills from project-status

## Shared Pattern

This dashboard is the **reference implementation** of the design-variables pattern documented at `cogni-workspace/references/design-variables-pattern.md`. Other plugins building themed HTML dashboards (cogni-trends trend-report, scoring-ui, catalog) should follow the same 3-stage flow: pick-theme → LLM derives design-variables.json → generator consumes JSON.

## Milestone Dashboard

The dashboard is not only a capstone deliverable — it is also a review tool at major workflow milestones. Other portfolio skills (features, propositions, solutions) have review checkpoints where they offer the user the option to "open the dashboard for a visual overview." When the user accepts that offer, the calling skill should generate a fresh dashboard snapshot so the user can see the current state before proceeding.

### When to offer a milestone dashboard

Skills should offer a dashboard at these checkpoints:
- **Features skill**: After quality assessment passes and before stakeholder review runs — the user can verify the feature set visually
- **Propositions skill**: Before batch generation starts (to review the Feature x Market matrix and feature readiness) and after batch generation completes (to see the newly populated proposition matrix with quality dots and variant badges)
- **Solutions skill**: After solution generation completes — the user can verify pricing tiers and margin health

### How it works at a checkpoint

When a skill offers "open the dashboard" at a review checkpoint:
1. Delegate to the `dashboard-refresher` agent with `project_dir` and `plugin_root: $CLAUDE_PLUGIN_ROOT` to regenerate and open the dashboard
2. After the dashboard opens, the calling skill resumes and asks the user if they're ready to proceed
3. The dashboard generation is a snapshot — it reflects the portfolio state at that moment, which is exactly what the user needs to review before the next phase changes things

This is lightweight — the generator script runs in seconds and the HTML is self-contained. The cost of generating an intermediate dashboard is negligible compared to the cost of the user discovering problems after the next phase has already run.

## Important Notes

- The dashboard is read-only — it shows portfolio state, it does not modify entities
- The HTML file is fully self-contained (inline CSS + JS, no external dependencies)
- Re-running the script overwrites the previous dashboard
- The dashboard lives at `output/dashboard.html`
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.

