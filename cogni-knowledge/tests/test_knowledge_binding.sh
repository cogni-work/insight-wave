#!/usr/bin/env bash
# test_knowledge_binding.sh — functional test for knowledge-binding.py
# upsert-themes (#409): the SOLE writer of topic_lineage.covered_themes[].
#
# Asserts:
#   1. init writes schema_version 0.1.4 with an empty covered_themes[].
#   2. upsert-themes APPENDS a fresh entry for an unseen theme_key
#      (first_seen == last_seen, labels seeded from theme_label).
#   3. A second upsert-themes for the SAME theme_key with a NEW label UNIONS
#      labels[], bumps last_seen, and keeps first_seen frozen; question_slug
#      refreshes to the latest record.
#   4. Liberal record parsing — the full question-store {success, data:
#      {theme_bindings: []}} envelope is accepted (not just the bare array).
#   5. A malformed record (missing theme_key/question_slug) is skipped, never
#      corrupting the block.
#
# bash 3.2 + stdlib python3 only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/knowledge-binding.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: knowledge-binding.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

KB="$WORK/kb"
WIKI="$KB"
mkdir -p "$WIKI/.cogni-wiki"
echo '{"name":"Test","slug":"test","schema_version":"0.0.5"}' > "$WIKI/.cogni-wiki/config.json"

BINDING="$KB/.cogni-knowledge/binding.json"

# 1. init — schema 0.1.4, empty covered_themes[].
python3 "$SCRIPT" init \
  --knowledge-root "$KB" --knowledge-slug test-kb \
  --knowledge-title "Test KB" --wiki-path "$WIKI" >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING'))
assert b['schema_version'] == '0.1.4', b['schema_version']
assert b['topic_lineage']['covered_themes'] == [], b['topic_lineage']
# 0.1.4 charter — a plain init writes a complete all-empty block, framed_at ''.
assert b['charter'] == {'domain': '', 'audience': '', 'scope': '', 'framed_at': ''}, b['charter']
assert b['topic_lineage']['open_themes'] == [], b['topic_lineage']
print('OK')
" | grep -q OK; then
  green "PASS: init writes schema 0.1.4 + empty covered_themes[] + empty charter"
else
  red "FAIL: init schema/covered_themes/charter wrong"; errors=$((errors+1))
fi

# 1b. init with charter + open-themes flags — charter populated, framed_at set,
#     open_themes parsed from the pipe-separated list.
KBC="$WORK/kbc"; mkdir -p "$KBC/.cogni-wiki"
echo '{"name":"T","slug":"t","schema_version":"0.0.5"}' > "$KBC/.cogni-wiki/config.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KBC" --knowledge-slug test-kbc \
  --knowledge-title "Test KBC" --wiki-path "$KBC" \
  --charter-domain 'EU AI Act compliance' \
  --charter-audience 'compliance officers' \
  --charter-scope 'EU, 2024-2027' \
  --open-themes 'high-risk systems|conformity assessment|GPAI' >/dev/null
if python3 -c "
import json
b = json.load(open('$KBC/.cogni-knowledge/binding.json'))
c = b['charter']
assert c['domain'] == 'EU AI Act compliance', c
assert c['audience'] == 'compliance officers', c
assert c['scope'] == 'EU, 2024-2027', c
assert c['framed_at'], c  # stamped when any field is non-empty
assert b['topic_lineage']['open_themes'] == ['high-risk systems', 'conformity assessment', 'GPAI'], b['topic_lineage']
print('OK')
" | grep -q OK; then
  green "PASS: init --charter-* / --open-themes populate charter + open_themes[]"
else
  red "FAIL: charter/open-themes flags not honoured"; errors=$((errors+1))
fi

# 2. upsert-themes — append a fresh theme (bare array form, via stdin).
printf '%s' '[{"theme_key":"process record scope","question_slug":"records-of-processing-scope","theme_label":"Records of Processing Scope","action":"new_theme"}]' \
  | python3 "$SCRIPT" upsert-themes --knowledge-root "$KB" --records - >/dev/null
if python3 -c "
import json
ct = json.load(open('$BINDING'))['topic_lineage']['covered_themes']
assert len(ct) == 1, ct
e = ct[0]
assert e['theme_key'] == 'process record scope', e
assert e['question_slug'] == 'records-of-processing-scope', e
assert e['labels'] == ['Records of Processing Scope'], e
assert e['first_seen'] == e['last_seen'], e
print('OK')
" | grep -q OK; then
  green "PASS: upsert-themes appends a fresh entry (first_seen==last_seen, labels seeded)"
else
  red "FAIL: append entry wrong"; errors=$((errors+1))
fi

# Freeze first_seen to a known-past date so the bump is observable.
python3 -c "
import json
b = json.load(open('$BINDING'))
b['topic_lineage']['covered_themes'][0]['first_seen'] = '2025-01-01'
b['topic_lineage']['covered_themes'][0]['last_seen'] = '2025-01-01'
json.dump(b, open('$BINDING','w'))
"

# 3. upsert-themes — SAME theme_key, NEW label, via the full envelope form (file).
RECS="$WORK/recs.json"
cat > "$RECS" <<'EOF'
{"success": true, "data": {"theme_bindings": [
  {"theme_key":"process record scope","question_slug":"records-of-processing-scope-v2","theme_label":"Scope of Processing Records","action":"lineage_reused"}
]}}
EOF
OUT3="$(python3 "$SCRIPT" upsert-themes --knowledge-root "$KB" --records "$RECS")"
echo "$OUT3" | grep -q '"themes_updated": 1' \
  && green "PASS: upsert-themes reports themes_updated=1 (envelope form accepted)" \
  || { red "FAIL: themes_updated!=1 or envelope rejected"; echo "$OUT3"; errors=$((errors+1)); }
if python3 -c "
import json
ct = json.load(open('$BINDING'))['topic_lineage']['covered_themes']
assert len(ct) == 1, ('no new entry expected', ct)
e = ct[0]
assert e['labels'] == ['Records of Processing Scope', 'Scope of Processing Records'], e
assert e['first_seen'] == '2025-01-01', ('first_seen must stay frozen', e)
assert e['last_seen'] != '2025-01-01', ('last_seen must bump', e)
assert e['question_slug'] == 'records-of-processing-scope-v2', ('question_slug refreshes', e)
print('OK')
" | grep -q OK; then
  green "PASS: re-upsert unions labels[], bumps last_seen, freezes first_seen, refreshes question_slug"
else
  red "FAIL: update semantics wrong"; errors=$((errors+1))
fi

# 5. Malformed record (missing question_slug) is skipped, block intact.
printf '%s' '[{"theme_key":"orphan key no slug","theme_label":"X"}]' \
  | python3 "$SCRIPT" upsert-themes --knowledge-root "$KB" --records - >/dev/null
if python3 -c "
import json
ct = json.load(open('$BINDING'))['topic_lineage']['covered_themes']
assert len(ct) == 1, ('malformed record must not append', ct)
print('OK')
" | grep -q OK; then
  green "PASS: malformed record (no question_slug) skipped, block uncorrupted"
else
  red "FAIL: malformed record corrupted the block"; errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
