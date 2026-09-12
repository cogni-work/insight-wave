#!/usr/bin/env bash
# test_check_readme_inventory_sync.sh — self-test for the root-README inventory guard.
#
# The guard binds every per-plugin count claim in the ROOT README — the prose
# sentence, the "Plugins at a glance" table row, and the roll-up total — to
# counts globbed from disk at run time. Cases:
#   1. Consistent fixture -> exit 0, zero violations.
#   2. Prose / table / roll-up mismatches each -> exit 1 with their own code.
#   3. Grammar: the singular "1 skill and 1 agent." parses as a claim. Without
#      this arm a plugin shipping exactly one skill is silently unguarded.
#   4. A claim line that ALSO carries a mid-sentence count phrase yields exactly
#      one claim, taking the sentence-final numbers. The real README has such a
#      line, so a phrase-blind regex would double-match it.
#   5. Scope: a per-plugin README is never opened, and a linked table row
#      OUTSIDE the glance section is not a claim. The second property is why the
#      guard scopes to H2 sections rather than scanning the file.
#   6. Failing loudly: a renamed anchor heading, and a README with no claim at
#      all, both exit non-zero rather than reporting a clean zero.
#   7. Real repo at branch head -> exit 0, and each of the three real claim
#      sites reverted independently -> exit 1.
#   8. The bare plugin-count arm: all three sites discovered on a clean fixture,
#      and each drifting independently reports which one moved. One aggregated
#      case could not tell them apart, which is what the site discriminator is
#      for.
#   9. Both halves of the fence decision. The identical tree line UNFENCED is
#      not the tree claim; a fenced example inside the prose section is not a
#      second intro claim. Drop either filter and one of the two reddens.
#  10. The noun discriminates, not the digit: the same fence carries a guides
#      count and a workflows count, so a loosened `(N <word>)` pattern reddens
#      the clean fixture. Both decoys are now live-bound claims in their own
#      right (family 13) and their counts still differ from the fixture's plugin
#      count, so the property this family grades survives that promotion rather
#      than being absorbed by it.
#  11. The roll-up's own plugin count stays bound exactly once. It matches the
#      bare pattern too and is kept out of reach only by region scoping.
#  12. A prose rename reports a missing claim rather than passing, and a claim
#      whose COUNT is deleted while its version-like qualifier remains reports
#      missing rather than a count of zero — the one shape that grades the bare
#      pattern's negative lookbehind.
#  13. The directory-count arm: each of the two sites drifting independently
#      reports which one moved, a removed claim line reports missing, and the
#      clean fixture discovers both at their live directory counts. Its basis is
#      a docs/ listing, not the plugin universe — a distinction the guides site
#      can only grade on a fixture whose guide count DIFFERS from its plugin
#      count, since the two coincide the moment every plugin has a guide.
#  14. An absent backing directory reports `dir-basis-missing`, not a mismatch
#      against a live count of zero. Without that arm a `(0 guides)` claim
#      passes green against a directory that does not exist.
#
# bash 3.2 + stdlib python3 only. No arguments, no network.
#
# Mutation recipe — replay to confirm the bare arm's comparison has teeth:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-readme-inventory-sync.py \
#     --expr 's/claim\["count"\] != len\(counts\)/False/m' \
#     --test 'bash tests/test_check_readme_inventory_sync.sh' --case ris31
#
# That literal appears exactly once in the guard and is never echoed in its
# docstring, its comments or a detail string — the expression is non-global
# under `perl -0pi`, so an earlier copy would absorb the substitution, leave the
# executable comparison intact, and grade nothing while still reporting a clean
# rewrite.
#
# Mutation recipe — replay to confirm the directory-count arm's comparison has
# teeth:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-readme-inventory-sync.py \
#     --expr 's/claim\["count"\] != live_dir/False/m' \
#     --test 'bash tests/test_check_readme_inventory_sync.sh' --case ris48
#
# Same uniqueness dependency as the recipe above, and verified the same way:
# `claim["count"] != live_dir` appears exactly once in the guard, and the
# mismatch detail interpolates `claim["count"]` and `live_dir` as separate
# .format() arguments rather than echoing that expression.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (risNN), unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. The id is
# followed by a SPACE, never a colon abutting it — the harness matches the
# case whole-token, so a colon-abutting id returns case_not_found. A new
# assertion takes the next free id rather than renumbering its neighbours.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-readme-inventory-sync.py"

# Plain text on purpose — result lines are machine-read; tooling anchors a
# literal PASS:/FAIL: prefix. Emit unconditionally, never probe the environment.
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

