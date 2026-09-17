#!/usr/bin/env bash
# Publishing-ownership regression guard. No live reference or manifest surface
# may reassert that cogni-workspace owns narrative composition, copywriting or
# the theme lifecycle, and none may repeat the retired claim that nothing in the
# ecosystem renders locally.
#
# Why this exists. The publishing transition moved three capabilities to
# cogni-publishing and left same-name compatibility routes behind. The ownership
# claims scattered across the root README, the ecosystem and selection docs, the
# ER diagram, the generated plugin guide and both manifests were corrected by
# hand, across several changes, and nothing bound them to the tree afterwards.
# One of those surfaces — docs/plugin-guide/cogni-workspace.md — is GENERATOR
# output, and this repository has already had a retired claim walk back into that
# exact page once, which is why its sibling suite
# tests/test-layering-claim-reconciled.sh exists at all.
#
# THIS IS A REGRESSION GUARD, NOT A CLEANUP DETECTOR. Every needle below measures
# ZERO hits across SURFACES on the tree that introduced this file. That is the
# intended state, not a defect in the needle list: the claims were corrected in
# the same change that adds this suite, and the suite's job is to keep them
# corrected. Its teeth therefore come from pown-02, which PLANTS each needle in a
# fixture and requires it to be caught — never from finding one in the live tree.
# Do not "simplify" a needle away because it matches nothing today; that is the
# post-condition, and dropping it is how the class returns unobserved.
#
# Re-measured over SURFACES as widened by the workflow-guide sweep — all twelve
# reference and manifest surfaces plus the seven docs/workflows/ walkthroughs:
#   cogni-workspace:text-to-narrative      0 hits
#   cogni-workspace:copywriter             0 hits
#   cogni-workspace narrative              0 hits
#   cogni-workspace (text-to-narrative)    0 hits
#   cogni-workspace (copywriter)           0 hits
#   cogni-workspace's text-to-narrative    0 hits
#   cogni-workspace's render chain         0 hits
#   cogni-workspace:manage-themes          0 hits
#   Nothing in the ecosystem renders       0 hits
#   nothing renders locally                0 hits
#
# SURFACES is an EXPLICIT LIST, never a tree walk, and that is the single most
# load-bearing decision in this file. The transition record
# (docs/architecture/publishing-transition.md), the migration guide
# (docs/publishing-migration.md) and the maintainer CLAUDE.md files must keep
# naming the old routes — recording a compatibility route is their whole job — so
# a repo-wide scan would flag the very documents that describe the migration, and
# the "obvious" fix of adding them to an exclusion list is worse: an exclusion
# matched by substring is always wider than the files it names, and it retires the
# guard instead of the claim. Scoping positively, to the surfaces that must be
# CURRENT, makes that structural rather than a promise. pown-04 is the case that
# holds the line: it plants every needle in exactly those three document classes
# and requires them NOT to be flagged.
#
# Coverage boundary, stated rather than implied. The seven cross-plugin
# walkthroughs under docs/workflows/ ARE surfaces: they carry the same class of
# claim, and a reader following one is routed to a compatibility delegate rather
# than to the owner. They entered this list in the change that swept them clean,
# which is why every needle still measures zero above.
#
# What that widening does NOT cover, stated rather than left to be rediscovered:
# the theme class is caught only in its DISPATCH-TOKEN form. A fixed-string
# needle broad enough to catch a prose theme mis-attribution — "Theming inherits
# from cogni-workspace", "cogni-workspace installed | Provides the active theme"
# — also matches legitimate workspace-themes-directory wording that several
# surfaces carry correctly, so it would flag documents that are behaving. Prose
# theme attribution therefore stays unguarded here; only a reader catches it.
#
# Contract under test:
#   - every SURFACE is clean of every NEEDLE on the real repo
#   - every NEEDLE is actually caught when planted (no dead config)
#   - a SURFACE that is missing or unreadable FAILS rather than reporting clean
#   - a needle in the transition record, the migration guide or a CLAUDE.md is
#     NOT flagged, because those are not SURFACES
#   - a scan that examined zero surfaces FAILS rather than reporting clean
#
# Result lines are plain: `printf '%s\n'` with no escape sequence, so the
# mutation harness's whole-token `FAIL: <id>` match is never defeated by a colour
# code. Case ids are allocated once and never renumbered — the harness addresses a
# case by its id token.
#
# Mutation recipe (verified — mutated red, restored green):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file docs/plugin-guide/cogni-workspace.md \
#     --expr 's{cogni-publishing:text-to-narrative}{cogni-workspace:text-to-narrative}' \
#     --test 'bash cogni-workspace/tests/test-publishing-ownership-reconciled.sh' \
#     --case pown-01-surfaces-clean
#
# Second recipe, over one of the workflow surfaces this suite added (verified —
# mutated red, restored green). It plants the theme dispatch needle in a newly
# added surface, so a green grading proves both halves of that widening:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file docs/workflows/portfolio-to-website.md \
#     --expr 's{cogni-publishing:manage-themes}{cogni-workspace:manage-themes}' \
#     --test 'bash cogni-workspace/tests/test-publishing-ownership-reconciled.sh' \
#     --case pown-01-surfaces-clean
#
# Each recipe names the UNVERSIONED managed-service marketplace install, never a
# version-pinned cache path: a pinned path resolves on no machine after the next
# upstream patch bump, and CI asserts the spelling rather than local
# resolvability. cogni-workspace/scripts/mutation-check.sh implements the same
# five-flag contract and grades this recipe identically, but the recorded
# spelling is the marketplace one.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A, no mapfile,
# no ${var^^}. stdlib-only: bash + coreutils, no pip deps, no network.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

