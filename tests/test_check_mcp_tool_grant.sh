#!/usr/bin/env bash
# Suite for scripts/check-mcp-tool-grant.py — the repo-scope MCP agent-grant guard.
#
# What is being pinned, and why each case earns its place:
#
#   * All THREE `tools:` frontmatter forms parse as granting. This is the
#     load-bearing one.
#     Measured when this note was pinned: 10 agents declare tools as a YAML
#     block list (the guard re-derives that count every run as
#     `summary.tools_form_counts.block`), and 3 of the 4 agents that carry a
#     real body call site are among them — so a reader that only looks at the
#     `tools:` LINE reports those 3 as false offenders and the guard is red on
#     an otherwise-clean tree.
#     The counts are a snapshot; the form stays load-bearing while any
#     block-form agent carries a call site. B1 fails first if that regresses.
#   * The provides_tools arm keys on a BACKTICK CODE SPAN, and V1/V2 are the
#     both-directions pair that pins it: same body, same vocabulary, backticks
#     the only difference. A matcher that ignored the span requirement passes
#     V1 and reds V2. The arm was ADOPTED to replace a plugin-scoped prose
#     detector that formerly lived in cogni-website/tests/, whose one live
#     instance was cogni-website/agents/hero-renderer.md — an agent that
#     documents driving Pencil with NO `mcp__` token in its body. That agent is
#     GRANTED (six mcp__pencil__* tokens on its bracketed tools: line), so the
#     retired arm's live case was a green "prose-only, must be granted"
#     assertion; the ungranted state is MANUFACTURED by the mutation recipe
#     below. V7 is the case that carries it, through the two in-span names
#     get_guidelines and batch_design, both resolving to pencil.
#   * V4/V4a exercise the multi-owner rules against a fixture only. The real
#     registry carries 18 bare names across 2 servers with ZERO overlap, so
#     those rules are forward-looking and must not be read as reproducing a
#     live collision.
#   * V8 pins that the two arms cannot both report one call site: `\b` will not
#     match a bare name inside `mcp__<ns>__<name>`, since the preceding
#     underscore is a word character.
#   * Disclaiming prose never fires. Agents elsewhere in the tree say "no
#     Excalidraw MCP" while granting something else entirely; P1 pins the
#     shape and P2 pins it against a byte copy of a real disclaiming agent, so
#     the case cannot pass by agreeing with a fixture nobody ships.
#   * The namespace token class admits hyphens. `mcp__claude-in-chrome__navigate`
#     is real, and an [A-Za-z0-9_]-only class matches none of it — the guard
#     would go blind to two agents and a whole namespace. H2/H2a are the cases
#     that red on that, and H1 is NOT: ONE token grammar reads both the grant
#     and the call site, so narrowing the class drops the two together and the
#     ungranted state H1 asserts against never arises. H1 pins the positive
#     round-trip and stays green under the narrowing, which is exactly why the
#     hyphen property needs the ungranted half of the pair rather than H1 alone.
#     Verified by mutation, not assumed.
#   * `desktop_config_key` drives key -> namespace mapping as data. R2 uses a
#     registry key that shares no prefix with its namespace, so an
#     implementation that strips `mcp_` resolves nothing and R2 reds.
#   * Zero discovery is a failure. Z1/Z2 keep an absence result meaning
#     "looked and found nothing wrong" rather than "looked at nothing".
#
# Liveness floors are INEQUALITIES pinned strictly below the values the real
# tree carries today, so a new agent never turns the suite red, while a
# collapsed scan population still does. L4 floors the EXAMINED population of
# the granted-name resolution for that reason and never an observation count —
# see the G-series note below.
#
# The G series pins the granted-name completeness channel. It needs a fixture
# case precisely BECAUSE it is non-failing: nothing else in CI reds if it rots,
# the same argument already recorded for R6/R6a. G1a asserts both directions on
# one fixture, since a one-directional case would still pass with the
# membership test inverted. What the suite deliberately does NOT assert is how
# many gaps the real tree carries: asserting zero would turn a non-failing
# channel into a hard CI gate through the back door, and asserting some would
# red the moment someone correctly widens the registry — which is the outcome
# this channel exists to prompt. It would be a live assertion either way today,
# since the real tree carries 9 gaps.
#
# Mutation recipe, transferred from the retired plugin-scoped suite so its
# defect shape stays reproducible:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file cogni-website/agents/hero-renderer.md \
#     --expr 's/^tools: \[.*mcp__pencil__.*\]$/tools: [\"Read\", \"Write\", \"Glob\", \"Bash\"]/m' \
#     --test 'bash tests/test_check_mcp_tool_grant.sh' --case V7
#
# The mutation strips the Pencil grants from the frontmatter while leaving the
# body's Pencil prose and its get_guidelines / batch_design code spans in place
# — the exact shape the retired arm existed to catch, and the one the mcp__ arm
# cannot see. The /m modifier is load-bearing: --expr is fed to `perl -0pi`,
# which slurps the whole file, so without it ^ and $ never bind to the tools:
# line. The substitution is non-global, which is safe because the target file
# carries exactly one `^tools: [` line. V7 is two-directional under it: strip
# the grant and the arm fires (by_arm gains the entry); disable the arm outright
# and the span counter drops to zero. Either way V7 reds, which is what stops
# it from being a vacuous real-tree assertion.
#
# Mutation recipe for the granted-name completeness channel:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-mcp-tool-grant.py \
#     --expr 's/tool not in vocabulary/tool in ()/m' \
#     --test 'bash tests/test_check_mcp_tool_grant.sh' --case G1a
#
# --expr is fed to `perl -0pi` — perl, never sed or ERE — which slurps the whole
# file; this substitution carries no ^/$ anchor, so /m is belt-and-braces here
# rather than load-bearing. The substitution is non-global, which is safe
# because `tool not in vocabulary` occurs exactly once in the guard. That
# uniqueness is why the membership test binds a local `vocabulary` on the
# preceding line: testing `tool not in vocabulary_by_namespace[namespace]`
# directly would still CONTAIN the anchor, and the rewrite would leave
# `tool in ()_by_namespace[namespace]` — a SyntaxError reddening every case
# rather than the one under test, which grades nothing. Never repeat the anchor
# string in a neighbouring comment, for the same reason.
#
# Mutated, the membership test is constantly false and the observation is never
# emitted, so G1a reds on its surfaced direction while the examined-population
# counter — incremented BEFORE the test — keeps L4 green. That is what makes
# the recipe grade the detection rather than the plumbing.
#
# Every assertion below is on an exit status, on a numeric shape, or on JSON
# this repo's own guard emits. None reads the wording of a foreign tool's
# diagnostic: bash and the GNU tools gettext-localize their messages, so a grep
# for an English fragment passes vacuously on a non-English host.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-mcp-tool-grant.py"
REGISTRY_REL="cogni-workspace/references/mcp-git-registry.json"

