#!/usr/bin/env bash
# MCP declaration hygiene guard: no plugin ships an MCP declaration, and the
# invariants that keep the relocated server's tool names stable still hold.
#
# Why this exists. MCP server declarations used to live in per-plugin
# `.mcp.json` files. That shape has two failure modes, and neither one reports
# itself:
#   - A checked-in declaration asserts machine state the repo cannot guarantee.
#     A plugin-level stdio server is spawned at session start, not lazily on
#     first tool call, so on a machine that never installed it the server fails
#     visibly under /mcp — for every user of the plugin, whether or not they
#     ever render a diagram.
#   - Two plugins declaring the SAME server name is worse than redundant. The
#     client disambiguates the collision by plugin-qualifying one side's tool
#     names (mcp__plugin_<plugin>_<server>__*), which silently dead-matches any
#     `mcp__<server>__.*` PreToolUse matcher. A dead hook matcher throws no
#     error and fails no build; the only evidence is the absence of whatever the
#     hook would have done.
# Declarations therefore moved into `cogni-workspace:install-mcp`, which writes
# them to the user's own config on demand. This suite is what keeps that true —
# nothing else in CI inspects `.mcp.json` presence, the registry's server key,
# or a hook matcher string.
#
# Contract under test:
#   - no cogni-*/.mcp.json exists at any plugin root — the only depth a
#     client loads a plugin-level declaration from, so a file nested deeper
#     is out of scope by glob depth rather than by exclusion
#   - mcp-git-registry.json still maps mcp_excalidraw to the desktop key
#     "excalidraw" — MCP tool names derive from that key, so renaming it breaks
#     every mcp__excalidraw__* tool and both hook matchers at once, silently
#   - both cogni-portfolio and cogni-workspace still carry the PreToolUse matcher
#     mcp__excalidraw__.* — correct only while no plugin re-declares the server
#   - the two copies of concept-mcp-server-map.md stay byte-identical
#   - every hand-maintained mirror of a registry server's required_by names the
#     same plugin set as the registry: the workspace-status probe table, that
#     skill's mcp-registry.md relation line, and the install-mcp plan example
#   - every registry server's mcp-registry.md section agrees with its registry
#     type and desktop_config_key install-mechanism facts
#   - each glob-driven arm proved it had something to look at (liveness floor)
#
# The liveness floor is the load-bearing half of A1. "Zero .mcp.json files
# found" is the pass condition AND what a mis-resolved REPO_ROOT produces, so
# without L1 proving the plugin glob matched real directories, A1 would pass
# hardest exactly when the suite is most broken.
#
# A4-A6 widen the stated scope: this is no longer only a declaration-shape
# guard, it also pins the prose copies of required_by to the registry. The
# reason is the same one behind D1: a fact stored twice drifts one-sidedly and
# nothing reports it. That is not hypothetical here. The cogni-visual
# retirement updated the registry and left all three mirrors naming a retired
# plugin, with every case in this suite still green.
#
# Deliberately NOT asserted: which servers the registry contains, or that any
# server is installed. This is still not an install check. Three more
# exclusions are chosen rather than overlooked:
#   - a server with no registry entry is never compared. claude-in-chrome is
#     one (a manual Chrome-extension install), and it falls out because the
#     arms iterate the REGISTRY and look the prose row up, not the reverse, so
#     no exclusion list is needed to keep it out and none should be added.
#   - the **Skills:** lines in mcp-registry.md carry a different relation
#     (skill names, not plugin names) and have no registry counterpart.
#   - the concept-mcp-server-map.md Plugins column is a fourth mirror of the
#     same fact. It is correct today and is deliberately NOT compared here: D1
#     asserts only that the two wiki copies stay byte-identical to each other,
#     never that either agrees with the registry, so that agreement is an
#     unguarded gap rather than something D1 already covers.
#   - three further mirrors of the same fact are out of this suite's reach and
#     tracked separately: the manage-workspace worked example, and the MCP
#     tables in the repo-root README.md and CLAUDE.md. Guarding a repo-root
#     doc from a plugin's suite is a scope call a human should make, and the
#     README spells plugins as markdown links, which needs a different parse.
#
# Case-label shape follows test-wiki-tree-parity.sh: "PASS: <id> <label>" /
# "FAIL: <id> <label>", ids letter-prefixed and never bare numerals, and never a
# colon after the id. The cogni-service mutation harness classifies a case GREEN
# only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and RED on the matching FAIL:
# form, matching the id as a whole token — so "A1: no plugin ..." would report
# case_not_found instead of a verdict, and the pass() and fail() call sites for
# one case must carry byte-identical label text. Do not restyle these labels and
# do not colour them.
#
# Mutation recipe (verifies A2 is a real assertion, not a vacuous one):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/references/mcp-git-registry.json \
#     --expr 's/"desktop_config_key": "excalidraw"/"desktop_config_key": "sketchpad"/' \
#     --test 'bash cogni-workspace/tests/test-mcp-declaration-hygiene.sh' \
#     --case A2
# Verdict: guard_verified. The search literal occurs once, and the replacement
# ("sketchpad") does not contain it, so the mutant cannot re-satisfy the pattern
# and stay green. Use the cogni-service harness, NOT the different
# scripts/mutation-check.sh that cogni-consult and cogni-portfolio each ship.
#
# A2 is the case to drive, not A1. Mutating A1's own comparison is vacuous: on a
# clean tree `declarations` is 0, so weakening `-eq 0` to `-ge 0` leaves the case
# green and the harness correctly reports vacuous_guard. A1's negative evidence
# comes from M1 below, which mutates the TREE (adds a .mcp.json) rather than the
# assertion — the only mutation that can distinguish "nothing is declared" from
# "nothing was looked at".
#
# Mutation recipe (verifies A4 is a real comparison, not a vacuous one):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/references/mcp-git-registry.json \
#     --expr 's/"required_by": \["cogni-portfolio", "cogni-workspace"\]/"required_by": ["cogni-portfolio", "cogni-workspace", "cogni-marketing"]/' \
#     --test 'bash cogni-workspace/tests/test-mcp-declaration-hygiene.sh' \
#     --case A4
# Verdict: guard_verified. The search literal occurs once (pencil's required_by
# is a different pair) and the replacement appends a plugin before the closing
# bracket, so the mutant cannot re-satisfy the pattern and stay green. The same
# mutant also reds A5 and A6, which is expected (one registry edit desyncs all
# three mirrors at once) and is not a reason for a second recipe. L4-L6 stay
# green throughout, which is what separates a real comparison from a parser
# that stopped seeing rows.
#
# The case ids A4/A5/A6 and L4-L6 are written out as static literals at their
# pass()/fail() call sites, never built in a loop: the handoff preflight
# literal-searches this source for the recipe's --case value with comment lines
# excluded, so an interpolated id replays as case_not_found while the arm
# itself works perfectly.
#
# Mutation recipe (verifies A7 is a real comparison, not a vacuous one):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/references/mcp-git-registry.json \
#     --expr 's/"desktop_config_key": "pencil"/"desktop_config_key": "pencil-mutant"/' \
#     --test 'bash cogni-workspace/tests/test-mcp-declaration-hygiene.sh' \
#     --case A7
# Verdict: guard_verified. The registry drives the lookup, so changing pencil's
# config key makes its prose section unreachable and turns A7 red; L7 remains
# green because the parser still sees both direct server sections.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# MCP_HYGIENE_ROOT is the mutant-root override used by case M1 below. It is
# honoured only when already set, so a normal run always resolves the real tree.
REPO_ROOT="${MCP_HYGIENE_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

