#!/usr/bin/env bash
set -euo pipefail
# repair-hash-mismatches.sh
# Version: 1.0.0
# Purpose: Fix wikilinks with incorrect hash values by replacing them with canonical entity IDs
# Category: utilities
#
# Usage: repair-hash-mismatches.sh --project-path <path> [options]
#
# Arguments:
#   --project-path <path>       Absolute path to deeper-research project directory (required)
#   --entity-type <type>        Target specific entity type (claim, source, finding, etc.) (optional)
#   --dry-run                   Preview changes without applying them (optional)
#   --json                      Output results in JSON format (optional)
#   --backup-dir <path>         Custom backup directory path (optional, default: project-path/.backup-TIMESTAMP)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "mode": "dry-run" | "repair",
#       "files_scanned": number,
#       "wikilinks_checked": number,
#       "hash_mismatches_found": number,
#       "hash_mismatches_repaired": number,
#       "unresolvable_mismatches": number,
#       "backup_created": "path" | null,
#       "repairs": [
#         {
#           "file": "path/to/file.md",
#           "line": number,
#           "old_link": "[[...]]",
#           "new_link": "[[...]]",
#           "entity_type": "type"
#         }
#       ]
#     },
#     "error": "error message" (if success=false)
#   }
#
# Output (text mode):
#   Human-readable report with statistics and repair details
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - Project path not found
#
# Example:
#   repair-hash-mismatches.sh --project-path /path/to/research --dry-run --json


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

# Build canonical entity ID index from project files
# Returns: index file path containing "type|prefix|canonical_filename" lines
build_canonical_index() {
    local project_path="$1"
    local entity_type_filter="$2"

    local temp_index
    temp_index="$(mktemp)"

    # Entity directories to scan (from centralized config)
    local entity_dirs=(
        "$(get_directory_by_key "findings")"
        "$(get_directory_by_key "sources")"
        "$(get_directory_by_key "publishers")"
        "$(get_directory_by_key "citations")"
        "$(get_directory_by_key "claims")"
    )

    # Scan each entity directory
    for dir in "${entity_dirs[@]}"; do
        local dir_path="$project_path/$dir/$DATA_SUBDIR"
        [[ -d "$dir_path" ]] || continue

        # Extract entity type from directory name (e.g., "10-claims" -> "claim")
        local dir_entity_type
        dir_entity_type="$(echo "$dir" | sed 's/^[0-9]*-//' | sed 's/s$//')"

        # Skip if filtering by type and doesn't match
        if [[ -n "$entity_type_filter" ]] && ! [[ "$dir_entity_type" == "$entity_type_filter" ]]; then
            continue
        fi

        # Find all markdown files in this directory
        while IFS= read -r entity_file; do
            [[ -f "$entity_file" ]] || continue

            # Extract entity_id from YAML frontmatter
            local entity_id
            entity_id="$(grep -m1 '^entity_id:' "$entity_file" 2>/dev/null | sed 's/^entity_id: *//' | tr -d '\r\t\n' || echo "")"

            [[ -n "$entity_id" ]] || continue

            # Extract prefix (everything before final hash)
            local prefix
            prefix="$(echo "$entity_id" | sed 's/-[a-z0-9]\{6,8\}$//')"

            # Store: type|prefix|filename
            local filename
            filename="$(basename "$entity_file")"
            echo "$dir_entity_type|$prefix|$filename" >> "$temp_index"

        done < <(find "$dir_path" -name "*.md" -type f)
    done

    echo "$temp_index"
}

