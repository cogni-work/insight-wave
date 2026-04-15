#!/usr/bin/env bash
set -euo pipefail
# write-report-metadata.sh - Wrapper delegating to Python backend
# Version: 1.0.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null; then
    PYTHON=python
else
    echo '{"success": false, "error": "Python 3.8+ not found"}' >&2
    exit 1
fi

exec "$PYTHON" "$SCRIPT_DIR/write-report-metadata.py" "$@"
