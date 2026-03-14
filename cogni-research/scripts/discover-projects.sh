#!/usr/bin/env bash
set -euo pipefail
# discover-projects.sh
# Version: 1.3.0
# Purpose: Discover existing research projects and portfolio projects, return metadata as JSON
# Category: extractors
#
# Usage: discover-projects.sh [--research-type <type>] [--search-path <path>] --json
#
# Arguments:
#   --research-type <type>  Filter projects by research type (optional)
#   --search-path <path>    Override search path (optional, can be specified multiple times)
#   --json                  Output results in JSON format (required)
#
# Output (JSON):
#   Success: {
#     "success": true,
#     "projects": [
#       {
#         "name": "project-name",
#         "path": "/absolute/path/to/project",
#         "research_type": "b2b-ict-portfolio",
#         "project_language": "de",
#         "created": "2025-01-15T10:30:00Z"
#       }
#     ],
#     "search_paths": ["/path/searched"],
#     "filter": {"research_type": "b2b-ict-portfolio"} | null
#   }
#   Failure: {
#     "success": false,
#     "error": "Error message",
#     "error_code": 1
#   }
#
# Exit codes:
#   0 - Success (projects discovered or empty array)
#   1 - Error (invalid search path, JSON parsing failure)
#   2 - Invalid arguments
#
# Example:
#   discover-projects.sh --json
#   discover-projects.sh --research-type "b2b-ict-portfolio" --json
#   discover-projects.sh --search-path ~/my-projects --json
#
# Dependencies:
#   - jq (JSON processing)
#   - find (directory scanning)
#
# Environment:
#   COGNI_RESEARCH_ROOT - Primary search path (optional)
#   CLAUDE_PROJECT_DIR  - Secondary search path (optional)
#   DEBUG_MODE          - Enable verbose logging (optional)


# Script metadata
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source enhanced logging (cross-plugin reference with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
    source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
    # Fallback: basic logging functions (|| true prevents exit code 1 with set -e)
    log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
    log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2 || true; }
    log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2 || true; }
fi

# ============================================================================
# ERROR HANDLER
# ============================================================================

error_json() {
    local msg="$1"
    local code="${2:-1}"

    log_conditional "ERROR" "$msg"

    jq -n --arg msg "$msg" \
          --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2

    exit "$code"
}

# ============================================================================
# PROJECT DISCOVERY
# ============================================================================

