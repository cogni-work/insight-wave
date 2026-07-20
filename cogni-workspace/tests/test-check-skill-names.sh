#!/usr/bin/env bash
# Regression test for scripts/check-skill-names.sh.
#
# Contract under test:
#   - stays free of the bash-4 `declare -A` construct (static guard, enforced on
#     every interpreter incl. CI bash 5.x) and, when a real bash 3.x is present
#     (e.g. /bin/bash on macOS), runs to completion under it
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

# run_check <fixture-root> [interpreter] -> sets RC and OUT
# The interpreter defaults to `bash` (PATH), so Cases 1-3 are unchanged; Case 4b
# passes a detected real bash 3.x to exercise the script under it.
run_check() {
  OUT="$(REPO_ROOT="$1" "${2:-bash}" "$CHECK" 2>&1)"; RC=$?
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

# --- Case 4: portability — the bash-4 `declare -A` construct must never return ---
# 4a is interpreter-independent: a static check that fires even on CI's bash 5.x,
# where a *runtime* declare-error check is inert (bash 5 runs `declare -A` fine).
# This is the guard that actually catches a re-introduced bash-4-ism on CI.
# Comments are stripped first so an *explanatory* `declare -A` mention (the script
# documents why it avoids the construct) is not mistaken for a code re-introduction.
# Matches the direct synonym `typeset -A` too, the other spelling of the same bash-4
# associative-array declaration.
if sed 's/#.*//' "$CHECK" | grep -qE '(declare|typeset) -A'; then
  fail "4a check-skill-names.sh re-introduced 'declare -A'/'typeset -A' in code (bash-4 only)"
else
  pass "4a check-skill-names.sh free of code-level associative-array declaration"
fi

# 4b/4c additionally exercise the script under a real bash 3.x when one exists
# (macOS system /bin/bash is 3.2.57), so the exact runtime failure this PR fixes
# is reproduced live. When no bash 3.x is present, emit a visible SKIP rather than
# a silent green.
BASH3=""
for cand in /bin/bash /usr/bin/bash; do
  [ -x "$cand" ] || continue
  if [ "$("$cand" -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null)" = "3" ]; then
    BASH3="$cand"; break
  fi
done
if [ -n "$BASH3" ]; then
  run_check "$CLEAN" "$BASH3"
  [ "$RC" -eq 0 ] && pass "4b clean tree exits 0 under real bash 3.x ($BASH3)" \
    || fail "4b clean tree exit under $BASH3 ($RC): $OUT"
  printf '%s\n' "$OUT" | grep -q "declare: -A" \
    && fail "4c 'declare: -A' runtime error under $BASH3" \
    || pass "4c no 'declare: -A' runtime error under $BASH3"
else
  echo "SKIP 4b/4c no real bash 3.x found (checked /bin/bash /usr/bin/bash) — static guard 4a still enforced"
fi

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures check-skill-names test(s) failed."
  exit 1
fi
echo ""
echo "All check-skill-names tests passed."
