#!/usr/bin/env bash
# test_health_contract.sh — grep-based contract assertions for the standalone
# read-only health surface: the knowledge-health skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-health: runs the vendored health.py (resolved vendored-first via
#     resolve_wiki_scripts) against the bound wiki for a read-only structural
#     verdict; reads the binding via knowledge-binding.py; does NOT dispatch
#     cogni-wiki:wiki-health (clean break — native vendored engine).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-health SKILL.md -------------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-health/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: skills/knowledge-health/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'health' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-health' "$SRC" "knowledge-health: frontmatter name (domain-prefixed)"

# Read-only posture — health is a pure audit (no --fix, no wiki writes).
assert_grep 'read-only' "$SRC" "knowledge-health: states the read-only posture"

# Binding + wiki-root resolution.
assert_grep 'knowledge-binding.py read' "$SRC" "knowledge-health: reads the binding via knowledge-binding.py"

# Vendored-first engine resolution.
assert_grep 'resolve_wiki_scripts' "$SRC" "knowledge-health: resolves the wiki-health script dir via the resolve_wiki_scripts probe"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-health/scripts' "$SRC" "knowledge-health: names the vendored-first wiki-health path"
assert_grep '[Pp]robe.*cogni-wiki' "$SRC" "knowledge-health: keeps the cogni-wiki fallback probe"

# Invokes the vendored health engine directly.
assert_grep 'health.py' "$SRC" "knowledge-health: names the vendored health.py engine"
assert_grep 'WIKI_HEALTH_SCRIPTS' "$SRC" "knowledge-health: wires resolve_wiki_scripts to the health.py invocation"

# Clean break: the boundary is documented AND there is no concrete dispatch.
assert_grep 'does not dispatch .cogni-wiki:wiki-health' "$SRC" "knowledge-health: documents the no-dispatch (vendored-native) boundary"
assert_not_grep 'Skill("cogni-wiki:wiki-health' "$SRC" "knowledge-health: does NOT dispatch cogni-wiki:wiki-health (clean break)"
assert_not_grep 'Skill: cogni-wiki:wiki-health' "$SRC" "knowledge-health: does NOT dispatch cogni-wiki:wiki-health (clean break, prose form)"

if [ "$errors" -eq 0 ]; then
  green "PASS: knowledge-health contract"
else
  red "FAIL: knowledge-health contract ($errors assertion(s))"
fi
exit "$errors"