REGISTRY_REL="cogni-workspace/references/mcp-git-registry.json"
WIKI_PAGE_REL="wiki/wiki/pages/concept-mcp-server-map.md"
BUNDLED_PAGE_REL="cogni-workspace/wiki/wiki/pages/concept-mcp-server-map.md"
PROBE_TABLE_REL="cogni-workspace/skills/workspace-status/SKILL.md"
RELATION_DOC_REL="cogni-workspace/skills/workspace-status/references/mcp-registry.md"
INSTALL_EXAMPLE_REL="cogni-workspace/skills/install-mcp/SKILL.md"
MATCHER='mcp__excalidraw__.*'

PASSED=0
FAILED=0
pass() { printf '%s\n' "PASS: $1"; PASSED=$((PASSED + 1)); }
fail() { printf '%s\n' "FAIL: $1"; FAILED=$((FAILED + 1)); }

# A missing root is a broken suite, never a clean one.
if [ ! -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]; then
  fail "L0 repo root resolves to a tree with .claude-plugin/marketplace.json"
  printf '%s\n' "  resolved REPO_ROOT=$REPO_ROOT"
  printf '%s\n' "$PASSED passed, $FAILED failed"
  exit 1
fi
pass "L0 repo root resolves to a tree with .claude-plugin/marketplace.json"

