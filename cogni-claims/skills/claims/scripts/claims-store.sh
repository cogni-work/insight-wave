#!/bin/bash
# claims-store.sh — JSON state management for cogni-claims
# Usage: bash claims-store.sh <command> [args...]
#
# Commands requiring <working_dir>:
#   init <working_dir>                    Initialize cogni-claims/ workspace
#   read-claims <working_dir>             Read claims.json to stdout
#   has-claims <working_dir>              Exit 0 if claims exist, 1 if empty
#   count-by-status <working_dir>         Output JSON with counts per status
#
# Standalone commands:
#   gen-id                                Generate a claim UUID
#   url-hash <url>                        Generate filesystem-safe hash for URL
#
# All output is JSON on stdout. Errors go to stderr.
# Compatible with bash 3.2 (macOS default).
#
# JSON FORMAT ASSUMPTION: This script expects pretty-printed JSON with one
# field per line (as produced by Claude's Write tool). Minified single-line
# JSON will cause incorrect results in has-claims and count-by-status.

set -euo pipefail

COMMAND="${1:-}"

usage() {
  echo "Usage: bash $0 <command> [args...]" >&2
  echo "Commands: init <dir>, gen-id, url-hash <url>, read-claims <dir>, has-claims <dir>, count-by-status <dir>" >&2
  exit 1
}

# Generate a UUID v4 (portable, no external deps)
gen_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    # Fallback using /dev/urandom
    od -x /dev/urandom | head -1 | awk '{print $2$3"-"$4"-4"substr($5,2)"-"$6"-"$7$8$9}'
  fi
}

# Generate filesystem-safe hash of a URL
url_hash() {
  local url="$1"
  echo -n "$url" | shasum -a 256 | cut -c1-16
}

case "$COMMAND" in
  init)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    CLAIMS_DIR="$WORKING_DIR/cogni-claims"
    mkdir -p "$CLAIMS_DIR/sources" "$CLAIMS_DIR/history"
    if [ ! -f "$CLAIMS_DIR/claims.json" ]; then
      NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      cat > "$CLAIMS_DIR/claims.json" <<ENDJSON
{
  "version": "1.0.0",
  "updated_at": "$NOW",
  "claims": []
}
ENDJSON
      echo "{\"status\":\"initialized\",\"path\":\"$CLAIMS_DIR\"}"
    else
      echo "{\"status\":\"exists\",\"path\":\"$CLAIMS_DIR\"}"
    fi
    ;;

  gen-id)
    UUID=$(gen_uuid)
    echo "{\"id\":\"claim-$UUID\"}"
    ;;

  url-hash)
    URL="${2:-}"
    [ -z "$URL" ] && { echo "Error: url-hash requires a URL argument" >&2; exit 1; }
    HASH=$(url_hash "$URL")
    echo "{\"hash\":\"$HASH\"}"
    ;;

  read-claims)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    CLAIMS_FILE="$WORKING_DIR/cogni-claims/claims.json"
    if [ -f "$CLAIMS_FILE" ]; then
      cat "$CLAIMS_FILE"
    else
      echo "{\"error\":\"claims.json not found\",\"path\":\"$CLAIMS_FILE\"}" >&2
      exit 1
    fi
    ;;

  has-claims)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    CLAIMS_FILE="$WORKING_DIR/cogni-claims/claims.json"
    if [ ! -f "$CLAIMS_FILE" ]; then
      exit 1
    fi
    # Check if claims array is non-empty (portable JSON check)
    # Use extended regex for \s portability across grep implementations
    if grep -qE '"claims" *: *\[ *\]' "$CLAIMS_FILE" 2>/dev/null; then
      exit 1
    fi
    exit 0
    ;;

  count-by-status)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    CLAIMS_FILE="$WORKING_DIR/cogni-claims/claims.json"
    if [ ! -f "$CLAIMS_FILE" ]; then
      echo "{\"error\":\"claims.json not found\"}" >&2
      exit 1
    fi
    # Count statuses using grep (portable, no jq dependency)
    # Match only top-level "status" fields (indented, not inside string values)
    # Pattern: line starts with whitespace + "status" key — avoids matching status
    # words inside source_excerpt or explanation strings
    UNVERIFIED=$(grep -cE '^ *"status" *: *"unverified"' "$CLAIMS_FILE" 2>/dev/null || true)
    UNVERIFIED=${UNVERIFIED:-0}
    VERIFIED=$(grep -cE '^ *"status" *: *"verified"' "$CLAIMS_FILE" 2>/dev/null || true)
    VERIFIED=${VERIFIED:-0}
    DEVIATED=$(grep -cE '^ *"status" *: *"deviated"' "$CLAIMS_FILE" 2>/dev/null || true)
    DEVIATED=${DEVIATED:-0}
    UNAVAILABLE=$(grep -cE '^ *"status" *: *"source_unavailable"' "$CLAIMS_FILE" 2>/dev/null || true)
    UNAVAILABLE=${UNAVAILABLE:-0}
    RESOLVED=$(grep -cE '^ *"status" *: *"resolved"' "$CLAIMS_FILE" 2>/dev/null || true)
    RESOLVED=${RESOLVED:-0}
    TOTAL=$((UNVERIFIED + VERIFIED + DEVIATED + UNAVAILABLE + RESOLVED))
    echo "{\"total\":$TOTAL,\"unverified\":$UNVERIFIED,\"verified\":$VERIFIED,\"deviated\":$DEVIATED,\"source_unavailable\":$UNAVAILABLE,\"resolved\":$RESOLVED}"
    ;;

  *)
    usage
    ;;
esac
