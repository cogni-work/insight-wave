#!/usr/bin/env bash
# check-workspace-python-deps.sh - Report optional Python-dependency health
# Usage: check-workspace-python-deps.sh [--registry <path>] [--venv <dir>]
# Output: JSON {success, data, error, metadata}
#
# Mirrors check-dependencies.sh (non-blocking health check). Every package in
# python-deps-registry.json is OPTIONAL, so success stays true even when packages
# are missing — the data block reports what is and isn't importable from the
# workspace venv (~/.claude/workspace-python-venv) so workspace-status can surface
# WARNING (never CRITICAL) for absent optional packages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

REGISTRY="$SCRIPT_DIR/../references/python-deps-registry.json"
VENV_DIR="${COGNI_WORKSPACE_PYTHON_VENV:-$HOME/.claude/workspace-python-venv}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2 ;;
    --venv)     VENV_DIR="$2"; shift 2 ;;
    *)
      echo "{\"success\":false,\"data\":{},\"error\":\"Unknown argument: $1\"}" >&2
      exit 2
      ;;
  esac
done

VENV_PY="$VENV_DIR/bin/python"
VENV_PRESENT=false
[ -f "$VENV_DIR/pyvenv.cfg" ] && [ -x "$VENV_PY" ] && VENV_PRESENT=true

if [ ! -f "$REGISTRY" ]; then
  cat <<EOF
{"success":true,"data":{"venv_present":$VENV_PRESENT,"venv_dir":"$VENV_DIR","packages":[],"missing_optional":0,"message":"registry not found — no optional packages declared"},"metadata":{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","script":"$SCRIPT_NAME","version":"0.1.0"}}
EOF
  exit 0
fi

# Probe each registry package for importability under the venv interpreter.
# An optional import_name overrides the package name (pip name != import name case).
RESULTS=$(REGISTRY="$REGISTRY" VENV_PY="$VENV_PY" VENV_PRESENT="$VENV_PRESENT" python3 <<'PY'
import json, os, subprocess

registry = os.environ["REGISTRY"]
venv_py = os.environ["VENV_PY"]
venv_present = os.environ["VENV_PRESENT"] == "true"

with open(registry) as f:
    reg = json.load(f)

out = []
for key, p in (reg.get("packages") or {}).items():
    name = p.get("name", key)
    import_name = p.get("import_name", name)
    available = False
    version = None
    if venv_present and os.access(venv_py, os.X_OK):
        try:
            r = subprocess.run(
                [venv_py, "-c",
                 "import importlib, importlib.metadata as m;"
                 "importlib.import_module(%r);"
                 "print(m.version(%r))" % (import_name, name)],
                capture_output=True, text=True, timeout=30,
            )
            if r.returncode == 0:
                available = True
                version = (r.stdout.strip() or None)
        except Exception:
            available = False
    out.append({
        "name": name,
        "import_name": import_name,
        "available": available,
        "version": version,
        "required_by": p.get("required_by", []),
    })

print(json.dumps(out))
PY
) || RESULTS="[]"

MISSING_OPTIONAL=$(echo "$RESULTS" | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
print(len([p for p in pkgs if not p['available']]))
" 2>/dev/null || echo "0")

cat <<EOF
{
  "success": true,
  "data": {
    "venv_present": $VENV_PRESENT,
    "venv_dir": "$VENV_DIR",
    "packages": $RESULTS,
    "missing_optional": $MISSING_OPTIONAL
  },
  "metadata": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "script": "$SCRIPT_NAME",
    "version": "0.1.0"
  }
}
EOF
