#!/usr/bin/env bash
set -euo pipefail
# check-phase-state.sh
# Version: 1.0.0
# Purpose: Checks if a phase has already completed in a previous execution attempt
# Category: state-management
#
# Enables resume-from-checkpoint support for failed executions.
#
# Usage: check-phase-state.sh --phase <0|1|2|3|4> --project-path <path> --execution-id <id>
#
# Arguments:
#   --phase <0|1|2|3|4>      Phase number to check (required)
#   --project-path <path>    Path to project directory (required)
#   --execution-id <id>      Unique execution identifier (required)
#
# Output: JSON object with structure:
#   {
#     "completed": true|false,
#     "phase": <phase_number>,
#     "status": "<completed|failed|unknown>",
#     "timestamp": "<ISO8601>",
#     "state_file": "<path>"
#   }
#
# Exit Codes:
#   0 - Phase is completed
#   1 - Phase not completed or state file doesn't exist
#   2 - Invalid parameters


# ============================================================================
# PARAMETER PARSING
# ============================================================================

PHASE_NUM=""
PROJECT_PATH=""
EXECUTION_ID=""

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
    --execution-id)
      EXECUTION_ID="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown parameter: $1" >&2
      exit 2
      ;;
  esac
done

# Validate required parameters
if [[ -z "$PHASE_NUM" ]] || [[ -z "$PROJECT_PATH" ]] || [[ -z "$EXECUTION_ID" ]]; then
  echo "ERROR: Missing required parameters" >&2
  exit 2
fi

# Validate phase number
if [[ ! "$PHASE_NUM" =~ ^[0-4]$ ]]; then
  echo "ERROR: Invalid phase number: $PHASE_NUM" >&2
  exit 2
fi

# ============================================================================
# STATE CHECK
# ============================================================================

STATE_FILE="${PROJECT_PATH}/.metadata/state/execution-${EXECUTION_ID}.json"

# Check if state file exists
if [[ ! -f "$STATE_FILE" ]]; then
  cat <<EOF
{
  "completed": false,
  "phase": $PHASE_NUM,
  "reason": "State file does not exist",
  "state_file": "$STATE_FILE"
}
EOF
  exit 1
fi

# Check phase status using jq if available
if command -v jq &>/dev/null; then
  STATUS="$(jq -r ".phases[\"$PHASE_NUM\"].status // \"unknown\"" "$STATE_FILE")"
  TIMESTAMP="$(jq -r ".phases[\"$PHASE_NUM\"].timestamp // \"unknown\"" "$STATE_FILE")"

  if [[ "$STATUS" == "completed" ]]; then
    cat <<EOF
{
  "completed": true,
  "phase": $PHASE_NUM,
  "status": "$STATUS",
  "timestamp": "$TIMESTAMP",
  "state_file": "$STATE_FILE"
}
EOF
    exit 0
  else
    cat <<EOF
{
  "completed": false,
  "phase": $PHASE_NUM,
  "status": "$STATUS",
  "timestamp": "$TIMESTAMP",
  "state_file": "$STATE_FILE"
}
EOF
    exit 1
  fi
else
  # Fallback: grep-based check (less robust)
  if grep -q "\"$PHASE_NUM\":{\"status\":\"completed\"" "$STATE_FILE"; then
    cat <<EOF
{
  "completed": true,
  "phase": $PHASE_NUM,
  "status": "completed",
  "state_file": "$STATE_FILE",
  "note": "Fallback mode (jq not available)"
}
EOF
    exit 0
  else
    cat <<EOF
{
  "completed": false,
  "phase": $PHASE_NUM,
  "state_file": "$STATE_FILE",
  "note": "Fallback mode (jq not available)"
}
EOF
    exit 1
  fi
fi
