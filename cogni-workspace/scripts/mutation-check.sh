#!/bin/bash
# mutation-check.sh — revert a guard, expect its case to go RED, restore, expect GREEN.
#
# Mutation testing is the only technique that separates a guard from a comment.
# A guard whose grep matches nothing still reports green forever; the sole proof
# that it fires is to break the thing it guards and watch its case fail. This
# plugin's review gate asks for a *replayable* recipe on every guard-bearing PR,
# which is why this harness parses flags instead of hardcoding a mutation list.
#
# Usage:
#   bash cogni-workspace/scripts/mutation-check.sh \
#     --root <dir> --file <path> --expr <perl-expr> --test <cmd> --case <case-id>
#
# All five flags are REQUIRED. There is no default for any of them.
#   --root  tree under test. NEVER inferred from this script's own location: a
#           harness that self-resolves its install directory grades whatever tree
#           it was installed into, which on a plugin path is not the checkout the
#           reviewer means. --file must live inside it, and --test runs with
#           cwd=--root, so a recipe recorded from the repo root replays from the
#           repo root.
#   --file  the file holding the guard; relative to --root, or absolute.
#   --expr  a `perl -0pi -e` expression that REMOVES or BREAKS the guard.
#   --test  shell command running the suite that contains --case.
#   --case  the case-id whose redness proves the guard fires — the first
#           whitespace-delimited token of the label passed to the suite's
#           pass()/fail() (`pass "P1 adopted trees ..."` -> --case P1).
#
# WHY THIS EXISTS AS A SEPARATE IMPLEMENTATION. The same five-flag contract is
# implemented by cogni-service/scripts/mutation-check.sh in the managed-service
# marketplace. That script is licensed LicenseRef-cogni-work-proprietary; this
# repo is Apache-2.0. Relicensing is the copyright holder's call, not a thing to
# do silently in passing, so this is an independent implementation of the same
# contract rather than a port of that code. Recipes are portable between the two
# because the FLAGS are the contract; the implementations are not shared.
#
# CLASSIFICATION READS OUTPUT LINES, NEVER THE EXIT CODE. A suite exits non-zero
# whenever ANY case is red, so keying on its exit code conflates "my case went
# red" with "some other case went red" — and the second is a baseline problem
# that says nothing about the guard under test.
#   RED    a line matching  ^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)
#   GREEN  a line matching  ^[[:space:]]*(ok|PASS):[[:space:]]+<case>([[:space:]]|$)
#          AND no RED line for that case
#   neither -> case_not_found, exit 2
#
# RED DOMINATES GREEN, PER CASE. This is not a tie-break detail, it is the single
# rule that keeps the harness honest on this repo's own suites. An aggregated
# case prints one line per tree it walks, so a genuinely-red run of `P1` in
# test-relocated-skill-hygiene.sh emits a FAIL: line AND a PASS: line together
# (PR #1834 records exactly this and warns about it). A classifier that stops at
# the first PASS: label grades that red run green, and then reports every guard
# it touches as verified — the precise false-green this harness exists to remove.
#
# Both green labels are matched because this repo genuinely uses both: the
# hygiene suites emit `PASS:`, the arc-sync suites emit `ok:`, and all of them
# emit `FAIL:`. Red is the one universal signal. Matching is whole-token, so
# --case P1 never matches a P10 line.
#
# SCOPE: this vocabulary is the insight-wave bash-suite shape and is deliberately
# fixed rather than a flag. --test accepts any command, but point it at a TAP
# harness ("not ok 1 - P1") or pytest and every run returns case_not_found,
# blaming your --case spelling for what is really an unsupported output shape.
# If this ever needs to read a foreign suite, add --green-label/--red-label; do
# not widen the regex silently.
#
# --expr is passed through the SHELL before perl sees it, so single-quote it at
# the call site. An unquoted `$` or backtick is interpolated by bash first.
#
# AN --expr THAT MATCHES NOTHING IS A HARD ERROR (expr_no_op), NOT A PASS. A
# typo'd regex mutates nothing, the case stays green, and a naive implementation
# reports "guard is fine" — inverting the whole signal. This is the most likely
# way this tool itself ships broken, so it is checked explicitly with `cmp`.
#
# RESTORE RUNS FROM A TRAP on EXIT INT TERM, so Ctrl-C or a kill mid-run still
# puts the file back. SIGKILL is untrappable and nothing in-process can restore
# through it. That gap is made LOUD rather than silent: the snapshot lives at a
# deterministic path reported in data.snapshot_path, and a pre-flight refuses to
# start when a stale snapshot for the same target already exists — turning "a
# previous run was killed and left a mutated tree" from a silently corrupted next
# result into an exit-2 naming the file to restore.
#
# The per-target LOCK is a separate artifact from the snapshot because the two
# need different lifetimes. The snapshot is killed-run evidence and is deleted
# the moment the copy back succeeds; the restored-tree test run happens AFTER
# that deletion, so snapshot-presence alone would leave a window where a second
# run could snapshot the now-pristine file and mutate it underneath the first
# run's restored phase. Both would then report a verdict and at least one would
# be wrong. The lock spans the whole run and is keyed on --file, so runs against
# different targets never contend.
#
# Environment:
#   COGNI_MUTATION_SNAPSHOT_DIR
#           overrides the root holding both artifacts. Unset OR EMPTY falls back
#           to ${TMPDIR:-/tmp}/cogni-workspace-mutation-check. The `:-` is
#           deliberate: with a bare `-` an empty value would survive and die at
#           mkdir, which is a worse failure than falling back. It exists for the
#           two callers a per-target key does not serve — a CI matrix running
#           several invocations on one runner, and a human replaying a recorded
#           recipe by hand beside a running drain.
#
# Dependencies: python3 (envelope construction and case classification) and perl,
# which --expr is written against. The did-anything-change check is a plain `cmp`
# — no hashing, so no shasum/sha256sum dependency.
#
# Output: {"success": bool, "data": {...}, "error": ...} on stdout.
#   data.case            — the case-id under verification
#   data.file            — resolved absolute path of the mutated file
#   data.root            — resolved absolute path of the tree under test
#   data.expr_applied    — the perl expression applied
#   data.mutated_result  — "red" | "green" — the case's state under mutation
#   data.restored_result — "red" | "green" — the case's state after restore
#   data.verdict         — "guard_verified" | "vacuous_guard" | "baseline_broken"
#                          | "restore_failed"
#   data.snapshot_path   — where the pristine copy lived during the run
#   data.metric_version  — pinned rule version for this classification
#
#   Exit 0 — guard_verified (red under mutation, green on restore).
#   Exit 1 — vacuous_guard, baseline_broken, or restore_failed. The RUN
#            succeeded and the GUARD did not, so the envelope stays
#            "success": true and data.verdict carries the signal.
#            baseline_broken means the case was red on the RESTORED tree while
#            the restore itself verifiably succeeded: it was already failing
#            before this run touched anything, so the guard was never assessed
#            and the run says nothing about it.
#   Exit 2 — genuine error ("success": false): a missing or invalid flag, --file
#            outside --root, expr_no_op, case_not_found, a stale snapshot, a lock
#            held by a concurrent run against the same --file, or a missing
#            dependency.

