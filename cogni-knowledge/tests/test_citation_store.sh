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
#  12. build reports a per-kind `claim_kinds` breakdown (#385) keyed on the
#      claim_id prefix — distilled (dcl-) / source (clm-) / null — the per-run
#      measurement of the distilled-citation rate.
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
    "  url: https://x.eu/a\n"
    '  sentence: She said "high-risk" applies here<sup>[1](https://x.eu/a)</sup>.\n'
    "- id: cit-002\n"
    "  pos: 02:05\n"
    "  slug: eu-ai-act-article-6\n"
    "  claim: null\n"
    "  url: https://x.eu/c\n"
    '  sentence: bei Systemen, die ein „Profiling natürlicher Personen" durchführen<sup>[3](https://x.eu/c)</sup>.\n'
    "- id: cit-003\n"
    "  pos: 03:01\n"
    "  slug: regex-page\n"
    "  claim: clm-009\n"
    "  url: https://x.eu/b\n"
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
assert m["schema_version"] == "0.1.1" and m["draft_version"] == 1, m
cites = m["citations"]
assert len(cites) == 3, cites
expected = json.loads((work / "expected.json").read_text(encoding="utf-8"))
for c, exp in zip(cites, expected):
    # Byte-equal round-trip of the verbatim sentence through json.dumps/json.loads.
    assert c["draft_sentence"] == exp, (c["draft_sentence"], exp)
    assert "id" in c and "wiki_slug" in c and "claim_id" in c and "draft_position" in c, c
    # #395: the structured per-citation url field rides through the build verbatim.
    assert "url" in c, c
assert [c["url"] for c in cites] == ["https://x.eu/a", "https://x.eu/c", "https://x.eu/b"], cites
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
   && python3 -c "import json; m=json.load(open('$WORK/empty-manifest.json')); assert m['citations']==[] and m['schema_version']=='0.1.1', m" 2>/dev/null; then
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

# 11. Per-citation slug→URL binding gate (#395). The #383 set-membership gate
#     above can't catch a REAL-but-mis-attributed URL: a record citing source A's
#     claim while linking source B's genuinely-INGESTED URL passes set-membership
#     (B is in `ingested[]`). The structured per-record `url` field + the ingest
#     manifest's per-slug `url` close this — `record.url` must equal the cited
#     slug's ingested `sources:` URL AND appear in its own sentence's marker.
python3 - "$WORK" <<'PY'
import sys, pathlib, json
work = pathlib.Path(sys.argv[1])
url_a = "https://a.eu/page-a"          # source-a's real ingested sources: URL
url_b = "https://b.eu/page-b"          # source-b's real ingested sources: URL
# Mis-attribution: record cites slug source-a but its url + inline marker are B's
# (real, ingested) URL — exactly the source-A-text-with-source-B-URL case.
(work / "misattr-records.txt").write_text(
    "- id: cit-001\n  pos: 1:1\n  slug: source-a\n  claim: clm-001\n"
    "  url: " + url_b + "\n"
    "  sentence: Fact attributed to source A<sup>[1](" + url_b + ")</sup>.\n",
    encoding="utf-8")
(work / "misattr-draft.md").write_text(
    "# R\n\nFact attributed to source A<sup>[1](" + url_b + ")</sup>.\n\n"
    "## References\n[[sources/source-a]]\n",
    encoding="utf-8")
# Correctly-bound: record cites slug source-a with A's url + inline marker.
(work / "bound-records.txt").write_text(
    "- id: cit-001\n  pos: 1:1\n  slug: source-a\n  claim: clm-001\n"
    "  url: " + url_a + "\n"
    "  sentence: Fact attributed to source A<sup>[1](" + url_a + ")</sup>.\n",
    encoding="utf-8")
(work / "bound-draft.md").write_text(
    "# R\n\nFact attributed to source A<sup>[1](" + url_a + ")</sup>.\n\n"
    "## References\n[[sources/source-a]]\n",
    encoding="utf-8")
# ingest manifest carries BOTH slug+url pairs (both URLs are genuinely ingested).
(work / "ingest-slug.json").write_text(
    json.dumps({"schema_version": "0.1.0", "ingested": [
        {"slug": "source-a", "url": url_a},
        {"slug": "source-b", "url": url_b},
    ], "skipped": []}),
    encoding="utf-8")
PY

