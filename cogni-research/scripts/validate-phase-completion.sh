#!/usr/bin/env bash
set -euo pipefail
# validate-phase-completion.sh
# Version: 1.0.0
# Purpose: Validates that a research-executor phase completed successfully before proceeding
# Category: validation
#
# Enforces phase completion criteria and prevents progression with incomplete phases.
#
# Usage: validate-phase-completion.sh --phase <0|1|2|3|4> --project-path <path> [--batch-id <id>]
#
# Arguments:
#   --phase <0|1|2|3|4>      Phase number to validate (required)
#   --project-path <path>    Path to project directory (required)
#   --batch-id <id>          Batch identifier (optional)
#
# Output: JSON object with structure:
#   {
#     "success": true|false,
#     "phase": <phase_number>,
#     "project_path": "<path>",
#     "message": "<validation result>"
#   }
#
# Exit codes:
#   0 - Phase validation passed
#   1 - Phase validation failed (incomplete)
#   2 - Invalid parameters


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"

# ============================================================================
# PARAMETER PARSING
# ============================================================================

PHASE_NUM=""
PROJECT_PATH=""
BATCH_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      PHASE_NUM="$2"
      shift 2
      ;;
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --batch-id)
      BATCH_ID="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown parameter: $1" >&2
      exit 2
      ;;
  esac
done

# Validate required parameters
if [[ -z "$PHASE_NUM" ]]; then
  echo "ERROR: Missing required parameter: --phase" >&2
  exit 2
fi

if [[ -z "$PROJECT_PATH" ]]; then
  echo "ERROR: Missing required parameter: --project-path" >&2
  exit 2
fi

# Validate phase number
if [[ ! "$PHASE_NUM" =~ ^[0-4]$ ]]; then
  echo "ERROR: Invalid phase number: $PHASE_NUM (must be 0-4)" >&2
  exit 2
fi

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_phase_0() {
  local failures=()

  # Verify PROJECT_PATH is valid directory
  if [[ ! -d "$PROJECT_PATH" ]]; then
    failures+=("PROJECT_PATH is not a valid directory: $PROJECT_PATH")
  fi

  # Verify WORKSPACE_ROOT environment variable set
  if [[ -z "${WORKSPACE_ROOT:-}" ]]; then
    failures+=("WORKSPACE_ROOT environment variable not set")
  fi

  # Verify LOG_FILE environment variable set
  if [[ -z "${LOG_FILE:-}" ]]; then
    failures+=("LOG_FILE environment variable not set")
  fi

  # Verify logging directory exists
  if [[ ! -d "${PROJECT_PATH}/.metadata/logs" ]]; then
    failures+=("Logging directory not created: ${PROJECT_PATH}/.metadata/logs")
  fi

  # Verify CLAUDE_PLUGIN_ROOT set
  if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    failures+=("CLAUDE_PLUGIN_ROOT environment variable not set")
  fi

  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "ERROR: Phase 0 validation failed:" >&2
    for failure in "${failures[@]}"; do
      echo "  - $failure" >&2
    done
    return 1
  fi

  echo "Phase 0 validation passed: Environment & Validation complete" >&2
  return 0
}

validate_phase_1() {
  local failures=()

  # Verify BATCH_ID exported
  if [[ -z "${BATCH_ID:-}" ]]; then
    failures+=("BATCH_ID environment variable not exported")
  fi

  # Verify QUERY_IDS exported
  if [[ -z "${QUERY_IDS:-}" ]]; then
    failures+=("QUERY_IDS environment variable not exported")
  fi

  # Verify QUERY_COUNT exported and > 0
  if [[ -z "${QUERY_COUNT:-}" ]]; then
    failures+=("QUERY_COUNT environment variable not exported")
  elif [[ "$QUERY_COUNT" -le 0 ]]; then
    failures+=("QUERY_COUNT must be > 0, got: $QUERY_COUNT")
  fi

  # Verify BATCH_FILENAME exported
  if [[ -z "${BATCH_FILENAME:-}" ]]; then
    failures+=("BATCH_FILENAME environment variable not exported")
  fi

  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "ERROR: Phase 1 validation failed:" >&2
    for failure in "${failures[@]}"; do
      echo "  - $failure" >&2
    done
    return 1
  fi

  echo "Phase 1 validation passed: Batch Validation complete (BATCH_ID=$BATCH_ID, QUERY_COUNT=$QUERY_COUNT)" >&2
  return 0
}

validate_phase_2() {
  local failures=()

  # Verify QUERIES_PROCESSED set and matches QUERY_COUNT
  if [[ -z "${QUERIES_PROCESSED:-}" ]]; then
    failures+=("QUERIES_PROCESSED environment variable not set")
  elif [[ -n "${QUERY_COUNT:-}" ]] && [[ "$QUERIES_PROCESSED" -ne "$QUERY_COUNT" ]]; then
    failures+=("QUERIES_PROCESSED ($QUERIES_PROCESSED) does not match QUERY_COUNT ($QUERY_COUNT)")
  fi

  # Verify search results metadata exists
  if [[ -z "${SEARCH_RESULTS_JSON:-}" ]] && [[ ! -f "${PROJECT_PATH}/.metadata/search-results-${BATCH_ID}.json" ]]; then
    failures+=("Search results not persisted (missing JSON file or SEARCH_RESULTS_JSON variable)")
  fi

  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "ERROR: Phase 2 validation failed:" >&2
    for failure in "${failures[@]}"; do
      echo "  - $failure" >&2
    done
    return 1
  fi

  echo "Phase 2 validation passed: Search Execution complete (QUERIES_PROCESSED=$QUERIES_PROCESSED)" >&2
  return 0
}

