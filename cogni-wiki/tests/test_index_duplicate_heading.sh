#!/usr/bin/env bash
# test_index_duplicate_heading.sh — lock the single-instance portal guarantee:
# wiki_index_update.py MUST collapse a duplicate `## <theme>` section into the
# first occurrence at write time, so a multi-project Knowledge Portal index.md
# never shows the same theme split across two competing sections.
#
# This is the #485 Phase-1 hardening on top of the #461 lead-in contract
# (test_index_leadin_preserve.sh). The collapse runs inside update_index() (and
# move_slug()) before the insert/relocate dispatch, so it is a free side-effect
# of any slug-mode insert/update or --move-slug call.
#
# Invariants asserted:
#   1. A pre-existing duplicate `## Syntheses` is collapsed to ONE heading on
#      the next insert; the FIRST section's curated lead-in survives verbatim.
#   2. Bullets from BOTH original sections survive, merged once and alphabetised
#      (the inserted bullet lands among them in slug order).
#   3. An unrelated section (## Sources) is left untouched.
#   4. Idempotent: a re-run produces no second heading and no bullet churn.
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

count_heading() { grep -c "^## $1\$" "$INDEX" || true; }
count_bullet()  { grep -cF "$1" "$INDEX" || true; }
has_line()      { grep -qF "$1" "$INDEX"; }

# ---------- seed a portal index that has DRIFTED into two ## Syntheses ----------
# The first section is curated (lead-in + a bullet); the second is the
# machine-shaped duplicate a prior Case-C insert would have appended.
mkdir -p "$WIKI/wiki"
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

$LEADIN_SYN

- [[alpha-synthesis]] — first synthesis

## Sources

- [[some-source]] — an unrelated source bullet that must stay put

## Syntheses

- [[omega-synthesis]] — last synthesis
EOF

green "seeded a drifted portal (two ## Syntheses sections + an unrelated ## Sources)"

# =====================================================================
# CASE 1 — an insert under Syntheses collapses the duplicate first.
# mid-synthesis sorts BETWEEN alpha and omega.
# =====================================================================
python3 "$UPDATE" --wiki-root "$WIKI" --slug "mid-synthesis" \
  --summary "middle synthesis" --category "Syntheses" >/dev/null

[ "$(count_heading Syntheses)" = "1" ] \
  || fail "Case 1: ## Syntheses not collapsed to single instance (count=$(count_heading Syntheses))"
green "Case 1: exactly one ## Syntheses heading after collapse"

has_line "$LEADIN_SYN" \
  || fail "Case 1: the first section's curated lead-in was lost during collapse"
green "Case 1: curated lead-in preserved byte-for-byte"

# all three slugs present, each exactly once
for s in alpha-synthesis mid-synthesis omega-synthesis; do
  has_line "[[$s]]" || fail "Case 1: bullet [[$s]] missing after collapse"
  [ "$(count_bullet "[[$s]]")" = "1" ] \
    || fail "Case 1: bullet [[$s]] duplicated (count=$(count_bullet "[[$s]]"))"
done
green "Case 1: bullets from both sections merged, each present exactly once"

# alphabetical order among the merged Syntheses bullets: alpha < mid < omega
ORDER=$(grep -oE '\[\[(alpha|mid|omega)-synthesis\]\]' "$INDEX" | tr '\n' ' ')
[ "$ORDER" = "[[alpha-synthesis]] [[mid-synthesis]] [[omega-synthesis]] " ] \
  || fail "Case 1: merged bullets not alphabetised (got: $ORDER)"
green "Case 1: merged bullets alphabetised (alpha < mid < omega)"

# the unrelated ## Sources section is untouched
[ "$(count_heading Sources)" = "1" ] \
  || fail "Case 1: unrelated ## Sources heading disturbed (count=$(count_heading Sources))"
has_line "[[some-source]]" \
  || fail "Case 1: unrelated [[some-source]] bullet was dropped"
