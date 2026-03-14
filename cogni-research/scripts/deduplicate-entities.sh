#!/usr/bin/env bash
set -euo pipefail
# deduplicate-entities.sh
# Version: 1.0.0
# Purpose: Detect and merge duplicate entities after parallel phases complete
# Category: utilities
#
# Usage:
#   ./deduplicate-entities.sh --project-path <path> --entity-type <type> [--auto-merge] [--json] [--dry-run]
#
# Arguments:
#   --project-path <path>  Project directory (required)
#   --entity-type <type>   Entity type: 08-authors or 12-institutions (required)
#   --auto-merge          Auto-merge without prompting (optional)
#   --json                Output JSON report (default: true)
#   --dry-run             Preview changes without making them (optional)
#
# Output Format:
#   {
#     "success": true,
#     "data": {
#       "duplicates_found": 3,
#       "duplicates_merged": 3,
#       "wikilinks_updated": 47,
#       "files_removed": 3,
#       "details": [...]
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Missing required arguments
#   3 - File not found
#
# Example:
#   deduplicate-entities.sh --project-path "/path/to/project" \
#     --entity-type "08-publishers" --auto-merge --json


# Error handling
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Normalize entity name (same as lookup-entity.sh)
normalize_name() {
    echo "$1" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9 ]//g' | \
        sed 's/^the //' | sed 's/^a //' | sed 's/^an //' | \
        sed 's/  */ /g' | \
        sed 's/^ //;s/ $//'
}

# Main function
main() {
    local project_path=""
    local entity_type=""
    local auto_merge=false
    local output_json=true
    local dry_run=false

    # Parse arguments
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
            --auto-merge)
                auto_merge=true
                shift
                ;;
            --json)
                output_json=true
                shift
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
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -n "$entity_type" ]] || error_json "Missing required argument: --entity-type" 2

    # Validate project path exists
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 3

    # Validate entity type
    [[ "$entity_type" == "08-authors" || "$entity_type" == "12-institutions" ]] || \
        error_json "Invalid entity type: $entity_type (must be 08-authors or 12-institutions)" 1

    # Check .metadata/entity-index.json exists
    local index_file="$project_path/.metadata/entity-index.json"
    [[ -f "$index_file" ]] || error_json "Entity index not found: $index_file" 3

    # BUG-021 FIX: Use jq --arg for dynamic field names to avoid double quote issues
    local entity_count
    entity_count="$(jq -r --arg type "$entity_type" '.[$type] | length' "$index_file" 2>/dev/null || echo "0")"
    ! [[ "$entity_count" == "null" || "$entity_count" == "0" ]] || \
        error_json "Entity type not found in index: $entity_type" 1

    # Log to stderr
    echo "🔍 Scanning for duplicate entities in $entity_type..." >&2
    echo "📂 Project: $project_path" >&2

    # Phase 1: Detect duplicates
    local duplicates_data
    duplicates_data="$(detect_duplicates "$index_file" "$entity_type")"

    local duplicates_found
    duplicates_found="$(echo "$duplicates_data" | jq 'length')"

    if [[ "$duplicates_found" -eq 0 ]]; then
        echo "✅ No duplicates found" >&2
        jq -n \
            --argjson found 0 \
            --argjson merged 0 \
            --argjson updated 0 \
            --argjson removed 0 \
            '{
                success: true,
                data: {
                    duplicates_found: $found,
                    duplicates_merged: $merged,
                    wikilinks_updated: $updated,
                    files_removed: $removed,
                    details: []
                }
            }'
        exit 0
    fi

    echo "⚠️  Found $duplicates_found duplicate groups" >&2

    # Phase 2: Merge duplicates
    if [[ "$dry_run" == true ]]; then
        echo "🔍 DRY RUN - No changes will be made" >&2
        preview_duplicates "$duplicates_data"
        exit 0
    fi

    # Backup .metadata/entity-index.json
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup_file="$project_path/.metadata/entity-index.json.backup.$timestamp"
    cp "$index_file" "$backup_file"
    echo "💾 Backup created: $backup_file" >&2

    # Merge duplicates
    local merge_results
    merge_results="$(merge_duplicates "$project_path" "$entity_type" "$index_file" "$duplicates_data" "$auto_merge")"

    # Output results
    echo "$merge_results"
}

