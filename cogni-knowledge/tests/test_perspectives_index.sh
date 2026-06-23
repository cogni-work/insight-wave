#!/usr/bin/env bash
# test_perspectives_index.sh — deterministic-renderer test for perspectives_index.py.
#
# perspectives_index.py is a derived OVERLAY sibling of root_index.py: it renders
# wiki/perspectives.md as a 5W1H re-projection (Who/What/Why backed by surviving
# types; When/Where thin v1 facets with honest signposts) WITHOUT changing the
# canonical type-first layout. The former `How` facet was dropped (permanently
# dead, no backing type). The vendored engine is never touched, so
# test_vendored_engine_parity.sh stays green.
#
# Asserts:
#   1. render creates wiki/perspectives.md with a well-formed envelope + changed:true.
#   2. The page carries the # Perspectives H1 + the MACHINE-OWNED:PERSPECTIVES-INDEX
#      marker + the intro line + the secondary-view labels / overview signpost.
#   3. Each of the five 5W1H facets renders `## <Facet>` + a MACHINE-OWNED:
#      PERSPECTIVES-FACET:<slug> lead-in span, and `## How` no longer renders.
#   4. Backed facets (Who=people+entities, What=concepts+sources, Why=questions+
#      syntheses) show **Explore:** count-links to wiki/<type>/index.md with counts.
#   5. When/Where render their custom bodies (timeline / market grouping) when the
#      fixture has data, and an honest signpost (not the generic empty line) when
#      thin; no facet renders the generic honest-empty line in this fixture.
#   6. BYTE-IDEMPOTENT: a re-render on an unchanged wiki reports changed:false and
#      leaves the page byte-identical.
#   7. CARRY-FORWARD: a narrator-edited facet lead-in survives a re-render verbatim
#      (the engine never regenerates an authored PERSPECTIVES-FACET span).
#   8. HUMAN-PAGE: a hand-authored perspectives.md (no PERSPECTIVES-INDEX marker) is
#      skipped (skipped_human_page:true), not clobbered.
#   9. stage writes <wiki-root>/.cogni-wiki/perspectives-proposed.md without touching
#      the live page.
#  10. python3.9 floor: perspectives_index.py carries `from __future__ import
#      annotations` and parses cleanly under ast.parse.
#
# bash 3.2 + stdlib python3 only. Posix only (render uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERSP_SCRIPT="$PLUGIN_ROOT/scripts/perspectives_index.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"
errors=0

# --- 10. python3.9 floor (no _wikilib needed) --------------------------------
grep -q 'from __future__ import annotations' "$PERSP_SCRIPT" \
  && green "PASS: perspectives_index.py declares __future__ annotations (py3.9 floor)" \
  || { red "FAIL: missing __future__ annotations import"; errors=$((errors+1)); }
python3 -c "import ast,sys; ast.parse(open('$PERSP_SCRIPT').read())" \
  && green "PASS: perspectives_index.py parses cleanly (ast.parse)" \
  || { red "FAIL: perspectives_index.py does not parse"; errors=$((errors+1)); }

if [ ! -f "$WSD/_wikilib.py" ]; then
  red "SKIP: cogni-wiki _wikilib not found at $WSD (render needs _wiki_lock)"
  [ "$errors" -eq 0 ] && exit 0 || exit 1
fi

WIKI="$(mktemp -d)"
trap 'rm -rf "$WIKI" 2>/dev/null || true' EXIT
mkdir -p "$WIKI/.cogni-wiki" \
  "$WIKI/wiki/concepts" "$WIKI/wiki/entities" "$WIKI/wiki/people" \
  "$WIKI/wiki/sources" "$WIKI/wiki/questions" "$WIKI/wiki/syntheses"

mk() { printf '%s\n' "$2" > "$1"; }
mk "$WIKI/wiki/sources/src-a.md" '---
id: src-a
type: source
title: Source A
theme_label: Scope
market: "dach"
---
body'
mk "$WIKI/wiki/concepts/concept-a.md" '---
id: concept-a
type: concept
title: Concept A
theme_label: Scope
---
body'
mk "$WIKI/wiki/entities/ent-a.md" '---
id: ent-a
type: entity
title: Entity A
theme_label: Scope
---
body'
mk "$WIKI/wiki/people/per-a.md" '---
id: per-a
type: person
title: Person A
theme_label: Scope
---
body'
mk "$WIKI/wiki/questions/q-a.md" '---
id: q-a
type: question
title: Question A?
theme_label: Scope
---
body'
mk "$WIKI/wiki/syntheses/syn-a.md" '---
id: syn-a
type: synthesis
title: Synthesis A
sources: ["wiki://x/src-a"]
---
body'

