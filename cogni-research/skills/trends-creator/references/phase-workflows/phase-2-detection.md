# Phase 2: Research Type Detection

**Objective:** Load sprint-log.json, detect research type, determine synthesis format, and establish context for trend generation.

**Inputs:**
- `${PROJECT_PATH}/.metadata/sprint-log.json` (research type configuration)
- `${PROJECT_PATH}/00-initial-question/` (research question context)

**Outputs:**
- Research type classification (smarter-service, lean-canvas, generic)
- Project language setting (ISO 639-1 code)
- Synthesis format determination (TIPS vs STANDARD)
- Initial question context

**Phase Duration:** ~30 seconds

---

## Phase Entry Verification (MANDATORY)

Before starting Phase 2 steps, verify Phase 1 completion:

```bash
# Verify Phase 1 complete - 11-trends/data/ directory must exist
ls -d "${PROJECT_PATH}/11-trends" 2>/dev/null || echo "ERROR: 11-trends/data/ not created by Phase 1"
```

**STOP if verification fails.** Return to Phase 1 to complete directory scaffolding.

---

## Step 0.5: Initialize Phase 2 TodoWrite

Use the TodoWrite tool to create step-level tracking for Phase 2:

```markdown
USE: TodoWrite tool

ADD the following step-level todos:
- content: "Load sprint-log.json from .metadata/"
  activeForm: "Loading sprint-log.json from .metadata/"
  status: "in_progress"

- content: "Extract research_type field"
  activeForm: "Extracting research_type field"
  status: "pending"

- content: "Extract project_language field"
  activeForm: "Extracting project_language field"
  status: "pending"

- content: "Determine synthesis format (TIPS vs standard)"
  activeForm: "Determining synthesis format (TIPS vs standard)"
  status: "pending"

- content: "Detect generation mode and extract dimensions (if dimension-scoped)"
  activeForm: "Detecting generation mode and extracting dimensions (if dimension-scoped)"
  status: "pending"

- content: "Load initial question for context"
  activeForm: "Loading initial question for context"
  status: "pending"

- content: "Log detection results"
  activeForm: "Logging detection results"
  status: "pending"
```

**Mark Step 0.5 complete** after TodoWrite initialization.

---

## Step 1: Load sprint-log.json

**Goal:** Read the sprint metadata file to extract research configuration.

**Actions:**

1. **Read sprint-log.json:**
   ```bash
   # Path to sprint metadata
   ${PROJECT_PATH}/.metadata/sprint-log.json
   ```

2. **Use Read tool** to load complete file content

3. **Handle missing file gracefully:**
   - If file doesn't exist, use defaults (research_type: "generic", project_language: "en")
   - Log warning but continue execution
   - No need to fail the phase

4. **Validate JSON structure:**
   - Confirm parseable JSON format
   - Check for expected fields (research_type, project_language)

**Update todo:** Mark "Load sprint-log.json" as completed.

---

## Step 2: Extract research_type

**Goal:** Identify the type of research being conducted to determine synthesis approach.

**Valid Research Types:**
- `smarter-service` - Business model innovation research (requires TIPS framework)
- `b2b-ict-portfolio` - ICT service provider portfolio analysis (requires Portfolio Entity Discovery)
- `lean-canvas` - Business canvas exploration (standard synthesis)
- `generic` - General research topic (standard synthesis)

**Actions:**

1. **Extract research_type field** from sprint-log.json:
   ```javascript
   research_type = sprint_log.research_type || "generic"
   ```

2. **Apply defaults:**
   - If field missing: default to "generic"
   - If unrecognized value: default to "generic" and log warning

3. **Log detected type:**
   ```
   Detected research_type: {value}
   ```

**Update todo:** Mark "Extract research_type field" as completed.

---

## Step 3: Extract project_language

**Goal:** Determine the output language for synthesis documents.

**Valid Language Codes (ISO 639-1):**
- `en` - English (default)
- `de` - German
- `fr` - French
- `es` - Spanish
- `it` - Italian
- Other ISO 639-1 codes as needed

**Actions:**

