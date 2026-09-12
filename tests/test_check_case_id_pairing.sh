#!/usr/bin/env bash
# test_check_case_id_pairing.sh — suite for the case-id pairing guard.
#
# Case labels are `<id> <description>` — an id token followed by a SPACE, never
# a colon abutting the id. A mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` whole-token, so
# `--case P1` matches `FAIL: P1 ...` while `--case 'P1:'` would match neither
# arm and report case_not_found instead of a verdict. No id here is a prefix of
# another (there is no P10), so every `--case` resolves unambiguously.
#
# SELF-SCAN is DUAL: this file sits inside the population BOTH repo-root guards
# scan. For the pairing guard, every case id below is emitted through `check`,
# which carries both labels in one body — a PAIRED emitter, so its call sites
# are self-pairing by construction and this suite can never flag itself. Do NOT
# add a single-arm helper here. Every dirty fixture is written through a
# heredoc, whose body the guard skips, so an unpaired `FAIL: <id>` lands in the
# fixture and never in this source. For the plainness guard, this file spells no
# escape literal at all.
#
# ZERO DISCOVERY IS RED: the guard treats an empty sweep as a failure, so every
# fixture tree whose case asserts exit 0 or 1 must also contain at least one
# in-scope suite. Without that, a tree meant to prove an exclusion would exit 2
# and the case would silently be grading the empty-sweep path instead.
#
# Mutation recipe (the recorded invocation; see also the PR that added this):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-case-id-pairing.py \
#     --expr 's/if red_id in green_ids/if True/' \
#     --test 'bash tests/test_check_case_id_pairing.sh' --case P1
#
# bash 3.2 + python3 stdlib only.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-case-id-pairing.py"

red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

FAILED=0

check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

# Argument order matches tests/test_check_result_line_plainness.sh's check_eq,
# so an assertion copied between the two repo-root suites cannot silently print
# its expected and actual the wrong way round.
check_eq() {  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    check "$1" 0
  else
    check "$1 (expected $2, got $3)" 1
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

OUT="$WORK/out.json"
CODE=0

run_guard() {  # run_guard <root>
  set +e
  python3 "$GUARD" --root "$1" > "$OUT" 2>/dev/null
  CODE=$?
  set -e
}

# Label first, matching check/check_eq. stderr is deliberately NOT suppressed:
# a traceback cannot be mistaken for a result line, since none of its lines
# begin with PASS: or FAIL:.
py_assert() {  # py_assert <label> <python-body, single-quoted strings only>
  set +e
  OUT_PATH="$OUT" python3 -c "
import json, os, sys
d = json.load(open(os.environ['OUT_PATH']))
s = d['data']['summary'] if d.get('data') else {}
v = d['data']['violations'] if d.get('data') else []
$2
"
  rc=$?
  set -e
  check "$1" "$rc"
}

# Every fixture tree gets this alongside whatever it is really testing, so the
# tree is never empty and the case grades its own subject rather than the
# zero-discovery path.
mk_clean_suite() {  # mk_clean_suite <abs-path>
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<'CLEAN'
#!/usr/bin/env bash
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }
if [ -d / ]; then
  green "PASS: clean-probe-01 root exists"
else
  red "FAIL: clean-probe-01 root missing"
fi
CLEAN
}

# --- P1: an unpaired direct-literal FAIL arm is flagged ---------------------
# This is the mutation target. It asserts the reported id, not just the exit
# code: a case that only checked rc would still pass against a guard that
# flagged something else entirely.
mk_clean_suite "$WORK/p1/tests/clean.sh"
cat > "$WORK/p1/tests/dirty.sh" <<'DIRTY'
#!/usr/bin/env bash
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }
if [ ! -f /nonexistent ]; then
  red "FAIL: only-red-01 the subject is missing"
  errors=1
fi
DIRTY
run_guard "$WORK/p1"
check_eq "P1 an unpaired direct-literal FAIL arm is flagged" "1" "$CODE"
py_assert "P1b the finding names the offending id, arm, file and line" "
ids = [x['case_id'] for x in v]
assert ids == ['only-red-01'], ids
assert v[0]['arm'] == 'unpaired_fail_id', v[0]['arm']
assert v[0]['file'].endswith('tests/dirty.sh'), v[0]['file']
assert isinstance(v[0]['line'], int) and v[0]['line'] > 0, v[0]['line']
"

