#!/usr/bin/env bash
set -euo pipefail
# finalize-candidates.sh
# Version: 1.0.0
# Purpose: Finalize trend-scout-output.json with agreed candidates, scoring metadata, and execution state
# Category: utilities
#
# Usage: finalize-candidates.sh --project-path <path> --candidates-file <path> \
#        --web-count <N> --training-count <N> --user-count <N> \
#        --search-timestamp <ISO8601> --web-status <status> [--json]
#
# Arguments:
#   --project-path <path>          Absolute path to project directory (required)
#   --candidates-file <path>       Path to JSON file with agreed candidates array (required)
#   --web-count <number>           Count of web-sourced candidates (required)
#   --training-count <number>      Count of training-sourced candidates (required)
#   --user-count <number>          Count of user-proposed candidates (required)
#   --search-timestamp <string>    ISO 8601 timestamp of web search (required)
#   --web-status <string>          Web research status: success|partial|failed|disabled (required)
#   --json                         Output JSON format (optional flag)
#
# Input:
#   The --candidates-file must point to a JSON file containing an array of candidate objects.
#   Each candidate should have: score, confidence_tier, signal_intensity fields.
#
# Output (JSON mode):
#   {"success": true, "data": {"output_file": "...", "total_candidates": N, "avg_score": N, "workflow_state": "agreed"}}
#
# Exit codes:
#   0 - Success
#   1 - Validation error or missing arguments
#   2 - File not found
#   3 - jq error
#
# Example:
#   finalize-candidates.sh --project-path "/path/to/project" \
#     --candidates-file "/path/to/agreed-candidates.json" \
#     --web-count 18 --training-count 32 --user-count 2 \
#     --search-timestamp "2025-12-16T10:25:00Z" --web-status "success" --json


