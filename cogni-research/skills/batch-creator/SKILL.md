---
name: batch-creator
description: Create optimized search query batches for all research questions. Use after dimension planning. Generates bilingual, facet-decomposed search configurations for web and LLM research.
allowed-tools: Read, Bash, Glob, Grep, TodoWrite
---

# Batch Creator

Create query batches for ALL refined research questions in a project through **sequential** processing, eliminating race conditions and context contamination that occur with parallel batch creation.

## Core Capabilities

- **Sequential processing**: One question at a time, single LLM context
- **Query optimization**: 4-7 search configs via PICOT facet decomposition + bilingual strategy
- **Batch creation**: UUID-based config IDs with WebSearch parameters
- **Entity creation via script**: Uses `create-entity.sh` for atomic writes, validation, and index registration
- **Error resilience**: Continue on single failures, track in summary

## Architecture Position

```text
deeper-research-0 orchestrator
  → Phase 2: dimension-planner (creates dimensions + questions)
  → Phase 2.5: batch-creator (THIS SKILL - creates ALL batches sequentially)

deeper-research-1 orchestrator
  → Phase 3: findings-creator ×N parallel (search + findings only)
```

## Script Architecture

This skill uses:

- Plugin-level utilities from `${CLAUDE_PLUGIN_ROOT}/scripts/utils/`
- Plugin-level `create-entity.sh` for entity creation
- Skill-level `scripts/generate-query-batches-readme.sh` for README generation
- Inline bash from phase reference documentation

## Why Sequential?

Previous architecture had 8-50 findings-creator agents running in parallel, each creating its own batch. This caused:

- **Race conditions**: Batch ID collisions during entity index updates
- **Context contamination**: Config IDs from prior questions bleeding into current processing
- **Complex stability mechanisms**: Two-phase commits, in-memory env vars, 18+ anti-hallucination patterns

Sequential batch creation in a single skill **eliminates all these issues by construction**.

## Prerequisites

- Deeper-research workspace initialized (Phase 2 complete)
- Refined question entities in `02-refined-questions/data/`
- `.metadata/sprint-log.json` with project configuration
- CLAUDE_PLUGIN_ROOT environment variable set
- **PROJECT_PATH parameter provided** (must be extracted from prompt and exported before Phase 0 validation)

## Critical Constraints

### No Fabrication Rule

**Every query MUST derive from the refined question's PICOT structure.**

Prohibited:
- Inventing search keywords not in PICOT
- Creating queries for topics not in the question
- Generating configs without corresponding question entity

### Write Tool Prohibition

**NEVER use Write tool for entity files.** This is HARD FAILURE.

| Directory | Required Tool | Write Tool = |
|-----------|---------------|--------------|
| `03-query-batches/data/` | `create-entity.sh` | **VIOLATION** |

**If create-entity.sh fails**: Log error, continue with next question. DO NOT use Write tool fallback.

**⛔ ALSO PROHIBITED:**

- Creating custom bash scripts that use `cat >` or heredoc to write entity files
- Using `echo >` to create entity files
- Any file creation method that bypasses `create-entity.sh`

**Why this matters**: Custom scripts bypass:

- Entity index registration
- UUID generation
- Schema validation
- Deduplication checks

**Correct pattern**:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "${PROJECT_PATH}" \
  --entity-type "03-query-batches" \
  --entity-id "${BATCH_ID}" \
  --data "${BATCH_JSON}"
```

### Batch Naming Convention

**STANDARD:** `{question_id}-batch.md`

**Example:** `question-sustainable-business-models-g9h0i1j2-batch.md`

**Derivation:**

```bash
BATCH_ID="${QUESTION_ID}-batch"
BATCH_FILE="${PROJECT_PATH}/${QUERY_BATCHES_DIR}/data/${BATCH_ID}.md"
```

**Pattern:** `^question-[a-z0-9-]+-[a-f0-9]{8}-batch\.md$`

**Why This Standard:**

- Aligns with question entity naming pattern
- Simplifies batch resolution logic (append "-batch")
- Matches schema `dc:identifier` pattern
- Eliminates timing bugs in Phase 3 discovery

**Deprecated:** `batch-{slug}.md` format (scheduled for removal in v1.11.0)

### Temp Script Creation

For complex bash logic (arrays, loops, multi-line conditionals), write to a temp script file then execute it. **Use Bash tool with heredoc, NOT Write tool**:

```bash
cat > /tmp/batch-creator-step.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
# Complex logic here (arrays, loops, etc.)
QUESTIONS_DIR="${PROJECT_PATH}/02-refined-questions/data"
QUESTION_FILES=($(find "${QUESTIONS_DIR}" -name "question-*.md" -type f | sort))
# ... processing ...
SCRIPT_EOF
chmod +x /tmp/batch-creator-step.sh && bash /tmp/batch-creator-step.sh
```

**⚠️ Write Tool Limitation**: Claude Code's Write tool requires reading a file first before writing. For new temp scripts, ALWAYS use `cat > file << 'EOF'` via Bash tool.

### Inline Bash Compatibility

**CRITICAL**: See [../../references/shell-compatibility.md](../../references/shell-compatibility.md) for zsh/bash compatibility patterns.

Key rule: Never use multiple variable assignments with `$()` on one line. Chain with `&&` instead:

```bash
# CORRECT
A=$(cmd) && B=$(cmd) && echo "$A $B"

