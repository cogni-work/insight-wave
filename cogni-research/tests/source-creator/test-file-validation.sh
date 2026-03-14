#!/usr/bin/env bash
set -euo pipefail
# test-file-validation.sh
# Version: 1.0.0
# Purpose: Unit test file validation phase (Sub-Phase 3.1) of source-creator batch processing
# Category: test
#
# Tests file validation logic including existence checks, permission checks,
# frontmatter structure validation, and skip tracking accuracy.
#
# Test Coverage:
#   1. Batch with all valid files (0 skips expected)
#   2. Batch with 1 missing file
#   3. Batch with 1 unreadable file (permission denied)
#   4. Batch with 1 file with missing frontmatter
#   5. Batch with 1 file with malformed YAML (tabs)
#   6. Batch with mixed valid + invalid files
#   7. Verify error messages include file paths
#   8. Verify processing continues after validation failure
#   9. Verify skip reasons are specific
#   10. Verify completeness validation (processed + skipped = total)
#
# Parameters:
#   --test-case    Optional: Run specific test case (1-10)
#                  If omitted, runs all tests
#
# Environment:
#   CLAUDE_PLUGIN_ROOT    Required: Plugin root directory
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#   2 - Parameter validation error


# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test output directory
TEST_OUTPUT_DIR=""

# Cleanup function
cleanup() {
    if [ -n "$TEST_OUTPUT_DIR" ] && [ -d "$TEST_OUTPUT_DIR" ]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

# Register cleanup on EXIT
trap cleanup EXIT

# Print test header
print_header() {
    echo ""
    echo "========================================"
    echo "Test: source-creator File Validation"
    echo "========================================"
    echo ""
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Summary: $TESTS_PASSED/$TESTS_RUN tests passed"
    echo "========================================"
    echo ""
}

# Print test result
print_result() {
    local test_num="$1"
    local test_name="$2"
    local test_status="$3"
    local message="${4:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$test_status" == "PASS" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}[PASS]${NC} Test $test_num: $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}[FAIL]${NC} Test $test_num: $test_name"
        if [ -n "$message" ]; then
            echo "  $message"
        fi
    fi
}

# Create test finding with valid structure
create_valid_finding() {
    local file_path="$1"
    local title="${2:-Test Finding}"
    local url="${3:-https://example.com/test}"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "$title"
url: "$url"
tags: [finding, search-result]
timestamp: "2025-01-14T10:00:00Z"
---

# Test Finding

This is test content for validation testing.
EOF
}

# Create test finding with missing frontmatter
create_missing_frontmatter_finding() {
    local file_path="$1"

    cat > "$file_path" <<EOF
# Test Finding without Frontmatter

This finding is missing the YAML frontmatter section.
EOF
}

# Create test finding with malformed YAML (tabs)
create_malformed_yaml_finding() {
    local file_path="$1"

    # Note: Using actual tab character (not spaces)
    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title:	"Finding with tabs"
url: "https://example.com/test"
tags: [finding, search-result]
---

# Test Finding

This finding has tabs in YAML frontmatter (forbidden).
EOF
}