assert_json() {  # assert_json <label> <json> <python-asserts>
  set +e
  printf '%s' "$2" | python3 -c "$3"
  local _code=$?
  set -e
  check "$1" "$_code"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# make_plugin <fixture-root> <name> <n-skills> <n-agents>
make_plugin() {
  local root="$1" name="$2" nskills="$3" nagents="$4" i=1
  mkdir -p "$root/$name/.claude-plugin"
  printf '{\n  "name": "%s",\n  "version": "0.0.1"\n}\n' "$name" \
    > "$root/$name/.claude-plugin/plugin.json"
  while [ "$i" -le "$nskills" ]; do
    mkdir -p "$root/$name/skills/skill-$i"
    printf 'skill %s\n' "$i" > "$root/$name/skills/skill-$i/SKILL.md"
    i=$((i + 1))
  done
  i=1
  while [ "$i" -le "$nagents" ]; do
    mkdir -p "$root/$name/agents"
    printf 'agent %s\n' "$i" > "$root/$name/agents/agent-$i.md"
    i=$((i + 1))
  done
}

# make_marketplace <fixture-root> <name>...
make_marketplace() {
  local root="$1"; shift
  mkdir -p "$root/.claude-plugin"
  {
    printf '{\n  "name": "fixture",\n  "plugins": [\n'
    local first=1
    for n in "$@"; do
      [ $first -eq 1 ] || printf ',\n'
      first=0
      printf '    {"name": "%s", "source": "./%s", "version": "0.0.1"}' "$n" "$n"
    done
    printf '\n  ]\n}\n'
  } > "$root/.claude-plugin/marketplace.json"
}

# begin_readme <fixture-root> <nplugins>
#
# Emits the lede region (everything before the first H2) carrying the lede
# plugin-count claim, then the prose heading and the intro plugin-count claim.
# Both are required for a fixture to be a VALID README under the bare-count arm:
# absence of a site is a violation, so a fixture omitting them would report a
# plugin-count-missing rather than the clean run its case asserts. The count is
# passed in rather than defaulted, so each fixture states its own universe size
# and no literal is shared between a fixture's manifest and its README.
begin_readme() {
  {
    printf '# Fixture\n\n'
    printf 'Open-source things. %s Apache-2.0 plugins that automate the work.\n\n' "$2"
    printf '## What the plugins do\n\n'
    printf '%s plugins organized around capability areas.\n\n' "$2"
  } > "$1/README.md"
}

# add_tree <fixture-root> <nplugins> — the fenced tree-diagram region carrying
# the third plugin-count claim site, plus the two same-fence counts whose nouns
# differ. Those two are baked into every green fixture on purpose: they are what
# make those cases assert that the tree pattern discriminates on the noun rather
# than on the digit, so a pattern loosened to `(N <word>)` reddens them instead
# of passing. They are now live-bound claims in their own right, so the helper
# also MATERIALISES the directories they name — a fixture stating a count it
# cannot back is exactly the un-bound claim this guard exists to remove, and
# creating them here keeps the invariant local to the one helper that states it.
# 9 and 5 are chosen to differ from each other and from every call site's plugin
# count (1 or 2), so the noun-discrimination property survives and the guides
# site cannot pass by coincidence against the plugin universe.
add_tree() {
  local i=1
  mkdir -p "$1/docs/plugin-guide" "$1/docs/workflows"
  while [ "$i" -le 9 ]; do
    printf 'guide %s\n' "$i" > "$1/docs/plugin-guide/guide-$i.md"
    i=$((i + 1))
  done
  i=1
  while [ "$i" -le 5 ]; do
    printf 'workflow %s\n' "$i" > "$1/docs/workflows/workflow-$i.md"
    i=$((i + 1))
  done
  {
    printf '## How it works\n\n'
    printf '```\n'
    printf 'fixture/\n'
    printf '|-- .claude-plugin/\n'
    printf '|   `-- marketplace.json   # Marketplace manifest (%s plugins)\n' "$2"
    printf '|-- docs/plugin-guide/     # Deep dives (9 guides)\n'
    printf '|-- docs/workflows/        # Pipeline guides (5 workflows)\n'
    printf '```\n\n'
  } >> "$1/README.md"
}

# add_prose <fixture-root> <name> <skills-phrase> <agents-phrase> [lead-in]
add_prose() {
  local root="$1" name="$2" sk="$3" ag="$4" lead="${5:-}"
  printf '[%s](%s/README.md) does things. %s%s and %s.\n\n' \
    "$name" "$name" "$lead" "$sk" "$ag" >> "$root/README.md"
}

# begin_table <fixture-root>
begin_table() {
  {
    printf '## Plugins at a glance\n\n'
    printf '| Plugin | Capability | Skills | Agents | What it does |\n'
    printf '|--------|-----------|--------|--------|--------------|\n'
  } >> "$1/README.md"
}

# add_row <fixture-root> <name> <skills> <agents>
add_row() {
  printf '| [%s](%s/README.md) | Capability | %s | %s | Does things |\n' \
    "$2" "$2" "$3" "$4" >> "$1/README.md"
}

# add_rollup <fixture-root> <skills> <agents> <plugins>
add_rollup() {
  printf '\n**%s skills, %s agents** across the %s active plugins.\n' \
    "$2" "$3" "$4" >> "$1/README.md"
}

run_guard() {  # run_guard <root> -> sets OUT, CODE
  set +e
  OUT=$(python3 "$GUARD" --root "$1" 2>/dev/null)
  CODE=$?
  set -e
}

# consistent_fixture <root> — two plugins, every claim matching live counts.
consistent_fixture() {
  local root="$1"
  make_plugin "$root" cogni-alpha 3 2
  make_plugin "$root" cogni-beta 1 1
  make_marketplace "$root" cogni-alpha cogni-beta
  begin_readme "$root" 2
  add_prose "$root" cogni-alpha "3 skills" "2 agents"
  add_prose "$root" cogni-beta "1 skill" "1 agent"
  add_tree "$root" 2
  begin_table "$root"
  add_row "$root" cogni-alpha 3 2
  add_row "$root" cogni-beta 1 1
  add_rollup "$root" 4 3 2
}

# real_scratch <name> — a scratch root whose README is a COPY of the real one and
# whose plugin directories and manifest are SYMLINKS to the real tree, so the
# real README can be mutated without touching the repo. glob resolves a
# symlinked directory through an ordinary listdir (only the '*' component is
# expanded), so the live counts are identical to a run against REPO_ROOT.
real_scratch() {
  local dest="$WORK/$1"
  mkdir -p "$dest"
  cp "$REPO_ROOT/README.md" "$dest/README.md"
  ln -s "$REPO_ROOT/.claude-plugin" "$dest/.claude-plugin"
  # docs/ is symlinked for the same reason the plugin directories are: the
  # copied README states counts over it, and a scratch root without it grades
  # every directory-count claim as un-bound instead of grading the claim.
  ln -s "$REPO_ROOT/docs" "$dest/docs"
  for d in "$REPO_ROOT"/cogni-*; do
    [ -d "$d" ] || continue
    ln -s "$d" "$dest/$(basename "$d")"
  done
  printf '%s' "$dest"
}

# mutate <file> <old> <new> — python3, never `sed -i` (its in-place flag differs
# between GNU and BSD, so a sed form passes locally and breaks on the runner).
mutate() {
  OLD="$2" NEW="$3" python3 - "$1" <<'PY'
import io, os, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
old, new = os.environ["OLD"], os.environ["NEW"]
assert s.count(old) == 1, (p, s.count(old), old)
io.open(p, "w", encoding="utf-8").write(s.replace(old, new))
PY
}

# readme_count <sed-ERE-script> — the count root README.md currently claims at
# one anchor, derived at run time rather than restated here as a literal. A
# restated count goes stale the moment the inventory moves, and because mutate()
# asserts under `set -eu` a stale literal ABORTS the suite rather than failing
# one case: the run then looks green-ish while every case after it silently
# never ran. Returns non-zero — never aborts — unless the anchor resolves to
# exactly one all-digit value, so an unresolvable anchor stays a case-local
# failure that its caller grades.
readme_count() {
  local vals count
  vals=$(sed -nE "$1" "$REPO_ROOT/README.md" 2>/dev/null || true)
  count=$(printf '%s\n' "$vals" | grep -c '^[0-9][0-9]*$' || true)
  [ "$count" -eq 1 ] || return 1
  printf '%s' "$vals"
}

# revert_claim <file> <sed-ERE-script> <prefix> <suffix> — derive N from the
# live root README.md, then rewrite "<prefix>N<suffix>" to "<prefix>N+1<suffix>"
# in <file>. Returns non-zero without aborting when the anchor cannot be derived
# or does not appear exactly once; uniqueness itself stays enforced downstream
# by mutate()'s own count(old) == 1 assertion. The set +e / set -e wrapper is
# the whole point: it converts a stale anchor from a suite abort into a status
# its call site folds into that case's own predicate.
revert_claim() {
  local file="$1" script="$2" prefix="$3" suffix="$4" n rc
  n=$(readme_count "$script") || return 1
  set +e
  mutate "$file" "$prefix$n$suffix" "$prefix$((n + 1))$suffix"
  rc=$?
  set -e
  return "$rc"
}

# try_mutate <file> <old> <new> — mutate() with its abort converted into a
# return status, for a real-tree mutation whose literal does not reduce to the
# <prefix>N<suffix> shape revert_claim takes. Same discipline and same reason as
# that wrapper: a literal that has gone stale must fail its own case, never
# abort the suite and take every case after it with it.
try_mutate() {
  local rc
  set +e
  mutate "$1" "$2" "$3"
  rc=$?
  set -e
  return "$rc"
}

# ---------------------------------------------------------------- case 1
CONSISTENT="$WORK/consistent"
consistent_fixture "$CONSISTENT"
run_guard "$CONSISTENT"
check "ris01 consistent fixture exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ris02 consistent fixture reports zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
assert d['data']['plugins_enumerated']==2, d['data']
assert d['data']['prose_claims']==2, d['data']
assert d['data']['table_claims']==2, d['data']
assert d['data']['rollup_present'] is True, d['data']
"

# The singular arm, asserted against the SAME consistent run above: cogni-beta
# ships exactly 1 skill and 1 agent, so its claim reads "1 skill and 1 agent." A
# plural-only regex would not match it and the plugin would report
# prose-claim-missing, so ris09 pins the property directly rather than leaving
# it implied by ris02's totals.
assert_json "ris09 singular one skill and one agent parses as a claim" "$OUT" "
import json,sys
d=json.load(sys.stdin)
missing=[x for x in d['data']['violations']
         if x['code'] in ('prose-claim-missing','table-claim-missing')]
assert missing==[], missing
assert d['data']['prose_claims']==2, d['data']
"

# ---------------------------------------------------------------- case 2
PROSE_BAD="$WORK/prose-mismatch"
consistent_fixture "$PROSE_BAD"
mutate "$PROSE_BAD/README.md" "does things. 3 skills and 2 agents." "does things. 9 skills and 2 agents."
run_guard "$PROSE_BAD"
check "ris03 prose count mismatch exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris04 prose mismatch reports prose-count-mismatch naming the plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='prose-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-alpha', v
"

# ---------------------------------------------------------------- case 3
TABLE_BAD="$WORK/table-mismatch"
consistent_fixture "$TABLE_BAD"
mutate "$TABLE_BAD/README.md" "| [cogni-alpha](cogni-alpha/README.md) | Capability | 3 | 2 |" \
                              "| [cogni-alpha](cogni-alpha/README.md) | Capability | 7 | 2 |"
run_guard "$TABLE_BAD"
check "ris05 table cell mismatch exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris06 table mismatch reports table-count-mismatch naming the plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='table-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-alpha', v
"

# ---------------------------------------------------------------- case 4
ROLLUP_BAD="$WORK/rollup-mismatch"
consistent_fixture "$ROLLUP_BAD"
mutate "$ROLLUP_BAD/README.md" "**4 skills, 3 agents**" "**5 skills, 3 agents**"
run_guard "$ROLLUP_BAD"
check "ris07 roll-up mismatch exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris08 roll-up mismatch reports rollup-count-mismatch" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='rollup-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin'] is None, v
"


