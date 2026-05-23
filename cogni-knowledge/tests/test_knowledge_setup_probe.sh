#!/usr/bin/env bash
# test_knowledge_setup_probe.sh - contract + behaviour tests for F1 and A4.
#
# F1 (knowledge-setup): the Step 0 probe handles both the dev-repo sibling
# layout (../<plugin>/skills/...) and the marketplace cache layout
# (../../<plugin>/<version>/skills/...).
#
# A4 (rollout): the same probe exists in the other knowledge-* skills so a
# user who reaches any of them without setup gets the same clean abort.
#
# M10a (v0.0.25) clean-break split: the read-side skills (query, dashboard,
# resume) dispatch ONLY cogni-wiki, so they probe cogni-wiki only and drop the
# cogni-research probe + "requires both" wording (decision-1: cogni-research is
# 0% of the v0.1.0 runtime path). The legacy chain skills (setup, research,
# report, refresh) still probe both — refresh flips to wiki-only at M10b.
#
# This test:
#   1. Greps the both-probe skills for the cogni-wiki + cogni-research probes
#      and the "requires both" abort wording (contract-level).
#   2. Greps the wiki-only skills for the cogni-wiki probe and asserts the
#      cogni-research probe + "requires both" wording are ABSENT.
#   3. Executes the probe body against two synthetic layouts (dev-repo
#      sibling AND marketplace cache) and asserts both resolve.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

# -----------------------------------------------------------------------------
# Part 1: contract-level — every knowledge-* skill carries the probe.
# -----------------------------------------------------------------------------

# Legacy-chain skills still gate on both cogni-wiki + cogni-research.
# (refresh flips to wiki-only at M10b.)
BOTH_PROBE_SKILLS=(
  knowledge-setup
  knowledge-research
  knowledge-report
  knowledge-refresh
)

# Read-side skills dispatch only cogni-wiki (M10a clean-break split).
WIKI_ONLY_PROBE_SKILLS=(
  knowledge-query
  knowledge-dashboard
  knowledge-resume
)

assert_skill_probes_both() {
  local skill="$1"
  local skill_file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    red "FAIL: skill file not found: $skill_file"
    errors=$((errors + 1))
    return
  fi
  local missing=0
  for pattern in \
    'probe_plugin\(\) \{' \
    'probe_plugin cogni-wiki wiki-setup' \
    'probe_plugin cogni-research research-setup' \
    'requires both .cogni-wiki. and .cogni-research.'
  do
    if ! grep -qE "$pattern" "$skill_file"; then
      red "FAIL: $skill missing pattern: $pattern"
      missing=$((missing + 1))
    fi
  done
  if [ $missing -eq 0 ]; then
    green "PASS: $skill carries the both-plugin probe and abort wording"
  else
    errors=$((errors + missing))
  fi
}

assert_skill_probes_wiki_only() {
  local skill="$1"
  local skill_file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    red "FAIL: skill file not found: $skill_file"
    errors=$((errors + 1))
    return
  fi
  local bad=0
  # Must keep the cogni-wiki probe.
  if ! grep -qE 'probe_plugin cogni-wiki wiki-setup' "$skill_file"; then
    red "FAIL: $skill missing cogni-wiki probe"
    bad=$((bad + 1))
  fi
  # Must NOT carry the cogni-research probe or "requires both" wording.
  if grep -qE 'probe_plugin cogni-research' "$skill_file"; then
    red "FAIL: $skill still probes cogni-research (M10a clean break requires wiki-only)"
    bad=$((bad + 1))
  fi
  if grep -qE 'requires both .cogni-wiki. and .cogni-research.' "$skill_file"; then
    red "FAIL: $skill still carries 'requires both' abort wording"
    bad=$((bad + 1))
  fi
  if [ $bad -eq 0 ]; then
    green "PASS: $skill probes cogni-wiki only (clean break)"
  else
    errors=$((errors + bad))
  fi
}

