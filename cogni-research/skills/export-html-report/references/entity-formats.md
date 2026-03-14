# Entity Formats Reference

Detailed frontmatter specifications and directory structure for cogni-research output entities.

## Directory Structure

```text
research-project/
├── .metadata/
│   └── sprint-log.json          # Project metadata
├── research-hub.md              # Main synthesis
├── README.md                    # Project navigation hub
│
├── 00-initial-question/
│   └── data/
│       └── initial-question.md  # Original research question
│
├── 01-research-dimensions/
│   └── data/
│       └── dim-*.md             # Research dimension definitions
│
├── 02-refined-questions/
│   └── data/
│       └── question-*.md        # Refined research questions
│
├── 03-query-batches/
│   └── data/
│       └── batch-*.md           # Search query batches
│
├── 04-findings/
│   └── data/
│       └── finding-*.md         # Web research findings
│
├── 05-sources/
│   └── data/
│       └── source-*.md          # Source metadata, publisher info, and citations
│
└── 06-claims/
    └── data/
        └── claim-*.md           # Verified claims
```

## Frontmatter Specifications

### Dimension (`dim-*.md`)

```yaml
---
dc:identifier: dim-external-effects
dc:title: External Effects
slug: external-effects
description: Market forces, regulations, and ecosystem shifts
question_count: 8
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique dimension ID |
| `dc:title` | Yes | string | Human-readable title |
| `slug` | Yes | string | URL-safe identifier |
| `description` | No | string | Brief description |
| `question_count` | No | int | Number of refined questions |

### Question (`question-*.md`)

```yaml
---
dc:identifier: question-001
dc:title: How are AI regulations evolving?
dimension: external-effects
priority: high
dok_level: 4
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique question ID |
| `dc:title` | Yes | string | The research question |
| `dimension` | Yes | string | Parent dimension slug |
| `priority` | No | string | high/medium/low |
| `dok_level` | No | int | Depth of Knowledge (1-4) |

### Finding (`finding-*.md`)

```yaml
---
dc:identifier: finding-ml-manufacturing-001
dc:title: ML Applications in Manufacturing
entity_type: finding
source_url: https://example.com/paper.pdf
access_date: 2025-01-15
dimension: digital-foundation
tags: [finding, source-type/academic]
# v3.0 quality fields
content_source: webfetch
quality_score: 0.78
quality_status: PASS
quality_dimensions:
  topical_relevance: 0.85
  content_completeness: 0.75
  source_reliability: 0.70
  evidentiary_value: 0.80
schema_version: "3.0"
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique finding ID |
| `dc:title` | Yes | string | Finding title |
| `entity_type` | Yes | string | Always `finding` |
| `source_url` | Yes | string | Original source URL |
| `access_date` | Yes | string | YYYY-MM-DD format |
| `dimension` | No | string | Related dimension slug |
| `tags` | No | list | Classification tags |
| `content_source` | No | string | Data source: `webfetch` or `snippet` (v3.0) |
| `quality_score` | No | float | Composite quality score 0.0-1.0 (v3.0) |
| `quality_status` | No | string | Quality gate: `PASS` or `FAIL` (v3.0) |
| `quality_dimensions` | No | object | Detailed quality scores (v3.0) |
| `schema_version` | No | string | Schema version (e.g., "3.0") |

### Source (`source-*.md`)

Sources are enriched entities that combine source metadata, publisher information, and citations into a single file within `05-sources/`.

```yaml
---
dc:identifier: source-harvard-ml-paper
dc:title: Machine Learning in Manufacturing
entity_type: source
source_type: academic
url: https://scholar.harvard.edu/paper.pdf
domain: scholar.harvard.edu
access_date: 2025-01-15
authors: [Chen, L., Rodriguez, M.]
publication_date: 2025-09
journal: Journal of Manufacturing Systems
doi: 10.1234/example
reliability_tier: tier-1
credibility_score: 9
finding_refs: ["[[04-findings/data/finding-001]]"]
# Publisher fields (folded in from former 08-publishers)
publisher_name: Harvard University Press
publisher_type: academic
# Citation fields (folded in from former 09-citations)
apa_citation: "Chen, L., Rodriguez, M. (2025). Machine Learning in Manufacturing. Journal of Manufacturing Systems."
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique source ID |
| `dc:title` | Yes | string | Source title |
| `entity_type` | Yes | string | Always `source` |
| `source_type` | Yes | string | academic/industry/news/blog |
| `url` | Yes | string | Source URL |
| `domain` | No | string | URL domain |
| `access_date` | Yes | string | YYYY-MM-DD format |
| `authors` | No | list | Author names |
| `publication_date` | No | string | Publication date |
| `journal` | No | string | Journal/publication name |
| `doi` | No | string | DOI if available |
| `reliability_tier` | No | string | tier-1 to tier-4 |
| `credibility_score` | No | int | 1-10 score |
| `finding_refs` | No | list | Wikilinks to findings |
| `publisher_name` | No | string | Publisher name |
| `publisher_type` | No | string | Publisher category |
| `apa_citation` | No | string | Formatted APA citation |

### Claim (`claim-*.md`)

```yaml
---
dc:identifier: claim-ml-accuracy-92
dc:title: ML Predictive Accuracy Claim
entity_type: claim
claim_text: ML models achieve 92% accuracy in predicting equipment failures
confidence_score: 0.85
verification_status: verified
finding_refs: ["[[04-findings/data/finding-001]]", "[[04-findings/data/finding-002]]"]
source_refs: ["[[05-sources/data/source-harvard]]"]
dimension: digital-foundation
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique claim ID |
| `dc:title` | Yes | string | Claim title |
| `entity_type` | Yes | string | Always `claim` |
| `claim_text` | Yes | string | The claim statement |
| `confidence_score` | Yes | float | 0.0-1.0 confidence |
| `verification_status` | Yes | string | verified/partially-verified/unverified/contradicted |
| `finding_refs` | No | list | Supporting finding wikilinks |
| `source_refs` | No | list | Supporting source wikilinks |
| `dimension` | No | string | Related dimension |

## Wikilink Patterns

Wikilinks appear in these formats:

```markdown
<!-- Simple ID reference -->
[[finding-001]]

<!-- Full path reference -->
[[04-findings/data/finding-001]]

<!-- With custom display text -->
[[source-harvard|Harvard Study]]

<!-- In frontmatter (quoted) -->
finding_refs: ["[[04-findings/data/finding-001]]"]
```

## Body Content Structure

### Finding Body

**Note:** Section headers should use language template variables from `references/language-templates.md` based on project language.

```markdown
# Finding: {title}

## {HEADER_CONTENT}
{summary paragraph}

## {HEADER_KEY_TRENDS}
- {bullet point}
- {bullet point}

## {HEADER_METHODOLOGY}
{methodology description}

## {HEADER_RELEVANCE_ASSESSMENT}
{relevance to research}

## {HEADER_SOURCE}
{source information}
```

### Claim Body

```markdown
# Claim: {claim_text}

## Evidence Summary
{summary of supporting evidence}

## Supporting Findings
- [[finding-001]]: {brief context}
- [[finding-002]]: {brief context}

## Confidence Assessment
{rationale for confidence score}
```
