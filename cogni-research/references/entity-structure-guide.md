# Entity Structure Guide

Universal entity patterns for the cogni-research plugin. Use when creating entities, implementing UUID generation, working with wikilinks, or debugging entity formats.

## Purpose

Provides 4 universal patterns:
1. **YAML Frontmatter** - Required fields, formatting
2. **UUID Generation** - Content-addressable identifiers
3. **Wikilink Conventions** - Bidirectional linking
4. **Entity Lifecycle** - Create, update, validate, delete

## Entity Types (v1.0.0)

| Prefix | Directory | Entity Type | Created By |
|--------|-----------|-------------|------------|
| `00` | `00-initial-question` | Initial Question | deeper-research-0 |
| `01` | `01-research-dimensions` | Dimension | dimension-planner |
| `02` | `02-refined-questions` | Refined Question | dimension-planner |
| `03` | `03-query-batches` | Query Batch | batch-creator |
| `04` | `04-findings` | Finding | findings-creator |
| `05` | `05-sources` | Source | source-creator |
| `06` | `06-claims` | Claim | claim-extractor |

## Section 1: YAML Frontmatter Patterns

### Universal Entity Structure

```markdown
---
# Obsidian Tags (REQUIRED)
tags: [entity-type, optional-subtypes, language]

# Dublin Core Metadata (REQUIRED)
dc:creator: "skill-name"
dc:title: "Entity: Title"
dc:created: "2025-01-26T12:00:00.000Z"
dc:identifier: "entity-type-slug-hash8"

# Entity Type (REQUIRED)
entity_type: "dimension|refined-question|finding|source|claim"

# Entity-Specific Metadata (varies by type)
---

# Markdown body with structured sections
```

### Required Fields

| Field | Type | Format | Example |
|-------|------|--------|---------|
| `dc:identifier` | string | `{type}-{slug}-{hash8}` | `dimension-economic-a7f3b2c1` |
| `entity_type` | string | Entity type | `"dimension"` or `"source"` |
| `tags` | array | `[{type}, ...]` | `[research-dimension, dimension-1, en]` |
| `dc:creator` | string | Skill/agent name | `"Claude (dimension-planner)"` |
| `dc:title` | string | Prefixed title | `"Dimension: Economic Analysis"` |
| `dc:created` | string | ISO8601 timestamp | `"2025-01-26T12:00:00.000Z"` |
| `language` | string | ISO 639-1 code | `"en"` |

### Entity-Specific Fields

| Entity Type | Unique Required Fields |
|-------------|------------------------|
| **Initial Question** | `question_text`, `research_type`, `dok_level` |
| **Dimension** | `dimension_name`, `dimension_number`, `research_question` |
| **Refined Question** | `question_text`, `dimension_id` |
| **Query Batch** | `question_id`, `queries` |
| **Finding** | `source_url`, `content`, `batch_id`, `dimension_id` |
| **Source** | `url`, `domain`, `title`, `access_date` |
| **Claim** | `finding_ids`, `claim_text`, `confidence_score` |

### Formatting Conventions

**String quoting** - Quote strings with: colons (`:`), special chars (`#@!`), leading/trailing spaces, multiline content

**Arrays** - Use inline: `tags: [source, source-type/academic]`

**Null values** - Explicit null for unpopulated optional fields: `reliability_tier: null` (not empty string or omitted)

**Multiline strings** - Use literal block style (`|`):
```yaml
description: |
  First line
  Second line
```

### Anti-Patterns

- Don't mix tabs/spaces, use field names in values, omit required fields
- Do use consistent indentation, quote special chars, include all required fields

## Section 2: UUID Generation

### Semantic UUID Pattern

Content-addressable UUIDs enable deduplication.

```bash
# Generate semantic slug from entity title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Generate 8-character hash
HASH=$(echo -n "$TITLE" | shasum -a 256 | cut -c1-8)

ENTITY_ID="${ENTITY_TYPE}-${SLUG}-${HASH}"
# Example: dimension-economic-analysis-a7f3b2c1
```

