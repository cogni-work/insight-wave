# portfolio-context.json — Schema Reference

The v3.2 schema for the `portfolio-context.json` file that `trends-bridge` writes
into the TIPS project directory. This file is the single source of truth for field
names, types, and enums — both the SKILL.md procedural steps (Steps 2, 2.5, 2.7,
2.8, 3) and downstream `cogni-trends` consumers read this spec.

## Source-of-truth discipline

`named_customer_references[]` mirrors data from the canonical `named_customers[]`
schema in `cogni-portfolio/references/data-model.md § customers/{market-slug}.json`.
If that upstream schema changes (field names, enum values, required/optional flags),
update **both** files in the same commit — drift between these two specs caused a
multi-commit churn during PR #120, where this bridge's field list drifted from the
canonical `name` / `pain_points` / enum `high|medium|low` spec and silently emptied
`named_customer_references[]` on every real portfolio until reviewers caught it.

Cross-file citations in this document use **section anchors** (e.g.,
`data-model.md § customers/{market-slug}.json`) rather than line numbers. Line
numbers rot on every edit; anchors survive.

## Worked example (v3.2)

```json
{
  "schema_version": "3.2",
  "source": "cogni-portfolio",
  "portfolio_slug": "{portfolio-slug}",
  "extracted_at": "{ISO-8601 timestamp}",
  "differentiators": [
    {
      "domain": "sovereign-infrastructure",
      "claim": "European sovereign cloud with BSI-C5 attestation and German-only data residency",
      "evidence": "BSI-C5 attestation certificate, data center locations",
      "swap_test_fails": true
    }
  ],
  "products": [
    {
      "slug": "cloud-platform",
      "name": "Cloud Platform",
      "revenue_model": "subscription",
      "maturity": "growth",
      "features": [
        {
          "slug": "cloud-monitoring",
          "name": "Cloud Infrastructure Monitoring",
          "description": "Real-time monitoring...",
          "category": "observability",
          "readiness": "ga",
          "propositions": [
            {
              "market_slug": "mid-market-saas-dach",
              "is_statement": "Cloud monitoring for SaaS operations teams",
              "does_statement": "Reduces MTTR by 60% through AI-correlated alerting",
              "means_statement": "Protects SaaS uptime SLAs in a market where churn from downtime costs 5-8% ARR",
              "evidence_count": 3,
              "variant_count": 2,
              "quality_assessment": {
                "overall": "pass",
                "does_score": {
                  "buyer_centricity": "pass",
                  "market_specificity": "pass",
                  "differentiation": "pass",
                  "status_quo_contrast": "warn",
                  "conciseness": "pass"
                },
                "means_score": {
                  "outcome_specificity": "pass",
                  "escalation": "pass",
                  "quantification": "pass",
                  "emotional_resonance": "warn",
                  "conciseness": "pass"
                },
                "assessed_at": "2026-03-12"
              },
              "solution_summary": {
                "solution_type": "project",
                "pricing_tiers": ["proof_of_value", "small", "medium", "large"],
                "price_range": { "min": 15000, "max": 250000, "currency": "EUR" }
              }
            }
          ]
        }
      ]
    }
  ],
  "markets": [
    {
      "slug": "mid-market-saas-dach",
      "name": "Mid-Market SaaS (DACH)",
      "region": "dach",
      "priority": "beachhead",
      "segmentation_summary": "SaaS companies, 50-500 employees",
      "vertical_codes": ["saas"],
      "tam_value": 5000000000,
      "currency": "EUR",
      "market_relevance": "direct",
      "match_reason": "vertical_codes includes 'saas' matching TIPS subsector"
    }
  ],
  "named_customer_references": [
    {
      "market_slug": "mid-market-saas-dach",
      "customer_name": "Acme SaaS GmbH",
      "domain": "acme-saas.example.com",
      "outcome_summary": "Reduced incident MTTR from 45 min to 12 min within 90 days of rollout",
      "fit_score": "high",
      "feature_slugs": []
    }
  ]
}
```

## Field contract

### Top-level

