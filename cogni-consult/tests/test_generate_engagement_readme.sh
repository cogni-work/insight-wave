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
#   4  stale chain        two stale deliverables, downstream listed first in
#                         field.json → the topological refresh order (via
#                         deliverable-graph.py) still names the upstream one
#   5  failure envelope   missing consult-project.json → success:false, exit 1
#   6  malformed field    non-dict deliverables entry → success:false envelope,
#                         never a raw traceback
#   7  overwrite guard    a hand-authored root README.md (no generated marker)
#                         is refused with success:false and left byte-identical;
#                         a script-generated README (marker present) is
#                         refreshed in place
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
  mkdir -p "$dir/action-fields/market-evidence" "$dir/personas" "$dir/sources" "$dir/.metadata" "$dir/scope"
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
  # Scope narrative — the primary framing artifact the front door links first.
  echo "# Key question" > "$dir/scope/key-question.md"
}

# --- Fixture 1: fully-scoped engagement — four sections, resolving links, README-only write
D1="$TMPROOT/full"
seed_scoped "$D1" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test"},
  {"slug": "competitor-map", "title": "Competitor map", "state": "pending"}
]'
echo '{"source": "scope-seeded", "name": "CFO"}' > "$D1/personas/cfo.json"
echo "# Market sizing" > "$D1/action-fields/market-evidence/market-sizing.md"
# Assumption registry with one entry — exercises the populated Assumptions table
# and the resolving wayfinding link. Written before the BEFORE1 snapshot so the
# "writes only README.md" check (1l) still sees README.md as the only new file.
cat > "$D1/assumptions.json" <<'EOF'
{"assumptions": [
  {"id": "asm-tam", "name": "DACH TAM", "value": "€1.2B", "provenance_type": "claim", "status": "reviewed"}
]}
EOF
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
assert_md_has "1m scope key-question link" "$MD1" "(scope/key-question.md)"
assert_md_has "1n action fields count"     "$MD1" "**Action fields:** 1 derived"
assert_links_resolve "1j all links resolve" "$D1"
# Deliverable without a .md artifact gets no link (would be broken).
assert_md_lacks "1k no broken deliv link" "$MD1" "(action-fields/market-evidence/competitor-map.md)"
# Knowledge base section renders; an unbound engagement shows the neutral line.
assert_md_has "1o kb section"           "$MD1" "## Knowledge base"
assert_md_has "1p kb neutral line"      "$MD1" "No knowledge base bound yet."
# Assumptions section renders the registry: count line, table row (value + type +
# verification status), and a resolving wayfinding link.
assert_md_has "1q assumptions section"  "$MD1" "## Assumptions"
assert_md_has "1r assumptions count"    "$MD1" "1 assumption registered."
assert_md_has "1s assumptions row"      "$MD1" "| DACH TAM | €1.2B | claim | reviewed |"
assert_md_has "1t assumptions wayfinding link" "$MD1" "(assumptions.json)"
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
assert_md_lacks "2f no scope link"      "$MD2" "(scope/key-question.md)"
assert_md_has "2g action fields zero"   "$MD2" "**Action fields:** 0 derived"
# Assumptions section renders even with no registry file — neutral line, no crash.
assert_md_has "2h assumptions section"  "$MD2" "## Assumptions"
assert_md_has "2i assumptions neutral"  "$MD2" "No assumptions registered yet."
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

# --- Fixture 4: stale chain — refresh rung recommends the upstream deliverable first
# The downstream deliverable is deliberately listed FIRST in field.json: the
# stale[0] file-order fallback would name "Competitor map", so this assertion
# passing proves the topological refresh order (via deliverable-graph.py) ran —
# and pins the field_slug/deliv_slug key contract between the two scripts.
D4="$TMPROOT/stale"
seed_scoped "$D4" '[
  {"slug": "competitor-map", "title": "Competitor map", "state": "complete", "dt_stage": "test",
   "depends_on": [{"action_field": "market-evidence", "deliverable": "market-sizing"}],
   "lineage_status": {"status": "stale", "reason": "upstream changed"}},
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test",
   "lineage_status": {"status": "stale", "reason": "source data updated"}}
]'
echo '{"source": "scope-seeded", "name": "CFO"}' > "$D4/personas/cfo.json"
OUT4="$(run "$D4")"
MD4="$D4/README.md"
assert_json "4a stale success"           "$OUT4" "d['success'] is True"
assert_json "4b rung is refresh"         "$OUT4" "d['data']['next_action_rung'] == 'refresh'"
assert_md_has "4c upstream named first"  "$MD4" "refresh “Market sizing” first"

