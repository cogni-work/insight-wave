#!/usr/bin/env bash
# Test portfolio-init.sh — the portfolio skeleton + manifest initializer.
#
# Regression for the failure-envelope contract: a write failure at any
# _atomic_write_json call site (the three .metadata seed logs or the manifest)
# must surface the {success, data, error} envelope on stdout with a non-zero
# exit — never a raw Python traceback under `set -euo pipefail`.
#
# Covers:
#   AC-1: a write failure prints the {success:false, ...} envelope + exits non-zero.
#   AC-2: temp cleanup + manifest-written-last ordering preserved — on that
#         failure path projects-portfolio.json is absent (init correctly
#         incomplete) and no .*.tmp debris is left behind.
#   plus the happy path still emits {success:true} and writes the manifest.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
#
# Usage: bash cogni-projects/tests/test_portfolio_init.sh
# Exits non-zero on any assertion failure.

set -u  # NOT -e: a failing assertion must not abort the per-fixture counter.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/portfolio-init.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: portfolio-init.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# assert_json <label> <python-bool-expr over `d`> — pipes the captured last
# stdout line (the envelope) into python3 and checks the expression is truthy.
assert_json() {
  local label="$1" expr="$2"
  if printf '%s' "$LAST_JSON" | python3 -c "import json,sys
d = json.loads(sys.stdin.read())
sys.exit(0 if ($expr) else 1)" 2>/dev/null; then
    pass "$label"
  else
    fail "$label" "envelope assertion failed on: $LAST_JSON"
  fi
}

# --- Fixture 1: happy path -------------------------------------------------
# A clean run emits {success:true} and writes projects-portfolio.json last.
WORK1="$TMPROOT/happy"
mkdir -p "$WORK1"
OUT1="$(cd "$WORK1" && bash "$SCRIPT" demo "Demo Portfolio" 2>/dev/null)"
RC1=$?
LAST_JSON="$(printf '%s\n' "$OUT1" | tail -n 1)"
if [ "$RC1" -eq 0 ]; then pass "1a happy path exits zero"; else fail "1a happy path exits zero" "rc=$RC1"; fi
assert_json "1b happy path envelope success:true" "d['success'] is True"
if [ -f "$WORK1/cogni-projects/demo/projects-portfolio.json" ]; then
  pass "1c manifest written"
else
  fail "1c manifest written" "projects-portfolio.json missing"
fi

# --- Fixture 2: write failure -> envelope, not traceback -------------------
# Pre-create the base skeleton with a read-only .metadata dir. The script's
# `mkdir -p` is a no-op on the existing dir, then _atomic_write_json's mkstemp
# in .metadata raises PermissionError (an OSError) — the top-level guard must
# turn that into the {success:false} envelope + a non-zero exit.
if [ "$(id -u)" -eq 0 ]; then
  printf 'SKIP 2 write-failure fixture (running as root — mode bits do not deny)\n'
else
  WORK2="$TMPROOT/failure"
  mkdir -p "$WORK2/cogni-projects/demo/.metadata"
  chmod 0555 "$WORK2/cogni-projects/demo/.metadata"
  OUT2="$(cd "$WORK2" && bash "$SCRIPT" demo "Demo Portfolio" 2>/dev/null)"
  RC2=$?
  LAST_JSON="$(printf '%s\n' "$OUT2" | tail -n 1)"
  if [ "$RC2" -ne 0 ]; then pass "2a write failure exits non-zero"; else fail "2a write failure exits non-zero" "rc=$RC2"; fi
  assert_json "2b failure envelope parses"          "isinstance(d, dict)"
  assert_json "2c failure envelope success:false"   "d['success'] is False"
  assert_json "2d failure envelope carries error"   "isinstance(d.get('error'), str) and len(d['error']) > 0"
  if [ ! -f "$WORK2/cogni-projects/demo/projects-portfolio.json" ]; then
    pass "2e manifest absent on failure (init correctly incomplete)"
  else
    fail "2e manifest absent on failure" "projects-portfolio.json should not exist"
  fi
  # Restore write bit so the tmp .metadata can be inspected / cleaned, then
  # assert no half-written temp debris was left behind by _atomic_write_json.
  chmod 0755 "$WORK2/cogni-projects/demo/.metadata"
  if [ -z "$(find "$WORK2/cogni-projects/demo/.metadata" -name '.*.tmp' 2>/dev/null)" ]; then
    pass "2f no temp-file debris left behind"
  else
    fail "2f no temp-file debris left behind" "a .*.tmp file survived the failed write"
  fi
fi

# --- Summary ---------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "All portfolio-init tests passed."
  exit 0
else
  echo "$failures assertion(s) failed." >&2
  exit 1
fi
