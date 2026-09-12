#!/usr/bin/env bash
# Retired-claim guard. Two subjects, one scanner: no surface may reassert that
# cogni-workspace is the foundation layer every other plugin depends on, and no
# surface may reassert the retired live-website / PowerPoint theme-extraction
# paths that Operation 10 replaced.
#
# Why this exists. The absorption that created this plugin replaced the LAYERING
# claim (cogni-workspace is the layer everything depends on) with a SCOPE claim
# (it is the horizontal layer; each vertical business plugin keeps its own
# project lifecycle). The claim was asserted in 19 places across docs/,
# both wiki trees, a since-retired plugin and cogni-workspace, and reconciling
# them by hand is only durable if something notices when one comes back. Nothing
# did:
# test-wiki-namespace-sync.sh checks filename stems against the marketplace
# roster and never reads page prose, and no suite anywhere compares the two wiki
# trees against each other. A regenerated doc or a re-imported wiki page could
# reintroduce the claim silently.
#
# Contract under test:
#   - none of the FORBIDDEN_ALL literals appears anywhere outside the excluded
#     paths — that is the layering-claim set and the retired theme-extraction set
#   - every one of those literals is actually caught when present (no dead config)
#   - a literal under an excluded path is NOT flagged
#   - each page on the PAGE_PARITY allowlist is byte-identical across the two
#     wiki trees
#   - the PAGE_PARITY allowlist has not shrunk below its recorded size
#   - a scan pointed at a missing or empty tree fails rather than reporting clean
#   - the guarded generated page carries no retired `narrative-review` reference,
#     a planted reference at EITHER reintroduction site is caught, a missing or
#     unreadable page fails rather than reporting clean, and the legitimate
#     occurrences elsewhere in the tree are NOT flagged
#
# Why the narrative-review needle is PAGE-SCOPED rather than another FORBIDDEN_ALL
# entry. `narrative-review` is live, correct prose in two tracked files: the
# retirement ledger at cogni-workspace/references/retired-trigger-phrases.tsv,
# where naming the retired phrase is the whole job, and
# docs/architecture/loop-health-map.md. A repo-wide literal would turn L1 red on
# both. The obvious "fix" — adding those two files to EXCLUDED — is worse:
# is_excluded matches by SUBSTRING, so the exemption is wider than the two files
# it names, and it retires the guard instead of the claim, which the root
# CLAUDE.md forbids explicitly. So the narrative-review arm scans ONE page and
# deliberately does not consult EXCLUDED at all, which is what makes the
# never-exempt rule structural rather than a promise.
#
# The needle is fail-closed by design. Because the guarded page is generator
# output, the bare literal also reds on a hand-written past-tense retirement note
# naming narrative-review. That is deliberate: the remedy stays the two halves —
# correct the page in place and raise the template fix upstream — never a
# weakened needle.
#
# Literals, not a regex over "foundation". `foundation` alone has many legitimate
# hits (cogni-portfolio prose, cogni-narrative, the theme-system migration guide),
# and `four layers` collides with cogni-workspace's four-layer validation gate and
# cogni-trends' Foundations dimension. Each literal below is a phrase that was
# measured present-and-wrong on the pre-reconciliation base, so each one is a
# claim about this repo rather than a guess.
#
# The first two literals measured ZERO on the base — an earlier PR had already
# removed them, which is why the issue's own acceptance criterion citing them was
# vacuous. They are retained here anyway, and case L2 plants each one in a
# fixture, so the scanner is proven to catch each phrase.
#
# The retired theme-extraction subject. The live-website and PPTX theme-extraction
# operations were retired in favour of Operation 10 (the Claude Design bundle
# importer), and a later sweep removed every surviving claim from both wiki trees,
# cogni-workspace/README.md and the theme-system RFC.
# Nothing stopped the class returning, so FORBIDDEN_EXTRACTION carries it here
# under the same scanner. Each of its four literals was measured ZERO-hit
# repo-wide over tracked files on the post-sweep tree, outside the excluded paths
# below — so each is a claim about this repo's current state, matching the
# measurement convention the layering literals follow.
#
# REJECTED / NOT SCANNED — two candidates were measured and deliberately left
# out, because each still hits live, correct prose in
# cogni-workspace/skills/manage-themes/SKILL.md. They are recorded here so a
# later editor does not re-propose them, and they are cited by quoted text
# rather than line number, the same way the phrase-level survivors further down
# are cited. "PowerPoint template"
# survives in the live Operation-10 discovery question, "Do you have a website,
# PowerPoint template, or brand guidelines (colors/fonts) I can use as a starting
# point?". "PPTX extraction" survives in TWO places, not one: the sentence
# documenting the retirement itself, "The live-website and PPTX extraction paths
# that once held 3 and 4 were retired in favour of Operation 10", and the
# rationale heading "Why this replaced the live website and PPTX extraction
# paths". Scanning either would turn L1 red on correct prose.
#
# What L2 does and does not prove. L2 reads the literals from FORBIDDEN_ALL,
# plants each in a fixture, and scans with FORBIDDEN_ALL — so it proves the
# SCANNER catches a planted phrase, but it cannot detect a literal being
# *reworded*: a substitution changes the planted text and the needle together,
# leaving L2 green. The count floor below is what protects BOTH sets — it is
# sized to the union (14 layering + 4 extraction = 18), so dropping an entry from
# either constant takes l2_n under the floor and turns L2 red. The floor is a
# hardcoded numeral on purpose: a count derived from the constants it guards
# would move with the deletion it is meant to catch and could never fire.
# Do not read L2 as a regression guard against editing a literal's wording; for
# a mutation that a change can actually flip, target the parity checker (see L4).
#
# The parity allowlist has the same floor, for the same reason. PAGE_PARITY is
# guarded by a hardcoded count in L10, because the per-page byte-identity arms
# cannot supply one: L4 and L5 build their fixtures by walking PAGE_PARITY
# itself, L7 runs against the real repo, and check_parity's only cardinality
# assertion fires at zero rather than at a floor — so all three stay green when
# an entry is dropped. Adding a page means raising that numeral in the same
# commit; the note on the constant itself says so at the point of use.
#
# Phrase-level survivors. These lines keep foundation vocabulary on purpose and
# must NOT be caught. Each says something about the workspace *state* other
# plugins read, never about the plugin's position in a dependency order, so none
# is falsified by the scope claim. Each is cited by its quoted text rather than
# by a line number: the quote is the locator, so an edit above it cannot rot the
# citation the way a number does.
#
#   - manage-workspace/SKILL.md — "An insight-wave workspace is the shared
#     foundation that all marketplace plugins depend on" (subject is the
#     workspace, not cogni-workspace)
#   - workspace-dashboard/SKILL.md — "the foundation that every other plugin
#     reads from" (reads from, not depends on)
#
# Two further entries once sat in this list, and a third such citation in the
# paragraph below, quoting course and workflow prose from a plugin since retired
# from the marketplace roster. All three are dropped rather than repointed: the
# files they named are gone from the tree, and the phrases they quoted survive
# nowhere else, so no page is left to point at. This inventory is a claim about
# what is standing in the current tree, so it may only name things that exist —
# the retired paths stay recorded in git history instead. Retired-plugin phrasing
# leaves a live survivor inventory behind, so a list like this one may name only
# what still stands.
#
# This list is why the shared-foundation literal below is prefixed with the
# plugin name: the bare "is the shared foundation" also matches the first entry,
# so an unprefixed literal would make this suite red on arrival against a line
# that is deliberately standing.
#
# The list is ILLUSTRATIVE, not exhaustive. It names the lines that shaped a
# literal's wording, not every surviving use of "foundation". More exist — the
# manage-workspace description propagates verbatim into its own frontmatter
# (:4, :10), into the [[skill-cogni-workspace-manage-workspace]] bullet under
# the cogni-workspace skills heading of each wiki tree's index.md (identified
# by wikilink rather than line number: the two trees number that bullet
# differently, so no single line number is right for both), and into both
# skill-cogni-workspace-manage-workspace.md:16. Those are
# all the same compatible claim about workspace state, and no literal here
# targets them. Grepping "foundation" will surface hits this block does not
# account for; that is expected, and the test is whether the sentence asserts a
# DEPENDENCY ORDER among plugins, not whether it uses the word.
#
# Path exclusions, each with a reason:
#   - this file (it necessarily contains every literal it forbids)
#   - wiki/log.md and the bundled copy — a dated ingest log; rewriting history is
#     not reconciliation
#   - wiki/pages/lint-2026-04-20.md — a dated lint note, and root-tree-only, so
#     editing it would also break the per-page parity assertion below
#   - .git/ and .claude/worktrees/ — nested checkouts of this same repo that
#     local tooling leaves in the tree. Untracked, so `grep_hits` already skips
#     them on the real repo; these entries only cover the filesystem fallback.
#
# No manifest is exempt. cogni-workspace's own plugin.json and the root
# marketplace.json were the retired claim's last upstream source and carried a
# temporary exemption while the reconciliation's scope boundary kept manifest
# edits out of its diff; both descriptions now assert the horizontal-layer scope
# claim, so the exemption is gone and the scan covers them like any other file.
#
# Never re-add a bare `.claude-plugin/` fragment in their place. `is_excluded`
# matches by SUBSTRING, so that one fragment would exempt all 15 files under
# every plugin's manifest directory — any OTHER plugin could then reintroduce
# the claim invisibly, a gap far wider than the two files it would read as
# covering. Case L9 is what keeps that revert red.
#
# Parity is per-page, never tree-wide, and that is load-bearing. The two trees
# legitimately differ (the root tree carries lint-2026-04-20.md and the bundled
# one does not), and scripts/release-bundle-wiki.sh states that drift between
# releases is acceptable. A tree-wide diff would be red on arrival and would
# pressure someone into running that rsync --delete sync, which sweeps unrelated
# drift. Naming an explicit allowlist of pages keeps the assertion true and
# useful at the same time. One group is the layering-claim pages; another is the
# group-B workflow pages back-ported bundle -> root, pinned here so the sections
# that once existed only in the bundle cannot drift back out of the root tree
# unnoticed; later entries each carry their own reason below.
#
# Case-label shape matches test-wiki-namespace-sync.sh on purpose: "PASS: <case>"
# / "FAIL: <case>", because the cogni-service mutation harness classifies a case
# GREEN only on ^[[:space:]]*(ok|PASS):[[:space:]]+<case> and RED on the matching
# FAIL: form. Case ids are L-prefixed and never bare numerals, so the summary line
# is not read as a case's RED line.
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
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Phrases that assert the retired layering claim. One per line; matched
# case-insensitively as fixed strings, never as regexes.
FORBIDDEN='every other plugin depends
every other cogni-x plugin depends
no upward dependencies
foundation layer
higher layers depend
depend on lower layers
depends on lower layers
depends on nothing
foundation for all
foundation-layer plugin
the foundation the others depend on
cogni-workspace is the shared foundation
foundation: cogni-workspace
span four tiers'