failures=0
red()   { printf '%s\n' "$1"; }
green() { printf '%s\n' "$1"; }

OUT="$(mktemp)"
REPO_OUT="$(mktemp)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" "$OUT" "$REPO_OUT"' EXIT

CODE=0
run_guard() {  # run_guard <root>
  set +e
  python3 "$GUARD" --root "$1" > "$OUT" 2>/dev/null
  CODE=$?
  set -e
}

check_eq() {  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    green "PASS: $1"
  else
    red "FAIL: $1 (expected $2, got $3)"
    failures=$((failures + 1))
  fi
}

# py_assert <label> <python body over d/s/v> [json-file, default $OUT]
#
# stderr is deliberately NOT suppressed: every assertion below carries a
# diagnostic operand whose only job is to print when it trips, and swallowing
# it would leave a red case in CI showing a label and nothing else.
py_assert() {
  set +e
  python3 - "${3:-$OUT}" <<PYEOF
import json, sys
d = json.load(open(sys.argv[1]))
s = d.get("data", {}).get("summary", {})
v = d.get("data", {}).get("violations", [])
o = d.get("data", {}).get("observations", [])
$2
PYEOF
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    failures=$((failures + 1))
  fi
}

# --- fixture helpers -------------------------------------------------------

# assert_fixture_json <path> — abort the whole suite if a fixture registry the
# helpers just wrote is not parseable JSON.
#
# Not a case, and deliberately not one: a malformed fixture means no case
# standing on that root grades anything, so there is nothing to report a
# verdict about. It aborts for the same reason the guard raises on an
# unreadable registry rather than reporting a clean arm — an absence result
# must mean "looked and found nothing wrong", not "looked at nothing".
#
# It earns its place because the failure it names is otherwise a MISDIAGNOSIS,
# not merely an obscure one. The guard answers an unparseable registry with
# exit 2 and its {"success": false, "data": {}} error envelope, so every
# affected case reds twice over in a shape that points away from the fixture:
# check_eq reports a count off by a constant (every expectation "got 2", the
# exit status, whatever it expected), and py_assert raises KeyError on
# `summary` fields the guard is emitting correctly. Two thirds of the suite
# fails at once looking exactly like guard schema drift. One line naming the
# unparseable file is the difference between reading that as a broken fixture
# and reading it as a broken guard.
#
# The diagnostic goes to STDERR, not through red(). new_root calls the writers
# from inside a `R="$(new_root ...)"` command substitution, which captures
# stdout into the variable — a message printed there would be swallowed whole
# and the abort would surface as a bare `set -e` death with no reason given,
# which is the failure this helper exists to stop happening. stderr is not
# captured, so the line reaches the terminal from either call path. The exit
# likewise ends only the subshell on that path; `set -e` then takes the suite
# down on the failed assignment, which is the intended abort either way.
assert_fixture_json() {
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" 2>/dev/null && return 0
  printf '%s\n' "ABORT: fixture registry is not parseable JSON: $1" >&2
  printf '%s\n' "ABORT: no case standing on this root can grade anything — fix the fixture writer, not the assertions" >&2
  exit 1
}

