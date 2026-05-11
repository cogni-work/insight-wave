#!/bin/bash
# Discover cogni-consulting engagements via the cogni-workspace generic helper.
# Thin wrapper: locates cogni-workspace, then delegates to
# cogni-workspace/scripts/discover-plugin-projects.sh with consulting-specific
# manifest, registry, extractor, and find spec. See that script for CLI flags.
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_WORKSPACE_ROOT="${WORKSPACE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ 2>/dev/null | head -1)}"
if [ -z "$_WORKSPACE_ROOT" ] || [ ! -f "$_WORKSPACE_ROOT/scripts/discover-plugin-projects.sh" ]; then
  _WORKSPACE_ROOT="$(cd "$_SCRIPT_DIR/../../cogni-workspace" 2>/dev/null && pwd || true)"
fi
if [ -z "$_WORKSPACE_ROOT" ] || [ ! -f "$_WORKSPACE_ROOT/scripts/discover-plugin-projects.sh" ]; then
  echo "Error: cogni-workspace not found. Install or update cogni-workspace." >&2
  exit 1
fi

exec bash "$_WORKSPACE_ROOT/scripts/discover-plugin-projects.sh" \
  --plugin cogni-consulting \
  --registry "$HOME/.claude/cogni-consulting-projects.json" \
  --extractor "$_SCRIPT_DIR/_discover_extractor.py" \
  --find "consulting-project.json:*/cogni-consulting/*:1" \
  "$@"