# Phrases that assert the retired live-website / PowerPoint theme-extraction
# paths. Same matching rules as FORBIDDEN: one per line, case-insensitive fixed
# strings, never regexes. Kept a separate constant from the layering set above
# because it is a different subject with its own measurement record.
FORBIDDEN_EXTRACTION='extract mode
theme extraction
from live websites
extracted from live'

# The union both literal readers consume, and the only value the scanner reads.
# The newline below is a real one, as in the constants above: "\n" inside double
# quotes is not a newline to bash, and that spelling fuses the last layering
# literal to the first extraction literal into one entry matching nothing —
# silently dropping a live literal and taking l2_n to 17.
FORBIDDEN_ALL="$FORBIDDEN
$FORBIDDEN_EXTRACTION"

# The single generated page the narrative-review arm guards, repo-relative.
GUARDED_PAGE='docs/plugin-guide/cogni-workspace.md'

# Retired references that must not reappear on GUARDED_PAGE. One per line,
# matched case-insensitively as fixed strings, never as regexes.
#
# One BARE literal on purpose. The upstream template emits narrative-review at
# two sites: the capability paragraph, whose heading carries NO leading slash,
# and the Commands line, which carries `/narrative-review`. The bare form
# subsumes the slash form, so one literal catches both; a slash-anchored needle
# would silently miss the capability paragraph — exactly the half the issue
# names first. L12 plants both site shapes to demonstrate that.
PAGE_FORBIDDEN='narrative-review'

