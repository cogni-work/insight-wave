---
library_id: example-website-plan
version: 1.0.0
created: 2026-03-27
---

# Example Website Plan

A complete `website-plan.json` for a German B2B technology company with 3 products, 2 markets, and marketing content. This example demonstrates how the `website-plan` skill maps content sources to pages.

---

## Example: website-plan.json

```json
{
  "version": "1.0",
  "site_title": "SmartFactory Solutions",
  "language": "de",
  "base_url": "/",
  "theme_path": "/path/to/cogni-workspace/themes/smarter-service/theme.md",
  "design_variables_path": "output/design-variables.json",

  "pages": [
    {
      "id": "home",
      "type": "home",
      "slug": "index",
      "title": "SmartFactory Solutions — Intelligente Fertigung für den Mittelstand",
      "meta_description": "SmartFactory Solutions bietet Predictive Maintenance, Qualitätssicherung und Energiemanagement für mittelständische Fertigungsunternehmen.",
      "source_files": [
        "../cogni-portfolio/smartfactory/output/communicate/customer-narrative/portfolio-overview.md"
      ],
      "source_entities": {
        "products": "../cogni-portfolio/smartfactory/products/*.json",
        "propositions_top3": [
          "../cogni-portfolio/smartfactory/propositions/predictive-maintenance--grosse-fertigungsunternehmen-de.json",
          "../cogni-portfolio/smartfactory/propositions/qualitaetssicherung--grosse-fertigungsunternehmen-de.json",
          "../cogni-portfolio/smartfactory/propositions/energiemanagement--grosse-fertigungsunternehmen-de.json"
        ]
      },
      "sections": [
        {
          "block_type": "hero",
          "section_theme": "dark",
          "arc_role": "hook",
          "section_label": "SmartFactory Solutions",
          "headline": "Fertigung digitalisieren — ohne IT-Projekt von 18 Monaten",
          "subline": "Predictive Maintenance, Qualitätssicherung und Energiemanagement für den Mittelstand. Von der Anbindung bis zum ROI in 90 Tagen.",
          "cta_text": "Strategiegespräch vereinbaren",
          "cta_href": "/pages/kontakt.html",
          "source_anchor": "# SmartFactory Solutions"
        },
        {
          "block_type": "problem-statement",
          "section_theme": "light",
          "arc_role": "problem",
          "section_label": "Warum Veränderung",
          "headline": "Ungeplante Stillstände kosten €134M pro Jahr — unsichtbar",
          "stat_number": "€134M",
          "bullets": [
            "Stillstände im Schnitt 4 Stunden statt 40 Minuten",
            "44% Ausschussrate in manuellen Prüflinien",
            "Energiekosten steigen 12% Jahr für Jahr"
          ],
          "source_anchor": "## Was wir bieten"
        },
        {
          "block_type": "stat-row",
          "section_theme": "dark",
          "arc_role": "urgency",
          "headline": "Messbare Wirkung in drei Kennzahlen",
          "stats": [
            {"number": "73%", "label": "weniger Stillstände", "context": "nach 6 Monaten"},
            {"number": "€2.4M", "label": "Einsparung pro Linie", "context": "12-Monats-Schnitt"},
            {"number": "90 Tage", "label": "bis zum ersten ROI", "context": "garantiert"}
          ],
          "source_anchor": "## Auf dem Fahrplan"
        },
        {
          "block_type": "feature-alternating",
          "section_theme": "light",
          "arc_role": "solution",
          "section_label": "Für wen wir arbeiten",
          "headline": "Mittelständische Fertigung — DSGVO-konform und ohne CISO-Blocker",
          "body": "Unsere Lösungen laufen on-premise oder in deutschen Rechenzentren. Sie behalten die Datenhoheit, wir liefern die Methodik und die Modelle.",
          "image_prompt": "Modern German mid-sized factory floor, workers collaborating with tablets, natural light",
          "source_anchor": "## Für wen wir arbeiten"
        },
        {
          "block_type": "feature-alternating",
          "section_theme": "light-alt",
          "arc_role": "proof",
          "section_label": "Warum SmartFactory",
          "headline": "Methodik statt Black-Box-KI",
          "body": "Jede Vorhersage ist nachvollziehbar. Jeder Prozessschritt dokumentiert. Keine Wunder-KI, sondern bewährtes Engineering mit modernen Werkzeugen.",
          "image_prompt": "Engineer reviewing explainable ML dashboard on laptop, industrial setting",
          "source_anchor": "## Warum cogni-works"
        },
        {
          "block_type": "cta",
          "section_theme": "accent",
          "arc_role": "call-to-action",
          "headline": "In 30 Minuten klären, ob Ihre Linie reif ist",
          "body": "Kostenloses Erstgespräch. Keine Vorbereitung nötig. Danach wissen Sie, ob ein 90-Tage-Pilot für Sie sinnvoll ist.",
          "primary_cta": "Gespräch vereinbaren",
          "primary_href": "/pages/kontakt.html",
          "secondary_cta": "Open Source testen",
          "secondary_href": "https://github.com/insight-wave",
          "source_anchor": "## Nächster Schritt"
        }
      ],
      "citations": [
        {"n": 1, "source_text": "BMWK Studie: Industrie 4.0 im Mittelstand", "url": "https://example.com/bmwk-2025", "url_label": "bmwk.de/i4-mittelstand"},
        {"n": 2, "source_text": "VDMA Fertigungsbericht 2025", "url": "https://example.com/vdma-2025", "url_label": "vdma.org/bericht-2025"}
      ],
      "hero_renderer": "pencil"
    },

    {
      "id": "market-b2b-fertigung-dach",
      "type": "market",
      "slug": "pages/markets/b2b-fertigung-dach",
      "title": "Fertigung DACH — SmartFactory Solutions",
      "meta_description": "Lösungen für mittelständische Fertigungsunternehmen in DACH — Predictive Maintenance, Qualität, Energie.",
      "source_files": [
        "../cogni-portfolio/smartfactory/output/communicate/customer-narrative/market/b2b-fertigung-dach.md"
      ],
      "source_entities": {
        "propositions": "../cogni-portfolio/smartfactory/propositions/*grosse-fertigungsunternehmen-de*.json"
      },
      "sections": [
        {"block_type": "hero", "section_theme": "dark", "arc_role": "hook", "headline": "…", "source_anchor": "# …"},
        {"block_type": "problem-statement", "section_theme": "light", "arc_role": "problem", "headline": "Ihre Herausforderungen", "source_anchor": "## Ihre Herausforderungen"},
        {"block_type": "feature-grid", "section_theme": "light-alt", "arc_role": "solution", "headline": "Wie wir helfen", "source_anchor": "## Wie wir helfen"},
        {"block_type": "comparison", "section_theme": "light", "arc_role": "proof", "headline": "Was uns auszeichnet", "source_anchor": "## Was uns auszeichnet"},
        {"block_type": "cta", "section_theme": "accent", "arc_role": "call-to-action", "headline": "Lassen Sie uns sprechen", "source_anchor": "## Lassen Sie uns sprechen"}
      ]
    },

    {
      "id": "audience-vp-operations",
      "type": "audience",
      "slug": "pages/audience/vp-operations",
      "title": "Für VP Operations — SmartFactory Solutions",
      "meta_description": "73% weniger ungeplante Stillstände in 90 Tagen — DSGVO-konform, ohne IT-Projekt.",
      "source_files": [
        "../cogni-portfolio/smartfactory/output/communicate/customer-narrative/customer/b2b-fertigung-dach--vp-operations.md"
      ],
      "sections": [
        {"block_type": "hero", "section_theme": "dark", "arc_role": "hook", "headline": "…", "source_anchor": "# …"},
        {"block_type": "problem-statement", "section_theme": "light", "arc_role": "problem", "headline": "Was wir in Ihrer Welt sehen", "source_anchor": "## Was wir in Ihrer Welt sehen"},
        {"block_type": "feature-alternating", "section_theme": "light-alt", "arc_role": "solution", "headline": "Was wir auf den Tisch bringen", "source_anchor": "## Was wir auf den Tisch bringen"},
        {"block_type": "timeline", "section_theme": "light", "arc_role": "roadmap", "headline": "Empfohlener Einstiegspunkt", "source_anchor": "## Empfohlener Einstiegspunkt"},
        {"block_type": "testimonial", "section_theme": "dark", "arc_role": "proof", "headline": "Was Kunden sagen", "source_anchor": "## Was Kunden sagen"},
        {"block_type": "text-block", "section_theme": "light", "arc_role": "context", "headline": "Warum jetzt", "source_anchor": "## Warum jetzt"},
        {"block_type": "cta", "section_theme": "accent", "arc_role": "call-to-action", "headline": "Pilot-Kunde werden", "source_anchor": "## Wie wir zusammenarbeiten würden"}
      ]
    },

    {
      "id": "about",
      "type": "about",
      "slug": "pages/ueber-uns",
      "title": "Über uns — SmartFactory Solutions",
      "meta_description": "Erfahren Sie mehr über SmartFactory Solutions, unsere Mission und unsere Geschichte.",
      "source_files": [
        "../cogni-portfolio/smartfactory/portfolio.json"
      ],
      "sections": ["page-header", "company-story", "mission", "timeline", "cta"]
    },

    {
      "id": "products",
      "type": "products",
      "slug": "pages/produkte",
      "title": "Unsere Produkte — SmartFactory Solutions",
      "meta_description": "Entdecken Sie unsere Produkte für Predictive Maintenance, Qualitätssicherung und Energiemanagement.",
      "source_entities": {
        "products": "../cogni-portfolio/smartfactory/products/*.json"
      },
      "sections": ["page-header", "product-grid"]
    },

    {
      "id": "product-predictive-maintenance",
      "type": "product-detail",
      "slug": "pages/produkte/predictive-maintenance",
      "title": "Predictive Maintenance — SmartFactory Solutions",
      "meta_description": "Ungeplante Stillstände um 73% senken mit KI-gestützter vorausschauender Wartung.",
      "source_entities": {
        "product": "../cogni-portfolio/smartfactory/products/predictive-maintenance.json",
        "features": [
          "../cogni-portfolio/smartfactory/features/vibration-analytics.json",
          "../cogni-portfolio/smartfactory/features/anomaly-detection.json",
          "../cogni-portfolio/smartfactory/features/maintenance-scheduler.json"
        ],
        "propositions": "../cogni-portfolio/smartfactory/propositions/vibration-analytics--*.json"
      },
      "sections": ["product-hero", "features", "benefits", "pricing", "cta"]
    },

    {
      "id": "solutions",
      "type": "solutions",
      "slug": "pages/loesungen",
      "title": "Lösungen — SmartFactory Solutions",
      "meta_description": "Maßgeschneiderte Lösungen für Fertigungsunternehmen — von Proof of Value bis Enterprise-Rollout.",
      "source_entities": {
        "solutions": "../cogni-portfolio/smartfactory/solutions/*.json",
        "packages": "../cogni-portfolio/smartfactory/packages/*.json",
        "markets": "../cogni-portfolio/smartfactory/markets/*.json"
      },
      "sections": ["page-header", "solution-groups", "cta"]
    },

    {
      "id": "blog",
      "type": "blog-index",
      "slug": "pages/blog",
      "title": "Blog — SmartFactory Solutions",
      "meta_description": "Insights zu Predictive Maintenance, Industrie 4.0 und intelligenter Fertigung.",
      "source_files": [
        "../cogni-marketing/smartfactory/content/thought-leadership/*.md",
        "../cogni-marketing/smartfactory/content/demand-generation/*.md"
      ],
      "sections": ["page-header", "featured-post", "post-grid"],
      "sort": "date_desc",
      "limit": 12
    },

    {
      "id": "blog-post-predictive-maintenance-roi",
      "type": "blog-post",
      "slug": "pages/blog/predictive-maintenance-roi-berechnen",
      "title": "So berechnen Sie den ROI von Predictive Maintenance — SmartFactory Solutions",
      "source_files": [
        "../cogni-marketing/smartfactory/content/thought-leadership/grosse-fertigungsunternehmen-de--industrie-4-0--blog.md"
      ],
      "sections": ["article-header", "article-body", "related-posts", "cta"]
    },

    {
      "id": "case-studies",
      "type": "case-studies",
      "slug": "pages/fallstudien",
      "title": "Fallstudien — SmartFactory Solutions",
      "meta_description": "Erfahren Sie, wie unsere Kunden mit SmartFactory Solutions ihre Fertigung optimieren.",
      "source_files": [
        "../cogni-portfolio/smartfactory/output/communicate/customer-narrative/market/*.md"
      ],
      "sections": ["page-header", "case-card-grid"]
    },

    {
      "id": "contact",
      "type": "contact",
      "slug": "pages/kontakt",
      "title": "Kontakt — SmartFactory Solutions",
      "meta_description": "Nehmen Sie Kontakt mit uns auf — wir beraten Sie gerne.",
      "source_files": [],
      "sections": ["page-header", "contact-form", "map"]
    },

    {
      "id": "legal-imprint",
      "type": "legal-imprint",
      "slug": "pages/impressum",
      "title": "Impressum — SmartFactory Solutions",
      "meta_description": "Impressum gemäß § 5 TMG.",
      "source_files": ["content/legal/impressum.md"],
      "sections": ["legal-header", "legal-body"],
      "footer_only": true
    },

    {
      "id": "legal-privacy",
      "type": "legal-privacy",
      "slug": "pages/datenschutz",
      "title": "Datenschutzerklärung — SmartFactory Solutions",
      "meta_description": "Informationen zur Verarbeitung personenbezogener Daten gemäß DSGVO.",
      "source_files": ["content/legal/datenschutz.md"],
      "sections": ["legal-header", "legal-body"],
      "footer_only": true
    },

    {
      "id": "legal-cookies",
      "type": "legal-cookies",
      "slug": "pages/cookies",
      "title": "Cookie-Hinweis — SmartFactory Solutions",
      "meta_description": "Welche Cookies diese Website verwendet.",
      "source_files": ["content/legal/cookies.md"],
      "sections": ["legal-header", "legal-body"],
      "footer_only": true
    }
  ],

  "legal_links": [
    { "label": "Impressum",   "href": "/pages/impressum.html" },
    { "label": "Datenschutz", "href": "/pages/datenschutz.html" },
    { "label": "Cookies",     "href": "/pages/cookies.html" }
  ],

  "navigation": {
    "header": {
      "logo_text": "SmartFactory Solutions",
      "logo_image": null,
      "nav": [
        {
          "label": "Produkte",
          "href": "/pages/produkte.html",
          "children": [
            { "label": "Predictive Maintenance", "href": "/pages/produkte/predictive-maintenance.html" },
            { "label": "Qualitätssicherung", "href": "/pages/produkte/qualitaetssicherung.html" },
            { "label": "Energiemanagement", "href": "/pages/produkte/energiemanagement.html" }
          ]
        },
        { "label": "Lösungen", "href": "/pages/loesungen.html" },
        { "label": "Blog", "href": "/pages/blog.html" },
        { "label": "Fallstudien", "href": "/pages/fallstudien.html" },
        { "label": "Über uns", "href": "/pages/ueber-uns.html" }
      ],
      "cta": {
        "label": "Kontakt aufnehmen",
        "href": "/pages/kontakt.html"
      }
    },
    "footer": {
      "columns": [
        {
          "title": "Produkte",
          "links": [
            { "label": "Predictive Maintenance", "href": "/pages/produkte/predictive-maintenance.html" },
            { "label": "Qualitätssicherung", "href": "/pages/produkte/qualitaetssicherung.html" },
            { "label": "Energiemanagement", "href": "/pages/produkte/energiemanagement.html" }
          ]
        },
        {
          "title": "Unternehmen",
          "links": [
            { "label": "Über uns", "href": "/pages/ueber-uns.html" },
            { "label": "Blog", "href": "/pages/blog.html" },
            { "label": "Fallstudien", "href": "/pages/fallstudien.html" },
            { "label": "Kontakt", "href": "/pages/kontakt.html" }
          ]
        }
      ],
      "company_name": "SmartFactory Solutions GmbH",
      "tagline": "Intelligente Fertigung für den Mittelstand",
      "copyright_year": 2026
    }
  },

  "sitemap": true,
  "robots_txt": true
}
```

