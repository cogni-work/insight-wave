# Shared Bash Patterns

Universal bash scaffolding patterns for deeper-research skill implementation.

**Read this when:** Implementing skill bash code, setting up parameter parsing, validating working directory, initializing logging, or constructing JSON responses.

## Purpose

This reference provides 5 universal bash patterns used by all deeper-research processing skills:

1. **Parameter Parsing** - Extract and validate command-line arguments
2. **Working Directory Validation** - Verify CLAUDE_PLUGIN_ROOT and project path
3. **Logging Initialization** - Set up enhanced logging with partition awareness
4. **JSON Response Construction** - Build structured JSON output
5. **Bash Syntax Rules** - Anti-hallucination patterns for correct bash generation

These patterns are extracted from 7 skill implementations and standardized for consistency.

## Section 1: Parameter Parsing

### Pattern: While Loop + Case Statement

Extract and validate parameters from skill invocation using standard bash patterns.

```bash
# Initialize variables with defaults
PROJECT_PATH=""
LANGUAGE="en"  # Default language
PARTITION=""   # Optional partition number

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --partition|--partition-num|--partition-id)
      PARTITION="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1" >&2
      exit 2
      ;;
  esac
done
```

### Validation Pattern

Validate required parameters before proceeding:

```bash
# Validate required parameters
if [ -z "$PROJECT_PATH" ]; then
  echo '{"success": false, "error": "Missing required parameter: --project-path"}' >&2
  exit 2
fi

# Validate format (example: language code)
if [ ! "$LANGUAGE" =~ ^[a-z]{2}$ ]; then
  echo '{"success": false, "error": "Invalid language code (must be 2-letter ISO 639-1): '"$LANGUAGE"'"}' >&2
  exit 2
fi

# Set defaults for optional parameters
LANGUAGE="${LANGUAGE:-en}"
```

### Standard Parameter Names

Use these standard parameter names across all skills:

| Parameter | Purpose | Required | Default |
|-----------|---------|----------|---------|
| `--project-path` | Research project directory | ✅ Yes | - |
| `--language` | Output language (ISO 639-1) | ❌ No | `en` |
| `--partition` | Partition number for parallel execution | ❌ No | - |
| `--dimension-id` | Dimension identifier | Skill-specific | - |
| `--finding-list-file` | Path to file with finding paths | Skill-specific | - |
| `--claim-files` | Comma-separated claim paths | Skill-specific | - |
| `--source-files` | Comma-separated source paths | Skill-specific | - |

### Parameter Variant Handling

Support multiple parameter name variants for flexibility:

```bash
# Example: Accept --partition, --partition-num, or --partition-id
case "$1" in
  --partition|--partition-num|--partition-id)
    PARTITION="$2"
    shift 2
    ;;
esac

# Later: Use the first non-empty variant
PART_NUM="${PARTITION:-${PARTITION_NUM:-${PARTITION_ID:-}}}"
```

### Exit Codes

Use standard exit codes consistently:

- `0` - Success
- `1` - Runtime error (file not found, validation failed)
- `2` - Parameter error (missing required, invalid format)

### Common Anti-Patterns

❌ **Don't:** Use positional parameters without names
```bash
# Bad: Hard to remember parameter order
PROJECT_PATH="$1"
LANGUAGE="$2"
```

❌ **Don't:** Skip validation of required parameters
```bash
# Bad: Silent failure if parameter missing
cd "$PROJECT_PATH" 2>/dev/null
```

❌ **Don't:** Use non-standard exit codes
```bash
# Bad: Custom exit codes confuse error handling
exit 42  # What does this mean?
```

✅ **Do:** Use named parameters with validation
```bash
# Good: Clear parameter names, explicit validation
--project-path "$PATH" with validation check
```

## Section 2: Working Directory Validation

### Pattern: CLAUDE_PLUGIN_ROOT + Validation Utility

Validate environment and project path using centralized utility.

