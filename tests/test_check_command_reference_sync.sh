#!/usr/bin/env bash
# test_check_command_reference_sync.sh — self-test for the command-reference guard.
#
# The guard binds docs/command-reference.md to the tree: for every plugin the
# marketplace enumerates, the page's skills line names exactly the
# skills/*/SKILL.md directories with the right count, its slash-command table
# row names exactly the commands/*.md stems (or the plugin sits on the
# no-commands row), and the prose "<N> of the <M> plugins ship **no** commands"
# states the live numbers. Cases:
#   1. Consistent fixture -> exit 0, zero violations, both plugins compared.
#   2. Skills, both directions: a live skill the page omits and a page skill the
#      tree lacks each report their own code naming the plugin and the token; a
#      stated count that disagrees with the tree reports skill-count-desync.
#   3. Commands, both directions and both row kinds: a live command the row
#      omits, a row command the tree lacks, a plugin that grows a commands
#      directory while still sitting on the no-commands row, and a plugin that
#      loses its commands directory while keeping a row.
#   4. Absence is never agreement: a plugin with no skills line, and a
#      command-less plugin missing from the no-commands row, each report rather
#      than comparing empty sets.
#   5. A page naming a plugin the roster no longer lists reports
#      plugin-not-in-roster — the retired-plugin drift class the wiki page had.
#   6. The prose count is bound: a stale "<N> of the <M>" sentence reports
#      prose-count-desync; a removed sentence reports prose-count-missing.
#   7. Zero discovery is a failure: an empty plugins[] and a missing page each
#      exit non-zero rather than reporting the page in sync.
#   8. Failing loudly: a malformed root manifest exits 2 with the error envelope.
#   9. Real repo at branch head -> exit 0, with plugins_enumerated derived from
#      the live manifest rather than a hardcoded roster size.
#
# bash 3.2 + stdlib python3 only. No arguments, no network.
#
# Mutation recipe — replay to confirm the skills comparison has teeth:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-command-reference-sync.py \
#     --expr 's/missing = sorted\(set\(skills\) - set\(stated\)\)/missing = []/m' \
#     --test 'bash tests/test_check_command_reference_sync.sh' --case crs03
#
# The mutation empties the live-minus-page skill set, so an omitted skill can
# never be reported. crs03 goes RED, GREEN again on restore. The /m modifier is
# load-bearing: --expr is fed to `perl -0pi`, which slurps the whole file.
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (crsNN), unique PER EMITTED LINE, followed by a SPACE. A new assertion takes
# the next free id rather than renumbering its neighbours.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-command-reference-sync.py"

# Plain text on purpose — result lines are machine-read.
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

OUT=""
CODE=0
run_guard() {  # run_guard <fixture-root>
  set +e
  OUT=$(python3 "$GUARD" --root "$1" 2>/dev/null)
  CODE=$?
  set -e
}

# build_fixture <root> — two plugins: alpha ships two skills and two commands,
# beta ships one skill and no commands directory. The page agrees with both.
build_fixture() {
  local root="$1"
  rm -rf "$root"
  mkdir -p "$root/.claude-plugin" "$root/docs" \
    "$root/alpha/skills/alpha-setup" "$root/alpha/skills/alpha-resume" "$root/alpha/commands" \
    "$root/beta/skills/beta-run"
  : > "$root/alpha/skills/alpha-setup/SKILL.md"
  : > "$root/alpha/skills/alpha-resume/SKILL.md"
  : > "$root/beta/skills/beta-run/SKILL.md"
  : > "$root/alpha/commands/alpha-go.md"
  : > "$root/alpha/commands/alpha-stop.md"
  printf '{"name": "fixture", "plugins": [{"name": "alpha", "source": "./alpha"}, {"name": "beta", "source": "./beta"}]}\n' \
    > "$root/.claude-plugin/marketplace.json"
  cat > "$root/docs/command-reference.md" <<'EOF'
# Command reference

One of the two plugins ship **no** commands directory at all.

| Plugin | Slash commands |
|---|---|
| alpha | `/alpha-go`, `/alpha-stop` |
| beta | none, skill-invoked |

## Skills, by plugin

**alpha** (2) — `alpha-setup`, `alpha-resume`

**beta** (1) — `beta-run`
EOF
}

