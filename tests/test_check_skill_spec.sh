#!/usr/bin/env bash
# test_check_skill_spec.sh -- suite for the skill-spec guard.
#
# Case labels are `<id> <description>` -- an id token followed by a SPACE, never
# a colon abutting the id. A mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` whole-token, so a
# trailing colon would match neither arm and report case_not_found.
#
# FIXTURE TREES, NOT THE LIVE REPO, except the live-tree case which grades the
# shipped tree on purpose. The guard takes `--root` and `--baseline`, so every
# fixture is a throwaway tree the SHIPPED script is pointed at -- never a copy.
#
# ZERO DISCOVERY IS EXIT 2. Any fixture meant to grade exit 0 or 1 must hold at
# least one plugin root with at least one skills/<name>/SKILL.md.
#
# THE GUARD'S STDERR IS NEVER REPLAYED VERBATIM. Its finding lines begin with
# `FAIL: [name]`, which matches the harness's result-line shape while carrying
# no case id. The live-tree case prefixes them.
#
# FOREIGN OUTPUT BY SHAPE. Assertions are on the guard's own emitted text and on
# exit status. Nothing here greps a bash or coreutils diagnostic.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/../scripts/check-skill-spec.py"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

OUT="$WORK/out.json"
ERR="$WORK/out.err"
EMPTY_BASELINE="$WORK/empty-baseline.json"
printf '{"entries": []}\n' > "$EMPTY_BASELINE"

new_tree() {
  local t="$WORK/$1"
  mkdir -p "$t"
  printf '%s' "$t"
}

add_plugin() {
  mkdir -p "$1/$2/.claude-plugin"
  printf '{"name":"%s","version":"0.1.0"}\n' "$2" > "$1/$2/.claude-plugin/plugin.json"
}

# add_skill <tree> <plugin> <dir> [name] -- a well-formed skill; name defaults to dir.
add_skill() {
  local name="${4:-$3}"
  mkdir -p "$1/$2/skills/$3"
  cat > "$1/$2/skills/$3/SKILL.md" <<SKILL
---
name: $name
description: Grades a fixture. Use when the suite needs a compliant skill.
---

# Fixture

Body.
SKILL
}

# run_guard <tree> [baseline]
run_guard() {
  python3 "$GUARD" --root "$1" --baseline "${2:-$EMPTY_BASELINE}" > "$OUT" 2>"$ERR"
}

# assert_case <id> <expected_rc> <needle_or_-> <tree> <baseline_or_-> <desc>
assert_case() {
  local id="$1" want="$2" needle="$3" tree="$4" base="$5" desc="$6"
  local label="$id $desc"
  if [ "$base" = "-" ]; then run_guard "$tree"; else run_guard "$tree" "$base"; fi
  local rc=$?
  if [ "$rc" -ne "$want" ]; then
    fail "$label -- expected exit $want, got $rc"
    return
  fi
  if [ "$needle" != "-" ] && ! grep -qF "$needle" "$ERR"; then
    fail "$label -- exit $want but stderr lacks '$needle'"
    return
  fi
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$OUT" 2>/dev/null; then
    fail "$label -- exit $want but stdout is not the JSON envelope every script owes"
    return
  fi
  pass "$label"
}

# --- 01  a clean tree is green ------------------------------------------------
T="$(new_tree clean)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
assert_case "skill-spec-01-clean" 0 - "$T" - \
  "compliant frontmatter, short body, no resources passes"

# --- 02  name does not equal the directory ------------------------------------
T="$(new_tree namedir)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill other-name
assert_case "skill-spec-02-name-dir-mismatch" 1 "[name]" "$T" - \
  "name: differing from the directory is reported"

# --- 03  name breaks the spec form --------------------------------------------
T="$(new_tree nameform)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/Bad_Name"
add_skill "$T" cogni-alpha Bad_Name Bad_Name
assert_case "skill-spec-03-name-form" 1 "[name]" "$T" - \
  "uppercase and underscore in name: are reported"

# --- 04  description over 1024 characters after folding -----------------------
T="$(new_tree longdesc)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/wordy"
{
  printf -- '---\nname: wordy\ndescription: >-\n'
  for _ in $(seq 1 60); do printf '  twenty characters.\n'; done
  printf -- '---\n\n# Wordy\n\nBody.\n'
} > "$T/cogni-alpha/skills/wordy/SKILL.md"
assert_case "skill-spec-04-description-over-cap" 1 "[description]" "$T" - \
  "a folded description over 1024 characters is reported"

