#!/usr/bin/env bash
set -euo pipefail
# validate-selection.sh
# Version: 1.0.0
# Purpose: Validate TIPS candidate selection counts from trend-candidates.md (5 per cell, 60 total)
# Category: utilities
#
# Usage: validate-selection.sh --input <trend-candidates.md> [--json]
#
# Arguments:
#   --input <string>  Path to trend-candidates.md file (required)
#   --file <string>   Alias for --input (required)
#   --json            Output JSON format (optional flag)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "total_selected": number,
#       "valid": boolean,
#       "invalid_cells": [...]
#     },
#     "error": "error message" (if success=false)
#   }
#
# Output (Standard mode):
#   Validation result summary to stdout
#
# Exit codes:
#   0 - Valid selection (60 candidates, 5 per cell)
#   1 - Invalid selection or error
#
# Example:
#   validate-selection.sh --input "/path/to/trend-candidates.md" --json


# Defaults
FILE_PATH=""
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input|--file)
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
  echo '{"success": false, "error": "Missing required argument: --input"}' >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "{\"success\": false, \"error\": \"File not found: $FILE_PATH\"}" >&2
  exit 1
fi

# Current parsing context
CURRENT_DIM=""
CURRENT_HORIZON=""
IN_USER_PROPOSED=false

# Count selections (POSIX-compatible using temp file instead of associative arrays)
TOTAL_SELECTED=0
CELL_COUNTS_FILE="$(mktemp)"
trap 'rm -f "$CELL_COUNTS_FILE"' EXIT

# Helper functions for POSIX-compatible key-value storage
get_cell_count() {
  local key="$1"
  local val
  val=$(grep "^${key}=" "$CELL_COUNTS_FILE" 2>/dev/null | tail -1 | cut -d= -f2)
  echo "${val:-0}"
}

set_cell_count() {
  local key="$1"
  local val="$2"
  # Remove old entry and add new one
  grep -v "^${key}=" "$CELL_COUNTS_FILE" > "${CELL_COUNTS_FILE}.tmp" 2>/dev/null || true
  mv "${CELL_COUNTS_FILE}.tmp" "$CELL_COUNTS_FILE"
  echo "${key}=${val}" >> "$CELL_COUNTS_FILE"
}

while IFS= read -r line; do
  # Detect sections
  if [[ "$line" =~ "## User Proposed" ]] || [[ "$line" =~ "## Eigene Vorschläge" ]]; then
    IN_USER_PROPOSED=true
    continue
  fi

  if [[ "$line" =~ "## Dimension: Externe Effekte" ]] || [[ "$line" =~ "## Dimension: External Effects" ]]; then
    CURRENT_DIM="externe-effekte"; IN_USER_PROPOSED=false
  elif [[ "$line" =~ "## Dimension: Neue Horizonte" ]] || [[ "$line" =~ "## Dimension: New Horizons" ]]; then
    CURRENT_DIM="neue-horizonte"; IN_USER_PROPOSED=false
  elif [[ "$line" =~ "## Dimension: Digitale Wertetreiber" ]] || [[ "$line" =~ "## Dimension: Digital Value Drivers" ]]; then
    CURRENT_DIM="digitale-wertetreiber"; IN_USER_PROPOSED=false
  elif [[ "$line" =~ "## Dimension: Digitales Fundament" ]] || [[ "$line" =~ "## Dimension: Digital Foundation" ]]; then
    CURRENT_DIM="digitales-fundament"; IN_USER_PROPOSED=false
  fi

  if [[ "$line" =~ "### Horizon: Act" ]] || [[ "$line" =~ "### Horizont: Handeln" ]]; then
    CURRENT_HORIZON="act"
  elif [[ "$line" =~ "### Horizon: Plan" ]] || [[ "$line" =~ "### Horizont: Planen" ]]; then
    CURRENT_HORIZON="plan"
  elif [[ "$line" =~ "### Horizon: Observe" ]] || [[ "$line" =~ "### Horizont: Beobachten" ]]; then
    CURRENT_HORIZON="observe"
  fi

  # Count [x] selections
  if [[ "$line" =~ ^\|[[:space:]]*\[x\] ]] || [[ "$line" =~ ^\|[[:space:]]*\[X\] ]]; then
    if [[ "$IN_USER_PROPOSED" == false && -n "$CURRENT_DIM" && -n "$CURRENT_HORIZON" ]]; then
      cell_key="${CURRENT_DIM}:${CURRENT_HORIZON}"
      current_count=$(get_cell_count "$cell_key")
      set_cell_count "$cell_key" $((current_count + 1))
      TOTAL_SELECTED=$((TOTAL_SELECTED + 1))
    elif [[ "$IN_USER_PROPOSED" == true ]]; then
      # Parse cell from user proposed row
      row="$(echo "$line" | sed 's/^|//' | sed 's/|$//')"
      dim="$(echo "$row" | awk -F'|' '{print $2}' | xargs)"
      hor="$(echo "$row" | awk -F'|' '{print $3}' | xargs)"
      if [[ -n "$dim" && -n "$hor" ]]; then
        cell_key="${dim}:${hor}"
        current_count=$(get_cell_count "$cell_key")
        set_cell_count "$cell_key" $((current_count + 1))
        TOTAL_SELECTED=$((TOTAL_SELECTED + 1))
      fi
    fi
  fi
done < "$FILE_PATH"

# Validate counts (POSIX-compatible using temp file for invalid cells)
INVALID_CELLS_FILE="$(mktemp)"
VALID=true

for dim in externe-effekte neue-horizonte digitale-wertetreiber digitales-fundament; do
  for horizon in act plan observe; do
    cell_key="${dim}:${horizon}"
    count=$(get_cell_count "$cell_key")
    if [[ "$count" -ne 5 ]]; then
      echo "{\"dimension\": \"$dim\", \"horizon\": \"$horizon\", \"selected\": $count, \"required\": 5}" >> "$INVALID_CELLS_FILE"
      VALID=false
    fi
  done
done

# Build JSON output
if [[ "$JSON_OUTPUT" == true ]]; then
  if [[ "$VALID" == true ]]; then
    echo "{\"success\": true, \"data\": {\"total_selected\": $TOTAL_SELECTED, \"valid\": true, \"invalid_cells\": []}}"
    rm -f "$INVALID_CELLS_FILE"
    exit 0
  else
    # Build JSON array from file (POSIX-compatible)
    invalid_json=$(paste -sd ',' "$INVALID_CELLS_FILE" 2>/dev/null || cat "$INVALID_CELLS_FILE" | tr '\n' ',' | sed 's/,$//')
    echo "{\"success\": true, \"data\": {\"total_selected\": $TOTAL_SELECTED, \"valid\": false, \"invalid_cells\": [$invalid_json]}}"
    rm -f "$INVALID_CELLS_FILE"
    exit 1
  fi
else
  if [[ "$VALID" == true ]]; then
    echo "Selection valid: $TOTAL_SELECTED candidates (5 per cell)"
    rm -f "$INVALID_CELLS_FILE"
    exit 0
  else
    echo "Selection invalid: $TOTAL_SELECTED candidates selected"
    echo "Invalid cells:"
    while IFS= read -r cell_info; do
      echo "  $cell_info"
    done < "$INVALID_CELLS_FILE"
    rm -f "$INVALID_CELLS_FILE"
    exit 1
  fi
fi
