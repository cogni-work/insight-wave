#!/bin/bash
# setup-gh.sh — Platform info for cogni-issues
# Usage: bash setup-gh.sh check
#
# Returns platform information as JSON. The primary readiness check
# (browser availability + GitHub login) is done by the skill itself
# using browsermcp tools, not this script.
#
# Compatible with bash 3.2 (macOS default).

set -euo pipefail

COMMAND="${1:-}"

if [ "$COMMAND" != "check" ]; then
  echo "Usage: bash $0 check" >&2
  exit 1
fi

# Detect platform
PLATFORM="unknown"
case "$(uname -s)" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
esac

cat <<EOF
{
  "platform": "$PLATFORM",
  "check": "browser",
  "instruction": "Use mcp__browsermcp__browser_navigate to github.com, then browser_snapshot to check login state."
}
EOF
