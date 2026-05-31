#!/usr/bin/env bash
# test_pipeline_summary.sh - smoke test for pipeline-summary.py (M10a).
#
# Asserts:
#   - project: full project (all six manifests) returns the right counts,
#     reads topic from plan.json, and reports phase_reached="verify".
#   - project: latest verify-vN.json wins (plant v0 and v1; v1 counts surface).
#   - project: partial project (plan+candidates+fetch only) counts those and
#     reports phase_reached="fetch", zeros downstream.
#   - project: missing .metadata degrades to zeros + phase_reached="none"
#     (no crash — the legacy v0.0.x posture).
#   - cache-health: empty cache -> verdict="empty".
#   - cache-health: one fresh ok entry -> verdict="healthy", negative_ratio=0.
#   - cache-health: backdated entry past max_age_days -> verdict="stale".
#   - cache-health: negative_ratio reflects unavailable/entries.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/pipeline-summary.py"
FETCH_CACHE="$PLUGIN_ROOT/scripts/fetch-cache.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: pipeline-summary.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

# --- Fixture planting helpers --------------------------------------------
plant() {
  # plant <abs-file-path> <<heredoc-content
  local target="$1"
  mkdir -p "$(dirname "$target")"
  cat > "$target"
}

# --- Scenario: full project ----------------------------------------------
FULL="$WORK/full/.metadata"
plant "$FULL/plan.json" <<'JSON'
{"schema_version":"0.1.0","topic":"EU AI Act Article 6","sub_questions":[{"id":"sq-01"},{"id":"sq-02"},{"id":"sq-03"}]}
JSON
plant "$FULL/candidates.json" <<'JSON'
{"schema_version":"0.1.0","candidates":[{"url":"a"},{"url":"b"},{"url":"c"},{"url":"d"}]}
JSON
plant "$FULL/fetch-manifest.json" <<'JSON'
{"schema_version":"0.1.0","fetched":[{"url":"a"},{"url":"b"},{"url":"c"}],"unavailable":[{"url":"d","reason":"webfetch_timeout"}]}
JSON
plant "$FULL/ingest-manifest.json" <<'JSON'
{"schema_version":"0.1.0","ingested":[{"url":"a"},{"url":"b"}],"skipped":[{"url":"c","reason":"cache_miss"}]}
JSON
plant "$FULL/distill-manifest.json" <<'JSON'
{"schema_version":"0.1.0","concepts":[{"slug":"x","action":"created"},{"slug":"y","action":"created"},{"slug":"z","action":"updated"}],"claims_attached_total":9,"claims_deduped_total":2}
JSON
plant "$FULL/citation-manifest.json" <<'JSON'
{"schema_version":"0.1.0","draft_version":2,"citations":[{"draft_position":"01:01","claim_id":"dcl-003"},{"draft_position":"02:03","claim_id":"clm-001"}]}
JSON
# v0 first, then v1 with different counts — v1 must win.
plant "$FULL/verify-v0.json" <<'JSON'
{"schema_version":"0.1.0","revision_round":0,"counts":{"verbatim":1,"paraphrase":1,"synthesis":0,"unsupported":5,"total":7}}
JSON
plant "$FULL/verify-v1.json" <<'JSON'
{"schema_version":"0.1.0","revision_round":1,"counts":{"verbatim":4,"paraphrase":28,"synthesis":2,"unsupported":3,"total":37}}
JSON

FULL_OUT=$(python3 "$SCRIPT" project --project-path "$WORK/full")
if echo "$FULL_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
x = d['data']
assert x['topic'] == 'EU AI Act Article 6', x
assert x['sub_questions'] == 3, x
assert x['candidates'] == 4, x
assert x['fetched'] == 3, x
assert x['unavailable'] == 1, x
assert x['ingested'] == 2, x
assert x['skipped'] == 1, x
assert x['citations'] == 2, x
assert x['draft_version'] == 2, x
assert x['phase_reached'] == 'verify', x
# Distill (Phase 4.5, #336) read-side counts.
assert x['concepts_created'] == 2, x
assert x['concepts_updated'] == 1, x
assert x['concepts_total'] == 3, x
assert x['claims_attached'] == 9, x
assert x['claims_deduped'] == 2, x
print('OK')
" | grep -q OK; then
  green "PASS: project full — all manifest counts + distill counts + topic + phase_reached=verify"
else
  red "FAIL: full-project summary wrong"
  red "  got: $FULL_OUT"
  errors=$((errors + 1))
fi

