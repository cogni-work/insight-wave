#!/usr/bin/env bash
# test_prefill.sh — smoke test for prefill_foundations.py (#224, v0.0.33).
#
# 1. Fixture prep: copy legacy-wiki, migrate to per-type layout.
# 2. --list mode → returns the curated set without touching the wiki.
# 3. --filter consulting --dry-run → plans copies but writes nothing.
# 4. --filter consulting (wet) → copies the consulting subset, bumps
#    entries_count, files exist with foundation: true frontmatter and
#    {{PREFILL_DATE}} substituted to today's ISO date.
# 5. Idempotent re-run → 0 copied, all skipped_existing.
# 6. lint_wiki.py over the prefilled wiki → no orphan_page / no_sources /
#    stale_page warnings for any foundation slug.
# 7. Pre-migration probe → standard hard-fail message.
# 8. wiki-update refusal contract — confirmed structurally: every
#    foundation page contains `foundation: true` in frontmatter.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
SCRIPT="$PLUGIN_ROOT/skills/wiki-prefill/scripts/prefill_foundations.py"
LINT="$PLUGIN_ROOT/skills/wiki-lint/scripts/lint_wiki.py"
FOUNDATIONS_DIR="$PLUGIN_ROOT/foundations"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

assert_success_json() {
  local label="$1" out="$2" ok
  ok=$(printf '%s' "$out" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print("yes" if d.get("success") else "no")' 2>/dev/null || echo "parse-error")
  if [ "$ok" != "yes" ]; then
    red "FAIL ($label): expected success:true"
    printf '%s\n' "$out"
    exit 1
  fi
}

# Extract a list field's length from the JSON output. Avoids relying on jq.
json_list_len() {
  printf '%s' "$1" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print(len(d['data'].get('$2', [])))
"
}

json_field() {
  printf '%s' "$1" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print(d['data'].get('$2', ''))
"
}

# ---------- prepare a migrated fixture ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null
green "fixture prepared (migrated to per-type layout)"

# ---------- 1) --list mode ----------
OUT=$(python3 "$SCRIPT" --list)
assert_success_json "--list (no wiki)" "$OUT"
LIST_LEN=$(json_list_len "$OUT" available)
[ "$LIST_LEN" -ge 11 ] || fail "--list: expected ≥11 foundations available, got $LIST_LEN"
green "--list (no wiki): $LIST_LEN foundations available"

OUT=$(python3 "$SCRIPT" --list --filter consulting)
assert_success_json "--list --filter consulting" "$OUT"
CONS_LEN=$(json_list_len "$OUT" available)
[ "$CONS_LEN" -ge 5 ] || fail "--list --filter consulting: expected ≥5, got $CONS_LEN"
green "--list --filter consulting: $CONS_LEN foundations"

# Confirm porters-five-forces is in the consulting filter.
echo "$OUT" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
slugs = [it['slug'] for it in d['data']['available']]
assert 'porters-five-forces' in slugs, f'missing porters-five-forces in consulting filter: {slugs}'
" || fail "consulting filter missing porters-five-forces"
green "consulting filter contains porters-five-forces"

# ---------- 2) --dry-run ----------
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --filter consulting --dry-run)
assert_success_json "--dry-run" "$OUT"
DRY_DELTA=$(json_field "$OUT" entries_count_delta)
[ "$DRY_DELTA" = "0" ] || fail "--dry-run: expected entries_count_delta=0, got $DRY_DELTA"
DRY_COPIED=$(json_list_len "$OUT" copied)
[ "$DRY_COPIED" -ge 5 ] || fail "--dry-run: expected ≥5 copied (planned), got $DRY_COPIED"
# Confirm no files were actually written.
[ ! -f "$WIKI/wiki/concepts/porters-five-forces.md" ] || \
  fail "--dry-run wrote porters-five-forces.md but should not have"
green "--dry-run: planned $DRY_COPIED, wrote 0 files"

# ---------- 3) wet apply ----------
PRE_COUNT=$(python3 -c "
import json
print(json.load(open('$WIKI/.cogni-wiki/config.json'))['entries_count'])
")
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --filter consulting)
assert_success_json "wet apply" "$OUT"
COPIED=$(json_list_len "$OUT" copied)
DELTA=$(json_field "$OUT" entries_count_delta)
[ "$COPIED" -ge 5 ] || fail "wet apply: expected ≥5 copied, got $COPIED"
[ "$DELTA" = "$COPIED" ] || fail "wet apply: delta $DELTA != copied $COPIED"
green "wet apply: copied $COPIED, entries_count_delta=$DELTA"

# Files exist?
[ -f "$WIKI/wiki/concepts/porters-five-forces.md" ] || \
  fail "porters-five-forces.md not written"
