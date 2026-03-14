# Quality Standards

Quality best practices and validation workflows for deeper-research entity generation.

**Read this when:** Implementing quality checks, validating entity integrity, debugging data issues, understanding quality standards.

## Overview

Quality management in deeper-research is distributed across individual processing skills rather than centralized gates. Each skill (publisher-generator, citation-generator, source-creator, etc.) implements quality checks appropriate to its domain.

## Quality Principles

### 1. In-Process Validation

**Pattern:** Validate data during creation, not after
- Publisher-generator validates publisher entities during generation
- Citation-generator validates citation links during creation
- Source-creator validates source metadata during extraction

**Benefits:**
- Immediate error detection
- Contextual error messages
- Prevents downstream propagation

### 2. Entity Integrity

**Standards:**
- Valid JSON/YAML frontmatter
- Required fields present (title, type, status)
- Wikilink syntax correctness
- ISO 8601 date formats
- Valid entity types per schema

**Validation Points:**
- Entity creation (Write tool usage)
- Entity updates (Edit tool usage)
- Index synchronization (entity-index.json)

### 3. Referential Integrity

**Standards:**
- All wikilinks resolve to existing entities
- Bidirectional references maintained
- No orphaned entities (zero references)
- No circular dependencies

**Validation Methods:**
- Pre-write wikilink validation
- Post-phase referential checks
- Index-based integrity verification

## Quality Checks by Phase

### Phase 5: Source Creation

**source-creator checks:**
- URL validity and normalization
- Duplicate URL detection (within batch)
- Required metadata fields (domain, title, authors)
- Finding reference validation

### Phase 6: Publisher & Citation Generation

**publisher-generator checks:**
- Publisher name normalization
- Type detection accuracy (organization vs individual)
- Deduplication within processing batch
- Source reference validation

**citation-generator checks:**
- Source-to-publisher linking accuracy
- Publisher entity existence
- Citation link bidirectionality
- Attribution completeness

## Validation Protocols

### Pre-Phase Validation

Before starting a phase:
1. Verify input entities exist
2. Check required directories present
3. Validate prerequisite phase completion
4. Confirm entity-index.json synchronized

### Post-Phase Validation

After completing a phase:
1. Verify all expected entities created
2. Check JSON/YAML syntax validity
3. Validate wikilink resolution
4. Update entity-index.json
5. Report entity counts and metrics

### Continuous Validation

During phase execution:
- Validate before each Write/Edit operation
- Log warnings for potential issues
- Track metrics for reporting
- Handle errors gracefully

## Error Handling

### Error Severity Levels

**CRITICAL:** Halt pipeline immediately
- Invalid JSON syntax
- Missing required directories
- Corrupted entity-index.json
- Zero entities when > 0 expected

**ERROR:** Log and continue with degraded functionality
- Missing optional metadata fields
- Broken wikilinks (can be fixed later)
- Duplicate entities (can merge manually)

**WARNING:** Log for review, continue normally
- Unusual entity counts
- Ambiguous publisher names
- Incomplete metadata

### Recovery Strategies

**For validation failures:**
1. Log detailed error context
2. Provide remediation guidance
3. Offer manual intervention points
4. Support re-running specific phases

**For data quality issues:**
1. Report issues clearly in logs
2. Continue processing when safe
3. Generate quality metrics report
4. Flag for post-pipeline review

## Quality Metrics

### Entity-Level Metrics

**Track per phase:**
- Entities created
- Entities updated
- Validation failures
- Warning count

**Report format:**
```json
{
  "phase": "Phase 6.2: Citation Generation",
  "entities_created": 145,
  "entities_updated": 23,
  "validation_errors": 0,
  "warnings": 3,
  "quality_score": 0.98
}
```

### Pipeline-Level Metrics

**Aggregate metrics:**
- Total entities across all types
- Cross-reference completeness
- Index synchronization status
- Overall data quality score

## Best Practices

### For Skill Developers

1. **Validate early:** Check data before processing
2. **Validate often:** Check during and after operations
3. **Validate clearly:** Provide actionable error messages
4. **Validate gracefully:** Handle errors without crashing

### For Pipeline Orchestration

1. **Progressive validation:** Check after each major phase
2. **Dependency validation:** Verify prerequisites before phase start
3. **Result validation:** Confirm expected outputs after phase completion
4. **Recovery planning:** Support selective phase re-runs

### For Entity Creation

1. **Required fields first:** Validate required metadata before optional
2. **Syntax before semantics:** Check JSON/YAML syntax before content
3. **References last:** Validate wikilinks after entity creation
4. **Index updates:** Keep entity-index.json synchronized

## Troubleshooting

### Common Issues

**Issue:** "Entity has invalid JSON syntax"
- **Cause:** Malformed frontmatter, missing quotes, trailing commas
- **Fix:** Validate JSON before Write, use jq for testing
- **Prevention:** Use JSON libraries, not string concatenation

**Issue:** "Wikilink [[Entity]] does not resolve"
- **Cause:** Target entity not created yet, typo in entity name
- **Fix:** Verify entity existence, check spelling, use entity-index.json
- **Prevention:** Create referenced entities before creating references

**Issue:** "Duplicate entities detected"
- **Cause:** Same entity created by multiple parallel agents
- **Fix:** Merge duplicates manually, update references
- **Prevention:** Use deduplication checks before entity creation

**Issue:** "Orphaned entities found"
- **Cause:** No findings or other entities reference this entity
- **Fix:** Link entity to findings, or archive if truly orphaned
- **Prevention:** Validate bidirectional references during creation

## Migration Notes

**Historical Context:**

Prior to v1.3.0, deeper-research used centralized data quality gates (Phase 6.1 & 6.5) via a dedicated data-quality-manager agent. This has been replaced with distributed quality management within individual skills.

**Changes:**
- Phase 6.1 (Data Quality Management) - removed
- Phase 6.5 (Quality Gate) - removed
- data-quality-manager agent - removed
- Quality responsibility distributed to processing skills

**Benefits of Distributed Approach:**
- Quality checks closer to data generation
- More contextual error messages
- Faster feedback loops
- Simpler pipeline architecture
- Easier to maintain and extend

## See Also

- [validation-protocols.md](validation-protocols.md) - JSON validation workflows
- [entity-tagging-taxonomy.md](entity-tagging-taxonomy.md) - Entity metadata schemas
- [phase-6-publisher-citation.md](phase-workflows/phase-6-publisher-citation.md) - Publisher and citation generation
