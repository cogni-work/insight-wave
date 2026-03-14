# Phase 1: Setup & Environment

**Objective:** Validate research project structure and initialize resources for trend synthesis.

## Phase Entry Verification

N/A - This is the first phase of the trends-creator workflow.

## Step 0.5: Initialize Phase 1 TodoWrite

**USE:** TodoWrite tool to create step-level todos for Phase 1.

**ADD** the following todos:

```markdown
- content: "Validate PROJECT_PATH parameter"
  activeForm: "Validating PROJECT_PATH parameter"
  status: "in_progress"

- content: "Parse and validate DIMENSION parameter (if provided)"
  activeForm: "Parsing and validating DIMENSION parameter"
  status: "pending"

- content: "Check required entity directories exist"
  activeForm: "Checking required entity directories exist"
  status: "pending"

- content: "Create 11-trends/data/ directory if needed"
  activeForm: "Creating 11-trends/data/ directory if needed"
  status: "pending"

- content: "Initialize citation registry"
  activeForm: "Initializing citation registry"
  status: "pending"

- content: "Log environment setup complete"
  activeForm: "Logging environment setup complete"
  status: "pending"
```

## Step 1: Validate PROJECT_PATH

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
- Mark "Parse and validate DIMENSION parameter" todo as in_progress

## Step 1.5: Parse and Validate DIMENSION Parameter

**Purpose:** Parse optional dimension parameter and validate it exists in the research project.

**Actions:**

1. **Check if DIMENSION parameter provided:**

   The dimension parameter may be passed in different ways:
   - Directly as `--dimension {slug}` parameter
   - Extracted from prompt text pattern: "for dimension: {slug}"

   ```bash
   # Check for explicit parameter
   if [ -n "${DIMENSION}" ]; then
     echo "Dimension parameter provided: ${DIMENSION}"
   else
     # Check for dimension in prompt pattern
     DIMENSION=$(echo "${PROMPT_TEXT}" | grep -oP 'for dimension: \K[a-z0-9-]+' || echo "")
     if [ -n "${DIMENSION}" ]; then
       echo "Dimension extracted from prompt: ${DIMENSION}"
     else
       echo "No dimension filter - operating in cross-dimensional mode"
       DIMENSION=""
     fi
   fi
   ```

2. **Validate dimension exists (if provided):**

   ```bash
   if [ -n "${DIMENSION}" ]; then
     # Find dimension entity file matching the slug
     DIMENSION_FILE=$(find "${PROJECT_PATH}/01-research-dimensions" -name "dimension-${DIMENSION}-*.md" 2>/dev/null | head -1)

     if [ -z "${DIMENSION_FILE}" ]; then
       echo "ERROR: Dimension not found in 01-research-dimensions/data/: ${DIMENSION}"
       echo "Available dimensions:"
       ls -1 "${PROJECT_PATH}/01-research-dimensions/data/" | grep "^dimension-" | sed 's/^dimension-//' | sed 's/-[a-f0-9]\{8\}\.md$//'
       exit 1
     fi

     echo "Dimension validated: ${DIMENSION}"
     echo "Dimension file: ${DIMENSION_FILE}"
     DIMENSION_FILTER_ENABLED="true"
   else
     DIMENSION_FILTER_ENABLED="false"
   fi
   ```

3. **Store dimension context for downstream phases:**

   ```bash
   # Export for Phase 2 and Phase 3 access
   export DIMENSION="${DIMENSION}"
   export DIMENSION_FILTER_ENABLED="${DIMENSION_FILTER_ENABLED}"

   if [ "${DIMENSION_FILTER_ENABLED}" = "true" ]; then
     echo "=== Dimension-Scoped Mode Activated ==="
     echo "Dimension: ${DIMENSION}"
     echo "Filter enabled: ${DIMENSION_FILTER_ENABLED}"
   else
     echo "=== Cross-Dimensional Mode ==="
     echo "Processing all dimensions"
   fi
   ```

**Output:**

- DIMENSION variable set (empty or slug value)
- DIMENSION_FILTER_ENABLED variable set (true/false)
- Log: Dimension mode status

**Step Trigger:**

- Mark "Parse and validate DIMENSION parameter" todo as completed
- Mark "Check required entity directories exist" todo as in_progress

## Step 2: Check Required Entity Directories

**Purpose:** Verify that the research project contains the minimum required entity directories with content.

**Required Directories (must exist with at least 1 file):**