if echo "$FULL_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
x = d['data']
assert x['verify_version'] == 1, x
c = x['verify_counts']
assert c == {'verbatim':4,'paraphrase':28,'synthesis':2,'unsupported':3,'total':37}, c
assert x['revision_round'] == 1, x
print('OK')
" | grep -q OK; then
  green "PASS: project full — latest verify-v1.json counts win over v0"
else
  red "FAIL: latest-verify selection wrong"
  red "  got: $FULL_OUT"
  errors=$((errors + 1))
fi

# #337 field-name regression guard: knowledge-dashboard's §"Claim verification
# scope" surfacing reads verify_counts.verbatim + .paraphrase by name. A rename
# of either field would silently break the dashboard's ratio surface, so pin the
# key names explicitly (independent of the whole-dict equality assert above).
if echo "$FULL_OUT" | python3 -c "
import sys, json
c = json.load(sys.stdin)['data']['verify_counts']
assert 'verbatim' in c, 'verify_counts missing verbatim key (#337 dashboard dependency)'
assert 'paraphrase' in c, 'verify_counts missing paraphrase key (#337 dashboard dependency)'
print('OK')
" | grep -q OK; then
  green "PASS: project full — verify_counts exposes stable 'verbatim' + 'paraphrase' keys (#337 dashboard dependency)"
else
  red "FAIL: verify_counts must expose 'verbatim' + 'paraphrase' keys for the dashboard (#337)"
  red "  got: $FULL_OUT"
  errors=$((errors + 1))
fi

# --- Scenario: partial project (plan+candidates+fetch only) --------------
PARTIAL="$WORK/partial/.metadata"
plant "$PARTIAL/plan.json" <<'JSON'
{"schema_version":"0.1.0","topic":"partial","sub_questions":[{"id":"sq-01"},{"id":"sq-02"}]}
JSON
plant "$PARTIAL/candidates.json" <<'JSON'
{"schema_version":"0.1.0","candidates":[{"url":"a"}]}
JSON
plant "$PARTIAL/fetch-manifest.json" <<'JSON'
{"schema_version":"0.1.0","fetched":[{"url":"a"}],"unavailable":[]}
JSON

PARTIAL_OUT=$(python3 "$SCRIPT" project --project-path "$WORK/partial")
if echo "$PARTIAL_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
x = d['data']
assert x['sub_questions'] == 2, x
assert x['candidates'] == 1, x
assert x['fetched'] == 1, x
assert x['ingested'] == 0, x
assert x['citations'] == 0, x
assert x['verify_counts']['total'] == 0, x
assert x['phase_reached'] == 'fetch', x
print('OK')
" | grep -q OK; then
  green "PASS: project partial — counts present phases, zeros downstream, phase_reached=fetch"
else
  red "FAIL: partial-project summary wrong"
  red "  got: $PARTIAL_OUT"
  errors=$((errors + 1))
fi

# --- Scenario: missing .metadata (legacy v0.0.x project) -----------------
mkdir -p "$WORK/legacy"
MISSING_OUT=$(python3 "$SCRIPT" project --project-path "$WORK/legacy")
if echo "$MISSING_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
x = d['data']
assert x['sub_questions'] == 0, x
assert x['fetched'] == 0, x
assert x['citations'] == 0, x
assert x['topic'] == '', x
assert x['verify_version'] is None, x
assert x['phase_reached'] == 'none', x
print('OK')
" | grep -q OK; then
  green "PASS: project missing — degrades to zeros + phase_reached=none (no crash)"
else
  red "FAIL: missing-manifest degradation wrong"
  red "  got: $MISSING_OUT"
  errors=$((errors + 1))
fi

# --- cache-health: empty -------------------------------------------------
KB="$WORK/kb"
mkdir -p "$KB/.cogni-knowledge"
EMPTY_OUT=$(python3 "$SCRIPT" cache-health --knowledge-root "$KB")
if echo "$EMPTY_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
x = d['data']
assert x['entries'] == 0, x
assert x['verdict'] == 'empty', x
assert x['scope'] == 'knowledge-base-global', x
print('OK')
" | grep -q OK; then
  green "PASS: cache-health — empty cache -> verdict=empty"
else
  red "FAIL: empty cache-health wrong"
  red "  got: $EMPTY_OUT"
  errors=$((errors + 1))
fi

# --- cache-health: one fresh ok entry -> healthy -------------------------
python3 "$FETCH_CACHE" store \
  --knowledge-root "$KB" \
  --url "https://example.org/fresh" \
  --fetch-method webfetch \
  --status ok \
  --body "fresh body" >/dev/null
