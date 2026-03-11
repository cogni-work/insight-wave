#!/bin/bash
# Sync portfolio.json with the current state of products/ directory.
# Updates company.products array and the updated timestamp.
# Usage: sync-portfolio.sh <project-dir>
# Exit codes: 0 = synced, 1 = no changes needed, 2 = usage error
set -euo pipefail

PROJECT_DIR="${1:-}"

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Usage: sync-portfolio.sh <project-dir>"}' >&2
  exit 2
fi

if [ ! -f "$PROJECT_DIR/portfolio.json" ]; then
  echo '{"error": "No portfolio.json found in project directory"}' >&2
  exit 2
fi

python3 -c "
import json, os, sys
from datetime import date

project_dir = sys.argv[1]
pf_path = os.path.join(project_dir, 'portfolio.json')

with open(pf_path) as f:
    data = json.load(f)

# Handle legacy format: company as string
if isinstance(data.get('company'), str):
    data['company'] = {
        'name': data['company'],
        'description': data.get('description', ''),
        'industry': data.get('industry', ''),
        'products': []
    }
    # Remove top-level fields that moved into company
    for key in ['description', 'industry']:
        data.pop(key, None)

# Ensure company is a dict with products array
company = data.setdefault('company', {})
if not isinstance(company, dict):
    company = {'name': str(company), 'products': []}
    data['company'] = company

# Read current product slugs from products/ directory
products_dir = os.path.join(project_dir, 'products')
current_slugs = []
if os.path.isdir(products_dir):
    for fname in sorted(os.listdir(products_dir)):
        if fname.endswith('.json'):
            current_slugs.append(fname[:-5])

old_slugs = sorted(company.get('products', []))
today = date.today().isoformat()

if sorted(current_slugs) == old_slugs and data.get('updated') == today:
    print(json.dumps({'synced': False, 'reason': 'already up to date'}))
    sys.exit(1)

company['products'] = current_slugs
data['updated'] = today

with open(pf_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(json.dumps({
    'synced': True,
    'products': current_slugs,
    'updated': today
}))
" "$PROJECT_DIR"
