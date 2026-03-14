# Entity Metadata Schema

## Overview

All research entities in the deeper-research plugin use standardized metadata following **Dublin Core** standards and **FAIR principles** (Findable, Accessible, Interoperable, Reusable).

## Dublin Core Metadata Fields

### Required Fields (All Entity Types)

```yaml
# Dublin Core Standard Fields
dc:creator: "{agent-name}"          # Agent that created this entity
dc:title: "{entity-title}"          # Human-readable title
dc:date: "{ISO8601-timestamp}"      # Creation timestamp
dc:identifier: "{entity-id}"        # Persistent unique identifier
dc:type: "{entity-type}"            # Entity type classification

# Legacy Compatibility (maintained for backward compatibility)
entity_type: "{entity-type}"        # Maps to dc:type
entity_id: "{entity-id}"            # Maps to dc:identifier
created_at: "{ISO8601-timestamp}"   # Maps to dc:date
```

### Optional Fields (Domain-Specific)

```yaml
dc:subject: ["{tag1}", "{tag2}"]    # Topic tags/keywords
dc:description: "{summary}"         # Brief entity description
dc:source: "{source-url}"           # Original source URL (for findings)
dc:relation: ["{related-id}"]       # Related entity IDs
dc:coverage: "{scope}"              # Temporal/spatial scope
dc:contributor: "{contributor}"     # Additional contributors
dc:rights: "{license}"              # Usage rights/license
dc:format: "text/markdown"          # File format
```

## Entity Type Mappings

### 1. Initial Question Entity

```yaml
---
# Dublin Core Fields
dc:creator: "deeper-research-skill"
dc:title: "Research Question: {brief question summary}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "question-{semantic-slug}-{hash}"
dc:type: "initial-question"
dc:subject: ["{domain}", "{methodology}"]
dc:coverage: "{temporal scope if specified}"

# Legacy Fields (maintained)
entity_type: "initial-question"
entity_id: "question-{semantic-slug}-{hash}"
created_at: "2025-10-23T15:30:00Z"
status: "refined"
---
```

**Filename Format**: `question-{semantic-slug}-{8-char-hash}.md`

**Examples**:
- `question-best-practices-fact-checking-llm-research-a3f5b294.md`
- `question-environmental-impacts-lithium-mining-south-america-9b4e6a3c.md`
- `question-kuka-innovations-collaborative-robotics-7c2d8e1f.md`

**dc:subject examples**: ["deeper-research-methods", "information-architecture"], ["AI", "fact-checking", "LLM"]

### 2. Research Dimension Entity

```yaml
---
# Dublin Core Fields
dc:creator: "dimension-planner"
dc:title: "Dimension: {dimension-name}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "dim-{dimension-name-kebab}"
dc:type: "research-dimension"
dc:subject: ["{dimension-type}", "{research-area}"]
dc:relation: ["question-{uuid}"]  # Parent question

# Legacy Fields
entity_type: "research-dimension"
dimension_type: "{operational|strategic|technical|etc}"
created_at: "2025-10-23T15:30:00Z"
---
```

### 3. Refined Question Entity

```yaml
---
# Dublin Core Fields
dc:creator: "Claude (dimension-planner)"
dc:title: "Question: {brief question text}"
dc:created: "2025-10-23T15:30:00.000Z"
dc:identifier: "question-{semantic-slug}-{8-char-hash}"
dc:type: "refined-question"
dc:subject: ["{dimension-type}", "{topic}"]

# Entity Fields
entity_type: "refined-question"
question:
  number: 1  # Question number within dimension (1-indexed)
  slug: "{semantic-slug}"
  title: "{question title}"
  text: "{full question text}"
dimension_ref: "[[01-research-dimensions/data/dimension-{slug}-{hash}]]"
language: "{en|de}"
---
```

**Filename Format**: `question-{semantic-slug}-{8-char-hash}.md`

### 4. Query Batch Entity

