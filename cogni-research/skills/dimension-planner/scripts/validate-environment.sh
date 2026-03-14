#!/usr/bin/env bash
set -euo pipefail
#
# validate-environment.sh
# Version: 1.0.1
#
# Purpose: Validate CLAUDE_PLUGIN_ROOT, working directory, and required
#          dependencies (jq, bc) for dimension-planner skill execution.
#
# Usage:
#   bash validate-environment.sh --project-path <path> --json
#
# Arguments:
#   --project-path <path>    Absolute path to project directory (required)
#   --json                   Output JSON format (required)
#
# Output:
#   JSON object with structure:
#   {
#     "success": <boolean>,
#     "data": {
#       "claude_plugin_root": <string>,
#       "project_path": <string>,
#       "dependencies_ok": <boolean>
#     },
#     "error": <string>    (only if success=false)
#   }
#
# Exit codes:
#   0 - All validations passed
#   1 - Validation failure (CLAUDE_PLUGIN_ROOT, project-path, or dependencies)
#   2 - Invalid arguments (missing required parameters)
#
# Example:
#   bash validate-environment.sh \
#     --project-path "/path/to/project" \
#     --json


# =============================================================================
# Resolve Plugin Root (handles monorepo and direct installs)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source resolve utility if available, otherwise use inline resolution
if [[ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/resolve-plugin-root.sh" ]]; then
    source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/resolve-plugin-root.sh"
    CLAUDE_PLUGIN_ROOT="$(resolve_plugin_root)"
else
    # Fallback: derive from script location (scripts/validate-environment.sh -> skills/dimension-planner/scripts -> plugin root)
    CLAUDE_PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
fi
export CLAUDE_PLUGIN_ROOT

# =============================================================================
# Enhanced Logging Integration
# =============================================================================

# Source enhanced logging (with fallback)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
    source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
    # Fallback: basic logging functions
    log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2; }
    log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2; }
    log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2; }
fi

# =============================================================================
# Error Handling
# =============================================================================

error_json() {
    local message="$1"
    local hint="${2:-}"
    local code="${3:-1}"

    if [[ -n "$hint" ]]; then
        jq -n \
            --arg msg "$message" \
            --arg h "$hint" \
            '{success: false, error: $msg, hint: $h}' >&2
    else
        jq -n \
            --arg msg "$message" \
            '{success: false, error: $msg}' >&2
    fi

    exit "$code"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    local project_path=""
    local json_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                [[ -n "${2:-}" ]] || error_json "Missing value for --project-path" "" 2
                project_path="$2"
                shift 2
                ;;
            --json)
                json_flag=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" "Usage: $0 --project-path <path> --json" 2
                ;;
        esac
    done

    # Validate required arguments
    [[ "$json_flag" == true ]] || \
        error_json "Missing required flag: --json" "Usage: $0 --project-path <path> --json" 2

    [[ -n "$project_path" ]] || \
        error_json "Missing required parameter: --project-path" "Usage: $0 --project-path <path> --json" 2

    log_phase "Environment Validation" "start"

    # =============================================================================
    # Validation 1: CLAUDE_PLUGIN_ROOT
    # =============================================================================

    log_conditional "DEBUG" "Validating CLAUDE_PLUGIN_ROOT"

    if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        error_json \
            "CLAUDE_PLUGIN_ROOT not set" \
            "Set CLAUDE_PLUGIN_ROOT environment variable to plugin installation directory" \
            1
    fi

    if [[ ! -d "$CLAUDE_PLUGIN_ROOT" ]]; then
        error_json \
            "CLAUDE_PLUGIN_ROOT directory does not exist: $CLAUDE_PLUGIN_ROOT" \
            "Verify CLAUDE_PLUGIN_ROOT points to valid plugin directory" \
            1
    fi

    local utils_dir="$CLAUDE_PLUGIN_ROOT/scripts/utils"
    if [[ ! -d "$utils_dir" ]]; then
        error_json \
            "Required directory not found: $utils_dir" \
            "CLAUDE_PLUGIN_ROOT must contain scripts/utils/" \
            1
    fi

    log_conditional "INFO" "CLAUDE_PLUGIN_ROOT validation passed"

    # =============================================================================
    # Validation 2: Project Path
    # =============================================================================

    log_conditional "DEBUG" "Validating project path"

    if [[ ! -e "$project_path" ]]; then
        error_json \
            "Project path does not exist: $project_path" \
            "Provide valid absolute path to project directory" \
            1
    fi

    if [[ ! -d "$project_path" ]]; then
        error_json \
            "Project path is not a directory: $project_path" \
            "Project path must be a directory" \
            1
    fi

    local question_dir="$project_path/00-initial-question"
    if [[ ! -d "$question_dir" ]]; then
        error_json \
            "Required directory not found: $question_dir" \
            "Project directory must contain 00-initial-question/ subdirectory" \
            1
    fi

    log_conditional "INFO" "Project path validation passed"

    # =============================================================================
    # Validation 3: Dependencies
    # =============================================================================

    log_conditional "DEBUG" "Validating dependencies"

    if ! command -v jq &>/dev/null; then
        error_json \
            "jq command required for JSON processing" \
            "Install jq: brew install jq (macOS) or apt-get install jq (Linux)" \
            1
    fi

    if ! command -v bc &>/dev/null; then
        error_json \
            "bc command required for score validation" \
            "Install bc: brew install bc (macOS) or apt-get install bc (Linux)" \
            1
    fi

    log_conditional "INFO" "Dependencies validation passed"

    # =============================================================================
    # Success Output
    # =============================================================================

    log_phase "Environment Validation" "complete"
    log_metric "validation_status" "success" "boolean"

    jq -n \
        --arg plugin_root "$CLAUDE_PLUGIN_ROOT" \
        --arg proj_path "$project_path" \
        '{
            success: true,
            data: {
                claude_plugin_root: $plugin_root,
                project_path: $proj_path,
                dependencies_ok: true
            }
        }'

    exit 0
}

main "$@"
