#!/usr/bin/env bash
set -euo pipefail
# validate-outputs.sh
# Version: 1.0.0
# Purpose: Validate final dimension/question counts and FINER score against thresholds
# Category: validators
#
# Usage: validate-outputs.sh --dimensions <number> --questions <number> --avg-finer <float> [--research-type <type>] --json
#
# Arguments:
#   --dimensions <number>      Dimension count (required, must be 2-10)
#   --questions <number>       Question count (required, varies by research type)
#   --avg-finer <float>        Average FINER score (required, must be >= 11.0)
#   --research-type <type>     Research type (optional: generic, smarter-service, lean-canvas, b2b-ict-portfolio)
#   --json                     Output in JSON format (required)
#
# Research-Type-Specific Question Constraints:
#   generic:           8-50 questions (default)
#   smarter-service:   exactly 52 questions (4 dimensions × (5 ACT + 5 PLAN + 3 OBSERVE))
#   lean-canvas:       8-50 questions
#   b2b-ict-portfolio: exactly 57 questions (1 per taxonomy category, 8 dimensions 0-7)
#
# Output (JSON):
#   Success:
#   {
#     "success": true,
#     "dimensions": number,
#     "questions": number,
#     "avg_finer_score": float,
#     "validation_passed": true
#   }
#
#   Failure:
#   {
#     "success": false,
#     "error": "description",
#     "validation": "field_name",
#     "constraint": "constraint_description",
#     "received": value
#   }
#
# Exit codes:
#   0 - Validation passed
#   1 - Validation failed (constraint violated)
#
# Examples:
#   validate-outputs.sh --dimensions 4 --questions 14 --avg-finer 13.1 --json
#   validate-outputs.sh --dimensions 4 --questions 52 --avg-finer 12.5 --research-type smarter-service --json
#   validate-outputs.sh --dimensions 8 --questions 57 --avg-finer 11.5 --research-type b2b-ict-portfolio --json


# =============================================================================
# Resolve Plugin Root (handles monorepo and direct installs)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source resolve utility if available, otherwise use inline resolution
if [[ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/resolve-plugin-root.sh" ]]; then
    source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/resolve-plugin-root.sh"
    CLAUDE_PLUGIN_ROOT="$(resolve_plugin_root)"
else
    # Fallback: derive from script location (scripts -> dimension-planner -> skills -> plugin root)
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

# Error handler for validation failures
validation_error() {
    local error_msg="$1"
    local validation_field="$2"
    local constraint="$3"
    local received="$4"

    jq -n \
        --arg err "$error_msg" \
        --arg field "$validation_field" \
        --arg constraint "$constraint" \
        --arg recv "$received" \
        '{
            success: false,
            error: $err,
            validation: $field,
            constraint: $constraint,
            received: $recv
        }' >&2
    exit 1
}

# Error handler for script errors
error_json() {
    local message="$1"
    jq -n --arg msg "$message" \
        '{success: false, error: $msg}' >&2
    exit 1
}

# Validate integer parameter
is_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

# Validate numeric parameter (float)
is_numeric() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]] || [[ "$value" =~ ^[0-9]*\.[0-9]+$ ]]
}

