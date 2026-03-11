---
name: dashboard
description: |
  Generate an interactive HTML dashboard showing the full portfolio status.
  Use whenever the user mentions dashboard, portfolio dashboard, portfolio view,
  "show me the portfolio", "visualize portfolio", status overview, or wants to
  see all portfolio data in a browser — even if they don't say "dashboard".
---

# Portfolio Dashboard

Generate a self-contained HTML dashboard that visualizes the entire portfolio — entity counts, completion progress, the Feature x Market matrix, market sizing, pricing, competitors, customer profiles, and claims status. The dashboard opens in the user's browser and supports drill-down navigation into every entity.

## Core Concept

The dashboard turns scattered JSON entity files into a single visual overview. Unlike the text-based `resume-portfolio` skill (quick status check) or `synthesize` (markdown messaging repository), the dashboard is designed for visual exploration — clicking through entities, scanning the proposition matrix, comparing pricing across markets, and spotting gaps at a glance.

It matters because portfolio data lives in dozens of small JSON files that are hard to reason about in aggregate. A visual dashboard makes coverage, gaps, and relationships immediately visible without reading markdown or running shell commands.

## Workflow

### 1. Find the Active Portfolio Project

Scan the workspace for `portfolio.json` files under `cogni-portfolio/` paths. If multiple projects exist, ask the user which one to open. Store the resolved project directory path.

### 2. Generate the Dashboard

Run the dashboard generator script:

```bash
python3 $CLAUDE_PLUGIN_ROOT/skills/dashboard/scripts/generate-dashboard.py "<project-dir>" [--theme <path-to-theme.md>]
```

The script:
- Reads `portfolio.json` and all entity directories (products, features, markets, propositions, solutions, competitors, customers)
- Reads `cogni-claims/claims.json` if present
- Runs `project-status.sh` for counts and completion data
- Parses a cogni-workspace theme.md file for colors, typography, and status colors (auto-discovers cogni-work theme if no `--theme` is given)
- Generates a self-contained HTML file at `<project-dir>/output/dashboard.html`
- Returns JSON with `{"status": "ok", "path": "<output-path>", "theme": "<name>"}` on success

The theme is a runtime variable. Any cogni-workspace theme.md file works — the parser extracts color palette tokens (`**Name**: \`#HEX\``), status colors, and typography from the markdown. To use a different theme, pass `--theme <path>` pointing to any theme.md in the workspace's `themes/` directory.

### 3. Open in Browser

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
4. **Feature x Market Matrix** — Interactive grid. Each cell is color-coded (green = proposition + solution, yellow = proposition only, red = missing). Click a cell to expand IS/DOES/MEANS, pricing tiers (type-aware: project/subscription/partnership), unit economics, and competitor summary
5. **Markets Overview** — Cards per market with TAM/SAM/SOM bars, region badge, priority badge (beachhead/expansion/aspirational), segmentation criteria. Click to see customer profiles and all propositions targeting that market
6. **Products & Features** — Grouped by product with revenue model chip (subscription/project/partnership/hybrid), maturity stage. Features show readiness indicator (GA/Beta/Planned) with color-coded dot.
7. **Solutions & Pricing** — Solutions grouped by type. Project solutions show implementation timeline and pricing tiers (PoV/S/M/L). Subscription solutions show onboarding, subscription tiers (Free/Pro/Enterprise), and professional services. Partnership solutions show program stages and revenue-share terms.
8. **Packages** — Product bundles as clickable cards. Each package shows product→market, package type chip, positioning, and tier cards with pricing and included solution pills. Click to drill down into full tier detail with bundle savings.
9. **Margin Health** (if any solutions have `cost_model`) — Separated by solution type. Project solutions show effort-based margins per tier. Subscription solutions show unit economics (LTV/CAC, gross margin, churn). Color-coded: green for healthy, yellow for below-target, red for negative/failing. This section is marked INTERNAL/CONFIDENTIAL.
10. **Competitive Landscape** — Per-proposition competitor cards with strengths/weaknesses
11. **Claims Status** — Verification summary (verified, unverified, deviated, resolved) with progress bar
12. **Next Actions** — Recommended next skills from project-status

## Important Notes

- The dashboard is read-only — it shows portfolio state, it does not modify entities
- The HTML file is fully self-contained (inline CSS + JS, no external dependencies)
- Re-running the script overwrites the previous dashboard
- The dashboard lives at `output/dashboard.html` alongside the synthesis README
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.

## Session Management

Dashboard generation is a capstone operation — it gives the user a complete visual overview and typically signals a natural pause point. After generating the dashboard, always recommend starting a fresh session for next steps:

> "Dashboard ready at `output/dashboard.html`. For next steps like [recommend from next_actions], I'd recommend starting a fresh session with `/resume-portfolio`. That picks up the current state cleanly and gives you full context for the next phase."

If the dashboard was generated after other heavy skills in the same session (batch propositions, feature reviews, etc.), be especially proactive — summarize what was accomplished in this session and frame the fresh start as the best way to maintain quality.

Use the portfolio's communication language (read `portfolio.json` for the `language` field). Frame it as helpful advice, not a limitation.