# ---------------------------------------------------------------- case 6
# A claim line that ALSO carries a mid-sentence count phrase. The real README
# has one: a plugin paragraph opening "... 21 skills handle the full positioning
# lifecycle ..." and closing "21 skills and 20 agents." The line DOES match, once
# — asserting it does not match would pin the wrong property.
MIDSENT="$WORK/mid-sentence"
make_plugin "$MIDSENT" cogni-alpha 3 2
make_marketplace "$MIDSENT" cogni-alpha
begin_readme "$MIDSENT" 1
add_prose "$MIDSENT" cogni-alpha "3 skills" "2 agents" "9 skills handle the whole lifecycle. "
add_tree "$MIDSENT" 1
begin_table "$MIDSENT"
add_row "$MIDSENT" cogni-alpha 3 2
add_rollup "$MIDSENT" 3 2 1
run_guard "$MIDSENT"
assert_json "ris10 mid-sentence skills phrase yields exactly one claim with the final numbers" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['prose_claims']==1, d['data']
amb=[x for x in d['data']['violations'] if x['code']=='prose-claim-ambiguous']
assert amb==[], amb
"

# ---------------------------------------------------------------- case 7
NOAGENTS="$WORK/no-agents-dir"
make_plugin "$NOAGENTS" cogni-alpha 2 0
make_marketplace "$NOAGENTS" cogni-alpha
begin_readme "$NOAGENTS" 1
add_prose "$NOAGENTS" cogni-alpha "2 skills" "0 agents"
add_tree "$NOAGENTS" 1
begin_table "$NOAGENTS"
add_row "$NOAGENTS" cogni-alpha 2 0
add_rollup "$NOAGENTS" 2 0 1
run_guard "$NOAGENTS"
assert_json "ris11 plugin with no agents directory counts zero without erroring" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['live_counts']['cogni-alpha']['agents']==0, d['data']['live_counts']
"

