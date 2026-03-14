# Schema Integration Guide

This guide explains how to integrate the centralized entity schemas with scripts, agents, and hooks in the deeper-research plugin.

## Integration Overview

The centralized schema system provides:
- **JSON schemas** for all 10 entity types in `/cogni-research/schemas/`
- **Validation script** at `/cogni-research/scripts/validate-entity-schema.sh`
- **Linking architecture** defining entity relationships in `linking-architecture.md`
- **Conventions** documented in `/cogni-research/schemas/.schema-conventions.md`

**Key Principle**: All entities follow the **upstream-only linking pattern** where entities link ONLY to their immediate parent entities. See [linking-architecture.md](linking-architecture.md) for complete relationship documentation.

## Integration Patterns

### Pattern 1: Entity Creation with Validation

**When creating entities**, validate against schemas after file creation:

```bash
#!/bin/bash
# In create-entity.sh or entity creation script

# 1. Create entity file (existing logic)
entity_file="/path/to/07-sources/source-example-a7f3b2c1.md"
entity_type="source"

# Write entity content with YAML frontmatter
cat > "${entity_file}" << EOF
---
tags: [source, source-type/academic]
dc:creator: "source-creator"
dc:title: "Example Source"
dc:identifier: "source-example-a7f3b2c1"
dc:created: "2025-11-26T12:00:00Z"
entity_type: "source"
url: "https://example.com/article"
domain: "example.com"
publisher_id: "[[08-publishers/data/publisher-example-b8c9d1e2]]"
finding_refs:
  - "[[04-findings/data/finding-example-c9d1e2f3]]"
---

# Source Content
EOF

# 2. Validate against schema
schema_path="${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json"

validation_result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-entity-schema.sh" \
  --entity-type "${entity_type}" \
  --entity-file "${entity_file}" \
  --schema-path "${schema_path}" \
  --json)

validation_status=$(echo "${validation_result}" | jq -r '.status')

if [ "${validation_status}" != "success" ]; then
  echo "ERROR: Entity validation failed"
  echo "${validation_result}" | jq '.validation_errors'
  exit 1
fi

echo "✅ Entity created and validated successfully"
```

### Pattern 2: Hook Integration

**In post-entity-creation.sh hook**, add schema validation:

```bash
#!/bin/bash
# File: hooks/post-entity-creation.sh

# Extract entity type from file path or frontmatter
entity_file="$1"  # Passed by hook trigger
entity_type=$(grep "^entity_type:" "${entity_file}" | cut -d'"' -f2)

# Validate if schema exists
schema_path="${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json"

if [ -f "${schema_path}" ]; then
  validation_result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-entity-schema.sh" \
    --entity-type "${entity_type}" \
    --entity-file "${entity_file}" \
    --schema-path "${schema_path}" \
    --json)

  validation_status=$(echo "${validation_result}" | jq -r '.status')

  if [ "${validation_status}" != "success" ]; then
    echo "⚠️ Schema validation failed for ${entity_file}"
    echo "${validation_result}" | jq '.validation_errors'
    # Warning mode: log but don't block
    # Strict mode: exit 1 to block
  fi
else
  echo "⚠️ No schema found for entity type: ${entity_type}"
fi
```

### Pattern 3: Agent/Skill Schema Loading

**In agent or skill prompts**, reference schemas for structure:

```markdown
# In agent.md or SKILL.md

## Phase 2: Entity Creation

Before creating entities, load the schema to understand required fields:

**READ**: /cogni-research/schemas/source-entity.schema.json

**EXTRACT**:
- Required fields (tags, dc:creator, dc:title, dc:identifier, dc:created, entity_type, url, domain, publisher_id, finding_refs)
- Field patterns (dc:identifier pattern: ^source-[a-z0-9-]+-[a-f0-9]{8}$)
- Optional fields (doi, pmid, isbn, reliability_tier)
- Linking pattern: Sources link upstream to findings via finding_refs array (upstream-only pattern)

**CREATE** entity with schema-compliant frontmatter:
\`\`\`yaml
---
tags: [source, source-type/academic]
dc:creator: "source-creator"
dc:title: "Research Source Title"
dc:identifier: "source-research-title-a7f3b2c1"
dc:created: "2025-11-26T12:00:00.000Z"
entity_type: "source"
url: "https://example.com/research"
domain: "example.com"
publisher_id: "[[08-publishers/data/publisher-example-b8c9d1e2]]"
finding_refs:
  - "[[04-findings/data/finding-example-c9d1e2f3]]"
---
\`\`\`
```

