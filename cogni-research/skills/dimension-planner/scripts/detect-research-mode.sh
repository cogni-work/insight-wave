#!/usr/bin/env bash
set -euo pipefail
# detect-research-mode.sh
# Version: 1.0.0
# Purpose: Extract research_type from question file frontmatter and determine execution mode
# Category: validators
#
# Description:
#   Extract research_type from question file frontmatter, determine execution mode
#   (domain-based vs research-type-specific), and resolve template path.
#
# Usage:
#   bash detect-research-mode.sh --question-file <path> --json
#
# Arguments:
#   --question-file <path>    Absolute path to question file (required)
#   --json                    Output JSON format (required)
#
# Output (JSON):
#   Success (domain-based):
#   {
#     "success": true,
#     "research_type": "generic",
#     "dimensions_mode": "domain-based",
#     "template_path": null
#   }
#
#   Success (research-type-specific):
#   {
#     "success": true,
#     "research_type": "lean-canvas",
#     "dimensions_mode": "research-type-specific",
#     "template_path": "/full/path/to/dimensions-lean-canvas.md"
#   }
#
#   Failure:
#   {
#     "success": false,
#     "error": "Template not found for research_type: business-model-canvas",
#     "hint": "Available templates: lean-canvas, generic. Set research_type: generic to use domain-based planning."
#   }
#
# Exit codes:
#   0 - Success
#   1 - Validation error or template not found
#   2 - Invalid arguments
#
# Example:
#   bash detect-research-mode.sh --question-file /path/to/question.md --json


# ============================================================================
# Enhanced Logging Integration
# ============================================================================

