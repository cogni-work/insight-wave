# Portfolio Opportunities Schema

## Overview

The `portfolio-opportunities.json` file captures structured gap analysis from the TIPS-to-portfolio bridge. When Solution Templates have no matching portfolio feature (`match_confidence: "none"` or `"low"`), they represent market opportunities worth evaluating.

Written by `/bridge tips-to-portfolio` (Step 5.8) or `/bridge sync` into the TIPS project directory alongside `tips-value-model.json`.

## Schema

```json
{
  "schema_version": "1.0",
  "pursuit_slug": "automotive-ai-predictive-maintenance-abc12345",
  "portfolio_slug": "acme-portfolio",
  "generated_at": "2026-03-13T10:00:00Z",
  "opportunities": [
    {
      "opportunity_id": "opp-001",
      "st_id": "st-003",
      "st_name": "Regulatory Compliance Automation Suite",
      "st_description": "Automated audit trail generation and compliance reporting for EU AI Act requirements",
      "theme_ref": "theme-002",
      "match_confidence": "none",

      "opportunity_score": 8.2,
      "scoring_breakdown": {
        "ranking_value": 4.2,
        "ranking_weight": 0.4,
        "tam_alignment": 0.85,
        "tam_weight": 0.3,
        "competitive_whitespace": 0.90,
        "whitespace_weight": 0.3
      },

      "classification": "build",
      "classification_rationale": "Core to company IP in compliance domain. No turnkey vendor solution exists for this niche. Internal team has adjacent expertise in audit trail systems.",
      "classification_alternatives": ["partner"],

      "revenue_estimate": {
        "annual_value": 500000,
        "currency": "EUR",
        "basis": "5 enterprise customers x 100K ACV derived from mid-market-saas-dach TAM (500M) at 0.1% penetration",
        "confidence": "low"
      },

      "feature_spec": {
        "proposed_slug": "compliance-automation",
        "proposed_product_slug": "cloud-platform",
        "name": "Regulatory Compliance Automation Suite",
        "description": "Automated audit trail generation, real-time compliance monitoring, and regulatory reporting for EU AI Act and industry-specific requirements.",
        "category": "compliance",
        "readiness": "planned",
        "unmet_needs": ["Explainable AI audit trails", "Cross-border regulatory mapping", "Real-time compliance dashboards"],
        "taxonomy_refs": ["2.9", "6.6"],
        "source_themes": ["theme-002"],
        "source_sts": ["st-003"]
      },

      "priority": "high",
      "user_decision": null
    }
  ],
  "summary": {
    "total_opportunities": 3,
    "by_classification": { "build": 2, "buy": 0, "partner": 1 },
    "by_priority": { "high": 1, "medium": 1, "low": 1 },
    "total_estimated_revenue": 1200000,
    "currency": "EUR"
  }
}
```

## Field Reference

### Opportunity Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `opportunity_id` | string | yes | Sequential identifier (`opp-001`, `opp-002`, ...) |
| `st_id` | string | yes | Source Solution Template ID |
| `st_name` | string | yes | ST name for display |
| `st_description` | string | yes | ST description for context |
| `theme_ref` | string | yes | Parent Strategic Theme ID |
| `match_confidence` | string | yes | Portfolio match level (`"none"` or `"low"`) |
| `opportunity_score` | number | yes | Composite score 0-10 (see formula below) |
| `scoring_breakdown` | object | yes | Component scores and weights |
| `classification` | string | yes | `"build"` \| `"buy"` \| `"partner"` |
| `classification_rationale` | string | yes | Why this classification was chosen |
| `classification_alternatives` | array | no | Other viable classifications |
| `revenue_estimate` | object | yes | Revenue projection with basis and confidence |
| `feature_spec` | object | yes | Roadmap-ready feature definition |
| `priority` | string | yes | `"high"` \| `"medium"` \| `"low"` |
| `user_decision` | string or null | no | User's decision after review: `"accept"`, `"defer"`, `"reject"`, or null |

