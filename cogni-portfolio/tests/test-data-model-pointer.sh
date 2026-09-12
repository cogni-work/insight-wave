#!/usr/bin/env bash
# Acceptance suite for the canonical-data-model pointer contract.
#
# cogni-portfolio ships exactly one schema document: the canonical
# `references/data-model.md`. It used to ship a second, partial note file at
# `skills/portfolio-setup/references/data-model.md`; that file's content has since
# been migrated into canonical and the file deleted. These tests pin the resulting
# contract so the split does not silently regrow: nothing in the plugin may cite
# the old note path, a note file that reappears must announce that it is
# non-canonical, and canonical must never be trimmed back toward what the note held.
#
# Named acceptance tests:
#   test_no_file_cites_notes             nothing in the plugin cites the note file
#   test_notes_scope_declared            a reappearing note file declares itself non-canonical up front
#   test_canonical_keeps_lineage_fields  canonical keeps the lineage fields the notes omit
#   test_canonical_carries_migrated_prose canonical carries the six passages the notes held alone
#   test_canonical_carries_solution_commercials  canonical carries the solutions/packages commercial semantics
#
# Usage: bash cogni-portfolio/tests/test-data-model-pointer.sh [test_name ...]
#   No args -> run every test (the CI path). One or more names -> run only those
#   (used by the mutation harness to run a single assertion against a mutant).
#   An unknown name exits 2 rather than reporting green, so a stale mutation
#   recipe cannot pass while running zero assertions.
# Exits non-zero on any assertion failure.
#
# Scope note: the scan covers this plugin only. Frozen eval fixtures under the
#   sibling cogni-portfolio-evals/ still carry the old pointer by design — they
#   are point-in-time snapshots, and a repo-wide grep would fail a correct
#   implementation. Keeping the scan inside PLUGIN_DIR excludes them structurally
#   rather than by an exception list.
#
# Mutation recipe — the SHARED cogni-service harness, which classifies on the output
#   labels below. Replayable as written, from the repo root. The mutant must be a
#   documentation file, not a script: this suite asserts on documentation content, so
#   mutating a scripts/ file would leave every case green and prove nothing.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/compete/SKILL.md \
#     --expr 's#\$CLAUDE_PLUGIN_ROOT/references/data-model.md#$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md#' \
#     --test 'bash cogni-portfolio/tests/test-data-model-pointer.sh test_no_file_cites_notes' \
#     --case test_no_file_cites_notes
#   The expr re-introduces the citation the repoint removed, so the case goes red on
#   the mutant and green on HEAD.
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.
#
# Mutation recipe for test_canonical_carries_solution_commercials — same harness,
#   same rules, replayable as written from the repo root:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/references/data-model.md \
#     --expr 's#Resources required for delivery#Resources needed at delivery time#g' \
#     --test 'bash cogni-portfolio/tests/test-data-model-pointer.sh test_canonical_carries_solution_commercials' \
#     --case test_canonical_carries_solution_commercials
#   The expr rewrites one of the six migrated prose literals the case asserts, so the
#   case goes red on the mutant and green on HEAD. Pick a metacharacter-free target:
#   the harness feeds the expr to `perl -0pi`, where the dot in `subscription.model`
#   would be a wildcard rather than a literal.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-test failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CANONICAL="$PLUGIN_DIR/references/data-model.md"
SETUP_NOTES="$PLUGIN_DIR/skills/portfolio-setup/references/data-model.md"

# The citation path the repoint removed. Kept as one literal so a partial revert
# (a single file regrowing the old pointer) is caught as precisely as a full one.
MIRROR_PATH='skills/portfolio-setup/references/data-model.md'
# The bare H1 the note file shared byte-for-byte with canonical. That collision is
# what let ten skills cite the wrong file, so the note file must not carry it again.
BARE_H1='# cogni-portfolio Data Model Reference'

# Pre-flight, deliberately outside the case vocabulary: a bare abort, not fail(),
# so a missing canonical file cannot surface to the mutation harness as an
# unmatched case label.
if [ ! -f "$CANONICAL" ]; then
  printf 'canonical reference not found at %s\n' "$CANONICAL" >&2
  exit 1
fi

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one "<case>: <msg>" string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

test_no_file_cites_notes() {
  # A scan that reads nothing would report "no offenders" and go green having
  # proved nothing — and the mutation recipe would then be green on both HEAD and
  # the mutant with no visible signal. Assert the scan surface is non-empty first.
  local scanned
  scanned="$(find "$PLUGIN_DIR" -name '*.md' -type f | wc -l | tr -d ' ')"
  if [ "$scanned" -eq 0 ]; then
    fail test_no_file_cites_notes "scanned no markdown files; scan surface is broken"
    return
  fi
  # Scan the whole plugin, not just skills/*/SKILL.md: the agents under agents/
  # are what actually write these entity files, and references/, README.md and
  # CLAUDE.md can regrow the pointer just as easily. tests/ is excluded because
  # this suite names the path as a literal.
  local offenders
  offenders="$(grep -rlF "$MIRROR_PATH" "$PLUGIN_DIR" --exclude-dir=tests 2>/dev/null \
    | sed "s|^$PLUGIN_DIR/||" | sort | tr '\n' ' ')"
  if [ -n "$offenders" ]; then
    fail test_no_file_cites_notes "files still citing the non-canonical notes: $offenders"
    return
  fi
  pass test_no_file_cites_notes "no file in the plugin cites the non-canonical notes ($scanned scanned)"
}

