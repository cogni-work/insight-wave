# Product Template

The B2B Fintech Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any fintech platform company can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 Card Processing) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — ARR, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Payment Services | `payment-services` | Payment Services | Card processing, digital wallets, cross-border, real-time payments, acquiring, orchestration, and billing |
| 2. Banking & Lending Platform | `banking-lending-platform` | Banking & Lending Platform | Core banking, lending origination, deposit management, account management, open banking, and BaaS |
| 3. Risk & Compliance | `risk-compliance` | Risk & Compliance | KYC/AML, fraud detection, credit scoring, regulatory reporting, transaction monitoring, and sanctions |
| 4. Capital Markets & Trading | `capital-markets-trading` | Capital Markets & Trading | Trading platforms, order management, market data, portfolio management, clearing, and algo trading |
| 5. Insurance Technology | `insurance-technology` | Insurance Technology | Policy administration, claims, underwriting, distribution, and actuarial analytics |
| 6. Data & Intelligence | `data-intelligence` | Data & Intelligence | Financial analytics, embedded finance APIs, AI/ML, data aggregation, reporting, and customer insights |
| 7. Advisory & Implementation | `advisory-implementation` | Advisory & Implementation | Regulatory consulting, implementation, digital transformation, program management, managed ops, and training |

## Product JSON Example

```json
{
  "slug": "payment-services",
  "name": "Payment Services",
  "description": "Card processing, digital wallets, cross-border payments, real-time payments, merchant acquiring, payment orchestration, and billing capabilities.",
  "revenue_model": "transaction-fee",
  "commercial_model": "usage",
  "maturity": "growth",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-21"
}
```

## Feature JSON Example

A discovered offering mapped to a feature entity:

```json
{
  "slug": "smart-payment-routing",
  "product_slug": "payment-services",
  "name": "Smart Payment Routing",
  "description": "Intelligent routing engine that optimizes authorization rates by selecting the best PSP/acquirer per transaction based on card type, geography, and historical performance",
  "taxonomy_mapping": {
    "dimension": 1,
    "dimension_name": "Payment Services",
    "category_id": "1.6",
    "category_name": "Payment Orchestration",
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
| `category_id` | string | Category ID (e.g. "1.6", "3.2") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Beta/early access, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
