#!/usr/bin/env bash
# test_root_index.sh — deterministic-renderer test for root_index.py.
#
# root_index.py is the root-portal sibling of sub_index.py: it renders the root
# wiki/index.md as a curated MAP (an overview-narrative intro + one section per
# real theme, each linking the per-type sub-indexes WITH counts) instead of a
# flat per-page bullet dump. The vendored wiki_index_update.py is never touched
# (Option A), so test_vendored_engine_parity.sh stays green.
#
# Asserts:
#   1. render rewrites a legacy bulleted root into a curated MAP: ROOT-INDEX
#      ownership marker + intro, and the envelope reports changed:true.
#   2. Per-theme count-link line shows each per-type sub-index WITH its count
#      (Sources (2), Concepts (1), …) and links to wiki/<type>/index.md.
#   3. NO per-page `- [[slug]]` source bullets remain on the root (they live in
#      the sub-indexes now).
#   4. A carried PORTAL-LEADIN machine span survives a re-render byte-for-byte
#      (date and all — never regenerated).
#   5. The non-theme container headings (## Categories, ## Syntheses) are dropped
#      (no page carries them as a theme_label); a synthesis appears as
#      Syntheses (n) inside its backing-source theme instead.
#   6. The OVERVIEW-NARRATIVE block folded into index.md (via overview_update.py
#      --target-file index.md) is carried into the curated intro.
#   7. BYTE-IDEMPOTENT: re-rendering an unchanged wiki reports changed:false.
#   8. reflow/collapse-STABLE: wiki_index_update.py --reflow-only + --collapse-only
#      on the curated MAP is a byte-for-byte no-op (the Step 10.5 lint --fix=all
#      gate ordering), and a following re-render stays changed:false.
#   9. TRANSIENT BULLETS: a freshly re-filed `- [[slug]]` bullet (next ingest) is
#      dropped on the next render (the curated MAP is the resting state).
#  10. counts subcommand on sub_index.py returns {theme: n} per type.
#  11. overview_update.py narrative-splice --target-file default is overview.md
#      (back-compat); index.md is opt-in.
#  12. HUMAN-PAGE: a hand-authored index.md (no ## heading, no MACHINE-OWNED span)
#      is skipped, not clobbered.
#  13. python3.9 floor: root_index.py carries `from __future__ import annotations`
#      and parses cleanly under ast.parse.
#
# bash 3.2 + stdlib python3 only. Posix only (render uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT_SCRIPT="$PLUGIN_ROOT/scripts/root_index.py"
SUB_SCRIPT="$PLUGIN_ROOT/scripts/sub_index.py"
OVR_SCRIPT="$PLUGIN_ROOT/scripts/overview_update.py"
WSD="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"
errors=0

if [ ! -f "$WSD/_wikilib.py" ]; then
  red "SKIP: cogni-wiki _wikilib not found at $WSD (render needs _wiki_lock)"
  exit 0
fi

WIKI="$(mktemp -d)"
trap 'rm -rf "$WIKI" "$PROSE" "$BEFORE" 2>/dev/null || true' EXIT
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/concepts" "$WIKI/wiki/questions" \
         "$WIKI/wiki/syntheses" "$WIKI/.cogni-wiki"

# --- pages: two sources + a concept + a question + a synthesis, theme "Scope" ---
cat > "$WIKI/wiki/sources/src-a.md" <<'EOF'
---
id: src-a
title: Source A
type: source
theme_label: Scope
sources: ["https://example.com/a"]
pre_extracted_claims:
  - id: clm-1
    text: A claim about scope.
---
Body A.
EOF
cat > "$WIKI/wiki/sources/src-b.md" <<'EOF'
---
id: src-b
title: Source B
type: source
theme_label: Scope
sources: ["https://example.com/b"]
pre_extracted_claims:
  - id: clm-1
    text: Another scope claim.
---
Body B.
EOF
cat > "$WIKI/wiki/concepts/high-risk.md" <<'EOF'
---
id: high-risk
title: High-risk system
type: concept
sources:
  - wiki://src-a
distilled_claims:
  - claim_id: dcl-1
    text: High-risk definition.