# Scan files for wikilinks and detect hash mismatches
# Returns: repairs file path containing "file_path|line_num|old_link|new_link|entity_type" lines
scan_for_mismatches() {
    local project_path="$1"
    local index_file="$2"

    local temp_repairs
    temp_repairs="$(mktemp)"

    # Find all markdown files in project
    while IFS= read -r md_file; do
        [[ -f "$md_file" ]] || continue

        # Extract wikilinks with line numbers
        while IFS=: read -r line_num line_content; do
            # Extract all wikilinks from this line
            echo "$line_content" | grep -o '\[\[[^\]]\+\]\]' | while IFS= read -r wikilink; do
                # Parse wikilink components
                local link_content
                link_content="$(echo "$wikilink" | sed 's/^\[\[//; s/\]\]$//')"

                # Extract path components (handle optional directory prefix)
                local dir_prefix=""
                local entity_ref="$link_content"

                if [[ "$link_content" == */* ]]; then
                    dir_prefix="$(echo "$link_content" | sed 's|/[^/]*$||')"
                    entity_ref="$(echo "$link_content" | sed 's|.*/||')"
                fi

                # Check if target file exists
                local target_file=""
                if [[ -n "$dir_prefix" ]]; then
                    target_file="$project_path/$dir_prefix/$entity_ref.md"
                else
                    # Try to find in any entity directory
                    target_file="$(find "$project_path" -name "$entity_ref.md" -type f 2>/dev/null | head -n1)"
                fi

                # If file doesn't exist, lookup canonical version
                if [[ ! -f "$target_file" ]]; then
                    # Extract entity type and prefix from reference
                    local entity_type
                    entity_type="$(echo "$entity_ref" | sed 's/-.*//')"

                    local entity_prefix
                    entity_prefix="$(echo "$entity_ref" | sed 's/-[a-z0-9]\{6,8\}$//')"

                    # Lookup in index
                    local canonical_filename
                    canonical_filename="$(grep "^$entity_type|$entity_prefix|" "$index_file" 2>/dev/null | head -n1 | cut -d'|' -f3 || echo "")"

                    if [[ -n "$canonical_filename" ]]; then
                        # Found canonical version - this is a hash mismatch
                        local canonical_id
                        canonical_id="$(echo "$canonical_filename" | sed 's/\.md$//')"

                        local new_link
                        if [[ -n "$dir_prefix" ]]; then
                            new_link="[[$dir_prefix/$canonical_id]]"
                        else
                            new_link="[[$canonical_id]]"
                        fi

                        # Record repair: file|line|old|new|type
                        echo "$md_file|$line_num|$wikilink|$new_link|$entity_type" >> "$temp_repairs"
                    fi
                fi
            done
        done < <(grep -n '\[\[[^\]]\+\]\]' "$md_file" 2>/dev/null || true)

    done < <(find "$project_path" -name "*.md" -type f)

    echo "$temp_repairs"
}

# Apply repairs to files
apply_repairs() {
    local repairs_file="$1"
    local backup_dir="$2"

    # Group repairs by file
    local current_file=""
    local file_content=""

    while IFS='|' read -r file_path line_num old_link new_link entity_type; do
        # If new file, save previous and load new
        if ! [[ "$file_path" == "$current_file" ]]; then
            # Save previous file if exists
            if [[ -n "$current_file" ]] && [[ -n "$file_content" ]]; then
                echo "$file_content" > "$current_file"
            fi

            # Backup new file
            local backup_path="$backup_dir/$(basename "$file_path")"
            cp "$file_path" "$backup_path"

            # Load new file
            current_file="$file_path"
            file_content="$(cat "$file_path")"
        fi

        # Escape special regex characters in old link
        local escaped_old
        escaped_old="$(echo "$old_link" | sed 's/[[\.*^$/]/\\&/g')"

        # Replace in content
        file_content="$(echo "$file_content" | sed "s/$escaped_old/$new_link/g")"

    done < "$repairs_file"

    # Save final file
    if [[ -n "$current_file" ]] && [[ -n "$file_content" ]]; then
        echo "$file_content" > "$current_file"
    fi
}

# Generate report in JSON format
generate_json_report() {
    local mode="$1"
    local files_scanned="$2"
    local wikilinks_checked="$3"
    local repairs_file="$4"
    local backup_dir="$5"

    local repairs_count
    repairs_count="$(wc -l < "$repairs_file" | tr -d ' ')"

    # Build repairs array
    local repairs_json="[]"

    while IFS='|' read -r file_path line_num old_link new_link entity_type; do
        repairs_json="$(echo "$repairs_json" | jq \
            --arg file "$file_path" \
            --argjson line "$line_num" \
            --arg old "$old_link" \
            --arg new "$new_link" \
            --arg type "$entity_type" \
            '. + [{file: $file, line: $line, old_link: $old, new_link: $new, entity_type: $type}]')"
    done < "$repairs_file"

    # Generate final report
    local backup_value="null"
    if [[ -n "$backup_dir" ]]; then
        backup_value="\"$backup_dir\""
    fi

    jq -n \
        --arg mode "$mode" \
        --argjson scanned "$files_scanned" \
        --argjson checked "$wikilinks_checked" \
        --argjson found "$repairs_count" \
        --argjson repaired "$([[ "$mode" == "repair" ]] && echo "$repairs_count" || echo 0)" \
        --argjson unresolvable 0 \
        --argjson backup "$backup_value" \
        --argjson repairs "$repairs_json" \
        '{
            success: true,
            data: {
                mode: $mode,
                files_scanned: $scanned,
                wikilinks_checked: $checked,
                hash_mismatches_found: $found,
                hash_mismatches_repaired: $repaired,
                unresolvable_mismatches: $unresolvable,
                backup_created: $backup,
                repairs: $repairs
            }
        }'
}

# Generate report in text format
generate_text_report() {
    local mode="$1"
    local files_scanned="$2"
    local wikilinks_checked="$3"
    local repairs_file="$4"
    local backup_dir="$5"

    local repairs_count
    repairs_count="$(wc -l < "$repairs_file" | tr -d ' ')"

    echo "Hash Mismatch Repair Report"
    echo "============================"
    echo "Mode: $mode"
    echo "Files scanned: $files_scanned"
    echo "Wikilinks checked: $wikilinks_checked"
    echo ""
    echo "Hash Mismatches:"
    echo "  ✓ Found: $repairs_count"

    if [[ "$mode" == "repair" ]]; then
        echo "  ✓ Repaired: $repairs_count"
    else
        echo "  ✓ Repaired: 0 (dry-run mode)"
    fi

    echo "  ✗ Unresolvable: 0"
    echo ""

    if [[ -n "$backup_dir" ]]; then
        echo "Backup: $backup_dir"
        echo ""
    fi

    if [[ "$repairs_count" -gt 0 ]]; then
        echo "Repairs Found:"
        local counter=1
        while IFS='|' read -r file_path line_num old_link new_link entity_type; do
            local relative_path
            relative_path="$(basename "$file_path")"
            echo "  $counter. $relative_path:$line_num"
            echo "     Old: $old_link"
            echo "     New: $new_link"
            echo ""
            counter=$((counter + 1))
        done < "$repairs_file"
    fi
}

# Main function
main() {
    # Parse arguments
    local project_path=""
    local entity_type=""
    local dry_run=false
    local json_output=false
    local backup_dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --entity-type)
                entity_type="$2"
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
            --backup-dir)
                backup_dir="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Usage: --project-path <path> is required" 2
    [[ -d "$project_path" ]] || error_json "Project path not found: $project_path" 3

    # Set default backup directory if not provided
    if [[ -z "$backup_dir" ]]; then
        local timestamp
        timestamp="$(date +"%Y%m%d-%H%M%S")"
        backup_dir="$project_path/.backup-$timestamp"
    fi

    # Create backup directory if in repair mode
    if [[ "$dry_run" == false ]]; then
        mkdir -p "$backup_dir" || error_json "Failed to create backup directory: $backup_dir" 3
    fi

    # Phase 1: Build canonical index
    local index_file
    index_file="$(build_canonical_index "$project_path" "$entity_type")"

    # Phase 2: Scan for hash mismatches
    local repairs_file
    repairs_file="$(scan_for_mismatches "$project_path" "$index_file")"

    # Count statistics
    local files_scanned
    files_scanned="$(find "$project_path" -name "*.md" -type f | wc -l | tr -d ' ')"

    local wikilinks_checked
    wikilinks_checked="$(grep -r '\[\[[^\]]\+\]\]' "$project_path" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')"

    # Phase 3: Apply repairs if not dry-run
    local mode="dry-run"
    if [[ "$dry_run" == false ]]; then
        mode="repair"
        apply_repairs "$repairs_file" "$backup_dir"
    fi

    # Phase 4: Generate report
    if [[ "$json_output" == true ]]; then
        generate_json_report "$mode" "$files_scanned" "$wikilinks_checked" "$repairs_file" "$backup_dir"
    else
        generate_text_report "$mode" "$files_scanned" "$wikilinks_checked" "$repairs_file" "$backup_dir"
    fi

    # Cleanup temp files
    rm -f "$index_file" "$repairs_file"
}

# Execute main function
main "$@"
