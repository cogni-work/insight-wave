# Phase 3: Finalize Agreed Candidates

Auto-select all 60 candidates and write the structured JSON that dimension-planner consumes.

## Entry Check

- `trend-candidates.md` written in Phase 2
- 60 candidates available (from memory or by parsing the markdown file)

## Build agreed-trend-candidates.json

Write to `{PROJECT_PATH}/.metadata/agreed-trend-candidates.json`.

### JSON Structure

```json
{
  "metadata": {
    "industry_sector": "{INDUSTRY_SECTOR}",
    "agreed_at": "{ISO_TIMESTAMP}",
    "total_candidates": 60,
    "source_skill": "tips-selection",
    "project_path": "{PROJECT_PATH}",
    "web_research_status": "{success|partial|failed|disabled}",
    "web_sourced_count": 28,
    "training_sourced_count": 32,
    "search_timestamp": "{SEARCH_TIMESTAMP_OR_NULL}"
  },
  "candidates": [
    {
      "dimension": "externe-effekte",
      "horizon": "act",
      "sequence": 1,
      "trend_name": "EU AI Act Compliance",
      "keywords": ["ai-act", "regulation", "2026"],
      "rationale": "Immediate deadline pressure",
      "source": "web-signal",
      "source_url": "https://...",
      "freshness_date": "2026-01"
    }
  ]
}
```

### Source Field Values

| Source | Description |
|--------|-------------|
| `web-signal` | From Phase 0.5 web search results |
| `training` | From LLM training knowledge |
| `hybrid` | Web signal enriched with training context |

All 60 candidates go into the `candidates` array. Maintain dimension/horizon/sequence ordering.

## Update trend-candidates.md

Change the frontmatter status from `draft` to `agreed` and add `agreed_at` timestamp:

```yaml
status: agreed
agreed_at: {ISO_TIMESTAMP}
selected_count: 60
```

## Validation

After writing both files:
- Verify `agreed-trend-candidates.json` exists and contains 60 candidates
- Verify `trend-candidates.md` status is `agreed`

## Completion Message

Inform the user:

- 60 trend candidates finalized
- Files created: `.metadata/agreed-trend-candidates.json` and `02-refined-questions/data/trend-candidates.md`
- Summary: 5 per cell, 15 per dimension, 60 total
- Next step: run `dimension-planner` to continue research planning

## Integration

The `dimension-planner` skill checks for `.metadata/agreed-trend-candidates.json` in its Phase 2:
- Present and valid (60 candidates) → uses them directly
- Missing → halts with instruction to run `tips-selection` first
