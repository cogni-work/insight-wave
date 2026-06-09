#!/usr/bin/env bash
# install-workspace-deps.sh - Provision optional Python dependencies into an
# isolated workspace venv at ~/.claude/workspace-python-venv/
# Usage: install-workspace-deps.sh [--registry <path>] [--venv <dir>] [--force]
# Output: JSON {success, data, error}
#
# Mirrors install-mcp.sh: cogni-workspace provisions a thing into ~/.claude/.
# Here the thing is a clean (no --system-site-packages) virtualenv holding the
# optional pip packages declared in references/python-deps-registry.json. The
# venv is PEP 668-safe (a venv is not an externally-managed environment) and its
# bin/python is what consuming plugins re-exec under via COGNI_WORKSPACE_PYTHON_VENV
# (e.g. cogni-knowledge/scripts/pdf-extract.py). A clean venv is required so that
# re-exec gets a predictable sys.path free of host compiled-dep contamination.
#
# All packages are OPTIONAL — this script is dispatched fail-soft by
# manage-workspace; a missing python3 / venv module / network must surface a
# clean error envelope, never abort the calling setup flow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Defaults
REGISTRY="$SCRIPT_DIR/../references/python-deps-registry.json"
VENV_DIR="${COGNI_WORKSPACE_PYTHON_VENV:-$HOME/.claude/workspace-python-venv}"
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2 ;;
    --venv)     VENV_DIR="$2"; shift 2 ;;
    --force)    FORCE=true;    shift ;;
    *)
      echo "{\"success\":false,\"data\":{\"action\":\"error\"},\"error\":\"Unknown argument: $1\"}" >&2
      exit 2
      ;;
  esac
done

emit_error() {
  # $1 = action, $2 = error message
  cat <<EOF
{"success":false,"data":{"action":"$1","venv_dir":"$VENV_DIR"},"error":"$2"}
EOF
}

# --- Prerequisites (fail-soft: clean envelope, exit 1, never abort the caller) ---
if ! command -v python3 &>/dev/null; then
  emit_error "unavailable" "python3 not found on PATH; optional Python deps cannot be provisioned"
  exit 1
fi

if ! python3 -c "import venv" &>/dev/null; then
  emit_error "unavailable" "python3 venv module not available; install python3-venv to provision optional deps"
  exit 1
fi

if [ ! -f "$REGISTRY" ]; then
  emit_error "error" "registry not found at $REGISTRY"
  exit 1
fi

# --- Resolve the package specifier list from the registry (name + version pin) ---
PKG_SPECS=$(python3 -c "
import json, sys
with open('$REGISTRY') as f:
    reg = json.load(f)
specs = []
for key, p in (reg.get('packages') or {}).items():
    name = p.get('name', key)
    ver = (p.get('version') or '').strip()
    specs.append(name + ver if ver else name)
print('\n'.join(specs))
" 2>/dev/null) || { emit_error "error" "failed to parse registry JSON at $REGISTRY"; exit 1; }

if [ -z "$PKG_SPECS" ]; then
  cat <<EOF
{"success":true,"data":{"action":"skipped","venv_dir":"$VENV_DIR","packages":[],"message":"Registry declares no packages; nothing to provision."}}
EOF
  exit 0
fi

# --- Idempotency: a provisioned venv has pyvenv.cfg; skip unless --force ---
if [ -f "$VENV_DIR/pyvenv.cfg" ] && [ "$FORCE" = false ]; then
  cat <<EOF
{"success":true,"data":{"action":"skipped","venv_dir":"$VENV_DIR","message":"venv already provisioned. Use --force to reinstall/upgrade."}}
EOF
  exit 0
fi

# --- Create (or reuse for --force) the clean isolated venv ---
ACTION="installed"
if [ -f "$VENV_DIR/pyvenv.cfg" ]; then
  ACTION="updated"
else
  mkdir -p "$(dirname "$VENV_DIR")"
  if ! python3 -m venv "$VENV_DIR" 2>/tmp/install-workspace-deps.log; then
    LOG=$(tail -3 /tmp/install-workspace-deps.log 2>/dev/null | tr '\n' ' ' | tr '"' "'")
    emit_error "error" "python3 -m venv failed: $LOG"
    exit 1
  fi
fi

VENV_PY="$VENV_DIR/bin/python"
if [ ! -x "$VENV_PY" ]; then
  emit_error "error" "venv interpreter missing at $VENV_PY after creation"
  exit 1
fi

# --- pip install the registry packages into the venv ---
# Build the install arg list (newline-delimited specs → array).
INSTALL_ARGS=()
while IFS= read -r spec; do
  [ -n "$spec" ] && INSTALL_ARGS+=("$spec")
done <<< "$PKG_SPECS"

if ! "$VENV_PY" -m pip install --upgrade pip >/tmp/install-workspace-deps.log 2>&1; then
  : # non-fatal: pip self-upgrade can fail offline; the package install below is the real gate
fi

if ! "$VENV_PY" -m pip install "${INSTALL_ARGS[@]}" >>/tmp/install-workspace-deps.log 2>&1; then
  LOG=$(tail -5 /tmp/install-workspace-deps.log 2>/dev/null | tr '\n' ' ' | tr '"' "'")
  emit_error "error" "pip install failed (network or build error): $LOG"
  exit 1
fi

# --- Record install metadata (parallel to install-mcp's .mcp-install.json) ---
PY_VERSION=$("$VENV_PY" --version 2>&1 | head -1)
PKG_JSON=$(printf '%s\n' "${INSTALL_ARGS[@]}" | python3 -c "
import json, sys
print(json.dumps([line for line in sys.stdin.read().splitlines() if line]))
")

cat > "$VENV_DIR/.deps-install.json" <<EOF
{
  "packages": $PKG_JSON,
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "python_version": "$PY_VERSION",
  "registry": "$REGISTRY"
}
EOF

cat <<EOF
{"success":true,"data":{"action":"$ACTION","venv_dir":"$VENV_DIR","packages":$PKG_JSON,"python_version":"$PY_VERSION"}}
EOF