---

## Commentary

### Page-to-Source Mapping

Each page has two ways to reference content:

1. **`source_files`** — direct paths to markdown files (narratives, articles, reports). The page-generator reads the full file and transforms it into HTML sections.

2. **`source_entities`** — glob patterns or arrays pointing to JSON entity files (products, features, propositions). The page-generator reads structured data and maps fields to template slots.

Both can coexist on the same page. The homepage uses a narrative file for prose structure AND entity files for stats and product highlights.

### Hero Renderer

Only the homepage specifies `"hero_renderer": "pencil"`. All other pages use CSS-only heroes (gradient backgrounds, no AI images). This keeps the build fast — only one Pencil MCP session is needed.

### Blog Posts

Blog posts are dynamically discovered from the marketing project's content directories. The `website-plan` skill reads all `.md` files matching the glob patterns, extracts YAML frontmatter (title, date, category), and generates one `blog-post` page entry per file.

The `blog-index` page aggregates all blog-post pages, sorted by date descending, limited to 12.

### Navigation Auto-Generation

The `website-plan` skill builds the navigation structure from the page list:
- Products dropdown children come from all `product-detail` pages
- Blog and case-studies are single links (no children)
- CTA always points to the contact page
- Footer columns group pages by category

### Legal Pages

The three `legal-*` pages are managed by the `website-legal` skill, not by the `website-plan` skill. They share these properties:

