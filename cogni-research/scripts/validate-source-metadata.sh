#!/usr/bin/env bash
set -euo pipefail
# validate-source-metadata.sh
# Purpose: Validate source metadata (URL, domain, title) from findings
# Category: validators
# Version: 1.2.0
#
# Changelog:
# v1.2.0 (2025-11-16, Sprint 315: Enhanced Logging Migration):
#   - Migrated to enhanced-logging.sh utilities (log_conditional, log_phase, log_metric)
#   - Added DEBUG_MODE awareness for clean production output
#   - Added structured phase markers (3 phases)
#   - Added performance metrics (validations_passed, checks_performed)
#   - Now compliant with three-layer debugging architecture
#
# Usage:
#   validate-source-metadata.sh --url URL --domain DOMAIN --title TITLE [--json]
#
# Arguments:
#   --url <string>     Source URL to validate (required)
#   --domain <string>  Extracted domain to validate (required)
#   --title <string>   Source title to validate (required)
#   --json             Output JSON format (optional flag)
#
# Output Format (JSON mode):
#   Success: {"success": true, "valid": true}
#   Invalid: {"success": true, "valid": false, "skip_reason": "...", "error": "..."}
#   Error:   {"success": false, "error": "..."}
#
# Exit codes:
#   0: Valid metadata (or JSON output returned)
#   1: Invalid metadata (standard mode)
#   2: Argument error (standard mode)


# ===== LOGGING INITIALIZATION =====
SCRIPT_NAME="validate-source-metadata"

# Source enhanced logging utilities (with fallback)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]] && [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging for standalone usage
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2 || true; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] ========== $1 [$2] ==========" >&2 || true; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 unit=$3" >&2 || true; }
fi

# Error handling function
error_json() {
    local message="$1"
    local code="${2:-1}"
    log_conditional "ERROR" "$message"
    jq -n --arg msg "$message" --argjson c "$code" \
        '{success: false, error: $msg, error_code: $c}' >&2
    exit "$code"
}

# Validation result functions
validation_failed_json() {
    local skip_reason="$1"
    local error_message="$2"

    jq -n \
        --argjson valid false \
        --arg reason "$skip_reason" \
        --arg error "$error_message" \
        '{
            success: true,
            valid: $valid,
            skip_reason: $reason,
            error: $error
        }'
}

validation_success_json() {
    jq -n --argjson valid true \
        '{success: true, valid: $valid}'
}

# Title normalization validation function
# Ensures titles are properly normalized before source creation
# to prevent deduplication failures
validate_title_normalization() {
    local title="$1"

    # Check 1: "Finding:" prefix (case-insensitive)
    # Prevents source entities with unnormalized "Finding: <title>" format
    if echo "$title" | grep -qiE '^finding:'; then
        echo "Title contains 'Finding:' prefix (not normalized)"
        return 1
    fi

    # Check 2: Leading/trailing whitespace
    # Ensures title matches normalized format for deduplication
    local trimmed
    trimmed="$(echo "$title" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if ! [[ "$title" == "$trimmed" ]]; then
        echo "Title has leading or trailing whitespace"
        return 1
    fi

    # Check 3: Multiple consecutive spaces
    # Prevents whitespace inconsistencies in title matching
    if echo "$title" | grep -q '  '; then
        echo "Title has multiple consecutive spaces"
        return 1
    fi

    return 0
}

