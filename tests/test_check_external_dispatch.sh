#!/usr/bin/env bash
# test_check_external_dispatch.sh — self-test for the external-dispatch guard.
#
# The guard asserts a HARD clean-zero: no live-dispatch surface
# (*/skills/*/SKILL.md, */agents/*.md, */commands/*.md, */hooks/**,
# */scripts/*.sh, */scripts/*.py) may carry a
# dispatch token for a prefix listed in scripts/retired-plugins.json. Cases:
#   1. Negative controls (bare noun "cogni-research" with no colon) -> exit 0.
#   2. Dispatch-laden fixture (cogni-wiki: + cogni-research:) -> exit 1, naming
#      the file + line + match.
#   3. Inline-allow escape hatch -> the flagged line is skipped.
#   4. Path exclusions (cogni-knowledge/ history, */wiki/ mirror) skipped in
#      discover mode -> exit 0 even though the token is present.
#   5. Real tree -> exit 0 (clean-zero today).
#   6. A tracked undecodable file under a discovered */hooks/** surface ->
#      exit 2 by design, with the error naming that file (ed42/ed43).
#
# Registry-loading cases (the retired set is data, not source):
#   R1. Missing registry     -> exit 2, never a silent clean-zero.
#   R2. Malformed JSON       -> exit 2.
#   R3. Empty prefix list    -> exit 2.
#   R4. Non-string / blank / padded / colon-bearing entry -> exit 2.
#   R5. A prefix added to the registry makes a planted dispatch fire -> exit 1.
#   R6. --registry REPLACES the default file rather than unioning with it.
#
# R1-R4 are the anti-vacuity trio-plus-one: each asserts a NON-ZERO exit on an
# input where a guard that ignored the registry would exit 0, so none of them can
# pass against an implementation that does not actually load it. They reach that
# state by staging a COPY of the guard with (or without) a sibling registry rather
# than by passing --registry, precisely so the assertion is behavioural — a
# --registry-based case would go red merely because an older argparse rejects the
# unknown flag, which proves nothing about the load path.
#
# bash 3.2 + stdlib python3 only (+ git for the discover-mode exclusion case).
#
# Result-line ids: every emitted PASS:/FAIL: line carries a first-token id,
# unique PER EMITTED LINE rather than per logical case, so
# `mutation-check.sh --case <id>` addresses exactly one assertion. Every id in
# this file is `edNN`: `ed01`-`ed09` for cases 1-5, `ed10`-`ed19` for the
# registry cases R1-R6 (R1 -> ed10/ed11, R2 -> ed12/ed13, R3 -> ed14,
# R4 -> ed15, R5 -> ed16/ed17, R6 -> ed18/ed19), `ed20`-`ed33` for the
# unresolved-target arm, `ed34`-`ed36` for its per-plugin pair binding and
# `ed37`-`ed41` for the scripts-surface discovery cases and `ed42`-`ed43` for
# the hooks decode-policy case.
# `R1`-`R6` remain the names of
# the LOGICAL case groups in the header notes and the section dividers below;
# they are not ids and must never be emitted as one. Never introduce an
# `R<n><letter>` id here: tests/test_check_mcp_tool_grant.sh already emits
# `R1a`, `R2a`, `R3a`, `R4a` and `R6a` among its own result lines, so an
# `R`-stemmed id in this file would be ambiguous in any harness run whose
# `--test` captures both suites. The whole-token matching rule the ids depend
# on is stated once, with the regex, above the registry cases below. A new
# assertion takes the next free id — `ed44` onward — never a renumbering and
# never an `R`-stemmed id.
#
# Mutation recipe (proves the per-plugin pair binding is load-bearing):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-external-dispatch.py \
#     --expr 's/if slug in resolvable\.get\(plugin, \(\)\):/if any(slug in owned for owned in resolvable.values()):/' \
#     --test 'bash tests/test_check_external_dispatch.sh' --case ed34
#
# The replacement restores GLOBAL resolution — valid Python, and `resolvable` is
# a scan_file parameter so `.values()` is in scope — so the wrong-owner token in
# livetree3 resolves again, `summary.total` drops to 0 and ed34 goes red. No /m
# is needed: the pattern carries no ^ or $ anchor. The substitution is
# non-global, which is safe only while that gate literal occurs exactly once in
# the guard — an invariant the guard's own comment above the line states.
# ed22 CANNOT carry this recipe: its token `cogni-beta:no-such-thing` resolves
# under no plugin, so it stays green when the binding is loosened back.
#
# Mutation recipe (proves the scripts-surface glob is load-bearing):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-external-dispatch.py \
#     --expr 's/\*\.sh",/*.shx",/' \
#     --test 'bash tests/test_check_external_dispatch.sh' --case ed38
#
# The substitution renames the shell-script glob entry to a suffix nothing
# matches, so the fixture's scripts/helper.sh stops being discovered, its
# unresolved token disappears, `summary.total` drops to 0 and ed38 goes red.
# Both recipes here substitute the first match only, which is safe only while
# each entry's text occurs exactly once in the guard — an invariant stated
# positionally above DEFAULT_GLOBS.
#
# Mutation recipe (proves the EXTENSION-SCOPING is load-bearing):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-external-dispatch.py \
#     --expr 's/"\*\/scripts\/\*\.py",/"*\/scripts\/*",/' \
#     --test 'bash tests/test_check_external_dispatch.sh' --case ed37
#
# The substitution widens the python-script entry to a bare */scripts/* glob,
# which a git pathspec's * makes match the fixture's scripts/blob.bin too. The
# guard then opens that binary and the run exits 2 instead of 1 — ed37 goes red.
# This is what gives the binary fixture teeth.
#
# Mutation recipe (proves the STRICT DECODE STANCE is load-bearing):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-external-dispatch.py \
#     --expr 's/open\(abs_path, "r", encoding="utf-8"\)/open(abs_path, "r", encoding="utf-8", errors="replace")/' \
#     --test 'bash tests/test_check_external_dispatch.sh' --case ed42
#
# The substitution decodes with replacement instead of raising, so the ed42
# fixture's hooks/blob.bin is scanned rather than aborting the run: the guard
# exits 0 instead of 2 and ed42 goes red. That is what gives the hooks fixture
# teeth. It substitutes the first match only, which is safe only because the
# anchored call occurs exactly once in the guard — an invariant stated
# positionally above the try in scan_file().

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-external-dispatch.py"

