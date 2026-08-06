# Product Template

The B2B SaaS Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any SaaS platform company can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 Product Editions) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — ARR, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Core Platform | `core-platform` | Core Platform | Product architecture, editions, APIs, and extensibility capabilities |
| 2. Data & Analytics | `data-analytics` | Data & Analytics | Reporting, analytics, AI/ML, and data management capabilities |
| 3. Integration & Ecosystem | `integration-ecosystem` | Integration & Ecosystem | Integrations, marketplace, APIs, and developer tools |
| 4. Security & Compliance | `security-compliance` | Security & Compliance | Authentication, access control, encryption, and compliance capabilities |
| 5. Customer Success & Support | `customer-success` | Customer Success & Support | Onboarding, training, support, and professional services |
| 6. Pricing & Packaging | `pricing-packaging` | Pricing & Packaging | Subscription models, licensing, and commercial packaging |
| 7. Industry Solutions | `industry-solutions` | Industry Solutions | Vertical-specific modules and configurations |

## Product JSON Example

```json
{
  "slug": "core-platform",
  "name": "Core Platform",
  "description": "Product architecture, editions, APIs, extensibility framework, mobile, and white-label capabilities.",
  "revenue_model": "subscription",
  "commercial_model": "subscription",
  "maturity": "growth",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-21"
}
```

## Feature JSON Example

A discovered offering mapped to a feature entity:

```json
{
  "slug": "graphql-api",
  "product_slug": "core-platform",
  "name": "GraphQL API",
  "description": "Full GraphQL API with real-time subscriptions, batched queries, and rate limiting per plan tier",
  "taxonomy_mapping": {
    "dimension": 1,
    "dimension_name": "Core Platform",
    "category_id": "1.3",
    "category_name": "Platform API",
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
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Beta/early access, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