1. **Extract project_language field** from sprint-log.json:
   ```javascript
   project_language = sprint_log.project_language || "en"
   ```

2. **Apply defaults:**
   - If field missing: default to "en"
   - If invalid code: default to "en" and log warning

3. **Validate language code:**
   - Confirm 2-letter ISO 639-1 format
   - Accept any valid code (no hardcoded whitelist needed)

4. **Log detected language:**
   ```
   Detected project_language: {value}
   ```

**Update todo:** Mark "Extract project_language field" as completed.

---

## Step 4: Determine Synthesis Format

**Goal:** Choose between TIPS framework, Portfolio Entity Discovery, and standard synthesis based on research type.

**Decision Logic:**

```text
IF research_type == "smarter-service":
    synthesis_format = "TIPS"
    framework = "Trend → Implications → Possibilities → Solutions"
ELIF research_type == "b2b-ict-portfolio":
    synthesis_format = "PORTFOLIO"
    framework = "Portfolio Entity Discovery (8 dimensions 0-7, variable count)"
ELSE:
    synthesis_format = "STANDARD"
    framework = "Context → Evidence → Implications"
```

**TIPS Activation Criteria:**
- PRIMARY: `research_type == "smarter-service"`
- SECONDARY: organizing_concept contains trend/innovation keywords
  - Keywords: "trend", "innovation", "disruption", "transformation", "future"

**PORTFOLIO Activation Criteria:**
- PRIMARY: `research_type == "b2b-ict-portfolio"`
- Generates portfolio entities (not trends) with variable count
- Uses 8 dimensions (0-7) and 3 service horizons

**Actions:**

1. **Apply primary decision logic:**
   - Check research_type value
   - Set synthesis_format accordingly

2. **Check secondary criteria** (if available):
   - Load organizing_concept from sprint-log.json or initial question
   - Scan for trend-related keywords
   - Override to TIPS if strong match found

3. **Log synthesis format decision:**
   ```
   Synthesis format: {TIPS|STANDARD}
   Framework: {description}
   Reason: research_type={value} [+ organizing_concept match]
   ```

4. **Set format flag** for use in later phases

**Update todo:** Mark "Determine synthesis format" as completed.

---

## Step 4.5: Detect Generation Mode and Extract Dimensions

**Goal:** Determine whether to generate trends dimension-by-dimension or cross-dimensionally, and extract dimension list if needed.

**Generation Modes:**

- `dimension-scoped` - Generate trends for a single dimension (when --dimension parameter provided) OR for each dimension separately (smarter-service)
- `cross-dimensional` - Generate trends across all dimensions together (default for all other types)

**Decision Logic (Enhanced with Dimension Parameter Override):**

```text
IF DIMENSION_FILTER_ENABLED == "true":
    # Explicit dimension parameter provided - process single dimension
    generation_mode = "dimension-scoped"
    dimension_list = [DIMENSION]  # Single dimension from Phase 1
ELIF research_type == "smarter-service":
    # Smarter-service auto-detection - process all dimensions (4 fixed)
    generation_mode = "dimension-scoped"
    LOAD dimension list from 01-research-dimensions/data/
ELIF research_type == "b2b-ict-portfolio":
    # B2B ICT Portfolio - process all 8 dimensions (0-7)
    generation_mode = "dimension-scoped"
    dimension_list = [
        "provider-profile-metrics",
        "cloud-services",
        "consulting-services",
        "connectivity-services",
        "security-services",
        "digital-workplace-services",
        "application-services",
        "managed-infrastructure-services"
    ]  # 8 dimensions (0-7) for portfolio analysis
ELSE:
    generation_mode = "cross-dimensional"
    dimension_list = [] (not applicable)
```

**Actions:**

