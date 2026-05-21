#!/usr/bin/env bash
# test_candidate_store.sh - smoke test for candidate-store.py.
#
# Asserts:
#   1. init creates an empty candidates.json with schema 0.1.0 and is idempotent
#      across re-runs.
#   2. append-batch merges two batches with an overlapping URL; the overlap
#      is deduped, the higher score wins, sub_question_refs are unioned,
#      earliest discovered_at wins, fetch_priority is re-assigned.
#   3. Two concurrent append-batch subshells racing on the same project end
#      with all batch entries present and a valid JSON file (file-lock works).
#   4. Malformed inputs are rejected with success:false and a clear error:
#      - non-array batch
#      - candidate missing url
#      - candidate with out-of-range score
#   5. URL normalization collapses scheme/host case, trailing slash, and
#      tracking query params to a single entry.
#
# bash 3.2 + stdlib python3 only. Posix only (uses fcntl.flock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/candidate-store.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: candidate-store.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

PROJ="$WORK/project"
mkdir -p "$PROJ"

# 1. init creates empty candidates.json + idempotent.
python3 "$SCRIPT" init --project-path "$PROJ" >/dev/null
INIT_AGAIN=$(python3 "$SCRIPT" init --project-path "$PROJ")
if echo "$INIT_AGAIN" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['created'] is False, d
assert d['data']['candidates_count'] == 0, d
print('OK')
" | grep -q OK; then
  green "PASS: init creates empty candidates.json and is idempotent"
else
  red "FAIL: init not idempotent"
  red "  got: $INIT_AGAIN"
  errors=$((errors + 1))
fi

SCHEMA=$(python3 -c "import json; print(json.load(open('$PROJ/.metadata/candidates.json'))['schema_version'])")
if [ "$SCHEMA" = "0.1.0" ]; then
  green "PASS: init writes schema_version 0.1.0"
else
  red "FAIL: schema_version expected 0.1.0, got '$SCHEMA'"
  errors=$((errors + 1))
fi

# 2. append-batch dedup + merge semantics.
BATCH_A="$WORK/batch-a.json"
cat > "$BATCH_A" <<'JSON'
[
  {"url": "https://europa.eu/article-6", "title": "Article 6", "score": 0.85,
   "sub_question_refs": ["sq-01"], "publisher": "europa.eu",
   "discovered_at": "2026-05-20T10:00:00Z"},
  {"url": "https://example.org/gdpr-art-30", "title": "Art 30 GDPR", "score": 0.71,
   "sub_question_refs": ["sq-02"], "publisher": "example.org",
   "discovered_at": "2026-05-20T10:00:01Z"}
]
JSON

BATCH_B="$WORK/batch-b.json"
cat > "$BATCH_B" <<'JSON'
[
  {"url": "https://europa.eu/article-6", "title": "Article 6 (alt)", "score": 0.92,
   "sub_question_refs": ["sq-03"], "publisher": "europa.eu",
   "discovered_at": "2026-05-20T11:00:00Z"},
  {"url": "https://acme.io/new-source", "title": "Acme", "score": 0.42,
   "sub_question_refs": ["sq-02"], "publisher": "acme.io",
   "discovered_at": "2026-05-20T11:00:01Z"}
]
JSON

python3 "$SCRIPT" append-batch --project-path "$PROJ" --batch-file "$BATCH_A" >/dev/null
python3 "$SCRIPT" append-batch --project-path "$PROJ" --batch-file "$BATCH_B" >/dev/null

if python3 - <<PY > /dev/null
import json
data = json.load(open('$PROJ/.metadata/candidates.json'))
cands = data['candidates']
assert len(cands) == 3, cands  # europa deduped, example + acme added
by_url = {c['url']: c for c in cands}
ea = by_url['https://europa.eu/article-6']
assert ea['score'] == 0.92, ea  # higher score wins
assert ea['title'] == 'Article 6 (alt)', ea  # higher-score entry's fields win
assert ea['tier'] == 'primary', ea  # >= 0.80
assert ea['discovered_at'] == '2026-05-20T10:00:00Z', ea  # earliest wins
assert sorted(ea['sub_question_refs']) == ['sq-01', 'sq-03'], ea  # unioned
# fetch_priority deterministic: europa (primary, 0.92) → 1, example (secondary, 0.71) → 2,
# acme (supporting, 0.42) → 3.
prios = {c['url']: c['fetch_priority'] for c in cands}
assert prios['https://europa.eu/article-6'] == 1, prios
assert prios['https://example.org/gdpr-art-30'] == 2, prios
assert prios['https://acme.io/new-source'] == 3, prios
PY
then
  green "PASS: append-batch dedup, score-win, ref-union, fetch_priority assignment"
else
  red "FAIL: dedup/merge semantics broken"
  errors=$((errors + 1))
fi

# 3. Concurrent append (two subshells racing).
PROJ2="$WORK/project2"
mkdir -p "$PROJ2"
python3 "$SCRIPT" init --project-path "$PROJ2" >/dev/null

BATCH_C="$WORK/batch-c.json"
BATCH_D="$WORK/batch-d.json"
python3 - <<PY
import json
batch_c = [{"url": f"https://race.test/c-{i}", "title": f"C-{i}", "score": 0.7,
            "sub_question_refs": ["sq-A"], "publisher": "race.test",
            "discovered_at": "2026-05-20T12:00:00Z"} for i in range(20)]
batch_d = [{"url": f"https://race.test/d-{i}", "title": f"D-{i}", "score": 0.6,
            "sub_question_refs": ["sq-B"], "publisher": "race.test",
            "discovered_at": "2026-05-20T12:00:01Z"} for i in range(20)]