# Repo-relative path fragments exempt from the scan. See the header for why each
# one is here.
#
# The two cogni-workspace/libraries/ entries carry `Foundation Layer` as a label
# inside an ASCII-art diagram, naming a z-order layer in a drawing rather than
# making any claim about plugin layering. They are listed by exact path rather
# than as a directory prefix, so a future file added to that tree still has to
# answer to this guard. The former `cogni-visual/libraries/` directory entry is
# gone with the source tree it exempted.
EXCLUDED='cogni-workspace/tests/test-layering-claim-reconciled.sh
wiki/wiki/log.md
wiki/wiki/pages/lint-2026-04-20.md
cogni-workspace/libraries/excalidraw-patterns.md
cogni-workspace/libraries/svg-patterns.md
.git/
.claude/worktrees/'

# Pages that must stay byte-identical between the two wiki trees. Scoped to what
# this reconciliation touched — see the header on why this is not tree-wide.
#
# plugin-cogni-portfolio.md joins the list with the bare-prose sweep: it carried
# four off-roster names across two lines, both copies were rewritten, and unlike
# its siblings here it had no byte-identity arm of its own. The roster-derived
# body scan now covers off-roster plugin names on both trees, so that class no
# longer rests on this entry alone. The entry stays regardless: a name scan sees
# only names, while byte-identity still catches arbitrary one-tree-only drift on
# that page — a reworded sentence, a dropped section, a changed link.
#
# concept-slug-based-lookups.md joins on the same grounds: its shared bullet named a
# manifest no plugin writes, both copies were rewritten identically, and no other arm
# here pins the two copies to each other. The roster-derived scan does not reach it
# either: that bullet named a MANIFEST, not a plugin, so a roster of plugin names
# never sees it.
#
# concept-theme-inheritance.md and skill-cogni-workspace-manage-themes.md join
# with the theme-extraction sweep. Both were edited in both trees by that sweep,
# both are the most prose-heavy of the pages it touched, and until now neither
# had a byte-identity arm anywhere: no other file under cogni-workspace/tests/
# names either page, and the one sibling that does pin a wiki page pins a
# different one. Both pairs are byte-identical as they are added, so a green run
# is not evidence they are guarded — mutating one copy is what shows the entry
# has teeth.
#
# Raise the floor in lockstep. L10 pins this list's size to a hardcoded numeral.
# Adding a page here without raising that numeral leaves the new entry — and
# every entry added after it — unprotected against silent removal, which is the
# class L10 exists to close.
PAGE_PARITY='plugin-cogni-workspace.md
workflow-install-to-infographic.md
arch-er-diagram.md
concept-four-layer-architecture.md
workflow-portfolio-to-website.md
workflow-content-pipeline.md
workflow-portfolio-to-pitch.md
workflow-trends-to-solutions.md
plugin-cogni-portfolio.md
concept-slug-based-lookups.md
concept-theme-inheritance.md
skill-cogni-workspace-manage-themes.md'