[ -f "$WIKI/wiki/concepts/mece.md" ] || fail "mece.md not written"

# Frontmatter has foundation: true and {{PREFILL_DATE}} replaced.
TODAY=$(date -u +%Y-%m-%d)
grep -q '^foundation: true$' "$WIKI/wiki/concepts/porters-five-forces.md" || \
  fail "porters-five-forces.md missing foundation: true"
grep -q "^created: $TODAY$" "$WIKI/wiki/concepts/porters-five-forces.md" || \
  fail "porters-five-forces.md created: not substituted to today"
grep -q "^updated: $TODAY$" "$WIKI/wiki/concepts/porters-five-forces.md" || \
  fail "porters-five-forces.md updated: not substituted to today"
grep -q "{{PREFILL_DATE}}" "$WIKI/wiki/concepts/porters-five-forces.md" && \
  fail "porters-five-forces.md still contains {{PREFILL_DATE}} placeholder" || true
green "frontmatter correct: foundation: true, dates substituted"

# entries_count bumped on disk?
POST_COUNT=$(python3 -c "
import json
print(json.load(open('$WIKI/.cogni-wiki/config.json'))['entries_count'])
")
EXPECTED=$((PRE_COUNT + COPIED))
[ "$POST_COUNT" = "$EXPECTED" ] || \
  fail "entries_count drift: pre=$PRE_COUNT delta=$COPIED post=$POST_COUNT expected=$EXPECTED"
green "entries_count bumped: $PRE_COUNT → $POST_COUNT"

# ---------- 4) idempotency ----------
OUT=$(python3 "$SCRIPT" --wiki-root "$WIKI" --filter consulting)
assert_success_json "idempotent re-run" "$OUT"
RE_COPIED=$(json_list_len "$OUT" copied)
RE_SKIPPED=$(json_list_len "$OUT" skipped_existing)
RE_DELTA=$(json_field "$OUT" entries_count_delta)
[ "$RE_COPIED" = "0" ] || fail "idempotent re-run: expected copied=0, got $RE_COPIED"
[ "$RE_SKIPPED" = "$COPIED" ] || \
  fail "idempotent re-run: expected skipped_existing=$COPIED, got $RE_SKIPPED"
[ "$RE_DELTA" = "0" ] || fail "idempotent re-run: expected delta=0, got $RE_DELTA"
green "idempotent re-run: copied=0, skipped=$RE_SKIPPED"

# entries_count unchanged after re-run.
RE_POST=$(python3 -c "
import json
print(json.load(open('$WIKI/.cogni-wiki/config.json'))['entries_count'])
")
[ "$RE_POST" = "$POST_COUNT" ] || \
  fail "entries_count changed on idempotent re-run: $POST_COUNT → $RE_POST"
green "entries_count stable on re-run: $RE_POST"

# ---------- 5) lint skips foundations ----------
OUT=$(python3 "$LINT" --wiki-root "$WIKI")
assert_success_json "lint after prefill" "$OUT"
# Assert no warnings of class orphan_page / no_sources / stale_page /
# stale_draft target a foundation slug.
echo "$OUT" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
foundation_slugs = {'porters-five-forces','mece','pyramid-principle','swot','value-chain','bcg-matrix','double-diamond'}
bad_classes = {'orphan_page','no_sources','stale_page','stale_draft'}
violations = [w for w in d['data']['warnings']
              if w['class'] in bad_classes and w['page'] in foundation_slugs]
if violations:
    print('lint flagged a foundation page:', violations)
    sys.exit(1)
fc = d['data']['stats'].get('foundation_count', 0)
if fc < 5:
    print(f'foundation_count too low: {fc}')
    sys.exit(1)
print('foundation_count =', fc)
" || fail "lint flagged a foundation page (it should not)"
green "lint correctly skips orphan/no_sources/stale for foundations"

# ---------- 6) pre-migration probe ----------
cp -R "$FIXTURES/legacy-wiki" "$WORKDIR/legacy-wiki"
OUT=$(python3 "$SCRIPT" --wiki-root "$WORKDIR/legacy-wiki" --filter all 2>/dev/null || true)
RESULT=$(printf '%s' "$OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
print("ok" if (not d.get("success")) and ("pre-migration" in d.get("error", "")) else "bad")
' 2>/dev/null || echo "parse-error")
[ "$RESULT" = "ok" ] || fail "pre-migration probe: expected success:false with pre-migration message; got: $OUT"
green "pre-migration probe: hard-fail with migration message"

# ---------- 7) every foundation file has foundation: true ----------
# Plugin-side contract check — guards against a contributor adding a new
# foundation file but forgetting the frontmatter flag.
for f in "$FOUNDATIONS_DIR"/*.md; do
  case "$(basename "$f")" in
    README.md) continue ;;
  esac
  grep -q '^foundation: true$' "$f" || \
    fail "plugin-side foundation $f missing 'foundation: true' frontmatter"
done
green "all foundation files declare 'foundation: true'"

# ---------- 8) SKILL.md-contract sentinel assertions ----------
# Acceptance criterion 6 ("assert ingest dedupe; assert wiki-update
# refusal") covers behaviours that are LLM-orchestrated SKILL.md
# instructions, so we cannot drive them from a shell test. The closest
# deterministic safety net is grep-based contract sentinels: if a
# regression silently deletes the instruction, these assertions catch
# it at CI time.

WIKI_UPDATE_SKILL="$PLUGIN_ROOT/skills/wiki-update/SKILL.md"
WIKI_INGEST_SKILL="$PLUGIN_ROOT/skills/wiki-ingest/SKILL.md"
WIKI_FROM_RESEARCH_SKILL="$PLUGIN_ROOT/skills/wiki-from-research/SKILL.md"
SCHEMA_TEMPLATE="$PLUGIN_ROOT/skills/wiki-setup/references/SCHEMA.md.template"

# 8a. wiki-update refusal contract
grep -q 'foundation: true' "$WIKI_UPDATE_SKILL" || \
  fail "wiki-update SKILL.md missing 'foundation: true' refusal contract"
grep -q '\-\-force' "$WIKI_UPDATE_SKILL" || \
  fail "wiki-update SKILL.md missing '--force' override mention"
green "wiki-update SKILL.md sentinel: foundation refusal + --force present"

# 8b. wiki-ingest foundation-collision branch
grep -q 'foundation: true' "$WIKI_INGEST_SKILL" || \
  fail "wiki-ingest SKILL.md missing 'foundation: true' detection"
grep -qiE 'foundation collision|foundation.*refus' "$WIKI_INGEST_SKILL" || \
  fail "wiki-ingest SKILL.md missing 'Foundation collision' branch"
green "wiki-ingest SKILL.md sentinel: foundation collision branch present"

# 8c. SCHEMA.md.template log enum includes prefill
grep -q '|prefill}' "$SCHEMA_TEMPLATE" || \
  fail "SCHEMA.md.template log-format enum missing 'prefill' verb"
green "SCHEMA.md.template sentinel: 'prefill' in log-format enum"

# 8d. wiki-from-research dispatches wiki-setup with --skip-prefill-prompt
grep -q '\-\-skip-prefill-prompt' "$WIKI_FROM_RESEARCH_SKILL" || \
  fail "wiki-from-research SKILL.md missing '--skip-prefill-prompt' on the wiki-setup dispatch"
green "wiki-from-research SKILL.md sentinel: --skip-prefill-prompt wired"

# ---------- 9) _wikilib.is_foundation_page helper sanity ----------
# The detection contract is owned by `_wikilib.is_foundation_page` so
# every consumer (lint today, wiki-update / wiki-ingest LLM-side
# tomorrow) reads the same source of truth.
HELPER_PROBE=$(python3 - <<'PY'
import sys
sys.path.insert(0, "skills/wiki-ingest/scripts")
from _wikilib import is_foundation_page
ok = (
    is_foundation_page({"foundation": "true"}) is True and
    is_foundation_page({"foundation": "True"}) is True and
    is_foundation_page({"foundation": True}) is True and
    is_foundation_page({"foundation": "false"}) is False and
    is_foundation_page({"foundation": ""}) is False and
    is_foundation_page({}) is False
)
print("ok" if ok else "bad")
PY
)
[ "$HELPER_PROBE" = "ok" ] || fail "is_foundation_page helper sanity check failed: $HELPER_PROBE"
green "_wikilib.is_foundation_page handles bool / 'true' / 'True' / missing"

# Live page check: read a copied foundation page's frontmatter and confirm
# the helper returns True against it. This proves the lint pipeline's
# detection is consistent with what wiki-prefill writes to disk.
LIVE_PROBE=$(WIKI="$WIKI" python3 - <<'PY'
import os, sys
sys.path.insert(0, "skills/wiki-ingest/scripts")
sys.path.insert(0, "skills/wiki-lint/scripts")
from _wikilib import is_foundation_page
from lint_wiki import parse_frontmatter
text = open(os.path.join(os.environ["WIKI"], "wiki/concepts/porters-five-forces.md"), encoding="utf-8").read()
print("ok" if is_foundation_page(parse_frontmatter(text)) else "bad")
PY
)
[ "$LIVE_PROBE" = "ok" ] || fail "is_foundation_page returned False on copied porters-five-forces.md"
green "_wikilib.is_foundation_page detects a copied foundation page"

green "ALL PASS — wiki-prefill smoke test"