# write_registry <root> <key> <namespace> <required_by-json-array>
#                [provides_tools-json-array, default ["do_thing"]]
#
# The provides_tools default is load-bearing, and its blast radius was measured
# rather than assumed. Every fixture root gets a registry (new_root writes the
# demo one internally), and an empty vocabulary is an exit-2 error, so without a
# default every case standing on a fixture root would flip to exit 2 — the two
# exceptions being Z1, whose root has no agents and errors earlier, and Z2,
# which deletes the registry outright. The default is also collision-free: no
# existing fixture body contains a backtick at all, so the provides_tools arm
# stays silent across every pre-existing case.
#
# Every default is materialized into a PLAIN VARIABLE before the heredoc, never
# written as a `${5:-...}` default word inside it, and that is portability
# rather than taste. Bash resolves the quoting of a default word differently in
# a here-document than in double quotes, and the two resolutions disagree
# ACROSS BASH VERSIONS. Spelled `${5:-[\"do_thing\"]}` in an unquoted heredoc it
# yields ["do_thing"] under bash 5, which is what CI runs, and the literal
# [\"do_thing\"] under bash 3.2 — the system bash on macOS, which is what
# `#!/usr/bin/env bash` resolves to there. The bare-quote spelling is no better:
# it loses its quotes to the default word's own quote removal on BOTH, emitting
# [do_thing]. Either way the fixture registry stops being JSON on some hosts and
# not others, which is the failure assert_fixture_json above is written to name.
# A variable expansion carries none of that ambiguity: its value is substituted
# verbatim on every bash.
write_registry() {
  local provides
  if [ "$#" -ge 5 ]; then provides="$5"; else provides='["do_thing"]'; fi
  mkdir -p "$1/$(dirname "$REGISTRY_REL")"
  cat > "$1/$REGISTRY_REL" <<REGEOF
{
  "version": "1.0.0",
  "servers": {
    "$2": {
      "name": "$2",
      "desktop_config_key": "$3",
      "required_by": $4,
      "provides_tools": $provides
    }
  }
}
REGEOF
  assert_fixture_json "$1/$REGISTRY_REL"
}

# write_registry_pair <root> <ns-a> <ns-b> <shared-tool> [tools-a] [tools-b]
#
# Two registered servers whose provides_tools arrays SHARE a bare name. The real
# registry has no such overlap (2 servers, 18 names, zero shared), so the
# multi-owner rules are forward-looking; this fixture is the only place they can
# be exercised, and V4/V4a must never be read as reproducing a live collision.
#
# The two arrays default to the shared name plus a private one, which is what
# keeps the multi-owner cases carrying a vocabulary; V6b overrides the second
# to exercise a per-server empty array. Both defaults are built into plain
# variables before the heredoc, for the reason recorded on write_registry
# above, and both key on the ARGUMENT COUNT rather than on the argument being
# non-empty. `[]` would survive an emptiness test too, so that is not the
# difference; the difference is that an argument supplied as the empty string
# then reaches the file as an empty `provides_tools:` value and trips
# assert_fixture_json by name, instead of being quietly swapped for a default
# vocabulary that makes an unwritable case look like a passing one.
write_registry_pair() {
  local tools_a tools_b
  if [ "$#" -ge 5 ]; then tools_a="$5"; else tools_a="[\"$4\", \"only_a\"]"; fi
  if [ "$#" -ge 6 ]; then tools_b="$6"; else tools_b="[\"$4\", \"only_b\"]"; fi
  mkdir -p "$1/$(dirname "$REGISTRY_REL")"
  cat > "$1/$REGISTRY_REL" <<REGEOF
{
  "version": "1.0.0",
  "servers": {
    "mcp_$2": {
      "name": "mcp_$2",
      "desktop_config_key": "$2",
      "required_by": ["plug"],
      "provides_tools": $tools_a
    },
    "mcp_$3": {
      "name": "mcp_$3",
      "desktop_config_key": "$3",
      "required_by": ["plug"],
      "provides_tools": $tools_b
    }
  }
}
REGEOF
  assert_fixture_json "$1/$REGISTRY_REL"
}

