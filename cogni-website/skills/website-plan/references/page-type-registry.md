# Page Type Registry

Quick reference for the `website-plan` skill — which page types exist, when to include them, and what content they need.

## Page Types

| Type | Slug Pattern | Required Source | Optional Source | Sections |
|------|-------------|-----------------|-----------------|----------|
| `home` | `index` | Portfolio overview narrative OR portfolio.json | Propositions (top 3), products | hero, value-props, product-highlights, stats, cta |
| `about` | `pages/ueber-uns` | portfolio.json (company context) | — | page-header, company-story, mission, timeline, cta |
| `products` | `pages/produkte` | products/*.json | — | page-header, product-grid |
| `product-detail` | `pages/produkte/{slug}` | product JSON + its features | Propositions for this product, packages | product-hero, features, benefits, pricing, cta |
| `solutions` | `pages/loesungen` | solutions/*.json | packages/*.json, markets/*.json | page-header, solution-groups, cta |
| `blog-index` | `pages/blog` | Marketing content files | — | page-header, featured-post, post-grid |
| `blog-post` | `pages/blog/{slug}` | Single marketing content .md | Related posts | article-header, article-body, related-posts, cta |
| `case-studies` | `pages/fallstudien` | Customer narrative .md files | — | page-header, case-card-grid |
| `contact` | `pages/kontakt` | Company config (email, phone, address) | — | page-header, contact-form |

## Inclusion Rules

| Rule | Condition |
|------|-----------|
| Always include | home, about, products, contact |
| Include if ≥1 product | product-detail (one per product) |
| Include if solutions exist | solutions |
| Include if marketing content AND `include_blog: true` | blog-index + blog-post pages |
| Include if customer narratives AND `include_case_studies: true` | case-studies |

## Slug Generation

- German pages: replace umlauts (ü→ue, ö→oe, ä→ae, ß→ss)
- Lowercase, hyphens instead of spaces
- No special characters
- Max 3 levels deep: `pages/{section}/{item}`

## Content Mapping Priority

When multiple source files could feed a page, prefer:
1. Portfolio-communicate narratives (richest, already audience-tailored)
2. Portfolio synthesize output (structured, complete)
3. Raw entity JSON files (most granular, needs more transformation)
4. Marketing content files (for blog/articles only)