```bash
# Set agent/skill name for logging context
AGENT_NAME="skill-name"  # Replace with actual skill name

# Validate CLAUDE_PLUGIN_ROOT environment variable
if [ -z "$CLAUDE_PLUGIN_ROOT" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

# Call centralized validation utility
VALIDATION_RESULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh" \
  --project-path "$PROJECT_PATH" \
  --json)

# Validate utility execution succeeded
if [ $? -ne 0 ]; then
  echo "$VALIDATION_RESULT" >&2
  exit 1
fi

# Validate JSON output
if ! echo "$VALIDATION_RESULT" | jq -e . >/dev/null 2>&1; then
  printf '{"success": false, "error": "validate-working-directory.sh returned invalid JSON"}\n' >&2
  exit 1
fi

# Check if validation succeeded
if [ "$(echo "$VALIDATION_RESULT" | jq -r '.success')" != "true" ]; then
  echo "$VALIDATION_RESULT" >&2
  exit 1
fi
```

### Contract: validate-working-directory.sh

**Location:** `${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh`

**Interface:**
```bash
--project-path <path>  # Required: Research project directory
--json                 # Required: Output JSON format
```

**Response Structure:**
```json
{
  "success": true,
  "project_path": "/absolute/path/to/project",
  "validation": "passed"
}
```

