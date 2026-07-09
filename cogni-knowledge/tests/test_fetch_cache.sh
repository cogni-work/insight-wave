#!/usr/bin/env bash
# test_fetch_cache.sh - smoke test for fetch-cache.py.
#
# Asserts:
#   - key --bare prints sha256(url) with no envelope.
#   - store + fetch round-trip preserves body, fetch_method, status,
#     content_hash, publisher.
#   - fetch --max-age-days short-circuits stale entries with
#     reason="stale" and surfaces the cached entry on data.entry. Backdating
#     uses the public --fetched-at flag, not inline JSON munging.
#   - fetch on a missing URL emits success: false with reason="miss".
#   - store with --status unavailable + --reason produces a negative-cache
#     entry whose reason round-trips on fetch.
#   - --status ok + --reason rejects; --status unavailable without --reason rejects.
#   - evict --dry-run + --older-than-days reports without deleting.
#   - evict drops the stale entry, keeps the fresh entry.
#   - stat reports the right count after evict.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/fetch-cache.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: fetch-cache.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
KB="$WORK/kb"
mkdir -p "$KB/.cogni-knowledge"

errors=0

URL1="https://example.org/article-6"
URL2="https://example.org/article-7"
URL_GONE="https://example.org/gone"

# 1. key --bare prints the hash with no envelope.
EXPECTED_KEY=$(python3 -c "import hashlib; print(hashlib.sha256('$URL1'.encode()).hexdigest())")
GOT_KEY=$(python3 "$SCRIPT" key --url "$URL1" --bare)
if [ "$GOT_KEY" = "$EXPECTED_KEY" ]; then
  green "PASS: key --bare returns sha256(url) with no envelope"
else
  red "FAIL: expected '$EXPECTED_KEY', got '$GOT_KEY'"
  errors=$((errors + 1))
fi

# 2. store + fetch round-trip.
python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "$URL1" \
  --fetch-method webfetch \
  --status ok \
  --body "the body of article 6" \
  --publisher "example.org" \
  --http-status 200 >/dev/null

FETCH_OUT=$(python3 "$SCRIPT" fetch --knowledge-root "$KB" --url "$URL1")
if echo "$FETCH_OUT" | python3 -c "
import sys, json, hashlib
d = json.load(sys.stdin)
assert d['success'] is True, d
e = d['data']['entry']
assert e['url'] == '$URL1', e
assert e['body'] == 'the body of article 6', e
assert e['fetch_method'] == 'webfetch', e
assert e['status'] == 'ok', e
assert e['publisher'] == 'example.org', e
expected_hash = 'sha256:' + hashlib.sha256('the body of article 6'.encode()).hexdigest()
assert e['content_hash'] == expected_hash, (e['content_hash'], expected_hash)
# A clean external body must not false-positive the contamination tripwire.
assert e.get('contamination_suspected') is False, e
assert e.get('contamination_match', '') == '', e
print('OK')
" | grep -q OK; then
  green "PASS: store + fetch round-trip preserves all fields incl. content_hash (clean body flags no contamination)"
else
  red "FAIL: round-trip mismatch"
  red "  got: $FETCH_OUT"
  errors=$((errors + 1))
fi

# 3. fetch with --max-age-days backdated -> stale.
# Re-store via the public --fetched-at flag instead of editing the cache file.
python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "$URL1" \
  --fetch-method webfetch \
  --status ok \
  --body "the body of article 6" \
  --publisher "example.org" \
  --http-status 200 \
  --fetched-at "2020-01-01T00:00:00Z" >/dev/null
STALE_OUT=$(python3 "$SCRIPT" fetch --knowledge-root "$KB" --url "$URL1" --max-age-days 30 || true)
if echo "$STALE_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['reason'] == 'stale', d['data']
assert d['data']['age_days'] > 30, d['data']
assert d['data']['entry']['url'] == '$URL1', d['data']
print('OK')
" | grep -q OK; then
  green "PASS: fetch --max-age-days flags stale entry with reason=stale"
