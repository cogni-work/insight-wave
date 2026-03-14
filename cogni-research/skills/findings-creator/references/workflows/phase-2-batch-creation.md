---
reference: phase-2-batch-creation
version: 7.0.0
checksum: phase-2-batch-creation-v7.0.0-portable-cot
dependencies: [create-entity.sh]
phase: 2
architecture: llm-control
changelog: |
  v7.0.0: PORTABLE COT - Added bash portability (wc -c), COT reasoning protocol, consolidated validation steps
  v6.0.0: TWO-PHASE COMMIT - Create batch in .staging/, validate, then atomic promotion to production
  v5.4.0: CONFIG VALIDATION - Add Step 2.3.5 config count gate, enhance Step 2.5 structure validation
---

# Phase 2: Batch Creation Workflow

**Checksum:** `phase-2-batch-creation-v7.0.0-portable-cot`

Output this checksum after reading to confirm reference loading.

---

## Purpose

Create a query-batch entity in `03-query-batches/data/` containing:

1. **search_configs[]** array with UUID-based config IDs and WebSearch parameters
2. **PICOT metadata** for finding relevance scoring
3. **Temporal constraints** for source date filtering
4. **⛔ MANDATORY: question_ref wikilink** for evidence chain integrity

---

## Chain-of-Thought Protocol

This phase requires explicit reasoning before batch creation. Use the **REASON → BUILD → VERIFY** pattern:

| Step       | Action                                                 | Output                   |
|------------|--------------------------------------------------------|--------------------------|
| **REASON** | Analyze configs from Phase 1, plan batch structure     | Internal reasoning block |
| **BUILD**  | Construct frontmatter and body with explicit decisions | Batch entity content     |
| **VERIFY** | Validate against requirements before promotion         | Verification assertion   |

**Reasoning Block Format:**

```markdown
<reasoning>
**Analyzing:** [What configs/data am I processing?]
**Observations:** [What patterns do I see in the search_configs?]
**Decisions:** [How will I structure frontmatter and body?]
**Conclusion:** [Ready to build batch with X configs]
</reasoning>
```

⚠️ **CRITICAL:** Output reasoning block before Step 2.3 (Build Frontmatter). Skipping reasoning leads to incomplete batch entities.

---

## ⛔ CRITICAL: Wikilink Requirements

**Every query-batch entity MUST contain:**

1. **Frontmatter:** `question_ref: "[[02-refined-questions/data/{question_id}]]"` (top-level, not nested)
2. **Body:** `**Refined Question**: [[02-refined-questions/data/{question_id}]]` (first line after H1)

**Without these wikilinks, the entity is ORPHANED and breaks synthesis.**

---

## Prohibited Patterns

**Frontmatter:**

- `dimension_ref:` - Query batches do NOT link to dimensions
- `refined_question_ref:` - Wrong field (use `question_ref`)
- Nested `question_ref` under `batch:` - Must be top-level

**Body:**

- `**Research Dimension**: [[...]]` - Query batches do NOT display dimension links
- Raw JSON arrays (e.g., `[{"query_id":...}]`) - Configs go in YAML frontmatter only
- Unrendered config placeholders

---

## Step 0.5: Initialize Phase 2 TodoWrite

```text
- Phase 2, Step 2.1: Generate UUID-based config_id values [in_progress]
- Phase 2, Step 2.2: Construct search_configs[] array [pending]
- Phase 2, Step 2.3: Build frontmatter and markdown body [pending]
- Phase 2, Step 2.3.5: Validate config count (minimum 4) [pending]
- Phase 2, Step 2.4: Create entity in STAGING [pending]
- Phase 2, Step 2.4.5: Deep validation gate [pending]
- Phase 2, Step 2.4.6: Atomic promotion to production [pending]
- Phase 2, Step 2.5: Verify entity and export references [pending]
```

---

## Step 2.1: Generate Config Identifiers

Generate deterministic UUID-based config_id for each search configuration.

**Algorithm:**

1. Concatenate: `{refined_question_id}-{profile}`
2. Compute SHA-256 hash
3. Format: `config-{8chars}-{4chars}-{4chars}-{4chars}-{12chars}`

| Input | Output |
|-------|--------|
| `market-q1` + `general` | `config-a1b2c3d4-e5f6-7890-abcd-ef1234567890` |

