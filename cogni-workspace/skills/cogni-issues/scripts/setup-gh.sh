#!/bin/bash
# setup-gh.sh — Check GitHub CLI installation and authentication status
# Usage: bash setup-gh.sh check
#
# Returns JSON to stdout with the current state of gh CLI readiness.
# Exit 0 always (non-blocking) so callers can inspect the JSON.
#
# Compatible with bash 3.2 (macOS default). Uses python3 for JSON output.

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

# Detect package manager
PKG_MANAGER="null"
if command -v brew &>/dev/null; then
  PKG_MANAGER="brew"
elif command -v apt &>/dev/null; then
  PKG_MANAGER="apt"
elif command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
elif command -v snap &>/dev/null; then
  PKG_MANAGER="snap"
fi

# Check gh installation
GH_INSTALLED="false"
GH_VERSION="null"
if command -v gh &>/dev/null; then
  GH_INSTALLED="true"
  GH_VERSION=$(gh --version 2>/dev/null | head -1 | sed 's/gh version //' | sed 's/ .*//' || echo "unknown")
fi

# Check gh authentication
GH_AUTHENTICATED="false"
GH_USER="null"
if [ "$GH_INSTALLED" = "true" ]; then
  AUTH_OUTPUT=$(gh auth status 2>&1 || true)
  if echo "$AUTH_OUTPUT" | grep -q "Logged in to"; then
    GH_AUTHENTICATED="true"
    # Extract username from auth status output
    GH_USER=$(echo "$AUTH_OUTPUT" | grep -o "account [^ ]*" | head -1 | sed 's/account //' || echo "unknown")
  fi
fi

# Determine overall readiness
ALL_READY="false"
if [ "$GH_INSTALLED" = "true" ] && [ "$GH_AUTHENTICATED" = "true" ]; then
  ALL_READY="true"
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

cat <<EOF
{
  "gh_installed": $GH_INSTALLED,
  "gh_version": $(quote "$GH_VERSION"),
  "gh_authenticated": $GH_AUTHENTICATED,
  "gh_user": $(quote "$GH_USER"),
  "platform": "$PLATFORM",
  "package_manager": $(quote "$PKG_MANAGER"),
  "all_ready": $ALL_READY
}
EOF