else
  red "FAIL: stale-detection wrong"
  red "  got: $STALE_OUT"
  errors=$((errors + 1))
fi

# 4. fetch on a missing URL.
MISS_OUT=$(python3 "$SCRIPT" fetch --knowledge-root "$KB" --url "https://nonexistent.example/page" || true)
if echo "$MISS_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert d['data']['reason'] == 'miss', d['data']
print('OK')
" | grep -q OK; then
  green "PASS: fetch on missing URL emits reason=miss"
else
  red "FAIL: miss-detection wrong"
  red "  got: $MISS_OUT"
  errors=$((errors + 1))
fi

# 5. Negative-cache entry round-trip.
python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "$URL_GONE" \
  --fetch-method webfetch \
  --status unavailable \
  --reason "webfetch_timeout" >/dev/null

GONE_OUT=$(python3 "$SCRIPT" fetch --knowledge-root "$KB" --url "$URL_GONE")
if echo "$GONE_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
e = d['data']['entry']
assert e['status'] == 'unavailable', e
assert e['reason'] == 'webfetch_timeout', e
assert e['body'] == '', e
assert e['content_hash'] == '', e
print('OK')
" | grep -q OK; then
  green "PASS: negative-cache entry round-trips status + reason"
else
  red "FAIL: negative cache wrong"
  red "  got: $GONE_OUT"
  errors=$((errors + 1))
fi

# 5b. --status ok + --reason should be rejected.
BAD_OK_REASON=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "https://example.org/should-not-store" \
  --fetch-method webfetch \
  --status ok \
  --body "x" \
  --reason "this is meaningless for status=ok" 2>&1 || true)
if echo "$BAD_OK_REASON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert 'reason' in d['error'] and 'unavailable' in d['error'], d
print('OK')
" | grep -q OK; then
  green "PASS: --status ok + --reason is rejected with a clear error"
else
  red "FAIL: --status ok + --reason was not rejected"
  red "  got: $BAD_OK_REASON"
  errors=$((errors + 1))
fi

# 5c. --status unavailable without --reason should be rejected.
BAD_UNAVAIL_NO_REASON=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "https://example.org/should-also-not-store" \
  --fetch-method webfetch \
  --status unavailable 2>&1 || true)
if echo "$BAD_UNAVAIL_NO_REASON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert 'reason' in d['error'] and 'required' in d['error'], d
print('OK')
" | grep -q OK; then
  green "PASS: --status unavailable without --reason is rejected with a clear error"
else
  red "FAIL: --status unavailable without --reason was not rejected"
  red "  got: $BAD_UNAVAIL_NO_REASON"
  errors=$((errors + 1))
fi

# 5c-bis. --reason outside the closed VALID_REASONS vocabulary should be rejected (v0.0.20+).
BAD_REASON=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "https://example.org/closed-vocab-check" \
  --fetch-method webfetch \
  --status unavailable \
  --reason "cobrowse_unavail" 2>&1 || true)
if echo "$BAD_REASON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert 'closed vocabulary' in d['error'], d
print('OK')
" | grep -q OK; then
  green "PASS: --reason outside VALID_REASONS is rejected with a closed-vocabulary error (catches typos)"
else
  red "FAIL: --reason typo was not rejected"
  red "  got: $BAD_REASON"
  errors=$((errors + 1))
fi

# 5d. Empty / whitespace --url should be rejected.
BAD_EMPTY_URL=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "  " \
  --fetch-method webfetch \
  --status ok \
  --body "x" 2>&1 || true)
if echo "$BAD_EMPTY_URL" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert 'url' in d['error'] and 'non-empty' in d['error'], d
print('OK')
" | grep -q OK; then
  green "PASS: whitespace-only --url is rejected"
else
  red "FAIL: whitespace --url was not rejected"
  red "  got: $BAD_EMPTY_URL"
  errors=$((errors + 1))
fi

