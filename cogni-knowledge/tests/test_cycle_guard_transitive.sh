#!/usr/bin/env bash
# test_cycle_guard_transitive.sh - transitive self-cycle detection.
#
# Fixture: candidate A cites page derived from B. B's project cites page
# derived from A. cycle-guard.py must:
#   - status: cycle_detected
#   - transitive_self_cycles non-empty
#   - cycle_path: [A, B, A]
#   - exit 1
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

# Wiki page derived from project-a.
mk_wiki_page "$KB" concepts page-from-a project-a
# Wiki page derived from project-b.
mk_wiki_page "$KB" concepts page-from-b project-b

# Project A cites page-from-b (so A -> B in the lineage walk).
mk_research_project "$PROJ_A" project-a
add_wiki_citation "$PROJ_A" src-1 test-wiki page-from-b

# Project B cites page-from-a (so B -> A, closing the cycle A -> B -> A).
mk_research_project "$PROJ_B" project-b
add_wiki_citation "$PROJ_B" src-1 test-wiki page-from-a

# Record B in the binding so cycle-guard walks into it.
append_binding_entry "$KB" project-b "$PROJ_B" "$PROJ_B/output/report.md"

set +e
OUT=$(python3 "$SCRIPT" \
  --knowledge-root "$KB" \
  --research-slug project-a \
  --research-project-path "$PROJ_A" 2>&1)
RC=$?
set -e

errors=0
if [ $RC -ne 1 ]; then
  red "FAIL: expected exit 1 (cycle_detected), got $RC"
  errors=$((errors + 1))
fi

if ! echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False
data = d['data']
assert data['status'] == 'cycle_detected', data['status']
assert len(data['transitive_self_cycles']) > 0, 'transitive_self_cycles empty'
# direct_self_cycles must be empty - the chain closes through B, not directly.
assert data['direct_self_cycles'] == [], data['direct_self_cycles']
assert data['cycle_path'] == ['project-a', 'project-b', 'project-a'], data['cycle_path']
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: output did not match transitive-cycle contract"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then exit 1; fi
green "PASS: transitive self-cycle detected with cycle_path [project-a, project-b, project-a]"
