#!/usr/bin/env bash
# test_health_raw_citation_depth.sh — assert wiki-health resolves raw-source
# citations from the page's ACTUAL on-disk location, not by decoding the
# literal `../raw/` prefix.
#
# Regression guard for the bug where pages live two levels deep
# (wiki/<type>/<slug>.md since schema 0.0.5) but the citation convention
# stayed `../raw/<file>` — which resolves to the non-existent `wiki/raw/`
# instead of `<wiki-root>/raw/`. The correct form is `../../raw/<file>`.
# The old check stripped the literal `../raw/` prefix and looked under
# raw/<tail>, so a depth-wrong (unreachable) citation passed "health clean".
#
# Three cases, one wiki run (each page distinguished by the `page` field):
#   1. depth-wrong  `../raw/<existing>`   -> MUST flag  missing_source
#   2. depth-right  `../../raw/<existing>` -> MUST be clean (no missing_source)
#   3. depth-right but absent file `../../raw/<nope>` -> MUST flag missing_source
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
HEALTH="$PLUGIN_ROOT/skills/wiki-health/scripts/health.py"
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

# missing_source raised for a given page? prints "yes"/"no"
missing_source_for() {
  local out="$1" page="$2"
  printf '%s' "$out" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())['data']
page = '$page'
for ent in d.get('errors', []) or []:
    if ent.get('class') == 'missing_source' and ent.get('page') == page:
        print('yes'); break
else:
    print('no')
"
}

# ---------- prepare a migrated 0.0.5 fixture wiki ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null
green "fixture migrated to per-type-dirs layout (0.0.5)"

# ---------- plant a real raw source + three notes pages ----------
TODAY=$(date +%Y-%m-%d)
mkdir -p "$WIKI/raw" "$WIKI/wiki/notes"
echo "raw source body for the depth regression test" > "$WIKI/raw/depth-test-source.md"

plant() {  # $1 = slug, $2 = source citation
  cat > "$WIKI/wiki/notes/$1.md" <<EOF
---
id: $1
title: Depth test $1
type: note
created: $TODAY
updated: $TODAY
sources: [$2]
---

Body long enough to clear the stub-page threshold so the only finding under
test is the raw-source citation resolution behaviour, padding padding padding.
EOF
}

plant "depth-wrong"        "../raw/depth-test-source.md"
plant "depth-right"        "../../raw/depth-test-source.md"
plant "depth-right-absent" "../../raw/does-not-exist.md"
green "planted raw/depth-test-source.md + 3 notes pages (wrong / right / right-absent)"

# ---------- run health once ----------
OUT=$(python3 "$HEALTH" --wiki-root "$WIKI")
assert_success_json "health.py" "$OUT"
green "health.py: success"

# ---------- 1) depth-wrong ../raw/ MUST be flagged ----------
[ "$(missing_source_for "$OUT" depth-wrong)" = "yes" ] \
  || fail "depth-wrong '../raw/depth-test-source.md' was NOT flagged missing_source (the #459 regression)"
green "depth-wrong ../raw/ citation correctly flagged missing_source"

# ---------- 2) depth-right ../../raw/ (file exists) MUST be clean ----------
[ "$(missing_source_for "$OUT" depth-right)" = "no" ] \
  || fail "depth-correct '../../raw/depth-test-source.md' was wrongly flagged missing_source"
green "depth-correct ../../raw/ citation (existing file) is clean"

# ---------- 3) depth-right but absent file MUST be flagged ----------
[ "$(missing_source_for "$OUT" depth-right-absent)" = "yes" ] \
  || fail "absent '../../raw/does-not-exist.md' was NOT flagged missing_source"
green "depth-correct ../../raw/ citation to an absent file correctly flagged missing_source"

green "ALL TESTS PASS"
