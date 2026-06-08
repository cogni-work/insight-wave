#!/usr/bin/env bash
# test_load_wiki_coverage_findings.sh — contract test for the #354 helpers in
# _knowledge_lib.py: load_wiki_coverage_findings() + gap_sq_ids_from_coverage().
#
# Asserts:
#   1. Missing wiki-coverage.json → both helpers return [] (fail-soft).
#   2. All-`covered` manifest → [] (no gaps to stream).
#   3. Mixed verdicts → research_uncovered/research_partial findings in
#      coverage order, ids prefixed `sq:`, messages joined from plan.json
#      (theme_label — query); gap_sq_ids_from_coverage returns bare ids.
#   4. Missing plan.json → findings still returned, bare-fallback message.
#   5. Regex-unsafe sq_id (contains a backtick) → dropped.
#   6. coverage_name override (#585): with a curate-time wiki-coverage.json
#      (uncovered) AND a post-ingest wiki-coverage-finalize.json (covered)
#      side by side, the default reads the curate file (returns the gap) while
#      the override reads the finalize file (returns []), for both helpers.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Build fixtures: one project dir per case under $WORK.
mk_cov() { # $1 = project dir, $2 = JSON for data.sub_questions
  mkdir -p "$1/.metadata"
  printf '{"success": true, "data": {"schema_version": "0.1.0", "sub_questions": %s}}' "$2" \
    > "$1/.metadata/wiki-coverage.json"
}
mk_plan() { # $1 = project dir, $2 = JSON for sub_questions
  mkdir -p "$1/.metadata"
  printf '{"schema_version": "0.1.0", "topic": "t", "sub_questions": %s}' "$2" \
    > "$1/.metadata/plan.json"
}

# Case 1: missing manifest
P1="$WORK/p1"; mkdir -p "$P1/.metadata"

# Case 2: all covered
P2="$WORK/p2"
mk_cov "$P2" '[{"sq_id":"sq-01","coverage_verdict":"covered","covered_pages":[]},{"sq_id":"sq-02","coverage_verdict":"covered","covered_pages":[]}]'

# Case 3: mixed verdicts with plan
P3="$WORK/p3"
mk_cov "$P3" '[{"sq_id":"sq-01","coverage_verdict":"covered","covered_pages":[]},{"sq_id":"sq-02","coverage_verdict":"partial","covered_pages":[]},{"sq_id":"sq-03","coverage_verdict":"uncovered","covered_pages":[]}]'
mk_plan "$P3" '[{"id":"sq-01","query":"q1","theme_label":"Theme One"},{"id":"sq-02","query":"q2","theme_label":"Theme Two"},{"id":"sq-03","query":"q3","theme_label":"Theme Three"}]'

# Case 4: mixed verdicts, NO plan.json
P4="$WORK/p4"
mk_cov "$P4" '[{"sq_id":"sq-05","coverage_verdict":"uncovered","covered_pages":[]}]'

# Case 5: regex-unsafe sq_id
P5="$WORK/p5"
mk_cov "$P5" '[{"sq_id":"sq-`evil`","coverage_verdict":"uncovered","covered_pages":[]},{"sq_id":"sq-06","coverage_verdict":"uncovered","covered_pages":[]}]'

# Case 6: coverage_name override (#585) — curate-time file shows uncovered, the
# post-ingest finalize file shows covered. Default reads curate (gap); override
# reads finalize ([]).
P6="$WORK/p6"
mk_cov "$P6" '[{"sq_id":"sq-07","coverage_verdict":"uncovered","covered_pages":[]}]'
mk_plan "$P6" '[{"id":"sq-07","query":"q7","theme_label":"Theme Seven"}]'
printf '{"success": true, "data": {"schema_version": "0.1.0", "sub_questions": %s}}' \
  '[{"sq_id":"sq-07","coverage_verdict":"covered","covered_pages":[]}]' \
  > "$P6/.metadata/wiki-coverage-finalize.json"

OUT=$(python3 - "$SCRIPTS_DIR" "$WORK" <<'PY'
import sys
from pathlib import Path

scripts = Path(sys.argv[1]); work = Path(sys.argv[2])
sys.path.insert(0, str(scripts))
from _knowledge_lib import load_wiki_coverage_findings, gap_sq_ids_from_coverage

def emit(tag, ok):
    print(f"{tag}:{'OK' if ok else 'BAD'}")

# Case 1: missing manifest
f1 = load_wiki_coverage_findings(work / "p1")
g1 = gap_sq_ids_from_coverage(work / "p1")
emit("missing", f1 == [] and g1 == [])

# Case 2: all covered
f2 = load_wiki_coverage_findings(work / "p2")
g2 = gap_sq_ids_from_coverage(work / "p2")
emit("covered", f2 == [] and g2 == [])

# Case 3: mixed with plan
f3 = load_wiki_coverage_findings(work / "p3")
g3 = gap_sq_ids_from_coverage(work / "p3")
ok3 = (
    f3 == [
        {"class": "research_partial",   "id": "sq:sq-02", "message": "Theme Two — q2"},
        {"class": "research_uncovered", "id": "sq:sq-03", "message": "Theme Three — q3"},
    ]
    and g3 == ["sq-02", "sq-03"]
)
emit("mixed", ok3)

# Case 4: no plan → bare fallback message
f4 = load_wiki_coverage_findings(work / "p4")
ok4 = f4 == [{"class": "research_uncovered", "id": "sq:sq-05",
             "message": "sub-question sq-05 (uncovered)"}]
emit("noplan", ok4)

# Case 5: unsafe id dropped, safe id kept
f5 = load_wiki_coverage_findings(work / "p5")
g5 = gap_sq_ids_from_coverage(work / "p5")
ok5 = f5 == [{"class": "research_uncovered", "id": "sq:sq-06",
             "message": "sub-question sq-06 (uncovered)"}] and g5 == ["sq-06"]
emit("unsafe", ok5)

# Case 6: coverage_name override (#585)
p6 = work / "p6"
f6_default = load_wiki_coverage_findings(p6)                                  # curate file → gap
g6_default = gap_sq_ids_from_coverage(p6)
f6_override = load_wiki_coverage_findings(p6, "wiki-coverage-finalize.json")  # finalize → []
g6_override = gap_sq_ids_from_coverage(p6, "wiki-coverage-finalize.json")
ok6 = (
    f6_default == [{"class": "research_uncovered", "id": "sq:sq-07", "message": "Theme Seven — q7"}]
    and g6_default == ["sq-07"]
    and f6_override == []
    and g6_override == []
)
emit("override", ok6)
PY
)

check() { # $1 = tag, $2 = description
  if printf '%s\n' "$OUT" | grep -q "^$1:OK$"; then
    green "PASS: $2"
  else
    red "FAIL: $2 (got: $(printf '%s\n' "$OUT" | grep "^$1:" || echo none))"
    errors=$((errors + 1))
  fi
}

check missing "missing wiki-coverage.json → []"
check covered "all-covered manifest → []"
check mixed   "mixed verdicts → ordered sq: findings + bare ids from plan"
check noplan  "missing plan.json → bare-fallback message"
check unsafe  "regex-unsafe sq_id dropped, safe id kept"
check override "coverage_name override reads finalize file (#585): default→gap, override→[]"

if [ "$errors" -ne 0 ]; then
  red "FAILED: $errors assertion(s)"
  exit 1
fi
green "ALL TESTS PASS"
