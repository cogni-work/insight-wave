#!/usr/bin/env bash
set -euo pipefail
# validate-query-batch-schema.sh
# Version: 2.0.0
# Purpose: Validate query batch files against schema contract
#
# Sprint: 001 - Query Builder Frontmatter Schema Inconsistencies
# Created: 2025-11-17
# Updated: 2026-01-13 - Aligned with phase-3-batch-creation.md schema (v3.0.0)
#
# Usage:
#   bash validate-query-batch-schema.sh --file PATH [--json]
#   bash validate-query-batch-schema.sh --directory PATH [--json]
#
# Parameters:
#   --file PATH      Validate single file
#   --directory PATH Validate all .md files in directory
#   --json           Output JSON format (default: human-readable)
#   --help           Show usage information
#
# Exit codes:
#   0 - All validations passed
#   1 - Validation errors found
#   2 - Parameter error

# Don't use set -e as we want to continue validation even when checks fail
# set -e

# Constants
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="validate-query-batch-schema"

# Global variables
FILE_PATH=""
DIRECTORY_PATH=""
JSON_MODE=false
TOTAL_FILES=0
VALID_FILES=0
INVALID_FILES=0
declare -a VIOLATIONS=()

# Colors for human-readable output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [ "$JSON_MODE" = false ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

log_warn() {
    if [ "$JSON_MODE" = false ]; then
        echo -e "${YELLOW}[WARN]${NC} $1" >&2
    fi
}

log_error() {
    if [ "$JSON_MODE" = false ]; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    fi
}

show_help() {
    cat << EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

Validate query batch files against schema contract.

Usage:
  bash ${SCRIPT_NAME}.sh --file PATH [--json]
  bash ${SCRIPT_NAME}.sh --directory PATH [--json]

Parameters:
  --file PATH      Validate single file
  --directory PATH Validate all .md files in directory
  --json           Output JSON format
  --help           Show this help message

Examples:
  bash ${SCRIPT_NAME}.sh --file 03-query-batches/query-batch-technical.md
  bash ${SCRIPT_NAME}.sh --directory 03-query-batches/ --json

Exit codes:
  0 - All validations passed
  1 - Validation errors found
  2 - Parameter error
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --file)
                FILE_PATH="$2"
                shift 2
                ;;
            --directory)
                DIRECTORY_PATH="$2"
                shift 2
                ;;
            --json)
                JSON_MODE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown parameter: $1"
                exit 2
                ;;
        esac
    done

    # Validate parameters
    if [ -z "$FILE_PATH" ] && [ -z "$DIRECTORY_PATH" ]; then
        log_error "Either --file or --directory parameter required"
        exit 2
    fi

    if [ -n "$FILE_PATH" ] && [ -n "$DIRECTORY_PATH" ]; then
        log_error "Cannot specify both --file and --directory"
        exit 2
    fi
}

add_violation() {
    local file="$1"
    local field="$2"
    local issue="$3"
    local severity="${4:-ERROR}"

    VIOLATIONS+=("{\"file\": \"$file\", \"field\": \"$field\", \"issue\": \"$issue\", \"severity\": \"$severity\"}")
}

validate_required_field() {
    local file="$1"
    local field="$2"
    local content="$3"

    if ! echo "$content" | grep -q "^${field}:"; then
        add_violation "$file" "$field" "Missing required field"
        return 1
    fi
    return 0
}

validate_block_list_format() {
    local file="$1"
    local field="$2"
    local content="$3"

    # Check if field exists
    if ! echo "$content" | grep -q "^${field}:"; then
        return 0  # Field doesn't exist, not a formatting issue
    fi

    # Check for inline array pattern (BAD)
    if echo "$content" | grep -q "^${field}:.*\[.*\".*\".*\]"; then
        add_violation "$file" "$field" "Inline array format detected, expected YAML block list"
        return 1
    fi

    # Check for block list pattern (GOOD) - field followed by lines starting with "  - "
    local field_line="$(echo "$content" | grep -n "^${field}:" | head -1 | cut -d: -f1)"
    if [ -n "$field_line" ]; then
        local next_line=$((field_line + 1))
        local next_content="$(echo "$content" | sed -n "${next_line}p")"

        # If field is not empty array and next line doesn't start with "  - ", it's wrong format
        if [ -n "$next_content" ] && [ "$next_content" != "---" ]; then
            if ! echo "$next_content" | grep -q "^  - "; then
                # Check if it's an empty array (field: [] is acceptable for empty)
                if ! echo "$content" | grep -q "^${field}: \[\]"; then
                    add_violation "$file" "$field" "Expected YAML block list format (  - item)" "WARN"
                fi
            fi
        fi
    fi
    return 0
}

