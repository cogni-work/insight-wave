#!/bin/bash
# setup-gh.sh — Check GitHub MCP connector availability in Cowork
# Usage: bash setup-gh.sh check
#
# Checks whether the GitHub connector is enabled by testing if
# GitHub MCP tools are discoverable. Returns JSON to stdout.
# Exit 0 always so callers can inspect the JSON.
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

# The GitHub connector in Cowork is a built-in integration.
# We can't directly test MCP tool availability from a shell script,
# so we report the platform and let the skill do the MCP tool check.
# The skill should attempt ToolSearch for mcp__github__* tools to verify.

cat <<EOF
{
  "platform": "$PLATFORM",
  "check": "mcp_tools",
  "instruction": "Use ToolSearch to check if mcp__github__ tools are available. If they are, the GitHub connector is enabled."
}
EOF
