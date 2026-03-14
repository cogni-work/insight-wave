# Query Batch Entity Schema Contract

## Purpose

Authoritative schema definition for query batch entities in the deeper-research pipeline. This contract ensures consistency across:
- Research-query-optimizer skill (initial creation)
- Research-executor skill (execution enrichment)
- Validation tools (compliance checking)

## Schema Version

**Version**: 3.0.0
**Created**: 2025-11-17
**Last Updated**: 2026-01-13

**Changelog**:

- v3.0.0 (2026-01-13): BREAKING - Aligned with batch-creator Phase 3 schema. Removed `batch_number`, `dimension`, `query_count`, `priority`, `created_at`, and old Dublin Core fields. Added `search_configs[]`, `config_count`, `queries_count`, `question_ref`. File naming changed from `{question-id}-b.md` to `{question-id}-batch.md`.
- v1.2.0 (2025-11-22): Added queries[] YAML array structure for query-to-refined-question mapping (Sprint 334)
- v1.1.0 (2025-11-18): Added optimization metadata (variant types, scores, language detection)
- v1.0.0 (2025-11-17): Initial schema definition

---

## Authoritative YAML Frontmatter Template

```yaml
---
# Obsidian Tags (REQUIRED - always first line after ---)
tags: [query-batch, research-batch, {language}]

# Dublin Core Metadata (REQUIRED)
dc:creator: "Claude (batch-creator)"
dc:title: "Query Batch: {batch_id}"
dc:identifier: "{batch_id}"
dc:created: "{ISO 8601 timestamp}"

# Entity Metadata (REQUIRED)
entity_type: query-batch
batch_id: "{question_id}-batch"
question_id: "{question_id}"
query_text: "{verbatim question}"
language: "{detected language code}"
config_count: {integer}
queries_count: {integer}
question_ref: "[[02-refined-questions/data/{question_id}]]"
schema_version: "3.0.0"

# Search Configurations (REQUIRED - minimum 4 configs)
search_configs:
  - config_id: "config-{uuid}"
    profile: "general"
    tier: 1
    websearch_params:
      query: "{optimized search query}"
      blocked_domains: ["pinterest.com"]
  - config_id: "config-{uuid}"
    profile: "localized"
    tier: 1
    websearch_params:
      query: "{localized search query}"
      allowed_domains: ["domain.de"]

# Query Metadata (v1.2.0 - OPTIONAL for backward compatibility)
queries:
  - query_id: "query-{uuid}"
    refined_question_id: "{refined-question-id}"
    query_text: "{query string}"
    type: "Academic"
    variant: "Primary"
  - query_id: "query-{uuid}"
    refined_question_id: "{refined-question-id}"
    query_text: "{query string}"
    type: "Industry"
    variant: "Synonym-enriched"

# Query Optimization Metadata (v1.1.0 - OPTIONAL for backward compatibility)
optimization_version: "1.0.0"
language_detected: "de"  # ISO 639-1 code
variant_distribution:
  primary: 4
  bilingual: 4
  synonym_enriched: 3
  decomposed: 7
avg_optimization_scores:
  primary: 85.3
  bilingual: 78.2
  synonym_enriched: 82.0
  decomposed: 76.5

# Execution Enrichment Fields (REQUIRED after execution)
executed_at: "{ISO 8601 timestamp}"
finding_ids:
  - "[[04-findings/data/finding-{semantic-slug}]]"
megatrend_ids:
  - "[[06-megatrends/data/megatrend-{semantic-slug}]]"
queries_executed: {integer}
queries_successful: {integer}
---
```

---

## Field Definitions

### Tags Section

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tags` | Array | ✅ REQUIRED | Obsidian taxonomy tags |

**Format**: `[question, dimension-type/{type}]`
- Always first line after opening `---`
- NO blank line between `---` and `tags:`
- `{type}` matches research type (e.g., `lean-canvas`, `academic`, `technical`)

### Dublin Core Metadata (v3.0.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dc:creator` | String | ✅ REQUIRED | Literal `"Claude (batch-creator)"` |
| `dc:title` | String | ✅ REQUIRED | `"Query Batch: {batch_id}"` |
| `dc:identifier` | String | ✅ REQUIRED | `"{batch_id}"` (e.g., `question-market-size-a1b2c3d4-batch`) |
| `dc:created` | String | ✅ REQUIRED | ISO 8601 timestamp of creation |

