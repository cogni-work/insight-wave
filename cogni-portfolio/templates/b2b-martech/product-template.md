# Product Template

The B2B MarTech Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any MarTech platform company can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 Customer Data Platform) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — ARR, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Customer Data & Identity | `customer-data-identity` | Customer Data & Identity | CDP, identity resolution, segmentation, enrichment, and consent capabilities |
| 2. Campaign & Marketing Automation | `campaign-marketing-automation` | Campaign & Marketing Automation | Email, automation, journey orchestration, testing, and lead management capabilities |
| 3. Content & Experience | `content-experience` | Content & Experience | CMS, DAM, personalization, commerce, search, and localization capabilities |
| 4. Advertising & Media | `advertising-media` | Advertising & Media | Programmatic, search, social, retail media, attribution, and planning capabilities |
| 5. Analytics & Intelligence | `analytics-intelligence` | Analytics & Intelligence | Marketing analytics, journey analytics, AI/ML, predictive modeling, and reporting |
| 6. Privacy & Compliance | `privacy-compliance` | Privacy & Compliance | Consent management, data privacy, brand safety, governance, and identity deprecation |
| 7. Services & Enablement | `services-enablement` | Services & Enablement | Implementation, consulting, creative, training, and managed campaign services |

## Product JSON Example

```json
{
  "slug": "customer-data-identity",
  "name": "Customer Data & Identity",
  "description": "CDP, identity resolution, audience segmentation, data enrichment, consent management, and data clean room capabilities.",
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
  "slug": "real-time-cdp",
  "product_slug": "customer-data-identity",
  "name": "Real-Time CDP",
  "description": "Unified customer profiles with real-time data ingestion, cross-channel activation, and audience sharing across advertising and marketing channels",
  "taxonomy_mapping": {
    "dimension": 1,
    "dimension_name": "Customer Data & Identity",
    "category_id": "1.1",
    "category_name": "Customer Data Platform (CDP)",
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
| `category_id` | string | Category ID (e.g. "1.1", "5.3") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Beta/early access, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
