#!/bin/bash
# Propagate resolved claim corrections to portfolio entity JSON files.
# Usage: propagate-corrections.sh <mode> <project-dir> [args...]
#
# Modes:
#   apply <project-dir> <entity-file> <field-path> <new-value>
#     Set a specific field in the entity JSON to the new value.
#     Validates that the field exists before replacing.
#
#   remove <project-dir> <entity-file> <field-path>
#     Remove a field or array element from entity JSON.
#
#   find-text <project-dir> <search-text>
#     Search for text across entity JSON files (markets/, customers/,
#     competitors/, propositions/). Returns matching files and field paths.
#     Used as fallback for claims without entity_ref.
#
#   update-source <project-dir> <entity-file> <field-path> <new-url> <new-title>
#     Update source_url and source_title at the given path.
#
# Field path syntax:
#   - Dot-notation: tam.value, tam.description
#   - Array index: evidence[0].statement, competitors[1].positioning
#   - Name-based lookup: named_customers[?name=="Siemens AG"].revenue.value
#     competitors[?name=="Datadog"].positioning
#
# Output: JSON status on stdout
# Exit codes: 0 = success, 1 = error
set -euo pipefail

MODE="${1:-}"
PROJECT_DIR="${2:-}"

if [ -z "$MODE" ] || [ -z "$PROJECT_DIR" ]; then
  echo '{"success": false, "error": "Usage: propagate-corrections.sh <mode> <project-dir> [args...]"}' >&2
  exit 1
fi

case "$MODE" in
  apply)
    ENTITY_FILE="${3:-}"
    FIELD_PATH="${4:-}"
    NEW_VALUE="${5:-}"
    if [ -z "$ENTITY_FILE" ] || [ -z "$FIELD_PATH" ] || [ -z "$NEW_VALUE" ]; then
      echo '{"success": false, "error": "Usage: propagate-corrections.sh apply <project-dir> <entity-file> <field-path> <new-value>"}' >&2
      exit 1
    fi
    FULL_PATH="$PROJECT_DIR/$ENTITY_FILE"
    if [ ! -f "$FULL_PATH" ]; then
      echo "{\"success\": false, \"error\": \"Entity file not found: $ENTITY_FILE\"}" >&2
      exit 1
    fi
    python3 -c "
import json, sys, re

entity_file = sys.argv[1]
field_path = sys.argv[2]
new_value = sys.argv[3]

def resolve_path(data, path):
    \"\"\"Resolve a dot-notation field path with array index and name-based lookup support.
    Returns (parent, key, old_value) or raises KeyError.\"\"\"
    parts = re.split(r'\.(?![^\[]*\])', path)
    current = data
    parent = None
    last_key = None

    for i, part in enumerate(parts):
        parent = current
        # Name-based array lookup: field[?name==\"Value\"]
        name_match = re.match(r'^(\w+)\[\?(\w+)==\"([^\"]+)\"\]$', part)
        # Numeric array index: field[0]
        idx_match = re.match(r'^(\w+)\[(\d+)\]$', part)

        if name_match:
            arr_field = name_match.group(1)
            lookup_key = name_match.group(2)
            lookup_val = name_match.group(3)
            current = current[arr_field]
            found = False
            for j, item in enumerate(current):
                if item.get(lookup_key) == lookup_val:
                    parent = current
                    last_key = j
                    current = item
                    found = True
                    break
            if not found:
                raise KeyError(f'No element with {lookup_key}==\"{lookup_val}\" in {arr_field}')
        elif idx_match:
            arr_field = idx_match.group(1)
            idx = int(idx_match.group(2))
            current = current[arr_field]
            parent = current
            last_key = idx
            current = current[idx]
        else:
            last_key = part
            current = current[part]

    return parent, last_key, current

with open(entity_file, 'r') as f:
    data = json.load(f)

try:
    parent, key, old_value = resolve_path(data, field_path)
except (KeyError, IndexError, TypeError) as e:
    print(json.dumps({'success': False, 'error': f'Field path resolution failed: {e}'}))
    sys.exit(1)

# Try to parse new_value as a number if it looks like one
try:
    if '.' in new_value:
        typed_value = float(new_value)
    else:
        typed_value = int(new_value)
except ValueError:
    typed_value = new_value