# WRONG - causes parse error in zsh
A=$(cmd) B=$(cmd) echo "$A $B"
```

### File Counting Pattern

**NEVER use `ls | wc -l` for file counting.** This causes zsh parse errors.

```bash
# CORRECT - find-based counting (zsh-compatible)
count=$(find "${DIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

# WRONG - causes zsh parse error
count=$(ls "${DIR}"/*.md 2>/dev/null | wc -l)
```

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Rule 5 for details.

### WebSearch API Constraints

Query-batches store `websearch_params` mapping directly to WebSearch tool:

| Parameter | Type | Required | Constraints |
|-----------|------|----------|-------------|
| `query` | string | Yes | Max ~2000 chars, include temporal modifiers |
| `user_location` | object | No | `type: "approximate"` + `country` |
| `allowed_domains` | string[] | No | No HTTP scheme, XOR with blocked_domains |
| `blocked_domains` | string[] | No | No HTTP scheme, XOR with allowed_domains |

**Domain format**: `["reuters.com"]` NOT `["https://reuters.com"]`

## Immediate Action: Initialize TodoWrite

**MANDATORY** - Initialize TodoWrite immediately:

1. Phase 0: Environment Validation [in_progress]
2. Phase 1: Load Refined Questions [pending]
3. Phase 2: Query Optimization (sequential per question) [pending]
4. Phase 3: Batch Creation (sequential per question) [pending]
5. Phase 4: README Generation & Summary [pending]

Update todo status as you progress through each phase.

---

## Core Workflow

```text
Phase 0 → Phase 1 → [FOR EACH question] → Phase 2 → Phase 3 → [END LOOP] → Phase 4
```

**CRITICAL**: This skill uses progressive disclosure. Each phase reference contains essential procedural details NOT duplicated here.

### Execution Protocol

1. **First**: Read phase-0-environment.md to validate environment
2. **Per-phase**: Read the linked reference file BEFORE executing that phase
3. **Verification**: After reading each phase reference, output the verification checksum

**⛔ MANDATORY: Read the phase reference file BEFORE executing that phase.**

### Phase 0: Environment Validation

Read [references/workflow-phases/phase-0-environment.md](references/workflow-phases/phase-0-environment.md), then execute:

1. Validate CLAUDE_PLUGIN_ROOT environment variable
2. Verify PROJECT_PATH parameter
3. Check `02-refined-questions/data/` directory exists
4. Initialize logging to `.logs/batch-creator/`
5. Load project language from `.metadata/sprint-log.json`

### Phase 1: Load Refined Questions

**⛔ GATE CHECK:** Verify Phase 0 completed (environment validated).

Read [references/workflow-phases/phase-1-load-questions.md](references/workflow-phases/phase-1-load-questions.md), then execute:

1. Glob all question files from `02-refined-questions/data/*.md`
2. For each question, extract PICOT metadata from frontmatter
3. Build QUESTIONS_ARRAY with: id, path, picot, dimension_ref, language
4. Log question count and dimension distribution

**Required outputs:**

- QUESTIONS_ARRAY populated
- QUESTION_COUNT set
- Phase 1 todo marked complete

---

### Phase 2+3: Iterative Batch Creation (MANDATORY FOR ALL QUESTIONS)

**CRITICAL:** The Phase 2→3 loop MUST iterate through ALL questions loaded in Phase 1. This is NOT optional - the loop continues until EVERY question has a corresponding batch entity.

#### Iteration Setup (MANDATORY - Before First Question)

After completing Phase 1 (questions loaded into QUESTION_FILES array):

```bash
# Initialize iteration tracking (REQUIRED)
QUESTION_INDEX=0
QUESTIONS_TOTAL=${#QUESTION_FILES[@]}
BATCHES_CREATED=0
BATCHES_FAILED=0
TOTAL_CONFIGS=0

log_conditional INFO "Starting batch creation for ${QUESTIONS_TOTAL} questions"
```

#### Iteration Loop Structure

```bash
# EXPLICIT LOOP - Process ALL questions
while [ $QUESTION_INDEX -lt $QUESTIONS_TOTAL ]; do
    CURRENT_QUESTION="${QUESTION_FILES[$QUESTION_INDEX]}"
    QUESTION_ID=$(basename "${CURRENT_QUESTION}" .md)

    log_conditional INFO "Processing question $((QUESTION_INDEX+1)) of ${QUESTIONS_TOTAL}: ${QUESTION_ID}"

    # ========== PHASE 2: Query Optimization for CURRENT question ==========
    # (Read phase-2-query-optimization.md, generate SEARCH_CONFIGS)

    # ========== PHASE 3: Batch Creation for CURRENT question ==========
    # (Read phase-3-batch-creation.md, invoke create-entity.sh)

    # ========== Error Handling (Continue on Failure) ==========
    if [ $? -ne 0 ]; then
        log_conditional ERROR "Batch creation failed for ${QUESTION_ID} - continuing with next"
        BATCHES_FAILED=$((BATCHES_FAILED + 1))
    else
        BATCHES_CREATED=$((BATCHES_CREATED + 1))
    fi

    # ========== INCREMENT (MANDATORY) ==========
    QUESTION_INDEX=$((QUESTION_INDEX + 1))
done
```

#### Post-Loop Gate Check (MANDATORY)

```bash
# Verify ALL questions were processed
if [ $BATCHES_CREATED -eq 0 ]; then
    log_conditional ERROR "CRITICAL: No batches created. Halting."
    exit 120
fi

EXPECTED_TOTAL=$QUESTIONS_TOTAL
ACTUAL_PROCESSED=$((BATCHES_CREATED + BATCHES_FAILED))

if [ $ACTUAL_PROCESSED -ne $EXPECTED_TOTAL ]; then
    log_conditional ERROR "Loop incomplete: processed ${ACTUAL_PROCESSED} of ${EXPECTED_TOTAL} questions"
    exit 121
fi

log_conditional INFO "Loop complete: ${BATCHES_CREATED} batches created, ${BATCHES_FAILED} failed"
```

**Only proceed to Phase 4 after this gate check passes.**

---

### Phase 2: Query Optimization (Per Question)

**CONTEXT:** This phase executes WITHIN the iteration loop. It processes the CURRENT question only (QUESTION_FILES[QUESTION_INDEX]).

**⛔ GATE CHECK:** Verify QUESTION_FILES array is populated from Phase 1.

Read [references/workflow-phases/phase-2-query-optimization.md](references/workflow-phases/phase-2-query-optimization.md), then execute for **CURRENT question**:

1. **Facet analysis**: Extract searchable facets from PICOT dimensions
2. **Complexity classification**: Simple (1-2 facets), Moderate (3-4), Complex (5+)
3. **Profile selection**: general, localized, industry, academic, trade, population, outcome
4. **Query generation**: 4-7 optimized queries per question
5. **Bilingual strategy**: For non-English questions, generate both original + English queries
6. **PICOT-Query alignment**: Verify ≥1 query contains Intervention keywords, ≥1 contains Population keywords
7. **Entity-specific handling**: For entity-specific questions, ensure PRIMARY_ENTITY in all queries

Store SEARCH_CONFIGS for Phase 3.

### Phase 3: Batch Creation (Per Question)

**CONTEXT:** This phase executes WITHIN the iteration loop, immediately after Phase 2 for the SAME question.

**⛔ GATE CHECK:** Verify SEARCH_CONFIGS populated from Phase 2 for CURRENT question.

Read [references/workflow-phases/phase-3-batch-creation.md](references/workflow-phases/phase-3-batch-creation.md), then execute for **CURRENT question**:

1. **Generate config IDs**: UUID-based config_id for each search config
2. **Build frontmatter**: search_configs[], picot, temporal_constraints, question_ref wikilink
3. **Build markdown body**: Render all configs with Query and Domains
4. **Create entity via create-entity.sh**:
   - Build JSON payload with frontmatter and content
   - Invoke `create-entity.sh --entity-type "03-query-batches" --entity-id "${BATCH_ID}"`
   - Script handles atomic writes, validation, and index registration
5. **Check result**: Parse JSON response, update counters

**On failure**: Log error, increment FAILURE_COUNT, continue with next question.

### Phase 4: README Generation & Summary

**⛔ BLOCKING GATE CHECK (MANDATORY):** Verify iteration loop completed before entering Phase 4.

```bash
# Pre-Phase-4 Verification (BLOCKING)
if [ $QUESTION_INDEX -lt $QUESTIONS_TOTAL ]; then
    log_conditional ERROR "HALT: Phase 4 entered prematurely. Only processed ${QUESTION_INDEX} of ${QUESTIONS_TOTAL} questions."
    exit 122
fi

PROCESSED_COUNT=$((BATCHES_CREATED + BATCHES_FAILED))
if [ $PROCESSED_COUNT -ne $QUESTIONS_TOTAL ]; then
    log_conditional ERROR "HALT: Counter mismatch. QUESTION_INDEX=${QUESTION_INDEX}, PROCESSED=${PROCESSED_COUNT}, TOTAL=${QUESTIONS_TOTAL}"
    exit 123
fi

log_conditional INFO "Phase 4 gate check PASSED: All ${QUESTIONS_TOTAL} questions processed"
```

**Only proceed if gate check passes.**

Read [references/workflow-phases/phase-4-summary.md](references/workflow-phases/phase-4-summary.md), then execute:

1. **Generate README**: Run `${CLAUDE_PLUGIN_ROOT}/skills/batch-creator/scripts/generate-query-batches-readme.sh` to create `03-query-batches/README.md`
2. Calculate statistics: batches_created, failures, avg_configs_per_batch
3. Write summary to `.metadata/batch-creation-summary.json`
4. Log execution metrics
5. Return JSON summary for orchestrator

**Return format:**

```json
{
  "success": true,
  "batches_created": 20,
  "batches_failed": 0,
  "total_configs": 120,
  "avg_configs_per_batch": 6.0,
  "execution_time_seconds": 45,
  "questions_directory": "02-refined-questions/data/",
  "batches_directory": "03-query-batches/data/"
}
```

---

## Error Handling

| Scenario | Action | Pipeline Impact |
|----------|--------|-----------------|
| Single batch creation fails | Log error, continue with remaining | Phase 3 skips that question |
| Multiple failures (>20%) | Continue but WARN in summary | Reduced coverage |
| Critical failure (environment) | HALT immediately | Pipeline stopped |
| PICOT extraction fails | Skip question, log error | No batch for that question |

## Logging Infrastructure

**Log directory**: `${PROJECT_PATH}/.logs/batch-creator/`

**Files created:**

- `batch-creator-execution-log.txt` - Main execution log
- `batch-creator-summary.json` - JSON summary (copied to `.metadata/`)

**DEBUG_MODE Configuration:**

- `DEBUG_MODE=true`: Verbose stderr + complete logs
- `DEBUG_MODE=false`: ERROR/WARN only to stderr + complete logs

---

## References Index

Read references **only when needed** for the specific task:

| Reference | Read when... |
|-----------|--------------|
| [references/workflow-phases/phase-0-environment.md](references/workflow-phases/phase-0-environment.md) | Starting Phase 0 |
| [references/workflow-phases/phase-1-load-questions.md](references/workflow-phases/phase-1-load-questions.md) | Starting Phase 1 |
| [references/workflow-phases/phase-2-query-optimization.md](references/workflow-phases/phase-2-query-optimization.md) | Processing each question (Phase 2) |
| [references/workflow-phases/phase-3-batch-creation.md](references/workflow-phases/phase-3-batch-creation.md) | Creating each batch (Phase 3) |
| [references/workflow-phases/phase-4-summary.md](references/workflow-phases/phase-4-summary.md) | Completing execution (Phase 4) |
| [../../references/query-batch-schema-contract.md](../../references/query-batch-schema-contract.md) | Building batch entity structure |

---

## Validation Criteria

1. All question entities in `02-refined-questions/data/` have corresponding batch in `03-query-batches/data/`
2. Each batch has ≥4 search configs with valid query text
3. All batches have `question_ref` wikilink in frontmatter AND body
4. No context contamination (all config_ids contain correct question_id prefix)
5. Summary JSON accurately reflects creation statistics
6. README.md exists in `03-query-batches/` with correct batch count and statistics
