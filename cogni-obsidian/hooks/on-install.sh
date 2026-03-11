#!/usr/bin/env bash
set -euo pipefail
# on-install.sh - Dependency check for cogni-obsidian
# Runs on SessionStart to verify required tools are available

missing=()

for cmd in jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "cogni-obsidian: Missing dependencies: ${missing[*]}"
    echo "  Install with: brew install ${missing[*]}  (macOS)"
    echo "  or: sudo apt-get install ${missing[*]}  (Linux)"
    echo ""
fi
