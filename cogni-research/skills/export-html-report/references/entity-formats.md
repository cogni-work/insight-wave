# Entity Formats Reference

Detailed frontmatter specifications and directory structure for deeper-research-3 output entities.

## Directory Structure

```text
research-project/
├── .metadata/
│   └── sprint-log.json          # Project metadata
├── research-hub.md           # Main synthesis (Phase 10)
├── README.md                    # Project navigation hub
│
├── 01-research-dimensions/
│   └── data/
│       └── dim-*.md             # Research dimension definitions
│
├── 02-refined-questions/
│   └── data/
│       └── question-*.md        # Refined research questions
│
├── 04-findings/
│   └── data/
│       └── finding-*.md         # Web research findings
│
├── 05-concepts/ (or 05-domain-concepts/)
│   └── data/
│       └── concept-*.md         # Domain concept definitions
│
├── 06-megatrends/
│   └── data/
│       └── megatrend-*.md           # Topic clusters
│
├── 07-sources/
│   └── data/
│       └── source-*.md          # Source metadata and credibility
│
├── 09-citations/
│   ├── README.md                # Evidence catalog (Phase 9)
│   └── data/
│       └── citation-*.md        # Individual citations
│
├── 10-claims/
│   └── data/
│       └── claim-*.md           # Verified claims
│
├── 11-trends/
│   └── data/
│       ├── trend-*.md           # Dimension-scoped trends
│       └── portfolio-*.md       # Portfolio trends (b2b-ict)
│
└── 12-synthesis/
    └── synthesis-*.md           # Dimension synthesis documents
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

### Concept (`concept-*.md`)

```yaml
---
dc:identifier: concept-predictive-maintenance
dc:title: Predictive Maintenance
entity_type: concept
definition: Using ML to predict equipment failures before they occur
related_concepts: [iot-sensors, condition-monitoring]
domain: manufacturing
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique concept ID |
| `dc:title` | Yes | string | Concept name |
| `entity_type` | Yes | string | Always `concept` |
| `definition` | No | string | Brief definition |
| `related_concepts` | No | list | Related concept IDs |
| `domain` | No | string | Domain category |

### Megatrend (`megatrend-*.md`)

Megatrends classify findings thematically. Structure depends on `megatrend_structure`:

- **tips**: TIPS strategic narrative (Trend-Implication-Possibility-Solution) for smarter-service research
- **generic**: Domain-based structure (What it is/What it does/What it means) for other research types

```yaml
---
tags: [entity/megatrend, megatrend, dimension/technology-trends]
dc:creator: knowledge-extractor
dc:title: Industry 4.0
dc:identifier: megatrend-industry-4-0-a1b2c3d4
dc:created: 2025-01-15T10:30:00Z
entity_type: megatrend
megatrend_name: Industry 4.0 Transformation
megatrend_structure: tips
finding_refs:
  - "[[04-findings/data/finding-ml-manufacturing-a1b2c3d4]]"
  - "[[04-findings/data/finding-automation-trends-b2c3d4e5]]"
finding_count: 2
source_type: hybrid
seed_validated: true
seed_name: Digital Transformation
evidence_strength: strong
confidence_score: 0.85
planning_horizon: act
dimension_affinity: technology-trends
strategic_narrative:
  trend: "Manufacturing sector rapidly adopting ML and IoT technologies..."
  implication: "Organizations without digital capabilities face competitive disadvantage..."
  possibility:
    overview: "Opportunity to lead digital transformation in industry..."
    chance: "Early movers capture 40% market share advantage..."
    risk: "Laggards face 25% cost disadvantage within 3 years..."
  solution: "Implement phased digital transformation roadmap..."
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique megatrend ID with 8-char hash (`megatrend-[slug]-[hash]`) |
| `dc:title` | Yes | string | Megatrend name (2-4 words) |
| `entity_type` | Yes | string | Always `megatrend` |
| `megatrend_name` | Yes | string | Full megatrend name |
| `megatrend_structure` | Yes | string | `tips` or `generic` |
| `finding_refs` | No | list | Wikilinks to findings |
| `finding_count` | No | int | Number of supporting findings |
| `source_type` | No | string | `clustered` (bottom-up), `seeded` (top-down), or `hybrid` |
| `seed_validated` | No | boolean | Whether seed was validated by findings |
| `evidence_strength` | No | string | `strong`, `moderate`, `weak`, or `hypothesis` |
| `confidence_score` | No | float | Composite score (0.0-1.0) |
| `planning_horizon` | No | string | `act` (0-6mo), `plan` (6-18mo), `observe` (18+mo) |
| `dimension_affinity` | No | string | Primary dimension slug |
| `strategic_narrative` | No | object | TIPS narrative (trend, implication, possibility, solution) |

**Body Content (TIPS Structure):**

```markdown
# {megatrend_name}

