#!/usr/bin/env bash
set -euo pipefail
# error-logging.sh
# Version: 1.0.0
# Purpose: Reusable error logging utility for deeper-research pipeline scripts
# Category: utilities
#
# Usage: Source this file in your scripts, then call logging functions
#   source /path/to/error-logging.sh
#   error_with_context "Entity creation failed" 3 '{"entity":"Advanced","phase":"publisher-creator"}'
#   debug_context "Title Extraction" entity="$entity_name" source_count="$count"
#   capture_stderr "risky-command --arg value" "risky-command"
#
# Functions:
#   error_with_context <message> [error_code] [context_json]
#     - Logs structured error with context and exits
#     - message: Error description (required)
#     - error_code: Exit code 1-255 (optional, default: 1)
#     - context_json: JSON object with context variables (optional, default: {})
#     - Output: [timestamp] [ERROR] [E{code}] {message}
#               [timestamp] [CONTEXT] {context_json}
#     - Exits with error_code
#
#   debug_context <label> [var=value ...]
#     - Logs variable context for debugging
#     - label: Description of debug point (required)
#     - var=value: Space-separated key=value pairs (optional)
#     - Output: [timestamp] [DEBUG] {label}: var1=value1, var2=value2, ...
#     - Does not exit
#
#   capture_stderr <command> <log_prefix>
#     - Executes command and captures stderr
#     - command: Shell command to execute (required)
#     - log_prefix: Prefix for error logs (required)
#     - Output: [timestamp] [ERROR] {log_prefix}: {stderr} (if stderr not empty)
#     - Returns command exit code
#     - IMPORTANT: Command is executed directly (not via eval) using "$@" pattern
#     - Caller must invoke as: capture_stderr "log_prefix" command arg1 arg2 ...
#
#   get_error_description <error_code>
#     - Returns human-readable description for error code
#     - error_code: Numeric error code 1-99 (required)
#     - Output: Description string or "Unknown error code"
#     - Does not exit
#
# Output (Logging):
#   All log functions write to stderr for error/debug levels
#   Format: [YYYY-MM-DDTHH:MM:SSZ] [LEVEL] message
#   Levels: ERROR, WARN, INFO, DEBUG, TRACE
#
# Exit codes:
#   N/A - This is a library file (does not execute main logic)
#   Individual functions may exit (see function descriptions)
#
# Example:
#   source error-logging.sh
#
#   # Error with context
#   error_with_context "Publisher creation failed" 3 '{"entity":"Advanced","type":"book"}'
#
#   # Debug context
#   debug_context "After title extraction" title="$title" confidence="0.95"
#
#   # Capture stderr (NOTE: This function signature has changed for security)
#   # OLD (INSECURE): capture_stderr "validate-json.sh config.json" "validate-json"
#   # NEW (SECURE): Pass command and arguments separately or build array
#   if ! capture_stderr "validate-json" validate-json.sh config.json; then
#       echo "Validation failed"
#   fi
#
#   # Get error description
#   desc="$(get_error_description 3)"
#   echo "Error E03 means: $desc"
#
# Dependencies:
#   - jq (for JSON formatting and validation)
#   - bash 3.2+ (compatible with macOS default bash)
#
# Environment Variables:
#   ERROR_LOG_LEVEL - Minimum log level to output (default: DEBUG)
#                      Values: ERROR, WARN, INFO, DEBUG, TRACE


# ISO 8601 timestamp generator
_timestamp() {
    # Primary: GNU date format, Fallback: BSD date format (macOS)
    date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ
}

# Error code to description mapping
# Returns description for given error code (E01-E99 and findings-creator 111-132)
get_error_description() {
    local code="${1:-0}"

    case "$code" in
        # General error codes (1-15)
        1)  echo "File not found" ;;
        2)  echo "Validation failed" ;;
        3)  echo "Entity creation failed" ;;
        4)  echo "Script execution failed" ;;
        5)  echo "Network error" ;;
        6)  echo "Parse error" ;;
        7)  echo "Permission denied" ;;
        8)  echo "Invalid arguments" ;;
        9)  echo "Configuration error" ;;
        10) echo "Dependency missing" ;;
        11) echo "Timeout error" ;;
        12) echo "Resource exhausted" ;;
        13) echo "Duplicate entry" ;;
        14) echo "Not implemented" ;;
        15) echo "State error" ;;
        # Findings-creator validation codes (111-114)
        111) echo "Environment validation failed (CLAUDE_PLUGIN_ROOT or PROJECT_PATH missing)" ;;
        112) echo "Parameter validation error (refined-question-path or project-path missing/mismatched)" ;;
        113) echo "Refined question entity not found" ;;
        114) echo "Missing template file" ;;
        # Findings-creator execution codes (121-124)
        121) echo "Query optimization failed" ;;
        122) echo "Batch creation failed or batch validation failed" ;;
        123) echo "Search execution failed" ;;
        124) echo "No search results after fallback (graceful failure)" ;;
        # Findings-creator entity creation codes (131-132)
        131) echo "Finding extraction failed" ;;
        132) echo "No findings created" ;;
        *)  echo "Unknown error code: E$(printf '%02d' "$code")" ;;
    esac
}