# Append-only activity log (legacy-flat path) — the When (v1) timeline source.
# Two months of dated `## [YYYY-MM-DD] <op> | …` operation headings.
mk "$WIKI/wiki/log.md" '# Log

Append-only record of every wiki operation. Never rewritten.

## [2026-05-20] setup | wiki initialized
## [2026-06-01] ingest | project=X sources=57 claims=512
## [2026-06-01] compose | project=X draft=v1
## [2026-06-02] verify | project=X round=1
## [2026-06-02] finalize | project=X'

PAGE="$WIKI/wiki/perspectives.md"

# --- 1. render creates the page, envelope changed:true -----------------------
OUT="$(python3 "$PERSP_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT" | grep -q '"changed": true' \
  && green "PASS: render reports changed:true on first render" \
  || { red "FAIL: render did not report changed:true"; errors=$((errors+1)); }
[ -f "$PAGE" ] \
  && green "PASS: render created wiki/perspectives.md" \
  || { red "FAIL: wiki/perspectives.md not created"; errors=$((errors+1)); }

# --- 2. H1 + ownership marker + intro ----------------------------------------
grep -q '^# Perspectives$' "$PAGE" \
  && green "PASS: page carries the # Perspectives H1" \
  || { red "FAIL: missing # Perspectives H1"; errors=$((errors+1)); }
grep -q 'MACHINE-OWNED:PERSPECTIVES-INDEX' "$PAGE" \
  && green "PASS: page carries the PERSPECTIVES-INDEX ownership marker" \
  || { red "FAIL: missing PERSPECTIVES-INDEX marker"; errors=$((errors+1)); }

# --- 2b. secondary-view labels (R10) + overview-stub signpost (R11) -----------
grep -q 'Other views:' "$PAGE" \
  && green "PASS: page carries the secondary-view labels line (R10)" \
  || { red "FAIL: missing secondary-view labels line"; errors=$((errors+1)); }
grep -q '\[Recent syntheses\](overview.md)' "$PAGE" \
  && green "PASS: page signposts the overview stub — Recent syntheses (R11)" \
  || { red "FAIL: missing overview.md (Recent syntheses) signpost"; errors=$((errors+1)); }

# --- 3. every facet renders its heading + PERSPECTIVES-FACET span -------------
# Five facets now (the dead `How` facet was dropped).
facet_ok=1
for pair in "Who who" "What what" "Why why" "When when" "Where where"; do
  heading="${pair%% *}"; slug="${pair##* }"
  grep -q "^## ${heading}\$" "$PAGE" || { facet_ok=0; red "  missing ## ${heading}"; }
  grep -q "MACHINE-OWNED:PERSPECTIVES-FACET:${slug}:START" "$PAGE" || { facet_ok=0; red "  missing FACET span ${slug}"; }
done
[ "$facet_ok" -eq 1 ] \
  && green "PASS: all five 5W1H facets render heading + PERSPECTIVES-FACET span" \
  || { red "FAIL: a facet heading or span is missing"; errors=$((errors+1)); }

# --- 3b. the dead How facet no longer renders --------------------------------
grep -q '^## How$' "$PAGE" \
  && { red "FAIL: the dropped How facet still renders"; errors=$((errors+1)); } \
  || green "PASS: the dead How facet no longer renders (R9)"
grep -q 'MACHINE-OWNED:PERSPECTIVES-FACET:how:START' "$PAGE" \
  && { red "FAIL: a How PERSPECTIVES-FACET span still renders"; errors=$((errors+1)); } \
  || green "PASS: no How PERSPECTIVES-FACET span renders (R9)"

# --- 4. backed facets show count-links ---------------------------------------
grep -q '\[People (1)\](people/index.md)' "$PAGE" \
  && grep -q '\[Entities (1)\](entities/index.md)' "$PAGE" \
  && grep -q '\[Concepts (1)\](concepts/index.md)' "$PAGE" \
  && grep -q '\[Sources (1)\](sources/index.md)' "$PAGE" \
  && grep -q '\[Questions (1)\](questions/index.md)' "$PAGE" \
  && grep -q '\[Syntheses (1)\](syntheses/index.md)' "$PAGE" \
  && green "PASS: backed facets (Who/What/Why) show count-links to the sub-indexes" \
  || { red "FAIL: a backed-facet count-link is missing/incorrect"; errors=$((errors+1)); }

