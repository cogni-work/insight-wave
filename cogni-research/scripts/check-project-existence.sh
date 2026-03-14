#!/usr/bin/env bash
set -euo pipefail
# check-project-existence.sh
# Version: 1.0.0
# Purpose: Check for existing research projects and preview slug normalization
# Category: utilities
#
# Usage:
#   check-project-existence.sh --project-name <name> --projects-root <path> [--json]
#
# Arguments:
#   --project-name <string>       Project name to check (required)
#   --projects-root <path>        Projects root directory (optional, aliases: --base-dir)
#   --base-dir <path>             Alias for --projects-root
#   --json                   Output JSON format (optional flag)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "exists": boolean,
#       "normalized_name": "string",
#       "similar_projects": ["array of similar project names"]
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   check-project-existence.sh --project-name "green-bonds-research" \
#     --projects-root "$HOME/research-projects" --json


error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Normalize project name (same logic as generate-semantic-slug.sh)
normalize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | \
        sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/ß/ss/g' | \
        sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed -e 's/^-//' -e 's/-$//'
}

# Simple similarity check: character difference < 3
is_similar() {
    local str1="$1"
    local str2="$2"
    local len1=${#str1}
    local len2=${#str2}
    local len_diff=$((len1 - len2))
    [[ $len_diff -lt 0 ]] && len_diff=$((len_diff * -1))

    # BUG-030 FIX: Validate len_diff is numeric before comparison
    if ! [[ "$len_diff" =~ ^[0-9]+$ ]]; then
        len_diff=999  # Large number to trigger mismatch
    fi
    [[ $len_diff -ge 3 ]] && return 1

    local min_len=$len1
    [[ $len2 -lt $min_len ]] && min_len=$len2
    local diff=0
    for ((i=0; i<min_len; i++)); do
        ! [[ "${str1:$i:1}" == "${str2:$i:1}" ]] && ((diff++))
    done
    diff=$((diff + len_diff))
    [[ $diff -lt 3 ]]
}

# Find similar projects (max 3)
find_similar() {
    local normalized="$1"
    local base_dir="$2"
    [[ ! -d "$base_dir" ]] && echo "[]" && return

    local similar=()
    while IFS= read -r dir && [[ ${#similar[@]} -lt 3 ]]; do
        local name="$(basename "$dir")"
        ! [[ "$name" == "$normalized" ]] && is_similar "$normalized" "$name" && similar+=("$name")
    done < <(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

    [[ ${#similar[@]} -eq 0 ]] && echo "[]" && return
    printf '%s\n' "${similar[@]}" | jq -R . | jq -s .
}

main() {
    local project_name=""
    local base_dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-name)
                [[ $# -lt 2 ]] && error_json "Missing value for --project-name" 2
                project_name="$2"
                shift 2
                ;;
            --base-dir|--projects-root)
                [[ $# -lt 2 ]] && error_json "Missing value for $1" 2
                base_dir="$2"
                shift 2
                ;;
            --json) shift ;;  # Compatibility flag, always output JSON
            *) error_json "Unknown argument: $1" 2 ;;
        esac
    done

    [[ -z "$project_name" ]] && \
        error_json "Usage: $0 --project-name <name> [--base-dir <dir>] [--json]" 2

    # BUG-028 FIX: Proper default value handling for BUILDER_ROOT
    # Default base directory
    if [[ -z "$base_dir" ]]; then
        if [ -n "$BUILDER_ROOT" ]; then
            base_dir="$BUILDER_ROOT"
        else
            base_dir="$HOME/deeper-research"
        fi
    fi

    local normalized="$(normalize_name "$project_name")"
    local project_path="$base_dir/$normalized"
    local exists=false
    local existing_path="null"

    if [[ -d "$project_path" ]]; then
        exists=true
        existing_path="$project_path"
    fi

    local similar="$(find_similar "$normalized" "$base_dir")"

    # Build output
    if [[ "$exists" == true ]]; then
        jq -n \
            --arg orig "$project_name" \
            --arg norm "$normalized" \
            --arg path "$existing_path" \
            --argjson sim "$similar" \
            '{success: true, data: {
                exists: true,
                original_name: $orig,
                normalized_name: $norm,
                existing_path: $path,
                similar_projects: $sim
            }}'
    else
        jq -n \
            --arg orig "$project_name" \
            --arg norm "$normalized" \
            --argjson sim "$similar" \
            '{success: true, data: {
                exists: false,
                original_name: $orig,
                normalized_name: $norm,
                existing_path: null,
                similar_projects: $sim
            }}'
    fi
}

main "$@"
