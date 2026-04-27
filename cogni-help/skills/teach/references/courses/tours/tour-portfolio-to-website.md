# Tour: Portfolio to Website

**Duration**: 60 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-portfolio → cogni-workspace → cogni-website
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-portfolio`, `/cogni-help:cheatsheet cogni-workspace`, `/cogni-help:cheatsheet cogni-website`; see also the matching `docs/plugin-guide/<plugin>.md` files.
**Audience**: Teams generating a deployable static site directly from portfolio data

---

This tour walks the portfolio-to-website pipeline as one workflow. You confirm
your portfolio data, pick a workspace theme, plan a sitemap, build the site, and
preview the result. The portfolio model drives the page content — propositions
become page headlines, customer narratives become landing pages, features
become capability lists.

## Module 1: Pipeline Overview & Portfolio Check

### Theory (5 min)

The portfolio-to-website pipeline produces a self-contained static site rendered
from portfolio data. Three plugins:
- `cogni-portfolio` — proposition, feature, customer profile content
- `cogni-workspace` — theme inheritance (colors, fonts, design variables)
- `cogni-website` — page generation, hero rendering, sitemap, preview

Optional content sources: cogni-marketing (blog, lead-gen pages), cogni-trends
(insights pages), cogni-research (whitepapers). The site is deployable to any
static host (Netlify, GitHub Pages, S3) — no backend.

The portfolio model drives the IA: propositions are top-level pages, features are
capability lists inside service pages, customer narratives are landing pages. If
the portfolio is thin, the site is thin.

### Demo

Walk the audience through the data flow:
1. Open the portfolio project — show one proposition, one feature, one customer narrative.
2. Open an example built site — show the proposition page, the capability section
   driven by features, the landing page driven by the customer narrative.
3. Show how a single change in cogni-portfolio cascades to the generated page.

### Exercise

Have the learner check their portfolio status: at least one product, propositions,
and customer profiles. Identify gaps. The website plan keys off all three; missing
data produces thin landing pages.

### Quiz

1. **Multiple choice**: Without any cogni-portfolio data, what does the website pipeline produce?
   - a) A complete site with placeholder text — b) A three-page minimum site — c) An
     error — d) A blank site
   **Answer**: b (a thin three-page placeholder; the pipeline runs but the IA collapses)

2. Why does the site IA depend on the portfolio model?
   **Answer**: The IA mirrors the IS/DOES/MEANS structure — propositions become
   pages, features become capability lists, customers become landing pages. Without
   the structure, there are no pages to generate.

### Recap

- Pipeline: portfolio → workspace (theme) → website
- The portfolio drives the IA — fill data first, generate site second
- Optional content sources: cogni-marketing, cogni-trends, cogni-research
- The site is deployable to any static host — no backend

---

## Module 2: Pick or Confirm a Theme (cogni-workspace)

### Theory (5 min)

The website inherits the workspace theme — colors, fonts, design variables.
`cogni-workspace` provides the theme via `/pick-theme`; a theme can be a preset, a
PowerPoint template, or extracted from a live website via `/manage-themes extract`.

Theme inheritance is global: the same theme drives slides, infographics, dashboards,
and the website. A theme switch + `/website-build` reskins the entire site — theme
changes are deliberately broad.

If the team has no theme yet, run the `install-to-infographic` workflow first to
extract one (it's the bootstrap workflow for theme + MCP setup).

### Demo

Run `/pick-theme`:
1. List available themes.
2. Pick one — show the design variables it sets.
3. Run `/manage-themes` to see how to extract a new theme from a company website.

If the team has a company URL handy, run `/manage-themes extract <url>` live and
show the extraction phases (claude-in-chrome reads the site → colors/fonts/logo
parsed → theme stored).

### Exercise

Pick a theme that matches the brand the website should reflect. If no matching
theme exists, run `/manage-themes extract` against the company URL or pick a preset
and accept that the result is preliminary.

### Quiz

1. Why does the website inherit the workspace theme instead of accepting per-build styling?
   **Answer**: Visual consistency across all deliverables (slides, dashboards, site).
   Per-build styling produces drift; theme inheritance keeps the brand intact.

2. **Hands-on**: Run `/manage-themes` and find one theme attribute (e.g. primary
   color, body font) that would change if the brand updated.

### Recap

- Themes drive colors, fonts, design variables across all visual plugins
- `/pick-theme` selects, `/manage-themes extract` builds new from a live URL
- Theme switching reskins the site — no per-page styling
- For first-run setup, run `install-to-infographic` to bootstrap a theme

---

## Module 3: Set Up & Plan the Site (cogni-website)

### Theory (6 min)

Two cogni-website skills cover setup and planning:
- `/website-setup` — initializes `website-project.json` with discovered portfolio
  entities and project config (target market, primary CTA, language)
- `/website-plan` — produces `website-plan.json` with the sitemap, content map,
  and navigation flow

Setup walks through optional content sources: cogni-marketing for blog/lead-gen
pages, cogni-trends for insights pages, cogni-research for whitepapers. Skip
optional sources you don't have content for; they can be added on a later run.

The plan picks defaults but the running order shapes the homepage. Review and
adjust priorities before `/website-build`. Pages with shallow content sources
(a proposition without a customer narrative) generate thin landing pages — fill
the gap or drop the page from the plan.

For German sites, set `language: de` during setup; bilingual sites need separate
runs per language for now.

### Demo

Run `/website-setup` followed by `/website-plan`:
1. Pick a target directory.
2. Configure: target market, primary CTA, language.
3. Watch entity discovery — the setup finds propositions, features, customer narratives.
4. Run `/website-plan` — review the sitemap and reorder priorities.
5. Open `website-plan.json` and discuss the page list.

### Exercise

Have the learner review the plan and identify one page that should be reordered or
dropped. Justify the change in one sentence.

### Quiz

1. **Multiple choice**: A proposition has no matching customer narrative. What does the planner do?
   - a) Drops the page — b) Generates a thin landing page — c) Errors —
     d) Replaces it with placeholder content
   **Answer**: b (generates a thin landing page; the planner doesn't enforce content
   completeness — review and drop or fill)

2. Why doesn't the planner auto-fill optional content sources?
   **Answer**: Optional sources reflect real-world variability — not every team has
   marketing content or trend research. Forcing them produces fake content; opting
   in keeps the site honest.

### Recap

- `/website-setup` discovers portfolio entities and configures project
- `/website-plan` produces the sitemap and content map
- Optional sources (marketing, trends, research) opt-in via setup
- Review the plan and adjust priorities before building

---

## Module 4: Build the Site (cogni-website)

### Theory (5 min)

`/website-build` generates `website/{page-slug}.html` files plus
`website/assets/` (themed CSS, JS, hero imagery). The build dispatches the
`site-assembler` agent, which renders every page from the plan in parallel.

Hero imagery: if Pencil MCP is available, the `hero-renderer` agent generates AI
hero images for landing pages. Without Pencil, hero blocks fall back to themed
gradients — usable, but not the AI-generated imagery in demos.

Subsequent runs do incremental rebuilds — only modified pages rebuild. Theme
changes trigger a full rebuild because every page's CSS variables change.

### Demo

Run `/website-build`:
1. Watch the parallel page rendering.
2. Show the produced `website/` directory — pages, assets, hero images.
3. Modify one proposition in cogni-portfolio and re-run — show the incremental rebuild.

If Pencil MCP isn't running, point at the gradient fallback and explain the
upgrade path (`/install-mcp pencil` then re-run build).

### Exercise

After the build, open one page in a browser. Confirm: theme is applied, hero block
renders, content reflects the portfolio data. Note any thin pages — they trace to
shallow portfolio data.

### Quiz

1. Why does the build use parallel rendering?
   **Answer**: Pages are independent — proposition pages don't depend on customer
   pages. Parallel rendering produces a 7-page site in roughly the time it takes
   to render one page sequentially.

2. **Hands-on**: Open one built page's HTML source. Find the theme CSS variables
   and trace one back to the workspace theme.

### Recap

- `/website-build` runs the site-assembler in parallel
- Pencil MCP enables AI hero imagery; without it, themed gradients
- Incremental rebuilds on subsequent runs; full rebuild on theme change
- Open the build and confirm theme + content before iterating

---

## Module 5: Preview, Iterate, & Deploy (cogni-website)

### Theory (4 min)

`/website-preview` opens the built site in a browser via claude-in-chrome MCP and
validates internal links. Use it for visual review and to catch link breakage
before deployment.

For legal pages — Impressum, Datenschutzerklärung, Cookie-Hinweis (or EU equivalents)
— `/website-legal` generates them based on the publishing entity. Required for
DACH/EU deployment.

Deployment: the `website/` directory is self-contained — push it to any static
host. No backend, no database, no API keys. The team can iterate on theme tweaks
or copy edits by re-running `/website-build` after changes.

### Demo

Run `/website-preview` followed by `/website-legal`:
1. Preview the site in the browser — click through pages.
2. Show a broken link if one exists (or simulate by editing a link).
3. Run `/website-legal` to generate Impressum + Datenschutz.
4. Show the deployable directory layout.

### Exercise

Have the learner deploy the built site to a temporary host (Netlify drop zone, or
local `python3 -m http.server`). Browse the live site. Identify two improvements to
make in the next iteration.

### Quiz

1. Why are legal pages handled by a separate skill rather than auto-generated by `/website-build`?
   **Answer**: Legal content depends on the publishing entity (sole proprietorship,
   GmbH, AG, etc.) and target jurisdiction. The build can't infer those; the legal
   skill asks explicitly.

2. **Hands-on**: After preview, edit one proposition in cogni-portfolio. Re-run
   `/website-build` and `/website-preview`. Confirm only the affected pages updated.

### Recap

- `/website-preview` validates the built site (visual + link check)
- `/website-legal` generates Impressum, Datenschutz, Cookie-Hinweis (DACH/EU)
- Deployable to any static host — `website/` is self-contained
- Iterate on portfolio data; re-run build; preview; deploy

---

## Tour Complete

Next steps:
- Run the pipeline against your real portfolio
- Add cogni-marketing for blog and lead-gen pages
- Use `/website-legal` before publishing to a DACH/EU audience
- Combine with `tour-content-pipeline` for editorial content layered onto the site
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/portfolio-to-website.md`
- See the narrative tutorial: `docs/workflows/portfolio-to-website.md`