# --- Fixture 5: failure envelope on missing project file -----------------------------
D5="$TMPROOT/missing"
mkdir -p "$D5"
OUT5="$(run "$D5")"
RC5=$?
assert_json "5a failure envelope"        "$OUT5" "d['success'] is False"
if [ "$RC5" -ne 0 ]; then
  pass "5b non-zero exit"
else
  fail "5b non-zero exit" "expected non-zero exit code, got 0"
fi

# --- Fixture 6: malformed field.json (non-dict deliverables entry) → envelope, no traceback
D6="$TMPROOT/malformed"
seed_scoped "$D6" '["not-a-deliverable-object"]'
OUT6="$(run "$D6" 2>/dev/null)"
RC6=$?
assert_json "6a malformed envelope"      "$OUT6" "d['success'] is False"
if [ "$RC6" -ne 0 ]; then
  pass "6b non-zero exit"
else
  fail "6b non-zero exit" "expected non-zero exit code, got 0"
fi

# --- Fixture 7: overwrite guard — hand-authored README refused, generated README refreshed
D7="$TMPROOT/overwrite-guard"
seed_scoped "$D7" '[]'
printf '# My notes\n\nHand-written front door.\n' > "$D7/README.md"
OUT7="$(run "$D7")"
RC7=$?
assert_json "7a hand-authored refusal"  "$OUT7" "d['success'] is False and 'refusing to overwrite' in d['error']"
if [ "$RC7" -ne 0 ]; then
  pass "7b non-zero exit"
else
  fail "7b non-zero exit" "expected non-zero exit code, got 0"
fi
if [ "$(cat "$D7/README.md")" = "$(printf '# My notes\n\nHand-written front door.\n' | cat)" ]; then
  pass "7c hand-authored README untouched"
else
  fail "7c hand-authored README untouched" "hand-authored README.md was modified"
fi
rm "$D7/README.md"
OUT7d="$(run "$D7")"
assert_json "7d fresh write succeeds"   "$OUT7d" "d['success'] is True"
if grep -q "Auto-generated front door" "$D7/README.md"; then
  pass "7e marker present in fresh write"
else
  fail "7e marker present in fresh write" "generated README.md lacks the marker footer"
fi
OUT7f="$(run "$D7")"
RC7f=$?
assert_json "7f regenerated README refreshed" "$OUT7f" "d['success'] is True"
if [ "$RC7f" -eq 0 ]; then
  pass "7g zero exit on refresh"
else
  fail "7g zero exit on refresh" "expected exit 0 on marked-README refresh"
fi

# --- Fixture 8: bound knowledge base + research files → kb line + research wayfinding
# seed_scoped binds no knowledge base, so patch in plugin_refs and seed two
# synthesis files (one under scope/research, one under a field's research dir) to
# exercise the bound-slug line, the synthesis count, and the research wayfinding links.
D8="$TMPROOT/kb"
seed_scoped "$D8" '[
  {"slug": "market-sizing", "title": "Market sizing", "state": "complete", "dt_stage": "test"}
]'
echo '{"source": "scope-seeded", "name": "CFO"}' > "$D8/personas/cfo.json"
python3 - "$D8" <<'PY'
import json, os, sys
d = sys.argv[1]
p = os.path.join(d, "consult-project.json")
proj = json.load(open(p))
proj["plugin_refs"] = {"knowledge_base": "eu-ai-act"}
json.dump(proj, open(p, "w"), indent=2)
PY
mkdir -p "$D8/scope/research" "$D8/action-fields/market-evidence/research"
echo "# synthesis A" > "$D8/scope/research/a.md"
echo "# synthesis B" > "$D8/action-fields/market-evidence/research/b.md"
OUT8="$(run "$D8")"
MD8="$D8/README.md"
assert_json "8a kb success"             "$OUT8" "d['success'] is True"
assert_md_has "8b kb section"           "$MD8" "## Knowledge base"
assert_md_has "8c bound slug + count"   "$MD8" 'Bound knowledge base: `eu-ai-act` · 2 synthesis file(s) across scope + action fields'
assert_md_has "8d scope research link"  "$MD8" "(scope/research)"
assert_md_has "8e field research link"  "$MD8" "(action-fields/market-evidence/research)"
assert_links_resolve "8f links resolve" "$D8"

# --- Summary ----------------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "All generate-engagement-readme.py tests passed."
  exit 0
else
  echo "$failures assertion(s) failed." >&2
  exit 1
fi
