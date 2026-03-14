---
reference: phase-4-summary
version: 1.1.0
checksum: phase-4-summary-v1.1.0-batch-creator
dependencies: [phase-3-batch-creation]
phase: 4
---

# Phase 4: README Generation & Summary

**Checksum:** `phase-4-summary-v1.1.0-batch-creator`

---

## Purpose

Generate README.md for query batches, calculate execution statistics, write summary file, and return JSON result to calling agent.

---

## Step 4.0 (Pre-check): Blocking Gate Check (MANDATORY)

**CRITICAL:** Before proceeding with README generation, verify that ALL questions have been processed.

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

# Filesystem verification
ACTUAL_BATCH_COUNT=$(find "${PROJECT_PATH}/03-query-batches/data" -name "*-batch.md" -type f | wc -l | tr -d ' ')
if [ "$ACTUAL_BATCH_COUNT" -lt "$BATCHES_CREATED" ]; then
    log_conditional ERROR "Filesystem mismatch: Expected ${BATCHES_CREATED} batches, found ${ACTUAL_BATCH_COUNT}"
    exit 124
fi

log_conditional INFO "Phase 4 gate check PASSED: All ${QUESTIONS_TOTAL} questions processed, ${ACTUAL_BATCH_COUNT} batch files verified"
```

**HALT CONDITIONS:**

| Exit Code | Condition | Meaning |
|-----------|-----------|---------|
| 122 | `QUESTION_INDEX < QUESTIONS_TOTAL` | Loop exited before processing all questions |
| 123 | `PROCESSED_COUNT != QUESTIONS_TOTAL` | Counter mismatch - some iterations lost |
| 124 | `ACTUAL_BATCH_COUNT < BATCHES_CREATED` | Files missing from filesystem |

**Only proceed to README generation if this gate check passes.**

---

## Step 4.1: Generate Query Batches README

**MANDATORY**: Run the README generator script before calculating statistics.

```bash
# Generate README.md for query-batches directory
# Use skill-level scripts directory via CLAUDE_PLUGIN_ROOT
README_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/batch-creator/scripts/generate-query-batches-readme.sh"

if [ -x "$README_SCRIPT" ]; then
  README_RESULT=$(bash "$README_SCRIPT" --project-path "$PROJECT_PATH" --language "$PROJECT_LANGUAGE" --json 2>/dev/null)
  README_SUCCESS=$(echo "$README_RESULT" | jq -r '.success // false')

  if [ "$README_SUCCESS" = "true" ]; then
    log_phase "README generation" "success"
  else
    log_phase "README generation" "failed - continuing without README"
  fi
else
  log_phase "README generation" "skipped - script not found"
fi
```

**Verification**: After running, check that `${PROJECT_PATH}/03-query-batches/README.md` exists.

---

## Step 4.2: Calculate Statistics

```bash
# Calculate averages
if [ $BATCHES_CREATED -gt 0 ]; then
  AVG_CONFIGS=$(echo "scale=1; $TOTAL_CONFIGS / $BATCHES_CREATED" | bc)
else
  AVG_CONFIGS=0
fi

# Calculate execution time
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

# Determine success
if [ $BATCHES_FAILED -eq 0 ]; then
  SUCCESS=true
elif [ $BATCHES_FAILED -lt $((QUESTION_COUNT / 5)) ]; then
  SUCCESS=true  # <20% failure is still success
else
  SUCCESS=false
fi
```

---

## Step 4.3: Write Summary File

```bash
SUMMARY_FILE="${PROJECT_PATH}/.metadata/batch-creation-summary.json"

cat > "${SUMMARY_FILE}" << EOF
{
  "success": ${SUCCESS},
  "batches_created": ${BATCHES_CREATED},
  "batches_failed": ${BATCHES_FAILED},
  "total_configs": ${TOTAL_CONFIGS},
  "avg_configs_per_batch": ${AVG_CONFIGS},
  "execution_time_seconds": ${EXECUTION_TIME},
  "questions_directory": "02-refined-questions/data/",
  "batches_directory": "03-query-batches/data/",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
```

---

## Step 4.4: Log Final Metrics

```bash
log_metric "batches_created" "$BATCHES_CREATED"
log_metric "batches_failed" "$BATCHES_FAILED"
log_metric "total_configs" "$TOTAL_CONFIGS"
log_metric "avg_configs" "$AVG_CONFIGS"
log_metric "execution_time" "$EXECUTION_TIME"
log_phase "Phase 4: Statistics & Summary" "complete"
log_phase "batch-creator" "complete"
```

---

## Step 4.5: Return JSON Result

**Output ONLY this JSON. No prose.**

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

## Validation Criteria

Before returning:

1. All questions from Phase 1 have been processed
2. README.md exists in `03-query-batches/` directory
3. Summary file written to `.metadata/`
4. Execution log complete
5. JSON output formatted correctly

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Partial success (some failures, <20%) |
| 122 | Critical batch creation failure |
| 113 | No questions found |
