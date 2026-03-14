#!/usr/bin/env bash
set -euo pipefail
# resolve-plugin-root.sh
# Version: 1.0.0
# Purpose: Resolve CLAUDE_PLUGIN_ROOT to correct plugin directory
#          Handles both monorepo and direct plugin installations
#
# Usage:
#   source resolve-plugin-root.sh
#   # Or call directly:
#   PLUGIN_ROOT=$(bash resolve-plugin-root.sh)
#
# Output: Resolved plugin root path to stdout
# Exit codes:
#   0 - Success
#   110 - CLAUDE_PLUGIN_ROOT not set and cannot be derived


resolve_plugin_root() {
    local plugin_root="${CLAUDE_PLUGIN_ROOT:-}"

    # If not set, try to derive from script location
    if [[ -z "$plugin_root" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
        # utils/ -> scripts/ -> plugin root
        plugin_root="$(cd "${script_dir}/../.." && pwd)"
    fi

    # Validate plugin root has expected structure

    # Final validation
    if [[ -z "$plugin_root" ]] || [[ ! -d "${plugin_root}/scripts" ]]; then
        echo "ERROR: Cannot resolve plugin root" >&2
        return 110
    fi

    echo "$plugin_root"
}

# If sourced, export function; if executed, run and output
# Use default values to prevent "parameter not set" errors in zsh
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
    resolve_plugin_root
else
    export -f resolve_plugin_root 2>/dev/null || true
fi
