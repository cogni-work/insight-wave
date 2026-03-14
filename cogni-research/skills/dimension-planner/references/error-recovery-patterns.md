## Runtime Safety Patterns

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 1 (Parameter parsing with POSIX locale safety)


## Section 6: Error Handling Patterns

Comprehensive error recovery patterns for dimension-planner execution. Each scenario includes detection, recovery, and validation steps.

### Error Scenario Reference

| Scenario | Detection | Recovery | Exit | Reference |
|----------|-----------|----------|------|-----------|
| No question file path | $QUESTION_FILE empty | Return error JSON | 1 | 6.1 |
| Question file not found | [ ! -f "$QUESTION_FILE" ] | Return error JSON | 1 | 6.2 |
| Invalid project structure | Missing .metadata | Return error JSON | 1 | 6.3 |
| CLAUDE_PLUGIN_ROOT not set | Empty or unset | Return error JSON | 1 | 6.4 |
| Template not found | [ ! -f "$DIMENSION_TEMPLATE" ] | Return error JSON | 1 | 6.5 |
| MECE validation fails (>20% overlap) | Overlap check | Return error JSON | 1 | 6.6 |
| Dimension count out of range | [ $DIMENSION_COUNT -lt 2 ] or > 9 | Return error JSON | 1 | 6.7 |
| Question count out of range | [ $TOTAL_QUESTIONS -lt 6 ] or > 40 | Return error JSON | 1 | 6.8 |
| Individual FINER score <10 | Score check | Log warning, reformulate | 0 | 6.9 |
| Average FINER score <11.0 | Average calculation | Return error JSON | 1 | 6.10 |

### 6.1: No Question File Path

**Detection:**
```bash
if [ -z "$QUESTION_FILE" ]; then
  log_conditional ERROR "No question file path provided"
  ERROR_DETECTED="true"
fi
```

**Recovery:**
```bash
if [ "$ERROR_DETECTED" = "true" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Missing required parameter: question_file" \
    '{success: $success, error: $error}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Validation:** Confirm exit code 1, error message in stderr.

### 6.2: Question File Not Found

**Detection:**
```bash
if [ ! -f "$QUESTION_FILE" ]; then
  log_conditional ERROR "Question file not found: $QUESTION_FILE"
  ERROR_TYPE="file_not_found"
