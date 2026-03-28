# cogni-website

Generate multi-page customer websites from portfolio, marketing, trend, and research content produced by other insight-wave plugins. Produces a deployable static site folder with shared CSS, navigation, and responsive HTML pages.

## Plugin Architecture

```
skills/              Website generation workflow skills
  website-setup/       Discover content sources, configure project, select theme
  website-plan/        Plan site structure interactively, map pages to content
  website-build/       Orchestrate page generation + assembly into static site
  website-preview/     Open site in browser, validate links, screenshot
  website-resume/      Re-entry point: status + next action

agents/              Parallel generation agents
  page-generator.md    Generate a single HTML page from source content + template
  site-assembler.md    Generate shared CSS, nav partials, sitemap, validate links
  hero-renderer.md     Pencil MCP rendering for homepage hero (AI images)

libraries/           Shared reference material
  page-templates.md    HTML patterns for each page type (home, product, blog, etc.)
  navigation-patterns.md  Header nav, footer, breadcrumb, mobile menu patterns
  EXAMPLE_WEBSITE_PLAN.md  Reference website-plan.json with commentary
```

## Content Sources

The plugin discovers and aggregates content from:
- **cogni-portfolio** — Products, features, propositions, solutions, customer narratives
- **cogni-marketing** — Blog posts, articles, whitepapers, landing pages

Future: cogni-trends (trend reports), cogni-research (research reports)

## Output

Static site folder at `output/website/`:
```
output/website/
├── index.html          Homepage (with Pencil MCP hero)
├── css/style.css       Shared stylesheet (theme-driven CSS custom properties)
├── pages/
│   ├── about.html
│   ├── products.html
│   ├── products/{slug}.html
│   ├── solutions.html
│   ├── blog.html
│   ├── blog/{slug}.html
│   ├── case-studies.html
│   └── contact.html
├── images/             Generated and referenced images
└── sitemap.xml
```

## Key Conventions

- **Theme-driven**: All colors/fonts via CSS custom properties from cogni-workspace themes
- **Design variables**: Follows `cogni-workspace/references/design-variables-pattern.md`
- **Language**: German (de) primary output, bilingual support planned
- **Semantic HTML**: Proper heading hierarchy, landmark elements, meta tags
- **Self-contained**: No external CDN dependencies, works offline