# Plain, uncoloured result lines — unconditionally, matching the harness-parsable
# suites elsewhere in the repo. A result line must start with the literal `PASS:` /
# `FAIL:` so a mutation harness can classify it with `^[[:space:]]*FAIL:[[:space:]]+`;
# an ANSI escape sequence precedes the label and defeats that match. Deciding by
# `[ -t 1 ]` instead would make parsability environment-dependent — run the suite
# under a pty and the colour, and the failure, come back.
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

# ---------------------------------------------------------------------------
# Case 1 — negative control: a bare "cogni-research" noun (no colon) is fine.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/clean/cogni-demo/skills/demo"
cat > "$WORK/clean/cogni-demo/skills/demo/SKILL.md" <<'EOF'
---
name: demo
---
Modeled on the cogni-research verify-report skill, scoped to demo data.
This plugin dispatches cogni-knowledge:knowledge-query, not the retired engines.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/clean" "cogni-demo/skills/demo/SKILL.md" 2>/dev/null)
CODE=$?
set -e
check "ed01 bare-noun negative control exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed02 negative control reports zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 2 — dispatch-laden fixture: must fail, naming file + line + match.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/dirty/cogni-bad/agents"
cat > "$WORK/dirty/cogni-bad/agents/bad.md" <<'EOF'
First the agent dispatches Skill("cogni-wiki:wiki-query") to read the base.
Then it falls back to cogni-research:section-researcher for fresh web work.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/dirty" "cogni-bad/agents/bad.md" 2>/dev/null)
CODE=$?
set -e
check "ed03 dispatch fixture exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ed04 dispatch fixture names both tokens with correct file+line" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
got={(x['match'],x['line']) for x in v}
want={('cogni-wiki:',1),('cogni-research:',2)}
missing=want-got
assert not missing, 'missing: %r (got %r)' % (missing, got)
assert all(x['file']=='cogni-bad/agents/bad.md' for x in v), v
assert d['success'] is False, d
"