# Reference and manifest surfaces that must describe CURRENT ownership. One
# repo-relative path per line. Never a glob, never a directory prefix.
#
# Three of the entries below are the workspace SETUP and HEALTH surfaces —
# manage-workspace/SKILL.md, plugin-diagnostics.md and known-issues.md. They are
# here because they are what a user reads when something is already wrong: a
# diagnostic that names the wrong owner sends them to a compatibility delegate
# while they are debugging, which is the worst moment to be misrouted. All three
# carried a stale claim until the change that added this suite.
#
# The seven docs/workflows/ entries are the cross-plugin walkthroughs. They are
# here because a walkthrough is what a reader follows step by step: a hop
# attributed to the wrong plugin sends them to a compatibility delegate for a
# capability cogni-publishing owns. The set equals the live listing of that
# directory in both directions, so a guide added there without a line here is
# simply unguarded, and a line naming a file that no longer exists fails the
# whole scan rather than reporting clean.
SURFACES='README.md
docs/ecosystem-overview.md
docs/plugin-selection.md
docs/er-diagram.md
docs/command-reference.md
docs/plugin-guide/cogni-workspace.md
cogni-workspace/README.md
cogni-workspace/.claude-plugin/plugin.json
.claude-plugin/marketplace.json
cogni-workspace/skills/manage-workspace/SKILL.md
cogni-workspace/skills/workspace-status/references/plugin-diagnostics.md
cogni-workspace/skills/workspace-status/references/known-issues.md
docs/workflows/consulting-engagement.md
docs/workflows/content-pipeline.md
docs/workflows/install-to-infographic.md
docs/workflows/portfolio-to-pitch.md
docs/workflows/portfolio-to-website.md
docs/workflows/research-to-report.md
docs/workflows/trends-to-solutions.md'

# Claims that must not reappear on a SURFACE. One per line, matched
# case-insensitively as FIXED STRINGS, never as regexes.
#
# The three dispatch-token needles are the load-bearing group: a surface that
# tells a reader to call cogni-workspace for narrative, copy or theme work routes
# them to a compatibility delegate instead of the owner, which is the failure a
# reader actually experiences. The prose needles catch the same claim made in
# running text, and the last two catch the retired "nothing renders locally"
# assertion that cogni-publishing's render chain falsified.
NEEDLES='cogni-workspace:text-to-narrative
cogni-workspace:copywriter
cogni-workspace narrative
cogni-workspace (text-to-narrative)
cogni-workspace (copywriter)
cogni-workspace'"'"'s text-to-narrative
cogni-workspace'"'"'s render chain
cogni-workspace:manage-themes
Nothing in the ecosystem renders
nothing renders locally'

# Documents that legitimately name the old routes and are deliberately NOT
# surfaces. Used only to build the pown-04 fixture; the scanner never reads it.
NON_SURFACES='docs/architecture/publishing-transition.md
docs/publishing-migration.md
CLAUDE.md'

# ---------------------------------------------------------------------------
# The checker. Every case drives this one function, so pointing a case at a
# broken checker turns that case red.
# ---------------------------------------------------------------------------

