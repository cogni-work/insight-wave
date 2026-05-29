#!/usr/bin/env bash
# test_build_open_questions_payload.sh — contract test for the #354 merge helper
# build_open_questions_payload.py.
#
# Uses a stub lint_wiki.py (prints a fixed {success, data} envelope) so the test
# stays inside cogni-knowledge — the real merge against cogni-wiki's lint is
# covered by the live bake-in. Asserts:
#   a. lint + gaps  → warnings carry both the lint finding and the research gaps;
#      envelope is the standard {success, data, error} shape with meta counts.
#   b. lint only    → no coverage manifest → research_findings == 0, lint kept.
#   c. gaps only    → lint stub FAILS → degraded recorded, gaps still streamed,
#      success still true (fail-soft), exit 0.
#   d. both missing → lint fails + no coverage → empty buckets, degraded, exit 0.
#   e. --no-research-gaps → coverage present but skipped.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"
HELPER="$SCRIPTS_DIR/build_open_questions_payload.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

[ -f "$HELPER" ] || { red "FAIL: $HELPER not found"; exit 1; }

# --- stubs -----------------------------------------------------------------
LINT_OK="$WORK/lint_ok.py"
cat > "$LINT_OK" <<'PY'
import json, sys
print(json.dumps({"success": True, "data": {
    "errors": [], "warnings": [{"class": "no_sources", "page": "pg", "message": "m"}],
    "info": []}}))
PY
LINT_FAIL="$WORK/lint_fail.py"
cat > "$LINT_FAIL" <<'PY'
import json
print(json.dumps({"success": False, "error": "boom"}))
PY

# --- coverage fixture ------------------------------------------------------
PROJ="$WORK/proj"; mkdir -p "$PROJ/.metadata"
printf '{"success": true, "data": {"sub_questions": [{"sq_id":"sq-01","coverage_verdict":"uncovered","covered_pages":[]}]}}' \
  > "$PROJ/.metadata/wiki-coverage.json"
EMPTY="$WORK/empty"; mkdir -p "$EMPTY/.metadata"  # no coverage manifest

# Inspect an envelope: $1 = JSON, $2..= python expr returning bool over `d`
assert_env() { # tag, json, expr, description
  local tag="$1" js="$2" expr="$3" desc="$4" res
  res=$(printf '%s' "$js" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print('OK' if ($expr) else 'BAD')
" 2>/dev/null || echo "ERR")
  if [ "$res" = "OK" ]; then green "PASS: $desc"; else
    red "FAIL: $desc (got $res)"; printf '%s\n' "$js"; errors=$((errors + 1)); fi
}

# a. lint + gaps
OUT=$(python3 "$HELPER" --wiki-root "$WORK/w" --project "$PROJ" --wiki-lint "$LINT_OK")
assert_env a "$OUT" "d['success'] and len(d['data']['warnings'])==2 and d['meta']['lint_findings']==1 and d['meta']['research_findings']==1 and any(w.get('id')=='sq:sq-01' for w in d['data']['warnings']) and any(w.get('page')=='pg' for w in d['data']['warnings'])" "a: lint + gaps merged into warnings"

# b. lint only (no coverage manifest)
OUT=$(python3 "$HELPER" --wiki-root "$WORK/w" --project "$EMPTY" --wiki-lint "$LINT_OK")
assert_env b "$OUT" "d['success'] and d['meta']['research_findings']==0 and len(d['data']['warnings'])==1 and d['meta']['lint_findings']==1" "b: lint only, zero research findings"

# c. gaps only (lint stub fails → degraded, gaps still streamed)
OUT=$(python3 "$HELPER" --wiki-root "$WORK/w" --project "$PROJ" --wiki-lint "$LINT_FAIL")
RC=$?
assert_env c "$OUT" "d['success'] and d['meta']['research_findings']==1 and len(d['meta']['degraded'])>=1 and len(d['data']['warnings'])==1" "c: lint failure degraded, gaps still streamed"
[ "$RC" = "0" ] || { red "FAIL: c exit code should be 0, got $RC"; errors=$((errors + 1)); }

# d. both missing (lint fails + no coverage)
OUT=$(python3 "$HELPER" --wiki-root "$WORK/w" --project "$EMPTY" --wiki-lint "$LINT_FAIL")
assert_env d "$OUT" "d['success'] and d['meta']['lint_findings']==0 and d['meta']['research_findings']==0 and len(d['meta']['degraded'])>=1" "d: both missing → empty buckets, degraded, success true"

# e. --no-research-gaps skips the coverage stream
OUT=$(python3 "$HELPER" --wiki-root "$WORK/w" --project "$PROJ" --wiki-lint "$LINT_OK" --no-research-gaps)
assert_env e "$OUT" "d['meta']['research_findings']==0 and len(d['data']['warnings'])==1" "e: --no-research-gaps skips gaps, keeps lint"

if [ "$errors" -ne 0 ]; then
  red "FAILED: $errors assertion(s)"
  exit 1
fi
green "ALL TESTS PASS"
