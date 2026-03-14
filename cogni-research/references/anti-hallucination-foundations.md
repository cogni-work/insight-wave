# Anti-Hallucination Foundations

## Purpose

Foundation patterns for preventing fabrication across the research pipeline. LLMs naturally generate plausible content not in source data. These patterns enforce complete data loading, verification checkpoints, and evidence-based processing to ensure all outputs traceable to actual loaded content.

---

## Core Principles

1. **Complete Entity Loading** - Load ALL entities before processing (no truncation, no shortcuts)
2. **Verification Checkpoints** - Validate completeness at phase boundaries with count matching
3. **Evidence-Based Processing** - All outputs grounded in loaded data only
4. **No Fabrication Rule** - Use explicit fallback when no match found (never invent alternatives)
5. **Provenance Integrity** - Ensure traceable wikilinks and validated knowledge graph connectivity

---

## Pattern 1: Complete Entity Loading Protocol

**Definition:** Load ALL entities completely before processing with no line limits or truncation. Partial loading creates hallucination risk where agents fabricate or miss matches.

### Implementation (3 Steps)

**Step 1: Count entities first**
```bash
SOURCE_COUNT=$(find "${PROJECT_PATH}/05-sources" -name "source-*.md" | wc -l | tr -d ' ')
log_conditional INFO "Loading $SOURCE_COUNT sources completely..."
```

**Step 2: Load entities completely**
```bash
SOURCES_TO_PROCESS=()
for source_file in "${PROJECT_PATH}"/05-sources/data/source-*.md; do
  [ -f "$source_file" ] || continue
  SOURCES_TO_PROCESS+=("$(basename "$source_file" .md)")
done
```

**Step 3: Verify count matches**
```bash
if [ ${#SOURCES_TO_PROCESS[@]} -ne "$SOURCE_COUNT" ]; then
  log_conditional ERROR "Count mismatch: expected $SOURCE_COUNT, loaded ${#SOURCES_TO_PROCESS[@]}"
  exit 1
fi
log_conditional INFO "VERIFICATION: All $SOURCE_COUNT sources loaded"
```

---

## Pattern 2: Verification Checkpoint Pattern

**Definition:** Mandatory validation at phase boundaries to confirm data completeness before proceeding. Prevents cascading failures from incomplete loading.

### Implementation (4 Steps)

**Step 1: Define verification criteria**
- Entity count matches expected count
- No empty arrays (unless valid edge case)
- All required metadata extracted
- No YAML artifacts in values

**Step 2: Execute verification check**
```bash
if [ ${#SOURCES_TO_PROCESS[@]} -eq 0 ]; then
  echo '{"success": true, "message": "No sources to process"}'
  exit 0
fi
```

**Step 3: Log verification status**
```bash
log_conditional INFO "CHECKPOINT: Complete entity loading verified"
log_conditional INFO "  Sources: ${#SOURCES_TO_PROCESS[@]}"
```

**Step 4: Halt if verification fails** - Exit with error JSON, DO NOT proceed to next phase

---

## Pattern 3: Evidence-Based Processing

**Definition:** All outputs grounded exclusively in loaded data. Validate entity existence before linking. Use explicit fallback when no match found.

### Implementation Rules

**Rule 1: Validate entity existence before linking**
```bash
if [ -f "${PROJECT_PATH}/05-sources/data/${SOURCE_ID}.md" ]; then
  SOURCE_WIKILINK="[[05-sources/data/${SOURCE_ID}]]"
else
  SOURCE_WIKILINK=""  # Entity doesn't exist - use fallback
fi
```

**Rule 2: Use explicit fallback (no fabrication)**
```bash
if [ -z "$SOURCE_ID" ]; then
  MATCH_STRATEGY="domain_fallback"
  log_conditional WARN "No source found - using domain fallback"
  # DO NOT fabricate source entity
fi
```

