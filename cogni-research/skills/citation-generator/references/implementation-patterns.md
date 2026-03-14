# Implementation Patterns

## Purpose

Bash implementation patterns extracted from citation-generator agent for use in citation-planner skill implementation. These patterns ensure robust parameter parsing, working directory management, YAML parsing, error handling, and JSON response generation.

---

## ⚠️ Bash Syntax Requirements (MANDATORY)

**Before generating any bash code, you MUST follow these rules:**

1. **Command separation:** Every command on its own line (or separated by `;`)
2. **Integer arithmetic:** Use `$(( ))` not `| bc` for partition calculations
3. **Variable names:** Use EXACT names from patterns below (e.g., `START_INDEX`, `END_INDEX`)

**Full rules:** `../../references/shared-bash-patterns.md` Section 5

---

## Parameter Parsing

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 1

## Working Directory Validation

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 2

## Logging

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 3

## YAML Parsing

### Safe Patterns

**CRITICAL:** Always use `grep + sed` (NOT `grep` alone).

```bash
# Extract field values properly
TITLE=$(grep "^title:" "$SOURCE_FILE" | head -1 | sed 's/^title:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")
URL=$(grep "^url:" "$SOURCE_FILE" | head -1 | sed 's/^url:[[:space:]]*//' | sed 's/"//g')
DOMAIN=$(grep "^domain:" "$SOURCE_FILE" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')
TIER=$(grep "^reliability_tier:" "$SOURCE_FILE" | head -1 | sed 's/^reliability_tier:[[:space:]]*//')
DOI=$(grep "^doi:" "$SOURCE_FILE" | head -1 | sed 's/^doi:[[:space:]]*//' | sed 's/"//g')
PMID=$(grep "^pmid:" "$SOURCE_FILE" | head -1 | sed 's/^pmid:[[:space:]]*//' | sed 's/"//g')
ACCESS_DATE=$(grep "^access_date:" "$SOURCE_FILE" | head -1 | sed 's/^access_date:[[:space:]]*//' | sed 's/"//g')
```

### Value Extraction

Pattern breakdown:
1. `grep "^field:"` → Find line starting with field name
2. `head -1` → Take first match only
3. `sed 's/^field:[[:space:]]*//'` → Remove field name and whitespace
4. `sed 's/"//g'` → Remove double quotes
5. `sed "s/'//g"` → Remove single quotes

### Artifact Detection

**CRITICAL:** Validate extracted values don't contain YAML artifacts:

```bash
# Validate extracted values don't contain YAML artifacts
if [ "$DOMAIN" == *":"* ]] || [ "$DOMAIN" == *"domain:"* ]; then
  echo "ERROR: Extracted domain contains YAML artifacts: $DOMAIN (source: $source_id)" >&2
  continue
fi

if [ "$TITLE" == *"title:"* ]] || [ "$TITLE" == *"Obsidian"* ]; then
  echo "ERROR: Extracted title contains YAML artifacts: $TITLE (source: $source_id)" >&2
  continue
fi

if [ "$URL" == *"url:"* ]] || [ "$URL" == *"source_url:"* ]; then
  echo "ERROR: Extracted URL contains YAML artifacts: $URL (source: $source_id)" >&2
  continue
fi
```

### Why It Matters

Common mistakes:
- Using `grep` alone leaves "field: value" format
- Missing quote removal leaves `"value"` in output
- Missing validation allows corrupted data through
- Citation text contains literal "domain: example.com"

**Solution:** Always use grep+sed pattern and validate results.

### Examples

```bash
# Extract publisher name (handles single and double quotes)
publisher_name=$(grep "^name:" "$PUBLISHER_FILE" | head -1 | sed 's/^name:[[:space:]]*//' | sed 's/"//g' | sed "s/'//g")

# Extract publisher type
publisher_type=$(grep "^publisher_type:" "$PUBLISHER_FILE" | head -1 | sed 's/^publisher_type:[[:space:]]*//' | sed 's/"//g')

# Extract domain from source
publisher_domain=$(grep "^domain:" "$publisher_file" | head -1 | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')

# Extract reliability tier (numeric field, no quotes)
TIER=$(grep "^reliability_tier:" "$SOURCE_FILE" | head -1 | sed 's/^reliability_tier:[[:space:]]*//')

# Extract year from access date
YEAR=$(echo "$ACCESS_DATE" | cut -d'-' -f1)

# Extract domain from URL
source_domain=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|' | tr '[:upper:]' '[:lower:]' | sed 's/^www\.//')
```

