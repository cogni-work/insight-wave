#!/usr/bin/env bash
set -euo pipefail
#
# validate-finding-template.sh
#
# Purpose: Validate finding entity markdown file has all mandatory fields with correct formats
#
# Usage: validate-finding-template.sh --finding-file <path> [--strict]
#
# Arguments:
#   --finding-file <path>    Path to finding markdown file (required)
#   --strict                 Exit 1 on any missing mandatory field (optional, default: false)
#
# Output: JSON object with validation results
#   {
#     "success": true|false,
#     "finding_file": "/path/to/finding.md",
#     "validations": {
#       "batch_id": {"present": true, "valid_format": true, "value": "[[...]]"},
#       "dimension_id": {"present": true, "valid_format": true, "value": "..."},
#       "finding_uuid": {"present": true, "valid_format": true, "value": "..."},
#       "source_url": {"present": true, "valid_format": true, "value": "https://..."}
#     },
#     "missing_fields": [],
#     "invalid_formats": [],
#     "errors": [],
#     "validation_passed": true|false
#   }
#
# Exit Codes:
#   0 - All validations passed
#   1 - Missing required parameters
#   2 - Finding file not found/unreadable
#   3 - Invalid frontmatter (not valid YAML)
#   4 - Mandatory fields missing (strict mode only)
#
# Example:
#   ./validate-finding-template.sh --finding-file ./findings/finding-001.md
#   ./validate-finding-template.sh --finding-file ./findings/finding-001.md --strict


# Source entity configuration for directory key resolution (required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/entity-config.sh" || {
    echo "ERROR: entity-config.sh required but not found" >&2
    exit 1
}
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"

