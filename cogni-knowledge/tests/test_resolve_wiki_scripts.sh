#!/usr/bin/env bash
# test_resolve_wiki_scripts.sh - behaviour test for F26.
#
# F26: resolve_wiki_scripts() (in knowledge-ingest + knowledge-finalize; named
# resolve_wiki_ingest_scripts() before Slice 16 generalized it to take a skill
# arg so finalize can also locate wiki-lint / wiki-health for the conformance
# gate) must pick the NEWEST cached cogni-wiki version, not the lexically-first
# glob match. On a multi-version dev cache the old code returned 0.0.16
# (lexically smallest) instead of the installed 0.0.45; the 0.0.16 helpers
# predate the per-type-dir + `type: source` schema. The fix sorts the glob with
# `sort -V` and takes the last entry, considering ONLY numeric version dirs (a
# stray non-numeric dir like `main` would otherwise sort ABOVE every real
# version).
#
# The resolver now lives in ONE shared snippet (scripts/resolve-wiki-scripts.sh)
# that every knowledge-* flow sources — there is no inline copy to drift. This
# test asserts the shared snippet defines the version-aware resolver, that every
# expected flow sources it (and carries no inline definition), and drives the
# snippet body directly through the behaviour cases below.
#
# Cases (against the shared snippet body):
#   1. multi-version cache (+ a stray `main`/`latest` dir) -> returns 0.0.45,
#      never the non-numeric dir
#   2. dev-repo sibling -> returns the sibling (short-circuits the glob)
#   3. nothing installed -> returns non-zero
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"
RESOLVER_SNIPPET="$PLUGIN_ROOT/scripts/resolve-wiki-scripts.sh"

# Every knowledge-* flow that needs the probe now SOURCES the shared snippet
# instead of carrying an inline copy. These are the flows expected to source it.
SOURCING_SKILLS="knowledge-ingest knowledge-finalize knowledge-dashboard knowledge-health knowledge-lint knowledge-resume knowledge-ingest-source knowledge-query"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

# The behavioural cases exercise the SHIPPED code by sourcing the one shared
# snippet directly — no extraction from a SKILL.md, no hand-maintained copy.
extract_resolver() {
  cat "$RESOLVER_SNIPPET"
}

# -----------------------------------------------------------------------------
# Part 1: contract — the shared snippet defines the version-aware resolver
#         (sort -V), and every knowledge-* flow sources it rather than carrying
#         an inline copy (the de-duplication invariant: one source of truth).
# -----------------------------------------------------------------------------

if [ ! -f "$RESOLVER_SNIPPET" ]; then
  red "FAIL: shared resolver snippet not found: $RESOLVER_SNIPPET"; errors=$((errors + 1))
elif ! grep -qE 'resolve_wiki_scripts\(\) \{' "$RESOLVER_SNIPPET"; then
  red "FAIL: shared snippet missing resolve_wiki_scripts() definition"; errors=$((errors + 1))
elif ! grep -qE 'sort -V' "$RESOLVER_SNIPPET"; then
  red "FAIL: shared snippet resolver does not version-sort (sort -V) — F26 would regress"; errors=$((errors + 1))
else
  green "PASS: shared snippet carries the version-aware resolver (sort -V)"
fi

for name in $SOURCING_SKILLS; do
  skill_file="$SKILLS_DIR/$name/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    red "FAIL: skill file not found: $skill_file"; errors=$((errors + 1)); continue
  fi
  if grep -qE 'resolve_wiki_scripts\(\) \{' "$skill_file"; then
    red "FAIL: $name still carries an inline resolve_wiki_scripts() definition (should source the snippet)"; errors=$((errors + 1))
  elif ! grep -qF 'scripts/resolve-wiki-scripts.sh' "$skill_file"; then
    red "FAIL: $name does not source the shared resolve-wiki-scripts.sh snippet"; errors=$((errors + 1))
  else
    green "PASS: $name sources the shared snippet (no inline copy)"
  fi
done

# -----------------------------------------------------------------------------
# Part 2: behaviour — run the shared snippet body against synthetic layouts.
# -----------------------------------------------------------------------------

# The shared snippet is the single source of truth all 8 flows source, so the
# behaviour cases below drive its body directly.
INGEST_BODY=$(extract_resolver)
if [ -z "$INGEST_BODY" ]; then
  red "FAIL: could not read resolve_wiki_scripts() body from the shared snippet"
  errors=$((errors + 1))
fi

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
if resolve_wiki_scripts wiki-ingest; then exit 0; else exit 1; fi"

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

# -----------------------------------------------------------------------------
# Part 3: entry-point existence (#536). With the optional 2nd arg, a probe
#         branch wins ONLY when the expected entry-point script is present in
#         the resolved dir, so a partial vendor (dir present, script absent)
#         falls through to the working fallback. Drives the SAME extracted
#         ingest body, now with the two-arg form.
# -----------------------------------------------------------------------------

RESOLVE_BODY_EP="$INGEST_BODY
if resolve_wiki_scripts wiki-ingest backlink_audit.py; then exit 0; else exit 1; fi"

run_resolve_ep() { CLAUDE_PLUGIN_ROOT="$1" bash -c "$RESOLVE_BODY_EP"; }