validate_no_blank_line_after_dash() {
    local file="$1"
    local content="$2"

    # Check if there's a blank line between --- and tags:
    local first_line="$(echo "$content" | sed -n '1p')"
    local second_line="$(echo "$content" | sed -n '2p')"

    if [ "$first_line" = "---" ] && [ -z "$second_line" ]; then
        add_violation "$file" "tags" "Blank line after opening --- (should be tags: immediately)" "WARN"
        return 1
    fi
    return 0
}

validate_integer_field() {
    local file="$1"
    local field="$2"
    local content="$3"

    if echo "$content" | grep -q "^${field}:"; then
        local value="$(echo "$content" | grep "^${field}:" | sed 's/^[^:]*:[[:space:]]*//')"
        if ! [[ "$value" =~ ^[0-9]+$ ]]; then
            add_violation "$file" "$field" "Expected integer, got: $value"
            return 1
        fi
    fi
    return 0
}

validate_timestamp_field() {
    local file="$1"
    local field="$2"
    local content="$3"

    if echo "$content" | grep -q "^${field}:"; then
        # For Dublin Core fields like dc:date, extract after the full field name
        local value="$(echo "$content" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//" | tr -d '"')"
        # Basic ISO 8601 format check (YYYY-MM-DDTHH:MM:SSZ or YYYY-MM-DDTHH:MM:SS+00:00)
        if ! [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            add_violation "$file" "$field" "Invalid ISO 8601 timestamp: $value"
            return 1
        fi
    fi
    return 0
}

validate_single_file() {
    local file_path="$1"
    local file_name="$(basename "$file_path")"
    local errors=0

    if [ ! -f "$file_path" ]; then
        add_violation "$file_name" "file" "File not found: $file_path"
        return 1
    fi

    # Read file content (frontmatter only, between first --- and second ---)
    # BSD sed compatible version (macOS)
    local content="$(awk '/^---$/{if(++n==1)next; if(n==2)exit} n==1{print}' "$file_path")"

    if [ -z "$content" ]; then
        add_violation "$file_name" "frontmatter" "No YAML frontmatter found"
        return 1
    fi

    # Required fields per phase-3-batch-creation.md schema (v3.0.0)
    # Core metadata
    validate_required_field "$file_name" "tags" "$content" || ((errors++))
    validate_required_field "$file_name" "dc:creator" "$content" || ((errors++))
    validate_required_field "$file_name" "dc:title" "$content" || ((errors++))
    validate_required_field "$file_name" "dc:identifier" "$content" || ((errors++))
    validate_required_field "$file_name" "entity_type" "$content" || ((errors++))

    # Batch-specific fields (new schema from batch-creator skill)
    validate_required_field "$file_name" "batch_id" "$content" || ((errors++))
    validate_required_field "$file_name" "question_id" "$content" || ((errors++))
    validate_required_field "$file_name" "query_text" "$content" || ((errors++))
    validate_required_field "$file_name" "language" "$content" || ((errors++))
    validate_required_field "$file_name" "config_count" "$content" || ((errors++))
    validate_required_field "$file_name" "queries_count" "$content" || ((errors++))
    validate_required_field "$file_name" "question_ref" "$content" || ((errors++))
    validate_required_field "$file_name" "search_configs" "$content" || ((errors++))
    validate_required_field "$file_name" "schema_version" "$content" || ((errors++))

    # No blank line after opening ---
    validate_no_blank_line_after_dash "$file_name" "$(cat "$file_path")"

    # Integer field validation
    validate_integer_field "$file_name" "config_count" "$content"
    validate_integer_field "$file_name" "queries_count" "$content"
    validate_integer_field "$file_name" "queries_executed" "$content"
    validate_integer_field "$file_name" "queries_successful" "$content"

    # Timestamp field validation (optional enrichment fields)
    validate_timestamp_field "$file_name" "dc:created" "$content"
    validate_timestamp_field "$file_name" "executed_at" "$content"

    # YAML block list format validation (optional enrichment fields)
    validate_block_list_format "$file_name" "finding_ids" "$content"
    validate_block_list_format "$file_name" "megatrend_ids" "$content"

    # Check for redundant fields (findings_count when finding_ids exists)
    if echo "$content" | grep -q "^finding_ids:" && echo "$content" | grep -q "^findings_count:"; then
        add_violation "$file_name" "findings_count" "Redundant field: findings_count exists alongside finding_ids array" "WARN"
    fi

    return $errors
}

