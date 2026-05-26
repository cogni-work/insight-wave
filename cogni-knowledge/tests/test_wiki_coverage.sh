#!/usr/bin/env bash
# test_wiki_coverage.sh — script unit tests for scripts/wiki-coverage.py (P1.3, #309).
#
# wiki-coverage.py is the deterministic half of read-before-web compounding:
# the orchestrator (knowledge-curate Step 0.5) scores the bound wiki's coverage
# of each plan.json sub-question ONCE, and threads the result to each curator.
#
# Contract under test:
#   1. empty / missing wiki (fresh base) -> every SQ `uncovered`, success:true
#      (this is the run-1 no-regression guarantee).
#   2. a sources/ page whose title + index one-liner overlaps an SQ ->
#      covered/partial, with the slug + correct `page_path` in covered_pages.
#   3. a syntheses/ page -> page_path is `wiki/syntheses/...` (guards the
#      "synthesis"+"s" != "synthesiss" pluralization trap).
#   4. --threshold boundary moves a page in/out of the covered set.
#   5. malformed plan.json -> clean success:false (the one hard input).
#
# bash 3.2 + python3 stdlib only (no pytest, no pip). Matches tests/README.md.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/wiki-coverage.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

WIKI="$WORK/wiki"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/syntheses"

# A two-sub-question plan: sq-01 about EU AI Act high-risk classification,
# sq-02 about an unrelated topic that no page covers.
cat > "$WORK/plan.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "sub_questions": [
    {"id": "sq-01", "query": "EU AI Act high-risk classification scope",
     "theme_label": "High-risk Classification", "search_guidance": "find the article 6 text",
     "candidate_domains": ["europa.eu"]},
    {"id": "sq-02", "query": "quantum computing surface code error correction thresholds",
     "theme_label": "Quantum Error Correction", "search_guidance": "decoder benchmarks"}
  ]
}
JSON

# Run the score command and capture stdout for python assertions.
run_score() {  # run_score <wiki-root> <plan> [extra args...]
  python3 "$SCRIPT" score --wiki-root "$1" --plan "$2" "${@:3}"
}

# Run a VALID-plan score into $OUT, asserting exit 0. A valid plan MUST exit 0;
# if it ever regresses to non-zero, label the failure loudly here instead of
# letting `set -e` abort the whole script silently at a bare `OUT=$(...)`
# assignment (which would skip every later case with no diagnostic).
run_score_ok() {  # run_score_ok <label> <wiki-root> <plan> [extra args...]
  local label="$1"; shift
  if ! OUT=$(run_score "$@"); then
    red "FAIL: $label — wiki-coverage.py exited non-zero on a VALID plan"
    errors=$((errors + 1))
    OUT='{}'
  fi
}

# Generic python assertion harness. The python program arrives on stdin (the
# heredoc attached to the `check` call); the JSON envelope is passed via the
# PAYLOAD env var (so the program reads it with os.environ, leaving stdin free
# for the program itself). The program prints "OK" on success.
check() {  # check <description> <json-envelope>  (program via heredoc on stdin)
  local desc="$1" payload="$2"
  if RESULT=$(PAYLOAD="$payload" python3 2>&1) && [ "$RESULT" = "OK" ]; then
    green "PASS: $desc"
  else
    red "FAIL: $desc"
    red "  $RESULT"
    errors=$((errors + 1))
  fi
}

# --- Case 1: empty wiki -> all uncovered, success:true --------------------
run_score_ok "empty-wiki" "$WIKI" "$WORK/plan.json"
check "empty wiki: success:true, all sub-questions uncovered, 0 pages scanned" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
assert d["success"] is True, "success should be true on a fresh base"
assert d["data"]["pages_scanned"] == 0, "no pages should be scanned"
v = {s["sq_id"]: s["coverage_verdict"] for s in d["data"]["sub_questions"]}
assert v == {"sq-01": "uncovered", "sq-02": "uncovered"}, v
print("OK")
PY

