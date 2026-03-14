# Entity Schemas - Deeper Research Plugin

This directory contains JSON schemas for all entity types in the deeper-research plugin's research pipeline. These schemas provide formal validation, documentation, and a single source of truth for entity structure.

## Overview

**Purpose**: Centralized schema definitions for 11 entity types used throughout the research workflow
**Standard**: JSON Schema Draft 07
**Metadata**: Dublin Core compliant
**Pattern**: Upstream-only linking (see [linking-architecture.md](linking-architecture.md))

**Version**: 1.1.0 (Added trend entity schema)

## Document Guide

This directory contains four key documents:

1. **[README.md](README.md)** (this file) - Overview of all schemas, validation standards, and usage examples
2. **[linking-architecture.md](linking-architecture.md)** - **AUTHORITATIVE** documentation of entity relationships and the upstream-only linking pattern
3. **[INTEGRATION.md](INTEGRATION.md)** - Practical integration patterns for scripts, agents, and hooks
4. **[MIGRATION-NOTES.md](MIGRATION-NOTES.md)** - Migration status tracking and rollout plan

## Entity Types

| ID | Entity Type | Schema File | Description |
|----|-------------|-------------|-------------|
| 00 | Initial Question | [initial-question-entity.schema.json](initial-question-entity.schema.json) | Starting research question |
| 01 | Dimension | [dimension-entity.schema.json](dimension-entity.schema.json) | Research dimension decomposition |
| 02 | Refined Question | [refined-question-entity.schema.json](refined-question-entity.schema.json) | Dimension-specific questions |
| 03 | Query Batch | [query-batch-entity.schema.json](query-batch-entity.schema.json) | Search query collections |
| 04 | Finding | [finding-entity.schema.json](finding-entity.schema.json) | Research findings |
| 05-06 | Megatrend | [megatrend-entity.schema.json](megatrend-entity.schema.json) | Categorization megatrends |
| 07 | Source | [source-entity.schema.json](source-entity.schema.json) | Research sources |
| 08 | Publisher | [publisher-entity.schema.json](publisher-entity.schema.json) | Source publishers |
| 09 | Citation | [citation-entity.schema.json](citation-entity.schema.json) | Source citations |
| 10 | Claim | [claim-entity.schema.json](claim-entity.schema.json) | Factual claims |
| 11 | Trend | [trend-entity.schema.json](trend-entity.schema.json) | Synthesized cross-finding patterns with mandatory planning_horizon |

## Schema Standards

### Required Fields (All Entity Types)

Every entity schema requires these Dublin Core metadata fields:

- `tags`: Array of classification tags
- `dc:creator`: Creator identifier (agent/skill name)
- `dc:title`: Human-readable title
- `dc:identifier`: Unique identifier with format `{entity-type}-{slug}-{8-char-hash}`
- `dc:created`: ISO 8601 timestamp
- `entity_type`: Entity type constant

### Identifier Pattern

All entity identifiers follow this pattern:
```
^{entity-type}-[a-z0-9-]+-[a-f0-9]{8}$
```

**Examples**:
- `source-climate-change-impacts-a7f3b2c1`
- `finding-market-growth-analysis-f3d2e1c4`
- `dimension-economic-factors-b8a9c2d5`

### Timestamp Format

All timestamps use ISO 8601 format with optional milliseconds:
```
^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z$
```

**Examples**:
- `2025-01-26T12:00:00Z`
- `2025-01-26T12:00:00.123Z`

## Usage

### Validating Entities

Use the centralized validation script:

```bash
bash scripts/validate-entity-schema.sh \
  --entity-type source \
  --entity-file research/07-sources/source-example-a7f3b2c1.md \
  --schema-path schemas/source-entity.schema.json \
  --json
```

### Reading Schemas

Skills and agents can load schemas for validation or documentation:

```markdown
# Load schema for source entities
READ: schemas/source-entity.schema.json

EXTRACT:
- Required fields
- Field formats and patterns
- Entity-specific properties
```