1. **Determine generation mode (check dimension parameter first):**

   ```bash
   if [ "${DIMENSION_FILTER_ENABLED}" = "true" ]; then
       # Dimension parameter was provided in Phase 1
       generation_mode="dimension-scoped"
       dimension_list=("${DIMENSION}")
       echo "Generation mode: dimension-scoped (explicit parameter)"
       echo "Target dimension: ${DIMENSION}"
   elif [ "${research_type}" = "smarter-service" ]; then
       generation_mode="dimension-scoped"
       echo "Generation mode: dimension-scoped (smarter-service auto-detection)"
       # Will extract all dimensions below
   elif [ "${research_type}" = "b2b-ict-portfolio" ]; then
       generation_mode="dimension-scoped"
       # 8 dimensions (0-7) for portfolio analysis
       dimension_list=(
           "provider-profile-metrics"
           "cloud-services"
           "consulting-services"
           "connectivity-services"
           "security-services"
           "digital-workplace-services"
           "application-services"
           "managed-infrastructure-services"
       )
       echo "Generation mode: dimension-scoped (b2b-ict-portfolio, 8 dimensions 0-7)"
       echo "Dimensions: ${dimension_list[*]}"
   else
       generation_mode="cross-dimensional"
       echo "Generation mode: cross-dimensional"
   fi
   ```

2. **Extract dimensions (if dimension-scoped mode AND not already set by parameter):**

   **Skip if dimension parameter was provided:**

   ```bash
   if [ "${DIMENSION_FILTER_ENABLED}" = "true" ]; then
       echo "Skipping dimension extraction - using explicit parameter: ${DIMENSION}"
       # dimension_list already set in Step 1 above
   else
       # Extract all dimensions from directory
   fi
   ```

   **Locate dimension entities (only if extracting all):**

   ```bash
   # Find dimension entity files
   ${PROJECT_PATH}/01-research-dimensions/data/dimension-*.md
   ```

   **Extract dimension slugs** from filenames:

   ```text
   Pattern: dimension-{slug}-{entity-id}.md
   Example: dimension-externe-effekte-abc123.md → "externe-effekte"
   Example: dimension-neue-horizonte-def456.md → "neue-horizonte"
   ```

   **Parse each filename:**

   - Remove "dimension-" prefix
   - Remove entity ID suffix (everything after last hyphen + 6 chars)
   - Store clean dimension slug

   **Build dimension list:**

   ```javascript
   dimension_list = [
     "externe-effekte",
     "neue-horizonte",
     "digitale-wertetreiber",
     "digitales-fundament"
   ]
   ```

   **Validate dimension count (smarter-service only, not for explicit parameter):**
   - Expected: 4 dimensions for smarter-service
   - If count mismatch: log warning but continue
   - Dimensions represent: Externe Effekte, Neue Horizonte, Digitale Wertetreiber, Digitales Fundament

3. **Store for Phase 4 use:**
   - generation_mode flag controls Phase 4 processing logic
   - dimension_list drives iteration in dimension-scoped mode
   - Empty dimension_list for cross-dimensional mode

4. **Log generation mode decision:**

   ```text
   Generation mode: {dimension-scoped|cross-dimensional}
   Reason: {explicit --dimension parameter | research_type=smarter-service | default}
   [IF dimension-scoped with explicit parameter] Target dimension: {slug}
   [IF dimension-scoped without parameter] Dimensions found: {count}
   [IF dimension-scoped without parameter] Dimension list: {comma-separated slugs}
   ```

**Self-verification questions:**

- Did you check DIMENSION_FILTER_ENABLED first before research_type?
- If dimension parameter provided: Did you set dimension_list to single dimension?
- If dimension-scoped without parameter: Did you load dimension files from 01-research-dimensions/data/?
- If dimension-scoped without parameter: Did you extract dimension slugs correctly?
- Did you store generation_mode and dimension_list for Phase 3 and 4?

**Update todo:** Mark "Detect generation mode and extract dimensions" as completed.

---

## Step 5: Load Initial Question

**Goal:** Extract the research question and metadata to provide context for trend generation.

**Actions:**

1. **Locate initial question file:**
   ```bash
   # Find first markdown file in 00-initial-question/data/
   ${PROJECT_PATH}/00-initial-question/data/*.md
   ```

2. **Read complete file** using Read tool

3. **Extract key elements:**
   - **Research question text** (main body content)
   - **YAML frontmatter** (if present):
     - organizing_concept
     - research_type (cross-check with sprint-log)
     - tags
     - Any custom metadata