# Case 4: partial vendor (vendored dir present but backlink_audit.py ABSENT)
# next to a COMPLETE sibling (dir + script) -> the sibling wins.
PART="$WORK/partial"
mkdir -p "$PART/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"  # vendor: no script
mkdir -p "$PART/cogni-wiki/skills/wiki-ingest/scripts"                                  # sibling...
: > "$PART/cogni-wiki/skills/wiki-ingest/scripts/backlink_audit.py"                     # ...with the script
if OUT=$(run_resolve_ep "$PART/cogni-knowledge"); then
  case "$OUT" in
    */../cogni-wiki/skills/wiki-ingest/scripts)
      green "PASS: partial vendor (dir, no entry-point) falls through to the complete sibling" ;;
    *)
      red "FAIL: entry-point check resolved an unexpected path"
      red "  got: $OUT"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: entry-point resolver returned non-zero despite a complete sibling"; errors=$((errors + 1))
fi

# Case 5: complete vendor (dir + entry-point present) -> vendor wins.
COMPLETE="$WORK/complete"
mkdir -p "$COMPLETE/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"
: > "$COMPLETE/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts/backlink_audit.py"
if OUT=$(run_resolve_ep "$COMPLETE/cogni-knowledge"); then
  case "$OUT" in
    */scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts)
      green "PASS: complete vendor (dir + entry-point) wins the probe" ;;
    *)
      red "FAIL: complete vendor did not win (got: $OUT)"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: complete-vendor resolver returned non-zero"; errors=$((errors + 1))
fi

# Case 6: vendor dir + sibling dir present but NEITHER carries the script ->
# non-zero (the partial-everything case the dir-only probe would have masked).
NONE="$WORK/partialnone"
mkdir -p "$NONE/cogni-knowledge/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"
mkdir -p "$NONE/cogni-wiki/skills/wiki-ingest/scripts"
if run_resolve_ep "$NONE/cogni-knowledge" >/dev/null 2>&1; then
  red "FAIL: entry-point resolver returned success when no dir carries the script"; errors=$((errors + 1))
else
  green "PASS: no dir carrying the entry-point -> resolver returns non-zero"
fi

# -----------------------------------------------------------------------------
# Part 4: unset CLAUDE_PLUGIN_ROOT — the resolver derives the plugin root from
#         its own sourced location instead of expanding a glob rooted at an
#         empty prefix (which zsh aborts on with `no matches found`). The
#         snippet must be sourced BY FILE PATH here: a `bash -c` inlined body
#         (Parts 2-3) has an empty BASH_SOURCE, which would mask the fallback.
# -----------------------------------------------------------------------------

UNSET_ROOT="$WORK/cache/cogni-knowledge/0.1.1"
mkdir -p "$UNSET_ROOT/scripts"
cp "$RESOLVER_SNIPPET" "$UNSET_ROOT/scripts/resolve-wiki-scripts.sh"

# Case 7: bash, CLAUDE_PLUGIN_ROOT unset -> source-location root, newest cache wins.
if OUT=$(env -u CLAUDE_PLUGIN_ROOT bash -c ". '$UNSET_ROOT/scripts/resolve-wiki-scripts.sh'; resolve_wiki_scripts wiki-ingest"); then
  case "$OUT" in
    */cogni-wiki/0.0.45/skills/wiki-ingest/scripts)
      green "PASS: unset CLAUDE_PLUGIN_ROOT derives the root from the script's own location" ;;
    *)
      red "FAIL: unset-env fallback resolved the wrong dir"
      red "  got: $OUT"; errors=$((errors + 1)) ;;
  esac
else
  red "FAIL: resolver returned non-zero with CLAUDE_PLUGIN_ROOT unset (fallback did not engage)"; errors=$((errors + 1))
fi

# Case 7b: the snippet must parse + resolve under the SYSTEM bash (macOS ships
# /bin/bash 3.2, whose parser rejects closing-paren-only case patterns inside
# $(...) — the suite's plain `bash` resolves to a newer Homebrew bash, which
# masked exactly that regression). Runs only where /bin/bash exists.
if [ -x /bin/bash ]; then
  if OUT=$(env -u CLAUDE_PLUGIN_ROOT /bin/bash -c ". '$UNSET_ROOT/scripts/resolve-wiki-scripts.sh'; resolve_wiki_scripts wiki-ingest" 2>&1); then
    case "$OUT" in
      */cogni-wiki/0.0.45/skills/wiki-ingest/scripts)
        green "PASS: system /bin/bash (3.2 on macOS) parses and resolves the snippet" ;;
      *)
        red "FAIL: system /bin/bash run produced unexpected output"
        red "  got: $OUT"; errors=$((errors + 1)) ;;
    esac
  else
    red "FAIL: system /bin/bash could not source/resolve the snippet (3.2 parser regression?): $OUT"; errors=$((errors + 1))
  fi
else
  green "PASS: /bin/bash not present on this host — system-bash case skipped"
fi

# Case 8: same shape under zsh — the originally-reported failure environment
# (zsh aborts a sourced block on an unmatched glob). Runs only where zsh exists.
if command -v zsh >/dev/null 2>&1; then
  if OUT=$(env -u CLAUDE_PLUGIN_ROOT zsh -c ". '$UNSET_ROOT/scripts/resolve-wiki-scripts.sh'; resolve_wiki_scripts wiki-ingest" 2>&1); then
    case "$OUT" in
      */cogni-wiki/0.0.45/skills/wiki-ingest/scripts)
        green "PASS: zsh + unset CLAUDE_PLUGIN_ROOT resolves without aborting" ;;
      *)
        red "FAIL: zsh unset-env run produced unexpected output"
        red "  got: $OUT"; errors=$((errors + 1)) ;;
    esac
  else
    red "FAIL: zsh aborted with CLAUDE_PLUGIN_ROOT unset (the reported bug): $OUT"; errors=$((errors + 1))
  fi
else
  green "PASS: zsh not available on this host — zsh case skipped (bash case 7 covers the fallback)"
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "F26 resolve_wiki_scripts version-sort contract and behaviour all pass."
