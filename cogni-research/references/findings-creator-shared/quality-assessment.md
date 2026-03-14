# Shared Quality Assessment Framework

4-dimension quality scoring used by all findings-creator variants. Threshold and dimension structure are identical; weights and source reliability differ by variant.

## Dimensions

| # | Dimension | Description |
|---|-----------|-------------|
| 1 | **Topical Relevance** | Question-response alignment (0.9+ direct, 0.7-0.89 high, 0.5-0.69 moderate, <0.5 weak) |
| 2 | **Content Completeness** | Substantiveness: word count, trends count, methodology presence, data specificity |
| 3 | **Source Reliability** | Credibility of data origin (variant-specific, see below) |
| 4 | **Evidentiary Value** | Research utility and citeability (0.9+ specific frameworks, 0.7-0.89 clear concepts, 0.5-0.69 general, <0.5 vague) |

## Weights by Variant

| Dimension | findings-creator (web) | findings-creator-llm | findings-creator-file |
|-----------|----------------------|---------------------|----------------------|
| Topical Relevance | 35% | 40% | 40% |
| Content Completeness | 25% | 30% | 30% |
| Source Reliability | 15% | 20% | 20% |
| Evidentiary Value | 10% | 10% | 10% |
| Source Freshness | 15% | - | - |

## Source Reliability Values

| Variant | Reliability | Rationale |
|---------|------------|-----------|
| Web | Dynamic per source | Assessed from publisher tier, domain authority, methodology disclosure |
| LLM | Fixed **0.50** | Tier 3 - conceptual synthesis from training corpus |
| File | From `config.yaml` | `source_reliability` field (typically 0.50-0.80) |

## Composite Calculation

```
composite = (relevance x weight_rel) + (completeness x weight_comp) + (reliability x weight_rel) + (evidentiary x weight_evid) [+ (freshness x 0.15) for web]
```

## Threshold

- `composite >= 0.50` -> **PASS** (create finding entity)
- `composite < 0.50` -> **FAIL** (log to `.rejected-findings.json`, skip entity creation)

## Confidence Mapping

| Composite Score | Confidence Level |
|----------------|-----------------|
| >= 0.75 | high |
| >= 0.60 | medium |
| < 0.60 | low |

## Variant-Specific Logic

### LLM: Entity Knowledge Gap Adjustment

When the question targets a specific entity but the LLM lacks entity-specific knowledge (`entity_knowledge_gap == true`):

- **Topical Relevance Cap:** Maximum 0.55 (general background cannot directly answer entity-specific question)
- **Auto-FAIL Trigger:** If Topical Relevance < 0.40, reject with `rejection_reason: "entity_knowledge_gap_insufficient_background"`
- **Rationale note:** "Entity-specific knowledge gap acknowledged - general background provided"

### File: Content-Source Coherence Validation

Before entity creation, verify content traces to source document:
- Finding title derives from document content
- All statistics appear in source document
- All quoted passages exist verbatim
- Coherence FAIL -> skip entity creation

### Web: Source Freshness

Additional 15% weight for temporal relevance (newer sources score higher for volatile topics).

## Relevance Assessment Section Template

All variants generate this section in the finding markdown body:

```markdown
## Relevance Assessment

**Composite Score**: {score} | **Threshold**: 0.50 | **Status**: {PASS|FAIL}

**Dimension Scores:**
- Topical Relevance ({weight}%): {score} - {rationale}
- Content Completeness ({weight}%): {score} - {rationale}
- Source Reliability ({weight}%): {score} - {rationale}
- Evidentiary Value ({weight}%): {score} - {rationale}

**Overall Rationale**: {2-3 sentences on research value}
```

See also: `references/templates/finding-template.md` for complete entity schema.
