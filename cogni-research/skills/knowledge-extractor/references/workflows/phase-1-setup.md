# Phase 1: Setup & Validation

Parse parameters, validate environment, and initialize logging infrastructure.

---

## Entry Conditions

This phase has no prerequisites (first phase in workflow).

---

## Step 1: Validate Environment & Parse Parameters (Script)

Delegate validation to computational service:

**⚠️ ZSH COMPATIBILITY:** This complex bash logic uses if/then, while loops, and case statements. MUST use temp script pattern.

```bash
cat > /tmp/knowledge-extractor-setup.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

CLAUDE_PLUGIN_ROOT="$1"
shift  # Remove first arg, rest are parameters to parse

# Validate CLAUDE_PLUGIN_ROOT exists
if [ -z "$CLAUDE_PLUGIN_ROOT" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

# Parse command-line parameters
PROJECT_PATH=""
CONTENT_LANGUAGE="en"
PARTITION=""

while [ $# -gt 0 ]; do
  case $1 in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --content-language) CONTENT_LANGUAGE="$2"; shift 2 ;;
    --partition) PARTITION="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Validate required parameter
if [ -z "$PROJECT_PATH" ]; then
  echo '{"success": false, "error": "Missing required parameter: --project-path"}' >&2
  exit 1
fi

# Delegate directory validation to script service
validation_result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh" \
  --project-path "$PROJECT_PATH" --json 2>&1) || {
  echo "$validation_result" >&2
  exit 1
}

echo "PROJECT_PATH=${PROJECT_PATH}"
echo "CONTENT_LANGUAGE=${CONTENT_LANGUAGE}"
echo "PARTITION=${PARTITION}"
SCRIPT_EOF
chmod +x /tmp/knowledge-extractor-setup.sh && \
  bash /tmp/knowledge-extractor-setup.sh "${CLAUDE_PLUGIN_ROOT}" --project-path "${PROJECT_PATH}" --content-language "${CONTENT_LANGUAGE}"

# Parse validation response
if [ "$(echo "$validation_result" | jq -r '.success')" != "true" ]; then
  echo "$validation_result" >&2
  exit 1
fi

# Extract validated path (handles canonicalization)
PROJECT_PATH=$(echo "$validation_result" | jq -r '.data.project_path')
```

**Output:** Validated `PROJECT_PATH`, `CONTENT_LANGUAGE`, `PARTITION` variables ready for use.

---

## Step 2: Initialize Logging (LLM Task)

Source enhanced logging utility and initialize log file:

```bash
# Source logging utility (requires CLAUDE_PLUGIN_ROOT)
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize skill-specific log file
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-extractor-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.logs"

# Log execution start
log_phase "Phase 1: Setup & Validation" "start"
log_conditional INFO "PROJECT_PATH: $PROJECT_PATH"
log_conditional INFO "CONTENT_LANGUAGE: $CONTENT_LANGUAGE"
[ -n "$PARTITION" ] && log_conditional INFO "PARTITION: $PARTITION"
log_phase "Phase 1: Setup & Validation" "complete"
```

---

## Step 3: Resolve Entity Directory Names (Script)

**MANDATORY:** Resolve entity directory placeholders from centralized config. Other phases depend on these variables.

```bash
# === MANDATORY: Directory Resolution ===
# Try both direct and monorepo paths for entity-config.sh
ENTITY_CONFIG=""
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
        ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
    # CLAUDE_PLUGIN_ROOT points directly to plugin root in flat structure
    fi
fi

if [ -n "$ENTITY_CONFIG" ]; then
    source "$ENTITY_CONFIG"
    DIMENSIONS_DIR=$(get_directory_by_key "research-dimensions")
    FINDINGS_DIR=$(get_directory_by_key "findings")
    DOMAIN_CONCEPTS_DIR=$(get_directory_by_key "domain-concepts")
    MEGATRENDS_DIR=$(get_directory_by_key "megatrends")
    SOURCES_DIR=$(get_directory_by_key "sources")
else
    # Fallback to hardcoded values if entity-config.sh unavailable
    DIMENSIONS_DIR="01-research-dimensions"
    FINDINGS_DIR="04-findings"
    DOMAIN_CONCEPTS_DIR="05-domain-concepts"
    MEGATRENDS_DIR="06-megatrends"
    SOURCES_DIR="07-sources"
fi
export DIMENSIONS_DIR FINDINGS_DIR DOMAIN_CONCEPTS_DIR MEGATRENDS_DIR SOURCES_DIR

# Log resolved directories
log_conditional INFO "Entity directories resolved:"
log_conditional INFO "  DIMENSIONS_DIR=${DIMENSIONS_DIR}"
log_conditional INFO "  FINDINGS_DIR=${FINDINGS_DIR}"
log_conditional INFO "  DOMAIN_CONCEPTS_DIR=${DOMAIN_CONCEPTS_DIR}"
log_conditional INFO "  MEGATRENDS_DIR=${MEGATRENDS_DIR}"
log_conditional INFO "  SOURCES_DIR=${SOURCES_DIR}"
```

