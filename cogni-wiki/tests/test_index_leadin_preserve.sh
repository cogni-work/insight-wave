#!/usr/bin/env bash
# test_index_leadin_preserve.sh — lock the curated-portal guarantee:
# wiki_index_update.py MUST preserve a curated per-theme lead-in paragraph
# (the prose between a `## <theme>` heading and its first `- [[slug]]` bullet)
# when it inserts a new auto-bullet under that heading.
#
# This is the script-side enabler for the "single curated Knowledge Portal
# index.md" consolidation: a curated index can only be safe if the
# deterministic inserter never clobbers the editorial lead-in. It mirrors the
# "preserve the human tail" discipline cogni-knowledge/scripts/question-store.py
# uses for `## Notes` — inverted here to preserve the LEAD.
#
# Two section states are exercised:
#   1. POPULATED section — lead-in + existing bullets; new bullet inserts
#      alphabetically among the bullets, lead-in untouched.
#   2. EMPTY-BULLET section — lead-in but no bullets yet; the first bullet
#      lands BELOW the lead-in, lead-in untouched.
# Both also assert no duplicate `## <theme>` heading is created.
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

LEADIN_SYN="The verified answers this base produces. Start here, then follow the evidence."
LEADIN_Q="The research questions this base answers; each links to the sources that answer it."

# ---------- seed a curated portal-shaped index ----------
mkdir -p "$WIKI/wiki"
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

$LEADIN_SYN

- [[alpha-synthesis]] — first synthesis
- [[omega-synthesis]] — last synthesis

## Questions

$LEADIN_Q
EOF

green "seeded curated portal index (## Syntheses w/ lead-in + 2 bullets; ## Questions w/ lead-in, no bullets)"

# ---------- helper: count occurrences of a heading ----------
count_heading() { grep -c "^## $1\$" "$INDEX" || true; }
# ---------- helper: literal-substring presence ----------
has_line() { grep -qF "$1" "$INDEX"; }

# =====================================================================
# CASE 1 — populated section: insert a bullet that sorts BETWEEN the two.
# =====================================================================
python3 "$UPDATE" --wiki-root "$WIKI" --slug "mid-synthesis" \
  --summary "middle synthesis" --category "Syntheses" >/dev/null

has_line "$LEADIN_SYN" \
  || fail "Case 1: curated ## Syntheses lead-in was lost after insert"
green "Case 1: lead-in preserved byte-for-byte"

[ "$(count_heading Syntheses)" = "1" ] \
  || fail "Case 1: duplicate ## Syntheses heading created (count=$(count_heading Syntheses))"
green "Case 1: exactly one ## Syntheses heading"

# alphabetical order among bullets: alpha < mid < omega
ORDER=$(grep -oE '\[\[(alpha|mid|omega)-synthesis\]\]' "$INDEX" | tr '\n' ' ')
[ "$ORDER" = "[[alpha-synthesis]] [[mid-synthesis]] [[omega-synthesis]] " ] \
  || fail "Case 1: bullets not alphabetised (got: $ORDER)"
green "Case 1: new bullet inserted alphabetically (alpha < mid < omega)"

# lead-in must still sit ABOVE the first bullet under ## Syntheses
python3 - "$INDEX" <<'PY' || exit 1
import sys
text = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_syn = False
seen_leadin = False
for ln in text:
    if ln.strip() == "## Syntheses":
        in_syn = True; continue
    if in_syn and ln.startswith("## "):
        break
    if in_syn and ln.startswith("The verified answers"):
        seen_leadin = True
    if in_syn and ln.startswith("- [[") and not seen_leadin:
        print("FAIL: a bullet precedes the curated lead-in under ## Syntheses")
        sys.exit(1)
sys.exit(0 if seen_leadin else 1)
PY
green "Case 1: lead-in still precedes the bullet block"

# =====================================================================
# CASE 2 — empty-bullet section: first bullet lands BELOW the lead-in.
# =====================================================================
python3 "$UPDATE" --wiki-root "$WIKI" --slug "first-question" \
  --summary "the first question" --category "Questions" >/dev/null

has_line "$LEADIN_Q" \
  || fail "Case 2: curated ## Questions lead-in was lost after first-bullet insert"
green "Case 2: lead-in preserved on empty-bullet section"

[ "$(count_heading Questions)" = "1" ] \
  || fail "Case 2: duplicate ## Questions heading created (count=$(count_heading Questions))"
green "Case 2: exactly one ## Questions heading"

has_line "[[first-question]]" \
  || fail "Case 2: the new bullet was not inserted under ## Questions"

# lead-in must precede the new bullet under ## Questions
python3 - "$INDEX" <<'PY' || exit 1
import sys
text = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_q = False
seen_leadin = False
for ln in text:
    if ln.strip() == "## Questions":
        in_q = True; continue
    if in_q and ln.startswith("## "):
        break
    if in_q and ln.startswith("The research questions"):
        seen_leadin = True
    if in_q and ln.startswith("- [[first-question]]"):
        if not seen_leadin:
            print("FAIL: the first bullet precedes the curated lead-in under ## Questions")
            sys.exit(1)
        sys.exit(0)
sys.exit(1)
PY
green "Case 2: first bullet lands below the lead-in"

green "ALL TESTS PASS"