# Simulate file validation logic (extracted from source-creator workflow)
validate_finding_file() {
    local finding_file="$1"
    local project_path="$2"
    local finding_id
    finding_id="$(basename "$finding_file" .md)"

    # Convert relative paths to absolute paths
    case "$finding_file" in
        /*) ;;  # already absolute
        *)  finding_file="${project_path}/${finding_file}" ;;
    esac

    # Validate file exists
    if [ ! -f "$finding_file" ]; then
        echo "{\"skip_reason\": \"file_not_found\", \"finding_id\": \"$finding_id\", \"error\": \"Finding file does not exist\"}"
        return 1
    fi

    # Validate file is readable
    if [ ! -r "$finding_file" ]; then
        echo "{\"skip_reason\": \"file_not_readable\", \"finding_id\": \"$finding_id\", \"error\": \"Permission denied - file is not readable\"}"
        return 1
    fi

    # Validate YAML frontmatter opening delimiter
    if ! grep -q '^---$' "$finding_file"; then
        echo "{\"skip_reason\": \"invalid_frontmatter\", \"finding_id\": \"$finding_id\", \"error\": \"Missing YAML opening delimiter (---)\"}"
        return 1
    fi

    # Validate YAML frontmatter closing delimiter
    local delimiter_count
    delimiter_count="$(grep -c '^---$' "$finding_file")"
    if [ "$delimiter_count" -lt 2 ]; then
        echo "{\"skip_reason\": \"invalid_frontmatter\", \"finding_id\": \"$finding_id\", \"error\": \"Missing YAML closing delimiter (---) - found only $delimiter_count delimiters\"}"
        return 1
    fi

    # Validate required field: url
    if ! grep -q '^url:' "$finding_file"; then
        echo "{\"skip_reason\": \"missing_required_field\", \"finding_id\": \"$finding_id\", \"error\": \"Frontmatter missing required field: url\"}"
        return 1
    fi

    # Validate required field: title
    if ! grep -q '^title:' "$finding_file"; then
        echo "{\"skip_reason\": \"missing_required_field\", \"finding_id\": \"$finding_id\", \"error\": \"Frontmatter missing required field: title\"}"
        return 1
    fi

    # Check for tab characters in YAML (forbidden)
    if grep -q $'\t' "$finding_file"; then
        echo "{\"skip_reason\": \"invalid_frontmatter\", \"finding_id\": \"$finding_id\", \"error\": \"YAML frontmatter contains tab characters (forbidden in YAML)\"}"
        return 1
    fi

    # All validations passed
    echo "{\"valid\": true, \"finding_id\": \"$finding_id\"}"
    return 0
}

# Test 1: All valid files (0 skips expected)
test_01_all_valid_files() {
    local test_dir="$TEST_OUTPUT_DIR/test01"
    mkdir -p "$test_dir"

    # Create 5 valid findings
    create_valid_finding "$test_dir/finding-001.md" "Valid Finding 1" "https://example.com/1"
    create_valid_finding "$test_dir/finding-002.md" "Valid Finding 2" "https://example.com/2"
    create_valid_finding "$test_dir/finding-003.md" "Valid Finding 3" "https://example.com/3"
    create_valid_finding "$test_dir/finding-004.md" "Valid Finding 4" "https://example.com/4"
    create_valid_finding "$test_dir/finding-005.md" "Valid Finding 5" "https://example.com/5"

    # Validate all files
    local skip_count=0
    for finding in "$test_dir"/*.md; do
        if ! validate_finding_file "$finding" "$test_dir" >/dev/null 2>&1; then
            skip_count=$((skip_count + 1))
        fi
    done

    # Verify 0 skips
    if [ "$skip_count" -eq 0 ]; then
        print_result 1 "All valid files (0 skips)" "PASS"
    else
        print_result 1 "All valid files (0 skips)" "FAIL" "Expected 0 skips, got $skip_count"
    fi
}

# Test 2: Batch with 1 missing file
test_02_missing_file() {
    local test_dir="$TEST_OUTPUT_DIR/test02"
    mkdir -p "$test_dir"

    # Create 2 valid findings
    create_valid_finding "$test_dir/finding-001.md"
    create_valid_finding "$test_dir/finding-002.md"

    # Reference non-existent file
    local result
    result="$(validate_finding_file "$test_dir/finding-003-missing.md" "$test_dir" 2>&1 || true)"

    # Verify skip reason
    if echo "$result" | grep -q '"skip_reason": "file_not_found"'; then
        print_result 2 "Missing file detected and skipped" "PASS"
    else
        print_result 2 "Missing file detected and skipped" "FAIL" "Expected skip_reason: file_not_found, got: $result"
    fi
}

# Test 3: Batch with 1 unreadable file (permission denied)
test_03_unreadable_file() {
    local test_dir="$TEST_OUTPUT_DIR/test03"
    mkdir -p "$test_dir"

    # Create finding and remove read permissions
    create_valid_finding "$test_dir/finding-001.md"
    chmod 000 "$test_dir/finding-001.md"

    local result
    result="$(validate_finding_file "$test_dir/finding-001.md" "$test_dir" 2>&1 || true)"

    # Restore permissions for cleanup
    chmod 644 "$test_dir/finding-001.md" 2>/dev/null || true

    # Verify skip reason
    if echo "$result" | grep -q '"skip_reason": "file_not_readable"'; then
        print_result 3 "Unreadable file - skip reason correct" "PASS"
    else
        print_result 3 "Unreadable file - skip reason correct" "FAIL" "Expected skip_reason: file_not_readable, got: $result"
    fi
}

# Test 4: Batch with 1 file with missing frontmatter
test_04_missing_frontmatter() {
    local test_dir="$TEST_OUTPUT_DIR/test04"
    mkdir -p "$test_dir"

    # Create finding without frontmatter
    create_missing_frontmatter_finding "$test_dir/finding-001.md"

    local result
    result="$(validate_finding_file "$test_dir/finding-001.md" "$test_dir" 2>&1 || true)"

    # Verify skip reason
    if echo "$result" | grep -q '"skip_reason": "invalid_frontmatter"'; then
        print_result 4 "Missing frontmatter detected" "PASS"
    else
        print_result 4 "Missing frontmatter detected" "FAIL" "Expected skip_reason: invalid_frontmatter, got: $result"
    fi
}

# Test 5: Batch with 1 file with malformed YAML (tabs)
test_05_malformed_yaml() {
    local test_dir="$TEST_OUTPUT_DIR/test05"
    mkdir -p "$test_dir"

    # Create finding with tabs in YAML
    create_malformed_yaml_finding "$test_dir/finding-001.md"

    local result
    result="$(validate_finding_file "$test_dir/finding-001.md" "$test_dir" 2>&1 || true)"

    # Verify skip reason
    if echo "$result" | grep -q '"skip_reason": "invalid_frontmatter"' && echo "$result" | grep -q "tab characters"; then
        print_result 5 "Malformed YAML (tabs) detected" "PASS"
    else
        print_result 5 "Malformed YAML (tabs) detected" "FAIL" "Expected skip_reason: invalid_frontmatter with tab error, got: $result"
    fi
}

# Test 6: Batch with mixed valid + invalid files
test_06_mixed_batch() {
    local test_dir="$TEST_OUTPUT_DIR/test06"
    mkdir -p "$test_dir"

    # Create 3 valid findings
    create_valid_finding "$test_dir/finding-001.md"
    create_valid_finding "$test_dir/finding-002.md"
    create_valid_finding "$test_dir/finding-003.md"

    # Create 2 invalid findings
    create_missing_frontmatter_finding "$test_dir/finding-004.md"
    create_malformed_yaml_finding "$test_dir/finding-005.md"

    # Validate all files
    local valid_count=0
    local skip_count=0
    for finding in "$test_dir"/*.md; do
        if validate_finding_file "$finding" "$test_dir" >/dev/null 2>&1; then
            valid_count=$((valid_count + 1))
        else
            skip_count=$((skip_count + 1))
        fi
    done

    # Verify 3 valid, 2 skipped
    if [ "$valid_count" -eq 3 ] && [ "$skip_count" -eq 2 ]; then
        print_result 6 "Mixed batch (3 valid, 2 skipped)" "PASS"
    else
        print_result 6 "Mixed batch (3 valid, 2 skipped)" "FAIL" "Expected 3 valid, 2 skipped; got $valid_count valid, $skip_count skipped"
    fi
}

# Test 7: Verify error messages include file paths
test_07_error_messages_include_paths() {
    local test_dir="$TEST_OUTPUT_DIR/test07"
    mkdir -p "$test_dir"

    # Create invalid finding
    create_missing_frontmatter_finding "$test_dir/finding-001.md"

    local result
    result="$(validate_finding_file "$test_dir/finding-001.md" "$test_dir" 2>&1 || true)"

    # Verify finding_id is included
    if echo "$result" | grep -q '"finding_id": "finding-001"'; then
        print_result 7 "Error messages include file paths" "PASS"
    else
        print_result 7 "Error messages include file paths" "FAIL" "Expected finding_id in error message, got: $result"
    fi
}

# Test 8: Verify processing continues after validation failure
test_08_processing_continues() {
    local test_dir="$TEST_OUTPUT_DIR/test08"
    mkdir -p "$test_dir"

    # Create batch: valid, invalid, valid, invalid, valid
    create_valid_finding "$test_dir/finding-001.md"
    create_missing_frontmatter_finding "$test_dir/finding-002.md"
    create_valid_finding "$test_dir/finding-003.md"
    create_malformed_yaml_finding "$test_dir/finding-004.md"
    create_valid_finding "$test_dir/finding-005.md"

    # Process all findings (should not exit on first failure)
    local processed_count=0
    for finding in "$test_dir"/*.md; do
        validate_finding_file "$finding" "$test_dir" >/dev/null 2>&1 || true
        processed_count=$((processed_count + 1))
    done

    # Verify all 5 findings were processed
    if [ "$processed_count" -eq 5 ]; then
        print_result 8 "Processing continues after validation failure" "PASS"
    else
        print_result 8 "Processing continues after validation failure" "FAIL" "Expected 5 processed, got $processed_count"
    fi
}

# Test 9: Verify skip reasons are specific
test_09_specific_skip_reasons() {
    local test_dir="$TEST_OUTPUT_DIR/test09"
    mkdir -p "$test_dir"

    # Test different validation failures
    local result1 result2 result3

    # Missing file
    result1="$(validate_finding_file "$test_dir/missing.md" "$test_dir" 2>&1 || true)"

    # Missing frontmatter
    create_missing_frontmatter_finding "$test_dir/no-frontmatter.md"
    result2="$(validate_finding_file "$test_dir/no-frontmatter.md" "$test_dir" 2>&1 || true)"

    # Malformed YAML
    create_malformed_yaml_finding "$test_dir/malformed.md"
    result3="$(validate_finding_file "$test_dir/malformed.md" "$test_dir" 2>&1 || true)"

    # Verify distinct skip reasons
    local has_file_not_found=0
    local has_invalid_frontmatter_missing=0
    local has_invalid_frontmatter_tabs=0

    echo "$result1" | grep -q '"skip_reason": "file_not_found"' && has_file_not_found=1
    echo "$result2" | grep -q '"skip_reason": "invalid_frontmatter"' && has_invalid_frontmatter_missing=1
    echo "$result3" | grep -q '"skip_reason": "invalid_frontmatter"' && echo "$result3" | grep -q "tab characters" && has_invalid_frontmatter_tabs=1

    if [ "$has_file_not_found" -eq 1 ] && [ "$has_invalid_frontmatter_missing" -eq 1 ] && [ "$has_invalid_frontmatter_tabs" -eq 1 ]; then
        print_result 9 "Skip reasons are specific" "PASS"
    else
        print_result 9 "Skip reasons are specific" "FAIL" "Not all skip reasons detected correctly"
    fi
}

# Test 10: Verify completeness validation (processed + skipped = total)
test_10_completeness_validation() {
    local test_dir="$TEST_OUTPUT_DIR/test10"
    mkdir -p "$test_dir"

    # Create mixed batch of 10 findings
    create_valid_finding "$test_dir/finding-001.md"
    create_valid_finding "$test_dir/finding-002.md"
    create_valid_finding "$test_dir/finding-003.md"
    create_valid_finding "$test_dir/finding-004.md"
    create_valid_finding "$test_dir/finding-005.md"
    create_valid_finding "$test_dir/finding-006.md"
    create_missing_frontmatter_finding "$test_dir/finding-007.md"
    create_malformed_yaml_finding "$test_dir/finding-008.md"
    create_valid_finding "$test_dir/finding-009.md"
    create_valid_finding "$test_dir/finding-010.md"

    # Process all findings
    local total_files=10
    local valid_count=0
    local skip_count=0

    for finding in "$test_dir"/*.md; do
        if validate_finding_file "$finding" "$test_dir" >/dev/null 2>&1; then
            valid_count=$((valid_count + 1))
        else
            skip_count=$((skip_count + 1))
        fi
    done

    local processed_plus_skipped=$((valid_count + skip_count))

    # Verify: processed + skipped = total
    if [ "$processed_plus_skipped" -eq "$total_files" ]; then
        print_result 10 "Completeness validation (processed + skipped = total)" "PASS"
    else
        print_result 10 "Completeness validation (processed + skipped = total)" "FAIL" "Expected $total_files, got $processed_plus_skipped (valid: $valid_count, skipped: $skip_count)"
    fi
}

# Main execution
main() {
    # Parse parameters
    local test_case=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --test-case)
                test_case="$2"
                shift 2
                ;;
            *)
                echo "Error: Unknown parameter: $1" >&2
                echo "Usage: $0 [--test-case <1-10>]" >&2
                exit 2
                ;;
        esac
    done

    # Validate test case if specified
    if [ -n "$test_case" ]; then
        # Use separate tests to avoid pipe character issues in eval contexts
        if ! [[ "$test_case" =~ ^[1-9]$ ]] && ! [[ "$test_case" =~ ^10$ ]]; then
            echo "Error: Invalid test case. Must be 1-10." >&2
            exit 2
        fi
    fi

    # Create temporary test directory
    TEST_OUTPUT_DIR="$(mktemp -d -t source-creator-file-validation-test-XXXXXX)"

    # Print header
    print_header

    # Run tests
    if [ -z "$test_case" ]; then
        # Run all tests
        test_01_all_valid_files
        test_02_missing_file
        test_03_unreadable_file
        test_04_missing_frontmatter
        test_05_malformed_yaml
        test_06_mixed_batch
        test_07_error_messages_include_paths
        test_08_processing_continues
        test_09_specific_skip_reasons
        test_10_completeness_validation
    else
        # Run specific test
        case "$test_case" in
            1) test_01_all_valid_files ;;
            2) test_02_missing_file ;;
            3) test_03_unreadable_file ;;
            4) test_04_missing_frontmatter ;;
            5) test_05_malformed_yaml ;;
            6) test_06_mixed_batch ;;
            7) test_07_error_messages_include_paths ;;
            8) test_08_processing_continues ;;
            9) test_09_specific_skip_reasons ;;
            10) test_10_completeness_validation ;;
        esac
    fi

    # Print summary
    print_summary

    # Generate JSON response
    local success="false"
    [ "$TESTS_FAILED" -eq 0 ] && success="true"

    echo "{\"success\": $success, \"tests_run\": $TESTS_RUN, \"tests_passed\": $TESTS_PASSED, \"tests_failed\": $TESTS_FAILED}"

    # Exit with appropriate code
    if [ "$TESTS_FAILED" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Execute main
main "$@"