**Note**: Fields `dc:date`, `dc:type`, `dc:subject`, `dc:relation` were removed in v3.0.0.

### Entity Metadata (v3.0.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `entity_type` | String | ✅ REQUIRED | Literal `"query-batch"` |
| `batch_id` | String | ✅ REQUIRED | Batch identifier (format: `{question_id}-batch`) |
| `question_id` | String | ✅ REQUIRED | Base question ID without `-batch` suffix (for README linkage) |
| `query_text` | String | ✅ REQUIRED | Verbatim question text |
| `language` | String | ✅ REQUIRED | ISO 639-1 language code (e.g., `en`, `de`) |
| `config_count` | Integer | ✅ REQUIRED | Number of search configurations (minimum 4) |
| `queries_count` | Integer | ✅ REQUIRED | Alias for config_count (required by generate-query-batches-readme.sh) |
| `question_ref` | Wikilink | ✅ REQUIRED | `"[[02-refined-questions/data/{question_id}]]"` |
| `schema_version` | String | ✅ REQUIRED | Schema version, must be `"3.0.0"` |

**NOTE**: `question_id` and `queries_count` are required by `generate-query-batches-readme.sh` for proper README generation. The `question_id` enables dimension resolution via question → dimension_ref lookup. The `queries_count` enables accurate statistics in the README.

### Search Configurations (v3.0.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `search_configs` | Array | ✅ REQUIRED | Array of search configuration objects (minimum 4) |

Each search config object contains:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `config_id` | String | ✅ REQUIRED | UUID-format identifier (`config-{8}-{4}-{4}-{4}-{12}`) |
| `profile` | String | ✅ REQUIRED | Search profile: `general`, `localized`, `industry`, `academic` |
| `tier` | Integer | ✅ REQUIRED | Execution tier (typically `1`) |
| `websearch_params` | Object | ✅ REQUIRED | WebSearch API parameters |

**websearch_params structure**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `query` | String | ✅ REQUIRED | Optimized search query string |
| `allowed_domains` | Array | ⚠️ OPTIONAL | Whitelist of domains (mutually exclusive with blocked_domains) |
| `blocked_domains` | Array | ⚠️ OPTIONAL | Blacklist of domains (mutually exclusive with allowed_domains) |

### Deprecated Fields (Removed in v3.0.0)

The following fields were removed in v3.0.0 and should NOT be used:

| Field | Replacement |
|-------|-------------|
| `batch_number` | Removed (no replacement needed) |
| `dimension` | Use `question_ref` to link to question, which has `dimension_ref` |
| `query_count` | Use `config_count` or `queries_count` |
| `priority` | Removed (no replacement needed) |
| `created_at` | Use `dc:created` |
| `dc:date` | Use `dc:created` |
| `dc:type` | Use `entity_type` |
| `dc:subject` | Removed (no replacement needed) |
| `dc:relation` | Removed (no replacement needed) |

### Query Metadata (v1.2.0 - NEW)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `queries` | Array | ⚠️ OPTIONAL* | Array of query objects with refined question mapping |

*Optional for backward compatibility with v1.0/v1.1 batches. Required when created by research-query-optimizer v1.1.0+ or manually for evidence chain integrity.

**Query Object Structure**:

Each object in the `queries[]` array contains:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `query_id` | String | ✅ REQUIRED | Unique query identifier (format: `query-{uuid}`) |
| `refined_question_id` | String | ✅ REQUIRED | ID of refined question that spawned this query |
| `query_text` | String | ✅ REQUIRED | The actual query string executed |
| `type` | Enum | ✅ REQUIRED | Query type: `Academic`, `Industry`, `News`, or `Technical` |
| `variant` | Enum | ⚠️ OPTIONAL | Optimization variant: `Primary`, `Bilingual`, `Synonym-enriched`, or `Decomposed` |

**YAML Format (Block List)**:

```yaml
queries:
  - query_id: "query-a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    refined_question_id: "competitive-advantage-q1"
    query_text: "top 5 competitors motorhome booking Germany market share"
    type: "Industry"
    variant: "Primary"
  - query_id: "query-f8e7d6c5-b4a3-2109-fedc-ba9876543210"
    refined_question_id: "competitive-advantage-q2"
    query_text: "unique value proposition Pincamp motorhome booking site:de"
    type: "Academic"
    variant: "Bilingual"
  - query_id: "query-z9y8x7w6-v5u4-3210-fedc-ba9876543210"
    refined_question_id: "competitive-advantage-q1"
    query_text: "motorhome booking platform market analysis Germany 2024"
    type: "News"
    variant: "Synonym-enriched"
```

