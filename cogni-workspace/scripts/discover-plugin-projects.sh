#!/bin/bash
# Generic per-plugin project discovery for insight-wave.
# Per-plugin discover-projects.sh wrappers (cogni-portfolio, cogni-consulting,
# cogni-trends, ...) call this script with the manifest + extractor that
# describes how their projects look on disk.
#
# Usage:
#   discover-plugin-projects.sh
#     --plugin <name>           Plugin directory name, e.g. "cogni-portfolio".
#                               Drives the walk-up target dir (an ancestor
#                               containing this subdirectory is the workspace
#                               root) and the discovery messages.
#     --registry <path>         Path to the JSON registry file (e.g.
#                               $HOME/.claude/cogni-portfolio-projects.json).
#     --extractor <path>        Path to a Python file defining
#                               `extract(project_dir: str) -> dict`. Called
#                               once per discovered project to enrich the
#                               JSON output with plugin-specific fields.
#     --find <spec>             Repeatable. Format:
#                                 <basename>:<path-glob>:<dirname-levels>
#                               e.g. "portfolio.json:*/cogni-portfolio/*:1"
#                               or   "trend-scout-output.json:*/cogni-trends/*/.metadata/*:2"
#                               dirname-levels is how many times to call
#                               dirname() on the matched file to get the
#                               project directory.
#     --maxdepth <n>            find -maxdepth (default 5).
#     --json                    Emit JSON envelope (default: one path per line).
#     --root <dir>              Override workspace root (skips resolution).
#     --register <path>         Add path to registry and exit.
#     --unregister <path>       Remove path from registry and exit.
#
# Workspace root resolution priority:
#   --root > $PROJECT_AGENTS_OPS_ROOT > walk-up from $PWD > $PWD
# The walk-up looks for an ancestor that contains a directory named after
# --plugin; this handles "user is inside <workspace>/<plugin>/<slug>/".
set -euo pipefail

JSON_OUTPUT=false
REGISTER_PATH=""
UNREGISTER_PATH=""
ROOT_OVERRIDE=""
PLUGIN_NAME=""
REGISTRY_FILE=""
EXTRACTOR_PY=""
MAXDEPTH=5
declare -a FIND_SPECS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --register) REGISTER_PATH="$2"; shift 2 ;;
    --unregister) UNREGISTER_PATH="$2"; shift 2 ;;
    --root) ROOT_OVERRIDE="$2"; shift 2 ;;
    --plugin) PLUGIN_NAME="$2"; shift 2 ;;
    --registry) REGISTRY_FILE="$2"; shift 2 ;;
    --extractor) EXTRACTOR_PY="$2"; shift 2 ;;
    --find) FIND_SPECS+=("$2"); shift 2 ;;
    --maxdepth) MAXDEPTH="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$PLUGIN_NAME" ] || [ -z "$REGISTRY_FILE" ]; then
  echo "Error: --plugin and --registry are required" >&2
  exit 2
fi

mkdir -p "$(dirname "$REGISTRY_FILE")"
if [ ! -f "$REGISTRY_FILE" ]; then
  echo '{"projects":[]}' > "$REGISTRY_FILE"
fi

# --- Register / Unregister early-exit paths ---
if [ -n "$REGISTER_PATH" ]; then
  REGISTER_PATH="$(cd "$REGISTER_PATH" 2>/dev/null && pwd || echo "$REGISTER_PATH")"
  TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  python3 -c "
import json, sys
registry_file, new_path, ts = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    reg = json.load(open(registry_file))
except Exception:
    reg = {'projects': []}
paths = [p['path'] for p in reg.get('projects', [])]
if new_path not in paths:
    reg['projects'].append({'path': new_path, 'registered': ts})
    with open(registry_file, 'w') as f:
        json.dump(reg, f, indent=2)
    print(f'Registered: {new_path}')
else:
    print(f'Already registered: {new_path}')
" "$REGISTRY_FILE" "$REGISTER_PATH" "$TIMESTAMP"
  exit 0
fi