### Integration with Entity Creation

The `create-entity.sh` script should reference these schemas for validation:

```bash
# Example integration
SCHEMA_PATH="${CLAUDE_PLUGIN_ROOT}/schemas/${entity_type}-entity.schema.json"
bash scripts/validate-entity-schema.sh \
  --entity-type "${entity_type}" \
  --entity-file "${entity_file}" \
  --schema-path "${SCHEMA_PATH}" \
  --json
```

## Schema Conventions

### File Naming

- Pattern: `{entity-type}-entity.schema.json`
- Case: kebab-case
- Suffix: `.schema.json`

### Schema Structure

All schemas follow this template:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://anthropic.com/schemas/{entity-type}-entity.schema.json",
  "title": "{Entity Type} Entity",
  "description": "Schema for validating {entity-type}.md YAML frontmatter",
  "type": "object",
  "required": ["tags", "dc:creator", "dc:title", "dc:identifier", "entity_type"],
  "additionalProperties": true,
  "properties": {
    "tags": {"type": "array", "items": {"type": "string"}, "minItems": 1},
    "dc:creator": {"type": "string"},
    "dc:title": {"type": "string"},
    "dc:identifier": {"type": "string", "pattern": "^{entity-type}-[a-z0-9-]+-[a-f0-9]{8}$"},
    "dc:created": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z$"},
    "entity_type": {"type": "string", "const": "{entity-type}"}
  }
}
```

### Dublin Core Compliance

All schemas implement core Dublin Core elements:

- `dc:creator` - Entity creator
- `dc:title` - Entity title
- `dc:identifier` - Unique identifier
- `dc:created` - Creation timestamp
- `dc:source` - Source URL (where applicable)
- `dc:type` - Resource type (always matches entity_type)

## Entity Relationships

All entities follow the **upstream-only linking pattern** where entities link ONLY to their immediate parent entities using forward wikilinks.

**For complete relationship documentation**, see [linking-architecture.md](linking-architecture.md), which provides:
- Visual mermaid diagram of entity hierarchy
- Detailed table of all linking fields by entity type
- Navigation patterns (upstream and downstream)
- Field naming conventions and exceptions
- Relationship rules and validation requirements

## Extension Guidelines

### Adding New Entity Types

1. Create schema file: `{entity-type}-entity.schema.json`
2. Include all required Dublin Core fields
3. Define entity-specific properties with descriptions
4. Add validation patterns for identifiers
5. Update this README with new entity type
6. Update UML diagram in `../docs/entity-relationships.uml`
7. Add validation tests

### Modifying Existing Schemas

1. Maintain backward compatibility where possible
2. Update schema version in `$id` field
3. Document breaking changes in CHANGELOG
4. Test against existing entity files
5. Update integration documentation

## Related Documentation

- [Linking Architecture](linking-architecture.md) - **Authoritative** entity relationship documentation
- [Schema Integration](INTEGRATION.md) - Integration patterns for scripts and agents
- [Migration Notes](MIGRATION-NOTES.md) - Migration status and rollout plan
- [Schema Conventions](.schema-conventions.md) - Detailed naming and structure standards

## Validation

All schemas in this directory have been validated against:

- JSON Schema Draft 07 meta-schema
- Dublin Core metadata standards
- Existing entity file examples from dimension-planner
- Plugin architecture standards (plugin-structure.md)

## Migration Notes

**Status**: Starting fresh - no backward compatibility constraints

This schema system replaces 3 previous mechanisms:
1. dimension-planner JSON schemas (Pattern 1)
2. Template-based documentation (Pattern 2)
3. Documentation-only patterns (Pattern 3)

The new centralized approach provides:
- ✅ Single source of truth
- ✅ Automated validation for all entity types
- ✅ Complete Dublin Core compliance
- ✅ Self-documenting schemas
- ✅ Clear integration patterns

---

**Version**: 1.0.0
**Created**: 2025-11-26
**Status**: Production Ready