validate_phase_3() {
  local failures=()

  # Verify findings directory exists
  if [[ ! -d "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" ]]; then
    failures+=("Findings directory does not exist: ${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}")

    # Early return if directory doesn't exist
    echo "ERROR: Phase 3 validation failed:" >&2
    for failure in "${failures[@]}"; do
      echo "  - $failure" >&2
    done
    return 1
  fi

  # Count findings in filesystem
  local findings_count
  findings_count="$(find "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" -maxdepth 1 -name "finding-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

  # Verify at least 1 finding created
  if [[ "$findings_count" -eq 0 ]]; then
    failures+=("No findings created (FINDINGS_CREATED = 0)")
    failures+=("This indicates Phase 3 was not executed or failed to extract findings")
  fi

  # Verify FINDINGS_CREATED variable matches filesystem count
  if [[ -n "${FINDINGS_CREATED:-}" ]]; then
    if [[ "$FINDINGS_CREATED" -ne "$findings_count" ]]; then
      failures+=("Metric mismatch: FINDINGS_CREATED=$FINDINGS_CREATED but filesystem shows $findings_count findings")
    fi
  else
    failures+=("FINDINGS_CREATED environment variable not set")
  fi

  # Verify batch entity updated with finding_ids backlinks
  if [[ -n "$BATCH_ID" ]]; then
    local batch_path="${PROJECT_PATH}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/query-batch-${BATCH_ID}.md"
    if [[ -f "$batch_path" ]]; then
      if ! grep -q "^finding_ids:" "$batch_path"; then
        failures+=("Batch entity missing finding_ids backlinks: $batch_path")
      else
        # Verify backlink count matches findings count
        local backlink_count
        backlink_count="$(grep -A 999 "^finding_ids:" "$batch_path" | grep -c "^\s*-\s*\[\[" || true)"
        if [[ "$backlink_count" -ne "$findings_count" ]]; then
          failures+=("Backlink count mismatch: $backlink_count backlinks vs $findings_count findings")
        fi
      fi
    else
      failures+=("Batch entity file not found: $batch_path")
    fi
  fi

  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "ERROR: Phase 3 validation failed:" >&2
    for failure in "${failures[@]}"; do
      echo "  - $failure" >&2
    done
    return 1
  fi

  echo "Phase 3 validation passed: Finding Extraction complete (FINDINGS_CREATED=$findings_count)" >&2
  return 0
}

validate_phase_4() {
  local failures=()

  # Verify JSON_SUMMARY variable set
  if [[ -z "${JSON_SUMMARY:-}" ]]; then
    failures+=("JSON_SUMMARY environment variable not set")
  else
    # Verify JSON is valid (can be parsed by jq)
    if ! echo "$JSON_SUMMARY" | jq empty 2>/dev/null; then
      failures+=("JSON_SUMMARY is not valid JSON")
    else
      # Verify required JSON fields exist
      local required_fields=("success" "batch_id" "queries_processed" "findings_created" "search_success_rate" "execution_time_seconds")
      for field in "${required_fields[@]}"; do
        if ! echo "$JSON_SUMMARY" | jq -e ".$field" >/dev/null 2>&1; then
          failures+=("JSON_SUMMARY missing required field: $field")
        fi
      done
    fi
  fi

  # Verify execution time calculated
  if [[ -z "${EXECUTION_TIME:-}" ]]; then
    failures+=("EXECUTION_TIME environment variable not set")
  fi

  # Verify log file exists
  if [[ -n "${LOG_FILE:-}" ]]; then
    if [[ ! -f "$LOG_FILE" ]]; then
      failures+=("Log file does not exist: $LOG_FILE")
    fi
  else
    failures+=("LOG_FILE environment variable not set")
  fi

  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "ERROR: Phase 4 validation failed:" >&2
    for failure in "${failures[@]}"; do
      echo "  - $failure" >&2
    done
    return 1
  fi

  echo "Phase 4 validation passed: Metadata Return complete" >&2
  return 0
}

# ============================================================================
# MAIN VALIDATION DISPATCH
# ============================================================================

case "$PHASE_NUM" in
  0)
    validate_phase_0
    ;;
  1)
    validate_phase_1
    ;;
  2)
    validate_phase_2
    ;;
  3)
    validate_phase_3
    ;;
  4)
    validate_phase_4
    ;;
  *)
    echo "ERROR: Invalid phase number: $PHASE_NUM" >&2
    exit 2
    ;;
esac

exit_code=$?

# Output JSON result for programmatic consumption
if [[ $exit_code -eq 0 ]]; then
  cat <<EOF
{
  "success": true,
  "phase": $PHASE_NUM,
  "project_path": "$PROJECT_PATH",
  "message": "Phase $PHASE_NUM validation passed"
}
EOF
else
  cat <<EOF
{
  "success": false,
  "phase": $PHASE_NUM,
  "project_path": "$PROJECT_PATH",
  "message": "Phase $PHASE_NUM validation failed - see stderr for details"
}
EOF
fi

exit $exit_code
