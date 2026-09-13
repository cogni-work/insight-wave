#!/usr/bin/env bash
# Regression test for scripts/check-skill-names.sh.
#
# Contract under test:
#   - stays free of the bash-4 `declare -A` construct (static guard, enforced on
#     every interpreter incl. CI bash 5.x)
#   - detects a skill name duplicated across plugins (ERROR + exit 1)
#   - detects a generic name without a domain prefix (ERROR + exit 1)
#   - a clean, correctly-prefixed tree reports OK and exits 0
#   - a literal tab inside a skill name does not fabricate a duplicate
#
# Every behavioural case runs under each interpreter in $INTERPRETERS: PATH
# `bash` plus a real bash 3.x when the host has a distinct one (macOS /bin/bash
# is 3.2.57). The second interpreter is what keeps the coverage honest — PATH
# `bash` is frequently a newer homebrew build, and running only under it leaves
# the script's *violation* path (the `${awk_violations:-0}` fold and the
# `if [[ $violations -gt 0 ]]` branch) unexercised on the very interpreter this
# check exists to support. A bash-4-ism reachable only from that path — say
# `${var^^}` or `mapfile`, neither of which the static guard looks for — would
# otherwise ship undetected.
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
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

# Slug an interpreter path into a case-id discriminator: /bin/bash -> bin-bash,
# /opt/homebrew/bin/bash -> opt-homebrew-bin-bash. The discriminator has to come
# from the FULL PATH, never `basename` — every interpreter in the matrix is named
# `bash`, so a basename-derived slug is constant and the ids still collide.
# Parameter expansion, not `tr -c 'A-Za-z0-9' '-'`: that form turns the leading
# `/` and the trailing newline into dashes and yields `-bin-bash-`.
bin_slug() { local _p="${1#/}"; printf '%s' "${_p//\//-}"; }

# Assert the script under test exists before anything reads it. Without this the
# static guard (Case 4) would sed/grep a missing file, match nothing, and report a
# spurious PASS — and on Linux/CI, where no bash 3.x exists, Case 4 is the only
# portability assertion left standing.
[ -f "$CHECK" ] || { fail "C0 script under test not found at $CHECK"; exit 1; }

# Interpreter matrix, derived once. Only *distinct* binaries are listed: on a
# stock macOS with no homebrew bash, PATH `bash` already IS /bin/bash 3.2.57, and
# running the same binary twice per case would buy no coverage.
PATH_BASH="$(command -v bash)"
BASH3=""
if [ "$("$PATH_BASH" -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null)" = "3" ]; then
  BASH3="$PATH_BASH"
else
  for cand in /bin/bash /usr/bin/bash; do
    [ -x "$cand" ] || continue
    if [ "$("$cand" -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null)" = "3" ]; then
      BASH3="$cand"; break
    fi
  done
fi
INTERPRETERS="$PATH_BASH"
if [ -n "$BASH3" ] && [ "$BASH3" != "$PATH_BASH" ]; then
  INTERPRETERS="$INTERPRETERS $BASH3"
fi
if [ -n "$BASH3" ]; then
  echo "INFO interpreters: $INTERPRETERS (real bash 3.x: $BASH3)"
else
  echo "SKIP no real bash 3.x found (checked PATH bash, /bin/bash, /usr/bin/bash) — behavioural cases run under $PATH_BASH only; static guard 4a still enforced"
fi

# mk_skill <fixture-root> <plugin> <skill-dir> <name>
mk_skill() {
  local d="$1/$2/skills/$3"
  mkdir -p "$d"
  printf -- '---\nname: %s\ndescription: fixture skill\n---\n' "$4" > "$d/SKILL.md"
}

# run_check <fixture-root> <interpreter> -> sets RC and OUT
# The interpreter is a required argument, so no call site can silently fall back
# to PATH bash and quietly drop the bash-3.x half of the matrix.
run_check() {
  OUT="$(REPO_ROOT="$1" "$2" "$CHECK" 2>&1)"; RC=$?
}

# Assertions read RC/OUT from the last run_check. `case` does fixed-string
# containment as a shell builtin, so an assertion costs no fork.
assert_rc()        { [ "$RC" -eq "$1" ] && pass "$2" || fail "$2 — exit $RC, want $1: $OUT"; }
assert_out_has()   { case "$OUT" in *"$1"*) pass "$2" ;; *) fail "$2 — missing '$1': $OUT" ;; esac; }
assert_out_lacks() { case "$OUT" in *"$1"*) fail "$2 — unexpected '$1': $OUT" ;; *) pass "$2" ;; esac; }