# ---------------------------------------------------------------------------
# The checkers. Fixture cases and the real-repo cases drive these same two
# functions, so pointing a case at a broken checker turns that case red.
# ---------------------------------------------------------------------------

# is_excluded <repo-relative-path> -> 0 when the path is exempt.
is_excluded() {
  local path="$1" frag
  while IFS= read -r frag; do
    [ -n "$frag" ] || continue
    case "$path" in
      *"$frag"*) return 0 ;;
    esac
  done <<EOF
$EXCLUDED
EOF
  return 1
}

# scan_literals <root> <label> -> 0 clean, 1 offenders found or root unusable.
# Prints one "OFFENDER <path>: <literal>" line per hit.
# Enumerate files under $1 containing the literal $2.
#
# Inside a git work tree, restrict the search to TRACKED files. The retired claim
# is an assertion about repo content, and the filesystem under this root also
# holds content git deliberately ignores — skill eval workspaces (`*-workspace/`)
# and nested worktree checkouts of this same repo. Scanning those makes the
# verdict depend on which branches and evals a developer happens to have on disk:
# green in CI, where none of it exists, and red on a working machine for reasons
# no reader can act on. `git grep` searches the working tree, so uncommitted edits
# to tracked files are still scanned — which is what a pre-commit guard needs.
#
# Outside a git work tree (the synthetic fixtures below) fall back to a plain
# recursive grep. The root must be the work tree's top level; `git grep` from a
# subdirectory scopes itself to that subdirectory, which would silently narrow
# the scan.
grep_hits() {
  local root="$1" lit="$2" top
  top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$top" ] && [ "$top" = "$(cd "$root" && pwd -P)" ]; then
    git -C "$root" grep -IliF -- "$lit" 2>/dev/null || true
  else
    grep -RIliF -- "$lit" "$root" 2>/dev/null || true
  fi
}

scan_literals() {
  local root="$1" label="$2"
  local offenders=0 scanned=0 lit hit path

  if [ ! -d "$root" ]; then
    echo "ERROR [$label] scan root not found: $root"
    return 1
  fi

  while IFS= read -r lit; do
    [ -n "$lit" ] || continue
    scanned=$((scanned + 1))
    # -R follows no symlinks by design; -I skips binaries; -l gives one path per file.
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      path="${hit#$root/}"
      if is_excluded "$path"; then continue; fi
      echo "OFFENDER $path: $lit"
      offenders=$((offenders + 1))
    done <<EOF
$(grep_hits "$root" "$lit")
EOF
  done <<EOF
$FORBIDDEN_ALL
EOF

  # Liveness floor: a scan that examined no literals is not evidence of a clean
  # tree, it is evidence of a broken constant. Same half-dead-arm failure
  # test-wiki-namespace-sync.sh guards with its own empty-tree case.
  if [ "$scanned" -eq 0 ]; then
    echo "ERROR [$label] no literals scanned — FORBIDDEN_ALL is empty"
    return 1
  fi
  [ "$offenders" -eq 0 ]
}