old_str = json.dumps(old_value) if not isinstance(old_value, str) else old_value
parent[key] = typed_value

with open(entity_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(json.dumps({
    'success': True,
    'data': {
        'file': sys.argv[4],
        'field_path': field_path,
        'old_value': old_str,
        'new_value': str(typed_value)
    }
}))
" "$FULL_PATH" "$FIELD_PATH" "$NEW_VALUE" "$ENTITY_FILE"
    ;;

  remove)
    ENTITY_FILE="${3:-}"
    FIELD_PATH="${4:-}"
    if [ -z "$ENTITY_FILE" ] || [ -z "$FIELD_PATH" ]; then
      echo '{"success": false, "error": "Usage: propagate-corrections.sh remove <project-dir> <entity-file> <field-path>"}' >&2
      exit 1
    fi
    FULL_PATH="$PROJECT_DIR/$ENTITY_FILE"
    if [ ! -f "$FULL_PATH" ]; then
      echo "{\"success\": false, \"error\": \"Entity file not found: $ENTITY_FILE\"}" >&2
      exit 1
    fi
    python3 -c "
import json, sys, re

entity_file = sys.argv[1]
field_path = sys.argv[2]

def resolve_path(data, path):
    parts = re.split(r'\.(?![^\[]*\])', path)
    current = data
    parent = None
    last_key = None

    for i, part in enumerate(parts):
        parent = current
        name_match = re.match(r'^(\w+)\[\?(\w+)==\"([^\"]+)\"\]$', part)
        idx_match = re.match(r'^(\w+)\[(\d+)\]$', part)

        if name_match:
            arr_field = name_match.group(1)
            lookup_key = name_match.group(2)
            lookup_val = name_match.group(3)
            current = current[arr_field]
            found = False
            for j, item in enumerate(current):
                if item.get(lookup_key) == lookup_val:
                    parent = current
                    last_key = j
                    current = item
                    found = True
                    break
            if not found:
                raise KeyError(f'No element with {lookup_key}==\"{lookup_val}\" in {arr_field}')
        elif idx_match:
            arr_field = idx_match.group(1)
            idx = int(idx_match.group(2))
            current = current[arr_field]
            parent = current
            last_key = idx
            current = current[idx]
        else:
            last_key = part
            current = current[part]

    return parent, last_key, current

with open(entity_file, 'r') as f:
    data = json.load(f)

try:
    parent, key, old_value = resolve_path(data, field_path)
except (KeyError, IndexError, TypeError) as e:
    print(json.dumps({'success': False, 'error': f'Field path resolution failed: {e}'}))
    sys.exit(1)

old_str = json.dumps(old_value) if not isinstance(old_value, str) else old_value

if isinstance(parent, list):
    parent.pop(key)
elif isinstance(parent, dict):
    del parent[key]

with open(entity_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(json.dumps({
    'success': True,
    'data': {
        'file': sys.argv[3],
        'field_path': field_path,
        'removed_value': old_str
    }
}))
" "$FULL_PATH" "$FIELD_PATH" "$ENTITY_FILE"
    ;;

  find-text)
    SEARCH_TEXT="${3:-}"
    if [ -z "$SEARCH_TEXT" ]; then
      echo '{"success": false, "error": "Usage: propagate-corrections.sh find-text <project-dir> <search-text>"}' >&2
      exit 1
    fi
    python3 -c "
import json, sys, os, glob

project_dir = sys.argv[1]
search_text = sys.argv[2]

# Search across entity directories
entity_dirs = ['markets', 'customers', 'competitors', 'propositions']
matches = []

def search_json(obj, path_prefix, text, matches_list, file_rel):
    \"\"\"Recursively search JSON values for text content.\"\"\"
    if isinstance(obj, str) and text.lower() in obj.lower():
        matches_list.append({
            'file': file_rel,
            'field_path': path_prefix,
            'value': obj
        })
    elif isinstance(obj, dict):
        for k, v in obj.items():
            search_json(v, f'{path_prefix}.{k}' if path_prefix else k, text, matches_list, file_rel)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            search_json(v, f'{path_prefix}[{i}]', text, matches_list, file_rel)

