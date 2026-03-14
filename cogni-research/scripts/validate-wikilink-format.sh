#!/usr/bin/env bash
set -euo pipefail
# validate-wikilink-format.sh
# Version: 1.1.0
# Purpose: Validate wikilink follows standard format [[entity-type/data/entity-slug]]
# Category: validators
#
# Usage: validate-wikilink-format.sh --wikilink <string> [--entity-type <type>]
#
# Arguments:
#   --wikilink <string>      Wikilink string to validate (required)
#   --entity-type <string>   Expected entity type prefix like "04-findings" or "07-sources" (optional)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "valid": boolean,
#       "wikilink": "input wikilink",
#       "format": "valid|invalid",
#       "issues": ["list of validation failures"]
#     },
#     "error": "error message" (if validation cannot be performed)
#   }
#
# Exit codes:
#   0 - Validation completed (check data.valid for result)
#   1 - Validation logic failed (not a validation failure, but script error)
#   2 - Invalid arguments
#
# Example:
#   validate-wikilink-format.sh --wikilink "[[04-findings/data/finding-slug]]"
#   validate-wikilink-format.sh --wikilink "[[04-findings/data/my-finding]]" --entity-type "04-findings"
#
# Note: All wikilinks must include /data/ subdirectory per entity-schema.json v2.1.0


# Error handler
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Main validation function
main() {
    local wikilink=""
    local entity_type=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --wikilink)
                wikilink="$2"
                shift 2
                ;;
            --entity-type)
                entity_type="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1. Usage: $0 --wikilink <string> [--entity-type <type>]" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$wikilink" ]] || error_json "Missing required argument: --wikilink. Usage: $0 --wikilink <string> [--entity-type <type>]" 2

    # Perform validation checks
    local issues=()
    local valid=true
    local format="valid"

    # Validation check 0a: Trailing backslash (LLM JSON escaping artifact) - CHECK FIRST
    if echo "$wikilink" | grep -q '\\]]$'; then
        issues+=("Trailing backslash detected - common LLM JSON escaping artifact: \\]] instead of ]]")
        valid=false
        format="invalid"
    fi

    # Validation check 0b: Trailing space (formatting artifact) - CHECK FIRST
    if echo "$wikilink" | grep -q ' ]]$'; then
        issues+=("Trailing space detected - formatting artifact:  ]] instead of ]]")
        valid=false
        format="invalid"
    fi

    # Validation check 0c: .md extension (path completion artifact) - CHECK FIRST
    if echo "$wikilink" | grep -q '\.md]]$'; then
        issues+=(".md extension detected - path completion artifact: should not include .md")
        valid=false
        format="invalid"
    fi

    # Validation check 1: General wikilink structure [[...]]
    if ! check_brackets "$wikilink"; then
        issues+=("Missing or incorrect brackets - expected format: [[entity-type/data/entity-slug]]")
        valid=false
        format="invalid"
    fi

    # Validation check 2: Path separator present
    if [[ "$valid" = true ]] && ! check_path_separator "$wikilink"; then
        issues+=("Missing path separator - expected format: [[entity-type/data/entity-slug]]")
        valid=false
        format="invalid"
    fi

    # Validation check 3: Entity type, data subdir, and slug format (kebab-case)
    if [[ "$valid" = true ]] && ! check_format "$wikilink" "$entity_type"; then
        if [[ -n "$entity_type" ]]; then
            issues+=("Invalid format - expected: [[${entity_type}/data/entity-slug]] with kebab-case slug")
        else
            issues+=("Invalid format - expected: [[entity-type/data/entity-slug]] with kebab-case type and slug")
        fi
        valid=false
        format="invalid"
    fi

    # Build issues array for JSON
    local issues_json
    if [[ ${#issues[@]} -gt 0 ]]; then
        issues_json="$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)"
    else
        issues_json="[]"
    fi

    # Return validation result
    jq -n \
        --arg wikilink "$wikilink" \
        --argjson valid "$([[ "$valid" = true ]] && echo true || echo false)" \
        --arg format "$format" \
        --argjson issues "$issues_json" \
        '{
            success: true,
            data: {
                valid: $valid,
                wikilink: $wikilink,
                format: $format,
                issues: $issues
            }
        }'
}

# Validation check: Trailing backslash (LLM artifact)
check_trailing_backslash() {
    local wikilink="$1"
    [[ "$wikilink" =~ \\]]\$ ]]
}

# Validation check: Trailing space (formatting artifact)
check_trailing_space() {
    local wikilink="$1"
    [[ "$wikilink" =~ \ ]]\$ ]]
}

# Validation check: .md extension (path completion artifact)
check_md_extension() {
    local wikilink="$1"
    [[ "$wikilink" =~ \.md]]\$ ]]
}

# Validation check: Proper bracket structure [[...]]
check_brackets() {
    local wikilink="$1"
    [[ "$wikilink" =~ ^\[\[.*\]\]$ ]]
}

# Validation check: Contains path separator /
check_path_separator() {
    local wikilink="$1"
    # Extract content between brackets
    local content="${wikilink#\[\[}"
    content="${content%\]\]}"
    [[ "$content" =~ / ]]
}

# Validation check: Proper format with entity type, data subdir, and slug
check_format() {
    local wikilink="$1"
    local entity_type="$2"

    # Extract content between brackets
    local content="${wikilink#\[\[}"
    content="${content%\]\]}"

    if [[ -n "$entity_type" ]]; then
        # Stricter validation: Check specific entity type with /data/ subdirectory
        # Pattern: entity-type/data/slug where slug is kebab-case
        [[ "$content" =~ ^${entity_type}/data/[a-z0-9]+(-[a-z0-9]+)*$ ]]
    else
        # General validation: Any valid entity-type/data/entity-slug
        # Pattern: type/data/slug where type and slug are kebab-case
        [[ "$content" =~ ^[a-z0-9]+(-[a-z0-9]+)*/data/[a-z0-9]+(-[a-z0-9]+)*$ ]]
    fi
}

# Execute main function
main "$@"
