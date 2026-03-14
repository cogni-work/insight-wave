#!/usr/bin/env bash
set -euo pipefail
# merge-duplicate-sources.sh
# Version: 1.0.0
# Purpose: Merge duplicate sources by updating finding references and archiving redundants
# Category: utilities
#
# Usage: merge-duplicate-sources.sh --project-path <path> --report <json> [OPTIONS]
#
# Arguments:
#   --project-path <path>   Project directory containing 04-findings/ and 07-sources/ (required)
#   --report <json>         Path to duplicate detection report JSON (required)
#   --dry-run              Preview changes without modifying files (optional)
#   --json                 Output results in JSON format (optional)
#   --no-backup            Skip backup creation (not recommended) (optional)
#   --archive-dir <path>   Custom archive directory (default: .archive/) (optional)
#
# Output (JSON):
#   {
#     "success": true,
#     "data": {
#       "dry_run": false,
#       "findings_updated": 5,
#       "sources_archived": 3,
#       "backup_path": "{project}/.backups/merge-20251105133045/",
#       "operations": [...]
#     }
#   }
#
# Output (Text):
#   Summary of merge operations with counts and paths
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - File/resource not found
#
# Example:
#   merge-duplicate-sources.sh --project-path /path/to/project --report duplicates.json --dry-run


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"

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
    # Initialize variables
    local project_path=""
    local report_file=""
    local dry_run=false
    local json_output=false
    local no_backup=false
    local archive_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --report)
                report_file="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --json)
                json_output=true
                shift
                ;;
            --no-backup)
                no_backup=true
                shift
                ;;
            --archive-dir)
                archive_dir="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -n "$report_file" ]] || error_json "Missing required argument: --report" 2

    # Validate paths exist
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 3
    [[ -f "$report_file" ]] || error_json "Report file not found: $report_file" 3

    # Validate project structure
    [[ -d "$project_path/04-findings/${DATA_SUBDIR}" ]] || error_json "Findings directory not found: $project_path/04-findings/${DATA_SUBDIR}" 3
    [[ -d "$project_path/07-sources/${DATA_SUBDIR}" ]] || error_json "Sources directory not found: $project_path/07-sources/${DATA_SUBDIR}" 3

    # Validate report JSON syntax
    if ! jq . "$report_file" &>/dev/null; then
        error_json "Invalid JSON in report file: $report_file" 1
    fi

    # Set archive directory
    if [[ -z "$archive_dir" ]]; then
        archive_dir="$project_path/.archive/sources"
    fi

    # Execute merge operation
    merge_duplicates "$project_path" "$report_file" "$dry_run" "$no_backup" "$archive_dir" "$json_output"
}