---
<!-- MACHINE-OWNED:SUMMARY:START -->
A high-risk AI system.
<!-- MACHINE-OWNED:SUMMARY:END -->
EOF
cat > "$WIKI/wiki/questions/q-scope.md" <<'EOF'
---
id: q-scope
title: What is in scope?
type: question
theme_label: Scope
---
## Findings
- [[src-a]]
EOF
cat > "$WIKI/wiki/syntheses/scope-synth.md" <<'EOF'
---
id: scope-synth
title: Scope synthesis
type: synthesis
sources:
  - wiki://src-a
  - wiki://src-b
---
A synthesis of scope.
EOF

# --- legacy bulleted root (what wiki_index_update.py produces) with a
#     ## Categories container, a themed section + PORTAL-LEADIN, and a fixed
#     ## Syntheses heading ---
LEADIN_LINE='<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-06-01 bullets:3 -->'
cat > "$WIKI/wiki/index.md" <<EOF
# Test Knowledge Base

_Curated front door. The overview narrative lives in wiki/overview.md._

## Categories

<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-01-01 bullets:0 -->
_Theme map pending._
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

## Scope

$LEADIN_LINE
Framing for the scope theme.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

- [[src-a]] — A claim about scope.
- [[src-b]] — Another scope claim.
- [[q-scope]] — What is in scope?

## Syntheses

- [[scope-synth]] — Scope synthesis
EOF

IDX="$WIKI/wiki/index.md"
PROSE=""; BEFORE=""

# === 1. render → curated MAP ===
OUT="$(python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT" | grep -q '"changed": true' \
  && green "PASS: 1 render reports changed:true" \
  || { red "FAIL: 1 render not changed:true ($OUT)"; errors=$((errors+1)); }
assert_grep "MACHINE-OWNED:ROOT-INDEX" "$IDX" "1 ROOT-INDEX ownership marker present"
assert_grep "Curated map of this knowledge base" "$IDX" "1 curated intro line present"

# === 2. per-theme count-links with counts ===
assert_grep "Sources (2)](sources/index.md)" "$IDX" "2 Sources (2) sub-index link"
assert_grep "Concepts (1)](concepts/index.md)" "$IDX" "2 Concepts (1) sub-index link"
assert_grep "Questions (1)](questions/index.md)" "$IDX" "2 Questions (1) sub-index link"
assert_grep "Syntheses (1)](syntheses/index.md)" "$IDX" "2 Syntheses (1) sub-index link (folded into theme)"

# === 3. no per-page source bullets remain on the root ===
assert_not_grep '^- \[\[src-a\]\]' "$IDX" "3 per-page src-a bullet dropped from root"
assert_not_grep '^- \[\[scope-synth\]\]' "$IDX" "3 per-page synthesis bullet dropped from root"

# === 4. carried PORTAL-LEADIN span (verbatim, date intact) ===
assert_grep "refreshed:2026-06-01 bullets:3" "$IDX" "4 PORTAL-LEADIN carried with original date"
assert_grep "Framing for the scope theme." "$IDX" "4 PORTAL-LEADIN inner prose carried"

# === 5. container headings dropped ===
assert_not_grep '^## Categories' "$IDX" "5 ## Categories container heading dropped"
assert_not_grep '^## Syntheses' "$IDX" "5 ## Syntheses fixed heading dropped (folded per-theme)"
assert_grep '^## Scope' "$IDX" "5 real theme heading kept"

# === 6. OVERVIEW-NARRATIVE fold carried into intro ===
PROSE="$(mktemp)"; printf 'This base maps scope for SMEs.' > "$PROSE"
python3 "$OVR_SCRIPT" narrative-splice --wiki-root "$WIKI" --prose-file "$PROSE" \
  --target-file index.md --wiki-scripts-dir "$WSD" >/dev/null
python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
assert_grep "MACHINE-OWNED:OVERVIEW-NARRATIVE" "$IDX" "6 OVERVIEW-NARRATIVE block in index.md"
assert_grep "This base maps scope for SMEs." "$IDX" "6 overview narrative prose in intro"

# === 7. idempotent re-render ===
OUT2="$(python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT2" | grep -q '"changed": false' \
  && green "PASS: 7 re-render is byte-identical no-op (changed:false)" \
  || { red "FAIL: 7 re-render not idempotent ($OUT2)"; errors=$((errors+1)); }

