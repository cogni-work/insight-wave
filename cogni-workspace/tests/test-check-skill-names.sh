#!/usr/bin/env bash
# Regression test for scripts/check-skill-names.sh.
#
# Contract under test:
#   - runs to completion under bash 3.2 (macOS system bash) — no `declare -A`
#   - detects a skill name duplicated across plugins (ERROR + non-zero exit)
#   - detects a generic name without a domain prefix (ERROR + non-zero exit)
#   - a clean, correctly-prefixed tree reports OK and exits 0
#
# The check globs "$REPO_ROOT"/cogni-*/skills/*/SKILL.md, so each case builds a
# throwaway fixture tree and points the script at it via the REPO_ROOT override.
#
# stdlib-only: bash + coreutils, no pip deps. Mirrors tests/test-sanitize-theme.sh.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
CHECK="$WS_ROOT/scripts/check-skill-names.sh"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "OK   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

# mk_skill <fixture-root> <plugin> <skill-dir> <name>
mk_skill() {
  local d="$1/$2/skills/$3"
  mkdir -p "$d"
  printf -- '---\nname: %s\ndescription: fixture skill\n---\n' "$4" > "$d/SKILL.md"
}

# run_check <fixture-root> -> sets RC and OUT
run_check() {
  OUT="$(REPO_ROOT="$1" bash "$CHECK" 2>&1)"; RC=$?
}

# --- Case 1: clean, correctly-prefixed tree -> OK, exit 0 ---
CLEAN="$TMPROOT/clean"
mk_skill "$CLEAN" cogni-alpha alpha-setup alpha-setup
mk_skill "$CLEAN" cogni-beta beta-dashboard beta-dashboard
run_check "$CLEAN"
[ "$RC" -eq 0 ] && pass "1a clean tree exits 0" || fail "1a clean tree exit ($RC)"
printf '%s\n' "$OUT" | grep -qF "OK: All skill names follow the naming convention." \
  && pass "1b clean tree reports OK" || fail "1b clean tree OK line ($OUT)"

# --- Case 2: duplicate name across two plugins -> ERROR, exit 1 ---
DUP="$TMPROOT/dup"
mk_skill "$DUP" cogni-alpha alpha-x iw-shared
mk_skill "$DUP" cogni-beta beta-y iw-shared
run_check "$DUP"
[ "$RC" -ne 0 ] && pass "2a duplicate exits non-zero" || fail "2a duplicate exit ($RC)"
printf '%s\n' "$OUT" | grep -qF "ERROR: Duplicate skill name 'iw-shared' in:" \
  && pass "2b duplicate ERROR line" || fail "2b duplicate ERROR line ($OUT)"

# --- Case 3: generic name without a domain prefix -> ERROR, exit 1 ---
GEN="$TMPROOT/gen"
mk_skill "$GEN" cogni-alpha the-dash dashboard
run_check "$GEN"
[ "$RC" -ne 0 ] && pass "3a generic exits non-zero" || fail "3a generic exit ($RC)"
printf '%s\n' "$OUT" | grep -qF "ERROR: Generic skill name 'dashboard' requires a domain prefix" \
  && pass "3b generic ERROR line" || fail "3b generic ERROR line ($OUT)"

# --- Case 4: portability — no bash-4 `declare -A` failure surfaces ---
run_check "$CLEAN"
printf '%s\n' "$OUT" | grep -q "declare: -A" \
  && fail "4 no declare -A error (found under $(bash --version | head -1))" \
  || pass "4 no declare -A error under $(bash --version | head -1 | sed 's/ (.*//')"

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures check-skill-names test(s) failed."
  exit 1
fi
echo ""
echo "All check-skill-names tests passed."