# scan_surfaces <root> <label> [surface-list]
#   Prints an OFFENDER line per (surface, needle) hit. Returns 0 when clean,
#   1 on any offender, a missing/unreadable surface, or an empty scan.
scan_surfaces() {
  # ${3-...}, NOT ${3:-...}: pown-05 passes an intentionally EMPTY list, and the
  # colon form treats empty as unset and would silently fall back to SURFACES,
  # leaving the zero-surface floor untested while its case still printed green.
  local root="$1" label="$2" list="${3-$SURFACES}"
  local surface path lit offenders=0 scanned=0

  while IFS= read -r surface; do
    [ -n "$surface" ] || continue
    path="$root/$surface"

    # A missing surface must FAIL, never report clean. A renamed or deleted
    # surface is exactly the case where a guard silently stops guarding.
    if [ ! -f "$path" ] || [ ! -r "$path" ]; then
      printf '%s\n' "ERROR [$label] surface not found: $surface"
      return 1
    fi

    scanned=$((scanned + 1))

    while IFS= read -r lit; do
      [ -n "$lit" ] || continue
      # -I skips binaries; -F fixed string; -i case-insensitive; -q sets rc only.
      if grep -IiFq -- "$lit" "$path" 2>/dev/null; then
        printf '%s\n' "OFFENDER $surface: $lit"
        offenders=$((offenders + 1))
      fi
    done <<EOF
$NEEDLES
EOF
  done <<EOF
$list
EOF

  # A scan that examined no surface is evidence of a broken constant, not of a
  # clean tree.
  if [ "$scanned" -eq 0 ]; then
    printf '%s\n' "ERROR [$label] no surfaces scanned — the surface list is empty"
    return 1
  fi

  [ "$offenders" -eq 0 ]
}

# --- harness ---------------------------------------------------------------
LAST_OUT=""; LAST_RC=0
run_scan() { LAST_OUT="$(scan_surfaces "$1" "$2" "${3-$SURFACES}" 2>&1)"; LAST_RC=$?; }
assert_rc() { [ "$LAST_RC" -eq "$1" ] || { printf '%s\n' "  expected rc=$1 got rc=$LAST_RC"; printf '%s\n' "$LAST_OUT" | sed 's/^/  | /'; return 1; }; }
assert_out_has() { case "$LAST_OUT" in *"$1"*) return 0 ;; esac; printf '%s\n' "  expected output to contain: $1"; printf '%s\n' "$LAST_OUT" | sed 's/^/  | /'; return 1; }
assert_out_lacks() { case "$LAST_OUT" in *"$1"*) printf '%s\n' "  expected output NOT to contain: $1"; printf '%s\n' "$LAST_OUT" | sed 's/^/  | /'; return 1 ;; esac; return 0; }

# build_fixture <dir> — a tree carrying every SURFACE with innocuous content.
build_fixture() {
  local dir="$1" surface
  while IFS= read -r surface; do
    [ -n "$surface" ] || continue
    mkdir -p "$dir/$(dirname "$surface")"
    printf '%s\n' "cogni-publishing owns narrative composition, copywriting and the theme lifecycle." > "$dir/$surface"
  done <<EOF
$SURFACES
EOF
}

# slugify <string> — a token-safe discriminator for a case id.
#
# The colon is mapped to `-dispatch-` BEFORE the generic scrub, and that is not
# cosmetic. A plain non-alphanumeric scrub collapses `cogni-workspace:copywriter`
# and `cogni-workspace (copywriter)` to the SAME token, so two case ids would
# collide and `mutation-check.sh --case <id>` would resolve to whichever line ran
# first — the exact failure the unique-first-token rule exists to prevent. The
# colon form is the dispatch spelling, so the name is accurate as well as unique.
slugify() {
  printf '%s' "$1" \
    | tr 'A-Z' 'a-z' \
    | sed 's/:/-dispatch-/g' \
    | tr -c 'a-z0-9\n' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//'
}

# ---------------------------------------------------------------------------
# pown-01 — the real repo is clean.
# ---------------------------------------------------------------------------
run_scan "$REPO_ROOT" "repo"
if assert_rc 0; then
  pass "pown-01-surfaces-clean every ownership surface is free of retired publishing-ownership claims"
else
  fail "pown-01-surfaces-clean an ownership surface reasserts a retired publishing-ownership claim"
