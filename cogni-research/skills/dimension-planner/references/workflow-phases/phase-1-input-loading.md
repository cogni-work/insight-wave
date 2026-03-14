# Phase 1: Load Question & Detect Mode

**Reference Checksum:** `sha256:4860411b`

**Verification Protocol:** After reading this reference, confirm complete load by outputting:

```text
Reference Loaded: phase-1-input-loading.md | Checksum: 4860411b
```

---

## ⛔ PHASE ENTRY VERIFICATION (MANDATORY)

**Self-Verification:** Before proceeding, check TodoWrite to verify Phase 0 is marked complete. Phase 1 cannot begin until Phase 0 todos are completed.

**THEN verify Phase 0 outputs exist:**

Phase 0 required outputs:

- PROJECT_PATH validated
- LOG_FILE initialized
- Environment validation passed
- Project language loaded from `.metadata/sprint-log.json`

**IF any output is missing:**

1. STOP immediately
2. Return to Phase 0
3. Complete the missing steps
4. Only then return to Phase 1

**This is not optional.** Skipping Phase 0 validation means the skill lacks proper environment setup.

---

## Step 0.5: Initialize Phase 1 TodoWrite

Add step-level todos for Phase 1:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 1, Step 1.1: Read question file and parse frontmatter [in_progress]
- Phase 1, Step 1.2: Detect research mode via script [pending]
- Phase 1, Step 1.3: Identify references to load [pending]
- Phase 1, Step 1.4: Parse and validate all frontmatter fields [pending]

As you complete each step, mark the corresponding todo as completed.
```

---

## Step 0.6: Initialize Phase 1 Logging

Log phase start:

```bash
log_phase "Phase 1: Load Question & Detect Mode" "start"
log_conditional INFO "Question file: ${QUESTION_FILE}"
```

---

## Objective

Load the complete question content and determine which execution mode to follow (domain-based or research-type-specific).

## Prerequisites

- PROJECT_PATH validated (Phase 0)
- LOG_FILE initialized (Phase 0)
- QUESTION_FILE absolute path provided

## Detailed Steps

### Step 1.1: Read Question File

**Purpose:** Load complete question content and metadata.

**Steps:**

1. Log step start
2. Use Read tool to load QUESTION_FILE
3. Extract frontmatter section (YAML between --- delimiters)
4. Extract question text (content after frontmatter)
5. Parse fields:
   - `research_type` - Template name if specified
   - `context` - Research context/background
   - `output` - Expected outputs
   - `details` - Additional details
6. Log completion

**Logging:**

```bash
log_conditional INFO "Step 1.1: Reading question file"

# ... read file and extract data ...

log_conditional INFO "Step 1.1: Complete - Question loaded"
log_conditional DEBUG "  Research type: ${RESEARCH_TYPE:-generic}"
log_conditional DEBUG "  Question length: ${#QUESTION_TEXT} characters"
```

**Expected structure:**
```yaml
---
research_type: lean-canvas  # Optional, defaults to generic
context: "Company X market research"
output: "Business validation framework"
details: "Focus on competitive landscape"
---

# Question Text

What are the market opportunities and competitive challenges for X in Y market?
```

**Variable assignment:**
```bash
QUESTION_TEXT=$(sed -n '/^---$/,/^---$/p' "$QUESTION_FILE" | tail -n +2 | head -n -1)
RESEARCH_TYPE=$(grep "^research_type:" "$QUESTION_FILE" | cut -d: -f2 | xargs)
```

### Step 1.2: Detect Research Mode

**Purpose:** Determine whether to use template-based or domain-based planning.

**Logging:**

```bash
log_conditional INFO "Step 1.2: Detecting research mode"
```

**Command:**

```bash
bash scripts/detect-research-mode.sh --question-file "$QUESTION_FILE" --json
```

**Expected output:**
```json
{
  "mode": "domain-based",
  "research_type": "generic",
  "dimensions_mode": "domain-based",
  "template_path": null
}
```

Or for template mode:
```json
{
  "mode": "research-type-specific",
  "research_type": "lean-canvas",
  "dimensions_mode": "research-type-specific",
  "template_path": "references/research-types/lean-canvas/dimensions-lean-canvas.md"
}
```

**Variable extraction:**

```bash
MODE_OUTPUT=$(bash scripts/detect-research-mode.sh --question-file "$QUESTION_FILE" --json)
RESEARCH_TYPE=$(echo "$MODE_OUTPUT" | jq -r '.research_type')
DIMENSIONS_MODE=$(echo "$MODE_OUTPUT" | jq -r '.dimensions_mode')
TEMPLATE_PATH=$(echo "$MODE_OUTPUT" | jq -r '.template_path // empty')

log_conditional INFO "Step 1.2: Complete - Mode detected"
log_conditional INFO "  Research type: ${RESEARCH_TYPE}"
log_conditional INFO "  Execution mode: ${DIMENSIONS_MODE}"
if [ -n "$TEMPLATE_PATH" ]; then
  log_conditional INFO "  Template path: ${TEMPLATE_PATH}"
