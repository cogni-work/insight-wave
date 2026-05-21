# test_helpers.sh — shared bash helpers sourced by cogni-knowledge/tests/*.
#
# Before this file landed at v0.0.17, every test file inlined `red()` /
# `green()` (byte-identical) and re-implemented `assert_grep` with two
# divergent signatures across plugins. The cogni-wiki form took (pattern,
# description) with a $SKILL global; the cogni-knowledge form added the
# file as an explicit first argument. The 3-arg form is the more general
# of the two and is the convention adopted here.
#
# Source via:
#   . "$(dirname "$0")/fixtures/test_helpers.sh"
#
# Bash 3.2 compatible.

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

# assert_grep PATTERN FILE DESCRIPTION
#   Increments the caller's `errors` variable on failure.
assert_grep() {
  local pattern="$1" file="$2" description="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    green "PASS: $description"
  else
    red "FAIL: $description"
    red "  pattern: $pattern"
    red "  file:    $file"
    errors=$((errors + 1))
  fi
}

# assert_not_grep PATTERN FILE DESCRIPTION
#   Symmetric counterpart — fails if PATTERN is present.
assert_not_grep() {
  local pattern="$1" file="$2" description="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    red "FAIL: $description"
    red "  pattern (should NOT appear): $pattern"
    red "  file: $file"
    errors=$((errors + 1))
  else
    green "PASS: $description"
  fi
}
