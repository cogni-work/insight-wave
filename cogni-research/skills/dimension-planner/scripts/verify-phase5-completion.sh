#!/usr/bin/env bash
set -euo pipefail
# verify-phase5-completion.sh
# Version: 1.0.1
# Purpose: Validate Phase 5 entity creation by counting actual files and comparing to expected counts
# Category: validators
# Changelog: v1.0.1 - Fixed dimension file pattern from "*.md" to "dimension-*.md" to prevent false positives
#
# Usage:
#   verify-phase5-completion.sh --project-path <path> --dimensions-count <n> --questions-count <n> --json [--check-readmes]
#
# Arguments:
#   --project-path <path>        Absolute path to research project directory (required)
#   --dimensions-count <number>  Expected number of dimension files (required)
#   --questions-count <number>   Expected number of question files (required)
#   --json                       Output JSON format (required)
#   --check-readmes              Optional: Also verify provenance READMEs exist
#
# Output:
#   Success: {success: true, dimensions_verified: N, questions_verified: N, timestamp: "ISO8601"}
#   Failure: {success: false, error: "verification_failed", expected: {...}, actual: {...}, missing: {...}, details: "...", timestamp: "ISO8601"}
#   Error: {success: false, error: "error_type", details: "...", timestamp: "ISO8601"}
#
# Exit codes:
#   0 - Verification passed (actual counts match expected)
#   1 - Verification failed (actual counts DO NOT match expected)
#   2 - Invalid parameters or missing directories
#
# Example:
#   verify-phase5-completion.sh \
#     --project-path /path/to/project \
#     --dimensions-count 4 \
#     --questions-count 24 \
#     --json


# Source enhanced logging (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging functions
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2; }
fi

# Initialize logging
LOG_FILE="${PROJECT_PATH:-/tmp}/.metadata/verify-phase5-completion.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log_phase "1" "Script initialization"
log_conditional "INFO" "verify-phase5-completion.sh v1.0.1 starting"
log_conditional "DEBUG" "DEBUG_MODE=${DEBUG_MODE:-false}"

###################
# Helper Functions
###################

error_json() {
    local error_type="$1"
    local details="$2"
    local exit_code="${3:-2}"
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    log_conditional "ERROR" "Error: $error_type - $details (exit code: $exit_code)"

    jq -n \
        --arg error "$error_type" \
        --arg details "$details" \
        --arg timestamp "$timestamp" \
        '{
            success: false,
            error: $error,
            details: $details,
            timestamp: $timestamp
        }' >&2

    exit "$exit_code"
}

usage() {
    cat >&2 <<EOF
Usage: verify-phase5-completion.sh --project-path <path> --dimensions-count <n> --questions-count <n> --json [--check-readmes]

Required Arguments:
  --project-path <path>        Absolute path to research project directory
  --dimensions-count <number>  Expected number of dimension files
  --questions-count <number>   Expected number of question files
  --json                       Output JSON format

Optional Arguments:
  --check-readmes              Also verify provenance READMEs exist and are valid

Exit Codes:
  0 - Verification passed (actual counts match expected)
  1 - Verification failed (actual counts DO NOT match expected)
  2 - Invalid parameters or missing directories

Example:
  verify-phase5-completion.sh \\
    --project-path /path/to/project \\
    --dimensions-count 4 \\
    --questions-count 24 \\
    --json \\
    --check-readmes
EOF
    exit 2
}

###################
# Parameter Parsing
###################

log_phase "2" "Parameter parsing"

PROJECT_PATH=""
EXPECTED_DIMENSIONS=""
EXPECTED_QUESTIONS=""
JSON_OUTPUT=false
CHECK_READMES=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --dimensions-count)
            EXPECTED_DIMENSIONS="$2"
            shift 2
            ;;
        --questions-count)
            EXPECTED_QUESTIONS="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --check-readmes)
            CHECK_READMES=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error_json "invalid_argument" "Unknown argument: $1" 2
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_PATH" ]]; then
    error_json "missing_parameter" "Missing required parameter: --project-path" 2
fi

if [[ -z "$EXPECTED_DIMENSIONS" ]]; then
    error_json "missing_parameter" "Missing required parameter: --dimensions-count" 2
fi

if [[ -z "$EXPECTED_QUESTIONS" ]]; then
    error_json "missing_parameter" "Missing required parameter: --questions-count" 2
fi

if ! [[ "$JSON_OUTPUT" == "true" ]]; then
    error_json "missing_parameter" "Missing required parameter: --json" 2
fi