# scan_page_literals <root> <label> -> 0 clean, 1 offender found or page unusable.
# Prints one "OFFENDER <GUARDED_PAGE>: <literal>" line per hit, so a failure
# names the file the way the boundary record promises it will.
#
# Scoped to the single generated page, NOT to the tree. It deliberately does not
# call is_excluded: the root CLAUDE.md forbids resolving a re-emission by
# exempting the page, and a scanner that cannot consult an exemption list cannot
# be talked into one. See the header for why the needle is not in FORBIDDEN_ALL.
scan_page_literals() {
  local root="$1" label="$2"
  local page offenders=0 scanned=0 lit

  page="$root/$GUARDED_PAGE"

  # A missing page must FAIL, never report clean. A scan whose subject can vanish
  # while the arm still reports green is the half-dead-arm class L6 and the
  # scanned-eq-0 floor above both exist to close.
  if [ ! -f "$page" ] || [ ! -r "$page" ]; then
    echo "ERROR [$label] guarded page not found: $GUARDED_PAGE"
    return 1
  fi

  while IFS= read -r lit; do
    [ -n "$lit" ] || continue
    scanned=$((scanned + 1))
    # -I skips binaries; -F fixed string; -i case-insensitive; -q sets rc only.
    if grep -IiFq -- "$lit" "$page" 2>/dev/null; then
      echo "OFFENDER $GUARDED_PAGE: $lit"
      offenders=$((offenders + 1))
    fi
  done <<EOF
$PAGE_FORBIDDEN
EOF

  # Same liveness floor as scan_literals: a scan that examined no literals is
  # evidence of a broken constant, not of a clean page.
  if [ "$scanned" -eq 0 ]; then
    echo "ERROR [$label] no page literals scanned — PAGE_FORBIDDEN is empty"
    return 1
  fi
  [ "$offenders" -eq 0 ]
}

# check_parity <root> <label> -> 0 when every PAGE_PARITY page matches across trees.
check_parity() {
  local root="$1" label="$2"
  local a="$root/wiki/wiki/pages" b="$root/cogni-workspace/wiki/wiki/pages"
  local mismatches=0 compared=0 page

  if [ ! -d "$a" ] || [ ! -d "$b" ]; then
    echo "ERROR [$label] one or both wiki page trees not found"
    return 1
  fi

  while IFS= read -r page; do
    [ -n "$page" ] || continue
    if [ ! -f "$a/$page" ] || [ ! -f "$b/$page" ]; then
      echo "MISSING $page absent from one tree"
      mismatches=$((mismatches + 1))
      continue
    fi
    compared=$((compared + 1))
    if ! cmp -s "$a/$page" "$b/$page"; then
      echo "DRIFT $page differs between the two wiki trees"
      mismatches=$((mismatches + 1))
    fi
  done <<EOF
$PAGE_PARITY
EOF

  if [ "$compared" -eq 0 ] && [ "$mismatches" -eq 0 ]; then
    echo "ERROR [$label] no pages compared — PAGE_PARITY is empty"
    return 1
  fi
  [ "$mismatches" -eq 0 ]
}

# --- harness ---------------------------------------------------------------
LAST_OUT=""; LAST_RC=0
run_scan()   { LAST_OUT="$(scan_literals "$1" "$2" 2>&1)"; LAST_RC=$?; }
run_page_scan() { LAST_OUT="$(scan_page_literals "$1" "$2" 2>&1)"; LAST_RC=$?; }
run_parity() { LAST_OUT="$(check_parity  "$1" "$2" 2>&1)"; LAST_RC=$?; }
assert_rc()      { [ "$LAST_RC" -eq "$1" ] || { echo "  expected rc=$1 got rc=$LAST_RC"; echo "$LAST_OUT" | sed 's/^/  | /'; return 1; }; }
assert_out_has() { case "$LAST_OUT" in *"$1"*) return 0 ;; esac; echo "  expected output to contain: $1"; echo "$LAST_OUT" | sed 's/^/  | /'; return 1; }
assert_out_lacks(){ case "$LAST_OUT" in *"$1"*) echo "  expected output NOT to contain: $1"; echo "$LAST_OUT" | sed 's/^/  | /'; return 1 ;; esac; return 0; }

# ---------------------------------------------------------------------------
# L1 — the real repo is clean.
# ---------------------------------------------------------------------------
run_scan "$REPO_ROOT" "repo"
if assert_rc 0; then
  pass "L1 the real repo asserts no retired layering claim outside the excluded paths"
else
  fail "L1 the real repo asserts no retired layering claim outside the excluded paths"
fi

# ---------------------------------------------------------------------------
# L2 — every forbidden literal is caught when planted, and the set has not
# shrunk. The scan proves the two zero-on-base literals are wired to a working
# scanner; the count floor below is what stops one being dropped unnoticed. See
# the header on what this case cannot prove.
# ---------------------------------------------------------------------------
l2_ok=1
l2_n=0
while IFS= read -r lit; do
  [ -n "$lit" ] || continue
  l2_n=$((l2_n + 1))
  d="$TMPROOT/l2/$l2_n/docs"
  mkdir -p "$d"
  printf 'Some prose that says %s in passing.\n' "$lit" > "$d/page.md"
  run_scan "$TMPROOT/l2/$l2_n" "planted"
  assert_rc 1 && assert_out_has "docs/page.md" || l2_ok=0
