#!/usr/bin/env bash
# test-mutation-check.sh — the harness that grades guards, graded itself.
#
# cogni-workspace/scripts/mutation-check.sh is the tool every other guard in this
# plugin gets proven with, so its own failure modes are the ones that matter
# most: each of them turns "this guard is load-bearing" into a claim nobody
# checked. Two of the cases below are the false-green shapes named in the
# script's header and in #1833 — an expression that mutates nothing (M3), and an
# aggregated case whose red run also prints a PASS line (M6).
#
# Every case runs against a self-contained fixture suite written into a temp
# tree, never against a real cogni-workspace suite: a test that mutated a real
# guard file would race any other run in the same checkout, and a kill here would
# leave the repo's own tree mutated.
#
# Each case that touches snapshot or lock state gets its OWN snapshot root, so
# no case can leave state that decides another one's verdict.
#
# Case-label shape is "PASS: <case>" / "FAIL: <case>", the vocabulary
# check-result-line-plainness.py protects and the one this harness classifies on.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
WS_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
HARNESS="$WS_ROOT/scripts/mutation-check.sh"

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/mutation-check-test.XXXXXX")
# A dedicated snapshot root under WORK keeps these runs from contending with a
# real drain replaying a recorded recipe on the same machine, and means the
# single cleanup below reclaims every artifact any case created.
export COGNI_MUTATION_SNAPSHOT_DIR="$WORK/snapshots"
cleanup_all() { rm -rf "$WORK"; }
trap cleanup_all EXIT

# ---------------------------------------------------------------------------
# Fixture. guarded.txt holds the token the guard looks for; the fixture suite
# emits a plain PASS:/FAIL: pair for case G1 depending on whether it is there.

build_fixture() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'LOAD_BEARING_TOKEN\n# a comment line that no guard reads\n' > "$dir/guarded.txt"
  cat > "$dir/suite.sh" <<'FIXTURE'
#!/usr/bin/env bash
# Fixture suite: case G1 is green only while the token survives in guarded.txt.
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
if grep -q 'LOAD_BEARING_TOKEN' "$dir/guarded.txt"; then
  echo "PASS: G1 the guarded token is present"
  exit 0
fi
echo "FAIL: G1 the guarded token is missing"
exit 1
FIXTURE
  chmod +x "$dir/suite.sh"
}

# An aggregated case: one case-id, one line per item walked, so a genuinely-red
# run prints a FAIL line AND a PASS line. This is the exact shape PR #1834
# recorded for P1 and warned about.
build_aggregated_fixture() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'LOAD_BEARING_TOKEN\n' > "$dir/guarded.txt"
  cat > "$dir/suite.sh" <<'FIXTURE'
#!/usr/bin/env bash
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# The first item always passes; the second keys on the token. A red run
# therefore emits both labels for the same case-id.
echo "PASS: A1 item one always holds"
if grep -q 'LOAD_BEARING_TOKEN' "$dir/guarded.txt"; then
  echo "PASS: A1 item two holds"
  exit 0
fi
echo "FAIL: A1 item two does not hold"
exit 1
FIXTURE
  chmod +x "$dir/suite.sh"
}

run_harness() { # captures stdout+stderr into HARNESS_OUT, exit code into RC
  HARNESS_OUT=$("$@" 2>&1); RC=$?
}

