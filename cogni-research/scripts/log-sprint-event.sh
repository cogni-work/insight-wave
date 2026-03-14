#!/usr/bin/env bash
set -euo pipefail
# log-sprint-event.sh
# Version: 1.0.0
# Purpose: Log events to project sprint-log.json for audit trail
#
# Usage:
#   log-sprint-event.sh --project-name <name> --phase <phase> --event <event> [OPTIONS]
#
# Arguments:
#   --project-name <name>    Project name (required)
#   --phase <phase>          Phase number (0-10) (required)
#   --event <event>          Event type (required, e.g., research_type_selected, phase_completed)
#   --details <details>      Event details string (optional)
#   --projects-root <path>   Projects root directory (default: ${COGNI_RESEARCH_ROOT})
#   --json                   Output results in JSON format
#
# Returns:
#   JSON: {"success": true|false, "event_logged": "...", "timestamp": "...", "error": "..."}
#
# Exit codes:
#   0 - Success
#   1 - Validation error
#   2 - Invalid arguments
#
# Example:
#   log-sprint-event.sh --project-name "green-bonds" --phase "0" \
#     --event "research_type_selected" --details "type=lean-canvas" --json


# Dependency checks
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 2
fi

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Default configuration
readonly DEFAULT_PROJECTS_ROOT="${COGNI_RESEARCH_ROOT:-${HOME}/research-projects}"

# Parse arguments
PROJECT_NAME=""
PHASE=""
EVENT=""
DETAILS=""
PROJECTS_ROOT="$DEFAULT_PROJECTS_ROOT"
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --phase)
            PHASE="$2"
            shift 2
            ;;
        --event)
            EVENT="$2"
            shift 2
            ;;
        --details)
            DETAILS="$2"
            shift 2
            ;;
        --projects-root)
            PROJECTS_ROOT="$2"
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
if [[ -z "$PROJECT_NAME" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --project-name" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --project-name" >&2
    fi
    exit 1
fi

if [[ -z "$PHASE" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --phase" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --phase" >&2
    fi
    exit 1
fi

if [[ -z "$EVENT" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Missing required argument: --event" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Missing required argument: --event" >&2
    fi
    exit 1
fi

# Construct project path
readonly PROJECT_PATH="$PROJECTS_ROOT/$PROJECT_NAME"
readonly SPRINT_LOG="$PROJECT_PATH/.metadata/sprint-log.json"

# Check if project exists
if [[ ! -d "$PROJECT_PATH" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Project not found: $PROJECT_PATH" \
            --arg path "$PROJECT_PATH" \
            '{success: false, error: $error, project_path: $path}'
    else
        echo "ERROR: Project not found: $PROJECT_PATH" >&2
    fi
    exit 1
fi

# Check if sprint-log.json exists
if [[ ! -f "$SPRINT_LOG" ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Sprint log not found: $SPRINT_LOG" \
            --arg path "$SPRINT_LOG" \
            '{success: false, error: $error, sprint_log_path: $path}'
    else
        echo "ERROR: Sprint log not found: $SPRINT_LOG" >&2
    fi
    exit 1
fi

# Generate timestamp
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Create event object
EVENT_JSON="$(jq -n \
    --arg timestamp "$TIMESTAMP" \
    --arg phase "$PHASE" \
    --arg event "$EVENT" \
    --arg details "$DETAILS" \
    '{
        timestamp: $timestamp,
        phase: $phase,
        event: $event,
        details: $details
    }')"

# Append event to sprint log
# Use temp file for atomic update
TEMP_FILE="$(mktemp)"
trap "rm -f $TEMP_FILE" EXIT

if jq --argjson new_event "$EVENT_JSON" '.events = (.events // []) + [$new_event]' "$SPRINT_LOG" > "$TEMP_FILE"; then
    mv "$TEMP_FILE" "$SPRINT_LOG"
else
    if [[ "$JSON_OUTPUT" == true ]]; then
        jq -n --arg error "Failed to update sprint log" \
            '{success: false, error: $error}'
    else
        echo "ERROR: Failed to update sprint log" >&2
    fi
    exit 1
fi

# Return success
if [[ "$JSON_OUTPUT" == true ]]; then
    jq -n \
        --arg event_logged "$EVENT" \
        --arg timestamp "$TIMESTAMP" \
        --arg phase "$PHASE" \
        --arg details "$DETAILS" \
        '{
            success: true,
            event_logged: $event_logged,
            timestamp: $timestamp,
            phase: $phase,
            details: $details
        }'
else
    echo "✓ Event logged: $EVENT"
    echo "  Phase: $PHASE"
    echo "  Timestamp: $TIMESTAMP"
    if [[ -n "$DETAILS" ]]; then
        echo "  Details: $DETAILS"
    fi
fi

exit 0
