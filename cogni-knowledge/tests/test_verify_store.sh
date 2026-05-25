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
#      - citation missing id/draft_sentence (pre-0.0.28 manifest, #291)
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

# 5e. Citation missing id/draft_sentence (pre-0.0.28 manifest) → reject (#291).
#     schema_version + draft_version are valid, so this slips every check EXCEPT
#     the per-entry id/draft_sentence guard.
PRE028="$WORK/pre-028.json"
cat > "$PRE028" <<'JSON'
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "citations": [
    {"draft_position": "00:01", "wiki_slug": "page-a", "claim_id": "clm-001"}
  ]
}
JSON
OUT=$(python3 "$SCRIPT" shard --manifest "$PRE028" --draft-version 1 --shard-size 2 --out-dir "$WORK/pre028-out" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'v0.0.28' in d['error']" 2>/dev/null; then
  green "PASS: pre-0.0.28 manifest (citation missing id/draft_sentence) rejected"
else
  red "FAIL: pre-0.0.28 manifest not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 6. merge conservation guards. Fresh dir with 2 input shards (4 citations).
MR="$WORK/merge-robust"
mkdir -p "$MR"
python3 - <<PY
import json
shards = {
  "shard-00-v1.json": ["cit-001", "cit-002"],
  "shard-01-v1.json": ["cit-003", "cit-004"],
}
for name, ids in shards.items():
    body = {"schema_version":"0.1.0","draft_version":1,"shard_index":0,
            "citations":[{"id":i,"draft_position":"00:01","draft_sentence":"s","wiki_slug":"p","claim_id":"c"} for i in ids]}
    open("$MR/"+name,"w").write(json.dumps(body))
PY

write_frag() {  # write_frag <name> <json>
  printf '%s' "$2" > "$MR/$1"
}
clear_frags() { rm -f "$MR"/verify-shard-*-v1.json; }
frag_full_00='{"schema_version":"0.1.0","draft_version":1,"revision_round":0,"verified":[{"id":"cit-001","verdict":"paraphrase"}],"deviations":[{"id":"cit-002","verdict":"unsupported","reason":"claim_text_misaligned"}],"counts":{"total":2}}'
frag_full_01='{"schema_version":"0.1.0","draft_version":1,"revision_round":0,"verified":[{"id":"cit-003","verdict":"verbatim"},{"id":"cit-004","verdict":"paraphrase"}],"deviations":[],"counts":{"total":2}}'

# 6a. Missing fragment → completeness error (merged 2 of 4).
clear_frags; write_frag verify-shard-00-v1.json "$frag_full_00"
OUT=$(python3 "$SCRIPT" merge --shard-dir "$MR" --draft-version 1 --revision-round 0 --out "$WORK/mr-a.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'of 4' in d['error']" 2>/dev/null; then
  green "PASS: merge rejects a missing fragment (2 of 4 sharded citations)"
else
  red "FAIL: missing fragment not caught by completeness check"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 6b. Duplicate id across fragments → reject.
clear_frags; write_frag verify-shard-00-v1.json "$frag_full_00"; write_frag verify-shard-01-v1.json "$frag_full_01"
write_frag verify-shard-02-v1.json '{"schema_version":"0.1.0","draft_version":1,"revision_round":0,"verified":[{"id":"cit-001","verdict":"paraphrase"}],"deviations":[],"counts":{"total":1}}'
OUT=$(python3 "$SCRIPT" merge --shard-dir "$MR" --draft-version 1 --revision-round 0 --out "$WORK/mr-b.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'duplicate' in d['error'].lower()" 2>/dev/null; then
  green "PASS: merge rejects duplicate citation id across fragments"
else
  red "FAIL: duplicate id not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 6c. unsupported verdict mis-filed into verified[] → reject.
clear_frags; write_frag verify-shard-01-v1.json "$frag_full_01"
write_frag verify-shard-00-v1.json '{"schema_version":"0.1.0","draft_version":1,"revision_round":0,"verified":[{"id":"cit-001","verdict":"paraphrase"},{"id":"cit-002","verdict":"unsupported","reason":"x"}],"deviations":[],"counts":{"total":2}}'
OUT=$(python3 "$SCRIPT" merge --shard-dir "$MR" --draft-version 1 --revision-round 0 --out "$WORK/mr-c.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'mis-filed' in d['error']" 2>/dev/null; then
  green "PASS: merge rejects unsupported verdict mis-filed in verified[]"
else
  red "FAIL: mis-filed unsupported not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 6d. Non-dict fragment top-level → JSON envelope error, NOT a Python traceback.
clear_frags; write_frag verify-shard-00-v1.json "$frag_full_00"; write_frag verify-shard-01-v1.json '[1,2,3]'
OUT=$(python3 "$SCRIPT" merge --shard-dir "$MR" --draft-version 1 --revision-round 0 --out "$WORK/mr-d.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'object' in d['error']" 2>/dev/null; then
  green "PASS: merge returns an envelope (not a traceback) on a non-dict fragment"
else
  red "FAIL: non-dict fragment crashed instead of returning the envelope"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 6e. Non-dict manifest top-level for shard → JSON envelope error, not a traceback.
NONDICT="$WORK/nondict-manifest.json"
echo '[1,2,3]' > "$NONDICT"
OUT=$(python3 "$SCRIPT" shard --manifest "$NONDICT" --draft-version 1 --shard-size 2 --out-dir "$WORK/nd" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'object' in d['error']" 2>/dev/null; then
  green "PASS: shard returns an envelope (not a traceback) on a non-dict manifest"
else
  red "FAIL: non-dict manifest crashed instead of returning the envelope"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# =============================================================================
# #305 — incremental re-verify (shard --only-ids), prefilter, merge --manifest
#        + --carry-forward-from.
# =============================================================================

# 7a. shard --only-ids restricts the split to the requested subset.
SH_ONLY="$WORK/shards-only"
OUT=$(python3 "$SCRIPT" shard --manifest "$MANIFEST" --draft-version 1 --shard-size 40 --only-ids "cit-002,cit-004" --out-dir "$SH_ONLY")
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['citation_count'] == 2, d
" 2>/dev/null && python3 - <<PY > /dev/null
import json, glob
files = glob.glob("$SH_ONLY/shard-*-v1.json")
ids = []
for f in files:
    for c in json.load(open(f))['citations']:
        ids.append(c['id'])
assert sorted(ids) == ['cit-002','cit-004'], ids
PY
then
  green "PASS: shard --only-ids splits only the requested delta subset (#305)"
else
  red "FAIL: shard --only-ids did not restrict to the subset"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# Build a small wiki for the prefilter: page-a has a real claim; page-c has a
# malformed (no closing ---) frontmatter so the parser must fail safe.
PFWIKI="$WORK/pf-wiki"
mkdir -p "$PFWIKI/wiki/sources"
cat > "$PFWIKI/wiki/sources/page-a.md" <<'EOF'
---
type: source
slug: page-a
sources: ["https://example.com/a"]
pre_extracted_claims:
  - id: clm-001
    text: "Article 6: high-risk classification rule"
    excerpt_quote: "shall be considered high-risk"
    excerpt_position: 12
    sub_question_refs: [sq-01]
---

# body
EOF
cat > "$PFWIKI/wiki/sources/page-c.md" <<'EOF'
---
type: source
pre_extracted_claims:
  - id: clm-009
    excerpt_quote: "never reached because frontmatter is unterminated"

# body with no closing fence
EOF

PFM="$WORK/pf-manifest.json"
cat > "$PFM" <<'EOF'
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "citations": [
    {"id": "cit-p1", "draft_position": "00:01", "draft_sentence": "The system shall be considered high-risk under Annex III.", "wiki_slug": "page-a", "claim_id": "clm-001"},
    {"id": "cit-p2", "draft_position": "00:02", "draft_sentence": "Eine deutsche Aussage ganz ohne englisches Zitat.", "wiki_slug": "page-a", "claim_id": "clm-001"},
    {"id": "cit-p3", "draft_position": "00:03", "draft_sentence": "Cites a page whose frontmatter cannot be parsed.", "wiki_slug": "page-c", "claim_id": "clm-009"}
  ]
}
EOF
# All three sentences are present in the draft, so a non-match is due to the
# language/parse-fail guard, NOT the staleness check (tested separately in 7j).
PFDRAFT="$WORK/pf-draft-v1.md"
cat > "$PFDRAFT" <<'EOF'
The system shall be considered high-risk under Annex III.
Eine deutsche Aussage ganz ohne englisches Zitat.
Cites a page whose frontmatter cannot be parsed.
EOF

# 7b. prefilter: exact-substring match → verbatim; cross-language + unparseable
#     page → remaining (fail-safe, never a wrong verdict).
PFSH="$WORK/pf-shards"
OUT=$(python3 "$SCRIPT" prefilter --manifest "$PFM" --wiki-root "$PFWIKI" --draft-version 1 --draft "$PFDRAFT" --out-dir "$PFSH")
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['matched_ids'] == ['cit-p1'], d['data']
assert sorted(d['data']['remaining_ids']) == ['cit-p2', 'cit-p3'], d['data']
" 2>/dev/null; then
  green "PASS: prefilter matches the verbatim citation, falls through on cross-lang + unparseable (#305)"
else
  red "FAIL: prefilter match/remaining split wrong"
  red "  got: $OUT"
  errors=$((errors + 1))
fi
if python3 - <<PY > /dev/null
import json
frag = json.load(open("$PFSH/verify-shard-prefilter-v1.json"))
assert frag['deviations'] == [], frag          # prefilter NEVER emits a deviation
assert len(frag['verified']) == 1, frag
e = frag['verified'][0]
assert e['id'] == 'cit-p1' and e['verdict'] == 'verbatim', e
PY
then
  green "PASS: prefilter fragment carries only verbatim verdicts, no deviations"
else
  red "FAIL: prefilter fragment malformed"
  errors=$((errors + 1))
fi

# 7b-fp. FALSE-POSITIVE GUARDS — the prefilter must NOT mark verbatim on a
#        block-scalar needle ('>'/'|'), a too-short needle, or a manifest
#        sentence that is not actually in the draft (stale). All must fall
#        through to the LLM (remaining_ids), never a wrong verbatim.
FPWIKI="$WORK/fp-wiki"
mkdir -p "$FPWIKI/wiki/sources"
cat > "$FPWIKI/wiki/sources/p.md" <<'EOF'
---
type: source
pre_extracted_claims:
  - id: clm-block
    text: short
    excerpt_quote: >
      Annex III systems shall be considered high-risk.
  - id: clm-shorttext
    text: AI
  - id: clm-real
    text: "Article 6 classifies high-risk systems."
    excerpt_quote: "shall be considered high-risk under Annex III"
---

# body
EOF
FPM="$WORK/fp-manifest.json"
cat > "$FPM" <<'EOF'
{"schema_version":"0.1.0","draft_version":1,"citations":[
 {"id":"cit-block","draft_position":"0:1","draft_sentence":"The system shall be considered high-risk<sup>[1](https://x.eu/a)</sup>.","wiki_slug":"p","claim_id":"clm-block"},
 {"id":"cit-short","draft_position":"0:2","draft_sentence":"This sentence mentions AI somewhere<sup>[2](https://x.eu/b)</sup>.","wiki_slug":"p","claim_id":"clm-shorttext"},
 {"id":"cit-real","draft_position":"0:3","draft_sentence":"A system shall be considered high-risk under Annex III here<sup>[3](https://x.eu/c)</sup>.","wiki_slug":"p","claim_id":"clm-real"},
 {"id":"cit-stale","draft_position":"0:4","draft_sentence":"Not in the draft yet shall be considered high-risk under Annex III.","wiki_slug":"p","claim_id":"clm-real"}
]}
EOF
FPDRAFT="$WORK/fp-draft-v1.md"
cat > "$FPDRAFT" <<'EOF'
The system shall be considered high-risk<sup>[1](https://x.eu/a)</sup>.
This sentence mentions AI somewhere<sup>[2](https://x.eu/b)</sup>.
A system shall be considered high-risk under Annex III here<sup>[3](https://x.eu/c)</sup>.
EOF
OUT=$(python3 "$SCRIPT" prefilter --manifest "$FPM" --wiki-root "$FPWIKI" --draft-version 1 --draft "$FPDRAFT" --out-dir "$WORK/fp-sh")
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['matched_ids'] == ['cit-real'], 'only the substantial in-draft match should be verbatim; got '+repr(d['data']['matched_ids'])
assert sorted(d['data']['remaining_ids']) == ['cit-block','cit-short','cit-stale'], d['data']
" 2>/dev/null; then
  green "PASS: prefilter rejects block-scalar / short-needle / stale-sentence false positives (#305 review)"
else
  red "FAIL: prefilter false-positive guard regressed"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7b-nfc. NFC/NFD normalization — a genuinely-verbatim non-ASCII match across
#         differing Unicode composition must still be found.
NFCWIKI="$WORK/nfc-wiki"
mkdir -p "$NFCWIKI/wiki/sources"
python3 - "$NFCWIKI/wiki/sources/g.md" "$WORK/nfc-manifest.json" "$WORK/nfc-draft-v1.md" <<'PY'
import sys, json, unicodedata
page_path, man_path, draft_path = sys.argv[1], sys.argv[2], sys.argv[3]
quote_nfd = unicodedata.normalize("NFD", "Geschäftsmodell der Hochrisiko-Systeme")
quote_nfc = unicodedata.normalize("NFC", "Geschäftsmodell der Hochrisiko-Systeme")
assert quote_nfd != quote_nfc
open(page_path, "w", encoding="utf-8").write(
    '---\ntype: source\npre_extracted_claims:\n  - id: clm-de\n'
    '    excerpt_quote: "' + quote_nfd + '"\n---\n# body\n')
sentence_nfc = "Das " + quote_nfc + " ist relevant."
json.dump({"schema_version":"0.1.0","draft_version":1,"citations":[
    {"id":"cit-de","draft_position":"0:1","draft_sentence":sentence_nfc,"wiki_slug":"g","claim_id":"clm-de"}]},
    open(man_path,"w",encoding="utf-8"))
open(draft_path,"w",encoding="utf-8").write(sentence_nfc + "\n")
PY
OUT=$(python3 "$SCRIPT" prefilter --manifest "$WORK/nfc-manifest.json" --wiki-root "$NFCWIKI" --draft-version 1 --draft "$WORK/nfc-draft-v1.md" --out-dir "$WORK/nfc-sh")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['data']['matched_ids']==['cit-de'], d['data']" 2>/dev/null; then
  green "PASS: prefilter matches a verbatim non-ASCII citation across NFC/NFD composition (#305 review)"
else
  red "FAIL: prefilter NFC/NFD normalization missing"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7b-dup. A duplicate claim_id on one page is ambiguous → that citation falls
#         through to the LLM (never matched against an arbitrary excerpt).
DUPWIKI="$WORK/dup-wiki"
mkdir -p "$DUPWIKI/wiki/sources"
cat > "$DUPWIKI/wiki/sources/d.md" <<'EOF'
---
type: source
pre_extracted_claims:
  - id: clm-dup
    excerpt_quote: "shall be considered high-risk under Annex III"
  - id: clm-dup
    excerpt_quote: "is exempt under the significant-risk derogation"
---
# body
EOF
cat > "$WORK/dup-manifest.json" <<'EOF'
{"schema_version":"0.1.0","draft_version":1,"citations":[
 {"id":"cit-dup","draft_position":"0:1","draft_sentence":"A system shall be considered high-risk under Annex III now.","wiki_slug":"d","claim_id":"clm-dup"}]}
EOF
cat > "$WORK/dup-draft-v1.md" <<'EOF'
A system shall be considered high-risk under Annex III now.
EOF
OUT=$(python3 "$SCRIPT" prefilter --manifest "$WORK/dup-manifest.json" --wiki-root "$DUPWIKI" --draft-version 1 --draft "$WORK/dup-draft-v1.md" --out-dir "$WORK/dup-sh")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['data']['matched_ids']==[] and d['data']['remaining_ids']==['cit-dup'], d['data']" 2>/dev/null; then
  green "PASS: prefilter treats a duplicate claim_id on a page as ambiguous → LLM fallthrough (#305 review)"
else
  red "FAIL: prefilter duplicate-claim_id ambiguity not handled"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7c. merge --manifest: prefilter fragment + LLM fragment union == manifest.
#     shard the remaining ids (preserving the prefilter fragment), add a verifier
#     fragment for them, merge against the manifest id-set.
python3 "$SCRIPT" shard --manifest "$PFM" --draft-version 1 --shard-size 40 --only-ids "cit-p2,cit-p3" --out-dir "$PFSH" >/dev/null
cat > "$PFSH/verify-shard-00-v1.json" <<'EOF'
{"schema_version":"0.1.0","draft_version":1,"revision_round":0,"verified":[{"id":"cit-p2","verdict":"paraphrase"}],"deviations":[{"id":"cit-p3","verdict":"unsupported","reason":"claim_not_found"}],"counts":{"total":2}}
EOF
OUT=$(python3 "$SCRIPT" merge --shard-dir "$PFSH" --draft-version 1 --revision-round 0 --manifest "$PFM" --out "$WORK/pf-verify-v1.json")
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
c = d['data']['counts']
assert c['total'] == 3 and c['verbatim'] == 1 and c['paraphrase'] == 1 and c['unsupported'] == 1, c
" 2>/dev/null; then
  green "PASS: merge --manifest unions prefilter + LLM fragments to the full manifest (#305)"
else
  red "FAIL: merge --manifest conservation wrong"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7d. merge WITHOUT --manifest now fails: the prefilter's cit-p1 is not in the
#     shard inputs (which cover only the delta), so input-set conservation can't
#     reconcile it — this is exactly why --manifest is required for the new flow.
OUT=$(python3 "$SCRIPT" merge --shard-dir "$PFSH" --draft-version 1 --revision-round 0 --out "$WORK/pf-nomani.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'of 2' in d['error']" 2>/dev/null; then
  green "PASS: merge without --manifest rejects the prefilter+delta union (conservation needs the manifest)"
else
  red "FAIL: merge without --manifest should fail conservation against the delta-only shard inputs"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7e. Idempotent reshard preserves the prefilter fragment (cleanup is scoped to
#     numbered fragments) while clearing the numbered ones.
python3 "$SCRIPT" shard --manifest "$PFM" --draft-version 1 --shard-size 40 --only-ids "cit-p2,cit-p3" --out-dir "$PFSH" >/dev/null
if python3 - <<PY > /dev/null
import glob, os
assert os.path.exists("$PFSH/verify-shard-prefilter-v1.json"), "prefilter fragment was clobbered by reshard"
assert glob.glob("$PFSH/verify-shard-[0-9]*-v1.json") == [], "numbered fragments not cleared"
PY
then
  green "PASS: reshard preserves the prefilter fragment, clears numbered fragments (#305)"
else
  red "FAIL: reshard fragment-cleanup scope wrong"
  errors=$((errors + 1))
fi

# 7f. Incremental round ≥1: merge --manifest --carry-forward-from. The delta is
#     re-scored; untouched verdicts are carried from the prior round; the merged
#     file equals the manifest id-set and is complete.
CFM="$WORK/cf-manifest.json"
cat > "$CFM" <<'EOF'
{"schema_version":"0.1.0","draft_version":2,"citations":[
 {"id":"cit-001","draft_position":"00:01","draft_sentence":"s1","wiki_slug":"p","claim_id":"c1"},
 {"id":"cit-002","draft_position":"00:02","draft_sentence":"s2","wiki_slug":"p","claim_id":"c2"},
 {"id":"cit-003","draft_position":"00:03","draft_sentence":"s3","wiki_slug":"p","claim_id":"c3"}
]}
EOF
PREV="$WORK/cf-verify-v1.json"
cat > "$PREV" <<'EOF'
{"schema_version":"0.1.0","draft_version":1,"revision_round":0,
 "verified":[{"id":"cit-001","verdict":"verbatim"},{"id":"cit-003","verdict":"paraphrase"}],
 "deviations":[{"id":"cit-002","verdict":"unsupported","reason":"claim_text_misaligned"}],
 "counts":{"verbatim":1,"paraphrase":1,"synthesis":0,"unsupported":1,"total":3}}
EOF
CFSH="$WORK/cf-shards"
python3 "$SCRIPT" shard --manifest "$CFM" --draft-version 2 --only-ids "cit-002" --out-dir "$CFSH" >/dev/null
cat > "$CFSH/verify-shard-00-v2.json" <<'EOF'
{"schema_version":"0.1.0","draft_version":2,"revision_round":1,"verified":[{"id":"cit-002","verdict":"paraphrase"}],"deviations":[],"counts":{"total":1}}
EOF
OUT=$(python3 "$SCRIPT" merge --shard-dir "$CFSH" --draft-version 2 --revision-round 1 --manifest "$CFM" --carry-forward-from "$PREV" --out "$WORK/cf-verify-v2.json")
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
c = d['data']['counts']
# cit-002 re-scored paraphrase; cit-001 verbatim + cit-003 paraphrase carried.
assert c['total'] == 3 and c['unsupported'] == 0 and c['paraphrase'] == 2 and c['verbatim'] == 1, c
" 2>/dev/null && python3 - <<PY > /dev/null
import json
v = json.load(open("$WORK/cf-verify-v2.json"))
ids = sorted(e['id'] for e in v['verified'] + v['deviations'])
assert ids == ['cit-001','cit-002','cit-003'], ids
PY
then
  green "PASS: merge --carry-forward-from re-scores the delta + carries untouched → complete (#305)"
else
  red "FAIL: carry-forward merge wrong"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7g. Empty delta: a fragment with no fresh ids + carry-forward rebuilds the full
#     file purely from the prior round (revisor did only drops/skips).
EMPTYSH="$WORK/cf-empty-shards"
mkdir -p "$EMPTYSH"
cat > "$EMPTYSH/verify-shard-prefilter-v2.json" <<'EOF'
{"schema_version":"0.1.0","draft_version":2,"revision_round":1,"verified":[],"deviations":[],"counts":{"total":0}}
EOF
OUT=$(python3 "$SCRIPT" merge --shard-dir "$EMPTYSH" --draft-version 2 --revision-round 1 --manifest "$CFM" --carry-forward-from "$PREV" --out "$WORK/cf-empty-v2.json")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['counts']['total'] == 3, d" 2>/dev/null; then
  green "PASS: empty-delta round rebuilds the full file by carry-forward alone (#305)"
else
  red "FAIL: empty-delta carry-forward wrong"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7h. --carry-forward-from without --manifest → reject.
OUT=$(python3 "$SCRIPT" merge --shard-dir "$CFSH" --draft-version 2 --revision-round 1 --carry-forward-from "$PREV" --out "$WORK/cf-bad.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'requires --manifest' in d['error']" 2>/dev/null; then
  green "PASS: --carry-forward-from without --manifest rejected"
else
  red "FAIL: --carry-forward-from without --manifest not rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7i. carry-forward when the prior file lacks a manifest id → reject (a manual
#     deletion of the prior round should force a full re-shard, not a silent gap).
PREV_GAP="$WORK/cf-prev-gap.json"
cat > "$PREV_GAP" <<'EOF'
{"schema_version":"0.1.0","draft_version":1,"revision_round":0,
 "verified":[{"id":"cit-001","verdict":"verbatim"}],"deviations":[],"counts":{"total":1}}
EOF
OUT=$(python3 "$SCRIPT" merge --shard-dir "$CFSH" --draft-version 2 --revision-round 1 --manifest "$CFM" --carry-forward-from "$PREV_GAP" --out "$WORK/cf-gap.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'no prior verdict' in d['error']" 2>/dev/null; then
  green "PASS: carry-forward rejects a manifest id with no prior verdict (forces full re-shard)"
else
  red "FAIL: carry-forward did not reject a missing prior verdict"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7j. merge --manifest with a DUPLICATE id in the manifest → clean rejection
#     (not the self-contradictory 'missing: []; unexpected: []' conservation error).
DUPMAN="$WORK/dup-manifest-merge.json"
cat > "$DUPMAN" <<'EOF'
{"schema_version":"0.1.0","draft_version":2,"citations":[
 {"id":"cit-001","draft_position":"0:1","draft_sentence":"a","wiki_slug":"p","claim_id":"c1"},
 {"id":"cit-001","draft_position":"0:2","draft_sentence":"b","wiki_slug":"p","claim_id":"c2"}]}
EOF
OUT=$(python3 "$SCRIPT" merge --shard-dir "$CFSH" --draft-version 2 --revision-round 1 --manifest "$DUPMAN" --carry-forward-from "$PREV" --out "$WORK/dupman-out.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'duplicate citation id' in d['error']" 2>/dev/null; then
  green "PASS: merge rejects a manifest with duplicate citation ids (#305 review)"
else
  red "FAIL: merge did not reject a duplicate-id manifest"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7k. carry-forward source with a duplicate id → reject (no silent last-write-wins).
PREV_DUP="$WORK/cf-prev-dup.json"
cat > "$PREV_DUP" <<'EOF'
{"schema_version":"0.1.0","draft_version":1,"revision_round":0,
 "verified":[{"id":"cit-001","verdict":"verbatim"},{"id":"cit-003","verdict":"paraphrase"},{"id":"cit-001","verdict":"unsupported"}],
 "deviations":[],"counts":{"total":3}}
EOF
OUT=$(python3 "$SCRIPT" merge --shard-dir "$CFSH" --draft-version 2 --revision-round 1 --manifest "$CFM" --carry-forward-from "$PREV_DUP" --out "$WORK/cf-dup.json" 2>&1 || true)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is False and 'duplicate citation id' in d['error']" 2>/dev/null; then
  green "PASS: carry-forward rejects a prior file with duplicate citation ids (#305 review)"
else
  red "FAIL: carry-forward did not reject a duplicate-id prior file"
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
