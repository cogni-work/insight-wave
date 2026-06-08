#!/usr/bin/env bash
# test_knowledge_binding.sh — functional test for knowledge-binding.py
# upsert-themes (#409): the SOLE writer of topic_lineage.covered_themes[].
#
# Asserts:
#   1. init writes schema_version 0.1.5 with empty covered_themes[]/refresh_candidates[].
#   2. upsert-themes APPENDS a fresh entry for an unseen theme_key
#      (first_seen == last_seen, labels seeded from theme_label).
#   3. A second upsert-themes for the SAME theme_key with a NEW label UNIONS
#      labels[], bumps last_seen, and keeps first_seen frozen; question_slug
#      refreshes to the latest record.
#   4. Liberal record parsing — the full question-store {success, data:
#      {theme_bindings: []}} envelope is accepted (not just the bare array).
#   5. A malformed record (missing theme_key/question_slug) is skipped, never
#      corrupting the block.
#   6. themes (#450) partitions the seed backlog open MINUS covered at read time
#      (matched by theme_norm_key), renders a covered[] display list, never
#      mutates the stored open_themes[], and degrades fail-soft on a
#      structurally-wrong binding.
#   7. set-charter (#451) in-place re-frames an existing base: partial field
#      update + framed_at re-stamp; --open-themes union-merge (no re-stamp);
#      pre-0.1.4 fail-soft; no-flags / missing-binding → clean success:false;
#      --knowledge-slug mismatch refusal.
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

# 1. init — schema 0.1.5, empty covered_themes[] + refresh_candidates[].
python3 "$SCRIPT" init \
  --knowledge-root "$KB" --knowledge-slug test-kb \
  --knowledge-title "Test KB" --wiki-path "$WIKI" >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING'))
assert b['schema_version'] == '0.1.5', b['schema_version']
assert b['topic_lineage']['covered_themes'] == [], b['topic_lineage']
# 0.1.4 charter — a plain init writes a complete all-empty block, framed_at ''.
assert b['charter'] == {'domain': '', 'audience': '', 'scope': '', 'framed_at': ''}, b['charter']
assert b['topic_lineage']['open_themes'] == [], b['topic_lineage']
# 0.1.5 — init seeds an empty refresh_candidates[].
assert b['refresh_candidates'] == [], b['refresh_candidates']
print('OK')
" | grep -q OK; then
  green "PASS: init writes schema 0.1.5 + empty covered_themes[]/refresh_candidates[] + empty charter"
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
assert b['schema_version'] == '0.1.5', ('schema must not bump', b['schema_version'])
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

# 12. Clearing the last steering field must NOT re-stamp framed_at — mirrors
#     init's invariant (framed_at stamped only when a steering field is
#     non-empty), so a cleared charter stays distinguishable from a fresh one.
#     A dedicated base whose ONLY steering field is domain.
KBCLR="$WORK/kbclr"; mkdir -p "$KBCLR/.cogni-wiki"
echo '{"name":"C","slug":"c","schema_version":"0.0.5"}' > "$KBCLR/.cogni-wiki/config.json"
BINDING_CLR="$KBCLR/.cogni-knowledge/binding.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KBCLR" --knowledge-slug clear-kb \
  --knowledge-title "Clear KB" --wiki-path "$KBCLR" \
  --charter-domain 'EU AI Act' >/dev/null
# Freeze framed_at to a known-past date so a (wrong) re-stamp would be visible.
python3 -c "
import json
b = json.load(open('$BINDING_CLR'))
b['charter']['framed_at'] = '2025-03-03'
json.dump(b, open('$BINDING_CLR','w'))
"
# Clear the only steering field — supplying an explicit empty string.
python3 "$SCRIPT" set-charter --knowledge-root "$KBCLR" --charter-domain '' >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING_CLR'))
c = b['charter']
assert c['domain'] == '', ('domain must clear', c)
assert c['framed_at'] == '2025-03-03', ('clearing the last field must NOT re-stamp', c)
print('OK')
" | grep -q OK; then
  green "PASS: set-charter clearing the last steering field does not re-stamp framed_at"
