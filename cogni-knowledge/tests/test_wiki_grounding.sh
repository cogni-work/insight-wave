#!/usr/bin/env bash
# test_wiki_grounding.sh — script unit tests for scripts/wiki-grounding.py
# (#388 Phase 8 d2 core — the shared wiki-discovery primitive).
#
# wiki-grounding.py is the ONE discovery mechanism the FMO ships: the
# index→select→read→score logic was extracted out of wiki-coverage.py so both
# the inverted-pipeline read-side (wiki-coverage.py) and the re-homed query
# skill resolve to the same primitive instead of two parallel implementations.
#
# Contract under test:
#   1. `rank` envelope shape: success:true with data.{pages_scanned,
#      coverage_verdict, pages[]} on a populated base.
#   2. fail-soft: a fresh / missing wiki -> pages_scanned 0, coverage_verdict
#      uncovered, pages [] (the run-1 no-regression guarantee, inherited).
#   3. THE DE-DUPLICATION PROOF: for the same sub-question (query + theme_label),
#      `wiki-grounding rank` returns exactly the same covering page set as
#      `wiki-coverage score` does for that sub-question — i.e. both call sites
#      provably resolve to the one primitive. This is the issue's explicit
#      acceptance criterion.
#   4. bad --threshold (0, >1) is rejected (exclusive lower bound, inherited).
#
# bash 3.2 + python3 stdlib only (no pytest, no pip). Matches tests/README.md.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GROUNDING="$PLUGIN_ROOT/scripts/wiki-grounding.py"
COVERAGE="$PLUGIN_ROOT/scripts/wiki-coverage.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

WIKI="$WORK/wiki"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/syntheses"

# Two pages that overlap an EU-AI-Act high-risk sub-question (one source, one
# synthesis so the 'syntheses' pluralization path is exercised), plus an index
# one-liner per page (the richest signal).
cat > "$WIKI/wiki/sources/eu-ai-act-high-risk-classification.md" <<'MD'
---
title: EU AI Act high-risk classification
tags: [source]
sources: ["https://eur-lex.europa.eu/ai-act"]
pre_extracted_claims:
  - id: clm-001
    text: "Article 6 sets the high-risk classification rules for AI systems."
MD

cat > "$WIKI/wiki/syntheses/high-risk-obligations.md" <<'MD'
---
title: High-risk classification obligations
tags: [synthesis]
pre_extracted_claims:
  - id: clm-001
    text: "High-risk AI systems must meet classification and transparency obligations."
MD

cat > "$WIKI/wiki/index.md" <<'MD'
# Wiki Index

## Sources
- [[eu-ai-act-high-risk-classification]] — EU AI Act high-risk classification scope and rules

## Syntheses
- [[high-risk-obligations]] — High-risk classification obligations and transparency
MD

# Single-sub-question plan reused for the equivalence proof (Case 3).
cat > "$WORK/plan.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "sub_questions": [
    {"id": "sq-01",
     "query": "EU AI Act high-risk classification scope transparency obligations",
     "theme_label": "High-risk Classification"}
  ]
}
JSON

QUERY="EU AI Act high-risk classification scope transparency obligations"
THEME="High-risk Classification"

# --- Case 1: rank envelope shape on a populated base -------------------------
if OUT=$(python3 "$GROUNDING" rank --wiki-root "$WIKI" --question "$QUERY" --theme-label "$THEME"); then
  if echo "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, 'success not true'
data=d['data']
assert data['pages_scanned'] == 2, f'expected 2 pages scanned, got {data[\"pages_scanned\"]}'
assert data['coverage_verdict'] == 'covered', f'expected covered, got {data[\"coverage_verdict\"]}'
slugs={p['slug'] for p in data['pages']}
assert slugs == {'eu-ai-act-high-risk-classification','high-risk-obligations'}, f'unexpected slugs {slugs}'
# each page carries the documented shape
for p in data['pages']:
    for k in ('slug','type','page_path','title','overlap_score','reasons'):
        assert k in p, f'page missing {k}'