# --- P2: an unpaired single-arm-helper CALL SITE is flagged -----------------
# The dominant emission shape in this tree: the label lives in the definition,
# the id arrives as $1. A same-line scan cannot see this at all.
mk_clean_suite "$WORK/p2/tests/clean.sh"
cat > "$WORK/p2/tests/dirty.sh" <<'DIRTY'
#!/usr/bin/env bash
failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }
pass "helper-01 this one is paired"
fail "helper-01 this one is paired"
fail "helper-02 this one has no green twin"
DIRTY
run_guard "$WORK/p2"
check_eq "P2 an unpaired single-arm-helper call site is flagged" "1" "$CODE"
py_assert "P2b only the unpaired call-site id is reported" "
ids = [x['case_id'] for x in v]
assert ids == ['helper-02'], ids
"

# --- P3: `ok:` counts as green, and a mismatch is still flagged -------------
mk_clean_suite "$WORK/p3/tests/clean.sh"
cat > "$WORK/p3/tests/dirty.sh" <<'DIRTY'
#!/usr/bin/env bash
failures=0
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }
pass ok-paired-01 "green arm"
fail ok-paired-01 "red arm"
fail ok-orphan-02 "red arm with no ok: twin"
DIRTY
run_guard "$WORK/p3"
check_eq "P3 an ok:-labelled green pairs, and its absence is flagged" "1" "$CODE"
py_assert "P3b the ok:-paired id is clean and only the orphan is reported" "
ids = [x['case_id'] for x in v]
assert ids == ['ok-orphan-02'], ids
"

# --- N1: a paired direct literal is clean ----------------------------------
mkdir -p "$WORK/n1/tests"
cat > "$WORK/n1/tests/paired.sh" <<'CLEANF'
#!/usr/bin/env bash
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }
if [ -d / ]; then
  green "PASS: paired-01 the subject is present"
else
  red "FAIL: paired-01 the subject is missing"
fi
CLEANF
run_guard "$WORK/n1"
check_eq "N1 a paired direct literal is clean" "0" "$CODE"

# --- N2: a loop-scoped pair carrying the same interpolated id is clean ------
# The AC's named negative shape: both arms interpolate one discriminator, so
# they pair on source spelling and the loop is correct as written.
mkdir -p "$WORK/n2/tests"
cat > "$WORK/n2/tests/loop.sh" <<'CLEANF'
#!/usr/bin/env bash
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }
for f in a b c; do
  fslug="$f"
  if [ -n "$f" ]; then
    green "PASS: loop-10-$fslug $f relocated"
  else
    red "FAIL: loop-10-$fslug $f not relocated"
  fi
done
CLEANF
run_guard "$WORK/n2"
check_eq "N2 a loop-scoped pair with one interpolated id is clean" "0" "$CODE"

# --- N3: a PAIRED helper leaves its call sites clean ------------------------
# `check`-style helpers carry both labels in one body, so a call site is
# self-pairing and contributes no emission. This suite relies on that property
# for its own ids, so a regression here would make the suite flag itself.
mkdir -p "$WORK/n3/tests"
cat > "$WORK/n3/tests/paired_helper.sh" <<'CLEANF'
#!/usr/bin/env bash
check() {
  if [ "$2" -eq 0 ]; then
    printf '%s\n' "PASS: $1"
  else
    printf '%s\n' "FAIL: $1"
  fi
}
check "ph-01 first assertion" 0
check "ph-02 second assertion" 0
CLEANF
run_guard "$WORK/n3"
check_eq "N3 a paired helper leaves its call sites clean" "0" "$CODE"

# --- N4: an unknown out-of-glob helper call is not an emission --------------
# The stated recall floor. `tests/fixtures/*.sh` is one path segment too deep
# for the globs, so a helper defined there is an unknown call, not an emitter.
mkdir -p "$WORK/n4/tests/fixtures"
cat > "$WORK/n4/tests/fixtures/helpers.sh" <<'CLEANF'
#!/usr/bin/env bash
assert_thing() { printf '%s\n' "FAIL: $1"; }
CLEANF
cat > "$WORK/n4/tests/uses_helper.sh" <<'CLEANF'
#!/usr/bin/env bash
. "$(dirname "$0")/fixtures/helpers.sh"
assert_thing "outside-01 this helper is not visible to the guard"
CLEANF
run_guard "$WORK/n4"
check_eq "N4 an out-of-glob helper call is not read as an emission" "0" "$CODE"

# --- N5: an id that is entirely an expansion is skipped ---------------------
# A trailing rollup line (`FAIL: $failures suite(s) failed.`) can never be a
# --case target, so it is outside the guard's remit. This is what keeps those
# 18 tree-wide rollups clean without any rule about id vocabulary.
mk_clean_suite "$WORK/n5/tests/clean.sh"
cat > "$WORK/n5/tests/rollup.sh" <<'CLEANF'
#!/usr/bin/env bash
failures=3
printf '%s\n' "FAIL: $failures rollup test(s) failed."
CLEANF
run_guard "$WORK/n5"
check_eq "N5 an id that is entirely an expansion is skipped" "0" "$CODE"

