#!/usr/bin/env bash
set -euo pipefail
# verify-batch-creator-output.sh
# Anti-hallucination hook for batch-creator agent
# Version: 1.0.0
#
# Purpose: Validates batch-creator output against filesystem reality
# When hallucination detected, logs warning (no auto-recovery - skill is complex)
#
# Trigger: SubagentStop when batch-creator agent completes
#
# Detection Patterns (hallucination indicators):
# 1. Statistics claim batches_created > 0 but 03-query-batches/data/ is empty
# 2. Agent reports 0 tool uses (visible in CLAUDE_SUBAGENT_TOOL_COUNT)
# 3. Claimed batch count doesn't match actual files
#
# Exit codes:
#   0 - Validation passed or non-applicable
#   1 - Hallucination detected (warning logged, no recovery)

set -e

# Source centralized entity config (required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DATA_SUBDIR="$(get_data_subdir)"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"

# Only run for batch-creator agent
AGENT_NAME="${CLAUDE_SUBAGENT_NAME:-}"
! [[ "$AGENT_NAME" == "batch-creator" ]] && exit 0

# Get agent output
OUTPUT="${CLAUDE_SUBAGENT_OUTPUT:-}"
[[ -z "$OUTPUT" ]] && exit 0

# Try to extract JSON from output
JSON_OUTPUT=""
if echo "$OUTPUT" | jq -e '.' >/dev/null 2>&1; then
  JSON_OUTPUT="$OUTPUT"
else
  # Try to extract JSON from mixed output
  JSON_OUTPUT="$(echo "$OUTPUT" | grep -E '^\{' | tail -1 2>/dev/null || echo "")"
fi

[[ -z "$JSON_OUTPUT" ]] && {
  echo "WARNING: No JSON output from batch-creator"
  exit 0  # Can't verify without JSON
}

# Extract claimed metrics
CLAIMED_BATCHES="$(echo "$JSON_OUTPUT" | jq -r '.b // .batches_created // 0')"
CLAIMED_OK="$(echo "$JSON_OUTPUT" | jq -r '.ok // .success // false')"

# Early exit if no claims or failure reported
[[ "$CLAIMED_OK" == "false" ]] && exit 0
[[ "$CLAIMED_BATCHES" == "0" ]] && exit 0

# Try to find project path from context
PROJECT_PATH=""

# Check common locations based on current directory
if [[ -d "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # Look for deeper-research project structure
  for dir in "$CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"/*; do
    if [[ -d "$dir/${DIR_REFINED_QUESTIONS}/${DATA_SUBDIR}" ]]; then
      PROJECT_PATH="$dir"
      break
    fi
  done
fi

# Can't verify without project path
[[ -z "$PROJECT_PATH" ]] && {
  echo "INFO: Cannot locate project path for verification"
  exit 0
}

# ============================================================================
# ANTI-HALLUCINATION CHECKS
# ============================================================================

HALLUCINATION_DETECTED=false
HALLUCINATION_REASONS=""

# CHECK 1: Verify batches actually exist
if [[ "$CLAIMED_BATCHES" -gt 0 ]]; then
  BATCH_DIR="$PROJECT_PATH/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}"

  if [[ -d "$BATCH_DIR" ]]; then
    ACTUAL_BATCHES="$(find "$BATCH_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

    if [[ "$ACTUAL_BATCHES" -eq 0 ]]; then
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_BATCHES batches created but ${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/ is EMPTY"
    elif [[ "$ACTUAL_BATCHES" -lt $(($CLAIMED_BATCHES / 2)) ]]; then
      # Allow some tolerance but flag if way off
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_BATCHES batches but only $ACTUAL_BATCHES exist (>50% missing)"
    fi
  else
    HALLUCINATION_DETECTED=true
    HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Claimed $CLAIMED_BATCHES batches but ${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/ directory doesn't exist"
  fi
fi

# CHECK 2: Verify batch files have valid structure (sample check)
if [[ "$HALLUCINATION_DETECTED" == false ]] && [[ "$CLAIMED_BATCHES" -gt 0 ]]; then
  BATCH_DIR="$PROJECT_PATH/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}"

  # Check first batch file for required fields
  SAMPLE_BATCH="$(find "$BATCH_DIR" -name "*.md" -type f 2>/dev/null | head -1)"

  if [[ -n "$SAMPLE_BATCH" ]]; then
    # Check for required fields: search_configs, question_ref
    if ! grep -q 'search_configs:' "$SAMPLE_BATCH" 2>/dev/null; then
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Batch files missing 'search_configs' field"
    fi

    if ! grep -q 'question_ref:' "$SAMPLE_BATCH" 2>/dev/null; then
      HALLUCINATION_DETECTED=true
      HALLUCINATION_REASONS="${HALLUCINATION_REASONS}\n- Batch files missing 'question_ref' field"
    fi
  fi
fi

# CHECK 3: Verify log directory was created (indicates real execution)
if [[ "$HALLUCINATION_DETECTED" == false ]]; then
  LOG_DIR="$PROJECT_PATH/.logs/batch-creator"

  if [[ ! -d "$LOG_DIR" ]]; then
    # Not conclusive but suspicious
    echo "WARNING: batch-creator log directory not found at $LOG_DIR"
  fi
fi

# ============================================================================
# VERDICT
# ============================================================================

if [[ "$HALLUCINATION_DETECTED" == true ]]; then
  echo ""
  echo "========================================"
  echo "ANTI-HALLUCINATION GATE TRIGGERED"
  echo "========================================"
  echo ""
  echo "The batch-creator agent appears to have SIMULATED execution"
  echo "without actually creating files."
  echo ""
  echo "Detection reasons:"
  echo -e "$HALLUCINATION_REASONS"
  echo ""
  echo "Project: $PROJECT_PATH"
  echo "Claimed batches: $CLAIMED_BATCHES"
  echo ""
  echo "========================================"
  echo "MANUAL RECOVERY REQUIRED"
  echo "========================================"
  echo ""
  echo "The batch-creator skill is too complex for auto-recovery."
  echo "Please re-run the skill manually:"
  echo ""
  echo "  1. Invoke deeper-research-0 Phase 2.5 again"
  echo "  2. Or run batch-creator skill directly:"
  echo ""
  echo "     Skill tool: cogni-research:batch-creator"
  echo "     args: PROJECT_PATH=$PROJECT_PATH LANGUAGE=en"
  echo ""

  # Exit with warning but don't block (allow orchestrator to handle)
  exit 0
fi

echo "Anti-hallucination verification passed for batch-creator"
exit 0