# === 8. reflow/collapse stability ===
BEFORE="$(mktemp)"; cp "$IDX" "$BEFORE"
python3 "$WSD/wiki_index_update.py" --wiki-root "$WIKI" --reflow-only >/dev/null 2>&1 || true
python3 "$WSD/wiki_index_update.py" --wiki-root "$WIKI" --collapse-only >/dev/null 2>&1 || true
if diff -q "$BEFORE" "$IDX" >/dev/null 2>&1; then
  green "PASS: 8 curated MAP byte-stable under reflow-only + collapse-only"
else
  red "FAIL: 8 curated MAP drifted under reflow/collapse"; diff "$BEFORE" "$IDX" || true; errors=$((errors+1))
fi
OUT3="$(python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")"
echo "$OUT3" | grep -q '"changed": false' \
  && green "PASS: 8 re-render after reflow/collapse stays changed:false" \
  || { red "FAIL: 8 re-render after fixers not idempotent ($OUT3)"; errors=$((errors+1)); }

# === 9. transient bullets: a freshly re-filed bullet is dropped next render ===
python3 - "$IDX" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
# simulate the next ingest re-filing a source bullet under ## Scope
t = t.replace("## Scope\n", "## Scope\n\n- [[src-c]] — a freshly ingested source\n", 1)
open(p, "w", encoding="utf-8").write(t)
PY
assert_grep '\[\[src-c\]\]' "$IDX" "9 transient bullet present before render"
python3 "$ROOT_SCRIPT" render --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" >/dev/null
assert_not_grep '\[\[src-c\]\]' "$IDX" "9 transient bullet dropped on next render"

# === 10. counts subcommand ===
CNT="$(python3 "$SUB_SCRIPT" counts --type sources --wiki-root "$WIKI")"
echo "$CNT" | grep -q '"Scope": 2' \
  && green "PASS: 10 counts subcommand returns {theme: n}" \
  || { red "FAIL: 10 counts wrong ($CNT)"; errors=$((errors+1)); }

# === 11. overview_update --target-file back-compat (default overview.md) ===
python3 "$OVR_SCRIPT" narrative-splice --wiki-root "$WIKI" --prose-file "$PROSE" \
  --wiki-scripts-dir "$WSD" >/dev/null
[ -f "$WIKI/wiki/overview.md" ] \
  && green "PASS: 11 narrative-splice default still writes wiki/overview.md" \
  || { red "FAIL: 11 default target did not write overview.md"; errors=$((errors+1)); }

# === 12. human-page skip ===
HWIKI="$(mktemp -d)"; mkdir -p "$HWIKI/wiki/sources" "$HWIKI/.cogni-wiki"
printf '# My hand-written portal\n\nJust prose, no headings, no markers.\n' > "$HWIKI/wiki/index.md"
HOUT="$(python3 "$ROOT_SCRIPT" render --wiki-root "$HWIKI" --wiki-scripts-dir "$WSD")"
echo "$HOUT" | grep -q '"skipped_human_page": true' \
  && green "PASS: 12 hand-authored portal skipped" \
  || { red "FAIL: 12 human page not skipped ($HOUT)"; errors=$((errors+1)); }
grep -q "hand-written portal" "$HWIKI/wiki/index.md" \
  && green "PASS: 12 hand-authored portal left untouched" \
  || { red "FAIL: 12 human page clobbered"; errors=$((errors+1)); }
rm -rf "$HWIKI"

# === 13. python3.9 floor ===
grep -q "from __future__ import annotations" "$ROOT_SCRIPT" \
  && green "PASS: 13 root_index.py carries __future__ annotations" \
  || { red "FAIL: 13 missing __future__ annotations"; errors=$((errors+1)); }
python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$ROOT_SCRIPT" \
  && green "PASS: 13 root_index.py parses under ast" \
  || { red "FAIL: 13 ast.parse failed"; errors=$((errors+1)); }

echo
if [ "$errors" -eq 0 ]; then
  green "test_root_index.sh: ALL PASS"
else
  red "test_root_index.sh: $errors failure(s)"; exit 1
fi
