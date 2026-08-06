# Product Template

The B2B Professional Services Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any professional services firm can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 Corporate Strategy) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures firm-level facts — revenue, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Strategy & Transformation | `strategy-transformation` | Strategy & Transformation | Corporate strategy, operating model, M&A, transformation, and ESG advisory |
| 2. Operations & Performance | `operations-performance` | Operations & Performance | Supply chain, process excellence, procurement, and cost transformation advisory |
| 3. Technology & Digital Advisory | `technology-digital-advisory` | Technology & Digital Advisory | Digital strategy, technology selection, data/AI, cybersecurity, and cloud advisory |
| 4. Industry Practices | `industry-practices` | Industry Practices | Vertical-specific expertise across financial services, healthcare, energy, public sector, manufacturing, and TMT |
| 5. Risk, Compliance & Assurance | `risk-compliance-assurance` | Risk, Compliance & Assurance | Regulatory, audit, forensic, enterprise risk, and third-party risk services |
| 6. People & Change | `people-change` | People & Change | Change management, talent advisory, leadership development, and HR transformation |
| 7. Engagement Models | `engagement-models` | Engagement Models | Retainer, project-based, managed services, secondment, and outcome-based delivery models |

## Product JSON Example

```json
{
  "slug": "strategy-transformation",
  "name": "Strategy & Transformation",
  "description": "Corporate strategy, operating model design, M&A advisory, organizational transformation, innovation, and ESG strategy capabilities.",
  "revenue_model": "project-fee",
  "commercial_model": "project",
  "maturity": "growth",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-21"
}
```

## Feature JSON Example

A discovered offering mapped to a feature entity:

```json
{
  "slug": "post-merger-integration",
  "product_slug": "strategy-transformation",
  "name": "Post-Merger Integration",
  "description": "End-to-end post-merger integration program covering Day 1 readiness, synergy tracking, cultural integration, and operating model harmonization",
  "taxonomy_mapping": {
    "dimension": 1,
    "dimension_name": "Strategy & Transformation",
    "category_id": "1.3",
    "category_name": "M&A Advisory",
    "horizon": "current"
  },
  "readiness": "ga",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-21"
}
```

## The `taxonomy_mapping` Field

Every feature created from a scan carries a `taxonomy_mapping` object:

| Field | Type | Description |
|---|---|---|
| `dimension` | integer | Dimension number (1-7) |
| `dimension_name` | string | Human-readable dimension name |
| `category_id` | string | Category ID (e.g. "1.3", "2.4") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven engagements |
| Emerging | `beta` | Pilot programs, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
