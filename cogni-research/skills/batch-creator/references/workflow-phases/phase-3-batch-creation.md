---
reference: phase-3-batch-creation
version: 1.2.0
checksum: phase-3-batch-creation-v1.2.0-batch-creator
dependencies: [phase-2-query-optimization]
phase: 3
---

# Phase 3: Batch Creation (Per Question)

**Checksum:** `phase-3-batch-creation-v1.2.0-batch-creator`

---

## Purpose

Create query-batch entity for current question using `create-entity.sh` script (handles atomic writes, validation, and index registration).

---

## HARD CONSTRAINT: Write Tool Prohibition

**CRITICAL**: Entity files MUST be created via `create-entity.sh` or `create-entity.py` scripts ONLY.

**Prohibited**:

- Using Write tool directly to create entity files
- Using `echo >` or heredoc to create entity files
- Any file creation method that bypasses `create-entity.*` scripts

**Enforcement Pattern**:

```text
BEFORE any entity file creation:
  1. Verify create-entity.sh exists at ${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh
  2. Use ONLY the script invocation pattern below
  3. If script not found → HALT with exit 130 (path resolution failure)

IF Write tool is about to be used for entity creation:
  → HALT with exit 131 (anti-hallucination violation)
```

**Rationale**: Direct file writes bypass schema validation, index registration, and deduplication checks. This was the root cause of non-compliant entities in bone-marrow-stroma project.

---

## Step 3.1: Generate Config IDs

Generate UUID-based config_id for each search config:

```bash
# For each config in SEARCH_CONFIGS
CONFIG_ID="config-$(echo -n "${QUESTION_ID}-${PROFILE}" | shasum -a 256 | cut -c1-8)-$(echo -n "${QUESTION_ID}-${PROFILE}" | shasum -a 256 | cut -c9-12)-$(echo -n "${QUESTION_ID}-${PROFILE}" | shasum -a 256 | cut -c13-16)-$(echo -n "${QUESTION_ID}-${PROFILE}" | shasum -a 256 | cut -c17-20)-$(echo -n "${QUESTION_ID}-${PROFILE}" | shasum -a 256 | cut -c21-32)"
```

---

## Step 3.2: Build Frontmatter

**Required fields:**

```yaml
---
tags: [query-batch, research-batch, {language}]
dc:creator: "Claude (batch-creator)"
dc:title: "Query Batch: {batch_id}"
dc:identifier: "{batch_id}"
dc:created: "{ISO 8601 timestamp}"
entity_type: query-batch
batch_id: "{question_id}-batch"
question_id: "{question_id}"
query_text: "{verbatim question}"
language: "{detected}"
config_count: {number}
queries_count: {number}
question_ref: "[[02-refined-questions/data/{question_id}]]"
search_configs:
  - config_id: "config-{uuid}"
    profile: "general"
    tier: 1
    websearch_params:
      query: "{optimized query}"
      blocked_domains: ["pinterest.com"]
schema_version: "3.0.0"
---
```

**Critical Fields:**

- `question_id`: MUST be the base question ID (without `-batch` suffix) for README linkage
- `queries_count`: MUST equal `config_count` - required by generate-query-batches-readme.sh
- `question_ref`: MUST be at top level with wikilink syntax

---

## Step 3.3: Build Markdown Body

```markdown
# Query Batch: {batch_id}

**Refined Question**: [[02-refined-questions/data/{question_id}]]

**Query Text**: "{verbatim_question}"

## Search Configurations

### Config 1: {profile}
- **Config ID**: {config_id}
- **Profile**: {profile}
- **Query**: "{query_text}"
- **Domains**: {allowed|blocked list}

### Config 2: {profile}
...
```

**MUST render ALL configs.** No placeholders.

---

## Step 3.4: Create Entity via Script

**MANDATORY:** Use `create-entity.sh` for entity creation. This script handles:

- Atomic file writes (no partial files)
- Schema validation via `validate-query-batch-schema.sh`
- Entity index registration
- UUID generation and deduplication

### 3.4.1: Build JSON Payload via Python

**CRITICAL:** Use Python for JSON construction to avoid shell escaping issues. Bash heredocs fail on zsh with complex JSON.

Write a temp Python script that constructs the JSON and invokes create-entity.sh:

```bash
cat > /tmp/create-batch.py << 'PYEOF'
#!/usr/bin/env python3
import json
import subprocess
import sys
import os

# Read environment variables passed from bash
PROJECT_PATH = os.environ.get('PROJECT_PATH', '')
BATCH_ID = os.environ.get('BATCH_ID', '')
QUESTION_ID = os.environ.get('QUESTION_ID', '')
QUERY_TEXT = os.environ.get('QUERY_TEXT', '')
LANGUAGE = os.environ.get('LANGUAGE', 'en')
CONFIG_COUNT = int(os.environ.get('CONFIG_COUNT', '0'))
SEARCH_CONFIGS_JSON = os.environ.get('SEARCH_CONFIGS_JSON', '[]')
MARKDOWN_BODY = os.environ.get('MARKDOWN_BODY', '')
CLAUDE_PLUGIN_ROOT = os.environ.get('CLAUDE_PLUGIN_ROOT', '')

# Parse search_configs from JSON string
try:
    search_configs = json.loads(SEARCH_CONFIGS_JSON)
except json.JSONDecodeError:
    search_configs = []

# Build the entity data structure (flat format - create-entity.py auto-normalizes)
entity_data = {
    "tags": ["query-batch", "research-batch", LANGUAGE],
    "dc:creator": "Claude (batch-creator)",
    "dc:title": f"Query Batch: {BATCH_ID}",
    "dc:identifier": BATCH_ID,
    "entity_type": "query-batch",
    "batch_id": BATCH_ID,
    "question_id": QUESTION_ID,
    "query_text": QUERY_TEXT,
    "language": LANGUAGE,
    "config_count": CONFIG_COUNT,
    "queries_count": CONFIG_COUNT,
    "question_ref": f"[[02-refined-questions/data/{QUESTION_ID}]]",
    "search_configs": search_configs,
    "schema_version": "3.0.0",
    "content": MARKDOWN_BODY
}

# Write to temp file
temp_json = f"/tmp/batch-{BATCH_ID}-{os.getpid()}.json"
with open(temp_json, 'w') as f:
    json.dump(entity_data, f, ensure_ascii=False, indent=2)

# Invoke create-entity.sh
try:
    result = subprocess.run(
        [
            f"{CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh",
            "--project-path", PROJECT_PATH,
            "--entity-type", "03-query-batches",
            "--entity-id", BATCH_ID,
            "--data", f"@{temp_json}",
            "--json"
        ],
        capture_output=True,
        text=True
    )
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    sys.exit(result.returncode)
finally:
    if os.path.exists(temp_json):
        os.remove(temp_json)
PYEOF
chmod +x /tmp/create-batch.py
```

### 3.4.2: Invoke via Python Script

Export variables and run the Python script:

```bash
export PROJECT_PATH BATCH_ID QUESTION_ID QUERY_TEXT LANGUAGE CONFIG_COUNT SEARCH_CONFIGS_JSON MARKDOWN_BODY CLAUDE_PLUGIN_ROOT && python3 /tmp/create-batch.py
```

Parse the result:

```bash
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: create-entity.sh failed for ${BATCH_ID}" >&2
  BATCHES_FAILED=$((BATCHES_FAILED + 1))
else
  echo "Created batch: ${BATCH_ID}"
  BATCHES_CREATED=$((BATCHES_CREATED + 1))
  TOTAL_CONFIGS=$((TOTAL_CONFIGS + CONFIG_COUNT))
fi
```

### 3.4.3: Validation (Automatic)

The `create-entity.sh` script automatically:

| Check | Handled By |
| ----- | ---------- |
| File exists | `atomic_write()` in Python |
| Schema validation | `validate-query-batch-schema.sh` |
| Index registration | `add_entity_to_index()` |
| Config count ≥4 | Schema validation script |
| question_ref wikilink | Schema validation script |

**No manual validation required.** If `create-entity.sh` returns exit code 0, the entity is valid and registered.

---

## Step 3.5: Log Progress

```bash
log_conditional INFO "Processed batch: ${BATCH_ID} (${CONFIG_COUNT} configs)"
```

**Note:** Tracking counters (`BATCHES_CREATED`, `BATCHES_FAILED`, `TOTAL_CONFIGS`) are updated in Step 3.4.2 based on `create-entity.sh` exit code.

---

## Error Handling

Error handling is integrated into Step 3.4.2. On `create-entity.sh` failure:

1. Error is logged to stderr
2. `BATCHES_FAILED` counter incremented
3. Processing continues with next question (no halt)

**Common failure reasons:**

| Exit Code | Meaning | Resolution |
| --------- | ------- | ---------- |
| 1 | Validation error | Check frontmatter fields |
| 2 | Usage/argument error | Check JSON payload structure |
| 122 | Schema validation failed | Ensure ≥4 configs, valid wikilinks |

---

## Shell Compatibility Requirements

Claude Code executes bash via the user's default shell (often zsh). To avoid parse errors:

**PROHIBITED in inline bash:**

- Multi-line if/then/else/fi blocks
- Bash array assignments: `ARRAY=($(...))`
- Newlines between statements

**REQUIRED patterns:**

- Single-line conditionals: `[ -d "$DIR"] && echo "exists" || echo "missing"`
- Chain with &&: `mkdir -p "$DIR" && cd "$DIR" && pwd`
- For complex logic: Write to temp script file, then execute with `bash script.sh`

---

## Next Step

**After processing current question, the iteration loop continues automatically:**

```bash
# Update tracking counters (based on create-entity.sh exit code)
if [ $EXIT_CODE -eq 0 ]; then
    BATCHES_CREATED=$((BATCHES_CREATED + 1))
    TOTAL_CONFIGS=$((TOTAL_CONFIGS + CONFIG_COUNT))
    log_conditional INFO "Created batch: ${BATCH_ID} (${CONFIG_COUNT} configs)"
else
    BATCHES_FAILED=$((BATCHES_FAILED + 1))
    log_conditional ERROR "Failed to create batch for ${QUESTION_ID}"
fi

# Increment loop counter (MANDATORY)
QUESTION_INDEX=$((QUESTION_INDEX + 1))

# Log progress
log_conditional INFO "Progress: ${QUESTION_INDEX}/${QUESTIONS_TOTAL} questions processed"
```

**Loop Control (Automatic):**

- If `QUESTION_INDEX < QUESTIONS_TOTAL`: The while loop continues → Return to Phase 2 for next question
- If `QUESTION_INDEX >= QUESTIONS_TOTAL`: The while loop exits → Proceed to Phase 4

**CRITICAL: Do NOT manually decide to "proceed to Phase 4"** - the loop exit condition handles this automatically. Only exit the loop when ALL questions have been processed.