**Rule 3: Preserve source content exactly**
```bash
# WRONG: Source "may improve" -> Claim "improves" (strengthened)
# CORRECT: Source "may improve" -> Claim "may improve" (preserved)

# Preserve hedge words: may, might, could, suggests, likely, appears, tends
```

**Rule 4: Never invent metadata**
```bash
# Use only values extracted from loaded files
DOI=$(grep "^doi:" "$SOURCE_FILE" | sed 's/^doi:[[:space:]]*//')
# If empty, stays empty - no fabrication
```

---

## Pattern 4: No Fabrication Rule

**Definition:** Never invent entities, connections, or metadata. When no match found, use documented fallback strategy.

### Anti-Patterns to Avoid

| Anti-Pattern | Wrong Approach | Correct Approach |
|--------------|----------------|------------------|
| **Fabricated Links** | Assume entity exists: `WIKILINK="[[05-sources/data/source-name]]"` | Validate first: `if [ -f "$file" ]; then ... else WIKILINK=""; fi` |
| **Fabricated Metadata** | Invent plausible DOI: `DOI="10.1000/placeholder.2024"` | Leave empty: `DOI=""` or use standard: `YEAR="n.d."` |
| **Strengthened Language** | Remove hedge: "may improve" -> "improves" | Preserve hedge: "may improve" -> "may improve" |
| **Assumed Existence** | Use without check: `NAME="${ARRAY[$key]}"` | Verify: `if [ -n "${ARRAY[$key]}" ]; then ... else NAME=""; fi` |

### Correct Alternatives

**Domain Fallback:**
```bash
if [ -z "$SOURCE_ID" ]; then
  MATCH_STRATEGY="domain_fallback"
  # References domain, not fabricated entity
fi
```

**Explicit Missing Data:**
```bash
[ -z "$YEAR" ] && YEAR="n.d."  # APA standard
```

**Flagged for Review:**
```bash
(( $(echo "$faithfulness < 0.7" | bc -l) )) && flagged_for_review="true"
```

---

## Pattern 5: Provenance Integrity

**Definition:** Ensure traceable wikilinks, complete audit trails, and knowledge graph connectivity based on validated entities.

### Implementation Standards

**Standard 1: Validated wikilinks**
```bash
if [ -f "${PROJECT_PATH}/05-sources/data/${source_id}.md" ]; then
  SOURCE_WIKILINK="[[05-sources/data/${source_id}]]"
else
  echo "ERROR: Source not found: $source_id" >&2
  continue  # Skip, don't create broken link
fi
```

**Standard 2: Directory prefix consistency**

```text
CORRECT: [[05-sources/data/source-climate-001]]
WRONG:   [[source-climate-001]]
```

**Standard 3: Complete audit trail**
```bash
# Log all entity creation with metadata
log_conditional INFO "Generated: ${ENTITY_ID}"
log_conditional INFO "  Match Strategy: ${MATCH_STRATEGY}"

# Include audit metadata in frontmatter
# created_at, creator, match_strategy, dc:relation
```

**Standard 4: Knowledge graph validation**
```bash
# Verify link targets exist
for wikilink in $(grep -o '\[\[[^]]*\]\]' "$FILE"); do
  target=$(echo "$wikilink" | sed 's/\[\[\(.*\)\]\]/\1/')
  [ ! -f "${PROJECT_PATH}/${target}.md" ] && echo "ERROR: Broken link: $wikilink" >&2
done
```

---

## Common Anti-Patterns

| Anti-Pattern | Detection | Correction |
|--------------|-----------|------------|
| **Truncated Loading** | `head -20 file.md`, no count verification | Load ALL: `for file in *.md; do ...; done` + verify count match |
| **Assumed Existence** | No file check: `WIKILINK="[[.../${ID}]]"` | Validate: `[ -f "$file" ] && WIKILINK="..." \|\| WIKILINK=""` |
| **Fabricated Links** | Pattern-based ID: `ID=$(echo "$domain" \| sed ...)` | Lookup: `[ -n "${HASH[$key]}" ] && ID="${HASH[$key]}"` + fallback |
| **Incomplete Verification** | Load -> process immediately | Count -> load -> verify match -> checkpoint -> process |

