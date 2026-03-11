#!/usr/bin/env bash
# check-dependencies.sh - Verify required and optional dependencies
# Exit 0 always (non-blocking), output JSON status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

check_command() {
  local cmd="$1"
  local required="$2"
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>/dev/null | head -1 || echo "unknown")
    echo "{\"name\":\"$cmd\",\"available\":true,\"required\":$required,\"version\":\"$version\"}"
  else
    echo "{\"name\":\"$cmd\",\"available\":false,\"required\":$required,\"version\":null}"
  fi
}

# Check all dependencies
results=()
results+=("$(check_command jq true)")
results+=("$(check_command python3 true)")
results+=("$(check_command curl false)")
results+=("$(check_command git false)")
results+=("$(check_command bc false)")

# Build JSON array
json_array="["
for i in "${!results[@]}"; do
  if [ "$i" -gt 0 ]; then json_array+=","; fi
  json_array+="${results[$i]}"
done
json_array+="]"

# Count missing required
missing_required=$(echo "$json_array" | python3 -c "
import json, sys
deps = json.load(sys.stdin)
missing = [d['name'] for d in deps if d['required'] and not d['available']]
print(len(missing))
" 2>/dev/null || echo "0")

missing_optional=$(echo "$json_array" | python3 -c "
import json, sys
deps = json.load(sys.stdin)
missing = [d['name'] for d in deps if not d['required'] and not d['available']]
print(len(missing))
" 2>/dev/null || echo "0")

all_ok="true"
if [ "$missing_required" -gt 0 ]; then
  all_ok="false"
fi

cat <<EOF
{
  "success": $all_ok,
  "data": {
    "dependencies": $json_array,
    "missing_required": $missing_required,
    "missing_optional": $missing_optional
  },
  "metadata": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "script": "$SCRIPT_NAME",
    "version": "0.1.0"
  }
}
EOF