# write_agent <root> <plugin> <name> <tools-block> <body>
write_agent() {
  mkdir -p "$1/$2/agents"
  {
    printf '%s\n' "---"
    printf '%s\n' "name: $3"
    printf '%s\n' "description: fixture agent"
    printf '%s\n' "$4"
    printf '%s\n' "---"
    printf '%s\n' ""
    printf '%s\n' "$5"
  } > "$1/$2/agents/$3.md"
}

# new_root <name> -> echoes path. Ships the standard one-server demo registry,
# so a case only calls write_registry when it needs a DIFFERENT vocabulary —
# which keeps the baseline from drifting between cases meant to share it.
new_root() {
  local r="$WORK/$1"
  mkdir -p "$r"
  write_registry "$r" "mcp_demo" "demo" '["plug"]'
  printf '%s' "$r"
}

# --- A: the real tree ------------------------------------------------------

# Scanned once and cached: the fixtures below all live under $WORK, so the real
# tree cannot change mid-suite. Later real-tree assertions read $REPO_OUT
# explicitly rather than depending on which run_guard happened to run last.
run_guard "$REPO_ROOT"
cp "$OUT" "$REPO_OUT"
check_eq "A1 the repository as it stands is clean" "0" "$CODE"
py_assert "A2 the clean result is not vacuous" "
assert s['agents_discovered'] > 0, s
assert s['total'] == 0, v
"

R="$(new_root offender)"
write_agent "$R" "plug" "ungranted" 'tools: [Read, Write]' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "A3 an ungranted body call site is reported" "1" "$CODE"
py_assert "A4 the violation names file, arm and namespace" "
assert s['by_arm'].get('body_call_site_ungranted') == 1, s
f = v[0]
assert f['file'].endswith('ungranted.md'), f
assert f['arm'] == 'body_call_site_ungranted', f
assert f['namespace'] == 'demo', f
"

# --- B: all three tools: forms ---------------------------------------------

R="$(new_root form_block)"
write_agent "$R" "plug" "blocklist" 'tools:
  - Read
  - mcp__demo__do_thing' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B1 a YAML block-list grant is parsed as granting" "0" "$CODE"
py_assert "B1a the block form was actually counted" "
assert s['tools_form_counts']['block'] == 1, s
"

R="$(new_root form_bracket)"
write_agent "$R" "plug" "bracketed" 'tools: ["Read", "mcp__demo__do_thing"]' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B2 a bracketed-array grant is parsed as granting" "0" "$CODE"
py_assert "B2a the bracketed form was actually counted" "
assert s['tools_form_counts']['bracketed'] == 1, s
"

R="$(new_root form_comma)"
write_agent "$R" "plug" "commalist" 'tools: Read, Write, mcp__demo__do_thing' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B3 a bare comma-list grant is parsed as granting" "0" "$CODE"
py_assert "B3a the comma form was actually counted" "
assert s['tools_form_counts']['comma'] == 1, s
"

# A block list written flush-left under `tools:` is valid YAML and the host
# accepts it. If the item anchor demanded indentation the grant would read as
# absent, the agent would drop out of the required_by arm, and the body call
# site below would be reported as a FALSE offender — the guard's own
# invisible-absence class, one level down. Nothing in the tree is written this
# way today, which is exactly why it needs a fixture.
R="$(new_root form_block_flush)"
write_agent "$R" "plug" "flushlist" 'tools:
- Read
- mcp__demo__do_thing' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B5 a flush-left block-list grant is parsed as granting" "0" "$CODE"
py_assert "B5a the flush-left grant was seen, not silently dropped" "
assert s['grant_tokens'] >= 1, s
assert s['tools_form_counts']['block'] == 1, s
"

# The bracketed form may wrap across lines. No agent in the tree does this
# today, so without this fixture the parser's continuation loop never executes
# and could rot unnoticed.
R="$(new_root form_bracket_wrapped)"
write_agent "$R" "plug" "wrapped" 'tools: ["Read",
  "mcp__demo__do_thing"]' \
  'Call mcp__demo__do_thing to render.'
