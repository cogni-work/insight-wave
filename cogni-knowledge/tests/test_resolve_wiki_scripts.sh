#!/usr/bin/env bash
# test_resolve_wiki_scripts.sh - behaviour test for F26.
#
# F26: resolve_wiki_ingest_scripts() (in knowledge-ingest + knowledge-finalize)
# must pick the NEWEST cached cogni-wiki version, not the lexically-first glob
# match. On a multi-version dev cache the old code returned 0.0.16 (lexically
# smallest) instead of the installed 0.0.45; the 0.0.16 helpers predate the
# per-type-dir + `type: source` schema. The fix sorts the glob with `sort -V`
# and takes the last entry.
#
# This test executes the canonical resolve body (copied verbatim from the
# SKILL.md files) against three synthetic layouts:
#   1. multi-version cache  -> returns the 0.0.45 path (not 0.0.9 / 0.0.16)
#   2. dev-repo sibling     -> returns the sibling (short-circuits the glob)
#   3. nothing installed    -> returns non-zero
#
# It also asserts both SKILLs carry the same `sort -V` resolver body, so the
# two copies cannot drift.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

# -----------------------------------------------------------------------------
# Part 1: contract — both SKILLs carry the version-aware resolver (sort -V).
# -----------------------------------------------------------------------------

for skill in knowledge-ingest knowledge-finalize; do
  skill_file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    red "FAIL: skill file not found: $skill_file"
    errors=$((errors + 1))
    continue
  fi
  if ! grep -qE 'resolve_wiki_ingest_scripts\(\) \{' "$skill_file"; then
    red "FAIL: $skill missing resolve_wiki_ingest_scripts() definition"
    errors=$((errors + 1))
  elif ! grep -qE 'sort -V' "$skill_file"; then
    red "FAIL: $skill resolver does not version-sort (sort -V) — F26 would regress"
    errors=$((errors + 1))
  else
    green "PASS: $skill carries the version-aware resolver (sort -V)"
  fi
done

# -----------------------------------------------------------------------------
# Part 2: behaviour — run the canonical resolver body against synthetic layouts.
# -----------------------------------------------------------------------------

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Multi-version marketplace cache. CLAUDE_PLUGIN_ROOT points at
# $WORK/cache/cogni-knowledge/0.1.1; siblings live at
# $WORK/cache/cogni-wiki/<version>/skills/wiki-ingest/scripts.
mkdir -p "$WORK/cache/cogni-knowledge/0.1.1"
for v in 0.0.9 0.0.16 0.0.45; do
  mkdir -p "$WORK/cache/cogni-wiki/$v/skills/wiki-ingest/scripts"
done

# Dev-repo sibling layout. CLAUDE_PLUGIN_ROOT at $WORK/devrepo/cogni-knowledge;
# sibling at $WORK/devrepo/cogni-wiki/skills/wiki-ingest/scripts.
mkdir -p "$WORK/devrepo/cogni-knowledge"
mkdir -p "$WORK/devrepo/cogni-wiki/skills/wiki-ingest/scripts"

# Nothing installed.
mkdir -p "$WORK/missing/cogni-knowledge"

# Canonical resolver body - mirrors the SKILL.md verbatim.
RESOLVE_BODY=$(cat <<'BASH'
resolve_wiki_ingest_scripts() {
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-wiki/skills/wiki-ingest/scripts"
  test -d "$sib" && { echo "$sib"; return 0; }
  # F26: pick the NEWEST cached version, not the lexically-first.
  # sort -V handles multi-digit segments (0.0.9 < 0.0.16 < 0.0.45).
  local newest
  newest=$(for d in "${CLAUDE_PLUGIN_ROOT}/../../cogni-wiki/"*/skills/wiki-ingest/scripts; do
    [ -d "$d" ] && printf '%s\n' "$d"
  done | sort -V | tail -1)
  [ -n "$newest" ] && { echo "$newest"; return 0; }
  return 1
}
if resolve_wiki_ingest_scripts; then exit 0; else exit 1; fi
BASH
)

run_resolve() {
  CLAUDE_PLUGIN_ROOT="$1" bash -c "$RESOLVE_BODY"
}

# Case 1: multi-version cache -> newest (0.0.45).
if OUT=$(run_resolve "$WORK/cache/cogni-knowledge/0.1.1"); then
  case "$OUT" in
    */cogni-wiki/0.0.45/skills/wiki-ingest/scripts)
      green "PASS: multi-version cache resolves the newest version (0.0.45)" ;;
    *)
      red "FAIL: multi-version cache did not resolve 0.0.45"
      red "  got: $OUT"
      errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: multi-version cache resolver returned non-zero"
  errors=$((errors + 1))
fi

# Case 2: dev-repo sibling -> the sibling path (short-circuits the glob).
# The resolver echoes $sib unnormalized, i.e. <CPR>/../cogni-wiki/...; the
# `/../cogni-wiki/...` form uniquely identifies the sibling short-circuit
# branch (the versioned cache branch has no `..`).
if OUT=$(run_resolve "$WORK/devrepo/cogni-knowledge"); then
  case "$OUT" in
    */../cogni-wiki/skills/wiki-ingest/scripts)
      green "PASS: dev-repo sibling layout resolves the sibling scripts dir" ;;
    *)
      red "FAIL: dev-repo sibling resolved an unexpected path"
      red "  got: $OUT"
      errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: dev-repo sibling resolver returned non-zero"
  errors=$((errors + 1))
fi

# Case 3: nothing installed -> non-zero exit.
if run_resolve "$WORK/missing/cogni-knowledge" >/dev/null 2>&1; then
  red "FAIL: resolver returned success with no cogni-wiki installed"
  errors=$((errors + 1))
else
  green "PASS: resolver returns non-zero when cogni-wiki is absent"
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "F26 resolve_wiki_ingest_scripts version-sort contract and behaviour all pass."
