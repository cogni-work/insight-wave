#!/usr/bin/env bash
# test_knowledge_setup_probe.sh - contract + behaviour tests for F1 and A4.
#
# F1 (knowledge-setup): the Step 0 probe handles both the dev-repo sibling
# layout (../<plugin>/skills/...) and the marketplace cache layout
# (../../<plugin>/<version>/skills/...).
#
# A4 (rollout): the same probe exists in every gating knowledge-* skill so a
# user who reaches one without setup gets the same clean abort.
#
# Post-M11 invariant: every live cogni-knowledge skill probes cogni-wiki ONLY.
# The v0.1.0 clean break (decision-1) makes cogni-research 0% of the runtime
# path. The read-side trio (query/dashboard/resume) flipped at M10a (v0.0.25);
# knowledge-refresh at M10b (v0.0.26); knowledge-setup at M11 (v0.0.27) when
# the legacy knowledge-research / knowledge-report skills were archived to
# _archive/. No live skill probes cogni-research or carries the "requires
# both" abort wording.
#
# This test:
#   1. For every live gating skill, asserts (positively) the probe_plugin()
#      function is defined, the cogni-wiki probe is invoked, and the
#      "requires cogni-wiki to be installed" abort wording is present; and
#      (negatively) that the cogni-research probe + "requires both" wording
#      are ABSENT (contract).
#   2. Executes the probe body against two synthetic layouts (dev-repo sibling
#      AND marketplace cache) and asserts both resolve cogni-wiki.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

# -----------------------------------------------------------------------------
# Part 1: contract-level — every gating skill probes cogni-wiki ONLY.
# -----------------------------------------------------------------------------

# Skills carrying a Step 0 plugin pre-flight. All probe cogni-wiki only.
WIKI_ONLY_PROBE_SKILLS=(
  knowledge-setup
  knowledge-query
  knowledge-dashboard
  knowledge-resume
  knowledge-refresh
)

assert_skill_probes_wiki_only() {
  local skill="$1"
  local skill_file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    red "FAIL: skill file not found: $skill_file"
    errors=$((errors + 1))
    return
  fi
  local bad=0
  # Must DEFINE the probe function (not merely mention the invocation line in
  # prose) — a stale `probe_plugin cogni-wiki wiki-setup` line in a comment
  # without the function body would be a dead gate.
  if ! grep -qE 'probe_plugin\(\) \{' "$skill_file"; then
    red "FAIL: $skill missing probe_plugin() function definition"
    bad=$((bad + 1))
  fi
  # Must invoke the cogni-wiki probe.
  if ! grep -qE 'probe_plugin cogni-wiki wiki-setup' "$skill_file"; then
    red "FAIL: $skill missing cogni-wiki probe"
    bad=$((bad + 1))
  fi
  # Must carry the POSITIVE abort wording for a missing cogni-wiki — otherwise
  # deleting the abort block would silently regress the clean-abort guarantee
  # (the behaviour F1/A4 exists to protect) without any test noticing.
  if ! grep -qE 'requires .cogni-wiki. to be installed' "$skill_file"; then
    red "FAIL: $skill missing 'requires cogni-wiki to be installed' abort wording"
    bad=$((bad + 1))
  fi
  # Must NOT carry the cogni-research probe or "requires both" wording.
  if grep -qE 'probe_plugin cogni-research' "$skill_file"; then
    red "FAIL: $skill still probes cogni-research (clean break requires wiki-only)"
    bad=$((bad + 1))
  fi
  if grep -qE 'requires both .cogni-wiki. and .cogni-research.' "$skill_file"; then
    red "FAIL: $skill still carries 'requires both' abort wording"
    bad=$((bad + 1))
  fi
  if [ $bad -eq 0 ]; then
    green "PASS: $skill probes cogni-wiki only + carries clean-abort wording"
  else
    errors=$((errors + bad))
  fi
}

for skill in "${WIKI_ONLY_PROBE_SKILLS[@]}"; do
  assert_skill_probes_wiki_only "$skill"
done

# -----------------------------------------------------------------------------
# Part 2: behaviour — the probe body resolves both layouts for cogni-wiki.
# -----------------------------------------------------------------------------

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Simulate dev-repo layout. CLAUDE_PLUGIN_ROOT points at
# $WORK/devrepo/cogni-knowledge; the sibling lives at $WORK/devrepo/cogni-wiki/.
mkdir -p "$WORK/devrepo/cogni-knowledge"
mkdir -p "$WORK/devrepo/cogni-wiki/skills/wiki-setup"
touch    "$WORK/devrepo/cogni-wiki/skills/wiki-setup/SKILL.md"

# Simulate marketplace cache layout. CLAUDE_PLUGIN_ROOT points at
# $WORK/cache/cogni-knowledge/0.0.27; the sibling lives at
# $WORK/cache/cogni-wiki/<version>/.
mkdir -p "$WORK/cache/cogni-knowledge/0.0.27"
mkdir -p "$WORK/cache/cogni-wiki/0.0.45/skills/wiki-setup"
touch    "$WORK/cache/cogni-wiki/0.0.45/skills/wiki-setup/SKILL.md"

# Canonical probe body - mirrors the SKILL.md verbatim (cogni-wiki only).
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
BASH
)

run_probe() {
  local cpr="$1"
  CLAUDE_PLUGIN_ROOT="$cpr" bash -c "$PROBE_BODY"
}

# Dev-repo case.
OUT=$(run_probe "$WORK/devrepo/cogni-knowledge")
if echo "$OUT" | grep -q "^wiki_ok$"; then
  green "PASS: probe resolves dev-repo sibling layout"
else
  red "FAIL: probe failed to resolve dev-repo siblings"
  red "  got:"; echo "$OUT" | sed 's/^/    /'
  errors=$((errors + 1))
fi

# Marketplace cache case.
OUT=$(run_probe "$WORK/cache/cogni-knowledge/0.0.27")
if echo "$OUT" | grep -q "^wiki_ok$"; then
  green "PASS: probe resolves marketplace cache layout"
else
  red "FAIL: probe failed to resolve marketplace cache siblings"
  red "  got:"; echo "$OUT" | sed 's/^/    /'
  errors=$((errors + 1))
fi

# Missing-plugin case - cogni-wiki absent.
mkdir -p "$WORK/missing_wiki/cogni-knowledge"
OUT=$(run_probe "$WORK/missing_wiki/cogni-knowledge")
if echo "$OUT" | grep -q "^wiki_missing$"; then
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
