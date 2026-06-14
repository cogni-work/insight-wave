#!/usr/bin/env bash
# test_knowledge_setup_probe.sh - contract tests for knowledge-setup's
# self-containment (the cogni-wiki parity gate).
#
# History: knowledge-setup was the ONE skill that still gated on cogni-wiki being
# installed — it bootstrapped the wiki via cogni-wiki:wiki-setup, so it probed
# cogni-wiki and aborted with "requires cogni-wiki to be installed" when absent.
# That was the last runtime cogni-wiki skill dispatch in the plugin (the
# read/render/lint/resweep paths re-homed earlier at ~v0.1.84-0.1.98).
#
# The parity-gate re-home replaced the Step 3 cogni-wiki:wiki-setup dispatch with
# an inline native scaffold (mkdir skeleton + a python3-written
# .cogni-wiki/config.json; Step 3.5 still curates the layout + bumps schema 0.0.7
# -> 0.0.9 via the vendored config_bump.py). So knowledge-setup now needs NO
# cogni-wiki install, carries NO probe gate, and dispatches ZERO cogni-wiki
# skills. This test guards that self-contained posture — the inverse of what the
# old probe-contract test asserted.
#
# The repo-wide zero-cogni-wiki-dispatch canary lives in test_skill_contracts.sh.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$PLUGIN_ROOT/skills/knowledge-setup/SKILL.md"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

if [ ! -f "$SETUP" ]; then
  red "FAIL: skills/knowledge-setup/SKILL.md not found"
  exit 1
fi

# --- knowledge-setup is self-contained (no cogni-wiki gate) ------------------

# Negative: the Step 0 hard gate is gone — no probe_plugin function, no
# cogni-wiki probe invocation, no "requires cogni-wiki to be installed" abort.
if grep -qE 'probe_plugin\(\) \{' "$SETUP"; then
  red "FAIL: knowledge-setup still defines the cogni-wiki probe_plugin() gate (re-home removed it)"
  errors=$((errors + 1))
else
  green "PASS: knowledge-setup carries no probe_plugin() gate"
fi

if grep -qE 'probe_plugin cogni-wiki wiki-setup' "$SETUP"; then
  red "FAIL: knowledge-setup still invokes the cogni-wiki probe"
  errors=$((errors + 1))
else
  green "PASS: knowledge-setup does not probe cogni-wiki"
fi

if grep -qE 'requires .cogni-wiki. to be installed' "$SETUP"; then
  red "FAIL: knowledge-setup still carries the 'requires cogni-wiki to be installed' abort"
  errors=$((errors + 1))
else
  green "PASS: knowledge-setup drops the 'requires cogni-wiki' hard gate"
fi

# Negative: no runtime cogni-wiki skill dispatch (the parity gate).
if grep -qE 'Skill\("?cogni-wiki:' "$SETUP"; then
  red "FAIL: knowledge-setup still dispatches a cogni-wiki skill:"
  grep -nE 'Skill\("?cogni-wiki:' "$SETUP"
  errors=$((errors + 1))
else
  green "PASS: knowledge-setup dispatches zero cogni-wiki skills"
fi

# Positive: the native scaffold is present (mkdir skeleton + config.json write).
if grep -qE 'mkdir -p' "$SETUP" && grep -qF '.cogni-wiki/config.json' "$SETUP"; then
  green "PASS: knowledge-setup scaffolds the wiki skeleton + config natively"
else
  red "FAIL: knowledge-setup is missing the native wiki scaffold (mkdir + .cogni-wiki/config.json)"
  errors=$((errors + 1))
fi

if grep -qF '"schema_version": "0.0.7"' "$SETUP"; then
  green "PASS: knowledge-setup seeds config schema_version 0.0.7 (Step 3.5 bumps to 0.0.9)"
else
  red "FAIL: knowledge-setup config scaffold does not seed schema_version 0.0.7"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors invariant(s) failed."
  exit 1
fi

green ""
green "knowledge-setup self-containment (cogni-wiki parity gate) contract: ALL PASS"