**Output:** Exported variables `DIMENSIONS_DIR`, `FINDINGS_DIR`, `DOMAIN_CONCEPTS_DIR`, `MEGATRENDS_DIR`, `SOURCES_DIR` available for all subsequent phases.

---

## Step 4: Path Verification & Directory Listing (Script)

**MANDATORY:** Output resolved paths AND list actual directories to prevent path hallucination.

```bash
# === MANDATORY PATH VERIFICATION ===
# Echo resolved paths - LLM MUST use these exact values in subsequent phases
echo "=== ENTITY DIRECTORY REFERENCE ===" | tee -a "$LOG_FILE"
echo "DIMENSIONS_DIR=${DIMENSIONS_DIR}" | tee -a "$LOG_FILE"
echo "FINDINGS_DIR=${FINDINGS_DIR}" | tee -a "$LOG_FILE"
echo "DOMAIN_CONCEPTS_DIR=${DOMAIN_CONCEPTS_DIR}" | tee -a "$LOG_FILE"
echo "MEGATRENDS_DIR=${MEGATRENDS_DIR}" | tee -a "$LOG_FILE"
echo "SOURCES_DIR=${SOURCES_DIR}" | tee -a "$LOG_FILE"
echo "===================================" | tee -a "$LOG_FILE"

# === MANDATORY: List actual directories to prevent path hallucination ===
echo "=== ACTUAL PROJECT DIRECTORIES ===" | tee -a "$LOG_FILE"
ls -d "${PROJECT_PATH}"/[0-9][0-9]-*/ 2>/dev/null | xargs -n1 basename | tee -a "$LOG_FILE"
echo "===================================" | tee -a "$LOG_FILE"
```

**CRITICAL:** Use ONLY the directory names shown in the output above. Never construct paths from memory (e.g., never use `03-dimensions` - use `${DIMENSIONS_DIR}` which resolves to `01-research-dimensions`).

---

## Phase 1 Exit Gate

⛔ **MANDATORY: Verify before proceeding to Phase 2**

| Check | Requirement |
|-------|-------------|
| PROJECT_PATH | Set, valid directory, canonicalized |
| CLAUDE_PLUGIN_ROOT | Set, accessible |
| LOG_FILE | Created at `${PROJECT_PATH}/.logs/` |
| FINDINGS_DIR | Set (e.g., "04-findings") |
| DOMAIN_CONCEPTS_DIR | Set (e.g., "05-domain-concepts") |
| MEGATRENDS_DIR | Set (e.g., "06-megatrends") |
| Phase 1 todo | Marked complete in TodoWrite |

**IF ANY CHECK FAILS:** Return to failed step. Do NOT proceed to Phase 2.

---

## Phase 1 Completion

Mark Phase 1 todo as completed, then output confirmation:

```text
✅ Phase 1 Complete: Setup & Validation

Parameters:
- PROJECT_PATH: {value}
- CONTENT_LANGUAGE: {value}
- PARTITION: {value or "none"}

Entity Directories:
- FINDINGS_DIR: {value}
- DOMAIN_CONCEPTS_DIR: {value}
- MEGATRENDS_DIR: {value}

Environment: ✅ Valid
Logging: ✅ Initialized
Directory Resolution: ✅ Complete
Path Verification: ✅ Directory listing displayed

→ Proceeding to Phase 2: Finding Loading
```
