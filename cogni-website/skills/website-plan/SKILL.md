---
name: website-plan
description: |
  This skill plans the site structure for a cogni-website project interactively — discovering
  available content, proposing pages, mapping content to page sections, and generating
  website-plan.json. It should be triggered when the user mentions "plan the website",
  "site structure", "which pages", "website plan", "plan pages", "Seitenstruktur",
  "Website planen", "Seiten festlegen", "map content to pages", "which pages do I need",
  "welche Seiten brauche ich", or wants to decide what pages their website should have
  — even without saying "plan" explicitly. Requires website-project.json.
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

**Narratives first** — these are the primary spine of narrative pages (home, per-market, per-persona). Raw entity JSON becomes enrichment, not the spine.

- Read `output/communicate/customer-narrative/portfolio-overview.md` — frontmatter + prose. This is the spine for the homepage.
- Read every `output/communicate/customer-narrative/market/*.md` — each becomes the spine for one market page. Extract `market` slug and H1 headline from frontmatter.
- Read every `output/communicate/customer-narrative/customer/*.md` — each becomes the spine for one persona/audience page. Extract `market` + `persona` slugs from frontmatter.

**Entities for enrichment** — still scan, still useful, but secondary:

- Read all `products/*.json` — extract names, descriptions, positioning, maturity
- Read all `features/*.json` — extract names, IS statements, product mapping
- Read all `propositions/*.json` — extract IS/DOES/MEANS, market mapping
- Read all `solutions/*.json` — extract solution types, pricing tiers
- Read all `packages/*.json` — extract bundle tiers
- Read all `markets/*.json` — extract market names, segments
- Read `output/README.md` — fallback company overview prose if no `portfolio-overview.md` narrative exists

#### Marketing Scan
- Read all `content/thought-leadership/*.md` — extract titles, dates, markets from frontmatter
- Read all `content/demand-generation/*.md` — extract titles, dates, formats
- Read all `content/lead-generation/*.md` — extract titles, formats

#### Trends Scan
If `sources.trends_project` is set in website-project.json:
- Read `tips-trend-report.md` — extract investment theme titles and executive summary
- Read `tips-value-model.json` — extract solution template names and rankings
- These feed the `insights` page type

#### Research Scan
If `sources.research_projects` is non-empty in website-project.json:
- For each research project, read the report output (`output/report.md` or latest `output/draft-v*.md`)
- Extract title, abstract/executive summary, date, topic
- These feed the `resources` page type

### 3. Propose Site Structure

Based on discovered content, propose a page list. Apply these rules:

| Page Type | Include When | Source spine | Always/Conditional |
|-----------|-------------|--------------|-------------------|
| `home` | Always | `customer-narrative/portfolio-overview.md` if present, else `portfolio.json` + top propositions | Always |
| `market` | Per `customer-narrative/market/*.md` found | `customer-narrative/market/{slug}.md` | One page per market narrative |
| `audience` | Per `customer-narrative/customer/*.md` found | `customer-narrative/customer/{market}--{persona}.md` | One page per persona narrative |
| `about` | Always | `portfolio.json` | Always |
| `products` | ≥2 products | `products/*.json` | Always (even with 1 product) |
| `product-detail` | Per product | `products/{slug}.json` + features + propositions | One page per product |
| `solutions` | ≥1 solution | `solutions/*.json` | Conditional |
| `blog-index` | Marketing content exists AND `include_blog: true` | Marketing `content/` tree | Conditional |
| `blog-post` | Per marketing article | Single marketing markdown file | One per article |
| `case-studies` | Customer narratives exist AND `include_case_studies: true` (legacy — prefer `market` / `audience`) | Per-customer narrative | Conditional |
| `insights` | Trend report exists AND `include_insights: true` | `tips-trend-report.md` | Conditional |
| `resources` | Research reports exist AND `include_resources: true` | Research `output/report.md` | Conditional |
| `custom` | User requests ad-hoc pages | User-specified | Per user request |
| `contact` | Always | Company details from project config | Always |
| `legal-imprint` / `legal-privacy` / `legal-cookies` | Managed by `website-legal` skill | Legal templates | Footer-only — never proposed by `website-plan` directly |

The `market` and `audience` page types are first-class narrative pages. They get their own URL tree (`pages/markets/{slug}.html`, `pages/audience/{persona}.html`) and appear in the header navigation as dropdown entries when at least two exist, so visitors can jump directly to content tuned to their segment.

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
| Insights | insights | tips-trend-report.md | Investitionsthemen + Trends |
| Ressourcen | resources | research reports | Forschungsberichte |
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
- `source_files` — markdown files to read for prose content (narrative is primary when present)
- `source_entities` — JSON entity files for structured enrichment
- `sections` — ordered list of section blocks (see step 6a for narrative pages)
- `meta_description` — SEO description (generate from content)