set -uo pipefail

METRIC_VERSION="1.0.0"

ROOT=""
FILE=""
EXPR=""
TEST_CMD=""
CASE_ID=""

USAGE='usage: mutation-check.sh --root <dir> --file <path> --expr <perl-expr> --test <cmd> --case <case-id>'

# Every error path emits the envelope through here. A hand-rolled
# `echo "{\"error\": \"...\"}"` breaks on any path containing a quote or
# backslash — invalid JSON out of a script whose entire contract is a JSON
# envelope — so python does the escaping. This runs BEFORE the python3
# dependency guard so a missing --expr reports itself rather than blaming
# python3; hence the fallback, which still emits an envelope, just unescaped.
die() {
  if command -v python3 >/dev/null 2>&1; then
    MSG="$1" python3 -c 'import json, os; print(json.dumps({"success": False, "data": None, "error": os.environ["MSG"]}, indent=2))'
  else
    echo "{\"success\": false, \"data\": null, \"error\": \"$1\"}"
  fi
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --file) FILE="${2:-}"; shift 2 ;;
    --expr) EXPR="${2:-}"; shift 2 ;;
    --test) TEST_CMD="${2:-}"; shift 2 ;;
    --case) CASE_ID="${2:-}"; shift 2 ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    *) die "unknown argument: $1. $USAGE" ;;
  esac
