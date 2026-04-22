# Product Template

The B2B ICT Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any ICT service provider can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

The mapping is **mode-conditional** — the `CONSOLIDATION_MODE` chosen at Phase 0 of `portfolio-scan` decides whether a discovered offering becomes a feature (per-offering differentiation) or a solution-seed (per-stack delivery detail under a category-grained feature). See [`cogni-portfolio/skills/portfolio-scan/references/consolidation-modes.md`](../../skills/portfolio-scan/references/consolidation-modes.md) for the full rationale.

| Taxonomy Level | Portfolio Entity — `consolidate` / `shadow` (default) | Portfolio Entity — `category-aggregation` | Mapping Rule |
|---|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 WAN Services) | Feature classification slot | **Feature** (`features/{slug}.json`) | In `consolidate` / `shadow`, categories are taxonomy positions, not features themselves. In `category-aggregation`, the category itself becomes a category-grained feature (≤57 features for b2b-ict). |
| Discovered offering | **Feature** (`features/{slug}.json`) | **Solution-seed** entry in `research/scan-solutions-draft.json` — one per delivery stack per category | In `consolidate` / `shadow`, each offering is its own feature (per-provider differentiation). In `category-aggregation`, offerings are rolled up as delivery-stack variants (OTC / AWS / GCP / on-prem / …) under the category-grained feature; `solutions/` seeds per-stack solution entities from the feature-level artifact. |

Under `research-only`, nothing in this table is written — Phase 7 is skipped and the Phase 6 report is the only deliverable. See [consolidation-modes.md](../../skills/portfolio-scan/references/consolidation-modes.md) for when to pick each mode.

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

Every feature created from a scan carries a `taxonomy_mapping` object:

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
