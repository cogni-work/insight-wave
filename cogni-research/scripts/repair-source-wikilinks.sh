#!/usr/bin/env bash
set -euo pipefail
# repair-source-wikilinks.sh
# Version: 1.0.0
# Purpose: Identify and report broken source wikilinks in claim entities
# Category: validators
#
# Usage: repair-source-wikilinks.sh --project-path <path>
#
# Arguments:
#   --project-path <path>   Absolute path to deeper-research project directory (required)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "project_path": "string",
#       "claims_scanned": number,
#       "sources_found": number,
#       "source_references": [
#         {
#           "claim_file": "path",
#           "source_id": "string",
#           "exists": boolean,
#           "actual_path": "string (if exists)"
#         }
#       ],
#       "broken_count": number,
#       "valid_count": number
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error (no claims or sources found)
#   2 - Invalid arguments
#   3 - Project directory not found or invalid structure
#
# Example:
#   repair-source-wikilinks.sh --project-path /path/to/research-project
#
# Notes:
#   This script IDENTIFIES broken references only. For repair operations,
#   use LLM orchestration with fuzzy-match and apply-fixes scripts.
#   Follows LLM-Control Architecture: scripts serve, LLMs orchestrate.


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_CLAIMS="$(get_directory_by_key "claims")"
DIR_SOURCES="$(get_directory_by_key "sources")"

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Extract source_id from claim YAML frontmatter
# Args: $1 = claim file path
# Returns: source_id (without [[]] brackets) or empty string
extract_source_id() {
    local claim_file="$1"

    # Extract YAML frontmatter and find source_id line
    # Format: source_id: [[07-sources/data/source-abc123]]
    local source_line
    source_line="$(awk '
        /^---$/ { in_yaml = !in_yaml; next }
        in_yaml && /^source_id:/ { print $0; exit }
    ' "$claim_file" 2>/dev/null || echo "")"

    if [[ -z "$source_line" ]]; then
        echo ""
        return
    fi

    # Extract content between [[ ]]
    # Use sed to extract wikilink: [[07-sources/data/xyz]] -> 07-sources/data/xyz
    local source_id
    source_id="$(echo "$source_line" | sed -n 's/.*\[\[\([^]]*\)\]].*/\1/p' | tr -d '\r\t\n')"

    echo "$source_id"
}

# Main function
main() {
    local project_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1. Usage: $0 --project-path <path>" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path <path>" 2

    # Validate project directory exists
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 3

    # Validate required subdirectories exist
    local claims_dir="${project_path}/${DIR_CLAIMS}/${DATA_SUBDIR}"
    local sources_dir="${project_path}/${DIR_SOURCES}/${DATA_SUBDIR}"

    [[ -d "$claims_dir" ]] || error_json "Claims directory not found: $claims_dir" 3
    [[ -d "$sources_dir" ]] || error_json "Sources directory not found: $sources_dir" 3

    # Build list of actual source files
    local source_files=()
    while IFS= read -r source_file; do
        source_files+=("$source_file")
    done < <(find "$sources_dir" -name "*.md" -type f 2>/dev/null || true)

    local sources_count=${#source_files[@]}
    [[ $sources_count -gt 0 ]] || error_json "No source files found in $sources_dir" 1

    # Scan all claim files
    local claim_files=()
    while IFS= read -r claim_file; do
        claim_files+=("$claim_file")
    done < <(find "$claims_dir" -name "*.md" -type f 2>/dev/null || true)

    local claims_count=${#claim_files[@]}
    [[ $claims_count -gt 0 ]] || error_json "No claim files found in $claims_dir" 1

    # Process each claim and collect source references
    local references_data=()
    local broken_count=0
    local valid_count=0

    for claim_file in "${claim_files[@]}"; do
        local source_id
        source_id="$(extract_source_id "$claim_file")"

        # Skip claims without source_id
        [[ -n "$source_id" ]] || continue

        # Check if source file exists
        # Convert wikilink path to filesystem path
        local source_file_path="${project_path}/${source_id}.md"
        local exists=false
        local actual_path=""

        if [[ -f "$source_file_path" ]]; then
            exists=true
            actual_path="$source_file_path"
            valid_count=$((valid_count + 1))
        else
            broken_count=$((broken_count + 1))
        fi

        # Build JSON object for this reference
        local ref_json
        ref_json="$(jq -n \
            --arg claim "$claim_file" \
            --arg sid "$source_id" \
            --argjson ex "$exists" \
            --arg path "$actual_path" \
            '{
                claim_file: $claim,
                source_id: $sid,
                exists: $ex,
                actual_path: $path
            }')"

        references_data+=("$ref_json")
    done

    # Convert references array to JSON
    local references_json="[]"
    if [[ ${#references_data[@]} -gt 0 ]]; then
        references_json="$(printf '%s\n' "${references_data[@]}" | jq -s .)"
    fi

    # Output results (always JSON format)
    jq -n \
        --arg project "$project_path" \
        --argjson claims "$claims_count" \
        --argjson sources "$sources_count" \
        --argjson refs "$references_json" \
        --argjson broken "$broken_count" \
        --argjson valid "$valid_count" \
        '{
            success: true,
            data: {
                project_path: $project,
                claims_scanned: $claims,
                sources_found: $sources,
                source_references: $refs,
                broken_count: $broken,
                valid_count: $valid
            }
        }'
}

# Execute main function
main "$@"
