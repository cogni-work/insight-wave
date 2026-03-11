#!/bin/bash
# Atomically append a claim to cogni-claims/claims.json with file locking.
# Usage: append-claim.sh <project-dir> <claim-json>
# The claim-json argument is a single JSON object (the claim to append).
# Creates cogni-claims/ directory and claims.json if they don't exist.
# Uses mkdir-based locking (portable across macOS and Linux) to prevent
# race conditions when agents run in parallel.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-}"
CLAIM_JSON="${2:-}"

if [ -z "$PROJECT_DIR" ] || [ -z "$CLAIM_JSON" ]; then
  echo '{"error": "Usage: append-claim.sh <project-dir> <claim-json>"}' >&2
  exit 1
fi

CLAIMS_DIR="$PROJECT_DIR/cogni-claims"
CLAIMS_FILE="$CLAIMS_DIR/claims.json"
LOCK_DIR="$CLAIMS_DIR/.claims.lock"

# Ensure directory structure exists
mkdir -p "$CLAIMS_DIR/sources" "$CLAIMS_DIR/history"

# Acquire lock using mkdir (atomic on all POSIX systems)
MAX_WAIT=30
WAITED=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.1
  WAITED=$((WAITED + 1))
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    # Stale lock detection: remove lock older than 60 seconds
    if [ -d "$LOCK_DIR" ]; then
      lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0) ))
      if [ "$lock_age" -gt 60 ]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
        continue
      fi
    fi
    echo '{"error": "Could not acquire lock on claims.json after 3s"}' >&2
    exit 1
  fi
done

# Ensure lock is released on exit
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# Initialize claims.json if missing
if [ ! -f "$CLAIMS_FILE" ]; then
  echo '{"claims": []}' > "$CLAIMS_FILE"
fi

# Append claim using python3 for safe JSON manipulation
python3 -c "
import json, sys

claims_file = sys.argv[1]
claim_json = sys.argv[2]

with open(claims_file, 'r') as f:
    data = json.load(f)

claim = json.loads(claim_json)
data['claims'].append(claim)

with open(claims_file, 'w') as f:
    json.dump(data, f, indent=2)

print(json.dumps({'status': 'appended', 'claim_id': claim.get('id', 'unknown'), 'total': len(data['claims'])}))
" "$CLAIMS_FILE" "$CLAIM_JSON"
