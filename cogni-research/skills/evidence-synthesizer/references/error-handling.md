# Error Handling and Recovery Patterns

## Overview

This reference provides detailed recovery procedures for errors encountered during evidence catalog generation. Use this when validation fails, entities are malformed, or catalog generation produces unexpected results.

## Exit Code Convention

- **Exit 2:** Parameter validation errors (user must provide correct parameters)
- **Exit 1:** Runtime/validation errors (system or data issues)
- **Exit 0:** Success (includes warnings for non-critical issues)

## Error Handling Table

| Scenario | Recovery | Exit Code |
|----------|----------|-----------|
| PROJECT_PATH missing | Return error JSON | 2 |
| Working directory validation fails | Return error JSON | 1 |
| No sources/citations directory | Skip, continue with empty list | 0 |
| Entity metadata incomplete | Skip entity, log warning | 0 |
| Catalog write fails | Return error JSON | 1 |
| Template not found | Fall back to generic | 0 |
| Malformed entity YAML | Skip entity, log error | 0 |
| Empty entity file | Skip entity, log warning | 0 |
| Missing required metadata fields | Skip entity, log warning | 0 |
| Invalid tier value | Skip entity, log error | 0 |
| Broken wikilinks in entities | Continue, links preserved as-is | 0 |
| Invalid URL format | Continue with URL as-is | 0 |
| Duplicate source IDs | Use first occurrence, log warning | 0 |
| Missing institutions directory | Continue without institutional analysis | 0 |
| Template validation warnings | Continue (non-blocking) | 0 |

## Error JSON Format

```bash
error_json() {
  local message="$1"
  local exit_code="${2:-1}"
  jq -n --arg msg "$message" '{"success": false, "error": $msg}'
  exit "$exit_code"
}
```

## Scenario 1: Missing or Invalid Project Path

**Symptom:** `PROJECT_PATH` parameter not provided or points to non-existent directory

**Diagnosis:**
```bash
if [ -z "$PROJECT_PATH" ]; then
    error_json "PROJECT_PATH parameter is required" 2
fi

if [ ! -d "$PROJECT_PATH" ]; then
    error_json "PROJECT_PATH does not exist: $PROJECT_PATH" 2
fi
```

**Recovery:**
1. Verify the project path is correct
2. Ensure the research project directory exists
3. Check that the path is absolute, not relative
4. Re-run with correct `--project-path` parameter

**Prevention:**
- Always validate PROJECT_PATH at start of Phase 1
- Use absolute paths, not relative paths
- Document the project directory structure requirement

## Scenario 2: Working Directory Validation Fails

**Symptom:** `validate-working-directory.sh` exits with non-zero code

**Diagnosis:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh" \
    --project-path "$PROJECT_PATH" --json

if [ $? -ne 0 ]; then
    log_conditional ERROR "Working directory validation failed"
    error_json "Project directory structure invalid" 1
fi
```

**Common Causes:**
- Missing `.metadata/` directory
- Missing `sprint-log.json`
- Missing required entity directories (01-dimensions, 02-questions, etc.)
- Incorrect directory permissions

**Recovery:**
1. Check validation script output for specific missing components
2. Verify project was initialized with deeper-research-1 skill
3. Ensure Phases 1-7 completed successfully
4. If directories missing, investigate which phase failed
5. Re-run failed phases to recreate missing structure

**Prevention:**
- Always run deeper-research-1 before deeper-synthesis
- Check Phase 7 completion before starting Phase 8
- Use validation script in Phase 2 of all synthesis skills

## Scenario 3: No Sources or Citations Found

**Symptom:** `SOURCE_COUNT=0` or `CITATION_COUNT=0`

**Diagnosis:**
```bash
# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_SOURCES="$(get_directory_by_key "sources")"
DATA_SUBDIR="$(get_data_subdir)"