run_guard "$R"
check_eq "B6 a bracketed grant wrapped across lines is parsed as granting" "0" "$CODE"
py_assert "B6a the wrapped grant was seen, not truncated at the first line" "
assert s['grant_tokens'] >= 1, s
assert s['tools_form_counts']['bracketed'] == 1, s
"

# Floors are >= 1, not the counts the tree happens to carry today: pinning the
# stylistic distribution of frontmatter would red the suite the moment anyone
# normalized agents toward one form. That every form PARSES is pinned
# deterministically by B1/B2/B3 against fixtures; this only asserts the real
# tree still exercises each branch at all.
py_assert "B4 every tools: form is still exercised by the real tree" "
c = s['tools_form_counts']
assert c['bracketed'] >= 1, c
assert c['comma'] >= 1, c
assert c['block'] >= 1, c
" "$REPO_OUT"

# --- H: hyphenated namespaces ----------------------------------------------

R="$(new_root hyphen_ok)"
write_registry "$R" "mcp_chrome" "claude-in-chrome" '["plug"]'
write_agent "$R" "plug" "hyphenated" \
  'tools: ["Read", "mcp__claude-in-chrome__navigate"]' \
  'Drive the page with mcp__claude-in-chrome__navigate.'
run_guard "$R"
check_eq "H1 a hyphenated namespace round-trips grant and call site" "0" "$CODE"

R="$(new_root hyphen_bad)"
write_registry "$R" "mcp_chrome" "claude-in-chrome" '["plug"]'
write_agent "$R" "plug" "hyphenated" 'tools: ["Read"]' \
  'Drive the page with mcp__claude-in-chrome__navigate.'
run_guard "$R"
check_eq "H2 a hyphenated namespace call with no grant is reported" "1" "$CODE"
py_assert "H2a the hyphenated namespace survives into the finding" "
assert v[0]['namespace'] == 'claude-in-chrome', v[0]
"

# --- P: disclaiming prose ---------------------------------------------------

R="$(new_root disclaim)"
write_registry "$R" "mcp_excalidraw" "excalidraw" '["plug"]'
write_agent "$R" "plug" "svgonly" 'tools:
  - Read
  - Write' \
  'You craft the SVG directly using clean geometric primitives — no Excalidraw
MCP, no hand-drawn wobble, no external tools. Use it without Excalidraw MCP.'
run_guard "$R"
check_eq "P1 disclaiming prose never fires" "0" "$CODE"

# A byte copy of a real disclaiming agent, so the case cannot pass by agreeing
# with a fixture nobody ships. It disclaims the REGISTERED namespace excalidraw
# in body prose while granting a different namespace via the block-list form,
# so it discriminates on the disclaiming-prose non-firing property and the
# block-list form at once. It is silent on the provides_tools arm too: the
# disclaimer fixtures carry no backticks, and that arm keys on a code span.
R="$(new_root disclaim_real)"
write_registry "$R" "mcp_excalidraw" "excalidraw" '["cogni-workspace"]'
mkdir -p "$R/cogni-workspace/agents"
cp "$REPO_ROOT/cogni-workspace/agents/concept-diagram-svg.md" \
   "$R/cogni-workspace/agents/concept-diagram-svg.md"
run_guard "$R"
check_eq "P2 a real disclaiming agent contributes no violation" "0" "$CODE"
py_assert "P2a the real disclaimer was actually scanned" "
assert s['agents_discovered'] == 1, s
assert s['tools_form_counts']['block'] == 1, s
"

# --- R: the registry required_by arm ---------------------------------------

R="$(new_root reqby_missing)"
write_registry "$R" "mcp_demo" "demo" '["someone-else"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__do_thing"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R1 a granting plugin absent from required_by is reported" "1" "$CODE"
py_assert "R1a the finding is on the required_by arm" "
assert s['by_arm'].get('required_by_missing_plugin') == 1, s
"

# The registry key shares no prefix with its namespace, so an implementation
# that derived the namespace by stripping 'mcp_' would resolve nothing, treat
# the grant as unregistered, and exit 0 — this case reds on that.
R="$(new_root key_as_data)"
write_registry "$R" "zz_totally_unrelated" "demo" '["someone-else"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__do_thing"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R2 desktop_config_key drives the mapping, not the key spelling" "1" "$CODE"
py_assert "R2a the grant resolved to the registry entry" "
assert s['skipped_unregistered'] == 0, s
assert s['by_arm'].get('required_by_missing_plugin') == 1, s
"