# ---------------------------------------------------------------- case 8
# A per-plugin README carrying a wrong claim must be invisible: the guard reads
# exactly one file, and asserting over both would put two guards on one claim
# and none on the other.
PLUGIN_README="$WORK/plugin-readme"
consistent_fixture "$PLUGIN_README"
printf '[cogni-alpha](cogni-alpha/README.md) does things. 99 skills and 99 agents.\n' \
  > "$PLUGIN_README/cogni-alpha/README.md"
run_guard "$PLUGIN_README"
check "ris12 per-plugin README claim is not discovered" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ris13 no count from a per-plugin README reaches the result" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['live_counts']['cogni-alpha']=={'skills':3,'agents':2}, d['data']['live_counts']
assert '99' not in json.dumps(d['data']['violations']), d['data']['violations']
assert d['data']['files_scanned']==['README.md'], d['data']['files_scanned']
"

# ---------------------------------------------------------------- case 9
NOCLAIMS="$WORK/no-claims"
make_plugin "$NOCLAIMS" cogni-alpha 3 2
make_marketplace "$NOCLAIMS" cogni-alpha
begin_readme "$NOCLAIMS" 1
printf 'Prose with no count claim at all.\n\n' >> "$NOCLAIMS/README.md"
begin_table "$NOCLAIMS"
run_guard "$NOCLAIMS"
check "ris14 README with no recognizable claim exits non-zero" "$([ "$CODE" -ne 0 ] && echo 0 || echo 1)"
assert_json "ris15 no-claim README reports no-claims-discovered" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='no-claims-discovered']
assert len(v)==1, d['data']['violations']
"

# ---------------------------------------------------------------- case 10
NOREADME="$WORK/no-readme"
make_plugin "$NOREADME" cogni-alpha 1 1
make_marketplace "$NOREADME" cogni-alpha
run_guard "$NOREADME"
check "ris16 missing root README exits 2 not 1" "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "ris17 missing root README reports the error in the envelope" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
assert d['data']=={}, d
"

# ---------------------------------------------------------------- case 11
# The table's row order and the manifest's plugins[] order genuinely differ in
# the real README, so rows must be keyed by their link text, never by index.
REORDERED="$WORK/reordered"
make_plugin "$REORDERED" cogni-alpha 3 2
make_plugin "$REORDERED" cogni-beta 1 1
make_marketplace "$REORDERED" cogni-alpha cogni-beta
begin_readme "$REORDERED" 2
add_prose "$REORDERED" cogni-alpha "3 skills" "2 agents"
add_prose "$REORDERED" cogni-beta "1 skill" "1 agent"
add_tree "$REORDERED" 2
begin_table "$REORDERED"
add_row "$REORDERED" cogni-beta 1 1
add_row "$REORDERED" cogni-alpha 3 2
add_rollup "$REORDERED" 4 3 2
run_guard "$REORDERED"
assert_json "ris18 table order differing from marketplace order is keyed by name" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------- case 12
REAL_CLEAN=$(real_scratch real-clean)
run_guard "$REAL_CLEAN"
check "ris19 real repo at HEAD exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ris20 real repo reports zero violations across every marketplace plugin" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
n=d['data']['plugins_enumerated']
assert n>0, d['data']
assert d['data']['prose_claims']==n, d['data']
assert d['data']['table_claims']==n, d['data']
assert d['data']['rollup_present'] is True, d['data']
"

# ---------------------------------------------------------------- case 13
# The three real claim sites, reverted one at a time. Each must redden on its
# own: a guard that only notices one of them leaves the other two drifting.
# Each from-side is DERIVED from root README.md at run time — the same premise
# the guard under test enforces on that file, applied to its own suite. An
# anchor that will not resolve fails its own case here and lets the cases after
# it run, rather than aborting the suite and taking ris22-ris29 with it.
#
# BOTH digits in each anchor are derived, not just the reverted one. Every claim
# site here states a skills count beside an agents count, and an anchor that
# reverts one while restating the other as a literal stops matching the day the
# RESTATED count moves — a plugin retirement that changes only the agent digit
# then reddens ris21-ris25 on their own stale anchors while the guard they exist
# to prove is behaving correctly. That is a false red on a correct change, and
# it is the harder kind to read, because the failure names the guard rather than
# the anchor. The sibling digit is read through readme_count exactly as the
# reverted one is; an unresolvable sibling leaves the literal unmatchable, which
# revert_claim reports as this case's own failure rather than a suite abort.
WS_AGENTS=$(readme_count 's/.*management\. [0-9]+ skills and ([0-9]+) agents\..*/\1/p') || WS_AGENTS=''
WS_TABLE_AGENTS=$(readme_count 's/.*\| Workspace Infrastructure \| [0-9]+ \| ([0-9]+) \|.*/\1/p') || WS_TABLE_AGENTS=''
ROLLUP_AGENTS=$(readme_count 's/.*\*\*[0-9]+ skills, ([0-9]+) agents\*\*.*/\1/p') || ROLLUP_AGENTS=''

REAL_PROSE=$(real_scratch real-prose-reverted)
ANCHOR_OK=0
revert_claim "$REAL_PROSE/README.md" \
  's/.*management\. ([0-9]+) skills and [0-9]+ agents\..*/\1/p' \
  'management. ' " skills and $WS_AGENTS agents." || ANCHOR_OK=1
