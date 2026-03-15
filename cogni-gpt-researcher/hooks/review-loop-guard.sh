#!/usr/bin/env bash
set -euo pipefail
# review-loop-guard.sh
# Version: 1.0.0
# Event: PostToolUse (Task)
# Purpose: Enforce max 3 review iterations to prevent infinite review loops
#
# Logic:
#   - Scans .metadata/review-verdicts/ for verdict files
#   - If 3+ verdicts exist, injects SHOULD_ACCEPT: true into latest verdict
#   - Advisory only (exit 0) — does not block the tool call
#
# Exit codes:
#   0 - Always (advisory hook)

# Try to find project path from task output or recent files
# The hook fires after any Task completes, so we need to find the active project

# Look for review-verdicts directories in common locations
find_verdicts_dir() {
  local dir
  # Check CLAUDE_TOOL_OUTPUT for project path hints
  local output="${CLAUDE_TOOL_OUTPUT:-}"
  if [[ -n "$output" ]]; then
    # Try to extract project_path from JSON output
    dir="$(echo "$output" | jq -r '.project_path // empty' 2>/dev/null || true)"
    if [[ -n "$dir" && -d "$dir/.metadata/review-verdicts" ]]; then
      echo "$dir/.metadata/review-verdicts"
      return 0
    fi
  fi

  # Check current directory tree
  if [[ -d ".metadata/review-verdicts" ]]; then
    echo ".metadata/review-verdicts"
    return 0
  fi

  return 1
}

VERDICTS_DIR="$(find_verdicts_dir 2>/dev/null || true)"

if [[ -z "$VERDICTS_DIR" || ! -d "$VERDICTS_DIR" ]]; then
  # No verdicts directory found — not a review context, allow
  exit 0
fi

# Count verdict files
VERDICT_COUNT=$(find "$VERDICTS_DIR" -name 'v*.json' -type f 2>/dev/null | wc -l | tr -d ' ')

if [[ "$VERDICT_COUNT" -ge 3 ]]; then
  # Find the latest verdict file
  LATEST=$(find "$VERDICTS_DIR" -name 'v*.json' -type f 2>/dev/null | sort -V | tail -1)
  if [[ -n "$LATEST" && -f "$LATEST" ]]; then
    # Inject SHOULD_ACCEPT flag
    if command -v python3 &>/dev/null; then
      python3 -c "
import json, sys
with open('$LATEST', 'r') as f:
    data = json.load(f)
data['SHOULD_ACCEPT'] = True
data['forced_reason'] = 'Max review iterations (3) reached'
with open('$LATEST', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
    fi
    echo "REVIEW LOOP GUARD: Max iterations (3) reached. Forcing acceptance." >&2
  fi
fi

exit 0
