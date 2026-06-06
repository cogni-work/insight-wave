#!/usr/bin/env bash
# test_lint_contract.sh — grep-based contract assertions for the standalone
# semantic lint surface: the knowledge-lint skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-lint: runs the vendored lint_wiki.py (resolved vendored-first via
#     resolve_wiki_scripts) against the bound wiki; audit-only by default, writes
#     only under --fix (mechanical classes), with --suggest / --dry-run modes;
#     reads the binding via knowledge-binding.py; needs Write in allowed-tools
#     for the --fix path; does NOT dispatch cogni-wiki:wiki-lint (clean break).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-lint SKILL.md ---------------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-lint/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: skills/knowledge-lint/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'lint' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-lint' "$SRC" "knowledge-lint: frontmatter name (domain-prefixed)"

# Write tool is required for the --fix write path.
assert_grep 'allowed-tools:.*Write' "$SRC" "knowledge-lint: Write in allowed-tools (for the --fix write path)"

# Binding + wiki-root resolution.
assert_grep 'knowledge-binding.py read' "$SRC" "knowledge-lint: reads the binding via knowledge-binding.py"

# Vendored-first engine resolution.
assert_grep 'resolve_wiki_scripts' "$SRC" "knowledge-lint: resolves the wiki-lint script dir via the resolve_wiki_scripts probe"
assert_grep 'scripts/vendor/cogni-wiki/skills/wiki-lint/scripts' "$SRC" "knowledge-lint: names the vendored-first wiki-lint path"
assert_grep '[Pp]robe.*cogni-wiki' "$SRC" "knowledge-lint: keeps the cogni-wiki fallback probe"

# Invokes the vendored lint engine and exposes its CLI surface.
assert_grep 'lint_wiki.py' "$SRC" "knowledge-lint: names the vendored lint_wiki.py engine"
assert_grep 'WIKI_LINT_SCRIPTS' "$SRC" "knowledge-lint: wires resolve_wiki_scripts to the lint_wiki.py invocation"
assert_grep '\-\-fix' "$SRC" "knowledge-lint: exposes the --fix repair mode"
assert_grep '\-\-suggest' "$SRC" "knowledge-lint: exposes the --suggest mode"
assert_grep '\-\-dry-run' "$SRC" "knowledge-lint: exposes the --dry-run mode"

# Audit-only-by-default posture (no wiki write unless --fix is passed).
assert_grep 'read-only by default' "$SRC" "knowledge-lint: states the audit-only (read-only by default) posture"

# Clean break: the boundary is documented AND there is no concrete dispatch.
assert_grep 'does not dispatch .cogni-wiki:wiki-lint' "$SRC" "knowledge-lint: documents the no-dispatch (vendored-native) boundary"
assert_not_grep 'Skill("cogni-wiki:wiki-lint' "$SRC" "knowledge-lint: does NOT dispatch cogni-wiki:wiki-lint (clean break)"
assert_not_grep 'Skill: cogni-wiki:wiki-lint' "$SRC" "knowledge-lint: does NOT dispatch cogni-wiki:wiki-lint (clean break, prose form)"

if [ "$errors" -eq 0 ]; then
  green "PASS: knowledge-lint contract"
else
  red "FAIL: knowledge-lint contract ($errors assertion(s))"
fi
exit "$errors"