## Publisher Loading with Retry (BUG-039 FIX)

### Race Condition Problem

When `citation-generator` and `publisher-generator` are invoked in parallel (or near-simultaneously), publishers may not exist yet when citation-generator tries to load them. Additionally, macOS filesystem caching can cause `find` to return stale results even after publishers are created.

### Solution: Retry with Exponential Backoff

```bash
# BUG-039 FIX: Publisher loading with retry and filesystem sync
# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_PUBLISHERS="$(get_directory_by_key "publishers")"
DATA_SUBDIR="$(get_data_subdir)"

MAX_RETRY_ATTEMPTS=3
RETRY_DELAY=2
PUBLISHER_COUNT=0

for attempt in $(seq 1 $MAX_RETRY_ATTEMPTS); do
  # Force filesystem sync (resolves macOS caching issues)
  sync 2>/dev/null || true

  # Count publishers
  PUBLISHER_COUNT=$(find "$PROJECT_PATH/$DIR_PUBLISHERS/$DATA_SUBDIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$PUBLISHER_COUNT" -gt 0 ]; then
    echo "Found $PUBLISHER_COUNT publishers on attempt $attempt" >&2
    break
  fi

  if [ "$attempt" -lt "$MAX_RETRY_ATTEMPTS" ]; then
    echo "WARNING: No publishers found, waiting ${RETRY_DELAY}s (attempt $attempt/$MAX_RETRY_ATTEMPTS)..." >&2
    sleep $RETRY_DELAY
    RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff: 2s, 4s
  fi
done

# CRITICAL: Verify publishers exist before proceeding
if [ "$PUBLISHER_COUNT" -eq 0 ]; then
  echo '{"success": false, "error": "No publishers loaded - publisher-generator may not have completed"}' >&2
  exit 1
fi
```

### Key Components

1. **`sync` command**: Forces filesystem to flush pending writes (critical for macOS)
2. **Exponential backoff**: 2s → 4s delays between retries (reduces load while waiting)
3. **Maximum attempts**: 3 retries before failing (prevents infinite loops)
4. **Clear error message**: Indicates publisher-generator dependency

### When to Use

- Before loading publishers for citation generation
- When skills may run in parallel with dependencies
- After any operation that creates files that another process reads

## Error Handling

### Error Scenarios

| Scenario | Detection | Recovery | Exit |
|----------|-----------|----------|------|
| Missing --project-path | Empty parameter | Return error JSON | 1 |
| Project directory not found | Directory check fails | Return error JSON | 1 |
| Working directory change fails | cd exit code ≠ 0 | Return error JSON | 1 |
| Sources directory missing | Directory check fails | Return error JSON | 1 |
| Publishers directory missing | Directory check fails | Return error JSON | 1 |
| Source count mismatch | Array length ≠ expected | Return error JSON | 1 |
| Publisher count mismatch | Array length ≠ expected | Return error JSON | 1 |
| No publishers loaded | Empty array at checkpoint | Return error JSON | 1 |
| Invalid partition parameter | Validation fails | Return error JSON | 1 |
| Source file not found | File existence check | Skip, warn stderr, continue | 0 |
| YAML artifact in extracted value | Validation check | Skip, log error, continue | 0 |
| Empty publisher_id (non-fallback) | Validation check | Skip, log error, continue | 0 |
| Citation text contains YAML artifacts | Validation check | Skip, log error, continue | 0 |
| No sources to process | Empty array (valid edge case) | Return success JSON (0 created) | 0 |

### JSON Error Responses

**Format:**
```bash
# Simple error
printf '{"success": false, "error": "Error message here"}\n'
exit 1

# Error with context
printf '{"success": false, "error": "Project directory not found: %s"}\n' "$PROJECT_PATH"
exit 1

# Inline error (no printf)
echo '{"success": false, "error": "Invalid partition: '"$PARTITION"'"}' >&2
exit 1
```