# --- E1 / E2: the exemption keys on SCOPE, not on abort ---------------------
# E1 and E2 are the discriminating PAIR. A guard that exempted every aborting
# fail-only arm would pass E1 and fail E2; one with no exemption at all would
# pass E2 and fail E1. Neither alone constrains the rule.
mk_clean_suite "$WORK/e1/tests/clean.sh"
cat > "$WORK/e1/tests/preflight.sh" <<'CLEANF'
#!/usr/bin/env bash
red() { printf '%s\n' "$1"; }
SCRIPT=/nonexistent
if [ ! -f "$SCRIPT" ]; then
  red "FAIL: pre-00-script-present script not found at $SCRIPT"
  exit 1
fi
CLEANF
run_guard "$WORK/e1"
check_eq "E1 a script-scope aborting preflight is exempt" "0" "$CODE"
py_assert "E1b the exemption is counted rather than silently dropped" "
assert s['script_scope_aborts_exempt'] >= 1, s
"

mk_clean_suite "$WORK/e2/tests/clean.sh"
cat > "$WORK/e2/tests/inloop.sh" <<'CLEANF'
#!/usr/bin/env bash
red() { printf '%s\n' "$1"; }
for f in one two three; do
  if [ ! -f "/nonexistent/$f" ]; then
    red "FAIL: klib-like-01-$f $f not found"
    exit 1
  fi
done
CLEANF
run_guard "$WORK/e2"
check_eq "E2 the same aborting shape inside a loop is flagged" "1" "$CODE"
py_assert "E2b it is attributed to the loop-scope arm" "
assert v[0]['arm'] == 'unpaired_abort_in_loop', v[0]['arm']
"

# --- E3: scope reads EVERY function span, not just the emitter map ---------
# Regression guard. The scope test once keyed on the emitter map, which only
# holds functions that spell a label inline — so an aborting fail-only arm in a
# function using the indirect `fail <id> "..."` shape read as script scope and
# was exempted, while the byte-equivalent arm in a function that inlined its
# label was flagged. Both must be findings.
mk_clean_suite "$WORK/e3/tests/clean.sh"
cat > "$WORK/e3/tests/infunc.sh" <<'DIRTY'
#!/usr/bin/env bash
failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }
t_indirect() {
  if [ ! -f /nonexistent ]; then
    fail zz-01 "indirect helper shape, aborting inside a function"
    exit 1
  fi
}
t_literal() {
  if [ ! -f /nonexistent ]; then
    printf '%s\n' "FAIL: zz-02 inline label, aborting inside a function"
    exit 1
  fi
}
DIRTY
run_guard "$WORK/e3"
check_eq "E3 an aborting fail-only arm inside a function is flagged" "1" "$CODE"
py_assert "E3b both the indirect and the inline shape are flagged alike" "
ids = sorted(x['case_id'] for x in v)
assert ids == ['zz-01', 'zz-02'], ids
assert {x['arm'] for x in v} == {'unpaired_abort_in_loop'}, v
"

# --- W1: the AC's own witness — the pre-#1582 klib-01 shape ----------------
# Resolved from the real blob when git can reach it; otherwise from a verbatim
# transcription of the same span. CI checks out shallow, so `git show` on a
# commit that old is routinely unreachable there — and a case that silently
# skipped in CI would be a case that never ran where it matters most. Both
# paths assert the same property, so the case always emits.
#   Provenance: git show e79c4163:cogni-knowledge/tests/test_knowledge_lib.sh
#   (lines 31-36 of that blob)
mk_clean_suite "$WORK/w1/tests/clean.sh"
W1_SRC="transcription"
if git -C "$REPO_ROOT" cat-file -e e79c4163 2>/dev/null && \
   git -C "$REPO_ROOT" show e79c4163:cogni-knowledge/tests/test_knowledge_lib.sh \
     > "$WORK/w1/tests/knowledge_lib.sh" 2>/dev/null; then
  W1_SRC="blob"
else
  cat > "$WORK/w1/tests/knowledge_lib.sh" <<'CLEANF'
#!/usr/bin/env bash
red() { printf '%s\n' "$1"; }
case_slug() { printf '%s' "${1%.py}"; }
SCRIPTS_DIR=/nonexistent
for f in _knowledge_lib.py candidate-store.py fetch-cache.py; do
  if [ ! -f "$SCRIPTS_DIR/$f" ]; then
    red "FAIL: klib-01-$(case_slug "$f") $f not found at $SCRIPTS_DIR/$f"
    exit 1
  fi
