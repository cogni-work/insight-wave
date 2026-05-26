#!/usr/bin/env bash
# test_index_placeholder_selfclean.sh — assert wiki_index_update.py sheds the
# wiki-setup seed placeholder (`## Categories` / `_No pages yet…_`) on the first
# real category insert (#306, v0.0.46).
#
# Script-level callers (cogni-knowledge:knowledge-ingest / knowledge-finalize)
# never run the wiki-ingest LLM skill that would otherwise clean the seed, so it
# lingered in the deposited index. This test plants a freshly-seeded index.md,
# runs one insert, and asserts the placeholder + empty heading are gone while the
# real entry landed under its category. A second run asserts idempotency.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPDATE="$PLUGIN_ROOT/skills/wiki-ingest/scripts/wiki_index_update.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

PLACEHOLDER='_No pages yet. Run `wiki-ingest` to add your first source._'

# ---------- seed a wiki/index.md exactly as wiki-setup writes it ----------
mkdir -p "$WIKI/wiki"
cat > "$WIKI/wiki/index.md" <<EOF
# Index

This is the content catalog for **Test Wiki**. Every wiki page is listed here with a one-line summary. Claude consults this file before drilling into specific pages.

## Categories

${PLACEHOLDER}
EOF

green "seeded wiki/index.md with the wiki-setup placeholder"

# ---------- 1) first real insert sheds the seed ----------
OUT=$(python3 "$UPDATE" --wiki-root "$WIKI" \
  --slug eu-ai-act-overview \
  --summary "Overview of the EU AI Act" \
  --category "Regulatory framework")

OK=$(printf '%s' "$OUT" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")' 2>/dev/null || echo "parse-error")
[ "$OK" = "yes" ] || { red "FAIL: insert did not return success:true"; printf '%s\n' "$OUT"; exit 1; }

INDEX_TEXT=$(cat "$WIKI/wiki/index.md")

if printf '%s' "$INDEX_TEXT" | grep -qF "$PLACEHOLDER"; then
  red "FAIL: placeholder line survived the first insert"
  printf '%s\n' "$INDEX_TEXT"
  exit 1
fi
green "placeholder line removed on first insert"

if printf '%s\n' "$INDEX_TEXT" | grep -qx "## Categories"; then
  red "FAIL: empty '## Categories' seed heading survived the first insert"
  printf '%s\n' "$INDEX_TEXT"
  exit 1
fi
green "empty '## Categories' seed heading removed"

if ! printf '%s\n' "$INDEX_TEXT" | grep -qx "## Regulatory framework"; then
  red "FAIL: real category heading was not created"
  printf '%s\n' "$INDEX_TEXT"
  exit 1
fi
if ! printf '%s' "$INDEX_TEXT" | grep -qF "[[eu-ai-act-overview]]"; then
  red "FAIL: the real entry did not land"
  printf '%s\n' "$INDEX_TEXT"
  exit 1
fi
green "real entry landed under its thematic category"

# ---------- 2) idempotency: a second insert is a clean no-op on the seed ----------
OUT2=$(python3 "$UPDATE" --wiki-root "$WIKI" \
  --slug gdpr-records \
  --summary "GDPR Article 30 records of processing" \
  --category "Regulatory framework")
OK2=$(printf '%s' "$OUT2" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")' 2>/dev/null || echo "parse-error")
[ "$OK2" = "yes" ] || { red "FAIL: second insert did not return success:true"; printf '%s\n' "$OUT2"; exit 1; }

INDEX_TEXT2=$(cat "$WIKI/wiki/index.md")
if printf '%s' "$INDEX_TEXT2" | grep -qF "$PLACEHOLDER"; then
  red "FAIL: placeholder reappeared on the second insert (not idempotent)"
  exit 1
fi
if ! printf '%s' "$INDEX_TEXT2" | grep -qF "[[gdpr-records]]"; then
  red "FAIL: second entry did not land"
  printf '%s\n' "$INDEX_TEXT2"
  exit 1
fi
green "second insert idempotent — no placeholder regression, both entries present"

# ---------- 3) a user's real `## Categories` heading with content is preserved ----------
cat > "$WIKI/wiki/index.md" <<EOF
# Index

## Categories

- [[real-page]] — A genuine page the user filed under Categories
EOF
OUT3=$(python3 "$UPDATE" --wiki-root "$WIKI" \
  --slug another-page \
  --summary "Another page" \
  --category "Categories")
OK3=$(printf '%s' "$OUT3" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")' 2>/dev/null || echo "parse-error")
[ "$OK3" = "yes" ] || { red "FAIL: insert into real Categories heading failed"; printf '%s\n' "$OUT3"; exit 1; }
INDEX_TEXT3=$(cat "$WIKI/wiki/index.md")
if ! printf '%s\n' "$INDEX_TEXT3" | grep -qx "## Categories"; then
  red "FAIL: a real '## Categories' heading with content was wrongly removed"
  printf '%s\n' "$INDEX_TEXT3"
  exit 1
fi
if ! printf '%s' "$INDEX_TEXT3" | grep -qF "[[real-page]]"; then
  red "FAIL: existing content under real Categories heading was lost"
  printf '%s\n' "$INDEX_TEXT3"
  exit 1
fi
green "real '## Categories' heading with content preserved (seed match is exact)"

green "ALL TESTS PASS"
