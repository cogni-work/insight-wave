#!/usr/bin/env bash
set -euo pipefail
# test-partition-entities.sh - Comprehensive test suite for partition-entities.sh
# Version: 1.0.0
# Purpose: Validate partition script behavior across all edge cases
# Output: TAP format for CI integration
#
# Exit codes:
#   0 - All tests pass
#   1 - Any test fails


# BUG-017 FIX: Use relative path instead of hardcoded absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="${SCRIPT_DIR}/partition-entities.sh"
TEST_DIR=""
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup test directory
setup_test_env() {
    TEST_DIR="$(mktemp -d -t partition-test.XXXXXX)"
    echo "# Test environment: $TEST_DIR" >&2
}

# Cleanup test directory
cleanup_test_env() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Create test entities with minimal YAML frontmatter
create_test_entities() {
    local dir="$1"
    local count="$2"
    local prefix="${3:-entity}"

    mkdir -p "$dir"
    for i in $(seq 1 "$count"); do
        local filename="$(printf "%s-%03d.md" "$prefix" "$i")"
        cat > "$dir/$filename" <<EOF
---
id: $prefix-$i
name: Test Entity $i
---
# Test Entity $i
EOF
    done
}

# Test helper: Run partition script and capture output
run_partition() {
    local entity_dir="$1"
    local pattern="$2"
    local partition_index="$3"
    local total_partitions="$4"

    "$SCRIPT_UNDER_TEST" \
        --entity-dir "$entity_dir" \
        --pattern "$pattern" \
        --partition-index "$partition_index" \
        --total-partitions "$total_partitions" \
        --json
}

# Test helper: Extract JSON from mixed output (for error cases)
# Test helper: Extract JSON from mixed output (for error cases)
extract_json() {
    local output="$1"
    # Try to parse entire output as JSON (works if only JSON + bash errors on stderr)
    # Extract first valid JSON object using jq (ignore errors from non-JSON lines)
    echo "$output" | jq -c . 2>/dev/null || echo ""
}