main() {
    local start_time
    start_time="$(date +%s)"
    local checks_performed=0

    # Parse arguments
    local url=""
    local domain=""
    local title=""
    local json_output=false

    log_phase "Phase 1: Input Parsing" "start"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                url="${2:-}"
                shift 2
                ;;
            --domain)
                domain="${2:-}"
                shift 2
                ;;
            --title)
                title="${2:-}"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                if [[ "$json_output" = true ]]; then
                    error_json "Unknown argument: $1" 2
                else
                    echo "Error: Unknown argument: $1" >&2
                    exit 2
                fi
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$url" ]]; then
        if [[ "$json_output" = true ]]; then
            error_json "Missing required argument: --url" 2
        else
            echo "Error: Missing required argument: --url" >&2
            exit 2
        fi
    fi

    if [[ -z "$domain" ]]; then
        if [[ "$json_output" = true ]]; then
            error_json "Missing required argument: --domain" 2
        else
            echo "Error: Missing required argument: --domain" >&2
            exit 2
        fi
    fi

    if [[ -z "$title" ]]; then
        if [[ "$json_output" = true ]]; then
            error_json "Missing required argument: --title" 2
        else
            echo "Error: Missing required argument: --title" >&2
            exit 2
        fi
    fi

    log_conditional "INFO" "Parameter: url = ${url:0:50}..."
    log_conditional "INFO" "Parameter: domain = ${domain}"
    log_conditional "DEBUG" "Parameter: title = ${title:0:50}..."
    log_phase "Phase 1: Input Parsing" "complete"

    # ===== PHASE 2: VALIDATION =====
    log_phase "Phase 2: Metadata Validation" "start"

    # Validation 1: URL format check
    checks_performed=$((checks_performed + 1))
    log_conditional "DEBUG" "Check 1: URL format"
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_conditional "WARN" "Validation failed: URL format invalid"
        log_metric "checks_performed" "$checks_performed" "count"
        if [[ "$json_output" = true ]]; then
            validation_failed_json "url_validation_failed" "URL must start with http:// or https://"
            exit 0
        else
            echo "Error: URL must start with http:// or https://" >&2
            exit 1
        fi
    fi

    # Validation 2: URL YAML field name leakage
    checks_performed=$((checks_performed + 1))
    log_conditional "DEBUG" "Check 2: URL YAML leakage"
    if [[ "$url" =~ source_url: ]] || [[ "$url" =~ url: ]]; then
        if [[ "$json_output" = true ]]; then
            validation_failed_json "url_validation_failed" "URL contains YAML field name (source_url: or url:)"
            exit 0
        else
            echo "Error: URL contains YAML field name" >&2
            exit 1
        fi
    fi

    # BUG-026 FIX: Correct regex pattern (remove outer bracket around colon)
    # Validation 3: Domain character check
    if [[ "$domain" =~ [:/\"] ]]; then
        if [[ "$json_output" = true ]]; then
            validation_failed_json "domain_extraction_failed" "Domain contains invalid characters (: / \")"
            exit 0
        else
            echo "Error: Domain contains invalid characters" >&2
            exit 1
        fi
    fi

    # Validation 4: Domain non-empty (meaningful content)
    # Strip whitespace and check if empty
    local domain_trimmed
    domain_trimmed="$(echo "$domain" | tr -d '[:space:]')"
    if [[ -z "$domain_trimmed" ]]; then
        if [[ "$json_output" = true ]]; then
            validation_failed_json "domain_extraction_failed" "Domain is empty"
            exit 0
        else
            echo "Error: Domain is empty" >&2
            exit 1
        fi
    fi

    # Validation 5: Title non-empty
    local title_trimmed
    title_trimmed="$(echo "$title" | tr -d '[:space:]')"
    if [[ -z "$title_trimmed" ]]; then
        if [[ "$json_output" = true ]]; then
            validation_failed_json "title_extraction_failed" "Title is empty"
            exit 0
        else
            echo "Error: Title is empty" >&2
            exit 1
        fi
    fi

    # Validation 6: Title YAML artifacts
    if [[ "$title" =~ "Obsidian Tags" ]] || [[ "$title" =~ ^[[:space:]]*#[[:space:]] ]]; then
        if [[ "$json_output" = true ]]; then
            validation_failed_json "title_extraction_failed" "Title contains YAML artifacts (Obsidian Tags or # prefix)"
            exit 0
        else
            echo "Error: Title contains YAML artifacts" >&2
            exit 1
        fi
    fi

    # Validation 7: Title normalization check
    # Ensures title is normalized before source creation to prevent deduplication failures
    local normalization_error
    if ! normalization_error="$(validate_title_normalization "$title" 2>&1)"; then
        if [[ "$json_output" = true ]]; then
            validation_failed_json "title_not_normalized" "$normalization_error: $title"
            exit 0
        else
            echo "Error: $normalization_error: $title" >&2
            exit 1
        fi
    fi

    # All validations passed
    log_conditional "INFO" "All validations passed"
    log_metric "checks_performed" "$checks_performed" "count"
    log_metric "validations_passed" 1 "boolean"
    log_phase "Phase 2: Metadata Validation" "complete"

    # ===== PHASE 3: OUTPUT =====
    log_phase "Phase 3: Result Output" "start"
    local end_time
    end_time="$(date +%s)"
    local duration=$((end_time - start_time))
    log_metric "duration" "$duration" "seconds"

    if [[ "$json_output" = true ]]; then
        log_conditional "INFO" "Outputting JSON success"
        validation_success_json
    fi

    log_phase "Phase 3: Result Output" "complete"
    exit 0
}

main "$@"
