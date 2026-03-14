# Entity Structure Guide

Universal entity patterns for deeper-research plugin. Use when creating entities, implementing UUID generation, working with wikilinks, or debugging entity formats.

## Purpose

Provides 4 universal patterns:
1. **YAML Frontmatter** - Required fields, formatting
2. **UUID Generation** - Content-addressable identifiers
3. **Wikilink Conventions** - Bidirectional linking
4. **Entity Lifecycle** - Create, update, validate, delete

## Section 1: YAML Frontmatter Patterns

### Universal Entity Structure

**Note:** Entity frontmatter structure varies by skill. Two common patterns exist:

**Pattern 1: dimension-planner entities (Dimensions, Questions)**
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
entity_type: "dimension|refined-question"

# Entity-Specific Metadata (varies by type)
dimension:
  number: 1
  slug: "dimension-slug"
  title: "Dimension Title"
# OR for refined questions:
question:
  number: 1
  slug: "question-slug"
  title: "Question Title"
  text: "Question text?"

language: "en"
---

# Markdown body with structured sections
```

**Pattern 2: Legacy/source entities (Sources, Publishers, Citations)**
```markdown
---
# Entity Identification (REQUIRED)
id: entity-type-uuid
name: "Entity human-readable name"

# Obsidian Tags (REQUIRED)
tags: [entity-type, optional-subtypes]

# Dublin Core Metadata (REQUIRED)
dc:creator: "skill-name"
dc:title: "Entity title"
dc:source: "Source URL or reference"
dc:type: "entity-type"

# Entity-Specific Metadata (varies by type)
---

# Optional markdown body
```

### Required Fields (By Pattern)

**Pattern 1 (dimension-planner):**

| Field | Type | Format | Example |
|-------|------|--------|---------|
| `dc:identifier` | string | `{type}-{slug}-{hash8}` | `dimension-economic-a7f3b2c1` |
| `entity_type` | string | Entity type | `"dimension"` or `"question"` |
| `tags` | array | `[{type}, ...]` | `[research-dimension, dimension-1, en]` |
| `dc:creator` | string | Skill/agent name | `"Claude (dimension-planner)"` |
| `dc:title` | string | Prefixed title | `"Dimension: Economic Analysis"` |
| `dc:created` | string | ISO8601 timestamp | `"2025-01-26T12:00:00.000Z"` |
| `language` | string | ISO 639-1 code | `"en"` |

**Pattern 2 (legacy sources):**

| Field | Type | Format | Example |
|-------|------|--------|---------|
| `id` | string | `{type}-{uuid}` | `source-a7f3b2c1` |
| `name` | string | Quoted, human-readable | `"Climate Study"` |
| `tags` | array | `[{type}, ...]` | `[source, source-type/academic]` |
| `dc:creator` | string | Skill/agent name | `"source-creator"` |
| `dc:title` | string | Entity title | `"Source Title"` |
| `dc:source` | string | Origin reference | `"https://..."` |
| `dc:type` | string | Entity type | `"source"` |

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

### Entity-Specific Fields

| Entity Type | Unique Required Fields |
|-------------|------------------------|
| **Source** | `url`, `domain`, `title`, `access_date` |
| **Publisher** | `name`, `url`, `publisher_type` |
| **Citation** | `source_id`, `publisher_id`, `citation_text` |
| **Finding** | `source_url`, `content` |
| **Claim** | `finding_ids`, `claim_text`, `confidence_score` |
| **Megatrend** | `megatrend_name`, `dimension_id` |
| **Dimension** | `dimension_name`, `research_question` |

**Optional Fields:**
- **Finding/Refined Question** (action-oriented-radar): `radar_category` ("Act"|"Plan"|"Observe") - See `research-executor/references/radar-categorization-guide.md`

See skill-specific `entity-templates.md` for complete schemas.

### Anti-Patterns

❌ **Don't:** Mix tabs/spaces, use field names in values, omit required fields

✅ **Do:** Use consistent indentation, quote special chars, include all required fields

## Section 2: UUID Generation

### Semantic UUID Pattern

Content-addressable UUIDs enable deduplication. Two patterns exist:

**Pattern 1: dimension-planner entities (8-char hash)**

```bash
# Generate semantic slug from dimension/question title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Generate 8-character hash
HASH=$(echo -n "$TITLE" | shasum -a 256 | cut -c1-8)

ENTITY_ID="${ENTITY_TYPE}-${SLUG}-${HASH}"
# Example: dimension-economic-analysis-a7f3b2c1
```

**Pattern 2: Legacy entities (centralized script)**

```bash
# Generate semantic slug using centralized utility
ENTITY_CONTENT="${URL}|${TITLE}"  # Varies by entity type

SLUG_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" \
  --title "$TITLE" --content-key "$ENTITY_CONTENT" --json)

SEMANTIC_UUID=$(echo "$SLUG_RESULT" | jq -r '.data.semantic_uuid')
ENTITY_ID="${ENTITY_TYPE}-${SEMANTIC_UUID}"
# Example: source-my-article-title-a7f3b2c1
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
ENTITY_FILE="${PROJECT_PATH}/07-sources/data/${ENTITY_ID}.md"
if [ -f "$ENTITY_FILE" ]; then
  log_conditional INFO "Entity exists: $ENTITY_ID (reused)"
else
  # Create new entity