# --- liveness floor -------------------------------------------------------
# Each glob-driven arm below proves its scan surface exists before its absence
# check is allowed to mean anything.

plugin_dirs=0
for dir in "$REPO_ROOT"/cogni-*; do
  [ -d "$dir" ] && plugin_dirs=$((plugin_dirs + 1))
done
if [ "$plugin_dirs" -ge 2 ]; then
  pass "L1 plugin directory glob is live"
else
  fail "L1 plugin directory glob is live"
  printf '%s\n' "  matched $plugin_dirs cogni-* directories under $REPO_ROOT, expected at least 2"
fi

# One parse feeds L2, A2 and the mirror arms A4-A6 — two copies of this heredoc
# drifted apart in review (different guards, different redirections) before they
# were merged, so the required_by comparison extends this block rather than
# adding a second one. It always emits exactly ten lines in a fixed order,
# because the bash side reads them positionally: server count, desktop key, then
# a row count and a defect report for each of the three prose mirrors. A pair
# for the relation document's install mechanism follows those eight lines. Each
# surface read is wrapped on its own, so one unreadable mirror reports count 0
# instead of aborting the other two. The registry try/except is unchanged: a
# registry that will not parse still emits only the first two lines, leaving the
# six mirror reads empty, which the guards below normalise to -1 (fail closed).
registry_read="$(python3 -c '
import json, re, sys
try:
    reg = json.load(open(sys.argv[1]))
except Exception:
    print(-1); print(""); sys.exit(0)
servers = reg.get("servers", {})
print(len(servers))
print(servers.get("mcp_excalidraw", {}).get("desktop_config_key", ""))

# One expectation list, built once and reused by all three surfaces. The config
# key falls back to the server name, matching how scripts/check-mcp-tool-grant.py
# normalises the same registry, so the repo keeps one notion of a namespace.
wanted = []
for name in sorted(servers):
    meta = servers[name]
    wanted.append((name,
                   meta.get("desktop_config_key") or name,
                   meta.get("type", ""),
                   sorted(set(meta.get("required_by", [])))))

def norm(text):
    out = []
    for tok in text.split(","):
        tok = tok.strip().strip("`* ")
        if tok:
            out.append(tok)
    return sorted(set(out))

def parse_table(lines):
    rows = {}
    idx = -1
    for ln in lines:
        if not ln.strip().startswith("|"):
            idx = -1
            continue
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        if idx < 0:
            if "Needed by" in cells:
                idx = cells.index("Needed by")
            continue
        if set("".join(cells)) <= set("-: "):
            continue
        if len(cells) <= idx:
            continue
        key = cells[0].strip("`* ")
        if key:
            rows[key] = cells[idx]
    return rows

def parse_sections(lines):
    rows = {}
    cur = None
    for ln in lines:
        if ln.startswith("### "):
            cur = ln[4:].strip().split(" (")[0].strip()
            continue
        if cur is not None:
            m = re.match(r"^- \*\*(?:Needed|Used) by:\*\*(.*)$", ln)
            if m and cur not in rows:
                rows[cur] = m.group(1)
    return rows

