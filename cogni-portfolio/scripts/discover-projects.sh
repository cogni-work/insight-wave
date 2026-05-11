#!/bin/bash
# Discover cogni-portfolio projects in the workspace and project registry.
# Usage: discover-projects.sh [--json] [--root <dir>] [--register <path>] [--unregister <path>]
# Scans for portfolio.json under cogni-portfolio/ directories.
# Also checks the project registry (~/.claude/cogni-portfolio-projects.json) for projects
# created in other workspaces (e.g., OneDrive, external directories).
# Returns one line per project (default) or a JSON array (--json).
# Exit codes: 0 = success (even if 0 projects found)
set -euo pipefail

JSON_OUTPUT=false
REGISTER_PATH=""
UNREGISTER_PATH=""
ROOT_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --register) REGISTER_PATH="$2"; shift 2 ;;
    --unregister) UNREGISTER_PATH="$2"; shift 2 ;;
    --root) ROOT_OVERRIDE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# --- Project Registry ---
REGISTRY_FILE="${HOME}/.claude/cogni-portfolio-projects.json"

mkdir -p "$(dirname "$REGISTRY_FILE")"

if [ ! -f "$REGISTRY_FILE" ]; then
  echo '{"projects":[]}' > "$REGISTRY_FILE"
fi

if [ -n "$REGISTER_PATH" ]; then
  REGISTER_PATH="$(cd "$REGISTER_PATH" 2>/dev/null && pwd || echo "$REGISTER_PATH")"
  python3 -c "
import json, sys
registry_file = sys.argv[1]
new_path = sys.argv[2]
try:
    reg = json.load(open(registry_file))
except Exception:
    reg = {'projects': []}
paths = [p['path'] for p in reg.get('projects', [])]
if new_path not in paths:
    reg['projects'].append({'path': new_path, 'registered': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'})
    with open(registry_file, 'w') as f:
        json.dump(reg, f, indent=2)
    print(f'Registered: {new_path}')
else:
    print(f'Already registered: {new_path}')
" "$REGISTRY_FILE" "$REGISTER_PATH"
  exit 0
fi

if [ -n "$UNREGISTER_PATH" ]; then
  UNREGISTER_PATH="$(cd "$UNREGISTER_PATH" 2>/dev/null && pwd || echo "$UNREGISTER_PATH")"
  python3 -c "
import json, sys
registry_file = sys.argv[1]
rm_path = sys.argv[2]
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
# Priority: --root > $PROJECT_AGENTS_OPS_ROOT > walk-up from $PWD > $PWD.
# Walk-up handles the common case where the user is inside a specific project
# directory (<workspace>/cogni-portfolio/<slug>/) and would otherwise miss
# sibling projects.
if [ -n "$ROOT_OVERRIDE" ]; then
  SEARCH_ROOT="$ROOT_OVERRIDE"
elif [ -n "${PROJECT_AGENTS_OPS_ROOT:-}" ]; then
  SEARCH_ROOT="$PROJECT_AGENTS_OPS_ROOT"
else
  SEARCH_ROOT="$(pwd)"
  CURRENT="$SEARCH_ROOT"
  while [ "$CURRENT" != "/" ] && [ -n "$CURRENT" ]; do
    if [ -d "$CURRENT/cogni-portfolio" ]; then
      SEARCH_ROOT="$CURRENT"
      break
    fi
    CURRENT="$(dirname "$CURRENT")"
  done
fi

add_project_dir() {
  local dir="$1"
  for existing in "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"; do
    if [ "$existing" = "$dir" ]; then
      return 0
    fi
  done
  PROJECT_DIRS+=("$dir")
}

declare -a PROJECT_DIRS=()

while IFS= read -r f; do
  dir="$(dirname "$f")"
  add_project_dir "$dir"
done < <(find "$SEARCH_ROOT" -maxdepth 4 -name "portfolio.json" -path "*/cogni-portfolio/*" 2>/dev/null || true)

if [ -f "$REGISTRY_FILE" ]; then
  while IFS= read -r reg_path; do
    if [ -d "$reg_path" ] && [ -f "$reg_path/portfolio.json" ]; then
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
fi

if [ "$JSON_OUTPUT" = true ]; then
  python3 -c "
import json, os, sys

dirs = sys.argv[2:]
search_root = sys.argv[1]
projects = []

for d in dirs:
    project = {'path': d, 'slug': os.path.basename(d)}

    pf = os.path.join(d, 'portfolio.json')
    if os.path.exists(pf):
        try:
            data = json.load(open(pf))
            project['slug'] = data.get('slug', project['slug'])
            project['language'] = data.get('language', 'en')
            company = data.get('company', {}) or {}
            project['company_name'] = company.get('name', '')
            project['company_industry'] = company.get('industry', '')
            project['updated'] = data.get('updated', data.get('created', ''))
        except Exception:
            pass

    # Pipeline-stage flags — cheap existence checks against canonical artifacts.
    project['has_products'] = os.path.isdir(os.path.join(d, 'products'))
    project['has_features'] = os.path.isdir(os.path.join(d, 'features'))
    project['has_markets'] = os.path.isdir(os.path.join(d, 'markets'))
    project['has_propositions'] = os.path.isdir(os.path.join(d, 'propositions'))
    project['has_solutions'] = os.path.isdir(os.path.join(d, 'solutions'))
    project['has_dashboard'] = os.path.exists(os.path.join(d, 'output', 'dashboard.html'))

    projects.append(project)

print(json.dumps({'count': len(projects), 'search_root': search_root, 'projects': projects}, indent=2, ensure_ascii=False))
" "$SEARCH_ROOT" "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"
else
  if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
    echo "No cogni-portfolio projects found in $SEARCH_ROOT"
  else
    for dir in "${PROJECT_DIRS[@]}"; do
      echo "$dir"
    done
  fi
fi
