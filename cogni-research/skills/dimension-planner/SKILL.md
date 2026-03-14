---
name: dimension-planner
description: Plan research dimensions from questions. Decomposes complex topics into 2-10 independent dimensions with validated sub-questions. Supports domain-adaptive and template-driven modes.
---

# Dimension Planner

## Execution Modes

Two modes based on `research_type` frontmatter in question file:

- **Domain-based** (`generic` or omitted): Dynamic dimensions via Webb's DOK + domain templates (2-10 adaptive)
- **Research-type-specific** (`lean-canvas`, etc.): Fixed dimensions from template

## References Index

Read references **only when needed** for the specific task:

| Reference | Read when... |
|-----------|--------------|
| [../../references/research-types/README.md](../../references/research-types/README.md) | Using research-type-specific mode |
| [../../references/dok-classification.md](../../references/dok-classification.md) | Classifying complexity (domain-based mode) |
| [references/picot-framework.md](references/picot-framework.md) | Generating research questions |
| [references/mece-validation.md](references/mece-validation.md) | Validating dimension structure |
| [references/finer-criteria.md](references/finer-criteria.md) | Validating question quality |
| [references/multilingual-patterns.md](references/multilingual-patterns.md) | Using language-aware generation (Phase 2, 5) |
| [references/error-recovery-patterns.md](references/error-recovery-patterns.md) | Handling errors, runtime safety patterns |
| [references/validation-patterns.md](references/validation-patterns.md) | Environment validation, filename generation |
| [references/workflow-phases/](references/workflow-phases/) | Detailed phase instructions needed |
| [references/workflow-phases/phase-4b-megatrend-proposal.md](references/workflow-phases/phase-4b-megatrend-proposal.md) | Phase 4b (Optional: Seed megatrend proposal for generic/smarter-service) |
| [references/workflow-phases/phase-5-entity-creation.md](references/workflow-phases/phase-5-entity-creation.md) | **MANDATORY** for Phase 5 (batched entity creation) |
| [references/workflow-phases/phase-6-llm-execution-report.md](references/workflow-phases/phase-6-llm-execution-report.md) | Phase 6 (LLM Execution Report) |

## Immediate Action: Initialize TodoWrite

**⛔ MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 0: Environment validation [in_progress]
2. Phase 1: Load question and detect mode [pending]
3. Phase 2: Analysis (DOK or template) [pending]
4. Phase 3: Planning (dimensions and questions) [pending]
5. Phase 4: Validation (MECE, FINER, quality) [pending]
6. Phase 4b: Megatrend proposal (optional, generic/smarter-service only) [pending]
7. Phase 5: Create entities (incremental processing) [pending]
8. Phase 6: LLM Execution Report [pending]

**⚠️ Phase 6 is ALWAYS in the todo list and ALWAYS executes.** After Phase 5, proceed directly to Phase 6. Never omit Phase 6 from tracking.

**Note:** Phase 4b (Megatrend Proposal) is optional and only executes for `generic` or `smarter-service` research types. It generates seed megatrends for megatrend clustering validation.

Update todo status as you progress through each phase.

**Note:** Each phase workflow file provides TodoWrite templates for progressive expansion from 6 phase-level todos to ~20-30 step-level todos. This prevents overwhelming initial context while maintaining detailed tracking.

---

## Core Workflow

```text
Phase 0 → Phase 1 → [Mode Detection]
                         ↓
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
     generic       smarter-service   lean-canvas
          ↓              ↓              ↓
     Phase 2a       Phase 2b         Phase 2c
          ↓              ↓              ↓
     Phase 3a       Phase 3b         Phase 3c
          └──────────────┼──────────────┘
                         ↓
                    Phase 4 → Phase 4b* → Phase 5 → Phase 6
                              (optional)           (LLM Execution Report)

* Phase 4b executes only for generic/smarter-service research types
```

**CRITICAL**: This skill uses progressive disclosure. Each phase reference contains essential procedural details NOT duplicated here.

