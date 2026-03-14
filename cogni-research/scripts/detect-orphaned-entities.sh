#!/usr/bin/env bash
set -euo pipefail
# detect-orphaned-entities.sh
# Version: 1.0.0
# Purpose: Detect and report orphaned/incomplete entity files not registered in .metadata/entity-index.json
# Category: utilities
#
# Usage: detect-orphaned-entities.sh --project-path <path> [--entity-type <type>] [--json] [--fix]
#
# Arguments:
#   --project-path <path>     Path to research project (required)
#   --entity-type <string>    Specific entity type to check, e.g., "07-sources" (optional, checks all if omitted)
#   --json                    Output in JSON format (optional, default: human-readable)
#   --fix                     Add orphaned entities to index (optional, default: report only)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "orphaned_entities": [
#         {
#           "entity_id": "source-4cd3ce8b7c2e",
#           "entity_type": "07-sources",
#           "file_path": "07-sources/source-4cd3ce8b7c2e.md",
#           "issues": ["not_in_index", "json_style_yaml", "missing_created_at"],
#           "line_count": 24
#         }
#       ],
#       "total_orphaned": 3,
#       "total_scanned": 60,
#       "fixed_count": 0
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#   3 - File/resource not found
#
# Example:
#   detect-orphaned-entities.sh --project-path /path/to/project --json
#   detect-orphaned-entities.sh --project-path /path/to/project --entity-type "07-sources" --fix


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"

# Global arrays for collecting results (intentionally script-level scope)
declare -a ORPHANED_ENTITIES
declare -a REGISTERED_IDS
# BUG-024 FIX: Hash map for O(1) lookup (bash 3.2 compatible - space-delimited lookup string)
REGISTERED_MAP=""
FIXED_COUNT=0

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# BUG-024 FIX: O(1) lookup using pattern matching instead of O(n) linear search
# Check if entity is registered (optimized with pre-built lookup string)
is_entity_registered() {
    local entity_id="$1"

    # Handle empty map case
    [[ -z "$REGISTERED_MAP" ]] && return 1

    # O(1) pattern matching lookup (bash 3.2 compatible)
    [[ "$REGISTERED_MAP" == *" $entity_id "* ]]
}