R="$(new_root unregistered)"
write_agent "$R" "plug" "other" 'tools: ["mcp__somethingelse__go"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R3 a grant outside the registry is skipped, not reported" "0" "$CODE"
py_assert "R3a the skip was counted rather than silently dropped" "
assert s['skipped_unregistered'] == 1, s
"

R="$(new_root no_tools)"
mkdir -p "$R/plug/agents"
{
  printf '%s\n' "---"
  printf '%s\n' "name: notools"
  printf '%s\n' "---"
  printf '%s\n' ""
  printf '%s\n' "Call mcp__demo__do_thing freely."
} > "$R/plug/agents/notools.md"
run_guard "$R"
check_eq "R4 an agent with no tools: key inherits unrestricted tools" "0" "$CODE"
py_assert "R4a the inheritance skip was counted" "
assert s['skipped_no_tools'] == 1, s
"

py_assert "R5 the real tree's required_by arm is clean over a live vocabulary" "
assert s['by_arm'].get('required_by_missing_plugin', 0) == 0, s
assert s['registered_namespaces'] >= 2, s
" "$REPO_OUT"

# The observations channel is non-failing by design (the arm asserts every
# GRANTING plugin is listed, not the converse), which is precisely why it needs
# a case: an output surface nothing asserts on can rot to garbage while every
# other case stays green.
R="$(new_root listed_no_grant)"
write_registry "$R" "mcp_demo" "demo" '["plug", "ghost"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__do_thing"]' \
  'Body text with no call site.'
run_guard "$R"
check_eq "R6 a plugin listed in required_by that grants nothing is not a violation" "0" "$CODE"
py_assert "R6a it is reported as a non-failing observation instead" "
assert s['total'] == 0, v
# .get(): the observations channel now carries two kinds with different key
# sets, and only this one has a single owning plugin.
names = [(x.get('plugin'), x['namespace'], x['kind']) for x in o]
assert ('ghost', 'demo', 'listed_without_grant') in names, names
assert ('plug', 'demo', 'listed_without_grant') not in names, names
"

# --- V: the provides_tools arm ---------------------------------------------
#
# The arm keys on a registry bare name inside a BACKTICK CODE SPAN. V1/V2 are
# the both-directions pair on that context rule: same body, same vocabulary,
# backticks the only difference. Without V2 a matcher that ignored the span
# requirement entirely would still pass V1.

R="$(new_root pt_span)"
write_agent "$R" "plug" "spanner" 'tools: ["Read"]' 'It calls `do_thing` on the canvas.'
run_guard "$R"
check_eq "V1 a registry tool named in a code span without a grant is reported" "1" "$CODE"
py_assert "V1a the finding names the new arm and the resolved server" "
assert len(v) == 1, v
assert v[0]['arm'] == 'provides_tools_body_name_ungranted', v
assert v[0]['namespace'] == 'demo', v
assert v[0]['file'].endswith('spanner.md'), v
"

R="$(new_root pt_prose)"
write_agent "$R" "plug" "proser" 'tools: ["Read"]' 'It calls do_thing on the canvas.'
run_guard "$R"
check_eq "V2 the same name in plain prose does not fire" "0" "$CODE"
py_assert "V2a and the span population is genuinely zero, not merely unreported" "
assert s['provides_tools_code_span_names'] == 0, s
"

# Resolution is SERVER level: any grant of an owning server satisfies any bare
# name that server provides. A tool-level matcher reds here, and reds the real
# tree too — concept-diagram names bare delete_element while granting four
# other excalidraw tools.
R="$(new_root pt_server_level)"
write_registry "$R" "mcp_demo" "demo" '["plug"]' '["do_thing", "other_thing"]'
write_agent "$R" "plug" "granter" 'tools: ["mcp__demo__other_thing"]' 'It calls `do_thing` here.'
run_guard "$R"
check_eq "V3 granting any tool of the owning server satisfies the bare name" "0" "$CODE"
py_assert "V3a and the name really was seen, so the pass is not vacuous" "
assert s['provides_tools_code_span_names'] >= 1, s
"

# V4/V4a exercise the multi-owner rules. The real registry has NO overlapping
# bare name, so this fixture is the only place they are reachable.
R="$(new_root pt_two_owners)"
write_registry_pair "$R" "alpha" "beta" "shared_tool"
write_agent "$R" "plug" "picksone" 'tools: ["mcp__beta__only_b"]' 'It calls `shared_tool`.'
run_guard "$R"
check_eq "V4 a two-owner name is satisfied by granting either owner" "0" "$CODE"