### Execution Protocol

1. **First**: Read [references/workflow-phases/workflow-overview.md](references/workflow-phases/workflow-overview.md) to understand the full workflow structure
2. **Runtime Tracking**: Use [references/workflow-phases/RUNTIME-CHECKLIST.md](references/workflow-phases/RUNTIME-CHECKLIST.md) to track phase completion and ensure all phases execute
3. **Per-phase**: Read the linked reference file BEFORE executing that phase - the reference contains the actual implementation steps
4. **Verification**: After reading each phase reference, output the verification checksum shown in the reference header

**⛔ MANDATORY: Read the phase reference file BEFORE executing that phase.**

- SKILL.md provides only navigation
- Phase workflow files provide execution details, TodoWrite templates, and verification gates
- **Sprint pattern lesson:** Phase failures occur when reference files are not read before execution, causing critical steps to be skipped

**Do NOT skip reference reads** - they contain the procedural logic this skill requires to execute correctly.

### Phase 0: Environment Validation

Read [references/workflow-phases/phase-0-environment.md](references/workflow-phases/phase-0-environment.md), then execute its steps:

1. Extract PROJECT_PATH from question file path
2. Validate: `bash scripts/validate-environment.sh --project-path "$PROJECT_PATH" --json`
3. Initialize logging, load project language from `.metadata/sprint-log.json`

### Phase 1: Load Question & Detect Mode

**⛔ GATE CHECK:** Before starting, verify Phase 0 completed successfully (environment validated).

Read [references/workflow-phases/phase-1-input-loading.md](references/workflow-phases/phase-1-input-loading.md), then execute its steps:

1. Read question content (fully)
2. Detect mode: `bash scripts/detect-research-mode.sh --question-file "$QUESTION_FILE" --json`
3. Parse `research_type`, `dimensions_mode`, `template_path`

**Required outputs:**

- RESEARCH_TYPE, DIMENSIONS_MODE, TEMPLATE_PATH variables set
- Mode detection logged

### Phase Routing: Research Type Detection

After Phase 1 completes, log the routing decision to Phase 2:

```bash
# Log phase routing decision - makes it clear which phase file will be loaded
log_phase "Phase 1: Load Question & Detect Mode" "complete"

case "$RESEARCH_TYPE" in
  smarter-service)
    log_conditional INFO "Routing: Phase 2 → phase-2-analysis-smarter-service.md"
    ;;
  lean-canvas)
    log_conditional INFO "Routing: Phase 2 → phase-2-analysis-lean-canvas.md"
    ;;
  generic|*)
    log_conditional INFO "Routing: Phase 2 → phase-2-analysis-generic.md"
    ;;
esac
```

### Phase 2: Analysis

**⛔ GATE CHECK:** Before starting, verify Phase 1 outputs exist (mode detected, variables set).

**Execute based on research_type:**

- **Generic** (`research_type: generic` or omitted): Read [references/workflow-phases/phase-2-analysis-generic.md](references/workflow-phases/phase-2-analysis-generic.md)
  - Classify complexity using Webb's DOK with **extended thinking**
  - Output: DOK level, dimension ranges (2-10), question targets (DOK-based: 8-50)

- **Smarter-Service** (`research_type: smarter-service`): Read [references/workflow-phases/phase-2-analysis-smarter-service.md](references/workflow-phases/phase-2-analysis-smarter-service.md)
  - Load 4 fixed dimensions (TIPS framework), extract momentum indicators
  - Output: 4 dimensions, TIPS context, trend velocity, case study requirements

- **Lean-Canvas** (`research_type: lean-canvas`): Read [references/workflow-phases/phase-2-analysis-lean-canvas.md](references/workflow-phases/phase-2-analysis-lean-canvas.md)
  - Load 9 canvas blocks, detect business stage focus
  - Output: 9 dimensions, stage weighting, evidence patterns

**Required outputs:**

