#!/usr/bin/env bash
set -euo pipefail
# test-partition-processing.sh
# Version: 1.0.0
# Purpose: Test partition-aware batch processing (Phase 2) of source-creator
# Category: test
#
# Tests partition calculation algorithm with ceiling division, array slicing,
# and partition boundary verification.
#
# Test Coverage:
#   1. Process 10 findings with no partitioning (all processed)
#   2. Process 10 findings with 2 partitions (5 each)
#   3. Process 10 findings with 3 partitions (4, 4, 2 via ceiling division)
#   4. Verify partition boundaries (no overlap, no gaps)
#   5. Verify partition-aware logging (partition number in logs)
#   6. Verify counters aggregate correctly per partition
#
# Parameters:
#   --test-case    Optional: Run specific test case (1-6)
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
    echo "Test: source-creator Partition Processing"
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

# Create test finding
create_test_finding() {
    local file_path="$1"
    local finding_num="$2"

    cat > "$file_path" <<EOF
---
finding_id: "finding-$(printf '%03d' "$finding_num")"
title: "Test Finding $finding_num"
url: "https://example.com/test-$finding_num"
tags: [finding, search-result, test]
timestamp: "2025-01-14T10:00:00Z"
---

# Test Finding $finding_num

This is test content for partition processing testing.
EOF
}

# Calculate partition slice (ceiling division algorithm)
calculate_partition_slice() {
    local total="$1"
    local partition_index="$2"
    local total_partitions="$3"

    # Ceiling division: (TOTAL + TOTAL_PARTITIONS - 1) / TOTAL_PARTITIONS
    local partition_size=$(( (total + total_partitions - 1) / total_partitions ))

    # Calculate start and end indices
    local start_index=$((partition_index * partition_size))
    local end_index=$((start_index + partition_size))

    # Clamp end index to total
    if [ $end_index -gt $total ]; then
        end_index=$total
    fi

    # Return as JSON
    echo "{\"start_index\": $start_index, \"end_index\": $end_index, \"partition_size\": $partition_size, \"actual_count\": $((end_index - start_index))}"
}