**Why UUID format:** Guaranteed uniqueness, reproducible (same input = same ID), schema v3.0.0 compliant.

Mark Step 2.1 completed.

---

## Step 2.2: Construct search_configs[] Array

Build JSON array with **exact WebSearch API structure**.

**For each config:**

```json
{
  "config_id": "config-{uuid}",
  "refined_question_id": "{from input}",
  "profile": "general|localized|industry|academic",
  "tier": 1,
  "query_text": "{verbatim question text}",
  "websearch_params": {
    "query": "{optimized search query with temporal modifiers}",
    "allowed_domains": ["reuters.com", "bloomberg.com"],
    "blocked_domains": ["pinterest.com", "facebook.com"]
  },
  "picot_source": "population|intervention|comparison|outcome|timeframe|null",
  "temporal_constraint": {
    "max_source_age_months": 12,
    "required_years": ["2024", "2025"]
  }
}
```

### WebSearch API Constraints

| Parameter         | Type     | Constraints                                            |
|-------------------|----------|--------------------------------------------------------|
| `query`           | string   | Max ~2000 chars. Include years for temporal filtering. |
| `allowed_domains` | string[] | Domain names only, **no HTTP/HTTPS scheme**.           |
| `blocked_domains` | string[] | Domain names only, **no HTTP/HTTPS scheme**.           |

### Mutual Exclusivity Rule

Each config uses **EITHER** `allowed_domains` **OR** `blocked_domains`, **never both**.

```json
// ✅ CORRECT - blocked domains
{"websearch_params": {"query": "...", "blocked_domains": ["pinterest.com"]}}

// ✅ CORRECT - allowed domains
{"websearch_params": {"query": "...", "allowed_domains": ["reuters.com"]}}

// ❌ WRONG - both (WebSearch will fail)
{"websearch_params": {"query": "...", "allowed_domains": [...], "blocked_domains": [...]}}
```

Mark Step 2.2 completed.

---

## Step 2.3: Build Frontmatter and Markdown Body

**⚠️ COT REQUIRED:** Output reasoning block before building.

```markdown
<reasoning>
**Analyzing:** Building batch for question "{REFINED_QUESTION_ID}"
**Observations:**
- Config count: {N} configs from Phase 1
- Profiles: {list profiles}
- Language detected: {language}
**Decisions:**
- Tags: [query-batch, research-batch, {language}]
- question_ref: [[02-refined-questions/data/{question_id}]]
- Body will render all {N} configs as ### sections
**Conclusion:** Ready to build frontmatter + body
</reasoning>
```

### Frontmatter Structure

```json
{
  "tags": ["query-batch", "research-batch", "{language}"],
  "dc:creator": "Claude (findings-creator)",
  "dc:title": "Query Batch: {batch_id}",
  "dc:identifier": "{batch_id}",
  "dc:created": "{ISO 8601 timestamp}",
  "entity_type": "query-batch",
  "batch_id": "{refined_question_id}-batch",
  "query_text": "{verbatim question}",
  "language": "{detected language}",
  "config_count": {number},
  "search_configs": [{array from Step 2.2}],
  "picot": {"population": "...", "intervention": "...", "comparison": "...", "outcome": "...", "timeframe": "..."},
  "temporal_constraints": {"max_source_age_months": 12, "required_years": ["2024", "2025"]},
  "question_ref": "[[02-refined-questions/data/{question_id}]]",
  "schema_version": "3.0.0"
}
```

**Critical Requirements:**

1. **`tags`** first field, includes `query-batch`, `research-batch`, language code
2. **`question_ref`** top-level with full wikilink syntax

### Markdown Body Template

**⛔ MANDATORY:** Render ALL configs. No placeholders.

```markdown
# Query Batch: {batch_id}

**Refined Question**: [[02-refined-questions/data/{question_id}]]

**Query Text**: "{verbatim_question}"

## Search Configurations

### Config 1: {profile}
- **Config ID**: {config_id}
- **Profile**: {profile}
- **Query**: "{query_text}"
- **Domains**: {allowed_domains or blocked_domains list}

### Config 2: {profile}
[Render ALL configs - never truncate]
```

Mark Step 2.3 completed.

---

## Step 2.3.5: Validate Config Count (GATE)

**⛔ GATE CHECK:** Verify search_configs array has minimum entries.

