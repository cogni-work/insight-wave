# ClaimEntity Schema Reference

## Overview

The ClaimEntity schema defines the data model for the cogni-claims cross-plugin contract. All plugins submitting or consuming claims MUST use these structures.

## Core Types

### ClaimRecord

```json
{
  "id": "claim-<uuid-v4>",
  "statement": "The global AI market is expected to reach $1.8 trillion by 2030.",
  "source_url": "https://example.com/ai-report",
  "source_title": "AI Market Forecast 2024-2030",
  "submitted_by": "cogni-trends",
  "submitted_at": "2026-02-23T14:30:00Z",
  "status": "unverified",
  "verified_at": null,
  "deviations": [],
  "resolution": null,
  "source_excerpt": null,
  "verification_notes": null,
  "entity_ref": null,
  "propagated_at": null
}
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | auto | Unique identifier, format: `claim-<uuid-v4>` |
| `statement` | string | yes | The claim text to verify |
| `source_url` | string | yes | URL of the cited source |
| `source_title` | string | yes | Human-readable title of the source |
| `submitted_by` | string | yes | Plugin name that submitted the claim (e.g., `cogni-trends`, `cogni-portfolio`, `user`) |
| `submitted_at` | string | auto | ISO 8601 timestamp of submission |
| `status` | enum | auto | One of: `unverified`, `verified`, `deviated`, `source_unavailable`, `resolved` |
| `verified_at` | string\|null | auto | ISO 8601 timestamp of last verification attempt |
| `deviations` | DeviationRecord[] | auto | Array of detected deviations (empty if verified clean) |
| `resolution` | ResolutionRecord\|null | auto | Resolution details if status is `resolved` |
| `source_excerpt` | string\|null | auto | Verbatim excerpt from source supporting or contradicting the claim |
| `verification_notes` | string\|null | auto | Free-text notes from the verification process (e.g., ambiguity explanations) |
| `entity_ref` | EntityRef\|null | no | Reference to the portfolio entity file and field that this claim describes. Set by the submitting agent so corrections can propagate back to the source entity. |
| `propagated_at` | string\|null | auto | ISO 8601 timestamp of when a resolved correction was applied back to the entity file. Null until propagation occurs. Prevents double-propagation. |

#### Status Transitions

```
unverified ──verify──> verified        (no deviations found)
unverified ──verify──> deviated        (deviations detected)
unverified ──verify──> source_unavailable (source unreachable)
deviated   ──resolve─> resolved        (user resolved all deviations)
source_unavailable ──reverify──> verified | deviated | source_unavailable
verified   ──reverify──> verified | deviated | source_unavailable
resolved   ──reverify──> verified | deviated | source_unavailable
```

### EntityRef

Optional provenance link from a claim back to the portfolio entity file and field it describes. When present, enables automatic propagation of corrections from resolved claims to their source entity files.

```json
{
  "type": "market",
  "file": "markets/mid-market-saas-dach.json",
  "field_path": "tam.description"
}
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | enum | yes | Entity type: `market`, `customer`, `competitor`, `proposition` |
| `file` | string | yes | Relative path from project root to the entity JSON file (e.g., `markets/mid-market-saas-dach.json`) |
| `field_path` | string | yes | Dot-notation path to the specific field. Supports array indices (`evidence[0].statement`) and name-based lookup (`named_customers[?name=="Siemens AG"].revenue.value`) for stable targeting when array order may change. |

#### Field Path Examples

| Entity Type | Example Field Paths |
|-------------|-------------------|
| market | `tam.value`, `tam.description`, `tam.source`, `sam.value`, `som.value` |
| customer | `named_customers[?name=="Siemens AG"].employees`, `named_customers[?name=="Siemens AG"].revenue.value` |
| competitor | `competitors[?name=="Datadog"].positioning`, `competitors[?name=="Datadog"].strengths[0]` |
| proposition | `evidence[0].statement`, `does_statement`, `means_statement` |

### DeviationRecord