---

## Integration

### claim-extractor Usage

- **Pattern 1:** Loads all findings completely, verifies count
- **Pattern 2:** 4-step verification before creating each claim
- **Pattern 3:** Claims grounded in finding text, preserves hedge words
- **Pattern 4:** Never strengthens qualifiers, flags verification failures
- **Pattern 5:** Validated wikilinks, complete audit trail, faithfulness dimension

### source-creator Usage

- **Pattern 1:** Loads ALL sources completely, verifies counts
- **Pattern 2:** Mandatory verification after loading, halts on mismatch
- **Pattern 3:** Source matching from loaded entities only, validates existence
- **Pattern 4:** Domain fallback is explicit strategy (not fabrication)
- **Pattern 5:** Validated wikilinks with directory prefixes, Dublin Core metadata

### Implementation Checklist

- [ ] Phase 0: Count entities before loading
- [ ] Phase 1: Load ALL entities completely (no truncation)
- [ ] Phase 2: Verify count matching (loaded = expected)
- [ ] Phase 3: Log verification checkpoint
- [ ] Phase 4: Halt if verification fails
- [ ] Phase 5: Process only after verification passes
- [ ] All outputs grounded in loaded data only
- [ ] Validate entity existence before linking
- [ ] Use explicit fallback (never fabricate)
- [ ] Include complete provenance metadata
- [ ] Log all entity creation with audit trail
- [ ] Validate wikilinks reference actual files

---

## Pattern 6: Wikilink Generation Protocol

**Definition:** MANDATORY steps for ALL agents generating wikilinks to ensure format validation, entity existence, and prevention of common LLM generation artifacts.

### Why This Pattern Exists

LLMs naturally generate broken wikilinks in three ways:
1. **JSON Escaping Artifacts**: Trailing backslashes from `[[path\]]` instead of `[[path]]`
2. **Entity Fabrication**: Inventing entity IDs without checking `entity-index.json`
3. **Format Violations**: Adding `.md` extensions, missing directory prefixes, trailing spaces

### Implementation (4 Steps)

**Step 1: Load Entity Index**

Always read the entity index BEFORE generating any wikilinks:

```bash
# Load entity index to verify IDs exist
if [ ! -f "${PROJECT_PATH}/.metadata/entity-index.json" ]; then
  log_conditional ERROR "entity-index.json not found"
  exit 1
fi

# Extract available entity IDs by type
jq -r '.entities[] | select(.type == "source") | .id' \
  "${PROJECT_PATH}/.metadata/entity-index.json" > /tmp/source-ids.txt
```

**Step 2: Never Fabricate Entity IDs**

- Every ID in wikilink MUST exist in `entity-index.json`
- If entity doesn't exist yet: create entity first, THEN wikilink
- NEVER guess or approximate entity IDs

**Step 3: Format Validation Checklist**

Validate EVERY wikilink matches this pattern:

```bash
# Pattern: [[NN-type/data/slug-hash]]
# Example: [[05-sources/data/source-pnas-d25bff0d]]

# Validation regex
WIKILINK_PATTERN='^\[\[[0-9]{2}-[a-z-]+/data/[a-z0-9-]+\]\]$'

if ! echo "$wikilink" | grep -qE "$WIKILINK_PATTERN"; then
  log_conditional ERROR "Invalid wikilink format: $wikilink"
  exit 1
fi
```

**Format Requirements:**

- Pattern: `[[NN-type/data/slug-hash]]`
- NO trailing backslash: `[[...\]]` -- FORBIDDEN
- NO trailing space: `[[... ]]` -- FORBIDDEN
- NO file extension: `[[....md]]` -- FORBIDDEN
- NO escaped characters
- Directory prefix REQUIRED (`05-sources/data/`)