### Pattern 4: Validation in CI/CD

**In pre-commit hooks or CI/CD**, validate all entities:

```bash
#!/bin/bash
# File: .git/hooks/pre-commit or CI script

# Find all entity markdown files
entity_files=$(find research -name "*.md" -type f)

validation_errors=0

for entity_file in ${entity_files}; do
  # Extract entity type
  entity_type=$(grep "^entity_type:" "${entity_file}" | cut -d'"' -f2)

  # Skip if no entity_type field
  if [ -z "${entity_type}" ]; then
    continue
  fi

  # Validate against schema
  schema_path="cogni-research/schemas/${entity_type}-entity.schema.json"

  if [ -f "${schema_path}" ]; then
    validation_result=$(bash cogni-research/scripts/validate-entity-schema.sh \
      --entity-type "${entity_type}" \
      --entity-file "${entity_file}" \
      --schema-path "${schema_path}" \
      --json)

    validation_status=$(echo "${validation_result}" | jq -r '.status')

    if [ "${validation_status}" != "success" ]; then
      echo "❌ Validation failed: ${entity_file}"
      echo "${validation_result}" | jq '.validation_errors'
      validation_errors=$((validation_errors + 1))
    fi
  fi
done

if [ ${validation_errors} -gt 0 ]; then
  echo "❌ ${validation_errors} entity validation errors found"
  exit 1
fi

echo "✅ All entities validated successfully"
```

### Pattern 5: Schema Reference in Documentation

**In agent/skill references**, link to schemas for field definitions:

```markdown
# In references/entity-templates.md

## Source Entity Template

**Schema**: [source-entity.schema.json](../../schemas/source-entity.schema.json)

For complete field definitions, validation patterns, and requirements, refer to the JSON schema.

**Required Fields** (from schema):
- tags: Array of classification tags
- dc:creator: Creator identifier
- dc:title: Source title
- dc:identifier: Unique ID (pattern: source-*-XXXXXXXX)
- dc:created: ISO 8601 timestamp
- entity_type: "source"
- url: Source URL (HTTP/HTTPS)
- domain: Source domain
- publisher_id: Wikilink to publisher (identifier, not ref - see schema note)
- finding_refs: Array of wikilinks to findings (upstream-only pattern)
```

## Integration with Existing Scripts

### Updating create-entity.sh

Modify the existing `create-entity.sh` script to validate against schemas:

```bash
# After entity file creation, before returning success

# Validate entity if schema exists
schema_path="${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json"

if [ -f "${schema_path}" ]; then
  validation_result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-entity-schema.sh" \
    --entity-type "${entity_type}" \
    --entity-file "${entity_file}" \
    --schema-path "${schema_path}" \
    --json 2>&1)

  validation_exit_code=$?

  if [ ${validation_exit_code} -ne 0 ]; then
    echo "{\"status\": \"error\", \"message\": \"Schema validation failed\", \"validation\": ${validation_result}}" | jq '.'
    exit 1
  fi
fi
```

### Updating dimension-planner Skill

The `dimension-planner` skill currently has local schemas in `skills/dimension-planner/schemas/`. Update to use centralized schemas:

**Before**:
```markdown
# In dimension-planner SKILL.md
READ: schemas/dimension-entity.schema.json
```

**After**:
```markdown
# In dimension-planner SKILL.md
READ: ../../schemas/dimension-entity.schema.json
```

Or use absolute path resolution:
```bash
schema_path="${CLAUDE_PLUGIN_ROOT}/schemas/dimension-entity.schema.json"
```

## Schema Path Resolution

### From Skills

Skills can reference schemas using relative paths from skill directory:

```
Current: /cogni-research/skills/my-skill/SKILL.md
Schema:  ../../schemas/source-entity.schema.json
Resolves: /cogni-research/schemas/source-entity.schema.json
```

### From Scripts

Scripts should use `CLAUDE_PLUGIN_ROOT` environment variable:

```bash
schema_path="${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json"
```

### From Agents

Agents use absolute paths provided in prompts or resolve via environment:

