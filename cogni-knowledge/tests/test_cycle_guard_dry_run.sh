#!/usr/bin/env bash
# test_cycle_guard_dry_run.sh - report-don't-gate semantics.
#
# Fixture: direct-cycle scenario (same as test_cycle_guard_direct.sh) but
# invoked with --dry-run. cycle-guard.py must:
#   - status: cycle_detected
#   - success: true (NOT false - dry-run reports without gating)
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
PROJ="$WORK/project-a"

mk_knowledge_base "$KB" test-wiki
mk_research_project "$PROJ" project-a
mk_wiki_page "$KB" concepts page-x project-a
add_wiki_citation "$PROJ" src-1 test-wiki page-x

set +e
OUT=$(python3 "$SCRIPT" \
  --knowledge-root "$KB" \
  --research-slug project-a \
  --research-project-path "$PROJ" \
  --dry-run 2>&1)
RC=$?
set -e

errors=0
if [ $RC -ne 0 ]; then
  red "FAIL: dry-run must exit 0 even on cycle, got $RC"
  errors=$((errors + 1))
fi

if ! echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, f\"dry-run success={d['success']}\"
data = d['data']
assert data['status'] == 'cycle_detected', data['status']
assert len(data['direct_self_cycles']) > 0, 'direct_self_cycles empty'
print('OK')
" 2>/dev/null | grep -q OK; then
  red "FAIL: output did not match dry-run contract"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then exit 1; fi
green "PASS: --dry-run reports cycle_detected with success=true (report-don't-gate)"