4. **Parse organizing_concept:**
   - This guides dimension identification
   - May override synthesis format decision
   - Used in Phase 3 for dimension naming

5. **Store question context** for reference in later phases:
   - Full question text
   - First 100 characters for logging
   - Organizing concept (if specified)

6. **Log loaded context:**
   ```
   Initial question: {first 100 chars}...
   Organizing concept: {value or "none"}
   ```

**Update todo:** Mark "Load initial question for context" as completed.

---

## Step 6: Log Detection Results

**Goal:** Create comprehensive summary of Phase 2 detection outcomes.

**Log Format:**

```
=== Phase 2: Research Type Detection Complete ===

Research Configuration:
  - research_type: {smarter-service|lean-canvas|generic}
  - project_language: {ISO 639-1 code}
  - synthesis_format: {TIPS|STANDARD}
  - generation_mode: {dimension-scoped|cross-dimensional}
  - dimension_filter: {enabled (explicit parameter) | disabled}

[IF dimension-scoped mode with explicit parameter]
Dimension Filter Configuration:
  - target_dimension: {slug}
  - filter_source: explicit --dimension parameter

[IF dimension-scoped mode without explicit parameter]
Dimension Configuration:
  - dimensions_found: {count}
  - dimension_list: {comma-separated slugs}
  - filter_source: smarter-service auto-detection

Context Loaded:
  - initial_question: {first 100 chars}...
  - organizing_concept: {value or "none"}

Framework Selection:
  - {TIPS: Trend → Implications → Possibilities → Solutions}
  - {STANDARD: Context → Evidence → Implications}

Ready for Phase 3: Dimension Synthesis
```

**Actions:**

1. **Compile detection results** from Steps 1-5 (including Step 4.5)

2. **Format summary** with clear sections

3. **Output to user** via direct message (not file write)

4. **No file creation** - this is informational logging only

**Update todo:** Mark "Log detection results" as completed.

---

## Before Marking Phase 2 Complete

**MANDATORY self-verification questions - answer each explicitly:**

1. **Did you load sprint-log.json** (or gracefully handle missing file)?
   - [ ] Yes, loaded successfully OR applied defaults

2. **Did you extract research_type?**
   - [ ] Yes, value stored: {value}

3. **Did you extract project_language?**
   - [ ] Yes, value stored: {value}

4. **Did you determine synthesis_format?**
   - [ ] Yes, TIPS or STANDARD selected with clear reasoning

4.5. **Did you detect generation_mode?**

   - [ ] Yes, checked DIMENSION_FILTER_ENABLED first
   - [ ] If explicit dimension parameter: set dimension_list to single dimension
   - [ ] If smarter-service (no explicit param): dimension list extracted from 01-research-dimensions/data/
   - [ ] generation_mode correctly set to dimension-scoped or cross-dimensional

5. **Did you load initial question?**
   - [ ] Yes, full content read and context extracted

6. **Did you log all detection results?**
   - [ ] Yes, comprehensive summary provided to user

**If ANY answer is NO:** Return to that step and complete before proceeding.

**If ALL answers are YES:** Proceed to Phase Completion Checklist.

---

## Phase Completion Checklist

Mark each item complete before advancing to Phase 3:

- [ ] Phase entry verification passed (11-trends/data/ exists)
- [ ] sprint-log.json loaded (or defaults applied)
- [ ] research_type extracted and validated
- [ ] project_language extracted and validated
- [ ] synthesis_format determined (TIPS vs STANDARD)
- [ ] generation_mode determined (dimension-scoped vs cross-dimensional)
- [ ] dimension_list extracted (if dimension-scoped mode)
- [ ] Initial question loaded with context
- [ ] All step-level todos marked completed
- [ ] Detection results logged comprehensively

**Phase 2 Success Criteria:**
- All configuration values known
- Synthesis approach determined
- Research context established
- Ready to process dimension files

**Next Phase:** Phase 3 - Dimension Synthesis (load and analyze dimension files using detected format)
