#!/usr/bin/env bash
# test_retrieval_eval.sh — script unit tests for scripts/retrieval-eval.py
# (the read-only retrieval-quality baseline harness: hit@1 / hit@5 / MRR over
# the shared wiki-grounding.py rank primitive).
#
# Contract under test:
#   1. `eval` envelope shape: success:true with
#      data.aggregate.{hit_at_1,hit_at_5,mrr,n_queries} + data.per_query[] on a
#      populated base, and the results JSON written under .cogni-knowledge/.
#   2. An exact-match query (ground-truth page IS the top covering page) scores
#      hit_at_1==1 / hit_at_5==1 / reciprocal_rank==1.0.
#   3. A no-match query (ground-truth slug present, but the query overlaps no
#      page) scores hit_at_1==0 / hit_at_5==0 / reciprocal_rank==0.0.
#   4. Aggregate over the two: hit_at_1==0.5, hit_at_5==0.5, mrr==0.5.
#   5. Seeding from wiki/questions/*.md sources_answering: the harness writes a
#      versioned retrieval-eval-set.json on first run.
#   6. READ-ONLY invariant: the wiki/ tree is byte-identical before and after a
#      run (the harness only writes under .cogni-knowledge/).
#
# bash 3.2 + python3 stdlib only (no pytest, no pip). Matches tests/README.md.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVAL="$PLUGIN_ROOT/scripts/retrieval-eval.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

WIKI="$WORK/base"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/questions"

# One source page that strongly overlaps the "high-risk classification" query.
cat > "$WIKI/wiki/sources/eu-ai-act-high-risk-classification.md" <<'MD'
---
title: EU AI Act high-risk classification
tags: [source]
sources: ["https://eur-lex.europa.eu/ai-act"]
pre_extracted_claims:
  - id: clm-001
    text: "Article 6 sets the high-risk classification rules for AI systems."
MD

# A second, unrelated source page so the base has >1 page (rank ordering is real).
cat > "$WIKI/wiki/sources/unrelated-topic.md" <<'MD'
---
title: Quantum cryptography hardware roadmaps
tags: [source]
pre_extracted_claims:
  - id: clm-001
    text: "Lattice-based primitives dominate post-quantum hardware accelerators."
MD

cat > "$WIKI/wiki/index.md" <<'MD'
# Wiki Index

## Sources
- [[eu-ai-act-high-risk-classification]] — EU AI Act high-risk classification scope and rules
- [[unrelated-topic]] — Quantum cryptography hardware roadmaps
MD

# Question node 1: query overlaps the high-risk source -> exact hit at rank 1.
cat > "$WIKI/wiki/questions/q-high-risk.md" <<'MD'
---
id: q-high-risk
title: "EU AI Act high-risk classification rules for AI systems"
type: question
tags: [question]
theme_label: "High Risk Classification"
sub_question_id: sq-01
sources_answering: [eu-ai-act-high-risk-classification]
---

## Findings

- [[eu-ai-act-high-risk-classification]]
MD

# Question node 2: query overlaps NEITHER page, but its ground truth slug exists
# -> guaranteed miss (rank None -> hit@1=0, hit@5=0, RR=0).
cat > "$WIKI/wiki/questions/q-nomatch.md" <<'MD'
---
id: q-nomatch
title: "Maritime shipping container logistics tariffs schedules"
type: question
tags: [question]
theme_label: "Maritime Logistics"
sub_question_id: sq-02
sources_answering: [eu-ai-act-high-risk-classification]
---

## Findings

- [[eu-ai-act-high-risk-classification]]
MD

# Snapshot the wiki/ tree to prove the read-only invariant later.
WIKI_HASH_BEFORE=$(find "$WIKI/wiki" -type f -exec shasum {} \; | sort | shasum)

# --- Run the harness -------------------------------------------------------
OUT=$("$EVAL" eval --wiki-root "$WIKI" 2>/dev/null) || true
echo "$OUT" > "$WORK/eval-out.json"

# 1. Envelope shape.
assert_grep '"success": true' "$WORK/eval-out.json" "eval emits success:true envelope"
assert_grep '"aggregate"'     "$WORK/eval-out.json" "data carries an aggregate block"
assert_grep '"per_query"'     "$WORK/eval-out.json" "data carries a per_query block"
assert_grep '"mrr"'           "$WORK/eval-out.json" "aggregate reports mrr"

