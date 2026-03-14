#!/usr/bin/env bash
set -euo pipefail
#
# log-execution-context.sh
#
# Purpose: Capture execution environment details for debugging and reproducibility
#
# Usage:
#   # Standalone invocation (returns JSON):
#   bash log-execution-context.sh --project-path <path> --agent-name <name> --json
#
#   # Sourceable (sets EXECUTION_CONTEXT_JSON variable):
#   source log-execution-context.sh
#   log_execution_context --project-path <path> --agent-name <name>
#
# Arguments:
#   --project-path <path>    Path to project directory (required)
#   --agent-name <string>    Name of executing agent (required)
#   --json                   Output JSON to stdout (optional, for standalone mode)
#
# Output:
#   JSON structure with execution context:
#   {
#     "success": true,
#     "timestamp": "2025-11-08T20:00:00Z",
#     "environment": {
#       "claude_plugin_root": "/path/to/plugins",
#       "debug_mode": "true",
#       "hostname": "machine.local",
#       "bash_version": "3.2.57",
#       "working_directory": "/path/to/workspace"
#     },
#     "execution": {
#       "project_path": "/path/to/project",
#       "agent_name": "source-creator"
#     },
#     "git": {
#       "commit": "abc123",
#       "branch": "main",
#       "available": true
#     }
#   }
#
# Exit Codes:
#   0 - Success
#   1 - Validation error (missing required parameters)
#   2 - Invalid arguments
#
# Example:
#   bash log-execution-context.sh \
#     --project-path /path/to/project \
#     --agent-name source-creator \
#     --json


# Error handler for structured JSON output
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n \
        --arg error "$msg" \
        --argjson error_code "$code" \
        '{success: false, error: $error, error_code: $error_code}' >&2
    exit "$code"
}

# Get git information from current directory
get_git_info() {
    local git_available="false"
    local git_commit="not-available"
    local git_branch="not-available"

    if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
        git_available="true"
        git_commit="$(git rev-parse HEAD 2>/dev/null || echo "not-available")"
        git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "not-available")"
    fi

    jq -n \
        --arg commit "$git_commit" \
        --arg branch "$git_branch" \
        --argjson available "$git_available" \
        '{
            commit: $commit,
            branch: $branch,
            available: $available
        }'
}

# Main function that can be called directly or sourced
log_execution_context() {
    local project_path=""
    local agent_name=""
    local output_json="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="${2:-}"
                [[ -n "$project_path" ]] || error_json "Missing value for --project-path" 2
                shift 2
                ;;
            --agent-name)
                agent_name="${2:-}"
                [[ -n "$agent_name" ]] || error_json "Missing value for --agent-name" 2
                shift 2
                ;;
            --json)
                output_json="true"
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 1
    [[ -n "$agent_name" ]] || error_json "Missing required argument: --agent-name" 1

    # Gather environment information
    local claude_plugin_root="${CLAUDE_PLUGIN_ROOT:-not-set}"
    local debug_mode="${DEBUG_MODE:-false}"
    local hostname_value
    hostname_value="$(hostname 2>/dev/null || echo "unknown")"
    local bash_version="${BASH_VERSION}"
    local working_dir
    working_dir="$(pwd)"
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Get git information
    local git_json
    git_json="$(get_git_info)"

    # Construct complete execution context JSON
    local context_json
    context_json="$(jq -n \
        --arg timestamp "$timestamp" \
        --arg claude_plugin_root "$claude_plugin_root" \
        --arg debug_mode "$debug_mode" \
        --arg hostname "$hostname_value" \
        --arg bash_version "$bash_version" \
        --arg working_directory "$working_dir" \
        --arg project_path "$project_path" \
        --arg agent_name "$agent_name" \
        --argjson git "$git_json" \
        '{
            success: true,
            timestamp: $timestamp,
            environment: {
                claude_plugin_root: $claude_plugin_root,
                debug_mode: $debug_mode,
                hostname: $hostname,
                bash_version: $bash_version,
                working_directory: $working_directory
            },
            execution: {
                project_path: $project_path,
                agent_name: $agent_name
            },
            git: $git
        }')"

    # Output based on mode
    if [[ "$output_json" == "true" ]]; then
        # Standalone mode: output to stdout
        echo "$context_json"
    else
        # Sourceable mode: set variable
        EXECUTION_CONTEXT_JSON="$context_json"
        export EXECUTION_CONTEXT_JSON
    fi
}

# If script is executed directly (not sourced), run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_execution_context "$@"
fi