### Opportunity Score Formula

```
opportunity_score = (
    (ranking_value / 5) × ranking_weight +
    tam_alignment × tam_weight +
    competitive_whitespace × whitespace_weight
) × 10
```

Default weights: `ranking_weight = 0.4`, `tam_weight = 0.3`, `whitespace_weight = 0.3`

Component derivation:
- **ranking_value** (0-5): The source ST's `ranking_value` from the TIPS value model. Higher means the trend analysis rates this solution as more business-relevant.
- **tam_alignment** (0-1): How well the opportunity aligns with portfolio market TAM. Calculated as the fraction of portfolio markets with `market_relevance: "direct"` or `"industry"` for this TIPS pursuit. 1.0 = all markets relevant, 0.0 = no market overlap.
- **competitive_whitespace** (0-1): Estimated gap in competitor coverage for this capability. Derived from competitive analysis data if available (`competitors/{feature}--{market}.json`), otherwise defaults to 0.7 (moderate whitespace assumption).

### Classification Guidelines

- **build**: The company has adjacent expertise, the opportunity is core to IP strategy, and no adequate turnkey solution exists. Requires development investment.
- **buy**: A commercial solution exists that covers 80%+ of the need. Faster time-to-market through acquisition or licensing. Consider when the opportunity is not core to differentiation.
- **partner**: The opportunity is best addressed through ecosystem collaboration — co-development, white-label, or referral. Consider when specialized domain expertise is required that the company lacks.

### Revenue Estimate Confidence

- **high**: Based on validated market data (TAM from research reports) and comparable pricing from existing products
- **medium**: Based on market sizing but with assumptions about penetration or pricing
- **low**: Rough estimate based on limited market data or analogies

### Feature Spec

The `feature_spec` object contains a roadmap-ready feature definition. When the user approves an opportunity, the bridge can create a feature file directly from this spec.

- `unmet_needs` (array): Derived from the ST's blueprint building blocks with `coverage: "gap"` — each gap block's `gaps` array provides specific unmet capabilities. Falls back to `portfolio_anchor.theme_needs_undelivered` (portfolio-anchored STs) or ST description extraction (abstract STs)
- `taxonomy_refs` (array, optional): B2B ICT taxonomy category IDs from the ST's blueprint gap blocks (e.g., `["1.4", "7.2"]`). Shows which portfolio dimensions this opportunity spans. Absent for STs without blueprints.
- `source_themes` / `source_sts` (arrays): Traceability back to the TIPS value model
- `readiness`: Always `"planned"` for new opportunities

### Priority Derivation

- **high**: `opportunity_score >= 7.0` AND `ranking_value >= 4.0`
- **medium**: `opportunity_score >= 4.0` OR `ranking_value >= 3.0`
- **low**: Everything else

## Taxonomy Gap Summary (v1.1)

When Solution Templates have `solution_blueprint` data, the opportunities file includes a
`taxonomy_gaps` section that aggregates building block gaps across ALL STs (not just
unmatched ones). This provides portfolio-level investment priorities:

```json
{
  "taxonomy_gaps": [
    {
      "taxonomy_dimension": 7,
      "dimension_name": "Consulting Services",
      "categories": [
        {
          "taxonomy_ref": "7.2",
          "taxonomy_name": "Digital Transformation",
          "sts_needing": 5,
          "covered": 0,
          "partial": 1,
          "gap": 4,
          "priority": "high"
        }
      ],
      "total_blocks": 7,
      "total_gap_blocks": 5,
      "priority": "high"
    }
  ]
}
```

Priority for taxonomy gaps: `"high"` = ≥3 STs affected AND majority are gap (not partial),
`"medium"` = 2+ STs affected, `"low"` = 1 ST affected.

This section is absent when no STs have blueprints (backward compatible).

## Backward Compatibility

This file did not exist before this feature. No existing consumer needs updating. The bridge creates it alongside `tips-value-model.json` in the TIPS project directory.