```markdown
READ: /cogni-research/schemas/source-entity.schema.json
# Or dynamically:
READ: ${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json
```

## Validation Modes

### Warning Mode (Default Recommendation)

Log validation errors but don't block entity creation:

```bash
if [ "${validation_status}" != "success" ]; then
  echo "⚠️ WARNING: Schema validation failed"
  echo "${validation_result}" | jq '.validation_errors'
  # Continue execution
fi
```

**Use case**: Gradual adoption, existing entities may not be fully compliant

### Strict Mode

Block entity creation on validation failure:

```bash
if [ "${validation_status}" != "success" ]; then
  echo "❌ ERROR: Schema validation failed"
  echo "${validation_result}" | jq '.validation_errors'
  exit 1
fi
```

**Use case**: New entities must be schema-compliant, enforcement enabled

## Testing Integration

### Test Entity Validation

```bash
# Create test entity
test_entity="/tmp/test-source.md"
cat > "${test_entity}" << EOF
---
tags: [source]
dc:creator: "test"
dc:title: "Test Source"
dc:identifier: "source-test-a7f3b2c1"
dc:created: "2025-01-26T12:00:00Z"
entity_type: "source"
url: "https://example.com"
domain: "example.com"
publisher_id: "[[08-publishers/data/publisher-test-b8c9d1e2]]"
finding_refs:
  - "[[04-findings/data/finding-test-c9d1e2f3]]"
---
EOF

# Validate
bash scripts/validate-entity-schema.sh \
  --entity-type source \
  --entity-file "${test_entity}" \
  --schema-path schemas/source-entity.schema.json \
  --json

# Check exit code
echo "Exit code: $?"
```

### Test Schema Loading in Agent

Create test agent that loads and uses schema:

```markdown
# test-schema-agent.md
---
name: test-schema-agent
---

# Test Schema Loading

## Step 1: Load Schema

READ: schemas/source-entity.schema.json

## Step 2: Validate Understanding

Confirm required fields loaded:
- tags
- dc:creator
- dc:title
- dc:identifier
- dc:created
- entity_type
- url
- domain
- publisher_id
- batch_id
```

## Migration Path

### Phase 1: Centralized Schemas (Complete)

✅ All 10 schemas created in `/cogni-research/schemas/`
✅ Validation script created
✅ UML diagram created

### Phase 2: Integration (Current)

1. Update `create-entity.sh` to call validation script
2. Add schema validation to `post-entity-creation.sh` hook (warning mode)
3. Update dimension-planner to reference centralized schemas
4. Document integration patterns (this guide)

### Phase 3: Adoption (Next Sprint)

1. Enable strict mode for new entities
2. Migrate existing entities gradually
3. Update all skills to reference centralized schemas
4. Deprecate local schema copies

### Phase 4: Enforcement (Future Sprint)

1. Enable strict mode globally
2. CI/CD validation for all entities
3. Pre-commit hooks for schema compliance
4. Remove legacy template files

## Troubleshooting

### Validation Script Not Found

```bash
# Check script exists
ls -la scripts/validate-entity-schema.sh

# Ensure executable
chmod +x scripts/validate-entity-schema.sh
```

### Schema Not Found

```bash
# Check schema exists
ls -la schemas/source-entity.schema.json

# Verify path resolution
echo "${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json"
```

### Validation Errors

```bash
# Get detailed error information
validation_result=$(bash scripts/validate-entity-schema.sh \
  --entity-type source \
  --entity-file path/to/entity.md \
  --schema-path schemas/source-entity.schema.json \
  --json)

# Pretty print errors
echo "${validation_result}" | jq '.validation_errors'
```

### Missing yq or jq

```bash
# Check tool availability
which yq
which jq

# Install if missing (macOS)
brew install yq jq

# Install if missing (Linux)
sudo apt-get install yq jq
```

## Related Documentation

- [Schema README](README.md) - Schema overview and entity types
- [Linking Architecture](linking-architecture.md) - **Authoritative** entity relationship documentation
- [Schema Conventions](.schema-conventions.md) - Naming and structure standards
- [Migration Notes](MIGRATION-NOTES.md) - Migration status and rollout plan

---

**Version**: 1.0.0
**Created**: 2025-11-26
**Status**: Production Ready