- `schema_version` (string, required): Always `"3.2"` for v3.2 exports.
- `source` (string, required): Always `"cogni-portfolio"`.
- `portfolio_slug` (string, required): Slug of the source portfolio project.
- `extracted_at` (string, required): ISO-8601 timestamp of export.

### `differentiators[]` (v3.1+, optional)

Provider-specific competitive advantages. 3–6 entries typical; empty array is valid.

- `domain` (string, required): One of `sovereign-infrastructure`, `network`, `security`,
  `scale`, `industry-expertise`, `platform`, `regulatory`.
- `claim` (string, required): One-sentence differentiator claim.
- `evidence` (string, required): What substantiates the claim (certification, metric,
  customer reference).
- `swap_test_fails` (boolean, required): `true` only when swapping the provider name
  for a competitor makes the claim false or implausible.

### `products[]`, `markets[]`, `products[].features[]`, `features[].propositions[]`

Structural content mirroring the portfolio project. `features[].propositions[]` carries
the compacted IS/DOES/MEANS plus the v3.0+ `variant_count`, `quality_assessment`, and
`solution_summary` fields.

### `named_customer_references[]` (v3.2, optional)

Structured customer references sourced from each market's
`customers/{market-slug}.json → named_customers[]`
(see `cogni-portfolio/references/data-model.md § customers/{market-slug}.json`).
Enables `cogni-trends` value-modeler Step 2.6 Example Enrichment (vendor mode) to
ground Solution Templates in concrete portfolio customers without re-reading the
portfolio project directly.

One reference per `named_customers[]` entry with a non-empty `name`:

- `market_slug` (string, required): Market this customer belongs to.
- `customer_name` (string, required): Copy of `named_customers[].name`.
- `domain` (string, optional): Copy of `named_customers[].domain` if present.
- `outcome_summary` (string, required): 1–2 sentences summarizing the engagement outcome.
  Derive from `named_customers[].pain_points` combined with `named_customers[].fit_rationale`
  when no explicit outcome text exists. **Must be portfolio-sourced — do not invent
  web-origin prose.**
- `fit_score` (string, optional): Copy of `named_customers[].fit_score` — canonical enum
  `high` | `medium` | `low` (per `data-model.md § customers/{market-slug}.json`). Never
  a float, never a percentage.
- `feature_slugs` (string array, optional): **v3.2 reserved; always `[]`.** No proposition
  or solution schema currently stores named-customer linkages, so there is no source to
  derive feature slugs from. Kept on the contract so future schemas that add
  `named_customer_refs[]` to propositions/solutions can populate it without a v3.3 bump.

## Schema version notes

Each version is a superset of the previous — new fields are additive. Consumers below
a version ignore the fields added at that version, preserving backward compatibility.

- **v3.2** adds `named_customer_references[]` — enables vendor-mode example enrichment
  in cogni-trends value-modeler Step 2.6.
- **v3.1** adds top-level `differentiators[]`. Pre-v3.2 consumers ignore
  `named_customer_references[]`.
- **v3.0** adds `variant_count` and `quality_assessment` per proposition.
- **v2.0** propositions without quality or variant data.
- **v1.0** (no `schema_version` field) no embedded propositions at all.

### Backward compatibility

The `schema_version` field is the contract boundary. `cogni-trends` value-modeler Phase 2
branches on this field:

- v3.2 enables vendor-reference surfacing.
- v3.1 enables differentiator surfacing.
- v3.0 enables quality-aware ST generation and variant tracking.
- v2.0 enables proposition-grounded ST generation.
- v1.0 (no field) falls back to basic feature matching.

## Related schemas

- `data-model.md § portfolio-context.json (Export to TIPS)` — the canonical data-model
  entry that references this document.
- `data-model.md § customers/{market-slug}.json` — the upstream source of the
  `named_customers[]` records that feed `named_customer_references[]`.
- `references/opportunity-schema.md` — the sibling `portfolio-opportunities.json`
  schema (written alongside `portfolio-context.json` when `tips-to-portfolio` runs).
