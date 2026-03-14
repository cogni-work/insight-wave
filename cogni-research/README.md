# cogni-research

General-purpose deep research engine with three-layer claim assurance and narrative-driven synthesis.

## Pipeline

```
research-plan → findings-sources → claims → synthesis
    (00-03)         (04-05)          (06)     (cogni-narrative)
```

| Skill | Purpose | Entities |
|-------|---------|----------|
| `research-plan` | Initial question → dimensions → refined questions → query batches | 00-03 |
| `findings-sources` | Parallel web + LLM research → enriched source extraction | 04-05 |
| `claims` | Claim extraction + three-layer verification | 06 |
| `synthesis` | Narrative storytelling via cogni-narrative | insight-summary.md |

## Research Types

- **generic** — flexible, DOK 1-4, dynamically generated dimensions
- **lean-canvas** — 9-block business model analysis, DOK-2
- **b2b-ict-portfolio** — 8-dimension B2B ICT provider analysis, DOK-3

## Entity Model (7 types)

| Dir | Type | Purpose |
|-----|------|---------|
| 00-initial-question | question | User's refined research question |
| 01-research-dimensions | dimension | 2-10 MECE research dimensions |
| 02-refined-questions | question | 8-50 atomic research questions |
| 03-query-batches | batch | Query sets for parallel web search |
| 04-findings | finding | Web + LLM research results |
| 05-sources | source | Enriched: URL/domain + publisher profile + APA citation |
| 06-claims | claim | Verified assertions with 3-layer confidence scoring |

## Three-Layer Claim Assurance

1. **Evidence confidence** — source quality, cross-validation, recency, expertise
2. **Claim quality** — atomicity, fluency, decontextualization, faithfulness
3. **Source verification** — URL fetch + deviation detection via cogni-claims

## Export

- `export-html-report` — interactive HTML with verification badges
- `export-pdf-report` — formal A4 PDF with verification badges
- `export-rag` — flat markdown for RAG / Claude Projects

## Quick Start

```
# 1. Plan your research
/research-plan

# 2. Gather findings and sources
/findings-sources

# 3. Extract and verify claims
/claims

# 4. Synthesize narratives
/synthesis

# 5. Export (optional)
/export-html-report
```

## Requirements

- bash, jq, python3 (stdlib only)
- cogni-narrative plugin (for synthesis)
- cogni-claims plugin (optional, for source URL verification)

## License

AGPL-3.0-only
