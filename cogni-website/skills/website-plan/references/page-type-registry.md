# Page Type Registry

Quick reference for the `website-plan` skill — which page types exist, when to include them, and what content they need.

## Page Types

| Type | Slug Pattern | Required Source | Optional Source | Sections |
|------|-------------|-----------------|-----------------|----------|
| `home` | `index` | `customer-narrative/home.md` (arc `jtbd-portfolio`) OR portfolio.json | Propositions (top 3), products | **Structured** via step 6a when narrative present; else flat: hero, value-props, product-highlights, stats, cta |
| `about` | `pages/ueber-uns` | `customer-narrative/about.md` (arc `company-credo`) OR portfolio.json | — | **Structured** via step 6a when narrative present; else flat: page-header, company-story, mission, timeline, cta |
| `approach` | `pages/unser-ansatz` (DE) / `pages/approach` (EN) | `customer-narrative/approach.md` (arc `engagement-model`) | — | **Structured** via step 6a (principles → process → partnership → outcomes). Only proposed when `approach.md` exists. |
| `capability` | `pages/leistungen/{feature-slug}` (DE) / `pages/capabilities/{feature-slug}` (EN) | `customer-narrative/capabilities/{feature-slug}.md` (arc `corporate-visions`) | Linked product, related propositions | **Structured** via step 6a (why change → why now → why you → why pay). Replaces `product-detail` for features with a v2 narrative. |
| `persona` | `pages/fuer/{market}--{persona}` (DE) / `pages/for/{market}--{persona}` (EN) | `customer-narrative/for/{market}--{persona}.md` (arc `jtbd-portfolio`) | Relevant capabilities for this persona | **Structured** via step 6a. Renamed from v1 `audience`. Links out to capability pages rather than inlining them. |
| `products` | `pages/produkte` | products/*.json | — | page-header, product-grid |
| `product-detail` | `pages/produkte/{slug}` | product JSON + its features | Propositions for this product, packages | Flat fallback when no `capabilities/{slug}.md` exists. Prefer `capability` when the v2 narrative is present. |
| `solutions` | `pages/loesungen` | solutions/*.json | packages/*.json, markets/*.json | page-header, solution-groups, cta |
| `blog-index` | `pages/blog` | Marketing content files | — | page-header, featured-post, post-grid |
| `blog-post` | `pages/blog/{slug}` | Single marketing content .md | Related posts | article-header, article-body, related-posts, cta |
| `case-studies` | `pages/fallstudien` | Customer narrative .md files | — | page-header, case-card-grid |
| `insights` | `pages/insights` | tips-trend-report.md | tips-value-model.json (investment themes) | page-header, trend-highlights, investment-themes, cta |
| `resources` | `pages/ressourcen` | Research report .md files | — | page-header, report-cards, cta |
| `custom` | `pages/{user-slug}` | User-provided markdown file | — | page-header, prose, cta |
| `contact` | `pages/kontakt` | Company config (email, phone, address) | — | page-header, contact-form |
| `legal-imprint` | `pages/impressum` (DE/AT/CH) or `pages/legal-notice` (EU) | `content/legal/impressum.md` (or `legal-notice.md`) | — | legal-header, legal-body |
| `legal-privacy` | `pages/datenschutz` (DE/AT/CH) or `pages/privacy-policy` (EU) | `content/legal/datenschutz.md` (or `privacy-policy.md`) | — | legal-header, legal-body |
| `legal-cookies` | `pages/cookies` | `content/legal/cookies.md` | — | legal-header, legal-body |

## Inclusion Rules

| Rule | Condition |
|------|-----------|
| Always include | home, about, products, contact |
| Include if `approach.md` exists | approach |
| Include per `capabilities/*.md` file | capability (one per narrative) |
| Include per `for/*.md` file | persona (one per narrative) |
| Include if ≥1 product AND no matching `capabilities/{slug}.md` | product-detail (one per product without a capability narrative) |
| Include if solutions exist | solutions |
| Include if marketing content AND `include_blog: true` | blog-index + blog-post pages |
| Include if customer narratives AND `include_case_studies: true` | case-studies |
| Include if trend report exists AND `include_insights: true` | insights |
| Include if research reports exist AND `include_resources: true` | resources |
| Include if user requests ad-hoc pages | custom (one per user-specified page) |
| Include automatically if `legal_config.jurisdiction` set | `legal-imprint`, `legal-privacy`, `legal-cookies` (created by `website-legal`, not by `website-plan` itself) |

## Legal page types

The three `legal-*` page types are **created and managed by the `website-legal` skill**, not by `website-plan`. They are listed here so the page-generator and site-assembler agents know how to render them.

When `website-plan` runs, it should:

1. Check whether `legal-pages.json` exists in the project directory (the queue file written by `website-legal` if it ran first). If present, merge its `pages[]` entries and `legal_links` array into the plan being generated.
2. Check whether `legal_config.jurisdiction` is set in `website-project.json` but `legal-pages.json` does not exist and the plan does not yet contain `legal-*` entries. If so, **do not** propose them to the user — instead, print a hint at the end of step 8: "Hinweis: Rechtliche Seiten fehlen noch — bitte /website-legal ausführen, bevor /website-build läuft."
3. Mark all `legal-*` page entries with `footer_only: true` so step 5 (Build Navigation Structure) excludes them from the primary header nav. They appear only in the footer legal column via the `legal_links` array.

## Slug Generation

- German pages: replace umlauts (ü→ue, ö→oe, ä→ae, ß→ss)
- Lowercase, hyphens instead of spaces
- No special characters
- Max 3 levels deep: `pages/{section}/{item}`

## Content Mapping Priority

When multiple source files could feed a page, prefer:
1. Portfolio-communicate v2 narratives (richest, arc-structured, already audience-tailored — each file carries `arc_id` in frontmatter)
2. Portfolio entity data (structured, complete)
3. Trend reports (executive-ready narrative with inline citations)
4. Research reports (comprehensive, well-cited analysis)
5. Raw entity JSON files (most granular, needs more transformation)
6. Marketing content files (for blog/articles only)