**Rationale (Sprint 333 Context)**:

The `queries[]` array formalizes the query-to-refined-question mapping required for evidence chain integrity. Sprint 333 implemented `refined_question_id` propagation from batch to finding entities, enabling traceable provenance:

```
Dimension (01-research-dimensions/data/)
    ↓
Refined Question (02-refined-questions/data/) ← refined_question_id links here
    ↓
Query Batch (03-query-batches/data/)
    ↓ queries[] array (v1.2.0)
Query (query_id + refined_question_id)
    ↓ QUERY_MAPPING_FILE lookup
Finding (04-findings/data/)
```

**Phase 1 Step 1.3c Reference**:

Research-executor Phase 1 Step 1.3c extracts this array into `QUERY_MAPPING_FILE` for Phase 3 access during finding creation. This ensures each finding entity can populate `question_id` field with the correct refined question ID, completing the evidence chain.

**Defensive Fallback**:

If `queries[]` array is missing (legacy v1.0/v1.1 batches), Phase 1 Step 1.3c triggers defensive fallback, allowing execution to continue without evidence chain integrity. Findings created from legacy batches will have empty or inferred `question_id` fields.

### Optimization Metadata (v1.1.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `optimization_version` | String | ⚠️ OPTIONAL* | Version of optimization methodology used |
| `language_detected` | String | ⚠️ OPTIONAL* | ISO 639-1 language code detected from questions |
| `variant_distribution` | Object | ⚠️ OPTIONAL* | Count of each variant type in batch |
| `avg_optimization_scores` | Object | ⚠️ OPTIONAL* | Average optimization scores by variant type |

*Optional for backward compatibility. Required when created by research-query-optimizer v1.0.0+

**variant_distribution Keys**:
- `primary`: Always present (count of Primary variant queries)
- `bilingual`: Optional (count of Bilingual variant queries)
- `synonym_enriched`: Optional (count of Synonym-enriched variant queries)
- `decomposed`: Optional (count of Decomposed variant queries)

**avg_optimization_scores Keys**:
- Same keys as `variant_distribution`
- Values are floating-point scores (0-100 scale)

### Execution Enrichment Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `executed_at` | String | ✅ REQUIRED* | ISO 8601 timestamp of execution |
| `finding_ids` | Array | ✅ REQUIRED* | Wikilinks to findings (YAML block list) |
| `megatrend_ids` | Array | ✅ REQUIRED* | Wikilinks to megatrends (YAML block list) |
| `queries_executed` | Integer | ✅ REQUIRED* | Number of queries executed |
| `queries_successful` | Integer | ✅ REQUIRED* | Number of successful queries |

*Required after research-executor completes execution on this batch.

**Empty Array Handling**:
- If no findings created: `finding_ids: []`
- If no megatrends created: `megatrend_ids: []`
- NEVER omit these fields after execution

---

## YAML Formatting Rules

### CRITICAL: Block Lists Only

**CORRECT** (block list):
```yaml
dc:subject:
  - "lean-canvas"
  - "competitive-advantage"

dc:relation:
  - "competitive-advantage"
  - "competitive-advantage-q1"
  - "competitive-advantage-q2"

finding_ids:
  - "[[04-findings/data/finding-network-effects-marketplace]]"
  - "[[04-findings/data/finding-winner-takes-all-risks]]"

megatrend_ids:
  - "[[06-megatrends/data/megatrend-network-effects-dynamics]]"
```

**INCORRECT** (inline array):
```yaml
dc:subject: ["lean-canvas", "competitive-advantage"]

dc:relation: ["competitive-advantage", "competitive-advantage-q1"]

finding_ids: ["[[04-findings/data/finding-network-effects]]", "[[04-findings/data/finding-risks]]"]
```

**Rationale**:
- Block lists are more readable
- Easier to parse with grep/sed tools
- Consistent formatting across all entities
- Aligns with FAIR principles (machine-readable)

### Blank Line Handling

**NO blank line** between `---` and `tags:`:
```yaml
---
tags: [question, dimension-type/lean-canvas]
```

**ONE blank line** between major sections (optional, for readability):
```yaml
entity_type: "query-batch"

config_count: 4
```

### Wikilink Format

**question_ref format** (full path to refined question):
```yaml
question_ref: "[[02-refined-questions/data/question-competitive-advantage-a1b2c3d4]]"
```

