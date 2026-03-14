#!/usr/bin/env bash
set -euo pipefail
# detect-index-drift.sh
# Version: 1.0.0
# Purpose: Compare filesystem entities with .metadata/entity-index.json to detect drift
# Category: validators
#
# Usage: detect-index-drift.sh --index-file <path> --entity-type <type> --filesystem-entities <json>
#
# Arguments:
#   --index-file <path>           Path to .metadata/entity-index.json (required)
#   --entity-type <string>        Entity type to check (e.g., "07-sources") (required)
#   --filesystem-entities <json>  JSON array of entities from filesystem (required)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "entity_type": string,
#       "missing_entries": [entity],
#       "orphaned_entries": [entity],
#       "filesystem_count": number,
#       "index_count": number,
#       "has_drift": boolean
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - File not found
#
# Example:
#   detect-index-drift.sh --index-file .metadata/entity-index.json --entity-type 07-sources --filesystem-entities '[...]'


error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

main() {
    local index_file=""
    local entity_type=""
    local filesystem_entities=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --index-file)
                index_file="$2"
                shift 2
                ;;
            --entity-type)
                entity_type="$2"
                shift 2
                ;;
            --filesystem-entities)
                filesystem_entities="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    [[ -n "$index_file" ]] || error_json "Missing required argument: --index-file" 2
    [[ -n "$entity_type" ]] || error_json "Missing required argument: --entity-type" 2
    [[ -n "$filesystem_entities" ]] || error_json "Missing required argument: --filesystem-entities" 2
    [[ -f "$index_file" ]] || error_json "Index file not found: $index_file" 3

    # Extract index entries for this entity type
    local index_entries="$(jq -r --arg type "$entity_type" \
        '.[$type] // []' "$index_file")"

    # Find missing entries (in filesystem but not in index)
    local missing="$(jq -n \
        --argjson fs "$filesystem_entities" \
        --argjson idx "$index_entries" \
        '$fs | map(select(.id as $id | $idx | map(.id) | index($id) | not))')"

    # Find orphaned entries (in index but not in filesystem)
    local orphaned="$(jq -n \
        --argjson fs "$filesystem_entities" \
        --argjson idx "$index_entries" \
        '$idx | map(select(.id as $id | $fs | map(.id) | index($id) | not))')"

    local fs_count="$(echo "$filesystem_entities" | jq 'length')"
    local idx_count="$(echo "$index_entries" | jq 'length')"
    local missing_count="$(echo "$missing" | jq 'length')"
    local orphaned_count="$(echo "$orphaned" | jq 'length')"
    local has_drift="$([[ $missing_count -gt 0 || $orphaned_count -gt 0 ]] && echo true || echo false)"

    jq -n \
        --arg type "$entity_type" \
        --argjson missing "$missing" \
        --argjson orphaned "$orphaned" \
        --argjson fs_count "$fs_count" \
        --argjson idx_count "$idx_count" \
        --argjson drift "$has_drift" \
        '{
            success: true,
            data: {
                entity_type: $type,
                missing_entries: $missing,
                orphaned_entries: $orphaned,
                filesystem_count: $fs_count,
                index_count: $idx_count,
                has_drift: $drift
            }
        }'
}

main "$@"
