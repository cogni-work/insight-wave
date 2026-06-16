#!/usr/bin/env bash
# Regression test for cogni-consult/skills/consult-dashboard/scripts/generate-dashboard.py
# — the read side of the deliverable dependency-graph engine: stale badges, depends_on
# hints, and the topological "Refresh order" section that shells out to
# deliverable-graph.py refresh-order.
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each fixture
# builds a minimal engagement (consult-project.json + action-fields/<slug>/field.json)
# in a temp directory, runs the generator, and asserts on both the JSON stdout and the
# generated output/dashboard.html.
#
# Coverage:
#   1  no-stale           engagement with dependencies but nothing stale → no stale
#                         badge, a "current" refresh note, depends_on hint rendered
#   2  stale-layers       two stale deliverables in a dependency chain → stale badge +
#                         a "Refresh order" section with two topological layers
#   3  graceful-degrade   stale deliverables whose stale sub-graph has a cycle →
#                         refresh-order errors, so the section is omitted, but the
#                         dashboard still renders with stale badges (no hard failure)
#
# Usage: bash cogni-consult/tests/test_generate_dashboard.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/skills/consult-dashboard/scripts/generate-dashboard.py"
GRAPH="$PLUGIN_DIR/scripts/deliverable-graph.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: generate-dashboard.py not found at $SCRIPT" >&2
  exit 1
fi
if [ ! -f "$GRAPH" ]; then
  echo "FAIL: deliverable-graph.py not found at $GRAPH (refresh-order dependency)" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

run() { python3 "$SCRIPT" "$@"; }

# assert_json <label> <json> <python-bool-expr over variable d (the parsed dict)>
assert_json() {
  local label="$1" js="$2" expr="$3"
  local verdict
  verdict="$(printf '%s' "$js" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print('PASS' if ($expr) else 'FAIL')
" 2>/dev/null)"
  if [ "$verdict" = "PASS" ]; then
    pass "$label"
  else
    fail "$label" "assertion failed over: $js"
  fi
}

# assert_html_has <label> <file> <needle>
assert_html_has() {
  local label="$1" file="$2" needle="$3"
  if [ -f "$file" ] && grep -qF "$needle" "$file"; then
    pass "$label"
  else
    fail "$label" "expected to find '$needle' in $file"
  fi
}

# assert_html_lacks <label> <file> <needle>
assert_html_lacks() {
  local label="$1" file="$2" needle="$3"
  if [ -f "$file" ] && grep -qF "$needle" "$file"; then
    fail "$label" "did not expect '$needle' in $file"
  else
    pass "$label"
  fi
}

# Build a single-field, two-deliverable engagement. The deliverable bodies are
# substituted by the caller so each fixture controls state / lineage_status / edges.
#   seed_engagement <dir> <deliverables-json>
seed_engagement() {
  local dir="$1" delivs="$2"
  mkdir -p "$dir/action-fields/market-evidence"
  cat > "$dir/consult-project.json" <<'EOF'
{
  "slug": "acme",
  "name": "Acme Engagement",
  "key_question": "How do we enter the market?",
  "action_fields": ["market-evidence"],
  "workflow_state": {"scope": "complete"}
}
EOF
  cat > "$dir/action-fields/market-evidence/field.json" <<EOF
{
  "title": "Market evidence",
  "framing": "Size the opportunity.",
  "deliverables": $delivs
}
EOF
}

# --- Fixture 1: dependencies present, nothing stale ------------------------------
D1="$TMPROOT/no-stale"
seed_engagement "$D1" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test", "persona_review": "complete"},
  {"slug": "competitor-map", "title": "Competitor map", "state": "complete", "dt_stage": "test", "persona_review": "complete",
   "depends_on": [{"action_field": "market-evidence", "deliverable": "market-sizing"}]}
]'
OUT1="$(run "$D1")"
HTML1="$D1/output/dashboard.html"
assert_json "1a no-stale success"        "$OUT1" "d['success'] is True"
assert_json "1b no-stale stale_count==0" "$OUT1" "d['data']['stale_count'] == 0"
assert_html_has   "1c depends_on hint rendered" "$HTML1" "depends on"
assert_html_has   "1d current refresh note"     "$HTML1" "All deliverables are current"
assert_html_lacks "1e no stale badge"           "$HTML1" '>stale</span>'