HEALTHY_OUT=$(python3 "$SCRIPT" cache-health --knowledge-root "$KB")
if echo "$HEALTHY_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
x = d['data']
assert x['entries'] == 1, x
assert x['ok'] == 1, x
assert x['unavailable'] == 0, x
assert x['negative_ratio'] == 0.0, x
assert x['verdict'] == 'healthy', x
print('OK')
" | grep -q OK; then
  green "PASS: cache-health — fresh ok entry -> verdict=healthy, negative_ratio=0"
else
  red "FAIL: healthy cache-health wrong"
  red "  got: $HEALTHY_OUT"
  errors=$((errors + 1))
fi

# --- cache-health: add an unavailable entry -> negative_ratio ------------
python3 "$FETCH_CACHE" store \
  --knowledge-root "$KB" \
  --url "https://example.org/gone" \
  --fetch-method webfetch \
  --status unavailable \
  --reason webfetch_timeout >/dev/null
NEG_OUT=$(python3 "$SCRIPT" cache-health --knowledge-root "$KB")
if echo "$NEG_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
x = d['data']
assert x['entries'] == 2, x
assert x['unavailable'] == 1, x
assert x['negative_ratio'] == 0.5, x
print('OK')
" | grep -q OK; then
  green "PASS: cache-health — negative_ratio = unavailable/entries"
else
  red "FAIL: negative_ratio wrong"
  red "  got: $NEG_OUT"
  errors=$((errors + 1))
fi

# --- cache-health: backdated entry past max_age_days -> stale ------------
KB2="$WORK/kb2"
mkdir -p "$KB2/.cogni-knowledge"
python3 "$FETCH_CACHE" store \
  --knowledge-root "$KB2" \
  --url "https://example.org/old" \
  --fetch-method webfetch \
  --status ok \
  --body "old body" \
  --fetched-at "2020-01-01T00:00:00Z" >/dev/null
STALE_OUT=$(python3 "$SCRIPT" cache-health --knowledge-root "$KB2")
if echo "$STALE_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
x = d['data']
assert x['entries'] == 1, x
assert x['oldest_age_days'] is not None and x['oldest_age_days'] > x['max_age_days'], x
assert x['verdict'] == 'stale', x
print('OK')
" | grep -q OK; then
  green "PASS: cache-health — backdated entry past max_age_days -> verdict=stale"
else
  red "FAIL: stale cache-health wrong"
  red "  got: $STALE_OUT"
  errors=$((errors + 1))
fi

# --- Robustness: a manifest path that is a DIRECTORY degrades, not crashes --
# Regression guard: _load_json must treat an unreadable manifest (incl. a
# directory where a file is expected) as absent, never raise to a traceback.
DIRMAN="$WORK/dirman/.metadata"
mkdir -p "$DIRMAN/verify-v1.json"   # verify-v1.json is a DIRECTORY
plant "$DIRMAN/plan.json" <<'JSON'
{"topic":"dir-manifest","sub_questions":[{"id":"sq-01"}]}
JSON
DIR_OUT=$(python3 "$SCRIPT" project --project-path "$WORK/dirman" 2>/dev/null || true)
if echo "$DIR_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['phase_reached'] == 'plan', d['data']
assert d['data']['verify_version'] is None, d['data']
print('OK')
" 2>/dev/null | grep -q OK; then
  green "PASS: project — a directory-shaped manifest degrades gracefully (no crash)"
else
  red "FAIL: directory-shaped manifest crashed or mis-summarized"
  red "  got: $DIR_OUT"
  errors=$((errors + 1))
fi

# --- Robustness: boolean values in verify counts clamp to 0 (bool ⊄ int) ----
BOOLMAN="$WORK/boolman/.metadata"
mkdir -p "$BOOLMAN"
plant "$BOOLMAN/verify-v0.json" <<'JSON'
{"counts":{"verbatim":true,"paraphrase":5,"synthesis":0,"unsupported":0,"total":5},"revision_round":true}
JSON
BOOL_OUT=$(python3 "$SCRIPT" project --project-path "$WORK/boolman")
if echo "$BOOL_OUT" | python3 -c "
import sys, json
x = json.load(sys.stdin)['data']
assert x['verify_counts']['verbatim'] == 0, x       # bool true -> 0
assert x['verify_counts']['paraphrase'] == 5, x     # real int preserved
assert x['revision_round'] == 0, x                  # bool true -> 0
print('OK')
" | grep -q OK; then
  green "PASS: project — boolean count values clamp to 0, real ints preserved"
else
  red "FAIL: boolean-in-counts not clamped"
  red "  got: $BOOL_OUT"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