done <<EOF
$FORBIDDEN_ALL
EOF
if [ "$l2_n" -lt 18 ]; then
  echo "  expected at least 18 literals, found $l2_n"
  l2_ok=0
fi
if [ "$l2_ok" -eq 1 ]; then
  pass "L2 every forbidden literal is caught when planted"
else
  fail "L2 every forbidden literal is caught when planted"
fi

# ---------------------------------------------------------------------------
# L3 — a literal under an excluded path is not flagged.
# ---------------------------------------------------------------------------
l3_ok=1
mkdir -p "$TMPROOT/l3/cogni-workspace/libraries" \
         "$TMPROOT/l3/wiki/wiki/pages"
printf '| Foundation Layer | fill |\n' > "$TMPROOT/l3/cogni-workspace/libraries/svg-patterns.md"
printf 'ingest: foundation layer\n' > "$TMPROOT/l3/wiki/wiki/log.md"
printf 'quoted `no upward dependencies` in a lint note\n' > "$TMPROOT/l3/wiki/wiki/pages/lint-2026-04-20.md"
run_scan "$TMPROOT/l3" "excluded"
assert_rc 0 || l3_ok=0
if [ "$l3_ok" -eq 1 ]; then
  pass "L3 a forbidden literal under an excluded path is not flagged"
else
  fail "L3 a forbidden literal under an excluded path is not flagged"
fi

# ---------------------------------------------------------------------------
# L4 — a PAGE_PARITY page that differs between the trees fails, and is named.
# ---------------------------------------------------------------------------
l4_ok=1
A="$TMPROOT/l4/wiki/wiki/pages"; B="$TMPROOT/l4/cogni-workspace/wiki/wiki/pages"
mkdir -p "$A" "$B"
while IFS= read -r page; do
  [ -n "$page" ] || continue
  printf 'same\n' > "$A/$page"
  printf 'same\n' > "$B/$page"
done <<EOF
$PAGE_PARITY
EOF
printf 'DIVERGED\n' > "$B/arch-er-diagram.md"
run_parity "$TMPROOT/l4" "drift"
assert_rc 1 && assert_out_has "arch-er-diagram.md" || l4_ok=0
if [ "$l4_ok" -eq 1 ]; then
  pass "L4 a touched page differing between the two trees fails and is named"
else
  fail "L4 a touched page differing between the two trees fails and is named"
fi

# ---------------------------------------------------------------------------
# L5 — a page outside PAGE_PARITY may differ without failing. This is what keeps
# the real trees' legitimate one-page delta from being red on arrival.
# ---------------------------------------------------------------------------
l5_ok=1
A="$TMPROOT/l5/wiki/wiki/pages"; B="$TMPROOT/l5/cogni-workspace/wiki/wiki/pages"
mkdir -p "$A" "$B"
while IFS= read -r page; do
  [ -n "$page" ] || continue
  printf 'same\n' > "$A/$page"
  printf 'same\n' > "$B/$page"
done <<EOF
$PAGE_PARITY
EOF
printf 'root-tree-only\n' > "$A/lint-2026-04-20.md"
run_parity "$TMPROOT/l5" "unlisted"
assert_rc 0 && assert_out_lacks "lint-2026-04-20" || l5_ok=0
if [ "$l5_ok" -eq 1 ]; then
  pass "L5 a page outside PAGE_PARITY may differ between the trees"
else
  fail "L5 a page outside PAGE_PARITY may differ between the trees"
fi

# ---------------------------------------------------------------------------
# L6 — liveness floor: a missing tree fails rather than reporting clean.
# ---------------------------------------------------------------------------
l6_ok=1
run_scan "$TMPROOT/l6/does-not-exist" "missing"
assert_rc 1 && assert_out_has "scan root not found" || l6_ok=0
run_parity "$TMPROOT/l6/does-not-exist" "missing"
assert_rc 1 && assert_out_has "wiki page trees not found" || l6_ok=0
if [ "$l6_ok" -eq 1 ]; then
  pass "L6 a missing tree fails rather than reporting clean"
else
  fail "L6 a missing tree fails rather than reporting clean"
fi

# ---------------------------------------------------------------------------
# L7 — the real repo's two wiki trees agree on every touched page.
# ---------------------------------------------------------------------------
run_parity "$REPO_ROOT" "repo"
if assert_rc 0; then
  pass "L7 the real wiki trees agree on every page this change touched"
else
  fail "L7 the real wiki trees agree on every page this change touched"
fi

