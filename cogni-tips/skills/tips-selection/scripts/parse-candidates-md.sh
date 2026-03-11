#!/usr/bin/env bash
set -euo pipefail
#
# parse-candidates-md.sh
# Version: 2.0.0
# Purpose: Parses trend-candidates.md and extracts all candidates to JSON
#
# Usage:
#   bash parse-candidates-md.sh --file <trend-candidates.md> [--json]
#
# Exit codes:
#   0 - Success
#   1 - Error


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

if [[ -z "$FILE_PATH" ]]; then
  echo '{"success": false, "error": "Missing required argument: --file"}' >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "{\"success\": false, \"error\": \"File not found: $FILE_PATH\"}" >&2
  exit 1
fi

# Initialize
CANDIDATES_JSON="[]"
CURRENT_DIM=""
CURRENT_HORIZON=""

# Read file and extract all candidate rows
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

  # Parse candidate rows (table rows starting with | followed by a number)
  if [[ -n "$CURRENT_DIM" && -n "$CURRENT_HORIZON" ]]; then
    if [[ "$line" =~ ^\|[[:space:]]*[0-9] ]]; then
      # Parse: | # | Trend Name | Keywords | Rationale | Source | Fresh |
      row="$(echo "$line" | sed 's/^|//' | sed 's/|$//')"

      sequence="$(echo "$row" | awk -F'|' '{print $1}' | xargs)"
      trend_name="$(echo "$row" | awk -F'|' '{print $2}' | xargs)"
      keywords="$(echo "$row" | awk -F'|' '{print $3}' | xargs)"
      rationale="$(echo "$row" | awk -F'|' '{print $4}' | xargs)"
      source_type="$(echo "$row" | awk -F'|' '{print $5}' | xargs)"

      candidate="{\"dimension\": \"$CURRENT_DIM\", \"horizon\": \"$CURRENT_HORIZON\", \"sequence\": $sequence, \"trend_name\": \"$trend_name\", \"keywords\": \"$keywords\", \"rationale\": \"$rationale\", \"source\": \"$source_type\"}"

      if [[ "$CANDIDATES_JSON" == "[]" ]]; then
        CANDIDATES_JSON="[$candidate]"
      else
        CANDIDATES_JSON="${CANDIDATES_JSON%]}, $candidate]"
      fi
    fi
  fi
done < "$FILE_PATH"

# Extract metadata from frontmatter
INDUSTRY_SECTOR="$(grep -E "^industry_sector:" "$FILE_PATH" | sed 's/industry_sector: *//' | tr -d '"' || echo "unknown")"

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
  TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "{\"success\": true, \"data\": {\"metadata\": {\"industry_sector\": \"$INDUSTRY_SECTOR\", \"parsed_at\": \"$TIMESTAMP\"}, \"candidates\": $CANDIDATES_JSON}}"
else
  echo "Parsed candidates:"
  echo "$CANDIDATES_JSON"
fi