# 11a. Negative: source-A text linking source-B's (real, ingested) URL → the
#      set-membership gate passes (url_b IS ingested) but the binding gate fires.
OUT=$(python3 "$SCRIPT" build --records "$WORK/misattr-records.txt" --draft "$WORK/misattr-draft.md" \
  --out "$WORK/misattr-manifest.json" --draft-version 1 --ingest-manifest "$WORK/ingest-slug.json" 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'url_slug_mismatch', d
ids = [m['id'] for m in d['data']['mismatches']]
assert ids == ['cit-001'], d
" 2>/dev/null && [ ! -f "$WORK/misattr-manifest.json" ]; then
  green "PASS: source-A text with source-B (real, ingested) URL → url_slug_mismatch, no manifest"
else
  red "FAIL: binding gate did not catch the real-but-mis-attributed URL"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 11b. Positive: record.url == cited slug's ingested URL == inline marker → success,
#      and the structured url rides through into the manifest.
OUT=$(python3 "$SCRIPT" build --records "$WORK/bound-records.txt" --draft "$WORK/bound-draft.md" \
  --out "$WORK/bound-manifest.json" --draft-version 1 --ingest-manifest "$WORK/ingest-slug.json")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==1, d" 2>/dev/null \
   && python3 -c "import json,pathlib; m=json.loads(pathlib.Path('$WORK/bound-manifest.json').read_text()); assert m['citations'][0]['url']=='https://a.eu/page-a', m" 2>/dev/null; then
  green "PASS: correctly-bound record (url == slug's ingested URL == marker) → success, url in manifest"
else
  red "FAIL: correctly-bound record rejected (or url not persisted)"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 11c. Slug not in ingest manifest → slug leg skipped (e.g. a synthesis-page or
#      prior-run citation has no ingest entry to bind against). Marker matches the
#      record url, so the prose leg is clean → build succeeds (no false positive).
python3 - "$WORK" <<'PY'
import sys, pathlib, json
work = pathlib.Path(sys.argv[1])
url_x = "https://x.eu/prior-run"
(work / "noslug-records.txt").write_text(
    "- id: cit-001\n  pos: 1:1\n  slug: prior-run-slug\n  claim: clm-001\n"
    "  url: " + url_x + "\n"
    "  sentence: A fact from a prior-run source<sup>[1](" + url_x + ")</sup>.\n",
    encoding="utf-8")
(work / "noslug-draft.md").write_text(
    "# R\n\nA fact from a prior-run source<sup>[1](" + url_x + ")</sup>.\n\n"
    "## References\n[[sources/prior-run-slug]]\n", encoding="utf-8")
# ingest manifest knows url_x as a source (so set-membership passes) but under a
# DIFFERENT slug — the cited slug `prior-run-slug` itself is absent, so the slug
# leg is skipped.
(work / "ingest-noslug.json").write_text(
    json.dumps({"schema_version": "0.1.0", "ingested": [
        {"slug": "some-other-slug", "url": url_x},
    ], "skipped": []}), encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/noslug-records.txt" --draft "$WORK/noslug-draft.md" \
  --out "$WORK/noslug-manifest.json" --draft-version 1 --ingest-manifest "$WORK/ingest-noslug.json")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==1, d" 2>/dev/null; then
  green "PASS: cited slug absent from ingest manifest → slug leg skipped, build succeeds"
else
  red "FAIL: binding gate false-positived on a slug with no ingest entry"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 11d. Legacy records (no url: line) + an ingest manifest carrying slugs → the
#      binding gate is per-record skipped (record.url empty); only the #383
#      set-membership gate applies. Proves the new field is additive.
OUT=$(python3 "$SCRIPT" build --records "$WORK/url-records-ok.txt" --draft "$WORK/url-draft-ok.md" \
  --out "$WORK/legacy-bind.json" --draft-version 1 --ingest-manifest "$WORK/ingest.json")
if echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['success'] is True and d['data']['citations_count']==1, d" 2>/dev/null; then
  green "PASS: legacy records without url: → binding gate skipped per-record (additive field)"
else
  red "FAIL: legacy url-less records broke under the binding gate"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 11e. Prose leg in ISOLATION: record.url == the cited slug's ingested URL (slug
#      leg clean), but the sentence's only marker is a DIFFERENT (real, ingested)
#      URL, so record.url is absent from its own markers → prose_bad alone fires.
#      Locks the membership semantics: the set-membership gate passes (both URLs
#      ingested) and the slug leg passes, yet the binding gate still rejects.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
url_a = "https://a.eu/page-a"   # source-a's ingested URL == record.url (slug leg clean)
url_b = "https://b.eu/page-b"   # source-b's ingested URL — the only marker in the sentence
(work / "prose-records.txt").write_text(
    "- id: cit-001\n  pos: 1:1\n  slug: source-a\n  claim: clm-001\n"
    "  url: " + url_a + "\n"
    "  sentence: Fact attributed to source A<sup>[1](" + url_b + ")</sup>.\n",
    encoding="utf-8")
(work / "prose-draft.md").write_text(
    "# R\n\nFact attributed to source A<sup>[1](" + url_b + ")</sup>.\n\n"
    "## References\n[[sources/source-a]]\n", encoding="utf-8")
PY
# Reuses ingest-slug.json from 11 (carries both source-a→url_a and source-b→url_b).
OUT=$(python3 "$SCRIPT" build --records "$WORK/prose-records.txt" --draft "$WORK/prose-draft.md" \
  --out "$WORK/prose-manifest.json" --draft-version 1 --ingest-manifest "$WORK/ingest-slug.json" 2>&1 || true)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False and d['error'] == 'write_failed', d
assert d['data']['failed_check'] == 'url_slug_mismatch', d
assert [m['id'] for m in d['data']['mismatches']] == ['cit-001'], d
" 2>/dev/null && [ ! -f "$WORK/prose-manifest.json" ]; then
  green "PASS: record.url absent from its own marker (slug leg clean) → prose leg fires alone"
else
  red "FAIL: prose-leg-only mismatch not caught (membership semantics regressed)"
  red "  got: $OUT"
  errors=$((errors + 1))
fi

# 12. Per-kind citation breakdown (#385). `build` classifies each citation by its
#     `claim_id` prefix and reports `data.claim_kinds` — the per-run measurement of
#     the distilled-citation (`dcl-NNN`) rate the #344 cross-source-convergence loop
#     produces. This is the deterministic fixture proving the dcl- count path fires
#     end-to-end through the serializer (0 dcl- citations on a converging base was the
#     #385 inert-loop symptom). Records mix a distilled (dcl-), two source (clm-), and
#     a null (synthesis) citation.
python3 - "$WORK" <<'PY'
import sys, pathlib
work = pathlib.Path(sys.argv[1])
# A distilled citation has an empty url (no external URL — plain <sup>[N]</sup>).
records = (
    "- id: cit-001\n  pos: 1:1\n  slug: nis2-meldepflichten\n  claim: dcl-003\n  url: \n"
    "  sentence: Die Meldepflicht folgt der 24h/72h/1-Monats-Kaskade<sup>[1]</sup>.\n"
    "- id: cit-002\n  pos: 1:2\n  slug: bsig-30\n  claim: clm-001\n  url: https://nis.de/a\n"
    "  sentence: Paragraph 30 BSIG listet die Mindestmassnahmen<sup>[2](https://nis.de/a)</sup>.\n"
    "- id: cit-003\n  pos: 1:3\n  slug: bsig-30\n  claim: clm-002\n  url: https://nis.de/a\n"
    "  sentence: Die Geldbussen erreichen 10 Mio EUR oder 2 Prozent<sup>[2](https://nis.de/a)</sup>.\n"
    "- id: cit-004\n  pos: 1:4\n  slug: prior-synthesis\n  claim: null\n  url: \n"
    "  sentence: Eine fruehere Synthese rahmt den Anwendungsbereich<sup>[3]</sup>.\n"
)
draft = (
    "# Bericht\n\n"
    "Die Meldepflicht folgt der 24h/72h/1-Monats-Kaskade<sup>[1]</sup>.\n"
    "Paragraph 30 BSIG listet die Mindestmassnahmen<sup>[2](https://nis.de/a)</sup>.\n"
    "Die Geldbussen erreichen 10 Mio EUR oder 2 Prozent<sup>[2](https://nis.de/a)</sup>.\n"
    "Eine fruehere Synthese rahmt den Anwendungsbereich<sup>[3]</sup>.\n\n"
    "## Referenzen\n[[concepts/nis2-meldepflichten]]\n[[sources/bsig-30]]\n[[syntheses/prior-synthesis]]\n"
)
(work / "kinds-records.txt").write_text(records, encoding="utf-8")
(work / "kinds-draft.md").write_text(draft, encoding="utf-8")
PY
OUT=$(python3 "$SCRIPT" build --records "$WORK/kinds-records.txt" --draft "$WORK/kinds-draft.md" \
  --out "$WORK/kinds-manifest.json" --draft-version 1)
if echo "$OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['citations_count'] == 4, d
# Single dict-equality also pins the absence of an 'other' bucket.
assert d['data']['claim_kinds'] == {'distilled': 1, 'source': 2, 'null': 1}, d
" 2>/dev/null; then
  green "PASS: build reports claim_kinds breakdown (distilled=1 source=2 null=1) — the #385 dcl- measurement"
else
  red "FAIL: claim_kinds breakdown wrong"
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
