#!/usr/bin/env bash
# Guard: the copywriter skill's arc mode reads the text-to-narrative skill's bundled arc files at runtime, and
# every upstream path it cites resolves.
#
# WHAT THIS REPLACED
#   An earlier version of this suite kept a copywriter-side MIRROR of the narrative
#   arc headings and technique rules in sync with the upstream definitions (cases A1-A5, with
#   a shrink-only ratchet naming five arcs the mirror never carried). The mirror
#   is gone: copywriter arc mode now reads each arc's contract
#   (skills/text-to-narrative/references/arc-{arc}.md), the arc registry and
#   the narrative techniques overview directly, so there is nothing to keep in sync and the
#   five-arc detection gap closed by construction. What can still break is the READ: a cited
#   upstream path that no longer resolves fails silently at runtime — the copywriter polishes
#   the document as ordinary prose and the arc skeleton is unprotected. This suite pins that.
#
# CASES
#   X0  the copywriter surfaces that cite upstream paths are readable
#   X1  every upstream `skills/text-to-narrative/...` path cited by copywriter's SKILL.md, 00-index.md
#       and arc-preservation.md resolves on disk (templated `{arc_id}` segments are expanded
#       over every arc directory found at run time). Fails when the extraction is EMPTY, so a
#       rewording that hides every path cannot turn the suite green by vacuity.
#   X2  every arc contract upstream has a `### {arc}` block in the narrative registry, so
#       copywriter detection — which reads the registry — can activate arc mode for it.
#   X3  the copywriter no longer carries a mirror: no `arc-technique-map.md`, no canonical
#       heading table inside arc-preservation.md, no do-not-read-at-runtime rule.
#   M1  self-hosted negative case: copies SKILL.md into this run's mktemp -d, rewrites one
#       cited upstream path to a file that does not exist, re-invokes this suite against the
#       mutant behind a recursion guard, and requires `FAIL: X1` by name.
#
# CASE LABEL SHAPE: "PASS: <case>" / "FAIL: <case>", single-token ids, summary `RESULT:`.
# Contract: runs as `bash <path>` with no arguments, from any cwd, touches no network,
# needs bash + coreutils, writes only under its own mktemp -d, exits non-zero on failure.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"

ARC_DIR="$WS_ROOT/skills/text-to-narrative/references"
REGISTRY="$ARC_DIR/arc-registry.md"
CW_SKILL="${ARC_SYNC_CW_SKILL:-$WS_ROOT/skills/copywriter/SKILL.md}"
CW_INDEX="$WS_ROOT/skills/copywriter/references/00-index.md"
CW_PRESERVATION="$WS_ROOT/skills/copywriter/references/arc-preservation.md"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ALL_CASES="X0 X1 X2 X3 M1"

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

finish() {
  echo ""
  if [ "$failures" -gt 0 ]; then
    echo "RESULT: $failures arc-reference-sync case(s) failed."
    exit 1
  fi
  echo "RESULT: all arc-reference-sync cases passed."
  exit 0
}

# ---------------------------------------------------------------------------- X0
missing=""
for f in "$CW_SKILL" "$CW_INDEX" "$CW_PRESERVATION" "$REGISTRY"; do [ -f "$f" ] || missing="$missing $f"; done
[ -d "$ARC_DIR" ] || missing="$missing $ARC_DIR"
if [ -n "$missing" ]; then
  fail "X0 inputs readable — missing:$missing"
  for c in X1 X2 X3; do fail "$c not evaluated — inputs missing"; done
  finish
fi
pass "X0 inputs readable"

arcs="$(ls "$ARC_DIR"/arc-*.md | xargs -n1 basename | sed 's/^arc-//; s/\.md$//' | grep -vx registry | sort)"

# ---------------------------------------------------------------------------- X1
# Extract every `skills/text-to-narrative/...` path the three copywriter surfaces cite. Both the
# `${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/...` form and the bare `skills/text-to-narrative/...` form
# count; a `{arc_id}` or `{arc}` segment expands over every `arc-*.md` contract found upstream.
cited="$(cat "$CW_SKILL" "$CW_INDEX" "$CW_PRESERVATION" \
  | grep -oE '(\$\{CLAUDE_PLUGIN_ROOT\}/)?skills/text-to-narrative/references/[A-Za-z0-9_./{}-]+\.md' \
  | sed 's#^\${CLAUDE_PLUGIN_ROOT}/##' | sort -u)"
if [ -z "$cited" ]; then
  fail "X1 every cited upstream narrative path resolves (extracted zero paths — the extractor stopped matching)"
