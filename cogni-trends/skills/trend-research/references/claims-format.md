# Claims Format

Reference for extracting and formatting claims compatible with `cogni-claims:claims`.

---

## Individual Claim Schema

Each quantitative claim is extracted as a JSON object:

```json
{
  "id": "claim_{dimension_prefix}_{sequence}",
  "text": "The predictive maintenance market reached $6.9 billion in 2024",
  "value": "6900000000",
  "unit": "USD",
  "type": "currency",
  "context": "Market size for predictive maintenance in manufacturing sector",
  "qualifiers": ["global", "2024"],
  "citations": [
    {
      "url": "https://www.gartner.com/en/documents/...",
      "proximity_confidence": 0.9
    }
  ]
}
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique ID: `claim_{prefix}_{N}` where prefix is dimension abbreviation |
| `text` | Yes | The complete claim sentence as it appears in the report |
| `value` | Yes | Numeric value as string (no formatting, no currency symbols) |
| `unit` | Yes | Unit of measurement: `USD`, `EUR`, `%`, `count`, `years`, etc. |
| `type` | Yes | Claim type: `currency`, `percentage`, `count`, `timeframe`, `ratio` |
| `context` | No | Additional context about what the number represents |
| `qualifiers` | No | Array of qualifying terms: `["global", "2024", "forecast"]` |
| `citations` | Yes | Array of source citations (at least 1) |

### Dimension ID Prefixes

| Dimension | Prefix | Example |
|-----------|--------|---------|
| `externe-effekte` | `ee` | `claim_ee_1`, `claim_ee_2` |
| `digitale-wertetreiber` | `dw` | `claim_dw_1`, `claim_dw_2` |
| `neue-horizonte` | `nh` | `claim_nh_1`, `claim_nh_2` |
| `digitales-fundament` | `df` | `claim_df_1`, `claim_df_2` |

### Claim Types

| Type | Value Format | Unit Examples |
|------|-------------|---------------|
| `currency` | Raw number (no symbols) | `USD`, `EUR`, `GBP` |
| `percentage` | Decimal or integer | `%`, `CAGR`, `YoY` |
| `count` | Integer | `companies`, `users`, `patents`, `deployments` |
| `timeframe` | Year or duration | `years`, `months`, `by-year` |
| `ratio` | Multiplier or factor | `x`, `factor`, `improvement` |

---

## Per-Dimension Claims File

Each agent writes claims to `{PROJECT_PATH}/.logs/claims-{dimension}.json`:

```json
{
  "dimension": "externe-effekte",
  "tips_role": "T",
  "claims_count": 18,
  "claims": [
    { "id": "claim_ee_1", "text": "...", ... },
    { "id": "claim_ee_2", "text": "...", ... }
  ]
}
```

---

## Merged Claims File

The orchestrator merges all 4 dimension files into `{PROJECT_PATH}/tips-trend-report-claims.json`:

```json
{
  "status": "success",
  "file_path": "tips-trend-report.md",
  "language": "en",
  "total_claims": 72,
  "claims": [
    { "id": "claim_ee_1", ... },
    { "id": "claim_ee_2", ... },
    { "id": "claim_dw_1", ... },
    { "id": "claim_nh_1", ... },
    { "id": "claim_df_1", ... }
  ]
}
```

**Ordering:** Claims are grouped by dimension (ee → dw → nh → df), maintaining sequence within each dimension.

---

## Extraction Rules

When extracting claims from the generated report section:

1. **Only extract quantitative statements** — skip qualitative assessments
2. **One claim per distinct number** — "market grew from $5B to $7B" = 2 claims
3. **Include the full sentence** — not just the number
4. **Preserve the exact citation** — URL must match what's in the prose
5. **Set `proximity_confidence: 0.9`** — standard for inline markdown citations
6. **Skip trends with no quantitative data** — `[No quantitative data available]` = zero claims

---

## Compatibility with cogni-claims

The merged claims file is directly consumable by `cogni-claims:claims` via:

```
Skill("cogni-claims:claims", args="--file-path {report} --claims-file {claims} --verdict-mode --language {lang}")
```

The `--claims-file` flag tells the claims skill to use pre-extracted claims instead of running its own extraction phase.