# Scoped to the bash 3.x interpreter: bash >= 4 executes `declare -A` fine and so
# is structurally incapable of emitting this error. Reporting it green there would
# be exactly the vacuous coverage the matrix above exists to eliminate.
assert_no_bash4_error() {
  [ "$BIN" = "$BASH3" ] || return 0
  case "$OUT" in
    *"declare: -A"*|*"typeset: -A"*) fail "$1 — bash-4 associative-array runtime error: $OUT" ;;
    *) pass "$1" ;;
  esac
}

# --- Case 1: clean, correctly-prefixed tree -> OK, exit 0 ---
CLEAN="$TMPROOT/clean"
mk_skill "$CLEAN" cogni-alpha alpha-setup alpha-setup
mk_skill "$CLEAN" cogni-beta beta-dashboard beta-dashboard
for BIN in $INTERPRETERS; do
  BIN_SLUG="$(bin_slug "$BIN")"
  run_check "$CLEAN" "$BIN"
  assert_rc 0 "1a-$BIN_SLUG clean tree exits 0 ($BIN)"
  assert_out_has "OK: All skill names follow the naming convention." "1b-$BIN_SLUG clean tree reports OK ($BIN)"
  assert_no_bash4_error "1c-$BIN_SLUG clean tree free of bash-4 runtime error ($BIN)"
done

# --- Case 2: duplicate name across two plugins -> ERROR, exit 1 ---
# 2c pins the FAIL summary because it is emitted from the violation branch, past
# the `${awk_violations:-0}` fold — the stretch of the script the matrix exists
# to reach under bash 3.x.
DUP="$TMPROOT/dup"
mk_skill "$DUP" cogni-alpha alpha-x iw-shared
mk_skill "$DUP" cogni-beta beta-y iw-shared
for BIN in $INTERPRETERS; do
  BIN_SLUG="$(bin_slug "$BIN")"
  run_check "$DUP" "$BIN"
  assert_rc 1 "2a-$BIN_SLUG duplicate exits 1 ($BIN)"
  assert_out_has "ERROR: Duplicate skill name 'iw-shared' in:" "2b-$BIN_SLUG duplicate ERROR line ($BIN)"
  assert_out_has "FAIL: 1 naming violation(s) found." "2c-$BIN_SLUG duplicate FAIL summary ($BIN)"
  assert_no_bash4_error "2d-$BIN_SLUG duplicate free of bash-4 runtime error ($BIN)"
done

# --- Case 3: generic name without a domain prefix -> ERROR, exit 1 ---
GEN="$TMPROOT/gen"
mk_skill "$GEN" cogni-alpha the-dash dashboard
for BIN in $INTERPRETERS; do
  BIN_SLUG="$(bin_slug "$BIN")"
  run_check "$GEN" "$BIN"
  assert_rc 1 "3a-$BIN_SLUG generic exits 1 ($BIN)"
  assert_out_has "ERROR: Generic skill name 'dashboard' requires a domain prefix" "3b-$BIN_SLUG generic ERROR line ($BIN)"
  assert_no_bash4_error "3c-$BIN_SLUG generic free of bash-4 runtime error ($BIN)"
done

# --- Case 4: portability — no bash-4-only construct may reach the script ---
# 4a is a source-text check, so it fires even on CI's bash 5.x, where a runtime
# check is inert (bash 5 runs these constructs fine). On a host with no bash 3.x
# it is the ONLY portability assertion standing, which is why it enumerates the
# bash-4-only forms someone might plausibly reach for rather than `declare -A`
# alone: a guard that covers one construct lets every other bash-4-ism ship green
# on CI. The list is necessarily incomplete — the live bash-3.x half of the
# contract (the assert_no_bash4_error step of the fixture cases, which reaches the
# violation path as well as the OK branch) is what catches the rest, wherever a
# real bash 3.x exists. Comments are stripped first so the script's own
# explanation of what it avoids is not read as a re-introduction.
CHECK_SRC="$(sed 's/#.*//' "$CHECK")"
bash4_hits=""
for pat in \
  '(declare|typeset|local)[[:space:]]+-[A-Za-z]*[An]' \
  '\$\{[A-Za-z_][A-Za-z0-9_]*(\^\^|,,|\^|,)' \
  '(^|[;&|[:space:]])(mapfile|readarray)([[:space:]]|$)' \
  '\$\{[A-Za-z_][A-Za-z0-9_]*@[QEPAKauL]\}'
