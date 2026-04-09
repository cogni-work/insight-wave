#!/usr/bin/env bash
# discover-plugins.sh - Scan for installed insight-wave marketplace plugins
# Discovers plugins by finding .claude-plugin/plugin.json markers
# Output: JSON with discovered plugin list

set -euo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Determine search root
SEARCH_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

if [ -z "$SEARCH_ROOT" ]; then
  # Fallback: check common marketplace cache locations
  if [ -d "$HOME/.claude/plugins/cache/insight-wave-marketplace" ]; then
    SEARCH_ROOT="$HOME/.claude/plugins/cache/insight-wave-marketplace"
  elif [ -d "$HOME/.claude/plugins/cache" ]; then
    SEARCH_ROOT="$HOME/.claude/plugins/cache"
  else
    echo '{"success":false,"data":{"error":"No plugin root found. Set CLAUDE_PLUGIN_ROOT or install marketplace plugins."}}'
    exit 0
  fi
fi

# Discover plugins by finding plugin.json markers
plugins="[]"
if command -v python3 &>/dev/null; then
  plugins=$(python3 -c "
import os, json, glob, sys

search_root = '$SEARCH_ROOT'
found = []

# Search for plugin.json files
for pattern in ['*/.claude-plugin/plugin.json', '*/*/.claude-plugin/plugin.json']:
    for manifest_path in glob.glob(os.path.join(search_root, pattern)):
        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
            plugin_name = manifest.get('name', '')
            plugin_dir = os.path.dirname(os.path.dirname(manifest_path))

            # Determine env var naming
            if plugin_name.startswith('cogni-'):
                suffix = plugin_name.replace('cogni-', '').upper().replace('-', '_')
                root_var = f'COGNI_{suffix}_ROOT'
                plugin_var = f'COGNI_{suffix}_PLUGIN'
            else:
                suffix = plugin_name.upper().replace('-', '_')
                root_var = f'PLUGIN_{suffix}_ROOT'
                plugin_var = f'PLUGIN_{suffix}_PLUGIN'

            # Version is authoritative in plugin.json — warn loudly if missing
            # (marketplace.json no longer carries version; git commit hash drives sync)
            version = manifest.get('version')
            if not version:
                sys.stderr.write(f'[discover-plugins] warning: {plugin_name or manifest_path} has no version field in plugin.json\n')
                version = 'unknown'

            found.append({
                'name': plugin_name,
                'version': version,
                'description': manifest.get('description', ''),
                'path': plugin_dir,
                'root_var': root_var,
                'plugin_var': plugin_var
            })
        except (json.JSONDecodeError, IOError):
            continue

# Deduplicate by name, keeping highest version
by_name = {}
for p in found:
    name = p['name']
    if name not in by_name or p['version'] > by_name[name]['version']:
        by_name[name] = p

result = sorted(by_name.values(), key=lambda x: x['name'])
print(json.dumps(result))
")
fi

count=$(echo "$plugins" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

cat <<EOF
{
  "success": true,
  "data": {
    "plugins": $plugins,
    "count": $count,
    "search_root": "$SEARCH_ROOT"
  },
  "metadata": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "script": "$SCRIPT_NAME",
    "version": "0.1.0"
  }
}
EOF