else
  red "FAIL: set-charter clearing case re-stamped framed_at"; errors=$((errors+1))
fi

# 12b. A subsequent non-empty re-steer DOES re-stamp (the common path stays).
python3 "$SCRIPT" set-charter --knowledge-root "$KBCLR" \
  --charter-domain 'EU AI Act high-risk' >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING_CLR'))
c = b['charter']
assert c['domain'] == 'EU AI Act high-risk', c
assert c['framed_at'] != '2025-03-03', ('a non-empty re-steer must re-stamp', c)
print('OK')
" | grep -q OK; then
  green "PASS: set-charter non-empty re-steer still re-stamps framed_at"
else
  red "FAIL: set-charter non-empty re-steer failed to re-stamp"; errors=$((errors+1))
fi

# --- themes subcommand (#450): open MINUS covered at read time -------------
# A fresh KB with a seed backlog, one of whose themes has been "researched"
# (its theme_norm_key recorded in covered_themes[]). Display must hide the
# researched seed without mutating the stored open_themes[].
KBT="$WORK/kbt"; mkdir -p "$KBT/.cogni-wiki"
echo '{"name":"T","slug":"t","schema_version":"0.0.5"}' > "$KBT/.cogni-wiki/config.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KBT" --knowledge-slug test-kbt \
  --knowledge-title "Test KBT" --wiki-path "$KBT" \
  --open-themes 'high-risk systems|conformity assessment|GPAI' >/dev/null
BINDT="$KBT/.cogni-knowledge/binding.json"
# Record a covered theme keyed by theme_norm_key("High-Risk AI Systems"); a
# variant phrasing of the "high-risk systems" seed (both fold to the same key).
python3 -c "
import json, sys
sys.path.insert(0, '$PLUGIN_ROOT/scripts')
from _knowledge_lib import theme_norm_key
b = json.load(open('$BINDT'))
b['topic_lineage']['covered_themes'] = [{
    'theme_key': theme_norm_key('High-Risk AI Systems'),
    'question_slug': 'high-risk-ai-systems',
    'labels': ['High-Risk AI Systems'],
    'first_seen': '2025-01-01', 'last_seen': '2025-02-01',
}]
json.dump(b, open('$BINDT','w'))
"
OUTT="$(python3 "$SCRIPT" themes --knowledge-root "$KBT")"
if echo "$OUTT" | python3 -c "
import json, sys
d = json.load(sys.stdin)['data']
# (a) the researched seed is hidden from open_active and (b) the un-researched
# seeds stay; matched by theme_norm_key despite the phrasing difference.
assert d['open_active'] == ['conformity assessment', 'GPAI'], d['open_active']
assert d['open_covered'] == ['high-risk systems'], d['open_covered']
# (d) covered[] renders labels[0] with the question_slug bound for reference.
assert d['covered'] == [{'label': 'High-Risk AI Systems', 'question_slug': 'high-risk-ai-systems'}], d['covered']
assert d['open_total'] == 3 and d['covered_total'] == 1, (d['open_total'], d['covered_total'])
print('OK')
" | grep -q OK; then
  green "PASS: themes hides a researched seed (open MINUS covered via theme_norm_key), keeps the rest"
else
  red "FAIL: themes open/covered partition wrong"; echo "$OUTT"; errors=$((errors+1))
fi

# themes does NOT mutate the stored backlog (display-only, approach (a)).
if python3 -c "
import json
b = json.load(open('$BINDT'))
assert b['topic_lineage']['open_themes'] == ['high-risk systems', 'conformity assessment', 'GPAI'], b['topic_lineage']['open_themes']
print('OK')
" | grep -q OK; then
  green "PASS: themes leaves the stored open_themes[] untouched (non-destructive)"
else
  red "FAIL: themes mutated open_themes[]"; errors=$((errors+1))
fi