# 5e. --body and --body-file together should be rejected.
TMP_BODY=$(mktemp)
echo "body from file" > "$TMP_BODY"
BAD_BOTH_BODY=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "https://example.org/both-body-flags" \
  --fetch-method webfetch \
  --status ok \
  --body "inline" \
  --body-file "$TMP_BODY" 2>&1 || true)
rm -f "$TMP_BODY"
if echo "$BAD_BOTH_BODY" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is False, d
assert 'mutually exclusive' in d['error'], d
print('OK')
" | grep -q OK; then
  green "PASS: --body and --body-file together is rejected"
else
  red "FAIL: --body + --body-file together was not rejected"
  red "  got: $BAD_BOTH_BODY"
  errors=$((errors + 1))
fi

# 5f. Malformed cache entry: evict drops it unconditionally (real run);
#     reports it on dry-run without unlinking.
MALFORMED_PATH="$KB/.cogni-knowledge/fetch-cache/0000000000000000000000000000000000000000000000000000000000000000.json"
echo '{not valid json' > "$MALFORMED_PATH"
DRY_MAL=$(python3 "$SCRIPT" evict --knowledge-root "$KB" --older-than-days 999999 --dry-run)
if [ -f "$MALFORMED_PATH" ] && echo "$DRY_MAL" | python3 -c "
import sys, json
d = json.load(sys.stdin)
mal = [e for e in d['data']['evicted'] if e.get('reason') == 'malformed']
assert len(mal) == 1, d['data']['evicted']
print('OK')
" | grep -q OK; then
  green "PASS: dry-run reports malformed entry but does not unlink"
else
  red "FAIL: dry-run handling of malformed entry wrong (file removed=$([ ! -f "$MALFORMED_PATH" ] && echo yes || echo no))"
  red "  got: $DRY_MAL"
  errors=$((errors + 1))
fi
REAL_MAL=$(python3 "$SCRIPT" evict --knowledge-root "$KB" --older-than-days 999999)
if [ ! -f "$MALFORMED_PATH" ] && echo "$REAL_MAL" | python3 -c "
import sys, json
d = json.load(sys.stdin)
mal = [e for e in d['data']['evicted'] if e.get('reason') == 'malformed']
assert len(mal) == 1, d['data']['evicted']
print('OK')
" | grep -q OK; then
  green "PASS: real evict unlinks malformed entry"
else
  red "FAIL: real-evict handling of malformed entry wrong"
  red "  got: $REAL_MAL"
  errors=$((errors + 1))
fi

# 6. Add a fresh entry (URL2) so evict has something to keep.
python3 "$SCRIPT" store \
  --knowledge-root "$KB" \
  --url "$URL2" \
  --fetch-method webfetch \
  --status ok \
  --body "fresh body" >/dev/null

# 7. evict --dry-run reports without deleting.
DRY_OUT=$(python3 "$SCRIPT" evict --knowledge-root "$KB" --older-than-days 30 --dry-run)
DRY_COUNT=$(echo "$DRY_OUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['evicted_count'])")
ENTRIES_AFTER_DRY=$(ls "$KB/.cogni-knowledge/fetch-cache/" | wc -l | tr -d ' ')
# URL1 was backdated -> should be evicted. URL_GONE + URL2 are fresh.
if [ "$DRY_COUNT" = "1" ] && [ "$ENTRIES_AFTER_DRY" = "3" ]; then
  green "PASS: evict --dry-run reports 1 evictee + keeps all 3 files on disk"
else
  red "FAIL: dry-run wrong (evicted_count=$DRY_COUNT, files-on-disk=$ENTRIES_AFTER_DRY)"
  red "  got: $DRY_OUT"
  errors=$((errors + 1))
fi