SOURCE_COUNT=$(find "${PROJECT_PATH}/$DIR_SOURCES" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [ "$SOURCE_COUNT" -eq 0 ]; then
    log_conditional WARN "No sources found in $DIR_SOURCES/$DATA_SUBDIR/"
fi
```

**Recovery:**
1. **If Phase 5 not run:** Evidence catalog requires source-creator (Phase 5) and citation-generator (Phase 6) to complete first
2. **If directories exist but empty:** Check deeper-research-1 logs for source creation failures
3. **Continue with empty catalog:** Skill will generate catalog with zero sources (valid state)

**Expected Output:**
```
✅ Evidence catalog generation complete.
- Sources cataloged: 0 (T1: 0, T2: 0, T3: 0)
- Citations formatted: 0
- Institutions mapped: 0
- Output: 09-citations/README.md (empty catalog)
```

**Prevention:**
- Verify Phases 5-6 completed before running evidence-synthesizer
- Check source-creator metrics for creation_succeeded count
- Ensure research queries found results in Phase 4

## Scenario 4: Entity Metadata Incomplete

**Symptom:** Source, citation, or institution missing required frontmatter fields

**Diagnosis:**
```bash
# After reading entity file
url=$(echo "$content" | grep "^url:" | sed 's/url: *//' | tr -d '"')
tier=$(echo "$content" | grep "^tier:" | sed 's/tier: *//')

if [ -z "$url" ] || [ -z "$tier" ]; then
    log_conditional WARN "Source $source_id missing required fields"
    # Skip this entity
    continue
fi
```

**Common Missing Fields:**
- Sources: `url`, `tier`, `title`
- Citations: `apa_citation`, `author`, `year`, `title`
- Institutions: `name`, `type`

**Recovery:**

**Option A: Skip Entity (Default)**
1. Log warning with entity ID
2. Continue processing remaining entities
3. Document skipped entities in execution log
4. Catalog will not include incomplete entity

**Option B: Manual Repair**
1. Identify incomplete entity file path
2. Read entity file
3. Add missing fields using Edit tool:
   ```yaml
   url: "https://example.com"
   tier: 2
   title: "Document Title"
   ```
4. Re-run evidence-synthesizer

**Prevention:**
- Use entity-structure-guide.md templates when creating entities
- Validate entity schema in source-creator and citation-generator
- Run entity validation before synthesis phases

## Scenario 5: Malformed Entity YAML

**Symptom:** Entity file has invalid YAML syntax (unclosed quotes, missing delimiters)

**Diagnosis:**
```bash
if ! echo "$content" | grep -q "^---"; then
    log_conditional ERROR "Malformed YAML in $entity_file"
    continue
fi
```

**Common Issues:**
- Missing frontmatter delimiters (`---`)
- Unclosed quotes in string fields
- Invalid array syntax
- Incorrect indentation
- Special characters not escaped

**Recovery:**

**Step 1: Identify Malformed Entity**
```bash
# Entity file read will show YAML parsing errors
Read tool: ${PROJECT_PATH}/07-sources/data/source-example-abc123.md
```

**Step 2: Diagnose Syntax Error**
1. Check for frontmatter delimiters at start and end
2. Verify all string fields properly quoted
3. Check array syntax: `field: ["item1", "item2"]`
4. Look for unescaped special characters in strings

**Step 3: Repair YAML**
Use Edit tool to fix syntax:
```yaml
# Before (broken)
title: "Author's Guide
url: https://example.com

# After (fixed)
title: "Author's Guide"
url: "https://example.com"
```

**Step 4: Verify and Re-run**
1. Read entity file to confirm valid YAML
2. Re-run evidence-synthesizer
3. Entity should now load successfully

**Prevention:**
- Properly escape quotes in entity creation: `"Author's Guide"` → `"Author\'s Guide"`
- Always wrap URLs in quotes
- Use consistent array formatting
- Validate YAML syntax in entity creation phases

## Scenario 6: Catalog Write Fails

**Symptom:** Write tool fails when creating `09-citations/README.md`

**Diagnosis:**
```bash
mkdir -p "${PROJECT_PATH}/09-citations"
OUTPUT_FILE="${PROJECT_PATH}/09-citations/README.md"

# Write catalog content
# If Write tool fails, check:
# - Directory permissions
# - Disk space
# - File path length
```

**Common Causes:**
- Directory permissions (read-only filesystem)
- Disk space full
- File path too long
- Output file already open in another process
- Invalid characters in filename

**Recovery:**

**Step 1: Verify Directory**
```bash
ls -la "${PROJECT_PATH}/09-citations/"
# Check permissions: should show drwxr-xr-x
```

**Step 2: Check Disk Space**
```bash
df -h "${PROJECT_PATH}"
# Ensure sufficient free space (>100MB recommended)
```

**Step 3: Fix Permissions**
```bash
chmod 755 "${PROJECT_PATH}/09-citations"
```

**Step 4: Retry Write**
1. Re-run evidence-synthesizer
2. Write tool should succeed with correct permissions
3. Verify file created: `ls -la 09-citations/README.md`

**Prevention:**
- Verify directory writable before Phase 6
- Check disk space in Phase 2 validation
- Use standard filesystem paths (avoid special characters)
- Close files in other applications before synthesis

## Scenario 7: Template Not Found

**Symptom:** Research type template missing, falling back to generic

**Diagnosis:**
```bash
# Read sprint-log.json for research_type
research_type=$(jq -r '.research_type // "generic"' "${PROJECT_PATH}/.metadata/sprint-log.json")

# Template file expected at:
# ${CLAUDE_PLUGIN_ROOT}/templates/${research_type}/evidence-catalog-template.md

if [ ! -f "$template_file" ]; then
    log_conditional WARN "Template not found for research_type: $research_type"
    log_conditional INFO "Falling back to generic template"
    research_type="generic"
fi
```

**Recovery:**
1. **Automatic Fallback:** Skill will use generic template (no user action needed)
2. **Optional:** Create custom template for research type
3. **Verify Output:** Catalog will use generic structure

**Prevention:**
- Document supported research types in template-loading.md
- Provide generic template as fallback
- Log template selection for debugging

## Scenario 8: Invalid Tier Values

**Symptom:** Source has tier value outside range 1-3

**Diagnosis:**
```bash
tier=$(echo "$content" | grep "^tier:" | sed 's/tier: *//')

if [ "$tier" -lt 1 ] || [ "$tier" -gt 3 ]; then
    log_conditional ERROR "Source $source_id has invalid tier: $tier"
    continue
fi
```

**Valid Tier Values:**
- **Tier 1:** Peer-reviewed, academic, high authority
- **Tier 2:** Professional, industry reports, established media
- **Tier 3:** Blog posts, opinion pieces, social media

**Recovery:**

**Step 1: Identify Invalid Sources**
```bash
grep -l "tier: [^123]" ${PROJECT_PATH}/07-sources/data/*.md
```

**Step 2: Determine Correct Tier**
Review source URL and publisher to classify correctly:
- Academic journal → Tier 1
- Government report → Tier 1-2
- News article → Tier 2
- Blog post → Tier 3

**Step 3: Update Source Entity**
Use Edit tool to correct tier value:
```yaml
# Before
tier: 0

# After
tier: 2
```

**Step 4: Re-run Evidence Synthesizer**
Source will now be included in catalog with correct tier

**Prevention:**
- Validate tier values in source-creator (Phase 5)
- Use tier-classification.md guidance during source creation
- Add tier validation to entity schema

## Scenario 9: Empty Entity Files

**Symptom:** Entity file exists but has no content or minimal content

**Diagnosis:**
```bash
if [ -z "$content" ] || [ $(echo "$content" | wc -l) -lt 5 ]; then
    log_conditional WARN "Entity appears empty: $entity_file"
    continue
fi
```

**Common Causes:**
- Write tool failure during entity creation
- Interrupted entity creation process
- Zero-byte file from disk errors
- Only frontmatter, no content body

**Recovery:**

**Step 1: Check File Size**
```bash
ls -lh ${PROJECT_PATH}/07-sources/data/source-*.md
# Look for 0-byte files or unusually small files (<100 bytes)
```

**Step 2: Inspect Empty File**
```bash
Read tool: ${PROJECT_PATH}/07-sources/data/source-example-abc123.md
```

**Step 3: Delete Empty Entity**
```bash
# Remove corrupted/empty entity
rm "${PROJECT_PATH}/07-sources/data/source-example-abc123.md"
```

**Step 4: Recreate Entity**
1. Identify which phase created the entity (check execution logs)
2. Re-run source-creator on the source that failed
3. Verify entity created successfully with content

**Prevention:**
- Add write verification in entity creation phases
- Check file size after Write tool completes
- Log entity creation success/failure
- Use atomic writes where possible

## Scenario 10: Duplicate Source IDs

**Symptom:** Multiple source files with same source_id in frontmatter

**Diagnosis:**
```bash
# Extract all source_ids
find ${PROJECT_PATH}/07-sources -name "*.md" -exec grep "^source_id:" {} \; | sort | uniq -d
```

**Recovery:**

**Step 1: Identify Duplicates**
List all sources with duplicate IDs:
```bash
# Shows which source IDs appear multiple times
find 07-sources -name "*.md" -exec grep -H "^source_id:" {} \; | cut -d':' -f2 | sort | uniq -d
```

**Step 2: Choose Canonical Entity**
- Select entity with more complete content
- Or select oldest entity (earliest created_at)
- Or select entity with more finding references

**Step 3: Delete Duplicate**
```bash
rm "${PROJECT_PATH}/07-sources/data/source-duplicate-xyz789.md"
```

**Step 4: Re-run Evidence Synthesizer**
Only canonical entity will be included in catalog

**Prevention:**
- Use deterministic ID generation (hash-based)
- Implement deduplication in source-creator
- Validate unique IDs before entity creation

## General Recovery Tips

### Before Recovery

**Backup Project:**
```bash
cd "${PROJECT_PATH}/.."
tar -czf "project-backup-$(date +%Y%m%d-%H%M%S).tar.gz" "$(basename $PROJECT_PATH)"
```

**Document Issue:**
- Record error symptoms
- Note which phase failed
- Save execution logs
- List affected entities

**Identify Scope:**
- Single entity or multiple?
- Specific phase or systematic?
- Critical or can continue?

### During Recovery

1. **Test on single entity first:** Verify recovery procedure works
2. **Use atomic operations:** Edit tool for updates (not Read+Write)
3. **Verify after each step:** Read entity to confirm changes
4. **Log recovery actions:** Document what was changed

### After Recovery

**Verify Catalog:**
```bash
# Check catalog was created
ls -lh ${PROJECT_PATH}/09-citations/README.md

# Verify content
Read tool: ${PROJECT_PATH}/09-citations/README.md
```

**Run Health Check:**
```bash
# Count entities loaded
SOURCE_COUNT=$(find ${PROJECT_PATH}/07-sources -name "*.md" | wc -l)
CITATION_COUNT=$(find ${PROJECT_PATH}/09-citations -name "*.md" | wc -l)
INST_COUNT=$(find ${PROJECT_PATH}/12-institutions -name "*.md" 2>/dev/null | wc -l)

echo "Sources: $SOURCE_COUNT"
echo "Citations: $CITATION_COUNT"
echo "Institutions: $INST_COUNT"
```

**Test Catalog Quality:**
- Verify tier distribution sums to 100%
- Check all wikilinks reference real entities
- Confirm citations formatted correctly (APA)
- Validate institutional authority mapping

### When to Escalate

Escalate to maintainers if:

1. **Systematic failures:** >20% of entities failing to load
2. **Data corruption:** Multiple malformed entity files
3. **Unknown errors:** Not covered in this guide
4. **Tool failures:** Read/Write tools not working
5. **Validation failures:** Working directory validation consistently fails

**Provide when escalating:**
- Error symptoms and frequency
- Execution logs from `reports/evidence-synthesizer-execution-log.txt`
- Sample malformed entity files
- Project backup (if safe to share)
- Steps attempted for recovery

## Recovery Checklists

### Quick Health Check

```bash
#!/bin/bash
# Run from project root

echo "=== Evidence Synthesizer Health Check ==="

# 1. Check entity counts
echo "Sources: $(find 07-sources -name "*.md" 2>/dev/null | wc -l)"
echo "Citations: $(find 09-citations -name "*.md" 2>/dev/null | wc -l)"
echo "Institutions: $(find 12-institutions -name "*.md" 2>/dev/null | wc -l)"

# 2. Check for empty files
echo "Empty source files: $(find 07-sources -name "*.md" -size 0 2>/dev/null | wc -l)"
echo "Empty citation files: $(find 09-citations -name "*.md" -size 0 2>/dev/null | wc -l)"

# 3. Check for malformed YAML
echo "Sources missing frontmatter: $(grep -L "^---" 07-sources/data/*.md 2>/dev/null | wc -l)"

# 4. Check catalog exists
if [ -f "09-citations/README.md" ]; then
    echo "Evidence catalog: EXISTS ($(wc -l < 09-citations/README.md) lines)"
else
    echo "Evidence catalog: NOT FOUND"
fi

# 5. Check tier distribution
echo "Tier 1 sources: $(grep -l "^tier: 1" 07-sources/data/*.md 2>/dev/null | wc -l)"
echo "Tier 2 sources: $(grep -l "^tier: 2" 07-sources/data/*.md 2>/dev/null | wc -l)"
echo "Tier 3 sources: $(grep -l "^tier: 3" 07-sources/data/*.md 2>/dev/null | wc -l)"
```

### Pre-Recovery Checklist

Before attempting recovery:

- [ ] Created project backup
- [ ] Documented error symptoms
- [ ] Identified scope (affected entities)
- [ ] Located execution logs
- [ ] Reviewed this guide for scenario
- [ ] Tested recovery on single entity (if applicable)

### Post-Recovery Checklist

After recovery:

- [ ] Verified entity changes successful
- [ ] Ran health check script
- [ ] Compared before/after entity counts
- [ ] Tested catalog generation
- [ ] Validated catalog quality
- [ ] Checked tier distribution
- [ ] Verified wikilinks
- [ ] Reviewed execution logs
- [ ] Documented recovery steps
- [ ] Removed backup (if recovery successful)

## Related Documentation

- [SKILL.md](../SKILL.md) - Main workflow specification
- [entity-processing.md](entity-processing.md) - Entity loading patterns
- [tier-classification.md](tier-classification.md) - Source tier guidance
- [catalog-structure.md](catalog-structure.md) - Output format specification
- [../../references/anti-hallucination-foundations.md](../../references/anti-hallucination-foundations.md) - Verification standards
- [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) - Error handling patterns