# ---------------------------------------------------------------------------
# Case 3 — inline-allow escape hatch skips an otherwise-flagged line.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/allow/cogni-x/commands"
cat > "$WORK/allow/cogni-x/commands/c.md" <<'EOF'
Historical note: this menu mirrors cogni-research:verify-report's Next steps.  # external-dispatch-guard:allow
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/allow" "cogni-x/commands/c.md" 2>/dev/null)
CODE=$?
set -e
check "ed05 inline-allow line exits 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed06 inline-allow suppresses the dispatch token" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 4 — discover-mode path exclusions: a token under cogni-knowledge/ (FMO
# history) or */wiki/ (generated mirror) must NOT trip the guard.
# ---------------------------------------------------------------------------
EXC="$WORK/exclude"
mkdir -p "$EXC"
git -C "$EXC" init -q
git -C "$EXC" config user.email t@t.test
git -C "$EXC" config user.name test
mkdir -p "$EXC/cogni-knowledge/skills/k" "$EXC/cogni-foo/wiki/concepts" "$EXC/cogni-foo/skills/s"
# cogni-knowledge legitimately NAMES the retired engines as history:
printf -- '---\nname: k\n---\nDelegation history: this once dispatched cogni-wiki:wiki-ingest.\n' \
  > "$EXC/cogni-knowledge/skills/k/SKILL.md"
# a generated wiki mirror page may quote a retired dispatch as page content:
printf -- '---\nname: x\n---\nThe source quoted cogni-research:section-researcher.\n' \
  > "$EXC/cogni-foo/wiki/concepts/SKILL.md"
# a genuinely-clean live surface in the same repo:
printf -- '---\nname: s\n---\nDispatches cogni-knowledge:knowledge-compose only.\n' \
  > "$EXC/cogni-foo/skills/s/SKILL.md"
git -C "$EXC" add -A >/dev/null 2>&1
git -C "$EXC" commit -qm init >/dev/null 2>&1

set +e
OUT=$(python3 "$GUARD" --root "$EXC" 2>/dev/null)
CODE=$?
set -e
check "ed07 discover-mode exclusions pass (cogni-knowledge/ + */wiki/ skipped)" \
  "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed08 exclusions report zero violations" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ---------------------------------------------------------------------------
# Case 5 — real tree: the guard passes clean-zero today.
# ---------------------------------------------------------------------------
set +e
python3 "$GUARD" >/dev/null 2>&1
CODE=$?
set -e
check "ed09 real tree passes clean-zero" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

# ===========================================================================
# Registry-loading cases (R1-R6; emitted ids ed10-ed19).
#
# Case labels below are `<id> <description>` — an id token followed by a SPACE,
# never a colon abutting the id. The mutation harness matches
# `^[[:space:]]*FAIL:[[:space:]]+<case>([[:space:]]|$)` (and the ok|PASS twin)
# whole-token, so `--case ed14` matches `FAIL: ed14 empty ...` while `--case 'ed14:'`
# would match neither line and return case_not_found instead of a verdict.
# ===========================================================================

# stage_guard <name> — copy the REAL guard into "$WORK/<name>/" and echo the path.
# A copy, taken at run time, is what makes these cases meaningful under mutation:
# a vendored snippet would keep testing a frozen implementation while the actual
# script drifted. The staged copy's registry default resolves to its own sibling
# "$WORK/<name>/retired-plugins.json", which the caller writes (or deliberately
# omits) per case.
stage_guard() {
  mkdir -p "$WORK/$1"
  cp "$GUARD" "$WORK/$1/check-external-dispatch.py"
  printf '%s' "$WORK/$1/check-external-dispatch.py"
}

# run_reg <name> <registry-json|NONE> <rel-file> [extra guard args...] — stage a
# guard copy, give it (or deny it) a sibling registry, run it, and leave the result
# in $OUT / $CODE. Each case keeps its own check/assert_json label, so the per-case
# `<id> <description>` targeting above is unaffected.
run_reg() {
  local g; g=$(stage_guard "$1")
  [ "$2" = NONE ] || printf '%s' "$2" > "$WORK/$1/retired-plugins.json"
  local rel="$3"; shift 3
  set +e
  OUT=$(python3 "$g" "$@" --root "$REG_TREE" "$rel" 2>/dev/null)
  CODE=$?
  set -e
}

# A clean live surface plus a planted one, shared by R1-R6. The clean file
# deliberately carries an ordinary word-colon token (`name: demo` frontmatter):
# under the empty-registry mutant the compiled alternation degenerates to
# `\b(?:):`, which matches exactly that shape — so R3 goes red because the mutant
# demonstrably fires, not incidentally because nothing was scanned.
REG_TREE="$WORK/regtree"
mkdir -p "$REG_TREE/cogni-demo/agents"
cat > "$REG_TREE/cogni-demo/agents/clean.md" <<'EOF'
---
name: demo
---
Dispatches cogni-knowledge:knowledge-query only.
EOF
cat > "$REG_TREE/cogni-demo/agents/planted.md" <<'EOF'
---
name: planted
---
First the agent dispatches cogni-demo:demo-skill to read the base.
EOF
CLEAN_REL="cogni-demo/agents/clean.md"
PLANTED_REL="cogni-demo/agents/planted.md"

# --- R1: missing registry -> exit 2, never a silent clean-zero -------------
# Also proves the default registry path follows __file__ and not --root: --root
# points at REG_TREE, which has no registry, and the staged dir has none either.
run_reg r1 NONE "$CLEAN_REL"
check "ed10 missing registry exits 2 (base exits 0 here)" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "ed11 missing registry reports success:false and names the path" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
assert 'retired-plugins.json' in d['error'], d['error']
"

# --- R2: malformed JSON -> exit 2 ------------------------------------------
run_reg r2 '{"retired_prefixes": ["cogni-wiki",' "$CLEAN_REL"
check "ed12 malformed registry JSON exits 2 (base exits 0 here)" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
assert_json "ed13 malformed registry reports success:false with a non-empty error" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
"

# --- R3: empty prefix list -> exit 2 ---------------------------------------
# Kept as its own case rather than folded into R4's table: the separately-labelled
# ed14 line makes empty-list anti-vacuity failures independently identifiable.
run_reg r3 '{"retired_prefixes": []}' "$CLEAN_REL"
check "ed14 empty registry exits 2 and never 0 (base exits 0 here)" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"

# --- R4: wrong type / non-string / blank / padded / colon-bearing -> exit 2 -
# The padded variant is the subtlest of the set: it survives the non-empty test
# (it strips to a real prefix) but re.escape would compile the UNSTRIPPED text
# into `\ \ cogni\-demo\ \ :`, which matches nothing — a clean-zero exit 0 from a
# registry that looks populated. Rejecting mirrors the colon-bearing entry rather
# than quietly repairing it.
R4_FAILED=0
R4_N=0
for BAD in \
  '{"retired_prefixes": "cogni-wiki"}' \
  '{"retired_prefixes": ["cogni-wiki", 7]}' \
  '{"retired_prefixes": ["cogni-wiki", "   "]}' \
  '{"retired_prefixes": ["cogni-wiki", "  cogni-demo  "]}' \
  '{"retired_prefixes": ["cogni-wiki:"]}' \
  '{"nothing_here": true}'
do
  R4_N=$((R4_N + 1))
  run_reg "r4_$R4_N" "$BAD" "$CLEAN_REL"
  [ "$CODE" -eq 2 ] || R4_FAILED=1
done
check "ed15 degenerate registry entries all exit 2 ($R4_N variants)" "$R4_FAILED"

# --- R5: a prefix added to the registry makes a planted dispatch fire -------
# The data-driven proof: base's hardcoded regex knows nothing of cogni-demo.
run_reg r5 '{"retired_prefixes": ["cogni-wiki", "cogni-research", "cogni-demo"]}' \
  "$PLANTED_REL"
check "ed16 registry-added prefix fires on a planted dispatch (exit 1)" \
  "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ed17 registry-added prefix reports match cogni-demo: with file+line" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
assert d['success'] is False, d
got={(x['match'],x['line'],x['file']) for x in v}
assert ('cogni-demo:',4,'cogni-demo/agents/planted.md') in got, got
"

# --- R6: --registry REPLACES the default file, never unions with it ---------
# The staged copy's sibling registry lists cogni-demo; the override does not.
# Doubles as the negative control that the compiled alternation is not over-broad.
mkdir -p "$WORK/r6"
printf '%s' '{"retired_prefixes": ["cogni-wiki", "cogni-research"]}' \
  > "$WORK/r6/override.json"
run_reg r6 '{"retired_prefixes": ["cogni-wiki", "cogni-research", "cogni-demo"]}' \
  "$PLANTED_REL" --registry "$WORK/r6/override.json"
check "ed18 --registry replaces the default set rather than unioning (exit 0)" \
  "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
assert_json "ed19 override set reports zero violations on the planted file" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"

# ===========================================================================
# Unresolved-target arm (ed20-ed36). The retired-prefix arm above is driven by
# scripts/retired-plugins.json; this second arm is driven by the marketplace
# manifest of the tree under --root, and reports a <live-plugin>:<slug> token
# whose slug names no skills/<slug>/SKILL.md and no agents/<slug>.md UNDER THE
# PLUGIN ITS OWN PREFIX NAMES — the plugin and the slug resolve as a pair, so a
# real slug owned by a different listed plugin is reported (ed34-ed36).
# ===========================================================================

# --- livetree: two listed plugins, one resolvable skill, one resolvable agent,
# --- and a caller naming one target that does not exist.
LT="$WORK/livetree"
mkdir -p "$LT/.claude-plugin" "$LT/cogni-alpha/skills/alpha-run" \
         "$LT/cogni-alpha/agents" "$LT/cogni-beta/agents"
printf '%s' '{"plugins":[{"name":"cogni-alpha","source":"./cogni-alpha"},{"name":"cogni-beta","source":"./cogni-beta"}]}' \
  > "$LT/.claude-plugin/marketplace.json"
printf -- '---\nname: alpha-run\n---\nA resolvable skill target.\n' \
  > "$LT/cogni-alpha/skills/alpha-run/SKILL.md"
printf -- '---\nname: beta-helper\n---\nA resolvable agent target.\n' \
  > "$LT/cogni-beta/agents/beta-helper.md"
printf -- '---\nname: caller\n---\nDispatches cogni-beta:no-such-thing for the missing step.\nThen cogni-alpha:alpha-run and cogni-beta:beta-helper, both of which resolve.\n' \
  > "$LT/cogni-alpha/agents/caller.md"
printf -- '---\nname: marked\n---\nHistorical: cogni-beta:also-missing was the old entry point.  <!-- external-dispatch-guard:allow -->\n' \
  > "$LT/cogni-alpha/agents/marked.md"
printf -- '---\nname: retired\n---\nDispatches cogni-wiki:wiki-query for the base.\n' \
  > "$LT/cogni-alpha/agents/retired.md"

set +e
OUT=$(python3 "$GUARD" --root "$LT" "cogni-alpha/agents/caller.md" 2>/dev/null)
CODE=$?
set -e
check "ed20 unresolvable live-plugin dispatch exits 1" \
  "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"

assert_json "ed21 unresolved-target violation names file line match and target" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
assert d['success'] is False, d
assert d['data']['summary']['total']==1, d['data']['summary']
o=v[0]
assert o['file']=='cogni-alpha/agents/caller.md', o
assert o['line']==4, o
assert o['match']=='cogni-beta:no-such-thing', o
assert o['target']=='no-such-thing', o
"

# ed22 attributes the produced finding to the unresolved-target arm rather than
# the retired-prefix arm. Its positive-finding shape makes that attribution
# observable; a case asserting only a clean zero would not.
assert_json "ed22 the finding is attributed to the unresolved-target arm" "$OUT" "
import json,sys
d=json.load(sys.stdin)
arms=[o['arm'] for o in d['data']['violations']]
assert 'unresolved-target' in arms, arms
"

assert_json "ed23 a dispatch resolving to a skill directory is not reported" "$OUT" "
import json,sys
d=json.load(sys.stdin)
m=[o['match'] for o in d['data']['violations']]
assert 'cogni-alpha:alpha-run' not in m, m
"

assert_json "ed24 a dispatch resolving to an agent file is not reported" "$OUT" "
import json,sys
d=json.load(sys.stdin)
m=[o['match'] for o in d['data']['violations']]
assert 'cogni-beta:beta-helper' not in m, m
"

# --- livetree2: identical shape, every dispatch resolvable (negative control).
LT2="$WORK/livetree2"
mkdir -p "$LT2/.claude-plugin" "$LT2/cogni-alpha/skills/alpha-run" \
         "$LT2/cogni-alpha/agents" "$LT2/cogni-beta/agents"
cp "$LT/.claude-plugin/marketplace.json" "$LT2/.claude-plugin/marketplace.json"
cp "$LT/cogni-alpha/skills/alpha-run/SKILL.md" "$LT2/cogni-alpha/skills/alpha-run/SKILL.md"
cp "$LT/cogni-beta/agents/beta-helper.md" "$LT2/cogni-beta/agents/beta-helper.md"
printf -- '---\nname: caller\n---\nDispatches cogni-alpha:alpha-run and cogni-beta:beta-helper only.\n' \
  > "$LT2/cogni-alpha/agents/caller.md"

set +e
OUT=$(python3 "$GUARD" --root "$LT2" "cogni-alpha/agents/caller.md" 2>/dev/null)
CODE=$?
printf '%s' "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"
JCODE=$?
set -e
check "ed25 an all-resolvable tree exits 0 with zero violations" \
  "$([ "$CODE" -eq 0 ] && [ "$JCODE" -eq 0 ] && echo 0 || echo 1)"

set +e
OUT=$(python3 "$GUARD" --root "$LT" "cogni-alpha/agents/retired.md" 2>/dev/null)
CODE=$?
set -e
assert_json "ed26 a retired-prefix dispatch is still reported by its own arm" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
assert d['data']['summary']['total']==1, d['data']['summary']
assert v[0]['arm']=='retired-prefix', v[0]
assert v[0]['match']=='cogni-wiki:', v[0]
"

# --- ed27: the two arms partition the token space. A name that is BOTH
# --- marketplace-listed and registry-retired is adjudicated by the retired arm
# --- alone, never counted twice. The real tree cannot exercise this: its
# --- retired set and its marketplace names are already disjoint.
printf '%s' '{"retired_prefixes": ["cogni-wiki", "cogni-alpha"]}' > "$WORK/overlap.json"
set +e
OUT=$(python3 "$GUARD" --root "$LT" --registry "$WORK/overlap.json" \
      "cogni-alpha/agents/caller.md" 2>/dev/null)
CODE=$?
set -e
assert_json "ed27 an overlapping name is judged by the retired arm alone" "$OUT" "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
alpha=[o for o in v if o['match'].startswith('cogni-alpha')]
assert len(alpha)==1, alpha
assert alpha[0]['arm']=='retired-prefix', alpha[0]
assert not [o for o in v if o['arm']=='unresolved-target' and o['match'].startswith('cogni-alpha')], v
"

# --- ed28: an ABSENT manifest degrades explicitly. It must never read as a
# --- clean pass that silently examined nothing.
set +e
OUT=$(python3 "$GUARD" --root "$WORK/clean" "cogni-demo/skills/demo/SKILL.md" 2>/dev/null)
CODE=$?
printf '%s' "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
s=d['data']['scanned']
assert s['degraded_reason']=='no-marketplace-manifest', s
assert s['unresolved_target_arm'] is False, s
assert s['live_plugins']==0, s
"
JCODE=$?
set -e
check "ed28 an absent marketplace manifest degrades and says so" \
  "$([ "$CODE" -eq 0 ] && [ "$JCODE" -eq 0 ] && echo 0 || echo 1)"

# --- ed29: a manifest that is PRESENT but malformed is a hard error, not a
# --- degrade. Absence is a tree without the input; corruption is a broken one.
BMF="$WORK/badmanifest"
mkdir -p "$BMF/.claude-plugin" "$BMF/cogni-alpha/agents"
printf '%s' '{"plugins": [' > "$BMF/.claude-plugin/marketplace.json"
printf -- '---\nname: c\n---\nDispatches cogni-alpha:whatever here.\n' \
  > "$BMF/cogni-alpha/agents/c.md"
set +e
OUT=$(python3 "$GUARD" --root "$BMF" "cogni-alpha/agents/c.md" 2>/dev/null)
CODE=$?
printf '%s' "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['error'], d
assert 'marketplace' in d['error'], d['error']
"
JCODE=$?
set -e
check "ed29 a malformed marketplace manifest exits 2 and never 0" \
  "$([ "$CODE" -eq 2 ] && [ "$JCODE" -eq 0 ] && echo 0 || echo 1)"

set +e
OUT=$(python3 "$GUARD" --root "$LT" "cogni-alpha/agents/caller.md" 2>/dev/null)
CODE=$?
set -e
assert_json "ed30 the scanned block reports a non-zero examined count" "$OUT" "
import json,sys
d=json.load(sys.stdin)
s=d['data']['scanned']
for k in ('files','tokens','live_plugins','resolvable_targets'):
    assert isinstance(s[k], int), (k, s)
assert isinstance(s['unresolved_target_arm'], bool), s
assert isinstance(s['degraded_reason'], str), s
assert s['files']>0 and s['tokens']>0, s
# 5 = alpha-run (skill) + beta-helper, caller, marked, retired (agents).
# The caller files are themselves agents, so they resolve too — that is the
# index doing exactly what it claims, not an over-count.
assert s['live_plugins']==2 and s['resolvable_targets']==5, s
"

# --- ed31: the discover-mode exclusions cover the new arm too. This fixture
# --- puts the unresolvable token under */wiki/ on a path that the
# --- */skills/*/SKILL.md pathspec DOES match (a git glob's * crosses /), so the
# --- file is genuinely discovered and then suppressed by the segment rule.
LXC="$WORK/livexc"
mkdir -p "$LXC/.claude-plugin"
git -C "$LXC" init -q 2>/dev/null || { mkdir -p "$LXC"; git -C "$LXC" init -q; }
git -C "$LXC" config user.email t@t.test
git -C "$LXC" config user.name test
mkdir -p "$LXC/cogni-knowledge/skills/k" "$LXC/cogni-foo/wiki/skills/w" "$LXC/cogni-foo/skills/s"
printf '%s' '{"plugins":[{"name":"cogni-knowledge","source":"./cogni-knowledge"},{"name":"cogni-foo","source":"./cogni-foo"}]}' \
  > "$LXC/.claude-plugin/marketplace.json"
printf -- '---\nname: k\n---\nHistory: this named cogni-foo:no-such-thing once.\n' \
  > "$LXC/cogni-knowledge/skills/k/SKILL.md"
printf -- '---\nname: w\n---\nMirror page quoting cogni-foo:no-such-thing verbatim.\n' \
  > "$LXC/cogni-foo/wiki/skills/w/SKILL.md"
printf -- '---\nname: s\n---\nDispatches cogni-foo:s only, which resolves.\n' \
  > "$LXC/cogni-foo/skills/s/SKILL.md"
git -C "$LXC" add -A >/dev/null 2>&1
git -C "$LXC" commit -qm init >/dev/null 2>&1

set +e
OUT=$(python3 "$GUARD" --root "$LXC" 2>/dev/null)
CODE=$?
printf '%s' "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['data']['summary']['total']==0, d['data']['violations']
assert d['data']['scanned']['files']>0, d['data']['scanned']
"
JCODE=$?
set -e
check "ed31 discover-mode exclusions cover the unresolved-target arm" \
  "$([ "$CODE" -eq 0 ] && [ "$JCODE" -eq 0 ] && echo 0 || echo 1)"

set +e
OUT=$(python3 "$GUARD" --root "$LT" "cogni-alpha/agents/caller.md" 2>/dev/null)
CODE=$?
set -e
assert_json "ed32 the summary block keeps exactly its original keys" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert set(d['data']['summary'])=={'total','by_plugin','files_affected'}, sorted(d['data']['summary'])
assert 'scanned' in d['data'], sorted(d['data'])
"

# --- ed33: the per-line escape hatch suppresses the new arm as well. It is
# --- read before either arm runs, so a marked line is invisible to both.
set +e
OUT=$(python3 "$GUARD" --root "$LT" "cogni-alpha/agents/marked.md" 2>/dev/null)
CODE=$?
printf '%s' "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"
JCODE=$?
set -e
check "ed33 the allow marker suppresses an unresolved-target finding" \
  "$([ "$CODE" -eq 0 ] && [ "$JCODE" -eq 0 ] && echo 0 || echo 1)"

# --- ed34/ed35: the arm resolves the PLUGIN and the SLUG as a pair. A token
# --- naming a real slug owned by a DIFFERENT listed plugin is a cross-plugin
# --- miswire and must be reported, even though the slug exists in the tree.
# --- Deliberately its own tree, never $LT: ed21 hard-asserts summary.total==1
# --- and ed30 hard-asserts live_plugins==2 / resolvable_targets==5 against $LT,
# --- so planting a target there would flip two verdicts this change must keep.
LT3="$WORK/livetree3"
mkdir -p "$LT3/.claude-plugin" "$LT3/cogni-beta/skills/beta-only" \
         "$LT3/cogni-alpha/agents"
printf '%s' '{"plugins":[{"name":"cogni-alpha","source":"./cogni-alpha"},{"name":"cogni-beta","source":"./cogni-beta"}]}' \
  > "$LT3/.claude-plugin/marketplace.json"
printf -- '---\nname: beta-only\n---\nA skill owned by cogni-beta and by nobody else.\n' \
  > "$LT3/cogni-beta/skills/beta-only/SKILL.md"
printf -- '---\nname: xcaller\n---\nDispatches cogni-alpha:beta-only, whose slug cogni-beta owns.\nThen cogni-beta:beta-only and cogni-alpha:xcaller, both correctly paired.\n' \
  > "$LT3/cogni-alpha/agents/xcaller.md"

set +e
OUT=$(python3 "$GUARD" --root "$LT3" "cogni-alpha/agents/xcaller.md" 2>/dev/null)
CODE=$?
set -e
# ed34 is the recorded mutation-recipe case for the pair binding (see the recipe
# in this file's header). It asserts the arm PRODUCED the cross-plugin finding,
# so loosening the gate back to a global lookup empties the arm and reds it.
assert_json "ed34 a slug owned by another listed plugin is reported as unresolved" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['summary']['total']==1, d['data']['summary']
o=d['data']['violations'][0]
assert o['file']=='cogni-alpha/agents/xcaller.md', o
assert o['line']==4, o
assert o['match']=='cogni-alpha:beta-only', o
assert o['target']=='beta-only', o
assert o['arm']=='unresolved-target', o
"
check "ed35 the cross-plugin miswire exits 1" \
  "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
# Attribution control: the redness above is the mis-pairing, not a broken tree.
assert_json "ed36 correctly paired tokens in the same tree are examined and cleared" "$OUT" "
import json,sys
d=json.load(sys.stdin)
# All three tokens must be COUNTED — that is what separates 'the paired tokens
# resolved' from 'the regex stopped matching them', which the absence checks
# below cannot tell apart on their own.
assert d['data']['scanned']['tokens']==3, d['data']['scanned']
matches=[o['match'] for o in d['data']['violations']]
assert 'cogni-beta:beta-only' not in matches, matches
assert 'cogni-alpha:xcaller' not in matches, matches
"

# --- ed37-ed39: the scripts surface is discovered. Everything here runs in
# --- DISCOVER mode (no explicit file argument) on purpose: collect() takes the
# --- explicit-files branch whenever one is passed, skipping discover_files()
# --- and therefore DEFAULT_GLOBS entirely — so an explicit-file case would pass
# --- byte-identically at base and prove nothing about the widening. This is its
# --- own git-initialized tree; the non-git fixtures above cannot be discovered
# --- at all, and the shared ones carry hard equality assertions a new file flips.
SXC="$WORK/scriptsxc"
mkdir -p "$SXC/.claude-plugin"
git -C "$SXC" init -q
git -C "$SXC" config user.email t@t.test
git -C "$SXC" config user.name test
mkdir -p "$SXC/cogni-foo/skills/s" "$SXC/cogni-foo/scripts"
printf '%s' '{"plugins":[{"name":"cogni-foo","source":"./cogni-foo"}]}' \
  > "$SXC/.claude-plugin/marketplace.json"
printf -- '---\nname: s\n---\nThe only resolvable target in this tree.\n' \
  > "$SXC/cogni-foo/skills/s/SKILL.md"
# The dangling token lives ONLY here, in a shell script — the shape that was
# structurally invisible before the widening. The slash-command line is the AC3
# negative control: it carries no colon, so it is never dispatch-shaped.
printf -- '#!/usr/bin/env bash\nadd_action "cogni-foo:no-such-thing" "dangling"\n# Prose: run /copywrite to polish the report.\n' \
  > "$SXC/cogni-foo/scripts/helper.sh"
printf -- '#!/usr/bin/env python3\n"""Dispatches cogni-foo:s, which resolves."""\n' \
  > "$SXC/cogni-foo/scripts/tool.py"
# Undecodable bytes directly under scripts/ — NOT under __pycache__, so this
# fixture falsifies a bare */scripts/* glob AND a __pycache__-only exclude.
# The extension-scoped globs never discover it, so no assertion here can go red
# on it today: it is a regression fence against a future widening, not a file
# the guard actively skips. The ed37 recipe in the header is what gives it teeth.
printf '\377\376\000\001' > "$SXC/cogni-foo/scripts/blob.bin"
# The head incident as filed, placement and extension included: the two files
# that prompted this were tracked under cogni-portfolio-evals/scripts/__pycache__/
# as *.cpython-314.pyc, and have since been removed from the index. A git
# pathspec *.py does not match a *.pyc suffix, so the extension-scoped globs
# would never discover that shape either — which is the property ed37's exit 1
# pins.
mkdir -p "$SXC/cogni-foo/scripts/__pycache__"
printf '\377\376\000\001' > "$SXC/cogni-foo/scripts/__pycache__/mod.cpython-314.pyc"
git -C "$SXC" add -A >/dev/null 2>&1
git -C "$SXC" commit -qm init >/dev/null 2>&1

set +e
OUT=$(python3 "$GUARD" --root "$SXC" 2>/dev/null)
CODE=$?
set -e
# Exit 1 also proves nothing discovered here hit scan_file()'s decode path,
# which exits 2 — so exit 1 is incompatible with blob.bin having been read.
check "ed37 a dangling token in a */scripts/*.sh file is discovered and flagged (exit 1, so nothing hit the decode path)" \
  "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
assert_json "ed38 the finding names the scripts file, the unresolved arm and the token" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['summary']['total']==1, d['data']['violations']
o=d['data']['violations'][0]
assert o['file']=='cogni-foo/scripts/helper.sh', o
assert o['arm']=='unresolved-target', o
assert o['match']=='cogni-foo:no-such-thing', o
"
# tokens: scan_file increments tokens_examined for EVERY target_re match, before
# the resolvability gate — so helper.sh's unresolved token and tool.py's
# resolvable cogni-foo:s contribute one each, while the SKILL.md and the
# colonless /copywrite prose line contribute none. Without this count the case
# could not tell 'the slash command was correctly ignored' from 'the file was
# never read'. files==3 is the positive pin that blob.bin was never discovered.
assert_json "ed39 both script extensions are examined and the slash-command prose contributes no token" "$OUT" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['scanned']['files']==3, d['data']['scanned']
assert d['data']['scanned']['tokens']==2, d['data']['scanned']
"

# --- ed40-ed41: the clean-tree controls. This tree carries NO violation, which
# --- is what lets ed40 assert total==0 — the fixture above cannot, since its
# --- whole point is to produce a finding.
SXC2="$WORK/scriptsxc2"
mkdir -p "$SXC2/.claude-plugin"
git -C "$SXC2" init -q
git -C "$SXC2" config user.email t@t.test
git -C "$SXC2" config user.name test
mkdir -p "$SXC2/cogni-foo/skills/s" "$SXC2/cogni-foo/scripts" "$SXC2/cogni-knowledge/scripts"
printf '%s' '{"plugins":[{"name":"cogni-foo","source":"./cogni-foo"},{"name":"cogni-knowledge","source":"./cogni-knowledge"}]}' \
  > "$SXC2/.claude-plugin/marketplace.json"
printf -- '---\nname: s\n---\nNo dispatch token here, so the token count below is attributable to the script.\n' \
  > "$SXC2/cogni-foo/skills/s/SKILL.md"
# AC3 control, co-located as the acceptance bar requires: the colonless slash
# command and a genuinely RESOLVABLE token share one file, and the tree produces
# no finding — so total==0 is the slash command being correctly ignored, while
# tokens>=1 proves the file was actually read rather than skipped.
printf -- '#!/usr/bin/env bash\n# Prose: run /copywrite to polish the report.\nadd_action "cogni-foo:s" "resolves"\n' \
  > "$SXC2/cogni-foo/scripts/clean.sh"
# EXCLUDE_PREFIXES is newly load-bearing under the widened globs: this file
# matches */scripts/*.py and carries a RETIRED-arm token, so without the
# cogni-knowledge/ prefix exclude it would fire. Pinned explicitly rather than
# left to ride on some other case exiting 0.
printf -- '# Vendored engine history: cogni-wiki:wiki-ingest was dispatched here.\n' \
  > "$SXC2/cogni-knowledge/scripts/vendored.py"
git -C "$SXC2" add -A >/dev/null 2>&1
git -C "$SXC2" commit -qm init >/dev/null 2>&1

set +e
OUT2=$(python3 "$GUARD" --root "$SXC2" 2>/dev/null)
set -e
assert_json "ed40 a colonless slash command beside a resolvable token yields no finding on a read file" "$OUT2" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['summary']['total']==0, d['data']['violations']
assert d['data']['scanned']['tokens']>=1, d['data']['scanned']
"
# files==2 is the attribution: cogni-foo/skills/s/SKILL.md and
# cogni-foo/scripts/clean.sh were discovered, while
# cogni-knowledge/scripts/vendored.py matched */scripts/*.py and was dropped by
# EXCLUDE_PREFIXES before scan_file() ever opened it. A third file here would
# mean the exclude stopped holding under the widened globs.
assert_json "ed41 a retired-arm token under cogni-knowledge/scripts is excluded under the widened globs" "$OUT2" "
import json,sys
d=json.load(sys.stdin)
assert d['data']['scanned']['files']==2, d['data']['scanned']
assert d['data']['summary']['total']==0, d['data']['violations']
"

# --- ed42-ed43: the decode policy. A tracked undecodable file under a discovered
# --- */hooks/** surface is a HARD exit 2, by design (#1771). Its OWN git tree, and
# --- discover mode, for the reasons given above ed37 — concretely, ed39 (files==3)
# --- and ed41 (files==2) are hard equalities any new file would flip, and unlike
# --- the extension-scoped scripts globs the hooks globs ARE type-agnostic, so a
# --- binary planted under a shared tree would be discovered and flip them.
HXC="$WORK/hooksxc"
mkdir -p "$HXC/.claude-plugin"
git -C "$HXC" init -q
git -C "$HXC" config user.email t@t.test
git -C "$HXC" config user.name test
mkdir -p "$HXC/cogni-foo/skills/s" "$HXC/cogni-foo/hooks"
# The manifest and the resolvable skill keep the unresolved-target arm ARMED, so
# ed42 asserts exit 2 from a fully-loaded guard rather than a degraded one. The
# binary alone would still be discovered without them.
printf '%s' '{"plugins":[{"name":"cogni-foo","source":"./cogni-foo"}]}' \
  > "$HXC/.claude-plugin/marketplace.json"
printf -- '---\nname: s\n---\nThe only resolvable target in this tree.\n' \
  > "$HXC/cogni-foo/skills/s/SKILL.md"
# Unlike scriptsxc's otherwise-identical blob.bin — parked beside an
# extension-scoped glob that never discovers it — this one IS discovered, which
# is the whole point of the case.
printf '\377\376\000\001' > "$HXC/cogni-foo/hooks/blob.bin"
git -C "$HXC" add -A >/dev/null 2>&1
git -C "$HXC" commit -qm init >/dev/null 2>&1

set +e
OUT3=$(python3 "$GUARD" --root "$HXC" 2>/dev/null)
CODE=$?
set -e
check "ed42 a tracked undecodable file under a discovered hooks/ surface is a hard exit 2" \
  "$([ "$CODE" -eq 2 ] && echo 0 || echo 1)"
# Exit 2 alone does not identify the decode path: eleven other RuntimeError sites
# in the guard render the identical empty-data envelope. Naming the file is the
# discriminator, and because no explicit file was passed, the rel path appearing
# in the error is also the proof that discover_files() reached it. Read it as
# "unreadable", not "undecodable": scan_file() raises the same "cannot read"
# message for OSError, so this pins the policy, not the exception class.
assert_json "ed43 the exit-2 envelope names the undecodable hooks file, discriminating it from the guard's other exit-2 producers" "$OUT3" "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']=={}, d['data']
assert 'cannot read cogni-foo/hooks/blob.bin' in d['error'], d['error']
"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All external-dispatch-guard tests passed."
  exit 0
else
  red "Some external-dispatch-guard tests failed."
  exit 1
fi