output_json() {
    local violations_json="[]"
    if [ ${#VIOLATIONS[@]} -gt 0 ]; then
        violations_json="[$(IFS=,; echo "${VIOLATIONS[*]}")]"
    fi

    cat << EOF
{
  "schema_version": "1.0.0",
  "files_checked": $TOTAL_FILES,
  "valid": $VALID_FILES,
  "invalid": $INVALID_FILES,
  "violations": $violations_json
}
EOF
}

output_human() {
    echo ""
    echo "========================================"
    echo "Query Batch Schema Validation Report"
    echo "========================================"
    echo "Schema Version: 1.0.0"
    echo "Files Checked: $TOTAL_FILES"
    echo "Valid: $VALID_FILES"
    echo "Invalid: $INVALID_FILES"
    echo ""

    if [ ${#VIOLATIONS[@]} -gt 0 ]; then
        echo "Violations Found:"
        echo "-----------------"
        for violation in "${VIOLATIONS[@]}"; do
            local file="$(echo "$violation" | grep -o '"file": "[^"]*"' | cut -d'"' -f4)"
            local field="$(echo "$violation" | grep -o '"field": "[^"]*"' | cut -d'"' -f4)"
            local issue="$(echo "$violation" | grep -o '"issue": "[^"]*"' | cut -d'"' -f4)"
            local severity="$(echo "$violation" | grep -o '"severity": "[^"]*"' | cut -d'"' -f4)"

            if [ "$severity" = "ERROR" ]; then
                echo -e "  ${RED}[ERROR]${NC} $file: $field - $issue"
            else
                echo -e "  ${YELLOW}[WARN]${NC} $file: $field - $issue"
            fi
        done
        echo ""
    else
        echo -e "${GREEN}All files passed validation!${NC}"
        echo ""
    fi
}

main() {
    parse_arguments "$@"

    if [ -n "$FILE_PATH" ]; then
        # Single file validation
        TOTAL_FILES=1
        validate_single_file "$FILE_PATH"
        if [ ${#VIOLATIONS[@]} -eq 0 ]; then
            VALID_FILES=1
        else
            INVALID_FILES=1
        fi
    else
        # Directory validation
        if [ ! -d "$DIRECTORY_PATH" ]; then
            log_error "Directory not found: $DIRECTORY_PATH"
            exit 2
        fi

        # Support both old (query-batch-*.md) and new (question-*-batch.md) naming patterns
        for batch_file in "$DIRECTORY_PATH"/question-*-batch.md "$DIRECTORY_PATH"/query-batch-*.md; do
            [ -f "$batch_file" ] || continue
            TOTAL_FILES=$((TOTAL_FILES + 1))

            local violations_before=${#VIOLATIONS[@]}
            validate_single_file "$batch_file"
            local violations_after=${#VIOLATIONS[@]}

            if [ $violations_after -eq $violations_before ]; then
                VALID_FILES=$((VALID_FILES + 1))
            else
                INVALID_FILES=$((INVALID_FILES + 1))
            fi
        done

        if [ $TOTAL_FILES -eq 0 ]; then
            log_warn "No batch files found in $DIRECTORY_PATH (expected question-*-batch.md or query-batch-*.md)"
        fi
    fi

    # Output results
    if [ "$JSON_MODE" = true ]; then
        output_json
    else
        output_human
    fi

    # Exit with appropriate code
    if [ $INVALID_FILES -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
