#!/usr/bin/env bash
set -euo pipefail
# validate-interface-compliance.sh
# Version: 1.0.0
# Purpose: Validate all scripts against interface specification standards
# Category: validators
#
# Usage:
#   validate-interface-compliance.sh --plugin-path <path> [OPTIONS]
#
# Arguments:
#   --plugin-path <path>   Plugin directory path (required)
#   --min-score <number>   Minimum compliance score (optional, default: 95)
#   --json                 Output JSON format (optional flag)
#   --verbose              Show detailed validation output (optional flag)
#
# Output (JSON mode):
#   {
#     "success": boolean,
#     "data": {
#       "compliance_score": number,
#       "scripts_validated": number,
#       "checks_passed": number,
#       "checks_failed": number,
#       "issues": [{...}]
#     }
#   }
#
# Exit codes:
#   0 - Compliance meets or exceeds minimum score
#   1 - Compliance below minimum score
#   2 - Invalid arguments
#
# Example:
#   validate-interface-compliance.sh --plugin-path "/path/to/cogni-research" \
#     --min-score 95 --json


# Configuration
PLUGIN_PATH=""
MIN_SCORE=95
JSON_OUTPUT=false
VERBOSE=false

# Counters
TOTAL_SCRIPTS=0
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Issue tracking
declare -a ISSUES=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handler
error_json() {
    local message="$1"
    local code="${2:-2}"
    jq -n --arg msg "$message" --argjson code "$code" \
        '{success: false, error: $msg, error_code: $code}' >&2
    exit "$code"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --plugin-path)
            PLUGIN_PATH="${2:-}"
            shift 2
            ;;
        --min-score)
            MIN_SCORE="${2:-95}"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        "")
            # Empty argument, skip
            shift
            ;;
        *)
            error_json "Unknown argument: $1" 2
            ;;
    esac
done

# Validate required arguments
[[ -n "$PLUGIN_PATH" ]] || error_json "Missing required argument: --plugin-path" 2
[[ -d "$PLUGIN_PATH" ]] || error_json "Plugin path not found: $PLUGIN_PATH" 2

# Normalize path
PLUGIN_PATH="$(cd "$PLUGIN_PATH" && pwd)"
SCRIPTS_DIR="$PLUGIN_PATH/scripts"
CONTRACTS_DIR="$PLUGIN_PATH/contracts"

[[ -d "$SCRIPTS_DIR" ]] || error_json "Scripts directory not found: $SCRIPTS_DIR" 2

# Logging functions
log_verbose() {
    if [[ "$VERBOSE" == true ]] && [[ "$JSON_OUTPUT" == false ]]; then
        echo "$@"
    fi
}

log_check() {
    local check_status="$1"
    local script="$2"
    local check_name="$3"
    local message="$4"

    if [[ "$check_status" == "PASS" ]]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        log_verbose "${GREEN}✓${NC} $script: $check_name"
    else
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        ISSUES+=("{\"script\": \"$script\", \"check\": \"$check_name\", \"message\": \"$message\"}")
        if [[ "$VERBOSE" == true ]] && [[ "$JSON_OUTPUT" == false ]]; then
            echo -e "${RED}✗${NC} $script: $check_name - $message"
        fi
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Validation functions
validate_file_identification() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    # Check line 2: script name
    local line2="$(sed -n '2p' "$script_path" | sed 's/^# //')"
    if [[ "$line2" == "$script_name" ]]; then
        log_check "PASS" "$script_name" "file_identification_name" ""
    else
        log_check "FAIL" "$script_name" "file_identification_name" "Line 2: expected format '# $script_name' (found: $line2)"
    fi

    # Check line 3: Version field
    local line3="$(sed -n '3p' "$script_path")"
    if echo "$line3" | grep -q "^# Version:"; then
        log_check "PASS" "$script_name" "file_identification_version" ""
    else
        log_check "FAIL" "$script_name" "file_identification_version" "Line 3: expected format '# Version: X.Y.Z'"
    fi

    # Check line 4: Purpose field
    local line4="$(sed -n '4p' "$script_path")"
    if echo "$line4" | grep -q "^# Purpose:"; then
        log_check "PASS" "$script_name" "file_identification_purpose" ""
    else
        log_check "FAIL" "$script_name" "file_identification_purpose" "Line 4: expected format '# Purpose: ...'"
    fi

    # Check line 5: Category field
    local line5="$(sed -n '5p' "$script_path")"
    if echo "$line5" | grep -q "^# Category:"; then
        log_check "PASS" "$script_name" "file_identification_category" ""
    else
        log_check "FAIL" "$script_name" "file_identification_category" "Line 5: expected format '# Category: ...'"
    fi
}

