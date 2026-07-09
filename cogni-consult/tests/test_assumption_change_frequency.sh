#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/assumption-change-frequency.sh —
# the retrospective git-history numeric-literal change-frequency spike.
#
# Unlike the JSON-fixture tests, these fixtures build a real throwaway git repo
# under a temp root, commit deliverable markdown across multiple commits, and
# assert on the emitted envelope plus the mined change-frequency figures.
#
# Coverage:
#   1  changed-literal     a literal edited across 3 commits reports edit_count 3
#   2  window              window.start/end span the observed commit dates
#   3  no-registry-dep     runs with no assumptions.json present (AC1)
#   4  frozen-literal      a literal added once and never touched reports edit_count 1
#   5  code-fence-skipped  numbers inside a fenced code block are not counted
#   6  subdir-recursion    nested action-fields/<field>/<deliverable>.md is mined
#   7  frontmatter-skipped a number in the leading YAML frontmatter is not counted
#   8  hr-not-frontmatter  a body `---` horizontal rule does not mask later literals
#   9  empty-corpus        a corpus with no markdown -> success, zero literals
#  10  not-a-git-repo      a non-git dir -> success:false, not_a_git_repo
#  11  missing-corpus      a non-existent path -> success:false, corpus_missing
#
# Usage: bash cogni-consult/tests/test_assumption_change_frequency.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/assumption-change-frequency.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: assumption-change-frequency.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Assert the envelope's success flag and (on failure) failed_check.
# Args: <name> <expected-success> <expected-failed_check-or-empty> <envelope>
assert_envelope() {
  local name="$1" want_success="$2" want_check="$3" envelope="$4"
  echo "$envelope" | ENV_SUCCESS="$want_success" ENV_CHECK="$want_check" python3 -c '
import json, os, sys
d = json.load(sys.stdin)
ok = str(d["success"]).lower() == os.environ["ENV_SUCCESS"]
check = os.environ["ENV_CHECK"]
if check:
    ok = ok and d["data"].get("failed_check") == check
sys.exit(0 if ok else 1)
' && pass "$name" || fail "$name" "envelope mismatch: $envelope"
}

# Assert the edit_count reported for a given literal value.
# Args: <name> <literal-value> <expected-edit-count> <envelope>
assert_edit_count() {
  local name="$1" value="$2" want="$3" envelope="$4"
  echo "$envelope" | LIT_VALUE="$value" LIT_WANT="$want" python3 -c '
import json, os, sys
d = json.load(sys.stdin)
want = int(os.environ["LIT_WANT"])
got = next((l["edit_count"] for l in d["data"]["literals"]
            if l["value"] == os.environ["LIT_VALUE"]), None)
sys.exit(0 if got == want else 1)
' && pass "$name" || fail "$name" "edit_count mismatch for $value: $envelope"
}

git_quiet() { git -C "$1" -c user.email=t@t -c user.name=t -c commit.gpgsign=false "${@:2}" >/dev/null 2>&1; }

# --- Shared multi-commit corpus (fixtures 1-6) ------------------------------
REPO="$TMPROOT/repo"
mkdir -p "$REPO/action-fields/market"
git -C "$REPO" init -q
BRIEF="$REPO/action-fields/market/sizing.md"

# The frozen note lives on its own line so line-granular diffing isolates it
# from the changing TAM line (co-located literals would otherwise share edit
# attribution — a documented spike imprecision).
printf 'TAM is 4.2bn EUR this year.\nA frozen note: 99 units.\n' > "$BRIEF"
git_quiet "$REPO" add -A && git_quiet "$REPO" commit -m c1
printf 'TAM is 4.5bn EUR this year.\nA frozen note: 99 units.\n' > "$BRIEF"
git_quiet "$REPO" add -A && git_quiet "$REPO" commit -m c2
printf 'TAM is 4.9bn EUR this year.\nA frozen note: 99 units.\n' > "$BRIEF"
git_quiet "$REPO" add -A && git_quiet "$REPO" commit -m c3

OUT=$(bash "$SCRIPT" "$REPO")
assert_envelope "changed-literal envelope" true "" "$OUT"
# 4.2bn added in c1, removed in c2 -> 2 edit events; 4.5bn added c2 removed c3
# -> 2; 4.9bn added c3 -> 1. The frozen "99" (own line) was added once in c1
# and never touched again -> 1. The trailing unit stays attached ("4.2bn").
assert_edit_count "changed-literal 4.2bn" "4.2bn" 2 "$OUT"
assert_edit_count "frozen-literal 99" "99" 1 "$OUT"

