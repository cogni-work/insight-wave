# Phase 2: Dimensional Planning

**Verification Checksum:** `DIMENSIONAL-PLANNING-V2`

Delegate to dimension-planner agent to generate research dimensions, organized questions, and seed megatrends (for generic/smarter-service research types).

---

## Step 1: Invoke dimension-planner

Delegate to dimension-planner agent via Task tool:

1. **Invoke via Task tool:**
   - Agent: `dimension-planner`
   - Input: Path to `00-initial-question/data/*.md` entity
   - Project path: From Phase 0

2. **Capture full response JSON** - dimension-planner returns extended response format

---

## Step 2: Validate Response & Check for Seeds

Parse the dimension-planner response:

```bash
# Validate basic response
if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
  : # Success response valid, continue
else
  log_conditional ERROR "dimension-planner failed"
  exit 1
fi

# Extract counts
DIMENSION_COUNT=$(echo "$response" | jq -r '.dimensions')
QUESTION_COUNT=$(echo "$response" | jq -r '.questions')

# Log results
log_conditional INFO "dimension-planner completed: ${DIMENSION_COUNT} dimensions, ${QUESTION_COUNT} questions"
```

### 2.1 Check for Seed Megatrends (generic/smarter-service)

For `generic` and `smarter-service` research types, dimension-planner executes Phase 4b and returns seed megatrends:

```bash
# Check if seed megatrends need user validation
if echo "$response" | jq -e '.seed_megatrends.pending_validation == true' > /dev/null 2>&1; then
  SEED_COUNT=$(echo "$response" | jq -r '.seed_megatrends.count')
  SEED_FILE=$(echo "$response" | jq -r '.seed_megatrends.file')
  EXECUTE_PHASE_2B=true
  log_conditional INFO "Seed megatrends require user validation: ${SEED_COUNT} seeds"
else
  EXECUTE_PHASE_2B=false
  log_conditional INFO "No seed megatrends pending validation"
fi
```

### 2.2 Verify Artifacts

Verify dimension-planner created the expected artifacts:

```bash
# Verify dimensions created
dimension_count=$(find "${project_path}/01-research-dimensions/data" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$dimension_count" -lt 2 ]; then
  log_conditional ERROR "Expected 2-10 dimensions, found: ${dimension_count}"
  exit 1
fi

# Verify questions created
question_count=$(find "${project_path}/02-refined-questions/data" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$question_count" -lt 8 ]; then
  log_conditional ERROR "Expected 8+ questions, found: ${question_count}"
  exit 1
fi

log_conditional INFO "✓ Artifacts verified: ${dimension_count} dimensions, ${question_count} questions"
```

---

## Step 3: Conditional Phase 2b Execution

### ⛔ IF `EXECUTE_PHASE_2B=true` (MANDATORY - DO NOT SKIP):

1. Log: `[INFO] Proceeding to Phase 2b: Megatrend Seed Validation`
2. Read [phase-2b-megatrend-validation.md](phase-2b-megatrend-validation.md)
3. Confirm checksum: `MEGATREND-VALIDATION-V1`
4. Execute Phase 2b steps:
   - Load seed megatrends from `.metadata/seed-megatrends.yaml`
   - Present to user via AskUserQuestion
   - Allow user to accept/modify/remove/add seeds
   - Update `seed-megatrends.yaml` with `user_validated: true`
5. Log: `✓ Phase 2b: Validated ${SEED_COUNT} seed megatrends`

**⛔ CRITICAL:** You MUST call AskUserQuestion in Phase 2b to present seeds to user.
Proceeding to Phase 2.5 without user validation violates the workflow contract.

### IF `EXECUTE_PHASE_2B=false`:

1. Log: `[INFO] Skipping Phase 2b - seeds not applicable or already validated`
2. Proceed directly to Step 4

---

## Step 3.5: Verify Phase 2b Completion (MANDATORY)

Before proceeding to Step 4, verify seed validation:

```bash
# Validate project_path is set (prevents empty path errors)
if [[ -z "${project_path:-}" ]]; then
  echo "ERROR: project_path is not set - cannot verify Phase 2b completion" >&2
  exit 1
fi

# Verify user validation completed (for generic/smarter-service)
SEED_FILE="${project_path}/.metadata/seed-megatrends.yaml"
if [ -f "$SEED_FILE" ]; then
  if grep -q "user_validated: false" "$SEED_FILE"; then
    echo "ERROR: Phase 2b incomplete - seed megatrends require user validation" >&2
    echo "HALT: Execute Phase 2b with AskUserQuestion before proceeding" >&2
    exit 1
  fi
  echo "✓ Seed megatrends validated by user"
else
  echo "INFO: No seed-megatrends.yaml found at ${SEED_FILE} - skipping validation"
fi
```

**IF CHECK FAILS:** STOP. Return to Phase 2b and execute AskUserQuestion for megatrend validation.

---

## Step 4: Report Completion

```text
✓ Phase 2: Created {DIMENSION_COUNT} research dimensions, {QUESTION_COUNT} detailed questions
✓ Phase 2b: Validated {SEED_COUNT} seed megatrends (if applicable)
```

Mark Phase 2 complete in TodoWrite. Proceed to Phase 2.5.

---

## Expected Response Format

dimension-planner returns:

```json
{
  "success": true,
  "dimensions": 4,
  "questions": 16,
  "seed_megatrends": {
    "count": 5,
    "file": ".metadata/seed-megatrends.yaml",
    "pending_validation": true
  }
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | true if dimension-planner completed successfully |
| `dimensions` | integer | Number of research dimensions created (2-10) |
| `questions` | integer | Number of refined questions created (8-50/36/57) |
| `seed_megatrends` | object | Present only for generic/smarter-service research types |
| `seed_megatrends.count` | integer | Number of seed megatrends proposed |
| `seed_megatrends.file` | string | Path to seed-megatrends.yaml |
| `seed_megatrends.pending_validation` | boolean | true if user validation required |

---

## Phase 2b Trigger Conditions

Execute Phase 2b when **ALL** conditions are met:

1. `seed_megatrends.pending_validation == true` in dimension-planner response
2. `.metadata/seed-megatrends.yaml` exists in project
3. File has `user_validated: false` in metadata

**Skip Phase 2b when:**

- `lean-canvas` research type (uses fixed canvas blocks)
- `seed-megatrends.yaml` already has `user_validated: true`
- No `seed_megatrends` field in dimension-planner response

---

**Document Size:** ~3KB | **Type:** Execution Instruction | **Complexity:** Medium
