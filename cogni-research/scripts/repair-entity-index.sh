#!/usr/bin/env bash
set -euo pipefail
# repair-entity-index.sh
# Version: 2.0.0
# Purpose: Orchestrate .metadata/entity-index.json repair by delegating to focused service scripts
# Category: utilities
#
# Changelog:
# v2.0.0 (2025-11-16, Sprint 315: Enhanced Logging Migration):
#   - Migrated to enhanced-logging.sh utilities (log_conditional, log_phase, log_metric)
#   - Added DEBUG_MODE awareness for clean production output
#   - Added structured phase markers (5 phases)
#   - Added performance metrics (entities_scanned, issues_found, repairs_applied)
#   - Now compliant with three-layer debugging architecture
#
# Usage: repair-entity-index.sh --project-path <path> [--entity-type <type>] [--dry-run] [--json]
#
# Arguments:
#   --project-path <path>     Research project directory (required)
#   --entity-type <string>    Specific entity type to repair (e.g., "07-sources"), default: all (optional)
#   --dry-run                 Report drift without modifying index (optional)
#   --json                    Return JSON response instead of human-readable output (optional)
#
# Output (JSON):
#   {
#     "success": boolean,
#     "dry_run": boolean,
#     "entities_scanned": number,
#     "index_entries_before": number,
#     "index_entries_after": number,
#     "missing_entries_added": number,
#     "orphaned_entries_removed": number,
#     "entity_types_repaired": [string],
#     "repair_report_path": string
#   }
#
# Exit codes:
#   0 - Success
#   1 - Repair failures (some entries couldn't be added)
#   2 - Validation failures (invalid parameters)
#
# Example:
#   repair-entity-index.sh --project-path ~/research/sprint-280 --dry-run --json


# Get script directory for helper scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===== LOGGING INITIALIZATION =====
SCRIPT_NAME="repair-entity-index"

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

# Generate markdown repair report
generate_report() {
    local project_path="$1"
    local drift_data="$2"
    local dry_run="$3"

    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    local report_filename="index-repair-$(date -u +"%Y%m%d-%H%M%S").md"
    local report_dir="$project_path/reports"
    mkdir -p "$report_dir"
    local report_path="$report_dir/$report_filename"

    local mode="Full Repair"
    [[ "$dry_run" = "true" ]] && mode="Dry Run"

    local total_scanned="$(echo "$drift_data" | jq '[.[] | .filesystem_count] | add // 0')"
    local total_missing="$(echo "$drift_data" | jq '[.[] | .missing_entries | length] | add // 0')"
    local total_orphaned="$(echo "$drift_data" | jq '[.[] | .orphaned_entries | length] | add // 0')"

    cat > "$report_path" <<EOF
# Entity Index Repair Report

**Date:** $timestamp
**Mode:** $mode

## Summary
- Entities scanned: $total_scanned
- Missing entries added: $total_missing
- Orphaned entries removed: $total_orphaned

## Details by Entity Type

EOF

    echo "$drift_data" | jq -r 'to_entries[] | "\(.key)|\(.value.filesystem_count)|\(.value.index_count)|\(.value.missing_entries | length)|\(.value.orphaned_entries | length)"' | \
    while IFS='|' read -r entity_type fs_count idx_count missing_count orphaned_count; do
        cat >> "$report_path" <<EOF
### $entity_type
- Files on disk: $fs_count
- Index entries before: $idx_count
- Missing entries: $missing_count
- Orphaned entries: $orphaned_count

EOF

        if [[ "$missing_count" -gt 0 ]]; then
            echo "#### Missing Entries" >> "$report_path"
            echo "$drift_data" | jq -r --arg type "$entity_type" \
                '.[$type].missing_entries[] | "- \(.id) (\(.url // "no URL"))"' >> "$report_path"
            echo "" >> "$report_path"
        fi
    done

    echo "$report_path"
}

