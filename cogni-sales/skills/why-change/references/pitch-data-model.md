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
| `tips_path` | No | Absolute path to cogni-tips project (null = portfolio-only mode) |
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