fi
```

**Recovery:**
```bash
if [ "$ERROR_TYPE" = "file_not_found" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Question file does not exist: ${QUESTION_FILE}" \
    --arg path "$QUESTION_FILE" \
    '{success: $success, error: $error, path: $path}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Validation:** Verify file path in error response, check parent directory exists.

### 6.3: Invalid Project Structure

**Detection:**
```bash
# Project must have .metadata/sprint-log.json
if [ ! -f "$PROJECT_PATH/.metadata/sprint-log.json" ]; then
  log_conditional ERROR "Invalid project structure: missing .metadata/sprint-log.json"
  ERROR_TYPE="invalid_project"
fi
```

**Recovery:**
```bash
if [ "$ERROR_TYPE" = "invalid_project" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Project structure invalid: missing .metadata/sprint-log.json" \
    --arg project "$PROJECT_PATH" \
    '{success: $success, error: $error, project_path: $project}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Validation:** User must create proper project structure before running skill.

### 6.4: CLAUDE_PLUGIN_ROOT Not Set

**Detection:**
```bash
if [ -z "$CLAUDE_PLUGIN_ROOT" ] || [ ! -d "$CLAUDE_PLUGIN_ROOT" ]; then
  log_conditional ERROR "CLAUDE_PLUGIN_ROOT not set or invalid"
  ERROR_TYPE="environment"
fi
```

**Recovery:**
```bash
if [ "$ERROR_TYPE" = "environment" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Environment variable CLAUDE_PLUGIN_ROOT not set" \
    '{success: $success, error: $error}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Validation:** Confirm skill installation and environment setup.

### 6.5: Template Not Found (Explicit Research Type)

**Detection:**
```bash
if [ "$RESEARCH_TYPE" != "generic" ] && [ ! -f "$DIMENSION_TEMPLATE" ]; then
  log_conditional ERROR "Template not found: $DIMENSION_TEMPLATE"
  ERROR_TYPE="template_not_found"
fi
```

**Recovery:**
```bash
if [ "$ERROR_TYPE" = "template_not_found" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Research type template not found: ${RESEARCH_TYPE}" \
    --arg research_type "$RESEARCH_TYPE" \
    --arg expected_path "$DIMENSION_TEMPLATE" \
    '{success: $success, error: $error, research_type: $research_type, expected_path: $expected_path}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Graceful degradation:** Fall back to domain-based mode if template unavailable:
```bash
if [ "$RESEARCH_TYPE" != "generic" ] && [ ! -f "$DIMENSION_TEMPLATE" ]; then
  log_conditional WARNING "Template not found, falling back to domain-based mode"
  DIMENSIONS_MODE="domain-based"
  RESEARCH_TYPE="generic"
  # Continue with domain-based workflow
fi
```

### 6.6: MECE Validation Fails (>20% Overlap)

**Detection (Phase 4.1):**
```bash
# Calculate pairwise overlap for all dimension pairs
MAX_OVERLAP=0
for ((i=0; i<${#SELECTED_DIMENSIONS[@]}; i++)); do
  for ((j=i+1; j<${#SELECTED_DIMENSIONS[@]}; j++)); do
    OVERLAP=$(calculate_overlap "${SELECTED_DIMENSIONS[$i]}" "${SELECTED_DIMENSIONS[$j]}")
    if (( $(echo "$OVERLAP > $MAX_OVERLAP" | bc -l) )); then
      MAX_OVERLAP=$OVERLAP
    fi
    if (( $(echo "$OVERLAP > 20" | bc -l) )); then
      log_conditional ERROR "MECE violation: ${SELECTED_DIMENSIONS[$i]} ↔ ${SELECTED_DIMENSIONS[$j]} = ${OVERLAP}% overlap"
      ERROR_TYPE="mece_violation"
    fi
  done
done

if [ "$ERROR_TYPE" = "mece_violation" ]; then
  log_conditional ERROR "MECE validation failed: maximum overlap ${MAX_OVERLAP}% exceeds threshold 20%"
  MECE_VALID="false"
fi
```

**Recovery:**
```bash
if [ "$MECE_VALID" != "true" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "MECE validation failed" \
    --argjson max_overlap "$MAX_OVERLAP" \
    --arg threshold "20" \
    '{success: $success, error: $error, max_overlap: $max_overlap, threshold: $threshold}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Validation script usage:**
```bash
# Phase 4.6: Validate outputs including MECE
bash scripts/validate-outputs.sh \
  --dimensions "$DIMENSION_COUNT" \
  --questions "$QUESTION_COUNT" \
  --avg-finer "$AVG_FINER_SCORE" \
  --mece-valid "$MECE_VALID" \
  --json
```

### 6.7: Dimension Count Out of Range

**Detection (Phase 2a or Phase 3):**
```bash
# Domain-based: 2-10 dimensions
# Research-type-specific: Fixed from template
if [ $DIMENSION_COUNT -lt 2 ]; then
  log_conditional ERROR "Too few dimensions: $DIMENSION_COUNT (minimum 2)"
  ERROR_TYPE="dimension_count_low"
elif [ $DIMENSION_COUNT -gt 10 ]; then
  log_conditional ERROR "Too many dimensions: $DIMENSION_COUNT (maximum 10)"
  ERROR_TYPE="dimension_count_high"
fi
```

**Recovery:**
```bash
if [ "$ERROR_TYPE" = "dimension_count_low" ] || [ "$ERROR_TYPE" = "dimension_count_high" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Dimension count out of range" \
    --argjson count "$DIMENSION_COUNT" \
    --argjson minimum 2 \
    --argjson maximum 10 \
    '{success: $success, error: $error, count: $count, minimum: $minimum, maximum: $maximum}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

### 6.8: Question Count Out of Range

**Detection (Phase 4.6):**
```bash
# Total questions: 8-50 minimum across all dimensions
if [ $TOTAL_QUESTIONS -lt 8 ]; then
  log_conditional ERROR "Too few questions: $TOTAL_QUESTIONS (minimum 8)"
  ERROR_TYPE="question_count_low"
elif [ $TOTAL_QUESTIONS -gt 50 ]; then
  log_conditional ERROR "Too many questions: $TOTAL_QUESTIONS (maximum 50)"
  ERROR_TYPE="question_count_high"
fi
```

**Recovery:**
```bash
if [ "$ERROR_TYPE" = "question_count_low" ] || [ "$ERROR_TYPE" = "question_count_high" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Question count out of range" \
    --argjson count "$TOTAL_QUESTIONS" \
    --argjson minimum 8 \
    --argjson maximum 50 \
    '{success: $success, error: $error, count: $count, minimum: $minimum, maximum: $maximum}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

### 6.9: Individual FINER Score <10 (Non-Fatal)

**Detection (Phase 4.3):**
```bash
# For each question, check individual FINER score
QUESTIONS_BELOW_THRESHOLD=0
for question_id in "${!FINER_SCORES[@]}"; do
  SCORE="${FINER_SCORES[$question_id]}"
  if [ "$SCORE" -lt 10 ]; then
    ((QUESTIONS_BELOW_THRESHOLD++))
    log_conditional WARNING "Question $question_id FINER score $SCORE below target 10"
  fi
done
```

**Recovery (Reformulation):**
```bash
if [ $QUESTIONS_BELOW_THRESHOLD -gt 0 ]; then
  log_conditional INFO "Reformulating $QUESTIONS_BELOW_THRESHOLD low-scoring questions..."

  # Re-evaluate and reformulate
  for question_id in "${!FINER_SCORES[@]}"; do
    SCORE="${FINER_SCORES[$question_id]}"
    if [ "$SCORE" -lt 10 ]; then
      # Adjust question, re-score
      NEW_QUESTION=$(reformulate_question "$question_id")
      NEW_SCORE=$(score_finer "$NEW_QUESTION")
      FINER_SCORES[$question_id]="$NEW_SCORE"
      log_conditional INFO "Reformulated $question_id: $SCORE → $NEW_SCORE"
    fi
  done

  # Continue workflow (exit code 0)
fi
```

**Validation:** Confirm reformulated questions meet threshold or are acceptable for domain context.

### 6.10: Average FINER Score <11.0 (Fatal)

**Detection (Phase 4.6):**
```bash
# Calculate average FINER score across all questions
TOTAL_SCORE=0
for score in "${FINER_SCORES[@]}"; do
  TOTAL_SCORE=$((TOTAL_SCORE + score))
done
AVG_FINER_SCORE=$(echo "scale=1; $TOTAL_SCORE / ${#FINER_SCORES[@]}" | bc)

if (( $(echo "$AVG_FINER_SCORE < 11.0" | bc -l) )); then
  log_conditional ERROR "Average FINER score $AVG_FINER_SCORE below threshold 11.0"
  FINER_VALID="false"
fi
```

**Recovery:**
```bash
if [ "$FINER_VALID" != "true" ]; then
  ERROR_RESPONSE=$(jq -n \
    --arg success "false" \
    --arg error "Average FINER score below quality threshold" \
    --argjson avg_score "$AVG_FINER_SCORE" \
    --arg threshold "11.0" \
    --argjson individual_below_10 "$QUESTIONS_BELOW_THRESHOLD" \
    '{success: $success, error: $error, avg_finer_score: $avg_score, threshold: $threshold, questions_reformulated: $individual_below_10}')
  echo "$ERROR_RESPONSE" >&2
  exit 1
fi
```

**Recommendations:** If average FINER insufficient despite reformulation:
1. Re-examine research question clarity
2. Adjust dimension selection (may have missed key aspects)
3. Consider domain expertise gaps
4. Simplify research scope

### Error Recovery Walkthrough: End-to-End Example

**Scenario:** User provides question file in German, research-type-specific mode (lean-canvas).

```bash
# Phase 0: Environment validation
PROJECT_PATH="/Users/name/my-project"
QUESTION_FILE="/Users/name/my-project/00-initial-questions/research-q1.md"
PROJECT_LANGUAGE="de"  # From .metadata/sprint-log.json

# Phase 1: Load question and detect mode
RESEARCH_TYPE="lean-canvas"
DIMENSION_TEMPLATE="${SKILL_BASE}/references/research-types/lean-canvas/dimensions-lean-canvas.md"

if [ ! -f "$DIMENSION_TEMPLATE" ]; then
  # ERROR 6.5: Template not found
  log_conditional WARNING "Template not found, attempting fallback to domain-based mode"
  DIMENSIONS_MODE="domain-based"
  RESEARCH_TYPE="generic"
  # Continue with domain-based workflow
else
  DIMENSIONS_MODE="research-type-specific"
  # Continue with template-based workflow
fi

# Phase 2a: Parse template
DIMENSION_COUNT=$(grep -c "^## Dimension:" "$DIMENSION_TEMPLATE")
if [ $DIMENSION_COUNT -ne 9 ]; then
  # ERROR 6.7: Dimension count incorrect for lean-canvas template
  log_conditional ERROR "Lean-canvas template has $DIMENSION_COUNT dimensions, expected 9"
  echo "{\"success\": false, \"error\": \"Template validation failed: incorrect dimension count\"}" >&2
  exit 1
fi

# Phases 3-4: Generate and validate questions...

# Phase 4.6: Final validation
if [ "$MECE_VALID" != "true" ]; then
  # ERROR 6.6: MECE validation failed
  exit 1
elif (( $(echo "$AVG_FINER_SCORE < 11.0" | bc -l) )); then
  # ERROR 6.10: Average FINER score too low
  exit 1
fi

# Phase 5: Create entities
# All dimensions created in German (display_name), English (slug)
# All questions created with localized display_name, English dc:identifier

echo "SUCCESS: Workflow completed with 9 dimensions, 27 questions, avg FINER 13.5"
```


## Logging Patterns

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 3 (Logging initialization and patterns)

### Section 4: Logging in LLM Context

**Important:** The logging functions (`log_conditional`, `log_phase`, `log_metric`) assume continuous bash execution context. In LLM-based skill execution:

1. Each Bash tool call is isolated (no persistent shell session)
2. Sourced functions don't persist between tool calls
3. LOG_FILE writes require explicit redirection in each call

**Practical implications:**
- **Terminal output (stderr):** Phase markers and metrics visible in real-time during Claude Code execution
- **LOG_FILE writes:** May not persist reliably across isolated tool calls
- **JSON report (Phase 5.3):** Primary reliable persistent output for debugging and audit trails

**Recommended debugging approach:**
1. Enable `DEBUG_MODE=true` in environment for verbose stderr output
2. Check `${PROJECT_PATH}/.metadata/dimension-planner-execution-log.txt` for partial logs
3. Rely on final JSON response (Phase 5.3) for structured metrics and validation


## JSON Response Pattern

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 4 (JSON response construction)

### Skill-Specific Response Fields

Success response must include mode-specific fields:

**Domain-based mode:**
```json
{
  "success": true,
  "dimensions_mode": "domain-based",
  "dok_level": 3,
  "domain_template": "business",
  "dimensions": 4,
  "questions": 16,
  "avg_finer_score": 13.2
}
```

**Research-type-specific mode:**
```json
{
  "success": true,
  "dimensions_mode": "research-type-specific",
  "research_type": "lean-canvas",
  "dimensions": 8,
  "questions": 24,
  "avg_finer_score": 13.5
}
```


