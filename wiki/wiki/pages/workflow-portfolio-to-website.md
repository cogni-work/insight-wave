---
id: workflow-portfolio-to-website
title: "Workflow: Portfolio to Website (portfolio → workspace → website)"
type: summary
tags: [workflow, website, static-site, portfolio, theme]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-website.md
status: stable
related: [plugin-cogni-portfolio, plugin-cogni-workspace, plugin-cogni-website]
---

Generate a deployable customer website from your portfolio model and a workspace theme.

## Pipeline

```
cogni-portfolio                                    (propositions + features + customers)
   ↓ portfolio entities
cogni-workspace:manage-themes (Operation 11)       (active theme path)
   ↓ theme_path frontmatter contract
cogni-website:website-setup → website-plan → website-build → website-preview
   ↓
deployable static site (multi-page HTML + CSS + assets)
```

## Duration

2–4 hours for a complete multi-page customer website.

## End deliverable

A deployable static website with shared navigation, theming, and SEO-optimized service pages — generated from the portfolio model.

## How it works

[[plugin-cogni-portfolio]] is the content source: propositions become "What we do" service pages, features become capability pages, customer profiles inform persona-targeted landing pages, and competitive positioning shapes "Why us" pages.

[[plugin-cogni-workspace]] provides the theme via [[concept-theme-inheritance]]. The `theme_path` YAML frontmatter contract is the boundary: cogni-workspace sets it, cogni-website reads it and generates the shared CSS stylesheet from the theme's design variables.

[[plugin-cogni-website]] runs the assembly:

- `website-setup` — discovers content from portfolio, marketing, trends, research; picks theme; captures site config
- `website-plan` — proposes pages, maps content to sections, generates the page template specifications
- `website-build` — orchestrates CSS generation, parallel page generation, hero rendering (via Pencil MCP), and sitemap.xml
- `website-preview` — opens the site in browser via `claude-in-chrome` and validates links

Optional `website-legal` generates Impressum/Datenschutzerklärung/Cookie-Hinweis per jurisdiction.

## Multi-source variant

The same workflow extends to pull from [[plugin-cogni-marketing]] (thought-leadership → blog) and [[plugin-cogni-trends]] (trend reports → insights pages).

## Steps

**1 — Confirm the portfolio content.** `cogni-portfolio:portfolio-resume`. You need at least one product, propositions and customer profiles. Propositions become page headlines, features become capability lists, and customer narratives become case-study blocks. If propositions or customer profiles are missing, generate them first with `propositions` and `customers` — the website plan keys off them. Operational-only entities (a market with no propositions) never reach the site.

**2 — Pick or confirm a theme.** `cogni-workspace:manage-themes`, Operation 11 (Select Theme). The theme drives colors, fonts and design variables across every page. Switching it later and rebuilding reskins the whole site, so theme changes are global rather than per-page. Without a theme yet, run [[workflow-install-to-infographic]] first to set one up — import a Claude Design bundle (Operation 10) or start from a bundled preset (Operation 5).

**3 — Set up the website project.** `cogni-website:website-setup`. Takes a target directory plus target market, primary CTA and language; writes `website-project.json` with the discovered portfolio entities. Setup walks the optional content sources — cogni-marketing for blog and lead-gen pages, cogni-trends for insights pages, cogni-knowledge for whitepapers. Skip sources you have no content for; they can be added on a later run. The chosen language is the site's primary language.

**4 — Plan the sitemap.** `cogni-website:website-plan`. Produces `website-plan.json`: sitemap, content map, navigation flow. Review priorities before building — the planner picks defaults, but the running order shapes the homepage. Pages with shallow sources (a proposition without a customer narrative) generate thin landing pages; fill the gap in cogni-portfolio or drop the page. Re-run after adding propositions to see what the build will change.

**5 — Build.** `cogni-website:website-build`. Renders `website/{page-slug}.html` plus `website/assets/` (themed CSS, JS, hero imagery). The build dispatches the site-assembler agent, which renders every planned page in parallel. With Pencil MCP available the hero-renderer generates hero imagery; without it, hero blocks fall back to themed gradients. Subsequent runs rebuild only modified pages — a theme change forces a full rebuild.

**6 — Preview and iterate.** `cogni-website:website-preview` opens a local browser preview through claude-in-chrome. Iterate on theme tweaks, copy edits or page additions by rebuilding. The `website/` directory is self-contained, so deployment is a push to any static host.

## Common pitfalls

- **Missing propositions or customers.** The plan needs propositions for service-page headlines and customer profiles to seed landing pages. Building before the portfolio is populated yields a thin three-page placeholder.
- **Theme not picked before build.** The build reads the active theme from workspace state; without one it falls back to the default and the site drifts visually from your slides and dashboards.
- **Pencil MCP missing.** Hero sections render as themed gradients — usable, but not the generated imagery the demos show.
- **Optional sources added late.** Installing cogni-marketing or cogni-trends after planning requires re-running plan and build to pick up the new pages.

**Source**: [docs/workflows/portfolio-to-website.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-website.md)
