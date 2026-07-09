#!/usr/bin/env bash
# Measure how often numeric literals in an engagement's deliverable corpus
# changed over its git history — the retrospective sizing datum that gates
# whether deterministic assumption propagation and LLM-assisted regen are
# worth building. Thin exec-delegator to the python3 miner (mirrors
# discover-projects.sh); the mining itself needs subprocess git + regex.
# Usage: bash assumption-change-frequency.sh <corpus-path> [--since <date>]
# Output: JSON {"success": bool, "data": {...}, "error": "string"}
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec python3 "$_SCRIPT_DIR/assumption-change-frequency.py" "$@"
