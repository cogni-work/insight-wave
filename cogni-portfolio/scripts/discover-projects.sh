#!/bin/bash
# Discover cogni-portfolio projects via the cogni-workspace generic helper.
# Thin wrapper: locates cogni-workspace, then delegates to
# cogni-workspace/scripts/discover-plugin-projects.sh with portfolio-specific
# manifest, registry, extractor, and find spec. See that script for CLI flags.
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate cogni-workspace: env var → plugin cache → monorepo sibling.
_WORKSPACE_ROOT="${WORKSPACE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ 2>/dev/null | head -1)}"
if [ -z "$_WORKSPACE_ROOT" ] || [ ! -f "$_WORKSPACE_ROOT/scripts/discover-plugin-projects.sh" ]; then
  _WORKSPACE_ROOT="$(cd "$_SCRIPT_DIR/../../cogni-workspace" 2>/dev/null && pwd || true)"
fi
if [ -z "$_WORKSPACE_ROOT" ] || [ ! -f "$_WORKSPACE_ROOT/scripts/discover-plugin-projects.sh" ]; then
  echo "Error: cogni-workspace not found. Install or update cogni-workspace." >&2
  exit 1
fi

exec bash "$_WORKSPACE_ROOT/scripts/discover-plugin-projects.sh" \
  --plugin cogni-portfolio \
  --registry "$HOME/.claude/cogni-portfolio-projects.json" \
  --extractor "$_SCRIPT_DIR/_discover_extractor.py" \
  --find "portfolio.json:*/cogni-portfolio/*:1" \
  "$@"