validate_usage_section() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if grep -q "^# Usage:" "$script_path"; then
        log_check "PASS" "$script_name" "usage_section_exists" ""
    else
        log_check "FAIL" "$script_name" "usage_section_exists" "Missing Usage section"
    fi
}

validate_arguments_section() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    # Check if Arguments section exists
    if grep -q "^# Arguments:" "$script_path"; then
        log_check "PASS" "$script_name" "arguments_section_exists" ""

        # Check if arguments have type specifications
        if grep -A 10 "^# Arguments:" "$script_path" | grep -q "<string>\|<path>\|<number>\|<file>"; then
            log_check "PASS" "$script_name" "arguments_have_types" ""
        else
            # Check if it's a utility library (has Functions instead)
            if grep -q "^# Functions:" "$script_path"; then
                log_check "PASS" "$script_name" "arguments_have_types" "Utility library uses Functions section"
            else
                log_check "FAIL" "$script_name" "arguments_have_types" "Arguments missing type specifications like <string>, <path>"
            fi
        fi
    else
        # Check if it's a utility library
        if grep -q "^# Functions:" "$script_path"; then
            log_check "PASS" "$script_name" "arguments_section_exists" "Utility library uses Functions section"
            log_check "PASS" "$script_name" "arguments_have_types" "Utility library pattern"
        else
            log_check "FAIL" "$script_name" "arguments_section_exists" "Missing Arguments section"
            log_check "FAIL" "$script_name" "arguments_have_types" "No Arguments or Functions section"
        fi
    fi
}

validate_output_section() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if grep -q "^# Output" "$script_path"; then
        log_check "PASS" "$script_name" "output_section_exists" ""

        # Check for JSON schema in Output section
        if grep -A 15 "^# Output" "$script_path" | grep -q "success.*boolean"; then
            log_check "PASS" "$script_name" "output_has_schema" ""
        else
            log_check "FAIL" "$script_name" "output_has_schema" "Output section missing complete JSON schema"
        fi
    else
        log_check "FAIL" "$script_name" "output_section_exists" "Missing Output section"
        log_check "FAIL" "$script_name" "output_has_schema" "No Output section"
    fi
}

validate_exit_codes_section() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if grep -q "^# Exit codes:" "$script_path" || grep -q "^# Exit Codes:" "$script_path"; then
        log_check "PASS" "$script_name" "exit_codes_section" ""
    else
        log_check "FAIL" "$script_name" "exit_codes_section" "Missing Exit codes section"
    fi
}

validate_example_section() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if grep -q "^# Example:" "$script_path"; then
        log_check "PASS" "$script_name" "example_section" ""
    else
        log_check "FAIL" "$script_name" "example_section" "Missing Example section"
    fi
}

validate_contract_exists() {
    local script_path="$1"
    local script_name="$(basename "$script_path" .sh)"
    local contract_path="$CONTRACTS_DIR/${script_name}.yml"

    if [[ -f "$contract_path" ]]; then
        log_check "PASS" "$script_name.sh" "contract_exists" ""

        # Check if contract version matches script version
        local script_version="$(grep "^# Version:" "$script_path" | sed 's/^# Version: //' | xargs)"
        local contract_version="$(grep "^version:" "$contract_path" | sed 's/^version: //' | xargs)"

        if [[ "$script_version" == "$contract_version" ]]; then
            log_check "PASS" "$script_name.sh" "contract_version_match" ""
        else
            log_check "FAIL" "$script_name.sh" "contract_version_match" "Script version ($script_version) != Contract version ($contract_version)"
        fi
    else
        log_check "FAIL" "$script_name.sh" "contract_exists" "Contract file missing: $contract_path"
        log_check "FAIL" "$script_name.sh" "contract_version_match" "No contract to check version"
    fi
}

