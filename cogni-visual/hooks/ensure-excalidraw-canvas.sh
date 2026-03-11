#!/usr/bin/env bash
# Ensure Excalidraw canvas frontend is running before MCP tool execution.
# Triggered by PreToolUse hook for all mcp__excalidraw__* tools.
#
# The Excalidraw MCP server (stdio) runs separately from the canvas frontend
# (Express + WebSocket on port 3000). Tools like describe_scene, export_scene,
# export_to_image, and get_canvas_screenshot require the frontend.
#
# This script is a fast no-op when the frontend is already running (~10ms).

set -euo pipefail

EXCALIDRAW_DIR="${EXCALIDRAW_MCP_DIR:-$HOME/.claude/mcp-servers/mcp_excalidraw}"
PORT="${EXCALIDRAW_CANVAS_PORT:-3000}"
LOG_FILE="${EXCALIDRAW_DIR}/excalidraw-canvas.log"
PID_FILE="${EXCALIDRAW_DIR}/canvas.pid"

# Consume stdin (hook input JSON) to prevent broken pipe
cat > /dev/null

# Fast path: port already listening
if nc -z localhost "$PORT" 2>/dev/null; then
  exit 0
fi

# Verify server.js exists
if [[ ! -f "${EXCALIDRAW_DIR}/dist/server.js" ]]; then
  echo "Warning: Excalidraw canvas server not found at ${EXCALIDRAW_DIR}/dist/server.js" >&2
  exit 0
fi

# Start canvas frontend in background
cd "$EXCALIDRAW_DIR"
nohup node dist/server.js > "$LOG_FILE" 2>&1 &
CANVAS_PID=$!
echo "$CANVAS_PID" > "$PID_FILE"

# Wait for port to become available (max 10 seconds)
for _ in $(seq 1 20); do
  if nc -z localhost "$PORT" 2>/dev/null; then
    echo "{\"systemMessage\": \"Excalidraw canvas frontend started on port ${PORT} (PID ${CANVAS_PID})\"}"
    exit 0
  fi
  sleep 0.5
done

echo "Warning: Excalidraw canvas frontend did not start within 10s" >&2
exit 0