# --- Case 1b: genuinely MISSING wiki/ dir (not just empty) ----------------
# The real fresh-base layout has no wiki/ subdir at all (before any ingest).
# Point --wiki-root at a dir that exists but has no wiki/ — exercises the
# `not d.is_dir()` + missing-index.md branches in _collect_pages.
NOWIKI="$WORK/nowiki"
mkdir -p "$NOWIKI"
run_score_ok "missing-wiki-dir" "$NOWIKI" "$WORK/plan.json"
check "missing wiki/ dir: success:true, 0 pages, all uncovered (no crash)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
assert d["success"] is True, d
assert d["data"]["pages_scanned"] == 0, d["data"]["pages_scanned"]
assert all(s["coverage_verdict"] == "uncovered" for s in d["data"]["sub_questions"])
print("OK")
PY

# --- Seed pages that cover sq-01 ------------------------------------------
cat > "$WIKI/wiki/sources/ai-act-article-6.md" <<'MD'
---
id: ai-act-article-6
title: "EU AI Act Article 6 — High-risk AI system classification scope"
type: source
tags: [source]
---
# EU AI Act Article 6
body
MD
cat > "$WIKI/wiki/syntheses/high-risk-classification.md" <<'MD'
---
id: high-risk-classification
title: "High-risk classification scope under the EU AI Act"
type: synthesis
tags: [synthesis]
---
# synthesis
body
MD
cat > "$WIKI/wiki/index.md" <<'MD'
# Index
## Categories
### High-risk Classification
- [[ai-act-article-6]] — Article 6 defines the high-risk AI system classification criteria and scope.
- [[high-risk-classification]] — Synthesis of high-risk classification scope across the EU AI Act.
MD

# --- Case 2 + 3: sq-01 covered (>=2 pages), correct page_paths incl. syntheses ---
run_score_ok "seeded-wiki" "$WIKI" "$WORK/plan.json"
check "seeded wiki: sq-01 covered with both pages + correct page_paths (incl. wiki/syntheses/)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
assert d["data"]["pages_scanned"] == 2, d["data"]["pages_scanned"]
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-01"]["coverage_verdict"] == "covered", sq["sq-01"]["coverage_verdict"]
assert sq["sq-02"]["coverage_verdict"] == "uncovered", sq["sq-02"]["coverage_verdict"]
paths = {p["slug"]: p["page_path"] for p in sq["sq-01"]["covered_pages"]}
assert paths["ai-act-article-6"] == "wiki/sources/ai-act-article-6.md", paths
# The pluralization guard: synthesis -> syntheses, never synthesiss.
assert paths["high-risk-classification"] == "wiki/syntheses/high-risk-classification.md", paths
# Pages are sorted by overlap descending.
scores = [p["overlap_score"] for p in sq["sq-01"]["covered_pages"]]
assert scores == sorted(scores, reverse=True), scores
print("OK")
PY

# --- Case 4: exactly-one covering page -> `partial` (exercises the middle branch) ---
# Case 2 seeds two pages (-> covered); without a one-page fixture the `partial`
# branch is never exercised and a bug there would ship silently. Build a separate
# wiki with a SINGLE page matching sq-01.
WIKI1="$WORK/wiki1"
mkdir -p "$WIKI1/wiki/sources" "$WIKI1/wiki/syntheses"
cat > "$WIKI1/wiki/sources/ai-act-article-6.md" <<'MD'
---
id: ai-act-article-6
title: "EU AI Act Article 6 — High-risk AI system classification scope"
type: source
tags: [source]
---
# EU AI Act Article 6
body
MD
cat > "$WIKI1/wiki/index.md" <<'MD'
# Index
## Categories
### High-risk Classification
- [[ai-act-article-6]] — Article 6 defines the high-risk AI system classification criteria and scope.
MD
run_score_ok "one-page-wiki" "$WIKI1" "$WORK/plan.json"
check "one covering page: sq-01 verdict is exactly 'partial' (not covered, not uncovered)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-01"]["coverage_verdict"] == "partial", sq["sq-01"]["coverage_verdict"]
assert len(sq["sq-01"]["covered_pages"]) == 1, sq["sq-01"]["covered_pages"]
assert sq["sq-02"]["coverage_verdict"] == "uncovered", sq["sq-02"]["coverage_verdict"]
print("OK")
PY