# Main validation loop
main() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo "Validating scripts in: $SCRIPTS_DIR"
        echo "Contracts directory: $CONTRACTS_DIR"
        echo ""
    fi

    # Find all production scripts
    for script in "$SCRIPTS_DIR"/*.sh; do
        # Skip test scripts and backups
        if [[ "$(basename "$script")" == test-* ]] || [[ "$script" == *".backups"* ]]; then
            continue
        fi

        if [[ ! -f "$script" ]]; then
            continue
        fi

        TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))

        if [[ "$VERBOSE" == true ]] && [[ "$JSON_OUTPUT" == false ]]; then
            echo -e "\n${YELLOW}Validating: $(basename "$script")${NC}"
        fi

        # Run all validation checks
        validate_file_identification "$script"
        validate_usage_section "$script"
        validate_arguments_section "$script"
        validate_output_section "$script"
        validate_exit_codes_section "$script"
        validate_example_section "$script"
        validate_contract_exists "$script"
    done

    # Calculate compliance score
    local compliance_score=0
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        compliance_score="$(echo "scale=2; ($PASSED_CHECKS / $TOTAL_CHECKS) * 100" | bc)"
    fi

    # Output results
    if [[ "$JSON_OUTPUT" == true ]]; then
        # Build issues JSON array
        local issues_json="[]"
        if [[ ${#ISSUES[@]} -gt 0 ]]; then
            issues_json="$(printf '%s\n' "${ISSUES[@]}" | jq -s '.')"
        fi

        jq -n \
            --argjson success "$(if (( $(echo "$compliance_score >= $MIN_SCORE" | bc -l) )); then echo true; else echo false; fi)" \
            --argjson score "$compliance_score" \
            --argjson scripts "$TOTAL_SCRIPTS" \
            --argjson passed "$PASSED_CHECKS" \
            --argjson failed "$FAILED_CHECKS" \
            --argjson total "$TOTAL_CHECKS" \
            --argjson min_score "$MIN_SCORE" \
            --argjson issues "$issues_json" \
            '{
                success: $success,
                data: {
                    compliance_score: $score,
                    scripts_validated: $scripts,
                    checks_passed: $passed,
                    checks_failed: $failed,
                    total_checks: $total,
                    minimum_score: $min_score,
                    issues: $issues
                }
            }'
    else
        echo ""
        echo "========================================"
        echo "VALIDATION RESULTS"
        echo "========================================"
        echo ""
        echo "Scripts validated: $TOTAL_SCRIPTS"
        echo "Total checks:      $TOTAL_CHECKS"
        echo -e "${GREEN}Checks passed:     $PASSED_CHECKS${NC}"
        echo -e "${RED}Checks failed:     $FAILED_CHECKS${NC}"
        echo ""
        echo -e "Compliance score:  ${YELLOW}${compliance_score}%${NC}"
        echo -e "Minimum required:  ${MIN_SCORE}%"
        echo ""

        if (( $(echo "$compliance_score >= $MIN_SCORE" | bc -l) )); then
            echo -e "${GREEN}✓ PASS${NC} - Compliance meets minimum requirement"
            echo ""
        else
            echo -e "${RED}✗ FAIL${NC} - Compliance below minimum requirement"
            echo ""
            echo "Issues found: ${#ISSUES[@]}"
            if [[ ${#ISSUES[@]} -gt 0 ]]; then
                echo ""
                echo "Top issues:"
                printf '%s\n' "${ISSUES[@]}" | jq -r '"\(.script): \(.check) - \(.message)"' | head -10
            fi
            echo ""
        fi
    fi

    # Exit based on compliance
    if (( $(echo "$compliance_score >= $MIN_SCORE" | bc -l) )); then
        exit 0
    else
        exit 1
    fi
}

# Run main
main
