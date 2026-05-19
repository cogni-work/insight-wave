#!/usr/bin/env bash
# test_wiki_query_wiki_root.sh — contract-level grep tests for the
# wiki-query --wiki-root invariants that landed in v0.0.41 (#264 Phase 3
# seam for cogni-knowledge:knowledge-query).
#
# wiki-query is a pure LLM skill — there is no script to execute. These greps
# catch the most likely regression class: someone removes the flag from the
# parameter table or reverts Step 1's conditional skip of the cwd walk, and
# knowledge-query silently falls back to cwd-walking (resolving the wrong wiki
# when invoked from a directory that has its own .cogni-wiki/).
#
# Asserted invariants:
#   1. --wiki-root flag row exists in the parameter table.
#   2. Step 1 documents the conditional: if --wiki-root passed, skip the
#      upward cwd walk and use the path directly.
#   3. The override mentions verifying <wiki-root>/.cogni-wiki/config.json exists.
#
# bash 3.2 + stdlib only. Exit non-zero on any missing invariant.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PLUGIN_ROOT/skills/wiki-query/SKILL.md"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SKILL" ]; then
  red "FAIL: skill file not found at $SKILL"
  exit 1
fi

errors=0
assert_grep() {
  local pattern="$1"
  local description="$2"
  if grep -qE "$pattern" "$SKILL"; then
    green "PASS: $description"
  else
    red "FAIL: MISSING: $description"
    red "      pattern: $pattern"
    errors=$((errors + 1))
  fi
}

# 1. Parameter table row.
assert_grep '\| `--wiki-root` \| No \|' \
  "--wiki-root row in parameter table"

# 2. Cwd-walk-skip conditional in Step 1.
assert_grep 'If `--wiki-root` was passed, set `<wiki-root>` to that path and verify' \
  "Step 1 conditional: --wiki-root sets <wiki-root> directly"
assert_grep 'skip the upward cwd walk' \
  "Step 1 explicitly skips upward cwd walk when --wiki-root is set"

# 3. Config-file existence check.
assert_grep '`<wiki-root>/\.cogni-wiki/config\.json` exists' \
  "Step 1 verifies <wiki-root>/.cogni-wiki/config.json exists"

# 4. Orchestrator-callable usage hint — knowledge-query is the named caller.
assert_grep 'cogni-knowledge:knowledge-query' \
  "orchestrator rationale (cogni-knowledge:knowledge-query mention)"

if [ $errors -gt 0 ]; then
  red "$errors invariant(s) missing — see lines above."
  exit 1
fi

green ""
green "All wiki-query --wiki-root contract invariants present."