```bash
# Minimum 4 configs required
if [ -z "${CONFIG_COUNT:-}" ]; then
  echo "ERROR: CONFIG_COUNT not set" >&2
  exit 121
fi

if [ "$CONFIG_COUNT" -lt 4 ]; then
  echo "ERROR: Insufficient configs: $CONFIG_COUNT (minimum 4)" >&2
  exit 121
fi

if [ "$CONFIG_COUNT" -gt 7 ]; then
  echo "WARNING: Too many configs: $CONFIG_COUNT (max 7 expected)" >&2
fi
```

Mark Step 2.3.5 completed.

---

## Step 2.4: Create Entity in STAGING (Two-Phase Commit)

**⛔ CRITICAL:** Create in `.staging/` first, validate, then promote.

```bash
# Resolve directories (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DATA_SUBDIR="$(get_data_subdir)"

# Create staging directory
mkdir -p "${PROJECT_PATH}/$DIR_QUERY_BATCHES/$DATA_SUBDIR/.staging"

# Build and write to staging
STAGING_ENTITY_PATH="${PROJECT_PATH}/$DIR_QUERY_BATCHES/$DATA_SUBDIR/.staging/${batch_id}.md"
printf '%s\n' "$ENTITY_CONTENT" > "$STAGING_ENTITY_PATH"

# Verify (portable file size check)
if [ ! -f "$STAGING_ENTITY_PATH" ]; then
  echo "FATAL: Failed to create staging file" >&2
  exit 122
fi

FILE_SIZE=$(wc -c < "$STAGING_ENTITY_PATH" | tr -d ' ')
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Staging file too small ($FILE_SIZE bytes)" >&2
  rm -f "$STAGING_ENTITY_PATH"
  exit 122
fi

export STAGING_ENTITY_PATH
```

Mark Step 2.4 completed.

---

## Step 2.4.5: Deep Validation Gate (BLOCKING)

**⛔ GATE CHECK:** Validate staging file before promotion. If ANY check fails, delete and exit.

```bash
STAGING_FILE="$STAGING_ENTITY_PATH"

# Validation 1: File exists with sufficient content
if [ ! -f "$STAGING_FILE" ]; then
  echo "FATAL: Staging file not found" >&2
  exit 122
fi

FILE_SIZE=$(wc -c < "$STAGING_FILE" | tr -d ' ')
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "FATAL: File too small ($FILE_SIZE bytes)" >&2
  rm -f "$STAGING_FILE"
  exit 122
fi

# Validation 2: Config count ≥4
CONFIG_COUNT=$(grep -c 'config_id:' "$STAGING_FILE" 2>/dev/null || echo 0)
if [ "$CONFIG_COUNT" -lt 4 ]; then
  echo "FATAL: Insufficient configs ($CONFIG_COUNT < 4)" >&2
  rm -f "$STAGING_FILE"
  exit 122
fi

# Validation 3: question_ref wikilink present
if ! grep -q 'question_ref:.*\[\[02-refined-questions/data/[^]]*\]\]' "$STAGING_FILE"; then
  echo "FATAL: Missing question_ref wikilink" >&2
  rm -f "$STAGING_FILE"
  exit 122
fi

# Validation 4: Body wikilink present
if ! grep -q '\*\*Refined Question\*\*:.*\[\[02-refined-questions/data/' "$STAGING_FILE"; then
  echo "FATAL: Missing body wikilink" >&2
  rm -f "$STAGING_FILE"
  exit 122
fi

echo "Staging validation PASSED: $CONFIG_COUNT configs" >&2
```

### Validation Checklist

| Check                | Requirement                     | Exit |
|----------------------|---------------------------------|------|
| File size            | ≥500 bytes                      | 122  |
| Config count         | ≥4 configs                      | 122  |
| Frontmatter wikilink | `question_ref: [[...]]`         | 122  |
| Body wikilink        | `**Refined Question**: [[...]]` | 122  |

Mark Step 2.4.5 completed.

---

## Step 2.4.6: Atomic Promotion to Production

**⛔ CRITICAL:** Atomic move from staging to production.