# Detect duplicates by normalized name
detect_duplicates() {
    local index_file="$1"
    local entity_type="$2"

    # Extract entities and group by normalized name
    jq -r --arg type "$entity_type" '
        .[$type] | to_entries |
        map({
            id: .key,
            name: .value.name,
            created_at: (.value.created_at // "1970-01-01T00:00:00Z"),
            path: .value.path
        }) |
        group_by(.name | ascii_downcase | gsub("[^a-z0-9 ]"; "") |
                 gsub("^(the|a|an) "; "") | gsub(" +"; " ") |
                 gsub("^ | $"; "")) |
        map(select(length > 1)) |
        map({
            canonical_name: .[0].name,
            entities: . | sort_by(.created_at)
        })
    ' "$index_file"
}

# Preview duplicates (dry-run mode)
preview_duplicates() {
    local duplicates_data="$1"

    echo "$duplicates_data" | jq -r '.[] |
        "📋 Group: \(.canonical_name)\n" +
        "   Entities (\(.entities | length)):\n" +
        (.entities | map("   - \(.id) (created: \(.created_at))") | join("\n"))
    ' >&2
}

# Merge duplicates
merge_duplicates() {
    local project_path="$1"
    local entity_type="$2"
    local index_file="$3"
    local duplicates_data="$4"
    local auto_merge="$5"

    local total_merged=0
    local total_wikilinks=0
    local total_removed=0
    local details_array="[]"

    # Process each duplicate group
    local group_count
    group_count="$(echo "$duplicates_data" | jq 'length')"

    for ((i=0; i<group_count; i++)); do
        local group
        group="$(echo "$duplicates_data" | jq ".[$i]")"

        local canonical_name
        canonical_name="$(echo "$group" | jq -r '.canonical_name')"

        local entities
        entities="$(echo "$group" | jq -c '.entities')"

        local entity_count
        entity_count="$(echo "$entities" | jq 'length')"

        # Ask for confirmation unless auto_merge
        if ! [[ "$auto_merge" == true ]]; then
            echo "" >&2
            echo "❓ Merge $entity_count duplicates of '$canonical_name'? (Y/n)" >&2
            read -r response
            if [[ "$response" =~ ^[Nn] ]]; then
                echo "⏭️  Skipped" >&2
                continue
            fi
        fi

        # Get canonical entity (first by created_at)
        local canonical_id
        canonical_id="$(echo "$entities" | jq -r '.[0].id')"

        # BUG-013 FIX: Check array has >1 elements before extracting .[1:]
        local duplicate_ids
        if [ "$entity_count" -gt 1 ]; then
            duplicate_ids="$(echo "$entities" | jq -r '.[1:] | map(.id) | .[]')"
        else
            duplicate_ids=""
        fi

        local wikilinks_updated=0
        local files_removed=0

        # Process each duplicate
        while IFS= read -r dup_id; do
            [[ -z "$dup_id" ]] && continue

            # Find and update wikilinks
            local files_with_links
            files_with_links="$(grep -rl "\[\[$dup_id\]\]" "$project_path" 2>/dev/null || true)"

            if [[ -n "$files_with_links" ]]; then
                while IFS= read -r file; do
                    [[ -z "$file" ]] && continue

                    # BUG-020 FIX: Escape special characters in IDs before using in sed
                    local dup_id_escaped canonical_id_escaped
                    dup_id_escaped="$(echo "$dup_id" | sed 's/[\/&]/\\&/g')"
                    canonical_id_escaped="$(echo "$canonical_id" | sed 's/[\/&]/\\&/g')"

                    # Replace wikilinks using portable sed pattern (SECURITY FIX: BUG-003)
                    # Portable alternative to sed -i that works on both Linux and macOS
                    sed "s/\[\[${dup_id_escaped}\]\]/[[${canonical_id_escaped}]]/g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
                    wikilinks_updated=$((wikilinks_updated + 1))
                done <<< "$files_with_links"
            fi

            # Get entity path and remove file
            local entity_path
            entity_path="$(jq -r --arg type "$entity_type" --arg id "$dup_id" \
                '.[$type][$id].path // empty' "$index_file")"

            if [[ -n "$entity_path" && -f "$project_path/$entity_path" ]]; then
                rm "$project_path/$entity_path"
                files_removed=$((files_removed + 1))
            fi

            # Remove from .metadata/entity-index.json
            jq --arg type "$entity_type" --arg id "$dup_id" \
                'del(.[$type][$id])' "$index_file" > "$index_file.tmp"
            mv "$index_file.tmp" "$index_file"

        done <<< "$duplicate_ids"

        # Update project-config.json (decrement count)
        local config_file="$project_path/.metadata/project-config.json"
        if [[ -f "$config_file" ]]; then
            local count_field="${entity_type}_count"
            jq --arg field "$count_field" --argjson decrement "$files_removed" \
                '.[$field] = (.[$field] // 0) - $decrement' "$config_file" > "$config_file.tmp"
            mv "$config_file.tmp" "$config_file"
        fi

        total_merged=$((total_merged + 1))
        total_wikilinks=$((total_wikilinks + wikilinks_updated))
        total_removed=$((total_removed + files_removed))

        # Build duplicate IDs array for details
        local dup_ids_array
        dup_ids_array="$(echo "$entities" | jq -c '[.[1:] | map(.id)] | .[0]')"

        # Add to details
        details_array="$(echo "$details_array" | jq \
            --arg canonical "$canonical_id" \
            --arg name "$canonical_name" \
            --argjson dups "$dup_ids_array" \
            --argjson links "$wikilinks_updated" \
            '. += [{
                canonical: $canonical,
                canonical_name: $name,
                duplicates: $dups,
                wikilinks_updated: $links
            }]')"

        echo "✅ Merged $files_removed duplicates of '$canonical_name' ($wikilinks_updated wikilinks updated)" >&2
    done

    local duplicates_found
    duplicates_found="$(echo "$duplicates_data" | jq 'length')"

    # Output final JSON
    jq -n \
        --argjson found "$duplicates_found" \
        --argjson merged "$total_merged" \
        --argjson updated "$total_wikilinks" \
        --argjson removed "$total_removed" \
        --argjson details "$details_array" \
        '{
            success: true,
            data: {
                duplicates_found: $found,
                duplicates_merged: $merged,
                wikilinks_updated: $updated,
                files_removed: $removed,
                details: $details
            }
        }'
}

main "$@"
