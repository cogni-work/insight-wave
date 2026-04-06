# cogni-website

Assembles multi-page customer websites from portfolio, marketing, trend, and research content produced by other insight-wave plugins — outputting a deployable static site with shared navigation, theming, and responsive HTML.

## Why this exists

Good content doesn't automatically become a good website. Turning portfolio propositions, marketing articles, and trend reports into a coherent, on-brand web presence requires layout decisions, navigation design, CSS theming, and page-by-page HTML generation — work that is mechanical but time-consuming without tooling:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Content scattered across plugins | Portfolio, marketing, trends, and research outputs live in separate project directories with no shared structure | No clear path from "we have content" to "we have a website" |
| Theme inconsistency | Without shared CSS variables, each page accumulates its own inline styles | Inconsistent brand identity, hard to reskin |
| Manual page assembly | Turning product JSON and proposition markdown into valid, responsive HTML requires per-page decisions | Hours of layout work per update, pages drift out of sync |
| No resumability | Partially built sites have no status tracking | Rebuilds start from scratch; incremental updates are error-prone |

This plugin automates the mechanical parts — CSS generation, navigation scaffolding, parallel page rendering, and hero imagery — while keeping content and structure decisions with you.

## What it is

A static-site generation pipeline purpose-built for the insight-wave ecosystem. cogni-website reads from cogni-portfolio (products, features, propositions, customer narratives), cogni-marketing (blog posts, articles, landing pages), cogni-trends (investment theme reports), and cogni-research (whitepapers) and assembles them into a fully linked, theme-driven, multi-page website. Three specialist agents handle site infrastructure (site-assembler), page HTML (page-generator), and homepage hero imagery (hero-renderer). The output is a self-contained `output/website/` folder ready for local preview or deployment to Netlify, Vercel, or S3.

## What it does

1. **Discover content sources** — scan the workspace for cogni-portfolio, cogni-marketing, cogni-trends, and cogni-research projects; validate minimum requirements; surface entity counts per source
2. **Select theme and configure** — invoke cogni-workspace to pick a visual theme; derive design-variables.json with color, font, shadow, and radius tokens; capture company details and hero renderer choice
3. **Plan site structure** — deep-scan source content; propose pages (home, about, products, solutions, blog, case studies, insights, resources, contact); present a page table for interactive approval; build navigation with dropdown support
4. **Generate shared infrastructure** — produce a complete `style.css` from design variables; render `header.html`, `footer.html`, and `sitemap.xml` shared across all pages
5. **Render homepage hero** — optionally use Pencil MCP to generate an AI-illustrated hero background image matched to the company's industry and theme palette; falls back to CSS gradient if unavailable
6. **Build all pages in parallel** — launch page-generator agents concurrently for each page in the plan; each agent reads source files, applies page-type HTML templates, injects shared navigation, and writes output HTML
7. **Validate and preview** — verify completeness and link integrity; open the site in the default browser; suggest a local HTTP server for full navigation testing
8. **Resume across sessions** — detect project phase from existing files; compare source modification times against built HTML; flag new entities or newly discovered upstream plugins; recommend targeted partial rebuilds

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically via the marketplace.

**Prerequisites:**
- **cogni-portfolio** (required — provides products, features, propositions, markets, solutions)
- **cogni-workspace** (required — provides theme selection and design variables)
- Optional: **cogni-marketing** (blog posts, articles, landing pages), **cogni-trends** (insights page), **cogni-research** (resources/whitepapers page)

## Quick start

```
/website-setup     # Discover sources, select theme, configure the project
/website-plan      # Plan site structure and map content to pages
/website-build     # Generate all pages and assemble the site
/website-preview   # Validate links and open in browser
```

Or describe what you want in natural language:

- "Build me a website from our portfolio"
- "Create a company website for Acme Cloud Services"
- "Generate a web presence from our portfolio and marketing content"
- "Resume the website project"

## How it works

**Setup** discovers every content source available in the workspace, validates that a portfolio project exists (hard gate), and produces `website-project.json` — the single configuration file that all downstream skills share. Theme selection and hero renderer choice happen here.

**Plan** goes beyond raw counts: it reads actual entity files and prose narratives to understand what pages are warranted, proposes a full page list with content-to-section mappings, and writes `website-plan.json`. You confirm or adjust the structure before any HTML is generated.

**Build** executes the plan in three stages: first the site-assembler produces shared CSS and navigation partials; then the hero-renderer (if Pencil MCP) generates homepage imagery; then all page-generator agents run in parallel — one agent per page — each reading source content, applying the correct HTML template, splicing in header/footer, and writing the output file. Partial rebuild modes (CSS only, single page, hero only) skip unneeded stages.