else
  x1_bad=""
  x1_count=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in
      *'{arc_id}'*|*'{arc}'*)
        for arc in $arcs; do
          concrete="$(printf '%s' "$rel" | sed "s/{arc_id}/$arc/; s/{arc}/$arc/")"
          x1_count=$((x1_count + 1))
          [ -f "$WS_ROOT/$concrete" ] || x1_bad="$x1_bad $concrete"
        done ;;
      *)
        x1_count=$((x1_count + 1))
        [ -f "$WS_ROOT/$rel" ] || x1_bad="$x1_bad $rel" ;;
    esac
  done <<EOF
$cited
EOF
  if [ -n "$x1_bad" ]; then
    fail "X1 every cited upstream narrative path resolves — dangling:$x1_bad"
  else
    pass "X1 every cited upstream narrative path resolves ($x1_count path(s) checked)"
  fi
fi

# ---------------------------------------------------------------------------- X2
x2_bad=""
for arc in $arcs; do
  grep -qx "### $arc" "$REGISTRY" || x2_bad="$x2_bad $arc"
done
if [ -z "$arcs" ]; then
  fail "X2 every arc contract has a registry block (found no arc contract)"
elif [ -n "$x2_bad" ]; then
  fail "X2 every arc contract has a registry block — missing:$x2_bad"
else
  pass "X2 every arc contract has a registry block, so copywriter detection covers it"
fi

# ---------------------------------------------------------------------------- X3
x3_bad=""
[ -f "$WS_ROOT/skills/copywriter/references/arc-technique-map.md" ] && x3_bad="$x3_bad technique-map-present"
grep -qE '^\| *Arc *\| *# *\| *EN' "$CW_PRESERVATION" && x3_bad="$x3_bad heading-mirror-table"
grep -qiE 'do (\*\*)?not(\*\*)? read' "$CW_SKILL" "$CW_PRESERVATION" && x3_bad="$x3_bad do-not-read-rule"
if [ -z "$x3_bad" ]; then
  pass "X3 the copywriter carries no arc mirror and no do-not-read-at-runtime rule"
else
  fail "X3 the copywriter still carries a mirror:$x3_bad"
fi

# ---------------------------------------------------------------------------- M1
if [ "${ARC_SYNC_MUTANT:-}" = "1" ]; then
  finish
fi

# The victim is drawn from SKILL.md alone, because SKILL.md is the only surface the copy
# rewrites: a path cited only by 00-index.md or arc-preservation.md would still resolve in
# the child run and the mutant would be green for the wrong reason.
victim="$(grep -oE '(\$\{CLAUDE_PLUGIN_ROOT\}/)?skills/text-to-narrative/references/[A-Za-z0-9_./{}-]+\.md' "$CW_SKILL" \
  | sed 's#^\${CLAUDE_PLUGIN_ROOT}/##' | grep -v '{' | sort -u | head -n 1)"
if [ -z "$victim" ]; then
  fail "M1 no concrete cited path available to mutate in SKILL.md"
  finish
fi
sed "s#$victim#skills/text-to-narrative/references/does-not-exist.md#g" "$CW_SKILL" > "$TMPROOT/SKILL.md"
if ! grep -q 'does-not-exist.md' "$TMPROOT/SKILL.md"; then
  fail "M1 could not rewrite '$victim' in the copy of SKILL.md"
  finish
fi
mutant_out="$(ARC_SYNC_MUTANT=1 ARC_SYNC_CW_SKILL="$TMPROOT/SKILL.md" bash "$HERE/$(basename "$0")" 2>&1)"
mutant_rc=$?
# Pin ALL_CASES against the ids the child actually emitted, in both directions, so a case
# deleted from the file (or added without registration) turns this suite red.
printf '%s\n' "$mutant_out" | grep -E '^(PASS|FAIL): ' | awk '{print $2}' | sort -u > "$TMPROOT/emitted.txt"
for c in $ALL_CASES; do [ "$c" = "M1" ] || echo "$c"; done | sort -u > "$TMPROOT/expected.txt"
unregistered="$(comm -13 "$TMPROOT/expected.txt" "$TMPROOT/emitted.txt" | tr '\n' ' ')"
unemitted="$(comm -23 "$TMPROOT/expected.txt" "$TMPROOT/emitted.txt" | tr '\n' ' ')"
if [ -n "${unregistered// /}" ]; then
  fail "M1 case(s) emitted but missing from ALL_CASES: $unregistered"
elif [ -n "${unemitted// /}" ]; then
  fail "M1 case id(s) in ALL_CASES never emitted: $unemitted"
elif [ "$mutant_rc" -ne 0 ] && printf '%s\n' "$mutant_out" | grep -q '^FAIL: X1 '; then
  pass "M1 rewriting a cited upstream path to a missing file turns X1 red (child exit $mutant_rc); registry matches"
else
  fail "M1 mutant exited $mutant_rc but X1 did not go red — got: $(printf '%s' "$mutant_out" | grep '^FAIL:' | tr '\n' ';')"
fi

finish
