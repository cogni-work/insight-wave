#!/usr/bin/env bash
# test_verify_store.sh — smoke test for verify-store.py (Phase 6 fan-out).
#
# Asserts:
#   1. shard splits N citations into ⌈N/size⌉ shard manifests, each a valid
#      citation-manifest (schema 0.1.0 + draft_version carried) with the
#      id/draft_sentence fields preserved; the union of shard citations equals
#      the original (no loss, no dup); the envelope reports shard_count.
#   2. A draft with citations <= shard-size yields exactly one shard.
#   3. merge concatenates per-shard verify fragments into verify-vN.json,
#      recomputes counts (counts.total == verified+deviations), sets
#      draft_version + revision_round, and reports shards_merged.
#   4. Idempotent re-shard clears stale shard/fragment files for the version.
#   5. Malformed inputs are rejected with success:false:
#      - missing manifest
#      - non-0.1.0 schema
#      - draft_version mismatch
#      - merge with no fragments present
#
# NOTE: no concurrency/file-lock case — unlike candidate-store.py, shards are
# partition-disjoint and merge is single-shot, so there is no shared-write
# contention to guard.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/verify-store.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: verify-store.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

# A 5-citation manifest at draft_version 1.
MANIFEST="$WORK/citation-manifest.json"
cat > "$MANIFEST" <<'JSON'
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "citations": [
    {"id": "cit-001", "draft_position": "00:01", "draft_sentence": "Sentence one.", "wiki_slug": "page-a", "claim_id": "clm-001"},
    {"id": "cit-002", "draft_position": "00:02", "draft_sentence": "Sentence two.", "wiki_slug": "page-a", "claim_id": "clm-002"},
    {"id": "cit-003", "draft_position": "01:01", "draft_sentence": "Sentence three.", "wiki_slug": "page-b", "claim_id": "clm-003"},
    {"id": "cit-004", "draft_position": "01:02", "draft_sentence": "Sentence four.", "wiki_slug": "page-b", "claim_id": null},
    {"id": "cit-005", "draft_position": "02:01", "draft_sentence": "Sentence five.", "wiki_slug": "page-c", "claim_id": "clm-005"}
  ]
}
JSON

# 1. shard: 5 citations, size 2 → 3 shards (2,2,1); subsets valid + union exact.
SHARDS="$WORK/verify-shards"
SHARD_OUT=$(python3 "$SCRIPT" shard --manifest "$MANIFEST" --draft-version 1 --shard-size 2 --out-dir "$SHARDS")
if echo "$SHARD_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['shard_count'] == 3, d
assert d['data']['citation_count'] == 5, d
counts = [s['citation_count'] for s in d['data']['shards']]
assert counts == [2, 2, 1], counts
print('OK')
" | grep -q OK; then
  green "PASS: shard splits 5 citations into 3 shards (2,2,1)"
else
  red "FAIL: shard split shape wrong"
  red "  got: $SHARD_OUT"
  errors=$((errors + 1))
fi

if python3 - <<PY > /dev/null
import json, glob
shard_files = sorted(glob.glob("$SHARDS/shard-*-v1.json"))
assert len(shard_files) == 3, shard_files
union_ids = []
for f in shard_files:
    m = json.load(open(f))
    assert m['schema_version'] == '0.1.0', m
    assert m['draft_version'] == 1, m
    assert isinstance(m['citations'], list) and m['citations'], m
    for c in m['citations']:
        # id + draft_sentence preserved verbatim through the split.
        assert 'id' in c and 'draft_sentence' in c, c
        union_ids.append(c['id'])
assert union_ids == ['cit-001','cit-002','cit-003','cit-004','cit-005'], union_ids
PY
then
  green "PASS: shard files are valid manifests; id/draft_sentence preserved; union exact + no dup"
else
  red "FAIL: shard file contents wrong"
  errors=$((errors + 1))
fi

# 2. Single shard when citations <= shard-size.
SHARDS_ONE="$WORK/shards-one"
ONE_OUT=$(python3 "$SCRIPT" shard --manifest "$MANIFEST" --draft-version 1 --shard-size 10 --out-dir "$SHARDS_ONE")
if echo "$ONE_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['data']['shard_count']==1, d" 2>/dev/null; then
  green "PASS: citations <= shard-size yields a single shard"
else
  red "FAIL: expected single shard"
  red "  got: $ONE_OUT"
  errors=$((errors + 1))
fi

