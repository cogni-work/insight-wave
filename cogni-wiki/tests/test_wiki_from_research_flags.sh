#!/usr/bin/env bash
# test_wiki_from_research_flags.sh — contract-level grep tests for the
# wiki-from-research SKILL.md invariants that landed in v0.0.40 (#264 Phase 2).
#
# wiki-from-research is a pure LLM skill — there is no script to execute, so
# behaviour-level tests are impossible. Instead, these greps catch the most
# likely regression class: someone reverts a SKILL.md path or flag, the
# downstream cogni-knowledge:knowledge-report skill silently breaks, and the
# failure only surfaces during a live Phase 4 alpha run.
#
# Asserted invariants:
#   1. --allow-wiki-source flag row exists, scoped to Mode A & Mode B.
#   2. --cycle-guard-cleared flag row exists, scoped to Mode A & Mode B.
#   3. Step 0(3) conditional refuses report_source ∈ {wiki, hybrid} unless
#      BOTH --allow-wiki-source AND --cycle-guard-cleared are passed.
#   4. Step 1d re-applies the same conditional (Mode A post-research-setup).
#   5. Project-config read path is .metadata/project-config.json
#      (NOT the pre-v0.0.40 stale `<project>/project-config.json`).
#
# bash 3.2 + stdlib only. Exit non-zero on any missing invariant.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$PLUGIN_ROOT/skills/wiki-from-research/SKILL.md"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SKILL" ]; then
  red "FAIL: skill file not found at $SKILL"
  exit 1
fi

errors=0
assert_grep() {
  local pattern="$1"
  local description="$2"
  if grep -qE "$pattern" "$SKILL"; then
    green "PASS: $description"
  else
    red "FAIL: MISSING: $description"
    red "      pattern: $pattern"
    errors=$((errors + 1))
  fi
}

# 1. Flag rows in the parameter table — scoped to Mode A & Mode B.
assert_grep '\| `--allow-wiki-source` \| No \| Mode A & Mode B\.' \
  "--allow-wiki-source row in parameter table (Mode A & Mode B)"
assert_grep '\| `--cycle-guard-cleared` \| No \| Mode A & Mode B\.' \
  "--cycle-guard-cleared row in parameter table (Mode A & Mode B)"

# 2. Step 0(3) — conditional abort lifts when both flags are passed.
#    `∈` is a literal UTF-8 byte sequence (E2 88 88); grep -E does not interpret
#    `\xNN` escapes, so embed the character directly.
assert_grep \
  'report_source ∈ \{wiki, hybrid\}.*AND NOT \(`--allow-wiki-source` AND `--cycle-guard-cleared` both passed\)' \
  "Step 0(3) report_source ∈ {wiki,hybrid} guard with flag-pair lift"

# 3. Step 1d — same re-check after research-setup resolves the actual slug.
assert_grep '1d\.' \
  "Step 1d exists"
assert_grep '1d\..*Re-run Step 0' \
  "Step 1d re-runs Step 0 checks against the resolved slug"

# 4. Post-v0.0.40 project-config path (the v0.0.39 path was the bare
#    `<project>/project-config.json` form which is now stale).
assert_grep '\.metadata/project-config\.json' \
  "post-v0.0.40 project-config read path (.metadata/ subdir)"
if grep -qE '<project>/project-config\.json' "$SKILL"; then
  red "FAIL: REGRESSION: stale pre-v0.0.40 path '<project>/project-config.json' is back"
  errors=$((errors + 1))
else
  green "PASS: stale pre-v0.0.40 path '<project>/project-config.json' is absent"
fi

# 5. Orchestrator-callable usage hint — at least one mention of cogni-knowledge
#    in the flag context, so the rationale ("exists for orchestrators") survives
#    casual edits.
assert_grep 'cogni-knowledge:knowledge-report' \
  "orchestrator rationale (cogni-knowledge:knowledge-report mention)"

# 6. Migration exit state: zero `cogni-research:` dispatches.
#    The skill is deprecated in favour of cogni-knowledge's inverted pipeline;
#    it must no longer carry any `cogni-research:` namespace reference (the
#    dispatch slug form) so the repo-wide zero-`cogni-research:`-dispatch
#    guard and the migration exit audit stay green.
if grep -qE 'cogni-research:' "$SKILL"; then
  red "FAIL: REGRESSION: a 'cogni-research:' dispatch/namespace reference is back"
  red "      (the deprecation requires zero 'cogni-research:' occurrences)"
  errors=$((errors + 1))
else
  green "PASS: zero 'cogni-research:' dispatch/namespace references (migration exit state)"
fi

# 7. Deprecation notice present and points users at cogni-knowledge.
assert_grep '[Dd]eprecated' \
  "deprecation notice present"
assert_grep 'cogni-knowledge:knowledge-setup' \
  "redirect to cogni-knowledge inverted pipeline (knowledge-setup entry point)"

if [ $errors -gt 0 ]; then
  red "$errors invariant(s) missing — see lines above."
  exit 1
fi

green ""
green "All wiki-from-research contract invariants present."
