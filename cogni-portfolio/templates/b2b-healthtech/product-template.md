# Product Template

The B2B HealthTech Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any health IT platform company can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 EHR/EMR) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — ARR, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Clinical Systems | `clinical-systems` | Clinical Systems | EHR/EMR, clinical decision support, medication management, lab, radiology, and surgical IT |
| 2. Patient Engagement | `patient-engagement` | Patient Engagement | Patient portal, telehealth, remote monitoring, scheduling, communication, and consumer apps |
| 3. Health Data & Interoperability | `health-data-interoperability` | Health Data & Interoperability | HIE, FHIR/HL7 integration, clinical data warehouse, population health, AI analytics, and MPI |
| 4. Revenue Cycle & Operations | `revenue-cycle-operations` | Revenue Cycle & Operations | Revenue cycle management, claims, coding, supply chain, and workforce management |
| 5. Regulatory & Compliance | `regulatory-compliance` | Regulatory & Compliance | HIPAA tools, quality reporting, MDR/FDA compliance, clinical trials, and pharmacovigilance |
| 6. Life Sciences Platform | `life-sciences-platform` | Life Sciences Platform | Drug discovery, real-world evidence, genomics, device connectivity, and research informatics |
| 7. Advisory & Implementation | `advisory-implementation` | Advisory & Implementation | Consulting, EHR implementation, training, managed operations, cybersecurity, and change management |

## Product JSON Example

```json
{
  "slug": "clinical-systems",
  "name": "Clinical Systems",
  "description": "EHR/EMR, clinical decision support, CPOE, laboratory information systems, radiology/PACS, and perioperative IT capabilities.",
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
  "slug": "fhir-r4-api",
  "product_slug": "health-data-interoperability",
  "name": "FHIR R4 API Gateway",
  "description": "Full FHIR R4 compliant API gateway with SMART on FHIR app launch, bulk data export, and patient-level access controls",
  "taxonomy_mapping": {
    "dimension": 3,
    "dimension_name": "Health Data & Interoperability",
    "category_id": "3.2",
    "category_name": "FHIR/HL7 Integration",
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
| `category_id` | string | Category ID (e.g. "1.1", "3.2") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Beta/early access, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