if [ -n "$UNREGISTER_PATH" ]; then
  UNREGISTER_PATH="$(cd "$UNREGISTER_PATH" 2>/dev/null && pwd || echo "$UNREGISTER_PATH")"
  python3 -c "
import json, sys
registry_file, rm_path = sys.argv[1], sys.argv[2]
try:
    reg = json.load(open(registry_file))
except Exception:
    reg = {'projects': []}
before = len(reg.get('projects', []))
reg['projects'] = [p for p in reg.get('projects', []) if p['path'] != rm_path]
after = len(reg['projects'])
with open(registry_file, 'w') as f:
    json.dump(reg, f, indent=2)
print(f'Unregistered: {rm_path}' if before > after else f'Not found: {rm_path}')
" "$REGISTRY_FILE" "$UNREGISTER_PATH"
  exit 0
fi

# --- Workspace Root Resolution ---
if [ -n "$ROOT_OVERRIDE" ]; then
  SEARCH_ROOT="$ROOT_OVERRIDE"
elif [ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]; then
  SEARCH_ROOT="$PROJECT_AGENTS_OPS_ROOT"
else
  SEARCH_ROOT="$(pwd)"
  CURRENT="$SEARCH_ROOT"
  while [ "$CURRENT" != "/" ] && [ -n "$CURRENT" ]; do
    if [ -d "$CURRENT/$PLUGIN_NAME" ]; then
      SEARCH_ROOT="$CURRENT"
      break
    fi
    CURRENT="$(dirname "$CURRENT")"
  done
fi

# --- Discovery ---
declare -a PROJECT_DIRS=()

add_project_dir() {
  local dir="$1"
  for existing in "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"; do
    if [ "$existing" = "$dir" ]; then
      return 0
    fi
  done
  PROJECT_DIRS+=("$dir")
}

# Run each --find spec against the search root.
for spec in "${FIND_SPECS[@]+"${FIND_SPECS[@]}"}"; do
  FIND_NAME="${spec%%:*}"
  rest="${spec#*:}"
  FIND_PATH="${rest%%:*}"
  DIRNAME_LEVELS="${rest#*:}"
  while IFS= read -r f; do
    dir="$f"
    for _ in $(seq 1 "$DIRNAME_LEVELS"); do
      dir="$(dirname "$dir")"
    done
    add_project_dir "$dir"
  done < <(find "$SEARCH_ROOT" -maxdepth "$MAXDEPTH" -name "$FIND_NAME" -path "$FIND_PATH" 2>/dev/null || true)
done

# Merge registry entries (validated against the first --find basename).
PRIMARY_MANIFEST="${FIND_SPECS[0]%%:*}"
while IFS= read -r reg_path; do
  if [ -n "$reg_path" ] && [ -f "$reg_path/$PRIMARY_MANIFEST" ]; then
    add_project_dir "$reg_path"
  fi
done < <(python3 -c "
import json, sys
try:
    reg = json.load(open(sys.argv[1]))
    for p in reg.get('projects', []):
        print(p['path'])
except Exception:
    pass
" "$REGISTRY_FILE" 2>/dev/null || true)

# --- Output ---
if [ "$JSON_OUTPUT" = true ]; then
  if [ -z "$EXTRACTOR_PY" ] || [ ! -f "$EXTRACTOR_PY" ]; then
    echo "Error: --extractor is required for --json output and must point to an existing Python file" >&2
    exit 2
  fi
  python3 -c "
import json, importlib.util, sys
spec = importlib.util.spec_from_file_location('extractor', sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
search_root = sys.argv[2]
dirs = sys.argv[3:]
projects = [mod.extract(d) for d in dirs]
print(json.dumps({'count': len(projects), 'search_root': search_root, 'projects': projects}, indent=2, ensure_ascii=False))
" "$EXTRACTOR_PY" "$SEARCH_ROOT" "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"
else
  if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
    echo "No $PLUGIN_NAME projects found in $SEARCH_ROOT"
  else
    for dir in "${PROJECT_DIRS[@]}"; do
      echo "$dir"
    done
  fi
fi