verdict_of() { printf '%s' "$1" | python3 -c 'import json,sys
try: print((json.load(sys.stdin).get("data") or {}).get("verdict",""))
except Exception: print("")'; }

field_of() { printf '%s' "$1" | CK_F="$2" python3 -c 'import json,os,sys
try: print((json.load(sys.stdin).get("data") or {}).get(os.environ["CK_F"],""))
except Exception: print("")'; }

# Must key on the SAME string the harness does, which is the fully-resolved
# path. On macOS /tmp is a symlink to /private/tmp, so keying on the unresolved
# path yields a different filename and the planted artifact is never found —
# which reads as "the guard did not fire" when the guard was never reached.
target_key() {
  local p; p=$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")
  printf '%s' "$p" | tr -c 'A-Za-z0-9._-' '_'
}

# ---------------------------------------------------------------------------
# Case M1 — a load-bearing guard is reported verified.

d="$WORK/m1"; build_fixture "$d"
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case G1
v=$(verdict_of "$HARNESS_OUT")
if [ "$v" = "guard_verified" ] && [ "$RC" -eq 0 ] \
   && [ "$(field_of "$HARNESS_OUT" mutated_result)" = "red" ] \
   && [ "$(field_of "$HARNESS_OUT" restored_result)" = "green" ]; then
  pass "M1 a load-bearing guard reports guard_verified (red under mutation, green on restore, exit 0)"
else
  fail "M1 a load-bearing guard must report guard_verified: got verdict='$v' rc=$RC"
fi

# The tree must be pristine afterwards — an unrestored mutation silently
# corrupts every later result in the same session.
if [ "$(cat "$d/guarded.txt")" = "$(printf 'LOAD_BEARING_TOKEN\n# a comment line that no guard reads')" ]; then
  pass "M2 the mutated file is restored byte-for-byte after a verified run"
else
  fail "M2 the mutated file must be restored byte-for-byte after a verified run"
fi

# ---------------------------------------------------------------------------
# Case M3 — the false-green shape. An expression matching nothing mutates
# nothing, the case stays green, and a naive harness reports the guard fine.

d="$WORK/m3"; build_fixture "$d"
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/NO_SUCH_TOKEN_ANYWHERE/REPLACED/' \
  --test 'bash suite.sh' --case G1
if [ "$RC" -eq 2 ] && printf '%s' "$HARNESS_OUT" | grep -q 'expr_no_op'; then
  pass "M3 an --expr that matches nothing is a hard error, never a pass (expr_no_op, exit 2)"
else
  fail "M3 an --expr that matches nothing must be expr_no_op with exit 2: got rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M4 — a mutation that changes the file without breaking the guard is
# reported NOT verified. This is the second direction #1833 requires: a harness
# that only ever returns "verified" proves nothing.

d="$WORK/m4"; build_fixture "$d"
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/a comment line that no guard reads/a different comment/' \
  --test 'bash suite.sh' --case G1
v=$(verdict_of "$HARNESS_OUT")
if [ "$v" = "vacuous_guard" ] && [ "$RC" -eq 1 ] \
   && [ "$(field_of "$HARNESS_OUT" mutated_result)" = "green" ]; then
  pass "M4 a mutation the guard does not notice reports vacuous_guard (exit 1)"
else
  fail "M4 a mutation the guard does not notice must report vacuous_guard: got verdict='$v' rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M5 — a case-id that appears nowhere in the output is case_not_found, not
# a verdict. The ABSENCE of a FAIL line must never read as proof of redness.

d="$WORK/m5"; build_fixture "$d"
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case G99
if [ "$RC" -eq 2 ] && printf '%s' "$HARNESS_OUT" | grep -q 'case_not_found'; then
  pass "M5 an unmatched --case is case_not_found, never a verdict (exit 2)"
else
  fail "M5 an unmatched --case must be case_not_found with exit 2: got rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M6 — red dominates green within one case. The aggregated fixture emits
# both labels for A1 on a red run; a classifier that stops at the PASS label
# grades it green and then reports every guard it touches as verified.

d="$WORK/m6"; build_aggregated_fixture "$d"
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case A1
v=$(verdict_of "$HARNESS_OUT")
if [ "$v" = "guard_verified" ] && [ "$(field_of "$HARNESS_OUT" mutated_result)" = "red" ]; then
  pass "M6 a red run that also prints a PASS line for the same case classifies red"
else
  fail "M6 red must dominate green within one case: got verdict='$v' mutated='$(field_of "$HARNESS_OUT" mutated_result)'"
fi

# ---------------------------------------------------------------------------
# Case M7 — --case matches whole tokens only, so G1 never matches a G10 line.

d="$WORK/m7"; mkdir -p "$d"
printf 'LOAD_BEARING_TOKEN\n' > "$d/guarded.txt"
cat > "$d/suite.sh" <<'FIXTURE'
#!/usr/bin/env bash
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
if grep -q 'LOAD_BEARING_TOKEN' "$dir/guarded.txt"; then
  echo "PASS: G10 the decoy case is green"
else
  echo "FAIL: G10 the decoy case is red"
fi
exit 0
FIXTURE
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case G1
if [ "$RC" -eq 2 ] && printf '%s' "$HARNESS_OUT" | grep -q 'case_not_found'; then
  pass "M7 --case matches whole tokens only (G1 does not match a G10 line)"
else
  fail "M7 --case must match whole tokens only: G1 matched a G10 line, rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M8 — --file outside --root is refused. Checked on resolved paths, so a
# `..` or a symlink cannot walk out of the tree under test.

d="$WORK/m8"; build_fixture "$d"; mkdir -p "$WORK/m8-outside"
printf 'x\n' > "$WORK/m8-outside/other.txt"
run_harness bash "$HARNESS" --root "$d" --file "$WORK/m8-outside/other.txt" \
  --expr 's/x/y/' --test 'bash suite.sh' --case G1
if [ "$RC" -eq 2 ] && printf '%s' "$HARNESS_OUT" | grep -q 'outside --root'; then
  pass "M8 a --file outside --root is refused (exit 2)"
else
  fail "M8 a --file outside --root must be refused: got rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M9 — every flag is required; none has a default that could silently
# grade the wrong thing.

d="$WORK/m9"; build_fixture "$d"
missing_ok=1
for omit in root file expr test case; do
  args=(--root "$d" --file guarded.txt --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' --test 'bash suite.sh' --case G1)
  filtered=(); skip_next=0
  for a in "${args[@]}"; do
    if [ "$skip_next" -eq 1 ]; then skip_next=0; continue; fi
    if [ "$a" = "--$omit" ]; then skip_next=1; continue; fi
    filtered+=("$a")
  done
  run_harness bash "$HARNESS" "${filtered[@]}"
  if [ "$RC" -ne 2 ]; then missing_ok=0; fi
done
if [ "$missing_ok" -eq 1 ]; then
  pass "M9 every one of the five flags is required (each omission exits 2)"
else
  fail "M9 every one of the five flags must be required"
fi

# ---------------------------------------------------------------------------
# Case M10 — a stale snapshot means a previous run was killed with the tree
# still mutated. Refuse loudly rather than snapshotting a mutated file as if it
# were pristine, which would invert the next run's verdict.
#
# Runs under its own snapshot root so the planted artifact cannot outlive the
# case and decide a later one.

d="$WORK/m10"; build_fixture "$d"
m10_snaps="$WORK/snapshots-m10"; mkdir -p "$m10_snaps"
printf 'pristine\n' > "$m10_snaps/$(target_key "$d/guarded.txt").snapshot"
run_harness env COGNI_MUTATION_SNAPSHOT_DIR="$m10_snaps" bash "$HARNESS" \
  --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case G1
if [ "$RC" -eq 2 ] && printf '%s' "$HARNESS_OUT" | grep -q 'stale snapshot'; then
  pass "M10 a stale snapshot refuses the run and names the restore (exit 2)"
else
  fail "M10 a stale snapshot must refuse the run: got rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M11 — a lock held for the same target refuses a second concurrent run.
# Two runs mutating one file would each report a verdict and at least one would
# be wrong. Own snapshot root, same reason as M10.

d="$WORK/m11"; build_fixture "$d"
m11_snaps="$WORK/snapshots-m11"; mkdir -p "$m11_snaps/$(target_key "$d/guarded.txt").lock"
run_harness env COGNI_MUTATION_SNAPSHOT_DIR="$m11_snaps" bash "$HARNESS" \
  --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case G1
if [ "$RC" -eq 2 ] && printf '%s' "$HARNESS_OUT" | grep -q 'holds the lock'; then
  pass "M11 a lock held for the same target refuses a concurrent run (exit 2)"
else
  fail "M11 a held lock must refuse a concurrent run: got rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M12 — a case already red before the run is baseline_broken, not
# guard_verified. The guard was never assessed, so the run must say so rather
# than crediting the mutation for a redness it did not cause.

d="$WORK/m12"; mkdir -p "$d"
printf 'LOAD_BEARING_TOKEN\nfiller\n' > "$d/guarded.txt"
cat > "$d/suite.sh" <<'FIXTURE'
#!/usr/bin/env bash
echo "FAIL: G1 this case is red no matter what"
exit 1
FIXTURE
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/filler/other/' --test 'bash suite.sh' --case G1
v=$(verdict_of "$HARNESS_OUT")
if [ "$v" = "baseline_broken" ] && [ "$RC" -eq 1 ]; then
  pass "M12 a case red on the restored tree is baseline_broken, not guard_verified (exit 1)"
else
  fail "M12 a case red on the restored tree must be baseline_broken: got verdict='$v' rc=$RC"
fi

# ---------------------------------------------------------------------------
# Case M13 — the emitted envelope is the plugin's JSON shape on a clean run.

d="$WORK/m13"; build_fixture "$d"
run_harness bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'bash suite.sh' --case G1
if printf '%s' "$HARNESS_OUT" | python3 -c 'import json,sys
d=json.load(sys.stdin)
assert set(d) == {"success","data","error"}, d.keys()
assert d["success"] is True
for k in ("case","file","root","expr_applied","mutated_result","restored_result","verdict","snapshot_path","metric_version"):
    assert k in d["data"], k
' 2>/dev/null; then
  pass "M13 a clean run returns the plugin JSON envelope with every documented data field"
else
  fail "M13 a clean run must return the plugin JSON envelope with every documented data field"
fi

# ---------------------------------------------------------------------------
# Case M14 — an interrupted run still restores the file. A kill -TERM is
# trappable and must restore; SIGKILL is not, and is covered by M10's
# stale-snapshot refusal instead.

d="$WORK/m14"; build_fixture "$d"
before=$(cat "$d/guarded.txt")
bash "$HARNESS" --root "$d" --file guarded.txt \
  --expr 's/LOAD_BEARING_TOKEN/BROKEN_TOKEN/' \
  --test 'sleep 20' --case G1 >/dev/null 2>&1 &
harness_pid=$!
sleep 2
kill -TERM "$harness_pid" 2>/dev/null
wait "$harness_pid" 2>/dev/null
sleep 1
if [ "$(cat "$d/guarded.txt")" = "$before" ]; then
  pass "M14 an interrupted run restores the mutated file"
else
  fail "M14 an interrupted run must restore the mutated file"
fi

# ---------------------------------------------------------------------------

if [ "$failures" -gt 0 ]; then
  echo
  echo "FAIL: $failures mutation-check test(s) failed."
  exit 1
fi

echo
echo "OK: mutation-check harness checks passed."
