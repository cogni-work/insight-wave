#!/usr/bin/env bash
# test_check_marketplace_manifest_sync.sh — self-test for the manifest-mirror guard.
#
# The guard binds two fields the root marketplace entry duplicates from each
# plugin's own manifest: `description` (strict equality) and `keywords`
# (marketplace must be a SUBSET of the plugin's list). Cases:
#   1. Consistent fixture -> exit 0, zero violations.
#   2. Description mutated on EACH side independently -> exit 1,
#      description-desync, naming that plugin. Two arms, because a guard that
#      only read one side would pass whenever the other drifted.
#   3. Keywords in BOTH directions: a marketplace-only keyword is a violation,
#      a plugin-only keyword is not. The second arm is the one that matters —
#      three real plugins carry a deliberately narrower marketplace list, so an
#      equality assertion would redden correct behaviour, and only a green case
#      pins subset-not-equality against a future tightening.
#   4. Absence never reads as agreement: a missing or wrongly-typed description
#      or keywords on either side reports its own code rather than letting two
#      None values compare equal, and never raises.
#   5. Zero discovery is a failure: an empty plugins[] exits non-zero with
#      nothing-compared rather than reporting the manifests reconciled.
#   6. Scope: the manifest's top-level metadata.description is NOT the subject —
#      a fixture whose metadata blurb matches no entry is still clean. Without
#      this arm a guard reading the wrong key would look identical on the happy
#      path.
#   7. Failing loudly: an unresolvable source, an unreadable plugin manifest,
#      and a malformed root manifest each report rather than crash or skip.
#   8. Stale-copy immunity: a divergent manifest planted under
#      .claude/worktrees/** is never discovered, because enumeration is
#      source-only. This is the property that keeps the guard from reddening a
#      clean repo on a developer's machine.
#   9. Real repo at branch head -> exit 0, with plugins_enumerated derived from
#      the live manifest rather than a hardcoded roster size.
#
# bash 3.2 + stdlib python3 only. No arguments, no network.
#
# Mutation recipe — replay to confirm the description comparison has teeth:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-marketplace-manifest-sync.py \
#     --expr 's/entry_desc != plugin_desc/False/m' \
#     --test 'bash tests/test_check_marketplace_manifest_sync.sh' --case mms05
#
# The mutation makes the description comparison constantly false, so no
# description drift can ever be reported. mms05, the plugin-side description
# mutation, then goes RED, and GREEN again on restore. The /m modifier is
# load-bearing: --expr is fed to `perl -0pi`, which slurps the whole file, so
# without it the anchors never bind. That literal appears exactly once in the
# guard and is never echoed in its docstring, its comments or a detail string —
# the expression is non-global, so an earlier copy would absorb the
# substitution, leave the executable comparison intact, and grade nothing while
# still reporting a clean rewrite.
#
# Mutation recipe — replay to confirm the keywords subset arm has teeth:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-marketplace-manifest-sync.py \
#     --expr 's/sorted\(set\(entry_kw\) - set\(plugin_kw\)\)/[]/m' \
#     --test 'bash tests/test_check_marketplace_manifest_sync.sh' --case mms07
#
# The mutation empties the extras list, so no marketplace-only keyword can ever
# be reported. mms07 goes RED, GREEN again on restore.
#
# Mutation recipe — zero discovery must not read as a clean zero:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-marketplace-manifest-sync.py \
#     --expr 's/if not enumerated or not \(descriptions_compared or keyword_sets_compared\)/if False/m' \
#     --test 'bash tests/test_check_marketplace_manifest_sync.sh' --case mms15
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id
# (mmsNN), unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. The id is
# followed by a SPACE, never a colon abutting it — the harness matches the case
# whole-token, so a colon-abutting id returns case_not_found. A new assertion
# takes the next free id rather than renumbering its neighbours.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-marketplace-manifest-sync.py"

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

OUT=""
CODE=0
run_guard() {  # run_guard <fixture-root>
  set +e
  OUT=$(python3 "$GUARD" --root "$1" 2>/dev/null)
  CODE=$?
  set -e
}

