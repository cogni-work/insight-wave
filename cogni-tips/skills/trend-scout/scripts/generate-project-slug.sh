#!/usr/bin/env bash
set -euo pipefail
# generate-project-slug.sh
# Version: 1.0.0
# Purpose: Generate semantic project slug combining industry subsector and research topic
# Category: utilities
#
# Usage: generate-project-slug.sh --industry <subsector-slug> --topic <topic> [--max-length N] [--json]
#
# Arguments:
#   --industry <string>    Subsector slug (e.g., "automotive", "pharmaceuticals") (required)
#   --topic <string>       Research topic text (required)
#   --max-length <number>  Maximum slug length (optional, default: 50)
#   --json                 Output JSON format (optional flag)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "industry_slug": "normalized-industry",
#       "topic_slug": "normalized-topic",
#       "hash": "8-char-hash",
#       "semantic_uuid": "industry-megatrend-hash"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Output (Standard mode):
#   semantic_uuid printed to stdout
#
# Exit codes:
#   0 - Success
#   1 - Validation error or missing arguments
#
# Example:
#   generate-project-slug.sh --industry "automotive" --topic "AI-driven predictive maintenance" --json


# Defaults
INDUSTRY=""
TOPIC=""
JSON_OUTPUT=false
MAX_LENGTH=50

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --industry)
      INDUSTRY="$2"
      shift 2
      ;;
    --topic)
      TOPIC="$2"
      shift 2
      ;;
    --max-length)
      MAX_LENGTH="$2"
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
if [[ -z "$INDUSTRY" ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo '{"success": false, "error": "Missing required argument: --industry"}'
  else
    echo "Error: Missing required argument: --industry" >&2
  fi
  exit 1
fi

if [[ -z "$TOPIC" ]]; then
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo '{"success": false, "error": "Missing required argument: --topic"}'
  else
    echo "Error: Missing required argument: --topic" >&2
  fi
  exit 1
fi

# Normalize function
normalize_slug() {
  local input="$1"
  local max_len="${2:-50}"

  # Convert to lowercase
  local slug="$(echo "$input" | tr '[:upper:]' '[:lower:]')"

  # Transliterate German umlauts
  slug="$(echo "$slug" | sed 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g')"
  slug="$(echo "$slug" | sed 's/Ä/ae/g; s/Ö/oe/g; s/Ü/ue/g')"

  # Replace non-alphanumeric with hyphens
  slug="$(echo "$slug" | sed 's/[^a-z0-9]/-/g')"

  # Collapse multiple hyphens
  slug="$(echo "$slug" | sed 's/--*/-/g')"

  # Strip leading/trailing hyphens
  slug="$(echo "$slug" | sed 's/^-//' | sed 's/-$//')"

  # Truncate at word boundary (last hyphen before max_len)
  if [[ ${#slug} -gt $max_len ]]; then
    slug="${slug:0:$max_len}"
    # Find last hyphen and truncate there
    if [[ "$slug" == *-* ]]; then
      slug="${slug%-*}"
    fi
  fi

  echo "$slug"
}

# Generate hash from content key
generate_hash() {
  local content="$1"
  # Use SHA256 and take first 8 characters
  echo -n "$content" | shasum -a 256 | cut -c1-8
}

# Normalize inputs
INDUSTRY_SLUG="$(normalize_slug "$INDUSTRY" 20)"
TOPIC_SLUG="$(normalize_slug "$TOPIC" 30)"

# Generate hash from combined content
CONTENT_KEY="${INDUSTRY}|${TOPIC}|$(date +%s)"
HASH="$(generate_hash "$CONTENT_KEY")"

# Combine into semantic UUID
SEMANTIC_UUID="${INDUSTRY_SLUG}-${TOPIC_SLUG}-${HASH}"

# Ensure total length doesn't exceed max
if [[ ${#SEMANTIC_UUID} -gt $MAX_LENGTH ]]; then
  # Recalculate with shorter topic
  remaining=$((MAX_LENGTH - ${#INDUSTRY_SLUG} - ${#HASH} - 2))
  TOPIC_SLUG="$(normalize_slug "$TOPIC" $remaining)"
  SEMANTIC_UUID="${INDUSTRY_SLUG}-${TOPIC_SLUG}-${HASH}"
fi

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
  cat << EOF
{
  "success": true,
  "data": {
    "industry_slug": "$INDUSTRY_SLUG",
    "topic_slug": "$TOPIC_SLUG",
    "hash": "$HASH",
    "semantic_uuid": "$SEMANTIC_UUID"
  }
}
EOF
else
  echo "$SEMANTIC_UUID"
fi