do
  if printf '%s\n' "$CHECK_SRC" | grep -qE "$pat"; then
    bash4_hits="$bash4_hits
    $pat"
  fi
done
if [ -n "$bash4_hits" ]; then
  fail "4a check-skill-names.sh contains bash-4-only construct(s) matching:$bash4_hits"
else
  pass "4a check-skill-names.sh free of the enumerated bash-4-only constructs"
fi

# --- Case 5: a literal tab inside a skill name must not fabricate a duplicate ---
# The script streams `name<TAB>plugin` pairs into `awk -F'\t'`, so an unsanitized
# tab would let a name's tail be read as the plugin column — turning an unrelated
# skill named `foo` into a phantom collision with `foo<TAB>bar`.
TABF="$TMPROOT/tabname"
mk_skill "$TABF" cogni-alpha alpha-tab "$(printf 'foo\tbar')"
mk_skill "$TABF" cogni-beta beta-foo foo
for BIN in $INTERPRETERS; do
  BIN_SLUG="$(bin_slug "$BIN")"
  run_check "$TABF" "$BIN"
  assert_rc 0 "5a-$BIN_SLUG tabbed name exits 0 ($BIN)"
  assert_out_lacks "ERROR: Duplicate skill name 'foo'" "5b-$BIN_SLUG tabbed name reports no phantom duplicate ($BIN)"
  assert_no_bash4_error "5c-$BIN_SLUG tabbed name free of bash-4 runtime error ($BIN)"
done

# --- Cases 6-8: the compatibility-delegate marker ---
# A same-name route left behind when a skill moves plugins carries
# `<!-- compatibility-delegate: <owner> -->`. It is exempt from the duplicate
# count only while <owner> really ships the skill (6); a marker naming a plugin
# without it routes to nothing and is an error (7); and the exemption covers the
# marked copy alone, so a third, unmarked copy is still a duplicate (8).
mk_delegate() {
  mk_skill "$1" "$2" "$3" "$4"
  printf '\n<!-- compatibility-delegate: %s -->\n\nDelegates.\n' "$5" >> "$1/$2/skills/$3/SKILL.md"
}
DELOK="$TMPROOT/delegate-ok"
mk_skill "$DELOK" cogni-alpha theme-x theme-x
mk_delegate "$DELOK" cogni-beta theme-x theme-x cogni-alpha
DELBAD="$TMPROOT/delegate-dangling"
mk_skill "$DELBAD" cogni-alpha alpha-other alpha-other
mk_delegate "$DELBAD" cogni-beta theme-y theme-y cogni-alpha
DELDUP="$TMPROOT/delegate-plus-duplicate"
mk_skill "$DELDUP" cogni-alpha theme-z theme-z
mk_delegate "$DELDUP" cogni-beta theme-z theme-z cogni-alpha
mk_skill "$DELDUP" cogni-gamma theme-z theme-z
for BIN in $INTERPRETERS; do
  BIN_SLUG="$(bin_slug "$BIN")"
  run_check "$DELOK" "$BIN"
  assert_rc 0 "6a-$BIN_SLUG owner-backed delegate exits 0 ($BIN)"
  assert_out_lacks "ERROR: Duplicate skill name 'theme-x'" "6b-$BIN_SLUG owner-backed delegate is not a duplicate ($BIN)"
  run_check "$DELBAD" "$BIN"
  assert_rc 1 "7a-$BIN_SLUG dangling delegate exits 1 ($BIN)"
  assert_out_has "ERROR: Compatibility delegate 'theme-y' in cogni-beta names cogni-alpha" "7b-$BIN_SLUG dangling delegate ERROR line ($BIN)"
  run_check "$DELDUP" "$BIN"
  assert_rc 1 "8a-$BIN_SLUG marker does not mask a real duplicate, exits 1 ($BIN)"
  assert_out_has "ERROR: Duplicate skill name 'theme-z' in:" "8b-$BIN_SLUG real duplicate still reported beside a delegate ($BIN)"
  assert_no_bash4_error "8c-$BIN_SLUG delegate cases free of bash-4 runtime error ($BIN)"
done

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures check-skill-names test(s) failed."
  exit 1
fi
echo ""
echo "All check-skill-names tests passed."