```bash
# Resolve production path
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DATA_SUBDIR="$(get_data_subdir)"

PRODUCTION_FILE="${PROJECT_PATH}/$DIR_QUERY_BATCHES/$DATA_SUBDIR/${batch_id}.md"

# Atomic move
mv "$STAGING_ENTITY_PATH" "$PRODUCTION_FILE"

# Verify promotion
if [ ! -f "$PRODUCTION_FILE" ]; then
  echo "FATAL: Promotion failed" >&2
  exit 122
fi

# Cleanup any leftover staging file
[ -f "$STAGING_ENTITY_PATH" ] && rm -f "$STAGING_ENTITY_PATH"

# Export for downstream phases
export BATCH_FILE="$DIR_QUERY_BATCHES/$DATA_SUBDIR/${batch_id}.md"
export BATCH_ID="${batch_id}"
```

Mark Step 2.4.6 completed.

---

## Step 2.5: Verify Entity and Export References

**⛔ GATE CHECK:** Deep content validation and reference export.

### Self-Verification Questions (answer YES to all)

1. Does entity contain `tags:` array in YAML? YES/NO
2. Does `tags:` include `query-batch`, `research-batch`, language? YES/NO
3. Does entity contain `question_ref:` in YAML? YES/NO
4. Does body start with `**Refined Question**: [[...]]`? YES/NO
5. Are ALL configs rendered as `### Config N:` sections? YES/NO
6. Is body free of raw JSON arrays? YES/NO
7. Do ALL config_ids start with `{REFINED_QUESTION_ID}-`? YES/NO

**If ANY NO:** Fix entity before proceeding.

### Config Structure Validation

```bash
#!/usr/bin/env bash
set -eo pipefail

BATCH_FILE="${PROJECT_PATH}/03-query-batches/data/${BATCH_ID}.md"
VALIDATION_ERRORS=0

CONFIG_COUNT=$(grep -c 'config_id:' "$BATCH_FILE" || echo 0)
if [ "$CONFIG_COUNT" -lt 4 ]; then
  echo "ERROR: Insufficient configs: $CONFIG_COUNT" >&2
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Verify naming convention
EXPECTED_FILENAME="${REFINED_QUESTION_ID}-batch.md"
ACTUAL_FILENAME=$(basename "$BATCH_FILE")
if [ "$ACTUAL_FILENAME" != "$EXPECTED_FILENAME" ]; then
  echo "ERROR: Filename mismatch: $ACTUAL_FILENAME vs $EXPECTED_FILENAME" >&2
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ $VALIDATION_ERRORS -gt 0 ]; then
  exit 122
fi
```

### Export Batch Reference Variables

```bash
# Export for Phase 3 and Phase 4
export BATCH_ID="${batch_id}"
export BATCH_FILE="03-query-batches/data/${batch_id}.md"
export BATCH_QUESTION_REF="[[02-refined-questions/data/${question_id}]]"
export BATCH_CONFIG_COUNT="${config_count}"

# Verify exports
if [ -z "${BATCH_ID:-}" ] || [ -z "${BATCH_FILE:-}" ]; then
  echo "FATAL: Batch reference variables not set" >&2
  exit 122
fi

log_conditional INFO "Batch exported: BATCH_ID=${BATCH_ID}"
```

### ⛔ Write Tool Prohibition

If create-entity.sh fails, FAIL the phase. NEVER use Write tool for entity files - it bypasses validation, locking, and index updates.

Mark Step 2.5 completed. Mark Phase 2 phase-level todo completed.

---

## Phase 2 Completion Checklist

**Core Requirements:**

- [ ] All config_ids use UUID format
- [ ] search_configs[] has 4-7 entries
- [ ] question_ref wikilink in frontmatter
- [ ] **Refined Question** wikilink in body
- [ ] All configs rendered in body (no placeholders)

**Validation:**

- [ ] Staging → Production promotion successful
- [ ] File size ≥500 bytes
- [ ] Config ID prefix matches REFINED_QUESTION_ID
- [ ] BATCH_ID and BATCH_FILE exported

---

## Expected Outputs

| Output | Location | Validation |
|--------|----------|------------|
| Query batch entity | `03-query-batches/data/{batch_id}.md` | >500 bytes |
| search_configs[] | Entity frontmatter | UUID format, 4-7 count |
| BATCH_ID | Environment variable | Non-empty |
| BATCH_FILE | Environment variable | Non-empty |
| BATCH_QUESTION_REF | Environment variable | Contains wikilink |