- DOK level determined with extended thinking (generic) OR template dimensions extracted (smarter-service/lean-canvas)
- Analysis documented

### Phase 3: Planning

**⛔ GATE CHECK:** Before starting, verify Phase 2 outputs exist (DOK level or dimension definitions).

**Execute based on research_type:**

- **Generic** (`research_type: generic` or omitted): Read [references/workflow-phases/phase-3-planning-generic.md](references/workflow-phases/phase-3-planning-generic.md)
  - Select domain template (Business/Academic/Product), preserve question context
  - Output: SELECTED_DIMENSIONS, DIMENSION_CONTEXT, PICOT_OVERRIDES

- **Smarter-Service** (`research_type: smarter-service`): Read [references/workflow-phases/phase-3-planning-smarter-service.md](references/workflow-phases/phase-3-planning-smarter-service.md)
  - Apply TIPS-enhanced PICOT with trend velocity framing, action horizons
  - Output: TIPS-enhanced questions, momentum metrics, case study integration

- **Lean-Canvas** (`research_type: lean-canvas`): Read [references/workflow-phases/phase-3-planning-lean-canvas.md](references/workflow-phases/phase-3-planning-lean-canvas.md)
  - Apply canvas-specific PICOT with DOK-2 distribution (3 questions per block)
  - Output: Canvas-specific questions (27 total), evidence patterns, hypothesis targets

- **Customer-Value-Mapping** (`research_type: customer-value-mapping`): Read [references/workflow-phases/phase-3-planning-customer-value-mapping.md](references/workflow-phases/phase-3-planning-customer-value-mapping.md)
  - Apply Value Story PICOT with DOK×2 multiplier (ask user for DOK, default=3)
  - Output: Customer-specific questions (16-40 total), source TIPS/portfolio references

**Required outputs:**

- Dimensions defined (2-10 range)
- PICOT questions generated per research type:
  - generic: 8-50 (DOK-based)
  - lean-canvas: 27 (DOK-2)
  - customer-value-mapping: 16-40 (DOK×2 multiplier)
  - smarter-service: 52 (fixed: 5 ACT + 5 PLAN + 3 OBSERVE per dimension)
- Planning documented

### Phase 4: Validation (Batched with Extended Thinking)

**⛔ GATE CHECK:** Before starting, verify Phase 3 outputs exist (dimensions and questions planned).

Read [references/workflow-phases/phase-4-validation.md](references/workflow-phases/phase-4-validation.md), then execute its steps:

1. **MECE** (domain-based): <20% overlap, 100% coverage
2. **PICOT Generation** (batched per-dimension with extended thinking): Target total questions per DOK level, explicit P/I/C/O/T reasoning
3. **Comprehensive Quality Assessment** (batched with extended thinking): FINER scoring + quality planning in single pass
   - FINER scores ≥10/15 individual, ≥11.0 average
   - Quality attributes: Confidence, Triangulation, Gaps, Complexity
4. **Final**: `bash scripts/validate-outputs.sh --dimensions "$N" --questions "$N" --avg-finer "$SCORE" --research-type "$RESEARCH_TYPE" --json`

**Required outputs:**

- Validation checks passed
- Quality metrics documented

**Performance Note:** Phase 4 uses batched generation and comprehensive assessment to achieve 35-42% speed improvement (90-135s → 40-60s for DOK-3, 20 questions) while improving quality through extended thinking.

### Phase 4b: Megatrend Proposal (CONDITIONAL)

**⛔ GATE CHECK:** Before starting, verify Phase 4 completed successfully (validation passed).

**Condition:** Execute ONLY if ALL conditions are met:

1. `research_type` is `generic` OR `smarter-service`
2. User has NOT disabled megatrend seeding (`--skip-megatrend-proposal` flag not set)

**Skip when:** `research_type` is `lean-canvas`

Read [references/workflow-phases/phase-4b-megatrend-proposal.md](references/workflow-phases/phase-4b-megatrend-proposal.md), then execute its steps:

