# Scan Entity Schema

Each discovered offering is captured with 12 fields during research. These are intermediate research artifacts stored in `research/.logs/` — they are NOT first-class data model entities. After the scan, offerings are mapped to features and products.

## Offering Fields (Research Phase)

| Field | Description | Example Values |
|-------|-------------|----------------|
| Category ID | Taxonomy category code from research assignment | "1.1", "3.4", "7.2" |
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
| — | `purpose` | Derived: 5-12 word customer-readable statement of what the feature is FOR (from web copy context) |
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

---

## Feature Candidates and Staging

Phase 7.3 does not write features directly. Instead it persists a candidate
list to a staging file that lives outside `features/` so neither the
dashboard nor `sync-portfolio.sh` sees it:

```
${PROJECT_PATH}/research/.staging/feature-candidates.json
```

Shape: a JSON array of feature-shaped objects. Every candidate carries two
markers on top of the normal feature schema:

| Field | Required | Purpose |
|---|---|---|
| `_candidate` | yes — always `true` | Lets the dedupe agent distinguish candidates from features loaded out of `features/*.json` when the pooled similarity matrix is built. |
| `_source_offering` | yes | Captures the original offering's `domain`, `link`, and `usp` so Phase 7.6 can write a rich `source_lineage` entry without re-reading `research/.logs/`. |

Example entry:

```json
{
  "_candidate": true,
  "slug": "aws-managed-services",
  "product_slug": "cloud-services",
  "name": "AWS Managed Services",
  "purpose": "Operate AWS workloads end-to-end for regulated enterprises",
  "description": "...",
  "taxonomy_mapping": { "dimension": 4, "category_id": "4.1", "category_name": "Managed Hyperscaler Services", "horizon": "current" },
  "readiness": "ga",
  "sort_order": 190,
  "_source_offering": {
    "domain": "t-systems.com",
    "link": "https://www.t-systems.com/.../aws-managed-services",
    "usp": "BSI C5-attested AWS operations with German data residency"
  }
}
```

**Lifecycle:**

1. Phase 7.3 — created. One file per scan run. `mkdir -p` the staging dir first.
2. Phase 7.4 — read-only by the dedupe agent (via `candidates_file` input).
3. Phase 7.6 — consumed; `_candidate` and `_source_offering` markers are stripped before any survivor is written to `features/{slug}.json`; the whole `research/.staging/` directory is `rm -rf`'d at the end of the phase.

If a scan is interrupted between 7.3 and 7.6, the staging file is the recovery evidence — it describes exactly what the scan was about to write and can be diffed against the final state to reconstruct what merged into what.