# --- Case 4b: title-less page falls back to the slug (read-before-web isn't blinded) ---
# A page with NO `title:` line and NO index summary must still match via its
# descriptive slug — without the slug fallback it would tokenize to just its
# `[source]` tag and go invisible to coverage.
WIKI2="$WORK/wiki2"
mkdir -p "$WIKI2/wiki/sources" "$WIKI2/wiki/syntheses"
cat > "$WIKI2/wiki/sources/eu-ai-act-high-risk-classification-scope.md" <<'MD'
---
id: eu-ai-act-high-risk-classification-scope
type: source
tags: [source]
---
# body only, no frontmatter title
MD
run_score_ok "title-less-page" "$WIKI2" "$WORK/plan.json"
check "title-less page: slug fallback still surfaces it for sq-01 (not invisible)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-01"]["coverage_verdict"] in ("covered", "partial"), sq["sq-01"]["coverage_verdict"]
slugs = [p["slug"] for p in sq["sq-01"]["covered_pages"]]
assert "eu-ai-act-high-risk-classification-scope" in slugs, slugs
print("OK")
PY

# --- Case 5: threshold boundary -------------------------------------------
# A very high threshold should drop every page back to uncovered.
run_score_ok "threshold-0.99" "$WIKI" "$WORK/plan.json" --threshold 0.99
check "threshold 0.99: nothing clears -> sq-01 uncovered" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-01"]["coverage_verdict"] == "uncovered", sq["sq-01"]
print("OK")
PY

# A very low (but positive) threshold should let at least one page through.
run_score_ok "threshold-0.01" "$WIKI" "$WORK/plan.json" --threshold 0.01
check "threshold 0.01: sq-01 has covering pages" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-01"]["coverage_verdict"] in ("covered", "partial"), sq["sq-01"]["coverage_verdict"]
assert len(sq["sq-01"]["covered_pages"]) >= 1
print("OK")
PY

# An out-of-range threshold is rejected.
if python3 "$SCRIPT" score --wiki-root "$WIKI" --plan "$WORK/plan.json" --threshold 1.5 >/dev/null 2>&1; then
  red "FAIL: --threshold 1.5 should be rejected"
  errors=$((errors + 1))
else
  green "PASS: out-of-range (>1) --threshold is rejected"
fi

# --threshold 0 is meaningless (jaccard 0.0 >= 0.0 would cover everything) and
# must be rejected by the exclusive lower bound.
if python3 "$SCRIPT" score --wiki-root "$WIKI" --plan "$WORK/plan.json" --threshold 0 >/dev/null 2>&1; then
  red "FAIL: --threshold 0 should be rejected (would cover every page with zero overlap)"
  errors=$((errors + 1))
else
  green "PASS: --threshold 0 is rejected (exclusive lower bound)"
fi

# --- Case 5: malformed plan.json -> clean success:false -------------------
printf '%s' '{bad json' > "$WORK/bad-plan.json"
if OUT=$(run_score "$WIKI" "$WORK/bad-plan.json" 2>/dev/null); then
  red "FAIL: malformed plan.json should exit non-zero"
  errors=$((errors + 1))
else
  check "malformed plan.json: success:false with an error message" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
assert d["success"] is False, d
assert d["error"], "error message should be non-empty"
print("OK")
PY
fi

# A plan with no sub_questions[] list is also a clean failure.
printf '%s' '{"schema_version":"0.1.0"}' > "$WORK/no-sq.json"
if OUT=$(run_score "$WIKI" "$WORK/no-sq.json" 2>/dev/null); then
  red "FAIL: plan without sub_questions[] should exit non-zero"
  errors=$((errors + 1))
else
  check "plan without sub_questions[]: success:false" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
assert d["success"] is False, d
print("OK")
PY
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi
green ""
green "wiki-coverage.py coverage-scorer contract all pass."
