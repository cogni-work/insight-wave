---
reference: phase-0-environment
version: 1.0.0
checksum: phase-0-environment-v1.0.0-batch-creator
dependencies: []
phase: 0
---

# Phase 0: Environment Validation

**Verification Checkpoint:** After reading, output checksum: `phase-0-environment-v1.0.0-batch-creator`

---

## Purpose

Validate environment prerequisites and initialize logging infrastructure before processing refined questions.

---

## Step 0.5: Initialize Phase 0 TodoWrite

Expand the phase-level todo into step-level todos:

```markdown
TodoWrite:
- Phase 0, Step 0.1: Validate CLAUDE_PLUGIN_ROOT [in_progress]
- Phase 0, Step 0.2: Validate PROJECT_PATH parameter [pending]
- Phase 0, Step 0.3: Verify 02-refined-questions exists [pending]
- Phase 0, Step 0.4: Initialize logging infrastructure [pending]
- Phase 0, Step 0.5: Load project configuration [pending]
```

---

## Step 0.1: Resolve CLAUDE_PLUGIN_ROOT

**⚠️ CRITICAL:** This step MUST complete before any script invocation to prevent path resolution failures.

```bash
# Validate CLAUDE_PLUGIN_ROOT has expected structure
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
    echo "[ERROR] CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: ${CLAUDE_PLUGIN_ROOT}" >&2
    exit 1
fi

# MANDATORY: Source centralized plugin root resolver
RESOLVER_PATH=""
if [ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/resolve-plugin-root.sh" ]; then
    RESOLVER_PATH="${CLAUDE_PLUGIN_ROOT}/scripts/utils/resolve-plugin-root.sh"
fi

if [ -n "$RESOLVER_PATH" ]; then
    source "$RESOLVER_PATH"
    CLAUDE_PLUGIN_ROOT=$(resolve_plugin_root)
    export CLAUDE_PLUGIN_ROOT
    echo "INFO: Resolved CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}" >&2
else
    # Final validation
    if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
        echo "ERROR: CLAUDE_PLUGIN_ROOT not set" >&2
        exit 110
    fi

    if [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
        echo "ERROR: Plugin scripts directory not found: ${CLAUDE_PLUGIN_ROOT}/scripts" >&2
        exit 110
    fi

    export CLAUDE_PLUGIN_ROOT
fi

echo "Environment validated: CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}" >&2
```

Mark Step 0.1 completed.

---

## Step 0.2: Validate PROJECT_PATH Parameter

The PROJECT_PATH parameter is provided by the invoking agent.

**⚠️ FRESH SHELL WARNING:** Each Bash tool invocation is a fresh shell. Environment variables do NOT persist between Bash calls. You MUST include the PROJECT_PATH assignment at the TOP of this same bash block.

```bash
# ⚠️ ADD THIS LINE FIRST - Replace with actual path from your prompt context:
PROJECT_PATH="/path/from/prompt"  # ← Replace with actual value

# Validate PROJECT_PATH is provided
if [ -z "${PROJECT_PATH:-}" ]; then
  echo "ERROR: PROJECT_PATH parameter not provided - add PROJECT_PATH assignment at top of this bash block" >&2
  exit 112
fi

# Normalize to absolute path
PROJECT_PATH=$(cd "${PROJECT_PATH}" 2>/dev/null && pwd -P)
if [ -z "${PROJECT_PATH}" ]; then
  echo "ERROR: PROJECT_PATH does not exist or is not accessible" >&2
  exit 112
fi

export PROJECT_PATH
echo "Project path validated: ${PROJECT_PATH}" >&2
```

Mark Step 0.2 completed.

---

## Step 0.3: Verify Phase 2 Artifacts Exist

Batch-creator requires Phase 2 (dimension-planner) to have completed.

```bash
# Verify 02-refined-questions/data directory exists
# NOTE: Question entities are stored in the data/ subdirectory
QUESTIONS_DIR="${PROJECT_PATH}/02-refined-questions/data"
if [ ! -d "${QUESTIONS_DIR}" ]; then
  echo "ERROR: 02-refined-questions/data directory not found - run dimension-planner first" >&2
  exit 113
fi

# Count question files
QUESTION_COUNT=$(find "${QUESTIONS_DIR}" -maxdepth 1 -name "question-*.md" -type f | wc -l | tr -d ' ')
if [ "${QUESTION_COUNT}" -eq 0 ]; then
  echo "ERROR: No question files found in 02-refined-questions/data" >&2
  exit 113
fi

echo "Found ${QUESTION_COUNT} refined questions to process" >&2
```