**Preview** validates that every planned page was built and that all internal links resolve, then opens `index.html` in the system browser. A local HTTP server command is provided for full relative-path testing.

**Resume** re-enters any interrupted session, detects phase from file state, checks for source changes since the last build, and routes to the correct next skill automatically.

## What it means for you

- **From content to website in one session.** Setup, plan, and build run sequentially with interactive checkpoints — the full pipeline completes in a single working session.
- **Every page reflects current content.** Resume detects when source files have changed since the last build and flags exactly which pages need regeneration — no manual diff required.
- **Theme-consistent across all pages.** One design-variables.json drives every color, font, and shadow token — reskinning the site means updating the theme, not editing individual pages.
- **No dead links.** Preview validates all internal `href` attributes before you share the site — broken references are caught before deployment.
- **Deployable anywhere.** The output is a self-contained static folder: open locally, serve with Python, or drop onto Netlify, Vercel, or S3 without build tooling.
- **Grows with your content.** New products, articles, or trend reports are detected at resume time — add content to upstream plugins and rebuild only the affected pages.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `website-setup` | skill | Discover content sources, validate requirements, select theme, scaffold project, write `website-project.json` |
| `website-plan` | skill | Deep-scan content, propose page structure, map content to page sections, write `website-plan.json` |
| `website-build` | skill | Orchestrate CSS generation, hero rendering, and parallel page generation from the plan |
| `website-preview` | skill | Validate built site file completeness and internal links; open in browser |
| `website-resume` | skill | Detect project phase, check for source changes and new upstream plugins, route to the correct next skill |
| `site-assembler` | agent (sonnet) | Generate `style.css` from design variables and navigation partials (`header.html`, `footer.html`, `sitemap.xml`) |
| `page-generator` | agent (sonnet) | Generate a single HTML page from source content and a page-type template specification |
| `hero-renderer` | agent (sonnet) | Render the homepage hero section using Pencil MCP for AI-generated imagery; falls back to CSS gradient |

## Architecture

```
cogni-website/
├── .claude-plugin/               Plugin manifest (v0.1.6)
│   └── plugin.json
├── skills/                       5 workflow skills
│   ├── website-setup/
│   │   └── SKILL.md              Source discovery, theme selection, project scaffolding
│   ├── website-plan/
│   │   └── SKILL.md              Deep content scan, page proposal, navigation design
│   ├── website-build/
│   │   └── SKILL.md              Build orchestration, parallel page generation
│   ├── website-preview/
│   │   └── SKILL.md              Link validation, browser preview
│   └── website-resume/
│       └── SKILL.md              Session re-entry, change detection, phase routing
├── agents/                       3 specialist agents
│   ├── hero-renderer.md          Pencil MCP hero image generation
│   ├── page-generator.md         Single-page HTML generation from templates
│   └── site-assembler.md         Shared CSS, navigation partials, sitemap
└── libraries/                    Shared reference files
    ├── page-templates.md         HTML patterns and CSS class reference per page type
    ├── navigation-patterns.md    Header, footer, breadcrumb, mobile menu patterns
    └── EXAMPLE_WEBSITE_PLAN.md   Annotated website-plan.json example
```

**Runtime output** (written to the website project directory, not inside the plugin):

```
{company}-website/
├── website-project.json          Configuration: sources, theme, build options
├── website-plan.json             Page blueprint: specs, slugs, source mappings
└── output/
    ├── design-variables.json     Color/font tokens derived from selected theme
    └── website/
        ├── index.html            Homepage
        ├── css/
        │   └── style.css         Shared theme-driven stylesheet
        ├── pages/
        │   ├── produkte.html
        │   ├── produkte/
        │   │   └── {slug}.html   Product detail pages
        │   ├── blog/
        │   │   └── {slug}.html   Blog post pages
        │   └── kontakt.html
        ├── images/
        │   └── hero-bg.png       AI-generated hero background (Pencil MCP)
        ├── .partials/
        │   ├── header.html
        │   ├── footer.html
        │   └── hero.html
        └── sitemap.xml
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-portfolio | Yes | Products, features, propositions, solutions, markets, customer narratives — core page content |
| cogni-workspace | Yes | Theme selection (`pick-theme`) and design-variables pattern reference |
| cogni-marketing | No | Blog posts, demand-generation articles, lead-generation landing pages |
| cogni-trends | No | Trend report with investment themes for an Insights page |
| cogni-research | No | Research reports as whitepapers for a Resources page |
| cogni-visual | No | Pencil MCP access for AI-generated hero imagery (via hero-renderer agent) |

## Custom development

Need a custom page type, CMS integration, or a domain-specific website template? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)

---

Built by [cogni-work](https://cogni-work.ai) — AI-powered consulting