**Workspace-relative paths** (for finding/megatrend backlinks):
```yaml
finding_ids:
  - "[[04-findings/data/finding-semantic-slug]]"
megatrend_ids:
  - "[[06-megatrends/data/megatrend-semantic-slug]]"
```

---

## Query Type Distribution

When generating queries for a batch, maintain this distribution:

**Standard 8-Query Batch (3 questions)**:
- Academic: 3 queries (one per question)
- Industry: 3 queries (one per question)
- News: 2 queries (from questions with news-worthy content)

**Validation Rule**:
```
IF query_count == 8:
  ASSERT Academic == 3
  ASSERT Industry == 3
  ASSERT News == 2
ELSE:
  LOG warning "Non-standard query count: {count}"
```

**Query Type Definitions**:
- **Academic**: Contains `site:edu` OR `site:arxiv.org` OR `site:researchgate.net`
- **Industry**: Contains practical qualifiers ("case study", "whitepaper", "best practices")
- **News**: Contains temporal qualifiers ("2024", "2025", "latest", "recent")
- **Technical**: Contains specification terms ("documentation", "specification", "standard")

---

## Query Content Sections (v1.1.0 Extension)

### Per-Query Variant Metadata

**v1.0 Format** (backward compatible):
```markdown
## Queries

1. **Query**: "top 5 competitors motorhome booking Germany market share"
   - **Type**: Industry
   - **Source Questions**: [[competitive-advantage-q1]]
   - **Keywords**: ["competitors", "market share", "Germany", "booking"]
```

**v1.1 Format** (extended):
```markdown
## Queries

1. **Query**: "top 5 competitors motorhome booking Germany market share Pincamp"
   - **Type**: Industry (v1.0 compatible)
   - **Variant**: Primary (v1.1 extension)
   - **Source Questions**: [[competitive-advantage-q1]]
   - **Optimization Score**: 85/100
   - **Synonym Count**: 12
   - **Keywords**: ["competitors", "market share", "Germany", "booking"]
   - **Language**: en

2. **Query**: "Top Stellplatz-Buchungsplattformen Deutschland Marktanteil site:de"
   - **Type**: Academic (v1.0 compatible - mapped from Bilingual)
   - **Variant**: Bilingual (v1.1 extension)
   - **Source Questions**: [[competitive-advantage-q1]]
   - **Optimization Score**: 78/100
   - **Language Mix**: de+en (60/40)
   - **Keywords**: ["Stellplatz", "Deutschland", "Marktanteil"]
```

**New v1.1 Fields** (per query):
- `Variant`: Primary | Bilingual | Synonym-enriched | Decomposed
- `Optimization Score`: Integer 0-100
- `Synonym Count`: Integer (number of synonyms used)
- `Language Mix`: String (for Bilingual variants, e.g., "de+en (60/40)")
- `Language`: ISO 639-1 code (for Primary/other variants)

---

## Auto-Generated Markdown Body (v1.2.0)

### Purpose and Format

Starting with v1.2.0, query batch entities MAY include an auto-generated markdown body section that mirrors the YAML `queries[]` array structure. This provides human-readable documentation while maintaining single source of truth in YAML frontmatter.

**AUTO-GENERATED Marker**:

When present, the markdown body MUST begin with this marker:

```markdown
---

<!-- AUTO-GENERATED from queries[] array - DO NOT EDIT MANUALLY -->

## Queries
```

**Format**:

```markdown
<!-- AUTO-GENERATED from queries[] array - DO NOT EDIT MANUALLY -->

## Queries

### Query 1: {query_text}

- **Query ID**: `query-{uuid}`
- **Type**: {type}
- **Variant**: {variant}
- **Refined Question**: [[02-refined-questions/data/{refined_question_id}]]

### Query 2: {query_text}

- **Query ID**: `query-{uuid}`
- **Type**: {type}
- **Variant**: {variant}
- **Refined Question**: [[02-refined-questions/data/{refined_question_id}]]
```

### Validation Rules

**v1.2.0 Batches**:
- If `queries[]` array present in YAML, markdown body is OPTIONAL
- If markdown body present, it MUST match `queries[]` array exactly
- Markdown body MUST begin with AUTO-GENERATED comment marker
- Any discrepancy between YAML and markdown triggers validation warning