**Contract:** `generate-semantic-slug.sh`
- Location: `${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh`
- Interface: `--title <title> --content-key <content> [--max-length N] [--json]`
- Response: `{"success": true, "data": {"slug": "my-article-title", "hash": "a7f3b2c1", "semantic_uuid": "my-article-title-a7f3b2c1"}}`

### Deduplication Logic

1. Generate UUID from entity content
2. Check if entity with same ID exists
3. If exists: Return existing ID (deduplication)
4. If not: Create new entity

```bash
ENTITY_FILE="${PROJECT_PATH}/05-sources/data/${ENTITY_ID}.md"
if [ -f "$ENTITY_FILE" ]; then
  log_conditional INFO "Entity exists: $ENTITY_ID (reused)"
else
  # Create new entity
fi
```

### UUID Content Patterns by Entity Type

| Entity Type | Slug Source | Hash Source | Example ID |
|-------------|-------------|-------------|------------|
| **Initial Question** | Question text (kebab-case) | SHA256 of text | `question-initial-how-does-ai-f7ef12b8` |
| **Dimension** | Dimension title (kebab-case) | SHA256 of title | `dimension-economic-analysis-a7f3b2c1` |
| **Refined Question** | Question title (kebab-case) | SHA256 of title | `question-market-size-b2c3d4e5` |
| **Query Batch** | Dimension + question ref | SHA256 of content | `batch-dim1-q3-c4d5e6f7` |
| **Finding** | Finding title (kebab-case) | SHA256 of `dim_id\|query_id\|seq` | `finding-renewable-12345678` |
| **Source** | Source title (kebab-case) | SHA256 of `url\|title` | `source-pnas-study-d25bff0d` |
| **Claim** | Claim text (kebab-case) | SHA256 of claim text | `claim-climate-action-f1e2d3c4` |

### Anti-Patterns

- Don't generate UUIDs inline (non-standard), use random UUIDs (no deduplication), skip existence check
- Do use centralized utility with deduplication check

## Section 3: Wikilink Conventions

### Wikilink Format

```markdown
[[directory/entity-id]]
```

Always include directory prefix:

| Entity Type | Directory | Wikilink Example |
|-------------|-----------|------------------|
| Initial Question | `00-initial-question/data/` | `[[00-initial-question/data/question-initial-f7ef12b8]]` |
| Dimension | `01-research-dimensions/data/` | `[[01-research-dimensions/data/dimension-economic-a7f3b2c1]]` |
| Refined Question | `02-refined-questions/data/` | `[[02-refined-questions/data/question-market-size-b2c3d4e5]]` |
| Query Batch | `03-query-batches/data/` | `[[03-query-batches/data/batch-dim1-q3-c4d5e6f7]]` |
| Finding | `04-findings/data/` | `[[04-findings/data/finding-xyz-abc123]]` |
| Source | `05-sources/data/` | `[[05-sources/data/source-a7f3b2c1]]` |
| Claim | `06-claims/data/` | `[[06-claims/data/claim-d5e8f3b4]]` |

### Bidirectional Linking

**Forward links** (in frontmatter):
```yaml
source_id: "[[05-sources/data/source-a7f3b2c1]]"
```

**Backlinks** (created by child entities):
```yaml
finding_ids: ["[[04-findings/data/finding-xyz-001]]", "[[04-findings/data/finding-xyz-002]]"]
```

### Backlink Update Pattern

When creating entity relationships:

```bash
# 1. Create child entity
# 2. Update parent with backlink
PARENT_FILE="${PROJECT_PATH}/05-sources/data/${SOURCE_ID}.md"

if grep -q "^finding_ids:" "$PARENT_FILE"; then
  # Append to existing array
  sed -i.bak "s|^finding_ids: \[|finding_ids: [\"[[04-findings/data/${FINDING_ID}]]\", |" "$PARENT_FILE"
else
  # Insert new field
  awk '/^---$/ && !n {n++; next} n==1 {print "finding_ids: [\"[[04-findings/data/'"$FINDING_ID"']]\"]"; n++} 1' "$PARENT_FILE" > tmp && mv tmp "$PARENT_FILE"
fi
```

