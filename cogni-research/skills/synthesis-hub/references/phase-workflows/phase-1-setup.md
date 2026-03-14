# Phase 1: Setup & Environment

**Objective:** Validate parameters and initialize logging infrastructure.

---

## Phase Entry Verification

N/A - This is the first phase of the synthesis-hub workflow.

---

## Step 0.5: Initialize Phase 1 TodoWrite

**USE:** TodoWrite tool to create step-level todos for Phase 1.

**ADD** the following todos:

```markdown
- content: "Validate PROJECT_PATH parameter"
  activeForm: "Validating PROJECT_PATH parameter"
  status: "in_progress"

- content: "Verify part1_complete in sprint-log.json"
  activeForm: "Verifying part1_complete in sprint-log.json"
  status: "pending"

- content: "Check entity directories exist"
  activeForm: "Checking entity directories exist"
  status: "pending"

- content: "Initialize logging infrastructure"
  activeForm: "Initializing logging infrastructure"
  status: "pending"

- content: "Mark Phase 1 complete"
  activeForm: "Marking Phase 1 complete"
  status: "pending"
```

**Mark Step 0.5 complete** after TodoWrite initialization, then proceed to Step 1.

---

## Step 1: Validate PROJECT_PATH Parameter

**Purpose:** Ensure the research project path is valid and contains the expected structure.

**Actions:**

1. **Check PROJECT_PATH parameter provided:**
   - Verify that PROJECT_PATH was passed as a parameter
   - If missing, exit with error message

2. **Verify path exists and is a directory:**
   ```bash
   if [ ! -d "${PROJECT_PATH}" ]; then
     echo "ERROR: PROJECT_PATH does not exist or is not a directory: ${PROJECT_PATH}"
     exit 1
   fi
   ```

3. **Check for .metadata/ directory presence:**
   ```bash
   if [ ! -d "${PROJECT_PATH}/.metadata" ]; then
     echo "ERROR: Missing .metadata/ directory. Not a valid research project: ${PROJECT_PATH}"
     exit 1
   fi
   ```

4. **Verify sprint-log.json exists:**
   ```bash
   if [ ! -f "${PROJECT_PATH}/.metadata/sprint-log.json" ]; then
     echo "ERROR: Missing sprint-log.json in .metadata/ directory"
     exit 1
   fi
   ```

**Output:**
- Log: "PROJECT_PATH validated: ${PROJECT_PATH}"

**Step Trigger:**
- Mark "Validate PROJECT_PATH parameter" todo as completed
- Mark "Verify part1_complete in sprint-log.json" todo as in_progress

---

## Step 2: Verify part1_complete

**Purpose:** Ensure all Part 1 research entities have been created before synthesis.

**Actions:**

1. **Load sprint-log.json:**
   ```bash
   SPRINT_LOG="${PROJECT_PATH}/.metadata/sprint-log.json"
   if [ ! -f "${SPRINT_LOG}" ]; then
     echo "ERROR: sprint-log.json not found at ${SPRINT_LOG}"
     exit 1
   fi
   ```

2. **Extract part1_complete field:**
   ```bash
   PART1_COMPLETE=$(jq -r '.part1_complete // false' "${SPRINT_LOG}")
   ```

3. **Validate part1_complete is true:**
   ```bash
   if [ "${PART1_COMPLETE}" != "true" ]; then
     echo "ERROR: part1_complete is not true in sprint-log.json"
     echo "Current value: ${PART1_COMPLETE}"
     echo "REMEDY: Run trends-creator to complete Part 1 research entities"
     exit 1
   fi
   ```

4. **Log verification:**
   ```bash
   echo "Part 1 research complete: verified (part1_complete = true)"
   ```

**Output:**
- Log: "part1_complete verified: true"

**Step Trigger:**
- Mark "Verify part1_complete in sprint-log.json" todo as completed
- Mark "Check entity directories exist" todo as in_progress

---

## Step 3: Check Entity Directories Exist

**Purpose:** Verify that the research project contains the minimum required entity directories for synthesis.

**Required Directories (must exist):**