# the synthesis page_path is pluralized correctly
paths={p['page_path'] for p in data['pages']}
assert 'wiki/syntheses/high-risk-obligations.md' in paths, f'bad synthesis path {paths}'
"; then
    green "PASS: rank envelope: success:true, 2 pages scanned, both pages covered, shape + syntheses path correct"
  else
    red "FAIL: rank envelope shape assertion failed"; errors=$((errors+1))
  fi
else
  red "FAIL: rank exited non-zero on a populated base"; errors=$((errors+1))
fi

# --- Case 2: fail-soft on a fresh / missing base -----------------------------
FRESH="$WORK/fresh"
mkdir -p "$FRESH"
if OUT=$(python3 "$GROUNDING" rank --wiki-root "$FRESH" --question "$QUERY" --theme-label "$THEME"); then
  if echo "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, 'success not true on fresh base'
data=d['data']
assert data['pages_scanned'] == 0, f'expected 0 pages, got {data[\"pages_scanned\"]}'
assert data['coverage_verdict'] == 'uncovered', f'expected uncovered, got {data[\"coverage_verdict\"]}'
assert data['pages'] == [], f'expected no pages, got {data[\"pages\"]}'
"; then
    green "PASS: fail-soft on a fresh base: success:true, 0 pages, uncovered (no regression)"
  else
    red "FAIL: fresh-base fail-soft assertion failed"; errors=$((errors+1))
  fi
else
  red "FAIL: rank exited non-zero on a fresh base (should be fail-soft success)"; errors=$((errors+1))
fi

# --- Case 3: THE DE-DUPLICATION PROOF ----------------------------------------
# wiki-grounding rank (single SQ) must return the SAME covering page set as
# wiki-coverage score does for that SQ — both call sites resolve to one primitive.
GROUND_OUT=$(python3 "$GROUNDING" rank --wiki-root "$WIKI" --question "$QUERY" --theme-label "$THEME")
COVER_OUT=$(python3 "$COVERAGE" score --wiki-root "$WIKI" --plan "$WORK/plan.json")
if printf '%s\0%s' "$GROUND_OUT" "$COVER_OUT" | python3 -c "
import json,sys
raw=sys.stdin.buffer.read().split(b'\x00')
ground=json.loads(raw[0]); cover=json.loads(raw[1])
g_pages=ground['data']['pages']
sq=cover['data']['sub_questions'][0]
c_pages=sq['covered_pages']
# Same verdict.
assert ground['data']['coverage_verdict'] == sq['coverage_verdict'], \
    f'verdict mismatch: grounding={ground[\"data\"][\"coverage_verdict\"]} coverage={sq[\"coverage_verdict\"]}'
# Same covering set, in the same order, with the same per-page fields.
assert g_pages == c_pages, f'covering set diverged:\n grounding={g_pages}\n coverage={c_pages}'
"; then
  green "PASS: de-duplication proof: wiki-grounding rank == wiki-coverage score for the same sub-question"
else
  red "FAIL: wiki-grounding and wiki-coverage produced different covering sets — they are NOT one primitive"; errors=$((errors+1))
fi

# --- Case 4: bad threshold rejected ------------------------------------------
if python3 "$GROUNDING" rank --wiki-root "$WIKI" --question "$QUERY" --threshold 0 >/dev/null 2>&1; then
  red "FAIL: --threshold 0 was accepted (must be rejected, exclusive lower bound)"; errors=$((errors+1))
else
  green "PASS: --threshold 0 is rejected (exclusive lower bound)"
fi
if python3 "$GROUNDING" rank --wiki-root "$WIKI" --question "$QUERY" --threshold 1.5 >/dev/null 2>&1; then
  red "FAIL: --threshold 1.5 was accepted (must be rejected, >1)"; errors=$((errors+1))
else
  green "PASS: out-of-range (>1) --threshold is rejected"
fi

echo
if [ "$errors" -eq 0 ]; then
  green "wiki-grounding.py shared-primitive contract all pass."
else
  red "wiki-grounding.py contract: $errors failure(s)."
  exit 1
fi