### Exit Codes

- **Exit 0:** Success OR recoverable error (entity skipped, processing continued)
- **Exit 1:** Fatal error (missing parameters, invalid directories, data integrity compromise)
- **Exit 2:** Reserved for future use

### Recovery Strategies

**Continue:** Skip problematic entity, log error, continue processing
```bash
if [ ! -f "$SOURCE_FILE" ]; then
  echo "WARNING: Source file not found: $SOURCE_FILE" >&2
  continue
fi
```

**Skip:** Skip entity without processing, increment skip counter
```bash
if [ -n "$EXISTING_CITATION" ]; then
  log_conditional DEBUG "Citation already exists for $source_id, skipping"
  echo "Citation already exists for $source_id ($(basename "$EXISTING_CITATION")), skipping..." >&2
  citations_skipped=$((citations_skipped + 1))
  continue
fi
```

**Halt:** Stop processing immediately, return error JSON
```bash
if [ ${#PUBLISHERS_LOADED[@]} -eq 0 ]; then
  log_conditional ERROR "No publishers loaded - cannot generate citations without publisher entities"
  echo '{"success": false, "error": "No publishers loaded - cannot generate citations without publisher entities"}' >&2
  exit 1
fi
```

## JSON Response Generation

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 4

### Citation-Specific Response Fields

The citation-generator skill extends the base JSON response pattern with these fields:

```json
{
  "success": true,
  "citations_created": 42,
  "citations_skipped": 2,
  "warnings": ["85% citations used domain_fallback - check publisher loading"],
  "publisher_matches": {
    "domain_exact": 28,
    "name_exact": 8,
    "reverse_index": 4,
    "domain_fallback": 2
  }
}
```

**Field Descriptions:**
- `citations_created`: Number of citation entities written
- `citations_skipped`: Number of citations skipped (already exist)
- `warnings`: Optional array of warning messages
- `publisher_matches`: Breakdown of publisher resolution strategy counts

## Bash Best Practices

### set -euo pipefail

**Usage:**
```bash
#!/bin/bash
set -euo pipefail

# Script continues...
```

**What it does:**
- `set -e`: Exit immediately if any command fails (non-zero exit code)
- `set -u`: Treat unset variables as errors
- `set -o pipefail`: Pipeline fails if any command in pipeline fails

**When to use:**
- Production scripts requiring strict error handling
- Scripts where silent failures are dangerous
- Data processing pipelines

**When NOT to use:**
- Interactive scripts
- Scripts with expected failures (use explicit error handling)
- Scripts relying on conditional execution (use `|| true` to allow failures)

### Variable Naming

**Conventions:**
```bash
# UPPERCASE for environment variables and constants
PROJECT_PATH="/Users/name/research"
AGENT_NAME="citation-generator"
LOG_FILE="${PROJECT_PATH}/.metadata/execution.log"

# lowercase for local variables
source_id="source-123"
publisher_name="Nature Publishing Group"
citation_count=42

# Readonly for constants that shouldn't change
readonly SCRIPT_VERSION="1.0.0"
readonly MAX_RETRIES=3
```

### Array Handling

**Declaration:**
```bash
# Empty array
SOURCES_TO_PROCESS=()
warnings_array=()

# Array with initial values
SUPPORTED_LANGUAGES=("en" "de" "fr")
```

**Iteration:**
```bash
# Iterate over array elements
for source_id in "${SOURCES_TO_PROCESS[@]}"; do
  echo "Processing: $source_id"
done

# Iterate over associative array keys
for source_id in "${!RESOLVED_CITATIONS[@]}"; do
  echo "Key: $source_id, Value: ${RESOLVED_CITATIONS[$source_id]}"
done
```

**Slicing:**
```bash
# Extract partition slice
# Format: ${array[@]:start_index:count}
SOURCES_TO_PROCESS=("${SOURCES_TO_PROCESS[@]:$START_IDX:$SOURCES_PER_PARTITION}")

# Example: Get elements 10-19 (10 elements starting at index 10)
PARTITION_SLICE=("${ALL_SOURCES[@]:10:10}")
```

**Adding elements:**
```bash
# Append to array
SOURCES_TO_PROCESS+=("$source_id")
warnings_array+=("Warning message here")
```