# Build list of search paths in priority order
get_search_paths() {
    local custom_paths=("$@")
    local paths=()

    # If custom paths provided, use those exclusively
    if [[ ${#custom_paths[@]} -gt 0 ]]; then
        for path in "${custom_paths[@]}"; do
            [[ -d "$path" ]] && paths+=("$path")
        done
        printf '%s\n' "${paths[@]}"
        return
    fi

    # Priority 1: COGNI_RESEARCH_ROOT (set by workplace-manager plugin)
    if [[ -n "${COGNI_RESEARCH_ROOT:-}" ]] && [[ -d "${COGNI_RESEARCH_ROOT}" ]]; then
        paths+=("${COGNI_RESEARCH_ROOT}")
        log_conditional "PATH" "Added COGNI_RESEARCH_ROOT: ${COGNI_RESEARCH_ROOT}"
    fi

    # Priority 2: CLAUDE_PROJECT_DIR (Claude Code runtime working directory)
    if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]] && [[ -d "${CLAUDE_PROJECT_DIR}" ]]; then
        # Avoid duplicates
        local already_added=false
        for p in "${paths[@]}"; do
            [[ "$p" == "${CLAUDE_PROJECT_DIR}" ]] && already_added=true
        done
        if [[ "$already_added" == "false" ]]; then
            paths+=("${CLAUDE_PROJECT_DIR}")
            log_conditional "PATH" "Added CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}"
        fi
    fi

    # Priority 3: Default fallback ~/research-projects/
    local default_path="${HOME}/research-projects"
    if [[ -d "$default_path" ]]; then
        local already_added=false
        for p in "${paths[@]}"; do
            [[ "$p" == "$default_path" ]] && already_added=true
        done
        if [[ "$already_added" == "false" ]]; then
            paths+=("$default_path")
            log_conditional "PATH" "Added default path: $default_path"
        fi
    fi

    # Priority 4: Current working directory (if different from above)
    local cwd
    cwd="$(pwd)"
    local already_added=false
    for p in "${paths[@]}"; do
        [[ "$p" == "$cwd" ]] && already_added=true
    done
    if [[ "$already_added" == "false" ]] && [[ -d "$cwd" ]]; then
        paths+=("$cwd")
        log_conditional "PATH" "Added current directory: $cwd"
    fi

    printf '%s\n' "${paths[@]}"
}

# Extract project metadata from sprint-log.json
extract_project_metadata() {
    local sprint_log="$1"
    local project_path
    project_path="$(cd "$(dirname "$sprint_log")/.." && pwd)"
    local project_name
    project_name="$(basename "$project_path")"

    # Validate JSON file
    if ! jq -e '.' "$sprint_log" > /dev/null 2>&1; then
        log_conditional "WARN" "Invalid JSON in: $sprint_log"
        return 1
    fi

    # Extract fields with fallbacks
    local research_type
    research_type="$(jq -r '.research_type // "generic"' "$sprint_log")"

    local project_language
    project_language="$(jq -r '.project_language // "en"' "$sprint_log")"

    # Try to get creation date from file or metadata
    local created=""
    if jq -e '.created' "$sprint_log" > /dev/null 2>&1; then
        created="$(jq -r '.created' "$sprint_log")"
    elif jq -e '.sprints[0].started_at' "$sprint_log" > /dev/null 2>&1; then
        created="$(jq -r '.sprints[0].started_at' "$sprint_log")"
    else
        # Fallback to file modification time (macOS compatible)
        if [[ "$(uname)" == "Darwin" ]]; then
            created="$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$sprint_log" 2>/dev/null || echo "")"
        else
            created="$(stat -c '%y' "$sprint_log" 2>/dev/null | sed 's/ /T/' | sed 's/\.[0-9]*/Z/' || echo "")"
        fi
    fi

    # Build JSON object
    jq -n \
        --arg name "$project_name" \
        --arg path "$project_path" \
        --arg type "$research_type" \
        --arg lang "$project_language" \
        --arg created "$created" \
        '{
            name: $name,
            path: $path,
            research_type: $type,
            project_language: $lang,
            created: (if $created == "" then null else $created end)
        }'
}

# Extract project metadata from portfolio-mapping-output.json
extract_portfolio_metadata() {
    local portfolio_output="$1"
    local project_path
    project_path="$(cd "$(dirname "$portfolio_output")/.." && pwd)"
    local project_name
    project_name="$(basename "$project_path")"

    # Validate JSON file
    if ! jq -e '.' "$portfolio_output" > /dev/null 2>&1; then
        log_conditional "WARN" "Invalid JSON in: $portfolio_output"
        return 1
    fi

    # Extract fields with fallbacks
    # Portfolio projects are always b2b-ict-portfolio type
    local research_type="b2b-ict-portfolio"

    # Use project_language if present, otherwise default to "en"
    local project_language
    project_language="$(jq -r '.project_language // "en"' "$portfolio_output")"

    # Get creation date from portfolio metadata
    local created=""
    if jq -e '.created' "$portfolio_output" > /dev/null 2>&1; then
        created="$(jq -r '.created' "$portfolio_output")"
    else
        # Fallback to file modification time (macOS compatible)
        if [[ "$(uname)" == "Darwin" ]]; then
            created="$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$portfolio_output" 2>/dev/null || echo "")"
        else
            created="$(stat -c '%y' "$portfolio_output" 2>/dev/null | sed 's/ /T/' | sed 's/\.[0-9]*/Z/' || echo "")"
        fi
    fi

    # Build JSON object
    jq -n \
        --arg name "$project_name" \
        --arg path "$project_path" \
        --arg type "$research_type" \
        --arg lang "$project_language" \
        --arg created "$created" \
        '{
            name: $name,
            path: $path,
            research_type: $type,
            project_language: $lang,
            created: (if $created == "" then null else $created end)
        }'
}

