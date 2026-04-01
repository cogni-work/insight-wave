# Pitch Data Model

## pitch-log.json

Master state file for a pitch project. Lives at `{project}/.metadata/pitch-log.json`.

### Customer Mode Example

```json
{
  "schema_version": "1.1",
  "pitch_mode": "customer",
  "slug": "siemens-manufacturing-pitch",
  "segment_name": null,
  "customer_name": "Siemens",
  "customer_domain": "siemens.com",
  "customer_industry": "Manufacturing",
  "market_slug": "enterprise-manufacturing-dach",
  "portfolio_path": "/abs/path/to/portfolio-project",
  "tips_path": "/abs/path/to/tips-project",
  "company_name": "Acme Cloud",
  "language": "de",
  "solution_focus": ["cloud-monitoring", "cloud-security"],
  "buying_center": {
    "economic_buyer": { "title": "CIO", "priorities": ["cost reduction", "risk mitigation"] },
    "technical_evaluator": { "title": "Cloud Architect", "priorities": ["integration", "security"] },
    "end_users": [{ "group": "DevOps Engineers", "priorities": ["ease of use", "automation"] }],
    "champion": { "title": "VP Engineering" }
  },
  "workflow_state": {
    "current_phase": "setup",
    "phases_completed": [],
    "claims_registered": 0
  },
  "created_at": "2026-03-17T10:00:00Z"
}
```

### Segment Mode Example