**Array length:**
```bash
# Get array length
count=${#SOURCES_TO_PROCESS[@]}

# Check if array is empty
if [ ${#SOURCES_TO_PROCESS[@]} -eq 0 ]; then
  echo "Array is empty"
fi
```

**Key-value lookups (Bash 3.2 compatible - parallel indexed arrays):**
```bash
# Bash 3.2 compatible key-value storage using parallel arrays
PUBLISHER_DOMAIN_KEYS=()
PUBLISHER_DOMAIN_VALUES=()

# Add key-value pairs
PUBLISHER_DOMAIN_KEYS+=("example.com")
PUBLISHER_DOMAIN_VALUES+=("publisher-123")
PUBLISHER_DOMAIN_KEYS+=("nature.com")
PUBLISHER_DOMAIN_VALUES+=("publisher-456")

# Lookup helper function
lookup_publisher() {
  local search_key="$1"
  local i=0
  for key in "${PUBLISHER_DOMAIN_KEYS[@]}"; do
    if [[ "$key" == "$search_key" ]]; then
      echo "${PUBLISHER_DOMAIN_VALUES[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  return 1
}

# Access value by key
publisher_id=$(lookup_publisher "$domain")

# Check if key exists
if lookup_publisher "$domain" >/dev/null 2>&1; then
  echo "Key exists"
fi

# Get number of keys
count=${#PUBLISHER_DOMAIN_KEYS[@]}
```

## Complete Examples

### Example 1: Multi-Strategy Matching

**Scenario:** 42 sources, 23 publishers

**Invocation:**

```bash
citation-planner --project-path /path/to/project --language en
```

**Process:**

1. Validate environment and working directory
2. Load 42 sources + 23 publishers completely
3. Verification: All entities loaded ✓
4. Build 4 lookup structures
5. Resolve publishers:
   - 28 matched via domain_exact
   - 8 matched via name_exact
   - 4 matched via reverse_index
   - 2 used domain_fallback
6. Write 40 citation entities (2 already existed)
7. Return JSON summary

**Response:**

```json
{
  "success": true,
  "citations_created": 40,
  "citations_skipped": 2,
  "publisher_matches": {
    "domain_exact": 28,
    "name_exact": 8,
    "reverse_index": 4,
    "domain_fallback": 2
  }
}
```

### Example 2: German Language Citations

**Invocation:**

```bash
citation-planner --project-path /path/to/project --language de
```

**Citation Output Example:**

```markdown
Müller, T. (2024). Digitalisierung im deutschen Profifußball.
Deutscher Fußball-Bund. Abgerufen am 15. Januar 2024, von https://www.dfb.de/news/detail/digitalisierung
```

**Validation:** "Abgerufen am" present, German date format correct

### Example 3: Partition Mode (Parallel Execution)

**Scenario:** 80 sources, split across 4 parallel jobs

**Invocation (Partition 1 of 4):**

```bash
citation-planner --project-path /path/to/project --partition 1/4
```

**Process:**

1. Load all 80 sources + 50 publishers
2. Filter to partition 1/4 (sources 0-19, 20 sources)
3. Build publisher lookup structures
4. Process 20 sources in partition 1
5. Write 20 citations

**Response:**

```json
{
  "success": true,
  "citations_created": 20,
  "citations_skipped": 0,
  "publisher_matches": {
    "domain_exact": 15,
    "name_exact": 3,
    "reverse_index": 1,
    "domain_fallback": 1
  }
}
```

**Benefits:**

- Prevents timeouts on large source sets (70+)
- Enables horizontal scaling across 4 parallel jobs
- Each partition independently processes its slice

### Example 4: High Domain Fallback Warning

**Scenario:** 25 sources, only 3 publishers exist

**Response:**

```json
{
  "success": true,
  "citations_created": 25,
  "citations_skipped": 0,
  "warnings": ["88% citations used domain_fallback - check publisher loading"],
  "publisher_matches": {
    "domain_exact": 2,
    "name_exact": 1,
    "reverse_index": 0,
    "domain_fallback": 22
  }
}
```

**Interpretation:** Warning indicates most sources lack publisher entities (expected in early research phases).