# Pull the computed metrics out with python for exact-value assertions.
python3 - "$WORK/eval-out.json" <<'PY' > "$WORK/metrics.txt" 2>/dev/null || true
import json, sys
d = json.load(open(sys.argv[1]))
agg = d["data"]["aggregate"]
pq = {p["query"][:12]: p for p in d["data"]["per_query"]}
print("n_queries", agg["n_queries"])
print("hit_at_1", agg["hit_at_1"])
print("hit_at_5", agg["hit_at_5"])
print("mrr", agg["mrr"])
# the high-risk query (exact match) and the maritime query (no match)
hr = next(p for p in d["data"]["per_query"] if "high-risk" in p["query"].lower())
nm = next(p for p in d["data"]["per_query"] if "maritime" in p["query"].lower())
print("hr_rank", hr["rank_of_first_relevant"])
print("hr_h1", hr["hit_at_1"])
print("nm_rank", nm["rank_of_first_relevant"])
print("nm_h1", nm["hit_at_1"])
print("nm_rr", nm["reciprocal_rank"])
PY

# 2. Exact-match query: rank 1, hit@1.
assert_grep '^hr_rank 1$' "$WORK/metrics.txt" "exact-match query ranks its ground-truth page at 1"
assert_grep '^hr_h1 1$'   "$WORK/metrics.txt" "exact-match query scores hit@1"

# 3. No-match query: no relevant page in passing set, RR 0.
assert_grep '^nm_rank None$' "$WORK/metrics.txt" "no-match query finds no relevant page"
assert_grep '^nm_h1 0$'      "$WORK/metrics.txt" "no-match query scores hit@1==0"
assert_grep '^nm_rr 0.0$'    "$WORK/metrics.txt" "no-match query scores reciprocal_rank==0.0"

# 4. Aggregate over the two queries.
assert_grep '^n_queries 2$' "$WORK/metrics.txt" "two queries seeded from question nodes"
assert_grep '^hit_at_1 0.5$' "$WORK/metrics.txt" "aggregate hit@1 == 0.5"
assert_grep '^hit_at_5 0.5$' "$WORK/metrics.txt" "aggregate hit@5 == 0.5"
assert_grep '^mrr 0.5$'      "$WORK/metrics.txt" "aggregate MRR == 0.5"

# 5. Seeding wrote a versioned labelled set + a results file under .cogni-knowledge/.
if [ -f "$WIKI/.cogni-knowledge/retrieval-eval-set.json" ]; then
  green "PASS: labelled set seeded to .cogni-knowledge/retrieval-eval-set.json"
else
  red "FAIL: labelled set was not written under .cogni-knowledge/"
  errors=$((errors + 1))
fi
if [ -f "$WIKI/.cogni-knowledge/retrieval-eval.json" ]; then
  green "PASS: run results persisted to .cogni-knowledge/retrieval-eval.json"
else
  red "FAIL: run results were not persisted under .cogni-knowledge/"
  errors=$((errors + 1))
fi

# 6. READ-ONLY invariant: wiki/ tree unchanged.
WIKI_HASH_AFTER=$(find "$WIKI/wiki" -type f -exec shasum {} \; | sort | shasum)
if [ "$WIKI_HASH_BEFORE" = "$WIKI_HASH_AFTER" ]; then
  green "PASS: wiki/ tree byte-unchanged after eval (read-only invariant holds)"
else
  red "FAIL: wiki/ tree changed during eval — harness is not read-only"
  errors=$((errors + 1))
fi

# --- bad-threshold rejection ----------------------------------------------
BAD=$("$EVAL" eval --wiki-root "$WIKI" --threshold 0 2>/dev/null) || true
echo "$BAD" > "$WORK/bad.json"
assert_grep '"success": false' "$WORK/bad.json" "threshold 0 is rejected (exclusive lower bound)"

if [ "$errors" -eq 0 ]; then
  green "All retrieval-eval tests passed."
  exit 0
else
  red "$errors retrieval-eval test(s) failed."
  exit 1
fi
