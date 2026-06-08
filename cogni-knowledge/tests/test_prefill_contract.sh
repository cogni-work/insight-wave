#!/usr/bin/env bash
# test_prefill_contract.sh — grep-based contract assertions for the standalone
# foundation-seeding surface: the knowledge-prefill skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-prefill: runs the vendored prefill_foundations.py (resolved
#     vendored-first via resolve_wiki_scripts) against the bound wiki to seed
#     foundation: true concept pages; exposes --filter / --list / --dry-run;
#     reads the binding via knowledge-binding.py; documents the
#     --skip-prefill-prompt opt-in rationale; does NOT dispatch
#     cogni-wiki:wiki-prefill (vendored-native clean break).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-prefill SKILL.md ------------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-prefill/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: skills/knowledge-prefill/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'prefill' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-prefill' "$SRC" "knowledge-prefill: frontmatter name (domain-prefixed)"

# Binding + wiki-root resolution.
assert_grep 'knowledge-binding.py read' "$SRC" "knowledge-prefill: reads the binding via knowledge-binding.py"

# Vendored-first engine resolution.
assert_grep 'resolve_wiki_scripts' "$SRC" "knowledge-prefill: resolves the wiki-prefill script dir via the resolve_wiki_scripts probe"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-prefill/scripts' "$SRC" "knowledge-prefill: names the vendored-first wiki-prefill path"
assert_grep '[Pp]robe.*cogni-wiki' "$SRC" "knowledge-prefill: keeps the cogni-wiki fallback probe"

# Invokes the vendored prefill engine and exposes its CLI surface.
assert_grep 'prefill_foundations.py' "$SRC" "knowledge-prefill: names the vendored prefill_foundations.py engine"
assert_grep 'WIKI_PREFILL_SCRIPTS' "$SRC" "knowledge-prefill: wires resolve_wiki_scripts to the prefill_foundations.py invocation"
assert_grep '\-\-filter' "$SRC" "knowledge-prefill: exposes the --filter set"
assert_grep '\-\-list' "$SRC" "knowledge-prefill: exposes the --list mode"
assert_grep '\-\-dry-run' "$SRC" "knowledge-prefill: exposes the --dry-run mode"

# Documents the deliberate opt-in posture (knowledge-setup skips foundations).
assert_grep 'skip.*prefill' "$SRC" "knowledge-prefill: documents the --skip-prefill-prompt opt-in rationale"

# Clean break: the boundary is documented AND there is no concrete dispatch.
assert_grep 'does not dispatch .cogni-wiki:wiki-prefill' "$SRC" "knowledge-prefill: documents the no-dispatch (vendored-native) boundary"
assert_not_grep 'Skill("cogni-wiki:wiki-prefill' "$SRC" "knowledge-prefill: does NOT dispatch cogni-wiki:wiki-prefill (clean break)"
assert_not_grep 'Skill: cogni-wiki:wiki-prefill' "$SRC" "knowledge-prefill: does NOT dispatch cogni-wiki:wiki-prefill (clean break, prose form)"

if [ "$errors" -eq 0 ]; then
  green "PASS: knowledge-prefill contract"
else
  red "FAIL: knowledge-prefill contract ($errors assertion(s))"
fi
exit "$errors"
