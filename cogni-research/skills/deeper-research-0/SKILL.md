---
name: deeper-research-0
description: Orchestrate research planning (Phase 1 of 4). Use when user requests "research [topic]", "investigate [subject]", "start research on", market analysis, competitive analysis, or business canvas creation. Executes phases 0-2.5 to initialize project, refine questions, create dimensions, validate megatrends, and create query batches. After completion, run deeper-research-1 for parallel findings creation.
---

# Deeper Research 0 - Planning

Orchestrate research planning by transforming questions into structured entity pipelines. Execute phases 0-2.5: initialization, question refinement, dimensional planning, megatrend validation, and batch creation.

---

## Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 0: Project initialization [in_progress]
2. Phase 1: Question refinement [pending]
3. Phase 2: Dimensional planning [pending]
4. Phase 2b: Megatrend seed validation [pending]
5. Phase 2.5: Batch creation [pending]

Update todo status as you progress through each phase.

**Note:** Each phase will add step-level todos when started (progressive expansion from 5 phase-level to ~15-20 step-level). Phase 2.5 creates all query batches before parallel findings execution in deeper-research-1.

---

## Progressive TodoWrite Expansion

The deeper-research-0 workflow uses **progressive disclosure** for TodoWrite tracking:

- **Initial state:** 5 phase-level todos (shown above)
- **Progressive expansion:** Each phase adds its step-level todos when started
- **Final state:** ~15-20 step-level todos across all phases

**Pattern:** As you enter each phase, the phase workflow file provides TodoWrite templates to expand phase-level todos into granular step-level tasks. This prevents overwhelming initial context while maintaining detailed tracking.

---

## CRITICAL: Research Type Required (DOK Auto-Determined)

**Phase 0 determines research template - DOK level is auto-determined in Phase 1:**

1. **Research Template (Phase 0):** Detect from user's request (e.g., "smarter-service research") OR ask via AskUserQuestion
2. **DOK Level (Phase 1):** Auto-determined based on research_type (only asked for `generic`)

**DOK Auto-Determination by Research Type:**

| Research Type | DOK Level | Rationale |
|---------------|-----------|-----------|
| `smarter-service` | **4** (auto) | 52 TIPS = extended complexity |
| `lean-canvas` | **2** (auto) | 9 canvas blocks |
| `customer-value-mapping` | **3** (auto) | Value mapping synthesis |
| `generic` | **ASK USER** | Only type where DOK is variable |

**Detection Examples:**

- "Run smarter-service research on AI trends" -> Detect smarter-service, auto-set DOK-4
- "Research cloud computing trends" -> Ask research type, then auto-set DOK based on selection
- "Do a generic DOK-3 analysis" -> Detect generic, ask DOK level

**DO NOT assume research type defaults.** Either detect from request OR ask the user.

---

## Required Input: Configuration

**Phase 0:** Research template (detected from request OR selected via AskUserQuestion)

**Phase 1:** DOK level (auto-determined based on research_type, or asked for `generic`)

See [dok-classification.md](../../references/dok-classification.md) for the complete DOK framework.

See [research-type-routing.md](../../references/research-type-routing.md) for the single source of truth on how research_type affects pipeline behavior (DOK, conditional phases, arc detection, findings-creator selection).

**MANDATORY:** Research type MUST be determined in Phase 0. DOK level is determined in Phase 1.

## Output Structure

```
project-name/
├── .metadata/              # Sprint log with planning_complete marker
├── 00-initial-question/    # Refined question entity
├── 01-research-dimensions/data/ # 2-10 dimension entities
├── 02-refined-questions/data/   # 8-50 question entities
└── 03-query-batches/data/       # Batch entities (one per refined question)
```

## Workflow Phases

```text
Phase 0 -> Phase 1 -> Phase 2 -> Phase 2b -> Phase 2.5
```

**MANDATORY PHASE GATES:** Each phase has required artifacts and self-verification questions. You MUST:

1. Answer verification questions before proceeding to next phase
2. Verify previous phase artifacts exist BEFORE starting next phase
3. Update step-level todos as you complete each verification step
4. Read the phase reference file BEFORE executing that phase

**Verification Pattern:** Each phase workflow file contains self-verification questions that validate completion before proceeding. Failure to complete verification invalidates the research collection.

**CRITICAL**: This skill uses progressive disclosure. Each phase reference contains essential procedural details NOT duplicated here.

### Execution Protocol

1. **First**: Read the phase reference file BEFORE executing that phase
2. **Per-phase**: The reference contains the actual implementation steps and TodoWrite templates
3. **Validation**: Each phase has verification checkpoints in its reference

**MANDATORY: Read the phase reference file BEFORE executing that phase.**

- SKILL.md provides only navigation
- Phase workflow files provide execution details, TodoWrite templates, and verification gates
- **Deeper-research lesson learned:** Phase execution failures occur when phase workflow files are not read before execution, causing critical steps to be skipped

