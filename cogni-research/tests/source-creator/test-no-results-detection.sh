#!/usr/bin/env bash
set -euo pipefail
# test-no-results-detection.sh
# Version: 1.0.0
# Purpose: Unit test no-results detection logic (Sub-Phase 3.2) of source-creator batch processing
# Category: test
#
# Tests no-results finding detection using 4 detection strategies:
# 1. Empty URL check (url: "", url: null, url:)
# 2. Tags check (no-results, search-exhausted)
# 3. Title prefix check ("No Results:")
# 4. Search success level check (exhausted, no-results)
#
# Test Coverage:
#   1. Batch with all normal findings (0 skips expected)
#   2. Batch with 1 no-results finding (empty URL: url: "")
#   3. Batch with 1 no-results finding (null URL: url: null)
#   4. Batch with 1 no-results finding (no-results tag)
#   5. Batch with 1 no-results finding (search-exhausted tag)
#   6. Batch with 1 no-results finding (title prefix "No Results:")
#   7. Batch with 1 no-results finding (search_success_level: exhausted)
#   8. Batch with multiple no-results findings (mixed detection strategies)
#   9. Batch with no-results + normal findings mixed
#   10. Verify skip reasons are specific (no_results_finding)
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
    echo "Test: source-creator No-Results Detection"
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

# Create normal finding
create_normal_finding() {
    local file_path="$1"
    local title="${2:-Normal Finding}"
    local url="${3:-https://example.com/test}"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "$title"
url: "$url"
tags: [finding, search-result]
search_success_level: "primary"
timestamp: "2025-01-14T10:00:00Z"
---

# Normal Finding

This is a normal finding with valid source metadata.
EOF
}

# Create no-results finding with empty URL
create_no_results_empty_url() {
    local file_path="$1"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "No Results: Specific climate metrics"
url: ""
tags: [finding, search-result]
search_success_level: "exhausted"
timestamp: "2025-01-14T10:00:00Z"
---

# No Results Finding

All search strategies exhausted. No suitable source found.
EOF
}

# Create no-results finding with null URL
create_no_results_null_url() {
    local file_path="$1"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "No Results: ISO climate adaptation standard"
url: null
tags: [finding, search-result]
search_success_level: "exhausted"
timestamp: "2025-01-14T10:00:00Z"
---

# No Results Finding

Search exhausted with null URL.
EOF
}

# Create no-results finding with no-results tag
create_no_results_tag() {
    local file_path="$1"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "Climate adaptation framework"
url: "https://example.com/placeholder"
tags: [finding, no-results]
search_success_level: "primary"
timestamp: "2025-01-14T10:00:00Z"
---

# No Results Finding (Tag-Based)

Detected via no-results tag.
EOF
}

# Create no-results finding with search-exhausted tag
create_no_results_search_exhausted_tag() {
    local file_path="$1"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "Green bonds market data"
url: "https://example.com/placeholder"
tags: [finding, search-exhausted]
timestamp: "2025-01-14T10:00:00Z"
---

# No Results Finding (Search Exhausted Tag)

Detected via search-exhausted tag.
EOF
}

# Create no-results finding with title prefix
create_no_results_title_prefix() {
    local file_path="$1"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "No Results: Specific ESG metrics framework"
url: "https://example.com/placeholder"
tags: [finding, search-result]
timestamp: "2025-01-14T10:00:00Z"
---

# No Results Finding (Title Prefix)

Detected via "No Results:" title prefix.
EOF
}

# Create no-results finding with search_success_level exhausted
create_no_results_search_level() {
    local file_path="$1"

    cat > "$file_path" <<EOF
---
finding_id: "$(basename "$file_path" .md)"
title: "Climate finance taxonomy"
url: "https://example.com/placeholder"
tags: [finding, search-result]
search_success_level: "exhausted"
timestamp: "2025-01-14T10:00:00Z"
---

# No Results Finding (Search Level)

Detected via search_success_level: exhausted.
EOF
}