# --- 05  description measured AFTER folding, not on the raw block -------------
# Each fixture line is `  twenty characters.\n` = 21 bytes raw, 18 characters
# once the indent and newline fold away. The line count must put the RAW block
# over the cap and the FOLDED value under it, or the case is entailed by 01 and
# discriminates nothing: 52 lines is raw 52*21 = 1092 (over) against folded
# 52*18 + 51 joining spaces = 987 (under). Any n in [49, 53] works; 48 does not
# (raw 1008, folded 911 -- both under, so a guard grading the raw region would
# still pass). A guard measuring anything but the folded scalar goes red here.
T="$(new_tree folded)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/folded"
{
  printf -- '---\nname: folded\ndescription: >-\n'
  for _ in $(seq 1 52); do printf '  twenty characters.\n'; done
  printf -- '---\n\n# Folded\n\nBody.\n'
} > "$T/cogni-alpha/skills/folded/SKILL.md"
assert_case "skill-spec-05-description-folded-measure" 0 - "$T" - \
  "a description whose raw block exceeds 1024 but folds under it passes"

# --- 06  description missing --------------------------------------------------
T="$(new_tree nodesc)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/mute"
printf -- '---\nname: mute\n---\n\n# Mute\n\nBody.\n' > "$T/cogni-alpha/skills/mute/SKILL.md"
assert_case "skill-spec-06-description-missing" 1 "[description]" "$T" - \
  "a skill without description: is reported"

# --- 07  a frontmatter key at column 0 of the BODY does not satisfy the rule ---
T="$(new_tree bodykey)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/prose"
printf -- '---\nname: prose\n---\n\nThe second key looks like this:\n\ndescription: not frontmatter.\n' \
  > "$T/cogni-alpha/skills/prose/SKILL.md"
assert_case "skill-spec-07-body-key-not-counted" 1 "[description]" "$T" - \
  "description: in the body does not satisfy the frontmatter requirement"

# --- 08  501 lines is over the ceiling ----------------------------------------
T="$(new_tree long)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/long"
{
  printf -- '---\nname: long\ndescription: Long fixture. Use when grading the ceiling.\n---\n'
  for _ in $(seq 1 497); do printf 'line\n'; done
} > "$T/cogni-alpha/skills/long/SKILL.md"
assert_case "skill-spec-08-over-500-lines" 1 "[length]" "$T" - \
  "a 501-line SKILL.md is reported"

# --- 09  exactly 500 lines is within the ceiling ------------------------------
T="$(new_tree exact)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/exact"
{
  printf -- '---\nname: exact\ndescription: Exact fixture. Use when grading the ceiling.\n---\n'
  for _ in $(seq 1 496); do printf 'line\n'; done
} > "$T/cogni-alpha/skills/exact/SKILL.md"
assert_case "skill-spec-09-exactly-500-lines" 0 - "$T" - \
  "a 500-line SKILL.md passes"

# --- 10  a README.md inside the skill directory -------------------------------
T="$(new_tree readme)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
printf '# parallel spec\n' > "$T/cogni-alpha/skills/good-skill/README.md"
assert_case "skill-spec-10-stray-readme" 1 "[stray-file]" "$T" - \
  "a README.md at the skill root is reported"

# --- 11  a directory nested inside references/ --------------------------------
T="$(new_tree deep)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
mkdir -p "$T/cogni-alpha/skills/good-skill/references/print"
printf 'deep\n' > "$T/cogni-alpha/skills/good-skill/references/print/rules.md"
printf '\nSee `references/print/rules.md`.\n' >> "$T/cogni-alpha/skills/good-skill/SKILL.md"
assert_case "skill-spec-11-reference-depth" 1 "[reference-depth]" "$T" - \
  "a directory nested inside references/ is reported"

# --- 12  a resource file SKILL.md never names ---------------------------------
T="$(new_tree orphan)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
mkdir -p "$T/cogni-alpha/skills/good-skill/references"
printf 'orphan\n' > "$T/cogni-alpha/skills/good-skill/references/orphan.md"
assert_case "skill-spec-12-unreferenced-resource" 1 "[unreferenced-resource]" "$T" - \
  "a references/ file never mentioned in SKILL.md is reported"