test_notes_scope_declared() {
  # The note file may legitimately be deleted outright — nothing cites it once the
  # repoint lands. Only assert the scoping contract when the file is still present.
  if [ ! -f "$SETUP_NOTES" ]; then
    pass test_notes_scope_declared "note file removed; nothing to scope"
    return
  fi
  local head10 first
  head10="$(head -10 "$SETUP_NOTES")"
  first="${head10%%$'\n'*}"
  if [ "$first" = "$BARE_H1" ]; then
    fail test_notes_scope_declared "note file still carries canonical's bare H1"
    return
  fi
  if ! printf '%s' "$head10" | grep -qF 'references/data-model.md'; then
    fail test_notes_scope_declared "no canonical pointer within the first 10 lines"
    return
  fi
  pass test_notes_scope_declared "note file declares itself non-canonical up front"
}

test_canonical_keeps_lineage_fields() {
  # Guards the inverse fix: closing the drift by trimming canonical down to match
  # the notes would corrupt the source of truth the repoint just pointed everyone at.
  local line missing="" field
  line="$(grep -m1 '^Optional fields: `positioning`' "$CANONICAL" || true)"
  if [ -z "$line" ]; then
    fail test_canonical_keeps_lineage_fields "products Optional-fields line not found in canonical"
    return
  fi
  for field in shared_solution source_refs lineage_status; do
    printf '%s' "$line" | grep -qF "$field" || missing="$missing $field"
  done
  if [ -n "$missing" ]; then
    fail test_canonical_keeps_lineage_fields "products Optional-fields line dropped:$missing"
    return
  fi
  pass test_canonical_keeps_lineage_fields "canonical keeps the lineage fields the notes omit"
}

test_canonical_carries_migrated_prose() {
  # Six passages lived only in the note file. Once nothing reads that file,
  # prose left there is unreachable — so canonical must carry it instead. Each
  # literal is one the notes held and canonical did not, so each can actually
  # detect a missing migration rather than passing on text canonical already had.
  # Prefer format literals over sentence fragments where one exists: canonical is
  # a live target for prose-editing passes, and an assertion on wording churns.
  #
  # The last three guard schema facts a skill actively gates on, so canonical
  # dropping any of them puts it in direct contradiction with the skill citing it:
  # packages/SKILL.md declares `solution_sizes` required on every tier and gates on
  # it, recommends `exclusions`, and solutions/SKILL.md lists `implementation` as
  # optional on hybrid where canonical's table alone would read "not part of the
  # schema". Each occurred zero times in canonical before the migration, so all
  # three discriminate.
  local missing="" literal
  for literal in '{domain}/{language}' 'coverage heatmap' 'CAC, LTV, churn' \
                 'solution_sizes' 'exclusions' 'reduced `implementation` block'; do
    grep -qF "$literal" "$CANONICAL" || missing="$missing [$literal]"
  done
  if [ -n "$missing" ]; then
    fail test_canonical_carries_migrated_prose "canonical missing migrated prose:$missing"
    return
  fi
  pass test_canonical_carries_migrated_prose "canonical carries all six migrated passages"
}

test_canonical_carries_solution_commercials() {
  # The second migration wave: the solutions cost_model / subscription / partnership
  # field semantics and the packages tier-requirement prose, which lived only in the
  # note file until it was deleted. Same discipline as the case above — every literal
  # here occurred zero times in canonical beforehand, so each one can actually detect
  # a missing migration.
  #
  # Deliberately NOT asserted: `bill_of_materials`, `effort_by_tier`, `unit_economics`,
  # `margin_pct` and `tiered`. All five already appeared inside canonical's JSON
  # example fences before this migration, so a case built on them would report green
  # while the prose field docs were still absent — the exact rubber-stamp this suite
  # exists to avoid. The literals below appear only in prose, so they discriminate.
  local missing="" literal
  for literal in 'Resources required for delivery' '(price - internal_cost) / price * 100' \
                 'LTV/CAC ratio' 'subscription.model' 'program.revenue_share' \
                 'Each tier requires'; do
    grep -qF "$literal" "$CANONICAL" || missing="$missing [$literal]"
  done
  if [ -n "$missing" ]; then
    fail test_canonical_carries_solution_commercials "canonical missing commercial semantics:$missing"
    return
  fi
  pass test_canonical_carries_solution_commercials "canonical carries the solutions/packages commercial semantics"
}

ALL_TESTS="test_no_file_cites_notes test_notes_scope_declared test_canonical_keeps_lineage_fields test_canonical_carries_migrated_prose test_canonical_carries_solution_commercials"

# Reject an unknown case name instead of letting bash's "command not found" pass
# through: with no `set -e` and no failures increment, an unrecognised name would
# otherwise print "All tests passed." having run nothing at all.
run_one() {
  case " $ALL_TESTS " in
    *" $1 "*) "$1" ;;
    *) printf 'unknown test %s\n' "$1" >&2; exit 2 ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for t in "$@"; do run_one "$t"; done
else
  for t in $ALL_TESTS; do "$t"; done
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