green "Case 1: unrelated ## Sources section left untouched"

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
green "Case 1: lead-in still precedes the merged bullet block"

# =====================================================================
# CASE 2 — idempotency: a re-run adds no second heading and no bullet churn.
# =====================================================================
BEFORE="$WORKDIR/before.md"
cp "$INDEX" "$BEFORE"
python3 "$UPDATE" --wiki-root "$WIKI" --slug "mid-synthesis" \
  --summary "middle synthesis" --category "Syntheses" >/dev/null

[ "$(count_heading Syntheses)" = "1" ] \
  || fail "Case 2: re-run created a second ## Syntheses heading"
if ! diff -q "$BEFORE" "$INDEX" >/dev/null 2>&1; then
  fail "Case 2: idempotent re-run mutated index.md (Case-A update should be a no-op)"
fi
green "Case 2: idempotent re-run — single heading, index unchanged"

# =====================================================================
# CASE 3 — the SAME slug present in BOTH duplicate sections collapses to
# exactly one bullet (the dedup "skip a slug the survivor already carries"
# branch, asserted directly rather than transitively).
# =====================================================================
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

$LEADIN_SYN

- [[dup-synthesis]] — first copy

## Syntheses

- [[dup-synthesis]] — second copy
- [[tail-synthesis]] — only in the second section
EOF

# An insert of an unrelated slug triggers the collapse.
python3 "$UPDATE" --wiki-root "$WIKI" --slug "head-synthesis" \
  --summary "sorts first" --category "Syntheses" >/dev/null

[ "$(count_heading Syntheses)" = "1" ] \
  || fail "Case 3: ## Syntheses not collapsed (count=$(count_heading Syntheses))"
[ "$(count_bullet "[[dup-synthesis]]")" = "1" ] \
  || fail "Case 3: slug in both sections not deduped (count=$(count_bullet "[[dup-synthesis]]"))"
has_line "[[tail-synthesis]]" \
  || fail "Case 3: distinct bullet from the second section was dropped"
has_line "$LEADIN_SYN" \
  || fail "Case 3: the survivor's curated lead-in was lost"
green "Case 3: a slug duplicated across both sections survives exactly once"

# =====================================================================
# CASE 4 — move_slug() collapses a drifted portal before relocating, so the
# move operates on the merged (single-instance) target section.
# =====================================================================
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

$LEADIN_SYN

- [[alpha-synthesis]] — first synthesis

## Drafts

- [[beta-synthesis]] — to be relocated into Syntheses

## Syntheses

- [[omega-synthesis]] — last synthesis
EOF

python3 "$UPDATE" --wiki-root "$WIKI" --move-slug "beta-synthesis" \
  --to-category "Syntheses" >/dev/null

[ "$(count_heading Syntheses)" = "1" ] \
  || fail "Case 4: move_slug did not collapse the duplicate (count=$(count_heading Syntheses))"
ORDER=$(grep -oE '\[\[(alpha|beta|omega)-synthesis\]\]' "$INDEX" | tr '\n' ' ')
[ "$ORDER" = "[[alpha-synthesis]] [[beta-synthesis]] [[omega-synthesis]] " ] \
  || fail "Case 4: relocated bullet not alphabetised into the merged section (got: $ORDER)"
has_line "$LEADIN_SYN" \
  || fail "Case 4: the survivor's curated lead-in was lost during move+collapse"
green "Case 4: move_slug collapses first, then relocates into the merged section"

# =====================================================================
# CASE 5 — the --collapse-only repair mode (wiki-lint --fix=portal_heading_dedup)
# reconciles a base that is ALREADY duplicated on disk, with no insert/relocate.
# A dry-run reports the plan without writing; a wet run collapses to one heading
# (lead-in preserved, bullets merged + alphabetised); a re-run is a noop.
# =====================================================================
cat > "$INDEX" <<EOF
# Test Base — Knowledge Portal