```yaml
---
# Dublin Core Fields
dc:creator: "Claude (batch-creator)"
dc:title: "Query Batch: {question_id}-batch"
dc:identifier: "{question_id}-batch"
dc:created: "2025-10-23T15:30:00.000Z"

# Entity Metadata (v3.0.0)
tags: [query-batch, research-batch, {language}]
entity_type: "query-batch"
batch_id: "{question_id}-batch"
question_id: "{question_id}"
query_text: "{verbatim question text}"
language: "{en|de}"
config_count: 4
queries_count: 4
question_ref: "[[02-refined-questions/data/{question_id}]]"
schema_version: "3.0.0"
search_configs:
  - config_id: "config-{uuid}"
    profile: "general"
    tier: 1
    websearch_params:
      query: "{optimized search query}"
      blocked_domains: ["pinterest.com"]
---
```

**Filename Format**: `{question_id}-batch.md`

**Examples**:
- `question-best-practices-fact-checking-a3f5b294-batch.md`
- `question-kuka-innovations-collaborative-7c2d8e1f-batch.md`

### 5. Finding Entity

```yaml
---
# Dublin Core Fields
dc:creator: "research-executor"
dc:title: "Finding: {brief finding title}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "finding-{semantic-uuid}"
dc:type: "finding"
dc:source: "{source-url}"
dc:subject: ["{megatrend-tags}"]
dc:relation: ["{refined-question-ids}", "source-{id}"]
dc:coverage: "{access-date}"

# Legacy Fields
entity_type: "finding"
source_url: "{url}"
source_id: "source-{uuid}"
access_date: "2025-10-23"
query_id: "{batch-id}-q{n}"  # Internal tracking only, no wikilink
created_at: "2025-10-23T15:30:00Z"
---
```

**Wikilink Strategy**: Findings link to refined questions they answer, NOT to query batches (which are execution details only).

### 6. Megatrend Entity

```yaml
---
# Dublin Core Fields
dc:creator: "research-executor"
dc:title: "Megatrend: {megatrend-name}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "megatrend-{megatrend-name-kebab}"
dc:type: "megatrend"
dc:subject: ["{domain}", "{theme}"]
dc:description: "{brief megatrend description}"

# Legacy Fields
entity_type: "megatrend"
megatrend_name: "{megatrend-name}"
created_at: "2025-10-23T15:30:00Z"
---
```

### 7. Source Entity

```yaml
---
# Dublin Core Fields
dc:creator: "source-creator"
dc:title: "{source-title}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "source-{semantic-uuid}"
dc:type: "source"
dc:source: "{url}"
dc:subject: ["{domain}", "{source-type}"]
dc:format: "{web|pdf|academic}"
dc:rights: "{license-if-known}"

# Legacy Fields
entity_type: "source"
entity_id: "source-{uuid}"
url: "{source-url}"
domain: "{domain}"
reliability_tier: {1-4}
source_type: "{academic|industry|news|technical}"
created_at: "2025-10-23T15:30:00Z"
---
```

### 8. Author Entity

```yaml
---
# Dublin Core Fields
dc:creator: "author-enricher"
dc:title: "Author: {author-name}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "author-{name-kebab}"
dc:type: "author"
dc:subject: ["{expertise-area}"]
dc:description: "{brief bio}"
dc:relation: ["source-{ids}"]

# Legacy Fields
entity_type: "author"
author_name: "{name}"
created_at: "2025-10-23T15:30:00Z"
---
```

### 9. Citation Entity

```yaml
---
# Dublin Core Fields
dc:creator: "citation-generator"
dc:title: "Citation: {citation-key}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "citation-{key}"
dc:type: "citation"
dc:source: "{url}"
dc:relation: ["source-{id}", "author-{ids}"]
dc:format: "application/x-bibtex"

# Legacy Fields
entity_type: "citation"
citation_key: "{key}"
created_at: "2025-10-23T15:30:00Z"
---
```

