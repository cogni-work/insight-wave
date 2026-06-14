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
cogni-workspace:pick-theme                         (active theme path)
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

**Source**: [docs/workflows/portfolio-to-website.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-website.md)