for entity_dir in entity_dirs:
    full_dir = os.path.join(project_dir, entity_dir)
    if not os.path.isdir(full_dir):
        continue
    for json_file in glob.glob(os.path.join(full_dir, '*.json')):
        try:
            with open(json_file, 'r') as f:
                data = json.load(f)
            rel_path = os.path.relpath(json_file, project_dir)
            search_json(data, '', search_text, matches, rel_path)
        except (json.JSONDecodeError, IOError):
            continue

print(json.dumps({
    'success': True,
    'data': {
        'search_text': search_text,
        'match_count': len(matches),
        'matches': matches
    }
}))
" "$PROJECT_DIR" "$SEARCH_TEXT"
    ;;

  update-source)
    ENTITY_FILE="${3:-}"
    FIELD_PATH="${4:-}"
    NEW_URL="${5:-}"
    NEW_TITLE="${6:-}"
    if [ -z "$ENTITY_FILE" ] || [ -z "$FIELD_PATH" ] || [ -z "$NEW_URL" ]; then
      echo '{"success": false, "error": "Usage: propagate-corrections.sh update-source <project-dir> <entity-file> <field-path> <new-url> [new-title]"}' >&2
      exit 1
    fi
    FULL_PATH="$PROJECT_DIR/$ENTITY_FILE"
    if [ ! -f "$FULL_PATH" ]; then
      echo "{\"success\": false, \"error\": \"Entity file not found: $ENTITY_FILE\"}" >&2
      exit 1
    fi
    python3 -c "
import json, sys, re

entity_file = sys.argv[1]
field_path = sys.argv[2]
new_url = sys.argv[3]
new_title = sys.argv[4] if len(sys.argv) > 4 else None

def resolve_path(data, path):
    parts = re.split(r'\.(?![^\[]*\])', path)
    current = data
    parent = None
    last_key = None

    for i, part in enumerate(parts):
        parent = current
        name_match = re.match(r'^(\w+)\[\?(\w+)==\"([^\"]+)\"\]$', part)
        idx_match = re.match(r'^(\w+)\[(\d+)\]$', part)

        if name_match:
            arr_field = name_match.group(1)
            lookup_key = name_match.group(2)
            lookup_val = name_match.group(3)
            current = current[arr_field]
            found = False
            for j, item in enumerate(current):
                if item.get(lookup_key) == lookup_val:
                    parent = current
                    last_key = j
                    current = item
                    found = True
                    break
            if not found:
                raise KeyError(f'No element with {lookup_key}==\"{lookup_val}\" in {arr_field}')
        elif idx_match:
            arr_field = idx_match.group(1)
            idx = int(idx_match.group(2))
            current = current[arr_field]
            parent = current
            last_key = idx
            current = current[idx]
        else:
            last_key = part
            current = current[part]

    return parent, last_key, current

with open(entity_file, 'r') as f:
    data = json.load(f)

try:
    parent, key, current = resolve_path(data, field_path)
except (KeyError, IndexError, TypeError) as e:
    print(json.dumps({'success': False, 'error': f'Field path resolution failed: {e}'}))
    sys.exit(1)

# The resolved element should be an object with source_url
target = current if isinstance(current, dict) else parent[key] if isinstance(parent[key], dict) else None
if target is None or not isinstance(target, dict):
    # Try parent as the object containing source fields
    target = parent if isinstance(parent, dict) and isinstance(key, str) else None

updates = {}
if target and isinstance(target, dict):
    if 'source_url' in target:
        updates['old_source_url'] = target['source_url']
        target['source_url'] = new_url
    elif 'source' in target:
        updates['old_source'] = target['source']
        target['source'] = new_url
    if new_title:
        if 'source_title' in target:
            updates['old_source_title'] = target['source_title']
            target['source_title'] = new_title
else:
    print(json.dumps({'success': False, 'error': 'Could not locate source fields at the given path'}))
    sys.exit(1)

with open(entity_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(json.dumps({
    'success': True,
    'data': {
        'file': sys.argv[5] if len(sys.argv) > 5 else entity_file,
        'field_path': field_path,
        'new_url': new_url,
        'new_title': new_title,
        **updates
    }
}))
" "$FULL_PATH" "$FIELD_PATH" "$NEW_URL" "$NEW_TITLE" "$ENTITY_FILE"
    ;;

  *)
    echo "{\"success\": false, \"error\": \"Unknown mode: $MODE. Use: apply, remove, find-text, update-source\"}" >&2
    exit 1
    ;;
esac