1. **Context Analysis:** Analyze research question, dimensions, and questions for expected megatrends
2. **Seed Generation:** Generate 5-10 seed megatrend candidates using extended thinking
3. **YAML Output:** Write proposed seeds to `.metadata/seed-megatrends.yaml` with `user_validated: false`
4. **Return seeds in response:** Include `seed_megatrends` object in JSON response for orchestrator

**⚠️ NO USER INTERACTION:** dimension-planner runs as a sub-agent and CANNOT use AskUserQuestion. User validation happens in deeper-research-1 Phase 2b AFTER this agent completes.

**Required outputs:**

- `.metadata/seed-megatrends.yaml` (proposed seeds with `user_validated: false`)
- JSON response with `seed_megatrends.pending_validation: true`

**Verification:** After reading phase-4b-megatrend-proposal.md, confirm checksum `MEGATREND-PROPOSAL-V2`

**Integration:** Seeds consumed by knowledge-extractor Phase 5 (Megatrend Clustering) for dual-source synthesis:

- Bottom-up: Cluster megatrends from findings
- Top-down: Match clusters against seed megatrends

**If skipped:** Proceed directly to Phase 5. Megatrend clustering will use bottom-up only mode.

### Phase 5: Create Entities (BATCHED - Single Pass)

**⛔ CRITICAL CONSTRAINTS - READ BEFORE PROCEEDING:**

1. **NEVER use Write tool for dimension or question markdown files** - The batch script creates them
2. **NEVER read entity-templates.md or archived phase-5 files** - They contain deprecated patterns
3. **ONLY the batch script creates entity files** - Direct Write calls produce incorrect schema
4. **Entity schema is defined by the script** - Not by templates or LLM generation

**Why:** Direct Write tool usage produces files missing `initial_question_ref` backlinks and using wrong `entity_type` values. Only the batch script at `scripts/unpack-dimension-plan-batch.sh` creates correctly-linked entities.

Execute these 4 steps exactly:

#### Step 5.1: Generate Batch JSON

Read [references/workflow-phases/phase-5-entity-creation.md](references/workflow-phases/phase-5-entity-creation.md) for the **canonical JSON schema**, then generate ONE JSON with ALL dimensions and questions.

**⛔ The JSON schema in phase-5-entity-creation.md is the ONLY valid schema. Do not invent fields or use patterns from other files.**

#### Step 5.2: Write JSON to .metadata/

Use Write tool to save JSON to `${PROJECT_PATH}/.metadata/dimension-plan-batch.json`

**This is the ONLY Write tool call permitted in Phase 5** (for the JSON file, not markdown entities).

#### Step 5.3: Call Batch Unpack Script (MANDATORY)

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/dimension-planner/scripts/unpack-dimension-plan-batch.sh" \
  --json-file "${PROJECT_PATH}/.metadata/dimension-plan-batch.json" \
  --project-path "${PROJECT_PATH}" \
  --validate-schema true \
  --json