**Do NOT skip reference reads** - they contain the three-layer enforcement architecture (self-verification, step-level todos, automated gates).

---

### Phase 0: Project Initialization

**GATE CHECK:** N/A (first phase)

Read [references/phase-workflows/phase-0-initialization.md](references/phase-workflows/phase-0-initialization.md), then execute its steps:

1. Parse user question and extract topic
2. Normalize project name with generate-semantic-slug.sh
3. Check for existing/similar projects
4. **Detect OR ask** research template: First check if user specified type in request (e.g., "smarter-service"), otherwise use AskUserQuestion
5. Initialize new project with selected template

**CRITICAL:** Step 4 must result in valid research_type - either by detection from user's request or via AskUserQuestion. Do NOT use defaults without detection or asking. research_type must be stored in `.metadata/sprint-log.json`.

**Note:** DOK level is determined in Phase 1 based on research_type (not asked in Phase 0).

**Required outputs:** `.metadata/sprint-log.json` (with research_type), normalized project name

---

### MANDATORY: Capture project_path After Phase 0

After Phase 0 completes, you MUST capture `project_path` from the initialization response. **This variable is required for ALL subsequent phase gate checks.**

```bash
# Phase 0 outputs project_path - capture it immediately
project_path="{PATH_FROM_PHASE_0_RESPONSE}"

# Validate the path exists
if [ ! -d "${project_path}/.metadata" ]; then
  echo "ERROR: project_path invalid: ${project_path}" >&2
  exit 1
fi
echo "project_path set to: ${project_path}"
```

**If you lose track of `project_path`, re-derive it:**

```bash
# Re-derive project_path from sprint-log.json location
sprint_log="$(find . -path "*/.metadata/sprint-log.json" -type f 2>/dev/null | head -1)"
if [ -z "$sprint_log" ]; then echo "ERROR: No sprint-log.json found" >&2; exit 1; fi
project_path="$(cd "$(dirname "$sprint_log")/.." && pwd)"
if [ ! -d "${project_path}/.metadata" ]; then echo "ERROR: Invalid project_path" >&2; exit 1; fi
echo "project_path: ${project_path}"
```

**CRITICAL:** The `project_path` variable MUST be set before running ANY gate check command. If `project_path` is empty, bash will expand `${project_path}/.metadata/sprint-log.json` to `/.metadata/sprint-log.json` (wrong path).

---

### Phase 1: Question Refinement

**GATE CHECK:** Before starting, verify these Phase 0 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set. See 'Capture project_path After Phase 0' section." >&2; exit 1; fi
ls -la "${project_path}/.metadata/sprint-log.json"
```

**IF MISSING: STOP. Return to Phase 0 and create required artifacts.**

Read [references/phase-workflows/phase-1-question-refinement.md](references/phase-workflows/phase-1-question-refinement.md), then execute its steps:

1. Load question analysis methodology
2. **Load research type and determine DOK level:**
   - Load research_type from sprint-log.json
   - Auto-set DOK based on research_type (see table above)
   - For `generic` only: Ask user for DOK level (1-4)
3. Perform systematic analysis
4. Interactive clarification (if blocking ambiguities)
5. **Research-type-specific clarifications:**
   - smarter-service: Ask about portfolio file linking
   - customer-value-mapping: Validate customer name and industry
   - lean-canvas: Gather business context
6. Generate semantic filename
7. Create question entity in 00-initial-question/data/ (with `research_type`, `dok_level`, and `linked_portfolio` fields)
8. Validate entity structure

**Required outputs:** `00-initial-question/data/` entity with frontmatter (including `research_type` and `dok_level`)

### Phase 2: Dimensional Planning

**GATE CHECK:** Before starting, verify these Phase 1 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set. See 'Capture project_path After Phase 0' section." >&2; exit 1; fi
ls -la "${project_path}/00-initial-question/data/"*.md
```

**IF MISSING: STOP. Return to Phase 1 and create required artifacts.**

Read [references/phase-workflows/phase-2-dimensional-planning.md](references/phase-workflows/phase-2-dimensional-planning.md), then execute its steps:

1. Invoke dimension-planner agent via Task tool
2. Validate dimension entities (2-10 dimensions)
3. Validate refined question entities (8-50 questions)
4. Verify MECE coverage

**Required outputs:** `01-research-dimensions/data/`, `02-refined-questions/data/`, `.metadata/seed-megatrends.yaml` (for generic/smarter-service)

### Phase 2b: Megatrend Seed Validation (MANDATORY for generic/smarter-service)

**GATE CHECK:** Execute only for `generic` or `smarter-service` research types.

