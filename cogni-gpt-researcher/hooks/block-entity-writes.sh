#!/usr/bin/env bash
set -euo pipefail
# block-entity-writes.sh
# Version: 1.0.0
# Event: PreToolUse
# Purpose: Block Write/Edit tool calls to entity directories, forcing create-entity.sh usage
#
# Exit codes:
#   0 - Allow the tool call
#   2 - Block the tool call

# Entity directory patterns (matches path components)
ENTITY_KEYS="00-sub-questions|01-contexts|02-sources|03-report-claims"

# Extract file path from tool input
FILE_PATH="$(echo "${CLAUDE_TOOL_INPUT:-}" | jq -r '.file_path // ""' 2>/dev/null || echo "")"

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Block writes/edits to entity data directories
if [[ "$FILE_PATH" =~ ($ENTITY_KEYS)/data/ ]]; then
  echo "BLOCKED: Entity files must be created via create-entity.sh, not Write/Edit tool" >&2
  echo "  Path: $FILE_PATH" >&2
  echo "  Use: bash \${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" >&2
  exit 2
fi

exit 0