# 3. merge: write 3 fragments matching the 3 shards, then merge.
python3 - <<PY
import json
frags = {
  "verify-shard-00-v1.json": {"verified":[{"id":"cit-001","verdict":"paraphrase","wiki_slug":"page-a","claim_id":"clm-001"}],
                              "deviations":[{"id":"cit-002","verdict":"unsupported","reason":"claim_text_misaligned","wiki_slug":"page-a","claim_id":"clm-002","note":"x"}]},
  "verify-shard-01-v1.json": {"verified":[{"id":"cit-003","verdict":"verbatim","wiki_slug":"page-b","claim_id":"clm-003"},
                                          {"id":"cit-004","verdict":"synthesis","wiki_slug":"page-b","claim_id":None}],
                              "deviations":[]},
  "verify-shard-02-v1.json": {"verified":[{"id":"cit-005","verdict":"paraphrase","wiki_slug":"page-c","claim_id":"clm-005"}],
                              "deviations":[]},
}
for name, body in frags.items():
    body.update({"schema_version":"0.1.0","draft_version":1,"revision_round":0})
    body["counts"] = {"verbatim":0,"paraphrase":0,"synthesis":0,"unsupported":0,
                      "total": len(body["verified"])+len(body["deviations"])}
    open("$SHARDS/"+name, "w").write(json.dumps(body))
PY

MERGE_OUT=$(python3 "$SCRIPT" merge --shard-dir "$SHARDS" --draft-version 1 --revision-round 0 --out "$WORK/verify-v1.json")
if echo "$MERGE_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['shards_merged'] == 3, d
c = d['data']['counts']
assert c['total'] == 5, c
assert c['paraphrase'] == 2 and c['verbatim'] == 1 and c['synthesis'] == 1 and c['unsupported'] == 1, c
print('OK')
" | grep -q OK; then
  green "PASS: merge recombines 3 fragments; counts recomputed; shards_merged reported"
else
  red "FAIL: merge envelope wrong"
  red "  got: $MERGE_OUT"
  errors=$((errors + 1))
fi

if python3 - <<PY > /dev/null
import json
v = json.load(open("$WORK/verify-v1.json"))
assert v['schema_version'] == '0.1.0', v
assert v['draft_version'] == 1 and v['revision_round'] == 0, v
assert v['counts']['total'] == len(v['verified']) + len(v['deviations']), v
ids = sorted([e['id'] for e in v['verified'] + v['deviations']])
assert ids == ['cit-001','cit-002','cit-003','cit-004','cit-005'], ids
PY
then
  green "PASS: merged verify-v1.json — total==verified+deviations, draft_version/revision_round set, ids intact"
else
  red "FAIL: merged verify-v1.json malformed"
  errors=$((errors + 1))
fi

# 4. Idempotent re-shard: re-running shard clears stale shard/fragment files.
python3 "$SCRIPT" shard --manifest "$MANIFEST" --draft-version 1 --shard-size 2 --out-dir "$SHARDS" >/dev/null
if python3 - <<PY > /dev/null
import glob
# the 3 stub fragments from step 3 must be gone after the re-shard
assert glob.glob("$SHARDS/verify-shard-*-v1.json") == [], glob.glob("$SHARDS/verify-shard-*-v1.json")
assert len(glob.glob("$SHARDS/shard-*-v1.json")) == 3
PY
then
  green "PASS: re-shard clears stale verify-shard fragments for the version"
else
  red "FAIL: re-shard did not clear stale fragments"
  errors=$((errors + 1))
fi

# 5a. Missing manifest → reject.
OUT=$(python3 "$SCRIPT" shard --manifest "$WORK/nope.json" --draft-version 1 --shard-size 2 --out-dir "$WORK/x" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'exist' in d['error'].lower()" 2>/dev/null; then
  green "PASS: missing manifest rejected"
else
  red "FAIL: missing manifest not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 5b. Non-0.1.0 schema → reject.
BAD_SCHEMA="$WORK/bad-schema.json"
echo '{"schema_version": "0.0.9", "draft_version": 1, "citations": []}' > "$BAD_SCHEMA"
OUT=$(python3 "$SCRIPT" shard --manifest "$BAD_SCHEMA" --draft-version 1 --shard-size 2 --out-dir "$WORK/y" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'schema_version' in d['error']" 2>/dev/null; then
  green "PASS: non-0.1.0 schema rejected"
else
  red "FAIL: non-0.1.0 schema not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 5c. draft_version mismatch → reject.
OUT=$(python3 "$SCRIPT" shard --manifest "$MANIFEST" --draft-version 9 --shard-size 2 --out-dir "$WORK/z" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'draft_version' in d['error']" 2>/dev/null; then
  green "PASS: draft_version mismatch rejected"
else
  red "FAIL: draft_version mismatch not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 5d. merge with no fragments → reject.
EMPTY_DIR="$WORK/empty-shards"
mkdir -p "$EMPTY_DIR"
OUT=$(python3 "$SCRIPT" merge --shard-dir "$EMPTY_DIR" --draft-version 1 --revision-round 0 --out "$WORK/nope-v1.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'fragment' in d['error'].lower()" 2>/dev/null; then
  green "PASS: merge with no fragments rejected"
else
  red "FAIL: merge with no fragments not rejected"
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