```

**Verify output contains ALL of these:**

```json
{
  "success": true,
  "data": {
    "dimensions_created": N,
    "questions_created": M,
    "readmes_created": {
      "dimensions_readme": true,
      "refined_questions_readme": true
    }
  }
}
```

**⛔ VERIFICATION CHECKLIST:**

- [ ] `success` is `true`
- [ ] `dimensions_created` matches expected count
- [ ] `questions_created` matches expected count
- [ ] `readmes_created.dimensions_readme` is `true`
- [ ] `readmes_created.refined_questions_readme` is `true`

IF any check fails: STOP and report error. Do NOT proceed to Phase 6.

**⛔ FALLBACK PROHIBITION (HARD FAILURE):**

If script fails or Write tool errors occur:

- ❌ **NEVER** use Write tool for entity `.md` files
- ❌ **NEVER** use Bash heredocs (`cat > file << 'EOF'`)
- ❌ **NEVER** use `echo >` or any shell redirection for entities
- ✅ **ONLY** fix the JSON and retry the script

**Why fallbacks cause failures:**

1. Write tool requires reading files first (fails on new files)
2. Heredocs bypass validation, locking, and entity-index updates
3. Created entities will have wrong schema (missing `initial_question_ref`, wrong `entity_type`)
4. Downstream phases (batch-creator, findings-creator) will fail on malformed entities

#### Step 5.4: Verify README Files Exist (MANDATORY)

After script completes, verify README files were created:

```bash
ls -la "${PROJECT_PATH}/01-research-dimensions/README.md" "${PROJECT_PATH}/02-refined-questions/README.md"
```

**Both files MUST exist.** If either is missing:

1. Log error: `[ERROR] README files not created by script`
2. Re-run the script from Step 5.3
3. If still missing after retry, STOP and report critical error

**⛔ NEVER create README files manually with Write tool. Only the script creates valid READMEs with provenance chains.**

### Phase 6: LLM Execution Report

> **MANDATORY PHASE - ALWAYS EXECUTES**

After Phase 5 completes, execute Phase 6 to capture any issues encountered during skill execution.

Read [references/workflow-phases/phase-6-llm-execution-report.md](references/workflow-phases/phase-6-llm-execution-report.md), then execute:

1. **Step 6.1:** Reflect on execution (Phases 0-5) - document any issues encountered
2. **Step 6.2:** Collect issues with type, severity, expected/actual/resolution
3. **Step 6.3:** Create JSON report following schema in reference file
4. **Step 6.4:** Append to `${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl`
5. Log: `[PHASE] Phase 6: LLM Execution Report [complete]`

**Purpose:** Capture silent adaptations and workarounds - Layer 4 of debugging architecture.

**Report Location:** `${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl`

**⛔ GATE CHECK:** Before marking skill complete, verify Phase 6 was executed. The execution log MUST contain Phase 6 completion evidence.

## Error Handling

| Scenario | Exit |
|----------|------|
| Missing/invalid question file, project structure, CLAUDE_PLUGIN_ROOT | 1 |
| Template not found, MECE fails (>20% overlap) | 1 |
| Dimensions <2 or >10, Questions outside valid range (8-50/36/57), Avg FINER <11.0 | 1 |
| Individual FINER <10 | 0 (reformulate) |

## Debugging

### Enhanced Logging Architecture

The dimension-planner skill implements comprehensive logging using enhanced-logging.sh utilities for debugging and execution tracking.

**Reference:** See [Enhanced Logging Standards](https://github.com/cogni-work/dev-work/blob/main/references/debugging/enhanced-logging-standards.md) for complete patterns.

### Logging Initialization (Phase 0)

Initialize logging immediately after environment validation in Phase 0:

```bash
# Source enhanced logging utility
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize skill-specific log file
SKILL_NAME="dimension-planner"
LOG_FILE="${PROJECT_PATH}/.logs/${SKILL_NAME}-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.logs"

# Log initialization
log_phase "Phase 0: Environment Validation" "start"
log_conditional INFO "Skill: dimension-planner"
log_conditional INFO "Project: ${PROJECT_PATH}"
log_conditional INFO "Question file: ${QUESTION_FILE}"
```

### Phase Transition Logging

Wrap each phase with start/complete markers that **clearly indicate the research type**:

```bash
# Phase start - includes research type in phase name
log_phase "Phase 2: Analysis (smarter-service)" "start"

# Step-level progress - prefixed with research type
log_conditional INFO "[smarter-service] Applying embedded dimension definitions"
log_conditional INFO "[smarter-service] DIMENSION_COUNT=4 (fixed, embedded)"

# Phase completion
log_phase "Phase 2: Analysis (smarter-service)" "complete"
```

**Standardized Phase Names:**

- `"Phase 0: Environment Validation"` (no research type yet)
- `"Phase 1: Load Question & Detect Mode"` (no research type yet)
- `"Phase 2: Analysis (generic)"` / `"Phase 2: Analysis (smarter-service)"` / `"Phase 2: Analysis (lean-canvas)"`
- `"Phase 3: Planning (generic)"` / `"Phase 3: Planning (smarter-service)"` / `"Phase 3: Planning (lean-canvas)"`
- `"Phase 4: Validation"` (common phase)
- `"Phase 5: Entity Creation (Batched)"` (common phase)

**Research Type Prefixes for Step Logs:**

```bash
# Generic mode
log_conditional INFO "[generic] DOK_LEVEL=3"
log_conditional INFO "[generic] Dimension range: 4-6"

# Smarter-service mode
log_conditional INFO "[smarter-service] Applying TIPS framework"
log_conditional INFO "[smarter-service] Trend velocity: accelerating"

# Lean-canvas mode
log_conditional INFO "[lean-canvas] Business stage detected: pmf"
log_conditional INFO "[lean-canvas] 9 canvas blocks loaded"

```

### Progress Tracking Logging

Log key decisions and progress updates during execution:

```bash
# Mode detection
log_conditional INFO "Research type detected: ${RESEARCH_TYPE}"
log_conditional INFO "Execution mode: ${DIMENSIONS_MODE}"

# DOK classification (Phase 2, domain-based)
log_conditional INFO "DOK Level: ${DOK_LEVEL}"
log_conditional INFO "Target dimensions: ${MIN_DIM}-${MAX_DIM}"

# Dimension planning (Phase 3)
log_conditional INFO "Dimensions planned: ${DIMENSION_COUNT}"
log_conditional INFO "Questions per dimension: ${QUESTIONS_PER_DIM}"

# Validation results (Phase 4)
log_conditional INFO "MECE validation: PASSED (overlap: ${OVERLAP_PCT}%)"
log_conditional INFO "FINER average score: ${AVG_FINER}"

# Entity creation progress (Phase 5)
log_conditional INFO "Creating dimension ${i}/${total}: ${dimension_name}"
log_conditional INFO "Created ${question_count} questions for dimension: ${dimension_name}"
```

### Error and Warning Logging

Use appropriate log levels for error scenarios:

```bash
# Critical errors (exit 1)
if [ ! -f "$QUESTION_FILE" ]; then log_conditional ERROR "Question file not found: ${QUESTION_FILE}" ; exit 1 ; fi

# Validation failures
if [ "$OVERLAP_PCT" -gt 20 ]; then log_conditional ERROR "MECE validation failed: ${OVERLAP_PCT}% overlap exceeds 20% threshold" ; exit 1 ; fi

# Warnings (non-fatal issues)
if [ "$INDIVIDUAL_FINER" -lt 10 ]; then log_conditional WARN "Question FINER score below threshold: ${INDIVIDUAL_FINER}/15" ; log_conditional WARN "Reformulating question to improve quality" ; fi

# Script execution errors
if [ "$exit_code" -ne 0 ]; then log_conditional ERROR "Script failed: ${script_name} (exit code: ${exit_code})" ; log_conditional ERROR "stderr: ${error_output}" ; fi
```

### Metrics Logging

Log quantitative metrics at phase completion:

```bash
# Phase 3: Planning metrics
log_metric "dimensions_planned" "${DIMENSION_COUNT}" "count"
log_metric "questions_planned" "${TOTAL_QUESTIONS}" "count"

# Phase 4: Validation metrics
log_metric "mece_overlap_percent" "${OVERLAP_PCT}" "percentage"
log_metric "mece_coverage_percent" "${COVERAGE_PCT}" "percentage"
log_metric "finer_average_score" "${AVG_FINER}" "score"
log_metric "finer_min_score" "${MIN_FINER}" "score"

# Phase 5: Entity creation metrics
log_metric "dimension_files_created" "${dimension_count}" "count"
log_metric "question_files_created" "${question_count}" "count"
log_metric "entity_creation_time" "${duration}" "seconds"
```

### Verification Gate Logging

Log verification checkpoint results:

```bash
# Phase entry verification
log_conditional INFO "Phase 1 Entry Gate: Checking Phase 0 outputs"
log_conditional INFO "✓ PROJECT_PATH validated: ${PROJECT_PATH}"
log_conditional INFO "✓ LOG_FILE initialized: ${LOG_FILE}"

# Phase completion verification
log_conditional INFO "Phase 1 Completion Checklist:"
log_conditional INFO "✓ Question file read"
log_conditional INFO "✓ Mode detected: ${DIMENSIONS_MODE}"
log_conditional INFO "✓ Variables set: RESEARCH_TYPE, TEMPLATE_PATH"

# Filesystem verification (Phase 5.2.5)
log_conditional INFO "Phase 5.2.5: Filesystem verification"
verification_json=$(bash scripts/verify-phase5-completion.sh \
  --project-path "$PROJECT_PATH" \
  --dimensions-count "$dimensions_count" \
  --questions-count "$questions_count" \
  --json)
verification_exit=$?

if [ "$verification_exit" -eq 0 ]; then log_conditional INFO "✓ Filesystem verification passed" ; log_conditional INFO "  Dimensions: ${dimensions_count} files created" ; log_conditional INFO "  Questions: ${questions_count} files created" ; else log_conditional ERROR "✗ Filesystem verification failed" ; log_conditional ERROR "  ${verification_json}" ; fi
```

### Debug Mode Usage

Enable verbose logging for troubleshooting:

```bash
# Enable DEBUG_MODE for all log levels to stderr
export DEBUG_MODE=true

# Run dimension-planner skill (via Claude Code)
# All INFO/DEBUG/TRACE logs will appear in stderr + log file
```

**DEBUG_MODE behavior:**

- `false` (default): Only ERROR/WARN to stderr, all levels to log file
- `true`: All levels (ERROR, WARN, INFO, DEBUG, TRACE) to stderr + log file

**QUIET_MODE behavior:**

- `false` (default): Normal DEBUG_MODE-based output
- `true`: Suppress ALL stderr (for JSON output modes), all levels still written to log file

### Log File Analysis

Execution logs contain structured markers for analysis:

```bash
# View phase transitions
grep "\[PHASE\]" "${PROJECT_PATH}/.metadata/dimension-planner-execution-log.txt"

# View metrics only
grep "\[METRIC\]" "${PROJECT_PATH}/.metadata/dimension-planner-execution-log.txt"

# View errors
grep "\[ERROR\]" "${PROJECT_PATH}/.metadata/dimension-planner-execution-log.txt"

# View specific phase
grep -A 50 "Phase 3: Planning \[start\]" "${PROJECT_PATH}/.metadata/dimension-planner-execution-log.txt"
```

**Log Format:**

```text
[2025-01-15T10:30:45Z] [PHASE] ========== Phase 1: Load Question & Detect Mode [start] ==========
[2025-01-15T10:30:45Z] [INFO] Step 1.1: Reading question file
[2025-01-15T10:30:46Z] [INFO] Step 1.1: Complete - Question loaded
[2025-01-15T10:30:46Z] [INFO] Routing: Phase 2 → phase-2-analysis-smarter-service.md
[2025-01-15T10:30:46Z] [PHASE] ========== Phase 1: Load Question & Detect Mode [complete] ==========
[2025-01-15T10:30:46Z] [PHASE] ========== Phase 2: Analysis (smarter-service) [start] ==========
[2025-01-15T10:30:46Z] [INFO] [smarter-service] Applying embedded dimension definitions
[2025-01-15T10:30:46Z] [INFO] [smarter-service] DIMENSION_COUNT=4 (fixed, embedded)
[2025-01-15T10:30:47Z] [INFO] [smarter-service] Trend velocity: accelerating
[2025-01-15T10:30:47Z] [METRIC] dimensions_planned=4 unit=count
[2025-01-15T10:30:47Z] [PHASE] ========== Phase 2: Analysis (smarter-service) [complete] ==========
```

### Log Locations

- **Execution logs:** `${PROJECT_PATH}/.logs/dimension-planner-execution-log.txt`
- **Script logs:** Individual scripts may create additional logs in `.metadata/` directory

### Debugging Workflow References

Each phase workflow reference file includes logging guidance:

- Phase 0: [references/workflow-phases/phase-0-environment.md](references/workflow-phases/phase-0-environment.md) - Logging initialization
- Phase 1: [references/workflow-phases/phase-1-input-loading.md](references/workflow-phases/phase-1-input-loading.md) - Mode detection logging
- Phase 2: Research-type-specific analysis logging:
  - [references/workflow-phases/phase-2-analysis-generic.md](references/workflow-phases/phase-2-analysis-generic.md) - DOK classification
  - [references/workflow-phases/phase-2-analysis-smarter-service.md](references/workflow-phases/phase-2-analysis-smarter-service.md) - TIPS context
  - [references/workflow-phases/phase-2-analysis-lean-canvas.md](references/workflow-phases/phase-2-analysis-lean-canvas.md) - Canvas blocks
- Phase 3: Research-type-specific planning logging:
  - [references/workflow-phases/phase-3-planning-generic.md](references/workflow-phases/phase-3-planning-generic.md) - Domain selection
  - [references/workflow-phases/phase-3-planning-smarter-service.md](references/workflow-phases/phase-3-planning-smarter-service.md) - TIPS-enhanced PICOT
  - [references/workflow-phases/phase-3-planning-lean-canvas.md](references/workflow-phases/phase-3-planning-lean-canvas.md) - Canvas PICOT
- Phase 4: [references/workflow-phases/phase-4-validation.md](references/workflow-phases/phase-4-validation.md) - Validation results logging
- Phase 5: [references/workflow-phases/phase-5-entity-creation.md](references/workflow-phases/phase-5-entity-creation.md) - Entity creation progress logging
- Phase 6: [references/workflow-phases/phase-6-llm-execution-report.md](references/workflow-phases/phase-6-llm-execution-report.md) - LLM Execution Report

### Debugging Guides

- **Enhanced Logging Standards:** [Enhanced Logging Standards](https://github.com/cogni-work/dev-work/blob/main/references/debugging/enhanced-logging-standards.md)
- **Best Practices:** [Best Practices](https://github.com/cogni-work/dev-work/blob/main/references/debugging/best-practices.md)
- **Architecture Overview:** [Three-Layer Architecture](https://github.com/cogni-work/dev-work/blob/main/references/debugging/three-layer-architecture.md)
- **LLM Execution Report (Layer 4):** [LLM Execution Report](https://github.com/cogni-work/dev-work/blob/main/references/debugging/llm-execution-report.md)
- **Navigation Index:** [Debugging Guide](https://github.com/cogni-work/dev-work/blob/main/references/debugging-guide.md)

### Layer 4: LLM Execution Report

The dimension-planner skill implements Layer 4 debugging via Phase 6 (LLM Execution Report).

| Layer | What It Captures | dimension-planner Examples |
|-------|------------------|---------------------------|
| Layer 1 | Tool calls, phases | Bash, Read, Write calls |
| Layer 2 | Script execution | validate-environment.sh, unpack-dimension-plan-batch.sh |
| Layer 3 | Tool output | Script JSON responses |
| **Layer 4** | **LLM improvisations** | **Path corrections, schema adaptations, fallback logic** |

**Report Location:** `${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl`

**Reference:** See [references/workflow-phases/phase-6-llm-execution-report.md](references/workflow-phases/phase-6-llm-execution-report.md) for implementation details and analysis examples.

## Script Contracts

The `contracts/` directory contains YAML interface specifications for scripts. These define parameter contracts, output schemas, and exit codes for script-prompt integration validation. See [contracts/detect-research-mode.yml](contracts/detect-research-mode.yml) for format.