run_guard "$REAL_PROSE"
check "ris21 real README with the workspace prose count reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris22 reverted prose reports prose-count-mismatch naming cogni-workspace" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=[x for x in d['data']['violations'] if x['code']=='prose-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['plugin']=='cogni-workspace', v
"

REAL_TABLE=$(real_scratch real-table-reverted)
ANCHOR_OK=0
revert_claim "$REAL_TABLE/README.md" \
  's/.*\| Workspace Infrastructure \| ([0-9]+) \| [0-9]+ \|.*/\1/p' \
  '| Workspace Infrastructure | ' " | $WS_TABLE_AGENTS |" || ANCHOR_OK=1
run_guard "$REAL_TABLE"
check "ris23 real README with the workspace table cell reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

REAL_ROLLUP=$(real_scratch real-rollup-reverted)
ANCHOR_OK=0
revert_claim "$REAL_ROLLUP/README.md" \
  's/.*\*\*([0-9]+) skills, [0-9]+ agents\*\*.*/\1/p' \
  '**' " skills, $ROLLUP_AGENTS agents**" || ANCHOR_OK=1
run_guard "$REAL_ROLLUP"
check "ris24 real README with the roll-up total reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------- case 14
# The singular arm against the real tree: one plugin's claim reads
# "1 skill and N agents." Pluralising it must redden, which proves the singular
# form was being read as a claim rather than skipped. N is derived for the same
# reason case 13's siblings are — the singular skills count is what this arm is
# about, and restating the agents count beside it would make an unrelated
# agent-inventory change abort this suite through mutate()'s uniqueness assert.
SINGULAR_AGENTS=$(readme_count 's/.*pitches\. 1 skill and ([0-9]+) agents\..*/\1/p') || SINGULAR_AGENTS=''
REAL_SINGULAR=$(real_scratch real-singular)
ANCHOR_OK=0
try_mutate "$REAL_SINGULAR/README.md" \
  "pitches. 1 skill and $SINGULAR_AGENTS agents." \
  "pitches. 2 skills and $SINGULAR_AGENTS agents." || ANCHOR_OK=1
run_guard "$REAL_SINGULAR"
check "ris25 real README with the singular claim pluralized exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------- case 15
# Section scoping. A pipe table OUTSIDE the glance section whose first cell is a
# markdown link must not be read as a claim: the real README carries such a
# table one formatting edit away from this shape, and a file-wide scan would
# redden a blocking gate on a change that has nothing to do with counts.
FOREIGN_TABLE="$WORK/foreign-table"
consistent_fixture "$FOREIGN_TABLE"
{
  printf '\n## Install\n\n'
  printf '| Server | Used by | What it enables |\n'
  printf '|--------|---------|-----------------|\n'
  printf '| [excalidraw](https://example.invalid/excalidraw) | [cogni-alpha](cogni-alpha/README.md) | Diagram rendering |\n'
} >> "$FOREIGN_TABLE/README.md"
run_guard "$FOREIGN_TABLE"
check "ris26 a linked table row outside the glance section is not discovered" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# ---------------------------------------------------------------- case 16
RENAMED="$WORK/renamed-heading"
consistent_fixture "$RENAMED"
mutate "$RENAMED/README.md" "## Plugins at a glance" "## The plugins, at a glance"
run_guard "$RENAMED"
assert_json "ris27 renaming the glance heading reports section-missing and fails" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='section-missing']
assert len(v)==1, d['data']['violations']
"

# ---------------------------------------------------------------- case 17
# The count cells are located from the table's own header row, not pinned to a
# fixed offset. The generator that reassembles this README carries a different
# column set, so a fixed offset would read the wrong column the day one moves.
# ris28: a header naming neither count column fails loudly with its own code
# rather than reporting every row as unparsable cells.
NO_HEADER="$WORK/table-header-unrecognized"
make_plugin "$NO_HEADER" cogni-alpha 3 2
make_marketplace "$NO_HEADER" cogni-alpha
begin_readme "$NO_HEADER" 1
add_prose "$NO_HEADER" cogni-alpha "3 skills" "2 agents"
{
  printf '## Plugins at a glance\n\n'
  printf '| Plugin | Capability | Maturity | What it does |\n'
  printf '|--------|-----------|----------|--------------|\n'
  printf '| [cogni-alpha](cogni-alpha/README.md) | Capability | Preview | Does things |\n'
} >> "$NO_HEADER/README.md"
add_rollup "$NO_HEADER" 3 2 1
run_guard "$NO_HEADER"
assert_json "ris28 a table header naming no count column reports table-header-unrecognized" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='table-header-unrecognized']
assert len(v)==1, d['data']['violations']
unparsable=[x for x in d['data']['violations'] if x['code']=='table-cell-unparsable']
assert unparsable==[], unparsable
"

# ris29: the same table with an EXTRA column inserted before Skills still reads
# the right cells. Under a fixed parts[3]/parts[4] offset this run reports the
# inserted column as a non-integer count instead of passing.
SHIFTED="$WORK/table-columns-shifted"
make_plugin "$SHIFTED" cogni-alpha 3 2
make_marketplace "$SHIFTED" cogni-alpha
begin_readme "$SHIFTED" 1
add_prose "$SHIFTED" cogni-alpha "3 skills" "2 agents"
add_tree "$SHIFTED" 1
{
  printf '## Plugins at a glance\n\n'
  printf '| Plugin | Capability | Maturity | Skills | Agents | What it does |\n'
  printf '|--------|-----------|----------|--------|--------|--------------|\n'
  printf '| [cogni-alpha](cogni-alpha/README.md) | Capability | Preview | 3 | 2 | Does things |\n'
} >> "$SHIFTED/README.md"
add_rollup "$SHIFTED" 3 2 1
run_guard "$SHIFTED"
check "ris29 a count column shifted by an inserted column is still read correctly" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# --------------------------------------------------------------- case 18
# The bare plugin-count arm: three sites, three regions. ris30 pins that all
# three are discovered on a clean fixture AND that the same-fence decoy is not
# read — the tree claim must come back as the plugin count, never the guides
# count that shares its fence and its shape.
run_guard "$CONSISTENT"
assert_json "ris30 the three bare plugin-count sites are discovered and the same-fence decoy is not" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
c=d['data']['plugin_count_claims']
assert sorted(c)==['intro','lede','tree'], c
assert [c[k]['count'] for k in ('lede','intro','tree')]==[2,2,2], c
assert all(isinstance(c[k]['line'],int) for k in c), c
"

