# Product Template

The B2B Open-Source (COSS) Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any commercial open-source company can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 Core OSS Project) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — revenue, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Open Source Projects | `oss-projects` | Open Source Projects | Core open-source projects, community health, and governance |
| 2. Enterprise Platform | `enterprise-platform` | Enterprise Platform | Commercial features, security hardening, and enterprise-grade capabilities |
| 3. Cloud & Managed Services | `cloud-managed` | Cloud & Managed Services | Hosted, managed, and cloud-native deployment options |
| 4. Developer Ecosystem | `developer-ecosystem` | Developer Ecosystem | Developer tools, documentation, community, and partner ecosystem |
| 5. Support & Subscriptions | `support-subscriptions` | Support & Subscriptions | Support tiers, SLAs, and recurring subscription offerings |
| 6. Professional Services | `professional-services` | Professional Services | Implementation, optimization, training, and managed operations |
| 7. Licensing & Monetization | `licensing` | Licensing & Monetization | License models, usage metering, and commercial terms |

## Product JSON Example

```json
{
  "slug": "enterprise-platform",
  "name": "Enterprise Platform",
  "description": "Commercial features beyond the open-source core including security hardening, HA clustering, multi-tenancy, and enterprise integrations.",
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
  "slug": "fips-140-compliance",
  "product_slug": "enterprise-platform",
  "name": "FIPS 140-2 Compliance Module",
  "description": "FIPS 140-2 validated cryptographic modules for government and regulated industry deployments",
  "taxonomy_mapping": {
    "dimension": 2,
    "dimension_name": "Enterprise Platform",
    "category_id": "2.2",
    "category_name": "Security Hardening & FIPS",
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
| `category_id` | string | Category ID (e.g. "2.2", "7.1") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Beta/early access, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |

## OSS-Specific Mapping Notes

- **Dimension 1 (Open Source Projects)** maps to features that describe the OSS foundation. These are not directly sellable but are critical for portfolio positioning — the open-source project IS the product's credibility.
- **Dimension 7 (Licensing & Monetization)** features describe the business model architecture. While not "features" in the traditional sense, they are essential portfolio entities that inform IS/DOES/MEANS proposition generation.
- The **IS statement** for COSS propositions often draws from Dimension 1 (the OSS capability), while **DOES** draws from Dimension 2 (the enterprise wrapper) or Dimension 3 (the managed cloud), and **MEANS** articulates the buyer outcome.