# Validate numeric parameters
if ! [[ "$EXPECTED_DIMENSIONS" =~ ^[0-9]+$ ]]; then
    error_json "invalid_parameter" "Invalid dimensions count (must be numeric): $EXPECTED_DIMENSIONS" 2
fi

if ! [[ "$EXPECTED_QUESTIONS" =~ ^[0-9]+$ ]]; then
    error_json "invalid_parameter" "Invalid questions count (must be numeric): $EXPECTED_QUESTIONS" 2
fi

log_conditional "INFO" "Project path: $PROJECT_PATH"
log_conditional "INFO" "Expected dimensions: $EXPECTED_DIMENSIONS"
log_conditional "INFO" "Expected questions: $EXPECTED_QUESTIONS"

# Validate project path exists
if [[ ! -d "$PROJECT_PATH" ]]; then
    error_json "project_not_found" "Project directory does not exist: $PROJECT_PATH" 2
fi

###################
# File Counting
###################

log_phase "3" "File counting"

# Define entity directories
DIMENSIONS_DIR="$PROJECT_PATH/01-research-dimensions"
QUESTIONS_DIR="$PROJECT_PATH/02-refined-questions"

log_conditional "DEBUG" "Dimensions directory: $DIMENSIONS_DIR"
log_conditional "DEBUG" "Questions directory: $QUESTIONS_DIR"

# Count dimension files (dimension-*.md files in 01-research-dimensions/)
ACTUAL_DIMENSIONS=0
if [[ -d "$DIMENSIONS_DIR" ]]; then
    ACTUAL_DIMENSIONS="$(find "$DIMENSIONS_DIR" -name "dimension-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    log_conditional "DEBUG" "Found $ACTUAL_DIMENSIONS dimension files"
else
    log_conditional "WARN" "Dimensions directory does not exist: $DIMENSIONS_DIR"
fi

# Count question files (format: question-{slug}-{hash}.md in 02-refined-questions/)
ACTUAL_QUESTIONS=0
if [[ -d "$QUESTIONS_DIR" ]]; then
    ACTUAL_QUESTIONS="$(find "$QUESTIONS_DIR" -name "question-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    log_conditional "DEBUG" "Found $ACTUAL_QUESTIONS question files"
else
    log_conditional "WARN" "Questions directory does not exist: $QUESTIONS_DIR"
fi

log_metric "actual_dimensions" "$ACTUAL_DIMENSIONS" "files"
log_metric "actual_questions" "$ACTUAL_QUESTIONS" "files"

###################
# README Verification (Optional)
###################

DIMENSIONS_README_VALID=false
QUESTIONS_README_VALID=false

if [[ "$CHECK_READMES" == "true" ]]; then
    log_phase "3.5" "README verification"

    # Check dimensions README
    DIMENSIONS_README="$DIMENSIONS_DIR/README.md"
    if [[ -f "$DIMENSIONS_README" ]]; then
        # Check file size > 300 bytes
        readme_size="$(wc -c < "$DIMENSIONS_README" | tr -d ' ')"
        if [[ "$readme_size" -gt 300 ]]; then
            # Check for mermaid block
            if grep -q '```mermaid' "$DIMENSIONS_README"; then
                DIMENSIONS_README_VALID=true
                log_conditional "DEBUG" "Dimensions README verified: size=$readme_size bytes, has mermaid"
            else
                log_conditional "WARN" "Dimensions README missing mermaid block"
            fi
        else
            log_conditional "WARN" "Dimensions README too small: $readme_size bytes"
        fi
    else
        log_conditional "WARN" "Dimensions README does not exist: $DIMENSIONS_README"
    fi

    # Check refined-questions README
    QUESTIONS_README="$QUESTIONS_DIR/README.md"
    if [[ -f "$QUESTIONS_README" ]]; then
        # Check file size > 300 bytes
        readme_size="$(wc -c < "$QUESTIONS_README" | tr -d ' ')"
        if [[ "$readme_size" -gt 300 ]]; then
            # Check for mermaid block
            if grep -q '```mermaid' "$QUESTIONS_README"; then
                QUESTIONS_README_VALID=true
                log_conditional "DEBUG" "Questions README verified: size=$readme_size bytes, has mermaid"
            else
                log_conditional "WARN" "Questions README missing mermaid block"
            fi
        else
            log_conditional "WARN" "Questions README too small: $readme_size bytes"
        fi
    else
        log_conditional "WARN" "Questions README does not exist: $QUESTIONS_README"
    fi

    log_metric "dimensions_readme_valid" "$DIMENSIONS_README_VALID" "boolean"
    log_metric "questions_readme_valid" "$QUESTIONS_README_VALID" "boolean"
