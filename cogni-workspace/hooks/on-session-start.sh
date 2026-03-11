#!/usr/bin/env bash
# on-session-start.sh - Minimal workspace status on session start
# Shows one-line status if workspace detected, silent otherwise
# Always exits 0 (non-blocking)

set -euo pipefail

# Find workspace: check PROJECT_AGENTS_OPS_ROOT, then cwd
WORKSPACE=""
if [ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ] && [ -f "${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json" ]; then
  WORKSPACE="$PROJECT_AGENTS_OPS_ROOT"
elif [ -f ".workspace-config.json" ]; then
  WORKSPACE="$(pwd)"
fi

# No workspace found - silent exit
if [ -z "$WORKSPACE" ]; then
  exit 0
fi

# Read workspace config
if ! command -v python3 &>/dev/null; then
  echo "cogni-workspace: python3 required for workspace status"
  exit 0
fi

STATUS=$(python3 -c "
import json, os, glob

workspace = '$WORKSPACE'
config_path = os.path.join(workspace, '.workspace-config.json')

try:
    with open(config_path) as f:
        config = json.load(f)
except (IOError, json.JSONDecodeError):
    print('cogni-workspace: config unreadable')
    exit(0)

lang = config.get('language', '?').upper()
plugins = config.get('installed_plugins', [])
plugin_count = len(plugins)

# Count themes
themes_dir = os.path.join(workspace, 'cogni-workspace', 'themes')
theme_count = 0
if os.path.isdir(themes_dir):
    for d in os.listdir(themes_dir):
        if d != '_template' and os.path.isfile(os.path.join(themes_dir, d, 'theme.md')):
            theme_count += 1

# Check env health
settings_ok = os.path.isfile(os.path.join(workspace, '.claude', 'settings.local.json'))

status_icon = 'OK' if settings_ok else 'WARN'

print(f'Workspace: {status_icon} | {plugin_count} plugins | {theme_count} themes | {lang}')
" 2>/dev/null || echo "")

if [ -n "$STATUS" ]; then
  echo "$STATUS"
fi

exit 0