# Main function
main() {
    # Parse arguments
    local project_path=""
    local entity_type=""
    local json_output=false
    local fix_mode=false

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
            --json)
                json_output=true
                shift
                ;;
            --fix)
                fix_mode=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Usage: $0 --project-path <path> [--entity-type <type>] [--json] [--fix]" 2
    [[ -d "$project_path" ]] || error_json "Project path not found: $project_path" 3

    # Validate index file exists
    local index_file="$project_path/.metadata/entity-index.json"
    [[ -f "$index_file" ]] || error_json "Entity index not found: $index_file" 3

    # Determine entity types to scan
    local entity_types=()
    if [[ -n "$entity_type" ]]; then
        entity_types=("$entity_type")
    else
        # Scan all standard entity directories
        entity_types=("07-sources" "08-publishers" "09-key-entities" "10-concepts" "11-relationships" "11-trends")
    fi

    # BUG-024 FIX: Load entity index into memory and build O(1) lookup map
    REGISTERED_IDS=()
    while IFS= read -r entity_id; do
        [[ -n "$entity_id" ]] && REGISTERED_IDS+=("$entity_id")
    done < <(jq -r '.[].id // empty' "$index_file" 2>/dev/null)

    # Build space-delimited lookup string with sentinel spaces (O(n) build, O(1) lookup)
    if [[ ${#REGISTERED_IDS[@]} -gt 0 ]]; then
        REGISTERED_MAP=" $(printf '%s ' "${REGISTERED_IDS[@]}")"
    fi

    # Scan for orphaned entities
    ORPHANED_ENTITIES=()
    local total_scanned=0
    FIXED_COUNT=0

    local data_subdir
    data_subdir="$(get_data_subdir)"

    for etype in "${entity_types[@]}"; do
        local entity_dir="$project_path/$etype/$data_subdir"
        [[ -d "$entity_dir" ]] || continue

        # Find all .md files in entity directory
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            total_scanned=$((total_scanned + 1))

            # Extract entity_id from filename
            local filename="$(basename "$file" .md)"

            # Check if registered in index (now O(1) instead of O(n))
            if ! is_entity_registered "$filename"; then
                analyze_orphan "$file" "$filename" "$etype" "$fix_mode" "$index_file"
            fi
        done < <(find "$entity_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)
    done

    # Output results
    if [[ "$json_output" = true ]]; then
        output_json "$total_scanned"
    else
        output_human "$total_scanned"
    fi
}

# Analyze orphaned entity file
analyze_orphan() {
    local file="$1"
    local entity_id="$2"
    local entity_type="$3"
    local fix_mode="$4"
    local index_file="$5"

    # Get relative path from project root (includes data subdir)
    local data_subdir
    data_subdir="$(get_data_subdir)"
    local relative_path="$entity_type/$data_subdir/$(basename "$file")"

    # Detect issues
    local issues=()
    issues+=("not_in_index")

    # Count lines
    local line_count="$(wc -l < "$file" | tr -d ' ')"

    # Check for incomplete file (<20 lines suggests frontmatter only)
    if [[ "$line_count" -lt 20 ]]; then
        issues+=("incomplete_file")
    fi

    # Check for JSON-style YAML (old format indicator)
    if grep -q '^[a-z_]*: ".*"$' "$file" 2>/dev/null; then
        issues+=("json_style_yaml")
    fi

    # Check for missing created_at field
    if ! grep -q '^created_at:' "$file" 2>/dev/null; then
        issues+=("missing_created_at")
    fi

    # Extract metadata from file for fix mode
    if [[ "$fix_mode" = true ]]; then
        # Extract name (remove quotes if present)
        local entity_name="$(grep '^name:' "$file" | head -1 | sed 's/^name: *//' | sed 's/"//g' || echo "")"

        # Extract URL (remove quotes if present)
        local entity_url="$(grep '^url:' "$file" | head -1 | sed 's/^url: *//' | sed 's/"//g' || echo "")"

        # Extract or generate created_at
        local created_at="$(grep '^created_at:' "$file" | head -1 | sed 's/^created_at: *//' || echo "")"
        if [[ -z "$created_at" ]]; then
            # Use file modification time as fallback
            created_at="$(date -u -r "$file" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")"
        fi

        # Register in index
        if [[ -n "$entity_name" ]]; then
            register_orphan "$index_file" "$entity_id" "$entity_type" "$relative_path" "$entity_name" "$entity_url" "$created_at"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi

    # Build issues array for JSON output
    local issues_json="$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)"

    # Store orphan data (global array for JSON output)
    ORPHANED_ENTITIES+=("$(jq -n \
        --arg id "$entity_id" \
        --arg type "$entity_type" \
        --arg path "$relative_path" \
        --argjson issues "$issues_json" \
        --argjson lines "$line_count" \
        '{
            entity_id: $id,
            entity_type: $type,
            file_path: $path,
            issues: $issues,
            line_count: $lines
        }')")
}

# Register orphaned entity in index
register_orphan() {
    local index_file="$1"
    local entity_id="$2"
    local entity_type="$3"
    local entity_path="$4"
    local name="$5"
    local url="$6"
    local created_at="$7"

    # Build new entry
    local new_entry="$(jq -n \
        --arg id "$entity_id" \
        --arg type "$entity_type" \
        --arg path "$entity_path" \
        --arg name "$name" \
        --arg url "$url" \
        --arg created "$created_at" \
        '{
            id: $id,
            entity_type: $type,
            entity_path: $path,
            name: $name,
            url: $url,
            created_at: $created
        }')"

    # Append to index file
    local tmp_file="${index_file}.tmp"
    jq --argjson entry "$new_entry" '. += [$entry]' "$index_file" > "$tmp_file"
    mv "$tmp_file" "$index_file"
}

# Output results in JSON format
output_json() {
    local total_scanned="$1"

    # Build orphaned entities array
    local orphaned_json="[]"
    if [[ ${#ORPHANED_ENTITIES[@]} -gt 0 ]]; then
        orphaned_json="$(printf '%s\n' "${ORPHANED_ENTITIES[@]}" | jq -s .)"
    fi

    jq -n \
        --argjson orphaned "$orphaned_json" \
        --argjson total "${#ORPHANED_ENTITIES[@]}" \
        --argjson scanned "$total_scanned" \
        --argjson fixed "$FIXED_COUNT" \
        '{
            success: true,
            data: {
                orphaned_entities: $orphaned,
                total_orphaned: $total,
                total_scanned: $scanned,
                fixed_count: $fixed
            }
        }'
}

# Output results in human-readable format
output_human() {
    local total_scanned="$1"
    local orphan_count="${#ORPHANED_ENTITIES[@]}"

    echo "=== Orphaned Entity Detection Results ==="
    echo "Total entities scanned: $total_scanned"
    echo "Total orphaned entities: $orphan_count"

    if [[ "$FIXED_COUNT" -gt 0 ]]; then
        echo "Fixed and registered: $FIXED_COUNT"
    fi

    if [[ "$orphan_count" -gt 0 ]]; then
        echo ""
        echo "Orphaned entities found:"

        # Build orphaned JSON for display
        local orphaned_json="[]"
        if [[ ${#ORPHANED_ENTITIES[@]} -gt 0 ]]; then
            orphaned_json="$(printf '%s\n' "${ORPHANED_ENTITIES[@]}" | jq -s .)"
        fi

        echo "$orphaned_json" | jq -r '.[] | "  - \(.entity_id) (\(.entity_type)) - Issues: \(.issues | join(", "))"'
    else
        echo ""
        echo "No orphaned entities detected."
    fi
}

# Execute main function
main "$@"