# set_page <root> <python-body> — rewrite the page text in place via Python
# string ops, so a case states exactly the edit it plants.
set_page() {
  python3 - "$1/docs/command-reference.md" <<PY
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
$2
open(path, "w", encoding="utf-8").write(text)
PY
}

codes_are() {  # codes_are <label> <json> <expected codes, space-separated>
  assert_json "$1" "$2" "
import json, sys
v = json.load(sys.stdin)['data']['violations']
codes = sorted(x['code'] for x in v)
assert codes == sorted('$3'.split()), codes
"
}

FIX="$WORK/repo"

# --- Case 1: consistent fixture is clean.
build_fixture "$FIX"
run_guard "$FIX"
check "crs01 consistent fixture exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "crs02 consistent fixture compares both skill lists and both command rows" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
assert d["violations"] == [], d["violations"]
assert d["plugins_enumerated"] == 2, d
assert d["skill_lists_compared"] == 2, d
assert d["command_rows_compared"] == 2, d
'

# --- Case 2: skills, both directions, and the count.
build_fixture "$FIX"
mkdir -p "$FIX/alpha/skills/alpha-new"; : > "$FIX/alpha/skills/alpha-new/SKILL.md"
run_guard "$FIX"
assert_json "crs03 a live skill the page omits reports skill-missing naming it" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
codes = sorted(x["code"] for x in v)
assert codes == ["skill-count-desync", "skill-missing"], codes
m = [x for x in v if x["code"] == "skill-missing"][0]
assert m["plugin"] == "alpha" and "alpha-new" in m["detail"], m
'
check "crs04 a live skill the page omits exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("`alpha-resume`", "`alpha-resume`, `alpha-ghost`")'
run_guard "$FIX"
assert_json "crs05 a page skill the tree lacks reports skill-extra naming it" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
codes = sorted(x["code"] for x in v)
assert codes == ["skill-extra"], codes
assert v[0]["plugin"] == "alpha" and "alpha-ghost" in v[0]["detail"], v
'

build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("**alpha** (2)", "**alpha** (3)")'
run_guard "$FIX"
codes_are "crs06 a stated count that disagrees with the tree reports skill-count-desync alone" "$OUT" "skill-count-desync"

# --- Case 3: commands, both directions and both row kinds.
build_fixture "$FIX"
: > "$FIX/alpha/commands/alpha-new.md"
run_guard "$FIX"
assert_json "crs07 a live command the row omits reports command-missing naming it" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert [x["code"] for x in v] == ["command-missing"], v
assert v[0]["plugin"] == "alpha" and "/alpha-new" in v[0]["detail"], v
'

build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("`/alpha-stop`", "`/alpha-stop`, `/alpha-retired`")'
run_guard "$FIX"
assert_json "crs08 a row command the tree lacks reports command-extra naming it" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert [x["code"] for x in v] == ["command-extra"], v
assert "/alpha-retired" in v[0]["detail"], v
'

# Growing or losing a commands directory also moves the live count of
# command-less plugins, so the prose arm fires alongside the row arm in both
# of these. That second code is the arm working, not noise: the page's
# "<N> of the <M>" sentence is stale the moment the directory changes.
build_fixture "$FIX"
mkdir -p "$FIX/beta/commands"; : > "$FIX/beta/commands/beta-go.md"
run_guard "$FIX"
codes_are "crs09 a plugin that grows commands while on the no-commands row reports none-row-desync" "$OUT" "none-row-desync prose-count-desync"