# (d-fallback) covered[] with an empty labels[] falls back to question_slug.
python3 -c "
import json
b = json.load(open('$BINDT'))
b['topic_lineage']['covered_themes'].append({
    'theme_key': 'unlabelled key', 'question_slug': 'some-slug',
    'labels': [], 'first_seen': '2025-03-01', 'last_seen': '2025-03-01',
})
json.dump(b, open('$BINDT','w'))
"
if python3 "$SCRIPT" themes --knowledge-root "$KBT" | python3 -c "
import json, sys
cov = json.load(sys.stdin)['data']['covered']
assert {'label': 'some-slug', 'question_slug': 'some-slug'} in cov, cov
print('OK')
" | grep -q OK; then
  green "PASS: themes covered[] falls back to question_slug when labels[] is empty"
else
  red "FAIL: covered[] labels[0]/question_slug fallback wrong"; errors=$((errors+1))
fi

# (c) an empty / whitespace open entry never hides (an empty key matches nothing).
KBW="$WORK/kbw"; mkdir -p "$KBW/.cogni-knowledge"
cat > "$KBW/.cogni-knowledge/binding.json" <<'EOF'
{"topic_lineage": {"open_themes": ["  ", ""], "covered_themes": []}, "schema_version": "0.1.4"}
EOF
if python3 "$SCRIPT" themes --knowledge-root "$KBW" | python3 -c "
import json, sys
d = json.load(sys.stdin)['data']
assert d['open_active'] == ['  ', ''], d['open_active']
assert d['open_covered'] == [], d['open_covered']
print('OK')
" | grep -q OK; then
  green "PASS: themes keeps empty/whitespace open entries visible (empty key never hides)"
else
  red "FAIL: empty-key open entry wrongly hidden"; errors=$((errors+1))
fi

# (e) a structurally-wrong topic_lineage degrades fail-soft to empty partitions.
KBF="$WORK/kbf"; mkdir -p "$KBF/.cogni-knowledge"
for SHAPE in '{"topic_lineage": [], "schema_version": "0.1.4"}' \
             '{"topic_lineage": null, "schema_version": "0.1.4"}' \
             '{"schema_version": "0.1.0"}'; do
  printf '%s' "$SHAPE" > "$KBF/.cogni-knowledge/binding.json"
  if python3 "$SCRIPT" themes --knowledge-root "$KBF" | python3 -c "
import json, sys
o = json.load(sys.stdin)
assert o['success'] is True, o
d = o['data']
assert d['open_active'] == [] and d['open_covered'] == [] and d['covered'] == [], d
print('OK')
" | grep -q OK; then
    green "PASS: themes fail-soft on structurally-wrong binding ($SHAPE)"
  else
    red "FAIL: themes did not degrade fail-soft for $SHAPE"; errors=$((errors+1))
  fi
done

# -----------------------------------------------------------------------------
# add-refresh-candidates / resolve-refresh-candidate (schema 0.1.5) — the
# evidence-aware refresh signal block.
# -----------------------------------------------------------------------------
KBR="$WORK/kbr"; mkdir -p "$KBR/.cogni-wiki"
echo '{"name":"R","slug":"r","schema_version":"0.0.5"}' > "$KBR/.cogni-wiki/config.json"
BINDING_R="$KBR/.cogni-knowledge/binding.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KBR" --knowledge-slug refresh-kb \
  --knowledge-title "Refresh KB" --wiki-path "$KBR" >/dev/null

# 9. add — a fresh candidate is appended; --triggered-by seeds triggered_by_source[].
printf '%s' '[{"synthesis_slug":"syn-a","title":"Synth A","via_pages":["src-x"],"confidence":"high"}]' \
  | python3 "$SCRIPT" add-refresh-candidates --knowledge-root "$KBR" --records - --triggered-by src-new >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING_R'))
rc = b['refresh_candidates']
assert len(rc) == 1, rc
e = rc[0]
assert e['synthesis_slug'] == 'syn-a', e
assert e['synthesis_title'] == 'Synth A', e
assert e['triggered_by_source'] == ['src-new'], e
assert e['via_pages'] == ['src-x'], e
assert e['status'] == 'open', e
print('OK')
" | grep -q OK; then
  green "PASS: add-refresh-candidates appends a fresh candidate"
