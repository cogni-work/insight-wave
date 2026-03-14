# Entity Schema Developer Guide

Complete reference for working with entity schemas in the deeper-research plugin.

## Wikilink Format Requirements

**CRITICAL:** All entity references MUST use this exact format to prevent validation failures.

### Required Format Pattern

```
[[NN-entity-type/data/entity-slug-hash]]
```

**Components:**
- `NN`: Two-digit directory number (00-11)
- `entity-type`: Type identifier (sources, claims, findings, etc.)
- `data`: Literal directory name
- `entity-slug-hash`: Entity filename without `.md` extension

### Valid Examples

```markdown
[[10-claims/data/claim-climate-action-f1e2d3c4]]
[[07-sources/data/source-pnas-8f2e1a9b]]
[[04-findings/data/finding-renewable-12345678]]
[[08-publishers/data/publisher-nature-abc12345]]
[[05-domain-concepts/data/concept-ai-ethics-9a8b7c6d]]
[[06-megatrends/data/megatrend-digital-transformation-1a2b3c4d]]
```

### FORBIDDEN Patterns

❌ `[[10-claims/data/claim-abc\]]` - trailing backslash (LLM JSON escaping artifact)
❌ `[[10-claims/data/claim-abc ]]` - trailing space (formatting artifact)
❌ `[[10-claims/data/claim-abc.md]]` - .md extension (path completion artifact)
❌ `[[claim-abc]]` - missing directory prefix (bare ID)
❌ `[[10-claims/claim-abc]]` - missing /data/ subdirectory
❌ `[[10-claims/data/claim-FAKEHASH]]` - fabricated hash not in entity-index.json

### Validation Process

Every wikilink is validated by `validate-wikilinks.sh` which checks:

1. **Entity file exists** at the referenced path
2. **Format matches schema**: `[[NN-type/data/slug-hash]]`
3. **No trailing characters**: backslashes, spaces, extensions
4. **Hash matches filename**: entity ID in index matches wikilink
5. **Entity type correct**: wikilink type matches actual entity type
6. **Directory structure**: proper NN-type/data/ prefix

### Common LLM Generation Errors

When LLMs generate wikilinks, they often create these artifacts:

| Error Type | Example | Cause | Prevention |
|------------|---------|-------|------------|
| Trailing backslash | `[[path\]]` | JSON escaping in LLM output | Read entity-index.json for exact IDs |
| Trailing space | `[[path ]]` | Markdown formatting | Validate format before entity write |
| Extension added | `[[path.md]]` | Path completion | Strip extensions in generation |
| Missing directory | `[[entity-id]]` | Bare ID usage | Require full path with prefix |
| Fabricated hash | `[[type/data/fake-123]]` | ID invention | Load entity-index.json first |

### Pre-Generation Validation

Before creating any entity with wikilinks:

```bash
# 1. Load entity index
jq -r '.entities[] | .id' .metadata/entity-index.json

# 2. Verify entity exists before referencing
if [ -f "${PROJECT_PATH}/07-sources/data/${source_id}.md" ]; then
  WIKILINK="[[07-sources/data/${source_id}]]"
else
  echo "ERROR: Entity not found: $source_id" >&2
  exit 1
fi

# 3. Validate format (no trailing characters)
if echo "$WIKILINK" | grep -qE '\\]]| ]]|\.md]]'; then
  echo "ERROR: Invalid wikilink format: $WIKILINK" >&2
  exit 1
fi
```

### Error Messages from Validation

If you encounter these errors from `validate-wikilinks.sh`:

