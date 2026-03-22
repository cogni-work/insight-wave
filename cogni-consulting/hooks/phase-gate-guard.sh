#!/usr/bin/env bash
# Phase gate guard hook — warns if prerequisites are incomplete.
# Runs as a PreToolUse hook on Skill invocations.
# Advisory only: returns warnings, never blocks execution.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract skill name from the tool input
SKILL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tool_input = data.get('tool_input', {})
    skill = tool_input.get('skill', '')
    print(skill)
except:
    print('')
" 2>/dev/null || echo "")

# Only check diamond phase skills
case "$SKILL_NAME" in
  consulting-discover|consulting-define|consulting-develop|consulting-deliver)
    ;;
  *)
    # Not a diamond phase skill — pass through
    exit 0
    ;;
esac

# Find consulting-project.json in current workspace
PROJECT_JSON=$(find . -maxdepth 3 -name "consulting-project.json" -path "*/cogni-consulting/*" 2>/dev/null | head -1)

if [ -z "$PROJECT_JSON" ]; then
  # No engagement found — let setup handle this
  exit 0
fi

PROJECT_DIR=$(dirname "$PROJECT_JSON")

# Check phase prerequisites
python3 - "$PROJECT_DIR" "$SKILL_NAME" << 'PYEOF'
import json, sys, os

project_dir = sys.argv[1]
skill_name = sys.argv[2]
phase = skill_name.replace("diamond-", "")

with open(f"{project_dir}/consulting-project.json") as f:
    project = json.load(f)

phase_state = project.get("phase_state", {})
phase_order = ["discover", "define", "develop", "deliver"]
phase_idx = phase_order.index(phase)

warnings = []

# Check if prior phases are complete
for i in range(phase_idx):
    prior = phase_order[i]
    prior_status = phase_state.get(prior, {}).get("status", "pending")
    if prior_status != "complete":
        warnings.append(f"{prior.capitalize()} phase is {prior_status}")

if warnings:
    msg = f"Phase gate advisory: {'; '.join(warnings)}. Proceeding anyway — override at your discretion."
    print(json.dumps({"decision": "approve", "reason": msg}))
else:
    print(json.dumps({"decision": "approve"}))

# Always exit 0 — advisory only, never blocks
sys.exit(0)
PYEOF