# build_fixture <fixture-root> — a two-plugin tree whose manifests agree, with
# alpha carrying a deliberately narrower marketplace keyword list (the shape
# three real plugins have) so the happy path already exercises subset-not-equal.
build_fixture() {
  local root="$1"
  rm -rf "$root"
  mkdir -p "$root/.claude-plugin" "$root/alpha/.claude-plugin" "$root/beta/.claude-plugin"
  python3 - "$root" <<'PY'
import json, os, sys
root = sys.argv[1]
alpha_desc = "Alpha plugin — does the alpha thing."
beta_desc = "Beta plugin — does the beta thing."
alpha_kw_plugin = ["alpha", "one", "two", "three"]
alpha_kw_market = ["alpha", "one"]          # deliberate curated subset
beta_kw = ["beta", "four"]                   # equal on both sides

def write(path, obj):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

write(os.path.join(root, "alpha", ".claude-plugin", "plugin.json"),
      {"name": "alpha", "version": "0.0.1", "description": alpha_desc,
       "keywords": alpha_kw_plugin})
write(os.path.join(root, "beta", ".claude-plugin", "plugin.json"),
      {"name": "beta", "version": "0.0.1", "description": beta_desc,
       "keywords": beta_kw})
write(os.path.join(root, ".claude-plugin", "marketplace.json"), {
    "name": "fixture",
    "metadata": {"description": "A marketplace blurb that mirrors no entry."},
    "plugins": [
        {"name": "alpha", "source": "./alpha", "version": "0.0.1",
         "description": alpha_desc, "keywords": alpha_kw_market},
        {"name": "beta", "source": "./beta", "version": "0.0.1",
         "description": beta_desc, "keywords": beta_kw},
    ],
})
PY
}

