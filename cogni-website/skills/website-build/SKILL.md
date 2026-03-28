---
name: website-build
description: |
  This skill builds the static website by orchestrating CSS generation, parallel page
  generation, hero rendering, and site assembly. It produces a deployable output/website/
  folder from the website-plan.json blueprint. This skill should be used when the user
  mentions "build the website", "generate website", "website build", "Website erstellen",
  "Website generieren", "Seiten erzeugen", "assemble the site", "create all pages",
  or wants to execute the website plan — even if they don't say "build" explicitly.
  Requires website-plan.json.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill
---

# Website Build

Orchestrate the full website generation pipeline: shared CSS, homepage hero, parallel page generation, and site assembly.

## Prerequisites

Both `website-project.json` and `website-plan.json` must exist (from setup and plan skills). If missing, redirect to the appropriate skill.

## Workflow

### 1. Load Configuration

Read `website-project.json` and `website-plan.json`. Extract:
- Theme path and design variables path
- All page specs from the plan
- Navigation structure
- Build options (hero_renderer, language)
- Company details

### 2. Prepare Output Directory

```bash
mkdir -p output/website/{css,pages,images,.partials}
```

Ensure the directory structure matches the plan's slug paths. Create subdirectories for nested pages (e.g., `pages/produkte/`, `pages/blog/`).

### 3. Generate Design Variables

If `output/design-variables.json` does not exist or is outdated:
- Read the theme.md file
- Derive design variables following `cogni-workspace/references/design-variables-pattern.md`
- Write `output/design-variables.json`

### 4. Generate Shared CSS + Navigation

Delegate to the `site-assembler` agent with:
- `project_dir`: absolute path to website project
- `plugin_root`: `$CLAUDE_PLUGIN_ROOT`
- `website_plan`: full plan JSON
- `theme_path`: from project config
- `design_variables_path`: path to design-variables.json

The site-assembler produces:
- `output/website/css/style.css`
- `output/website/.partials/header.html`
- `output/website/.partials/footer.html`
- `output/website/sitemap.xml`

Wait for this to complete before page generation.

### 5. Render Homepage Hero (if Pencil MCP)

If the homepage page spec has `"hero_renderer": "pencil"`:

Delegate to the `hero-renderer` agent with:
- `project_dir`: absolute path
- `plugin_root`: `$CLAUDE_PLUGIN_ROOT`
- `home_page_spec`: homepage page spec from plan
- `theme_path`: from project config
- `design_variables`: from design-variables.json
- `company`: company object from project config
- `language`: from project config

The hero-renderer produces:
- `output/website/.partials/hero.html`
- `output/website/images/hero-bg.png`

### 6. Generate Pages in Parallel

Read the generated navigation partials:
- `output/website/.partials/header.html`
- `output/website/.partials/footer.html`

For the homepage, also read `output/website/.partials/hero.html` if it exists.

Launch `page-generator` agents in parallel for each page in the plan. For each page, provide:

```json
{
  "page_spec": {page spec from plan},
  "project_dir": "{absolute path}",
  "plugin_root": "$CLAUDE_PLUGIN_ROOT",
  "css_path": "{relative path from page to css/style.css}",
  "navigation_header": "{header HTML with active state for this page}",
  "navigation_footer": "{footer HTML}",
  "site_title": "{site title from plan}",
  "language": "{language}",
  "design_variables": {design variables JSON}
}
```

**Active state**: For each page, mark the matching nav link with `site-nav__link--active` class in the header HTML before passing it to the agent.

**CSS path calculation**:
- `index.html` → `css/style.css`
- `pages/produkte.html` → `../css/style.css`
- `pages/produkte/cloud.html` → `../../css/style.css`

**Homepage hero**: For the homepage page-generator, include the hero HTML partial in the prompt so it can splice it into the hero section instead of generating a CSS-only hero.

**Parallelism**: Launch all page-generator agents in a single message for maximum parallelism. Independent pages have no dependencies on each other.

### 7. Validate Results

After all agents return:

1. **Check completeness**: Every page in the plan has a corresponding HTML file
2. **Check file sizes**: Flag any page under 1KB (likely empty) or over 500KB (likely bloated)
3. **Count results**: total pages, total errors, total word count

### 8. Present Summary

```
Website erstellt: output/website/

  {N} Seiten generiert
  {M} Bilder erstellt
  CSS: {size}KB
  Gesamtgröße: {total}KB

  Dateien:
  ├── index.html (Startseite)
  ├── css/style.css
  ├── pages/
  │   ├── produkte.html
  │   ├── produkte/cloud-platform.html
  │   ├── ...
  │   └── kontakt.html
  ├── images/
  │   └── hero-bg.png
  └── sitemap.xml

Nächste Schritte:
  • /website-preview — Website im Browser öffnen und prüfen
  • python3 -m http.server -d output/website 8080 — Lokaler Testserver
  • Output-Ordner auf Netlify/Vercel/S3 deployen
```

## Error Handling

- If a page-generator agent fails, report the error but continue with other pages
- If site-assembler fails, abort (CSS is required for all pages)
- If hero-renderer fails, fall back to CSS-only hero and note it in the summary
- If no design-variables.json can be generated, abort with theme error

## Rebuild Modes

The skill supports partial rebuilds:

- **Full rebuild**: Default — regenerate everything
- **CSS only**: If user says "update CSS" or "change theme" — only run site-assembler
- **Single page**: If user names a specific page — only run one page-generator
- **Hero only**: If user says "regenerate hero" — only run hero-renderer

Detect the mode from the user's request and skip unnecessary steps.

## Reference Files

- `${CLAUDE_PLUGIN_ROOT}/libraries/page-templates.md` — HTML patterns for page types
- `${CLAUDE_PLUGIN_ROOT}/libraries/navigation-patterns.md` — Header, footer, breadcrumb CSS
- `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md` — Plan format reference
- `${CLAUDE_PLUGIN_ROOT}/skills/website-build/scripts/generate-css.py` — Standalone CSS generator from design-variables.json (alternative to site-assembler agent for CSS-only updates)
