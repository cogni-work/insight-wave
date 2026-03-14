# Finding Entity Output Format

This reference defines the finding entity structure for file-based findings.

## YAML Frontmatter

```yaml
---
dc:title: "Finding: {Semantic Title}"
dc:identifier: "finding-file-{slug}-{8-char-hash}"
dc:created: "{ISO 8601 timestamp}"
dc:type: "finding"
dc:creator: "findings-creator-file"
entity_type: "finding"
finding_text: "{1-2 sentence summary}"
question_ref: "[[02-refined-questions/data/{question-id}]]"  # if question provided
source_type: "local_file"
file_store: "{store-slug}"
source_document: "{document-filename.md}"
source_document_title: "{Document Title from frontmatter}"
source_url: "{website_url from config.yaml}"
content_language: "{en|de}"
quality_score: {0.00-1.00}
quality_status: "{PASS|FAIL}"
confidence_level: "{high|medium|low}"
finding_type: "qualitative"
quality_dimensions:
  topical_relevance: {0.00-1.00}
  content_completeness: {0.00-1.00}
  source_reliability: {from config, default 0.65}
  evidentiary_value: {0.00-1.00}
schema_version: "3.0"
tags:
  - finding
  - source/file
  - dimension/{dimension-slug}
---
```

## Markdown Body Structure

```markdown
# {Finding Title}

## Content

{Extracted and synthesized content from the source document. 150-400 words.
Include specific insights, data points, and contextual information.
All content must derive from the actual document text.}

## Key Trends

- {Trend 1: specific insight with concrete details}
- {Trend 2: actionable information or measurable aspect}
- {Trend 3: evidence-based claim from document}
{3-6 bullets total}

## Methodology & Data Points

Information extracted from local file document store.
**Source Document**: {document title}
**Store**: {store-slug}
**Extraction Timestamp**: {ISO 8601}

{If document contains methodology info, include it here.
Otherwise state: "Source document methodology not explicitly stated."}

## Relevance Assessment

**Composite Score**: {score} | **Threshold**: 0.50 | **Status**: {PASS|FAIL}

**Dimension Scores:**
- Topical Relevance (40%): {score} - {rationale}
- Content Completeness (30%): {score} - {rationale}
- Source Reliability (20%): {score} - Local file store (Tier 2.5)
- Evidentiary Value (10%): {score} - {rationale}

## Source

**Document**: {Document Title}
**File**: {source_document}
**Store**: {store-slug}
**Lookup**: {website_url from config}
```

## Quality Score Calculation

### Composite Formula

```
composite = (relevance * 0.40) + (completeness * 0.30) + (reliability * 0.20) + (evidentiary * 0.10)
```

### Source Reliability

Fixed based on store config (default 0.65 for curated local documents):
- 0.70+: Primary sources, academic papers
- 0.60-0.69: Curated knowledge bases, whitepapers
- 0.50-0.59: General articles, blog posts

### Confidence Level Mapping

| Composite Score | Confidence Level |
|-----------------|------------------|
| >= 0.75         | high             |
| >= 0.60         | medium           |
| < 0.60          | low              |

### Threshold

- `composite_score >= 0.50` -> PASS (create finding)
- `composite_score < 0.50` -> FAIL (log rejection, skip)

## Identifier Format

Pattern: `finding-file-{semantic-slug}-{8-char-hash}`

Example: `finding-file-digital-service-trends-a1b2c3d4`

- Slug: derived from finding title, max 40 chars
- Hash: random 8-character hex for uniqueness