fi

# ---------------------------------------------------------------------------
# pown-02 — every needle is caught when planted. This is where the guard's
# teeth are: each needle measures zero on the live tree, so only planting shows
# that the scanner would catch it. One result line per needle, each addressable
# by its own id.
# ---------------------------------------------------------------------------
planted_n=0
while IFS= read -r lit; do
  [ -n "$lit" ] || continue
  planted_n=$((planted_n + 1))
  slug="$(slugify "$lit")"
  fixture="$TMPROOT/plant-$planted_n"
  rm -rf "$fixture"; mkdir -p "$fixture"
  build_fixture "$fixture"
  # Plant this one needle in one surface, leaving the rest clean.
  printf '%s\n' "A sentence that mentions $lit in passing." >> "$fixture/docs/ecosystem-overview.md"

  run_scan "$fixture" "plant-$slug"
  if assert_rc 1 && assert_out_has "OFFENDER docs/ecosystem-overview.md"; then
    pass "pown-02-needle-$slug a planted needle is caught and its surface named"
  else
    fail "pown-02-needle-$slug a planted needle was not caught"
  fi
done <<EOF
$NEEDLES
EOF

# The needle list must not silently shrink. Ten literals were measured and
# recorded in the header; dropping one removes a regression class without
# removing its result line, which is the shape that looks like coverage.
if [ "$planted_n" -eq 10 ]; then
  pass "pown-02-needle-floor all ten recorded needles were planted and exercised"
else
  fail "pown-02-needle-floor expected 10 needles, planted $planted_n — the needle list changed"
fi

# ---------------------------------------------------------------------------
# pown-03 — a missing surface fails rather than reporting clean.
# ---------------------------------------------------------------------------
fixture="$TMPROOT/missing"
rm -rf "$fixture"; mkdir -p "$fixture"
build_fixture "$fixture"
rm -f "$fixture/docs/plugin-guide/cogni-workspace.md"
run_scan "$fixture" "missing"
if assert_rc 1 && assert_out_has "surface not found: docs/plugin-guide/cogni-workspace.md"; then
  pass "pown-03-missing-surface a missing surface fails and is named"
else
  fail "pown-03-missing-surface a missing surface did not fail the scan"
fi

# ---------------------------------------------------------------------------
# pown-04 — scoping. The transition record, the migration guide and the
# maintainer CLAUDE.md files legitimately name the old routes. They are not
# surfaces, so a needle in them is NOT an offender. This is the case that stops
# SURFACES being "simplified" into a tree walk.
# ---------------------------------------------------------------------------
fixture="$TMPROOT/scoping"
rm -rf "$fixture"; mkdir -p "$fixture"
build_fixture "$fixture"
while IFS= read -r nonsurface; do
  [ -n "$nonsurface" ] || continue
  mkdir -p "$fixture/$(dirname "$nonsurface")"
  {
    printf '%s\n' "This document records the compatibility routes on purpose."
    while IFS= read -r lit; do
      [ -n "$lit" ] || continue
      printf '%s\n' "$lit"
    done <<EOF2
$NEEDLES
EOF2
  } > "$fixture/$nonsurface"
done <<EOF
$NON_SURFACES
EOF

run_scan "$fixture" "scoping"
if assert_rc 0 && assert_out_lacks "OFFENDER"; then
  pass "pown-04-scoping needles in the transition record, migration guide and CLAUDE.md are not flagged"
else
  fail "pown-04-scoping a needle outside the surface list was wrongly flagged"
fi

# ---------------------------------------------------------------------------
# pown-05 — a scan that examined zero surfaces fails rather than reporting
# clean. Without this floor, an emptied surface list reports a clean tree.
# ---------------------------------------------------------------------------
fixture="$TMPROOT/floor"
rm -rf "$fixture"; mkdir -p "$fixture"
build_fixture "$fixture"
run_scan "$fixture" "floor" ""
if assert_rc 1 && assert_out_has "no surfaces scanned"; then
  pass "pown-05-surface-floor a scan examining zero surfaces fails"
else
  fail "pown-05-surface-floor an empty surface list reported clean"
fi

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  printf '%s\n' ""
  printf '%s\n' "FAIL: $failures publishing-ownership test(s) failed."
  exit 1
fi
printf '%s\n' ""
printf '%s\n' "All publishing-ownership tests passed."
