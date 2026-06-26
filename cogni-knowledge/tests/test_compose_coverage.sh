#!/usr/bin/env bash
# test_compose_coverage.sh — contract test for scripts/compose-coverage.py.
#
# The script offloads knowledge-compose's Step 5.5 / Step 7 inline coverage
# heredocs. The behaviour-preserving contract is that each subcommand reproduces
# the EXACT raw stdout shape the SKILL captures with $(...):
#   coverage-deficit → one JSON object {uncited_evidence_sq_ids, zero_cited_sq_ids}
#   expand-sections  → a bare comma-list of section indices (density-aware)
#   per-sq-coverage  → a header line + one per-sub-question line
# Host-independent: synthetic fixtures, stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/compose-coverage.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: compose-coverage.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- fixtures -----------------------------------------------------------------
# sq-01: 2 ingested (src-a cited, src-b uncited)  → deficit, NOT zero-cited
# sq-02: 1 ingested (src-b, uncited)              → deficit, zero-cited
# sq-03: 1 ingested (src-c, uncited)              → deficit, zero-cited
cat > "$WORK/plan.json" <<'JSON'
{"sub_questions": [{"id": "sq-01"}, {"id": "sq-02"}, {"id": "sq-03"}]}
JSON
cat > "$WORK/ingest.json" <<'JSON'
{"ingested": [
  {"slug": "src-a", "sub_question_refs": ["sq-01"]},
  {"slug": "src-b", "sub_question_refs": ["sq-01", "sq-02"]},
  {"slug": "src-c", "sub_question_refs": ["sq-03"]}
]}
JSON
cat > "$WORK/citation.json" <<'JSON'
{"citations": [{"wiki_slug": "src-a"}]}
JSON
# section 0 covers sq-01 (thin: 50/100), section 1 covers sq-02 (full: 95/100),
# section 2 is structural (covers nothing).
cat > "$WORK/outline.json" <<'JSON'
{"sections": [
  {"index": 0, "covers_sub_questions": ["sq-01"], "budget": 100, "drafted_words": 50},
  {"index": 1, "covers_sub_questions": ["sq-02"], "budget": 100, "drafted_words": 95},
  {"index": 2, "covers_sub_questions": [], "budget": 50, "drafted_words": 40}
]}
JSON

errors=0
emit() { # tag description
  case "$1" in
    OK) green "PASS: $2" ;;
    *)  red "FAIL: $2"; red "  $1"; errors=$((errors + 1)) ;;
  esac
}

# --- coverage-deficit: raw JSON with both key sets -----------------------------
DEFICIT=$(python3 "$SCRIPT" coverage-deficit --plan "$WORK/plan.json" \
  --ingest "$WORK/ingest.json" --citation "$WORK/citation.json")
RES=$(DEF="$DEFICIT" python3 -c '
import json, os
d = json.loads(os.environ["DEF"])
assert d["uncited_evidence_sq_ids"] == ["sq-01", "sq-02", "sq-03"], d
assert d["zero_cited_sq_ids"] == ["sq-02", "sq-03"], d
print("OK")
' 2>&1 || true)
emit "$RES" "coverage-deficit — raw JSON with uncited_evidence_sq_ids + zero_cited_sq_ids (src-b/src-c uncited; sq-02/sq-03 zero-cited)"

# --- expand-sections: density-aware bare comma-list ----------------------------
EXP_STD=$(python3 "$SCRIPT" expand-sections --outline "$WORK/outline.json" \
  --coverage-json "$DEFICIT" --density standard)
[ "$EXP_STD" = "0,1" ] && emit OK "expand-sections (standard) — thin sq-01 + zero-cited sq-02 → '0,1'" \
  || emit "got: '$EXP_STD' want '0,1'" "expand-sections (standard) — thin sq-01 + zero-cited sq-02 → '0,1'"

EXP_EXEC=$(python3 "$SCRIPT" expand-sections --outline "$WORK/outline.json" \
  --coverage-json "$DEFICIT" --density executive)
[ "$EXP_EXEC" = "1" ] && emit OK "expand-sections (executive) — only zero-cited sq-02 qualifies → '1' (thin-but-cited sq-01 dropped)" \
  || emit "got: '$EXP_EXEC' want '1'" "expand-sections (executive) — only zero-cited sq-02 qualifies → '1' (thin-but-cited sq-01 dropped)"

# --- per-sq-coverage: header + per-sub-question lines ---------------------------
PSQ=$(python3 "$SCRIPT" per-sq-coverage --plan "$WORK/plan.json" \
  --ingest "$WORK/ingest.json" --citation "$WORK/citation.json")
RES=$(PSQ="$PSQ" python3 -c '
import os
lines = os.environ["PSQ"].splitlines()
assert lines[0] == "Per-sub-question source coverage (executive caps length, not breadth):", lines
assert "  sq-01: 1/2 ingested sources cited" in lines, lines
assert "  sq-02: 0/1 ingested sources cited" in lines, lines
assert "  sq-03: 0/1 ingested sources cited" in lines, lines
print("OK")
' 2>&1 || true)
emit "$RES" "per-sq-coverage — header + per-sub-question cited/available lines"

# --- fail-soft: coverage-deficit on a missing file prints nothing, exits 1 -----
OUT=$(python3 "$SCRIPT" coverage-deficit --plan "$WORK/nope.json" \
  --ingest "$WORK/ingest.json" --citation "$WORK/citation.json" 2>/dev/null && echo "RC0" || echo "RC1")
[ "$OUT" = "RC1" ] && emit OK "coverage-deficit — fail-soft: missing file → no stdout, exit 1 (SKILL treats empty as 'no deficit, skip')" \
  || emit "got: '$OUT'" "coverage-deficit — fail-soft: missing file → no stdout, exit 1"

# --- fail-soft: per-sq-coverage on a missing file prints nothing, exits 0 ------
PSQ_ERR=$(python3 "$SCRIPT" per-sq-coverage --plan "$WORK/nope.json" \
  --ingest "$WORK/ingest.json" --citation "$WORK/citation.json" 2>/dev/null; echo "rc=$?")
[ "$PSQ_ERR" = "rc=0" ] && emit OK "per-sq-coverage — fail-soft: missing file → no stdout, exit 0 (SKILL wraps it 2>/dev/null || true)" \
  || emit "got: '$PSQ_ERR'" "per-sq-coverage — fail-soft: missing file → no stdout, exit 0"

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All compose-coverage.py cases pass."
