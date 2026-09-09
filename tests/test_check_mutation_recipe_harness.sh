#!/usr/bin/env bash
# Behavioral suite for scripts/check-mutation-recipe-harness.py.
#
# Mutation recipe:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file scripts/check-mutation-recipe-harness.py \
#     --expr 's#~/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check\.sh#join(q{/}, q{~/.claude/plugins/cache/managed-service/cogni-service}, join(q{.}, 0, 0, 383), q{scripts/mutation-check.sh})#e' \
#     --test 'bash tests/test_check_mutation_recipe_harness.sh' \
#     --case P1

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-mutation-recipe-harness.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

FAILED=0
CODE=0
OUT="$WORK/out.json"

check() {
  if [ "$2" -eq 0 ]; then
    printf '%s\n' "PASS: $1"
  else
    printf '%s\n' "FAIL: $1"
    FAILED=1
  fi
}

check_eq() {
  if [ "$2" = "$3" ]; then check "$1" 0; else check "$1" 1; fi
}

run_guard() {
  set +e
  python3 "$GUARD" --root "$1" > "$OUT" 2>/dev/null
  CODE=$?
  set -e
}

json_assert() {
  set +e
  OUT_PATH="$OUT" python3 -c "
import json, os
d = json.load(open(os.environ['OUT_PATH']))
$2
"
  rc=$?
  set -e
  check "$1" "$rc"
}

write_suite() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' '#!/usr/bin/env bash' "$2" > "$1"
}

# P1: the version-pinned cache form is rejected and named. Build the fixture
# from two literals so the suite itself does not retain the forbidden spelling.
PINNED_PREFIX='# bash ~/.claude/plugins/cache/managed-service/cogni-service/'
write_suite "$WORK/p1/tests/pinned.sh" "${PINNED_PREFIX}0.0.383/scripts/mutation-check.sh --root . --file x --expr x --test x --case P1"
run_guard "$WORK/p1"
check_eq "P1 pinned cache harness is rejected" 1 "$CODE"
json_assert "P1b pinned finding names its file and arm" "
v = d['data']['violations']
assert len(v) == 1, v
assert v[0]['file'] == 'tests/pinned.sh', v
assert v[0]['line'] == 2, v
assert v[0]['arm'] == 'unapproved_harness', v
"

# P2: the repo-root-relative spelling is rejected.
write_suite "$WORK/p2/tests/bare.sh" '# scripts/mutation-check.sh --root . --file x --expr x --test x --case P2'
run_guard "$WORK/p2"
check_eq "P2 bare repo-root harness is rejected" 1 "$CODE"
json_assert "P2b bare finding names its file, line, and harness" "
v = d['data']['violations']
assert len(v) == 1, v
assert v[0]['file'] == 'tests/bare.sh', v
assert v[0]['line'] == 2, v
assert v[0]['harness'] == 'scripts/mutation-check.sh', v
"

# N1: both approved live spellings are accepted.
write_suite "$WORK/n1/tests/approved.sh" '# bash ~/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh --root . --file x --expr x --test x --case N1
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file x --expr x --test x --case N1b'
run_guard "$WORK/n1"
check_eq "N1 both approved marketplace spellings are clean" 0 "$CODE"

# N2: prose mentions are ignored without an allowlist.
write_suite "$WORK/n2/tests/prose.sh" '# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file x --expr x --test x --case N2
# Use the plugin-local scripts/mutation-check.sh rather than the shared harness.
# mutation-check.sh --case <id> addresses exactly one assertion.'
run_guard "$WORK/n2"
check_eq "N2 prose mentions do not become invocations" 0 "$CODE"
json_assert "N2b only the approved invocation is inspected" "
assert d['data']['summary']['invocations_inspected'] == 1
"

# M1: flags on backslash-continued comment lines make an invocation observable.
mkdir -p "$WORK/m1/tests"
cat > "$WORK/m1/tests/multiline.sh" <<'FIXTURE'
#!/usr/bin/env bash
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#   --root . --file x --expr x --test x --case M1
FIXTURE
run_guard "$WORK/m1"
check_eq "M1 multiline approved invocation is clean" 0 "$CODE"
json_assert "M1b multiline invocation advances liveness" "
assert d['data']['summary']['invocations_inspected'] == 1
"

# Z1: an empty tree cannot report clean.
mkdir -p "$WORK/z1"
run_guard "$WORK/z1"
check_eq "Z1 zero suite discovery is an error" 2 "$CODE"
json_assert "Z1b discovery error is explicit" "
assert d['success'] is False
assert 'no test suites discovered' in d['error']
"

# Z2: suites with no recipe population cannot report clean either.
write_suite "$WORK/z2/tests/empty-population.sh" 'printf "%s\n" "no recipe here"'
run_guard "$WORK/z2"
check_eq "Z2 zero invocation discovery is an error" 2 "$CODE"
json_assert "Z2b predicate-liveness error is explicit" "
assert 'no mutation-recipe invocations discovered' in d['error']
"

# R1/L1: the real tree is clean and both liveness counters are non-zero.
run_guard "$REPO_ROOT"
check_eq "R1 repository recipe population is clean" 0 "$CODE"
json_assert "L1 real-tree discovery and invocation counters are live" "
s = d['data']['summary']
assert s['files_discovered'] > 0, s
assert s['files_scanned'] == s['files_discovered'], s
assert s['invocations_inspected'] > 0, s
assert s['total'] == 0, s
"

exit "$FAILED"