**"Trailing backslash detected"**
- Cause: LLM added `\` before `]]` during JSON generation
- Fix: Remove all `\` characters before `]]` in wikilinks

**"Trailing space detected"**
- Cause: Formatting added space before `]]`
- Fix: Remove spaces before `]]` in wikilinks

**"Hash mismatch"**
- Cause: Entity filename changed but wikilink not updated
- Fix: Update wikilink to match current entity filename

**"Entity type confusion"**
- Cause: Wikilink references wrong entity type (e.g., source as claim)
- Fix: Verify entity type in entity-index.json and correct wikilink

## Quick Start

```bash
# 1. View available schemas
ls schemas/*.schema.json

# 2. Read schema for your entity type
cat schemas/source-entity.schema.json

# 3. Create entity with schema-compliant frontmatter
# (see templates below)

# 4. Validate entity
bash scripts/validate-entity-schema.sh \
  --entity-type source \
  --entity-file research/07-sources/data/source-example-a7f3b2c1.md \
  --schema-path schemas/source-entity.schema.json \
  --json
```

## Entity Types Reference

### 00 - Initial Question

**Schema**: [initial-question-entity.schema.json](../schemas/initial-question-entity.schema.json)
**Purpose**: Starting point for research, decomposed into dimensions
**Directory**: `research/00-initial-question/`

**Key Fields**:
- `question_text`: Full research question
- `research_topic`: Topic/domain
- `dimension_refs`: Links to dimensions derived from this question

**Example**:
```yaml
---
tags: [initial-question, en]
dc:creator: "research-initiator"
dc:title: "Initial Question: Market Analysis"
dc:identifier: "question-initial-a7f3b2c1"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "initial-question"
question_text: "What are the key factors driving market growth?"
research_topic: "Market Analysis"
language: "en"
---
```

### 01 - Dimension

**Schema**: [dimension-entity.schema.json](../schemas/dimension-entity.schema.json)
**Purpose**: High-level MECE decomposition of initial question
**Directory**: `research/01-research-dimensions/data/`

**Key Fields**:
- `dimension.number`: Dimension number (1-N)
- `dimension.slug`: URL-friendly identifier
- `dimension.title`: Human-readable title
- `initial_question_ref`: Link to initial question
- `question_count`: Number of refined questions
- `mece_validated`: MECE framework validation

**Example**:
```yaml
---
tags: [research-dimension, dimension-1, en]
dc:creator: "dimension-planner"
dc:title: "Dimension 1: Economic Factors"
dc:identifier: "dimension-economic-factors-b8a9c2d5"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "dimension"
dimension:
  number: 1
  slug: "economic-factors"
  title: "Economic Factors"
initial_question_ref: "[[00-initial-question/data/question-initial-a7f3b2c1]]"
question_count: 5
mece_validated: true
language: "en"
---
```

### 02 - Refined Question

**Schema**: [refined-question-entity.schema.json](../schemas/refined-question-entity.schema.json)
**Purpose**: Dimension-specific questions with PICOT structure
**Directory**: `research/02-refined-questions/data/`

**Key Fields**:
- `question.number`: Question number within dimension
- `question.text`: Question text
- `dimension_ref`: Parent dimension
- `query_batch_refs`: Search query collections
- `picot_structure`: PICOT framework elements
- `finer_scores`: FINER criteria assessment

**Example**:
```yaml
---
tags: [refined-question, dimension-1, question-1, en]
dc:creator: "dimension-planner"
dc:title: "Question 1.1: GDP Impact"
dc:identifier: "question-gdp-impact-c9d1e2f3"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "refined-question"
question:
  number: 1
  text: "How does GDP growth affect market expansion?"
dimension_ref: "[[01-research-dimensions/data/dimension-economic-factors-b8a9c2d5]]"
language: "en"
---
```

### 03 - Query Batch

**Schema**: [query-batch-entity.schema.json](../schemas/query-batch-entity.schema.json)
**Purpose**: Collection of search queries for refined questions
**Directory**: `research/03-query-batches/data/`

**Key Fields**:
- `queries`: Array of search query strings
- `question_ref`: Refined question this batch addresses
- `source_count`: Number of sources generated

**Example**:
```yaml
---
tags: [query-batch]
dc:creator: "query-generator"
dc:title: "Query Batch: GDP Impact Analysis"
dc:identifier: "query-batch-gdp-impact-d1e2f3a4"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "query-batch"
queries:
  - "GDP growth market expansion correlation"
  - "economic indicators market size"
question_ref: "[[02-refined-questions/data/question-gdp-impact-c9d1e2f3]]"
source_count: 15
---
```

### 04 - Finding

**Schema**: [finding-entity.schema.json](../schemas/finding-entity.schema.json)
**Purpose**: Synthesized trends from multiple sources
**Directory**: `research/04-findings/data/`

**Key Fields**:
- `finding_text`: Main finding content
- `source_refs`: Supporting sources
- `claim_refs`: Factual claims
- `megatrend_refs`: Classification megatrends
- `confidence_level`: High/medium/low

**Example**:
```yaml
---
tags: [finding, finding-type/quantitative]
dc:creator: "findings-synthesizer"
dc:title: "GDP Growth Correlation"
dc:identifier: "finding-gdp-growth-e2f3a4b5"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "finding"
finding_text: "GDP growth shows strong positive correlation with market expansion"
source_refs:
  - "[[07-sources/data/source-gdp-study-f3a4b5c6]]"
  - "[[07-sources/data/source-market-analysis-a4b5c6d7]]"
confidence_level: "high"
finding_type: "quantitative"
---
```

### 05-06 - Megatrend

**Schema**: [megatrend-entity.schema.json](../schemas/megatrend-entity.schema.json)
**Purpose**: Thematic categories for classifying findings
**Directory**: `research/06-megatrends/data/`

**Key Fields**:
- `megatrend_name`: Megatrend name
- `megatrend_structure`: **Required** - `tips` or `generic` (determines content structure)
- `finding_refs`: Findings under this megatrend
- `parent_megatrend_ref`: Parent megatrend (hierarchical)
- `submegatrend_refs`: Child megatrends

**Megatrend Structure Types**:

| Structure | Research Type | Content Format | Word Count |
|-----------|---------------|----------------|------------|
| `tips` | smarter-service | TIPS narrative (Trend/Implication/Possibility/Solution) | 600-900 |
| `generic` | All others | Domain-based (What it is/does/means) | 400-600 |

**Example (TIPS)**:
```yaml
---
tags: [megatrend]
dc:creator: "knowledge-extractor"
dc:title: "Megatrend: Economic Indicators"
dc:identifier: "megatrend-economic-indicators-b5c6d7e8"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "megatrend"
megatrend_name: "Economic Indicators"
megatrend_structure: "tips"
finding_refs:
  - "[[04-findings/data/finding-gdp-growth-e2f3a4b5]]"
---
```

**Example (Generic)**:
```yaml
---
tags: [megatrend]
dc:creator: "knowledge-extractor"
dc:title: "Megatrend: Digital Transformation"
dc:identifier: "megatrend-digital-transformation-a1b2c3d4"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "megatrend"
megatrend_name: "Digital Transformation"
megatrend_structure: "generic"
finding_refs:
  - "[[04-findings/data/finding-cloud-adoption-f5g6h7i8]]"
---
```

### 07 - Source

**Schema**: [source-entity.schema.json](../schemas/source-entity.schema.json)
**Purpose**: Research materials discovered during query execution
**Directory**: `research/07-sources/data/`

**Key Fields**:
- `url`: Source URL
- `domain`: Source domain
- `publisher_id`: Publisher link
- `batch_id`: Query batch link
- `reliability_tier`: Tier 1-4 classification
- `doi/pmid/isbn`: Academic identifiers

**Example**:
```yaml
---
tags: [source, source-type/academic, en]
dc:creator: "source-creator"
dc:title: "GDP Growth and Market Expansion Study"
dc:identifier: "source-gdp-study-f3a4b5c6"
dc:created: "2025-01-26T12:00:00Z"
dc:source: "https://example.com/gdp-study"
entity_type: "source"
url: "https://example.com/gdp-study"
domain: "example.com"
access_date: "2025-01-26"
publisher_id: "[[08-publishers/data/publisher-example-c6d7e8f9]]"
batch_id: "[[03-query-batches/data/query-batch-gdp-impact-d1e2f3a4]]"
reliability_tier: "tier-1"
doi: "10.1234/example.123"
---
```

### 08 - Publisher

**Schema**: [publisher-entity.schema.json](../schemas/publisher-entity.schema.json)
**Purpose**: Domains that publish research sources
**Directory**: `research/08-publishers/data/`

**Key Fields**:
- `domain`: Publisher domain
- `publisher_name`: Human-readable name
- `reliability_score`: 0.0-1.0 score
- `publisher_type`: Academic/news/government/etc.

**Example**:
```yaml
---
tags: [publisher, publisher-type/academic]
dc:creator: "publisher-generator"
dc:title: "Publisher: Academic Journal"
dc:identifier: "publisher-example-c6d7e8f9"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "publisher"
domain: "example.com"
publisher_name: "Example Academic Journal"
reliability_score: 0.9
publisher_type: "academic"
---
```

### 09 - Citation

**Schema**: [citation-entity.schema.json](../schemas/citation-entity.schema.json)
**Purpose**: Quoted excerpts from sources with attribution
**Directory**: `research/09-citations/data/`

**Key Fields**:
- `source_ref`: Source being cited
- `quote_text`: Exact quote
- `page_number`: Location in source

**Example**:
```yaml
---
tags: [citation]
dc:creator: "citation-generator"
dc:title: "Citation: GDP Growth Impact"
dc:identifier: "citation-gdp-growth-d7e8f9a1"
dc:created: "2025-01-26T12:00:00Z"
dc:source: "https://example.com/gdp-study"
entity_type: "citation"
source_ref: "[[07-sources/data/source-gdp-study-f3a4b5c6]]"
quote_text: "GDP growth demonstrates a statistically significant positive correlation with market expansion."
page_number: 42
---
```

### 09 - Claim

**Schema**: [claim-entity.schema.json](../schemas/claim-entity.schema.json)
**Purpose**: Factual assertions supported by citations
**Directory**: `research/09-claims/`

**Key Fields**:
- `claim_text`: Factual claim
- `citation_refs`: Supporting citations
- `verification_status`: Verified/partially-verified/unverified/contradicted
- `confidence_score`: 0.0-1.0 score

**Example**:
```yaml
---
tags: [claim]
dc:creator: "fact-checker"
dc:title: "Claim: GDP-Market Correlation"
dc:identifier: "claim-gdp-market-e8f9a1b2"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "claim"
claim_text: "GDP growth is positively correlated with market expansion"
citation_refs:
  - "[[09-citations/data/citation-gdp-growth-d7e8f9a1]]"
verification_status: "verified"
confidence_score: 0.92
---
```

## Common Patterns

### Universal Dublin Core Fields

All entities include these Dublin Core fields:

```yaml
tags: [entity-type, ...]           # Classification
dc:creator: "skill-name"            # Creator
dc:title: "Entity Title"            # Title
dc:identifier: "{type}-{slug}-{hash}"  # Unique ID
dc:created: "2025-01-26T12:00:00Z" # ISO 8601 timestamp
entity_type: "{type}"               # Type constant
```

### Wikilink References

Wikilinks follow the pattern `[[{directory}/{entity-id}]]`:

```yaml
# Single reference
dimension_ref: "[[01-research-dimensions/data/dimension-economic-factors-b8a9c2d5]]"

# Multiple references
source_refs:
  - "[[07-sources/data/source-gdp-study-f3a4b5c6]]"
  - "[[07-sources/data/source-market-analysis-a4b5c6d7]]"
```

### Entity Identifiers

All identifiers follow: `{entity-type}-{semantic-slug}-{8-char-hash}`

```yaml
dc:identifier: "source-gdp-growth-study-a7f3b2c1"
#              ^^^^^^ type  ^^^^^^^^^^^^^^ slug ^^^^^^^^ hash
```

## Validation

### Validate Single Entity

```bash
bash scripts/validate-entity-schema.sh \
  --entity-type source \
  --entity-file research/07-sources/data/source-example-a7f3b2c1.md \
  --schema-path schemas/source-entity.schema.json \
  --json
```

### Validate All Entities of Type

```bash
for entity in research/07-sources/data/*.md; do
  bash scripts/validate-entity-schema.sh \
    --entity-type source \
    --entity-file "${entity}" \
    --schema-path schemas/source-entity.schema.json \
    --json
done
```

## Schema Extension

### Adding Optional Fields

Schemas allow `additionalProperties: true`, enabling extensions:

```yaml
---
# Standard fields
dc:identifier: "source-example-a7f3b2c1"
# ... other required fields ...

# Custom extension fields
custom_field: "custom value"
experimental_score: 0.85
---
```

### Creating New Entity Type

1. Create JSON schema: `schemas/new-type-entity.schema.json`
2. Follow template from existing schemas
3. Update [schemas/README.md](../schemas/README.md) with new type
4. Update [entity-relationships.uml](entity-relationships.uml) diagram
5. Test validation with sample entity

## Best Practices

### 1. Always Validate

Validate entities after creation to catch errors early:

```bash
# In entity creation scripts
validation_result=$(bash scripts/validate-entity-schema.sh ...)
if [ $? -ne 0 ]; then
  echo "Validation failed"
  exit 1
fi
```

### 2. Use Schema-Compliant IDs

Generate identifiers matching schema patterns:

```bash
# Correct
dc:identifier: "source-market-analysis-a7f3b2c1"  # ✅

# Incorrect
dc:identifier: "Source_Market_Analysis_123"  # ❌ (wrong pattern)
```

### 3. Reference Centralized Schemas

Always reference schemas from `/cogni-research/schemas/`:

```markdown
# ✅ Correct
READ: ../../schemas/source-entity.schema.json

# ❌ Incorrect
READ: local-copy-of-schema.json
```

### 4. Maintain Wikilink Format

Use exact wikilink format from schemas:

```yaml
# ✅ Correct
publisher_id: "[[08-publishers/data/publisher-example-c6d7e8f9]]"

# ❌ Incorrect
publisher_id: "publisher-example-c6d7e8f9"  # Missing wikilink syntax
```

## Troubleshooting

### Schema Validation Fails

1. Check entity file has YAML frontmatter between `---` markers
2. Verify all required fields present
3. Check field patterns match schema (especially identifiers)
4. Validate wikilink format
5. Review validation error details in JSON output

### Schema Not Found

1. Verify schema path: `ls schemas/{entity-type}-entity.schema.json`
2. Check `CLAUDE_PLUGIN_ROOT` environment variable
3. Use absolute paths for reliability

### Wikilink Pattern Mismatch

Ensure wikilinks match directory structure and entity type:

```yaml
# Pattern: [[{directory}/{entity-id}]]
"[[07-sources/data/source-example-a7f3b2c1]]"  # ✅
"[[sources/source-example-a7f3b2c1]]"     # ❌ Wrong directory
```

## Related Documentation

- [Schema README](../schemas/README.md) - Schema overview
- [Schema Conventions](../schemas/.schema-conventions.md) - Standards
- [Integration Guide](../schemas/INTEGRATION.md) - Integration patterns
- [Entity Relationships](entity-relationships.uml) - UML diagram

---

**Version**: 1.0.0
**Created**: 2025-11-26
**Status**: Production Ready