# --- 5. no facet renders the generic honest-empty line in this fixture --------
# How was dropped (it was the only generic-empty emitter); When carries the
# log-derived timeline and Where groups by market: frontmatter (the src-a fixture
# carries market: "dach"), and who/what/why are all type-backed — so the generic
# "_(no pages in this facet yet)_" line renders zero times here.
EMPTY_COUNT="$(grep -c '_(no pages in this facet yet)_' "$PAGE" || true)"
[ "$EMPTY_COUNT" -eq 0 ] \
  && green "PASS: no generic honest-empty line renders (How dropped; When/Where backed)" \
  || { red "FAIL: expected 0 generic honest-empty lines, got $EMPTY_COUNT"; errors=$((errors+1)); }

# --- 5c. Where (v1) groups source pages by their market: frontmatter ----------
# Where is now the last facet (How dropped), so the block runs to EOF.
WHERE_BLOCK="$(sed -n '/^## Where$/,$p' "$PAGE")"
echo "$WHERE_BLOCK" | grep -q 'Sources grouped by the market' \
  && green "PASS: Where facet renders the market-grouping intro" \
  || { red "FAIL: Where grouping intro missing"; errors=$((errors+1)); }
echo "$WHERE_BLOCK" | grep -qF -- '- **dach** — [1 source](sources/index.md)' \
  && green "PASS: Where groups the src-a source under its market (dach, singular), linked to the sources sub-index" \
  || { red "FAIL: Where 'dach' grouping row missing/incorrect"; errors=$((errors+1)); }
echo "$WHERE_BLOCK" | grep -q '_(no pages in this facet yet)_' \
  && { red "FAIL: Where facet wrongly rendered the honest-empty page line"; errors=$((errors+1)); } \
  || green "PASS: Where facet does not render the honest-empty page line (it has a market grouping)"

# --- 5b. When (v1) renders a deterministic log-derived timeline ---------------
# The When facet derives a month-grouped timeline (newest first) from wiki/log.md.
WHEN_BLOCK="$(sed -n '/^## When$/,/^## Where$/p' "$PAGE")"
echo "$WHEN_BLOCK" | grep -q 'Activity timeline from the base' \
  && green "PASS: When facet renders the timeline intro" \
  || { red "FAIL: When timeline intro missing"; errors=$((errors+1)); }
echo "$WHEN_BLOCK" | grep -qF -- '- **2026-06** — [4 operations](log.md) (compose · finalize · ingest · verify)' \
  && green "PASS: When timeline groups 2026-06 by month with sorted op counts, linked to the activity log" \
  || { red "FAIL: 2026-06 timeline row missing/incorrect"; errors=$((errors+1)); }
echo "$WHEN_BLOCK" | grep -qF -- '- **2026-05** — [1 operation](log.md) (setup)' \
  && green "PASS: When timeline groups 2026-05 (singular 'operation'), linked to the activity log" \
  || { red "FAIL: 2026-05 timeline row missing/incorrect"; errors=$((errors+1)); }
# Newest-first ordering: 2026-06 row must precede the 2026-05 row.
echo "$WHEN_BLOCK" | grep -nE '2026-0[56]' | head -1 | grep -q '2026-06' \
  && green "PASS: When timeline is newest-month-first" \
  || { red "FAIL: When timeline ordering is not newest-first"; errors=$((errors+1)); }
# The When facet does NOT render the honest-empty page line (it has a timeline).
echo "$WHEN_BLOCK" | grep -q '_(no pages in this facet yet)_' \
  && { red "FAIL: When facet wrongly rendered the honest-empty page line"; errors=$((errors+1)); } \
  || green "PASS: When facet does not render the honest-empty page line"

# --- 6. byte-idempotent re-render --------------------------------------------
BEFORE="$(cat "$PAGE")"
OUT2="$(python3 "$PERSP_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT2" | grep -q '"changed": false' \
  && green "PASS: re-render on unchanged wiki reports changed:false" \
  || { red "FAIL: re-render was not idempotent (changed != false)"; errors=$((errors+1)); }
[ "$BEFORE" = "$(cat "$PAGE")" ] \
  && green "PASS: re-render left the page byte-identical" \
  || { red "FAIL: re-render mutated the page"; errors=$((errors+1)); }

