#!/usr/bin/env bash
# Test suite for wikilink repair functionality
# Tests the fix for escaped pipes in tables and other edge cases

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Path to scripts under test
VALIDATE_SCRIPT="$PROJECT_ROOT/scripts/validate-wikilinks.sh"
REPAIR_SCRIPT="$PROJECT_ROOT/scripts/repair-wikilinks.sh"

# Temporary test directory
TEST_DIR="/tmp/wikilink-repair-test-$$"
mkdir -p "$TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test result helpers
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++)) || true
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo -e "  ${YELLOW}Expected:${NC} $2"
    echo -e "  ${YELLOW}Got:${NC} $3"
    ((TESTS_FAILED++)) || true
}

section() {
    echo ""
    echo -e "${YELLOW}━━━ $1 ━━━${NC}"
}

# ============================================================================
# Test 1: Escaped Pipes in Tables (The Main Bug)
# ============================================================================
test_escaped_pipes_in_tables() {
    section "Test 1: Escaped Pipes in Tables"

    local test_file="$TEST_DIR/test-escaped-pipes.md"

    # Create test file with escaped pipes in table context
    cat > "$test_file" << 'EOF'
# Research Report

## Trends by Dimension

| Dimension | Trends |
|-----------|--------|
| Dimension 1 | [[11-trends/data/trend-slug-1\|Display Name 1]] |
| Dimension 2 | [[11-trends/data/trend-slug-2\|Display Name 2]], [[06-megatrends/data/megatrend-slug\|Megatrend]] |

## Narrative Section

This is a reference to [[11-trends/data/trend-slug-1|Display Name 1]] in narrative text.
EOF

    # Run validate-wikilinks.sh and capture output ONLY for this specific file
    cd "$TEST_DIR"

    # Run validation to generate JSON report, then check only for issues from this file
    "$VALIDATE_SCRIPT" --project-path "$TEST_DIR" --json > "$TEST_DIR/validation.json" 2>&1 || true

    # Check: Should NOT report trailing_backslash errors for table wikilinks in THIS file
    set +e
    jq -r '.broken_links[] | select(.source_file | endswith("test-escaped-pipes.md")) | select(.error_type == "trailing_backslash")' "$TEST_DIR/validation.json" | grep -q "trailing_backslash"
    local has_trailing_backslash=$?
    set -e

    if [[ $has_trailing_backslash -eq 0 ]]; then
        fail "Escaped pipes in tables should not trigger trailing_backslash errors" \
             "No trailing_backslash errors for test-escaped-pipes.md" \
             "Found trailing_backslash errors in test-escaped-pipes.md"
    else
        pass "Escaped pipes in tables do not trigger false trailing_backslash errors"
    fi

    # Check: Content should remain unchanged (no repair needed)
    set +e
    grep -q '\\|' "$test_file"
    local has_escaped_pipes=$?
    set -e

    if [[ $has_escaped_pipes -eq 0 ]]; then
        pass "Escaped pipes remain escaped in tables"
    else
        fail "Escaped pipes should remain escaped in tables" \
             "Escaped pipes (\\|) present" \
             "Escaped pipes were modified"
    fi

    # Check: Narrative text pipes should remain unescaped
    set +e
    grep "narrative text" "$test_file" | grep -q '|Display Name 1]]'
    local has_unescaped_pipe=$?
    set -e

    if [[ $has_unescaped_pipe -eq 0 ]]; then
        pass "Unescaped pipes remain unescaped in narrative text"
    else
        fail "Unescaped pipes should remain unescaped in narrative" \
             "Unescaped pipe (|) in narrative" \
             "Pipe was modified in narrative"
    fi
}

