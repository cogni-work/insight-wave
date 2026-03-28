---
name: website-plan
description: |
  This skill plans the site structure for a cogni-website project interactively — discovering
  available content, proposing pages, mapping content to page sections, and generating
  website-plan.json. It should be triggered when the user mentions "plan the website",
  "site structure", "which pages", "website plan", "plan pages", "Seitenstruktur",
  "Website planen", "map content to pages", or wants to decide what pages their website
  should have — even without saying "plan" explicitly. Requires website-project.json.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Website Plan

Plan the site structure by discovering available content, proposing pages, and mapping content sources to page templates. Produces `website-plan.json` — the blueprint that `website-build` executes.

## Prerequisites

A `website-project.json` must exist (created by `website-setup`). If not found, redirect to the setup skill.

## Workflow

### 1. Load Project Configuration

Read `website-project.json` to get:
- Content source paths (portfolio, marketing)
- Company details (name, tagline, language)
- Build options (hero renderer, blog, case studies)
- Content discovery counts

### 2. Deep Content Scan

Go beyond the counts from setup — read actual content to understand what's available for each page type.

#### Portfolio Scan
- Read all `products/*.json` — extract names, descriptions, positioning, maturity
- Read all `features/*.json` — extract names, IS statements, product mapping
- Read all `propositions/*.json` — extract IS/DOES/MEANS, market mapping
- Read all `solutions/*.json` — extract solution types, pricing tiers
- Read all `packages/*.json` — extract bundle tiers
- Read all `markets/*.json` — extract market names, segments
- Read `output/communicate/customer-narrative/*.md` — extract titles, markets
- Read `output/README.md` — extract company overview prose

#### Marketing Scan
- Read all `content/thought-leadership/*.md` — extract titles, dates, markets from frontmatter
- Read all `content/demand-generation/*.md` — extract titles, dates, formats
- Read all `content/lead-generation/*.md` — extract titles, formats

### 3. Propose Site Structure

Based on discovered content, propose a page list. Apply these rules:

| Page Type | Include When | Always/Conditional |
|-----------|-------------|-------------------|
| `home` | Always | Always |
| `about` | Always | Always |
| `products` | ≥2 products | Always (even with 1 product) |
| `product-detail` | Per product | One page per product |
| `solutions` | ≥1 solution | Conditional |
| `blog-index` | Marketing content exists AND `include_blog: true` | Conditional |
| `blog-post` | Per marketing article | One per article |
| `case-studies` | Customer narratives exist AND `include_case_studies: true` | Conditional |
| `contact` | Always | Always |

Present the proposed structure as a table:

```
Vorgeschlagene Seitenstruktur:

| Seite | Typ | Quelle | Inhalt |
|-------|-----|--------|--------|
| Startseite | home | Portfolio-Übersicht | Hero + Wertversprechen + Produkte |
| Über uns | about | portfolio.json | Unternehmensgeschichte + Mission |
| Produkte | products | products/*.json | Produktübersicht (3 Produkte) |
| Cloud Platform | product-detail | cloud-platform.json | Features + Benefits + Preise |
| ... | ... | ... | ... |
| Blog | blog-index | marketing/ | 10 Artikel |
| Kontakt | contact | Konfiguration | Formular + Kontaktdaten |

Gesamt: 14 Seiten
```

### 4. Interactive Approval

Ask the user to review and modify:

> "Stimmt die Seitenstruktur so? Sie können Seiten hinzufügen, entfernen oder umordnen."

Common modifications:
- Remove solutions page (if pricing is confidential)
- Remove blog (if content is not ready)
- Add custom pages (careers, partners, downloads)
- Reorder navigation priority
- Change page titles

Iterate until the user confirms.

### 5. Build Navigation Structure

Auto-generate navigation from the confirmed page list:

**Header navigation rules:**
- Products gets a dropdown with all product-detail pages as children
- Blog, Case Studies, About are top-level links
- CTA button always links to Contact
- Maximum 5-6 top-level items (combine if needed)

**Footer columns:**
- Column 1: Products (all product detail links)
- Column 2: Company (About, Contact, Blog, Case Studies)

Present navigation for approval:

> "Navigation: **Produkte** (mit Dropdown) | **Lösungen** | **Blog** | **Über uns** — CTA: **Kontakt aufnehmen**"

### 6. Map Content to Pages

For each page, determine:
- `source_files` — markdown files to read for prose content
- `source_entities` — JSON entity files for structured data
- `sections` — which template sections to include
- `meta_description` — SEO description (generate from content)

Use the page type definitions from `${CLAUDE_PLUGIN_ROOT}/libraries/page-templates.md` as reference for section lists.

### 7. Generate website-plan.json

Write the complete plan following the format in `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md`.

Key fields per page:
```json
{
  "id": "unique-page-id",
  "type": "page-type",
  "slug": "path/relative/to/output",
  "title": "Page Title — Site Title",
  "meta_description": "SEO description (max 160 chars)",
  "source_files": ["../path/to/content.md"],
  "source_entities": { "products": "../path/to/products/*.json" },
  "sections": ["hero", "features", "cta"],
  "hero_renderer": "pencil"
}
```

### 8. Present Summary

```
Website-Plan erstellt: website-plan.json

  {N} Seiten geplant
  {M} Inhaltsquellen zugeordnet
  Navigation: {nav_items} Hauptpunkte + {dropdown_children} Dropdown-Einträge

Nächster Schritt: /website-build — Seiten generieren und Website zusammenbauen
```

## Slug Convention

Page slugs determine the output file path:
- `index` → `output/website/index.html`
- `pages/produkte` → `output/website/pages/produkte.html`
- `pages/produkte/cloud-platform` → `output/website/pages/produkte/cloud-platform.html`
- `pages/blog/article-slug` → `output/website/pages/blog/article-slug.html`

German slugs: replace umlauts (ü→ue, ö→oe, ä→ae, ß→ss), lowercase, hyphens.

## Page-Type Reference

Consult `${CLAUDE_PLUGIN_ROOT}/libraries/page-templates.md` for the HTML section patterns and CSS class reference for each page type. Consult `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md` for a complete plan example with commentary.

## Content Language

All user-facing text (page titles, meta descriptions, navigation labels, section headlines) in the language from `website-project.json`. JSON field names remain English.
