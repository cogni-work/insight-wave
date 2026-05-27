#!/usr/bin/env bash
# test_citation_store.sh — smoke test for citation-store.py (Phase 5 manifest
# assembly, #325).
#
# Asserts:
#   1. build round-trips the hard cases the LLM-hand-built JSON broke on:
#      a straight ASCII `"`, the exact #311 German `„Profiling natürlicher
#      Personen"` pair (closing with an ASCII quote), and a backslash. Output
#      json.loads cleanly, each draft_sentence is byte-equal to its records
#      input, citations_count == record count.
#   2. A `claim: null` record emits JSON null (synthesis citation).
#   3. Negative: a draft_sentence NOT in the draft → success:false,
#      error:"write_failed", and NO manifest is written.
#   4. Edge: missing records file / missing draft → success:false; an empty
#      records file → a valid EMPTY manifest (success, count 0).
#   5. The built manifest is accepted by verify-store.py shard (the downstream
#      consumer #325 broke — every entry carries id + draft_sentence).
#
# Fixtures are written by python3 heredocs so the bytes (Unicode, quotes,
# backslash) are exact and the test exercises the SCRIPT, not bash quoting.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/citation-store.py"
VERIFY="$PLUGIN_ROOT/scripts/verify-store.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: citation-store.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

# Write the records + matching draft fixtures byte-exact via python3.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
records = (
    "- id: cit-001\n"
    "  pos: 02:03\n"
    "  slug: eu-ai-act-article-6\n"
    "  claim: clm-001\n"
    '  sentence: She said "high-risk" applies here<sup>[1](https://x.eu/a)</sup>.\n'
    "- id: cit-002\n"
    "  pos: 02:05\n"
    "  slug: eu-ai-act-article-6\n"
    "  claim: null\n"
    '  sentence: bei Systemen, die ein „Profiling natürlicher Personen" durchführen<sup>[3](https://x.eu/c)</sup>.\n'
    "- id: cit-003\n"
    "  pos: 03:01\n"
    "  slug: regex-page\n"
    "  claim: clm-009\n"
    '  sentence: The pattern \\d+ matches one or more digits<sup>[2](https://x.eu/b)</sup>.\n'
)
draft = (
    '# Report\n\n'
    'She said "high-risk" applies here<sup>[1](https://x.eu/a)</sup>.\n'
    'bei Systemen, die ein „Profiling natürlicher Personen" durchführen<sup>[3](https://x.eu/c)</sup>.\n'
    'The pattern \\d+ matches one or more digits<sup>[2](https://x.eu/b)</sup>.\n\n'
    '## References\n[[sources/eu-ai-act-article-6]]\n'
)
(work / "records.txt").write_text(records, encoding="utf-8")
(work / "draft-v1.md").write_text(draft, encoding="utf-8")
# Expected per-citation sentences, for the byte-equal round-trip assertion.
import json
expected = [
    'She said "high-risk" applies here<sup>[1](https://x.eu/a)</sup>.',
    'bei Systemen, die ein „Profiling natürlicher Personen" durchführen<sup>[3](https://x.eu/c)</sup>.',
    'The pattern \\d+ matches one or more digits<sup>[2](https://x.eu/b)</sup>.',
]
(work / "expected.json").write_text(json.dumps(expected), encoding="utf-8")
PY

# 1 + 2. build the hard-case manifest.
OUT=$(python3 "$SCRIPT" build \
  --records "$WORK/records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/citation-manifest.json" --draft-version 1)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['citations_count'] == 3, d
" 2>/dev/null; then
  green "PASS: build succeeds on quotes / German pair / backslash → citations_count 3"
else
  red "FAIL: build envelope wrong"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if python3 - "$WORK" <<'PY' > /dev/null
import sys, json, pathlib
work = pathlib.Path(sys.argv[1])
m = json.loads((work / "citation-manifest.json").read_text(encoding="utf-8"))
assert m["schema_version"] == "0.1.0" and m["draft_version"] == 1, m
cites = m["citations"]
assert len(cites) == 3, cites
expected = json.loads((work / "expected.json").read_text(encoding="utf-8"))
for c, exp in zip(cites, expected):
    # Byte-equal round-trip of the verbatim sentence through json.dumps/json.loads.
    assert c["draft_sentence"] == exp, (c["draft_sentence"], exp)
    assert "id" in c and "wiki_slug" in c and "claim_id" in c and "draft_position" in c, c
# claim: null → JSON null (synthesis citation).
assert cites[1]["claim_id"] is None, cites[1]
assert cites[0]["claim_id"] == "clm-001" and cites[2]["claim_id"] == "clm-009", cites
PY
then
  green "PASS: manifest json.loads clean; draft_sentence byte-equal; claim:null → JSON null"
else
  red "FAIL: manifest content / round-trip wrong"
  errors=$((errors + 1))
fi

# 5. Downstream: verify-store.py shard accepts the built manifest (the #325 break).
if python3 "$VERIFY" shard --manifest "$WORK/citation-manifest.json" \
     --draft-version 1 --shard-size 40 --out-dir "$WORK/verify-shards" \
   | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citation_count']==3, d" 2>/dev/null; then
  green "PASS: verify-store.py shard accepts the built manifest (downstream #325 path)"
else
  red "FAIL: verify-store.py shard rejected the built manifest"
  errors=$((errors + 1))
fi

# 3. Negative: a draft_sentence NOT in the draft → write_failed, no manifest.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
(work / "bad-records.txt").write_text(
    "- id: cit-001\n  pos: 0:1\n  slug: p\n  claim: clm-001\n"
    "  sentence: This sentence is absent from the draft entirely.\n",
    encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/bad-records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/bad-manifest.json" --draft-version 1 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'sentence_not_in_draft' and d['data']['ids'] == ['cit-001'], d
" 2>/dev/null && [ ! -f "$WORK/bad-manifest.json" ]; then
  green "PASS: sentence-not-in-draft → write_failed, no manifest written"
else
  red "FAIL: negative substring case wrong (or manifest leaked)"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 4a. Missing records file → success:false (records_not_found).
OUT=$(python3 "$SCRIPT" build --records "$WORK/nope.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/x.json" --draft-version 1 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and d['error']=='records_not_found', d" 2>/dev/null; then
  green "PASS: missing records file rejected (records_not_found)"
else
  red "FAIL: missing records file not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 4b. Missing draft → success:false (draft_not_found).
OUT=$(python3 "$SCRIPT" build --records "$WORK/records.txt" --draft "$WORK/nope-draft.md" \
  --out "$WORK/y.json" --draft-version 1 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and d['error']=='draft_not_found', d" 2>/dev/null; then
  green "PASS: missing draft rejected (draft_not_found)"
else
  red "FAIL: missing draft not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 4c. Empty records → valid EMPTY manifest (success, count 0). Zero citations is
#     a tolerated upstream-data state (Step 5 WARN), not a build error.
: > "$WORK/empty-records.txt"
OUT=$(python3 "$SCRIPT" build --records "$WORK/empty-records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/empty-manifest.json" --draft-version 1)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==0, d" 2>/dev/null \
   && python3 -c "import json; m=json.load(open('$WORK/empty-manifest.json')); assert m['citations']==[] and m['schema_version']=='0.1.0', m" 2>/dev/null; then
  green "PASS: empty records → valid empty manifest (success, count 0)"
else
  red "FAIL: empty records did not yield a valid empty manifest"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