done

[ -n "$ROOT" ]     || die "--root is required. $USAGE"
[ -n "$FILE" ]     || die "--file is required. $USAGE"
[ -n "$EXPR" ]     || die "--expr is required. $USAGE"
[ -n "$TEST_CMD" ] || die "--test is required. $USAGE"
[ -n "$CASE_ID" ]  || die "--case is required. $USAGE"

command -v python3 >/dev/null 2>&1 || die "python3 not found — required for envelope construction and case classification"
command -v perl    >/dev/null 2>&1 || die "perl not found — required to apply --expr"

[ -d "$ROOT" ] || die "--root is not a directory: $ROOT"
ABS_ROOT=$(cd "$ROOT" 2>/dev/null && pwd -P) || die "--root could not be resolved: $ROOT"

case "$FILE" in
  /*) ABS_FILE="$FILE" ;;
  *)  ABS_FILE="$ABS_ROOT/$FILE" ;;
esac
[ -f "$ABS_FILE" ] || die "--file does not exist: $ABS_FILE"
ABS_FILE=$(cd "$(dirname "$ABS_FILE")" && pwd -P)/$(basename "$ABS_FILE")

# --file must live inside --root, checked on the RESOLVED paths so a `..` or a
# symlink cannot walk out of the tree under test. The trailing slash stops
# /repo-other from matching a /repo prefix.
case "$ABS_FILE/" in
  "$ABS_ROOT"/*) : ;;
  *) die "--file is outside --root: $ABS_FILE not under $ABS_ROOT" ;;
esac

SNAP_ROOT="${COGNI_MUTATION_SNAPSHOT_DIR:-}"
[ -n "$SNAP_ROOT" ] || SNAP_ROOT="${TMPDIR:-/tmp}/cogni-workspace-mutation-check"
mkdir -p "$SNAP_ROOT" 2>/dev/null || die "could not create snapshot dir: $SNAP_ROOT"

# Both artifacts are keyed on the target path, so two runs against DIFFERENT
# files never contend while two against the SAME file always do.
TARGET_KEY=$(printf '%s' "$ABS_FILE" | tr -c 'A-Za-z0-9._-' '_')
SNAPSHOT_PATH="$SNAP_ROOT/$TARGET_KEY.snapshot"
LOCK_PATH="$SNAP_ROOT/$TARGET_KEY.lock"

# Pre-flight: a snapshot already sitting here means a previous run was SIGKILLed
# with the tree still mutated. Refuse loudly and name the restore, rather than
# snapshotting a mutated file as if it were pristine.
if [ -e "$SNAPSHOT_PATH" ]; then
  die "stale snapshot present at $SNAPSHOT_PATH — a previous run was killed with $ABS_FILE still mutated. Restore it with: cp '$SNAPSHOT_PATH' '$ABS_FILE' && rm '$SNAPSHOT_PATH'"
fi

# mkdir is the atomic test-and-set; a plain -e check would race.
if ! mkdir "$LOCK_PATH" 2>/dev/null; then
  die "another mutation-check run holds the lock for this target: $LOCK_PATH. If no run is active it was killed; clear it with: rmdir '$LOCK_PATH'"
fi

RESTORE_OK="unknown"

cleanup() {
  if [ -e "$SNAPSHOT_PATH" ]; then
    if cp "$SNAPSHOT_PATH" "$ABS_FILE" 2>/dev/null; then
      rm -f "$SNAPSHOT_PATH"
      RESTORE_OK="yes"
    else
      RESTORE_OK="no"
    fi
  fi
  rmdir "$LOCK_PATH" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

cp "$ABS_FILE" "$SNAPSHOT_PATH" || die "could not snapshot $ABS_FILE to $SNAPSHOT_PATH"

if ! perl -0pi -e "$EXPR" "$ABS_FILE" 2>/dev/null; then
  die "perl failed to apply --expr to $ABS_FILE — check the expression's syntax and quoting"
fi

# The no-op check is the load-bearing one: an expression that matched nothing
# leaves a green case that would otherwise read as "the guard is fine".
if cmp -s "$SNAPSHOT_PATH" "$ABS_FILE"; then
  die "expr_no_op: --expr changed nothing in $ABS_FILE. A mutation that does not mutate cannot falsify a guard; fix the expression rather than reading the green result as a pass."
fi

# Classification is a function of the suite's OUTPUT, so the exit code is
# deliberately discarded here (`|| true`) and reconstructed per case below.
classify() {
  OUT=$( cd "$ABS_ROOT" && eval "$TEST_CMD" 2>&1 ) || true
  CLASSIFY_OUT="$OUT" CLASSIFY_CASE="$CASE_ID" python3 -c '
import os, re, sys
out = os.environ["CLASSIFY_OUT"]
case = re.escape(os.environ["CLASSIFY_CASE"])
red = re.compile(r"^[ \t]*FAIL:[ \t]+" + case + r"([ \t]|$)", re.M)
green = re.compile(r"^[ \t]*(?:ok|PASS):[ \t]+" + case + r"([ \t]|$)", re.M)
# Red is tested FIRST and wins outright: an aggregated case prints one line per
# tree it walks, so a red run legitimately carries a PASS line alongside a FAIL.
if red.search(out):
    print("red")
elif green.search(out):
    print("green")
else:
    print("none")
'
}

MUTATED_RESULT=$(classify)
if [ "$MUTATED_RESULT" = "none" ]; then
  die "case_not_found: neither 'FAIL: $CASE_ID' nor 'ok|PASS: $CASE_ID' appeared in the output of --test on the MUTATED tree. Check the --case spelling and that --test runs the suite containing it; the absence of a FAIL line is never proof of redness."
fi

# Restore before the second run: `cleanup` is idempotent, and calling it here
# means the restored-tree test runs against a tree that is verifiably pristine.
cleanup
trap - EXIT INT TERM

if [ "$RESTORE_OK" = "no" ]; then
  RESTORED_RESULT="unknown"
  VERDICT="restore_failed"
else
  RESTORED_RESULT=$(classify)
  if [ "$RESTORED_RESULT" = "none" ]; then
    die "case_not_found: the case '$CASE_ID' appeared on the mutated tree but not on the restored one. That is a suite whose case set depends on the mutation; the run cannot grade the guard."
  fi
  if [ "$MUTATED_RESULT" = "red" ] && [ "$RESTORED_RESULT" = "green" ]; then
    VERDICT="guard_verified"
  elif [ "$RESTORED_RESULT" = "red" ]; then
    # Red on a verifiably-restored tree means the case was already failing before
    # this run touched anything, so nothing here assessed the guard.
    VERDICT="baseline_broken"
  else
    VERDICT="vacuous_guard"
  fi
fi

CASE_ID="$CASE_ID" ABS_FILE="$ABS_FILE" ABS_ROOT="$ABS_ROOT" EXPR="$EXPR" \
MUTATED_RESULT="$MUTATED_RESULT" RESTORED_RESULT="$RESTORED_RESULT" \
VERDICT="$VERDICT" SNAPSHOT_PATH="$SNAPSHOT_PATH" METRIC_VERSION="$METRIC_VERSION" \
python3 -c '
import json, os
print(json.dumps({
    "success": True,
    "data": {
        "case": os.environ["CASE_ID"],
        "file": os.environ["ABS_FILE"],
        "root": os.environ["ABS_ROOT"],
        "expr_applied": os.environ["EXPR"],
        "mutated_result": os.environ["MUTATED_RESULT"],
        "restored_result": os.environ["RESTORED_RESULT"],
        "verdict": os.environ["VERDICT"],
        "snapshot_path": os.environ["SNAPSHOT_PATH"],
        "metric_version": os.environ["METRIC_VERSION"],
    },
    "error": None,
}, indent=2))
'

[ "$VERDICT" = "guard_verified" ] && exit 0
exit 1
