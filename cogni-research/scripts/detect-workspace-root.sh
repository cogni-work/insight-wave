#!/usr/bin/env bash
set -euo pipefail
# detect-workspace-root.sh
# Version: 1.0.0
# Purpose: Auto-detect Obsidian vault root from project path using multi-strategy detection
# Category: utilities
#
# Usage: detect-workspace-root.sh --project-path <path>
#
# Arguments:
#   --project-path <path>    Absolute filesystem path to research project (required)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "workspace_root": "/absolute/path/to/vault",
#       "mode": "multi-project|single-project",
#       "detection_method": "environment_variable|obsidian_marker|fallback"
#     },
#     "error": "error message" (if success=false)
#   }
#
# Detection Strategies (in order):
#   1. Environment variable: OBSIDIAN_VAULT_ROOT
#   2. Directory traversal: Find .obsidian directory marker
#   3. Fallback: Use project path (single-project mode)
#
# Exit codes:
#   0 - Success (both single-project and multi-project are valid)
#   1 - Validation error (project path doesn't exist)
#   2 - Invalid arguments (missing required parameters)
#
# Example:
#   detect-workspace-root.sh --project-path /vault/research/project-1


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

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1. Usage: $0 --project-path <path>" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2

    # SECURITY FIX (BUG-006): Resolve to canonical path and validate
    if [[ -e "$project_path" ]]; then
        # Use readlink if available, fallback to realpath pattern
        if command -v realpath &>/dev/null; then
            project_path="$(realpath "$project_path" 2>/dev/null || echo "$project_path")"
        elif command -v readlink &>/dev/null; then
            # Try GNU readlink first
            if readlink -f "$project_path" &>/dev/null; then
                project_path="$(readlink -f "$project_path")"
            # Fall back to BSD readlink
            elif [[ "$(uname)" == "Darwin" ]] && cd "$(dirname "$project_path")" 2>/dev/null; then
                project_path="$(pwd -P)/$(basename "$project_path")"
                cd - >/dev/null
            fi
        fi
    else
        error_json "Project path does not exist: $project_path" 1
    fi

    # SECURITY FIX (BUG-006): Validate no traversal sequences remain
    if [[ "$project_path" == *".."* ]]; then
        error_json "Invalid path: contains directory traversal" 1
    fi

    # Detect workspace root using multi-strategy approach
    local workspace_root=""
    local detection_method=""
    local mode=""

    # Strategy 1: Check OBSIDIAN_VAULT_ROOT environment variable
    if [[ -n "${OBSIDIAN_VAULT_ROOT:-}" ]]; then
        workspace_root="${OBSIDIAN_VAULT_ROOT}"
        detection_method="environment_variable"

        # Determine mode: compare workspace_root with project_path
        if [[ "$workspace_root" == "$project_path" ]]; then
            mode="single-project"
        else
            mode="multi-project"
        fi
    else
        # Strategy 2: Traverse up directory tree to find .obsidian marker
        local current_dir="$project_path"
        local found_obsidian=false

        # Traverse up to root, checking each directory
        while ! [[ "$current_dir" == "/" ]]; do
            if [[ -d "$current_dir/.obsidian" ]]; then
                workspace_root="$current_dir"
                detection_method="obsidian_marker"
                mode="multi-project"
                found_obsidian=true
                break
            fi
            current_dir="$(dirname "$current_dir")"
        done

        # Strategy 3: Fallback to project path (single-project mode)
        if [[ "$found_obsidian" == false ]]; then
            workspace_root="$project_path"
            detection_method="fallback"
            mode="single-project"
        fi
    fi

    # Success output with structured JSON
    jq -n \
        --arg workspace_root "$workspace_root" \
        --arg mode "$mode" \
        --arg detection_method "$detection_method" \
        '{
            success: true,
            data: {
                workspace_root: $workspace_root,
                mode: $mode,
                detection_method: $detection_method
            }
        }'
}

# Execute main function
main "$@"
