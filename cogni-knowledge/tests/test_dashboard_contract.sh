#!/usr/bin/env bash
# test_dashboard_contract.sh — contract assertions for the v0.1.16 (#337)
# knowledge-dashboard verification-scope honesty surfacing.
#
# Per tests/README.md §"Contract tests": knowledge-dashboard is a pure LLM
# orchestrator (it dispatches cogni-wiki:wiki-dashboard and composes a sidecar),
# so regression coverage is SKILL.md content invariants. These catch the
# verification-scope block, the last-resweep read, or the resweep suggestion
# silently disappearing from the contract.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

DASH="$PLUGIN_ROOT/skills/knowledge-dashboard/SKILL.md"
if [ ! -f "$DASH" ]; then
  red "FAIL: skills/knowledge-dashboard/SKILL.md not found"
  exit 1
fi

# --- 1) The verification block is renamed to name the scope honestly -------
assert_grep '## Claim verification scope' "$DASH" "knowledge-dashboard: §2 renames the heatmap block to 'Claim verification scope' (#337)"
# The old heatmap heading must be gone (a rename, not an addition).
assert_not_grep '## Claim verification heatmap' "$DASH" "knowledge-dashboard: dropped the old 'Claim verification heatmap' heading (#337)"

# --- 2) The scope paragraph names the citation-consistent / zero-network --
# semantics (accept either the snake_case enum or the hyphenated prose form).
if grep -qE 'citation.consistent|citation_consistent' "$DASH"; then
  green "PASS: knowledge-dashboard: names citation-consistent verification semantics (#337)"
else
  red "FAIL: knowledge-dashboard: must name citation-consistent verification semantics (#337)"
  errors=$((errors + 1))
fi
assert_grep 'zero-network' "$DASH" "knowledge-dashboard: names the zero-network (no live-source re-check) cost win (#337)"

# --- 3) The last-resweep cadence is read + surfaced ------------------------
assert_grep 'last-resweep.json' "$DASH" "knowledge-dashboard: reads <wiki_path>/.cogni-wiki/last-resweep.json (#337)"
assert_grep 'never' "$DASH" "knowledge-dashboard: renders 'never' when no resweep has run (#337)"
assert_grep 'Last live-source resweep' "$DASH" "knowledge-dashboard: short summary surfaces the Last live-source resweep line (#337)"

# --- 4) The opt-in resweep path is suggested -------------------------------
assert_grep 'knowledge-refresh --resweep' "$DASH" "knowledge-dashboard: suggests knowledge-refresh --resweep as the opt-in refresh path (#337)"

# --- 5) Edge case + Out of scope -------------------------------------------
assert_grep 'no resweep ever run on this base' "$DASH" "knowledge-dashboard: Edge cases document the missing-last-resweep.json case (#337)"
# The dashboard must NOT dispatch the (expensive) resweep itself.
assert_not_grep 'Skill("cogni-wiki:wiki-claims-resweep"' "$DASH" "knowledge-dashboard: does NOT dispatch wiki-claims-resweep itself (cheap-and-frequent contract, #337)"

# --- 6) Verification-scope semantics named ---------------------------------
assert_grep 'citation-consistent' "$DASH" "knowledge-dashboard: names citation-consistent verification semantics"

# --- 7) Existing surfaces survive (regression guard) -----------------------
assert_grep 'pipeline-summary.py' "$DASH" "knowledge-dashboard: still reads pipeline-summary.py per project"
assert_grep 'knowledge-overlay.md' "$DASH" "knowledge-dashboard: still writes the knowledge-overlay.md sidecar"

# --- 8) Seed-theme backlog is read open-MINUS-covered, not raw (#450) -------
# The dashboard must call the themes subcommand and drive Seed themes from
# open_active, so a researched seed drops off instead of rendering stale.
assert_grep 'knowledge-binding.py themes' "$DASH" "knowledge-dashboard: reads the still-open backlog via knowledge-binding.py themes (#450)"
assert_grep 'open_active' "$DASH" "knowledge-dashboard: drives Seed themes from open_active (open minus researched, #450)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
