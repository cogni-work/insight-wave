#!/usr/bin/env bash
# test_cycle_guard_direct.sh - direct self-cycle detection.
#
# Fixture: candidate project A cites a wiki page that is itself stamped
# `derived_from_research: A`. cycle-guard.py must:
#   - status: cycle_detected
#   - direct_self_cycles non-empty
#   - cycle_path: [A, A]
#   - exit 1
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/cycle-guard.py"

# shellcheck source=fixtures/_cycle_guard_lib.sh
. "$TESTS_DIR/fixtures/_cycle_guard_lib.sh"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

KB="$WORK/kb"
PROJ="$WORK/project-a"

mk_knowledge_base "$KB" test-wiki
mk_research_project "$PROJ" project-a
# Wiki page derived from project-a (stamped lineage).
mk_wiki_page "$KB" concepts page-x project-a
# Project-a cites that same page - direct cycle.
add_wiki_citation "$PROJ" src-1 test-wiki page-x

set +e
OUT=$(python3 "$SCRIPT" \
  --knowledge-root "$KB" \
  --research-slug project-a \
  --research-project-path "$PROJ" 2>&1)
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
assert d['success'] is False, 'success should be False on wet cycle'
data = d['data']
assert data['status'] == 'cycle_detected', f\"status={data['status']}\"
assert len(data['direct_self_cycles']) > 0, 'direct_self_cycles empty'
assert data['cycle_path'] == ['project-a', 'project-a'], f\"cycle_path={data['cycle_path']}\"
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: output did not match direct-cycle contract"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then exit 1; fi
green "PASS: direct self-cycle detected with cycle_path [project-a, project-a]"