def parse_install_sections(lines):
    rows = {}
    cur = None
    for ln in lines:
        if ln.startswith("### "):
            cur = ln[4:].strip().split(" (")[0].strip()
            rows.setdefault(cur, {"type": "", "claimed_key": ""})
            continue
        if cur is None:
            continue
        type_match = re.match(r"^- \*\*Type:\*\*\s*(.+)$", ln)
        if type_match:
            value = type_match.group(1).strip().lower()
            if re.match(r"^git-installed(?:\s|$|\()", value):
                rows[cur]["type"] = "git"
            elif re.match(r"^desktop app with bundled mcp server(?:\s|$|\()", value):
                rows[cur]["type"] = "native"
            else:
                rows[cur]["type"] = "UNRECOGNIZED:" + value
        key_match = re.search(r"`?desktop_config_key`?:\s*`?([A-Za-z0-9_.-]+)`?", ln) if ln.startswith("- ") else None
        if key_match:
            rows[cur]["claimed_key"] = key_match.group(1)
    return {key: value for key, value in rows.items() if value["type"]}

def parse_plan(lines):
    rows = {}
    for ln in lines:
        head, sep, tail = ln.partition("needed by:")
        if not sep:
            continue
        toks = head.split()
        if toks and toks[0] not in rows:
            rows[toks[0]] = tail
    return rows

def report(rows, by_name):
    defects = []
    for name, config_key, registry_type, want in wanted:
        key = name if by_name else config_key
        if key not in rows:
            defects.append("MISSING " + key)
            continue
        got = norm(rows[key])
        if got != want:
            defects.append("MISMATCH " + key + " expected=" + ",".join(want) + " found=" + ",".join(got))
    return "; ".join(defects)

def report_install(rows):
    defects = []
    for name, config_key, registry_type, required_by in wanted:
        if config_key not in rows:
            defects.append("MISSING " + config_key + " section for " + name)
            continue
        got = rows[config_key]
        if got["type"] != registry_type:
            defects.append("MISMATCH " + name + ".type expected=" + registry_type + " found=" + (got["type"] or "MISSING"))
        # When the registry server name differs from its config key, finding the
        # section by config_key makes the heading itself key evidence. When the
        # names are identical, only an explicit prose claim disambiguates them.
        claimed_key = got["claimed_key"] or (config_key if config_key != name else "")
        if not claimed_key:
            defects.append("MISSING " + name + ".desktop_config_key expected=" + config_key)
        elif claimed_key != config_key:
            defects.append("MISMATCH " + name + ".desktop_config_key expected=" + config_key + " found=" + claimed_key)
    return "; ".join(defects)

for path, parse, by_name in ((sys.argv[2], parse_table, False),
                             (sys.argv[3], parse_sections, False),
                             (sys.argv[4], parse_plan, True)):
    try:
        rows = parse(open(path).read().splitlines())
    except Exception:
        rows = None
    if rows is None:
        print(0)
        print("surface unreadable")
    else:
        print(len(rows))
        print(report(rows, by_name))

try:
    install_rows = parse_install_sections(open(sys.argv[3]).read().splitlines())
except Exception:
    install_rows = None
if install_rows is None:
    print(0)
    print("surface unreadable")
else:
    print(len(install_rows))
    print(report_install(install_rows))
' "$REPO_ROOT/$REGISTRY_REL" "$REPO_ROOT/$PROBE_TABLE_REL" "$REPO_ROOT/$RELATION_DOC_REL" "$REPO_ROOT/$INSTALL_EXAMPLE_REL" 2>/dev/null)"
# One pass over the ten lines instead of ten subshell+sed forks over a
# string already in memory. A here-string keeps the loop in this shell, so the
# assignments survive it; a pipe would not.
registry_servers=""; desktop_key=""
probe_rows=""; probe_defects=""
relation_rows=""; relation_defects=""
example_rows=""; example_defects=""
install_rows=""; install_defects=""
mirror_line=0
while IFS= read -r mirror_value; do
  mirror_line=$((mirror_line + 1))
  case "$mirror_line" in
    1) registry_servers="$mirror_value" ;;
    2) desktop_key="$mirror_value" ;;
    3) probe_rows="$mirror_value" ;;
    4) probe_defects="$mirror_value" ;;
    5) relation_rows="$mirror_value" ;;
    6) relation_defects="$mirror_value" ;;
    7) example_rows="$mirror_value" ;;
    8) example_defects="$mirror_value" ;;
    9) install_rows="$mirror_value" ;;
    10) install_defects="$mirror_value" ;;
  esac
