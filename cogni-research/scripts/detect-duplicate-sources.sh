#!/usr/bin/env bash
set -euo pipefail
# detect-duplicate-sources.sh
# Version: 1.0.0
# Purpose: Detect duplicate source entities by URL and generate remediation report
# Category: utilities
#
# Usage:
#   detect-duplicate-sources.sh --project-path <path> [--output <file>]
#
# Arguments:
#   --project-path <path>    Project directory containing 07-sources and 04-findings (required)
#   --output <file>          Write report to file instead of stdout (optional)
#
# Output (JSON):
#   {
#     "success": true,
#     "data": {
#       "timestamp": "2025-11-05T13:30:00Z",
#       "project_path": "/path/to/project",
#       "total_sources": 150,
#       "unique_urls": 145,
#       "duplicate_count": 5,
#       "duplicate_groups": [
#         {
#           "url": "https://example.com/article",
#           "source_count": 2,
#           "sources": [
#             {
#               "id": "source-abc123",
#               "path": "07-sources/source-abc123.md",
#               "name": "Article Title",
#               "created_at": "2025-11-05T09:53:46Z",
#               "finding_references": []
#             }
#           ],
#           "canonical": "source-abc123",
#           "orphaned": ["source-xyz789"]
#         }
#       ]
#     }
#   }
#
# Exit codes:
#   0 - Success (report generated)
#   1 - Error (validation or processing failed)
#   2 - Invalid arguments
#
# Example:
#   ./detect-duplicate-sources.sh --project-path /path/to/project --output report.json


# Source centralized entity config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_FINDINGS="$(get_directory_by_key "findings")"

# Error handling function
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Extract field from YAML frontmatter
extract_field() {
    local file="$1"
    local field="$2"

    # Extract field value, remove quotes and whitespace
    grep "^${field}:" "$file" 2>/dev/null | \
        sed "s/^${field}: *//" | \
        sed 's/^"//;s/"$//' | \
        sed "s/^'//;s/'$//" | \
        head -n 1 || echo ""
}

# Find all findings that reference a source
find_source_references() {
    local project_path="$1"
    local source_id="$2"
    local findings_dir="${project_path}/${DIR_FINDINGS}/${DATA_SUBDIR}"

    [[ ! -d "$findings_dir" ]] && echo "[]" && return

    # Search for source references in findings
    local findings=()
    while IFS= read -r finding_file; do
        [[ ! -f "$finding_file" ]] && continue

        # Check if this finding references the source
        if grep -q "source_id:.*${source_id}" "$finding_file" 2>/dev/null; then
            local finding_id="$(basename "$finding_file" .md)"
            findings+=("$finding_id")
        fi
    done < <(find "$findings_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)

    # Convert to JSON array
    if [[ ${#findings[@]} -eq 0 ]]; then
        echo "[]"
    else
        printf '%s\n' "${findings[@]}" | jq -R . | jq -s .
    fi
}

# BUG-021 FIX: Process all sources and extract metadata (optimized JSON building)
process_sources() {
    local project_path="$1"
    local sources_dir="${project_path}/${DIR_SOURCES}/${DATA_SUBDIR}"

    [[ ! -d "$sources_dir" ]] && error_json "Sources directory not found: $sources_dir" 1

    # Collect all source objects in array first (O(n) instead of O(n²))
    local source_objects_array=()

    while IFS= read -r source_file; do
        [[ ! -f "$source_file" ]] && continue

        # Extract metadata
        local source_id="$(basename "$source_file" .md)"
        local url
        url="$(extract_field "$source_file" "url" | tr -d '\r\t\n')"
        # Validate URL format (basic check)
        if [[ ! "$url" =~ ^https?:// ]]; then
            url=""
        fi
        local name="$(extract_field "$source_file" "name")"
        local created_at="$(extract_field "$source_file" "created_at")"
        local relative_path="${DIR_SOURCES}/$(basename "$source_file")"

        # Skip sources without URL
        [[ -z "$url" ]] && continue

        # Find references
        local refs="$(find_source_references "$project_path" "$source_id")"

        # Build source object
        local source_obj
        source_obj="$(jq -n \
            --arg id "$source_id" \
            --arg path "$relative_path" \
            --arg name "$name" \
            --arg created_at "$created_at" \
            --arg url "$url" \
            --argjson refs "$refs" \
            '{
                id: $id,
                path: $path,
                name: $name,
                created_at: $created_at,
                url: $url,
                finding_references: $refs
            }')"

        # Accumulate in array (O(1) append)
        source_objects_array+=("$source_obj")

    done < <(find "$sources_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)

    # Build JSON array once at end (O(n) instead of O(n²) repeated concatenation)
    if [[ ${#source_objects_array[@]} -eq 0 ]]; then
        echo "[]"
    else
        printf '%s\n' "${source_objects_array[@]}" | jq -s '.'
    fi
}

# Group sources by URL and identify duplicates
analyze_duplicates() {
    local sources_json="$1"
    local project_path="$2"

    # Group by URL and generate duplicate groups
    local duplicate_groups
    duplicate_groups="$(echo "$sources_json" | jq -c '
        group_by(.url) |
        map({
            url: .[0].url,
            source_count: length,
            sources: .
        }) |
        map(select(.source_count > 1)) |
        map(. + {
            canonical: (
                .sources |
                sort_by(.created_at) |
                reverse |
                .[0].id
            ),
            orphaned: (
                .sources |
                map(select(.finding_references | length == 0) | .id)
            )
        })
    ')"

    # Calculate statistics
    local total_sources="$(echo "$sources_json" | jq 'length')"
    local unique_urls="$(echo "$sources_json" | jq 'map(.url) | unique | length')"
    local duplicate_count="$(echo "$duplicate_groups" | jq 'length')"
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Build final report
    jq -n \
        --arg timestamp "$timestamp" \
        --arg project_path "$project_path" \
        --argjson total_sources "$total_sources" \
        --argjson unique_urls "$unique_urls" \
        --argjson duplicate_count "$duplicate_count" \
        --argjson duplicate_groups "$duplicate_groups" \
        '{
            success: true,
            data: {
                timestamp: $timestamp,
                project_path: $project_path,
                total_sources: $total_sources,
                unique_urls: $unique_urls,
                duplicate_count: $duplicate_count,
                duplicate_groups: $duplicate_groups
            }
        }'
}

main() {
    local project_path=""
    local output_file=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                [[ -z "${2:-}" ]] && error_json "Missing value for --project-path" 2
                project_path="$2"
                shift 2
                ;;
            --output)
                [[ -z "${2:-}" ]] && error_json "Missing value for --output" 2
                output_file="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -z "$project_path" ]] && error_json "Missing required argument: --project-path" 2
    [[ ! -d "$project_path" ]] && error_json "Project path not found: $project_path" 1

    # Process sources and analyze duplicates
    local sources_json
    sources_json="$(process_sources "$project_path")"

    local report
    report="$(analyze_duplicates "$sources_json" "$project_path")"

    # Output report
    if [[ -n "$output_file" ]]; then
        echo "$report" > "$output_file"
        echo "Report written to: $output_file" >&2
    else
        echo "$report"
    fi
}

main "$@"
