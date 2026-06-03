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

# -----------------------------------------------------------------------------
# set-charter (#451) — in-place charter re-frame on an existing base.
# Uses a dedicated base so the upsert-themes assertions above stay isolated.
# -----------------------------------------------------------------------------
KBS="$WORK/kbs"; mkdir -p "$KBS/.cogni-wiki"
echo '{"name":"S","slug":"s","schema_version":"0.0.5"}' > "$KBS/.cogni-wiki/config.json"
BINDING_S="$KBS/.cogni-knowledge/binding.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KBS" --knowledge-slug set-kb \
  --knowledge-title "Set KB" --wiki-path "$KBS" \
  --charter-domain 'EU AI Act' \
  --charter-audience 'compliance officers' \
  --charter-scope 'EU, 2024-2027' \
  --open-themes 'high-risk systems|GPAI' >/dev/null
# Freeze framed_at to a known-past date so the re-stamp is observable.
python3 -c "
import json
b = json.load(open('$BINDING_S'))
b['charter']['framed_at'] = '2025-01-01'
json.dump(b, open('$BINDING_S','w'))
"

# 6. Partial update — only --charter-domain changes; audience/scope intact;
#    framed_at re-stamped; covered_themes/research_projects untouched.
python3 "$SCRIPT" set-charter --knowledge-root "$KBS" \
  --charter-domain 'EU AI Act high-risk obligations' >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING_S'))
c = b['charter']
assert c['domain'] == 'EU AI Act high-risk obligations', c
assert c['audience'] == 'compliance officers', ('audience must stay intact', c)
assert c['scope'] == 'EU, 2024-2027', ('scope must stay intact', c)
assert c['framed_at'] != '2025-01-01', ('framed_at must re-stamp on a field change', c)
assert b['schema_version'] == '0.1.4', ('schema must not bump', b['schema_version'])
assert b['research_projects'] == [], b['research_projects']
assert b['topic_lineage']['covered_themes'] == [], b['topic_lineage']
print('OK')
" | grep -q OK; then
  green "PASS: set-charter partial update changes one field, leaves others + re-stamps framed_at"
else
  red "FAIL: set-charter partial update wrong"; errors=$((errors+1))
fi

# 7. --open-themes unions (no clobber, no dupes, order preserved); an
#    open-themes-only update does NOT re-stamp framed_at (not a re-frame).
python3 -c "
import json
b = json.load(open('$BINDING_S'))
b['charter']['framed_at'] = '2025-02-02'
json.dump(b, open('$BINDING_S','w'))
"
python3 "$SCRIPT" set-charter --knowledge-root "$KBS" \
  --open-themes 'GPAI|conformity assessment' >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING_S'))
ot = b['topic_lineage']['open_themes']
assert ot == ['high-risk systems', 'GPAI', 'conformity assessment'], ('union, order-preserving, no dup', ot)
assert b['charter']['framed_at'] == '2025-02-02', ('open-themes-only must NOT re-stamp', b['charter'])
print('OK')
" | grep -q OK; then
  green "PASS: set-charter --open-themes unions (no dup, order kept), no framed_at re-stamp"
else
  red "FAIL: set-charter open-themes union wrong"; errors=$((errors+1))
fi

# 8. Pre-0.1.4 fail-soft — delete the charter block, set-charter recreates a
#    complete one and seeds open_themes.
KBP="$WORK/kbp"; mkdir -p "$KBP/.cogni-wiki"
echo '{"name":"P","slug":"p","schema_version":"0.0.5"}' > "$KBP/.cogni-wiki/config.json"
python3 "$SCRIPT" init --knowledge-root "$KBP" --knowledge-slug pre-kb \
  --knowledge-title "Pre KB" --wiki-path "$KBP" >/dev/null
python3 -c "
import json
p = '$KBP/.cogni-knowledge/binding.json'
b = json.load(open(p))
del b['charter']
del b['topic_lineage']['open_themes']
json.dump(b, open(p,'w'))
"
python3 "$SCRIPT" set-charter --knowledge-root "$KBP" \
  --charter-domain 'Data Act' --open-themes 'data sharing' >/dev/null
if python3 -c "
import json
b = json.load(open('$KBP/.cogni-knowledge/binding.json'))
c = b['charter']
assert c == {'domain': 'Data Act', 'audience': '', 'scope': '', 'framed_at': c['framed_at']}, c
assert c['framed_at'], ('framed_at stamped', c)
assert b['topic_lineage']['open_themes'] == ['data sharing'], b['topic_lineage']
print('OK')
" | grep -q OK; then
  green "PASS: set-charter on a pre-0.1.4 binding recreates a complete charter fail-soft"
else
  red "FAIL: set-charter pre-0.1.4 fail-soft wrong"; errors=$((errors+1))
fi

# 9. No field flags → success:false, no silent no-op.
OUT9="$(python3 "$SCRIPT" set-charter --knowledge-root "$KBS" 2>&1 || true)"
echo "$OUT9" | grep -q '"success": false' \
  && green "PASS: set-charter with no field flags returns success:false" \
  || { red "FAIL: set-charter no-flags should fail"; echo "$OUT9"; errors=$((errors+1)); }

# 10. Missing binding → clean success:false envelope (not a traceback).
KBM="$WORK/kbm"; mkdir -p "$KBM"
OUT10="$(python3 "$SCRIPT" set-charter --knowledge-root "$KBM" --charter-domain 'X' 2>&1 || true)"
echo "$OUT10" | grep -q '"success": false' \
  && green "PASS: set-charter on a missing binding returns a clean success:false envelope" \
  || { red "FAIL: set-charter missing binding should fail cleanly"; echo "$OUT10"; errors=$((errors+1)); }

# 11. --knowledge-slug mismatch → refuse.
OUT11="$(python3 "$SCRIPT" set-charter --knowledge-root "$KBS" \
  --knowledge-slug wrong-slug --charter-domain 'X' 2>&1 || true)"
echo "$OUT11" | grep -q 'knowledge_slug mismatch' \
  && green "PASS: set-charter refuses on --knowledge-slug mismatch" \
  || { red "FAIL: set-charter slug-mismatch guard wrong"; echo "$OUT11"; errors=$((errors+1)); }

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
