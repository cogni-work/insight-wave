# Phase 2.5: Batch Creation (Sequential)

**Reference Checksum:** `sha256:p2.5-v1.0-batch-creator`

**Verification Protocol:** After reading this reference, confirm complete load by outputting:

```
Reference Loaded: phase-2.5-batch-creation.md | Checksum: p2.5-v1.0-batch-creator
```

---

**Objective:** Invoke batch-creator agent to create query batches for ALL refined questions sequentially. This eliminates race conditions and context contamination from parallel batch creation.

---

## Step 0: Derive project_path (MANDATORY)

**⛔ CRITICAL:** Before any Phase 2.5 work, derive and validate `project_path`:

```bash
# Derive project_path from sprint-log.json location
sprint_log="$(find . -path "*/.metadata/sprint-log.json" -type f 2>/dev/null | head -1)"
if [ -z "$sprint_log" ]; then echo "ERROR: No sprint-log.json found. Ensure Phase 0 completed." >&2; exit 1; fi
project_path="$(cd "$(dirname "$sprint_log")/.." && pwd)"

# Validate
if [ ! -d "${project_path}/.metadata" ]; then echo "ERROR: Invalid project_path: ${project_path}" >&2; exit 1; fi
echo "project_path: ${project_path}"
```

**Use this `project_path` value in ALL subsequent commands in this phase.**

---

## Phase Entry Verification (MANDATORY)

Before starting, verify Phase 2 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set. Run Step 0 first." >&2; exit 1; fi

# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DATA_SUBDIR="$(get_data_subdir)"

ls -la "${project_path}/$DIR_REFINED_QUESTIONS/$DATA_SUBDIR/"*.md
```

**IF MISSING: STOP. Return to Phase 2 and create required artifacts.**

---

## Phase 2b Validation Gate (MANDATORY)

**⛔ BLOCKING CHECK:** For `generic` and `smarter-service` research types, verify Phase 2b completed:

```bash
# Validate project_path is set (prevents empty path errors)
if [[ -z "${project_path:-}" ]]; then
  echo "ERROR: project_path is not set - cannot validate Phase 2b" >&2
  exit 1
fi

# Check research type
RESEARCH_TYPE=$(grep "^research_type:" "${project_path}/00-initial-question/data/"*.md | head -1 | awk '{print $2}')

case "$RESEARCH_TYPE" in
  generic|smarter-service)
    SEED_FILE="${project_path}/.metadata/seed-megatrends.yaml"
    if [ -f "$SEED_FILE" ]; then
      if grep -q "user_validated: false" "$SEED_FILE"; then
        echo "⛔ HALT: Phase 2b not completed" >&2
        echo "Seed megatrends exist but user_validated: false" >&2
        echo "You MUST return to Phase 2b and call AskUserQuestion" >&2
        exit 1
      fi
      echo "✓ Phase 2b complete: seed megatrends validated"
    else
      echo "✓ No seed megatrends file (Phase 4b skipped)"
    fi
    ;;
  *)
    echo "✓ Phase 2b not applicable for ${RESEARCH_TYPE}"
    ;;
esac
```

**IF CHECK FAILS:** STOP. Return to Phase 2b and execute AskUserQuestion for megatrend validation.

---

## Step 0.5: Initialize TodoWrite

Update TodoWrite with Phase 2.5 status:

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 2: Dimensional planning → completed
- Phase 2.5: Batch creation → in_progress
```

---

## Step 1: Invoke batch-creator Agent

Invoke batch-creator agent via Task tool (single invocation, sequential execution):

```text
Task(subagent_type="cogni-research:batch-creator", prompt="PROJECT_PATH={project_path}")
```

The batch-creator agent handles all internal phases:
1. Environment validation
2. Load refined questions from `02-refined-questions/data/`
3. Generate 4-7 optimized search configs per question (PICOT facet decomposition)
4. Create batch entities sequentially in `03-query-batches/data/`
5. Return JSON summary

**Why Sequential:** Eliminates race conditions and context contamination that occur with parallel batch creation. All batches created in single LLM context before parallel findings execution.

---

## Step 2: Validate Results

After agent completes, verify:

1. **JSON Response Validation:**
   ```text
   Verify response contains: {"success": true, "batches_created": N, ...}
   ```

2. **Coverage Validation:**
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/validate-phase3-completion.sh" --project-path "${project_path}"
   ```

   Verify response shows `"success": true` and matching question/batch counts.

3. **Directory Validation:**
   ```bash
   ls -la ${project_path}/$DIR_QUERY_BATCHES/$DATA_SUBDIR/*.md
   ```

**IF BATCHES MISSING:** Review batch-creator output for errors. Re-run if needed.

### Shell Compatibility Note

When validating Phase 2.5 completion, use **separate bash commands** for each directory count:

```bash
# CORRECT - Separate commands (zsh-compatible)
QUESTIONS_COUNT=$(find "${project_path}/$DIR_REFINED_QUESTIONS/$DATA_SUBDIR" -name 'question-*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
echo "Questions: ${QUESTIONS_COUNT}"

BATCHES_COUNT=$(find "${project_path}/$DIR_QUERY_BATCHES/$DATA_SUBDIR" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
echo "Batches: ${BATCHES_COUNT}"
```

**⛔ PROHIBITED:** Do NOT combine multiple `$()` on one line:

```bash
# WRONG - Causes zsh parse error: (eval):1: parse error near `('
QUESTIONS=$(find ...) && BATCHES=$(find ...)
```

See [shell-compatibility.md](../../../deeper-research-1/references/shell-compatibility.md) for additional patterns.

---

## Step 3: Mark Phase Complete

Update TodoWrite:

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 2.5: Batch creation → completed
- Phase 3: Parallel findings creation → in_progress
```

---

## Self-Verification Questions

Before proceeding to Phase 3:

1. Did you run the phase entry verification gate (ls command)? ✅ YES / ❌ NO
2. Did you invoke batch-creator agent via Task tool? ✅ YES / ❌ NO
3. Did the agent return `success: true` in JSON response? ✅ YES / ❌ NO
4. Does `batches_created` equal the number of refined questions? ✅ YES / ❌ NO
5. Does `03-query-batches/data/` directory contain batch files? ✅ YES / ❌ NO

**IF ANY NO:** STOP. Complete the missing step before proceeding.

---

## Next Phase

Proceed to [phase-3-parallel-findings-creation.md](phase-3-parallel-findings-creation.md).
