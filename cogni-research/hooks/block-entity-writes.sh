#!/usr/bin/env bash
set -euo pipefail
# block-entity-writes.sh
# Version: 1.1.0
# Event: PreToolUse
# Purpose: Block Write/Edit tool calls to entity directories, forcing create-entity.sh usage
#
# This hook prevents Claude from bypassing the entity creation script by writing
# directly to entity directories. All entity creation must go through create-entity.sh
# to ensure validation, locking, and index updates.
#
# Exit codes:
#   0 - Allow the tool call
#   2 - Block the tool call
#
# Environment:
#   CLAUDE_TOOL_INPUT - JSON with file_path parameter (set by Claude Code)


# Entity keys that require script-based creation
# NOTE: Using entity keys instead of directory names for more robust pattern matching
# This pattern matches paths like:
#   - /project/03-query-batches/data/file.md → matches "query-batches"
#   - /project/04-findings/data/file.md → matches "findings"
ENTITY_KEYS="query-batches|findings|sources|publishers"

# Extract file path from tool input
FILE_PATH="$(echo "${CLAUDE_TOOL_INPUT:-}" | jq -r '.file_path // ""' 2>/dev/null || echo "")"

if [[ -z "$FILE_PATH" ]]; then
  # No file path - allow (shouldn't happen for Write/Edit)
  exit 0
fi

# Block writes/edits to entity directories
if [[ "$FILE_PATH" =~ ($ENTITY_KEYS) ]]; then
  echo "BLOCKED: Entity files must be created via create-entity.sh, not Write/Edit tool" >&2
  echo "  Path: $FILE_PATH" >&2
  echo "  Use: bash \${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" >&2
  exit 2  # Block
fi

exit 0  # Allow other writes