# 2 window spans the commit dates
echo "$OUT" | python3 -c '
import json, sys
w = json.load(sys.stdin)["data"]["window"]
sys.exit(0 if w["start"] and w["end"] and w["start"] <= w["end"] else 1)
' && pass "window populated" || fail "window populated" "$OUT"

# 3 no-registry-dep: the corpus has no assumptions.json at all
[ ! -f "$REPO/assumptions.json" ] && pass "no-registry-dep (no assumptions.json)" \
  || fail "no-registry-dep" "unexpected assumptions.json present"

# 5 code-fence-skipped: a number only inside a fenced block must not be counted
FENCED="$REPO/action-fields/market/fenced.md"
printf 'prose has 7 items.\n\n```\ncode has 123456 here\n```\n' > "$FENCED"
git_quiet "$REPO" add -A && git_quiet "$REPO" commit -m fence
OUT2=$(bash "$SCRIPT" "$REPO")
echo "$OUT2" | python3 -c '
import json, sys
lits = {l["value"] for l in json.load(sys.stdin)["data"]["literals"]}
# 7 (prose) must be present; 123456 (inside the code fence) must be absent.
sys.exit(0 if "7" in lits and "123456" not in lits else 1)
' && pass "code-fence-skipped" || fail "code-fence-skipped" "$OUT2"

# 6 subdir-recursion: the nested action-fields/market/*.md was mined at all
echo "$OUT2" | python3 -c '
import json, sys
files = {l["file"] for l in json.load(sys.stdin)["data"]["literals"]}
sys.exit(0 if any("sizing.md" in f for f in files) else 1)
' && pass "subdir-recursion" || fail "subdir-recursion" "$OUT2"

# --- 7 frontmatter-skipped: number in the leading YAML block is not counted --
# --- 8 hr-not-frontmatter: a body `---` rule must not mask later literals -----
FM="$REPO/action-fields/market/framed.md"
printf -- '---\nweight: 500\n---\n\nGrowth was 12 percent.\n\n---\n\nMargin hit 34 percent.\n' > "$FM"
git_quiet "$REPO" add -A && git_quiet "$REPO" commit -m framed
OUT_FM=$(bash "$SCRIPT" "$REPO")
echo "$OUT_FM" | python3 -c '
import json, sys
lits = {l["value"] for l in json.load(sys.stdin)["data"]["literals"]}
# 500 lives in the leading frontmatter -> must be absent.
sys.exit(0 if "500" not in lits else 1)
' && pass "frontmatter-skipped" || fail "frontmatter-skipped" "$OUT_FM"
echo "$OUT_FM" | python3 -c '
import json, sys
lits = {l["value"] for l in json.load(sys.stdin)["data"]["literals"]}
# 12 (before the body HR) AND 34 (after it) must both be counted — the body
# `---` rule must not flip frontmatter state and hide 34.
sys.exit(0 if "12" in lits and "34" in lits else 1)
' && pass "hr-not-frontmatter" || fail "hr-not-frontmatter" "$OUT_FM"

# --- 9 empty-corpus ---------------------------------------------------------
EMPTY="$TMPROOT/empty"
mkdir -p "$EMPTY"
git -C "$EMPTY" init -q
printf 'not markdown\n' > "$EMPTY/notes.txt"
git_quiet "$EMPTY" add -A && git_quiet "$EMPTY" commit -m only-txt
OUT3=$(bash "$SCRIPT" "$EMPTY")
assert_envelope "empty-corpus envelope" true "" "$OUT3"
echo "$OUT3" | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"]
sys.exit(0 if d["literals_observed"] == 0 and d["edits_per_literal"] == 0.0 else 1)
' && pass "empty-corpus zeroed" || fail "empty-corpus zeroed" "$OUT3"

# --- 8 not-a-git-repo -------------------------------------------------------
NOGIT="$TMPROOT/nogit"
mkdir -p "$NOGIT"
printf 'TAM 4.2bn\n' > "$NOGIT/brief.md"
OUT4=$(bash "$SCRIPT" "$NOGIT")
assert_envelope "not-a-git-repo envelope" false "not_a_git_repo" "$OUT4"

# --- 9 missing-corpus -------------------------------------------------------
OUT5=$(bash "$SCRIPT" "$TMPROOT/does-not-exist")
assert_envelope "missing-corpus envelope" false "corpus_missing" "$OUT5"

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All assumption-change-frequency assertions passed"
