# Phase 2: Research Type Detection

**Objective:** Detect research type from sprint log to determine report template.

**Inputs:**
- `${PROJECT_PATH}/.metadata/sprint-log.json` (research type configuration)

**Outputs:**
- Research type classification (smarter-service, lean-canvas, generic)
- Report template selection (TIPS, Canvas, Standard)
- Project language setting (ISO 639-1 code)

**Phase Duration:** ~15 seconds

---

## Phase Entry Verification (MANDATORY)

Before starting Phase 2 steps, verify Phase 1 completion:

```bash
# Verify Phase 1 complete - logging initialized
# Check that part1_complete = true in execution context
```

**Required Phase 1 artifacts:**
- Logging initialized
- PROJECT_PATH validated
- part1_complete = true

**STOP if verification fails.** Return to Phase 1 to complete initialization.

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

- content: "Select report template based on research type"
  activeForm: "Selecting report template based on research type"
  status: "pending"

- content: "Mark Phase 2 complete"
  activeForm: "Marking Phase 2 complete"
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
   - If file doesn't exist, use defaults:
     - research_type: "generic"
     - project_language: "en"
   - Log warning but continue execution
   - No need to fail the phase

4. **Validate JSON structure:**
   - Confirm parseable JSON format
   - Check for expected fields (research_type, project_language)

5. **Extract key fields:**
   ```javascript
   research_type = sprint_log.research_type || "generic"
   project_language = sprint_log.project_language || "en"
   ```

6. **Log loaded values:**
   ```
   Loaded sprint-log.json:
     - research_type: {value}
     - project_language: {value}
   ```

**Update todo:** Mark "Load sprint-log.json from .metadata/" as completed.

---

## Step 2: Extract research_type Field

**Goal:** Identify the type of research being conducted to determine report template.

**Valid Research Types:**
- `smarter-service` - Business model innovation research (requires TIPS format)
- `lean-canvas` - Business canvas exploration (canvas format)
- `generic` - General research topic (standard format)

**Actions:**

1. **Validate research_type value:**
   ```javascript
   // Apply defaults for missing or invalid values
   if (!research_type || !["smarter-service", "lean-canvas", "generic"].includes(research_type)) {
     research_type = "generic"
     log_warning("Unrecognized research_type, defaulting to 'generic'")
   }
   ```

2. **Log detected type:**
   ```
   Research Type Detection:
     - Detected: {value}
     - Valid: {true|false}
     - Applied: {final value after defaults}
   ```

**Update todo:** Mark "Extract research_type field" as completed.

---

## Step 3: Select Report Template

**Goal:** Choose the appropriate report template based on research type.

**Template Mapping:**

| research_type | Template | Template File | Focus |
|---------------|----------|---------------|-------|
| smarter-service | TIPS | tips-format.md | Trend, Implications, Possibilities, Solutions |
| lean-canvas | Canvas | canvas-format.md | Business model canvas sections |
| generic | Standard | standard-format.md | Executive summary format |

**Decision Logic:**

```
IF research_type == "smarter-service":
    template = "TIPS"
    template_file = "references/templates/tips-format.md"
    framework = "Trend → Implications → Possibilities → Solutions"

ELSE IF research_type == "lean-canvas":
    template = "Canvas"
    template_file = "references/templates/canvas-format.md"
    framework = "Problem → Solution → Value Proposition"

ELSE:
    template = "Standard"
    template_file = "references/templates/standard-format.md"
    framework = "Context → Evidence → Implications"
```

**Actions:**

1. **Apply template selection logic:**
   - Check research_type value
   - Set template name accordingly
   - Set template_file path
   - Set framework description

2. **Verify template file exists:**
   ```bash
   # Check that template file is available
   # Template location: references/templates/{template-name}.md
   ```

3. **Log template selection:**
   ```
   Report Template Selection:
     - research_type: {value}
     - template: {TIPS|Canvas|Standard}
     - template_file: {path}
     - framework: {description}
   ```

4. **Store template information** for use in Phase 3:
   - template_name
   - template_file_path
   - framework_description
   - project_language

**Update todo:** Mark "Select report template based on research type" as completed.

---

## Before Marking Phase 2 Complete

**MANDATORY self-verification questions - answer each explicitly:**

1. **Did you load sprint-log.json** (or gracefully handle missing file)?
   - [ ] Yes, loaded successfully OR applied defaults

2. **Did you extract research_type field?**
   - [ ] Yes, value stored: {value}

3. **Did you select appropriate template?**
   - [ ] Yes, template selected: {TIPS|Canvas|Standard}

4. **Do you know which template file to use?**
   - [ ] Yes, template_file: {path}

5. **Did you validate all extracted values?**
   - [ ] Yes, all values validated or defaulted

6. **Do you have all information needed for Phase 3?**
   - [ ] Yes, template and language configuration ready

**If ANY answer is NO:** Return to that step and complete before proceeding.

**If ALL answers are YES:** Proceed to Step 4.

---

## Step 4: Mark Phase 2 Complete

**Goal:** Update TodoWrite and document completion.

**Actions:**

1. **Update TodoWrite:**
   ```markdown
   USE: TodoWrite tool

   UPDATE:
   - Mark "Mark Phase 2 complete" as completed
   - Transition Phase 3 to in_progress (if Phase 3 todo exists)
   ```

2. **Log Phase 2 completion:**
   ```
   === Phase 2: Research Type Detection Complete ===

   Research Configuration:
     - research_type: {smarter-service|lean-canvas|generic}
     - project_language: {ISO 639-1 code}

   Template Selection:
     - template: {TIPS|Canvas|Standard}
     - template_file: {path}
     - framework: {description}

   Ready for Phase 3: Report Generation
   ```

3. **Set completion flag:**
   ```javascript
   part2_complete = true
   ```

**Update todo:** Mark "Mark Phase 2 complete" as completed.

---

## Phase Completion Checklist

Mark each item complete before advancing to Phase 3:

- [ ] Phase entry verification passed (part1_complete = true)
- [ ] sprint-log.json loaded (or defaults applied)
- [ ] research_type extracted and validated
- [ ] project_language extracted and validated
- [ ] Report template selected (TIPS, Canvas, or Standard)
- [ ] Template file path determined
- [ ] All step-level todos marked completed
- [ ] Self-verification questions answered YES
- [ ] Phase 2 completion logged
- [ ] part2_complete = true

**Phase 2 Success Criteria:**
- Research type identified
- Template selected and verified
- Language configuration confirmed
- Ready to generate synthesis report

**Next Phase:** Phase 3 - Report Generation (use selected template to create synthesis report)