# ---------------------------------------------------------------------------
# L8 — the git-tracked arm of grep_hits is live, and its narrowing is deliberate.
#
# Without this case the arm is untested. Every "caught when planted" fixture
# (L2, L3, L5) builds under mktemp, which is not a git work tree, so they all
# exercise the recursive-grep fallback; the only cases reaching the git arm are
# L1 and L7, and both assert CLEAN. Nothing would prove the arm can find
# anything — so if it ever returned empty (an edit, a sparse checkout, a flag an
# older git rejects) L1 would report PASS vacuously. That is the same half-dead
# arm the `scanned -eq 0` floor and L6 exist to prevent, and the arms were one
# code path until the scan was made git-aware.
#
# The second half pins the narrowing as intended rather than accidental: an
# untracked file carrying a literal is deliberately skipped, because the claim is
# an assertion about repo content and scanning ignored scratch made the verdict
# depend on a developer's local state. If the arm is ever swapped back to a
# filesystem walk, this half turns red and says so.
# ---------------------------------------------------------------------------
l8_ok=1
G="$TMPROOT/l8"
mkdir -p "$G/docs"
if ! git init -q "$G" >/dev/null 2>&1; then
  echo "  git init failed — cannot exercise the git-tracked arm"
  l8_ok=0
else
  printf 'Some prose that says foundation layer in passing.\n' > "$G/docs/tracked.md"
  git -C "$G" add docs/tracked.md >/dev/null 2>&1
  # commit.gpgsign is overridden too: it is a common personal global default, and
  # a signing failure here would red this case for a reason with nothing to do
  # with the arm under test — pointing a reader at the wrong code. CI is
  # unaffected, so this only bites the local pre-PR run, which is where the
  # suite's fastest signal is meant to come from.
  git -C "$G" -c user.email=guard@example.invalid -c user.name=Guard \
    -c commit.gpgsign=false \
    commit -q -m "fixture" >/dev/null 2>&1 || l8_ok=0

  # Tracked offender must be found, and named, by the git arm.
  run_scan "$G" "git-tracked"
  assert_rc 1 && assert_out_has "docs/tracked.md" || l8_ok=0

  # Untracked offender must NOT be found — the deliberate narrowing.
  printf 'Some prose that says foundation layer in passing.\n' > "$G/docs/untracked.md"
  run_scan "$G" "git-untracked"
  assert_rc 1 && assert_out_lacks "docs/untracked.md" || l8_ok=0
fi
if [ "$l8_ok" -eq 1 ]; then
  pass "L8 the git-tracked scan arm is live and skips untracked files"
else
  fail "L8 the git-tracked scan arm is live and skips untracked files"
fi

# ---------------------------------------------------------------------------
# L9 — no manifest is exempt: every `.claude-plugin` manifest is scanned.
#
# Same lesson as L8: without a case, the rule is asserted only in a comment.
# L1 cannot carry this one. Once the manifests were corrected, no manifest in
# the real repo holds a forbidden literal, so L1 is green whether EXCLUDED is
# empty of manifest entries or names them again — a re-added exemption, or a
# bare `.claude-plugin/` fragment re-opening all 15 files under every plugin's
# manifest directory, would slip in with every case still passing.
#
# This case makes both reverts red by planting the literal in three manifests
# that must ALL be caught: another plugin's, cogni-workspace's own (formerly
# exempt), and the root marketplace.json (which no case exercised before).
# ---------------------------------------------------------------------------
l9_ok=1
X="$TMPROOT/l9"
mkdir -p "$X/cogni-workspace/.claude-plugin" "$X/cogni-other/.claude-plugin" \
  "$X/.claude-plugin"
printf '{"description": "Foundation-layer plugin for insight-wave."}\n' \
  > "$X/cogni-workspace/.claude-plugin/plugin.json"
printf '{"description": "Foundation-layer plugin for insight-wave."}\n' \
  > "$X/cogni-other/.claude-plugin/plugin.json"
printf '{"description": "Foundation-layer plugin for insight-wave."}\n' \
  > "$X/.claude-plugin/marketplace.json"
run_scan "$X" "manifest-scope"
assert_rc 1 && assert_out_has "cogni-other/.claude-plugin/plugin.json" || l9_ok=0
assert_out_has "cogni-workspace/.claude-plugin/plugin.json" || l9_ok=0
assert_out_has ".claude-plugin/marketplace.json" || l9_ok=0
if [ "$l9_ok" -eq 1 ]; then
  pass "L9 no manifest is exempt — every .claude-plugin manifest is scanned"
else
  fail "L9 no manifest is exempt — every .claude-plugin manifest is scanned"
fi