done
CLEANF
fi
run_guard "$WORK/w1"
check_eq "W1 the pre-fix klib-01 shape is flagged (source: $W1_SRC)" "1" "$CODE"
py_assert "W1b the finding carries the klib-01 id stem" "
ids = [x['case_id'] for x in v]
assert any(i.startswith('klib-01') for i in ids), ids
"

# --- W2: the AC's own negative — the real migrate_layout suite -------------
mkdir -p "$WORK/w2/tests"
cp "$REPO_ROOT/cogni-knowledge/tests/test_migrate_layout.sh" "$WORK/w2/tests/"
run_guard "$WORK/w2"
py_assert "W2 the real test_migrate_layout.sh reports no migrate-layout-10 finding" "
ids = [x['case_id'] for x in v]
assert not [i for i in ids if i.startswith('migrate-layout-10')], ids
"

# --- S1 / S2: discovery is the two globs, and nothing deeper ---------------
mkdir -p "$WORK/s1/tests" "$WORK/s1/plug/tests"
mk_clean_suite "$WORK/s1/tests/test_underscore.sh"
mk_clean_suite "$WORK/s1/plug/tests/test-hyphen.sh"
run_guard "$WORK/s1"
py_assert "S1 both globs and both namings are discovered" "
assert s['files_discovered'] == 2, s['files_discovered']
"

mkdir -p "$WORK/s2/tests" "$WORK/s2/a/b/tests"
mk_clean_suite "$WORK/s2/tests/in_scope.sh"
cat > "$WORK/s2/a/b/tests/too_deep.sh" <<'DIRTY'
#!/usr/bin/env bash
red() { printf '%s\n' "$1"; }
red "FAIL: too-deep-01 this suite is out of reach by glob shape"
DIRTY
run_guard "$WORK/s2"
check_eq "S2 a suite one segment deeper is unreachable by glob shape" "0" "$CODE"
py_assert "S2b only the in-scope suite was discovered" "
assert s['files_discovered'] == 1, s['files_discovered']
"

# --- Z1: zero discovery is a failure, never a silent clean pass ------------
mkdir -p "$WORK/z1"
run_guard "$WORK/z1"
check_eq "Z1 an empty tree exits 2" "2" "$CODE"
py_assert "Z1b the empty sweep reports success:false with a reason" "
assert d['success'] is False, d
assert d['error'], d
"

# --- C1: every known false-positive shape stays clean in one fixture -------
# Each line here is transcribed from a shape that ships in the tree today. They
# are all in-scope files the guard must leave alone by RULE, never by exclusion.
mk_clean_suite "$WORK/c1/tests/clean.sh"
cat > "$WORK/c1/tests/hazards.sh" <<'DIRTY'
#!/usr/bin/env bash
# A comment naming FAIL: commented-01 must not read as an emission.
failures=0
red() { printf '%s\n' "$1"; }
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }
mutant_out="$(printf '%s\n' 'nothing')"
printf '%s\n' "$mutant_out" | grep -q '^FAIL: greped-01 ' || true
EXPECTED='FAIL: literal-01 an expected-value literal'
case "$mutant_out" in
  "FAIL: casearm-01"*) : ;;
  *) : ;;
esac
bash -c '. /dev/null; printf "%s\n" "FAIL: payload-01 inside a single-quoted payload"' || true
fail "M1 mutant run did not print the expected 'FAIL: prose-01 ...' line"
pass "M1 mutant run did not print the expected line"
printf '%s\n' "FAIL: $failures hazard test(s) failed."
DIRTY
run_guard "$WORK/c1"
check_eq "C1 every known false-positive shape stays clean" "0" "$CODE"

# --- R1 / L1 / L2 / L3: the real tree, and the liveness floors -------------
# The floors are inequalities on purpose. An exact count would turn every
# future suite into a false failure. They sit on counters the guard advances
# BEFORE any arm condition, so a guard that silently stopped extracting ids
# cannot ship green by finding nothing.
run_guard "$REPO_ROOT"
check_eq "R1 the repository as it stands is clean" "0" "$CODE"
py_assert "L1 discovery is still reaching suites" "
assert s['files_scanned'] >= 80, s['files_scanned']
"
py_assert "L2 emitter classification is still resolving helpers" "
assert s['emitters_classified'] >= 40, s['emitters_classified']
"
py_assert "L3 emissions are still being extracted" "
assert s['emissions_inspected'] >= 800, s['emissions_inspected']
"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All case-id pairing guard tests passed."
  exit 0
else
  red "Some case-id pairing guard tests failed."
  exit 1
fi
