#!/usr/bin/env bash
set -euo pipefail
# update-industry-metadata.sh
# Version: 1.0.0
# Purpose: Update trend-scout-output.json with industry metadata after project initialization
# Category: utilities
#
# Usage: update-industry-metadata.sh --output-file <path> --industry <slug> --industry-en <name> \
#        --industry-de <name> --subsector <slug> --subsector-en <name> --subsector-de <name> \
#        --topic <text> --topic-normalized <slug> [--json]
#
# Arguments:
#   --output-file <path>       Path to trend-scout-output.json (required)
#   --industry <string>        Industry slug (required)
#   --industry-en <string>     Industry name in English (required)
#   --industry-de <string>     Industry name in German (required)
#   --subsector <string>       Subsector slug (required)
#   --subsector-en <string>    Subsector name in English (required)
#   --subsector-de <string>    Subsector name in German (required)
#   --topic <string>           Research topic text (required)
#   --topic-normalized <string> Normalized topic slug (required)
#   --portfolio-slug <string>  Portfolio project slug (optional, for portfolio-sourced init)
#   --portfolio-market <string> Portfolio market slug (optional, for portfolio-sourced init)
#   --json                     Output JSON format (optional flag)
#
# Output (JSON mode):
#   {"success": true, "data": {"output_file": "...", "fields_updated": 8}}
#
# Exit codes:
#   0 - Success
#   1 - Validation error or missing arguments
#   2 - File not found or jq error
#
# Example:
#   update-industry-metadata.sh --output-file "/path/to/.metadata/trend-scout-output.json" \
#     --industry "manufacturing" --industry-en "Manufacturing" --industry-de "Fertigung" \
#     --subsector "automotive" --subsector-en "Automotive" --subsector-de "Automobil" \
#     --topic "AI-driven predictive maintenance" --topic-normalized "ai-driven-predictive-maintenance" \
#     --json


# Defaults
OUTPUT_FILE=""
INDUSTRY=""
INDUSTRY_EN=""
INDUSTRY_DE=""
SUBSECTOR=""
SUBSECTOR_EN=""
SUBSECTOR_DE=""
TOPIC=""
TOPIC_NORMALIZED=""
PORTFOLIO_SLUG=""
PORTFOLIO_MARKET=""
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-file)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --industry)
      INDUSTRY="$2"
      shift 2
      ;;
    --industry-en)
      INDUSTRY_EN="$2"
      shift 2
      ;;
    --industry-de)
      INDUSTRY_DE="$2"
      shift 2
      ;;
    --subsector)
      SUBSECTOR="$2"
      shift 2
      ;;
    --subsector-en)
      SUBSECTOR_EN="$2"
      shift 2
      ;;
    --subsector-de)
      SUBSECTOR_DE="$2"
      shift 2
      ;;
    --topic)
      TOPIC="$2"
      shift 2
      ;;
    --topic-normalized)
      TOPIC_NORMALIZED="$2"
      shift 2
      ;;
    --portfolio-slug)
      PORTFOLIO_SLUG="$2"
      shift 2
      ;;
    --portfolio-market)
      PORTFOLIO_MARKET="$2"
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
[[ -z "$OUTPUT_FILE" ]] && MISSING+=("--output-file")
[[ -z "$INDUSTRY" ]] && MISSING+=("--industry")
[[ -z "$INDUSTRY_EN" ]] && MISSING+=("--industry-en")
[[ -z "$INDUSTRY_DE" ]] && MISSING+=("--industry-de")
[[ -z "$SUBSECTOR" ]] && MISSING+=("--subsector")
[[ -z "$SUBSECTOR_EN" ]] && MISSING+=("--subsector-en")
[[ -z "$SUBSECTOR_DE" ]] && MISSING+=("--subsector-de")
[[ -z "$TOPIC" ]] && MISSING+=("--topic")
[[ -z "$TOPIC_NORMALIZED" ]] && MISSING+=("--topic-normalized")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{\"success\": false, \"error\": \"Missing required arguments: ${MISSING[*]}\"}"
  else
    echo "Error: Missing required arguments: ${MISSING[*]}" >&2
  fi
  exit 1
fi

# Validate file exists
if [[ ! -f "$OUTPUT_FILE" ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{\"success\": false, \"error\": \"File not found: $OUTPUT_FILE\"}"
  else
    echo "Error: File not found: $OUTPUT_FILE" >&2
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
  exit 2
fi

# Build jq filter — base fields always updated
JQ_FILTER='.config.industry.primary = $industry |
   .config.industry.primary_en = $industry_en |
   .config.industry.primary_de = $industry_de |
   .config.industry.subsector = $subsector |
   .config.industry.subsector_en = $subsector_en |
   .config.industry.subsector_de = $subsector_de |
   .config.research_topic = $topic |
   .config.organizing_concept = $topic_normalized'

FIELDS_UPDATED=8

# Conditionally add portfolio_source if provided
JQ_ARGS=(
  --arg industry "$INDUSTRY"
  --arg industry_en "$INDUSTRY_EN"
  --arg industry_de "$INDUSTRY_DE"
  --arg subsector "$SUBSECTOR"
  --arg subsector_en "$SUBSECTOR_EN"
  --arg subsector_de "$SUBSECTOR_DE"
  --arg topic "$TOPIC"
  --arg topic_normalized "$TOPIC_NORMALIZED"
)

if [[ -n "$PORTFOLIO_SLUG" && -n "$PORTFOLIO_MARKET" ]]; then
  DISCOVERED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  JQ_ARGS+=(
    --arg portfolio_slug "$PORTFOLIO_SLUG"
    --arg portfolio_market "$PORTFOLIO_MARKET"
    --arg discovered_at "$DISCOVERED_AT"
  )
  JQ_FILTER="$JQ_FILTER |
   .config.portfolio_source = {portfolio_slug: \$portfolio_slug, market_slug: \$portfolio_market, discovered_at: \$discovered_at}"
  FIELDS_UPDATED=11
fi

# Update industry metadata in trend-scout-output.json
jq "${JQ_ARGS[@]}" "$JQ_FILTER" \
  "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
  cat << EOF
{
  "success": true,
  "data": {
    "output_file": "$OUTPUT_FILE",
    "fields_updated": $FIELDS_UPDATED
  }
}
EOF
else
  echo "Updated trend-scout-output.json with industry metadata"
fi