```json
{
  "schema_version": "1.1",
  "pitch_mode": "segment",
  "slug": "enterprise-manufacturing-dach-segment-pitch",
  "segment_name": "Enterprise Manufacturing DACH",
  "customer_name": null,
  "customer_domain": null,
  "customer_industry": "Manufacturing",
  "market_slug": "enterprise-manufacturing-dach",
  "portfolio_path": "/abs/path/to/portfolio-project",
  "tips_path": "/abs/path/to/tips-project",
  "company_name": "Acme Cloud",
  "language": "de",
  "solution_focus": [],
  "buying_center": {
    "economic_buyer": { "title": "CIO", "priorities": ["cost reduction", "risk mitigation"] },
    "technical_evaluator": { "title": "IT Director", "priorities": ["integration", "scalability"] },
    "end_users": [{ "group": "Operations Managers", "priorities": ["efficiency", "visibility"] }],
    "champion": null
  },
  "workflow_state": {
    "current_phase": "setup",
    "phases_completed": [],
    "claims_registered": 0
  },
  "created_at": "2026-03-17T10:00:00Z"
}
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `pitch_mode` | Yes | `"customer"` for named-customer pitches, `"segment"` for reusable segment pitches |
| `slug` | Yes | Kebab-case project identifier |
| `segment_name` | Segment mode | Market segment label (e.g., "Enterprise Manufacturing DACH") |
| `customer_name` | Customer mode | Named customer for this pitch |
| `customer_domain` | No | Website domain for web research (customer mode only) |
| `customer_industry` | Yes | Industry sector — matched to portfolio markets |
| `market_slug` | No | Matched portfolio market slug (set during setup) |
| `portfolio_path` | Yes | Absolute path to cogni-portfolio project |
| `tips_path` | No | Absolute path to cogni-trends project (null = portfolio-only mode) |
| `company_name` | Yes | Our company name (from portfolio.json) |
| `language` | Yes | `en` or `de` |
| `solution_focus` | No | Feature slugs to focus on (empty = full portfolio) |
| `buying_center` | No | Buyer role mapping — specific titles in customer mode, persona defaults in segment mode |

### Workflow State

| Phase | Name | State Value |
|-------|------|-------------|
| 0 | Setup | `setup` |
| 1 | Why Change | `why-change` |
| 2 | Why Now | `why-now` |
| 3 | Why You | `why-you` |
| 4 | Why Pay | `why-pay` |
| 5 | Synthesize | `synthesize` |

`current_phase` holds the active phase name. `phases_completed` is an array of completed phase names.

---

## theme-brief.json

Strategic theme intelligence derived by backwards reasoning from portfolio capabilities. Generated once during the first researcher agent invocation (why-change phase), reused by all subsequent phases. Lives at `{project}/.metadata/theme-brief.json`.

### Schema

```json
{
  "schema_version": "1.0",
  "generated_for": "why-change",
  "tips_available": true,
  "portfolio_strengths": [
    {
      "capability_cluster": "Cluster label",
      "supporting_features": ["feature-slug-1", "feature-slug-2"],
      "proposition_slugs": ["feature--market"],
      "is_summary": "What the capability is",
      "does_summary": "What it achieves for the buyer",
      "means_summary": "Why competitors cannot replicate it"
    }
  ],
  "ranked_themes": [
    {
      "theme_id": "theme-001",
      "theme_name": "Investment theme name",
      "source": "tips",
      "portfolio_alignment_score": 0.92,
      "alignment_reasoning": "Why this theme aligns with portfolio strengths",
      "why_change_angle": "Unconsidered need framing",
      "why_now_angle": "Urgency driver",
      "why_you_angle": "Differentiation angle",
      "why_pay_angle": "Cost dimension"
    }
  ],
  "portfolio_derived_themes": [
    {
      "theme_name": "Theme derived from portfolio backwards reasoning",
      "source": "portfolio",
      "capability_cluster": "Cluster label",
      "derivation_reasoning": "How this theme was derived from the portfolio",
      "why_change_angle": "Unconsidered need framing",
      "why_now_angle": "Urgency driver",
      "why_you_angle": "Differentiation angle",
      "why_pay_angle": "Cost dimension"
    }
  ],
  "focused_queries": {
    "why-change": ["targeted query 1", "targeted query 2"],
    "why-now": ["targeted query 1", "targeted query 2"],
    "why-you": ["targeted query 1", "targeted query 2"],
    "why-pay": ["targeted query 1", "targeted query 2"]
  },
  "open_exploration_queries": {
    "why-change": ["generic fallback query 1", "generic fallback query 2"],
    "why-now": ["generic fallback query 1", "generic fallback query 2"],
    "why-you": ["generic fallback query 1", "generic fallback query 2"],
    "why-pay": ["generic fallback query 1", "generic fallback query 2"]
  }
}
```

### Field Reference

| Field | Description |
|-------|-------------|
| `tips_available` | Whether TIPS data was loaded during generation |
| `portfolio_strengths[]` | Capability clusters derived from portfolio propositions |
| `ranked_themes[]` | TIPS investment themes ranked by portfolio alignment (empty if no TIPS) |
| `portfolio_derived_themes[]` | Themes derived purely from portfolio backwards reasoning |
| `focused_queries{}` | Per-phase targeted search queries (~70% of search budget) |
| `open_exploration_queries{}` | Per-phase generic queries for open discovery (~30% of search budget) |

When `tips_available` is false, `ranked_themes` is empty and all themes come from `portfolio_derived_themes`.

---

## Bridge Files (per phase)

Each content phase writes two files:

### research.json

Structured research output consumed by next phase and by the synthesizer.

```json
{
  "phase": "why-change",
  "pitch_mode": "customer",
  "target": "Siemens",
  "findings": [
    {
      "id": "wc-001",
      "type": "unconsidered_need",
      "headline": "Workflow integration gap in predictive maintenance",
      "detail": "...",
      "evidence": [
        {
          "claim": "60% of predictive maintenance deployments fail to deliver ROI",
          "source_url": "https://...",
          "source_title": "McKinsey Manufacturing Report 2025"
        }
      ],
      "buyer_relevance": ["ECONOMIC-BUYER", "TECH-EVAL"],
      "portfolio_refs": ["predictive-analytics--enterprise-manufacturing-dach"]
    }
  ],
  "portfolio_context": {
    "propositions_used": ["predictive-analytics--enterprise-manufacturing-dach"],
    "solutions_used": ["predictive-analytics--enterprise-manufacturing-dach"]
  },
  "tips_context": {
    "themes_referenced": ["theme-001"],
    "value_chains_referenced": ["vc-001"]
  }
}
```

In segment mode, `target` holds the segment name and findings use industry-level evidence rather than company-specific research.

### narrative.md

Prose output following the cogni-narrative Corporate Visions arc patterns. Written in the configured language. Buyer roles are NOT tagged in narrative.md — they live in research.json's `buyer_role_relevance` field and inform tone/framing, but never appear as inline brackets.

In customer mode, the narrative addresses the named customer directly. In segment mode, it uses "organizations in this segment" phrasing to remain reusable.

---

## Claims Registration

Claims with web URLs are registered for optional cogni-claims verification. Each claim entry:

```json
{
  "claim_id": "wc-001-e1",
  "phase": "why-change",
  "claim_text": "60% of predictive maintenance deployments fail to deliver ROI",
  "source_url": "https://...",
  "source_title": "McKinsey Manufacturing Report 2025",
  "submitted_by": "cogni-sales:why-change-researcher"
}
```

Claims are appended to `{project}/.metadata/claims.json` during each phase.