# BUG-029 & BUG-031 FIX: Core merge logic with single-pass processing
merge_duplicates() {
    local project_path="$1"
    local report_file="$2"
    local dry_run="$3"
    local no_backup="$4"
    local archive_dir="$5"
    local json_output="$6"

    local findings_updated=0
    local sources_archived=0
    local backup_path=""

    # BUG-031 FIX: Use temp file for operations to avoid array concatenation overhead
    local ops_temp="$(mktemp)"
    trap "rm -f '$ops_temp'" EXIT

    # Create backup directory if not dry-run and not disabled
    if [[ "$dry_run" = false ]] && [[ "$no_backup" = false ]]; then
        backup_path="$project_path/.backups/merge-$(date +%Y%m%d%H%M%S)"
        mkdir -p "$backup_path"
        [[ "$json_output" = false ]] && echo "Created backup directory: $backup_path"
    fi

    # Create archive directory
    if [[ "$dry_run" = false ]]; then
        mkdir -p "$archive_dir"
    fi

    # Parse duplicate groups from report
    local num_groups="$(jq '.data.duplicate_groups | length' "$report_file")"

    [[ "$json_output" = false ]] && echo "Processing $num_groups duplicate groups..."

    # Process each duplicate group
    local group_index=0
    while [[ $group_index -lt $num_groups ]]; do
        local group="$(jq -c ".data.duplicate_groups[$group_index]" "$report_file")"

        local canonical_id="$(echo "$group" | jq -r '.canonical')"
        local clean_canonical_id="$(echo "$canonical_id" | tr -d '\r\t\n')"
        local canonical_file="$project_path/07-sources/${DATA_SUBDIR}/${clean_canonical_id}.md"

        # Verify canonical source exists
        if [[ ! -f "$canonical_file" ]]; then
            [[ "$json_output" = false ]] && echo "WARNING: Canonical source not found: $canonical_id" >&2
            echo "ERROR: Canonical source missing: $canonical_id" >> "$ops_temp"
            group_index=$((group_index + 1))
            continue
        fi

        # Get orphaned source IDs
        local num_orphaned="$(echo "$group" | jq '.orphaned | length')"
        local orphan_index=0

        while [[ $orphan_index -lt $num_orphaned ]]; do
            local orphaned_id="$(echo "$group" | jq -r ".orphaned[$orphan_index]")"
            local clean_orphaned_id="$(echo "$orphaned_id" | tr -d '\r\t\n')"
            local orphaned_file="$project_path/07-sources/${DATA_SUBDIR}/${clean_orphaned_id}.md"

            # BUG-029 FIX: Single-pass processing - process findings inline without building array first
            # This avoids double iteration (O(2n) → O(n))
            while IFS= read -r finding; do
                [[ -z "$finding" ]] && continue

                if [[ "$dry_run" = true ]]; then
                    [[ "$json_output" = false ]] && echo "[DRY-RUN] Would update $(basename "$finding"): $orphaned_id → $canonical_id"
                    echo "UPDATE: $(basename "$finding") - $orphaned_id → $canonical_id" >> "$ops_temp"
                else
                    # Backup finding if backups enabled
                    if [[ "$no_backup" = false ]]; then
                        cp "$finding" "$backup_path/$(basename "$finding")"
                    fi

                    # Update source_id reference using sed (atomic with temp file)
                    # Pattern handles: source_id: "[[07-sources/data/SOURCE-ID]]"
                    # Use escaped versions in sed
                    if sed "s|source_id: \"\\[\\[07-sources/data/${clean_orphaned_id}\\]\\]\"|source_id: \"[[07-sources/data/${clean_canonical_id}]]\"|g" \
                        "$finding" > "${finding}.tmp"; then

                        # Verify update succeeded by checking for new canonical_id
                        if grep -q "source_id:.*${clean_canonical_id}" "${finding}.tmp"; then
                            mv "${finding}.tmp" "$finding"
                            findings_updated=$((findings_updated + 1))
                            [[ "$json_output" = false ]] && echo "✓ Updated $(basename "$finding"): $orphaned_id → $canonical_id"
                            echo "UPDATED: $(basename "$finding") - $orphaned_id → $canonical_id" >> "$ops_temp"
                        else
                            echo "ERROR: Failed to update $finding - verification failed" >&2
                            rm -f "${finding}.tmp"
                            echo "ERROR: Failed to update $(basename "$finding")" >> "$ops_temp"
                        fi
                    else
                        echo "ERROR: sed failed for $finding" >&2
                        rm -f "${finding}.tmp"
                        echo "ERROR: sed failed for $(basename "$finding")" >> "$ops_temp"
                    fi
                fi
            done < <(grep -l "source_id:.*${clean_orphaned_id}" "$project_path/04-findings/${DATA_SUBDIR}/"*.md 2>/dev/null || true)

            # Archive orphaned source
            if [[ -f "$orphaned_file" ]]; then
                if [[ "$dry_run" = true ]]; then
                    [[ "$json_output" = false ]] && echo "[DRY-RUN] Would archive: ${clean_orphaned_id}.md"
                    echo "ARCHIVE: ${clean_orphaned_id}.md" >> "$ops_temp"
                else
                    if mv "$orphaned_file" "$archive_dir/${clean_orphaned_id}.md"; then
                        sources_archived=$((sources_archived + 1))
                        [[ "$json_output" = false ]] && echo "✓ Archived: ${clean_orphaned_id}.md"
                        echo "ARCHIVED: ${clean_orphaned_id}.md" >> "$ops_temp"
                    else
                        echo "ERROR: Failed to archive $orphaned_file" >&2
                        echo "ERROR: Failed to archive ${clean_orphaned_id}.md" >> "$ops_temp"
                    fi
                fi
            fi

            orphan_index=$((orphan_index + 1))
        done

        group_index=$((group_index + 1))
    done

    # Generate output
    if [[ "$json_output" = true ]]; then
        # BUG-031 FIX: Build operations JSON from temp file (single operation)
        local ops_json="[]"
        if [[ -s "$ops_temp" ]]; then
            ops_json="$(cat "$ops_temp" | jq -R . | jq -s .)"
        fi

        jq -n \
            --argjson dry_run "$([[ "$dry_run" = true ]] && echo true || echo false)" \
            --argjson findings "$findings_updated" \
            --argjson sources "$sources_archived" \
            --arg backup "$backup_path" \
            --argjson ops "$ops_json" \
            '{
                success: true,
                data: {
                    dry_run: $dry_run,
                    findings_updated: $findings,
                    sources_archived: $sources,
                    backup_path: $backup,
                    operations: $ops
                }
            }'
    else
        # Text summary
        echo ""
        echo "=== Merge Summary ==="
        echo "Mode: $([[ "$dry_run" = true ]] && echo "DRY-RUN" || echo "EXECUTED")"
        echo "Findings updated: $findings_updated"
        echo "Sources archived: $sources_archived"
        [[ -n "$backup_path" ]] && echo "Backup location: $backup_path"
        echo "Archive location: $archive_dir"
        echo ""

        if [[ "$dry_run" = false ]] && [[ -n "$backup_path" ]]; then
            echo "To restore backups if needed:"
            echo "  cp $backup_path/*.md $project_path/04-findings/"
            echo "  cp $archive_dir/*.md $project_path/07-sources/"
        fi
    fi
}

# Execute main function
main "$@"