**Step 4: Pre-Generation Test**

Before returning entity with wikilinks:

```bash
# Extract all wikilinks from entity content
WIKILINKS=$(grep -o '\[\[[^]]*\]\]' "$entity_file")

# Validate each wikilink
while IFS= read -r link; do
  # Remove [[ and ]] to get path
  path=$(echo "$link" | sed 's/\[\[\(.*\)\]\]/\1/')

  # Check for trailing backslash (common LLM artifact)
  if echo "$link" | grep -q '\\]]'; then
    echo "ERROR: Trailing backslash in wikilink: $link" >&2
    exit 1
  fi

  # Check entity exists
  if [ ! -f "${PROJECT_PATH}/${path}.md" ]; then
    echo "ERROR: Entity not found: ${path}.md" >&2
    exit 1
  fi
done <<< "$WIKILINKS"
```

### Entity Directory Mapping (v1.0.0)

| Entity Type | Directory Prefix | Example Wikilink |
|-------------|-----------------|------------------|
| Initial Question | `00-initial-question/data/` | `[[00-initial-question/data/question-initial-f7ef12b8]]` |
| Dimension | `01-research-dimensions/data/` | `[[01-research-dimensions/data/dimension-economic-a7f3b2c1]]` |
| Refined Question | `02-refined-questions/data/` | `[[02-refined-questions/data/question-market-size-b2c3d4e5]]` |
| Query Batch | `03-query-batches/data/` | `[[03-query-batches/data/batch-dim1-q3-c4d5e6f7]]` |
| Finding | `04-findings/data/` | `[[04-findings/data/finding-renewable-12345678]]` |
| Source | `05-sources/data/` | `[[05-sources/data/source-pnas-d25bff0d]]` |
| Claim | `06-claims/data/` | `[[06-claims/data/claim-climate-action-f1e2d3c4]]` |

### Integration with Existing Patterns

Wikilink Generation Protocol extends **Pattern 5 (Provenance Integrity)**:

- Pattern 5 validates wikilinks reference actual files
- Pattern 6 prevents wikilinks from being malformed in the first place
- Together: Complete wikilink validation (format + existence)

### Implementation Checklist

Before ANY agent creates entities with wikilinks:

- [ ] Load `entity-index.json` to get available entity IDs
- [ ] Verify every entity ID exists in index before using
- [ ] Validate wikilink format matches `[[NN-type/data/slug-hash]]`
- [ ] Check for trailing backslash (LLM JSON escaping artifact)
- [ ] Check for trailing space (formatting artifact)
- [ ] Check for `.md` extension (path completion artifact)
- [ ] Verify directory prefix present (not bare ID)
- [ ] Test entity file exists at wikilink path
- [ ] Log validation results for audit trail

---

## Summary

**Anti-hallucination foundations prevent fabrication through:**

1. Complete Entity Loading - No truncation, verified counts
2. Verification Checkpoints - Mandatory validation before proceeding
3. Evidence-Based Processing - All outputs grounded in loaded data
4. No Fabrication Rule - Explicit fallback instead of invention
5. Provenance Integrity - Validated links, complete audit trails
6. **Wikilink Generation Protocol** - Format validation, entity existence, artifact prevention

**Key Takeaway:** Hallucination occurs when agents process incomplete data or invent plausible content. Prevention requires systematic enforcement of complete loading, verification, and evidence-based operations at every phase boundary. **Wikilink validation prevents broken links from LLM generation artifacts and entity ID fabrication.**

**Implementation Priority:** Start with Pattern 1 (Complete Loading) and Pattern 2 (Verification Checkpoints) to prevent hallucination at the source. Patterns 3-5 provide defense-in-depth for processing and output validation. **Pattern 6 (Wikilink Protocol) prevents broken links at generation time.**
