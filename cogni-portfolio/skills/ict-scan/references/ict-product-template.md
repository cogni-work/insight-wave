# ICT Product Template

The B2B ICT Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any ICT service provider can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has ≥1 confirmed offering |
| Category (e.g. 1.1 WAN Services) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — revenue, headcount, certifications, partnerships. These describe the provider, not a sellable service. They belong in `portfolio.json` as project metadata or in a dedicated `provider-profile.json`, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Connectivity Services | `connectivity-services` | Connectivity Services | Network infrastructure and connectivity offerings |
| 2. Security Services | `security-services` | Security Services | Cybersecurity and compliance offerings |
| 3. Digital Workplace | `workplace-services` | Digital Workplace Services | End-user computing and collaboration offerings |
| 4. Cloud Services | `cloud-services` | Cloud Services | Cloud infrastructure, migration, and platform offerings |
| 5. Managed Infrastructure | `infrastructure-services` | Managed Infrastructure Services | Data center, compute, and operations offerings |
| 6. Application Services | `application-services` | Application Services | Software development, integration, and platform offerings |
| 7. Consulting Services | `consulting-services` | Consulting Services | Strategy, transformation, and advisory offerings |

## Product JSON Example

```json
{
  "slug": "connectivity-services",
  "name": "Connectivity Services",
  "description": "Network infrastructure and connectivity offerings including WAN, SASE, cloud connect, IoT, voice, and managed network services.",
  "revenue_model": "subscription",
  "maturity": "growth",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-12"
}
```

## Feature JSON Example

A discovered offering mapped to a feature entity:

```json
{
  "slug": "managed-sd-wan",
  "product_slug": "connectivity-services",
  "name": "Managed SD-WAN Pro",
  "description": "End-to-end SD-WAN with 24/7 NOC support and automated failover",
  "taxonomy_mapping": {
    "dimension": 1,
    "dimension_name": "Connectivity Services",
    "category_id": "1.1",
    "category_name": "WAN Services",
    "horizon": "current"
  },
  "readiness": "ga",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-12"
}
```

## The `taxonomy_mapping` Field

Every feature created from an ICT scan carries a `taxonomy_mapping` object:

| Field | Type | Description |
|---|---|---|
| `dimension` | integer | Dimension number (1-7) |
| `dimension_name` | string | Human-readable dimension name |
| `category_id` | string | Category ID (e.g. "1.1", "2.10") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Pilot/beta, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
