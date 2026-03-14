#!/usr/bin/env bash
set -euo pipefail
# validate-working-directory.sh
# Version: 1.1.0
# Purpose: Validates working directory setup and CLAUDE_PLUGIN_ROOT environment variable
# Category: utilities
#
# Usage: validate-working-directory.sh --project-path <path> [--json]
#
# Arguments:
#   --project-path <path>    Path to project directory (required)
#   --json                   Enable JSON-only output mode (optional, default: true)
#
# Output: JSON object with structure:
#   {
#     "success": true|false,
#     "data": {
#       "message": "<success message>",
#       "project_path": "<validated path>"
#     },
#     "error": "<error message>" (only if success=false)
#   }
#
# Exit Codes:
#   0 - Validation successful, directory changed to project path
#   1 - Validation failed (environment variable not set, CLAUDE_PLUGIN_ROOT directory not found, project directory not found, cd failed)
#   2 - Invalid arguments (missing required parameter)
#
# Example:
#   validate-working-directory.sh --project-path /path/to/project
#   Returns: {"success": true, "data": {"message": "Working directory validation successful", "project_path": "/path/to/project"}}


# Error output function - returns structured JSON error
error_json() {
    local error_message="$1"
    local exit_code="${2:-1}"

    jq -n \
        --arg error "$error_message" \
        '{
            success: false,
            error: $error
        }' >&2

    exit "$exit_code"
}

# Main validation logic
main() {
    local project_path=""
    local json_mode="true"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                if [[ $# -lt 2 ]] || [[ "$2" == --* ]]; then
                    error_json "Missing value for --project-path" 2
                fi
                project_path="$2"
                shift 2
                ;;
            --json)
                json_mode="true"
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Step 1: Validate CLAUDE_PLUGIN_ROOT exists and is not empty
    if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        error_json "CLAUDE_PLUGIN_ROOT environment variable not set. Please configure: export CLAUDE_PLUGIN_ROOT=/path/to/cogni-research" 1
    fi

    # Step 1a: Validate CLAUDE_PLUGIN_ROOT directory exists
    if [[ ! -d "$CLAUDE_PLUGIN_ROOT" ]]; then
        error_json "CLAUDE_PLUGIN_ROOT directory does not exist: $CLAUDE_PLUGIN_ROOT. Verify path in settings.local.json" 1
    fi

    # Step 2: Validate PROJECT_PATH parameter exists and is not empty
    if [[ -z "$project_path" ]]; then
        error_json "Missing required parameter: --project-path" 2
    fi

    # SECURITY FIX (BUG-006): Canonicalize and validate path for traversal
    # Use readlink/realpath if available to resolve symlinks and canonicalize
    if command -v realpath >/dev/null 2>&1; then
        project_path="$(realpath "$project_path" 2>/dev/null || echo "$project_path")"
    elif command -v readlink >/dev/null 2>&1; then
        # Try GNU readlink first
        if readlink -f "$project_path" >/dev/null 2>&1; then
            project_path="$(readlink -f "$project_path")"
        # Fall back to BSD readlink (macOS)
        elif [[ -e "$project_path" ]] && cd "$(dirname "$project_path")" 2>/dev/null; then
            project_path="$(pwd -P)/$(basename "$project_path")"
            cd - >/dev/null
        fi
    fi

    # Validate path doesn't contain directory traversal sequences
    if [[ "$project_path" == *".."* ]]; then
        error_json "Invalid path: contains directory traversal" 1
    fi

    # Step 3: Verify directory exists at PROJECT_PATH
    if [[ ! -d "$project_path" ]]; then
        error_json "Project directory not found: $project_path" 1
    fi

    # Step 4: Change working directory to PROJECT_PATH
    if ! cd "$project_path" 2>/dev/null; then
        error_json "Failed to change to project directory: $project_path" 1
    fi

    # Step 5: Return success
    jq -n \
        --arg message "Working directory validation successful" \
        --arg project_path "$project_path" \
        '{
            success: true,
            data: {
                message: $message,
                project_path: $project_path
            }
        }'

    exit 0
}

main "$@"