# --- 7. carry-forward a narrator-edited facet lead-in ------------------------
python3 - "$PAGE" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace(
    "_The named subjects this base tracks — the people and organizations behind the evidence._",
    "Narrated Who lead-in, authored by hand.",
)
open(p, "w").write(s)
PY
python3 "$PERSP_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
grep -q 'Narrated Who lead-in, authored by hand.' "$PAGE" \
  && green "PASS: a narrated PERSPECTIVES-FACET lead-in survives a re-render" \
  || { red "FAIL: narrated facet lead-in was clobbered"; errors=$((errors+1)); }

# --- 8. human-page skip (no marker) ------------------------------------------
printf '# Hand-authored perspectives\n\nNothing machine-owned here.\n' > "$PAGE"
OUT3="$(python3 "$PERSP_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT3" | grep -q '"skipped_human_page": true' \
  && green "PASS: a hand-authored page (no marker) is skipped_human_page" \
  || { red "FAIL: human page not skipped"; errors=$((errors+1)); }
grep -q 'Hand-authored perspectives' "$PAGE" \
  && green "PASS: the hand-authored page was preserved, not clobbered" \
  || { red "FAIL: human page was clobbered"; errors=$((errors+1)); }

# --- 9. stage writes the proposed file, never touches the live page ----------
rm -f "$PAGE"
python3 "$PERSP_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null  # re-seed a machine page
LIVE_BEFORE="$(cat "$PAGE")"
OUT4="$(python3 "$PERSP_SCRIPT" stage --wiki-root "$WIKI")"
echo "$OUT4" | grep -q '"subcommand": "stage"' \
  && [ -f "$WIKI/.cogni-wiki/perspectives-proposed.md" ] \
  && green "PASS: stage wrote .cogni-wiki/perspectives-proposed.md" \
  || { red "FAIL: stage did not write the proposed file"; errors=$((errors+1)); }
[ "$LIVE_BEFORE" = "$(cat "$PAGE")" ] \
  && green "PASS: stage left the live page untouched" \
  || { red "FAIL: stage mutated the live page"; errors=$((errors+1)); }

# --- 10. When (v1) honest no-timeline fallback (absent log) -------------------
# A wiki with no log.md must render the honest fallback, never a fabricated
# timeline. Use a fresh fixture so the main fixture's log.md is untouched.
NOLOG="$(mktemp -d)"
mkdir -p "$NOLOG/.cogni-wiki" "$NOLOG/wiki/concepts"
mk "$NOLOG/wiki/concepts/c1.md" '---
id: c1
type: concept
title: C1
theme_label: Scope
---
body'
python3 "$PERSP_SCRIPT" render --wiki-root "$NOLOG" --wiki-scripts-dir "$WSD" >/dev/null
NOLOG_WHEN="$(sed -n '/^## When$/,/^## Where$/p' "$NOLOG/wiki/perspectives.md")"
# R9: thin When renders an honest signpost (names why it is empty + how it fills),
# not a bare "no pages" line.
echo "$NOLOG_WHEN" | grep -q 'When: no activity timeline yet' \
  && green "PASS: When facet renders the honest no-timeline signpost when log.md is absent (R9)" \
  || { red "FAIL: missing no-timeline signpost for an absent log.md"; errors=$((errors+1)); }
echo "$NOLOG_WHEN" | grep -q 'Activity timeline from the base' \
  && { red "FAIL: When fabricated a timeline intro with no log.md"; errors=$((errors+1)); } \
  || green "PASS: When does not fabricate a timeline when log.md is absent"
# R9: thin Where (no market-tagged sources in this fixture) renders its own honest
# signpost, distinct from the generic "_(no pages in this facet yet)_" line.
NOLOG_WHERE="$(sed -n '/^## Where$/,$p' "$NOLOG/wiki/perspectives.md")"
echo "$NOLOG_WHERE" | grep -q 'Where: no market-tagged sources yet' \
  && green "PASS: Where facet renders the honest thin-facet signpost when no source carries a market (R9)" \
  || { red "FAIL: missing Where thin-facet signpost"; errors=$((errors+1)); }
echo "$NOLOG_WHERE" | grep -q '_(no pages in this facet yet)_' \
  && { red "FAIL: Where reused the generic honest-empty line instead of its signpost"; errors=$((errors+1)); } \
  || green "PASS: Where uses its own signpost, not the generic honest-empty line (R9)"
rm -rf "$NOLOG" 2>/dev/null || true

if [ "$errors" -eq 0 ]; then
  green "All perspectives_index.py tests passed."
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