**v1.0/v1.1 Batches**:
- No `queries[]` array in YAML
- Markdown body may contain manually-created query listings
- No AUTO-GENERATED marker required
- No validation enforcement

### Backward Compatibility

**Reading v1.2.0 Batches**:
- ALWAYS parse `queries[]` from YAML frontmatter (source of truth)
- IGNORE markdown body during programmatic processing
- Use markdown body only for human review/debugging

**Reading v1.0/v1.1 Batches**:
- `queries[]` array will be absent
- Fallback to markdown body parsing if needed (legacy mode)
- Apply defensive programming patterns

### Benefits

1. **Single Source of Truth**: YAML `queries[]` array is authoritative
2. **Human Readability**: Markdown provides formatted view for review
3. **Consistency**: Auto-generation prevents YAML/markdown drift
4. **Tooling Support**: Editors render markdown, scripts parse YAML
5. **Audit Trail**: AUTO-GENERATED marker clearly identifies programmatic content

---

## Backward Compatibility (v1.1.0)

### v1.0 Consumer Support

All v1.1 fields are optional. Existing validators and consumers can:
- Ignore unknown fields (optimization_version, language_detected, variant_distribution, avg_optimization_scores)
- Process batches using only v1.0 required fields
- Function without modification

### Type Field Mapping

For v1.0 compatibility, **Type** field maintained with variant mapping:
- Primary → Industry
- Bilingual → Academic
- Synonym-enriched → Industry
- Decomposed → Technical

This ensures search executors using v1.0 schema can still categorize queries.

### Migration Path

1. Deploy research-query-optimizer skill (creates v1.1 batches)
2. Existing search executors continue working (ignore v1.1 fields)
3. Update search executors to leverage optimization metadata (optional)
4. No breaking changes required

---

## Backward Compatibility (v1.2.0)

### v1.1 Consumer Support

The `queries[]` array is optional for backward compatibility:
- v1.0/v1.1 batches without `queries[]` array remain valid
- Existing research-executor can process legacy batches via defensive fallback
- Phase 1 Step 1.3c detects missing `queries[]` and continues execution
- Evidence chain integrity only available for v1.2.0+ batches

### Migration Path (v1.1 → v1.2.0)

**For New Batches**:
1. Research-query-optimizer v1.1.0+ can generate `queries[]` array during batch creation
2. Provides refined_question_id mapping for evidence chain integrity
3. Enables finding entities to populate question_id field correctly

**For Legacy Batches**:
1. No migration required - batches remain valid without `queries[]`
2. Research-executor applies defensive fallback during execution
3. Findings created from legacy batches have empty/inferred question_id
4. Optional: Manually add `queries[]` array to critical legacy batches

**No Breaking Changes**:
- All v1.2.0 extensions are optional
- Phase 1 Step 1.3c has defensive fallback for missing `queries[]`
- Existing workflows continue functioning
- Evidence chain integrity is opt-in enhancement

---

## Anti-Hallucination Compliance

### Checkpoint Integration

This schema contract integrates with anti-hallucination foundations:

1. **Complete Entity Loading** (Pattern 1): All fields must be present
2. **Verification Checkpoints** (Pattern 2): Validate schema before file write
3. **Evidence-Based Processing** (Pattern 3): All values from actual data
4. **No Fabrication Rule** (Pattern 4): Never use placeholder values
5. **Provenance Integrity** (Pattern 5): Wikilinks reference actual files

### Forbidden Patterns

**NEVER use**:
- Placeholder IDs: `[[question-001]]` (use actual filename)
- Generic slugs: `[[finding-1]]` (use semantic slug)
- Fabricated counts: Guess query_count (count actual queries)
- Missing fields: Omit required fields (use empty arrays if needed)

---

## Validation Checklist

Before writing a query batch file, validate:

**Creation Phase (v3.0.0 - batch-creator)**:

- [ ] `tags` is first line after `---`, includes `query-batch`, `research-batch`, language code
- [ ] `dc:creator`, `dc:title`, `dc:identifier`, `dc:created` present
- [ ] `entity_type` is `"query-batch"`
- [ ] `batch_id` follows `{question_id}-batch` format
- [ ] `question_id` is base ID without `-batch` suffix
- [ ] `query_text` contains verbatim question
- [ ] `language` is valid ISO 639-1 code
- [ ] `config_count` matches number of search_configs entries
- [ ] `queries_count` equals `config_count`
- [ ] `question_ref` is wikilink to refined question `[[02-refined-questions/data/{question_id}]]`
- [ ] `schema_version` is `"3.0.0"`
- [ ] `search_configs[]` has minimum 4 entries
- [ ] Each config has `config_id`, `profile`, `tier`, `websearch_params`
- [ ] `websearch_params` uses either `allowed_domains` OR `blocked_domains`, not both