R="$(new_root pt_two_owners_none)"
write_registry_pair "$R" "alpha" "beta" "shared_tool"
write_agent "$R" "plug" "picksnone" 'tools: ["Read"]' 'It calls `shared_tool`.'
run_guard "$R"
check_eq "V4a granting neither owner reports it once" "1" "$CODE"
py_assert "V4b attributed deterministically to the first owner, not dict order" "
assert len(v) == 1, v
assert v[0]['namespace'] == 'alpha', v
"

# The arm sits after the no-tools skip, so it inherits it. This is what keeps
# the four no-tools agents in the real tree from becoming false offenders.
R="$(new_root pt_no_tools)"
write_agent "$R" "plug" "unrestricted" 'description: no tools key here' 'It calls `do_thing`.'
run_guard "$R"
check_eq "V5 an agent with no tools: key is skipped on this arm too" "0" "$CODE"
py_assert "V5a and it is counted as skipped rather than silently passed" "
assert s['skipped_no_tools'] == 1, s
assert s['provides_tools_code_span_names'] == 0, s
"

# An empty vocabulary is a loud failure on the same channel as Z1/Z2 — a
# collapsed provides_tools must not read as a clean arm.
R="$(new_root pt_empty_vocab)"
# An empty array and an absent key are one code path in the guard
# (`entry.get("provides_tools") or []`), so the helper reaches this state — a
# third inline copy of the registry envelope would be one more place to edit
# when the schema grows.
write_registry "$R" "mcp_demo" "demo" '["plug"]' '[]'
write_agent "$R" "plug" "any" 'tools: ["Read"]' 'Body text.'
run_guard "$R"
check_eq "V6 a registry with no provides_tools is an error, not an empty arm" "2" "$CODE"
py_assert "V6a the error is reported, not swallowed" "
assert d['success'] is False, d
assert d['error'], d
"

# The per-server half of that floor. V6 above collapses the ONLY server, so the
# union check catches it; here server A keeps a real array and only B is empty,
# which is the state that stays green without the per-server raise. One agent
# is necessary and sufficient: collect() calls discover() before load_registry,
# so an agent-less root errors earlier (Z1) and never reaches the floor here.
R="$(new_root pt_one_empty_vocab)"
write_registry_pair "$R" "alpha" "beta" "shared_tool" '["shared_tool"]' '[]'
write_agent "$R" "plug" "any" 'tools: ["mcp__alpha__shared_tool"]' 'Body text.'
run_guard "$R"
check_eq "V6b a single registered server with no provides_tools is an error, not a narrowed vocabulary" "2" "$CODE"
py_assert "V6b1 the per-server gap is reported, not swallowed" "
assert d['success'] is False, d
assert d['error'], d
"

# The two arms cannot both report one call site: \b will not match a bare name
# inside mcp__<ns>__<name>, because the preceding underscore is a word char.
R="$(new_root pt_no_double)"
write_agent "$R" "plug" "doubler" 'tools: ["Read"]' 'It calls `mcp__demo__do_thing` directly.'
run_guard "$R"
py_assert "V8 a name inside an mcp__ token is reported once, by one arm only" "
assert len(v) == 1, v
assert v[0]['arm'] == 'body_call_site_ungranted', v
assert s['provides_tools_code_span_names'] == 0, s
"

py_assert "V7 the real tree is clean on the provides_tools arm over a live span population" "
assert 'provides_tools_body_name_ungranted' not in s['by_arm'], s['by_arm']
assert s['provides_tools_code_span_names'] > 0, s
" "$REPO_OUT"

# --- G: grants outside their server's vocabulary ----------------------------

# The completeness channel keys on GRANT tokens in frontmatter, not on code
# spans, so it reaches names the third arm structurally cannot see. G1a asserts
# both directions on one fixture because a one-directional case would pass with
# the membership test inverted.
R="$(new_root grant_vocab)"
write_registry "$R" "mcp_demo" "demo" '["plug"]' '["do_thing"]'
write_agent "$R" "plug" "any" 'tools: ["mcp__demo__do_thing", "mcp__demo__undeclared_thing"]' 'Body text with no call site.'
run_guard "$R"
check_eq "G1 a grant outside its server's provides_tools is not a violation" "0" "$CODE"
py_assert "G1a a grant outside the vocabulary is surfaced, one inside is not" "
gaps = [x for x in o if x['kind'] == 'granted_outside_vocabulary']
named = [(x['namespace'], x['tool']) for x in gaps]
assert ('demo', 'undeclared_thing') in named, named
assert ('demo', 'do_thing') not in named, named
# One record per gap, carrying the granting agents as evidence rather than
# one record per granting agent.
hit = [x for x in gaps if x['tool'] == 'undeclared_thing']
assert len(hit) == 1, hit
assert hit[0]['plugins'] == ['plug'], hit[0]
assert hit[0]['files'] == ['plug/agents/any.md'], hit[0]
assert s['total'] == 0, s['total']
assert s['provides_tools_grant_names_resolved'] >= 2, s['provides_tools_grant_names_resolved']
"