# Main validation function
main() {
    local dimensions=""
    local questions=""
    local avg_finer=""
    local research_type="generic"
    local json_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dimensions)
                dimensions="${2:-}"
                shift 2
                ;;
            --questions)
                questions="${2:-}"
                shift 2
                ;;
            --avg-finer)
                avg_finer="${2:-}"
                shift 2
                ;;
            --research-type)
                research_type="${2:-generic}"
                shift 2
                ;;
            --json)
                json_flag=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1"
                ;;
        esac
    done

    # Check required parameters
    [[ -n "$dimensions" ]] || error_json "Missing required parameter: --dimensions"
    [[ -n "$questions" ]] || error_json "Missing required parameter: --questions"
    [[ -n "$avg_finer" ]] || error_json "Missing required parameter: --avg-finer"
    [[ "$json_flag" = true ]] || error_json "Missing required flag: --json"

    log_phase "Output Validation" "start"
    log_conditional "DEBUG" "Validating dimensions=${dimensions}, questions=${questions}, avg_finer=${avg_finer}"

    log_conditional "DEBUG" "Checking dimension count range (2-10)"
    # Validate dimension count is integer
    if ! is_integer "$dimensions"; then
        validation_error \
            "Invalid dimension count: $dimensions (must be integer)" \
            "dimensions" \
            "Must be integer 2-10" \
            "$dimensions"
    fi

    # Validate dimension count range
    if [[ "$dimensions" -lt 2 ]] || [[ "$dimensions" -gt 10 ]]; then
        validation_error \
            "Invalid dimension count: $dimensions" \
            "dimensions" \
            "Must be 2-10 dimensions" \
            "$dimensions"
    fi

    # Validate question count is integer
    if ! is_integer "$questions"; then
        validation_error \
            "Invalid question count: $questions (must be integer)" \
            "questions" \
            "Must be integer" \
            "$questions"
    fi

    # Research-type-specific question count validation
    log_conditional "DEBUG" "Checking question count for research_type=${research_type}"
    case "$research_type" in
        smarter-service)
            # smarter-service requires exactly 52 questions (4 dimensions × (5 ACT + 5 PLAN + 3 OBSERVE))
            if [[ "$questions" -ne 52 ]]; then
                validation_error \
                    "Invalid question count for smarter-service: $questions" \
                    "questions" \
                    "smarter-service requires exactly 52 questions (4 dimensions × (5 ACT + 5 PLAN + 3 OBSERVE))" \
                    "$questions"
            fi
            log_conditional "DEBUG" "smarter-service: 52 questions validated"
            ;;
        b2b-ict-portfolio)
            # b2b-ict-portfolio requires exactly 57 questions (1 per taxonomy category, 8 dimensions 0-7)
            if [[ "$questions" -ne 57 ]]; then
                validation_error \
                    "Invalid question count for b2b-ict-portfolio: $questions" \
                    "questions" \
                    "b2b-ict-portfolio requires exactly 57 questions (1 per taxonomy category, 8 dimensions 0-7)" \
                    "$questions"
            fi
            log_conditional "DEBUG" "b2b-ict-portfolio: 57 questions validated"
            ;;
        generic|lean-canvas|*)
            # Default: 8-50 questions
            if [[ "$questions" -lt 8 ]] || [[ "$questions" -gt 50 ]]; then
                validation_error \
                    "Invalid question count: $questions" \
                    "questions" \
                    "Must be 8-50 questions" \
                    "$questions"
            fi
            log_conditional "DEBUG" "generic/lean-canvas: 8-50 questions validated"
            ;;
    esac

    log_conditional "DEBUG" "Checking average FINER score threshold (>= 11.0)"
    # Validate FINER score is numeric
    if ! is_numeric "$avg_finer"; then
        validation_error \
            "Invalid FINER score: $avg_finer (must be numeric)" \
            "avg_finer_score" \
            "Must be numeric >= 11.0" \
            "$avg_finer"
    fi

    # Check bc availability
    if ! command -v bc &>/dev/null; then
        error_json "bc command not available (required for float comparison)"
    fi

    # Validate FINER score threshold (>= 11.0)
    if (( $(echo "$avg_finer < 11.0" | bc -l) )); then
        validation_error \
            "Average FINER score below threshold: $avg_finer" \
            "avg_finer_score" \
            "Must be >= 11.0" \
            "$avg_finer"
    fi

    log_phase "Output Validation" "complete"
    log_conditional "INFO" "All validation thresholds passed (research_type=${research_type})"
    log_metric "dimensions_validated" "${dimensions}" "count"
    log_metric "questions_validated" "${questions}" "count"
    log_metric "avg_finer_validated" "${avg_finer}" "score"
    log_metric "research_type" "${research_type}" "type"

    # All validations passed
    jq -n \
        --argjson dims "$dimensions" \
        --argjson qs "$questions" \
        --argjson finer "$avg_finer" \
        --arg rt "$research_type" \
        '{
            success: true,
            dimensions: $dims,
            questions: $qs,
            avg_finer_score: $finer,
            research_type: $rt,
            validation_passed: true
        }'
}

# Execute main function
main "$@"