# ---------------------------------------------------------------------------
# L10 — the PAGE_PARITY allowlist has not shrunk. The parity arms above prove
# each page ON the list is byte-identical across the trees; the count floor
# below is what stops an entry being dropped unnoticed. See the header on why
# that floor is a hardcoded numeral, and the note on the constant for what it
# obliges of whoever adds a page.
#
# Why a standalone case rather than a floor inside check_parity. Were the floor
# sited there, a dropped entry would make the checker return 1 to every caller —
# so L5 and L7, which both expect rc 0, would go red reporting a cardinality
# loss as parity drift, while L4, which already expects rc 1, would stay green.
# The loss would surface on two cases it has nothing to do with and stay
# invisible in the one case whose label says "differs". A standalone case reds
# only itself.
# ---------------------------------------------------------------------------
l10_ok=1
l10_n=0
while IFS= read -r page; do
  [ -n "$page" ] || continue
  l10_n=$((l10_n + 1))
done <<EOF
$PAGE_PARITY
EOF
if [ "$l10_n" -lt 12 ]; then
  echo "  expected at least 12 pinned pages, found $l10_n"
  l10_ok=0
fi
if [ "$l10_ok" -eq 1 ]; then
  pass "L10 the PAGE_PARITY allowlist has not shrunk"
else
  fail "L10 the PAGE_PARITY allowlist has not shrunk"
fi

# ---------------------------------------------------------------------------
# L11 — the real guarded page is clean. The real-repo arm, the counterpart of
# L1: without it every case below could pass against fixtures while the tracked
# page said anything at all.
# ---------------------------------------------------------------------------
run_page_scan "$REPO_ROOT" "guarded-page"
if assert_rc 0; then
  pass "L11 the generated cogni-workspace plugin guide carries no retired narrative-review reference"
else
  fail "L11 the generated cogni-workspace plugin guide carries no retired narrative-review reference"
fi

# ---------------------------------------------------------------------------
# L12 — teeth. Both reintroduction sites the upstream template emits are caught,
# and the failure output names the page. Fixture 1 is the capability paragraph,
# whose heading carries no leading slash; fixture 2 is the Commands line, which
# carries the slash form. A needle anchored on the slash form would pass fixture
# 2 and silently fail fixture 1, so planting both is what proves the bare needle
# is the right one.
# ---------------------------------------------------------------------------
l12_ok=1
l12_n=0
while IFS= read -r site; do
  [ -n "$site" ] || continue
  l12_n=$((l12_n + 1))
  d="$TMPROOT/l12/$l12_n/docs/plugin-guide"
  mkdir -p "$d"
  printf '%s\n' "$site" > "$d/cogni-workspace.md"
  run_page_scan "$TMPROOT/l12/$l12_n" "planted-site"
  assert_rc 1 && assert_out_has "$GUARDED_PAGE" || l12_ok=0
done <<EOF
### \`narrative-review\` — review a narrative against its source
Commands: \`/narrative-review\`.
EOF
if [ "$l12_n" -lt 2 ]; then
  echo "  expected at least 2 planted reintroduction sites, found $l12_n"
  l12_ok=0
fi
if [ "$l12_ok" -eq 1 ]; then
  pass "L12 both narrative-review reintroduction sites are caught when planted"
else
  fail "L12 both narrative-review reintroduction sites are caught when planted"
fi

# ---------------------------------------------------------------------------
# L13 — a missing guarded page fails rather than reporting clean. Without this
# the arm would go green the moment the page were renamed or dropped, which is
# precisely when the boundary record needs it most.
# ---------------------------------------------------------------------------
mkdir -p "$TMPROOT/l13/docs/plugin-guide"
run_page_scan "$TMPROOT/l13" "missing-page"
if assert_rc 1 && assert_out_has "guarded page not found"; then
  pass "L13 a missing guarded page fails rather than reporting clean"
else
  fail "L13 a missing guarded page fails rather than reporting clean"
fi

# ---------------------------------------------------------------------------
# L14 — scoping proof. narrative-review is live, correct prose in the retirement
# ledger and the loop-health map. This case is what stops a future maintainer
# "simplifying" the page-scoped arm into another FORBIDDEN_ALL entry: do that and
# this case goes red, naming files that are supposed to say the name.
# ---------------------------------------------------------------------------
l14_root="$TMPROOT/l14"
mkdir -p "$l14_root/docs/plugin-guide" "$l14_root/docs/architecture" "$l14_root/cogni-workspace/references"
printf 'A clean guide with no retired reference.\n' > "$l14_root/$GUARDED_PAGE"
printf 'narrative-review\tretired\n' > "$l14_root/cogni-workspace/references/retired-trigger-phrases.tsv"
printf 'The retired narrative-review loop is recorded here.\n' > "$l14_root/docs/architecture/loop-health-map.md"
run_page_scan "$l14_root" "scoping"
if assert_rc 0; then
  pass "L14 the legitimate ledger and loop-map occurrences are not flagged"
else
  fail "L14 the legitimate ledger and loop-map occurrences are not flagged"
fi

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures layering-claim test(s) failed."
  exit 1
fi
echo ""
echo "All layering-claim tests passed."