# Discover all projects in a search path
discover_projects_in_path() {
    local search_path="$1"
    local filter_type="${2:-}"

    log_phase "SCAN" "Searching: $search_path"

    local projects="[]"

    # Find all sprint-log.json files (max depth 3 to avoid deep recursion)
    while IFS= read -r sprint_log; do
        [[ -f "$sprint_log" ]] || continue

        log_conditional "FOUND" "Sprint log: $sprint_log"

        # Extract metadata
        local metadata
        if ! metadata="$(extract_project_metadata "$sprint_log")"; then
            continue
        fi

        # Apply filter if specified
        if [[ -n "$filter_type" ]]; then
            local project_type
            project_type="$(echo "$metadata" | jq -r '.research_type')"
            if ! [[ "$project_type" == "$filter_type" ]]; then
                log_conditional "SKIP" "Type mismatch: $project_type != $filter_type"
                continue
            fi
        fi

        # Add to projects array
        projects="$(echo "$projects" | jq --argjson proj "$metadata" '. + [$proj]')"

    done < <(find "$search_path" -maxdepth 5 -path "*/.metadata/sprint-log.json" -type f 2>/dev/null || true)

    # Find all portfolio-mapping-output.json files (portfolio projects)
    while IFS= read -r portfolio_output; do
        [[ -f "$portfolio_output" ]] || continue

        log_conditional "FOUND" "Portfolio output: $portfolio_output"

        # Extract metadata from portfolio format
        local metadata
        if ! metadata="$(extract_portfolio_metadata "$portfolio_output")"; then
            continue
        fi

        # Apply filter if specified
        if [[ -n "$filter_type" ]]; then
            local project_type
            project_type="$(echo "$metadata" | jq -r '.research_type')"
            if ! [[ "$project_type" == "$filter_type" ]]; then
                log_conditional "SKIP" "Type mismatch: $project_type != $filter_type"
                continue
            fi
        fi

        # Add to projects array (will be deduplicated later by path)
        projects="$(echo "$projects" | jq --argjson proj "$metadata" '. + [$proj]')"

    done < <(find "$search_path" -maxdepth 5 -path "*/.metadata/portfolio-mapping-output.json" -type f 2>/dev/null || true)

    echo "$projects"
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    log_phase "START" "Research project discovery"

    local filter_type=""
    local custom_paths=()
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --research-type)
                filter_type="${2:-}"
                [[ -z "$filter_type" ]] && error_json "Missing value for --research-type" 2
                shift 2
                ;;
            --search-path)
                local path="${2:-}"
                [[ -z "$path" ]] && error_json "Missing value for --search-path" 2
                custom_paths+=("$path")
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate --json is required
    if ! [[ "$json_output" == "true" ]]; then
        error_json "Usage: $0 [--research-type <type>] [--search-path <path>] --json" 2
    fi

    # Get search paths
    local search_paths_array=()
    while IFS= read -r path; do
        [[ -n "$path" ]] && search_paths_array+=("$path")
    done < <(get_search_paths "${custom_paths[@]}")

    if [[ ${#search_paths_array[@]} -eq 0 ]]; then
        # No search paths found - return empty result
        log_conditional "WARN" "No valid search paths found"

        local filter_json="null"
        if [[ -n "$filter_type" ]]; then
            filter_json="$(jq -n --arg type "$filter_type" '{research_type: $type}')"
        fi

        jq -n \
            --argjson filter "$filter_json" \
            '{
                success: true,
                projects: [],
                search_paths: [],
                filter: $filter
            }'
        exit 0
    fi

    # Discover projects in all search paths
    local all_projects="[]"
    local searched_paths="[]"

    for search_path in "${search_paths_array[@]}"; do
        searched_paths="$(echo "$searched_paths" | jq --arg p "$search_path" '. + [$p]')"

        local projects
        projects="$(discover_projects_in_path "$search_path" "$filter_type")"

        # Merge projects (deduplicate by path)
        all_projects="$(jq -n \
            --argjson existing "$all_projects" \
            --argjson new "$projects" \
            '($existing + $new) | unique_by(.path)')"
    done

    # Sort by name
    all_projects="$(echo "$all_projects" | jq 'sort_by(.name)')"

    # Build filter object
    local filter_json="null"
    if [[ -n "$filter_type" ]]; then
        filter_json="$(jq -n --arg type "$filter_type" '{research_type: $type}')"
    fi

    # Count results
    local project_count
    project_count="$(echo "$all_projects" | jq 'length')"

    log_metric "projects_found" "$project_count" "count"

    # Output final JSON
    jq -n \
        --argjson projects "$all_projects" \
        --argjson paths "$searched_paths" \
        --argjson filter "$filter_json" \
        '{
            success: true,
            projects: $projects,
            search_paths: $paths,
            filter: $filter
        }'

    log_phase "COMPLETE" "Project discovery successful"
}

main "$@"