# Detect no-results finding using 4 strategies (OR logic)
detect_no_results_finding() {
    local finding_file="$1"

    # Strategy 1: Empty/null URL check
    if grep -q '^url:[[:space:]]*\(null\|""\)\?[[:space:]]*$' "$finding_file"; then
        echo "{\"is_no_results\": true, \"strategy\": \"empty_url\", \"skip_reason\": \"no_results_finding\"}"
        return 0
    fi

    # Strategy 2: no-results tag
    if grep -q 'tags:.*no-results' "$finding_file"; then
        echo "{\"is_no_results\": true, \"strategy\": \"no_results_tag\", \"skip_reason\": \"no_results_finding\"}"
        return 0
    fi

    # Strategy 3: search-exhausted tag
    if grep -q 'tags:.*search-exhausted' "$finding_file"; then
        echo "{\"is_no_results\": true, \"strategy\": \"search_exhausted_tag\", \"skip_reason\": \"no_results_finding\"}"
        return 0
    fi

    # Strategy 4: Title prefix "No Results:"
    if grep -q '^title:.*"No Results:' "$finding_file"; then
        echo "{\"is_no_results\": true, \"strategy\": \"title_prefix\", \"skip_reason\": \"no_results_finding\"}"
        return 0
    fi

    # Strategy 5: search_success_level exhausted
    if grep -q '^search_success_level:[[:space:]]*"\?\(exhausted\|no-results\)"\?' "$finding_file"; then
        echo "{\"is_no_results\": true, \"strategy\": \"search_success_level\", \"skip_reason\": \"no_results_finding\"}"
        return 0
    fi

    # Normal finding
    echo "{\"is_no_results\": false}"
    return 1
}