# --- 13  a resource named by basename alone is referenced ---------------------
T="$(new_tree basename)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
mkdir -p "$T/cogni-alpha/skills/good-skill/references"
printf 'named\n' > "$T/cogni-alpha/skills/good-skill/references/named.md"
printf '\n| **named.md** | 2 | rules |\n' >> "$T/cogni-alpha/skills/good-skill/SKILL.md"
assert_case "skill-spec-13-basename-counts-as-reference" 0 - "$T" - \
  "a resource cited by bare basename in a table passes"

# --- 13a a directly linked reference index exposes one sibling resource -------
T="$(new_tree linkedindex)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
mkdir -p "$T/cogni-alpha/skills/good-skill/references"
printf 'Route through `routed.md`.\n' > "$T/cogni-alpha/skills/good-skill/references/00-index.md"
printf 'routed\n' > "$T/cogni-alpha/skills/good-skill/references/routed.md"
printf '\nREAD: `references/00-index.md`.\n' >> "$T/cogni-alpha/skills/good-skill/SKILL.md"
assert_case "skill-spec-13a-linked-index-reaches-resource" 0 - "$T" - \
  "a resource named by a directly linked references index passes"

# --- 13b an unlinked reference index cannot launder a sibling resource --------
T="$(new_tree unlinkedindex)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
mkdir -p "$T/cogni-alpha/skills/good-skill/references"
printf 'Route through `laundered.md`.\n' > "$T/cogni-alpha/skills/good-skill/references/00-index.md"
printf 'laundered\n' > "$T/cogni-alpha/skills/good-skill/references/laundered.md"
run_guard "$T"
rc=$?
if [ "$rc" -eq 1 ] && python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
want = ('unreferenced-resource', 'cogni-alpha/skills/good-skill/references/laundered.md')
got = {(f.get('arm'), f.get('file')) for f in d['data']['findings']}
assert want in got, (want, sorted(got))
" "$OUT" 2>/dev/null; then
  pass "skill-spec-13b-unlinked-index-cannot-launder a resource named only by an unlinked index is still reported"
else
  fail "skill-spec-13b-unlinked-index-cannot-launder the finding must name both the unreferenced-resource arm and laundered sibling path"
fi

# --- 14  a baselined ratchet finding is suppressed ----------------------------
T="$(new_tree baselined)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
printf '# parallel spec\n' > "$T/cogni-alpha/skills/good-skill/README.md"
B="$WORK/baseline-14.json"
printf '{"entries":[{"skill":"good-skill","arm":"stray-file","file":"cogni-alpha/skills/good-skill/README.md"}]}\n' > "$B"
assert_case "skill-spec-14-baseline-suppresses" 0 - "$T" "$B" \
  "a stray-file finding admitted by the baseline passes"

# --- 15  a stale baseline entry is itself a violation -------------------------
T="$(new_tree stale)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
B="$WORK/baseline-15.json"
printf '{"entries":[{"skill":"good-skill","arm":"stray-file","file":"cogni-alpha/skills/good-skill/README.md"}]}\n' > "$B"
assert_case "skill-spec-15-stale-baseline" 1 "[stale-baseline]" "$T" "$B" \
  "a baseline entry matching no live finding is reported"

# --- 16  a hard arm cannot be baselined ---------------------------------------
T="$(new_tree hardarm)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill other-name
B="$WORK/baseline-16.json"
printf '{"entries":[{"skill":"good-skill","arm":"name","file":"cogni-alpha/skills/good-skill/SKILL.md"}]}\n' > "$B"
assert_case "skill-spec-16-hard-arm-not-baselinable" 1 "[name]" "$T" "$B" \
  "a name finding is reported even when the baseline names it"

# --- 17  zero discovery: no plugin roots --------------------------------------
T="$(new_tree noplugins)"
assert_case "skill-spec-17-zero-plugins" 2 "zero discovery" "$T" - \
  "a tree with no plugin roots exits 2 rather than reporting clean"

