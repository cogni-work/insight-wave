#!/usr/bin/env bash
# Regression test for cogni-trends/scripts/project-status.sh stale-report
# detection. Pins the script's contract for issue #187:
#
#   1. Mirroring is not drift  — Phase 4.1 of /trend-report writes report_tier
#      back into .metadata/trend-scout-output.json, bumping its mtime. The
#      pre-#187 mtime check fired stale_report on every resume after a report.
#      The post-#187 hash anchor must NOT fire.
#
#   2. Real candidate drift fires — when a candidate id-set or item content
#      actually changes, stale_report must fire with subtype scout_drift, and
#      the action injector must prepend a cogni-trends:trend-report next_action
#      naming the diff (added / removed / changed counts).
#
#   3. Legacy projects stay silent — projects whose report was generated before
#      this fix have no content_hash_at_report anchor; the script must not fall
#      back to the buggy mtime check, so no stale_report is emitted.
#
# Stdlib-only (bash + python3, no pip deps). Sister to test-project-status.sh.
#
# Usage: bash cogni-trends/tests/test-stale-detection.sh
# Exits non-zero on any assertion failure.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/project-status.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: script not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# Helper: hash a scout-output document the same way Phase 4.1 / project-status.sh
# do. Keeps the test independent of the script's internals — if either side
# changes its hashing rule without the other, this test fails loudly.
HASH_HELPER="$TMPROOT/hash.py"
cat > "$HASH_HELPER" <<'PYEOF'
import json, hashlib, sys
def _key(c): return c.get('id') or c.get('title') or ''
def scout_hash(items):
    items_sorted = sorted(items, key=_key)
    return 'sha256:' + hashlib.sha256(
        json.dumps(items_sorted, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    ).hexdigest()
def signature(items):
    sig = {}
    for c in sorted(items, key=_key):
        k = _key(c)
        if not k: continue
        sig[k] = hashlib.sha256(
            json.dumps(c, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
        ).hexdigest()[:12]
    return sig
def vm_sorted(seq, key):
    return sorted(seq or [], key=lambda x: (x.get(key) or '') if isinstance(x, dict) else '')
def vm_hash(vm_doc):
    payload = {
        'investment_themes': vm_sorted(vm_doc.get('investment_themes'), 'theme_id'),
        'solutions':         vm_sorted(vm_doc.get('solutions'),         'solution_id'),
        'blueprints':        vm_sorted(vm_doc.get('blueprints'),        'solution_id'),
    }
    return 'sha256:' + hashlib.sha256(
        json.dumps(payload, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    ).hexdigest()

# CLI: hash.py scout SCOUT_FILE  ->  prints content_hash, signature_json, vm_hash
mode = sys.argv[1]
if mode == 'anchor':
    scout_path, vm_path = sys.argv[2], sys.argv[3]
    items = (json.load(open(scout_path)).get('tips_candidates') or {}).get('items') or []
    vm = json.load(open(vm_path))
    print(json.dumps({
        'content_hash_at_report':     scout_hash(items),
        'value_model_hash_at_report': vm_hash(vm),
        'candidate_signature':        signature(items),
    }))
PYEOF

# ---------------------------------------------------------------------------
# Shared fixture builder — produces a project workspace that has reached
# "complete" phase: scout-output with 4 candidates (one per dimension/horizon
# slot the script checks), value-model with one investment theme, and a
# trend-report file. The hash anchor is then computed and embedded.
# ---------------------------------------------------------------------------
build_project() {
  local proj="$1"
  mkdir -p "$proj/.metadata" "$proj/.logs"

  cat > "$proj/tips-project.json" <<EOF
{
  "project_id": "stale-test",
  "project_slug": "stale-test",
  "project_language": "en",
  "industry": "test",
  "subsector": "test",
  "research_topic": "test"
}
EOF

  cat > "$proj/.metadata/trend-scout-output.json" <<'EOF'
{
  "tips_candidates": {
    "total": 2,
    "items": [
      {"id": "t-001", "title": "First trend",  "dimension": "externe-effekte", "horizon": "act",  "source": "training"},
      {"id": "t-002", "title": "Second trend", "dimension": "neue-horizonte",  "horizon": "plan", "source": "training"}
    ]
  },
  "execution": {"workflow_state": "candidates_agreed"}
}
EOF

  cat > "$proj/tips-value-model.json" <<'EOF'
{
  "investment_themes": [
    {"theme_id": "th-001", "name": "Test theme", "value_chain": ["a", "b"]}
  ],
  "solutions":  [{"solution_id": "s-001", "name": "Sol-A"}],
  "blueprints": [{"solution_id": "s-001", "readiness": 1.0}]
}
EOF

  printf 'tips trend report body\n' > "$proj/tips-trend-report.md"

  # Compute and embed the hash anchor — simulates trend-report Phase 4.1.
  local anchor
  anchor="$(python3 "$HASH_HELPER" anchor "$proj/.metadata/trend-scout-output.json" "$proj/tips-value-model.json")"
  python3 - "$proj/.metadata/trend-scout-output.json" "$anchor" <<'PYEOF'
import json, sys
path, anchor = sys.argv[1], json.loads(sys.argv[2])
doc = json.load(open(path))
doc.update({
    'trend_report_complete': True,
    'trend_report_path': 'tips-trend-report.md',
    'trend_report_generated_at': '2026-04-30T00:00:00Z',
    'report_tier': 'standard',
    'report_target_words': 6000,
    'content_hash_at_report':     anchor['content_hash_at_report'],
    'value_model_hash_at_report': anchor['value_model_hash_at_report'],
    'candidate_signature':        anchor['candidate_signature'],
})
open(path, 'w').write(json.dumps(doc, indent=2))
PYEOF
}

# Helper: extract stale_warnings + next_actions from --health-check output.
extract() {
  python3 -c '
import json, sys
d = json.load(sys.stdin)
print(json.dumps({
    "warnings": d.get("stale_warnings") or [],
    "actions":  d.get("next_actions")   or [],
}))
'
}

run_health() {
  local proj="$1"
  bash "$SCRIPT" "$proj" --health-check 2>/dev/null
}

FAIL_COUNT=0
fail() { echo "FAIL $1" >&2; FAIL_COUNT=$((FAIL_COUNT + 1)); }
ok()   { echo "OK   $1"; }

# ---------------------------------------------------------------------------
# Case 1: Mirroring is not drift.
# After build_project(), simulate the next /trends-resume: the user has done
# nothing, but Phase 4.1 has already mirrored report_tier into the file (which
# we did during build). Just touch the file to bump mtime past the report.
# ---------------------------------------------------------------------------
P1="$TMPROOT/case1-mirroring"
build_project "$P1"
sleep 1
touch "$P1/.metadata/trend-scout-output.json"

OUT="$(run_health "$P1" | extract)"
HAS_STALE="$(echo "$OUT" | python3 -c 'import json,sys; w=json.load(sys.stdin)["warnings"]; print(any(x.get("type")=="stale_report" for x in w))')"
if [ "$HAS_STALE" = "False" ]; then
  ok "case 1 — mirroring did not fire stale_report"
else
  fail "case 1 — stale_report fired even though candidate content is unchanged"
  echo "$OUT" >&2
fi

# ---------------------------------------------------------------------------
# Case 2: Real candidate drift fires + concrete action injected.
# Mutate one candidate's title and add a brand-new candidate so the diff
# reports both a `changed` id and an `added` id.
# ---------------------------------------------------------------------------
P2="$TMPROOT/case2-drift"
build_project "$P2"
python3 - "$P2/.metadata/trend-scout-output.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
doc = json.load(open(path))
items = doc['tips_candidates']['items']
items[0]['title'] = 'First trend (revised)'
items.append({'id': 't-003', 'title': 'Third trend', 'dimension': 'digitale-wertetreiber', 'horizon': 'observe', 'source': 'training'})
doc['tips_candidates']['total'] = len(items)
open(path, 'w').write(json.dumps(doc, indent=2))
PYEOF

OUT="$(run_health "$P2" | extract)"
SUMMARY="$(echo "$OUT" | python3 -c '
import json, sys
d = json.load(sys.stdin)
warns = [w for w in d["warnings"] if w.get("type") == "stale_report"]
acts  = d["actions"]
report_actions = [a for a in acts if a.get("skill") == "cogni-trends:trend-report"]
print(json.dumps({
    "stale_count": len(warns),
    "subtype":     warns[0].get("subtype") if warns else None,
    "added":       warns[0].get("added")   if warns else None,
    "changed":     warns[0].get("changed") if warns else None,
    "first_action_skill":  acts[0].get("skill")  if acts else None,
    "first_action_reason": acts[0].get("reason") if acts else None,
    "report_actions":      report_actions,
}))
')"

# Parse SUMMARY for assertions.
python3 - "$SUMMARY" <<'PYEOF'
import json, sys
s = json.loads(sys.argv[1])
problems = []
if s["stale_count"] < 1:
    problems.append("stale_report did not fire on real drift")
if s["subtype"] != "scout_drift":
    problems.append(f"subtype={s['subtype']!r} (expected 'scout_drift')")
if "t-003" not in (s["added"] or []):
    problems.append(f"added={s['added']!r} (expected to contain 't-003')")
if "t-001" not in (s["changed"] or []):
    problems.append(f"changed={s['changed']!r} (expected to contain 't-001')")
if s["first_action_skill"] != "cogni-trends:trend-report":
    problems.append(f"first action skill={s['first_action_skill']!r} (expected cogni-trends:trend-report)")
reason = s["first_action_reason"] or ""
for fragment in ("1 added", "1 changed", "/trend-report"):
    if fragment not in reason:
        problems.append(f"first action reason missing fragment {fragment!r}: {reason!r}")
if problems:
    print("\n".join("FAIL case 2 — " + p for p in problems), file=sys.stderr)
    sys.exit(1)
print("OK   case 2 — drift fired with subtype=scout_drift, added={t-003}, changed={t-001}")
print("OK   case 2 — concrete cogni-trends:trend-report action prepended naming the diff")
PYEOF
RC=$?
if [ $RC -ne 0 ]; then FAIL_COUNT=$((FAIL_COUNT + 1)); fi

# ---------------------------------------------------------------------------
# Case 3: Legacy project (no anchor) stays silent.
# Build a project, then strip content_hash_at_report and friends from the
# scout-output metadata. Touch the file so its mtime > report mtime.
# ---------------------------------------------------------------------------
P3="$TMPROOT/case3-legacy"
build_project "$P3"
python3 - "$P3/.metadata/trend-scout-output.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
doc = json.load(open(path))
for k in ('content_hash_at_report', 'value_model_hash_at_report', 'candidate_signature'):
    doc.pop(k, None)
open(path, 'w').write(json.dumps(doc, indent=2))
PYEOF
sleep 1
touch "$P3/.metadata/trend-scout-output.json"

OUT="$(run_health "$P3" | extract)"
HAS_STALE="$(echo "$OUT" | python3 -c 'import json,sys; w=json.load(sys.stdin)["warnings"]; print(any(x.get("type")=="stale_report" for x in w))')"
if [ "$HAS_STALE" = "False" ]; then
  ok "case 3 — legacy project (no anchor) stayed silent"
else
  fail "case 3 — stale_report fired on a legacy project (no hash anchor present)"
  echo "$OUT" >&2
fi

if [ $FAIL_COUNT -gt 0 ]; then
  echo
  echo "$FAIL_COUNT case(s) failed" >&2
  exit 1
fi
echo
echo "All stale-detection assertions passed."