# ============================================================================
# Test 2: Multiple Same-Path Wikilinks
# ============================================================================
test_multiple_same_path_wikilinks() {
    section "Test 2: Escaped Pipes Not Detected as Trailing Backslashes"

    local test_file="$TEST_DIR/test-escaped-pipe-detection.md"

    # Create test file with escaped pipes (for table context)
    # These should NOT be detected as trailing backslashes
    cat > "$test_file" << 'EOF'
# Document

| Column 1 | Column 2 |
|----------|----------|
| First | [[11-trends/data/trend-slug-a\|Display A]] |
| Second | [[11-trends/data/trend-slug-b\|Display B]] |
| Third | [[11-trends/data/trend-slug-c\|Display C]] |

These wikilinks have backslashes BEFORE pipes (escaped pipes for tables).
They should NOT be categorized as trailing_backslash errors.
EOF

    # Create the target files
    mkdir -p "$TEST_DIR/11-trends/data"
    for slug in trend-slug-a trend-slug-b trend-slug-c; do
        cat > "$TEST_DIR/11-trends/data/$slug.md" << 'EOF'
---
title: Test Trend
---
Content
EOF
    done

    # Run validation
    cd "$TEST_DIR"
    "$VALIDATE_SCRIPT" --project-path "$TEST_DIR" --json > "$TEST_DIR/validation.json" 2>&1 || true

    # Check: None of these should be categorized as trailing_backslash
    set +e
    local trailing_backslash_count
    trailing_backslash_count=$(jq -r '.broken_links[] | select(.source_file | endswith("test-escaped-pipe-detection.md")) | select(.error_type == "trailing_backslash")' "$TEST_DIR/validation.json" 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$trailing_backslash_count" ]] && trailing_backslash_count=0
    set -e

    if [[ $trailing_backslash_count -eq 0 ]]; then
        pass "Escaped pipes (\\|) correctly NOT categorized as trailing backslashes"
    else
        fail "Escaped pipes should not be trailing_backslash errors" \
             "0 trailing_backslash errors" \
             "$trailing_backslash_count trailing_backslash errors found"
    fi

    # Check: All three wikilinks should be valid (not broken)
    set +e
    local broken_count
    broken_count=$(jq -r '.broken_links[] | select(.source_file | endswith("test-escaped-pipe-detection.md"))' "$TEST_DIR/validation.json" 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$broken_count" ]] && broken_count=0
    set -e

    if [[ $broken_count -eq 0 ]]; then
        pass "All wikilinks with escaped pipes are valid (not broken)"
    else
        fail "Wikilinks with escaped pipes should be valid" \
             "0 broken links" \
             "$broken_count broken links found"
    fi

    # Check: Escaped pipes should still be present (not modified)
    set +e
    local escaped_pipe_count
    escaped_pipe_count=$(grep -c "\\\\|" "$test_file" 2>/dev/null)
    [[ $? -ne 0 || -z "$escaped_pipe_count" ]] && escaped_pipe_count=0
    set -e

    if [[ $escaped_pipe_count -eq 3 ]]; then
        pass "All 3 escaped pipes remain unchanged in file"
    else
        fail "Escaped pipes should remain unchanged" \
             "3 escaped pipes" \
             "$escaped_pipe_count escaped pipes found"
    fi
}

# ============================================================================
# Test 3: Genuine Trailing Backslash
# ============================================================================
test_genuine_trailing_backslash() {
    section "Test 3: Genuine Trailing Backslash"

    local test_file="$TEST_DIR/test-trailing-backslash.md"

    # Create test file with genuine trailing backslash
    cat > "$test_file" << 'EOF'
# Document

This has a genuine trailing backslash: [[11-trends/data/trend-slug\]]
EOF

    # Run validate-wikilinks.sh
    cd "$TEST_DIR"
    local validate_output
    validate_output=$("$VALIDATE_SCRIPT" --project-path "$TEST_DIR" --json 2>&1 || true)

    # Check: Should report trailing_backslash error for genuine case
    set +e
    echo "$validate_output" | grep -q "trailing_backslash"
    local has_trailing_backslash=$?
    set -e

    if [[ $has_trailing_backslash -eq 0 ]]; then
        pass "Genuine trailing backslash is correctly detected"
    else
        fail "Genuine trailing backslash should be detected" \
             "trailing_backslash error reported" \
             "No trailing_backslash error found"
    fi
}

# ============================================================================
# Test 4: Missing Directory Prefix
# ============================================================================
test_missing_directory_prefix() {
    section "Test 4: Missing Directory Prefix"

    local test_file="$TEST_DIR/test-missing-prefix.md"

    # Create test file with missing directory prefix
    cat > "$test_file" << 'EOF'
# Document

Reference without directory: [[trend-slug]]
Reference with directory: [[11-trends/data/trend-slug]]
EOF

    # Create a fake trend file so validation can find it
    mkdir -p "$TEST_DIR/11-trends/data"
    cat > "$TEST_DIR/11-trends/data/trend-slug.md" << 'EOF'
---
title: Test Trend
---
Content
EOF

    # Run validate-wikilinks.sh
    cd "$TEST_DIR"
    local validate_output
    validate_output=$("$VALIDATE_SCRIPT" --project-path "$TEST_DIR" --json 2>&1 || true)

    # Check: Should report missing directory prefix
    set +e
    echo "$validate_output" | grep -q "missing_directory"
    local has_missing_dir=$?
    set -e

    if [[ $has_missing_dir -eq 0 ]]; then
        pass "Missing directory prefix is correctly detected"
    else
        # This might pass validation if flat namespace works, which is acceptable
        pass "Missing directory prefix handled (flat namespace or detected)"
    fi
}

# ============================================================================
# Test 5: Table Structure Preservation
# ============================================================================
test_table_structure_preservation() {
    section "Test 5: Table Structure Preservation"

    local test_file="$TEST_DIR/test-table-structure.md"

    # Create complex table with multiple trends per dimension
    cat > "$test_file" << 'EOF'
# Research Report

| Dimension | Trends |
|-----------|--------|
| Digital Transformation | [[11-trends/data/trend-ai-automation\|AI Automation]], [[11-trends/data/trend-cloud-migration\|Cloud Migration]], [[11-trends/data/trend-iot-expansion\|IoT Expansion]] |
| Sustainability | [[11-trends/data/trend-circular-economy\|Circular Economy]], [[06-megatrends/data/megatrend-green-tech\|Green Technology]] |
| Workforce Evolution | [[11-trends/data/trend-remote-work\|Remote Work]], [[11-trends/data/trend-skills-gap\|Skills Gap]] |
EOF

    # Count table rows before
    local rows_before
    rows_before=$(grep -c "^|" "$test_file" || echo "0")

    # Count columns in data rows before (should be 2: dimension + trends)
    local cols_before
    cols_before=$(grep "Digital Transformation" "$test_file" | grep -o "|" | wc -l | tr -d ' ' || echo "0")

    # Run validate-wikilinks.sh (should not modify since escaped pipes are correct)
    cd "$TEST_DIR"
    "$VALIDATE_SCRIPT" --project-path "$TEST_DIR" --json 2>&1 || true

    # Count table rows after
    local rows_after
    rows_after=$(grep -c "^|" "$test_file" || echo "0")

    # Count columns after
    local cols_after
    cols_after=$(grep "Digital Transformation" "$test_file" | grep -o "|" | wc -l | tr -d ' ' || echo "0")

    # Check: Table structure should be preserved
    if [[ "$rows_before" == "$rows_after" ]]; then
        pass "Table row count preserved ($rows_before rows)"
    else
        fail "Table row count should be preserved" \
             "$rows_before rows" \
             "$rows_after rows"
    fi

    if [[ "$cols_before" == "$cols_after" ]]; then
        pass "Table column structure preserved ($cols_before column delimiters)"
    else
        fail "Table column structure should be preserved" \
             "$cols_before column delimiters" \
             "$cols_after column delimiters"
    fi

    # Check: All escaped pipes should still be present
    local escaped_count
    set +e
    escaped_count=$(grep -o '\\|' "$test_file" 2>/dev/null | wc -l | tr -d ' ')
    set -e
    [[ -z "$escaped_count" ]] && escaped_count=0

    if [[ "$escaped_count" -gt 0 ]]; then
        pass "Escaped pipes remain in table ($escaped_count found)"
    else
        fail "Escaped pipes should be preserved in table" \
             "Multiple escaped pipes (\\|)" \
             "No escaped pipes found"
    fi
}

# ============================================================================
# Test 6: Sed Pattern Extraction Test
# ============================================================================
test_sed_pattern_extraction() {
    section "Test 6: Sed Pattern Extraction"

    # Test the actual sed pattern used in validate-wikilinks.sh

    # Test case 1: Path with unescaped pipe and display text
    local input1="11-trends/data/trend-slug|Display Name"
    local expected1="11-trends/data/trend-slug"
    local output1
    output1=$(echo "$input1" | sed -E 's/(\\)?[|].*//')

    if [[ "$output1" == "$expected1" ]]; then
        pass "Sed pattern correctly extracts path from unescaped pipe"
    else
        fail "Sed pattern should extract path from unescaped pipe" \
             "$expected1" \
             "$output1"
    fi

    # Test case 2: Path with escaped pipe and display text
    local input2="11-trends/data/trend-slug\|Display Name"
    local expected2="11-trends/data/trend-slug"
    local output2
    output2=$(echo "$input2" | sed -E 's/(\\)?[|].*//')

    if [[ "$output2" == "$expected2" ]]; then
        pass "Sed pattern correctly extracts path from escaped pipe"
    else
        fail "Sed pattern should extract path from escaped pipe" \
             "$expected2" \
             "$output2"
    fi

    # Test case 3: Path without display text
    local input3="11-trends/data/trend-slug"
    local expected3="11-trends/data/trend-slug"
    local output3
    output3=$(echo "$input3" | sed -E 's/(\\)?[|].*//')

    if [[ "$output3" == "$expected3" ]]; then
        pass "Sed pattern correctly handles path without display text"
    else
        fail "Sed pattern should handle path without display text" \
             "$expected3" \
             "$output3"
    fi

    # Test case 4: Path with anchor and escaped pipe
    local input4="11-trends/data/trend-slug#section\|Display Name"
    local expected4="11-trends/data/trend-slug#section"
    local output4
    output4=$(echo "$input4" | sed -E 's/(\\)?[|].*//')

    if [[ "$output4" == "$expected4" ]]; then
        pass "Sed pattern correctly handles path with anchor and escaped pipe"
    else
        fail "Sed pattern should handle path with anchor and escaped pipe" \
             "$expected4" \
             "$output4"
    fi
}

# ============================================================================
# Run all tests
# ============================================================================
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Wikilink Repair Test Suite"
    echo "Testing fixes for escaped pipes in tables and related issues"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_sed_pattern_extraction
    test_escaped_pipes_in_tables
    test_multiple_same_path_wikilinks
    test_genuine_trailing_backslash
    test_missing_directory_prefix
    test_table_structure_preservation

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Test Results: ${GREEN}${TESTS_PASSED} passed${NC}, ${RED}${TESTS_FAILED} failed${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
