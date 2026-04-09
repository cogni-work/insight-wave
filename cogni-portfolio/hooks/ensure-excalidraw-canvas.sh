#!/usr/bin/env bash
# Ensure Excalidraw canvas frontend is running and browser is open before MCP
# tool execution. Triggered by PreToolUse hook for all mcp__excalidraw__* tools.
#
# The Excalidraw MCP server (stdio) runs separately from the canvas frontend
# (Express + WebSocket on port 3000). Tools like describe_scene, export_scene,
# export_to_image, and get_canvas_screenshot require the frontend AND a browser
# tab open at localhost:3000.
#
# Reliability model:
#   1. Fast path (~10ms): port listening AND WebSocket client connected → exit 0
#   2. Canvas down: start server, open browser, wait for WS connection
#   3. Tab closed: detect websocket_clients=0, re-open browser, wait for WS
#   No sticky /tmp flags — always checks actual WebSocket state.

set -euo pipefail

EXCALIDRAW_DIR="${EXCALIDRAW_MCP_DIR:-$HOME/.claude/mcp-servers/mcp_excalidraw}"
PORT="${EXCALIDRAW_CANVAS_PORT:-3000}"
LOG_FILE="${EXCALIDRAW_DIR}/excalidraw-canvas.log"
PID_FILE="${EXCALIDRAW_DIR}/canvas.pid"

# Consume stdin (hook input JSON) to prevent broken pipe
cat > /dev/null

# Check if a WebSocket client is connected via the /health endpoint
has_ws_client() {
  local health
  health=$(curl -sf "http://localhost:${PORT}/health" 2>/dev/null) || return 1
  echo "$health" | grep -qE '"websocket_clients":[1-9]'
}

# Open browser (platform-aware)
open_browser() {
  local url="http://localhost:${PORT}"
  case "$(uname -s)" in
    Darwin) open "$url" ;;
    Linux)  xdg-open "$url" 2>/dev/null || true ;;
  esac
}

# Fast path: port up AND WebSocket client connected
if nc -z localhost "$PORT" 2>/dev/null && has_ws_client; then
  exit 0
fi

# If port not up: start canvas server
if ! nc -z localhost "$PORT" 2>/dev/null; then
  if [[ ! -f "${EXCALIDRAW_DIR}/dist/server.js" ]]; then
    echo "Warning: Excalidraw canvas server not found at ${EXCALIDRAW_DIR}/dist/server.js" >&2
    exit 0
  fi

  cd "$EXCALIDRAW_DIR"
  nohup node dist/server.js > "$LOG_FILE" 2>&1 &
  CANVAS_PID=$!
  echo "$CANVAS_PID" > "$PID_FILE"

  # Wait for port to become available (max 10 seconds)
  for _ in $(seq 1 20); do
    nc -z localhost "$PORT" 2>/dev/null && break
    sleep 0.5
  done

  if ! nc -z localhost "$PORT" 2>/dev/null; then
    echo "Warning: Excalidraw canvas frontend did not start within 10s" >&2
    exit 0
  fi
fi

# Port is up but no WS client → open browser and wait for connection
if ! has_ws_client; then
  open_browser

  # Wait for WS client to connect (max 5s)
  for _ in $(seq 1 10); do
    sleep 0.5
    has_ws_client && break
  done
fi

# Report status
if has_ws_client; then
  echo '{"systemMessage": "Excalidraw canvas ready with browser connected"}'
else
  echo '{"systemMessage": "Warning: Excalidraw canvas running but no browser connected — export_to_image and get_canvas_screenshot may fail. Open http://localhost:'"${PORT}"' in your browser."}'
fi
exit 0