# patch_json <path> <python-body> — mutate one fixture manifest in place.
patch_json() {
  local path="$1" body="$2"
  python3 - "$path" <<PY
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    doc = json.load(fh)
$body
with open(path, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY
}

FIX="$WORK/repo"
MARKET="$FIX/.claude-plugin/marketplace.json"

# --- Case 1: consistent fixture is clean. The green twin every arm below is
# measured against — each mutation case restores to exactly this state.
build_fixture "$FIX"
run_guard "$FIX"
check "mms01 consistent fixture exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "mms02 consistent fixture reports no violations and compares both plugins" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
assert d["violations"] == [], d["violations"]
assert d["plugins_enumerated"] == 2, d
assert d["descriptions_compared"] == 2, d
assert d["keyword_sets_compared"] == 2, d
'

# --- Case 2: description drift, each side independently.
build_fixture "$FIX"
patch_json "$MARKET" 'doc["plugins"][0]["description"] = "Alpha plugin — drifted on the marketplace side."'
run_guard "$FIX"
check "mms03 marketplace-side description drift exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "mms04 marketplace-side drift reports description-desync naming alpha" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert len(v) == 1, v
assert v[0]["code"] == "description-desync", v
assert v[0]["plugin"] == "alpha", v
'

build_fixture "$FIX"
patch_json "$FIX/alpha/.claude-plugin/plugin.json" 'doc["description"] = "Alpha plugin — drifted on the plugin side."'
run_guard "$FIX"
assert_json "mms05 plugin-side description drift reports description-desync naming alpha" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert len(v) == 1, v
assert v[0]["code"] == "description-desync", v
assert v[0]["plugin"] == "alpha", v
'
check "mms06 plugin-side description drift exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# --- Case 3: keywords, both directions. The subset arm is asymmetric on
# purpose, so both directions need pinning.
build_fixture "$FIX"
patch_json "$MARKET" 'doc["plugins"][1]["keywords"].append("market-only")'
run_guard "$FIX"
assert_json "mms07 a marketplace-only keyword reports keywords-not-subset naming it" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert len(v) == 1, v
assert v[0]["code"] == "keywords-not-subset", v
assert v[0]["plugin"] == "beta", v
assert "market-only" in v[0]["detail"], v
'
check "mms08 a marketplace-only keyword exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

build_fixture "$FIX"
patch_json "$FIX/beta/.claude-plugin/plugin.json" 'doc["keywords"].append("plugin-only")'
run_guard "$FIX"
check "mms09 a plugin-only keyword stays clean — subset, never equality" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# --- Case 4: absence is never agreement.
build_fixture "$FIX"
patch_json "$MARKET" 'del doc["plugins"][0]["description"]
del doc["plugins"][0]["keywords"]'
patch_json "$FIX/alpha/.claude-plugin/plugin.json" 'del doc["description"]
del doc["keywords"]'
run_guard "$FIX"
assert_json "mms10 both sides missing both fields reports absence, never a None-equals-None pass" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
codes = sorted(v["code"] for v in d["violations"])
assert codes == ["description-absent", "keywords-absent"], codes
for v in d["violations"]:
    assert "marketplace.json" in v["detail"] and "plugin.json" in v["detail"], v
assert d["descriptions_compared"] == 1, d
assert d["keyword_sets_compared"] == 1, d
'
check "mms11 both sides missing both fields exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

build_fixture "$FIX"
patch_json "$MARKET" 'doc["plugins"][0]["description"] = ["not", "a", "string"]
doc["plugins"][0]["keywords"] = "not-a-list"'
run_guard "$FIX"
assert_json "mms12 wrongly-typed fields on one side report absence codes without raising" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
codes = sorted(v["code"] for v in d["violations"])
assert codes == ["description-absent", "keywords-absent"], codes
for v in d["violations"]:
    assert v["detail"].endswith("marketplace.json"), v
'
check "mms13 wrongly-typed fields exit 1 rather than tracebacking" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# --- Case 5: zero discovery is a failure, not a clean zero.
build_fixture "$FIX"
patch_json "$MARKET" 'doc["plugins"] = []'
run_guard "$FIX"
assert_json "mms14 an empty plugins[] reports nothing-compared" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
assert [v["code"] for v in d["violations"]] == ["nothing-compared"], d["violations"]
assert d["plugins_enumerated"] == 0, d
'
check "mms15 an empty plugins[] exits 1 rather than reporting a clean zero" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

# --- Case 6: the top-level metadata.description is not the subject. The base
# fixture already carries a metadata blurb matching no entry; make it differ
# from every entry description explicitly and confirm the verdict is unchanged.
build_fixture "$FIX"
patch_json "$MARKET" 'doc["metadata"]["description"] = "Entirely unlike any plugin entry description."'
run_guard "$FIX"
check "mms16 a metadata.description matching no entry is not a violation" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# --- Case 7: failing loudly on entries that cannot be joined at all.
build_fixture "$FIX"
patch_json "$MARKET" 'doc["plugins"][0]["source"] = "https://example.invalid/alpha"'
run_guard "$FIX"
assert_json "mms17 a non-local source reports source-unresolvable" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert [x["code"] for x in v] == ["source-unresolvable"], v
'

build_fixture "$FIX"
rm -f "$FIX/alpha/.claude-plugin/plugin.json"
run_guard "$FIX"
assert_json "mms18 an entry whose plugin.json is absent reports manifest-unreadable" "$OUT" '
import json, sys
v = json.load(sys.stdin)["data"]["violations"]
assert [x["code"] for x in v] == ["manifest-unreadable"], v
'

build_fixture "$FIX"
printf '{ not json' > "$MARKET"
run_guard "$FIX"
check "mms19 a malformed root manifest exits 2" "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "mms20 a malformed root manifest returns the error envelope" "$OUT" '
import json, sys
d = json.load(sys.stdin)
assert d["success"] is False, d
assert d["error"], d
'

# --- Case 8: enumeration is source-only, so a stale manifest planted under a
# worktree path is invisible. Reading it would redden a clean tree.
build_fixture "$FIX"
mkdir -p "$FIX/.claude/worktrees/stale/gamma/.claude-plugin"
printf '{"name": "gamma", "description": "Stale copy.", "keywords": ["ghost"]}\n' \
  > "$FIX/.claude/worktrees/stale/gamma/.claude-plugin/plugin.json"
run_guard "$FIX"
assert_json "mms21 a manifest under .claude/worktrees is never enumerated" "$OUT" '
import json, sys
d = json.load(sys.stdin)["data"]
assert d["violations"] == [], d["violations"]
assert d["plugins_enumerated"] == 2, d
'

# --- Case 9: the real repo at branch head. plugins_enumerated is compared
# against the live manifest, never a hardcoded roster size, so adding or
# retiring a plugin cannot silently invalidate this case.
run_guard "$REPO_ROOT"
check "mms22 the real repo at branch head exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
LIVE_COUNT=$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    print(len(json.load(fh)["plugins"]))
' "$REPO_ROOT/.claude-plugin/marketplace.json")
assert_json "mms23 the real repo compares every plugin the manifest lists" "$OUT" "
import json, sys
d = json.load(sys.stdin)['data']
live = $LIVE_COUNT
assert live > 0, live
assert d['plugins_enumerated'] == live, (d['plugins_enumerated'], live)
assert d['descriptions_compared'] == live, (d['descriptions_compared'], live)
assert d['keyword_sets_compared'] == live, (d['keyword_sets_compared'], live)
assert d['violations'] == [], d['violations']
"

exit "$FAILED"