Use the page type definitions from `${CLAUDE_PLUGIN_ROOT}/libraries/page-templates.md` as reference for section lists and the "Section Block Library" appendix for narrative-page section patterns.

### 6a. Decompose Narrative Pages into Section Blocks

For every page whose spine is a `customer-narrative/*.md` file (`home`, `market`, `audience`), do not emit a flat list of generic template section names. Instead, decompose the narrative into an ordered sequence of **section blocks** using the story-to-web pattern. This produces scroll-driven reading experiences instead of entity-card dumps.

The decomposition rules are defined in cogni-visual's story-to-web skill and referenced rather than duplicated here. Read once, apply per page:

- Section taxonomy + decision tree: `$CLAUDE_PLUGIN_ROOT/../cogni-visual/skills/story-to-web/references/02-section-architecture.md` (decision tree lives around lines 145–187)
- Copywriting rules (assertion headlines, number plays, bullet discipline): `$CLAUDE_PLUGIN_ROOT/../cogni-visual/skills/story-to-web/references/03-section-copywriting.md`

For each narrative page, walk the markdown in order:

1. **Governing thought → `hero` block.** Use the narrative H1 as the assertion headline, the intro paragraph as the subline, and the final-step CTA verb as the hero button text. Section theme: `dark`.
2. **Each H2 section → one block**, typed by content shape:
   - Bulleted pain list → `problem-statement` (light)
   - 3+ numeric data points → `stat-row` (dark)
   - 4+ parallel capabilities → `feature-grid` (light-alt)
   - Single argument + implied imagery → `feature-alternating` (light, alternate side per block)
   - 3–5 sequential steps → `timeline` (light-alt)
   - Direct attributed quote → `testimonial` (dark)
   - Before/after or contrast prose → `comparison` (light-alt)
   - Prose bridge → `text-block` (light)
3. **Final H2 (CTA / Nächster Schritt / Einstieg) → `cta` block** (accent).
4. **Enforce theme bookends and alternation:** hero first (`dark`), CTA last (`accent`), and no two adjacent non-bookend blocks may share a `section_theme`. Swap `light` ↔ `light-alt` to resolve collisions.
5. **Carry citations through:** collect superscript references ([1], [2]…) into a `citations` array on the page spec so the generator can render a footnote block at the bottom of the page.

Each section block in `sections[]` is an object, not a bare string:

```json
{
  "block_type": "problem-statement",
  "section_theme": "light",
  "arc_role": "problem",
  "section_label": "Ihre Herausforderungen",
  "headline": "Legacy-Systeme kosten €134 Millionen pro Jahr — unsichtbar",
  "body": "...",
  "bullets": [
    "Tarifkalkulation dauert 4 Wochen statt 4 Tage",
    "44% Kundenabbruch in digitalen Journeys"
  ],
  "stat_number": "€134M",
  "confidence": 0.87,
  "source_anchor": "## Ihre Herausforderungen"
}
```

`source_anchor` lets the `page-generator` find the exact H2 in the narrative markdown and lift the copy verbatim without re-authoring it.

**Back-compat note.** Legacy page types (`about`, `products`, `product-detail`, `blog-*`, `insights`, `resources`, `contact`, `legal-*`) keep using the flat `sections: ["hero", "features", "cta"]` string-array form. The page-generator agent accepts both shapes and picks its renderer accordingly. Do not retrofit legacy pages unless the user asks for it.

### 6a. Merge Legal Pages (if any)

Check the project directory for `legal-pages.json` — this is the queue file written by `website-legal` when it runs before `website-plan`. If it exists:

1. Read it. The structure mirrors a partial `website-plan.json`: a `pages[]` array with `legal-*` entries and a `legal_links[]` array.
2. Append the `legal-*` page entries to the plan's `pages[]`.
3. Copy the `legal_links` array onto the plan as a top-level field.
4. Delete `legal-pages.json` after a successful merge — it has served its purpose.

If `legal-pages.json` does **not** exist but `legal_config.jurisdiction` is set in `website-project.json`, print a reminder at the end of step 8: "Hinweis: Rechtliche Seiten fehlen — bitte /website-legal ausführen, bevor /website-build läuft."

### 7. Generate website-plan.json

Write the complete plan following the format in `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md`.

**Footer-only pages**: any page with `footer_only: true` (legal pages, optionally also custom legal-adjacent pages) must be excluded from the auto-generated header navigation in step 5. They are linked exclusively from the footer legal column built from the `legal_links` array.

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
