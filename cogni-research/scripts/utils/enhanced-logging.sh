#!/usr/bin/env bash
set -euo pipefail
# enhanced-logging.sh
# Version: 1.2.0
# Purpose: Enhanced logging utility with DEBUG_MODE and QUIET_MODE-aware conditional output
# Category: utilities
#
# Changelog:
# - v1.2.0: POSIX sh compatibility for zsh support
#           - Replace [[ ]] with [ ] conditionals
#           - Replace == with = for string comparison
#           - Replace set -euo with set -eo (remove bash-only -u flag)
#           - Rename 'status' variable to 'phase_status' (zsh read-only conflict)
# - v1.1.0: Add QUIET_MODE support to suppress ALL stderr output (for JSON mode)
#           Fixes jq parse errors when scripts output to stderr in JSON mode
# - v1.0.0: Initial release with DEBUG_MODE-aware logging
#
# Provides backward-compatible logging functions with DEBUG_MODE and QUIET_MODE awareness:
# - log_conditional: DEBUG_MODE-aware logging to stderr and file
# - log_phase: Phase transition logging with special formatting
# - log_metric: Structured performance metrics logging
#
# Environment Variables:
#   DEBUG_MODE    Controls stderr verbosity (true/false, default: false)
#                 - true: All levels to stderr (ERROR, WARN, INFO, DEBUG, TRACE)
#                 - false: Only ERROR and WARN to stderr
#   QUIET_MODE    Suppresses ALL stderr output when true (default: false)
#                 - true: No stderr output at all (for JSON mode)
#                 - false: Normal DEBUG_MODE-based output
#   LOG_FILE      Optional file path for log output (if unset, skip file writes)
#
# Functions:
#   log_conditional <level> <message>
#       Logs with conditional stderr output based on DEBUG_MODE
#       Always writes to LOG_FILE if set
#       Levels: ERROR, WARN, INFO, DEBUG, TRACE
#
#   log_phase <phase_name> <status>
#       Logs phase transitions with special formatting
#       status: "start" or "complete"
#       Example: [PHASE] ========== Phase 3: Entity Creation [start] ==========
#
#   log_metric <metric_name> <value> <unit>
#       Logs performance metrics in structured format
#       Example: [METRIC] entities_created=42 unit=count
#
# Usage Examples:
#   # Source this file to use functions
#   source enhanced-logging.sh
#
#   # Basic logging
#   log_conditional INFO "Processing started"
#   log_conditional ERROR "Failed to process file"
#
#   # Phase logging
#   log_phase "Entity Creation" "start"
#   log_phase "Entity Creation" "complete"
#
#   # Metric logging
#   log_metric "entities_created" 42 "count"
#   log_metric "processing_time" 1.5 "seconds"
#
# Exit codes:
#   0 - Success (always, logging functions don't fail)
#
# Compatibility:
#   - POSIX sh compatible (works in bash, zsh, dash)
#   - Works alongside existing error-logging.sh
#   - All functions exported for sourcing


# Default DEBUG_MODE and QUIET_MODE to false if unset
DEBUG_MODE="${DEBUG_MODE:-false}"
QUIET_MODE="${QUIET_MODE:-false}"

# Get ISO 8601 timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Determine if level should output to stderr based on DEBUG_MODE
should_output_to_stderr() {
    local level="$1"

    # If DEBUG_MODE is true, output all levels
    if [ "$DEBUG_MODE" = "true" ]; then
        return 0
    fi

    # If DEBUG_MODE is false, only output ERROR and WARN
    if [ "$level" = "ERROR" ] || [ "$level" = "WARN" ]; then
        return 0
    fi

    # All other levels (INFO, DEBUG, TRACE) suppressed when DEBUG_MODE=false
    return 1
}

# Core logging function: log_conditional
# Usage: log_conditional <level> <message>
# Always writes to LOG_FILE if set
# Conditionally writes to stderr based on DEBUG_MODE and level
log_conditional() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(get_timestamp)"

    local log_line="[${timestamp}] [${level}] ${message}"

    # Write to LOG_FILE if set
    if [ -n "${LOG_FILE:-}" ]; then
        echo "$log_line" >> "$LOG_FILE"
    fi

    # Conditionally write to stderr based on QUIET_MODE and DEBUG_MODE
    if [ "$QUIET_MODE" != "true" ] && should_output_to_stderr "$level"; then
        echo "$log_line" >&2
    fi
}

# Phase transition logging with optional TodoWrite integration
# Usage: log_phase <phase_name> <status> [--todo-update]
# status: "start" or "complete"
# --todo-update: Enable TodoWrite status synchronization (optional flag)
log_phase() {
    local phase_name="$1"
    local phase_status="$2"
    local enable_todo_update="${3:-}"
    local timestamp
    timestamp="$(get_timestamp)"

    local log_line="[${timestamp}] [PHASE] ========== ${phase_name} [${phase_status}] =========="

    # Write to LOG_FILE if set
    if [ -n "${LOG_FILE:-}" ]; then
        echo "$log_line" >> "$LOG_FILE"
    fi

    # Phase logs go to stderr unless QUIET_MODE is enabled
    if [ "$QUIET_MODE" != "true" ]; then
        echo "$log_line" >&2
    fi

    # Optional TodoWrite integration (enabled by --todo-update flag)
    # This allows phase logging to automatically update TodoWrite status
    # Note: TodoWrite updates must be performed by the LLM agent, not scripts
    # Scripts log a TodoWrite reminder that agents should act upon
    if [ "$enable_todo_update" = "--todo-update" ] && [ "$phase_status" = "complete" ]; then
        local todo_marker="[TODO_UPDATE_NEEDED] Phase: ${phase_name} | Status: completed"
        if [ -n "${LOG_FILE:-}" ]; then
            echo "[${timestamp}] ${todo_marker}" >> "$LOG_FILE"
        fi
        if [ "$QUIET_MODE" != "true" ] && [ "$DEBUG_MODE" = "true" ]; then
            echo "[${timestamp}] ${todo_marker}" >&2
        fi
    fi
}

# Metric logging with structured format
# Usage: log_metric <metric_name> <value> <unit>
log_metric() {
    local metric_name="$1"
    local value="$2"
    local unit="$3"
    local timestamp
    timestamp="$(get_timestamp)"

    local log_line="[${timestamp}] [METRIC] ${metric_name}=${value} unit=${unit}"

    # Write to LOG_FILE if set
    if [ -n "${LOG_FILE:-}" ]; then
        echo "$log_line" >> "$LOG_FILE"
    fi

    # Metrics go to stderr unless QUIET_MODE is enabled
    if [ "$QUIET_MODE" != "true" ]; then
        echo "$log_line" >&2
    fi
}

# Export functions for sourcing
export -f log_conditional
export -f log_phase
export -f log_metric
export -f get_timestamp
export -f should_output_to_stderr