### Wikilink Validation

```bash
VALIDATION_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-wikilinks.sh" \
  --entity-file "$ENTITY_FILE" --project-path "$PROJECT_PATH" --json)

ORPHANED=$(echo "$VALIDATION_RESULT" | jq -r '.orphaned_count')
[ "$ORPHANED" -gt 0 ] && log_conditional WARN "Found $ORPHANED orphaned wikilinks"
```

### Anti-Patterns

- Don't omit directory prefix, use absolute paths, create wikilinks without validating target exists
- Do use directory-prefixed wikilinks with existence validation

## Section 4: Entity Lifecycle

### Entity Creation

Use centralized `create-entity.sh`:

```bash
ENTITY_DATA=$(cat <<EOF
{
  "id": "$ENTITY_ID",
  "name": "$ENTITY_NAME",
  "url": "$URL",
  "tags": ["source"],
  "dc:creator": "source-creator",
  "dc:title": "$TITLE",
  "dc:source": "$URL",
  "dc:type": "source"
}
EOF
)

CREATE_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --entity-type "source" --entity-data "$ENTITY_DATA" --project-path "$PROJECT_PATH" --json)
```

**Contract:** `--entity-type <type> --entity-data <json> --project-path <path> --json`

**Response:** `{"success": true, "entity_created": true, "entity_id": "source-a7f3b2c1", "entity_file": "/path/to/..."}`

### Entity Updating

Atomic write pattern:

```bash
# 1. Read current entity
CURRENT_CONTENT=$(cat "$ENTITY_FILE")

# 2. Modify content
UPDATED_CONTENT=$(echo "$CURRENT_CONTENT" | sed 's/^reliability_tier: null/reliability_tier: "tier1"/')

# 3. Write to temp, validate, atomic move
echo "$UPDATED_CONTENT" > "${ENTITY_FILE}.tmp"
[ -f "${ENTITY_FILE}.tmp" ] && mv "${ENTITY_FILE}.tmp" "$ENTITY_FILE"
```

### Entity Validation

```bash
# Validate YAML frontmatter
awk '/^---$/{n++} n==2{exit} n==1' "$ENTITY_FILE" | grep -q "^id:" || { log_conditional ERROR "Missing id"; exit 1; }

# Validate ID matches filename
ENTITY_ID_FILE=$(basename "$ENTITY_FILE" .md)
ENTITY_ID_YAML=$(awk '/^---$/,/^---$/ {if(/^id:/) print $2}' "$ENTITY_FILE" | tr -d ' "')
[ "$ENTITY_ID_FILE" != "$ENTITY_ID_YAML" ] && { log_conditional ERROR "ID mismatch"; exit 1; }
```

### Entity Deletion

Delete with orphan cleanup:

```bash
# 1. Find referencing entities
REFS=$(grep -r "[[.*/${ENTITY_ID}]]" "${PROJECT_PATH}/" --include="*.md" | cut -d: -f1)

# 2. Remove backlinks
for REF in $REFS; do
  sed -i.bak "s|\"\\[\\[.*/${ENTITY_ID}\\]\\]\", *||g" "$REF"
done

# 3. Delete entity
rm "$ENTITY_FILE"
```

## Related References

- [shared-bash-patterns.md](shared-bash-patterns.md) - Bash scaffolding
- [anti-hallucination-foundations.md](anti-hallucination-foundations.md) - Verification patterns
- [../contracts/](../contracts/) - Entity creation contracts

## Version History

**v2.0.0** - Rebuilt for cogni-research v1.0.0: 7 entity types (00-06), removed publishers/citations/megatrends/trends/synthesis/domain-concepts
**v1.2.0** - Compressed 19.4KB -> 10.5KB (46% reduction) while preserving technical specifications
**v1.1.0** - Added radar_category field for action-oriented-radar research type
**v1.0.0** - Initial: YAML patterns, UUID generation, wikilinks, lifecycle (4 sections from 5 skills)
