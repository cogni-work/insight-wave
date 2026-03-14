#!/usr/bin/env bash
set -euo pipefail
# scan-entity-directory.sh
# Version: 1.0.0
# Purpose: Scan entity directory and extract metadata from markdown files
# Category: extractors
#
# Usage: scan-entity-directory.sh --project-path <path> --entity-type <type>
#
# Arguments:
#   --project-path <path>     Research project directory (required)
#   --entity-type <string>    Entity type directory to scan (e.g., "07-sources") (required)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "entity_type": string,
#       "entities": [
#         {
#           "id": string,
#           "name": string,
#           "url": string,
#           "type": string
#         }
#       ],
#       "count": number
#     },
#     "error": string (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - Directory not found
#
# Example:
#   scan-entity-directory.sh --project-path ~/research/sprint-280 --entity-type 07-sources


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"

# Error handler
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Extract frontmatter field from markdown file
extract_frontmatter_field() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        /^---$/ { if (in_fm) exit; in_fm=!in_fm; next }
        in_fm && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            gsub(/^["'\''"]|["'\''""]$/, "")
            print
            exit
        }
    ' "$file"
}

# Main function
main() {
    local project_path=""
    local entity_type=""

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
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -n "$entity_type" ]] || error_json "Missing required argument: --entity-type" 2
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 3

    local data_subdir
    data_subdir="$(get_data_subdir)"
    local entity_dir="$project_path/$entity_type/$data_subdir"
    [[ -d "$entity_dir" ]] || {
        # Return empty array if directory doesn't exist
        jq -n --arg type "$entity_type" \
            '{success: true, data: {entity_type: $type, entities: [], count: 0}}'
        exit 0
    }

    # Scan entity files
    local entities="[]"
    while IFS= read -r file; do
        [[ -f "$file" ]] || continue

        local id="$(extract_frontmatter_field "$file" "id")"
        [[ -n "$id" ]] || continue

        local name="$(extract_frontmatter_field "$file" "name")"
        local url="$(extract_frontmatter_field "$file" "url")"

        local entity="$(jq -n \
            --arg id "$id" \
            --arg name "$name" \
            --arg url "$url" \
            --arg type "$entity_type" \
            '{id: $id, name: $name, url: $url, type: $type}')"

        entities="$(echo "$entities" | jq --argjson ent "$entity" '. + [$ent]')"
    done < <(find "$entity_dir" -name "*.md" -type f 2>/dev/null || true)

    local count="$(echo "$entities" | jq 'length')"

    jq -n \
        --arg type "$entity_type" \
        --argjson ents "$entities" \
        --argjson cnt "$count" \
        '{
            success: true,
            data: {
                entity_type: $type,
                entities: $ents,
                count: $cnt
            }
        }'
}

main "$@"