build_fixture "$FIX"
rm -rf "$FIX/alpha/commands"
run_guard "$FIX"
codes_are "crs10 a plugin that loses its commands directory while keeping a row reports command-extra" "$OUT" "command-extra prose-count-desync"

# --- Case 4: absence is never agreement.
build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("**beta** (1) — `beta-run`\n", "")'
run_guard "$FIX"
assert_json "crs11 a plugin with no skills line reports skills-line-missing rather than an empty comparison" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
assert [x["code"] for x in d["violations"]] == ["skills-line-missing"], d["violations"]
assert d["violations"][0]["plugin"] == "beta", d
assert d["skill_lists_compared"] == 1, d
'

build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("| beta | none, skill-invoked |\n", "")'
run_guard "$FIX"
codes_are "crs12 a command-less plugin absent from the no-commands row reports commands-row-missing" "$OUT" "commands-row-missing"

# --- Case 5: a retired plugin left on the page.
build_fixture "$FIX"
set_page "$FIX" 'text = text + "\n**gamma** (1) — `gamma-run`\n"'
run_guard "$FIX"
assert_json "crs13 a page plugin the roster does not list reports plugin-not-in-roster" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert [x["code"] for x in v] == ["plugin-not-in-roster"], v
assert v[0]["plugin"] == "gamma", v
'

# --- Case 6: the prose count is bound.
build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("One of the two plugins", "Two of the two plugins")'
run_guard "$FIX"
codes_are "crs14 a stale prose count reports prose-count-desync" "$OUT" "prose-count-desync"

build_fixture "$FIX"
set_page "$FIX" 'text = text.replace("One of the two plugins ship **no** commands directory at all.\n", "")'
run_guard "$FIX"
codes_are "crs15 a removed prose count reports prose-count-missing" "$OUT" "prose-count-missing"

# --- Case 7: zero discovery is a failure.
build_fixture "$FIX"
printf '{"name": "fixture", "plugins": []}\n' > "$FIX/.claude-plugin/marketplace.json"
run_guard "$FIX"
check "crs16 an empty plugins[] exits 1 rather than reporting a clean zero" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "crs17 an empty plugins[] reports nothing-compared" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
assert "nothing-compared" in [x["code"] for x in d["violations"]], d["violations"]
assert d["plugins_enumerated"] == 0, d
'

build_fixture "$FIX"
rm -f "$FIX/docs/command-reference.md"
run_guard "$FIX"
check "crs18 a missing page exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "crs19 a missing page reports reference-missing and compares nothing" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
codes = [x["code"] for x in d["violations"]]
assert "reference-missing" in codes and "nothing-compared" in codes, codes
assert d["skill_lists_compared"] == 0, d
'

# --- Case 8: failing loudly on a malformed root manifest.
build_fixture "$FIX"
printf '{ not json' > "$FIX/.claude-plugin/marketplace.json"
run_guard "$FIX"
check "crs20 a malformed root manifest exits 2" "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "crs21 a malformed root manifest returns the error envelope" "$OUT" '
import json, sys
d = json.load(sys.stdin)
assert d["success"] is False and d["error"], d
'

# --- Case 9: the real repo at branch head.
run_guard "$REPO_ROOT"
check "crs22 the real repo at branch head exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
LIVE_COUNT=$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    print(len(json.load(fh)["plugins"]))
' "$REPO_ROOT/.claude-plugin/marketplace.json")
assert_json "crs23 the real repo compares every plugin the manifest lists" "$OUT" "
import json, sys
d = json.load(sys.stdin)['data']
live = $LIVE_COUNT
assert live > 0, live
assert d['plugins_enumerated'] == live, (d['plugins_enumerated'], live)
assert d['skill_lists_compared'] == live, (d['skill_lists_compared'], live)
assert d['command_rows_compared'] == live, (d['command_rows_compared'], live)
assert d['violations'] == [], d['violations']
"

exit "$FAILED"