done <<< "$registry_read"

[ -n "$registry_servers" ] || registry_servers=-1
[ -n "$probe_rows" ] || probe_rows=-1
[ -n "$relation_rows" ] || relation_rows=-1
[ -n "$example_rows" ] || example_rows=-1
[ -n "$install_rows" ] || install_rows=-1

if [ "$registry_servers" -ge 1 ]; then
  pass "L2 registry parsed at least one server"
else
  fail "L2 registry parsed at least one server"
  printf '%s\n' "  $REGISTRY_REL yielded $registry_servers servers"
fi

matcher_files="$(grep -rl -- "$MATCHER" "$REPO_ROOT"/cogni-*/hooks/hooks.json 2>/dev/null | wc -l | tr -d ' ')"
if [ "$matcher_files" -eq 2 ]; then
  pass "L3 exactly two hooks.json carry the excalidraw matcher"
else
  fail "L3 exactly two hooks.json carry the excalidraw matcher"
  printf '%s\n' "  found $matcher_files, expected 2 — the scan surface moved"
fi

# Liveness floors for the three required_by mirrors. A renamed path or a
# restyled table yields zero parsed rows, which is also what a clean comparison
# looks like from A4-A6 alone — so without these floors those arms would pass
# hardest exactly when the parser had gone blind. The count is every row the
# parser found, not just the registry-backed ones, which is what keeps "the
# parser saw nothing" distinguishable from "this server has no row" (the latter
# is a MISSING defect on the arm, not a floor failure).
#
# The threshold is two, matching L1, because the registry carries two servers:
# a surface that parses down to a single row has lost at least one of them. A1
# would also catch that as a MISSING defect, but it would read as a missing row
# in the document rather than a parser that stopped seeing rows, which is the
# distinction these floors exist to draw.

if [ "$probe_rows" -ge 2 ]; then
  pass "L4 workspace-status probe table parsed at least two rows"
else
  fail "L4 workspace-status probe table parsed at least two rows"
  printf '%s\n' "  $PROBE_TABLE_REL yielded $probe_rows rows — the Needed by column moved or the file was renamed"
fi

if [ "$relation_rows" -ge 2 ]; then
  pass "L5 mcp-registry relation lines parsed at least two servers"
else
  fail "L5 mcp-registry relation lines parsed at least two servers"
  printf '%s\n' "  $RELATION_DOC_REL yielded $relation_rows sections — the ### heading or the Needed by/Used by line shape moved"
fi

if [ "$example_rows" -ge 2 ]; then
  pass "L6 install-mcp plan example parsed at least two rows"
else
  fail "L6 install-mcp plan example parsed at least two rows"
  printf '%s\n' "  $INSTALL_EXAMPLE_REL yielded $example_rows rows — the needed by: separator moved"
fi

if [ "$install_rows" -ge "$registry_servers" ] && [ "$registry_servers" -ge 1 ]; then
  pass "L7 mcp-registry install-mechanism parser saw every registry server"
else
  fail "L7 mcp-registry install-mechanism parser saw every registry server"
  printf '%s\n' "  $RELATION_DOC_REL yielded $install_rows sections for $registry_servers registry servers — the direct ### server heading or Type line shape moved"
fi

# --- A1: no plugin ships an MCP declaration -------------------------------

declarations=0
for f in "$REPO_ROOT"/cogni-*/.mcp.json; do
  [ -f "$f" ] && declarations=$((declarations + 1))
done
if [ "$declarations" -eq 0 ]; then
  pass "A1 no plugin ships a .mcp.json"
else
  fail "A1 no plugin ships a .mcp.json"
  for f in "$REPO_ROOT"/cogni-*/.mcp.json; do
    [ -f "$f" ] && printf '%s\n' "  found ${f#$REPO_ROOT/}"
  done
  printf '%s\n' "  declarations move into cogni-workspace:install-mcp, written to user config on demand"
