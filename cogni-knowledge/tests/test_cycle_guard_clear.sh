#!/usr/bin/env bash
# test_cycle_guard_clear.sh - clear deposit, no cycle.
#
# Fixture: candidate A cites a page derived from another project B. B does
# not cite back into A. cycle-guard.py must:
#   - status: clear
#   - cross_lineage_overlap non-empty (the cited page from B)
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

# Wiki page derived from B.
mk_wiki_page "$KB" concepts page-from-b project-b

# A cites that page (legitimate cross-project use, no cycle).
mk_research_project "$PROJ_A" project-a
add_wiki_citation "$PROJ_A" src-1 test-wiki page-from-b

# B's project exists in the binding but cites nothing wiki-relevant.
mk_research_project "$PROJ_B" project-b
append_binding_entry "$KB" project-b "$PROJ_B" "$PROJ_B/output/report.md"

set +e
OUT=$(python3 "$SCRIPT" \
  --knowledge-root "$KB" \
  --research-slug project-a \
  --research-project-path "$PROJ_A" 2>&1)
RC=$?
set -e

errors=0
if [ $RC -ne 0 ]; then
  red "FAIL: expected exit 0 (clear), got $RC"
  errors=$((errors + 1))
fi

if ! echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
data = d['data']
assert data['status'] == 'clear', data['status']
assert data['direct_self_cycles'] == [], data['direct_self_cycles']
assert data['transitive_self_cycles'] == [], data['transitive_self_cycles']
assert len(data['cross_lineage_overlap']) > 0, 'cross_lineage_overlap empty'
print('OK')
" | grep -q OK; then
  red "FAIL: output did not match clear contract"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then exit 1; fi
green "PASS: legitimate cross-project citation reports status: clear with overlap recorded"