open("$BATCH_C", "w").write(json.dumps(batch_c))
open("$BATCH_D", "w").write(json.dumps(batch_d))
PY

(python3 "$SCRIPT" append-batch --project-path "$PROJ2" --batch-file "$BATCH_C" >/dev/null) &
PID_C=$!
(python3 "$SCRIPT" append-batch --project-path "$PROJ2" --batch-file "$BATCH_D" >/dev/null) &
PID_D=$!
wait $PID_C
wait $PID_D

if python3 - <<PY > /dev/null
import json
data = json.load(open('$PROJ2/.metadata/candidates.json'))
cands = data['candidates']
assert len(cands) == 40, f"expected 40, got {len(cands)}"
urls = {c['url'] for c in cands}
expected = {f"https://race.test/c-{i}" for i in range(20)} | {f"https://race.test/d-{i}" for i in range(20)}
assert urls == expected, urls.symmetric_difference(expected)
PY
then
  green "PASS: concurrent append-batch — file lock preserves both batches' content"
else
  red "FAIL: concurrent append lost data"
  errors=$((errors + 1))
fi

# 4a. Non-array batch → reject.
BAD_BATCH="$WORK/bad-not-array.json"
echo '{"not": "an array"}' > "$BAD_BATCH"
OUT=$(python3 "$SCRIPT" append-batch --project-path "$PROJ" --batch-file "$BAD_BATCH" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'array' in d['error'].lower()" 2>/dev/null; then
  green "PASS: non-array batch rejected"
else
  red "FAIL: non-array batch not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 4b. Missing url → reject.
BAD_URL="$WORK/bad-url.json"
echo '[{"score": 0.5, "sub_question_refs": []}]' > "$BAD_URL"
OUT=$(python3 "$SCRIPT" append-batch --project-path "$PROJ" --batch-file "$BAD_URL" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'url' in d['error'].lower()" 2>/dev/null; then
  green "PASS: missing-url candidate rejected"
else
  red "FAIL: missing-url candidate not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 4c. Out-of-range score → reject.
BAD_SCORE="$WORK/bad-score.json"
echo '[{"url": "https://x.io/y", "score": 1.5, "sub_question_refs": []}]' > "$BAD_SCORE"
OUT=$(python3 "$SCRIPT" append-batch --project-path "$PROJ" --batch-file "$BAD_SCORE" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'score' in d['error'].lower()" 2>/dev/null; then
  green "PASS: out-of-range score rejected"
else
  red "FAIL: out-of-range score not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 5. URL normalization: scheme/host case + trailing slash + tracking params
# collapse to one entry.
PROJ3="$WORK/project3"
mkdir -p "$PROJ3"
python3 "$SCRIPT" init --project-path "$PROJ3" >/dev/null

NORM_BATCH="$WORK/norm-batch.json"
cat > "$NORM_BATCH" <<'JSON'
[
  {"url": "https://Foo.COM/Article/?utm_source=a&utm_medium=b",
   "title": "v1", "score": 0.7, "sub_question_refs": ["sq-1"],
   "discovered_at": "2026-05-20T10:00:00Z"},
  {"url": "HTTPS://foo.com/Article?fbclid=xyz",
   "title": "v2", "score": 0.8, "sub_question_refs": ["sq-2"],
   "discovered_at": "2026-05-20T10:00:01Z"}
]
JSON

python3 "$SCRIPT" append-batch --project-path "$PROJ3" --batch-file "$NORM_BATCH" >/dev/null
if python3 - <<PY > /dev/null
import json
data = json.load(open('$PROJ3/.metadata/candidates.json'))
cands = data['candidates']
assert len(cands) == 1, f"expected 1 deduped entry, got {len(cands)}: {[c['url'] for c in cands]}"
c = cands[0]
assert c['score'] == 0.8, c  # higher score wins
assert sorted(c['sub_question_refs']) == ['sq-1', 'sq-2'], c
PY
then
  green "PASS: URL normalization collapses scheme-case, trailing slash, and tracking params"
else
  red "FAIL: URL normalization broken"
  errors=$((errors + 1))
fi

# 6. Empty batch is a no-op — does not rewrite candidates.json on disk
# (early-return optimisation; verified via mtime).
PROJ4="$WORK/project4"
mkdir -p "$PROJ4"
python3 "$SCRIPT" init --project-path "$PROJ4" >/dev/null
EMPTY_BATCH="$WORK/empty-batch.json"
echo '[]' > "$EMPTY_BATCH"
BEFORE_MTIME=$(python3 -c "import os; print(int(os.stat('$PROJ4/.metadata/candidates.json').st_mtime_ns))")
# Sleep just enough to make a mtime-change observable if the file is rewritten.
sleep 0.05
EMPTY_OUT=$(python3 "$SCRIPT" append-batch --project-path "$PROJ4" --batch-file "$EMPTY_BATCH")
AFTER_MTIME=$(python3 -c "import os; print(int(os.stat('$PROJ4/.metadata/candidates.json').st_mtime_ns))")
if [ "$BEFORE_MTIME" = "$AFTER_MTIME" ] && echo "$EMPTY_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True and d['data']['added'] == 0 and d['data']['merged'] == 0, d
"; then
  green "PASS: empty batch short-circuits — no rewrite, added=merged=0"
else
  red "FAIL: empty batch triggered a rewrite or wrong envelope"
  red "  before: $BEFORE_MTIME, after: $AFTER_MTIME"
  red "  got:    $EMPTY_OUT"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