# --- 18  zero discovery: plugins without skills -------------------------------
T="$(new_tree noskills)"
add_plugin "$T" cogni-alpha
assert_case "skill-spec-18-zero-skills" 2 "zero discovery" "$T" - \
  "plugins holding no SKILL.md exit 2, not 0"

# --- 19  a quoted multi-line description is resolved across both lines --------
# The first line alone is 620 characters (under the cap); with the continuation
# it is 1241 (over). So the case is red only if the guard actually consumes the
# continuation line -- a resolver that stops at the first line measures 620,
# the orphaned continuation carries no `key:` and cannot re-match FM_KEY, and
# the guard would exit 0. Asserting exit 1 is what makes the case discriminate.
T="$(new_tree quoted)"
add_plugin "$T" cogni-alpha
mkdir -p "$T/cogni-alpha/skills/quoted"
{
  printf -- '---\nname: quoted\ndescription: "Grades a fixture with a \\"quoted\\" scalar'
  for _ in $(seq 1 29); do printf ' twenty characters.'; done
  printf -- '\n  and a continuation line'
  for _ in $(seq 1 30); do printf ' twenty characters.'; done
  printf -- '"\n---\n\nBody.\n'
} > "$T/cogni-alpha/skills/quoted/SKILL.md"
assert_case "skill-spec-19-quoted-description" 1 "[description]" "$T" - \
  "a double-quoted description spanning two lines is measured across both, not just the first"

# --- 20  the live repo is clean against the shipped baseline ------------------
# Deliberately grades the LIVE tree, so a real skill-spec violation reds two CI
# jobs: the dedicated skill-spec job (correctly labelled) and the plugin-test
# sweep that discovers this suite. The duplicate report is accepted on purpose:
# the fixture cases above prove the guard discriminates, and this one proves the
# shipped baseline still matches the tree it was captured from -- the property a
# fixture cannot carry. workflow-guard.yml accepts the same tradeoff.
python3 "$GUARD" --root "$REPO_ROOT" > "$OUT" 2>"$ERR"
if [ $? -eq 0 ]; then
  pass "skill-spec-20-live-tree-clean the repository passes its own guard against the shipped baseline"
else
  fail "skill-spec-20-live-tree-clean the repository passes its own guard against the shipped baseline"
  sed 's/^/    live-tree| /' "$ERR" >&2
fi

# --- 21  the JSON envelope is the shape every script in this repo owes --------
T="$(new_tree envelope)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
run_guard "$T"
if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert set(d) == {'success', 'data', 'error'}, sorted(d)
assert d['success'] is True and d['error'] == ''
s = d['data']['summary']
for k in ('total', 'plugins_discovered', 'skills_scanned', 'baseline_size', 'suppressed_by_baseline'):
    assert isinstance(s[k], int), k
assert s['skills_scanned'] == 1, s['skills_scanned']
" "$OUT" 2>/dev/null; then
  pass "skill-spec-21-envelope-shape the JSON envelope carries success, data and error"
else
  fail "skill-spec-21-envelope-shape the JSON envelope carries success, data and error"
fi

# --- 22  findings carry their structured diagnostic fields --------------------
T="$(new_tree findingdetail)"
add_plugin "$T" cogni-alpha
add_skill "$T" cogni-alpha good-skill
mkdir -p "$T/cogni-alpha/skills/good-skill/references"
printf 'orphan\n' > "$T/cogni-alpha/skills/good-skill/references/orphan.md"
run_guard "$T"
rc=$?
if [ "$rc" -eq 1 ] && python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
assert d['success'] is False and d['error'] == ''
findings = d['data']['findings']
assert len(findings) == 1, findings
finding = findings[0]
assert finding['arm'] == 'unreferenced-resource', finding
assert finding['file'] == 'cogni-alpha/skills/good-skill/references/orphan.md', finding
assert isinstance(finding['detail'], str) and finding['detail'].strip(), finding
" "$OUT" 2>/dev/null; then
  pass "skill-spec-22-finding-detail-shape a finding names its arm, file and non-empty detail"
else
  fail "skill-spec-22-finding-detail-shape a finding names its arm, file and non-empty detail"
fi

printf '%s\n' "---"
if [ "$FAILURES" -eq 0 ]; then
  printf '%s\n' "All cases passed."
  exit 0
fi
printf '%s\n' "$FAILURES case(s) failed."
exit 1
