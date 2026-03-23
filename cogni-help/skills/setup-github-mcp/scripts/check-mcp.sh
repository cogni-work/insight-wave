#!/bin/bash
# check-mcp.sh — Check GitHub MCP server prerequisites and configuration status
# Usage: bash check-mcp.sh check
#
# Returns JSON to stdout with the current state of GitHub MCP readiness.
# Exit 0 always (non-blocking) so callers can inspect the JSON.
#
# Compatible with bash 3.2 (macOS default). Uses python3 for JSON parsing.

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

# Resolve Claude Desktop config path
CONFIG_PATH=""
case "$PLATFORM" in
  macos)
    CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    ;;
  linux)
    CONFIG_PATH="$HOME/.config/Claude/claude_desktop_config.json"
    ;;
esac

# Check if config file exists
CONFIG_EXISTS="false"
if [ -n "$CONFIG_PATH" ] && [ -f "$CONFIG_PATH" ]; then
  CONFIG_EXISTS="true"
fi

# Check Docker installation
DOCKER_INSTALLED="false"
if command -v docker &>/dev/null; then
  DOCKER_INSTALLED="true"
fi

# Check Docker running status (with timeout to avoid hanging)
DOCKER_RUNNING="false"
if [ "$DOCKER_INSTALLED" = "true" ]; then
  if timeout 5 docker info &>/dev/null 2>&1; then
    DOCKER_RUNNING="true"
  fi
fi

# Check npx availability
NPX_AVAILABLE="false"
if command -v npx &>/dev/null; then
  NPX_AVAILABLE="true"
fi

# Check gh CLI installation and authentication
GH_INSTALLED="false"
GH_VERSION="null"
GH_AUTHENTICATED="false"
if command -v gh &>/dev/null; then
  GH_INSTALLED="true"
  GH_VERSION=$(gh --version 2>/dev/null | head -1 | sed 's/gh version //' | sed 's/ .*//' || echo "unknown")
  AUTH_OUTPUT=$(gh auth status 2>&1 || true)
  if echo "$AUTH_OUTPUT" | grep -q "Logged in to"; then
    GH_AUTHENTICATED="true"
  fi
fi

# Parse config file for GitHub MCP status
GITHUB_MCP_CONFIGURED="false"
EXISTING_MCP_SERVERS="[]"
if [ "$CONFIG_EXISTS" = "true" ]; then
  MCP_RESULT=$(python3 -c "
import json, sys
try:
    with open('''$CONFIG_PATH''') as f:
        cfg = json.load(f)
    servers = cfg.get('mcpServers', {})
    names = list(servers.keys())
    github_configured = 'github' in servers
    print(json.dumps({'configured': github_configured, 'servers': names}))
except Exception:
    print(json.dumps({'configured': False, 'servers': []}))
" 2>/dev/null || echo '{"configured": false, "servers": []}')

  GITHUB_MCP_CONFIGURED=$(echo "$MCP_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(str(d['configured']).lower())")
  EXISTING_MCP_SERVERS=$(echo "$MCP_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d['servers']))")
fi

# Quote strings for JSON, leave booleans and null unquoted
quote() {
  local val="$1"
  if [ "$val" = "true" ] || [ "$val" = "false" ] || [ "$val" = "null" ]; then
    echo "$val"
  else
    echo "\"$val\""
  fi
}

# Determine overall readiness
ALL_READY="false"
if [ "$GITHUB_MCP_CONFIGURED" = "true" ]; then
  ALL_READY="true"
fi

cat <<EOF
{
  "platform": "$PLATFORM",
  "config_path": "$CONFIG_PATH",
  "config_exists": $CONFIG_EXISTS,
  "docker_installed": $DOCKER_INSTALLED,
  "docker_running": $DOCKER_RUNNING,
  "npx_available": $NPX_AVAILABLE,
  "gh_installed": $GH_INSTALLED,
  "gh_version": $(quote "$GH_VERSION"),
  "gh_authenticated": $GH_AUTHENTICATED,
  "github_mcp_configured": $GITHUB_MCP_CONFIGURED,
  "existing_mcp_servers": $EXISTING_MCP_SERVERS,
  "all_ready": $ALL_READY
}
EOF