# ris31-ris36: each of the three sites drifts INDEPENDENTLY and the guard names
# which one. One aggregated case could not distinguish them, which is the whole
# point of the site discriminator.
BARE_LEDE="$WORK/bare-lede"
consistent_fixture "$BARE_LEDE"
mutate "$BARE_LEDE/README.md" ". 2 Apache-2.0 plugins that automate" ". 3 Apache-2.0 plugins that automate"
run_guard "$BARE_LEDE"
check "ris31 a drifted lede plugin count exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris32 the drifted lede count reports plugin-count-mismatch naming the lede site" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=[x for x in d['data']['violations'] if x['code']=='plugin-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['site']=='lede', v
assert isinstance(v[0]['line'],int), v
"

BARE_INTRO="$WORK/bare-intro"
consistent_fixture "$BARE_INTRO"
mutate "$BARE_INTRO/README.md" "2 plugins organized around" "3 plugins organized around"
run_guard "$BARE_INTRO"
check "ris33 a drifted intro plugin count exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris34 the drifted intro count reports plugin-count-mismatch naming the intro site" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=[x for x in d['data']['violations'] if x['code']=='plugin-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['site']=='intro', v
assert isinstance(v[0]['line'],int), v
"

BARE_TREE="$WORK/bare-tree"
consistent_fixture "$BARE_TREE"
mutate "$BARE_TREE/README.md" "Marketplace manifest (2 plugins)" "Marketplace manifest (3 plugins)"
run_guard "$BARE_TREE"
check "ris35 a drifted tree plugin count exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris36 the drifted tree count reports plugin-count-mismatch naming the tree site" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=[x for x in d['data']['violations'] if x['code']=='plugin-count-mismatch']
assert len(v)==1, d['data']['violations']
assert v[0]['site']=='tree', v
assert isinstance(v[0]['line'],int), v
"

# ris37: a prose RENAME around a claim cannot silently disarm the site. The
# number is untouched and still correct; only the noun moved.
BARE_RENAMED="$WORK/bare-renamed"
consistent_fixture "$BARE_RENAMED"
mutate "$BARE_RENAMED/README.md" "2 Apache-2.0 plugins that automate" "2 Apache-2.0 extensions that automate"
run_guard "$BARE_RENAMED"
assert_json "ris37 renaming the lede noun reports plugin-count-missing rather than passing" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
v=[x for x in d['data']['violations'] if x['code']=='plugin-count-missing']
assert len(v)==1, d['data']['violations']
assert v[0]['site']=='lede', v
"

# ris38: the in-fence half of the fence decision. The identical tree line,
# unfenced, is NOT the tree claim — so a guard that dropped the fence filter
# and scanned every line would find it here and this case would redden.
NOFENCE="$WORK/tree-unfenced"
make_plugin "$NOFENCE" cogni-alpha 3 2
make_marketplace "$NOFENCE" cogni-alpha
begin_readme "$NOFENCE" 1
add_prose "$NOFENCE" cogni-alpha "3 skills" "2 agents"
{
  printf '## How it works\n\n'
  printf 'fixture/\n'
  printf '|   `-- marketplace.json   # Marketplace manifest (1 plugins)\n\n'
} >> "$NOFENCE/README.md"
begin_table "$NOFENCE"
add_row "$NOFENCE" cogni-alpha 3 2
add_rollup "$NOFENCE" 3 2 1
run_guard "$NOFENCE"
assert_json "ris38 an unfenced tree line is not the tree claim" "$OUT" "
import json,sys
d=json.load(sys.stdin)
miss=[x for x in d['data']['violations'] if x['code']=='plugin-count-missing']
assert len(miss)==1, d['data']['violations']
assert miss[0]['site']=='tree', miss
mism=[x for x in d['data']['violations'] if x['code']=='plugin-count-mismatch']
assert mism==[], mism
"

# ris39: the out-of-fence half of the same decision. A fenced example carrying a
# second bare count sits INSIDE the prose section — placement is load-bearing,
# because a fence under its own H2 would fall outside the prose bounds and be
# skipped by region scoping, grading the fence filter not at all. Here, drop the
# unfenced filter and the region carries two matches, so the intro site degrades
# to plugin-count-ambiguous and this case reddens.
FENCED_EXAMPLE="$WORK/fenced-example"
make_plugin "$FENCED_EXAMPLE" cogni-alpha 3 2
make_plugin "$FENCED_EXAMPLE" cogni-beta 1 1
make_marketplace "$FENCED_EXAMPLE" cogni-alpha cogni-beta
begin_readme "$FENCED_EXAMPLE" 2
add_prose "$FENCED_EXAMPLE" cogni-alpha "3 skills" "2 agents"
{
  printf '```\n'
  printf 'Example README: 5 plugins organized around capability areas.\n'
  printf '```\n\n'
} >> "$FENCED_EXAMPLE/README.md"
add_prose "$FENCED_EXAMPLE" cogni-beta "1 skill" "1 agent"
add_tree "$FENCED_EXAMPLE" 2
begin_table "$FENCED_EXAMPLE"
add_row "$FENCED_EXAMPLE" cogni-alpha 3 2
add_row "$FENCED_EXAMPLE" cogni-beta 1 1
add_rollup "$FENCED_EXAMPLE" 4 3 2
run_guard "$FENCED_EXAMPLE"
assert_json "ris39 a fenced example inside the prose section is not a second intro claim" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
c=d['data']['plugin_count_claims']
assert c['intro']['count']==2, c
amb=[x for x in d['data']['violations'] if x['code']=='plugin-count-ambiguous']
assert amb==[], amb
"

# ris40: the roll-up's own plugin count stays bound EXACTLY ONCE. It matches the
# bare pattern too, and is kept out of reach only by region scoping — so a new
# arm that widened its regions would report the same drift twice.
DOUBLE_BIND="$WORK/double-bind"
consistent_fixture "$DOUBLE_BIND"
mutate "$DOUBLE_BIND/README.md" "across the 2 active plugins" "across the 3 active plugins"
run_guard "$DOUBLE_BIND"
assert_json "ris40 a drifted roll-up plugin count is reported once, by the roll-up arm alone" "$OUT" "
import json,sys
d=json.load(sys.stdin)
r=[x for x in d['data']['violations'] if x['code']=='rollup-plugin-count-mismatch']
assert len(r)==1, d['data']['violations']
p=[x for x in d['data']['violations'] if x['code'].startswith('plugin-count-')]
assert p==[], p
"

# ris41: the arm's basis is the same universe the roll-up arm compares against —
# the plugins whose source normalises to a countable directory, not every entry
# the manifest lists. This fixture is the day the two differ: keyed off
# len(plugins) instead, every bare site would report a mismatch here.
UNUSABLE_SRC="$WORK/unusable-source"
make_plugin "$UNUSABLE_SRC" cogni-alpha 3 2
mkdir -p "$UNUSABLE_SRC/.claude-plugin"
{
  printf '{\n  "name": "fixture",\n  "plugins": [\n'
  printf '    {"name": "cogni-alpha", "source": "./cogni-alpha", "version": "0.0.1"},\n'
  printf '    {"name": "cogni-beta", "source": "/absolute/cogni-beta", "version": "0.0.1"}\n'
  printf '  ]\n}\n'
} > "$UNUSABLE_SRC/.claude-plugin/marketplace.json"
begin_readme "$UNUSABLE_SRC" 1
add_prose "$UNUSABLE_SRC" cogni-alpha "3 skills" "2 agents"
add_tree "$UNUSABLE_SRC" 1
begin_table "$UNUSABLE_SRC"
add_row "$UNUSABLE_SRC" cogni-alpha 3 2
add_rollup "$UNUSABLE_SRC" 3 2 1
run_guard "$UNUSABLE_SRC"
assert_json "ris41 the bare arm counts the same universe the roll-up arm does" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['plugins_enumerated']==1, d['data']
c=d['data']['plugin_count_claims']
assert [c[k]['count'] for k in ('lede','intro','tree')]==[1,1,1], c
"

# ris42-ris44: the three REAL claim sites, reverted independently against a
# scratch copy, each count derived at run time. A restated literal here would go
# stale the day the plugin roster moves and abort the suite.
REAL_LEDE=$(real_scratch real-bare-lede)
ANCHOR_OK=0
revert_claim "$REAL_LEDE/README.md" 's/.*\. ([0-9]+) Apache-2.0 plugins that automate.*/\1/p' \
  '. ' ' Apache-2.0 plugins that automate' || ANCHOR_OK=1
run_guard "$REAL_LEDE"
check "ris42 real README with the lede plugin count reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

REAL_INTRO=$(real_scratch real-bare-intro)
ANCHOR_OK=0
revert_claim "$REAL_INTRO/README.md" 's/^([0-9]+) plugins organized around.*/\1/p' \
  '' ' plugins organized around' || ANCHOR_OK=1
run_guard "$REAL_INTRO"
check "ris43 real README with the intro plugin count reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

REAL_TREE=$(real_scratch real-bare-tree)
ANCHOR_OK=0
revert_claim "$REAL_TREE/README.md" 's/.*Marketplace manifest \(([0-9]+) plugins\).*/\1/p' \
  'Marketplace manifest (' ' plugins)' || ANCHOR_OK=1
run_guard "$REAL_TREE"
check "ris44 real README with the fenced tree plugin count reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# ris45: the real README carries all three sites, each at the live universe size.
run_guard "$REAL_CLEAN"
assert_json "ris45 the real README carries all three bare sites at the live plugin count" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
n=d['data']['plugins_enumerated']
c=d['data']['plugin_count_claims']
assert sorted(c)==['intro','lede','tree'], c
assert [c[k]['count'] for k in c]==[n,n,n], (c,n)
"

# ris46: the count is DELETED while its qualifier and noun remain. This is the
# only shape that grades the bare pattern's negative lookbehind: without it the
# trailing digit of the version-like qualifier is read as the count, so the site
# reports a mismatch against a claim of zero instead of the missing claim it is.
COUNTLESS="$WORK/bare-countless"
consistent_fixture "$COUNTLESS"
mutate "$COUNTLESS/README.md" "Open-source things. 2 Apache-2.0 plugins" "Open-source things. Apache-2.0 plugins"
run_guard "$COUNTLESS"
assert_json "ris46 a lede claim whose count is deleted reports missing, never a count of zero" "$OUT" "
import json,sys
d=json.load(sys.stdin)
miss=[x for x in d['data']['violations'] if x['code']=='plugin-count-missing']
assert len(miss)==1, d['data']['violations']
assert miss[0]['site']=='lede', miss
mism=[x for x in d['data']['violations'] if x['code']=='plugin-count-mismatch']
assert mism==[], mism
"

# ris47: a site carrying TWO candidates is ambiguous, and ambiguous ALONE. The
# two findings call for opposite fixes — one region has too many candidates, the
# other none — so reporting both would send the reader at the wrong edit.
AMBIG="$WORK/bare-ambiguous"
consistent_fixture "$AMBIG"
mutate "$AMBIG/README.md" "2 plugins organized around capability areas." \
  $'2 plugins organized around capability areas.\n\nA second sentence claims 2 plugins outright.'
run_guard "$AMBIG"
assert_json "ris47 an ambiguous site is reported as ambiguous alone, never also as missing" "$OUT" "
import json,sys
d=json.load(sys.stdin)
amb=[x for x in d['data']['violations'] if x['code']=='plugin-count-ambiguous']
assert len(amb)==1, d['data']['violations']
assert amb[0]['site']=='intro', amb
miss=[x for x in d['data']['violations'] if x['code']=='plugin-count-missing']
assert miss==[], miss
"

# --------------------------------------------------------------- case 13
# The directory-count arm. Each site drifts independently, so a finding names
# which claim moved rather than that "a count" moved.
DIR_GUIDES="$WORK/dir-guides-drift"
consistent_fixture "$DIR_GUIDES"
mutate "$DIR_GUIDES/README.md" "# Deep dives (9 guides)" "# Deep dives (8 guides)"
run_guard "$DIR_GUIDES"
check "ris48 a drifted guides count in the tree fence exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris49 the drifted guides count reports dir-count-mismatch naming tree-guides" "$OUT" "
import json,sys
d=json.load(sys.stdin)
mism=[x for x in d['data']['violations'] if x['code']=='dir-count-mismatch']
assert len(mism)==1, d['data']['violations']
assert mism[0]['site']=='tree-guides', mism
assert mism[0]['line']is not None, mism
p=[x for x in d['data']['violations'] if x['code'].startswith('plugin-count-')]
assert p==[], p
"

DIR_WORKFLOWS="$WORK/dir-workflows-drift"
consistent_fixture "$DIR_WORKFLOWS"
mutate "$DIR_WORKFLOWS/README.md" "# Pipeline guides (5 workflows)" "# Pipeline guides (6 workflows)"
run_guard "$DIR_WORKFLOWS"
check "ris50 a drifted workflows count in the tree fence exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ris51 the drifted workflows count reports dir-count-mismatch naming tree-workflows" "$OUT" "
import json,sys
d=json.load(sys.stdin)
mism=[x for x in d['data']['violations'] if x['code']=='dir-count-mismatch']
assert len(mism)==1, d['data']['violations']
assert mism[0]['site']=='tree-workflows', mism
p=[x for x in d['data']['violations'] if x['code'].startswith('plugin-count-')]
assert p==[], p
"

# A removed claim line is missing, never a mismatch: the two call for opposite
# fixes, exactly as the bare arm's own pair does.
DIR_GUIDES_GONE="$WORK/dir-guides-missing"
consistent_fixture "$DIR_GUIDES_GONE"
mutate "$DIR_GUIDES_GONE/README.md" $'|-- docs/plugin-guide/     # Deep dives (9 guides)\n' ""
run_guard "$DIR_GUIDES_GONE"
assert_json "ris52 a removed guides claim reports dir-count-missing naming tree-guides, never a mismatch" "$OUT" "
import json,sys
d=json.load(sys.stdin)
miss=[x for x in d['data']['violations'] if x['code']=='dir-count-missing']
assert len(miss)==1, d['data']['violations']
assert miss[0]['site']=='tree-guides', miss
mism=[x for x in d['data']['violations'] if x['code']=='dir-count-mismatch']
assert mism==[], mism
"

DIR_WF_GONE="$WORK/dir-workflows-missing"
consistent_fixture "$DIR_WF_GONE"
mutate "$DIR_WF_GONE/README.md" $'|-- docs/workflows/        # Pipeline guides (5 workflows)\n' ""
run_guard "$DIR_WF_GONE"
assert_json "ris53 a removed workflows claim reports dir-count-missing naming tree-workflows, never a mismatch" "$OUT" "
import json,sys
d=json.load(sys.stdin)
miss=[x for x in d['data']['violations'] if x['code']=='dir-count-missing']
assert len(miss)==1, d['data']['violations']
assert miss[0]['site']=='tree-workflows', miss
mism=[x for x in d['data']['violations'] if x['code']=='dir-count-mismatch']
assert mism==[], mism
"

# The clean fixture discovers BOTH sites at their live directory counts. The
# fixture's plugin count is 2 while its guides count is 9, so a binding to the
# plugin universe rather than to the directory fails this case rather than
# passing on the coincidence the real README currently offers.
DIR_CLEAN="$WORK/dir-clean"
consistent_fixture "$DIR_CLEAN"
run_guard "$DIR_CLEAN"
assert_json "ris54 the clean fixture discovers both directory sites at their live directory counts" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
c=d['data']['dir_count_claims']
assert sorted(c)==['tree-guides','tree-workflows'], c
assert c['tree-guides']['count']==9, c
assert c['tree-workflows']['count']==5, c
live=d['data']['live_dir_counts']
assert live=={'tree-guides':9,'tree-workflows':5}, live
assert d['data']['plugins_enumerated']==2, d['data']
assert d['data']['files_scanned']==['README.md'], d['data']
"

# The real README, against the real directories. Counts are read back from the
# guard rather than restated, so this case cannot go stale the day docs/ moves.
REAL_DIR=$(real_scratch real-dir-counts)
run_guard "$REAL_DIR"
assert_json "ris55 the real README carries both directory sites at their live directory counts" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
c=d['data']['dir_count_claims']
assert sorted(c)==['tree-guides','tree-workflows'], c
live=d['data']['live_dir_counts']
assert c['tree-guides']['count']==live['tree-guides'], (c,live)
assert c['tree-workflows']['count']==live['tree-workflows'], (c,live)
"

# Each real site reverted independently. The from-side is DERIVED at run time by
# revert_claim, never restated as a literal that would go stale.
REAL_GUIDES=$(real_scratch real-dir-guides)
ANCHOR_OK=0
revert_claim "$REAL_GUIDES/README.md" 's/.*Per-plugin deep dives \(([0-9]+) guides\).*/\1/p' \
  'Per-plugin deep dives (' ' guides)' || ANCHOR_OK=1
run_guard "$REAL_GUIDES"
check "ris56 real README with the guides count reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

REAL_WF=$(real_scratch real-dir-workflows)
ANCHOR_OK=0
revert_claim "$REAL_WF/README.md" 's/.*Cross-plugin pipeline guides \(([0-9]+) workflows\).*/\1/p' \
  'Cross-plugin pipeline guides (' ' workflows)' || ANCHOR_OK=1
run_guard "$REAL_WF"
check "ris57 real README with the workflows count reverted exits 1" "$([ "$ANCHOR_OK" -eq 0 ] && [ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# --------------------------------------------------------------- case 14
# An absent BASIS is not a drifted claim. Without this arm the claim is graded
# against a live count of zero, so the fixture below — whose claim is rewritten
# to (0 guides) — exits 0 and the site asserts nothing. That is what makes this
# case discriminate rather than merely cover.
DIR_BASIS="$WORK/dir-basis-missing"
consistent_fixture "$DIR_BASIS"
mutate "$DIR_BASIS/README.md" "# Deep dives (9 guides)" "# Deep dives (0 guides)"
rm -rf "$DIR_BASIS/docs/plugin-guide"
run_guard "$DIR_BASIS"
assert_json "ris58 an absent backing directory reports dir-basis-missing, never a mismatch against zero" "$OUT" "
import json,sys
d=json.load(sys.stdin)
basis=[x for x in d['data']['violations'] if x['code']=='dir-basis-missing']
assert len(basis)==1, d['data']['violations']
assert basis[0]['site']=='tree-guides', basis
mism=[x for x in d['data']['violations'] if x['code']=='dir-count-mismatch']
assert mism==[], mism
assert 'tree-guides' not in d['data']['live_dir_counts'], d['data']['live_dir_counts']
"

echo
if [ "$FAILED" -eq 0 ]; then
  green "All README inventory-sync guard tests passed."
else
  red "Some README inventory-sync guard tests FAILED."
fi
exit "$FAILED"
