#!/usr/bin/env bash
# Regression test for cogni-consult/scripts/generate-engagement-readme.py — the
# markdown wayfinding front door written at the engagement root.
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each fixture
# builds a minimal engagement in a temp directory, runs the generator, and asserts on
# both the JSON stdout and the generated README.md.
#
# Coverage:
#   1  fully-scoped       all four sections render; every relative link in the
#                         README resolves inside the engagement dir; the run
#                         writes README.md and nothing else
#   2  scaffold-only      scope pending, no fields → status reads "scoping",
#                         next-action recommends consult-scope, no field links
#   3  personas-gate      scoped engagement without a scope-seeded persona →
#                         next-action recommends consult-personas before
#                         deliverable work
#   4  failure envelope   missing consult-project.json → success:false, exit 1
#
# Usage: bash cogni-consult/tests/test_generate_engagement_readme.sh
# Exits non-zero on any assertion failure.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-fixture failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/generate-engagement-readme.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: generate-engagement-readme.py not found at $SCRIPT" >&2
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

# assert_md_has <label> <file> <needle>
assert_md_has() {
  local label="$1" file="$2" needle="$3"
  if [ -f "$file" ] && grep -qF "$needle" "$file"; then
    pass "$label"
  else
    fail "$label" "expected to find '$needle' in $file"
  fi
}

# assert_md_lacks <label> <file> <needle> — a missing file is its own failure,
# so a "did not expect X" assertion can never pass vacuously on a run that
# produced no README at all.
assert_md_lacks() {
  local label="$1" file="$2" needle="$3"
  if [ ! -f "$file" ]; then
    fail "$label" "file absent: $file"
  elif grep -qF "$needle" "$file"; then
    fail "$label" "did not expect '$needle' in $file"
  else
    pass "$label"
  fi
}

# assert_links_resolve <label> <engagement-dir> — every markdown link target in
# README.md must exist relative to the engagement dir (AC1: no broken links).
assert_links_resolve() {
  local label="$1" dir="$2"
  local verdict
  verdict="$(ENG_DIR="$dir" python3 -c "
import os, re
dir = os.environ['ENG_DIR']
with open(os.path.join(dir, 'README.md')) as f:
    body = f.read()
missing = [t for t in re.findall(r'\]\(([^)]+)\)', body)
           if not t.startswith(('http://', 'https://'))
           and not os.path.exists(os.path.join(dir, t))]
print('PASS' if not missing else 'FAIL ' + ', '.join(missing))
")"
  if [ "$verdict" = "PASS" ]; then
    pass "$label"
  else
    fail "$label" "unresolved link targets: ${verdict#FAIL }"
  fi
}

# Build a scoped, one-field engagement with the full wayfinding surface.
#   seed_scoped <dir> <deliverables-json>
seed_scoped() {
  local dir="$1" delivs="$2"
  mkdir -p "$dir/action-fields/market-evidence" "$dir/personas" "$dir/sources" "$dir/.metadata"
  cat > "$dir/consult-project.json" <<'EOF'
{
  "slug": "acme",
  "name": "Acme Engagement",
  "key_question": "How do we enter the market by 2027?",
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
  echo '{"decisions": []}' > "$dir/.metadata/decision-log.json"
}

# --- Fixture 1: fully-scoped engagement — four sections, resolving links, README-only write
D1="$TMPROOT/full"
seed_scoped "$D1" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test"},
  {"slug": "competitor-map", "title": "Competitor map", "state": "pending"}
]'
echo '{"source": "scope-seeded", "name": "CFO"}' > "$D1/personas/cfo.json"
echo "# Market sizing" > "$D1/action-fields/market-evidence/market-sizing.md"
BEFORE1="$(cd "$D1" && find . -type f | sort)"
OUT1="$(run "$D1")"
AFTER1="$(cd "$D1" && find . -type f | sort)"
MD1="$D1/README.md"
assert_json "1a full success"           "$OUT1" "d['success'] is True"
assert_json "1b completion 50pct"       "$OUT1" "d['data']['completion_pct'] == 50"
assert_md_has "1c H1 + name"            "$MD1" "# Acme Engagement"
assert_md_has "1d key question"         "$MD1" "How do we enter the market by 2027?"
assert_md_has "1e status section"       "$MD1" "## Status"
assert_md_has "1f field done/total row" "$MD1" "| Market evidence | 1/2 |"
assert_md_has "1g next section"         "$MD1" "## Next"
assert_md_has "1h wayfinding section"   "$MD1" "## Wayfinding"
assert_md_has "1i decision-log link"    "$MD1" "(.metadata/decision-log.json)"
assert_links_resolve "1j all links resolve" "$D1"
# Deliverable without a .md artifact gets no link (would be broken).
assert_md_lacks "1k no broken deliv link" "$MD1" "(action-fields/market-evidence/competitor-map.md)"
# The run wrote README.md and nothing else (AC3).
DIFF1="$(comm -13 <(printf '%s\n' "$BEFORE1") <(printf '%s\n' "$AFTER1"))"
if [ "$DIFF1" = "./README.md" ]; then
  pass "1l writes only README.md"