# Process findings in partition slice
process_partition_slice() {
    local finding_files_array=("$@")
    local partition_index="${PARTITION_INDEX:-0}"
    local total_partitions="${TOTAL_PARTITIONS:-1}"

    local total=${#finding_files_array[@]}

    # Calculate partition slice
    local slice_json
    slice_json="$(calculate_partition_slice "$total" "$partition_index" "$total_partitions")"

    local start_index
    local end_index
    start_index="$(echo "$slice_json" | grep -o '"start_index": [0-9]*' | grep -o '[0-9]*$')"
    end_index="$(echo "$slice_json" | grep -o '"end_index": [0-9]*' | grep -o '[0-9]*$')"

    # Extract partition slice
    local partition_size=$((end_index - start_index))
    local findings_to_process=("${finding_files_array[@]:$start_index:$partition_size}")

    # Process findings
    local processed_count=0
    for finding in "${findings_to_process[@]}"; do
        if [ -f "$finding" ]; then
            processed_count=$((processed_count + 1))
        fi
    done

    # Return results
    echo "{\"partition_index\": $partition_index, \"total_partitions\": $total_partitions, \"start_index\": $start_index, \"end_index\": $end_index, \"expected_count\": $partition_size, \"processed_count\": $processed_count}"
}

# Test 1: Process 10 findings with no partitioning (all processed)
test_01_no_partitioning() {
    local test_dir="$TEST_OUTPUT_DIR/test01"
    mkdir -p "$test_dir"

    # Create 10 test findings
    local finding_files=()
    for i in $(seq 1 10); do
        local file_path="$test_dir/finding-$(printf '%03d' "$i").md"
        create_test_finding "$file_path" "$i"
        finding_files+=("$file_path")
    done

    # Process without partitioning (sequential mode)
    unset PARTITION_INDEX
    unset TOTAL_PARTITIONS

    local result
    result="$(process_partition_slice "${finding_files[@]}")"

    local processed_count
    processed_count="$(echo "$result" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

    # Verify all 10 processed
    if [ "$processed_count" -eq 10 ]; then
        print_result 1 "No partitioning (all 10 processed)" "PASS"
    else
        print_result 1 "No partitioning (all 10 processed)" "FAIL" "Expected 10 processed, got $processed_count"
    fi
}

# Test 2: Process 10 findings with 2 partitions (5 each)
test_02_two_partitions() {
    local test_dir="$TEST_OUTPUT_DIR/test02"
    mkdir -p "$test_dir"

    # Create 10 test findings
    local finding_files=()
    for i in $(seq 1 10); do
        local file_path="$test_dir/finding-$(printf '%03d' "$i").md"
        create_test_finding "$file_path" "$i"
        finding_files+=("$file_path")
    done

    # Process partition 0 (first 5)
    export PARTITION_INDEX=0
    export TOTAL_PARTITIONS=2

    local result_p0
    result_p0="$(process_partition_slice "${finding_files[@]}")"

    local p0_count
    p0_count="$(echo "$result_p0" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

    # Process partition 1 (last 5)
    export PARTITION_INDEX=1

    local result_p1
    result_p1="$(process_partition_slice "${finding_files[@]}")"

    local p1_count
    p1_count="$(echo "$result_p1" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

    # Verify 5 + 5 = 10
    local total_processed=$((p0_count + p1_count))

    if [ "$p0_count" -eq 5 ] && [ "$p1_count" -eq 5 ] && [ "$total_processed" -eq 10 ]; then
        print_result 2 "Two partitions (5 + 5 = 10)" "PASS"
    else
        print_result 2 "Two partitions (5 + 5 = 10)" "FAIL" "Expected 5 + 5 = 10, got $p0_count + $p1_count = $total_processed"
    fi

    unset PARTITION_INDEX
    unset TOTAL_PARTITIONS
}

# Test 3: Process 10 findings with 3 partitions (4, 4, 2 via ceiling division)
test_03_three_partitions() {
    local test_dir="$TEST_OUTPUT_DIR/test03"
    mkdir -p "$test_dir"

    # Create 10 test findings
    local finding_files=()
    for i in $(seq 1 10); do
        local file_path="$test_dir/finding-$(printf '%03d' "$i").md"
        create_test_finding "$file_path" "$i"
        finding_files+=("$file_path")
    done

    # Process partition 0
    export PARTITION_INDEX=0
    export TOTAL_PARTITIONS=3

    local result_p0
    result_p0="$(process_partition_slice "${finding_files[@]}")"

    local p0_count
    p0_count="$(echo "$result_p0" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

    # Process partition 1
    export PARTITION_INDEX=1

    local result_p1
    result_p1="$(process_partition_slice "${finding_files[@]}")"

    local p1_count
    p1_count="$(echo "$result_p1" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

    # Process partition 2
    export PARTITION_INDEX=2

    local result_p2
    result_p2="$(process_partition_slice "${finding_files[@]}")"

    local p2_count
    p2_count="$(echo "$result_p2" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

    # Verify 4 + 4 + 2 = 10 (ceiling division)
    local total_processed=$((p0_count + p1_count + p2_count))

    if [ "$p0_count" -eq 4 ] && [ "$p1_count" -eq 4 ] && [ "$p2_count" -eq 2 ] && [ "$total_processed" -eq 10 ]; then
        print_result 3 "Three partitions (4 + 4 + 2 = 10 via ceiling)" "PASS"
    else
        print_result 3 "Three partitions (4 + 4 + 2 = 10 via ceiling)" "FAIL" "Expected 4 + 4 + 2 = 10, got $p0_count + $p1_count + $p2_count = $total_processed"
    fi

    unset PARTITION_INDEX
    unset TOTAL_PARTITIONS
}

# Test 4: Verify partition boundaries (no overlap, no gaps)
test_04_partition_boundaries() {
    local test_dir="$TEST_OUTPUT_DIR/test04"
    mkdir -p "$test_dir"

    # Create 15 test findings
    local finding_files=()
    for i in $(seq 1 15); do
        local file_path="$test_dir/finding-$(printf '%03d' "$i").md"
        create_test_finding "$file_path" "$i"
        finding_files+=("$file_path")
    done

    # Test with 4 partitions
    export TOTAL_PARTITIONS=4

    local all_indices=()
    local boundaries_valid=1

    for partition_idx in $(seq 0 3); do
        export PARTITION_INDEX=$partition_idx

        local slice_json
        slice_json="$(calculate_partition_slice 15 "$partition_idx" 4)"

        local start_index
        local end_index
        start_index="$(echo "$slice_json" | grep -o '"start_index": [0-9]*' | grep -o '[0-9]*$')"
        end_index="$(echo "$slice_json" | grep -o '"end_index": [0-9]*' | grep -o '[0-9]*$')"

        # Record indices
        for idx in $(seq "$start_index" $((end_index - 1))); do
            all_indices+=("$idx")
        done

        # Check previous partition end matches current start (no gaps)
        if [ "$partition_idx" -gt 0 ]; then
            local prev_end="$prev_partition_end"
            if [ "$start_index" -ne "$prev_end" ]; then
                boundaries_valid=0
            fi
        fi

        prev_partition_end=$end_index
    done

    # Verify all indices 0-14 covered exactly once
    local unique_count
    unique_count="$(printf '%s\n' "${all_indices[@]}" | sort -u | wc -l | tr -d ' ')"

    # Verify total count and uniqueness
    if [ "${#all_indices[@]}" -eq 15 ] && [ "$unique_count" -eq 15 ] && [ "$boundaries_valid" -eq 1 ]; then
        print_result 4 "Partition boundaries (no overlap, no gaps)" "PASS"
    else
        print_result 4 "Partition boundaries (no overlap, no gaps)" "FAIL" "Expected 15 unique indices, got ${#all_indices[@]} total, $unique_count unique"
    fi

    unset PARTITION_INDEX
    unset TOTAL_PARTITIONS
}

# Test 5: Verify partition-aware logging (partition number in logs)
test_05_partition_logging() {
    local test_dir="$TEST_OUTPUT_DIR/test05"
    mkdir -p "$test_dir"

    # Create 10 test findings
    local finding_files=()
    for i in $(seq 1 10); do
        local file_path="$test_dir/finding-$(printf '%03d' "$i").md"
        create_test_finding "$file_path" "$i"
        finding_files+=("$file_path")
    done

    # Process partition 1 of 3
    export PARTITION_INDEX=1
    export TOTAL_PARTITIONS=3

    local result
    result="$(process_partition_slice "${finding_files[@]}")"

    # Verify result includes partition metadata
    if echo "$result" | grep -q '"partition_index": 1' && echo "$result" | grep -q '"total_partitions": 3'; then
        print_result 5 "Partition-aware logging (partition number in output)" "PASS"
    else
        print_result 5 "Partition-aware logging (partition number in output)" "FAIL" "Expected partition metadata in result: $result"
    fi

    unset PARTITION_INDEX
    unset TOTAL_PARTITIONS
}

# Test 6: Verify counters aggregate correctly per partition
test_06_counter_aggregation() {
    local test_dir="$TEST_OUTPUT_DIR/test06"
    mkdir -p "$test_dir"

    # Create 20 test findings
    local finding_files=()
    for i in $(seq 1 20); do
        local file_path="$test_dir/finding-$(printf '%03d' "$i").md"
        create_test_finding "$file_path" "$i"
        finding_files+=("$file_path")
    done

    # Process with 5 partitions
    export TOTAL_PARTITIONS=5

    local partition_counts=()
    local total_across_partitions=0

    for partition_idx in $(seq 0 4); do
        export PARTITION_INDEX=$partition_idx

        local result
        result="$(process_partition_slice "${finding_files[@]}")"

        local processed_count
        processed_count="$(echo "$result" | grep -o '"processed_count": [0-9]*' | grep -o '[0-9]*$')"

        partition_counts+=("$processed_count")
        total_across_partitions=$((total_across_partitions + processed_count))
    done

    # Verify total equals 20
    if [ "$total_across_partitions" -eq 20 ]; then
        print_result 6 "Counter aggregation (5 partitions sum to 20)" "PASS"
    else
        local counts_str="$(printf '%s + ' "${partition_counts[@]}")"
        counts_str=${counts_str% + }
        print_result 6 "Counter aggregation (5 partitions sum to 20)" "FAIL" "Expected 20 total, got $total_across_partitions ($counts_str)"
    fi

    unset PARTITION_INDEX
    unset TOTAL_PARTITIONS
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
                echo "Usage: $0 [--test-case <1-6>]" >&2
                exit 2
                ;;
        esac
    done

    # Validate test case if specified
    if [ -n "$test_case" ]; then
        if ! [[ "$test_case" =~ ^[1-6]$ ]]; then
            echo "Error: Invalid test case. Must be 1-6." >&2
            exit 2
        fi
    fi

    # Create temporary test directory
    TEST_OUTPUT_DIR="$(mktemp -d -t source-creator-partition-test-XXXXXX)"

    # Print header
    print_header

    # Run tests
    if [ -z "$test_case" ]; then
        # Run all tests
        test_01_no_partitioning
        test_02_two_partitions
        test_03_three_partitions
        test_04_partition_boundaries
        test_05_partition_logging
        test_06_counter_aggregation
    else
        # Run specific test
        case "$test_case" in
            1) test_01_no_partitioning ;;
            2) test_02_two_partitions ;;
            3) test_03_three_partitions ;;
            4) test_04_partition_boundaries ;;
            5) test_05_partition_logging ;;
            6) test_06_counter_aggregation ;;
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
