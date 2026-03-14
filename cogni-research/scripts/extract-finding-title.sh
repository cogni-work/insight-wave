#!/usr/bin/env bash
set -euo pipefail
# extract-finding-title.sh
# Version: 3.0.0
# Purpose: Extract and normalize titles from finding entities with multi-strategy fallback
# Category: extractors
#
# Usage: extract-finding-title.sh --finding-file PATH [--json]
#
# Arguments:
#   --finding-file  Path to finding entity file (required)
#   --json          Output JSON format (optional)
#
# Output (JSON mode):
#   {
#     "success": true,
#     "data": {
#       "raw_title": "Finding: EU Taxonomy Green Finance Framework",
#       "normalized_title": "EU Taxonomy Green Finance Framework",
#       "strategy_used": "extract_from_heading"
#     }
#   }
#
# Output (Standard mode):
#   EU Taxonomy Green Finance Framework
#
# Exit codes:
#   0 - Success
#   1 - Validation/extraction error
#   2 - Invalid arguments
#   3 - File not found
#
# Strategies (in priority order):
#   1. extract_from_title      - title field from frontmatter (HIGHEST AUTHORITY)
#   2. extract_from_dc_title   - dc:title field from frontmatter (SECONDARY)
#   3. extract_from_heading    - First #+ heading after frontmatter (TERTIARY, rejects generic)
#   4. extract_from_filename   - Normalize filename as fallback (LAST RESORT)
#
# Example:
#   extract-finding-title.sh --finding-file finding-001.md --json


# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Extract frontmatter end line number
get_frontmatter_end() {
    local file="$1"
    local line_num=0
    local in_frontmatter=false

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Check for frontmatter delimiter (---)
        if [[ "$line" = "---" ]]; then
            if [[ "$in_frontmatter" = false ]]; then
                in_frontmatter=true
            else
                # Found closing delimiter
                echo "$line_num"
                return 0
            fi
        fi
    done < "$file"

    # No frontmatter found
    echo "0"
    return 0
}

# Strategy 1: Extract title from frontmatter
extract_from_title() {
    local file="$1"
    local title=""

    title="$(grep '^title:' "$file" 2>/dev/null | \
            sed 's/^title:[[:space:]]*//' | \
            sed 's/"//g' | \
            head -n1 | tr -d '\r\t' || echo "")"

    if [[ -n "$title" ]]; then
        echo "$title"
        return 0
    fi

    return 1
}

# Strategy 2: Extract dc:title from frontmatter
extract_from_dc_title() {
    local file="$1"
    local title=""

    title="$(grep '^dc:title:' "$file" 2>/dev/null | \
            sed 's/^dc:title:[[:space:]]*//' | \
            sed 's/"//g' | \
            head -n1 | tr -d '\r\t' || echo "")"

    if [[ -n "$title" ]]; then
        echo "$title"
        return 0
    fi

    return 1
}

# Strategy 3: Extract first #+ heading after frontmatter
extract_from_heading() {
    local file="$1"
    local frontmatter_end
    frontmatter_end="$(get_frontmatter_end "$file")"

    # Extract first heading after frontmatter (#+ format)
    local title=""
    if [[ "$frontmatter_end" -gt 0 ]]; then
        # Use tail to skip frontmatter, then grep for first heading
        # Match lines starting with 1 or more # characters followed by space
        title="$(tail -n +"$((frontmatter_end + 1))" "$file" 2>/dev/null | \
                grep -m1 '^#\{1,\}[[:space:]]' 2>/dev/null | \
                sed 's/^#\{1,\}[[:space:]]*//' | tr -d '\r\t' || echo "")"
    else
        # No frontmatter, just find first #+ heading
        title="$(grep -m1 '^#\{1,\}[[:space:]]' "$file" 2>/dev/null | \
                sed 's/^#\{1,\}[[:space:]]*//' | tr -d '\r\t' || echo "")"
    fi

    if [[ -n "$title" ]]; then
        echo "$title"
        return 0
    fi

    return 1
}