# --- Fixture 2: two stale deliverables in a chain → two refresh layers ------------
D2="$TMPROOT/stale-layers"
seed_engagement "$D2" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test", "persona_review": "complete",
   "lineage_status": {"status": "stale", "reason": "source data updated"}},
  {"slug": "competitor-map", "title": "Competitor map", "state": "complete", "dt_stage": "test", "persona_review": "complete",
   "depends_on": [{"action_field": "market-evidence", "deliverable": "market-sizing"}],
   "lineage_status": {"status": "stale", "reason": "upstream changed"}}
]'
OUT2="$(run "$D2")"
HTML2="$D2/output/dashboard.html"
assert_json "2a stale success"          "$OUT2" "d['success'] is True"
assert_json "2b stale_count==2"         "$OUT2" "d['data']['stale_count'] == 2"
assert_html_has "2c stale badge"        "$HTML2" '>stale</span>'
assert_html_has "2d refresh section"    "$HTML2" "Refresh order"
assert_html_has "2e refresh layer 0"    "$HTML2" "Layer 0"
assert_html_has "2f refresh layer 1"    "$HTML2" "Layer 1"
# next-action recommends refreshing first, ahead of pending/in-progress work
assert_html_has "2g next-action stale"  "$HTML2" "went stale"

# --- Fixture 3: stale sub-graph has a cycle → refresh-order errors → degrade -------
D3="$TMPROOT/graceful"
seed_engagement "$D3" '[
  {"slug": "alpha", "title": "Alpha", "state": "complete", "dt_stage": "test", "persona_review": "complete",
   "depends_on": [{"action_field": "market-evidence", "deliverable": "beta"}],
   "lineage_status": {"status": "stale", "reason": "x"}},
  {"slug": "beta", "title": "Beta", "state": "complete", "dt_stage": "test", "persona_review": "complete",
   "depends_on": [{"action_field": "market-evidence", "deliverable": "alpha"}],
   "lineage_status": {"status": "stale", "reason": "y"}}
]'
OUT3="$(run "$D3")"
HTML3="$D3/output/dashboard.html"
# Dashboard still generates even though refresh-order returns success:false on the cycle.
assert_json "3a degrade success"          "$OUT3" "d['success'] is True"
# refresh is None on a cycle, so stale_count falls back to 0 in the output envelope.
assert_json "3b degrade stale_count==0"   "$OUT3" "d['data']['stale_count'] == 0"
# Stale badges still render (they come from lineage_status directly, not refresh-order)...
assert_html_has   "3c stale badge survives"   "$HTML3" '>stale</span>'
# ...but the Refresh-order section is omitted entirely (graceful degradation).
assert_html_lacks "3d no refresh section"     "$HTML3" "Refresh order"

# --- Fixture 4: chosen_framework surfaced read-only in deliverable rows ------------
# A slug, a combo, and an absent value — the framework cell renders each exactly as
# stored, with absence shown as a dash (legacy deliverables display cleanly).
D4="$TMPROOT/framework"
seed_engagement "$D4" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test", "persona_review": "complete",
   "chosen_framework": "pyramid-principle"},
  {"slug": "options-brief", "title": "Options brief", "state": "in-progress", "dt_stage": "ideate", "persona_review": "pending",
   "chosen_framework": "combo:scqa+pyramid-principle"},
  {"slug": "legacy-note", "title": "Legacy note", "state": "complete", "dt_stage": "test", "persona_review": "complete"}
]'
OUT4="$(run "$D4")"
HTML4="$D4/output/dashboard.html"
assert_json "4a framework success"        "$OUT4" "d['success'] is True"
assert_html_has "4b slug chip rendered"   "$HTML4" '<span class="fw-chip" title="Structuring framework">pyramid-principle</span>'
assert_html_has "4c combo split rendered" "$HTML4" '<span class="fw-chip" title="Structuring framework">scqa + pyramid-principle</span>'
# The legacy deliverable with no chosen_framework renders the empty-cell dash.
assert_html_has "4d absent renders dash"  "$HTML4" '<span class="deliv-fw-empty" title="No framework chosen">'

# --- Summary ----------------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "All generate-dashboard.py read-side tests passed."
  exit 0
else
  echo "$failures assertion(s) failed." >&2
  exit 1
fi
