#!/usr/bin/env bash
# test_cycle_guard_depth_bound.sh - --max-depth 0 disables transitive recursion.
#
# Fixture: same A -> B -> A chain as test_cycle_guard_transitive.sh, but
# invoked with --max-depth 0 (the v0.0.6 behavior - direct cycles only).
# cycle-guard.py must:
#   - status: clear (transitive recursion disabled)
#   - exit 0
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/cycle-guard.py"

. "$TESTS_DIR/fixtures/_cycle_guard_lib.sh"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

KB="$WORK/kb"
PROJ_A="$WORK/project-a"
PROJ_B="$WORK/project-b"

mk_knowledge_base "$KB" test-wiki
mk_wiki_page "$KB" concepts page-from-a project-a
mk_wiki_page "$KB" concepts page-from-b project-b
mk_research_project "$PROJ_A" project-a
add_wiki_citation "$PROJ_A" src-1 test-wiki page-from-b
mk_research_project "$PROJ_B" project-b
add_wiki_citation "$PROJ_B" src-1 test-wiki page-from-a
append_binding_entry "$KB" project-b "$PROJ_B" "$PROJ_B/output/report.md"

set +e
OUT=$(python3 "$SCRIPT" \
  --knowledge-root "$KB" \
  --research-slug project-a \
  --research-project-path "$PROJ_A" \
  --max-depth 0 2>&1)
RC=$?
set -e

errors=0
if [ $RC -ne 0 ]; then
  red "FAIL: expected exit 0 (clear with depth 0), got $RC"
  errors=$((errors + 1))
fi

if ! echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
data = d['data']
assert data['status'] == 'clear', data['status']
assert data['transitive_self_cycles'] == [], data['transitive_self_cycles']
assert data['direct_self_cycles'] == [], data['direct_self_cycles']
assert data['max_depth'] == 0, data['max_depth']
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: output did not match clear-at-depth-0 contract"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then exit 1; fi
green "PASS: --max-depth 0 disables transitive recursion (status: clear)"
