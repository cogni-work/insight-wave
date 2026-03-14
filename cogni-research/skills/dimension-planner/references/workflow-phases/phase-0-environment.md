# Phase 0: Environment Validation

**Reference Checksum:** `sha256:fa73141e`

**Verification Protocol:** After reading this reference, confirm complete load by outputting:

```text
Reference Loaded: phase-0-environment.md | Checksum: fa73141e
```

---

## Objective

Validate the execution environment and initialize logging infrastructure. Set up variables that persist throughout all subsequent phases.

## Prerequisites

- Absolute path to question file provided
- CLAUDE_PLUGIN_ROOT environment variable accessible
- Project structure compliant (contains `.metadata/sprint-log.json`)

## Detailed Steps

### Step 0.1: Extract Project Path

**Purpose:** Determine project root from question file location.

**Logic:**
1. Read the absolute question file path (e.g., `/Users/name/project/00-initial-questions/q1.md`)
2. Extract project root: parent of the topmost numbered directory
3. Store as PROJECT_PATH variable

**Example extraction:**
```bash
# From question file path
QUESTION_FILE="/Users/name/project/00-initial-questions/research-q1.md"

# Extract to project root
PROJECT_PATH="/Users/name/project"
```

### Step 0.2: Validate CLAUDE_PLUGIN_ROOT

**Purpose:** Verify plugin installation and access to skill scripts.

**Command:**
```bash
bash scripts/validate-environment.sh --project-path "$PROJECT_PATH" --json
```

**Expected output:**
```json
{
  "valid": true,
  "claude_plugin_root": "/Users/name/.claude/plugins/cogni-research",
  "skill_path": "/Users/name/.claude/plugins/cogni-research/skills/dimension-planner",
  "scripts_available": true
}
```

**Error handling:**
- If `valid` is false: Return error JSON with exit code 1
- If scripts unavailable: Return error JSON about missing dimension-planner scripts

### Step 0.3: Initialize Enhanced Logging

**Purpose:** Set up enhanced logging infrastructure for debugging and metrics collection.

**Steps:**

1. **Source enhanced logging utilities:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
   ```

2. **Set LOG_FILE path:**

   ```bash
   LOG_FILE="${PROJECT_PATH}/.logs/dimension-planner-execution-log.txt"
   mkdir -p "${PROJECT_PATH}/.logs"
   ```

3. **Log phase start and initialization:**

   ```bash
   log_phase "Phase 0: Environment Validation" "start"
   log_conditional INFO "Skill: dimension-planner"
   log_conditional INFO "Question file: ${QUESTION_FILE}"
   log_conditional INFO "Project path: ${PROJECT_PATH}"
   ```

**Enhanced Logging Functions Available:**

- `log_phase <phase_name> <status>` - Phase transitions (start/complete)
- `log_conditional <level> <message>` - Conditional logging (ERROR, WARN, INFO, DEBUG, TRACE)
- `log_metric <metric_name> <value> <unit>` - Performance metrics

**DEBUG_MODE Support:**

- `DEBUG_MODE=false` (default): Only ERROR/WARN to stderr
- `DEBUG_MODE=true`: All levels to stderr + log file
- Always writes to LOG_FILE regardless of DEBUG_MODE

**Variable assignments:**

```bash
# Source enhanced logging
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Set log file
LOG_FILE="${PROJECT_PATH}/.logs/dimension-planner-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.logs"

# Log initialization
log_phase "Phase 0: Environment Validation" "start"
log_conditional INFO "Skill: dimension-planner"
log_conditional INFO "Question file: ${QUESTION_FILE}"
log_conditional INFO "Project path: ${PROJECT_PATH}"
```

### Step 0.4: Load Project Language

**Purpose:** Detect project language for multilingual content generation.

**Steps:**

1. Read `.metadata/sprint-log.json` from project root
2. Extract language field: `jq -r '.project_language // "en"' ".metadata/sprint-log.json"`
3. Store as PROJECT_LANGUAGE variable
4. Log the detected language

**Fallback:** If file not found or language field empty, default to "en" (English)

**Example:**

```bash
log_conditional INFO "Step 0.4: Loading project language"

PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "$PROJECT_PATH/.metadata/sprint-log.json" 2>/dev/null || echo "en")

log_conditional INFO "Project language detected: ${PROJECT_LANGUAGE}"
```

### Step 0.5: Validate Directory Structure

**Purpose:** Ensure project has required directories for output.

**Required directories:**

- `01-research-dimensions/data/` - For dimension entities
- `02-refined-questions/data/` - For question entities

**Steps:**

1. Check if directories exist
2. If missing, create them: `mkdir -p "$PROJECT_PATH/$DIR_DIMENSIONS" "$PROJECT_PATH/$DIR_QUESTIONS"`
3. Log directory status

**Example:**

```bash
log_conditional INFO "Step 0.5: Validating directory structure"

mkdir -p "$PROJECT_PATH/$DIR_DIMENSIONS"
mkdir -p "$PROJECT_PATH/$DIR_QUESTIONS"

log_conditional INFO "✓ Output directories validated"
log_conditional DEBUG "  - $DIR_DIMENSIONS: exists"
log_conditional DEBUG "  - $DIR_QUESTIONS: exists"
```

### Step 0.6: Log Phase Completion

**Purpose:** Mark Phase 0 completion with metrics.

**Steps:**

```bash
# Log environment validation completion
log_conditional INFO "Environment validation complete"
log_conditional INFO "✓ CLAUDE_PLUGIN_ROOT validated"
log_conditional INFO "✓ LOG_FILE initialized: ${LOG_FILE}"
log_conditional INFO "✓ PROJECT_LANGUAGE loaded: ${PROJECT_LANGUAGE}"
log_conditional INFO "✓ Output directories validated"

# Log phase completion
log_phase "Phase 0: Environment Validation" "complete"
```

## Variable Assignments

| Variable | Source | Purpose | Example |
|----------|--------|---------|---------|
| QUESTION_FILE | Parameter | Input question file path | /project/00-initial-questions/q1.md |
| PROJECT_PATH | Extracted from QUESTION_FILE | Project root directory | /project |
| CLAUDE_PLUGIN_ROOT | Environment variable | Skill installation root | /Users/name/.claude/plugins/cogni-research |
| LOG_FILE | Generated | Logging destination | /project/reports/dimension-planner-execution-log.txt |
| PROJECT_LANGUAGE | .metadata/sprint-log.json | Content generation language | en, de, fr, etc. |

## Success Criteria

- [ ] CLAUDE_PLUGIN_ROOT validated via validate-environment.sh
- [ ] LOG_FILE initialized and writable
- [ ] PROJECT_LANGUAGE loaded (default to "en" if not found)
- [ ] Output directories (01-research-dimensions, 02-refined-questions) exist
- [ ] All variables set without errors
- [ ] Initial phase marker logged

## Common Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| CLAUDE_PLUGIN_ROOT not set | Environment not configured | Return error JSON, advise user to set environment variable |
| .logs directory creation fails | Permission denied | Return error JSON, advise checking project permissions |
| .metadata/sprint-log.json missing | Project structure incomplete | Log warning, continue with default language (en) |
| validate-environment.sh fails | Skill not installed correctly | Return error JSON with validation output |

## Next Phase

Proceed to [phase-1-input-loading.md](phase-1-input-loading.md) when all success criteria met.

---

**Size: 3.1KB** | Dependencies: validate-environment.sh, .metadata/sprint-log.json