- `footer_only: true` — excluded from the auto-generated header navigation
- `source_files` points to `content/legal/{slug}.md` — markdown files rendered from jurisdiction-specific templates by `website-legal`
- `sections: ["legal-header", "legal-body"]` — the simple two-section layout defined in `libraries/legal-pages.md`
- The slug pattern depends on jurisdiction (DE/AT/CH use `impressum`/`datenschutz`/`cookies`, EU uses `legal-notice`/`privacy-policy`/`cookies`)

The top-level `legal_links` array (parallel to `pages` and `navigation`) tells the `site-assembler` to render a dedicated **Rechtliches** column in the footer linking to these pages. Without `legal_links`, no legal column appears.

### Example legal_config in website-project.json

The `legal_config` block lives in `website-project.json`, **not** in `website-plan.json`. It is captured by `website-setup` (step 3a) and refined by `website-legal`. Example for a German GmbH:

```json
{
  "legal_config": {
    "jurisdiction": "de",
    "site_audience": "b2b",
    "legal_entity": {
      "legal_name": "SmartFactory Solutions GmbH",
      "legal_form": "GmbH",
      "address": {
        "street": "Beispielstraße 12",
        "postal_code": "80331",
        "city": "München",
        "country": "Deutschland"
      },
      "register_court": "Amtsgericht München",
      "register_number": "HRB 123456",
      "vat_id": "DE123456789",
      "tax_id": null
    },
    "responsible_person": {
      "name": "Maria Mustermann",
      "role": "Geschäftsführerin",
      "address_same_as_entity": true,
      "address": null
    },
    "supervisory_authority": { "name": null, "address": null, "url": null },
    "professional_regulations": { "title": null, "awarded_in": null, "rules_url": null },
    "contact": {
      "email": "kontakt@smartfactory.example",
      "phone": "+49 89 12345678"
    },
    "data_protection": {
      "controller_name": "SmartFactory Solutions GmbH",
      "controller_contact": "datenschutz@smartfactory.example",
      "dpo_required": false,
      "dpo_name": null,
      "dpo_contact": null,
      "uses_analytics": false,
      "uses_marketing_cookies": false,
      "uses_external_fonts": false,
      "uses_external_embeds": false
    },
    "dispute_resolution": {
      "os_platform_link": "https://ec.europa.eu/consumers/odr",
      "willing_to_participate": false
    },
    "generated_at": "2026-04-08",
    "template_version": "1.0.0"
  }
}
```