**Exit Codes:**
- `0` - Validation passed
- `1` - Validation failed (directory doesn't exist, not writable)
- `2` - Parameter error

### Why Use Absolute Paths

**Important:** Agent threads reset their current working directory (`cwd`) between bash calls. The validation utility verifies the project path exists but does NOT change directories.

**All file operations must use absolute paths:**

```bash
# ✅ Good: Absolute path construction
FINDING_FILE="${PROJECT_PATH}/04-findings/data/finding-xyz.md"
if [ -f "$FINDING_FILE" ]; then
  # Process finding
fi

# ❌ Bad: Relative path (will fail after thread reset)
cd "$PROJECT_PATH"
if [ -f "04-findings/data/finding-xyz.md" ]; then
  # This might work once, but breaks on next bash call
fi
```

### Common Anti-Patterns

❌ **Don't:** Change working directory
```bash
# Bad: cwd resets between bash calls
cd "$PROJECT_PATH" || exit 1
```

❌ **Don't:** Skip CLAUDE_PLUGIN_ROOT validation
```bash
# Bad: Assumes environment variable exists
source "${CLAUDE_PLUGIN_ROOT}/script.sh"  # Fails silently
```

❌ **Don't:** Trust validation utility without checking response
```bash
# Bad: Assumes validation passed
RESULT=$(bash validate-working-directory.sh ...)
# Proceeds without checking $RESULT
```

✅ **Do:** Use absolute paths with validation
```bash
# Good: Validate environment, use absolute paths
if [ -z "$CLAUDE_PLUGIN_ROOT" ]; then exit 1; fi
VALIDATION=$(validate-working-directory.sh ...)
if [ "$(echo "$VALIDATION" | jq -r '.success')" != "true" ]; then exit 1; fi
FILE="${PROJECT_PATH}/relative/path.md"
```

## Section 3: Logging Initialization

### Pattern: Enhanced Logging with Partition Awareness

Initialize logging with support for partition-aware file naming.

```bash
# ===== LOGGING INITIALIZATION =====

# Detect partition parameter for partition-aware log file naming
if [ -n "${PARTITION:-}" ] || [ -n "${PARTITION_NUM:-}" ] || [ -n "${PARTITION_ID:-}" ]; then
  # Use partition from whichever variable is set
  PART_NUM="${PARTITION:-${PARTITION_NUM:-${PARTITION_ID:-}}}"
  LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-partition${PART_NUM}-execution-log.txt"
else
  # No partition - use standard log name
  LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
fi

# Ensure metadata directory exists
mkdir -p "${PROJECT_PATH}/.metadata" 2>/dev/null || true

# Source enhanced logging utility
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize log file with header
echo "========================================" >> "$LOG_FILE"
echo "Execution Log: $AGENT_NAME" >> "$LOG_FILE"
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Log execution context
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh"
CONTEXT=$(log_execution_context --project-path "$PROJECT_PATH" --agent-name "$AGENT_NAME")
echo "$CONTEXT" >> "$LOG_FILE" 2>/dev/null || true
```

### Logging Functions

Enhanced logging utility provides these functions:

#### log_conditional

Log message respecting DEBUG_MODE environment variable:

```bash
log_conditional LEVEL MESSAGE

# Examples:
log_conditional INFO "Processing entity: $ENTITY_ID"
log_conditional ERROR "Validation failed: $ERROR"
log_conditional DEBUG "Variable state: FOO=$FOO, BAR=$BAR"
```

**Levels:** TRACE, DEBUG, INFO, WARN, ERROR

**DEBUG_MODE Behavior:**
- `DEBUG_MODE=true` - All levels written to log
- `DEBUG_MODE=false` or unset - Only INFO, WARN, ERROR written

#### log_phase

Log phase transitions for workflow tracking:

```bash
log_phase "PHASE_NAME" "STATUS"

# Examples:
log_phase "Phase 1: Parameter Validation" "start"
log_phase "Phase 1: Parameter Validation" "complete"
```

**Status values:** `start`, `complete`

#### log_metric

Log performance metrics:

```bash
log_metric "METRIC_NAME" VALUE "UNIT"

# Examples:
log_metric "entities_processed" 127 "count"
log_metric "processing_time" 45.3 "seconds"
```

### Log File Location

**Standard format:** `${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt`
**Partition format:** `${PROJECT_PATH}/.metadata/${AGENT_NAME}-partition${N}-execution-log.txt`

### Common Anti-Patterns

❌ **Don't:** Hardcode log paths
```bash
# Bad: Not portable
LOG_FILE="/tmp/my-skill.log"
```

❌ **Don't:** Skip log directory creation
```bash
# Bad: Fails if .metadata/ doesn't exist
echo "Log entry" >> "$LOG_FILE"
```

❌ **Don't:** Use echo instead of log_conditional
```bash
# Bad: No debug mode control, no timestamps
echo "Processing: $ID"
```

✅ **Do:** Use enhanced logging with partition awareness
```bash
# Good: Respects DEBUG_MODE, handles partitions
log_conditional INFO "Processing: $ID"
```

## Section 4: JSON Response Construction

### Pattern: jq-Based JSON Generation

Construct structured JSON responses for agent communication.

### Success Response

```bash
# Construct success response with jq
cat <<EOF | jq .
{
  "success": true,
  "entities_created": $CREATED_COUNT,
  "entities_reused": $REUSED_COUNT,
  "entities_skipped": $SKIPPED_COUNT,
  "validation_passed": true,
  "error": null
}
EOF
```

### Error Response

```bash
# Construct error response
cat <<EOF | jq .
{
  "success": false,
  "error": "Error description here",
  "error_code": "ERROR_CODE",
  "context": {
    "entity_id": "$ENTITY_ID",
    "operation": "entity_creation"
  }
}
EOF
```

### Counter Aggregation

```bash
# Initialize counters at workflow start
CREATED_COUNT=0
REUSED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

# Increment during processing
if [ "$ENTITY_CREATED" = "true" ]; then
  CREATED_COUNT=$((CREATED_COUNT + 1))
elif [ "$ENTITY_REUSED" = "true" ]; then
  REUSED_COUNT=$((REUSED_COUNT + 1))
else
  SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
fi

# Include in final response
cat <<EOF | jq .
{
  "success": true,
  "entities_created": $CREATED_COUNT,
  "entities_reused": $REUSED_COUNT,
  "entities_skipped": $SKIPPED_COUNT
}
EOF
```

### Response Validation

Validate JSON structure before output:

```bash
# Generate response
RESPONSE=$(cat <<EOF
{
  "success": true,
  "count": $COUNT
}
EOF
)

# Validate JSON
if ! echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
  echo '{"success": false, "error": "Internal error: invalid JSON response"}' >&2
  exit 1
fi

# Output validated response
echo "$RESPONSE" | jq .
```

### Standard Response Fields

All JSON responses should include:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `success` | boolean | ✅ Yes | Overall operation success |
| `error` | string\|null | ✅ Yes | Error message if failed, null if succeeded |
| `error_code` | string | ❌ No | Machine-readable error code |
| `*_count` | number | ❌ No | Entity counts (created, reused, skipped, etc.) |
| `validation_passed` | boolean | ❌ No | Validation result |

### Common Anti-Patterns

❌ **Don't:** Manually escape JSON strings
```bash
# Bad: Error-prone, breaks on special characters
echo "{\"success\": true, \"message\": \"$MSG\"}"
```

❌ **Don't:** Mix conversational text with JSON
```bash
# Bad: Not parsable
echo "Processing complete!"
echo '{"success": true}'
```

❌ **Don't:** Skip JSON validation
```bash
# Bad: Malformed JSON breaks agent parsing
echo "{success: true, count: $COUNT"  # Missing quotes, closing brace
```

✅ **Do:** Use jq for JSON construction with validation
```bash
# Good: jq handles escaping, validates structure
cat <<EOF | jq .
{
  "success": true,
  "message": "$MSG"
}
EOF
```

## Integration Example

Complete bash scaffolding using all 4 patterns:

```bash
#!/bin/bash
set -e

# ===== SECTION 1: PARAMETER PARSING =====
PROJECT_PATH=""
LANGUAGE="en"
PARTITION=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --partition) PARTITION="$2"; shift 2 ;;
    *) echo "Unknown parameter: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$PROJECT_PATH" ]; then
  echo '{"success": false, "error": "Missing --project-path"}' >&2
  exit 2
fi

# ===== SECTION 2: WORKING DIRECTORY VALIDATION =====
AGENT_NAME="my-skill"

if [ -z "$CLAUDE_PLUGIN_ROOT" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

VALIDATION=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh" \
  --project-path "$PROJECT_PATH" --json)

if [ "$(echo "$VALIDATION" | jq -r '.success')" != "true" ]; then
  echo "$VALIDATION" >&2
  exit 1
fi

# ===== SECTION 3: LOGGING INITIALIZATION =====
if [ -n "$PARTITION" ]; then
  LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-partition${PARTITION}-execution-log.txt"
else
  LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
fi

mkdir -p "${PROJECT_PATH}/.metadata"
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

echo "========================================" >> "$LOG_FILE"
echo "Execution Log: $AGENT_NAME" >> "$LOG_FILE"
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

log_phase "Phase 1: Initialization" "start"

# ===== SKILL-SPECIFIC PROCESSING =====
PROCESSED_COUNT=0
ERROR_COUNT=0

# ... processing logic here ...

log_phase "Phase 1: Initialization" "complete"

# ===== SECTION 4: JSON RESPONSE =====
cat <<EOF | jq .
{
  "success": true,
  "processed_count": $PROCESSED_COUNT,
  "error_count": $ERROR_COUNT,
  "error": null
}
EOF
```

## Usage in Skills

Skills reference this file using progressive disclosure:

**Phase 0 (Parameter Validation):**
```markdown
**Read:** `../../references/shared-bash-patterns.md` for:
- Parameter parsing pattern (Section 1)
```

**Phase 1 (Environment Setup):**
```markdown
**Read:** `../../references/shared-bash-patterns.md` for:
- Working directory validation (Section 2)
- Logging initialization (Section 3)
```

**Phase N (Final Response):**
```markdown
**Read:** `../../references/shared-bash-patterns.md` for:
- JSON response construction (Section 4)
```

## Section 5: Bash Syntax Rules (Anti-Hallucination)

**CRITICAL:** When generating bash code, you MUST follow these rules to prevent parse errors and ensure correct execution.

### Rule 1: Command Separation

Commands MUST be separated by newlines or semicolons. NEVER concatenate commands on one line without separators.

❌ **WRONG (causes parse error):**

```bash
VAR=$(cmd) echo "$VAR" NEXT=$(cmd2)
```

✅ **CORRECT (newlines):**

```bash
VAR=$(cmd)
echo "$VAR"
NEXT=$(cmd2)
```

✅ **CORRECT (semicolons for one-liners):**

```bash
VAR=$(cmd); echo "$VAR"; NEXT=$(cmd2)
```

**Why this matters:** The shell interprets `VAR=$(cmd) echo` as setting `VAR` for a single `echo` command, not as two separate commands. This causes `parse error near '('` when the next command starts with `$(`.

### Rule 2: Integer vs Floating-Point Arithmetic

- **Integer math:** Use bash arithmetic `$(( expression ))`
- **Floating-point math:** Use `bc` with `scale=N`

❌ **WRONG (using bc for integers):**

```bash
PARTITION_SIZE=$(echo "($TOTAL + 17) / 18" | bc)
START_INDEX=$(echo "4 * $PARTITION_SIZE" | bc)
```

✅ **CORRECT (bash arithmetic for integers):**

```bash
PARTITION_SIZE=$(( (TOTAL + 17) / 18 ))
START_INDEX=$(( 4 * PARTITION_SIZE ))
```

✅ **CORRECT (bc for floating-point only):**

```bash
# Averages require floating-point precision
avg_confidence=$(echo "scale=2; $total_confidence / $claims_created" | bc)
```

**Why this matters:** `bc` is slower and requires proper quoting. Bash arithmetic is faster and cleaner for integer operations like partition calculations.

### Rule 3: Use Exact Variable Names

Use EXACT variable names from reference patterns. DO NOT invent alternatives or abbreviations.

| ✅ Reference Name | ❌ DO NOT USE |
| --- | --- |
| `FINDINGS_TOTAL` | `TOTAL_FINDINGS` |
| `START_INDEX` | `START_IDX` |
| `END_INDEX` | `END_IDX` |
| `PARTITION_SIZE` | `PART_SIZE` |
| `PARTITION_INDEX` | `PART_INDEX`, `PART_IDX` |
| `TOTAL_PARTITIONS` | `NUM_PARTITIONS` |

**Why this matters:** Consistent variable names across the codebase enable grep-based debugging and prevent confusion when reading logs.

### Rule 4: Heredoc Formatting

When using heredocs, the delimiter must be on its own line with no leading whitespace (unless using `<<-`).

❌ **WRONG:**

```bash
cat <<EOF { "success": true } EOF
```

✅ **CORRECT:**

```bash
cat <<EOF
{
  "success": true
}
EOF
```

### Rule 5: File Counting (zsh Compatibility)

Use `find` instead of `ls` with glob patterns for file counting. This prevents zsh parse errors when no files match.

❌ **WRONG (fails in zsh when no files match):**

```bash
count=$(ls "${DIR}/"*.md 2>/dev/null | wc -l | tr -d ' ')
```

✅ **CORRECT (works in both bash and zsh):**

```bash
count=$(find "${DIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
```

For recursive counting:

```bash
count=$(find "${DIR}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
```

**Why this matters:** In zsh (default macOS shell), when a glob pattern like `*.md` matches no files, it causes a parse error before the command executes. The `find` command handles empty results gracefully in both bash and zsh.

### Quick Checklist Before Executing Bash

Before running any generated bash code, verify:

- [ ] Each command is on its own line (or separated by `;`)
- [ ] Integer math uses `$(( ))` not `| bc`
- [ ] Variable names match reference patterns exactly
- [ ] Heredocs have delimiter on separate lines
- [ ] No space between `$` and `(` in command substitution
- [ ] File counting uses `find` not `ls` with glob patterns

## Related References

- [script-contract-usage.md](script-contract-usage.md) - Contract-based script invocation
- [entity-structure-guide.md](entity-structure-guide.md) - Entity YAML patterns
- [anti-hallucination-foundations.md](anti-hallucination-foundations.md) - Verification patterns
- [../contracts/](../contracts/) - Script interface contracts

## Version History

**v1.2.0** - Added zsh compatibility rule for file counting

- Rule 5: File counting with `find` instead of `ls` + glob patterns
- Prevents zsh parse errors when no files match glob patterns
- Updated checklist with file counting verification

**v1.1.0** - Added bash syntax anti-hallucination rules

- Section 5: Bash Syntax Rules (command separation, integer arithmetic, variable naming, heredocs)
- Prevents parse errors from concatenated commands
- Enforces bash arithmetic for integer calculations (not bc)
- Standardizes variable naming conventions

**v1.0.0 (Sprint 001)** - Initial extraction
- Section 1: Parameter parsing (from 7 skills)
- Section 2: Working directory validation (from 7 skills)
- Section 3: Logging initialization (from 7 skills)
- Section 4: JSON response construction (from 7 skills)
- 74% token reduction from consolidation
