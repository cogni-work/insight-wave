#!/usr/bin/env bash
set -euo pipefail
# repair-wikilinks.sh
# Version: 1.3.0
# Purpose: Auto-repair broken wikilinks based on validate-wikilinks.sh categorization
# Category: utilities
# Changelog:
#   1.3.0: Support partial_path category from validate-wikilinks.sh v3.3.0 (relative paths: ../prefix, data/ without entity dir)
#   1.2.0: Add trailing_backslash to auto-repairable categories (fixes LLM-generated wikilinks with trailing backslashes)
#
# Usage: repair-wikilinks.sh --project-path <path> [options]
#
# Arguments:
#   --project-path <path>       Absolute path to deeper-research project directory (required)
#   --dry-run                   Preview changes without applying them (optional)
#   --json                      Output results in JSON format (optional)
#   --backup-dir <path>         Custom backup directory path (optional, default: project-path/.backup-TIMESTAMP)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "mode": "dry-run" | "repair",
#       "total_broken_before": number,
#       "auto_repaired": number,
#       "manual_review_needed": number,
#       "backup_path": "path" | null,
#       "repairs_applied": [
#         {
#           "file": "path/to/file.md",
#           "original": "[[...]]",
#           "repaired": "[[...]]",
#           "category": "missing_directory_prefix|missing_md_extension|trailing_backslash|partial_path"
#         }
#       ],
#       "manual_review": [
#         {
#           "file": "path/to/entity.md",
#           "wikilink": "[[source-wrong-hash]]",
#           "category": "hash_mismatch|entity_type_confusion|missing_entity",
#           "details": "..."
#         }
#       ]
#     },
#     "error": "error message" (if success=false)
#   }
#
# Exit codes:
#   0 - Success (all auto-repairable links fixed)
#   1 - Partial success (some links require manual review)
#   2 - Invalid arguments
#   3 - Project path not found
#   4 - validate-wikilinks.sh not found
#
# Example:
#   repair-wikilinks.sh --project-path /path/to/research --dry-run --json
#   repair-wikilinks.sh --project-path /path/to/research --json


# Script metadata
readonly SCRIPT_VERSION="1.2.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized entity config
source "${SCRIPT_DIR}/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh not found at ${SCRIPT_DIR}/lib/entity-config.sh" >&2
    exit 1
}
DATA_SUBDIR="$(get_data_subdir)"

# Error handler - outputs JSON error to stderr and exits
error_json() {
    local message="$1"
    local code="${2:-1}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Parse arguments
PROJECT_PATH=""
DRY_RUN=false
JSON_OUTPUT=false
BACKUP_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        *)
            error_json "Unknown argument: $1" 2
            ;;
    esac
done

# Validation
if [[ -z "$PROJECT_PATH" ]]; then
    error_json "Missing required argument: --project-path" 2
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    error_json "Project path not found: $PROJECT_PATH" 3
fi

# Check for validate-wikilinks.sh
VALIDATE_SCRIPT="${SCRIPT_DIR}/validate-wikilinks.sh"
if [[ ! -f "$VALIDATE_SCRIPT" ]]; then
    error_json "validate-wikilinks.sh not found at: $VALIDATE_SCRIPT" 4
fi

# Set default backup directory if not provided
if [[ -z "$BACKUP_DIR" ]]; then
    TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
    BACKUP_DIR="$PROJECT_PATH/.backup-repair-$TIMESTAMP"
fi

# Create backup directory if not dry-run
if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$BACKUP_DIR" || error_json "Failed to create backup directory: $BACKUP_DIR" 3
fi

# =============================================================================
# PHASE 1: Run validate-wikilinks.sh to get categorized broken links
# =============================================================================

VALIDATION_OUTPUT="$(bash "$VALIDATE_SCRIPT" --project-path "$PROJECT_PATH" --json 2>/dev/null)" || true

# Validate JSON output
if ! echo "$VALIDATION_OUTPUT" | jq -e . >/dev/null 2>&1; then
    error_json "Validation script returned invalid JSON or timed out" 5
fi

# Parse validation results with safe defaults
TOTAL_BROKEN="$(echo "$VALIDATION_OUTPUT" | jq -r '.broken_count // 0' 2>/dev/null || echo "0")"
AUTO_REPAIRABLE_COUNT="$(echo "$VALIDATION_OUTPUT" | jq -r '.auto_repairable_count // 0' 2>/dev/null || echo "0")"
MANUAL_REVIEW_COUNT="$(echo "$VALIDATION_OUTPUT" | jq -r '.manual_review_count // 0' 2>/dev/null || echo "0")"

# Ensure numeric values
[[ "$TOTAL_BROKEN" =~ ^[0-9]+$ ]] || TOTAL_BROKEN=0
[[ "$AUTO_REPAIRABLE_COUNT" =~ ^[0-9]+$ ]] || AUTO_REPAIRABLE_COUNT=0
[[ "$MANUAL_REVIEW_COUNT" =~ ^[0-9]+$ ]] || MANUAL_REVIEW_COUNT=0

