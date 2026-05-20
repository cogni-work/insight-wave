#!/usr/bin/env bash
# test_cycle_guard_not_applicable.sh - web/local mode = no walk needed.
#
# Fixture: candidate project with report_source: web (NOT wiki/hybrid).
# cycle-guard.py must:
#   - status: not_applicable
#   - exit 0
#   - no source walk performed (wiki_pages_cited empty even if sources exist)
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
PROJ="$WORK/project-a"

mk_knowledge_base "$KB" test-wiki
mk_research_project "$PROJ" project-a
# Even though the citation exists, web mode means no walk - the citation
# would create a cycle if walked, but cycle-guard short-circuits.
mk_wiki_page "$KB" concepts page-x project-a
add_wiki_citation "$PROJ" src-1 test-wiki page-x
set_report_source "$PROJ" web

set +e
OUT=$(python3 "$SCRIPT" \
  --knowledge-root "$KB" \
  --research-slug project-a \
  --research-project-path "$PROJ" 2>&1)
RC=$?
set -e

errors=0
if [ $RC -ne 0 ]; then
  red "FAIL: expected exit 0 (not_applicable), got $RC"
  errors=$((errors + 1))
fi

if ! echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
data = d['data']
assert data['status'] == 'not_applicable', data['status']
assert data['wiki_pages_cited'] == [], data['wiki_pages_cited']
assert data['direct_self_cycles'] == [], data['direct_self_cycles']
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: output did not match not_applicable contract"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then exit 1; fi
green "PASS: report_source=web yields status: not_applicable, no walk"
