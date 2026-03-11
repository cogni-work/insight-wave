# Phase 2: Present Candidates

Write all 60 candidates to `trend-candidates.md` for the user to review. This file serves as the human-readable record of what was generated.

## Entry Check

- 60 candidates generated and held in memory from Phase 1
- All candidates have trend_name, keywords, rationale, source, freshness
- INDUSTRY_SECTOR available

## Write trend-candidates.md

Write to `{PROJECT_PATH}/02-refined-questions/data/trend-candidates.md`.

Use the template from [../../templates/tips-candidates-template.md](../../templates/tips-candidates-template.md) and populate it with the generated candidates.

### File Structure

```yaml
---
status: draft
industry_sector: "{INDUSTRY_SECTOR}"
generated_at: {ISO_TIMESTAMP}
total_candidates: 60
web_research_status: "{success|partial|failed|disabled}"
web_sourced_candidates: {COUNT}
training_sourced_candidates: {COUNT}
search_timestamp: {TIMESTAMP_OR_NULL}
---
```

The body contains one section per dimension, each with 3 horizon tables (Act, Plan, Observe). Each table has 5 candidate rows with columns: #, Trend Name, Keywords, Rationale, Source, Fresh.

### Source Legend

| Code | Meaning |
|------|---------|
| `[Web]` | Derived from live web search (Phase 0.5) |
| `[LLM]` | Generated from training knowledge |
| `[Mix]` | Web signal enriched with training context |

## After Writing

Inform the user:
- The file has been created with 60 trend candidates
- They can review it at `02-refined-questions/data/trend-candidates.md`
- All 60 candidates will be auto-selected for the research project
- Proceed to Phase 3 (finalize) immediately unless the user wants to discuss changes

If the user wants to swap or modify specific candidates, handle that conversationally before proceeding to Phase 3.

## Next Phase

Proceed to [phase-3-finalize.md](phase-3-finalize.md) to write the agreed JSON.