# Test helper: Validate JSON output
validate_json() {
    local output="$1"
    if ! echo "$output" | jq . >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Test helper: Extract JSON field
get_json_field() {
    local output="$1"
    local field="$2"
    echo "$output" | jq -r "$field"
}

# Test helper: Get array length
get_array_length() {
    local output="$1"
    local field="$2"
    echo "$output" | jq -r "${field} | length"
}

# Test result tracking
pass_test() {
    local test_name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "ok $TESTS_RUN - $test_name"
    echo -e "${GREEN}✓${NC} $test_name" >&2
}

fail_test() {
    local test_name="$1"
    local reason="${2:-}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "not ok $TESTS_RUN - $test_name"
    [[ -n "$reason" ]] && echo "  # $reason"
    echo -e "${RED}✗${NC} $test_name: $reason" >&2
}

# ==============================================================================
# Test Scenarios
# ==============================================================================

# Scenario 1: Standard Partitioning (42 entities, 4 partitions)
test_scenario_1() {
    echo "# Scenario 1: Standard Partitioning (42/4)" >&2

    local test_dir="$TEST_DIR/scenario1"
    create_test_entities "$test_dir" 42 "entity"

    # Expected: ceiling(42/4) = 11 per partition
    # Partition sizes: 11, 11, 11, 9 (remainder)

    local p0 p1 p2 p3
    p0="$(run_partition "$test_dir" "entity-*.md" 0 4)"
    p1="$(run_partition "$test_dir" "entity-*.md" 1 4)"
    p2="$(run_partition "$test_dir" "entity-*.md" 2 4)"
    p3="$(run_partition "$test_dir" "entity-*.md" 3 4)"

    # Validate JSON
    if ! validate_json "$p0"; then
        fail_test "Scenario 1: Partition 0 JSON valid" "Invalid JSON"
        return
    fi

    # Check partition sizes
    local size0="$(get_json_field "$p0" ".entities_in_partition")"
    local size1="$(get_json_field "$p1" ".entities_in_partition")"
    local size2="$(get_json_field "$p2" ".entities_in_partition")"
    local size3="$(get_json_field "$p3" ".entities_in_partition")"

    if [[ "$size0" -eq 11 && "$size1" -eq 11 && "$size2" -eq 11 && "$size3" -eq 9 ]]; then
        pass_test "Scenario 1: Partition sizes correct (11,11,11,9)"
    else
        fail_test "Scenario 1: Partition sizes" "Expected 11,11,11,9 but got $size0,$size1,$size2,$size3"
        return
    fi

    # Check total coverage
    local total=$((size0 + size1 + size2 + size3))
    if [[ "$total" -eq 42 ]]; then
        pass_test "Scenario 1: Total coverage (42/42)"
    else
        fail_test "Scenario 1: Total coverage" "Expected 42 but got $total"
    fi

    # Check for overlaps (no duplicate files across partitions)
    local files0="$(get_json_field "$p0" ".entity_files[]" | tr '\n' ' ')"
    local files1="$(get_json_field "$p1" ".entity_files[]" | tr '\n' ' ')"
    local files2="$(get_json_field "$p2" ".entity_files[]" | tr '\n' ' ')"
    local files3="$(get_json_field "$p3" ".entity_files[]" | tr '\n' ' ')"

    local all_files="${files0}${files1}${files2}${files3}"
    local unique_count="$(echo "$all_files" | tr ' ' '\n' | grep -v '^$' | sort -u | wc -l | tr -d ' ')"
    local total_count="$(echo "$all_files" | tr ' ' '\n' | grep -v '^$' | wc -l | tr -d ' ')"

    if [[ "$unique_count" -eq "$total_count" ]]; then
        pass_test "Scenario 1: No overlaps detected"
    else
        fail_test "Scenario 1: Overlaps" "Found duplicates: $unique_count unique vs $total_count total"
    fi

    # Check deterministic ordering (run partition 0 again)
    local p0_repeat="$(run_partition "$test_dir" "entity-*.md" 0 4)"
    if [[ "$p0" == "$p0_repeat" ]]; then
        pass_test "Scenario 1: Deterministic ordering"
    else
        fail_test "Scenario 1: Deterministic" "Partition 0 produced different results on repeat"
    fi
}

# Scenario 2: Last Partition Remainder (10 entities, 3 partitions)
test_scenario_2() {
    echo "# Scenario 2: Remainder Handling (10/3)" >&2

    local test_dir="$TEST_DIR/scenario2"
    create_test_entities "$test_dir" 10 "item"

    # Expected: ceiling(10/3) = 4 per partition
    # Partition sizes: 4, 4, 2

    local p0 p1 p2
    p0="$(run_partition "$test_dir" "item-*.md" 0 3)"
    p1="$(run_partition "$test_dir" "item-*.md" 1 3)"
    p2="$(run_partition "$test_dir" "item-*.md" 2 3)"

    local size0="$(get_json_field "$p0" ".entities_in_partition")"
    local size1="$(get_json_field "$p1" ".entities_in_partition")"
    local size2="$(get_json_field "$p2" ".entities_in_partition")"

    if [[ "$size0" -eq 4 && "$size1" -eq 4 && "$size2" -eq 2 ]]; then
        pass_test "Scenario 2: Partition sizes correct (4,4,2)"
    else
        fail_test "Scenario 2: Partition sizes" "Expected 4,4,2 but got $size0,$size1,$size2"
    fi

    local total=$((size0 + size1 + size2))
    if [[ "$total" -eq 10 ]]; then
        pass_test "Scenario 2: Total coverage (10/10)"
    else
        fail_test "Scenario 2: Total coverage" "Expected 10 but got $total"
    fi
}

# Scenario 3: Empty Directory
test_scenario_3() {
    echo "# Scenario 3: Empty Directory" >&2

    local test_dir="$TEST_DIR/scenario3"
    mkdir -p "$test_dir"

    local output
    output="$(run_partition "$test_dir" "*.md" 0 4)"

    local success="$(get_json_field "$output" ".success")"
    local total="$(get_json_field "$output" ".total_entities")"
    local in_partition="$(get_json_field "$output" ".entities_in_partition")"
    local files_count="$(get_array_length "$output" ".entity_files")"

    if [[ "$success" == "true" && "$total" -eq 0 && "$in_partition" -eq 0 && "$files_count" -eq 0 ]]; then
        pass_test "Scenario 3: Empty directory returns success with 0 entities"
    else
        fail_test "Scenario 3: Empty directory" "Expected success:true, 0 entities but got success:$success, total:$total, in_partition:$in_partition"
    fi
}

# Scenario 4: More Partitions Than Entities (3 entities, 5 partitions)
test_scenario_4() {
    echo "# Scenario 4: More Partitions Than Entities (3/5)" >&2

    local test_dir="$TEST_DIR/scenario4"
    create_test_entities "$test_dir" 3 "doc"

    # Expected: ceiling(3/5) = 1 per partition
    # Partition sizes: 1, 1, 1, 0, 0

    # BUG-045 FIX: Add array bounds checks before accessing array elements
    local sizes=()
    for i in {0..4}; do
        local output
        output="$(run_partition "$test_dir" "doc-*.md" "$i" 5)"
        local size="$(get_json_field "$output" ".entities_in_partition")"
        sizes+=("$size")

        local success="$(get_json_field "$output" ".success")"
        if ! [[ "$success" == "true" ]]; then
            fail_test "Scenario 4: Partition $i returns success" "Expected success:true but got $success"
            return
        fi
    done

    # BUG-045 FIX: Check array length before accessing elements
    if [[ ${#sizes[@]} -ge 5 ]]; then
        if [[ "${sizes[0]}" -eq 1 && "${sizes[1]}" -eq 1 && "${sizes[2]}" -eq 1 && "${sizes[3]}" -eq 0 && "${sizes[4]}" -eq 0 ]]; then
            pass_test "Scenario 4: Partition sizes correct (1,1,1,0,0)"
        else
            fail_test "Scenario 4: Partition sizes" "Expected 1,1,1,0,0 but got ${sizes[0]},${sizes[1]},${sizes[2]},${sizes[3]},${sizes[4]}"
        fi
    else
        fail_test "Scenario 4: Array bounds" "Expected 5 elements but got ${#sizes[@]}"
    fi

    pass_test "Scenario 4: Empty partitions return success (not error)"
}

# Scenario 5: Single Entity
test_scenario_5() {
    echo "# Scenario 5: Single Entity" >&2

    local test_dir="$TEST_DIR/scenario5"
    create_test_entities "$test_dir" 1 "single"

    local sizes=()
    for i in {0..3}; do
        local output
        output="$(run_partition "$test_dir" "single-*.md" "$i" 4)"
        local size="$(get_json_field "$output" ".entities_in_partition")"
        sizes+=("$size")
    done

    # BUG-045 FIX: Check array length before accessing
    if [[ ${#sizes[@]} -ge 4 ]]; then
        if [[ "${sizes[0]}" -eq 1 && "${sizes[1]}" -eq 0 && "${sizes[2]}" -eq 0 && "${sizes[3]}" -eq 0 ]]; then
            pass_test "Scenario 5: Single entity handled correctly (1,0,0,0)"
        else
            fail_test "Scenario 5: Single entity" "Expected 1,0,0,0 but got ${sizes[0]},${sizes[1]},${sizes[2]},${sizes[3]}"
        fi
    else
        fail_test "Scenario 5: Array bounds" "Expected 4 elements but got ${#sizes[@]}"
    fi
}

# Scenario 6: Invalid Parameters
test_scenario_6() {
    echo "# Scenario 6: Invalid Parameters" >&2

    local test_dir="$TEST_DIR/scenario6"
    create_test_entities "$test_dir" 5 "test"

    # Test: partition_index >= total_partitions
    local output
    if output="$(run_partition "$test_dir" "test-*.md" 4 4 2>&1)"; then
        fail_test "Scenario 6: partition_index >= total_partitions" "Expected error but succeeded"
    else
        # Extract JSON from mixed stderr output
        local json_output="$(extract_json "$output")"
        if [[ -n "$json_output" ]] && echo "$json_output" | jq -e '.success == false' >/dev/null 2>&1; then
            pass_test "Scenario 6: partition_index >= total_partitions returns error"
        else
            fail_test "Scenario 6: partition_index >= total_partitions" "Expected JSON error response"
        fi
    fi

    # Test: negative partition_index (bash interprets as string, should fail validation)
    if output="$("$SCRIPT_UNDER_TEST" --entity-dir "$test_dir" --pattern "test-*.md" --partition-index -1 --total-partitions 4 --json 2>&1)"; then
        fail_test "Scenario 6: negative partition_index" "Expected error but succeeded"
    else
        pass_test "Scenario 6: negative partition_index returns error"
    fi

    # Test: missing required parameters
    if output="$("$SCRIPT_UNDER_TEST" --entity-dir "$test_dir" --pattern "test-*.md" --json 2>&1)"; then
        fail_test "Scenario 6: missing parameters" "Expected error but succeeded"
    else
        local json_output="$(extract_json "$output")"
        if [[ -n "$json_output" ]] && echo "$json_output" | jq -e '.success == false' >/dev/null 2>&1; then
            pass_test "Scenario 6: missing parameters returns error"
        else
            fail_test "Scenario 6: missing parameters" "Expected JSON error response"
        fi
    fi

    # Test: directory doesn't exist
    if output="$(run_partition "/nonexistent/dir" "*.md" 0 4 2>&1)"; then
        fail_test "Scenario 6: nonexistent directory" "Expected error but succeeded"
    else
        local json_output="$(extract_json "$output")"
        if [[ -n "$json_output" ]] && echo "$json_output" | jq -e '.success == false' >/dev/null 2>&1; then
            pass_test "Scenario 6: nonexistent directory returns error"
        else
            fail_test "Scenario 6: nonexistent directory" "Expected JSON error response"
        fi
    fi
}

# Scenario 7: Deterministic Ordering with Non-Alphabetical Filenames
test_scenario_7() {
    echo "# Scenario 7: Deterministic Ordering" >&2

    local test_dir="$TEST_DIR/scenario7"
    mkdir -p "$test_dir"

    # Create files with non-alphabetical order
    for name in "zebra" "apple" "mango" "banana" "kiwi"; do
        cat > "$test_dir/${name}.md" <<EOF
---
id: $name
---
# $name
EOF
    done

    # Run partition 0 twice
    local run1
    local run2
    run1="$(run_partition "$test_dir" "*.md" 0 2)"
    run2="$(run_partition "$test_dir" "*.md" 0 2)"

    if [[ "$run1" == "$run2" ]]; then
        pass_test "Scenario 7: Deterministic ordering (identical results)"
    else
        fail_test "Scenario 7: Deterministic ordering" "Results differ between runs"
    fi

    # Verify files are sorted
    local files1="$(get_json_field "$run1" ".entity_files[]")"
    local first_file="$(echo "$files1" | head -1 | xargs basename)"

    # First file should be apple.md (alphabetically first)
    if [[ "$first_file" == "apple.md" ]]; then
        pass_test "Scenario 7: Files sorted alphabetically"
    else
        fail_test "Scenario 7: File ordering" "Expected apple.md first but got $first_file"
    fi
}

# ==============================================================================
# Main Test Execution
# ==============================================================================

main() {
    echo "TAP version 13"
    echo "1..20"  # Approximate test count

    echo "" >&2
    echo "Test Suite: partition-entities.sh Validation" >&2
    echo "=============================================" >&2

    # Verify script exists
    if [[ ! -x "$SCRIPT_UNDER_TEST" ]]; then
        echo "# FATAL: Script not found or not executable: $SCRIPT_UNDER_TEST" >&2
        exit 1
    fi

    # Setup
    setup_test_env
    trap cleanup_test_env EXIT

    # Run all test scenarios
    test_scenario_1
    test_scenario_2
    test_scenario_3
    test_scenario_4
    test_scenario_5
    test_scenario_6
    test_scenario_7

    # Summary
    echo "" >&2
    echo "=============================================" >&2
    echo "Test Summary" >&2
    echo "=============================================" >&2
    echo "Total tests: $TESTS_RUN" >&2
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}" >&2
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}" >&2
        echo "" >&2
        echo "Exit code: 1 (FAILURE)" >&2
        exit 1
    else
        echo "Failed: 0" >&2
        echo "" >&2
        echo -e "${GREEN}✓ All tests passed!${NC}" >&2
        exit 0
    fi
}

main "$@"
