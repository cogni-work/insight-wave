#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/deliverable-graph.py — the deliverable
# dependency-graph engine (edge schema, validation, cascade, topological refresh).
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each fixture
# builds a minimal engagement (consult-project.json + action-fields/<slug>/field.json)
# in a temp directory, runs a subcommand, and asserts on the resulting JSON.
#
# Coverage:
#   1  validate-clean        valid cross-field depends_on graph (success:true)
#   2  validate-cycle        A->B->A cycle detected as a hard error (success:false)
#   3  validate-dangling     depends_on ref to a missing deliverable (success:false)
#   4  trace-upstream        transitive upstream lineage of a deliverable
#   5  impact-downstream     transitive downstream blast radius of a deliverable
#   6  cascade-stale         flags downstream lineage_status=stale via RMW, preserves siblings
#   7  cascade-idempotent    a second cascade-stale produces no new writes
#   8  refresh-order         currently-stale deliverables grouped into topological layers
#
# Usage: bash cogni-consult/tests/test_deliverable_graph.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/deliverable-graph.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: deliverable-graph.py not found at $SCRIPT" >&2
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

# Build a three-deliverable chain spanning two fields:
#   market-evidence/market-sizing  (root, no deps)
#     <- portfolio-fit/portfolio-screen   (depends on market-sizing)
#        <- go-to-market/gtm-play          (depends on portfolio-screen)
seed_chain() {
  local dir="$1"
  mkdir -p "$dir/action-fields/market-evidence" \
           "$dir/action-fields/portfolio-fit" \
           "$dir/action-fields/go-to-market"
  cat > "$dir/consult-project.json" <<'EOF'
{
  "slug": "acme",
  "name": "Acme Engagement",
  "key_question": "How?",
  "action_fields": ["market-evidence", "portfolio-fit", "go-to-market"],
  "workflow_state": {"scope": "complete"},
  "created": "2026-06-15",
  "updated": "2026-06-15"
}
EOF
  cat > "$dir/action-fields/market-evidence/field.json" <<'EOF'
{
  "slug": "market-evidence",
  "title": "Market Evidence",
  "deliverables": [
    {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"}
  ]
}
EOF
  cat > "$dir/action-fields/portfolio-fit/field.json" <<'EOF'
{
  "slug": "portfolio-fit",
  "title": "Portfolio Fit",
  "deliverables": [
    {"slug": "portfolio-screen", "title": "Portfolio screen", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete",
     "depends_on": [{"action_field": "market-evidence", "deliverable": "market-sizing"}]}
  ]
}
EOF
  cat > "$dir/action-fields/go-to-market/field.json" <<'EOF'
{
  "slug": "go-to-market",
  "title": "Go To Market",
  "deliverables": [
    {"slug": "gtm-play", "title": "GTM play", "state": "in-progress", "dt_stage": "ideate", "producing_route": "consult-design-thinking", "persona_review": "pending",
     "depends_on": [{"action_field": "portfolio-fit", "deliverable": "portfolio-screen"}]}
  ]
}
EOF
}

# ---------------------------------------------------------------------------
# 1  validate-clean
# ---------------------------------------------------------------------------
D1="$TMPROOT/clean"; seed_chain "$D1"
OUT="$(run "$D1" validate)"
assert_json "validate-clean" "$OUT" \
  "d['success'] is True and d['data']['node_count'] == 3 and d['data']['edge_count'] == 2 and not d['data']['cycles'] and not d['data']['dangling']"

# ---------------------------------------------------------------------------
# 2  validate-cycle  (market-sizing now depends on gtm-play -> A->B->C->A)
# ---------------------------------------------------------------------------
D2="$TMPROOT/cycle"; seed_chain "$D2"
cat > "$D2/action-fields/market-evidence/field.json" <<'EOF'
{
  "slug": "market-evidence",
  "title": "Market Evidence",
  "deliverables": [
    {"slug": "market-sizing", "title": "Market sizing", "state": "complete",
     "depends_on": [{"action_field": "go-to-market", "deliverable": "gtm-play"}]}
  ]
}
EOF
OUT="$(run "$D2" validate)"
assert_json "validate-cycle" "$OUT" \
  "d['success'] is False and len(d['data']['cycles']) >= 1 and 'cycle' in d['error']"

# ---------------------------------------------------------------------------
# 3  validate-dangling  (gtm-play depends on a non-existent deliverable)
# ---------------------------------------------------------------------------
D3="$TMPROOT/dangling"; seed_chain "$D3"
cat > "$D3/action-fields/go-to-market/field.json" <<'EOF'
{
  "slug": "go-to-market",
  "title": "Go To Market",
  "deliverables": [
    {"slug": "gtm-play", "title": "GTM play", "state": "in-progress",
     "depends_on": [{"action_field": "portfolio-fit", "deliverable": "does-not-exist"}]}
  ]
}
EOF
OUT="$(run "$D3" validate)"
assert_json "validate-dangling" "$OUT" \
  "d['success'] is False and len(d['data']['dangling']) == 1 and d['data']['dangling'][0]['to'] == 'portfolio-fit/does-not-exist'"

# ---------------------------------------------------------------------------
# 4  trace-upstream  (gtm-play -> portfolio-screen -> market-sizing)
# ---------------------------------------------------------------------------
OUT="$(run "$D1" trace go-to-market/gtm-play)"
assert_json "trace-upstream" "$OUT" \
  "d['success'] is True and set(d['data']['upstream']) == {'portfolio-fit/portfolio-screen', 'market-evidence/market-sizing'} and d['data']['upstream_count'] == 2"

# ---------------------------------------------------------------------------
# 5  impact-downstream  (market-sizing blocks portfolio-screen + gtm-play)
# ---------------------------------------------------------------------------
OUT="$(run "$D1" impact market-evidence/market-sizing)"
assert_json "impact-downstream" "$OUT" \
  "d['success'] is True and set(d['data']['downstream']) == {'portfolio-fit/portfolio-screen', 'go-to-market/gtm-play'} and d['data']['downstream_count'] == 2"

# trace on a missing node is a graceful error
OUT="$(run "$D1" trace market-evidence/nope)"
assert_json "trace-missing-node" "$OUT" \
  "d['success'] is False and 'not found' in d['error']"

# ---------------------------------------------------------------------------
# 6  cascade-stale  (market-sizing changed -> flag downstream, preserve siblings)
# ---------------------------------------------------------------------------
D6="$TMPROOT/cascade"; seed_chain "$D6"
OUT="$(run "$D6" cascade-stale market-evidence/market-sizing --trigger deliverable_update)"
assert_json "cascade-stale-result" "$OUT" \
  "d['success'] is True and set(d['data']['newly_flagged']) == {'portfolio-fit/portfolio-screen', 'go-to-market/gtm-play'} and d['data']['already_stale'] == []"

# the upstream (changed) deliverable itself is NOT flagged
assert_json "cascade-upstream-not-flagged" \
  "$(python3 -c "import json; print(json.dumps(json.load(open('$D6/action-fields/market-evidence/field.json'))))")" \
  "d['deliverables'][0].get('lineage_status') is None"

# a flagged downstream deliverable keeps its sibling fields + gains lineage_status
assert_json "cascade-preserves-siblings" \
  "$(python3 -c "import json; print(json.dumps(json.load(open('$D6/action-fields/portfolio-fit/field.json'))['deliverables'][0]))")" \
  "d['state'] == 'complete' and d['dt_stage'] == 'test' and d['persona_review'] == 'complete' and d['lineage_status']['status'] == 'stale' and d['lineage_status']['trigger'] == 'deliverable_update' and 'market-evidence/market-sizing' in d['lineage_status']['reason']"

# ---------------------------------------------------------------------------
# 7  cascade-idempotent  (re-running flags nothing new)
# ---------------------------------------------------------------------------
OUT="$(run "$D6" cascade-stale market-evidence/market-sizing --trigger deliverable_update)"
assert_json "cascade-idempotent" "$OUT" \
  "d['success'] is True and d['data']['newly_flagged'] == [] and set(d['data']['already_stale']) == {'portfolio-fit/portfolio-screen', 'go-to-market/gtm-play'}"

# ---------------------------------------------------------------------------
# 8  refresh-order  (after the cascade, the two stale deliverables layer
#     portfolio-screen (layer 0) before gtm-play (layer 1))
# ---------------------------------------------------------------------------
OUT="$(run "$D6" refresh-order)"
assert_json "refresh-order" "$OUT" \
  "d['success'] is True and d['data']['stale_count'] == 2 and d['data']['layers'][0] == ['portfolio-fit/portfolio-screen'] and d['data']['layers'][1] == ['go-to-market/gtm-play'] and d['data']['order'] == ['portfolio-fit/portfolio-screen', 'go-to-market/gtm-play']"

# ---------------------------------------------------------------------------
echo
if [ "$failures" -eq 0 ]; then
  echo "All deliverable-graph tests passed."
  exit 0
else
  echo "$failures deliverable-graph test(s) failed." >&2
  exit 1
fi
