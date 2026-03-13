#!/bin/bash
# Discover cogni-tips projects in the workspace and project registry.
# Usage: discover-projects.sh [--json] [--register <path>] [--unregister <path>]
# Scans for tips-project.json and trend-scout-output.json under cogni-tips/ directories.
# Also checks the project registry (~/.claude/cogni-tips-projects.json) for projects
# created in other workspaces (e.g., OneDrive, external directories).
# Returns one line per project (default) or a JSON array (--json).
# Exit codes: 0 = success (even if 0 projects found)
set -euo pipefail

JSON_OUTPUT=false
REGISTER_PATH=""
UNREGISTER_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --register) REGISTER_PATH="$2"; shift 2 ;;
    --unregister) UNREGISTER_PATH="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# --- Project Registry ---
REGISTRY_FILE="${HOME}/.claude/cogni-tips-projects.json"

# Ensure registry directory exists
mkdir -p "$(dirname "$REGISTRY_FILE")"

# Initialize registry if missing
if [ ! -f "$REGISTRY_FILE" ]; then
  echo '{"projects":[]}' > "$REGISTRY_FILE"
fi

# Handle --register: add a project path to the registry
if [ -n "$REGISTER_PATH" ]; then
  # Resolve to absolute path
  REGISTER_PATH="$(cd "$REGISTER_PATH" 2>/dev/null && pwd || echo "$REGISTER_PATH")"
  python3 -c "
import json, sys, os
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

# Handle --unregister: remove a project path from the registry
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

# --- Discovery ---
SEARCH_ROOT="${PROJECT_AGENTS_OPS_ROOT:-$(pwd)}"

# Helper: add a directory to PROJECT_DIRS if not already present
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

# Method 1: tips-project.json in cogni-tips/*/ (local workspace)
while IFS= read -r f; do
  dir="$(dirname "$f")"
  add_project_dir "$dir"
done < <(find "$SEARCH_ROOT" -maxdepth 4 -name "tips-project.json" -path "*/cogni-tips/*" 2>/dev/null || true)

# Method 2: trend-scout-output.json fallback (local workspace)
while IFS= read -r f; do
  dir="$(dirname "$(dirname "$f")")"  # go up from .metadata/
  add_project_dir "$dir"
done < <(find "$SEARCH_ROOT" -maxdepth 5 -name "trend-scout-output.json" -path "*/cogni-tips/*/.metadata/*" 2>/dev/null || true)

# Method 3: Project registry — include projects from other workspaces
if [ -f "$REGISTRY_FILE" ]; then
  while IFS= read -r reg_path; do
    # Only include if the directory still exists and contains a valid project
    if [ -d "$reg_path" ] && { [ -f "$reg_path/tips-project.json" ] || [ -f "$reg_path/.metadata/trend-scout-output.json" ]; }; then
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

dirs = sys.argv[1:]
projects = []

for d in dirs:
    project = {'path': d, 'slug': os.path.basename(d)}

    # Try tips-project.json first
    pf = os.path.join(d, 'tips-project.json')
    if os.path.exists(pf):
        try:
            data = json.load(open(pf))
            project['slug'] = data.get('slug', project['slug'])
            project['language'] = data.get('language', 'en')
            ind = data.get('industry', {})
            project['industry'] = ind.get('primary_en') or ind.get('primary') or ''
            project['subsector'] = ind.get('subsector_en') or ind.get('subsector') or ''
            project['research_topic'] = data.get('research_topic') or ''
            project['updated'] = data.get('updated', data.get('created', ''))
        except Exception:
            pass

    # Enrich with workflow state from trend-scout-output.json
    sf = os.path.join(d, '.metadata', 'trend-scout-output.json')
    if os.path.exists(sf):
        try:
            data = json.load(open(sf))
            exe = data.get('execution', {})
            project['workflow_state'] = exe.get('workflow_state', 'unknown')
            project['candidates_total'] = data.get('tips_candidates', {}).get('total', 0)
            # Fill gaps from scout output if tips-project.json was sparse
            if not project.get('industry'):
                ind = data.get('config', {}).get('industry', {})
                project['industry'] = ind.get('primary_en') or ind.get('primary') or ''
                project['subsector'] = ind.get('subsector_en') or ind.get('subsector') or ''
            if not project.get('research_topic'):
                project['research_topic'] = data.get('config', {}).get('research_topic') or ''
            if not project.get('language'):
                project['language'] = data.get('project_language', 'en')
        except Exception:
            project.setdefault('workflow_state', 'unknown')
            project.setdefault('candidates_total', 0)

    # Check for report
    project['has_report'] = os.path.exists(os.path.join(d, 'tips-trend-report.md'))

    projects.append(project)

print(json.dumps({'count': len(projects), 'projects': projects}, indent=2, ensure_ascii=False))
" "${PROJECT_DIRS[@]+"${PROJECT_DIRS[@]}"}"
else
  if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
    echo "No cogni-tips projects found in $SEARCH_ROOT"
  else
    for dir in "${PROJECT_DIRS[@]}"; do
      echo "$dir"
    done
  fi
fi