# Extract broken links arrays
BROKEN_LINKS_JSON="$(echo "$VALIDATION_OUTPUT" | jq -c '.broken_links // []' 2>/dev/null || echo "[]")"

# =============================================================================
# PHASE 2: Process auto-repairable links into temp files
# =============================================================================

# Create temp files for data (Bash 3.x compatible - no associative arrays)
REPAIRS_BY_FILE="$(mktemp)"
REPAIRS_JSON_FILE="$(mktemp)"
MANUAL_JSON_FILE="$(mktemp)"
BACKED_UP_FILES="$(mktemp)"

cleanup() {
    rm -f "$REPAIRS_BY_FILE" "$REPAIRS_JSON_FILE" "$MANUAL_JSON_FILE" "$BACKED_UP_FILES"
}
trap cleanup EXIT

# Initialize JSON arrays in temp files
echo "[]" > "$REPAIRS_JSON_FILE"
echo "[]" > "$MANUAL_JSON_FILE"

# Process each broken link - write to temp files
echo "$BROKEN_LINKS_JSON" | jq -c '.[]' 2>/dev/null | while IFS= read -r broken_link; do
    source_file="$(echo "$broken_link" | jq -r '.source_file')"
    wikilink="$(echo "$broken_link" | jq -r '.wikilink')"
    error_type="$(echo "$broken_link" | jq -r '.error_type')"
    suggested_fix="$(echo "$broken_link" | jq -r '.suggested_fix')"
    auto_repairable="$(echo "$broken_link" | jq -r '.auto_repairable')"
    target_file="$(echo "$broken_link" | jq -r '.target_file')"

    if [[ "$auto_repairable" == "true" ]]; then
        # Record repair for processing
        # Format: source_file|original_wikilink|suggested_fix|category
        echo "${source_file}|${wikilink}|${suggested_fix}|${error_type}" >> "$REPAIRS_BY_FILE"
    else
        # Record manual review item - append to JSON file
        new_item="$(jq -n \
            --arg file "$source_file" \
            --arg wikilink "$wikilink" \
            --arg category "$error_type" \
            --arg details "$target_file" \
            '{file: $file, wikilink: $wikilink, category: $category, details: $details}')"

        # Thread-safe append using temp file
        jq --argjson item "$new_item" '. + [$item]' "$MANUAL_JSON_FILE" > "${MANUAL_JSON_FILE}.tmp"
        mv "${MANUAL_JSON_FILE}.tmp" "$MANUAL_JSON_FILE"
    fi
done

# =============================================================================
# PHASE 3: Apply repairs (grouped by file for efficiency)
# =============================================================================

# Sort repairs by file for efficient processing
if [[ -f "$REPAIRS_BY_FILE" ]] && [[ -s "$REPAIRS_BY_FILE" ]]; then
    sort -t'|' -k1 "$REPAIRS_BY_FILE" > "${REPAIRS_BY_FILE}.sorted"
    mv "${REPAIRS_BY_FILE}.sorted" "$REPAIRS_BY_FILE"
fi

ACTUAL_REPAIRS=0

# Process repairs - use file-based tracking instead of associative arrays
while IFS='|' read -r source_file original_wikilink suggested_fix category; do
    [[ -z "$source_file" ]] && continue

    # Backup file if not already backed up and not dry-run
    # Use grep on temp file instead of associative array
    if [[ "$DRY_RUN" == false ]] && ! grep -qxF "$source_file" "$BACKED_UP_FILES" 2>/dev/null; then
        if [[ -f "$source_file" ]]; then
            relative_path="${source_file#"$PROJECT_PATH"/}"
            backup_path="$BACKUP_DIR/$relative_path"
            backup_parent="$(dirname "$backup_path")"
            mkdir -p "$backup_parent"
            cp "$source_file" "$backup_path"
            echo "$source_file" >> "$BACKED_UP_FILES"
        fi
    fi

    # Apply repair if not dry-run
    if [[ "$DRY_RUN" == false ]] && [[ -f "$source_file" ]]; then
        # Escape special regex characters in wikilink patterns for sed
        # Using perl-style escaping for reliability
        escaped_original="$(printf '%s\n' "$original_wikilink" | sed 's/[[\.*^$()+?{|]/\\&/g')"

        # Apply replacement using sed with | delimiter to avoid path conflicts
        # Remove -g flag to only replace first occurrence
        # This prevents affecting other wikilinks with same path but different display names
        if sed -i.tmp "s|${escaped_original}|${suggested_fix}|" "$source_file" 2>/dev/null; then
            rm -f "${source_file}.tmp"

            # Verify replacement succeeded
            if grep -qF "$suggested_fix" "$source_file"; then
                ACTUAL_REPAIRS=$((ACTUAL_REPAIRS + 1))
            else
                # Log failed repair
                echo "WARNING: Failed to repair $original_wikilink in $source_file" >> "${BACKUP_DIR}/failed-repairs.log"
            fi
        fi
    else
        ACTUAL_REPAIRS=$((ACTUAL_REPAIRS + 1))
    fi

    # Record repair - append to JSON file
    new_repair="$(jq -n \
        --arg file "$source_file" \
        --arg original "$original_wikilink" \
        --arg repaired "$suggested_fix" \
        --arg category "$category" \
        '{file: $file, original: $original, repaired: $repaired, category: $category}')"

    jq --argjson item "$new_repair" '. + [$item]' "$REPAIRS_JSON_FILE" > "${REPAIRS_JSON_FILE}.tmp"
    mv "${REPAIRS_JSON_FILE}.tmp" "$REPAIRS_JSON_FILE"

