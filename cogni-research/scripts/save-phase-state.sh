#!/usr/bin/env bash
set -euo pipefail
# save-phase-state.sh
# Version: 1.0.0
# Purpose: Persists phase completion state to disk for resume-from-checkpoint support
# Category: state-management
#
# Allows research-executor to resume from last successful phase on failure retry.
#
# Usage: save-phase-state.sh --phase <0|1|2|3|4> --project-path <path> --execution-id <id> [--status <completed|failed>]
#
# Arguments:
#   --phase <0|1|2|3|4>      Phase number (required)
#   --project-path <path>    Path to project directory (required)
#   --execution-id <id>      Unique execution identifier (required)
#   --status <status>        Phase status: completed or failed (optional, default: completed)
#
# Output: JSON object with structure:
#   {
#     "success": true|false,
#     "phase": <phase_number>,
#     "status": "<completed|failed>",
#     "execution_id": "<id>",
#     "state_file": "<path>",
#     "timestamp": "<ISO8601>"
#   }
#
# Exit codes:
#   0 - State saved successfully
#   1 - Save failed
#   2 - Invalid parameters


# ============================================================================
# PARAMETER PARSING
# ============================================================================

PHASE_NUM=""
PROJECT_PATH=""
EXECUTION_ID=""
STATUS="completed"

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
    --status)
      STATUS="$2"
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
  echo "ERROR: Missing required parameters (--phase, --project-path, --execution-id)" >&2
  exit 2
fi

# Validate phase number
if [[ ! "$PHASE_NUM" =~ ^[0-4]$ ]]; then
  echo "ERROR: Invalid phase number: $PHASE_NUM (must be 0-4)" >&2
  exit 2
fi

# Validate status
if ! [[ "$STATUS" == "completed" ]] && ! [[ "$STATUS" == "failed" ]]; then
  echo "ERROR: Invalid status: $STATUS (must be 'completed' or 'failed')" >&2
  exit 2
fi

# ============================================================================
# STATE PERSISTENCE
# ============================================================================

STATE_DIR="${PROJECT_PATH}/.metadata/state"
STATE_FILE="${STATE_DIR}/execution-${EXECUTION_ID}.json"

# Create state directory if it doesn't exist
mkdir -p "$STATE_DIR"

# Generate timestamp
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Initialize state file if it doesn't exist
if [[ ! -f "$STATE_FILE" ]]; then
  cat > "$STATE_FILE" <<EOF
{
  "execution_id": "$EXECUTION_ID",
  "project_path": "$PROJECT_PATH",
  "created_at": "$TIMESTAMP",
  "phases": {}
}
EOF
fi

# Update phase status using jq
if command -v jq &>/dev/null; then
  # Use jq for robust JSON manipulation
  TEMP_FILE="${STATE_FILE}.tmp"
  jq --arg phase "$PHASE_NUM" \
     --arg status "$STATUS" \
     --arg timestamp "$TIMESTAMP" \
     '.phases[$phase] = {"status": $status, "timestamp": $timestamp, "updated_at": $timestamp}' \
     "$STATE_FILE" > "$TEMP_FILE"

  if [[ $? -eq 0 ]]; then
    mv "$TEMP_FILE" "$STATE_FILE"
    echo "Phase $PHASE_NUM state saved: $STATUS at $TIMESTAMP" >&2
  else
    echo "ERROR: Failed to update state file with jq" >&2
    rm -f "$TEMP_FILE"
    exit 1
  fi
else
  # Fallback: manual JSON construction (less robust)
  echo "WARN: jq not available, using fallback JSON construction" >&2

  # Read existing phases
  EXISTING_PHASES="$(grep -o '"phases":{[^}]*}' "$STATE_FILE" || echo '"phases":{}')"

  # Construct new phase entry
  NEW_PHASE_ENTRY="\"$PHASE_NUM\":{\"status\":\"$STATUS\",\"timestamp\":\"$TIMESTAMP\"}"

  # Simple replacement (fragile, prefer jq)
  sed -i '' "s|\"phases\":{.*}|\"phases\":{$NEW_PHASE_ENTRY}|" "$STATE_FILE"

  echo "Phase $PHASE_NUM state saved: $STATUS at $TIMESTAMP (fallback mode)" >&2
fi

# Output JSON result
cat <<EOF
{
  "success": true,
  "phase": $PHASE_NUM,
  "status": "$STATUS",
  "execution_id": "$EXECUTION_ID",
  "state_file": "$STATE_FILE",
  "timestamp": "$TIMESTAMP"
}
EOF

exit 0