fi

###################
# Verification
###################

log_phase "4" "Verification and JSON output"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Check if counts match
if [[ "$ACTUAL_DIMENSIONS" -eq "$EXPECTED_DIMENSIONS" ]] && [[ "$ACTUAL_QUESTIONS" -eq "$EXPECTED_QUESTIONS" ]]; then
    # SUCCESS
    log_conditional "INFO" "Verification passed: All entity counts match"
    log_metric "verification_status" "passed" "boolean"

    if [[ "$CHECK_READMES" == "true" ]]; then
        jq -n \
            --argjson dimensions "$ACTUAL_DIMENSIONS" \
            --argjson questions "$ACTUAL_QUESTIONS" \
            --argjson dim_readme "$DIMENSIONS_README_VALID" \
            --argjson q_readme "$QUESTIONS_README_VALID" \
            --arg timestamp "$timestamp" \
            '{
                success: true,
                dimensions_verified: $dimensions,
                questions_verified: $questions,
                readmes_verified: {
                    dimensions_readme: $dim_readme,
                    refined_questions_readme: $q_readme
                },
                timestamp: $timestamp
            }'
    else
        jq -n \
            --argjson dimensions "$ACTUAL_DIMENSIONS" \
            --argjson questions "$ACTUAL_QUESTIONS" \
            --arg timestamp "$timestamp" \
            '{
                success: true,
                dimensions_verified: $dimensions,
                questions_verified: $questions,
                timestamp: $timestamp
            }'
    fi

    exit 0
else
    # FAILURE
    log_conditional "ERROR" "Verification failed: Count mismatch"
    log_metric "verification_status" "failed" "boolean"

    # Calculate missing counts
    MISSING_DIMENSIONS=$((EXPECTED_DIMENSIONS - ACTUAL_DIMENSIONS))
    MISSING_QUESTIONS=$((EXPECTED_QUESTIONS - ACTUAL_QUESTIONS))

    log_conditional "ERROR" "Missing dimensions: $MISSING_DIMENSIONS"
    log_conditional "ERROR" "Missing questions: $MISSING_QUESTIONS"

    # Build detailed error message
    DETAILS="Missing $MISSING_DIMENSIONS dimension files and $MISSING_QUESTIONS question files. Check entity creation in Phase 5.2."

    if [[ "$CHECK_READMES" == "true" ]]; then
        jq -n \
            --argjson exp_dims "$EXPECTED_DIMENSIONS" \
            --argjson exp_qs "$EXPECTED_QUESTIONS" \
            --argjson act_dims "$ACTUAL_DIMENSIONS" \
            --argjson act_qs "$ACTUAL_QUESTIONS" \
            --argjson miss_dims "$MISSING_DIMENSIONS" \
            --argjson miss_qs "$MISSING_QUESTIONS" \
            --argjson dim_readme "$DIMENSIONS_README_VALID" \
            --argjson q_readme "$QUESTIONS_README_VALID" \
            --arg details "$DETAILS" \
            --arg timestamp "$timestamp" \
            '{
                success: false,
                error: "verification_failed",
                expected: {
                    dimensions: $exp_dims,
                    questions: $exp_qs
                },
                actual: {
                    dimensions: $act_dims,
                    questions: $act_qs
                },
                missing: {
                    dimensions: $miss_dims,
                    questions: $miss_qs
                },
                readmes_verified: {
                    dimensions_readme: $dim_readme,
                    refined_questions_readme: $q_readme
                },
                details: $details,
                timestamp: $timestamp
            }'
    else
        jq -n \
            --argjson exp_dims "$EXPECTED_DIMENSIONS" \
            --argjson exp_qs "$EXPECTED_QUESTIONS" \
            --argjson act_dims "$ACTUAL_DIMENSIONS" \
            --argjson act_qs "$ACTUAL_QUESTIONS" \
            --argjson miss_dims "$MISSING_DIMENSIONS" \
            --argjson miss_qs "$MISSING_QUESTIONS" \
            --arg details "$DETAILS" \
            --arg timestamp "$timestamp" \
            '{
                success: false,
                error: "verification_failed",
                expected: {
                    dimensions: $exp_dims,
                    questions: $exp_qs
                },
                actual: {
                    dimensions: $act_dims,
                    questions: $act_qs
                },
                missing: {
                    dimensions: $miss_dims,
                    questions: $miss_qs
                },
                details: $details,
                timestamp: $timestamp
            }'
    fi

    exit 1
fi