# Source enhanced logging (with fallback)
if [[ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/enhanced-logging.sh" ]]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging functions
  log_conditional() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[$1] $2" >&2; }
  log_phase() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[PHASE] $1: $2" >&2; }
  log_metric() { [[ "${DEBUG_MODE:-false}" == "true" ]] && echo "[METRIC] $1=$2 ($3)" >&2; }
fi

# ============================================================================
# Error Handling
# ============================================================================

error_json() {
    local msg="$1"
    local hint="${2:-}"
    local code="${3:-1}"

    if [[ -n "$hint" ]]; then
        jq -n --arg msg "$msg" --arg hint "$hint" --argjson code "$code" \
            '{success: false, error: $msg, hint: $hint, error_code: $code}' >&2
    else
        jq -n --arg msg "$msg" --argjson code "$code" \
            '{success: false, error: $msg, error_code: $code}' >&2
    fi
    exit "$code"
}

# ============================================================================
# Available Templates Discovery
# ============================================================================

get_available_templates() {
    local plugin_root="$1"
    local research_types_dir="${plugin_root}/references/research-types"

    local templates=()

    # Always include generic
    templates+=("generic")

    # Find all dimension template files
    if [[ -d "$research_types_dir" ]]; then
        while IFS= read -r template_file; do
            local filename="$(basename "$template_file")"
            # Extract research type from dimensions-{type}.md pattern
            if [[ "$filename" =~ ^dimensions-(.+)\.md$ ]]; then
                local research_type="${BASH_REMATCH[1]}"
                templates+=("$research_type")
            fi
        done < <(find "$research_types_dir" -name "dimensions-*.md" -type f 2>/dev/null || true)
    fi

    # Return comma-separated list
    local IFS=', '
    echo "${templates[*]}"
}

# ============================================================================
# YAML Frontmatter Extraction
# ============================================================================

extract_research_type() {
    local question_file="$1"

    # Extract YAML frontmatter between --- delimiters
    local frontmatter
    frontmatter="$(sed -n '/^---$/,/^---$/p' "$question_file" 2>/dev/null || echo "")"

    if [[ -z "$frontmatter" ]]; then
        echo "generic"
        return 0
    fi

    # Extract research_type field using grep and sed
    local research_type
    research_type="$(echo "$frontmatter" | grep -E '^research_type:' | sed -E 's/^research_type:[[:space:]]*//; s/[[:space:]]*$//' || echo "")"

    # Remove quotes if present
    research_type="$(echo "$research_type" | sed -E 's/^["'\'']//; s/["'\'']$//')"

    # Default to generic if empty
    if [[ -z "$research_type" ]]; then
        # Check if body mentions research type (helpful diagnostic)
        if grep -qE "(\*\*)?Research Type(\*\*)?" "$question_file" 2>/dev/null; then
            # Always log warning (not conditional on DEBUG_MODE)
            echo "[WARN] research_type field missing in frontmatter, but found in body. Consider adding to YAML frontmatter." >&2
        fi
        echo "generic"
    else
        echo "$research_type"
    fi
}

# ============================================================================
# Template Path Resolution
# ============================================================================

resolve_template_path() {
    local plugin_root="$1"
    local research_type="$2"

    if [[ "$research_type" == "generic" ]]; then
        echo ""
        return 0
    fi

    # New flat structure (Sprint 438+): research-types/{type}.md
    local flat_path="${plugin_root}/references/research-types/${research_type}.md"

    if [[ -f "$flat_path" ]]; then
        log_conditional INFO "Loading flat template: ${flat_path}"
        echo "$flat_path"
        return 0
    fi

    # Fallback to old subdirectory structure (deprecated)
    local subdir_path="${plugin_root}/references/research-types/${research_type}/dimensions.md"

    if [[ -f "$subdir_path" ]]; then
        log_conditional WARN "Using deprecated subdirectory template. Migrate to flat structure: research-types/${research_type}.md"
        echo "$subdir_path"
        return 0
    fi

    # Legacy skill-local location (very old)
    local legacy_path="${plugin_root}/skills/dimension-planner/references/research-types/${research_type}/dimensions-${research_type}.md"

    if [[ -f "$legacy_path" ]]; then
        log_conditional WARN "Using legacy skill-local template. Migrate to: references/research-types/${research_type}.md"
        echo "$legacy_path"
        return 0
    fi

    # No template found
    log_conditional ERROR "Template not found for research_type: ${research_type}"
    echo ""
    return 1
}

# ============================================================================
# Mode Determination
# ============================================================================

determine_mode() {
    local research_type="$1"
    local template_exists="$2"

    if [[ "$research_type" == "generic" ]]; then
        echo "domain-based"
        return 0
    fi

    if [[ "$template_exists" == "true" ]]; then
        echo "research-type-specific"
        return 0
    fi

    # research_type specified but template missing - error case
    echo "error"
    return 1
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    # Validate CLAUDE_PLUGIN_ROOT
    if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        error_json "CLAUDE_PLUGIN_ROOT environment variable not set" "" 2
    fi

    local plugin_root="${CLAUDE_PLUGIN_ROOT}"
    local question_file=""
    local json_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --question-file)
                [[ $# -lt 2 ]] && error_json "Missing value for --question-file" "" 2
                question_file="$2"
                shift 2
                ;;
            --json)
                json_flag=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" "" 2
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$question_file" ]]; then
        error_json "Missing required argument: --question-file" "" 2
    fi

    if ! [[ "$json_flag" == true ]]; then
        error_json "Missing required argument: --json" "" 2
    fi

    # Validate question file exists
    if [[ ! -f "$question_file" ]]; then
        error_json "Question file not found: ${question_file}" "" 1
    fi

    # Validate question file is readable
    if [[ ! -r "$question_file" ]]; then
        error_json "Question file not readable: ${question_file}" "" 1
    fi

    log_phase "Research Mode Detection" "start"

    # Extract research type from frontmatter
    local research_type
    research_type="$(extract_research_type "$question_file")"

    log_conditional "INFO" "Detected research_type: ${research_type}"
    log_metric "research_type" "${research_type}" "string"

    # Resolve template path
    local template_path=""
    local template_exists=false

    if ! [[ "$research_type" == "generic" ]]; then
        if template_path="$(resolve_template_path "$plugin_root" "$research_type")"; then
            template_exists=true
        fi
    fi

    if [[ -n "$template_path" ]]; then
        log_conditional "DEBUG" "Template path resolved: ${template_path}"
    else
        log_conditional "DEBUG" "No template path (domain-based mode)"
    fi

    # Determine mode
    local mode
    if ! mode="$(determine_mode "$research_type" "$template_exists")"; then
        # research_type specified but template not found - error case
        local available_templates
        available_templates="$(get_available_templates "$plugin_root")"
        error_json "Template not found for research_type: ${research_type}" \
                   "Available templates: ${available_templates}. Set research_type: generic to use domain-based planning." \
                   1
    fi

    log_conditional "INFO" "Dimensions mode: ${mode}"
    log_metric "dimensions_mode" "${mode}" "string"

    log_phase "Research Mode Detection" "complete"

    # Output success JSON
    if [[ "$mode" == "domain-based" ]]; then
        jq -n \
            --arg research_type "$research_type" \
            --arg mode "$mode" \
            '{
                success: true,
                research_type: $research_type,
                dimensions_mode: $mode,
                template_path: null
            }'
    else
        jq -n \
            --arg research_type "$research_type" \
            --arg mode "$mode" \
            --arg template_path "$template_path" \
            '{
                success: true,
                research_type: $research_type,
                dimensions_mode: $mode,
                template_path: $template_path
            }'
    fi
}

main "$@"