# Enhanced error logging with structured context
# Usage: error_with_context "message" [error_code] [context_json]
error_with_context() {
    local message="${1:-Unknown error}"
    local error_code="${2:-1}"
    local context_json="${3:-{}}"

    local timestamp
    timestamp="$(_timestamp)"

    # Format error code with leading zeros (E01, E02, etc.)
    local formatted_code
    formatted_code="$(printf 'E%02d' "$error_code")"

    # Get error description
    local error_desc
    error_desc="$(get_error_description "$error_code")"

    # Log error message
    echo "[$timestamp] [ERROR] [$formatted_code] $message" >&2
    echo "[$timestamp] [ERROR] Description: $error_desc" >&2

    # Log context if provided and valid JSON
    if ! [[ "$context_json" == "{}" ]]; then
        # Validate JSON before logging
        if echo "$context_json" | jq . >/dev/null 2>&1; then
            local formatted_context
            formatted_context="$(echo "$context_json" | jq -c .)"
            echo "[$timestamp] [CONTEXT] $formatted_context" >&2
        else
            echo "[$timestamp] [WARN] Invalid context JSON provided" >&2
        fi
    fi

    exit "$error_code"
}

# Debug context logging for variable inspection
# Usage: debug_context "label" var1="value1" var2="value2" ...
debug_context() {
    local label="${1:-Debug}"
    shift || true

    local timestamp
    timestamp="$(_timestamp)"

    # Build context string from remaining arguments
    local context_parts=()
    local arg
    for arg in "$@"; do
        # Accept key=value format
        if [[ "$arg" =~ ^[a-zA-Z0-9_]+= ]]; then
            context_parts+=("$arg")
        fi
    done

    # Join with commas
    local context_str
    if [[ ${#context_parts[@]} -gt 0 ]]; then
        # Use printf to join array with comma separator
        context_str="$(printf '%s, ' "${context_parts[@]}")"
        # Remove trailing comma and space
        context_str="${context_str%, }"
    else
        context_str="(no context)"
    fi

    echo "[$timestamp] [DEBUG] $label: $context_str" >&2
}

# Capture and log stderr from commands
# Usage: capture_stderr "log_prefix" command [args...]
# Returns: Command exit code
# SECURITY FIX: Removed eval to prevent command injection
# Commands are now executed directly via "$@" pattern
capture_stderr() {
    local log_prefix="${1:-command}"
    shift || {
        error_with_context "capture_stderr requires log_prefix and command arguments" 8 '{"function":"capture_stderr"}'
    }

    if [[ $# -eq 0 ]]; then
        error_with_context "capture_stderr requires command argument" 8 '{"function":"capture_stderr"}'
    fi

    local timestamp
    timestamp="$(_timestamp)"

    # Create temporary file for stderr
    local stderr_file
    stderr_file="$(mktemp)"

    # Execute command directly without eval (SECURITY FIX)
    local exit_code=0
    "$@" 2>"$stderr_file" || exit_code=$?

    # Read stderr content
    local stderr_content
    stderr_content="$(cat "$stderr_file")"

    # Clean up temp file
    rm -f "$stderr_file"

    # Log if stderr is not empty
    if [[ -n "$stderr_content" ]]; then
        # Log each line of stderr
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            echo "[$timestamp] [ERROR] $log_prefix: $line" >&2
        done <<< "$stderr_content"
    fi

    return "$exit_code"
}

# Export functions for use in sourcing scripts
# BUG-011 FIX: Removed export -f (not needed - functions sourced in same shell)
# Functions are available when script is sourced via: source /path/to/error-logging.sh
# Available functions:
# - _timestamp
# - get_error_description
# - log_error  
# - error_with_context
# - debug_context
# - capture_stderr
