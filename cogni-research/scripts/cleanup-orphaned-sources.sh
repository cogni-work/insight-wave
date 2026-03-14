#!/usr/bin/env bash
set -euo pipefail
# cleanup-orphaned-sources.sh
# Version: 1.0.0
# Purpose: Detect and archive sources not referenced by any findings
# Category: utilities
#
# Usage: cleanup-orphaned-sources.sh --project-path <path> [--dry-run]
#
# Arguments:
#   --project-path <path>   Project root directory (required)
#   --dry-run              Preview only, no archive operations (optional)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "total_sources": number,
#       "orphaned_count": number,
#       "archived_count": number,
#       "orphaned_sources": [string],
#       "archive_path": string,
#       "dry_run": boolean
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - Directory not found
#
# Example:
#   cleanup-orphaned-sources.sh --project-path /path/to/project
#   cleanup-orphaned-sources.sh --project-path /path/to/project --dry-run


# Script directory for sourcing libs
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized entity configuration
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_FINDINGS="$(get_directory_by_key "findings")"

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Main function
main() {
    local project_path=""
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Usage: $0 --project-path <path> [--dry-run]" 2

    # Validate project directory exists
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 3

    # Validate required subdirectories (using data/ subdirectory)
    local sources_dir="$project_path/${DIR_SOURCES}/${DATA_SUBDIR}"
    local findings_dir="$project_path/${DIR_FINDINGS}/${DATA_SUBDIR}"
    local archive_dir="$project_path/.archive/orphaned-sources"

    [[ -d "$sources_dir" ]] || error_json "Sources directory not found: $sources_dir" 3
    [[ -d "$findings_dir" ]] || error_json "Findings directory not found: $findings_dir" 3

    # Find all source IDs
    local source_ids=()
    while IFS= read -r source_file; do
        local source_id
        source_id="$(basename "$source_file" .md)"
        source_ids+=("$source_id")
    done < <(find "$sources_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)

    local total_sources=${#source_ids[@]}

    # BUG-018 FIX: Build source reference map once (O(n×m) → O(n+m))
    # Phase 1: Extract all source references from all findings (single pass)
    local source_refs_map=" "  # Space-delimited string for bash 3.2 compatibility

    while IFS= read -r finding_file; do
        # Extract all source IDs from this finding file
        while IFS= read -r source_id; do
            # Add to map if not already present (deduplicate)
            if ! [[ "$source_refs_map" == *" $source_id "* ]]; then
                source_refs_map="${source_refs_map}${source_id} "
            fi
        done < <(grep -o '"[^"]*"' "$finding_file" 2>/dev/null | grep -o 'source-[a-zA-Z0-9]*' || true)
    done < <(find "$findings_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)

    # Phase 2: Check each source against map (O(1) lookup per source)
    local orphaned_sources=()
    for source_id in "${source_ids[@]}"; do
        # O(1) pattern matching lookup
        if ! [[ "$source_refs_map" == *" $source_id "* ]]; then
            orphaned_sources+=("$source_id")
        fi
    done

    local orphaned_count=${#orphaned_sources[@]}
    local archived_count=0

    # Archive orphaned sources (unless dry-run)
    if [[ "$orphaned_count" -gt 0 ]] && [[ "$dry_run" = false ]]; then
        mkdir -p "$archive_dir"

        for source_id in "${orphaned_sources[@]}"; do
            local source_file="$sources_dir/$source_id.md"
            if [[ -f "$source_file" ]]; then
                mv "$source_file" "$archive_dir/$source_id.md"
                ((archived_count++))
            fi
        done
    fi

    # Build orphaned sources array for JSON
    local orphaned_json
    if [[ ${#orphaned_sources[@]} -gt 0 ]]; then
        orphaned_json="$(printf '%s\n' "${orphaned_sources[@]}" | jq -R . | jq -s .)"
    else
        orphaned_json="[]"
    fi

    # Output results (always JSON format)
    jq -n \
        --argjson total_sources "$total_sources" \
        --argjson orphaned_count "$orphaned_count" \
        --argjson archived_count "$archived_count" \
        --argjson orphaned_list "$orphaned_json" \
        --arg archive_path "$archive_dir" \
        --argjson dry_run "$dry_run" \
        '{
            success: true,
            data: {
                total_sources: $total_sources,
                orphaned_count: $orphaned_count,
                archived_count: $archived_count,
                orphaned_sources: $orphaned_list,
                archive_path: $archive_path,
                dry_run: $dry_run
            }
        }'
}

# Execute main function
main "$@"
