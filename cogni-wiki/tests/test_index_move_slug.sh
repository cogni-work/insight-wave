#!/usr/bin/env bash
# test_index_move_slug.sh — assert wiki_index_update.py's `--move-slug` mode
# (issue #438 Part A): non-destructive, idempotent relocation of an existing
# index.md entry between category headings.
#
# Models the real migration shape: question-node slugs live only under the old
# additive `## Research questions` heading; per-theme sections hold *source*
# slugs. The migration relocates each question node into its theme section and
# drops `## Research questions` once it is drained.
#
# Covers:
#   1. Relocate — a question node moves into its theme section, alphabetised,
#      summary text preserved verbatim; a still-populated source heading stays.
#   2. Empty-heading drop — draining the last bullet drops the source heading
#      (mirrors strip_seed_placeholder's empty-heading discipline).
#   3. Idempotency — a second identical `--move-slug` is action:"noop", file
#      byte-identical.
#   4. Drift safety — the set of `[[wikilinks]]` is unchanged by a move.
#   5. Mutual exclusivity — `--move-slug` with `--slug` or `--reflow-only` fails.
#   6. Lead-in preservation — a source heading that still carries curated prose
#      (no bullets left) is NOT dropped.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPDATE="$PLUGIN_ROOT/skills/wiki-ingest/scripts/wiki_index_update.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"
INDEX="$WIKI/wiki/index.md"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; printf -- '----- index.md -----\n'; cat "$INDEX" 2>/dev/null; exit 1; }

count_heading() { grep -c "^## $1\$" "$INDEX" || true; }
has_line() { grep -qF "$1" "$INDEX"; }
wikilink_set() { grep -oE '\[\[[a-z0-9][a-z0-9-]*\]\]' "$INDEX" | sort -u; }

seed_index() {
  mkdir -p "$WIKI/wiki"
  cat > "$INDEX" <<'EOF'
# Test Base — Knowledge Portal

## Market Shifts
- [[market-source-a]] — a market analysis source
- [[market-source-b]] — another market source

## Research questions
- [[sq-adoption-barriers]] — what blocks adoption
- [[sq-market-demand-drivers]] — what drives demand
EOF
}

# =====================================================================
# CASE 1 + 2a + 4 — relocate one question node into its theme section.
# =====================================================================
seed_index
BEFORE_SET=$(wikilink_set)

python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "sq-market-demand-drivers" \
  --to-category "Market Shifts" >/dev/null

# moved bullet (summary verbatim) now lives under ## Market Shifts, alphabetised
python3 - "$INDEX" <<'PY' || exit 1
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_ms = False
slugs = []
for ln in lines:
    if ln.strip() == "## Market Shifts":
        in_ms = True; continue
    if in_ms and ln.startswith("## "):
        break
    if in_ms and ln.startswith("- [["):
        slugs.append(ln)
joined = "\n".join(slugs)
assert "- [[sq-market-demand-drivers]] — what drives demand" in joined, "moved bullet missing/altered under ## Market Shifts"
# alphabetised by slug: market-source-a < market-source-b < sq-market-demand-drivers
order = [l.split("[[")[1].split("]]")[0] for l in slugs]
assert order == sorted(order), f"not alphabetised: {order}"
PY
green "Case 1: question node relocated into theme section, alphabetised, verbatim"

[ "$(count_heading "Research questions")" = "1" ] \
  || fail "Case 2a: ## Research questions dropped while it still has a bullet"
green "Case 2a: non-empty source heading retained"

AFTER_SET=$(wikilink_set)
[ "$BEFORE_SET" = "$AFTER_SET" ] || fail "Case 4: wikilink set changed across move (drift)"
green "Case 4: WIKILINK set-membership unchanged across move"

# =====================================================================
# CASE 2b — empty-heading drop: drain the last bullet out of ## Research questions.
# =====================================================================
python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "sq-adoption-barriers" \
  --to-category "Adoption" >/dev/null
[ "$(count_heading "Research questions")" = "0" ] \
  || fail "Case 2b: drained ## Research questions heading was not dropped"
green "Case 2b: drained source heading dropped"

# =====================================================================
# CASE 3 — idempotency: a second identical move is a noop, file byte-identical.
# =====================================================================
seed_index
python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "sq-adoption-barriers" --to-category "Adoption" >/dev/null
SNAP=$(cat "$INDEX")
OUT=$(python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "sq-adoption-barriers" --to-category "Adoption")
ACTION=$(printf '%s' "$OUT" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['action'])")
[ "$ACTION" = "noop" ] || fail "Case 3: second move returned action=$ACTION (expected noop)"
[ "$SNAP" = "$(cat "$INDEX")" ] || fail "Case 3: noop move mutated the file"
green "Case 3: second move is a noop and byte-identical"

# =====================================================================
# CASE 5 — mutual exclusivity.
# =====================================================================
seed_index
if python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "x" --to-category "Y" --reflow-only >/dev/null 2>&1; then
  fail "Case 5: --move-slug + --reflow-only did not fail"
fi
green "Case 5a: --move-slug + --reflow-only rejected"
if python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "x" --to-category "Y" --slug "z" --summary "s" --category "C" >/dev/null 2>&1; then
  fail "Case 5: --move-slug + --slug did not fail"
fi
green "Case 5b: --move-slug + --slug/--summary/--category rejected"

# =====================================================================
# CASE 6 — lead-in preservation: a source heading with curated prose but no
# bullets left is NOT dropped.
# =====================================================================
mkdir -p "$WIKI/wiki"
cat > "$INDEX" <<'EOF'
# Test Base

## Syntheses

The verified answers this base produces.

- [[only-synthesis]] — the one synthesis

## Adoption
- [[other-page]] — placeholder
EOF
python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "only-synthesis" --to-category "Adoption" >/dev/null
[ "$(count_heading "Syntheses")" = "1" ] \
  || fail "Case 6: ## Syntheses dropped despite a curated lead-in remaining"
has_line "The verified answers this base produces." \
  || fail "Case 6: curated lead-in lost"
green "Case 6: source heading with curated lead-in preserved"

green "ALL TESTS PASS"
