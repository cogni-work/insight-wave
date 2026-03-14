#!/usr/bin/env bash
set -euo pipefail
# lookup-entity.sh - Wrapper delegating to Python backend
# Version: 3.1.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null; then
    PYTHON=python
else
    echo '{"success": false, "error": "Python 3.8+ not found"}' >&2
    exit 1
fi

exec "$PYTHON" "$SCRIPT_DIR/lookup-entity.py" "$@"
