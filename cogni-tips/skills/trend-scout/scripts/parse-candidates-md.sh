#!/usr/bin/env bash
set -euo pipefail
# parse-candidates-md.sh
# Version: 1.0.0
# Purpose: Parse trend-candidates.md and extract selected candidates, user proposals, and regeneration requests
# Category: utilities
#
# Usage: parse-candidates-md.sh --input <trend-candidates.md> [--json]
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
#       "frontmatter": {...},
#       "selections": [...],
#       "user_proposed": [...],
#       "regeneration_requests": [...],
#       "counts": {...},
#       "parsed_at": "ISO timestamp"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Output (Standard mode):
#   Summary of parsed candidates to stdout
#
# Exit codes:
#   0 - Success
#   1 - Error (file not found, parse failure)
#
# Example:
#   parse-candidates-md.sh --input "/path/to/trend-candidates.md" --json


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

# Initialize
CURRENT_DIM=""
CURRENT_HORIZON=""
SEQUENCE=0
IN_USER_PROPOSED=false

# Arrays to store results (using temp files for portability)
SELECTED_FILE="$(mktemp)"
USER_PROPOSED_FILE="$(mktemp)"
REGEN_FILE="$(mktemp)"
trap "rm -f $SELECTED_FILE $USER_PROPOSED_FILE $REGEN_FILE" EXIT

# Read file and extract data
while IFS= read -r line; do
  # Detect user proposed section
  if [[ "$line" =~ "## User Proposed" ]] || [[ "$line" =~ "## Eigene Vorschläge" ]]; then
    IN_USER_PROPOSED=true
    CURRENT_DIM=""
    CURRENT_HORIZON=""
    continue
  fi

  # Detect dimension headers (bilingual)
  if [[ "$line" =~ "## Dimension: Externe Effekte" ]] || [[ "$line" =~ "## Dimension: External Effects" ]]; then
    CURRENT_DIM="externe-effekte"
    IN_USER_PROPOSED=false
  elif [[ "$line" =~ "## Dimension: Neue Horizonte" ]] || [[ "$line" =~ "## Dimension: New Horizons" ]]; then
    CURRENT_DIM="neue-horizonte"
    IN_USER_PROPOSED=false
  elif [[ "$line" =~ "## Dimension: Digitale Wertetreiber" ]] || [[ "$line" =~ "## Dimension: Digital Value Drivers" ]]; then
    CURRENT_DIM="digitale-wertetreiber"
    IN_USER_PROPOSED=false
  elif [[ "$line" =~ "## Dimension: Digitales Fundament" ]] || [[ "$line" =~ "## Dimension: Digital Foundation" ]]; then
    CURRENT_DIM="digitales-fundament"
    IN_USER_PROPOSED=false
  fi

  # Detect horizon headers (bilingual)
  if [[ "$line" =~ "### Horizon: Act" ]] || [[ "$line" =~ "### Horizont: Handeln" ]]; then
    CURRENT_HORIZON="act"
    SEQUENCE=0
  elif [[ "$line" =~ "### Horizon: Plan" ]] || [[ "$line" =~ "### Horizont: Planen" ]]; then
    CURRENT_HORIZON="plan"
    SEQUENCE=0
  elif [[ "$line" =~ "### Horizon: Observe" ]] || [[ "$line" =~ "### Horizont: Beobachten" ]]; then
    CURRENT_HORIZON="observe"
    SEQUENCE=0
  fi

  # Parse table rows
  if [[ "$line" =~ ^\| ]]; then
    # Skip header rows
    if [[ "$line" =~ "Select" ]] || [[ "$line" =~ "Auswahl" ]] || [[ "$line" =~ "----" ]]; then
      continue
    fi

    # Check for selection marker [x] or [X]
    if [[ "$line" =~ \[x\] ]] || [[ "$line" =~ \[X\] ]]; then
      # Remove leading/trailing pipes and split
      row="$(echo "$line" | sed 's/^|//' | sed 's/|$//')"

      if [[ "$IN_USER_PROPOSED" == true ]]; then
        # Parse user proposed: | [x] | dimension | horizon | name | description | keywords | rationale |
        dim="$(echo "$row" | awk -F'|' '{print $2}' | xargs)"
        hor="$(echo "$row" | awk -F'|' '{print $3}' | xargs)"
        name="$(echo "$row" | awk -F'|' '{print $4}' | xargs)"
        description="$(echo "$row" | awk -F'|' '{print $5}' | xargs)"
        keywords="$(echo "$row" | awk -F'|' '{print $6}' | xargs)"
        rationale="$(echo "$row" | awk -F'|' '{print $7}' | xargs)"

        if [[ -n "$dim" && -n "$hor" && -n "$name" ]]; then
          echo "{\"dimension\": \"$dim\", \"horizon\": \"$hor\", \"name\": \"$name\", \"description\": \"$description\", \"keywords\": \"$keywords\", \"rationale\": \"$rationale\", \"source\": \"user_proposed\"}" >> "$USER_PROPOSED_FILE"
        fi
      elif [[ -n "$CURRENT_DIM" && -n "$CURRENT_HORIZON" ]]; then
        # Parse generated candidate: | [x] | # | name | description | keywords | score | conf | int | source | more? |
        SEQUENCE=$((SEQUENCE + 1))
        seq_num="$(echo "$row" | awk -F'|' '{print $2}' | xargs)"
        name="$(echo "$row" | awk -F'|' '{print $3}' | xargs)"
        description="$(echo "$row" | awk -F'|' '{print $4}' | xargs)"
        keywords="$(echo "$row" | awk -F'|' '{print $5}' | xargs)"

        echo "{\"dimension\": \"$CURRENT_DIM\", \"horizon\": \"$CURRENT_HORIZON\", \"sequence\": $seq_num, \"name\": \"$name\", \"description\": \"$description\", \"keywords\": \"$keywords\", \"source\": \"generated\"}" >> "$SELECTED_FILE"
      fi
    fi

    # Check for regeneration request [+N] (POSIX-compatible, no BASH_REMATCH)
    if [[ -n "$CURRENT_DIM" && -n "$CURRENT_HORIZON" && ! "$IN_USER_PROPOSED" == true ]]; then
      regen_count=$(echo "$line" | sed -n 's/.*\[\+\([0-9][0-9]*\)\].*/\1/p')
      if [[ -n "$regen_count" ]]; then
        echo "{\"dimension\": \"$CURRENT_DIM\", \"horizon\": \"$CURRENT_HORIZON\", \"count\": $regen_count}" >> "$REGEN_FILE"
      fi
    fi
  fi