fi
```

### UUID Content Patterns by Entity Type

**Pattern 1 (dimension-planner - slug + 8-char hash):**

| Entity Type | Slug Source | Hash Source | Example ID |
|-------------|-------------|-------------|------------|
| **Dimension** | Dimension title (kebab-case) | SHA256 of title | `dimension-economic-analysis-a7f3b2c1` |
| **Question** | Question title (kebab-case) | SHA256 of title | `question-market-size-b2c3d4e5` |

**Pattern 2 (legacy - centralized script):**

| Entity Type | UUID Source Content |
|-------------|---------------------|
| **Source** | `${URL}\|${TITLE}` |
| **Publisher** | `${PUBLISHER_NAME}\|${URL}` |
| **Citation** | `${SOURCE_ID}\|${PUBLISHER_ID}` |
| **Finding** | `${DIMENSION_ID}\|${QUERY_ID}\|${SEQUENCE}` |
| **Claim** | `${CLAIM_TEXT_HASH}` |
| **Megatrend** | `${MEGATREND_NAME}\|${DIMENSION_ID}` |

### Anti-Patterns

❌ **Don't:** Generate UUIDs inline (non-standard), use random UUIDs (no deduplication), skip existence check

✅ **Do:** Use centralized utility with deduplication check

## Section 3: Wikilink Conventions

### Wikilink Format

```markdown
[[directory/entity-id]]
```

Always include directory prefix:

**Pattern 1 (dimension-planner):**

| Entity Type | Directory | Wikilink Example |
|-------------|-----------|------------------|
| Initial Question | `00-initial-question` | `[[00-initial-question/data/question-initial-f7ef12b8]]` |
| Dimension | `01-research-dimensions` | `[[01-research-dimensions/data/dimension-economic-analysis-a7f3b2c1]]` |
| Question | `02-refined-questions` | `[[02-refined-questions/data/question-market-size-b2c3d4e5]]` |

**Pattern 2 (legacy entities):**

| Entity Type | Directory | Wikilink Example |
|-------------|-----------|------------------|
| Finding | `04-findings` | `[[04-findings/data/finding-xyz-abc123]]` |
| Claim | `10-claims` | `[[10-claims/data/claim-d5e8f3b4]]` |
| Megatrend | `06-megatrends` | `[[06-megatrends/data/megatrend-e6f9a4c5]]` |
| Source | `07-sources` | `[[07-sources/data/source-a7f3b2c1]]` |
| Publisher | `08-publishers` | `[[08-publishers/data/publisher-b3d5e2f1]]` |
| Citation | `09-citations` | `[[09-citations/data/citation-c4f7a2d3]]` |

### Bidirectional Linking

**Forward links** (in frontmatter):
```yaml
source_id: "[[07-sources/data/source-a7f3b2c1]]"
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
PARENT_FILE="${PROJECT_PATH}/07-sources/data/${SOURCE_ID}.md"

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

❌ **Don't:** Omit directory prefix, use absolute paths, create wikilinks without validating target exists

✅ **Do:** Use directory-prefixed wikilinks with existence validation

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

## Integration Example

Complete workflow using all 4 sections:

```bash
# Section 1: Prepare YAML data
ENTITY_DATA=$(cat <<EOF
{"id": "$ENTITY_ID", "name": "$NAME", "url": "$URL", "tags": ["source"],
 "dc:creator": "source-creator", "dc:title": "$TITLE", "dc:source": "$URL", "dc:type": "source"}
EOF
)

# Section 2: Generate UUID with deduplication
SLUG_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" --title "${TITLE}" --content-key "${URL}|${TITLE}" --json)
SLUG=$(echo "$SLUG_RESULT" | jq -r '.data.semantic_uuid')
ENTITY_ID="source-${SLUG}"

# Section 3: Create entity (handles wikilinks)
CREATE_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --entity-type "source" --entity-data "$ENTITY_DATA" --project-path "$PROJECT_PATH" --json)

# Section 4: Validate lifecycle
if [ "$(echo "$CREATE_RESULT" | jq -r '.success')" = "true" ]; then
  ENTITY_FILE="${PROJECT_PATH}/07-sources/data/${ENTITY_ID}.md"
  [ ! -f "$ENTITY_FILE" ] && { log_conditional ERROR "File missing: $ENTITY_FILE"; exit 1; }
  log_conditional INFO "Entity created: $ENTITY_ID"
fi
```

## Related References

- [shared-bash-patterns.md](shared-bash-patterns.md) - Bash scaffolding
- [script-contract-usage.md](script-contract-usage.md) - Contract invocation
- [anti-hallucination-foundations.md](anti-hallucination-foundations.md) - Verification patterns
- [../contracts/](../contracts/) - Entity creation contracts

## Entity Type Reference

For complete schemas, see skill-specific `entity-templates.md`:

- **Sources:** See `scripts/source-creator.sh` (script-based, no skill)
- **Publishers:** `skills/publisher-generator/references/entity-templates.md`
- **Citations:** `skills/citation-generator/references/entity-templates.md`
- **Findings:** `skills/findings-creator/references/workflows/phase-4-finding-extraction.md`
- **Claims:** `skills/fact-checker/references/entity-templates.md`
- **Megatrends:** `skills/knowledge-extractor/references/domain/entity-templates.md`
- **Dimensions:** `skills/dimension-planner/references/entity-templates.md`

## Version History

**v1.0.0** - Initial: YAML patterns, UUID generation, wikilinks, lifecycle (4 sections from 5 skills)
**v1.1.0** - Added radar_category field for action-oriented-radar research type
**v1.2.0** - Compressed 19.4KB → 10.5KB (46% reduction) while preserving technical specifications