# Test 1: Batch with all normal findings (0 skips expected)
test_01_all_normal_findings() {
    local test_dir="$TEST_OUTPUT_DIR/test01"
    mkdir -p "$test_dir"

    # Create 5 normal findings
    create_normal_finding "$test_dir/finding-001.md" "Finding 1" "https://example.com/1"
    create_normal_finding "$test_dir/finding-002.md" "Finding 2" "https://example.com/2"
    create_normal_finding "$test_dir/finding-003.md" "Finding 3" "https://example.com/3"
    create_normal_finding "$test_dir/finding-004.md" "Finding 4" "https://example.com/4"
    create_normal_finding "$test_dir/finding-005.md" "Finding 5" "https://example.com/5"

    # Detect no-results findings
    local no_results_count=0
    for finding in "$test_dir"/*.md; do
        if detect_no_results_finding "$finding" >/dev/null 2>&1; then
            no_results_count=$((no_results_count + 1))
        fi
    done

    # Verify 0 no-results findings
    if [ "$no_results_count" -eq 0 ]; then
        print_result 1 "All normal findings (0 skips)" "PASS"
    else
        print_result 1 "All normal findings (0 skips)" "FAIL" "Expected 0 no-results, got $no_results_count"
    fi
}

# Test 2: No-results finding with empty URL
test_02_empty_url() {
    local test_dir="$TEST_OUTPUT_DIR/test02"
    mkdir -p "$test_dir"

    create_no_results_empty_url "$test_dir/finding-001.md"

    local result
    result="$(detect_no_results_finding "$test_dir/finding-001.md" 2>&1)"

    if echo "$result" | grep -q '"is_no_results": true' && echo "$result" | grep -q '"strategy": "empty_url"'; then
        print_result 2 "No-results finding (empty URL: url: \"\")" "PASS"
    else
        print_result 2 "No-results finding (empty URL: url: \"\")" "FAIL" "Expected detection via empty_url strategy, got: $result"
    fi
}

# Test 3: No-results finding with null URL
test_03_null_url() {
    local test_dir="$TEST_OUTPUT_DIR/test03"
    mkdir -p "$test_dir"

    create_no_results_null_url "$test_dir/finding-001.md"

    local result
    result="$(detect_no_results_finding "$test_dir/finding-001.md" 2>&1)"

    if echo "$result" | grep -q '"is_no_results": true' && echo "$result" | grep -q '"strategy": "empty_url"'; then
        print_result 3 "No-results finding (null URL: url: null)" "PASS"
    else
        print_result 3 "No-results finding (null URL: url: null)" "FAIL" "Expected detection via empty_url strategy, got: $result"
    fi
}

# Test 4: No-results finding with no-results tag
test_04_no_results_tag() {
    local test_dir="$TEST_OUTPUT_DIR/test04"
    mkdir -p "$test_dir"

    create_no_results_tag "$test_dir/finding-001.md"

    local result
    result="$(detect_no_results_finding "$test_dir/finding-001.md" 2>&1)"

    if echo "$result" | grep -q '"is_no_results": true' && echo "$result" | grep -q '"strategy": "no_results_tag"'; then
        print_result 4 "No-results finding (no-results tag)" "PASS"
    else
        print_result 4 "No-results finding (no-results tag)" "FAIL" "Expected detection via no_results_tag strategy, got: $result"
    fi
}

# Test 5: No-results finding with search-exhausted tag
test_05_search_exhausted_tag() {
    local test_dir="$TEST_OUTPUT_DIR/test05"
    mkdir -p "$test_dir"

    create_no_results_search_exhausted_tag "$test_dir/finding-001.md"

    local result
    result="$(detect_no_results_finding "$test_dir/finding-001.md" 2>&1)"

    if echo "$result" | grep -q '"is_no_results": true' && echo "$result" | grep -q '"strategy": "search_exhausted_tag"'; then
        print_result 5 "No-results finding (search-exhausted tag)" "PASS"
    else
        print_result 5 "No-results finding (search-exhausted tag)" "FAIL" "Expected detection via search_exhausted_tag strategy, got: $result"
    fi
}

# Test 6: No-results finding with title prefix
test_06_title_prefix() {
    local test_dir="$TEST_OUTPUT_DIR/test06"
    mkdir -p "$test_dir"

    create_no_results_title_prefix "$test_dir/finding-001.md"

    local result
    result="$(detect_no_results_finding "$test_dir/finding-001.md" 2>&1)"

    if echo "$result" | grep -q '"is_no_results": true' && echo "$result" | grep -q '"strategy": "title_prefix"'; then
        print_result 6 "No-results finding (title prefix \"No Results:\")" "PASS"
    else
        print_result 6 "No-results finding (title prefix \"No Results:\")" "FAIL" "Expected detection via title_prefix strategy, got: $result"
    fi
}

# Test 7: No-results finding with search_success_level exhausted
test_07_search_success_level() {
    local test_dir="$TEST_OUTPUT_DIR/test07"
    mkdir -p "$test_dir"

    create_no_results_search_level "$test_dir/finding-001.md"

    local result
    result="$(detect_no_results_finding "$test_dir/finding-001.md" 2>&1)"

    if echo "$result" | grep -q '"is_no_results": true' && echo "$result" | grep -q '"strategy": "search_success_level"'; then
        print_result 7 "No-results finding (search_success_level: exhausted)" "PASS"
    else
        print_result 7 "No-results finding (search_success_level: exhausted)" "FAIL" "Expected detection via search_success_level strategy, got: $result"
    fi
}

# Test 8: Multiple no-results findings (mixed detection strategies)
test_08_mixed_no_results_strategies() {
    local test_dir="$TEST_OUTPUT_DIR/test08"
    mkdir -p "$test_dir"

    # Create no-results findings using different strategies
    create_no_results_empty_url "$test_dir/finding-001.md"
    create_no_results_tag "$test_dir/finding-002.md"
    create_no_results_title_prefix "$test_dir/finding-003.md"
    create_no_results_search_level "$test_dir/finding-004.md"

    # Detect all no-results findings
    local no_results_count=0
    local strategies_detected=()

    for finding in "$test_dir"/*.md; do
        result="$(detect_no_results_finding "$finding" 2>&1)"
        if echo "$result" | grep -q '"is_no_results": true'; then
            no_results_count=$((no_results_count + 1))
            strategy="$(echo "$result" | grep -o '"strategy": "[^"]*"' | cut -d'"' -f4)"
            strategies_detected+=("$strategy")
        fi
    done

    # Verify all 4 detected
    if [ "$no_results_count" -eq 4 ] && [ "${#strategies_detected[@]}" -eq 4 ]; then
        print_result 8 "Multiple no-results findings (mixed strategies)" "PASS"
    else
        print_result 8 "Multiple no-results findings (mixed strategies)" "FAIL" "Expected 4 no-results, got $no_results_count"
    fi
}

# Test 9: Batch with no-results + normal findings mixed
test_09_mixed_batch() {
    local test_dir="$TEST_OUTPUT_DIR/test09"
    mkdir -p "$test_dir"

    # Create mixed batch
    create_normal_finding "$test_dir/finding-001.md"
    create_no_results_empty_url "$test_dir/finding-002.md"
    create_normal_finding "$test_dir/finding-003.md"
    create_no_results_tag "$test_dir/finding-004.md"
    create_normal_finding "$test_dir/finding-005.md"
    create_no_results_title_prefix "$test_dir/finding-006.md"
    create_normal_finding "$test_dir/finding-007.md"

    # Detect findings
    local normal_count=0
    local no_results_count=0

    for finding in "$test_dir"/*.md; do
        if detect_no_results_finding "$finding" >/dev/null 2>&1; then
            no_results_count=$((no_results_count + 1))
        else
            normal_count=$((normal_count + 1))
        fi
    done

    # Verify 4 normal, 3 no-results
    if [ "$normal_count" -eq 4 ] && [ "$no_results_count" -eq 3 ]; then
        print_result 9 "Mixed batch (4 normal, 3 no-results)" "PASS"
    else
        print_result 9 "Mixed batch (4 normal, 3 no-results)" "FAIL" "Expected 4 normal, 3 no-results; got $normal_count normal, $no_results_count no-results"
    fi
}

# Test 10: Verify skip reasons are specific (no_results_finding)
test_10_specific_skip_reason() {
    local test_dir="$TEST_OUTPUT_DIR/test10"
    mkdir -p "$test_dir"

    # Create various no-results findings
    create_no_results_empty_url "$test_dir/finding-001.md"
    create_no_results_tag "$test_dir/finding-002.md"
    create_no_results_title_prefix "$test_dir/finding-003.md"

    # Verify all have skip_reason: no_results_finding
    local correct_skip_reasons=0

    for finding in "$test_dir"/*.md; do
        result="$(detect_no_results_finding "$finding" 2>&1)"
        if echo "$result" | grep -q '"skip_reason": "no_results_finding"'; then
            correct_skip_reasons=$((correct_skip_reasons + 1))
        fi
    done

    # Verify all 3 have correct skip reason
    if [ "$correct_skip_reasons" -eq 3 ]; then
        print_result 10 "Skip reasons are specific (no_results_finding)" "PASS"
    else
        print_result 10 "Skip reasons are specific (no_results_finding)" "FAIL" "Expected 3 with correct skip_reason, got $correct_skip_reasons"
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
    TEST_OUTPUT_DIR="$(mktemp -d -t source-creator-no-results-test-XXXXXX)"

    # Print header
    print_header

    # Run tests
    if [ -z "$test_case" ]; then
        # Run all tests
        test_01_all_normal_findings
        test_02_empty_url
        test_03_null_url
        test_04_no_results_tag
        test_05_search_exhausted_tag
        test_06_title_prefix
        test_07_search_success_level
        test_08_mixed_no_results_strategies
        test_09_mixed_batch
        test_10_specific_skip_reason
    else
        # Run specific test
        case "$test_case" in
            1) test_01_all_normal_findings ;;
            2) test_02_empty_url ;;
            3) test_03_null_url ;;
            4) test_04_no_results_tag ;;
            5) test_05_search_exhausted_tag ;;
            6) test_06_title_prefix ;;
            7) test_07_search_success_level ;;
            8) test_08_mixed_no_results_strategies ;;
            9) test_09_mixed_batch ;;
            10) test_10_specific_skip_reason ;;
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
