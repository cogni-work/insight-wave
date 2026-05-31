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

# 5. Duplicate citation id → write_failed at the build gate (no manifest), so the
#    bad join key is caught here, not several phases downstream.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
(work / "dup-records.txt").write_text(
    "- id: cit-001\n  pos: 0:1\n  slug: p\n  claim: clm-001\n"
    "  sentence: She said \"high-risk\" applies here<sup>[1](https://x.eu/a)</sup>.\n"
    "- id: cit-001\n  pos: 0:2\n  slug: p\n  claim: clm-002\n"
    "  sentence: The pattern \\d+ matches one or more digits<sup>[2](https://x.eu/b)</sup>.\n",
    encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/dup-records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/dup-manifest.json" --draft-version 1 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'duplicate_id' and d['data']['ids'] == ['cit-001'], d
" 2>/dev/null && [ ! -f "$WORK/dup-manifest.json" ]; then
  green "PASS: duplicate citation id → write_failed, no manifest written"
else
  red "FAIL: duplicate id not rejected at the build gate"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 6. A record missing its `sentence:` line → empty draft_sentence must NOT slip
#    past the substring check (`"" in draft` is always True).
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
(work / "nosent-records.txt").write_text(
    "- id: cit-001\n  pos: 0:1\n  slug: p\n  claim: clm-001\n",  # no sentence line
    encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/nosent-records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/nosent-manifest.json" --draft-version 1 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'sentence_not_in_draft' and d['data']['ids'] == ['cit-001'], d
" 2>/dev/null && [ ! -f "$WORK/nosent-manifest.json" ]; then
  green "PASS: record with an empty/missing sentence → write_failed, no manifest"
else
  red "FAIL: empty draft_sentence slipped past the substring check"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 7. Long-key aliases: the composer may emit the manifest field names
#    (draft_position / wiki_slug / claim_id / draft_sentence) instead of the short
#    keys — the parser must accept both and produce an identical manifest.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
(work / "alias-records.txt").write_text(
    "- id: cit-001\n"
    "  draft_position: 02:03\n"
    "  wiki_slug: eu-ai-act-article-6\n"
    "  claim_id: clm-001\n"
    '  draft_sentence: She said "high-risk" applies here<sup>[1](https://x.eu/a)</sup>.\n',
    encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/alias-records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/alias-manifest.json" --draft-version 1)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==1, d" 2>/dev/null \
   && python3 -c "
import json
c = json.load(open('$WORK/alias-manifest.json'))['citations'][0]
assert c['draft_position'] == '02:03' and c['wiki_slug'] == 'eu-ai-act-article-6', c
assert c['claim_id'] == 'clm-001' and c['draft_sentence'].startswith('She said'), c
" 2>/dev/null; then
  green "PASS: parser accepts long-key aliases (draft_position/wiki_slug/claim_id/draft_sentence)"
else
  red "FAIL: long-key aliases not accepted"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 8. A sentence containing a Unicode line separator (U+2028) must NOT be
#    truncated — the parser splits on \n only, not str.splitlines() (which also
#    breaks on U+2028/U+2029/NEL and would split the sentence mid-record, then
#    fail the substring check on prose the composer wrote correctly).
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
sentence = "Phrase one phrase two<sup>[1](https://x.eu/a)</sup>."
(work / "ls-records.txt").write_text(
    "- id: cit-001\n  pos: 0:1\n  slug: p\n  claim: clm-001\n  sentence: " + sentence + "\n",
    encoding="utf-8")
(work / "ls-draft.md").write_text("# R\n\n" + sentence + "\n\n## References\n[[sources/p]]\n",
    encoding="utf-8")
(work / "ls-expected.txt").write_text(sentence, encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/ls-records.txt" --draft "$WORK/ls-draft.md" \
  --out "$WORK/ls-manifest.json" --draft-version 1)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==1, d" 2>/dev/null \
   && python3 -c "
import json
c = json.load(open('$WORK/ls-manifest.json'))['citations'][0]
exp = open('$WORK/ls-expected.txt', encoding='utf-8').read()
assert c['draft_sentence'] == exp, ('truncated: ' + repr(c['draft_sentence']))
" 2>/dev/null; then
  green "PASS: U+2028 inside a sentence is preserved, not truncated (split on \\n only)"
else
  red "FAIL: sentence with a Unicode line separator was truncated"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 9. A record block missing its `id:` line must NOT be silently dropped (which
#    would vanish a citation while the round-trip count self-validates) — the
#    parser emits it with an empty id and the build rejects it as empty_id.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
# First bullet is `- pos:`, no id: line; the sentence IS in the draft, so this
# isolates the empty-id path (not the substring check).
(work / "noid-records.txt").write_text(
    "- pos: 0:1\n  slug: p\n  claim: clm-001\n"
    '  sentence: She said "high-risk" applies here<sup>[1](https://x.eu/a)</sup>.\n',
    encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/noid-records.txt" --draft "$WORK/draft-v1.md" \
  --out "$WORK/noid-manifest.json" --draft-version 1 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'empty_id', d
" 2>/dev/null && [ ! -f "$WORK/noid-manifest.json" ]; then
  green "PASS: id-less record block → empty_id write_failed, not a silent drop"
else
  red "FAIL: id-less record block was silently dropped or mis-handled"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 10. --ingest-manifest URL gate (#383). The composer must copy each cited page's
#     real `sources:` URL; a slug-derived URL diverges from the real path tail and
#     ships a broken link. The gate cross-checks every inline `<sup>[N](url)</sup>`
#     URL against `ingest-manifest.json::ingested[].url`. Fixtures use a real
#     slug≠URL-tail case (the #383 NIS2 Artikel 3 / Mindestmaßnahmen divergence).
python3 - "$WORK" <<'PY'
import sys, pathlib, json
work = pathlib.Path(sys.argv[1])
good = "https://nis.de/artikel-3-wesentliche-und-wichtige-einrichtungen/"        # trailing slash
goodbase = "https://nis.de/artikel-3-wesentliche-und-wichtige-einrichtungen"      # ingested w/o slash
bad = "https://nis.de/nis-2-mindestmassnahmen-nach-30-bsig"                       # slug-derived (wrong)
real2 = "https://nis.de/nis-2-mindestmassnahmen-paragraph-30-bsig/"               # real ingested URL
# url-records: cit-001 good (trailing-slash variant of an ingested URL), cit-002 slug-derived/wrong.
(work / "url-records.txt").write_text(
    "- id: cit-001\n  pos: 1:1\n  slug: artikel-3\n  claim: clm-001\n"
    "  sentence: Artikel 3 definiert die Einrichtungen<sup>[1](" + good + ")</sup>.\n"
    "- id: cit-002\n  pos: 1:2\n  slug: mindestmassnahmen\n  claim: clm-002\n"
    "  sentence: Die Mindestmassnahmen folgen<sup>[2](" + bad + ")</sup>.\n",
    encoding="utf-8")
(work / "url-draft.md").write_text(
    "# R\n\nArtikel 3 definiert die Einrichtungen<sup>[1](" + good + ")</sup>.\n"
    "Die Mindestmassnahmen folgen<sup>[2](" + bad + ")</sup>.\n\n## References\n[[sources/artikel-3]]\n",
    encoding="utf-8")
# good-only records (both inline URLs ARE ingested — the positive path).
(work / "url-records-ok.txt").write_text(
    "- id: cit-001\n  pos: 1:1\n  slug: artikel-3\n  claim: clm-001\n"
    "  sentence: Artikel 3 definiert die Einrichtungen<sup>[1](" + good + ")</sup>.\n",
    encoding="utf-8")
(work / "url-draft-ok.md").write_text(
    "# R\n\nArtikel 3 definiert die Einrichtungen<sup>[1](" + good + ")</sup>.\n\n## References\n[[sources/artikel-3]]\n",
    encoding="utf-8")
# ingest manifest: the two REAL source URLs.
(work / "ingest.json").write_text(
    json.dumps({"schema_version": "0.1.0", "ingested": [{"url": goodbase}, {"url": real2}], "skipped": []}),
    encoding="utf-8")
# empty ingested[] → gate skips (fail-soft on degenerate input).
(work / "ingest-empty.json").write_text(
    json.dumps({"schema_version": "0.1.0", "ingested": [], "skipped": []}), encoding="utf-8")
PY

# 10a. Negative: a slug-derived inline URL not in ingested[] → url_not_in_sources,
#      no manifest. The good cit-001 (trailing-slash variant) must NOT be flagged
#      (normalize_url is applied symmetrically — proves no false positive).
OUT=$(python3 "$SCRIPT" build --records "$WORK/url-records.txt" --draft "$WORK/url-draft.md" \
  --out "$WORK/url-manifest.json" --draft-version 1 --ingest-manifest "$WORK/ingest.json" 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'url_not_in_sources', d
assert d['data']['urls'] == ['https://nis.de/nis-2-mindestmassnahmen-nach-30-bsig'], d
" 2>/dev/null && [ ! -f "$WORK/url-manifest.json" ]; then
  green "PASS: slug-derived inline URL → url_not_in_sources, no manifest (good URL not false-flagged)"
else
  red "FAIL: --ingest-manifest gate did not flag the slug-derived URL (or false-flagged the good one)"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 10b. Positive: every inline URL is a known ingested source (trailing-slash
#      variant matches via normalize_url symmetry) → success.
OUT=$(python3 "$SCRIPT" build --records "$WORK/url-records-ok.txt" --draft "$WORK/url-draft-ok.md" \
  --out "$WORK/url-manifest-ok.json" --draft-version 1 --ingest-manifest "$WORK/ingest.json")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==1, d" 2>/dev/null; then
  green "PASS: all inline URLs in ingested set (trailing-slash normalized) → success"
else
  red "FAIL: positive --ingest-manifest case rejected"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 10c. Fail-soft: an empty ingested[] (or missing manifest) yields zero known URLs
#      → the gate is skipped, build succeeds (hardening, not a new hard-fail mode).
OK_EMPTY=$(python3 "$SCRIPT" build --records "$WORK/url-records.txt" --draft "$WORK/url-draft.md" \
  --out "$WORK/url-fs1.json" --draft-version 1 --ingest-manifest "$WORK/ingest-empty.json" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['success'])" 2>/dev/null || true)
OK_MISSING=$(python3 "$SCRIPT" build --records "$WORK/url-records.txt" --draft "$WORK/url-draft.md" \
  --out "$WORK/url-fs2.json" --draft-version 1 --ingest-manifest "$WORK/does-not-exist.json" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['success'])" 2>/dev/null || true)
if [ "$OK_EMPTY" = "True" ] && [ "$OK_MISSING" = "True" ]; then
  green "PASS: empty / missing ingest-manifest → gate skipped, build succeeds (fail-soft)"
else
  red "FAIL: fail-soft degenerate-input contract broken (empty=$OK_EMPTY missing=$OK_MISSING)"
  errors=$((errors + 1))
fi

# 10d. Backward compat: omitting --ingest-manifest entirely → no URL check; the
#      slug-derived-URL records build clean (the gate is strictly opt-in).
OUT=$(python3 "$SCRIPT" build --records "$WORK/url-records.txt" --draft "$WORK/url-draft.md" \
  --out "$WORK/url-noflag.json" --draft-version 1)
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==2, d" 2>/dev/null; then
  green "PASS: no --ingest-manifest → URL gate is opt-in (slug-derived URL builds clean)"
else
  red "FAIL: omitting --ingest-manifest unexpectedly ran the URL gate"
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
