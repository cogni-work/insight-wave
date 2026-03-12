# Scan Entity Schema

Each discovered offering is captured with 11 fields during research. These are intermediate research artifacts stored in `research/.logs/` — they are NOT first-class data model entities. After the scan, offerings are mapped to features and products.

## Offering Fields (Research Phase)

| Field | Description | Example Values |
|-------|-------------|----------------|
| Name | Service/product name as marketed | "Managed SD-WAN Pro" |
| Description | 1-2 sentence summary | "End-to-end SD-WAN with 24/7 NOC support" |
| Domain | Source domain where offering was found | "t-systems.com" |
| Link | Direct URL to source page | `[Link](https://t-systems.com/sd-wan)` |
| USP | Unique selling proposition / differentiators | "Only provider with native 5G failover" |
| Provider Unit | Business unit offering this service | "T-Systems", "MMS" |
| Pricing Model | How the service is priced | subscription, usage-based, project-based |
| Delivery Model | Where service is delivered from | Onshore, nearshore, offshore, hybrid |
| Technology Partners | Key partnerships and certifications | "AWS Advanced Partner", "Microsoft Gold" |
| Industry Verticals | Target industries | Healthcare, Automotive, Public Sector |
| Service Horizon | Market maturity classification | Current, Emerging, Future |

## Service Horizons

| Horizon | Timeframe | Characteristics |
|---------|-----------|-----------------|
| Current | 0-1 years | Generally available, proven deployments |
| Emerging | 1-3 years | Pilot/beta, limited availability |
| Future | 3+ years | Announced, conceptual, R&D phase |

## Offering → Feature Field Mapping

When importing offerings as portfolio features (Phase 7), map fields as follows:

| Offering Field | Feature Field | Notes |
|---|---|---|
| Name | `name` + `slug` (kebab-case) | Slug derived from name |
| Description | `description` | Direct mapping |
| Category ID | `taxonomy_mapping.category_id` | From taxonomy classification |
| Dimension | `taxonomy_mapping.dimension` | First digit of category ID |
| Dimension Name | `taxonomy_mapping.dimension_name` | From taxonomy |
| Category Name | `taxonomy_mapping.category_name` | From taxonomy |
| Service Horizon | `taxonomy_mapping.horizon` + `readiness` | `current`→`ga`, `emerging`→`beta`, `future`→`planned` |
| Link | Referenced in `source_file` | Source URL preserved in research report |
| Domain | — | Research artifact, not persisted in feature |
| USP | — | Captured downstream in `proposition.is_statement` |
| Provider Unit | — | Captured in `portfolio.json` company context |
| Pricing Model | — | Informs `product.revenue_model` (inferred) |
| Delivery Model | — | Research artifact, not persisted in feature |
| Technology Partners | — | Captured in provider profile (Dimension 0.6) |
| Industry Verticals | — | Captured in market definitions downstream |

## Null-Safe Field Access

When processing offerings from log files, use null-safe access for optional fields (`partners`, `verticals`, `usp`, `pricing_model`, `delivery_model`):

```python
# CORRECT: Use 'or' to handle both missing AND null values
partners = (offer.get('partners') or '').replace('|', '\\|')[:60]
```

```bash
# Use // to provide default for null values
jq -r '.partners // ""'
```