# 8. Real evict drops the stale, keeps the fresh.
REAL_OUT=$(python3 "$SCRIPT" evict --knowledge-root "$KB" --older-than-days 30)
REAL_COUNT=$(echo "$REAL_OUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['evicted_count'])")
ENTRIES_AFTER_REAL=$(ls "$KB/.cogni-knowledge/fetch-cache/" | wc -l | tr -d ' ')
if [ "$REAL_COUNT" = "1" ] && [ "$ENTRIES_AFTER_REAL" = "2" ]; then
  green "PASS: evict drops 1 stale, leaves 2 fresh entries"
else
  red "FAIL: evict wrong (evicted=$REAL_COUNT, remaining=$ENTRIES_AFTER_REAL)"
  red "  got: $REAL_OUT"
  errors=$((errors + 1))
fi

# 9. stat after evict.
STAT_OUT=$(python3 "$SCRIPT" stat --knowledge-root "$KB")
if echo "$STAT_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['entries'] == 2, d['data']
assert d['data']['ok'] == 1, d['data']
assert d['data']['unavailable'] == 1, d['data']
assert d['data']['total_bytes'] > 0, d['data']
print('OK')
" | grep -q OK; then
  green "PASS: stat reports 2 entries (1 ok, 1 unavailable) after evict"
else
  red "FAIL: stat wrong"
  red "  got: $STAT_OUT"
  errors=$((errors + 1))
fi

# 9. URL normalization at key — semantically identical URLs (case, trailing
# slash, tracking params) must produce the SAME cache key so that the
# curator's dedup (candidate-store.normalize_url) and the cache lookup
# agree. Regression guard for the bug fixed in v0.0.17.
KEY_RAW=$(python3 "$SCRIPT" key --url "https://Example.ORG/Article/?utm_source=x&ref=y" --bare)
KEY_NORM=$(python3 "$SCRIPT" key --url "https://example.org/Article" --bare)
if [ "$KEY_RAW" = "$KEY_NORM" ]; then
  green "PASS: cache key normalizes scheme/host case, trailing slash, tracking params"
else
  red "FAIL: cache keys diverge for semantically identical URLs"
  red "  raw  : $KEY_RAW"
  red "  norm : $KEY_NORM"
  errors=$((errors + 1))
fi

# 10. store + fetch via two equivalent URL forms — body round-trips.
KB2="$WORK/kb2"
mkdir -p "$KB2/.cogni-knowledge"
python3 "$SCRIPT" store \
  --knowledge-root "$KB2" \
  --url "https://EXAMPLE.com/Doc/?utm_source=foo" \
  --fetch-method webfetch \
  --status ok \
  --body "the doc body" \
  --http-status 200 >/dev/null
FETCH_NORM=$(python3 "$SCRIPT" fetch --knowledge-root "$KB2" --url "https://example.com/Doc")
if echo "$FETCH_NORM" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['entry']['body'] == 'the doc body', d
print('OK')
" | grep -q OK; then
  green "PASS: store + fetch round-trip across equivalent URL forms"
else
  red "FAIL: cross-form fetch missed the entry"
  red "  got: $FETCH_NORM"
  errors=$((errors + 1))
fi

# 11. store + fetch a `direct` (non-web / local) source — round-trips with no reason.
KB3="$WORK/kb3"
mkdir -p "$KB3/.cogni-knowledge"
URL_LOCAL="file:///notes/interview-2026-06-06.txt"
python3 "$SCRIPT" store \
  --knowledge-root "$KB3" \
  --url "$URL_LOCAL" \
  --fetch-method direct \
  --status ok \
  --body "verbatim local interview note body" \
  --publisher "local" >/dev/null
FETCH_DIRECT=$(python3 "$SCRIPT" fetch --knowledge-root "$KB3" --url "$URL_LOCAL")
if echo "$FETCH_DIRECT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
e = d['data']['entry']
assert e['fetch_method'] == 'direct', e
assert e['status'] == 'ok', e
assert e['body'] == 'verbatim local interview note body', e
assert e.get('reason') in (None, ''), e
print('OK')
" | grep -q OK; then
  green "PASS: store + fetch round-trip for a direct (non-web) source"
