#!/bin/bash
# Cascade a slug rename across all dependent entity files.
# Usage: cascade-rename.sh <project-dir> <entity-type> <old-slug> <new-slug>
#   entity-type: feature | market | product | proposition
# Exit codes: 0 = done, 2 = usage error
set -euo pipefail

PROJECT_DIR="${1:-}"
ENTITY_TYPE="${2:-}"
OLD_SLUG="${3:-}"
NEW_SLUG="${4:-}"

if [ -z "$PROJECT_DIR" ] || [ -z "$ENTITY_TYPE" ] || [ -z "$OLD_SLUG" ] || [ -z "$NEW_SLUG" ]; then
  echo '{"error": "Usage: cascade-rename.sh <project-dir> <entity-type> <old-slug> <new-slug>"}' >&2
  exit 2
fi

python3 -c "
import json, os, sys, glob

project_dir = sys.argv[1]
entity_type = sys.argv[2]
old_slug = sys.argv[3]
new_slug = sys.argv[4]

changes = []

def read_json(path):
    with open(path) as f:
        return json.load(f)

def write_json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def rename_file(old_path, new_path, updates):
    \"\"\"Rename a file and update JSON fields inside it.\"\"\"
    if not os.path.exists(old_path):
        return False
    data = read_json(old_path)
    for key, value in updates.items():
        if key in data:
            data[key] = value
    write_json(new_path, data)
    if old_path != new_path:
        os.remove(old_path)
    changes.append({'file': os.path.basename(new_path), 'action': 'renamed' if old_path != new_path else 'updated'})
    return True

def update_field_in_dir(directory, field, old_val, new_val, extra_updates=None):
    \"\"\"Update a field value in all JSON files in a directory.\"\"\"
    if not os.path.isdir(directory):
        return
    for fname in os.listdir(directory):
        if not fname.endswith('.json'):
            continue
        fpath = os.path.join(directory, fname)
        data = read_json(fpath)
        if data.get(field) == old_val:
            data[field] = new_val
            if extra_updates:
                for k, v in extra_updates.items():
                    if k in data:
                        data[k] = v
            write_json(fpath, data)
            changes.append({'file': fname, 'action': 'updated', 'field': field})

props_dir = os.path.join(project_dir, 'propositions')
solutions_dir = os.path.join(project_dir, 'solutions')
packages_dir = os.path.join(project_dir, 'packages')
competitors_dir = os.path.join(project_dir, 'competitors')
customers_dir = os.path.join(project_dir, 'customers')

if entity_type == 'feature':
    # Propositions: {feature}--{market}.json -> rename files where feature matches
    if os.path.isdir(props_dir):
        for fname in list(os.listdir(props_dir)):
            if not fname.endswith('.json'):
                continue
            slug = fname[:-5]
            if slug.startswith(old_slug + '--'):
                market_part = slug[len(old_slug) + 2:]
                new_prop_slug = f'{new_slug}--{market_part}'
                old_path = os.path.join(props_dir, fname)
                new_path = os.path.join(props_dir, f'{new_prop_slug}.json')
                rename_file(old_path, new_path, {
                    'slug': new_prop_slug,
                    'feature_slug': new_slug
                })
                # Cascade to solutions and competitors that reference this proposition
                old_sol = os.path.join(solutions_dir, fname)
                new_sol = os.path.join(solutions_dir, f'{new_prop_slug}.json')
                rename_file(old_sol, new_sol, {
                    'slug': new_prop_slug,
                    'proposition_slug': new_prop_slug
                })
                old_comp = os.path.join(competitors_dir, fname)
                new_comp = os.path.join(competitors_dir, f'{new_prop_slug}.json')
                rename_file(old_comp, new_comp, {
                    'slug': new_prop_slug,
                    'proposition_slug': new_prop_slug,
                    'feature_slug': new_slug
                })

    # Packages: update included_solutions references that contain the old feature slug
    if os.path.isdir(packages_dir):
        for fname in os.listdir(packages_dir):
            if not fname.endswith('.json'):
                continue
            fpath = os.path.join(packages_dir, fname)
            data = read_json(fpath)
            modified = False
            for tier in data.get('tiers', []):
                new_included = []
                for sol_slug in tier.get('included_solutions', []):
                    if sol_slug.startswith(old_slug + '--'):
                        market_part = sol_slug[len(old_slug) + 2:]
                        new_included.append(f'{new_slug}--{market_part}')
                        modified = True
                    else:
                        new_included.append(sol_slug)
                tier['included_solutions'] = new_included
            if modified:
                write_json(fpath, data)
                changes.append({'file': fname, 'action': 'updated', 'field': 'included_solutions'})

