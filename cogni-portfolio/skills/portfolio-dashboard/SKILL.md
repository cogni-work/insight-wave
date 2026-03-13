---
name: portfolio-dashboard
description: |
  Generate an interactive HTML dashboard showing the full portfolio status.
  Use whenever the user mentions dashboard, portfolio dashboard, portfolio view,
  "show me the portfolio", "visualize portfolio", status overview, or wants to
  see all portfolio data in a browser — even if they don't say "dashboard".
---

# Portfolio Dashboard

Generate a self-contained HTML dashboard that visualizes the entire portfolio — entity counts, completion progress, the Feature x Market matrix, market sizing, pricing, competitors, customer profiles, and claims status. The dashboard opens in the user's browser and supports drill-down navigation into every entity.

## Core Concept

The dashboard turns scattered JSON entity files into a single visual overview. Unlike the text-based `portfolio-resume` skill (quick status check) or `synthesize` (markdown messaging repository), the dashboard is designed for visual exploration — clicking through entities, scanning the proposition matrix, comparing pricing across markets, and spotting gaps at a glance.

It matters because portfolio data lives in dozens of small JSON files that are hard to reason about in aggregate. A visual dashboard makes coverage, gaps, and relationships immediately visible without reading markdown or running shell commands.

## Workflow

### 1. Find the Active Portfolio Project

Scan the workspace for `portfolio.json` files under `cogni-portfolio/` paths. If multiple projects exist, ask the user which one to open. Store the resolved project directory path.

### 2. Pick Theme

Use the `cogni-workspace:pick-theme` skill to let the user select a theme. The skill returns `theme_path`, `theme_name`, and `theme_slug`.

**Skip conditions** (auto-select without prompting):
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

0. **Sticky Navigation** — Pill-style nav bar with section links, active state tracking via scroll detection, backdrop blur. Click any link to smooth-scroll to that section.
1. **Header** — Company name, industry, project slug, last updated. Bricolage Grotesque typography with gradient mesh background.
2. **Phase & Progress** — Current workflow phase with visual progress bar, completion percentages per entity type
3. **Entity Counts** — Card grid showing products, features, markets, propositions, solutions, packages, competitors, customers with counts, completion bars, and expected totals
4. **Feature x Market Matrix** — Interactive grid. Each cell is color-coded (green = proposition + solution, yellow = proposition only, red = missing). When a proposition has variants, display a variant count badge on the cell (e.g., "3v" pill). When a proposition has a `quality_assessment`, display a quality badge on the cell: green dot for `"pass"`, yellow dot for `"warn"`, red dot for `"fail"`. Click a cell to expand IS/DOES/MEANS, pricing tiers (type-aware: project/subscription/partnership), unit economics, and competitor summary. The drill-down panel includes a "Quality Assessment" section (when present) showing the overall score and per-dimension pass/warn/fail for DOES and MEANS, with `assessed_at` date. Below that, a collapsible "Variants" section lists all variants with their angle label, DOES/MEANS summary, tips_ref, and quality score. Variants are sorted by variant_id. The section is collapsed by default and shows a count header (e.g., "Variants (3)").
5. **Markets Overview** — Cards per market with TAM/SAM/SOM bars, region badge, priority badge (beachhead/expansion/aspirational), segmentation criteria. Click to see customer profiles and all propositions targeting that market
6. **Products & Features** — Grouped by product with revenue model chip (subscription/project/partnership/hybrid), maturity stage. Features show readiness indicator (GA/Beta/Planned) with color-coded dot.
6b. **Taxonomy Coverage** — (shown when `portfolio.json` has a `taxonomy` field) Heatmap grid showing all 8 dimensions x categories from the b2b-ict taxonomy. Green cells = category has mapped features, red cells = gap. Summary chip shows X of 57 covered (Y%). Below the heatmap: Gap Analysis listing uncovered categories grouped by dimension.
7. **Solutions & Pricing** — Solutions grouped by type. Project solutions show implementation timeline and pricing tiers (PoV/S/M/L). Subscription solutions show onboarding, subscription tiers (Free/Pro/Enterprise), and professional services. Partnership solutions show program stages and revenue-share terms.
8. **Packages** — Product bundles as clickable cards. Each package shows product->market, package type chip, positioning, and tier cards with pricing and included solution pills. Click to drill down into full tier detail with bundle savings.
9. **Margin Health** (if any solutions have `cost_model`) — Separated by solution type. Project solutions show effort-based margins per tier. Subscription solutions show unit economics (LTV/CAC, gross margin, churn). Color-coded: green for healthy, yellow for below-target, red for negative/failing. This section is marked INTERNAL/CONFIDENTIAL.
10. **Target Customers** (if any customer files have `named_customers`) — Per-market named company cards with fit score badges (green/yellow/red), industry, headquarters, revenue, and pain points. Click a card to expand full profile with tech stack pills, fit rationale, source URLs, and researched date. Buyer personas for the market are shown below for context. Hidden when no named customers exist.
11. **Competitive Landscape** — Per-proposition competitor cards with strengths/weaknesses
12. **Innovation Pipeline** — (shown when `portfolio-opportunities.json` exists in a linked TIPS project) Opportunity cards sorted by `opportunity_score`. Each card shows: opportunity name, score gauge (0-10, color gradient), classification badge (build/buy/partner), revenue estimate, priority badge (high/medium/low), and the feature spec summary. Unmet needs shown as pills. Cards link back to source ST via `tips_ref`. Summary bar at top: N opportunities, total estimated revenue, classification breakdown pie chart. Hidden when no opportunities file exists.
13. **Claims Status** — Verification summary (verified, unverified, deviated, resolved) with progress bar
14. **Next Actions** — Recommended next skills from project-status

## Shared Pattern

This dashboard is the **reference implementation** of the design-variables pattern documented at `cogni-workspace/references/design-variables-pattern.md`. Other plugins building themed HTML dashboards (cogni-tips trend-report, scoring-ui, catalog) should follow the same 3-stage flow: pick-theme → LLM derives design-variables.json → generator consumes JSON.

## Important Notes

- The dashboard is read-only — it shows portfolio state, it does not modify entities
- The HTML file is fully self-contained (inline CSS + JS, no external dependencies)
- Re-running the script overwrites the previous dashboard
- The dashboard lives at `output/dashboard.html` alongside the synthesis README
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.

## Session Management

Dashboard generation is a capstone operation — it gives the user a complete visual overview and typically signals a natural pause point. After generating the dashboard, always recommend starting a fresh session for next steps:

> "Dashboard ready at `output/dashboard.html`. For next steps like [recommend from next_actions], I'd recommend starting a fresh session with `/portfolio-resume`. That picks up the current state cleanly and gives you full context for the next phase."

If the dashboard was generated after other heavy skills in the same session (batch propositions, feature reviews, etc.), be especially proactive — summarize what was accomplished in this session and frame the fresh start as the best way to maintain quality.

Use the portfolio's communication language (read `portfolio.json` for the `language` field). Frame it as helpful advice, not a limitation.
