# Product Template

The B2B Industrial Technology Portfolio taxonomy defines a **product template** — a predefined skeleton that maps taxonomy structure to the cogni-portfolio data model. Any industrial technology company can use this template as a starting point for their portfolio.

## Taxonomy → Data Model Mapping

| Taxonomy Level | Portfolio Entity | Mapping Rule |
|---|---|---|
| Dimension 0 (Provider Profile) | Provider metadata in `portfolio.json` | Project-level metrics, not a product |
| Dimensions 1-7 | **Product** (one per dimension) | Only create if dimension has >=1 confirmed offering |
| Category (e.g. 1.1 PLC/DCS Systems) | Feature classification slot | Categories are taxonomy positions, not features themselves |
| Discovered offering | **Feature** (`features/{slug}.json`) | Concrete capability with `taxonomy_mapping` field |

## Why Dimension 0 Is Not a Product

Dimension 0 (Provider Profile Metrics) captures company-level facts — revenue, headcount, certifications, partnerships. These describe the provider, not a sellable capability. They belong in `portfolio.json` as project metadata, not as a product with features.

## Default Product Definitions

Create one product per active dimension (only if that dimension has confirmed offerings):

| Dimension | Product Slug | Product Name | Description |
|---|---|---|---|
| 1. Automation & Control | `automation-control` | Automation & Control | PLC/DCS, SCADA/HMI, motion control, instrumentation, networking, edge, and safety systems |
| 2. Manufacturing Execution | `manufacturing-execution` | Manufacturing Execution | MES/MOM platforms, quality management, scheduling, track & trace, batch, and warehouse execution |
| 3. Digital Twin & Simulation | `digital-twin-simulation` | Digital Twin & Simulation | Product/process/asset digital twins, simulation, virtual commissioning, and AR/VR |
| 4. Industrial IoT & Data | `industrial-iot-data` | Industrial IoT & Data | IoT platform, data management, predictive analytics, condition monitoring, energy, and emissions |
| 5. OT Cybersecurity | `ot-cybersecurity` | OT Cybersecurity | OT network security, asset visibility, OT SOC, vulnerability management, IEC 62443, secure remote access |
| 6. Lifecycle & Service | `lifecycle-service` | Lifecycle & Service | Asset lifecycle, maintenance, field service, spare parts, and remote monitoring |
| 7. Engineering & Advisory | `engineering-advisory` | Engineering & Advisory | Plant engineering, digital transformation consulting, system integration, training, managed operations, sustainability |

## Product JSON Example

```json
{
  "slug": "automation-control",
  "name": "Automation & Control",
  "description": "PLC/DCS systems, SCADA/HMI, motion control & robotics, instrumentation, industrial networking, edge computing, and safety systems.",
  "revenue_model": "product_and_license",
  "commercial_model": "catalog",
  "maturity": "established",
  "source_file": "research/{company-slug}-portfolio.md",
  "created": "2026-03-21"
}
```

## Feature JSON Example

A discovered offering mapped to a feature entity:

```json
{
  "slug": "simatic-s7-1500",
  "product_slug": "automation-control",
  "name": "SIMATIC S7-1500 PLC",
  "description": "Advanced PLC platform with integrated motion control, safety, and security features for discrete and process automation",
  "taxonomy_mapping": {
    "dimension": 1,
    "dimension_name": "Automation & Control",
    "category_id": "1.1",
    "category_name": "PLC/DCS Systems",
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
| `category_id` | string | Category ID (e.g. "1.1", "4.3") |
| `category_name` | string | Human-readable category name |
| `horizon` | string | `current`, `emerging`, or `future` |

## Readiness Mapping

The scan's Service Horizon maps to the feature's `readiness` field:

| Horizon | Readiness | Meaning |
|---|---|---|
| Current | `ga` | Generally available, proven deployments |
| Emerging | `beta` | Beta/early access, limited availability |
| Future | `planned` | Announced, conceptual, R&D phase |