fi
```

### Step 1.3: Mode-Dependent Reference Loading

**Purpose:** Identify which references to load based on detected mode.

**Domain-Based Mode:**
- Load [../../../../references/dok-classification.md](../../../../references/dok-classification.md) for Phase 2
- Load [../mece-validation.md](../mece-validation.md) for Phase 4.1
- Load domain templates from Phase 3

**Research-Type-Specific Mode:**
- Use RESEARCH_TYPE to select Phase 2 file (e.g., `phase-2-analysis-{research_type}.md`)
- Phase 2 files are self-contained (all definitions embedded)
- TEMPLATE_PATH returned for reference only (not runtime loaded)

### Step 1.4: Parse Frontmatter Fields

**Purpose:** Extract all metadata fields from question for use in planning.

**Fields to extract:**
```bash
QUESTION_TITLE=$(grep "^title:" "$QUESTION_FILE" | cut -d: -f2- | xargs)
QUESTION_CONTEXT=$(grep "^context:" "$QUESTION_FILE" | cut -d: -f2- | xargs)
QUESTION_OUTPUT=$(grep "^output:" "$QUESTION_FILE" | cut -d: -f2- | xargs)
QUESTION_DETAILS=$(grep "^details:" "$QUESTION_FILE" | cut -d: -f2- | xargs)
```

**Variable assignment table:**

| Variable | Source | Purpose |
|----------|--------|---------|
| RESEARCH_TYPE | Frontmatter `research_type` | Selects execution mode |
| DIMENSIONS_MODE | detect-research-mode.sh | Branch logic (domain or template) |
| TEMPLATE_PATH | detect-research-mode.sh | Reference path (not runtime loaded, for documentation only) |
| QUESTION_TEXT | File content | Input for DOK/template analysis |
| QUESTION_CONTEXT | Frontmatter `context` | Background for dimension planning |
| QUESTION_OUTPUT | Frontmatter `output` | Expected deliverable format |

## Mode Branching Logic

**After Step 1.4, branch based on DIMENSIONS_MODE:**

```
IF DIMENSIONS_MODE == "domain-based"
  → Proceed to Phase 2 (DOK Classification)
  → Load [phase-2-analysis.md](phase-2-analysis.md)

ELSE IF DIMENSIONS_MODE == "research-type-specific"
  → Proceed to Phase 2a (Template Parsing)
  → Load [phase-2-analysis.md](phase-2-analysis.md)
  → Use TEMPLATE_PATH variable
```

## Success Criteria

- [ ] Question file loaded without errors
- [ ] Frontmatter parsed (research_type extracted)
- [ ] detect-research-mode.sh executed successfully
- [ ] RESEARCH_TYPE determined
- [ ] DIMENSIONS_MODE set (domain-based or research-type-specific)
- [ ] TEMPLATE_PATH set (if research-type-specific)
- [ ] All variables logged

**Mark Step 1.4 todo as completed** after validating all success criteria.

## Common Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Question file not found | Invalid QUESTION_FILE path | Return error JSON with file path |
| Frontmatter malformed | YAML syntax error | Return error JSON, request well-formed frontmatter |
| research_type invalid | Template name not recognized | Return error JSON listing valid templates |
| detect-research-mode.sh fails | Script missing or environment issue | Return error JSON from validation |
| TEMPLATE_PATH points to missing file | Template definition incomplete | Return error JSON, verify template installation |

## Self-Verification Before Completion

**Verify all steps completed:**

1. Did you run the phase entry verification gate? ✅ YES / ❌ NO
2. Did you initialize Phase 1 TodoWrite with step-level tasks? ✅ YES / ❌ NO
3. Did you read the question file completely? ✅ YES / ❌ NO
4. Did you execute detect-research-mode.sh successfully? ✅ YES / ❌ NO
5. Did you parse all frontmatter fields? ✅ YES / ❌ NO
6. Did you identify which references to load based on mode? ✅ YES / ❌ NO
7. Did you set all required variables (RESEARCH_TYPE, DIMENSIONS_MODE, etc.)? ✅ YES / ❌ NO
8. Did you mark all Phase 1 step-level todos as completed? ✅ YES / ❌ NO

⛔ **IF ANY NO:** STOP. Return to incomplete step before proceeding to Phase 2.

## Step 1.99: Log Phase Completion

Log phase completion:

```bash
log_conditional INFO "Phase 1 complete - All variables set"
log_conditional INFO "  RESEARCH_TYPE: ${RESEARCH_TYPE}"
log_conditional INFO "  DIMENSIONS_MODE: ${DIMENSIONS_MODE}"
log_conditional INFO "  TEMPLATE_PATH: ${TEMPLATE_PATH:-none}"

log_phase "Phase 1: Load Question & Detect Mode" "complete"
```

## Mark Phase 1 Complete

- Update TodoWrite: Phase 1 → completed, Phase 2 → in_progress
- Verify all success criteria checked off
- Confirm all required variables are set and logged

**Mark Phase 1 todo as completed** before proceeding to Phase 2.

---

## Next Phase

Proceed to [phase-2-analysis.md](phase-2-analysis.md) when all success criteria met and self-verification passed.

Branch selection:
- **Domain-based:** Phase 2 (DOK Classification)
- **Research-type-specific:** Phase 2a (Template Parsing)

---

## Phase Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 2

Before marking Phase 1 complete in TodoWrite, verify:

- [ ] Phase entry verification gate passed (TodoWrite check + Phase 0 outputs verified)
- [ ] Question file read completely
- [ ] detect-research-mode.sh executed successfully
- [ ] All frontmatter fields parsed
- [ ] Mode-dependent references identified
- [ ] All required variables set (RESEARCH_TYPE, DIMENSIONS_MODE, TEMPLATE_PATH)
- [ ] All variables logged
- [ ] All step-level todos marked as completed
- [ ] All self-verification questions answered YES
- [ ] Phase 1 todo marked completed in TodoWrite

---

**Size: 2.1KB** | Dependencies: detect-research-mode.sh, question file frontmatter, template files
