# Phase 1: Setup & Validation

Initialize the knowledge merger environment and validate prerequisites.

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 1.1: Parse parameters [in_progress]
- Phase 1.2: Validate PROJECT_PATH [pending]
- Phase 1.3: Initialize logging [pending]
- Phase 1.4: Verify concept directory [pending]
```

---

## Step 1: Parse Parameters

**⚠️ ZSH COMPATIBILITY:** while/case blocks require temp script pattern.

```bash
cat > /tmp/km-parse-params.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

PROJECT_PATH=""
CONTENT_LANGUAGE="en"

while [ $# -gt 0 ]; do
  case $1 in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --content-language) CONTENT_LANGUAGE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Validate required parameter
if [ -z "$PROJECT_PATH" ]; then
  echo '{"success": false, "error": "Missing required parameter: --project-path"}' >&2
  exit 1
fi

echo "PROJECT_PATH=${PROJECT_PATH}"
echo "CONTENT_LANGUAGE=${CONTENT_LANGUAGE}"
SCRIPT_EOF
chmod +x /tmp/km-parse-params.sh && bash /tmp/km-parse-params.sh --project-path "${PROJECT_PATH}" --content-language "${CONTENT_LANGUAGE}"
```

**Mark 1.1 complete.**

---

## Step 2: Validate PROJECT_PATH

**⚠️ ZSH COMPATIBILITY:** if/then blocks with command substitution require temp script pattern.

```bash
cat > /tmp/km-validate-path.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
CLAUDE_PLUGIN_ROOT="$1"
PROJECT_PATH="$2"

# Use shared validation script
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  validation_result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh" \
    --project-path "$PROJECT_PATH" \
    --json)

  if [ "$(echo "$validation_result" | jq -r '.success')" != "true" ]; then
    echo "$validation_result" >&2
    exit 1
  fi
fi
echo "Validation passed for: $PROJECT_PATH"
SCRIPT_EOF
chmod +x /tmp/km-validate-path.sh && bash /tmp/km-validate-path.sh "${CLAUDE_PLUGIN_ROOT}" "${PROJECT_PATH}"
```

**Mark 1.2 complete.**

---

## Step 3: Initialize Logging

```bash
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

# Create .metadata directory if needed
mkdir -p "${PROJECT_PATH}/.metadata"

# Initialize log file
echo "=== Knowledge Merger Execution Log ===" > "$LOG_FILE"
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG_FILE"
echo "PROJECT_PATH: $PROJECT_PATH" >> "$LOG_FILE"
echo "CONTENT_LANGUAGE: $CONTENT_LANGUAGE" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

# Define logging function
log_phase() {
  local phase="$1"
  local phase_status="$2"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $phase: $phase_status" >> "$LOG_FILE"
}

log_conditional() {
  local level="$1"
  local message="$2"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $message" >> "$LOG_FILE"
}

log_phase "Phase 1: Setup" "start"
```

**Mark 1.3 complete.**

---

## Step 4: Verify Concept Directory

**⚠️ ZSH COMPATIBILITY:** if/then blocks with command substitution require temp script pattern.

```bash
cat > /tmp/km-verify-concepts.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
CONCEPTS_DIR="${PROJECT_PATH}/05-domain-concepts"
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

if [ ! -d "$CONCEPTS_DIR" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [ERROR] Concept directory does not exist: $CONCEPTS_DIR" >> "$LOG_FILE"
  echo '{"success": false, "error": "Concept directory not found - run knowledge-extractor first"}' >&2
  exit 1
fi

# Count existing concepts
concept_count=$(find "$CONCEPTS_DIR" -maxdepth 1 -name "concept-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

if [ "$concept_count" -eq 0 ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [WARN] No concepts found - will create megatrends only" >> "$LOG_FILE"
fi

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Found $concept_count existing concepts" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 1: Setup: complete" >> "$LOG_FILE"
echo "concept_count=${concept_count}"
SCRIPT_EOF
chmod +x /tmp/km-verify-concepts.sh && bash /tmp/km-verify-concepts.sh "${PROJECT_PATH}"
```

**Mark 1.4 complete.**

---

## Phase 1 Verification

| Check | Status |
|-------|--------|
| PROJECT_PATH parsed and validated | |
| Logging initialized | |
| Concept directory verified | |
| All step todos completed | |

⛔ **All checks must pass before Phase 2.**

---

## Phase 1 Output

```text
✅ Phase 1 Complete

PROJECT_PATH: {PROJECT_PATH}
CONTENT_LANGUAGE: {CONTENT_LANGUAGE}
Existing concepts: {concept_count}

→ Phase 2: Concept Deduplication
```

**Mark Phase 1 complete in TodoWrite.**