# An unregistered namespace has no vocabulary to resolve against, so it must not
# flood the channel. The kind-keyed assertion is load-bearing: `plug` grants
# nothing on the demo namespace here, so the required_by loop DOES emit a
# listed_without_grant observation, and that record carries no 'tool' key.
R="$(new_root grant_vocab_unregistered)"
write_agent "$R" "plug" "any" 'tools: ["mcp__somethingelse__go"]' 'Body text.'
run_guard "$R"
check_eq "G2 a grant outside the registry is not resolved against any vocabulary" "0" "$CODE"
py_assert "G2a the unregistered grant is neither examined nor surfaced" "
assert not any(x['kind'] == 'granted_outside_vocabulary' for x in o), o
assert s['provides_tools_grant_names_resolved'] == 0, s['provides_tools_grant_names_resolved']
"

# --- Z: zero discovery is a failure ----------------------------------------

R="$(new_root empty)"
run_guard "$R"
check_eq "Z1 a tree with no agents is an error, not a clean zero" "2" "$CODE"
py_assert "Z1a the error is reported, not swallowed" "
assert d['success'] is False, d
assert d['error'], d
"

R="$(new_root no_registry)"
rm -f "$R/$REGISTRY_REL"   # new_root ships one; this case is about its absence
write_agent "$R" "plug" "any" 'tools: ["Read"]' 'Body text.'
run_guard "$R"
check_eq "Z2 an unreadable registry is an error, not a skipped arm" "2" "$CODE"

# --- L: liveness floors on the real tree -----------------------------------

# Observed 101 agents discovered and 92 `tools:` declarations (68 bracketed,
# 14 comma, 10 block) when these floors were pinned. The previous 100/90 sat
# at 0.99/0.98 of observed, inside ordinary churn: every plugin here carries
# at least 3 agents, so retiring any one of them dropped the population below
# both floors and reddened this arm on a correct tree. 70 and 60 are the
# largest multiples of 5 at or below 0.7x observed — the sizing rule the L4
# floor below already records — and sit inside the 0.56x-0.82x span the other
# floors occupy. The arm stays non-vacuous at that width: the largest
# single-plugin agent population is 26 (17 of them declaring `tools:`) and the
# largest single-plugin tools:-declaring population is 20, so a glob that
# collapsed to one plugin — or to none — still reds.
py_assert "L1 the scan population is still reaching agent files" "
assert s['agents_discovered'] >= 70, s['agents_discovered']
assert sum(s['tools_form_counts'].values()) >= 60, s['tools_form_counts']
" "$REPO_OUT"
# Floors re-derived after cogni-visual's retirement removed its render agents,
# which carried most of the repo's mcp__excalidraw__*/mcp__pencil__* grants:
# grant_tokens fell 130 -> 73 and body_call_sites 23 -> 14. The replacements keep
# the original ~75% margin below observed, so the arm still catches a collapsed
# scan (a broken glob reports zero) without reddening on ordinary churn.
py_assert "L2 grants and body call sites are still being extracted" "
assert s['grant_tokens'] >= 60, s['grant_tokens']
assert s['body_call_sites'] >= 10, s['body_call_sites']
" "$REPO_OUT"
py_assert "L3 the provides_tools vocabulary and span population are still live" "
assert s['provides_tools_vocabulary'] >= 10, s['provides_tools_vocabulary']
assert s['provides_tools_code_span_names'] >= 20, s['provides_tools_code_span_names']
" "$REPO_OUT"
# Observed 55 when this floor was pinned (73 grant tokens, 18 of them on
# unregistered namespaces). 35 is the largest multiple of 5 at or below 0.7x
# observed, the band every floor above already occupies. This floors the
# EXAMINED population deliberately, never an observation count: asserting the
# real tree carries zero gaps would turn a non-failing channel into a hard CI
# gate through the suite, and asserting it carries some would red the moment
# the registry is correctly widened. Either way the arm stays non-vacuous,
# because a collapsed resolution population still reds here.
py_assert "L4 the granted-name resolution population is still live" "
assert s['provides_tools_grant_names_resolved'] >= 35, s['provides_tools_grant_names_resolved']
" "$REPO_OUT"

printf '%s\n' "$failures failed"
[ "$failures" -eq 0 ] || exit 1
