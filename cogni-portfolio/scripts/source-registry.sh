#!/bin/bash
# Manage source lineage registry for cogni-portfolio projects.
# Usage: source-registry.sh <project-dir> <command> [args...]
# Commands:
#   init                        — Create empty source-registry.json
#   register-doc <filepath>     — Compute hash and register a document source
#   check-docs                  — Compare uploads/ against registry, report changes
#   staleness                   — Walk dependency graph, output stale entities
#   status                      — Summary JSON (counts, staleness, coverage)
# Outputs JSON. Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-}"
COMMAND="${2:-}"

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"success": false, "error": "Valid project directory required. Usage: source-registry.sh <project-dir> <command> [args...]"}' >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/portfolio.json" ]; then
  echo '{"success": false, "error": "Not a cogni-portfolio project (missing portfolio.json)"}' >&2
  exit 1
fi

REGISTRY="$PROJECT_DIR/source-registry.json"
TODAY=$(date +%Y-%m-%d)

case "$COMMAND" in
  init)
    if [ -f "$REGISTRY" ]; then
      echo "{\"success\": true, \"data\": {\"action\": \"exists\", \"path\": \"$REGISTRY\"}}"
    else
      cat > "$REGISTRY" << INITEOF
{
  "version": "1.0",
  "updated": "$TODAY",
  "sources": []
}
INITEOF
      echo "{\"success\": true, \"data\": {\"action\": \"created\", \"path\": \"$REGISTRY\"}}"
    fi
    ;;

  register-doc)
    FILEPATH="${3:-}"
    if [ -z "$FILEPATH" ] || [ ! -f "$FILEPATH" ]; then
      echo '{"success": false, "error": "Valid file path required for register-doc"}' >&2
      exit 1
    fi
    # Ensure registry exists
    if [ ! -f "$REGISTRY" ]; then
      cat > "$REGISTRY" << INITEOF2
{
  "version": "1.0",
  "updated": "$TODAY",
  "sources": []
}
INITEOF2
    fi

    FILENAME=$(basename "$FILEPATH")
    HASH=$(shasum -a 256 "$FILEPATH" | cut -d' ' -f1)

    python3 -c "
import json, os, re, sys

registry_path = '$REGISTRY'
filename = '$FILENAME'
filepath = '$FILEPATH'
file_hash = 'sha256:$HASH'
today = '$TODAY'

with open(registry_path) as f:
    registry = json.load(f)

# Generate deterministic source_id from filename
name_no_ext = os.path.splitext(filename)[0]
slug = re.sub(r'[^a-z0-9]+', '-', name_no_ext.lower()).strip('-')
source_id = f'doc--{slug}'

# Check if source already exists
existing = None
for s in registry['sources']:
    if s['source_id'] == source_id:
        existing = s
        break

if existing:
    old_hash = existing.get('fingerprint', {}).get('hash', '')
    if old_hash == file_hash:
        print(json.dumps({'success': True, 'data': {'action': 'unchanged', 'source_id': source_id}}))
    else:
        existing['fingerprint'] = {'hash': file_hash, 'computed_at': today}
        existing['path'] = filepath
        existing['status'] = 'current'
        registry['updated'] = today
        with open(registry_path, 'w') as f:
            json.dump(registry, f, indent=2, ensure_ascii=False)
        print(json.dumps({'success': True, 'data': {'action': 'updated', 'source_id': source_id, 'old_hash': old_hash, 'new_hash': file_hash}}))
else:
    new_entry = {
        'source_id': source_id,
        'type': 'document',
        'filename': filename,
        'path': filepath,
        'fingerprint': {'hash': file_hash, 'computed_at': today},
        'ingested_at': today,
        'entities': [],
        'context_entries': [],
        'supersedes': None,
        'status': 'current'
    }
    registry['sources'].append(new_entry)
    registry['updated'] = today
    with open(registry_path, 'w') as f:
        json.dump(registry, f, indent=2, ensure_ascii=False)
    print(json.dumps({'success': True, 'data': {'action': 'registered', 'source_id': source_id}}))
"
    ;;

  check-docs)
    if [ ! -f "$REGISTRY" ]; then
      echo '{"success": true, "data": {"has_registry": false, "changed": [], "new": [], "missing": []}}'
      exit 0
    fi

    python3 -c "
import json, os, glob, subprocess, re

proj = '$PROJECT_DIR'
registry_path = '$REGISTRY'

with open(registry_path) as f:
    registry = json.load(f)

# Build lookup of registered doc sources by filename
registered = {}
for s in registry['sources']:
    if s['type'] == 'document' and s.get('filename'):
        registered[s['filename']] = s

# Scan uploads/ (excluding processed/)
upload_files = []
uploads_dir = os.path.join(proj, 'uploads')
if os.path.isdir(uploads_dir):
    for entry in os.listdir(uploads_dir):
        path = os.path.join(uploads_dir, entry)
        if os.path.isfile(path) and entry != '.DS_Store':
            upload_files.append((entry, path))

