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

# ---------- 3a) seed placeholder PRESENT alongside a real bullet under `## Categories` ----------
# This is the adversarial case the strip logic must actually run on (the seed
# line IS present, so there is no early-return): the placeholder must go, but the
# real `## Categories` heading + its bullet must survive.
cat > "$WIKI/wiki/index.md" <<EOF
# Index

## Categories

${PLACEHOLDER}
- [[real-page]] — A genuine page the user filed under Categories
EOF
OUT3=$(python3 "$UPDATE" --wiki-root "$WIKI" \
  --slug new-a --summary "New A" --category "Other")
OK3=$(printf '%s' "$OUT3" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")' 2>/dev/null || echo "parse-error")
[ "$OK3" = "yes" ] || { red "FAIL: insert alongside seed+real-bullet Categories failed"; printf '%s\n' "$OUT3"; exit 1; }
INDEX_TEXT3=$(cat "$WIKI/wiki/index.md")
if printf '%s' "$INDEX_TEXT3" | grep -qF "$PLACEHOLDER"; then
  red "FAIL: placeholder survived when '## Categories' also carried a real bullet"; printf '%s\n' "$INDEX_TEXT3"; exit 1
fi
if ! printf '%s\n' "$INDEX_TEXT3" | grep -qx "## Categories"; then
  red "FAIL: a real '## Categories' heading with a bullet was wrongly removed"; printf '%s\n' "$INDEX_TEXT3"; exit 1
fi
if ! printf '%s' "$INDEX_TEXT3" | grep -qF "[[real-page]]"; then
  red "FAIL: real bullet under '## Categories' was lost"; printf '%s\n' "$INDEX_TEXT3"; exit 1
fi
green "seed placeholder shed while a real '## Categories' bullet is preserved (strip actually ran)"

# ---------- 3b) seed placeholder PRESENT alongside PROSE-only `## Categories` ----------
# Prose (no page bullets) under a real `## Categories` must NOT be deleted with
# the placeholder (the heading is dropped only when nothing non-blank remains).
cat > "$WIKI/wiki/index.md" <<EOF
# Index

## Categories

${PLACEHOLDER}
Some user notes explaining how this wiki organizes its categories.
EOF
OUT4=$(python3 "$UPDATE" --wiki-root "$WIKI" \
  --slug new-b --summary "New B" --category "Other")
OK4=$(printf '%s' "$OUT4" | python3 -c 'import json,sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")' 2>/dev/null || echo "parse-error")
[ "$OK4" = "yes" ] || { red "FAIL: insert alongside seed+prose Categories failed"; printf '%s\n' "$OUT4"; exit 1; }
INDEX_TEXT4=$(cat "$WIKI/wiki/index.md")
if printf '%s' "$INDEX_TEXT4" | grep -qF "$PLACEHOLDER"; then
  red "FAIL: placeholder survived alongside prose under '## Categories'"; printf '%s\n' "$INDEX_TEXT4"; exit 1
fi
if ! printf '%s\n' "$INDEX_TEXT4" | grep -qx "## Categories"; then
  red "FAIL: a prose-only '## Categories' heading was wrongly removed (A3 regression)"; printf '%s\n' "$INDEX_TEXT4"; exit 1
fi
if ! printf '%s' "$INDEX_TEXT4" | grep -qF "Some user notes explaining"; then
  red "FAIL: user prose under '## Categories' was deleted with the placeholder (A3 regression)"; printf '%s\n' "$INDEX_TEXT4"; exit 1
fi
green "prose under a real '## Categories' preserved while the seed placeholder is shed"

green "ALL TESTS PASS"
