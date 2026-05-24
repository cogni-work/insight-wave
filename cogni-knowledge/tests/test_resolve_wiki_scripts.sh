#!/usr/bin/env bash
# test_resolve_wiki_scripts.sh - behaviour test for F26.
#
# F26: resolve_wiki_ingest_scripts() (in knowledge-ingest + knowledge-finalize)
# must pick the NEWEST cached cogni-wiki version, not the lexically-first glob
# match. On a multi-version dev cache the old code returned 0.0.16 (lexically
# smallest) instead of the installed 0.0.45; the 0.0.16 helpers predate the
# per-type-dir + `type: source` schema. The fix sorts the glob with `sort -V`
# and takes the last entry, considering ONLY numeric version dirs (a stray
# non-numeric dir like `main` would otherwise sort ABOVE every real version).
#
# To avoid testing a stale copy of the resolver, this test EXTRACTS the live
# function body straight from each SKILL.md and runs THAT — and asserts the
# ingest and finalize copies are byte-identical so they cannot drift.
#
# Cases (against the extracted ingest body):
#   1. multi-version cache (+ a stray `main`/`latest` dir) -> returns 0.0.45,
#      never the non-numeric dir
#   2. dev-repo sibling -> returns the sibling (short-circuits the glob)
#   3. nothing installed -> returns non-zero
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"
INGEST_SKILL="$SKILLS_DIR/knowledge-ingest/SKILL.md"
FINALIZE_SKILL="$SKILLS_DIR/knowledge-finalize/SKILL.md"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

# Pull the live resolve_wiki_ingest_scripts() body straight from a SKILL.md so
# the behavioural cases exercise the SHIPPED code, not a hand-maintained copy.
# The function sits at column 0 inside a fenced block; print from its header
# through the first column-0 closing brace.
extract_resolver() {
  awk '/^resolve_wiki_ingest_scripts\(\) \{/{f=1} f{print} f&&/^\}/{exit}' "$1"
}

# -----------------------------------------------------------------------------
# Part 1: contract — both SKILLs define the version-aware resolver (sort -V) and
#         their copies have not drifted from each other.
# -----------------------------------------------------------------------------

for skill_file in "$INGEST_SKILL" "$FINALIZE_SKILL"; do
  name=$(basename "$(dirname "$skill_file")")
  if [ ! -f "$skill_file" ]; then
    red "FAIL: skill file not found: $skill_file"; errors=$((errors + 1)); continue
  fi
  if ! grep -qE 'resolve_wiki_ingest_scripts\(\) \{' "$skill_file"; then
    red "FAIL: $name missing resolve_wiki_ingest_scripts() definition"; errors=$((errors + 1))
  elif ! grep -qE 'sort -V' "$skill_file"; then
    red "FAIL: $name resolver does not version-sort (sort -V) — F26 would regress"; errors=$((errors + 1))
  else
    green "PASS: $name carries the version-aware resolver (sort -V)"
  fi
done

INGEST_BODY=$(extract_resolver "$INGEST_SKILL")
FINALIZE_BODY=$(extract_resolver "$FINALIZE_SKILL")

if [ -z "$INGEST_BODY" ]; then
  red "FAIL: could not extract resolve_wiki_ingest_scripts() body from knowledge-ingest SKILL.md"
  errors=$((errors + 1))
fi
if [ "$INGEST_BODY" != "$FINALIZE_BODY" ]; then
  red "FAIL: ingest and finalize resolver bodies have drifted apart"
  errors=$((errors + 1))
else
  green "PASS: ingest and finalize resolver bodies are byte-identical"
fi

# -----------------------------------------------------------------------------
# Part 2: behaviour — run the EXTRACTED ingest body against synthetic layouts.
# -----------------------------------------------------------------------------

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Multi-version marketplace cache + two stray non-numeric dirs. CLAUDE_PLUGIN_ROOT
# points at $WORK/cache/cogni-knowledge/0.1.1; siblings at
# $WORK/cache/cogni-wiki/<dir>/skills/wiki-ingest/scripts.
mkdir -p "$WORK/cache/cogni-knowledge/0.1.1"
for v in 0.0.9 0.0.16 0.0.45 main latest; do
  mkdir -p "$WORK/cache/cogni-wiki/$v/skills/wiki-ingest/scripts"
done

# Dev-repo sibling layout.
mkdir -p "$WORK/devrepo/cogni-knowledge"
mkdir -p "$WORK/devrepo/cogni-wiki/skills/wiki-ingest/scripts"

# Nothing installed.
mkdir -p "$WORK/missing/cogni-knowledge"

RESOLVE_BODY="$INGEST_BODY
if resolve_wiki_ingest_scripts; then exit 0; else exit 1; fi"

run_resolve() {
  CLAUDE_PLUGIN_ROOT="$1" bash -c "$RESOLVE_BODY"
}

# Case 1: multi-version cache + stray non-numeric dirs -> newest VERSION (0.0.45),
# never `main`/`latest` (which sort -V would otherwise rank highest).
if OUT=$(run_resolve "$WORK/cache/cogni-knowledge/0.1.1"); then
  case "$OUT" in
    */cogni-wiki/0.0.45/skills/wiki-ingest/scripts)
      green "PASS: multi-version cache resolves newest version (0.0.45), ignores main/latest" ;;
    *)
      red "FAIL: multi-version cache resolved the wrong dir (expected 0.0.45)"
      red "  got: $OUT"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: multi-version cache resolver returned non-zero"; errors=$((errors + 1))
fi

# Case 2: dev-repo sibling -> the sibling path (short-circuits the glob). The
# resolver echoes $sib unnormalized (<CPR>/../cogni-wiki/...); that `/../cogni-wiki/`
# form uniquely identifies the sibling branch (the cache branch has no `..`).
if OUT=$(run_resolve "$WORK/devrepo/cogni-knowledge"); then
  case "$OUT" in
    */../cogni-wiki/skills/wiki-ingest/scripts)
      green "PASS: dev-repo sibling layout resolves the sibling scripts dir" ;;
    *)
      red "FAIL: dev-repo sibling resolved an unexpected path"
      red "  got: $OUT"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: dev-repo sibling resolver returned non-zero"; errors=$((errors + 1))
fi

# Case 3: nothing installed -> non-zero exit.
if run_resolve "$WORK/missing/cogni-knowledge" >/dev/null 2>&1; then
  red "FAIL: resolver returned success with no cogni-wiki installed"; errors=$((errors + 1))
else
  green "PASS: resolver returns non-zero when cogni-wiki is absent"
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "F26 resolve_wiki_ingest_scripts version-sort contract and behaviour all pass."