```json
{
  "id": "dev-<uuid-v4>",
  "claim_id": "claim-<uuid-v4>",
  "type": "unsupported_conclusion",
  "severity": "high",
  "source_excerpt": "The report states AI market growth is projected between $800B and $1.5T by 2030.",
  "explanation": "The claim states $1.8 trillion, but the source projects a range of $800B to $1.5T. The claim exceeds the upper bound of the source's projection.",
  "detected_at": "2026-02-23T14:35:00Z"
}
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | auto | Unique identifier, format: `dev-<uuid-v4>` |
| `claim_id` | string | auto | Reference to parent ClaimRecord |
| `type` | enum | yes | One of: `misquotation`, `unsupported_conclusion`, `selective_omission`, `data_staleness`, `source_contradiction` |
| `severity` | enum | yes | One of: `low`, `medium`, `high`, `critical` |
| `source_excerpt` | string | yes | Verbatim text from source that evidences the deviation |
| `explanation` | string | yes | Plain-language explanation of what deviates and why |
| `detected_at` | string | auto | ISO 8601 timestamp |

#### Deviation Types

| Type | Description | Example |
|------|-------------|---------|
| `misquotation` | Claim misrepresents what the source says | Source says "up to 50%", claim says "exactly 50%" |
| `unsupported_conclusion` | Claim draws a conclusion the source does not support | Source presents data, claim adds causal interpretation |
| `selective_omission` | Claim omits context that changes meaning | Source says "growth in Q1, decline in Q2-Q4", claim says "growth observed" |
| `data_staleness` | Claim uses outdated data from the source | Source published 2019 data, claim presents it as current |
| `source_contradiction` | Source directly contradicts the claim | Source says "declined by 10%", claim says "increased by 10%" |

#### Severity Levels

| Severity | Criteria | User Action Required |
|----------|----------|---------------------|
| `low` | Minor imprecision, meaning preserved | Optional review |
| `medium` | Noticeable difference, could mislead | Review recommended |
| `high` | Significant misrepresentation | Resolution required |
| `critical` | Complete contradiction or fabrication | Immediate resolution required |

### ResolutionRecord

```json
{
  "id": "res-<uuid-v4>",
  "claim_id": "claim-<uuid-v4>",
  "action": "corrected",
  "original_statement": "The global AI market is expected to reach $1.8 trillion by 2030.",
  "corrected_statement": "The global AI market is projected between $800B and $1.5T by 2030.",
  "rationale": "Updated to match the source's stated range.",
  "resolved_by": "user",
  "resolved_at": "2026-02-23T15:00:00Z"
}
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | auto | Unique identifier, format: `res-<uuid-v4>` |
| `claim_id` | string | auto | Reference to parent ClaimRecord |
| `action` | enum | yes | One of: `corrected`, `disputed`, `alternative_source`, `discarded`, `accepted_override` |
| `original_statement` | string | auto | The original claim statement before resolution |
| `corrected_statement` | string\|null | conditional | New statement text (required when action is `corrected`) |
| `alternative_source_url` | string\|null | conditional | New source URL (required when action is `alternative_source`) |
| `alternative_source_title` | string\|null | conditional | New source title (when action is `alternative_source`) |
| `rationale` | string | yes | User's explanation for the resolution decision |
| `resolved_by` | string | auto | Always `user` (system never auto-resolves) |
| `resolved_at` | string | auto | ISO 8601 timestamp |

#### Resolution Actions

| Action | Description | Required Fields |
|--------|-------------|-----------------|
| `corrected` | Claim text updated to match source | `corrected_statement` |
| `disputed` | User disputes the deviation finding | `rationale` |
| `alternative_source` | User provides a different source | `alternative_source_url`, `alternative_source_title` |
| `discarded` | Claim removed from consideration | `rationale` |
| `accepted_override` | User acknowledges deviation but keeps claim as-is | `rationale` |

## Batch Submission Format

For submitting multiple claims at once:

```json
{
  "claims": [
    {
      "statement": "Claim text 1",
      "source_url": "https://example.com/source1",
      "source_title": "Source Title 1"
    },
    {
      "statement": "Claim text 2",
      "source_url": "https://example.com/source1",
      "source_title": "Source Title 1"
    }
  ],
  "submitted_by": "cogni-trends"
}
```

Note: Multiple claims may share the same `source_url`. The verification pipeline groups claims by URL to minimize fetches.

## Query Interfaces

### Query by Claim ID

```
Input:  claim_id (string)
Output: ClaimRecord (with embedded deviations and resolution)
```

### Query by Submitting Plugin

```
Input:  submitted_by (string), status_filter (optional enum[])
Output: ClaimRecord[] (sorted by submitted_at descending)
```

### Query by Status

```
Input:  status (enum), limit (optional int)
Output: ClaimRecord[] (sorted by severity descending for deviated claims)
```