main() {
    local start_time
    start_time="$(date +%s)"
    local project_path=""
    local entity_type=""
    local dry_run="false"
    local json_output="false"

    log_phase "Phase 1: Input Validation" "start"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-path)
                project_path="$2"
                shift 2
                ;;
            --entity-type)
                entity_type="$2"
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --json)
                json_output="true"
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 2
                ;;
        esac
    done

    [[ -n "$project_path" ]] || error_json "Missing required argument: --project-path" 2
    [[ -d "$project_path" ]] || error_json "Project directory not found: $project_path" 2

    log_conditional "INFO" "Parameter: project_path = ${project_path}"
    log_conditional "INFO" "Parameter: entity_type = ${entity_type:-all}"
    log_conditional "INFO" "Parameter: dry_run = ${dry_run}"

    local index_file="$project_path/.metadata/entity-index.json"
    [[ -f "$index_file" ]] || error_json ".metadata/entity-index.json not found: $index_file" 2

    log_conditional "INFO" "Index file found: $index_file"
    log_phase "Phase 1: Input Validation" "complete"

    # ===== PHASE 2: ENTITY TYPE DISCOVERY =====
    log_phase "Phase 2: Entity Type Discovery" "start"

    # Determine entity types
    local entity_types=()
    if [[ -n "$entity_type" ]]; then
        entity_types=("$entity_type")
    else
        while IFS= read -r dir; do
            local dirname="$(basename "$dir")"
            [[ "$dirname" =~ ^[0-9]{2}- ]] && entity_types+=("$dirname")
        done < <(find "$project_path" -maxdepth 1 -type d 2>/dev/null || true)
    fi

    log_conditional "INFO" "Entity types to process: ${entity_types[*]}"
    log_metric "entity_types_count" "${#entity_types[@]}" "count"
    log_phase "Phase 2: Entity Type Discovery" "complete"

    # ===== PHASE 3: SCAN AND DRIFT DETECTION =====
    log_phase "Phase 3: Scan and Drift Detection" "start"

    # Process each entity type
    local drift_data="{}"
    local total_scanned=0
    local index_before=0
    local total_missing=0
    local total_orphaned=0

    for etype in "${entity_types[@]}"; do
        log_conditional "DEBUG" "Processing entity type: $etype"

        # Call scan-entity-directory service
        local scan_result="$("$SCRIPT_DIR/scan-entity-directory.sh" \
            --project-path "$project_path" \
            --entity-type "$etype" 2>/dev/null || echo '{"success":false}')"

        local scan_success="$(echo "$scan_result" | jq -r '.success')"
        [[ "$scan_success" = "true" ]] || { log_conditional "WARN" "Scan failed for $etype"; continue; }

        local fs_entities="$(echo "$scan_result" | jq '.data.entities')"
        local fs_count="$(echo "$scan_result" | jq '.data.count')"

        # Call detect-index-drift service
        local drift_result="$("$SCRIPT_DIR/detect-index-drift.sh" \
            --index-file "$index_file" \
            --entity-type "$etype" \
            --filesystem-entities "$fs_entities" 2>/dev/null || echo '{"success":false}')"

        local drift_success="$(echo "$drift_result" | jq -r '.success')"
        [[ "$drift_success" = "true" ]] || { log_conditional "WARN" "Drift detection failed for $etype"; continue; }

        local drift="$(echo "$drift_result" | jq '.data')"
        log_conditional "DEBUG" "Drift detected for $etype: $(echo "$drift" | jq -c '{missing: (.missing_entries | length), orphaned: (.orphaned_entries | length)}')"
        local idx_count="$(echo "$drift" | jq '.index_count')"
        local missing_count="$(echo "$drift" | jq '.missing_entries | length')"
        local orphaned_count="$(echo "$drift" | jq '.orphaned_entries | length')"
        local has_drift="$(echo "$drift" | jq -r '.has_drift')"

        # Store drift data
        drift_data="$(echo "$drift_data" | jq \
            --arg type "$etype" \
            --argjson drift "$drift" \
            '.[$type] = $drift')"

        total_scanned=$((total_scanned + fs_count))
        index_before=$((index_before + idx_count))
        total_missing=$((total_missing + missing_count))
        total_orphaned=$((total_orphaned + orphaned_count))

        # Update index if not dry-run and has drift
        if [[ "$dry_run" = "false" && "$has_drift" = "true" ]]; then
            log_conditional "INFO" "Updating index for $etype"
            "$SCRIPT_DIR/update-index-section.sh" \
                --index-file "$index_file" \
                --entity-type "$etype" \
                --entities "$fs_entities" >/dev/null 2>&1 || \
                error_json "Failed to update index for $etype" 1
        fi
    done

    log_metric "entities_scanned" "$total_scanned" "count"
    log_metric "issues_found" "$((total_missing + total_orphaned))" "count"
    log_metric "missing_entries" "$total_missing" "count"
    log_metric "orphaned_entries" "$total_orphaned" "count"
    log_phase "Phase 3: Scan and Drift Detection" "complete"

    # ===== PHASE 4: REPORT GENERATION =====
    log_phase "Phase 4: Report Generation" "start"

    # Generate report
    local report_path="$(generate_report "$project_path" "$drift_data" "$dry_run")"
    local entity_types_json="$(echo "$drift_data" | jq -r 'keys | @json')"
    log_conditional "INFO" "Report generated: $report_path"
    log_phase "Phase 4: Report Generation" "complete"

    # ===== PHASE 5: OUTPUT =====
    log_phase "Phase 5: Result Output" "start"
    local end_time
    end_time="$(date +%s)"
    local duration=$((end_time - start_time))
    log_metric "duration" "$duration" "seconds"

    # Output results
    if [[ "$json_output" = "true" ]]; then
        log_conditional "INFO" "Outputting JSON response"
        jq -n \
            --argjson dry "$([[ "$dry_run" = "true" ]] && echo true || echo false)" \
            --argjson scanned "$total_scanned" \
            --argjson before "$index_before" \
            --argjson after "$total_scanned" \
            --argjson missing "$total_missing" \
            --argjson orphaned "$total_orphaned" \
            --argjson types "$entity_types_json" \
            --arg report "$report_path" \
            '{
                success: true,
                dry_run: $dry,
                entities_scanned: $scanned,
                index_entries_before: $before,
                index_entries_after: $after,
                missing_entries_added: $missing,
                orphaned_entries_removed: $orphaned,
                entity_types_repaired: $types,
                repair_report_path: $report
            }'
    else
        local mode_text="Repair completed"
        [[ "$dry_run" = "true" ]] && mode_text="Dry run completed"

        echo "✅ $mode_text"
        echo ""
        echo "Summary:"
        echo "  Entities scanned: $total_scanned"
        echo "  Missing entries: $total_missing"
        echo "  Orphaned entries: $total_orphaned"
        echo ""
        echo "Report: $report_path"
    fi

    log_phase "Phase 5: Result Output" "complete"
}

main "$@"
