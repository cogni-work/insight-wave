#!/usr/bin/env bash
set -euo pipefail
# generate-publisher-id.sh
# Purpose: Generate deterministic publisher ID from domain using name+hash algorithm
# Version: 1.0.0 - Created to fix source-creator/publisher-generator ID mismatch (Issue #84)
# Category: deeper-research shared utilities
# Usage: ./generate-publisher-id.sh --domain <domain> [--json]
#
# This utility ensures consistent publisher ID generation across:
# - source-creator.sh (Phase 5.1)
# - publisher-generator skill (Phase 6)
#
# Algorithm:
# 1. Extract organization name from domain (strip www., extract first component, capitalize)
# 2. Generate slug from org name (lowercase, hyphens, alphanumeric only)
# 3. Generate 8-char MD5 hash from org name
# 4. Combine: publisher-{slug}-{hash}
#
# Example:
#   Input:  www.pnas.org
#   Output: publisher-pnas-b86d58b8
#
# Exit codes:
#   0 - Success
#   2 - Parameter validation error (missing --domain)


# ============================================================================
# Parameter Parsing
# ============================================================================

DOMAIN=""
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
  case "$1" in
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "{\"success\": false, \"error\": \"Unknown parameter: $1\"}" >&2
      exit 2
      ;;
  esac
done

if [ -z "$DOMAIN" ]; then
  echo '{"success": false, "error": "Missing required parameter: --domain"}' >&2
  exit 2
fi

# ============================================================================
# Organization Name Extraction
# ============================================================================

extract_org_name_from_domain() {
  local domain="$1"

  # Strip protocol prefixes (if accidentally included)
  domain="${domain#http://}"
  domain="${domain#https://}"

  # Strip www. prefix
  domain="${domain#www.}"

  # Extract primary domain name (first component before dot)
  local org_name
  org_name=$(echo "$domain" | cut -d'.' -f1)

  # Capitalize first letter only (bash 3.2 compatible)
  local first_char
  local rest
  first_char=$(echo "${org_name:0:1}" | tr '[:lower:]' '[:upper:]')
  rest="${org_name:1}"
  org_name="${first_char}${rest}"

  echo "$org_name"
}

# ============================================================================
# ID Generation
# ============================================================================

generate_publisher_id() {
  local org_name="$1"

  # Generate slug: lowercase, replace spaces with hyphens, remove non-alphanumeric
  local slug
  slug=$(echo "$org_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g')

  # Handle empty slug edge case
  if [ -z "$slug" ]; then
    slug="unknown"
  fi

  # Generate 8-character MD5 hash (cross-platform)
  # NOTE: Using echo WITH newline (not echo -n) to match publisher-generator behavior
  # The documentation specifies -n but existing publishers were created with newline
  # This ensures backward compatibility with existing publisher files
  local hash
  if command -v md5sum &> /dev/null; then
    # Linux
    hash=$(echo "$org_name" | md5sum | cut -c1-8)
  elif command -v md5 &> /dev/null; then
    # macOS
    hash=$(echo "$org_name" | md5 | cut -c1-8)
  else
    # Fallback to Python (truly portable) - include newline for consistency
    hash=$(python3 -c "import hashlib; print(hashlib.md5(('$org_name' + '\\n').encode()).hexdigest()[:8])")
  fi

  echo "publisher-${slug}-${hash}"
}

# ============================================================================
# Main Execution
# ============================================================================

ORG_NAME=$(extract_org_name_from_domain "$DOMAIN")
PUBLISHER_ID=$(generate_publisher_id "$ORG_NAME")

if [ "$JSON_OUTPUT" = true ]; then
  jq -n \
    --arg domain "$DOMAIN" \
    --arg org_name "$ORG_NAME" \
    --arg publisher_id "$PUBLISHER_ID" \
    '{
      success: true,
      data: {
        domain: $domain,
        org_name: $org_name,
        publisher_id: $publisher_id
      }
    }'
else
  echo "$PUBLISHER_ID"
fi

exit 0