> One entry point.

## Syntheses

$LEADIN_SYN

- [[alpha-synthesis]] — first synthesis

## Sources

- [[some-source]] — an unrelated source bullet that must stay put

## Syntheses

- [[omega-synthesis]] — last synthesis
EOF

# 5a — dry-run: action collapsed, applied false, and NO on-disk change.
BEFORE="$WORKDIR/collapse-before.md"
cp "$INDEX" "$BEFORE"
OUT=$(python3 "$UPDATE" --wiki-root "$WIKI" --collapse-only --dry-run)
echo "$OUT" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
assert d['success'], d.get('error')
data = d['data']
assert data['action'] == 'collapsed', f'5a: action != collapsed: {data}'
assert data['changed'] is True, f'5a: changed != True: {data}'
assert data['applied'] is False, f'5a: applied != False on dry-run: {data}'
assert data['dry_run'] is True, f'5a: dry_run != True: {data}'
" || fail "Case 5a: --collapse-only --dry-run envelope check"
if ! diff -q "$BEFORE" "$INDEX" >/dev/null 2>&1; then
  fail "Case 5a: --collapse-only --dry-run mutated index.md (must be plan-only)"
fi
[ "$(count_heading Syntheses)" = "2" ] \
  || fail "Case 5a: --dry-run collapsed the duplicate on disk (must not write)"
green "Case 5a: --collapse-only --dry-run reports collapsed, writes nothing"

# 5b — wet: collapses to one heading, lead-in preserved, bullets merged + sorted.
OUT=$(python3 "$UPDATE" --wiki-root "$WIKI" --collapse-only)
echo "$OUT" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())['data']
assert data['action'] == 'collapsed', f'5b: action != collapsed: {data}'
assert data['applied'] is True, f'5b: applied != True on wet run: {data}'
" || fail "Case 5b: --collapse-only wet envelope check"
[ "$(count_heading Syntheses)" = "1" ] \
  || fail "Case 5b: ## Syntheses not collapsed to single instance (count=$(count_heading Syntheses))"
has_line "$LEADIN_SYN" \
  || fail "Case 5b: the survivor's curated lead-in was lost during collapse"
for s in alpha-synthesis omega-synthesis; do
  [ "$(count_bullet "[[$s]]")" = "1" ] \
    || fail "Case 5b: bullet [[$s]] not present exactly once (count=$(count_bullet "[[$s]]"))"
done
ORDER=$(grep -oE '\[\[(alpha|omega)-synthesis\]\]' "$INDEX" | tr '\n' ' ')
[ "$ORDER" = "[[alpha-synthesis]] [[omega-synthesis]] " ] \
  || fail "Case 5b: merged bullets not alphabetised (got: $ORDER)"
[ "$(count_heading Sources)" = "1" ] \
  || fail "Case 5b: unrelated ## Sources heading disturbed"
green "Case 5b: --collapse-only wet run collapses, preserves lead-in, merges+sorts bullets"

# 5c — idempotent: a second wet run is a noop and leaves the file byte-identical.
BEFORE="$WORKDIR/collapse-after.md"
cp "$INDEX" "$BEFORE"
OUT=$(python3 "$UPDATE" --wiki-root "$WIKI" --collapse-only)
echo "$OUT" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())['data']
assert data['action'] == 'noop', f'5c: action != noop on clean index: {data}'
assert data['changed'] is False, f'5c: changed != False: {data}'
assert data['applied'] is False, f'5c: applied != False on noop: {data}'
" || fail "Case 5c: --collapse-only idempotency envelope check"
if ! diff -q "$BEFORE" "$INDEX" >/dev/null 2>&1; then
  fail "Case 5c: idempotent --collapse-only re-run mutated index.md"
fi
green "Case 5c: --collapse-only is idempotent — second run is a noop, file unchanged"

green "ALL TESTS PASS"