1. **00-initial-question/data/**
   ```bash
   INITIAL_Q_COUNT=$(find "${PROJECT_PATH}/00-initial-question/data" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   if [ "${INITIAL_Q_COUNT}" -eq 0 ]; then
     echo "ERROR: 00-initial-question/data/ directory must contain at least 1 markdown file"
     exit 1
   fi
   echo "Found ${INITIAL_Q_COUNT} file(s) in 00-initial-question/data/"
   ```

2. **01-research-dimensions/data/**
   ```bash
   DIMENSIONS_COUNT=$(find "${PROJECT_PATH}/01-research-dimensions" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   if [ "${DIMENSIONS_COUNT}" -eq 0 ]; then
     echo "ERROR: 01-research-dimensions/data/ directory must contain at least 1 markdown file"
     exit 1
   fi
   echo "Found ${DIMENSIONS_COUNT} file(s) in 01-research-dimensions/data/"
   ```

3. **04-findings/data/**
   ```bash
   FINDINGS_COUNT=$(find "${PROJECT_PATH}/04-findings" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   if [ "${FINDINGS_COUNT}" -eq 0 ]; then
     echo "ERROR: 04-findings/data/ directory must contain at least 1 markdown file"
     exit 1
   fi
   echo "Found ${FINDINGS_COUNT} file(s) in 04-findings/data/"
   ```

**Optional but Expected Directories:**

4. **02-refined-questions/data/**
   ```bash
   REFINED_Q_COUNT=$(find "${PROJECT_PATH}/02-refined-questions" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   echo "Found ${REFINED_Q_COUNT} file(s) in 02-refined-questions/data/"
   ```

5. **05-domain-concepts/data/**
   ```bash
   CONCEPTS_COUNT=$(find "${PROJECT_PATH}/05-domain-concepts" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   echo "Found ${CONCEPTS_COUNT} file(s) in 05-domain-concepts/data/"
   ```

6. **06-megatrends/data/**
   ```bash
   MEGATRENDS_COUNT=$(find "${PROJECT_PATH}/06-megatrends" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
   echo "Found ${MEGATRENDS_COUNT} file(s) in 06-megatrends/data/"
   ```

**Output:**
- Log entity counts for each directory
- Store counts in variables for Phase 5 logging

**Step Trigger:**
- Mark "Check required entity directories exist" todo as completed
- Mark "Create 11-trends/data/ directory if needed" todo as in_progress

## Step 3: Create 11-trends/data/ Directory

**Purpose:** Ensure the output directory exists for synthesized trends.

**Actions:**

1. **Create directory if it doesn't exist:**
   ```bash
   if [ ! -d "${PROJECT_PATH}/$DIR_TRENDS" ]; then
     mkdir -p "${PROJECT_PATH}/$DIR_TRENDS"
     echo "Created $DIR_TRENDS/data/ directory"
   else
     echo "$DIR_TRENDS/data/ directory already exists"
   fi
   ```

2. **Verify directory is writable:**
   ```bash
   if [ ! -w "${PROJECT_PATH}/$DIR_TRENDS" ]; then
     echo "ERROR: $DIR_TRENDS/data/ directory is not writable"
     exit 1
   fi
   ```

**Output:**
- Log: "11-trends/data/ directory ready at ${PROJECT_PATH}/11-trends"

**Step Trigger:**
- Mark "Create 11-trends/data/ directory if needed" todo as completed
- Mark "Initialize citation registry" todo as in_progress

## Step 4: Initialize Citation Registry

**Purpose:** Create a temporary citation registry to track all entity citations used during trend synthesis.

**Actions:**

1. **Create temporary citation registry file:**
   ```bash
   CITATION_REGISTRY="${PROJECT_PATH}/.metadata/tmp_citation_registry.csv"
   echo "citation_num,entity_path,first_use_context" > "${CITATION_REGISTRY}"
   echo "Initialized citation registry at ${CITATION_REGISTRY}"
   ```

2. **Store registry path in environment:**
   - This file will be populated in Phase 4 (Cross-Reference Citations)
   - Each citation will receive a sequential number [1], [2], [3], etc.
   - Format: citation_num, relative entity path, context where first used

**Output:**
- Log: "Citation registry initialized: ${CITATION_REGISTRY}"

**Step Trigger:**
- Mark "Initialize citation registry" todo as completed
- Mark "Log environment setup complete" todo as in_progress

## Step 5: Log Environment Setup

**Purpose:** Capture and log the complete environment configuration for the trend synthesis process.

**Actions:**

1. **Extract research project name:**
   ```bash
   PROJECT_NAME=$(jq -r '.project_name // "unknown"' "${PROJECT_PATH}/.metadata/sprint-log.json")
   echo "Research Project: ${PROJECT_NAME}"
   ```

2. **Log PROJECT_PATH:**
   ```bash
   echo "PROJECT_PATH: ${PROJECT_PATH}"
   ```

3. **Log entity counts per directory:**
   ```bash
   echo "Entity Directory Summary:"
   echo "  - 00-initial-question/data/: ${INITIAL_Q_COUNT} file(s)"
   echo "  - 01-research-dimensions/data/: ${DIMENSIONS_COUNT} file(s)"
   echo "  - 02-refined-questions/data/: ${REFINED_Q_COUNT} file(s)"
   echo "  - 04-findings/data/: ${FINDINGS_COUNT} file(s)"
   echo "  - 05-domain-concepts/data/: ${CONCEPTS_COUNT} file(s)"
   echo "  - 06-megatrends/data/: ${MEGATRENDS_COUNT} file(s)"
   ```

4. **Log total entity count:**
   ```bash
   TOTAL_ENTITIES=$((INITIAL_Q_COUNT + DIMENSIONS_COUNT + REFINED_Q_COUNT + FINDINGS_COUNT + CONCEPTS_COUNT + MEGATRENDS_COUNT))
   echo "Total entities available: ${TOTAL_ENTITIES}"
   ```

5. **Log output directory:**
   ```bash
   echo "Output directory: ${PROJECT_PATH}/11-trends"
   ```

6. **Log dimension filter status:**
   ```bash
   if [ "${DIMENSION_FILTER_ENABLED}" = "true" ]; then
     echo "Dimension Filter: ENABLED"
     echo "  - Target dimension: ${DIMENSION}"
     echo "  - Mode: dimension-scoped (single dimension)"
   else
     echo "Dimension Filter: DISABLED"
     echo "  - Mode: cross-dimensional (all dimensions)"
   fi
   ```

**Output:**

- Complete environment configuration summary
- Dimension filter status logged
- Ready to proceed to Phase 2

**Step Trigger:**
- Mark "Log environment setup complete" todo as completed

## Before Marking Phase 1 Complete

**Self-Verification Questions:**

1. **Did you validate PROJECT_PATH exists?**
   - Confirmed path exists as a directory
   - Verified .metadata/ directory is present
   - Checked sprint-log.json exists

2. **Did you parse and validate DIMENSION parameter (if provided)?**
   - Checked for explicit --dimension parameter or prompt pattern
   - If dimension provided, validated it exists in 01-research-dimensions/data/
   - Set DIMENSION_FILTER_ENABLED flag appropriately
   - Logged dimension mode (scoped or cross-dimensional)

3. **Did you check required directories have files?**
   - Verified 00-initial-question/data/ has at least 1 file
   - Verified 01-research-dimensions/data/ has at least 1 file
   - Verified 04-findings/data/ has at least 1 file
   - Counted files in optional directories

4. **Did you create 11-trends/data/ directory?**
   - Directory exists and is writable
   - Logged creation or existence status

5. **Did you initialize citation registry?**
   - Created tmp_citation_registry.csv in .metadata/
   - Added CSV header row
   - Stored registry path for later phases

6. **Did you log environment setup?**
   - Extracted and logged project name
   - Logged PROJECT_PATH
   - Logged entity counts for all directories
   - Logged total entity count
   - Logged output directory path

## Phase Completion Checklist

Before proceeding to Phase 2, verify:

- [ ] PROJECT_PATH validated and confirmed as valid research project
- [ ] DIMENSION parameter parsed and validated (if provided)
- [ ] DIMENSION_FILTER_ENABLED flag set appropriately
- [ ] Required directories (00-initial-question/data/, 01-research-dimensions/data/, 04-findings/data/) verified with content
- [ ] 11-trends/data/ directory created and writable
- [ ] Citation registry initialized at .metadata/tmp_citation_registry.csv
- [ ] Environment setup logged with project name, entity counts, and dimension filter status
- [ ] All Phase 1 step-level todos marked as completed

**Next Phase:** Proceed to Phase 2 - Research Type Detection to detect research type and generation mode.
