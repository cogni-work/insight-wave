#!/usr/bin/env bash
# test_prose_density_contract.sh — #309 P2.1 + P2.4 cross-cutting contract.
#
# The prose-density knob spans three files (composer drafting discipline,
# compose dispatch threading, reviewer advisory Word Count Gate). This file is
# the single regression guard that the standard-floor / executive-ceiling
# contract stays intact end-to-end — and, critically, that it never grows an
# expansion LOOP (the composer stays single-pass; the floor/ceiling is advisory).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

COMPOSER="$PLUGIN_ROOT/agents/wiki-composer.md"
COMPOSE="$PLUGIN_ROOT/skills/knowledge-compose/SKILL.md"
REVIEWER="$PLUGIN_ROOT/agents/wiki-reviewer.md"

for f in "$COMPOSER" "$COMPOSE" "$REVIEWER"; do
  if [ ! -f "$f" ]; then
    red "FAIL: required file not found: $f"
    exit 1
  fi
done

# --- composer: standard soft-budget vs executive ceiling, single pass ----
# Brevity-first retune: standard treats TARGET_WORDS as a soft UPPER BUDGET (not a
# floor), so the outline budgets to ≤ TARGET_WORDS with no 5% headroom and never pads.
assert_grep 'soft upper budget' "$COMPOSER" "wiki-composer: standard treats TARGET_WORDS as a soft upper budget (not a floor)"
assert_grep 'ceiling' "$COMPOSER" "wiki-composer: names the executive-density ceiling"
assert_grep 'no headroom' "$COMPOSER" "wiki-composer: executive outline budgets to a ceiling (no headroom)"
assert_grep 'sum(budgets) ≤ TARGET_WORDS' "$COMPOSER" "wiki-composer: standard outline budgets to ≤ TARGET_WORDS (no quota padding)"
assert_not_grep '× 1.05' "$COMPOSER" "wiki-composer: no 5% floor headroom remains (brevity-first retune)"
# The self-check must branch but explicitly NEVER loop.
assert_grep 'NEVER loop\|never loops\|no re-dispatch loop\|there is no re-dispatch loop' "$COMPOSER" "wiki-composer: the word-count self-check shapes ONE pass, never loops (#309 P2.4)"
assert_grep 'Over ceiling\|over .TARGET_WORDS. (the ceiling)\|over the ceiling\|trim .*redundancy' "$COMPOSER" "wiki-composer: executive trims redundancy when over the ceiling"
# The single-pass invariant in the NOT-list must survive the density knob.
assert_grep 'Does NOT iterate on word-count shortfall\|does NOT re-dispatch' "$COMPOSER" "wiki-composer: NOT-list keeps the single-pass / no-re-dispatch invariant"

# --- compose: threads PROSE_DENSITY + TARGET_WORDS, density-aware summary -
# Brevity-first: standard NO LONGER warns "Below target" (under-budget is the
# intended outcome); it surfaces a coverage line instead. executive keeps over-ceiling.
assert_grep 'PROSE_DENSITY=' "$COMPOSE" "knowledge-compose: threads PROSE_DENSITY into the composer dispatch"
assert_not_grep 'Below target' "$COMPOSE" "knowledge-compose: no standard under-budget warning (brevity is the intended outcome)"
assert_grep 'coverage:' "$COMPOSE" "knowledge-compose: standard surfaces a coverage line, not a word warning"
assert_grep 'Over ceiling' "$COMPOSE" "knowledge-compose: executive over-ceiling warning"
# Coverage-gated expansion now fires under executive too (ceiling-bounded). The
# Step 5.5 actuator must reach executive runs, and the wiki/log Expansion summary
# line must no longer be omitted on every non-standard density run.
assert_grep 'standard or executive density' "$COMPOSE" "knowledge-compose: Step 5.5 Expansion summary line emits under standard OR executive density"
assert_not_grep "omit the line on a non-.standard. density run" "$COMPOSE" "knowledge-compose: the Expansion line is no longer omitted on every non-standard density run"

# --- reviewer: advisory Word Count Gate — brevity-neutral, no loop --------
assert_grep 'Word Count Gate (advisory)\|advisory Word Count Gate' "$REVIEWER" "wiki-reviewer: has an advisory Word Count Gate"
assert_grep 'Possible truncated draft' "$REVIEWER" "wiki-reviewer: standard caps only a likely-truncated draft (not brevity)"
assert_not_grep 'Word deficit' "$REVIEWER" "wiki-reviewer: no Word deficit penalty (brevity-first retune)"
assert_grep 'Word excess' "$REVIEWER" "wiki-reviewer: executive excess emits Word excess"
# Representative thresholds: the executive >1.25 excess tier and the standard <0.50 truncation tier.
assert_grep '1.25' "$REVIEWER" "wiki-reviewer: gate has the >1.25 excess tier"
assert_grep '0.50' "$REVIEWER" "wiki-reviewer: gate has the <0.50 truncation tier"
# The cap targets Completeness, NOT Depth (Depth is the density gate's job).
assert_grep 'cap.*Completeness\|caps Completeness\|Completeness.*cap\|applied_completeness_cap' "$REVIEWER" "wiki-reviewer: Word Count Gate caps Completeness"
# Hard invariant: advisory only — no expansion loop, never blocks finalize.
assert_grep 'no expansion loop\|never gates finalize\|never blocks\|advisory only\|drives no\|drives NO' "$REVIEWER" "wiki-reviewer: Word Count Gate is advisory — no expansion loop, never blocks"

# allow_short must NOT be a live input parameter (it only made sense against the
# upstream expansion loop). The reviewer prose legitimately EXPLAINS why it is
# not ported, so we assert it is not a `| `allow_short` |` parameter-table row.
if grep -q "| \`allow_short\` |\|allow_short.*input parameter\|takes.*allow_short" "$REVIEWER"; then
  red "FAIL: wiki-reviewer: allow_short must not be a live input (no upstream loop to short-circuit)"
  errors=$((errors + 1))
else
  green "PASS: wiki-reviewer: allow_short is not a live input parameter (not ported)"
fi
assert_grep 'allow_short.*not ported\|allow_short. is not ported\|not ported' "$REVIEWER" "wiki-reviewer: documents that allow_short is intentionally not ported"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