fi

# --- A2: the registry key MCP tool names derive from ----------------------

if [ "$desktop_key" = "excalidraw" ]; then
  pass "A2 registry maps mcp_excalidraw to desktop key excalidraw"
else
  fail "A2 registry maps mcp_excalidraw to desktop key excalidraw"
  printf '%s\n' "  got '$desktop_key' — tool names derive from this key, so a rename breaks every mcp__excalidraw__* tool"
fi

# --- A3: both surviving PreToolUse matchers survive -----------------------

missing_matcher=""
for plugin in cogni-portfolio cogni-workspace; do
  hooks="$REPO_ROOT/$plugin/hooks/hooks.json"
  if [ ! -f "$hooks" ] || ! grep -q -- "$MATCHER" "$hooks" 2>/dev/null; then
    missing_matcher="$missing_matcher $plugin"
  fi
done
if [ -z "$missing_matcher" ]; then
  pass "A3 both excalidraw hook matchers survive"
else
  fail "A3 both excalidraw hook matchers survive"
  printf '%s\n' "  missing or unmatched in:$missing_matcher"
  printf '%s\n' "  the matcher is correct only while no plugin re-declares the server"
fi

# --- A4/A5/A6: the required_by mirrors agree with the registry ------------
# Each arm iterates the REGISTRY and looks the prose row up, never the reverse.
# Plugin lists compare as sorted SETS, so ordering is free. The rationale for
# the direction, the exclusions it buys, and the static-case-id rule are in the
# header rather than repeated here.
#
# One thing worth restating at the call site, because it is the easiest to undo
# by accident: the three arms are written out separately on purpose. Folding
# them into a loop over their ids would replay as case_not_found at the handoff
# preflight, which literal-searches this source for the recipe case id.

if [ -z "$probe_defects" ]; then
  pass "A4 workspace-status probe table matches registry required_by"
else
  fail "A4 workspace-status probe table matches registry required_by"
  printf '%s\n' "  $probe_defects"
  printf '%s\n' "  $REGISTRY_REL is the source of truth — correct $PROBE_TABLE_REL to match it, never the reverse"
fi

if [ -z "$relation_defects" ]; then
  pass "A5 mcp-registry relation lines match registry required_by"
else
  fail "A5 mcp-registry relation lines match registry required_by"
  printf '%s\n' "  $relation_defects"
  printf '%s\n' "  $REGISTRY_REL is the source of truth — correct $RELATION_DOC_REL to match it, never the reverse"
fi

if [ -z "$example_defects" ]; then
  pass "A6 install-mcp plan example matches registry required_by"
else
  fail "A6 install-mcp plan example matches registry required_by"
  printf '%s\n' "  $example_defects"
  printf '%s\n' "  $REGISTRY_REL is the source of truth — correct $INSTALL_EXAMPLE_REL to match it, never the reverse"
fi

# --- A7: registry install mechanism agrees with mcp-registry prose --------
# The registry supplies every expected server, type and config key; the prose
# is only looked up from those expectations. Registry-less prose therefore
# falls out naturally, with no server allowlist or exclusion to maintain.

if [ -z "$install_defects" ]; then
  pass "A7 mcp-registry install mechanism matches registry type and desktop key"
else
  fail "A7 mcp-registry install mechanism matches registry type and desktop key"
  printf '%s\n' "  $install_defects"
  printf '%s\n' "  $REGISTRY_REL is the source of truth — correct $RELATION_DOC_REL to match it, never the reverse"
fi

# --- D1: the two wiki copies stay byte-identical --------------------------
# No other suite covers this page: test-wiki-tree-parity.sh deliberately does
# not assert tree equality, and test-layering-claim-reconciled.sh pins a named
# allowlist this page is not on.