## Trend
{Observable pattern summary - what is happening (evidence-based)}

## Implication
{What this means for the industry/organization}

## Possibility
{What could be done - opportunity framing}

### Chance
{Value gained by acting}

### Risk
{Cost of not acting}

## Solution
{Recommended action - concrete next steps}

## Evidence
{Supporting findings and claims with citations}
```

**Body Content (Generic Structure):**

```markdown
# {megatrend_name}

## What it is
{Definition and scope of the megatrend}

## What it does
{Key mechanisms and effects}

## What it means
{Strategic implications}
```

### Source (`source-*.md`)

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

### Citation (`citation-*.md`)

```yaml
---
dc:identifier: citation-001
source_ref: "[[07-sources/data/source-harvard]]"
quote: "ML models achieve 92% accuracy in predicting failures"
page: 156
context: Results section discussing predictive maintenance
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique citation ID |
| `source_ref` | Yes | string | Wikilink to source |
| `quote` | Yes | string | Quoted text |
| `page` | No | int/string | Page reference |
| `context` | No | string | Citation context |

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
source_refs: ["[[07-sources/data/source-harvard]]"]
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

### Trend (`trend-*.md` or `portfolio-*.md`)

```yaml
---
dc:identifier: trend-ext-001
dc:title: AI Regulation Accelerating
entity_type: trend
dimension: external-effects
planning_horizon: act
confidence: high
claim_refs: [claim-001, claim-002]
finding_refs: [finding-001, finding-003]
word_count: 850
citation_count: 12
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `dc:identifier` | Yes | string | Unique trend ID |
| `dc:title` | Yes | string | Trend title |
| `entity_type` | Yes | string | Always `trend` |
| `dimension` | Yes | string | Parent dimension slug |
| `planning_horizon` | Yes | string | act/plan/observe |
| `confidence` | No | string | high/medium/low |
| `claim_refs` | No | list | Supporting claim IDs |
| `finding_refs` | No | list | Supporting finding IDs |
| `word_count` | No | int | Content word count |
| `citation_count` | No | int | Number of citations |

### Synthesis (`synthesis-*.md`)

Dimension synthesis documents provide comprehensive deep-dive analysis per dimension. Located in `12-synthesis/` (or legacy `11-trends/` for older projects).

```yaml
---
title: "Dimension Synthesis: Technology Trends"
tags: [answer, synthesis-level/dimensions]
dimension: "technology-trends"
research_type: "generic"
synthesis_date: "2025-01-12T14:30:00Z"
word_count: 1100
citation_count: 15
trend_count: 5
cross_connections: 8
avg_confidence: 0.82
thematic_clusters: 3
evidence_freshness: "current"
---
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `title` | Yes | string | Display title |
| `tags` | No | list | Entity tags including `synthesis-level/dimensions` or `synthesis-level/executive` |
| `dimension` | Yes | string | Parent dimension slug |
| `research_type` | No | string | generic/smarter-service/lean-canvas/b2b-ict-portfolio |
| `synthesis_date` | Yes | string | ISO 8601 timestamp |
| `word_count` | No | int | Document word count |
| `citation_count` | No | int | Number of citations |
| `trend_count` | No | int | Number of trends synthesized |
| `cross_connections` | No | int | Cross-trend connection count |
| `avg_confidence` | No | float | Average trend confidence (0.0-1.0) |
| `thematic_clusters` | No | int | Thematic grouping count |
| `evidence_freshness` | No | string | current/recent/dated |

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

### Trend Body (TIPS Framework)

```markdown
# {title}

## Trend
{what is happening}

## Implications
{what it means}

## Possibilities
{what could be done}

## Solutions
{what should be done}

## Evidence
{supporting claims and findings with citations}
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