for skill in "${BOTH_PROBE_SKILLS[@]}"; do
  assert_skill_probes_both "$skill"
done

for skill in "${WIKI_ONLY_PROBE_SKILLS[@]}"; do
  assert_skill_probes_wiki_only "$skill"
done

# -----------------------------------------------------------------------------
# Part 2: behaviour — the probe body resolves both layouts.
# -----------------------------------------------------------------------------

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Simulate dev-repo layout. CLAUDE_PLUGIN_ROOT points at
# $WORK/devrepo/cogni-knowledge; siblings live at $WORK/devrepo/<plugin>/.
mkdir -p "$WORK/devrepo/cogni-knowledge"
mkdir -p "$WORK/devrepo/cogni-wiki/skills/wiki-setup"
mkdir -p "$WORK/devrepo/cogni-research/skills/research-setup"
touch    "$WORK/devrepo/cogni-wiki/skills/wiki-setup/SKILL.md"
touch    "$WORK/devrepo/cogni-research/skills/research-setup/SKILL.md"

# Simulate marketplace cache layout. CLAUDE_PLUGIN_ROOT points at
# $WORK/cache/cogni-knowledge/0.0.14; siblings live at
# $WORK/cache/<plugin>/<version>/.
mkdir -p "$WORK/cache/cogni-knowledge/0.0.14"
mkdir -p "$WORK/cache/cogni-wiki/0.0.43/skills/wiki-setup"
mkdir -p "$WORK/cache/cogni-research/0.8.0/skills/research-setup"
touch    "$WORK/cache/cogni-wiki/0.0.43/skills/wiki-setup/SKILL.md"
touch    "$WORK/cache/cogni-research/0.8.0/skills/research-setup/SKILL.md"

# Canonical probe body - mirrors the SKILL.md verbatim.
PROBE_BODY=$(cat <<'BASH'
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && echo wiki_ok || echo wiki_missing
probe_plugin cogni-research research-setup && echo research_ok || echo research_missing
BASH
)

run_probe() {
  local cpr="$1"
  CLAUDE_PLUGIN_ROOT="$cpr" bash -c "$PROBE_BODY"
}

# Dev-repo case.
OUT=$(run_probe "$WORK/devrepo/cogni-knowledge")
if echo "$OUT" | grep -q "^wiki_ok$" && echo "$OUT" | grep -q "^research_ok$"; then
  green "PASS: probe resolves dev-repo sibling layout"
else
  red "FAIL: probe failed to resolve dev-repo siblings"
  red "  got:"; echo "$OUT" | sed 's/^/    /'
  errors=$((errors + 1))
fi

# Marketplace cache case.
OUT=$(run_probe "$WORK/cache/cogni-knowledge/0.0.14")
if echo "$OUT" | grep -q "^wiki_ok$" && echo "$OUT" | grep -q "^research_ok$"; then
  green "PASS: probe resolves marketplace cache layout"
else
  red "FAIL: probe failed to resolve marketplace cache siblings"
  red "  got:"; echo "$OUT" | sed 's/^/    /'
  errors=$((errors + 1))
fi

# Missing-plugin case - cogni-wiki absent, cogni-research present.
mkdir -p "$WORK/missing_wiki/cogni-knowledge"
mkdir -p "$WORK/missing_wiki/cogni-research/skills/research-setup"
touch    "$WORK/missing_wiki/cogni-research/skills/research-setup/SKILL.md"
OUT=$(run_probe "$WORK/missing_wiki/cogni-knowledge")
if echo "$OUT" | grep -q "^wiki_missing$" && echo "$OUT" | grep -q "^research_ok$"; then
  green "PASS: probe correctly reports cogni-wiki missing"
else
  red "FAIL: probe did not detect cogni-wiki missing"
  red "  got:"; echo "$OUT" | sed 's/^/    /'
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors invariant(s)/case(s) failed."
  exit 1
fi

green ""
green "F1 + A4 probe contract and behaviour all pass."