# Defaults
PROJECT_PATH=""
CANDIDATES_FILE=""
WEB_COUNT=""
TRAINING_COUNT=""
USER_COUNT=""
SEARCH_TIMESTAMP=""
WEB_STATUS=""
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --candidates-file)
      CANDIDATES_FILE="$2"
      shift 2
      ;;
    --web-count)
      WEB_COUNT="$2"
      shift 2
      ;;
    --training-count)
      TRAINING_COUNT="$2"
      shift 2
      ;;
    --user-count)
      USER_COUNT="$2"
      shift 2
      ;;
    --search-timestamp)
      SEARCH_TIMESTAMP="$2"
      shift 2
      ;;
    --web-status)
      WEB_STATUS="$2"
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
MISSING=()
[[ -z "$PROJECT_PATH" ]] && MISSING+=("--project-path")
[[ -z "$CANDIDATES_FILE" ]] && MISSING+=("--candidates-file")
[[ -z "$WEB_COUNT" ]] && MISSING+=("--web-count")
[[ -z "$TRAINING_COUNT" ]] && MISSING+=("--training-count")
[[ -z "$USER_COUNT" ]] && MISSING+=("--user-count")
[[ -z "$SEARCH_TIMESTAMP" ]] && MISSING+=("--search-timestamp")
[[ -z "$WEB_STATUS" ]] && MISSING+=("--web-status")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{\"success\": false, \"error\": \"Missing required arguments: ${MISSING[*]}\"}"
  else
    echo "Error: Missing required arguments: ${MISSING[*]}" >&2
  fi
  exit 1
fi

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{\"success\": false, \"error\": \"Project directory not found: $PROJECT_PATH\"}"
  else
    echo "Error: Project directory not found: $PROJECT_PATH" >&2
  fi
  exit 2
fi

# Validate output file exists
OUTPUT_FILE="${PROJECT_PATH}/.metadata/trend-scout-output.json"
if [[ ! -f "$OUTPUT_FILE" ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{\"success\": false, \"error\": \"Output file not found: $OUTPUT_FILE\"}"
  else
    echo "Error: Output file not found: $OUTPUT_FILE" >&2
  fi
  exit 2
fi

# Validate candidates file
if [[ ! -f "$CANDIDATES_FILE" ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{\"success\": false, \"error\": \"Candidates file not found: $CANDIDATES_FILE\"}"
  else
    echo "Error: Candidates file not found: $CANDIDATES_FILE" >&2
  fi
  exit 2
fi

# Validate jq available
if ! command -v jq &>/dev/null; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo '{"success": false, "error": "jq is required but not installed"}'
  else
    echo "Error: jq is required but not installed" >&2
  fi
  exit 3
fi

# Validate web-status value
case "$WEB_STATUS" in
  success|partial|failed|disabled) ;;
  *)
    if [[ "$JSON_OUTPUT" == true ]]; then
      echo "{\"success\": false, \"error\": \"Invalid --web-status: $WEB_STATUS (expected: success|partial|failed|disabled)\"}"
    else
      echo "Error: Invalid --web-status: $WEB_STATUS" >&2
    fi
    exit 1
    ;;
esac

# Read candidates JSON
CANDIDATES_JSON="$(cat "$CANDIDATES_FILE")"

# Calculate all scoring metadata in a single jq pass
SCORING_META=$(echo "$CANDIDATES_JSON" | jq '{
  avg_score: ([.[].score // 0.5] | if length > 0 then add / length else 0 end),
  high: [.[] | select(.confidence_tier == "high")] | length,
  medium: [.[] | select(.confidence_tier == "medium")] | length,
  low: [.[] | select(.confidence_tier == "low")] | length,
  uncertain: [.[] | select(.confidence_tier == "uncertain")] | length,
  int_1: [.[] | select(.signal_intensity == 1)] | length,
  int_2: [.[] | select(.signal_intensity == 2)] | length,
  int_3: [.[] | select(.signal_intensity == 3)] | length,
  int_4: [.[] | select(.signal_intensity == 4)] | length,
  int_5: [.[] | select(.signal_intensity == 5)] | length,
  total: length
}') || {
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo '{"success": false, "error": "Failed to calculate scoring metadata from candidates"}'
  else
    echo "Error: Failed to calculate scoring metadata from candidates" >&2
  fi
  exit 3
}

# Extract values
TOTAL_CANDIDATES=$(echo "$SCORING_META" | jq '.total')
AVG_SCORE=$(echo "$SCORING_META" | jq '.avg_score')
HIGH_COUNT=$(echo "$SCORING_META" | jq '.high')
MEDIUM_COUNT=$(echo "$SCORING_META" | jq '.medium')
LOW_COUNT=$(echo "$SCORING_META" | jq '.low')
UNCERTAIN_COUNT=$(echo "$SCORING_META" | jq '.uncertain')
INT_1=$(echo "$SCORING_META" | jq '.int_1')
INT_2=$(echo "$SCORING_META" | jq '.int_2')
INT_3=$(echo "$SCORING_META" | jq '.int_3')
INT_4=$(echo "$SCORING_META" | jq '.int_4')
INT_5=$(echo "$SCORING_META" | jq '.int_5')

AGREED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Atomically update the output file
jq \
  --arg agreed_at "$AGREED_AT" \
  --argjson candidates "$CANDIDATES_JSON" \
  --argjson total "$TOTAL_CANDIDATES" \
  --argjson web_count "$WEB_COUNT" \
  --argjson train_count "$TRAINING_COUNT" \
  --argjson user_count "$USER_COUNT" \
  --arg search_ts "$SEARCH_TIMESTAMP" \
  --arg web_status "$WEB_STATUS" \
  --argjson avg_score "$AVG_SCORE" \
  --argjson high_count "$HIGH_COUNT" \
  --argjson medium_count "$MEDIUM_COUNT" \
  --argjson low_count "$LOW_COUNT" \
  --argjson uncertain_count "$UNCERTAIN_COUNT" \
  --argjson int_1 "$INT_1" \
  --argjson int_2 "$INT_2" \
  --argjson int_3 "$INT_3" \
  --argjson int_4 "$INT_4" \
  --argjson int_5 "$INT_5" \
  '.tips_candidates.total = $total |
   .tips_candidates.source_distribution.web_signal = $web_count |
   .tips_candidates.source_distribution.training = $train_count |
   .tips_candidates.source_distribution.user_proposed = $user_count |
   .tips_candidates.web_research_status = $web_status |
   .tips_candidates.search_timestamp = $search_ts |
   .tips_candidates.scoring_metadata.avg_score = $avg_score |
   .tips_candidates.scoring_metadata.confidence_distribution.high = $high_count |
   .tips_candidates.scoring_metadata.confidence_distribution.medium = $medium_count |
   .tips_candidates.scoring_metadata.confidence_distribution.low = $low_count |
   .tips_candidates.scoring_metadata.confidence_distribution.uncertain = $uncertain_count |
   .tips_candidates.scoring_metadata.intensity_distribution.level_1 = $int_1 |
   .tips_candidates.scoring_metadata.intensity_distribution.level_2 = $int_2 |
   .tips_candidates.scoring_metadata.intensity_distribution.level_3 = $int_3 |
   .tips_candidates.scoring_metadata.intensity_distribution.level_4 = $int_4 |
   .tips_candidates.scoring_metadata.intensity_distribution.level_5 = $int_5 |
   .tips_candidates.items = $candidates |
   .execution.workflow_state = "agreed" |
   .execution.current_phase = 5 |
   .execution.phases_completed = ["phase-0", "phase-1", "phase-2", "phase-3", "phase-4", "phase-5"] |
   .execution.agreed_at = $agreed_at' \
  "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
  cat << EOF
{
  "success": true,
  "data": {
    "output_file": "$OUTPUT_FILE",
    "total_candidates": $TOTAL_CANDIDATES,
    "avg_score": $AVG_SCORE,
    "workflow_state": "agreed",
    "agreed_at": "$AGREED_AT"
  }
}
EOF
else
  echo "Finalized $TOTAL_CANDIDATES candidates in trend-scout-output.json (avg_score: $AVG_SCORE)"
fi