done < "$FILE_PATH"

# Extract metadata from frontmatter
INDUSTRY="$(grep -E "^industry:" "$FILE_PATH" 2>/dev/null | head -1 | sed 's/industry: *//' | tr -d '"' || echo "")"
SUBSECTOR="$(grep -E "^subsector:" "$FILE_PATH" 2>/dev/null | head -1 | sed 's/subsector: *//' | tr -d '"' || echo "")"
PROJECT_LANG="$(grep -E "^project_language:" "$FILE_PATH" 2>/dev/null | head -1 | sed 's/project_language: *//' | tr -d '"' || echo "en")"
STATUS="$(grep -E "^status:" "$FILE_PATH" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '"' || echo "draft")"

# Build JSON arrays from temp files
SELECTED_JSON="[]"
if [[ -s "$SELECTED_FILE" ]]; then
  SELECTED_JSON="$(cat "$SELECTED_FILE" | jq -s '.' 2>/dev/null || echo "[]")"
fi

USER_PROPOSED_JSON="[]"
if [[ -s "$USER_PROPOSED_FILE" ]]; then
  USER_PROPOSED_JSON="$(cat "$USER_PROPOSED_FILE" | jq -s '.' 2>/dev/null || echo "[]")"
fi

REGEN_JSON="[]"
if [[ -s "$REGEN_FILE" ]]; then
  REGEN_JSON="$(cat "$REGEN_FILE" | jq -s '.' 2>/dev/null || echo "[]")"
fi

# Count selections
TOTAL_SELECTED="$(echo "$SELECTED_JSON" | jq 'length' 2>/dev/null || echo "0")"
USER_PROPOSED_COUNT="$(echo "$USER_PROPOSED_JSON" | jq 'length' 2>/dev/null || echo "0")"

# Build final output
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ "$JSON_OUTPUT" == true ]]; then
  cat << EOF
{
  "success": true,
  "data": {
    "frontmatter": {
      "status": "$STATUS",
      "industry": "$INDUSTRY",
      "subsector": "$SUBSECTOR",
      "project_language": "$PROJECT_LANG"
    },
    "selections": $SELECTED_JSON,
    "user_proposed": $USER_PROPOSED_JSON,
    "regeneration_requests": $REGEN_JSON,
    "counts": {
      "selected": $TOTAL_SELECTED,
      "user_proposed": $USER_PROPOSED_COUNT
    },
    "parsed_at": "$TIMESTAMP"
  }
}
EOF
else
  echo "Parsed $TOTAL_SELECTED selected candidates, $USER_PROPOSED_COUNT user proposed"
fi