done < "$REPAIRS_BY_FILE"

# =============================================================================
# PHASE 4: Generate report
# =============================================================================

# Read final counts from JSON files
REPAIRS_COUNT="$(jq 'length' "$REPAIRS_JSON_FILE")"
MANUAL_COUNT="$(jq 'length' "$MANUAL_JSON_FILE")"

# Read JSON arrays
REPAIRS_JSON="$(cat "$REPAIRS_JSON_FILE")"
MANUAL_JSON="$(cat "$MANUAL_JSON_FILE")"

# Determine mode string
MODE="repair"
[[ "$DRY_RUN" == true ]] && MODE="dry-run"

# Generate JSON report
if [[ "$JSON_OUTPUT" == true ]]; then
    # Build backup path value
    BACKUP_VALUE=""
    if [[ "$DRY_RUN" == false ]] && [[ -d "$BACKUP_DIR" ]]; then
        BACKUP_VALUE="$BACKUP_DIR"
    fi

    # Output final JSON
    if [[ -n "$BACKUP_VALUE" ]]; then
        jq -n \
            --arg mode "$MODE" \
            --argjson total_broken "$TOTAL_BROKEN" \
            --argjson auto_repaired "$REPAIRS_COUNT" \
            --argjson manual_review "$MANUAL_COUNT" \
            --arg backup "$BACKUP_VALUE" \
            --argjson repairs "$REPAIRS_JSON" \
            --argjson manual "$MANUAL_JSON" \
            '{
                success: true,
                data: {
                    mode: $mode,
                    total_broken_before: $total_broken,
                    auto_repaired: $auto_repaired,
                    manual_review_needed: $manual_review,
                    backup_path: $backup,
                    repairs_applied: $repairs,
                    manual_review: $manual
                }
            }'
    else
        jq -n \
            --arg mode "$MODE" \
            --argjson total_broken "$TOTAL_BROKEN" \
            --argjson auto_repaired "$REPAIRS_COUNT" \
            --argjson manual_review "$MANUAL_COUNT" \
            --argjson repairs "$REPAIRS_JSON" \
            --argjson manual "$MANUAL_JSON" \
            '{
                success: true,
                data: {
                    mode: $mode,
                    total_broken_before: $total_broken,
                    auto_repaired: $auto_repaired,
                    manual_review_needed: $manual_review,
                    backup_path: null,
                    repairs_applied: $repairs,
                    manual_review: $manual
                }
            }'
    fi
else
    # Text report
    echo "Wikilink Repair Report"
    echo "======================"
    echo "Mode: $MODE"
    echo "Project: $PROJECT_PATH"
    echo ""
    echo "Summary:"
    echo "  Total broken links found: $TOTAL_BROKEN"
    echo "  Auto-repaired: $REPAIRS_COUNT"
    echo "  Manual review needed: $MANUAL_COUNT"
    echo ""

    if [[ "$DRY_RUN" == false ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo "Backup: $BACKUP_DIR"
        echo ""
    fi

    if [[ "$REPAIRS_COUNT" -gt 0 ]]; then
        echo "Repairs Applied:"
        echo "----------------"
        echo "$REPAIRS_JSON" | jq -r --arg pp "$PROJECT_PATH" '.[] |
            "  \(.file | sub($pp + "/"; ""))\n     Category: \(.category)\n     Old: \(.original)\n     New: \(.repaired)\n"'
    fi

    if [[ "$MANUAL_COUNT" -gt 0 ]]; then
        echo "Manual Review Required:"
        echo "-----------------------"
        echo "$MANUAL_JSON" | jq -r --arg pp "$PROJECT_PATH" '.[] |
            "  \(.file | sub($pp + "/"; ""))\n     Category: \(.category)\n     Link: \(.wikilink)\n"'
    fi
fi

# Exit with appropriate code
if [[ $MANUAL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
