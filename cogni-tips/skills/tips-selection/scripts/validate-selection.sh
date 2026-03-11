#!/usr/bin/env bash
set -euo pipefail
#
# validate-selection.sh
# Version: 2.0.0
# Purpose: Validates TIPS candidate counts from trend-candidates.md
#
# Usage:
#   bash validate-selection.sh --file <trend-candidates.md> [--json]
#
# Validates that the file contains exactly 60 candidates:
#   5 per cell (4 dimensions x 3 horizons)
#
# Exit codes:
#   0 - Valid (60 candidates, 5 per cell)
#   1 - Invalid or error


# Defaults
FILE_PATH=""
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE_PATH="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$FILE_PATH" ]]; then
  echo '{"success": false, "error": "Missing required argument: --file"}' >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "{\"success\": false, \"error\": \"File not found: $FILE_PATH\"}" >&2
  exit 1
fi

# Initialize counters (Bash 3.2 compatible - indexed arrays)
CELL_KEYS=()
CELL_VALUES=()

get_cell_count() {
  local key="$1"
  local i=0
  for k in "${CELL_KEYS[@]}"; do
    if [[ "$k" == "$key" ]]; then
      echo "${CELL_VALUES[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  echo "0"
}

increment_cell_count() {
  local key="$1"
  local i=0
  for k in "${CELL_KEYS[@]}"; do
    if [[ "$k" == "$key" ]]; then
      CELL_VALUES[$i]=$((CELL_VALUES[$i] + 1))
      return
    fi
    i=$((i + 1))
  done
  CELL_KEYS+=("$key")
  CELL_VALUES+=("1")
}

TOTAL_COUNT=0
DIMENSIONS=("externe-effekte" "neue-horizonte" "digitale-wertetreiber" "digitales-fundament")
HORIZONS=("act" "plan" "observe")

CURRENT_DIM=""
CURRENT_HORIZON=""

# Count candidate rows per cell
while IFS= read -r line; do
  # Detect dimension headers
  if [[ "$line" =~ "## Dimension: Externe Effekte" ]]; then
    CURRENT_DIM="externe-effekte"
  elif [[ "$line" =~ "## Dimension: Neue Horizonte" ]]; then
    CURRENT_DIM="neue-horizonte"
  elif [[ "$line" =~ "## Dimension: Digitale Wertetreiber" ]]; then
    CURRENT_DIM="digitale-wertetreiber"
  elif [[ "$line" =~ "## Dimension: Digitales Fundament" ]]; then
    CURRENT_DIM="digitales-fundament"
  fi

  # Detect horizon headers
  if [[ "$line" =~ "### Horizon: Act" ]]; then
    CURRENT_HORIZON="act"
  elif [[ "$line" =~ "### Horizon: Plan" ]]; then
    CURRENT_HORIZON="plan"
  elif [[ "$line" =~ "### Horizon: Observe" ]]; then
    CURRENT_HORIZON="observe"
  fi

  # Count candidate rows (table rows starting with | followed by a number)
  if [[ -n "$CURRENT_DIM" && -n "$CURRENT_HORIZON" ]]; then
    if [[ "$line" =~ ^\|[[:space:]]*[0-9] ]]; then
      cell_key="${CURRENT_DIM}:${CURRENT_HORIZON}"
      increment_cell_count "$cell_key"
      TOTAL_COUNT=$((TOTAL_COUNT + 1))
    fi
  fi
done < "$FILE_PATH"

# Validate: 5 candidates per cell, 60 total
INVALID_CELLS=()
VALID=true
EXPECTED_PER_CELL=5

for dim in "${DIMENSIONS[@]}"; do
  for horizon in "${HORIZONS[@]}"; do
    cell_key="${dim}:${horizon}"
    count=$(get_cell_count "$cell_key")
    if [[ "$count" -ne "$EXPECTED_PER_CELL" ]]; then
      INVALID_CELLS+=("{\"dimension\": \"$dim\", \"horizon\": \"$horizon\", \"found\": $count, \"expected\": $EXPECTED_PER_CELL}")
      VALID=false
    fi
  done
done

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
  if [[ "$VALID" == true ]]; then
    echo "{\"success\": true, \"data\": {\"total_candidates\": $TOTAL_COUNT, \"valid\": true, \"invalid_cells\": []}}"
    exit 0
  else
    invalid_json="$(printf '%s,' "${INVALID_CELLS[@]}" | sed 's/,$//')"
    echo "{\"success\": true, \"data\": {\"total_candidates\": $TOTAL_COUNT, \"valid\": false, \"invalid_cells\": [$invalid_json]}}"
    exit 1
  fi
else
  if [[ "$VALID" == true ]]; then
    echo "Valid: $TOTAL_COUNT candidates (5 per cell x 12 cells)"
    exit 0
  else
    echo "Invalid: $TOTAL_COUNT candidates found (expected 60)"
    echo "Cells with wrong counts:"
    for cell_info in "${INVALID_CELLS[@]}"; do
      echo "  $cell_info"
    done
    exit 1
  fi
fi
