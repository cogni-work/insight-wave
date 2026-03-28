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
      "sections": ["hero", "value-props", "product-highlights", "stats", "cta"],
      "hero_renderer": "pencil"
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
    }
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