else
  fail "1l writes only README.md" "unexpected new files: $DIFF1"
fi

# --- Fixture 2: scaffold-only engagement — graceful degradation ---------------------
D2="$TMPROOT/scaffold"
mkdir -p "$D2/action-fields" "$D2/personas" "$D2/sources"
cat > "$D2/consult-project.json" <<'EOF'
{
  "slug": "fresh",
  "name": "Fresh Engagement",
  "action_fields": [],
  "workflow_state": {"scope": "pending"}
}
EOF
OUT2="$(run "$D2")"
MD2="$D2/README.md"
assert_json "2a scaffold success"       "$OUT2" "d['success'] is True"
assert_json "2a2 rung is scope"         "$OUT2" "d['data']['next_action_rung'] == 'scope'"
assert_md_has "2b status reads scoping" "$MD2" "**Scope:** scoping"
assert_md_has "2c next recommends scope" "$MD2" "consult-scope"
assert_md_lacks "2d no field links"     "$MD2" "(action-fields/"
assert_links_resolve "2e links resolve" "$D2"

# --- Fixture 3: personas gate pending blocks deliverable work ------------------------
D3="$TMPROOT/gate"
seed_scoped "$D3" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "pending"}
]'
# personas/ holds only a setup-default advisor — the gate stays pending.
echo '{"source": "setup-default", "name": "Consulting partner"}' > "$D3/personas/consulting-partner.json"
OUT3="$(run "$D3")"
MD3="$D3/README.md"
assert_json "3a gate success"            "$OUT3" "d['data']['personas_gate'] == 'pending'"
assert_json "3a2 rung is personas"       "$OUT3" "d['data']['next_action_rung'] == 'personas'"
assert_md_has "3b next recommends personas" "$MD3" "consult-personas"
assert_md_lacks "3c does not start deliverable" "$MD3" "consult-design-thinking"

# --- Fixture 5: stale chain — refresh rung recommends the upstream deliverable first
D5="$TMPROOT/stale"
seed_scoped "$D5" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test",
   "lineage_status": {"status": "stale", "reason": "source data updated"}},
  {"slug": "competitor-map", "title": "Competitor map", "state": "complete", "dt_stage": "test",
   "depends_on": [{"action_field": "market-evidence", "deliverable": "market-sizing"}],
   "lineage_status": {"status": "stale", "reason": "upstream changed"}}
]'
echo '{"source": "scope-seeded", "name": "CFO"}' > "$D5/personas/cfo.json"
OUT5="$(run "$D5")"
MD5="$D5/README.md"
assert_json "5a stale success"           "$OUT5" "d['success'] is True"
assert_json "5b rung is refresh"         "$OUT5" "d['data']['next_action_rung'] == 'refresh'"
# The topological refresh order (via deliverable-graph.py) names the upstream
# deliverable first — this pins the field_slug/deliv_slug key contract between
# the two scripts, and that staleness outranks the pending/in-progress rungs.
assert_md_has "5c upstream named first"  "$MD5" "refresh “Market sizing” first"

# --- Fixture 4: failure envelope on missing project file -----------------------------
D4="$TMPROOT/missing"
mkdir -p "$D4"
OUT4="$(run "$D4")"
RC4=$?
assert_json "4a failure envelope"        "$OUT4" "d['success'] is False"
if [ "$RC4" -ne 0 ]; then
  pass "4b non-zero exit"
else
  fail "4b non-zero exit" "expected non-zero exit code, got 0"
fi

# --- Summary ----------------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "All generate-engagement-readme.py tests passed."
  exit 0
else
  echo "$failures assertion(s) failed." >&2
  exit 1
fi