if [ -f "$REPO_ROOT/$WIKI_PAGE_REL" ] && [ -f "$REPO_ROOT/$BUNDLED_PAGE_REL" ]; then
  if cmp -s "$REPO_ROOT/$WIKI_PAGE_REL" "$REPO_ROOT/$BUNDLED_PAGE_REL"; then
    pass "D1 concept-mcp-server-map.md byte-identical across wiki trees"
  else
    fail "D1 concept-mcp-server-map.md byte-identical across wiki trees"
    printf '%s\n' "  $WIKI_PAGE_REL and $BUNDLED_PAGE_REL diverged"
  fi
else
  fail "D1 concept-mcp-server-map.md byte-identical across wiki trees"
  printf '%s\n' "  one or both copies are missing"
fi

# --- M1: executed negative case for A1 ------------------------------------
# Proves A1 can actually go red. Runs only on a real invocation, never inside
# the mutant child, so it cannot recurse.

if [ -z "${MCP_HYGIENE_ROOT:-}" ]; then
  mutant="$(mktemp -d)"
  trap 'rm -rf "$mutant"' EXIT

  # One list drives both the mkdir and the cp, so a fixture added to the mutant
  # cannot arrive without its parent directory.
  for rel in ".claude-plugin/marketplace.json" \
             "$REGISTRY_REL" \
             "cogni-portfolio/hooks/hooks.json" \
             "cogni-workspace/hooks/hooks.json" \
             "$WIKI_PAGE_REL" \
             "$BUNDLED_PAGE_REL" \
             "$PROBE_TABLE_REL" \
             "$RELATION_DOC_REL" \
             "$INSTALL_EXAMPLE_REL"; do
    mkdir -p "$mutant/$(dirname "$rel")"
    cp "$REPO_ROOT/$rel" "$mutant/$rel"
  done
  # The mutation: reintroduce exactly what this suite forbids.
  printf '%s\n' '{"mcpServers": {"excalidraw": {"command": "bash", "args": ["-c", "start.sh"]}}}' \
    > "$mutant/cogni-portfolio/.mcp.json"

  mutant_out="$(MCP_HYGIENE_ROOT="$mutant" bash "$SCRIPT_DIR/$(basename "$0")" 2>&1)"
  mutant_rc=$?

  if [ "$mutant_rc" -ne 0 ] && printf '%s\n' "$mutant_out" | grep -q '^FAIL: A1 no plugin ships a \.mcp\.json$'; then
    pass "M1 mutant .mcp.json turns A1 red"
  else
    fail "M1 mutant .mcp.json turns A1 red"
    printf '%s\n' "  mutant run exit=$mutant_rc; expected a 'FAIL: A1 ...' line and a non-zero exit"
    printf '%s\n' "$mutant_out" | sed 's/^/    /'
  fi

  # Reuse the isolated fixture for the second negative case after restoring A1.
  # Removing Pencil's prose key claim must make A7 fail closed rather than skip
  # the comparison because the parsed value is empty.
  rm -f "$mutant/cogni-portfolio/.mcp.json"
  if python3 -c '
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = "desktop_config_key: pencil"
if text.count(needle) != 1:
    raise SystemExit(1)
path.write_text(text.replace(needle, "desktop config key omitted", 1))
' "$mutant/$RELATION_DOC_REL"; then
    mutant_out="$(MCP_HYGIENE_ROOT="$mutant" bash "$SCRIPT_DIR/$(basename "$0")" 2>&1)"
    mutant_rc=$?

    if [ "$mutant_rc" -ne 0 ] && printf '%s\n' "$mutant_out" | grep -q '^FAIL: A7 mcp-registry install mechanism matches registry type and desktop key$'; then
      pass "M2 missing prose desktop key turns A7 red"
    else
      fail "M2 missing prose desktop key turns A7 red"
      printf '%s\n' "  mutant run exit=$mutant_rc; expected the exact A7 FAIL line and a non-zero exit"
      printf '%s\n' "$mutant_out" | sed 's/^/    /'
    fi
  else
    fail "M2 missing prose desktop key turns A7 red"
    printf '%s\n' "  fixture mutation could not find exactly one Pencil desktop_config_key claim"
  fi
fi

printf '%s\n' "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ] || exit 1
