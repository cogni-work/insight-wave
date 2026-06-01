#!/usr/bin/env bash
# test_prelim_search_contract.sh — #382 preliminary/scoping search contract.
#
# Ports cogni-research's Phase-0.5 preliminary search into knowledge-plan as an
# opt-in, fail-soft scan folded into the Step 0.4 topic-framing pass. This file
# is the single regression guard that the scan stays:
#   - opt-in (rides framing's engage decision, --no-prelim-search opts out),
#   - fail-soft (any error → pure-reasoning path),
#   - web-bounded (WebSearch only; WebFetch is still forbidden), and
#   - documented in both the skill and the topic-framing playbook.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

PLAN="$PLUGIN_ROOT/skills/knowledge-plan/SKILL.md"
FRAMING="$PLUGIN_ROOT/references/topic-framing.md"

for f in "$PLAN" "$FRAMING"; do
  if [ ! -f "$f" ]; then
    red "FAIL: required file not found: $f"
    exit 1
  fi
done

# --- knowledge-plan: WebSearch enabled, scan is opt-in + fail-soft ---------
assert_grep 'allowed-tools:.*WebSearch' "$PLAN" "knowledge-plan: allowed-tools includes WebSearch"
assert_grep 'reliminary scoping scan' "$PLAN" "knowledge-plan: documents the preliminary scoping scan"
assert_grep 'no-prelim-search' "$PLAN" "knowledge-plan: --no-prelim-search opt-out is documented"
assert_grep '[Ff]ail-soft' "$PLAN" "knowledge-plan: the scan is fail-soft"
assert_grep 'rides framing' "$PLAN" "knowledge-plan: the scan rides framing's engage decision (opt-in, no new decision point)"
# The scan must not fire on the non-interactive paths — one stable phrase anchors
# the whole "sharp topic / --no-framing / --dry-run" sentence (--no-prelim-search
# is asserted separately above).
assert_grep 'never runs on a sharp topic' "$PLAN" "knowledge-plan: the scan never fires on a sharp topic / --no-framing / --dry-run"

# --- the WebSearch loosening must NOT erode the WebFetch ban ---------------
# Out of scope used to flatly forbid both; it now allows the opt-in scan but
# keeps WebFetch forbidden outright.
assert_not_grep 'Does NOT call WebSearch or WebFetch' "$PLAN" "knowledge-plan: the flat 'no WebSearch or WebFetch' forbiddance is replaced (scan is now allowed)"
# Match the semantic contract, not the markdown emphasis, so a reword that drops
# the bold doesn't silently break the guard.
assert_grep 'WebSearch.*by default' "$PLAN" "knowledge-plan: WebSearch is forbidden only by default (the scan is the exception)"
assert_grep '[Nn]ever.*calls WebFetch' "$PLAN" "knowledge-plan: WebFetch is still forbidden outright"

# --- topic-framing playbook: the scan move is wired in ---------------------
assert_grep 'Step 0.2b' "$FRAMING" "topic-framing: has the Step 0.2b preliminary scan move"
assert_grep 'ground.*scan.*sharpen' "$FRAMING" "topic-framing: spine updated to ground → scan → sharpen"
assert_grep '[Pp]reliminary scoping scan' "$FRAMING" "topic-framing: names the preliminary scoping scan"
assert_grep 'no-prelim-search' "$FRAMING" "topic-framing: documents the --no-prelim-search opt-out"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