# Error output in JSON format
error_json() {
    local msg="$1"
    local code="${2:-1}"
    jq -n --arg msg "$msg" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Extract frontmatter from markdown file
extract_frontmatter() {
    local file="$1"

    # Check if file starts with ---
    if ! head -n 1 "$file" | grep -q '^---$'; then
        return 1
    fi

    # Extract content between first two --- markers
    awk '/^---$/ {if (++count == 2) exit} count == 1 && !/^---$/ {print}' "$file"
}

# Parse YAML frontmatter field value
parse_yaml_field() {
    local yaml_content="$1"
    local field_name="$2"

    # Extract field value (handles quoted and unquoted values)
    echo "$yaml_content" | grep "^${field_name}:" | sed "s/^${field_name}:[[:space:]]*//" | sed 's/^["'\'']\(.*\)["'\'']$/\1/'
}

# Validate batch_id format (wikilink)
validate_batch_id() {
    local value="$1"
    [[ "$value" =~ ^\[\[${DIR_QUERY_BATCHES}/.+\]\]$ ]]
}

# Validate dimension_id format (non-empty string)
validate_dimension_id() {
    local value="$1"
    [[ -n "$value" ]]
}

# Validate finding_uuid format (UUID v4)
validate_finding_uuid() {
    local value="$1"
    [[ "$value" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]
}

# Validate source_url format (http/https URL)
validate_source_url() {
    local value="$1"
    [[ "$value" =~ ^https?:// ]]
}

# Validate question_ref format (wikilink to refined-questions)
validate_question_ref() {
    local value="$1"
    [[ "$value" =~ ^\[\[${DIR_REFINED_QUESTIONS}/.+\]\]$ ]]
}

main() {
    local finding_file=""
    local strict_mode=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --finding-file)
                finding_file="${2:-}"
                shift 2
                ;;
            --strict)
                strict_mode=true
                shift
                ;;
            *)
                error_json "Unknown argument: $1" 1
                ;;
        esac
    done

    # Validate required parameters
    [[ -n "$finding_file" ]] || error_json "Missing required parameter: --finding-file" 1

    # Check file exists and is readable
    [[ -f "$finding_file" ]] || error_json "Finding file not found: $finding_file" 2
    [[ -r "$finding_file" ]] || error_json "Finding file not readable: $finding_file" 2

    # Extract frontmatter
    local frontmatter
    if ! frontmatter="$(extract_frontmatter "$finding_file")"; then
        error_json "Invalid frontmatter: File must start with --- marker" 3
    fi

    [[ -n "$frontmatter" ]] || error_json "Invalid frontmatter: No content found between --- markers" 3

    # Extract field values
    local batch_id
    local dimension_id
    local finding_uuid
    local source_url

    batch_id="$(parse_yaml_field "$frontmatter" "batch_id" || echo "")"
    dimension_id="$(parse_yaml_field "$frontmatter" "dimension_id" || echo "")"
    finding_uuid="$(parse_yaml_field "$frontmatter" "finding_uuid" || echo "")"
    source_url="$(parse_yaml_field "$frontmatter" "source_url" || echo "")"
    question_ref="$(parse_yaml_field "$frontmatter" "question_ref" || echo "")"

    # Validation tracking
    local missing_fields=()
    local invalid_formats=()
    local errors=()

    # Validate batch_id
    local batch_id_present=false
    local batch_id_valid=false
    if [[ -n "$batch_id" ]]; then
        batch_id_present=true
        if validate_batch_id "$batch_id"; then
            batch_id_valid=true
        else
            invalid_formats+=("batch_id")
            errors+=("batch_id format invalid: Expected [[${DIR_QUERY_BATCHES}/...]], got: $batch_id")
        fi
    else
        missing_fields+=("batch_id")
        errors+=("batch_id is missing")
    fi

    # Validate dimension_id
    local dimension_id_present=false
    local dimension_id_valid=false
    if [[ -n "$dimension_id" ]]; then
        dimension_id_present=true
        if validate_dimension_id "$dimension_id"; then
            dimension_id_valid=true
        else
            invalid_formats+=("dimension_id")
            errors+=("dimension_id format invalid: Expected non-empty string")
        fi
    else
        missing_fields+=("dimension_id")
        errors+=("dimension_id is missing")
    fi

    # Validate finding_uuid
    local finding_uuid_present=false
    local finding_uuid_valid=false
    if [[ -n "$finding_uuid" ]]; then
        finding_uuid_present=true
        if validate_finding_uuid "$finding_uuid"; then
            finding_uuid_valid=true
        else
            invalid_formats+=("finding_uuid")
            errors+=("finding_uuid format invalid: Expected UUID v4, got: $finding_uuid")
        fi
    else
        missing_fields+=("finding_uuid")
        errors+=("finding_uuid is missing")
    fi

    # Validate source_url
    local source_url_present=false
    local source_url_valid=false
    if [[ -n "$source_url" ]]; then
        source_url_present=true
        if validate_source_url "$source_url"; then
            source_url_valid=true
        else
            invalid_formats+=("source_url")
            errors+=("source_url format invalid: Expected http/https URL, got: $source_url")
        fi
    else
        missing_fields+=("source_url")
        errors+=("source_url is missing")
    fi

    # Validate question_ref (prevents LLM hallucination of wrong directory names)
    local question_ref_present=false
    local question_ref_valid=false
    if [[ -n "$question_ref" ]]; then
        question_ref_present=true
        if validate_question_ref "$question_ref"; then
            question_ref_valid=true
        else
            invalid_formats+=("question_ref")
            errors+=("question_ref format invalid: Expected [[${DIR_REFINED_QUESTIONS}/...]], got: $question_ref")
        fi
    else
        missing_fields+=("question_ref")
        errors+=("question_ref is missing")
    fi

    # Determine overall validation status
    local validation_passed=true
    if [[ ${#missing_fields[@]} -gt 0 ]] || [[ ${#invalid_formats[@]} -gt 0 ]]; then
        validation_passed=false
    fi

    # Build JSON arrays
    local missing_fields_json
    local invalid_formats_json
    local errors_json

    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        missing_fields_json="$(printf '%s\n' "${missing_fields[@]}" | jq -R . | jq -s .)"
    else
        missing_fields_json="[]"
    fi

    if [[ ${#invalid_formats[@]} -gt 0 ]]; then
        invalid_formats_json="$(printf '%s\n' "${invalid_formats[@]}" | jq -R . | jq -s .)"
    else
        invalid_formats_json="[]"
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        errors_json="$(printf '%s\n' "${errors[@]}" | jq -R . | jq -s .)"
    else
        errors_json="[]"
    fi

    # Build validations object using jq
    local validations_json
    validations_json="$(jq -n \
        --argjson batch_present "$batch_id_present" \
        --argjson batch_valid "$batch_id_valid" \
        --arg batch_value "$batch_id" \
        --argjson dim_present "$dimension_id_present" \
        --argjson dim_valid "$dimension_id_valid" \
        --arg dim_value "$dimension_id" \
        --argjson uuid_present "$finding_uuid_present" \
        --argjson uuid_valid "$finding_uuid_valid" \
        --arg uuid_value "$finding_uuid" \
        --argjson url_present "$source_url_present" \
        --argjson url_valid "$source_url_valid" \
        --arg url_value "$source_url" \
        --argjson qref_present "$question_ref_present" \
        --argjson qref_valid "$question_ref_valid" \
        --arg qref_value "$question_ref" \
        '{
            batch_id: {
                present: $batch_present,
                valid_format: $batch_valid,
                value: $batch_value
            },
            dimension_id: {
                present: $dim_present,
                valid_format: $dim_valid,
                value: $dim_value
            },
            finding_uuid: {
                present: $uuid_present,
                valid_format: $uuid_valid,
                value: $uuid_value
            },
            source_url: {
                present: $url_present,
                valid_format: $url_valid,
                value: $url_value
            },
            question_ref: {
                present: $qref_present,
                valid_format: $qref_valid,
                value: $qref_value
            }
        }')"

    # Output final JSON
    jq -n \
        --arg file "$finding_file" \
        --argjson validations "$validations_json" \
        --argjson missing "$missing_fields_json" \
        --argjson invalid "$invalid_formats_json" \
        --argjson errors "$errors_json" \
        --argjson passed "$validation_passed" \
        '{
            success: true,
            finding_file: $file,
            validations: $validations,
            missing_fields: $missing,
            invalid_formats: $invalid,
            errors: $errors,
            validation_passed: $passed
        }'

    # Handle strict mode
    if [[ "$strict_mode" = true ]] && [[ "$validation_passed" = false ]]; then
        exit 4
    fi

    exit 0
}

main "$@"