# Strategy 4: Normalize filename as last resort
extract_from_filename() {
    local file="$1"
    local basename_file
    basename_file="$(basename "$file" .md)"

    # Remove common prefixes and UUID suffix, convert to title case
    local title
    title="$(echo "$basename_file" | \
            sed 's/^finding-//' | \
            sed 's/^source-//' | \
            sed 's/-[a-f0-9]\{8\}$//' | \
            tr '-' ' ' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')"

    if [[ -n "$title" ]]; then
        echo "$title"
        return 0
    fi

    return 1
}

# Detect and reject generic section headers that provide no descriptive value
is_generic_header() {
    local title="$1"

    # Normalize to lowercase for case-insensitive matching
    local normalized
    normalized="$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    # Check against known generic headers
    case "$normalized" in
        finding|introduction|summary|background|overview|abstract|conclusion|results|discussion|methods)
            return 0  # Is generic (true)
            ;;
        *)
            return 1  # Not generic (false)
            ;;
    esac
}

# Extract title using cascading fallback strategies
extract_raw_title() {
    local file="$1"
    local title=""
    local strategy=""

    # Strategy 1: title from frontmatter (HIGHEST AUTHORITY)
    if title="$(extract_from_title "$file")"; then
        strategy="extract_from_title"
        echo "${strategy}|${title}"
        return 0
    fi

    # Strategy 2: dc:title from frontmatter (SECONDARY)
    if title="$(extract_from_dc_title "$file")"; then
        strategy="extract_from_dc_title"
        echo "${strategy}|${title}"
        return 0
    fi

    # Strategy 3: Heading after frontmatter (TERTIARY - document structure, may be ambiguous)
    if title="$(extract_from_heading "$file")"; then
        # Reject generic section headers, fallback to next strategy
        if ! is_generic_header "$title"; then
            strategy="extract_from_heading"
            echo "${strategy}|${title}"
            return 0
        fi
        # Generic header detected, try next strategy
    fi

    # Strategy 4: Filename normalization (LAST RESORT)
    if title="$(extract_from_filename "$file")"; then
        strategy="extract_from_filename"
        echo "${strategy}|${title}"
        return 0
    fi

    # All strategies failed
    return 1
}

# Normalize title by stripping "Finding:" prefix and whitespace
normalize_title() {
    local raw_title="$1"

    # Strip "Finding:" prefix (case-insensitive)
    local normalized
    normalized="$(echo "$raw_title" | sed 's/^[Ff]inding:[[:space:]]*//')"

    # Remove leading/trailing whitespace
    normalized="$(echo "$normalized" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Normalize internal whitespace (multiple spaces to single space)
    normalized="$(echo "$normalized" | sed 's/[[:space:]][[:space:]]*/ /g')"

    echo "$normalized"
}

# Main function
main() {
    local finding_file=""
    local json_mode=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --finding-file)
                finding_file="$2"
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
    [[ -n "$finding_file" ]] || error_json "Usage: $0 --finding-file PATH [--json]" 2

    # Validate file existence
    [[ -f "$finding_file" ]] || error_json "File not found: $finding_file" 3

    # Extract raw title with strategy
    local extraction_result
    if ! extraction_result="$(extract_raw_title "$finding_file")"; then
        error_json "No title found in file: $finding_file (all strategies failed)" 1
    fi

    # Parse strategy and title (format: "strategy|title")
    local strategy
    local raw_title
    strategy="$(echo "$extraction_result" | cut -d'|' -f1)"
    raw_title="$(echo "$extraction_result" | cut -d'|' -f2-)"

    # Validate extraction succeeded
    [[ -n "$raw_title" ]] || error_json "No title found in file: $finding_file" 1

    # Normalize title
    local normalized_title
    normalized_title="$(normalize_title "$raw_title")"

    # Validate normalization produced non-empty result
    [[ -n "$normalized_title" ]] || error_json "Empty title after normalization: $finding_file" 1

    # Output based on mode
    if [[ "$json_mode" = true ]]; then
        jq -n \
            --arg raw "$raw_title" \
            --arg normalized "$normalized_title" \
            --arg strategy "$strategy" \
            '{
                success: true,
                data: {
                    raw_title: $raw,
                    normalized_title: $normalized,
                    strategy_used: $strategy
                }
            }'
    else
        echo "$normalized_title"
    fi
}

# Execute main function
main "$@"
