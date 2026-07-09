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
#   9  validate-inferred     unrecorded sources[]-derived edge surfaced, success stays true
#  10  impact-default        declared graph only — inferred dependent not counted
#  11  impact-include-inferred   --include-inferred folds the unrecorded dependent in
#  12  cascade-default       status-quo silent-zero-dependents (no flag, flags nothing)
#  13  cascade-include-inferred  --include-inferred flags the unrecorded dependent stale
#  14  inferred-graceful     no artifact .md -> zero inferred edges, no warnings, success
#  15  diagnostic-gate       solution deliverable auto-wired to the diagnostic field-0 terminal validates clean
#  16  stale-diagnostic-gate solution edge to a NON-terminal diagnostic deliverable warns (advisory, success:true)
#  17  schedule-forward      earliest-start/finish respect depends_on[] order (AC1)
#  18  schedule-critical-path  critical_path is the max duration-weighted chain, length == project finish (AC2)
#  19  schedule-unscheduled  duration-less deliverable listed under unscheduled[], treated as zero, no crash (AC3)
#  20  schedule-cycle        schedule over a cyclic graph short-circuits success:false
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
# Inferred edges from artifact sources[] (unrecorded dependencies)
# ---------------------------------------------------------------------------
# canvas/canvas-build-spec's artifact sources[] references facilitation-flow's
# artifact (via a file:// source_url) but declares NO depends_on; market/ext-note
# cites only an external https source. So exactly one edge should be inferred:
#   canvas/canvas-build-spec -> facilitation/facilitation-flow
seed_sources() {
  local dir="$1"
  mkdir -p "$dir/action-fields/facilitation" \
           "$dir/action-fields/canvas" \
           "$dir/action-fields/market"
  cat > "$dir/consult-project.json" <<'EOF'
{
  "slug": "acme",
  "name": "Acme Engagement",
  "key_question": "How?",
  "action_fields": ["facilitation", "canvas", "market"],
  "workflow_state": {"scope": "complete"},
  "created": "2026-06-15",
  "updated": "2026-06-15"
}
EOF
  cat > "$dir/action-fields/facilitation/field.json" <<'EOF'
{
  "slug": "facilitation",
  "title": "Facilitation",
  "deliverables": [
    {"slug": "facilitation-flow", "title": "Facilitation flow", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"}
  ]
}
EOF
  cat > "$dir/action-fields/canvas/field.json" <<'EOF'
{
  "slug": "canvas",
  "title": "Canvas",
  "deliverables": [
    {"slug": "canvas-build-spec", "title": "Canvas build spec", "state": "in-progress", "dt_stage": "prototype", "producing_route": "consult-design-thinking", "persona_review": "pending"}
  ]
}
EOF
  cat > "$dir/action-fields/market/field.json" <<'EOF'
{
  "slug": "market",
  "title": "Market",
  "deliverables": [
    {"slug": "ext-note", "title": "External note", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"}
  ]
}
EOF
  cat > "$dir/action-fields/facilitation/facilitation-flow.md" <<'EOF'
---
slug: facilitation-flow
action_field: facilitation
updated: 2026-06-11
---

# Facilitation flow
EOF
  # canvas-build-spec sources facilitation-flow via a file:// source_url; its
  # entity_ref is its own coordinate (the lineage triple's self-identity), which
  # must be skipped so the source_url is what resolves the cross-deliverable edge.
  cat > "$dir/action-fields/canvas/canvas-build-spec.md" <<'EOF'
---
slug: canvas-build-spec
action_field: canvas
sources:
  - source_url: file:///repo/cogni-consult/acme/action-fields/facilitation/facilitation-flow.md
    entity_ref: cogni-consult/acme/action-fields/canvas/canvas-build-spec
    propagated_at: 2026-06-11T09:00:00Z
updated: 2026-06-11
---

# Canvas build spec
EOF
  # ext-note cites only an external source: entity_ref is self, source_url is https.
  # Neither resolves to a sibling deliverable, so it must contribute no edge.
  cat > "$dir/action-fields/market/ext-note.md" <<'EOF'
---
slug: ext-note
action_field: market
sources:
  - source_url: https://www.destatis.de/some-figure
    entity_ref: cogni-consult/acme/action-fields/market/ext-note
    propagated_at: 2026-06-11T09:00:00Z
    kb_ref: wiki/sources/destatis
updated: 2026-06-11
---

# External note
EOF
}

# ---------------------------------------------------------------------------
# 9  validate-inferred  (surfaces the one unrecorded edge, stays success:true)
# ---------------------------------------------------------------------------
D9="$TMPROOT/sources"; seed_sources "$D9"
OUT="$(run "$D9" validate)"
assert_json "validate-inferred" "$OUT" \
  "d['success'] is True and d['data']['edge_count'] == 0 and d['data']['inferred_edge_count'] == 1 and d['data']['inferred_edges'] == [{'from': 'canvas/canvas-build-spec', 'to': 'facilitation/facilitation-flow'}] and len(d['data']['warnings']) == 1"

# ---------------------------------------------------------------------------
# 10  impact-default  (declared graph only: facilitation-flow blocks nothing)
# ---------------------------------------------------------------------------
OUT="$(run "$D9" impact facilitation/facilitation-flow)"
assert_json "impact-default-no-inferred" "$OUT" \
  "d['success'] is True and d['data']['downstream_count'] == 0 and d['data']['include_inferred'] is False"

# ---------------------------------------------------------------------------
# 11  impact-include-inferred  (folds in the unrecorded dependent)
# ---------------------------------------------------------------------------
OUT="$(run "$D9" impact facilitation/facilitation-flow --include-inferred)"
assert_json "impact-include-inferred" "$OUT" \
  "d['success'] is True and d['data']['downstream'] == ['canvas/canvas-build-spec'] and d['data']['downstream_count'] == 1 and d['data']['include_inferred'] is True"

# ---------------------------------------------------------------------------
# 12  cascade-default  (the silent-zero-dependents status quo: flags nothing)
# ---------------------------------------------------------------------------
OUT="$(run "$D9" cascade-stale facilitation/facilitation-flow --trigger deliverable_update)"
assert_json "cascade-default-no-inferred" "$OUT" \
  "d['success'] is True and d['data']['downstream_count'] == 0 and d['data']['newly_flagged'] == []"

# ---------------------------------------------------------------------------
# 13  cascade-include-inferred  (flags the unrecorded dependent stale)
# ---------------------------------------------------------------------------
OUT="$(run "$D9" cascade-stale facilitation/facilitation-flow --trigger deliverable_update --include-inferred)"
assert_json "cascade-include-inferred" "$OUT" \
  "d['success'] is True and d['data']['newly_flagged'] == ['canvas/canvas-build-spec'] and d['data']['include_inferred'] is True"

# ---------------------------------------------------------------------------
# 14  inferred-graceful  (no artifact .md anywhere -> zero inferred, success)
# ---------------------------------------------------------------------------
D14="$TMPROOT/graceful"; seed_chain "$D14"
OUT="$(run "$D14" validate)"
assert_json "inferred-graceful-no-artifacts" "$OUT" \
  "d['success'] is True and d['data']['inferred_edge_count'] == 0 and d['data']['warnings'] == []"

# ---------------------------------------------------------------------------
# 15  diagnostic-gate  (a solution deliverable auto-wired to the diagnostic
#     field-0 terminal deliverable validates clean — the gating edge is counted,
#     no cycles, no dangling)
# ---------------------------------------------------------------------------
D15="$TMPROOT/diagnostic-gate"
mkdir -p "$D15/action-fields/diagnostic-as-is" \
         "$D15/action-fields/growth-plays"
cat > "$D15/consult-project.json" <<'EOF'
{
  "slug": "acme",
  "name": "Acme Engagement",
  "key_question": "How?",
  "action_fields": ["diagnostic-as-is", "growth-plays"],
  "workflow_state": {"scope": "complete"},
  "created": "2026-06-15",
  "updated": "2026-06-15"
}
EOF
# diagnostic field-0 with two deliverables — terminal is the LAST entry
cat > "$D15/action-fields/diagnostic-as-is/field.json" <<'EOF'
{
  "slug": "diagnostic-as-is",
  "title": "Diagnostic: Current State",
  "deliverables": [
    {"slug": "current-state-scan", "title": "Current-state scan", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"},
    {"slug": "as-is-assessment", "title": "As-is assessment", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"}
  ]
}
EOF
# solution field whose deliverable is auto-wired to the diagnostic terminal
cat > "$D15/action-fields/growth-plays/field.json" <<'EOF'
{
  "slug": "growth-plays",
  "title": "Growth Plays",
  "deliverables": [
    {"slug": "play-design", "title": "Play design", "state": "in-progress", "dt_stage": "ideate", "producing_route": "consult-design-thinking", "persona_review": "pending",
     "depends_on": [{"action_field": "diagnostic-as-is", "deliverable": "as-is-assessment"}]}
  ]
}
EOF
OUT="$(run "$D15" validate)"
assert_json "diagnostic-gate-clean" "$OUT" \
  "d['success'] is True and d['data']['node_count'] == 3 and d['data']['edge_count'] == 1 and not d['data']['cycles'] and not d['data']['dangling'] and not d['data']['stale_diagnostic_gate_edges']"

# ---------------------------------------------------------------------------
# 16  stale-diagnostic-gate  (the diagnostic field-0 gained a NEW terminal after the
#     gate was wired — the solution edge still points at the FORMER terminal, now a
#     non-terminal diagnostic deliverable; validate warns but stays success:true)
# ---------------------------------------------------------------------------
D16="$TMPROOT/stale-diagnostic-gate"
mkdir -p "$D16/action-fields/diagnostic-as-is" \
         "$D16/action-fields/growth-plays"
cat > "$D16/consult-project.json" <<'EOF'
{
  "slug": "acme",
  "name": "Acme Engagement",
  "key_question": "How?",
  "action_fields": ["diagnostic-as-is", "growth-plays"],
  "workflow_state": {"scope": "complete"},
  "created": "2026-06-15",
  "updated": "2026-06-15"
}
EOF
# diagnostic field-0 RE-PLANNED: a third deliverable appended, so the current
# terminal is "synthesis-readout", NOT "as-is-assessment".
cat > "$D16/action-fields/diagnostic-as-is/field.json" <<'EOF'
{
  "slug": "diagnostic-as-is",
  "title": "Diagnostic: Current State",
  "deliverables": [
    {"slug": "current-state-scan", "title": "Current-state scan", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"},
    {"slug": "as-is-assessment", "title": "As-is assessment", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"},
    {"slug": "synthesis-readout", "title": "Synthesis readout", "state": "complete", "dt_stage": "test", "producing_route": "consult-design-thinking", "persona_review": "complete"}
  ]
}
EOF
# solution edge still wired to the FORMER terminal "as-is-assessment" (now non-terminal)
cat > "$D16/action-fields/growth-plays/field.json" <<'EOF'
{
  "slug": "growth-plays",
  "title": "Growth Plays",
  "deliverables": [
    {"slug": "play-design", "title": "Play design", "state": "in-progress", "dt_stage": "ideate", "producing_route": "consult-design-thinking", "persona_review": "pending",
     "depends_on": [{"action_field": "diagnostic-as-is", "deliverable": "as-is-assessment"}]}
  ]
}
EOF
OUT="$(run "$D16" validate)"
assert_json "stale-diagnostic-gate" "$OUT" \
  "d['success'] is True and not d['data']['cycles'] and not d['data']['dangling'] and d['data']['stale_diagnostic_gate_edge_count'] == 1 and d['data']['stale_diagnostic_gate_edges'][0] == {'from': 'growth-plays/play-design', 'to': 'diagnostic-as-is/as-is-assessment'} and any('non-terminal diagnostic' in w for w in d['data']['warnings'])"

# ---------------------------------------------------------------------------
# schedule fixtures: one "plan" field with a fan-in (root -> {long,short} -> sink),
# plus a duration-less "loose" node to exercise unscheduled[].
#   root(2) -> long(10)  \
#          \-> short(1) --> sink(3)      earliest-finish: root 2, long 12, short 3,
#          \-> loose(none)                                 sink 15, loose 2
# critical path = root -> long -> sink (2+10+3 = 15 = project earliest-finish).
seed_scheduled() {
  local dir="$1"
  mkdir -p "$dir/action-fields/plan"
  cat > "$dir/consult-project.json" <<'EOF'
{
  "slug": "acme", "name": "Acme Engagement", "key_question": "How?",
  "action_fields": ["plan"],
  "workflow_state": {"scope": "complete"},
  "created": "2026-06-15", "updated": "2026-06-15"
}
EOF
  cat > "$dir/action-fields/plan/field.json" <<'EOF'
{
  "slug": "plan",
  "title": "Plan",
  "deliverables": [
    {"slug": "root", "title": "Root", "state": "complete", "duration": 2},
    {"slug": "long", "title": "Long", "state": "pending", "duration": 10,
     "depends_on": [{"action_field": "plan", "deliverable": "root"}]},
    {"slug": "short", "title": "Short", "state": "pending", "duration": 1,
     "depends_on": [{"action_field": "plan", "deliverable": "root"}]},
    {"slug": "sink", "title": "Sink", "state": "pending", "duration": 3,
     "depends_on": [{"action_field": "plan", "deliverable": "long"},
                    {"action_field": "plan", "deliverable": "short"}]},
    {"slug": "loose", "title": "Loose", "state": "pending",
     "depends_on": [{"action_field": "plan", "deliverable": "root"}]}
  ]
}
EOF
}

# ---------------------------------------------------------------------------
# 17  schedule-forward      earliest-start/finish respect depends_on[] order (AC1)
# ---------------------------------------------------------------------------
DS="$TMPROOT/schedule"; seed_scheduled "$DS"
OUT="$(run "$DS" schedule)"
assert_json "schedule-forward" "$OUT" \
  "d['success'] is True and (lambda s: s['plan/root']['earliest_start'] == 0 and s['plan/root']['earliest_finish'] == 2 and s['plan/long']['earliest_start'] == 2 and s['plan/long']['earliest_finish'] == 12 and s['plan/short']['earliest_finish'] == 3 and s['plan/sink']['earliest_start'] == 12 and s['plan/sink']['earliest_finish'] == 15)({e['key']: e for e in d['data']['schedule']})"

# ---------------------------------------------------------------------------
# 18  schedule-critical-path   longest duration-weighted chain == project finish (AC2)
# ---------------------------------------------------------------------------
assert_json "schedule-critical-path" "$OUT" \
  "d['success'] is True and d['data']['critical_path'] == ['plan/root', 'plan/long', 'plan/sink'] and d['data']['project_earliest_finish'] == 15 and (lambda s: sum(s[k]['duration'] for k in d['data']['critical_path']) == d['data']['project_earliest_finish'])({e['key']: e for e in d['data']['schedule']})"

# ---------------------------------------------------------------------------
# 19  schedule-unscheduled   duration-less deliverable listed + treated as zero (AC3)
# ---------------------------------------------------------------------------
assert_json "schedule-unscheduled" "$OUT" \
  "d['success'] is True and d['data']['unscheduled'] == ['plan/loose'] and (lambda s: s['plan/loose']['unscheduled'] is True and s['plan/loose']['duration'] is None and s['plan/loose']['earliest_finish'] == 2)({e['key']: e for e in d['data']['schedule']})"

# ---------------------------------------------------------------------------
# 20  schedule-cycle    schedule over a cyclic graph short-circuits success:false
# ---------------------------------------------------------------------------
DSC="$TMPROOT/schedule-cycle"; seed_chain "$DSC"
cat > "$DSC/action-fields/market-evidence/field.json" <<'EOF'
{
  "slug": "market-evidence",
  "title": "Market Evidence",
  "deliverables": [
    {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "duration": 2,
     "depends_on": [{"action_field": "go-to-market", "deliverable": "gtm-play"}]}
  ]
}
EOF
OUT="$(run "$DSC" schedule)"
assert_json "schedule-cycle" "$OUT" \
  "d['success'] is False and len(d['data']['cycles']) >= 1 and 'cycle' in d['error']"

# ---------------------------------------------------------------------------
echo
if [ "$failures" -eq 0 ]; then
  echo "All deliverable-graph tests passed."
  exit 0
else
  echo "$failures deliverable-graph test(s) failed." >&2
  exit 1
fi
