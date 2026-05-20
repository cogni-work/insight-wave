#!/usr/bin/env bash
# test_fetch_cache.sh - smoke test for fetch-cache.py.
#
# Asserts:
#   - key --bare prints sha256(url) with no envelope.
#   - store + fetch round-trip preserves body, fetch_method, status,
#     content_hash, publisher.
#   - fetch --max-age-days short-circuits stale entries with
#     reason="stale" and surfaces the cached entry on data.entry.
#   - fetch on a missing URL emits success: false with reason="miss".
#   - store with --status unavailable + --reason produces a negative-cache
#     entry whose reason round-trips on fetch.
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
print('OK')
" | grep -q OK; then
  green "PASS: store + fetch round-trip preserves all fields incl. content_hash"
else
  red "FAIL: round-trip mismatch"
  red "  got: $FETCH_OUT"
  errors=$((errors + 1))
fi

# 3. fetch with --max-age-days backdated -> stale.
# Backdate by directly rewriting fetched_at to an old date.
ENTRY_PATH="$KB/.cogni-knowledge/fetch-cache/${EXPECTED_KEY}.json"
python3 -c "
import json
p = '$ENTRY_PATH'
e = json.load(open(p))
e['fetched_at'] = '2020-01-01T00:00:00Z'
json.dump(e, open(p, 'w'), indent=2)
"
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

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All fetch-cache.py cases pass."