else
  red "FAIL: direct-source round-trip mismatch"
  red "  got: $FETCH_DIRECT"
  errors=$((errors + 1))
fi

# 11b. store + fetch a `webfetch_fulltext` (primary-tier fuller-body) source — round-trips, status ok, no reason.
KB4="$WORK/kb4"
mkdir -p "$KB4/.cogni-knowledge"
URL_FULLTEXT="https://eur-lex.example/legal-content/EN/TXT/?uri=annex-iii"
python3 "$SCRIPT" store \
  --knowledge-root "$KB4" \
  --url "$URL_FULLTEXT" \
  --fetch-method webfetch_fulltext \
  --status ok \
  --body "verbatim full annex text with every enumerated clause" \
  --publisher "eur-lex" >/dev/null
FETCH_FULLTEXT=$(python3 "$SCRIPT" fetch --knowledge-root "$KB4" --url "$URL_FULLTEXT")
if echo "$FETCH_FULLTEXT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
e = d['data']['entry']
assert e['fetch_method'] == 'webfetch_fulltext', e
assert e['status'] == 'ok', e
assert e['body'] == 'verbatim full annex text with every enumerated clause', e
assert e.get('reason') in (None, ''), e
print('OK')
" | grep -q OK; then
  green "PASS: store + fetch round-trip for a webfetch_fulltext (primary-tier fuller-body) source"
else
  red "FAIL: webfetch_fulltext round-trip mismatch"
  red "  got: $FETCH_FULLTEXT"
  errors=$((errors + 1))
fi

# 11c. Contamination tripwire: a body carrying pipeline-internal tokens is
#      flagged (flag-and-store, fail-soft) on both the store envelope and the
#      fetched entry, but is still persisted.
KB5="$WORK/kb5"
mkdir -p "$KB5/.cogni-knowledge"
URL_CONTAM="https://arxiv.example/pdf/2506.17208"
CONTAM_BODY="Benchmark analysis (relevant to this curator's own sq-06 set) SWE-rebench (this same session's other candidate). Real content follows."
STORE_CONTAM=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB5" \
  --url "$URL_CONTAM" \
  --fetch-method webfetch \
  --status ok \
  --body "$CONTAM_BODY" \
  --publisher "arxiv")
if echo "$STORE_CONTAM" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['contamination_suspected'] is True, d['data']
assert d['data']['contamination_match'], d['data']
print('OK')
" | grep -q OK; then
  green "PASS: store envelope surfaces contamination_suspected + match on a pipeline-token body"
else
  red "FAIL: store did not surface contamination flag"
  red "  got: $STORE_CONTAM"
  errors=$((errors + 1))
fi
FETCH_CONTAM=$(python3 "$SCRIPT" fetch --knowledge-root "$KB5" --url "$URL_CONTAM")
if echo "$FETCH_CONTAM" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
e = d['data']['entry']
# flag-and-store: the body is still persisted verbatim, and the flag rides on the entry.
assert e['body'].startswith('Benchmark analysis'), e
assert e['contamination_suspected'] is True, e
assert e['contamination_match'], e
print('OK')
" | grep -q OK; then
  green "PASS: contamination flag rides through fetch on data.entry (body still stored)"
else
  red "FAIL: fetch did not carry the contamination flag"
  red "  got: $FETCH_CONTAM"
  errors=$((errors + 1))
fi

# 12. an unknown fetch-method is still rejected by argparse choices.
BAD_METHOD=$(python3 "$SCRIPT" store \
  --knowledge-root "$KB3" \
  --url "https://example.org/x" \
  --fetch-method scrape \
  --status ok \
  --body "x" 2>&1 || true)
if echo "$BAD_METHOD" | grep -q "invalid choice: 'scrape'"; then
  green "PASS: unknown --fetch-method is rejected (closed vocabulary held)"
else
  red "FAIL: unknown --fetch-method was not rejected"
  red "  got: $BAD_METHOD"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All fetch-cache.py cases pass."
