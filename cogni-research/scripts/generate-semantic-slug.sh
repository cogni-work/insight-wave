#!/usr/bin/env bash
set -euo pipefail
# generate-semantic-slug.sh
# Version: 1.1.0
# Purpose: Generate semantic UUIDs (slug + hash) for entity creation across deeper-research agents
# Category: utilities
#
# Usage: generate-semantic-slug.sh --title "Entity Title" --content-key "unique-key" [--max-length N] [--json]
#
# Arguments:
#   --title <string>       Entity title for slug generation (required)
#   --content-key <string> String for hash generation (e.g., "url|title") (required)
#   --max-length <number>  Max slug length (optional, default: 50)
#   --json                 Output JSON format (optional flag)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "slug": "normalized-title",
#       "hash": "8-char-hash",
#       "semantic_uuid": "slug-hash"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Output (Standard mode):
#   semantic_uuid printed to stdout
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   generate-semantic-slug.sh --title "How 3 cities are using municipal green bonds" \
#     --content-key "https://example.com|How 3 cities are using municipal green bonds" \
#     --max-length 50 --json


# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Check if string contains non-ASCII characters
has_non_ascii() {
    local text="$1"
    # Use LC_ALL=C to make grep treat bytes, not UTF-8
    if echo "$text" | LC_ALL=C grep -q '[^[:print:]]' || echo "$text" | grep -qE '[^\x00-\x7F]'; then
        return 0  # Has non-ASCII
    fi
    return 1  # ASCII only
}

# Attempt to transliterate Unicode to ASCII
# Returns transliterated string on success, or hash-based slug on failure
transliterate_unicode() {
    local text="$1"
    local transliterated

    # Try iconv transliteration if available
    if command -v iconv >/dev/null 2>&1; then
        # macOS iconv outputs warnings to stderr - discard to prevent JSON contamination
        # Issue: 2>&1 was merging stderr into stdout, contaminating downstream jq parsing
        transliterated="$(echo "$text" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || echo "")"

        # Check if transliteration produced reasonable output (not all symbols)
        if [[ -n "$transliterated" ]] && ! [[ "$transliterated" == *"???"* ]]; then
            echo "$transliterated"
            return 0
        fi
    fi

    # Fallback: generate hash-based slug for non-transliteratable text
    # Use first 16 chars of hash to keep slug reasonably short
    local hash
    hash="$(echo -n "$text" | shasum -a 256 | cut -c1-16)"
    echo "unicode-${hash}"
    return 0
}

# Normalize title to slug
# - Lowercase
# - Replace non-alphanumeric with hyphens
# - Collapse multiple hyphens
# - Strip leading/trailing hyphens
normalize_slug() {
    local title="$1"
    local slug

    # Check if title contains non-ASCII characters
    if has_non_ascii "$title"; then
        # Transliterate or generate hash-based slug
        title="$(transliterate_unicode "$title")"
    fi

    # Convert to lowercase (bash 3.2 compatible)
    slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -d '\r\t\n')"

    # Transliterate German umlauts for better slug readability
    slug="$(echo "$slug" | sed 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g')"

    # Replace non-alphanumeric characters with hyphens
    slug="$(echo "$slug" | sed 's/[^a-z0-9]/-/g')"

    # Collapse multiple hyphens to single hyphen
    slug="$(echo "$slug" | sed 's/-\{2,\}/-/g')"

    # Strip leading hyphens
    slug="$(echo "$slug" | sed 's/^-*//')"

    # Strip trailing hyphens
    slug="$(echo "$slug" | sed 's/-*$//')"

    echo "$slug"
}

# Truncate slug at word boundary (last hyphen before max_length)
truncate_slug() {
    local slug="$1"
    local max_length="$2"

    # If slug is within max_length, return as-is
    if [[ ${#slug} -le $max_length ]]; then
        echo "$slug"
        return
    fi

    # Truncate to max_length
    local truncated="${slug:0:$max_length}"

    # Find last hyphen in truncated string
    # Work backwards to find last hyphen (BUG-023 FIX: bash 3.2 compatible while loop)
    local last_hyphen_pos=-1
    local i
    i=$((${#truncated} - 1))
    while [ $i -ge 0 ]; do
        if [[ "${truncated:$i:1}" == "-" ]]; then
            last_hyphen_pos=$i
            break
        fi
        i=$((i - 1))
    done

    # If we found a hyphen, truncate there
    # Otherwise, use full truncated string (no word boundary available)
    if [[ $last_hyphen_pos -gt 0 ]]; then
        echo "${truncated:0:$last_hyphen_pos}"
    else
        echo "$truncated"
    fi
}

# Generate 8-character hash from content key
generate_hash() {
    local content_key="$1"
    echo -n "$content_key" | shasum -a 256 | cut -c1-8
}

# Main function
main() {
    # Initialize variables
    local title=""
    local content_key=""
    local max_length=50
    local json_mode=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            --content-key)
                content_key="$2"
                shift 2
                ;;
            --max-length)
                max_length="$2"
                shift 2
                ;;
            --json)
                json_mode=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$title" ]] || error_json "Missing required argument: --title" 2
    [[ -n "$content_key" ]] || error_json "Missing required argument: --content-key" 2

    # Validate max_length is numeric and positive
    if ! [[ "$max_length" =~ ^[0-9]+$ ]] || [[ $max_length -lt 1 ]]; then
        error_json "Invalid --max-length: must be positive integer" 2
    fi

    # Generate slug
    local slug
    slug="$(normalize_slug "$title")"

    # Validate slug is not empty after normalization
    [[ -n "$slug" ]] || error_json "Invalid title: produces empty slug after normalization" 1

    # Truncate slug at word boundary if needed
    slug="$(truncate_slug "$slug" "$max_length")"

    # Validate slug is not empty after truncation
    [[ -n "$slug" ]] || error_json "Invalid title: produces empty slug after truncation" 1

    # Generate hash from content key
    local hash
    hash="$(generate_hash "$content_key")"

    # Combine into semantic UUID
    local semantic_uuid="${slug}-${hash}"

    # Output based on mode
    if [[ "$json_mode" == true ]]; then
        jq -n \
            --arg slug "$slug" \
            --arg hash "$hash" \
            --arg semantic_uuid "$semantic_uuid" \
            '{
                success: true,
                data: {
                    slug: $slug,
                    hash: $hash,
                    semantic_uuid: $semantic_uuid
                }
            }'
    else
        # Standard mode: print semantic_uuid only
        echo "$semantic_uuid"
    fi
}

# Execute main function
main "$@"