**Creation Phase (v1.1.0 Extensions)**:
- [ ] `optimization_version` present if using research-query-optimizer
- [ ] `language_detected` is valid ISO 639-1 code
- [ ] `variant_distribution` keys match actual variants in queries
- [ ] `avg_optimization_scores` keys match variant_distribution keys
- [ ] Per-query `Variant` field matches one of 4 types
- [ ] Per-query `Optimization Score` is integer 0-100
- [ ] Per-query `Type` field maps correctly for v1.0 compatibility

**Creation Phase (v1.2.0 Extensions)**:
- [ ] `queries[]` array present if evidence chain integrity needed
- [ ] Each query object has query_id, refined_question_id, query_text, type
- [ ] `queries[]` uses YAML block list format (not inline array)
- [ ] refined_question_id values reference actual refined question entities
- [ ] If markdown body present, includes AUTO-GENERATED marker
- [ ] Markdown body matches `queries[]` array exactly (if both present)

**Enrichment Phase (Research Executor)**:
- [ ] `executed_at` is valid ISO 8601 timestamp
- [ ] `finding_ids` uses YAML block list format (empty array if none)
- [ ] `megatrend_ids` uses YAML block list format (empty array if none)
- [ ] All wikilinks in `finding_ids` reference actual files
- [ ] All wikilinks in `megatrend_ids` reference actual files
- [ ] `queries_executed` matches number attempted
- [ ] `queries_successful` <= `queries_executed`
- [ ] No redundant fields (no `findings_count` if `finding_ids` exists)

---

## Migration Guide

### Fixing Existing Files

For query batch files created before this contract:

1. **Inline arrays → Block lists**:
   ```bash
   # Identify inline arrays
   grep -n '\[.*".*".*,.*".*".*\]' file.md

   # Manual conversion required (no safe automated fix)
   ```

2. **Missing execution fields**:
   ```bash
   # Add missing fields after execution
   if ! grep -q "^executed_at:" file.md; then
     # Insert executed_at field
   fi
   ```

3. **Inconsistent field names**:
   ```bash
   # Replace queries_no_results with queries_failed
   sed -i '' 's/queries_no_results:/queries_failed:/' file.md
   ```

### Breaking Changes

**v1.0.0 → v1.1.0**: None - All v1.1 fields are optional extensions. Existing valid v1.0 files remain valid.

**v1.1.0 → v1.2.0**: None - `queries[]` array is optional extension. Existing valid v1.1 files remain valid. Evidence chain integrity available only for batches with `queries[]` array.

---

## Usage in Skills

### Research Query Optimizer Skill

```markdown
**Read:** `../../references/query-batch-schema-contract.md` for:
- Authoritative YAML frontmatter template (v1.2.0)
- Field definitions and required markers
- YAML block list formatting rules
- Query variant metadata requirements
- queries[] array structure for evidence chain
- Backward compatibility mapping
```

### Research Executor Skill

```markdown
**Read:** `../../references/query-batch-schema-contract.md` for:
- Execution enrichment field definitions
- YAML block list formatting requirements
- Empty array handling rules
- queries[] array parsing (Phase 1 Step 1.3c)
- Defensive fallback for legacy batches
- Validation checklist for enrichment phase
```

### Validation Script

```bash
# Reference schema contract for validation rules
readonly SCHEMA_CONTRACT="${CLAUDE_PLUGIN_ROOT}/references/query-batch-schema-contract.md"
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.2.0 | 2025-11-22 | Added queries[] YAML array structure for query-to-refined-question mapping (Sprint 334). Added auto-generated markdown body specification. All extensions backward compatible. |
| 1.1.0 | 2025-11-18 | Added optimization metadata (variant types, scores, language detection) for research-query-optimizer integration. All extensions backward compatible. |
| 1.0.0 | 2025-11-17 | Initial schema contract (Sprint 001) |

---

## References

- [Entity Structure Guide](entity-structure-guide.md) - General entity patterns
- [Anti-Hallucination Foundations](anti-hallucination-foundations.md) - Quality safeguards
- [Wikilink Architecture](wikilink-architecture.md) - Wikilink conventions
