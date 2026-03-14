#!/usr/bin/env bash
set -euo pipefail
# update-index-section.sh
# Version: 2.0.0
# Purpose: Update .metadata/entity-index.json section with filesystem entities
# Category: utilities
#
# Changelog:
# v2.0.0 (2025-11-16, Sprint 315: Enhanced Logging Migration):
#   - Migrated to enhanced-logging.sh utilities (log_conditional, log_phase, log_metric)
#   - Added DEBUG_MODE awareness for clean production output
#   - Added structured phase markers (4 phases)
#   - Added performance metrics
#   - Now compliant with three-layer debugging architecture
#
# Usage: update-index-section.sh --index-file <path> --entity-type <type> --entities <json>
#
# Arguments:
#   --index-file <path>       Path to .metadata/entity-index.json (required)
#   --entity-type <string>    Entity type to update (e.g., "05-sources") (required)
#   --entities <json>         JSON array of entities to write (required)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "data": {
#       "index_file": string,
#       "entity_type": string,
#       "entries_written": number,
#       "backup_created": string
#     }
#   }
#
# Exit codes:
#   0 - Success
#   1 - Update failed
#   2 - Invalid arguments
#   3 - File not found
#
# Example:
#   update-index-section.sh --index-file .metadata/entity-index.json --entity-type 05-sources --entities '[...]'


# ===== LOGGING INITIALIZATION =====
SCRIPT_NAME="update-index-section"

# Source enhanced logging utilities (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging for standalone usage
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] ========== $1 [$2] ==========" >&2 || true; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 unit=$3" >&2 || true; }
fi

error_json() {
    local message="$1"
    local code="${2:-1}"
    log_conditional "ERROR" "$message"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

main() {
    local index_file=""
    local entity_type=""
    local entities=""
    local start_time
    start_time="$(date +%s)"

    log_phase "Phase 1: Input Validation" "start"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --index-file)
                index_file="$2"
                shift 2
                ;;
            --entity-type)
                entity_type="$2"
                shift 2
                ;;
            --entities)
                entities="$2"
                shift 2
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    log_conditional "INFO" "Parameter: index_file = ${index_file}"
    log_conditional "INFO" "Parameter: entity_type = ${entity_type}"
    log_conditional "DEBUG" "Parameter: entities length = $(echo "$entities" | wc -c) bytes"

    [[ -n "$index_file" ]] || error_json "Missing required argument: --index-file" 2
    [[ -n "$entity_type" ]] || error_json "Missing required argument: --entity-type" 2
    [[ -n "$entities" ]] || error_json "Missing required argument: --entities" 2
    [[ -f "$index_file" ]] || error_json "Index file not found: $index_file" 3

    log_phase "Phase 1: Input Validation" "complete"

    # ===== PHASE 2: BACKUP CREATION =====
    log_phase "Phase 2: Backup Creation" "start"

    local backup_file="${index_file}.backup-$(date -u +%Y%m%d-%H%M%S)"
    cp "$index_file" "$backup_file" || error_json "Failed to create backup: $backup_file" 1
    log_conditional "INFO" "Backup created: $backup_file"
    log_metric "backup_created" 1 "boolean"

    log_phase "Phase 2: Backup Creation" "complete"

    # ===== PHASE 3: INDEX UPDATE =====
    log_phase "Phase 3: Index Update" "start"

    local temp_file="${index_file}.tmp"
    log_conditional "DEBUG" "Updating section: $entity_type"

    jq --arg type "$entity_type" \
       --argjson ents "$entities" \
       '.[$type] = $ents' "$index_file" > "$temp_file" || \
       error_json "Failed to update index" 1

    # Atomic move
    mv "$temp_file" "$index_file" || error_json "Failed to write index file" 1
    log_conditional "INFO" "Index file updated atomically"

    local count
    count="$(echo "$entities" | jq 'length')"
    log_metric "entries_written" "$count" "count"
    log_metric "section_updated" 1 "count"

    log_phase "Phase 3: Index Update" "complete"

    # ===== PHASE 4: RESULT GENERATION =====
    log_phase "Phase 4: Result Generation" "start"

    local end_time
    end_time="$(date +%s)"
    local duration=$((end_time - start_time))
    log_metric "duration" "$duration" "seconds"
    log_conditional "INFO" "Update completed successfully"

    log_phase "Phase 4: Result Generation" "complete"

    jq -n \
        --arg file "$index_file" \
        --arg type "$entity_type" \
        --argjson cnt "$count" \
        --arg backup "$backup_file" \
        '{
            success: true,
            data: {
                index_file: $file,
                entity_type: $type,
                entries_written: $cnt,
                backup_created: $backup
            }
        }'
}

main "$@"
