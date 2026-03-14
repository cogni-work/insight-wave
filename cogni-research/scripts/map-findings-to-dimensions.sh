#!/usr/bin/env bash
set -euo pipefail
# map-findings-to-dimensions.sh
# Version: 1.0.0
# Purpose: Map findings to dimensions via query batch provenance
# Category: utilities
#
# Usage: map-findings-to-dimensions.sh --project-path <path> --dimension <name> [--json|--export]
#
# Arguments:
#   --project-path <path>  Project directory path (required)
#   --dimension <string>   Dimension name to filter findings (required)
#   --json                 Output JSON format (optional flag, default)
#   --export               Export wikilink format (optional flag)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "dimension": "string",
#       "findings_mapped": number,
#       "findings": ["array of finding IDs"]
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Usage error
#   3 - Path not found
#
# Example:
#   map-findings-to-dimensions.sh --project-path "/path/to/project" \
#     --dimension "sustainability-frameworks" --json


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DIR_FINDINGS="$(get_directory_by_key "findings")"

error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

main() {
    local project_path="" dimension="" output_mode="json"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path) project_path="${2:-}"; shift 2 ;;
            --dimension) dimension="${2:-}"; shift 2 ;;
            --json) output_mode="json"; shift ;;
            --export) output_mode="export"; shift ;;
            *) error_json "Unknown argument: $1" 2 ;;
        esac
    done

    # Validate inputs
    [[ -n "$project_path" ]] || error_json "Project path required (--project-path)" 2
    [[ -n "$dimension" ]] || error_json "Dimension name required (--dimension)" 2
    [[ -d "$project_path" ]] || error_json "Project path not found: $project_path" 3

    local batches_dir="$project_path/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}"
    local findings_dir="$project_path/${DIR_FINDINGS}/${DATA_SUBDIR}"

    [[ -d "$batches_dir" ]] || error_json "Query batches directory not found: $batches_dir" 3
    [[ -d "$findings_dir" ]] || error_json "Findings directory not found: $findings_dir" 3

    # Get batch files for dimension
    local batch_files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && batch_files+=("$f")
    done < <(grep -l "dimension: \"$dimension\"" "$batches_dir"/*.md 2>/dev/null || true)

    [[ ${#batch_files[@]} -gt 0 ]] || error_json "No query batches found for dimension: $dimension" 1

    # Extract query IDs from batches
    local query_ids=()
    for batch in "${batch_files[@]}"; do
        while IFS= read -r qid; do
            [[ -n "$qid" ]] && query_ids+=("$qid")
        done < <(grep "^  - query_id:" "$batch" | sed 's/.*"\([^"]*\)".*/\1/')
    done

    # BUG-034 FIX: Array accumulation instead of string concatenation (O(n²) → O(n))
    # Find findings referencing these queries (deduplicated)
    local findings_found_array=()
    for qid in "${query_ids[@]}"; do
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                findings_found_array+=("$(basename "$file" .md)")
            fi
        done < <(grep -l "\"$qid\"" "$findings_dir"/*.md 2>/dev/null || true)
    done

    # Deduplicate using sort -u (single operation instead of accumulating string)
    local finding_ids=()
    if [[ ${#findings_found_array[@]} -gt 0 ]]; then
        while IFS= read -r fid; do
            [[ -n "$fid" ]] && finding_ids+=("$fid")
        done < <(printf '%s\n' "${findings_found_array[@]}" | sort -u)
    fi

    local count="${#finding_ids[@]}"

    # Output
    if [[ "$output_mode" == "export" ]]; then
        echo "export DIMENSION_NAME=\"$dimension\""
        echo "export FINDING_IDS=\"${finding_ids[*]}\""
        echo "export FINDING_COUNT=\"$count\""
    else
        local json_array="[]"
        [[ $count -gt 0 ]] && json_array="$(printf '%s\n' "${finding_ids[@]}" | jq -R . | jq -s .)"

        jq -n \
            --arg dim "$dimension" \
            --argjson findings "$json_array" \
            --argjson cnt "$count" \
            '{success: true, data: {dimension: $dim, findings: $findings, finding_count: $cnt}}'
    fi
}

main "$@"