Mark Step 0.3 completed.

---

## Step 0.4: Initialize Logging Infrastructure

```bash
# Create log directory
LOG_DIR="${PROJECT_PATH}/.logs/batch-creator"
mkdir -p "${LOG_DIR}"

# Initialize execution log
LOG_FILE="${LOG_DIR}/batch-creator-execution-log.txt"
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PHASE] ========== batch-creator Phase 0 Started ==========" >> "${LOG_FILE}"

# Source enhanced logging utilities (with fallback)
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
  # Set log file for this session
  export LOG_FILE
else
  # Fallback: basic logging
  log_conditional() {
    local level="$1"
    local msg="$2"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [$level] $msg" >> "${LOG_FILE}"
    [ "${DEBUG_MODE:-false}" = "true" ] && echo "[$level] $msg" >&2
  }
  log_phase() {
    local name="$1"
    local phase_status="$2"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PHASE] ========== $name [$phase_status] ==========" >> "${LOG_FILE}"
    [ "${DEBUG_MODE:-false}" = "true" ] && echo "[PHASE] ========== $name [$phase_status] ==========" >&2
  }
  log_metric() {
    local name="$1"
    local value="$2"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [METRIC] $name=$value" >> "${LOG_FILE}"
  }
fi

log_conditional INFO "Logging initialized: ${LOG_FILE}"
```

Mark Step 0.4 completed.

---

## Step 0.5: Load Project Configuration

```bash
# Load project language from sprint-log.json
SPRINT_LOG="${PROJECT_PATH}/.metadata/sprint-log.json"
if [ -f "${SPRINT_LOG}" ]; then
  PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${SPRINT_LOG}")
  RESEARCH_TYPE=$(jq -r '.research_type // "generic"' "${SPRINT_LOG}")
else
  PROJECT_LANGUAGE="${LANGUAGE:-en}"
  RESEARCH_TYPE="generic"
  log_conditional WARN "sprint-log.json not found, using defaults"
fi

export PROJECT_LANGUAGE
export RESEARCH_TYPE

log_conditional INFO "Project language: ${PROJECT_LANGUAGE}"
log_conditional INFO "Research type: ${RESEARCH_TYPE}"
log_phase "Phase 0: Environment Validation" "complete"
```

Mark Step 0.5 completed. Mark Phase 0 phase-level todo completed.

---

## Expected Outputs

| Output | Type | Description |
|--------|------|-------------|
| PROJECT_PATH | Environment variable | Validated absolute path to project |
| PROJECT_LANGUAGE | Environment variable | ISO 639-1 language code |
| RESEARCH_TYPE | Environment variable | Research type from sprint-log |
| LOG_FILE | Environment variable | Path to execution log |
| QUESTION_COUNT | Integer | Number of questions to process |

---

## Validation Gates

| Gate | Condition | Exit Code |
|------|-----------|-----------|
| CLAUDE_PLUGIN_ROOT | Set and valid | 110 |
| PROJECT_PATH | Exists and accessible | 112 |
| 02-refined-questions/data | Directory exists | 113 |
| Question files | At least 1 present | 113 |

---

## Shell Compatibility Requirements

Claude Code executes bash via the user's default shell (often zsh). To avoid parse errors:

**PROHIBITED in inline bash:**

- Multi-line if/then/else/fi blocks
- Bash array assignments: `ARRAY=($(...))`
- Newlines between statements

**REQUIRED patterns:**

- Single-line conditionals: `[ -d "$DIR" ] && echo "exists" || echo "missing"`
- Chain with &&: `mkdir -p "$DIR" && cd "$DIR" && pwd`
- For complex logic: Write to temp script file, then execute with `bash script.sh`

**NOTE**: The bash code blocks in this reference file show the LOGIC to implement, not copy-paste commands. When executing inline, convert multi-line blocks to single-line equivalents or write to a temp script.

### Temp Script Creation Pattern

To create temporary bash scripts, use the Bash tool with heredoc (NOT Write tool):

```bash
cat > /tmp/batch-processor.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
# ... script content with arrays, loops, etc. ...
SCRIPT_EOF
chmod +x /tmp/batch-processor.sh
```

Then execute: `bash /tmp/batch-processor.sh`

**⚠️ Write Tool Limitation**: The Write tool requires reading a file first. For new temp scripts, ALWAYS use `cat > file << 'EOF'` via Bash tool.

---

## Next Phase

Proceed to [phase-1-load-questions.md](phase-1-load-questions.md) when all criteria met.