The full schema and per-jurisdiction requirement matrix lives in `cogni-website/skills/website-legal/references/legal-config-schema.md`.

### Slug Convention

- Homepage: `index` (→ `index.html`)
- All other pages: `pages/{name}` (→ `pages/{name}.html`)
- Nested pages: `pages/{parent}/{child}` (→ `pages/{parent}/{child}.html`)
- German slugs: lowercase with umlauts replaced (`ü→ue`, `ö→oe`, `ä→ae`, `ß→ss`)

### Output Structure

```
output/website/
├── index.html                        ← home
├── css/
│   └── style.css                     ← shared stylesheet
├── images/
│   ├── hero-bg.png                   ← Pencil MCP generated
│   └── ...
├── pages/
│   ├── ueber-uns.html                ← about
│   ├── produkte.html                 ← products
│   ├── produkte/
│   │   ├── predictive-maintenance.html
│   │   ├── qualitaetssicherung.html
│   │   └── energiemanagement.html
│   ├── loesungen.html                ← solutions
│   ├── blog.html                     ← blog-index
│   ├── blog/
│   │   ├── predictive-maintenance-roi-berechnen.html
│   │   └── ...
│   ├── fallstudien.html              ← case-studies
│   └── kontakt.html                  ← contact
└── sitemap.xml
```