```bash
# Check research type from initial question entity
RESEARCH_TYPE=$(grep "^research_type:" "${project_path}/00-initial-question/data/"*.md | head -1 | awk '{print $2}')

case "$RESEARCH_TYPE" in
  generic|smarter-service)
    # Execute Phase 2b
    ;;
  *)
    # Skip Phase 2b, proceed to Phase 2.5
    log_conditional INFO "Skipping Phase 2b - not applicable for ${RESEARCH_TYPE}"
    ;;
esac
```

**IF applicable:** Read [references/phase-workflows/phase-2b-megatrend-validation.md](references/phase-workflows/phase-2b-megatrend-validation.md), then execute its steps:

1. Load proposed seed megatrends from `.metadata/seed-megatrends.yaml`
2. Use AskUserQuestion to present seeds for validation
3. Handle user response (accept all / review & modify / skip seeding)
4. Update `seed-megatrends.yaml` with `user_validated: true`

**CRITICAL:** Phase 2b REQUIRES calling AskUserQuestion to present seeds to user.

- You MUST read phase-2b-megatrend-validation.md
- You MUST use AskUserQuestion with the megatrend options
- You MUST NOT proceed to Phase 2.5 until user responds
- Failure to call AskUserQuestion violates the workflow contract

**Required outputs:** `.metadata/seed-megatrends.yaml` with `user_validated: true`

### Phase 2.5: Batch Creation (Sequential)

**GATE CHECK:** Before starting, verify these Phase 2 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set. See 'Capture project_path After Phase 0' section." >&2; exit 1; fi
ls -la "${project_path}/02-refined-questions/data/"*.md
```

**IF MISSING: STOP. Return to Phase 2 and create required artifacts.**

Read [references/phase-workflows/phase-2.5-batch-creation.md](references/phase-workflows/phase-2.5-batch-creation.md), then execute its steps:

1. Invoke batch-creator agent via Task tool
2. Validate batch count matches question count
3. Verify `03-query-batches/data/` contains batch files

**Required outputs:** `03-query-batches/data/` (one batch per refined question)

---

## Critical Phase Gates

### Phase 0: Template Selection

**MUST call** `discover-research-templates.sh --json` to get available templates:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/discover-research-templates.sh" --json
```

Update BOTH metadata AND question frontmatter with selection.

## Language Propagation

Read `project_language` from `.metadata/sprint-log.json` (default: "en"). Pass to all collection agents via `LANGUAGE` or `CONTENT_LANGUAGE` parameter.

## Planning Completion

**PRE-COMPLETION VALIDATION (MANDATORY):**

Before declaring planning complete, verify ALL directories contain entities:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set. See 'Capture project_path After Phase 0' section." >&2; exit 1; fi

# Verify all Phase 0-2.5 outputs exist
find "${project_path}/00-initial-question/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +      # 1 question
find "${project_path}/01-research-dimensions/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +   # 2-10 dimensions
find "${project_path}/02-refined-questions/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +     # 8-50 questions
find "${project_path}/03-query-batches/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +         # Equal to questions
```

**If ANY directory is empty, you skipped a phase. Return to the missing phase.**

After Phase 2.5 validation passes:

1. Update sprint log: `planning_complete = true`
2. Report entity counts to user
3. Instruct user to run `deeper-research-1 --project-path "{project_path}"`

**HANDOFF MESSAGE:**

```
Planning phase complete.

Entity Summary:
- Dimensions: {count}
- Refined Questions: {count}
- Query Batches: {count}
- Seed Megatrends: {count if applicable}

Next Step: Run deeper-research-1 for parallel findings creation:

deeper-research-1 --project-path "{project_path}"
```

## Constraints

- DO NOT perform research directly (delegate to agents via Task tool)
- DO NOT modify agent-created entity files
- ALWAYS validate agent responses
- ALWAYS report phase completion with metrics

### Bash One-Liner Syntax (CRITICAL)

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 5 for mandatory semicolon rules and script path conventions.

**Script path**: `${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh` (NOT `lib/create-entity.sh`)

## Error Handling

| Phase | Failure | Action |
|-------|---------|--------|
| 0-2.5 | Any | HALT |

## Debugging

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 3 for enhanced logging initialization pattern.

Enable verbose stderr output: `export DEBUG_MODE=true`

Log file: `${PROJECT_PATH}/.logs/deeper-research-0-execution-log.txt`

## Bundled Resources

### References

- `references/phase-workflows/` - Phase 0-2.5 implementation details
- `../deeper-research-1/references/question-analysis-methodology.md` - Question analysis framework
- `../deeper-research-1/references/quality-gates.md` - Quality thresholds
- `../deeper-research-1/references/validation-protocols.md` - JSON validation and agent response standards
- `../deeper-research-1/references/entity-tagging-taxonomy.md` - Obsidian tag taxonomy for entities
- `../../references/dok-classification.md` - Webb's DOK framework (shared)

### Agents (via Task tool)

- **Planning:** dimension-planner
- **Batch Creation:** batch-creator (sequential, single invocation)