else
  red "FAIL: add-refresh-candidates append wrong"; errors=$((errors+1))
fi

# 10. add again (same slug, new trigger + new via page) — dedup by synthesis_slug,
#     union triggered_by_source[] + via_pages[], no second entry.
printf '%s' '{"data":{"refresh_candidates":[{"synthesis_slug":"syn-a","title":"Synth A","via_pages":["concept-y"]}]}}' \
  | python3 "$SCRIPT" add-refresh-candidates --knowledge-root "$KBR" --records - --triggered-by src-two >/dev/null
if python3 -c "
import json
b = json.load(open('$BINDING_R'))
rc = b['refresh_candidates']
assert len(rc) == 1, ('must dedup by synthesis_slug', rc)
e = rc[0]
assert e['triggered_by_source'] == ['src-new', 'src-two'], ('union triggers', e)
assert e['via_pages'] == ['concept-y', 'src-x'], ('union via_pages sorted', e)
print('OK')
" | grep -q OK; then
  green "PASS: add-refresh-candidates dedups + unions on a repeat trigger (full envelope accepted)"
else
  red "FAIL: add-refresh-candidates dedup/union wrong"; errors=$((errors+1))
fi

# 11. resolve (hit) — removes the matching entry.
if python3 "$SCRIPT" resolve-refresh-candidate --knowledge-root "$KBR" --synthesis-slug syn-a | python3 -c "
import json, sys
o = json.load(sys.stdin)
assert o['success'] is True, o
assert o['data']['removed'] == 1, o['data']
assert o['data']['refresh_candidates_count'] == 0, o['data']
import json as j
b = j.load(open('$BINDING_R'))
assert b['refresh_candidates'] == [], b['refresh_candidates']
print('OK')
" | grep -q OK; then
  green "PASS: resolve-refresh-candidate removes the matching entry"
else
  red "FAIL: resolve-refresh-candidate remove wrong"; errors=$((errors+1))
fi

# 12. resolve (miss) — no-op success, count unchanged.
if python3 "$SCRIPT" resolve-refresh-candidate --knowledge-root "$KBR" --synthesis-slug nope | python3 -c "
import json, sys
o = json.load(sys.stdin)
assert o['success'] is True, o
assert o['data']['removed'] == 0, o['data']
print('OK')
" | grep -q OK; then
  green "PASS: resolve-refresh-candidate no-ops on a missing slug"
else
  red "FAIL: resolve-refresh-candidate no-op wrong"; errors=$((errors+1))
fi

# 13. Legacy pre-0.1.5 fall-through — a binding with NO refresh_candidates key:
#     add setdefault()s it, resolve no-ops, readers never KeyError.
KBL="$WORK/kbl"; mkdir -p "$KBL/.cogni-knowledge"
printf '%s' '{"knowledge_slug":"legacy","schema_version":"0.1.4"}' > "$KBL/.cogni-knowledge/binding.json"
if python3 "$SCRIPT" resolve-refresh-candidate --knowledge-root "$KBL" --synthesis-slug whatever | python3 -c "
import json, sys
assert json.load(sys.stdin)['success'] is True
print('OK')
" | grep -q OK \
  && printf '%s' '[{"synthesis_slug":"syn-z","title":"Z"}]' \
     | python3 "$SCRIPT" add-refresh-candidates --knowledge-root "$KBL" --records - >/dev/null \
  && python3 -c "
import json
b = json.load(open('$KBL/.cogni-knowledge/binding.json'))
assert b['refresh_candidates'][0]['synthesis_slug'] == 'syn-z', b
print('OK')
" | grep -q OK; then
  green "PASS: refresh-candidate writers fall through on a pre-0.1.5 binding"
else
  red "FAIL: pre-0.1.5 fall-through wrong"; errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