---

## Complete Example

**File:** `03-query-batches/data/question-ki-anwendungen-produktion-v5w6x7y8-batch.md`

```yaml
---
tags: [query-batch, research-batch, de]
dc:creator: Claude (findings-creator)
dc:title: "Query Batch: question-ki-anwendungen-produktion-v5w6x7y8-batch"
dc:identifier: "question-ki-anwendungen-produktion-v5w6x7y8-batch"
dc:created: 2025-12-01T10:00:00.000Z
entity_type: query-batch
batch_id: question-ki-anwendungen-produktion-v5w6x7y8-batch
question_id: question-ki-anwendungen-produktion-v5w6x7y8
queries_count: 4
query_text: "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?"
language: de
config_count: 4
question_ref: "[[02-refined-questions/data/question-ki-anwendungen-produktion-v5w6x7y8]]"
search_configs:
  - config_id: "config-a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    profile: "general"
    tier: 1
    websearch_params:
      query: "KI-Anwendungen Produktion Maschinenbau 2024 2025"
      blocked_domains: ["pinterest.com", "facebook.com"]
  - config_id: "config-b2c3d4e5-f6a7-8901-bcde-f12345678901"
    profile: "technical"
    tier: 1
    websearch_params:
      query: "Machine Learning Prozessoptimierung Maschinenbau"
      allowed_domains: ["linkedin.com", "researchgate.net"]
  - config_id: "config-c3d4e5f6-a7b8-9012-cdef-012345678902"
    profile: "industry"
    tier: 1
    websearch_params:
      query: "KI Mittelstand Maschinenbau Use-Cases"
      allowed_domains: ["handelsblatt.com", "ifo.de"]
  - config_id: "config-d4e5f6a7-b8c9-0123-defa-123456789012"
    profile: "academic"
    tier: 1
    websearch_params:
      query: "artificial intelligence manufacturing 2024"
      allowed_domains: ["scholar.google.com", "ieee.org"]
schema_version: "3.0.0"
---

# Query Batch: question-ki-anwendungen-produktion-v5w6x7y8-batch

**Refined Question**: [[02-refined-questions/data/question-ki-anwendungen-produktion-v5w6x7y8]]

**Query Text**: "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?"

## Search Configurations

### Config 1: general
- **Config ID**: config-a1b2c3d4-e5f6-7890-abcd-ef1234567890
- **Profile**: general
- **Query**: "KI-Anwendungen Produktion Maschinenbau 2024 2025"
- **Domains**: blocked: pinterest.com, facebook.com

### Config 2: technical
- **Config ID**: config-b2c3d4e5-f6a7-8901-bcde-f12345678901
- **Profile**: technical
- **Query**: "Machine Learning Prozessoptimierung Maschinenbau"
- **Domains**: allowed: linkedin.com, researchgate.net

### Config 3: industry
- **Config ID**: config-c3d4e5f6-a7b8-9012-cdef-012345678902
- **Profile**: industry
- **Query**: "KI Mittelstand Maschinenbau Use-Cases"
- **Domains**: allowed: handelsblatt.com, ifo.de

### Config 4: academic
- **Config ID**: config-d4e5f6a7-b8c9-0123-defa-123456789012
- **Profile**: academic
- **Query**: "artificial intelligence manufacturing 2024"
- **Domains**: allowed: scholar.google.com, ieee.org
```

---

## Anti-Pattern Examples (DO NOT CREATE)

**❌ Raw JSON in body:**

```markdown
[{"query_id":"smart-products-001","type":"general"}]
```

**❌ Missing wikilinks:**

```yaml
# MISSING: question_ref field
```

**❌ Simplified question_id:**

```yaml
# ❌ WRONG - simplified ID
question_ref: "[[02-refined-questions/data/datenkultur-data-literacy]]"
# ✅ CORRECT - exact filename
question_ref: "[[02-refined-questions/data/question-datenkultur-data-literacy-s3t4u5v6]]"
```

**Rule:** `{question_id}` MUST be `$(basename "${REFINED_QUESTION_PATH}" .md)` - exact filename without extension.

---

## See Also

- [phase-1-query-optimization.md](phase-1-query-optimization.md) - Previous phase (generates SEARCH_CONFIGS)
- [phase-3-search-execution.md](phase-3-search-execution.md) - Next phase