### 10. Claim Entity

```yaml
---
# Dublin Core Fields
dc:creator: "fact-checker"
dc:title: "Claim: {brief claim summary}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "claim-{semantic-id}"
dc:type: "claim"
dc:subject: ["{megatrend-tags}"]
dc:description: "{claim_text}"
dc:relation: ["finding-{ids}", "source-{ids}"]

# Legacy Fields
entity_type: "claim"
claim_text: "{claim}"
confidence_score: {0.0-1.0}
created_at: "2025-10-23T15:30:00Z"
# ... (other claim-specific fields)
---
```

### 11. Synthesis Entity

```yaml
---
# Dublin Core Fields
dc:creator: "synthesis-hub"
dc:title: "Synthesis: {synthesis-type}"
dc:date: "2025-10-23T15:30:00Z"
dc:identifier: "synthesis-{type}"
dc:type: "synthesis"
dc:subject: ["{research-question-topics}"]
dc:description: "{synthesis-level}: {brief description}"
dc:relation: ["question-{id}", "claim-{ids}"]

# Legacy Fields
entity_type: "synthesis"
synthesis_level: "{readme|executive|dimensions|findings|evidence}"
created_at: "2025-10-23T15:30:00Z"
---
```

## FAIR Principles Compliance

### Findable (F)
- **F1**: Globally unique identifiers (`dc:identifier` with semantic UUIDs)
- **F2**: Rich metadata describing entities (Dublin Core fields)
- **F3**: Metadata includes identifier of related entities (`dc:relation`)
- **F4**: Entities indexed in `.metadata/entity-index.json`

### Accessible (A)
- **A1**: Entities retrievable via file system paths (Obsidian wikilinks)
- **A2**: Metadata persists even if entity content unavailable (frontmatter)

### Interoperable (I)
- **I1**: Formal metadata vocabulary (Dublin Core standard)
- **I2**: Vocabularies follow FAIR principles (Dublin Core, YAML)
- **I3**: Qualified references via wikilinks and `dc:relation`

### Reusable (R)
- **R1**: Rich metadata with provenance (`dc:creator`, timestamps)
- **R2**: Clear usage context (`dc:description`, `dc:subject`)
- **R3**: Community standards (Dublin Core, ISO 8601, YAML)

## JSON-LD Export Format

Entities can be exported to JSON-LD for semantic web compatibility:

```json
{
  "@context": {
    "dc": "http://purl.org/dc/elements/1.1/",
    "dcterms": "http://purl.org/dc/terms/"
  },
  "@type": "dc:Text",
  "dc:creator": "deeper-research-skill",
  "dc:title": "Research Question: Deep Research Methods",
  "dcterms:created": "2025-10-23T15:30:00Z",
  "dc:identifier": "question-a7b3c4d5",
  "dc:type": "initial-question",
  "dc:subject": ["deeper-research-methods", "information-architecture"],
  "dc:format": "text/markdown"
}
```

## Backward Compatibility

All agents maintain **both** Dublin Core fields and legacy fields to ensure:
- Existing workflows continue functioning
- Gradual migration to standards-based metadata
- Interoperability with external systems via Dublin Core
- Tools can parse either format

## Migration Path

1. **Phase 1** (Current): Add Dublin Core fields alongside existing metadata
2. **Phase 2** (Future): Update internal tools to prefer Dublin Core fields
3. **Phase 3** (Future): Deprecate legacy fields (keep for compatibility)
4. **Phase 4** (Future): JSON-LD export becomes standard interchange format

## Validation

Entity metadata can be validated against this schema using:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-entity-metadata.sh" \
  --project-path "{project-path}"
```

## References

- Dublin Core Metadata Initiative: https://www.dublincore.org/
- FAIR Principles: https://www.go-fair.org/fair-principles/
- ISO 8601 Timestamps: https://en.wikipedia.org/wiki/ISO_8601