elif entity_type == 'market':
    # Propositions: {feature}--{market}.json -> rename files where market matches
    if os.path.isdir(props_dir):
        for fname in list(os.listdir(props_dir)):
            if not fname.endswith('.json'):
                continue
            slug = fname[:-5]
            if slug.endswith('--' + old_slug):
                feature_part = slug[:-(len(old_slug) + 2)]
                new_prop_slug = f'{feature_part}--{new_slug}'
                old_path = os.path.join(props_dir, fname)
                new_path = os.path.join(props_dir, f'{new_prop_slug}.json')
                rename_file(old_path, new_path, {
                    'slug': new_prop_slug,
                    'market_slug': new_slug
                })
                # Cascade to solutions and competitors
                old_sol = os.path.join(solutions_dir, fname)
                new_sol = os.path.join(solutions_dir, f'{new_prop_slug}.json')
                rename_file(old_sol, new_sol, {
                    'slug': new_prop_slug,
                    'proposition_slug': new_prop_slug
                })
                old_comp = os.path.join(competitors_dir, fname)
                new_comp = os.path.join(competitors_dir, f'{new_prop_slug}.json')
                rename_file(old_comp, new_comp, {
                    'slug': new_prop_slug,
                    'proposition_slug': new_prop_slug,
                    'market_slug': new_slug
                })
    # Customers: {market}.json
    old_cust = os.path.join(customers_dir, f'{old_slug}.json')
    new_cust = os.path.join(customers_dir, f'{new_slug}.json')
    rename_file(old_cust, new_cust, {
        'slug': new_slug,
        'market_slug': new_slug
    })

    # Packages: {product}--{market}.json -> rename files where market matches
    if os.path.isdir(packages_dir):
        for fname in list(os.listdir(packages_dir)):
            if not fname.endswith('.json'):
                continue
            pkg_slug = fname[:-5]
            if pkg_slug.endswith('--' + old_slug):
                product_part = pkg_slug[:-(len(old_slug) + 2)]
                new_pkg_slug = f'{product_part}--{new_slug}'
                old_path = os.path.join(packages_dir, fname)
                new_path = os.path.join(packages_dir, f'{new_pkg_slug}.json')
                # Also update included_solutions references
                data = read_json(old_path)
                data['slug'] = new_pkg_slug
                data['market_slug'] = new_slug
                for tier in data.get('tiers', []):
                    new_included = []
                    for sol_slug in tier.get('included_solutions', []):
                        if sol_slug.endswith('--' + old_slug):
                            feature_part = sol_slug[:-(len(old_slug) + 2)]
                            new_included.append(f'{feature_part}--{new_slug}')
                        else:
                            new_included.append(sol_slug)
                    tier['included_solutions'] = new_included
                write_json(new_path, data)
                if old_path != new_path:
                    os.remove(old_path)
                changes.append({'file': os.path.basename(new_path), 'action': 'renamed'})

elif entity_type == 'product':
    # Packages: {product}--{market}.json -> rename files where product matches
    if os.path.isdir(packages_dir):
        for fname in list(os.listdir(packages_dir)):
            if not fname.endswith('.json'):
                continue
            pkg_slug = fname[:-5]
            if pkg_slug.startswith(old_slug + '--'):
                market_part = pkg_slug[len(old_slug) + 2:]
                new_pkg_slug = f'{new_slug}--{market_part}'
                old_path = os.path.join(packages_dir, fname)
                new_path = os.path.join(packages_dir, f'{new_pkg_slug}.json')
                rename_file(old_path, new_path, {
                    'slug': new_pkg_slug,
                    'product_slug': new_slug
                })

elif entity_type == 'proposition':
    # Solutions and competitors reference proposition_slug
    old_sol = os.path.join(solutions_dir, f'{old_slug}.json')
    new_sol = os.path.join(solutions_dir, f'{new_slug}.json')
    rename_file(old_sol, new_sol, {
        'slug': new_slug,
        'proposition_slug': new_slug
    })
    old_comp = os.path.join(competitors_dir, f'{old_slug}.json')
    new_comp = os.path.join(competitors_dir, f'{new_slug}.json')
    rename_file(old_comp, new_comp, {
        'slug': new_slug,
        'proposition_slug': new_slug
    })

else:
    print(json.dumps({'error': f'Unknown entity type: {entity_type}. Use: feature, market, product, proposition'}))
    sys.exit(2)

print(json.dumps({'entity_type': entity_type, 'old_slug': old_slug, 'new_slug': new_slug, 'changes': changes}))
" "$PROJECT_DIR" "$ENTITY_TYPE" "$OLD_SLUG" "$NEW_SLUG"
