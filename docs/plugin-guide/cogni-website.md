# cogni-website

Turn your portfolio and marketing content into a deployable static website.

> For installation details and architecture reference, see the [cogni-website README](../../cogni-website/README.md).

---

## What It Does

cogni-website reads from cogni-portfolio and optionally from cogni-marketing, cogni-trends, and cogni-research, then assembles a fully linked, theme-driven multi-page website. It handles the mechanical parts — CSS generation from shared design tokens, navigation scaffolding, and parallel page rendering — while you control structure and content decisions at each checkpoint.

The output is a self-contained `output/website/` folder. You can open it locally, serve it with a one-line Python command, or deploy it to Netlify, Vercel, or S3 without any build tooling.

---

## Prerequisites

- **cogni-portfolio** (required) — products, features, propositions, solutions, markets, and customer narratives are the core page content; cogni-website will not run without it
- **cogni-workspace** (required) — provides the `pick-theme` skill and design-variables patterns used during setup
- Optional: **cogni-marketing** (blog posts, articles, landing pages), **cogni-trends** (Insights page), **cogni-research** (Resources/whitepapers page)

Set up cogni-portfolio before starting. The richer your portfolio — especially propositions and customer narratives — the more complete the generated pages will be.

---

## Getting Started

The typical workflow runs four skills in sequence:

### Step 1 — Set up the project

```
/website-setup
```

The skill scans the workspace for all available content sources, validates that cogni-portfolio exists, and then walks you through theme selection (via cogni-workspace) and company details. It writes `website-project.json` — the config file that all subsequent skills read.

### Step 2 — Plan the site structure

```
/website-plan
```

The skill reads your actual content files (not just entity counts) to understand what pages are warranted. It proposes a full page list — home, about, products, solutions, blog, case studies, insights, resources, contact — with content-to-section mappings and a navigation structure. You confirm or adjust before any HTML is generated.

### Step 3 — Build all pages

```
/website-build
```

Build runs in three stages: first the site-assembler generates shared CSS and navigation partials; then (optionally) the hero-renderer creates an AI-illustrated homepage hero using Pencil MCP; then page-generator agents run in parallel — one per page — each reading source content, applying the correct HTML template, and writing the output file.

### Step 4 — Preview

```
/website-preview
```

Preview validates that every planned page was built and that all internal links resolve. It then opens `index.html` in your default browser and prints a local HTTP server command for full navigation testing.

### Resuming an interrupted session

```
/website-resume
```

If a session ends partway through, resume detects the current phase from existing files, checks whether any source content has changed since the last build, and routes you to the correct next skill automatically.

---

## Key Concepts

| Concept | What it means |
|---------|--------------|
| Site plan (`website-plan.json`) | The approved blueprint: page list, content-to-section mappings, and navigation structure. Build reads this file; nothing is generated until you confirm the plan |
| Page templates | Per-page-type HTML patterns (homepage, product detail, blog post, etc.) defined in `page-templates.md`. Each page-generator agent picks the correct template for its page type |
| Theme integration | One `design-variables.json` drives every color, font, and shadow token across all pages. Reskinning the site means updating the theme, not editing individual HTML files |
| Resume / change detection | `website-resume` compares source file modification times against built HTML. It flags exactly which pages need regeneration — new products, articles, or reports are surfaced automatically |

---

## Skills Overview

| Skill | What it does |
|-------|-------------|
| `website-setup` | Discover content sources, validate requirements, select theme, write `website-project.json` |
| `website-plan` | Deep-scan content, propose page structure and navigation, write `website-plan.json` |
| `website-build` | Orchestrate CSS generation, hero rendering, and parallel page generation |
| `website-preview` | Validate file completeness and internal links; open site in browser |
| `website-resume` | Detect current phase, check for source changes, route to the correct next skill |

---

## Agents

Three specialist agents handle the work that `website-build` orchestrates:

- **site-assembler** — generates the shared `style.css` from design-variables.json and produces the `header.html`, `footer.html`, and `sitemap.xml` partials used across all pages
- **page-generator** — one instance runs per page in the plan; reads source content, applies the page-type HTML template, splices in navigation partials, and writes the output HTML file
- **hero-renderer** — generates the homepage hero background image using Pencil MCP when available; falls back to a CSS gradient if Pencil MCP is not connected

---

## Tips and Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| Setup reports no portfolio found | cogni-portfolio project not in workspace | Run cogni-portfolio setup first; `portfolio.json` must exist in the workspace |
| Products page is thin or generic | Portfolio propositions not fully populated | Complete cogni-portfolio's propositions and customer narratives phases before building |
| Hero image is a CSS gradient instead of an illustration | Pencil MCP not connected | Connect the Pencil MCP server and re-run `website-build` with the hero-only partial rebuild option |
| Internal links broken in preview | A page failed to generate during build | Check the build output for errors; re-run `website-build` — it will regenerate only the missing pages |
| Resume routes to setup instead of the expected phase | `website-project.json` is missing or corrupt | Re-run `/website-setup`; existing plan and built pages are preserved and detected in the next plan/build run |
| New products not appearing after content update | Pages built before the portfolio was updated | Run `/website-resume` — it compares source modification times and flags stale pages; confirm the targeted rebuild |
| Blog or Insights page not proposed in the plan | cogni-marketing / cogni-trends not installed | Install the relevant plugins and re-run `/website-setup` to register the new sources before re-planning |
