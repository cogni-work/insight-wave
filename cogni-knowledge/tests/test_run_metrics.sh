#!/usr/bin/env bash
# test_run_metrics.sh — smoke test for run-metrics.py (B1: per-phase
# timing + cost ledger).
#
# Asserts:
#   1. record appends a row to <project>/.metadata/run-metrics.json and
#      computes elapsed_s from --started-at / --ended-at.
#   2. record honours an explicit --elapsed-s (no timestamps needed).
#   3. record is append-only: two records for the same project keep both rows.
#   4. report sums elapsed_s / cost_estimate_usd / agent_count across rows and
#      orders phases by the canonical pipeline order (plan before finalize even
#      when recorded out of order).
#   5. report on a project with no ledger returns success + ledger_present=false
#      (graceful degradation — never crashes a read).
#   6. record on a project with no .metadata/ returns success:false (no silent
#      write to a non-project path).
#   7. record stores --max-agent-duration-ms in the row, report exposes it in
#      totals (max across phases) + the rendered max_agent_s column, and a row
#      recorded without the flag defaults max_agent_duration_ms to 0.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/run-metrics.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: run-metrics.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

PROJ="$WORK/proj"
mkdir -p "$PROJ/.metadata"

# --- 1. record computes elapsed from timestamps --------------------------
OUT=$(python3 "$SCRIPT" record --project-path "$PROJ" --phase curate \
  --started-at 2026-06-16T16:29:07Z --ended-at 2026-06-16T16:43:14Z \
  --agent-count 3 --cost-usd 0.132)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
r = d['data']['recorded']
assert r['phase'] == 'curate', r
assert r['elapsed_s'] == 847.0, r          # 16:43:14 - 16:29:07 = 847s
assert r['agent_count'] == 3, r
assert r['cost_estimate_usd'] == 0.132, r
print('OK')
" | grep -q OK; then
  green "PASS: record computes elapsed_s from timestamps + stores fields"
else
  red "FAIL: record timestamp/elapsed"; red "  got: $OUT"; errors=$((errors + 1))
fi

# --- 2. record honours explicit --elapsed-s ------------------------------
python3 "$SCRIPT" record --project-path "$PROJ" --phase plan --elapsed-s 44.9 >/dev/null

# --- 3. append-only: both rows present -----------------------------------
LEDGER="$PROJ/.metadata/run-metrics.json"
if python3 -c "
import json
d = json.load(open('$LEDGER'))
assert len(d['phases']) == 2, d
phases = [p['phase'] for p in d['phases']]
assert phases == ['curate', 'plan'], phases   # append order preserved on disk
print('OK')
" | grep -q OK; then
  green "PASS: record is append-only (both rows kept, on-disk insertion order)"
else
  red "FAIL: append-only"; errors=$((errors + 1))
fi

# --- 4. report sums + orders by canonical pipeline order -----------------
REP=$(python3 "$SCRIPT" report --project-path "$PROJ")
if echo "$REP" | python3 -c "
import sys, json
d = json.load(sys.stdin)['data']
t = d['totals']
assert t['elapsed_s'] == 891.9, t          # 847.0 + 44.9
assert t['cost_estimate_usd'] == 0.132, t
assert t['agent_count'] == 3, t
ordered = [p['phase'] for p in d['phases']]
assert ordered == ['plan', 'curate'], ordered   # canonical order, not insertion
assert 'TOTAL' in d['rendered'], d['rendered']
print('OK')
" | grep -q OK; then
  green "PASS: report sums totals + orders phases canonically (plan before curate)"
else
  red "FAIL: report totals/order"; red "  got: $REP"; errors=$((errors + 1))
fi

# --- 5. report on a project with no ledger (graceful) --------------------
EMPTY="$WORK/empty"
mkdir -p "$EMPTY/.metadata"
OUT=$(python3 "$SCRIPT" report --project-path "$EMPTY")
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['ledger_present'] is False, d
assert d['data']['totals']['elapsed_s'] == 0, d
print('OK')
" | grep -q OK; then
  green "PASS: report on no-ledger project degrades gracefully (success, ledger_present=false)"
else
  red "FAIL: no-ledger report"; red "  got: $OUT"; errors=$((errors + 1))
fi

# --- 6. record on a non-project path (no .metadata/) fails cleanly -------
OUT=$(python3 "$SCRIPT" record --project-path "$WORK/nope" --phase plan --elapsed-s 1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
print('OK')
" | grep -q OK; then
  green "PASS: record on a path with no .metadata/ returns success:false"
else
  red "FAIL: non-project record should fail"; red "  got: $OUT"; errors=$((errors + 1))
fi

# --- 7. max_agent_duration_ms: stored in the row + surfaced in report ----
DPROJ="$WORK/dproj"
mkdir -p "$DPROJ/.metadata"
# ingest phase carries the slowest-agent duration; verify phase omits the flag (defaults 0)
python3 "$SCRIPT" record --project-path "$DPROJ" --phase ingest \
  --elapsed-s 300 --agent-count 25 --cost-usd 0.30 --max-agent-duration-ms 42000 >/dev/null
python3 "$SCRIPT" record --project-path "$DPROJ" --phase verify --elapsed-s 60 >/dev/null
DREP=$(python3 "$SCRIPT" report --project-path "$DPROJ")
if echo "$DREP" | python3 -c "
import sys, json
d = json.load(sys.stdin)['data']
# row storage: ingest carries the value, verify defaults to 0
rows = {p['phase']: p for p in d['phases']}
assert rows['ingest']['max_agent_duration_ms'] == 42000, rows['ingest']
assert rows['verify']['max_agent_duration_ms'] == 0, rows['verify']
# totals: max across phases (not a sum)
assert d['totals']['max_agent_duration_ms'] == 42000, d['totals']
# rendered table exposes the column + the per-phase value (42000ms -> 42.0s)
assert 'max_agent_s' in d['rendered'], d['rendered']
assert '42.0' in d['rendered'], d['rendered']
print('OK')
" | grep -q OK; then
  green "PASS: record stores max_agent_duration_ms; report surfaces it (totals max + max_agent_s column); missing flag defaults 0"
else
  red "FAIL: max_agent_duration_ms record/report"; red "  got: $DREP"; errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
