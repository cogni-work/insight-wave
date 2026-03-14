#!/usr/bin/env bash
set -euo pipefail
# validate-part1-completion.sh
# Version: 1.0.0
# Purpose: Validate that Part 1 (deeper-analysis) completed successfully
#
# Usage:
#   validate-part1-completion.sh --project-path <path> [OPTIONS]
#
# Arguments:
#   --project-path <path>    Path to research project (required)
#   --json                   Output results in JSON format
#
# Returns:
#   JSON: {
#     "success": true|false,
#     "part1_complete": true|false,
#     "missing_directories": [],
#     "entity_counts": {},
#     "warnings": [],
#     "error": "..."
#   }
#
# Exit codes:
#   0 - Part 1 complete and valid
#   1 - Part 1 incomplete or invalid
#   2 - Invalid arguments


# Dependency checks
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 2
fi

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized entity configuration
source "${SCRIPT_DIR}/lib/entity-config.sh"
DATA_SUBDIR="$(get_data_subdir)"
DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_SOURCES="$(get_directory_by_key "sources")"

# Required directories for Part 1 completion (indices 0-9 from entity-schema.json)
# Bash 3.2 compatible array loading (mapfile requires Bash 4.0+)
REQUIRED_DIRS=()
while IFS= read -r dir; do
    REQUIRED_DIRS+=("$dir")
done < <(get_entity_dirs_array | head -10)
readonly REQUIRED_DIRS

# Parse arguments
PROJECT_PATH=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# Validation
if [[ -z "$PROJECT_PATH" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --project-path" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --project-path" >&2
    fi
    exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Project path does not exist: $PROJECT_PATH" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Project path does not exist: $PROJECT_PATH" >&2
    fi
    exit 1
fi

# Check for required directories
missing_dirs=()
entity_counts=()
warnings=()

for dir in "${REQUIRED_DIRS[@]}"; do
    dir_path="${PROJECT_PATH}/${dir}"
    if [[ ! -d "$dir_path" ]]; then
        missing_dirs+=("$dir")
    else
        # Count entities (markdown files) in data/ subdirectory
        count="$(find "$dir_path/${DATA_SUBDIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
        entity_counts+=("\"$dir\": $count")
    fi
done

# Check sprint-log.json for completion marker
sprint_log="${PROJECT_PATH}/.metadata/sprint-log.json"
has_completion_marker=false

if [[ -f "$sprint_log" ]]; then
    if jq -e '.part1_complete == true' "$sprint_log" > /dev/null 2>&1; then
        has_completion_marker=true
    else
        warnings+=("sprint-log.json does not have part1_complete marker")
    fi
else
    warnings+=("sprint-log.json not found at ${sprint_log}")
fi

# Determine overall success
success=true
if [[ ${#missing_dirs[@]} -gt 0 ]]; then
    success=false
fi

# Check for minimum entity counts
if [[ "$success" == true ]]; then
    # Verify critical directories have entities (in data/ subdirectory)
    findings_count="$(find "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    sources_count="$(find "${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

    if [[ $findings_count -lt 10 ]]; then
        warnings+=("Low finding count: $findings_count (expected 100+)")
    fi
    if [[ $sources_count -lt 5 ]]; then
        warnings+=("Low source count: $sources_count (expected 50+)")
    fi
fi

# Output results
if [[ "$JSON_OUTPUT" == true ]]; then
    # Build entity counts JSON object
    entity_counts_json="{"
    first=true
    for count_entry in "${entity_counts[@]}"; do
        if [[ "$first" == true ]]; then
            entity_counts_json+="$count_entry"
            first=false
        else
            entity_counts_json+=", $count_entry"
        fi
    done
    entity_counts_json+="}"

    # Build missing directories JSON array
    missing_json="$(printf '%s\n' "${missing_dirs[@]:-}" | jq -R . | jq -s .)"

    # Build warnings JSON array
    warnings_json="$(printf '%s\n' "${warnings[@]:-}" | jq -R . | jq -s .)"

    jq -n \
        --argjson success "$success" \
        --argjson part1_complete "$has_completion_marker" \
        --argjson missing "$missing_json" \
        --argjson counts "$entity_counts_json" \
        --argjson warnings "$warnings_json" \
        '{
            success: $success,
            part1_complete: $part1_complete,
            missing_directories: $missing,
            entity_counts: $counts,
            warnings: $warnings
        }'
else
    if [[ "$success" == true ]]; then
        echo "Part 1 validation: PASSED"
        echo "Part 1 completion marker: $has_completion_marker"
        echo "Entity directories: ${#entity_counts[@]} found"
    else
        echo "Part 1 validation: FAILED"
        echo "Missing directories: ${missing_dirs[*]}"
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "Warnings:"
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
    fi
fi

# Exit with appropriate code
if [[ "$success" == true ]]; then
    exit 0
else
    exit 1
fi