changed = []
new_files = []
for filename, filepath in upload_files:
    # Compute hash
    result = subprocess.run(['shasum', '-a', '256', filepath], capture_output=True, text=True)
    if result.returncode != 0:
        continue
    current_hash = 'sha256:' + result.stdout.split()[0]

    if filename in registered:
        reg_hash = registered[filename].get('fingerprint', {}).get('hash', '')
        if reg_hash != current_hash:
            source = registered[filename]
            changed.append({
                'source_id': source['source_id'],
                'filename': filename,
                'old_hash': reg_hash,
                'new_hash': current_hash,
                'entities': source.get('entities', []),
                'context_entries': source.get('context_entries', [])
            })
    else:
        new_files.append({'filename': filename, 'path': filepath})

# Check for registered docs whose files are missing from both uploads/ and processed/
missing = []
upload_names = set(f for f, _ in upload_files)
processed_dir = os.path.join(uploads_dir, 'processed')
processed_names = set()
if os.path.isdir(processed_dir):
    processed_names = set(os.listdir(processed_dir))

for filename, source in registered.items():
    if filename not in upload_names and filename not in processed_names:
        missing.append({'source_id': source['source_id'], 'filename': filename})

print(json.dumps({
    'success': True,
    'data': {
        'has_registry': True,
        'changed': changed,
        'new': new_files,
        'missing': missing
    }
}, ensure_ascii=False))
"
    ;;

  staleness)
    if [ ! -f "$REGISTRY" ]; then
      echo '{"success": true, "data": {"stale_entities": []}}'
      exit 0
    fi

    python3 -c "
import json, os, glob

proj = '$PROJECT_DIR'
registry_path = '$REGISTRY'

with open(registry_path) as f:
    registry = json.load(f)

stale = []
seen = set()

# Collect entities linked to stale/superseded sources
for source in registry['sources']:
    if source['status'] not in ('stale', 'superseded'):
        continue
    for entity_path in source.get('entities', []):
        if entity_path in seen:
            continue
        seen.add(entity_path)
        entity_type, slug = entity_path.split('/', 1) if '/' in entity_path else (entity_path, '')
        reason = f'source {source[\"source_id\"]} status: {source[\"status\"]}'
        stale.append({
            'entity': entity_type.rstrip('s'),  # features -> feature
            'slug': slug,
            'entity_path': entity_path,
            'source_id': source['source_id'],
            'reason': reason
        })

# For stale features, cascade to propositions and solutions
stale_features = set(e['slug'] for e in stale if e['entity'] == 'feature')
if stale_features:
    prop_dir = os.path.join(proj, 'propositions')
    if os.path.isdir(prop_dir):
        for pf in glob.glob(os.path.join(prop_dir, '*.json')):
            slug = os.path.basename(pf)[:-5]
            if '--' not in slug:
                continue
            f_slug = slug.split('--')[0]
            if f_slug in stale_features:
                path = f'propositions/{slug}'
                if path not in seen:
                    seen.add(path)
                    stale.append({
                        'entity': 'proposition',
                        'slug': slug,
                        'entity_path': path,
                        'source_id': None,
                        'reason': f'upstream feature {f_slug} has stale source'
                    })

# For stale propositions, cascade to solutions
stale_props = set(e['slug'] for e in stale if e['entity'] == 'proposition')
if stale_props:
    sol_dir = os.path.join(proj, 'solutions')
    if os.path.isdir(sol_dir):
        for sf in glob.glob(os.path.join(sol_dir, '*.json')):
            slug = os.path.basename(sf)[:-5]
            if slug in stale_props:
                path = f'solutions/{slug}'
                if path not in seen:
                    seen.add(path)
                    stale.append({
                        'entity': 'solution',
                        'slug': slug,
                        'entity_path': path,
                        'source_id': None,
                        'reason': f'upstream proposition {slug} has stale source'
                    })

print(json.dumps({'success': True, 'data': {'stale_entities': stale}}, ensure_ascii=False))
"
    ;;

  status)
    if [ ! -f "$REGISTRY" ]; then
      echo '{"success": true, "data": {"has_registry": false}}'
      exit 0
    fi

    python3 -c "
import json, os, glob

proj = '$PROJECT_DIR'
registry_path = '$REGISTRY'

with open(registry_path) as f:
    registry = json.load(f)

sources = registry.get('sources', [])
docs = [s for s in sources if s['type'] == 'document']
urls = [s for s in sources if s['type'] == 'url']
stale = [s for s in sources if s['status'] in ('stale', 'superseded')]
unreachable = [s for s in sources if s['status'] == 'unreachable']

# Count entities with source tracking
tracked_entities = set()
for s in sources:
    for e in s.get('entities', []):
        tracked_entities.add(e)

# Count total entities
total_entities = 0
for subdir in ['products', 'features', 'markets']:
    d = os.path.join(proj, subdir)
    if os.path.isdir(d):
        total_entities += len(glob.glob(os.path.join(d, '*.json')))

untracked = total_entities - len(tracked_entities)
if untracked < 0:
    untracked = 0

print(json.dumps({
    'success': True,
    'data': {
        'has_registry': True,
        'documents': len(docs),
        'urls': len(urls),
        'total_sources': len(sources),
        'stale_sources': len(stale),
        'unreachable_sources': len(unreachable),
        'tracked_entities': len(tracked_entities),
        'untracked_entities': untracked,
        'total_entities': total_entities
    }
}, ensure_ascii=False))
"
    ;;

  *)
    echo '{"success": false, "error": "Unknown command. Valid: init, register-doc, check-docs, staleness, status"}' >&2
    exit 1
    ;;
esac
