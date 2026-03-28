---
name: website-setup
description: |
  This skill initializes a cogni-website project by discovering content sources from
  cogni-portfolio and cogni-marketing, selecting a theme, and scaffolding the project
  directory. It should be triggered when the user mentions creating a website, starting
  a new website project, setting up a website, "build me a website", "company website",
  "customer website", "generate a website", "website setup", "Website erstellen",
  or wants to turn portfolio content into a web presence — even without saying "setup"
  explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill, AskUserQuestion
---

# Website Project Setup

Initialize a cogni-website project by discovering content from existing insight-wave plugins, selecting a theme, and scaffolding the project directory.

## Core Concept

A website project aggregates content from cogni-portfolio (products, features, propositions, customer narratives) and cogni-marketing (blog posts, articles, whitepapers) into a multi-page static website. Setup discovers what content is available, captures company details, selects a visual theme, and creates `website-project.json` — the configuration that all downstream skills depend on.

If a `website-project.json` already exists in the working directory, redirect to the `website-resume` skill.

## Workflow

### 1. Check for Existing Project

Scan the current directory and immediate children for `website-project.json`. If found, inform the user and invoke the `website-resume` skill instead.

### 2. Discover Content Sources

Search for insight-wave plugin projects in nearby directories (parent, siblings, children):

#### Portfolio Discovery
- Look for `cogni-portfolio/*/portfolio.json` or `*/portfolio.json`
- Read `portfolio.json` to extract: company name, description, industry, language
- Check for synthesized output: `output/README.md`
- Check for customer narratives: `output/communicate/customer-narrative/*.md`
- Count entities: products, features, markets, propositions, solutions, packages

#### Marketing Discovery
- Look for `cogni-marketing/*/marketing-project.json` or `*/marketing-project.json`
- Read `marketing-project.json` for brand voice and content strategy
- Count content pieces by type: `content/thought-leadership/*.md`, `content/demand-generation/*.md`, `content/lead-generation/*.md`

Present findings:

```
Gefundene Inhaltsquellen:

Portfolio: ../cogni-portfolio/acme-cloud/
  ✓ 3 Produkte, 8 Features, 2 Märkte, 12 Propositions
  ✓ Kundendarstellungen vorhanden (3 Narrative)
  ✓ Synthese erstellt

Marketing: ../cogni-marketing/acme-cloud/
  ✓ 4 Thought-Leadership-Artikel
  ✓ 6 Demand-Generation-Beiträge
  ✓ 2 Landing Pages
```

If no portfolio project is found, warn the user that a portfolio project is the minimum requirement. Offer to help set one up via `cogni-portfolio:portfolio-setup`.

### 3. Gather Company Details

Extract company information from the discovered portfolio.json:
- Company name, description, tagline
- Contact email, phone, address (ask if not in portfolio)
- Language (from portfolio.json `language` field)

Ask only for what's missing. Adapt all user-facing text to the portfolio language (examples below use German):

> "Aus dem Portfolio übernehme ich: **Acme Cloud Services** — Cloud-Infrastruktur für den Mittelstand. Fehlen noch: **Kontakt-E-Mail** und **Adresse** für die Kontaktseite. Können Sie die ergänzen?"

### 4. Select Theme

Invoke `cogni-workspace:pick-theme` to let the user select a visual theme. The theme drives all colors, fonts, and styling across the website.

After theme selection, derive design variables by reading the theme.md file and generating `output/design-variables.json` following the convention in `cogni-workspace/references/design-variables-pattern.md`.

### 5. Configure Build Options

Ask the user about build preferences using AskUserQuestion:

- **Homepage Hero**: "Pencil MCP" (AI-generated hero image, ~3-5 Min.) or "CSS-only" (schneller, Farbverlauf-Hintergrund)
- **Blog einbinden**: Ja/Nein (only if marketing content exists)
- **Fallstudien einbinden**: Ja/Nein (only if customer narratives exist)

### 6. Create Project Structure

Create the website project directory and write configuration:

```bash
mkdir -p cogni-website/{output/website/{css,pages,images},output}
```

Write `website-project.json` following the schema documented in `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md` (see the project config section). Key fields: `slug`, `name`, `language`, `theme_path`, `sources` (portfolio + marketing paths), `company` (name, tagline, description, contact details), `build_options` (hero_renderer, include_blog, include_case_studies), and `content_discovery` (entity counts per source).

All boolean fields default to `true`. Set `hero_renderer` to `"pencil"` or `"html"` based on user choice. Set `marketing_project` to `null` if no marketing project was found.

### 7. Present Summary and Next Steps

```
Website-Projekt erstellt: {slug}

Konfiguration:
  Unternehmen: {name}
  Sprache: {language}
  Theme: {theme_name}
  Hero: {pencil|html}
  Blog: {ja|nein}
  Fallstudien: {ja|nein}

Nächster Schritt: /website-plan — Seitenstruktur planen und Inhalte zuordnen
```

## Output Language

Read the `language` field from portfolio.json. Generate all user-facing text in that language. JSON field names and slugs remain in English. Default to German (de) if not specified.

## Slug Convention

Derive the website slug from the company name:
- Lowercase, hyphens instead of spaces
- Replace umlauts: ü→ue, ö→oe, ä→ae, ß→ss
- Remove special characters
- Append `-website` suffix
- Example: "Acme Cloud Services" → `acme-cloud-website`