1. **00-initial-question/data/** - Must exist with at least 1 file
   ```bash
   if [ ! -d "${PROJECT_PATH}/00-initial-question/data" ]; then
     echo "ERROR: Missing required directory: 00-initial-question/data/"
     exit 1
   fi
   INITIAL_Q_COUNT=$(find "${PROJECT_PATH}/00-initial-question/data" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   if [ "${INITIAL_Q_COUNT}" -eq 0 ]; then
     echo "ERROR: 00-initial-question/data/ directory must contain at least 1 markdown file"
     exit 1
   fi
   echo "Found ${INITIAL_Q_COUNT} file(s) in 00-initial-question/data/"
   ```

2. **01-research-dimensions/data/** - Must exist with at least 1 file
   ```bash
   if [ ! -d "${PROJECT_PATH}/01-research-dimensions" ]; then
     echo "ERROR: Missing required directory: 01-research-dimensions/data/"
     exit 1
   fi
   DIMENSIONS_COUNT=$(find "${PROJECT_PATH}/01-research-dimensions" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   if [ "${DIMENSIONS_COUNT}" -eq 0 ]; then
     echo "ERROR: 01-research-dimensions/data/ directory must contain at least 1 markdown file"
     exit 1
   fi
   echo "Found ${DIMENSIONS_COUNT} file(s) in 01-research-dimensions/data/"
   ```

3. **02-refined-questions/data/** - Must exist (may be empty)
   ```bash
   if [ ! -d "${PROJECT_PATH}/02-refined-questions" ]; then
     echo "WARNING: Missing optional directory: 02-refined-questions/data/"
     REFINED_Q_COUNT=0
   else
     REFINED_Q_COUNT=$(find "${PROJECT_PATH}/02-refined-questions" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
     echo "Found ${REFINED_Q_COUNT} file(s) in 02-refined-questions/data/"
   fi
   ```

4. **05-domain-concepts/data/** - Must exist (may be empty)
   ```bash
   if [ ! -d "${PROJECT_PATH}/05-domain-concepts" ]; then
     echo "WARNING: Missing optional directory: 05-domain-concepts/data/"
     CONCEPTS_COUNT=0
   else
     CONCEPTS_COUNT=$(find "${PROJECT_PATH}/05-domain-concepts" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
     echo "Found ${CONCEPTS_COUNT} file(s) in 05-domain-concepts/data/"
   fi
   ```

5. **06-megatrends/data/** - Must exist (may be empty)
   ```bash
   if [ ! -d "${PROJECT_PATH}/06-megatrends" ]; then
     echo "WARNING: Missing optional directory: 06-megatrends/data/"
     MEGATRENDS_COUNT=0
   else
     MEGATRENDS_COUNT=$(find "${PROJECT_PATH}/06-megatrends" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
     echo "Found ${MEGATRENDS_COUNT} file(s) in 06-megatrends/data/"
   fi
   ```

6. **11-trends/data/** - Must exist with at least 1 file
   ```bash
   if [ ! -d "${PROJECT_PATH}/11-trends" ]; then
     echo "ERROR: Missing required directory: 11-trends/data/"
     echo "REMEDY: Run trends-creator to generate trend entities"
     exit 1
   fi
   TRENDS_COUNT=$(find "${PROJECT_PATH}/11-trends" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   if [ "${TRENDS_COUNT}" -eq 0 ]; then
     echo "ERROR: 11-trends/data/ directory must contain at least 1 markdown file"
     echo "REMEDY: Run trends-creator to generate trend entities"
     exit 1
   fi
   echo "Found ${TRENDS_COUNT} file(s) in 11-trends/data/"
   ```

**Output:**
- Log entity counts for each directory
- Store counts in variables for Phase 5 reporting

**Step Trigger:**
- Mark "Check entity directories exist" todo as completed
- Mark "Initialize logging infrastructure" todo as in_progress

---

## Step 4: Initialize Logging

**Purpose:** Set up enhanced logging infrastructure for execution tracking and debugging.

**Actions:**

1. **Source enhanced logging utility:**
   ```bash
   if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]; then
     source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
     echo "Enhanced logging utility loaded"
   else
     echo "WARNING: Enhanced logging utility not found, using basic logging"
     # Fallback: Define basic log functions
     log_phase() { echo "[PHASE] $1: $2"; }
     log_metric() { echo "[METRIC] $1: $2 $3"; }
   fi
   ```

2. **Create .logs/ directory if needed:**
   ```bash
   if [ ! -d "${PROJECT_PATH}/.logs" ]; then
     mkdir -p "${PROJECT_PATH}/.logs"
     echo "Created .logs/ directory"
   else
     echo ".logs/ directory already exists"
   fi
   ```

3. **Initialize skill-specific log file:**
   ```bash
   SKILL_NAME="synthesis-hub"
   LOG_FILE="${PROJECT_PATH}/.metadata/${SKILL_NAME}-execution-log.txt"
   echo "=== Synthesis Creator Execution Log ===" > "${LOG_FILE}"
   echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "${LOG_FILE}"
   echo "Project: ${PROJECT_PATH}" >> "${LOG_FILE}"
   echo "" >> "${LOG_FILE}"
   echo "Log file initialized: ${LOG_FILE}"
   ```

4. **Log Phase 1 start:**
   ```bash
   log_phase "Phase 1: Setup & Environment" "start"
   ```

5. **Log environment configuration:**
   ```bash
   PROJECT_NAME=$(jq -r '.project_name // "unknown"' "${PROJECT_PATH}/.metadata/sprint-log.json")
   echo "Research Project: ${PROJECT_NAME}"
   echo "PROJECT_PATH: ${PROJECT_PATH}"
   echo "Entity Directory Summary:"
   echo "  - 00-initial-question/data/: ${INITIAL_Q_COUNT} file(s)"
   echo "  - 01-research-dimensions/data/: ${DIMENSIONS_COUNT} file(s)"
   echo "  - 02-refined-questions/data/: ${REFINED_Q_COUNT} file(s)"
   echo "  - 05-domain-concepts/data/: ${CONCEPTS_COUNT} file(s)"
   echo "  - 06-megatrends/data/: ${MEGATRENDS_COUNT} file(s)"
   echo "  - 11-trends/data/: ${TRENDS_COUNT} file(s)"
   ```

6. **Calculate total entity count:**
   ```bash
   TOTAL_ENTITIES=$((INITIAL_Q_COUNT + DIMENSIONS_COUNT + REFINED_Q_COUNT + CONCEPTS_COUNT + MEGATRENDS_COUNT + TRENDS_COUNT))
   echo "Total entities available: ${TOTAL_ENTITIES}"
   log_metric "total_entities" "${TOTAL_ENTITIES}" "count"
   ```

**Output:**
- Log file created at: `${PROJECT_PATH}/.metadata/synthesis-hub-execution-log.txt`
- Environment configuration logged
- Total entity count calculated

**Step Trigger:**
- Mark "Initialize logging infrastructure" todo as completed
- Mark "Mark Phase 1 complete" todo as in_progress

---

## Before Marking Phase 1 Complete

**Self-Verification Questions:**

1. **Is PROJECT_PATH provided and valid?**
   - Path exists as a directory: YES/NO
   - .metadata/ directory exists: YES/NO
   - sprint-log.json exists: YES/NO

2. **Does part1_complete = true in sprint-log.json?**
   - Verified part1_complete field: YES/NO
   - Value is exactly "true": YES/NO

3. **Do all required entity directories exist?**
   - 00-initial-question/data/ with files: YES/NO
   - 01-research-dimensions/data/ with files: YES/NO
   - 11-trends/data/ with files: YES/NO

4. **Is logging initialized?**
   - Enhanced logging utility loaded: YES/NO
   - Log file created in .logs/: YES/NO
   - Phase 1 start logged: YES/NO
   - Entity counts logged: YES/NO

**IF ANY NO: STOP.** Return to incomplete step and resolve issue.

---

## Step 5: Mark Phase 1 Complete

**Purpose:** Document Phase 1 completion and prepare for Phase 2.

**Actions:**

1. **Log Phase 1 completion:**
   ```bash
   log_phase "Phase 1: Setup & Environment" "complete"
   echo "Phase 1 completed successfully"
   ```

2. **Update TodoWrite:**
   - Mark "Mark Phase 1 complete" todo as completed
   - Add Phase 2 phase-level todo as in_progress

3. **Document verification results:**
   ```bash
   echo "Phase 1 Self-Verification:"
   echo "  - PROJECT_PATH validated: YES"
   echo "  - part1_complete verified: YES"
   echo "  - Entity directories confirmed: YES"
   echo "  - Logging initialized: YES"
   echo ""
   echo "Ready to proceed to Phase 2: Research Type Detection"
   ```

**Output:**
- Phase 1 marked complete
- Phase 2 ready to begin
- All verification criteria met

**Step Trigger:**
- Mark "Mark Phase 1 complete" todo as completed
- Proceed to Phase 2 reference file

---

## Phase Completion Checklist

Before proceeding to Phase 2, verify:

- [ ] PROJECT_PATH validated and confirmed as valid research project
- [ ] part1_complete = true verified in sprint-log.json
- [ ] Required directories verified with content:
  - [ ] 00-initial-question/data/ (1+ files)
  - [ ] 01-research-dimensions/data/ (1+ files)
  - [ ] 11-trends/data/ (1+ files)
- [ ] Optional directories checked:
  - [ ] 02-refined-questions/data/
  - [ ] 05-domain-concepts/data/
  - [ ] 06-megatrends/data/
- [ ] .logs/ directory created
- [ ] Logging initialized with enhanced-logging.sh
- [ ] Log file created at .logs/synthesis-hub-execution-log.txt
- [ ] Entity counts calculated and logged
- [ ] Phase 1 start and complete logged
- [ ] All Phase 1 step-level todos marked as completed
- [ ] Self-verification questions answered YES

**Next Phase:** Proceed to [Phase 2: Research Type Detection](phase-2-detection.md) to determine report template.

---

## Phase 1 Summary

**Validated:**
- Research project structure
- Part 1 completion status
- Entity directory presence and content

**Initialized:**
- Enhanced logging infrastructure
- Execution log file
- .logs/ output directory

**Prepared:**
- Entity count metrics
- Project configuration
- Phase 2 prerequisites

**Exit Criteria:**
- All validation checks passed
- Logging infrastructure ready
- Entity directories confirmed
- Ready for research type detection
