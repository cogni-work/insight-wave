#!/bin/bash
# Validate cogni-portfolio project data model integrity.
# Usage: validate-entities.sh <project-dir>
# Checks: required fields, referential integrity, naming conventions.
# Outputs JSON with errors array and valid boolean.
# Exit codes: 0 = valid, 1 = errors found, 2 = usage error
set -euo pipefail

PROJECT_DIR="${1:-}"

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Usage: validate-entities.sh <project-dir>"}' >&2
  exit 2
fi

errors="["
first=true
warnings="["
first_warning=true

add_error() {
  if $first; then first=false; else errors="$errors, "; fi
  errors="$errors{\"entity\": \"$1\", \"file\": \"$2\", \"message\": \"$3\"}"
}

add_warning() {
  if $first_warning; then first_warning=false; else warnings="$warnings, "; fi
  warnings="$warnings{\"entity\": \"$1\", \"file\": \"$2\", \"message\": \"$3\"}"
}

# Check portfolio.json exists and has required fields
if [ ! -f "$PROJECT_DIR/portfolio.json" ]; then
  add_error "portfolio" "portfolio.json" "Missing portfolio.json"
fi

# Check portfolio.json company.products matches actual products/ directory
if [ -f "$PROJECT_DIR/portfolio.json" ] && [ -d "$PROJECT_DIR/products" ]; then
  python3 -c "
import json, os, sys
pf = json.load(open('$PROJECT_DIR/portfolio.json'))
company = pf.get('company', pf)
listed = sorted(company.get('products', [])) if isinstance(company, dict) else []
actual = sorted(f[:-5] for f in os.listdir('$PROJECT_DIR/products') if f.endswith('.json'))
if listed != actual:
    missing_in_pf = [s for s in actual if s not in listed]
    extra_in_pf = [s for s in listed if s not in actual]
    msgs = []
    if missing_in_pf: msgs.append('products/ has ' + ', '.join(missing_in_pf) + ' not listed in portfolio.json')
    if extra_in_pf: msgs.append('portfolio.json lists ' + ', '.join(extra_in_pf) + ' not found in products/')
    print('; '.join(msgs))
    sys.exit(1)
" 2>/dev/null || {
    sync_msg=$(python3 -c "
import json, os
pf = json.load(open('$PROJECT_DIR/portfolio.json'))
company = pf.get('company', pf)
listed = sorted(company.get('products', [])) if isinstance(company, dict) else []
actual = sorted(f[:-5] for f in os.listdir('$PROJECT_DIR/products') if f.endswith('.json'))
missing = [s for s in actual if s not in listed]
extra = [s for s in listed if s not in actual]
msgs = []
if missing: msgs.append('products/ has ' + ', '.join(missing) + ' not in portfolio.json')
if extra: msgs.append('portfolio.json lists ' + ', '.join(extra) + ' not in products/')
print('; '.join(msgs))
" 2>/dev/null)
    add_error "portfolio" "portfolio.json" "Product list out of sync: $sync_msg. Run sync-portfolio.sh to fix."
  }
fi

# Validate products have required fields (slug, name, description)
if [ -d "$PROJECT_DIR/products" ]; then
  for p in "$PROJECT_DIR/products"/*.json; do
    [ -f "$p" ] || continue
    slug=$(basename "$p" .json)
    if ! python3 -c "
import json, sys
with open('$p') as fh:
    d = json.load(fh)
    if 'name' not in d: sys.exit(1)
    if 'description' not in d: sys.exit(1)
    if 'slug' in d and d['slug'] != '$slug': sys.exit(2)
    if 'maturity' in d and d['maturity'] not in ['concept','development','launch','growth','mature','decline']: sys.exit(3)
" 2>/dev/null; then
      add_error "product" "$slug" "Invalid JSON, missing required field (name, description), or invalid maturity value"
    fi
  done
fi

# Validate features have required fields (slug, name, description, product_slug)
if [ -d "$PROJECT_DIR/features" ]; then
  for f in "$PROJECT_DIR/features"/*.json; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .json)
    # Check file is valid JSON and has required fields
    exit_code=0
    python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
    if 'name' not in d: sys.exit(1)
    if 'description' not in d: sys.exit(1)
    if 'slug' in d and d['slug'] != '$slug': sys.exit(2)
    if 'product_slug' not in d: sys.exit(3)
    if 'readiness' in d and d['readiness'] not in ['ga', 'beta', 'planned']: sys.exit(4)
" 2>/dev/null || exit_code=$?
    if [ "$exit_code" -eq 4 ]; then
      add_error "feature" "$slug" "Invalid readiness value -- must be one of: ga, beta, planned"
    elif [ "$exit_code" -ne 0 ]; then
      add_error "feature" "$slug" "Invalid JSON, missing required field (name, description), or missing product_slug"
    else
      # Check referenced product exists
      p_slug=$(python3 -c "import json; print(json.load(open('$f')).get('product_slug',''))" 2>/dev/null)
      if [ -n "$p_slug" ] && [ ! -f "$PROJECT_DIR/products/${p_slug}.json" ]; then
        add_error "feature" "$slug" "References missing product: $p_slug"
      fi
    fi
  done
fi

# Warn on singleton categories (possible typos)
if [ -d "$PROJECT_DIR/features" ]; then
  while IFS='|' read -r slug msg; do
    add_warning "feature" "$slug" "$msg"
  done < <(python3 -c "
import json, os, glob
cats = {}
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        c = d.get('category')
        if c:
            cats.setdefault(c, []).append(os.path.basename(f)[:-5])
    except Exception:
        pass
for cat, slugs in cats.items():
    if len(slugs) == 1:
        print(f'{slugs[0]}|Category {cat} is used by only one feature -- possible typo')
" 2>/dev/null)
fi

# Feature description structural warning: very short descriptions
# Deep quality assessment (mechanism clarity, customer relevance, language quality)
# is handled by the feature-quality-assessor agent, which works in any language.
if [ -d "$PROJECT_DIR/features" ]; then
  while IFS='|' read -r slug msg; do
    add_warning "feature" "$slug" "$msg"
  done < <(python3 -c "
import json, os, glob
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        slug = os.path.basename(f)[:-5]
        desc = d.get('description', '')
        words = desc.split()
        if len(words) < 15:
            print(f'{slug}|Description has only {len(words)} words (minimum 15 recommended)')
    except Exception:
        pass
" 2>/dev/null)
fi

# Valid region codes from the taxonomy
VALID_REGIONS="de dach eu uk nordics us na cn apac jp latam mea global"

# Validate markets have required fields (slug, name, region, description)
if [ -d "$PROJECT_DIR/markets" ]; then
  for m in "$PROJECT_DIR/markets"/*.json; do
    [ -f "$m" ] || continue
    slug=$(basename "$m" .json)
    exit_code=0
    python3 -c "
import json, sys
with open('$m') as fh:
    d = json.load(fh)
    if 'name' not in d: sys.exit(1)
    if 'description' not in d: sys.exit(1)
    if 'slug' in d and d['slug'] != '$slug': sys.exit(2)
    if 'region' not in d: sys.exit(3)
    if 'priority' in d and d['priority'] not in ['beachhead', 'expansion', 'aspirational']: sys.exit(4)
" 2>/dev/null || exit_code=$?
    if [ "$exit_code" -eq 4 ]; then
      add_error "market" "$slug" "Invalid priority value -- must be one of: beachhead, expansion, aspirational"
    elif [ "$exit_code" -ne 0 ]; then
      add_error "market" "$slug" "Invalid JSON or missing required field (name, description, region)"
    else
      # Validate region code against taxonomy
      region=$(python3 -c "import json; print(json.load(open('$m')).get('region',''))" 2>/dev/null)
      region_valid=false
      for r in $VALID_REGIONS; do
        if [ "$region" = "$r" ]; then region_valid=true; break; fi
      done
      if [ "$region_valid" = "false" ]; then
        add_error "market" "$slug" "Invalid region '$region' -- must be one of: $VALID_REGIONS"
      fi
    fi
  done

  # Market overlap detection and SAM/TAM ratio warnings
  while IFS='|' read -r slug msg; do
    add_warning "market" "$slug" "$msg"
  done < <(python3 -c "
import json, os, glob
markets = []
for f in sorted(glob.glob('$PROJECT_DIR/markets/*.json')):
    try:
        d = json.load(open(f))
        d['_slug'] = os.path.basename(f)[:-5]
        markets.append(d)
    except Exception:
        pass

# SAM/TAM and SOM/SAM ratio warnings
for m in markets:
    tam_v = (m.get('tam') or {}).get('value')
    sam_v = (m.get('sam') or {}).get('value')
    som_v = (m.get('som') or {}).get('value')
    if tam_v and sam_v and tam_v > 0:
        ratio = sam_v / tam_v
        if ratio > 0.5:
            print(f'{m[\"_slug\"]}|SAM/TAM ratio is {ratio:.0%} (>50%) -- SAM may be overestimated')
    if sam_v and som_v and sam_v > 0:
        ratio = som_v / sam_v
        if ratio > 0.2:
            print(f'{m[\"_slug\"]}|SOM/SAM ratio is {ratio:.0%} (>20%) -- SOM may be overestimated')

# Overlap detection: same region + overlapping employee/ARR ranges + shared verticals
for i, a in enumerate(markets):
    for b in markets[i+1:]:
        if a.get('region') != b.get('region'):
            continue
        sa = a.get('segmentation', {})
        sb = b.get('segmentation', {})
        # Check employee range overlap
        a_emin = sa.get('employees_min')
        a_emax = sa.get('employees_max')
        b_emin = sb.get('employees_min')
        b_emax = sb.get('employees_max')
        emp_overlap = True  # assume overlap if ranges not defined
        if all(v is not None for v in [a_emin, a_emax, b_emin, b_emax]):
            emp_overlap = a_emin <= b_emax and b_emin <= a_emax
        # Check vertical overlap
        a_verts = set(sa.get('vertical_codes', []))
        b_verts = set(sb.get('vertical_codes', []))
        vert_overlap = True  # assume overlap if verticals not defined
        if a_verts and b_verts:
            vert_overlap = bool(a_verts & b_verts)
        if emp_overlap and vert_overlap:
            print(f'{a[\"_slug\"]}|Potential overlap with {b[\"_slug\"]} in region {a.get(\"region\")} (shared employee range and verticals)')
            print(f'{b[\"_slug\"]}|Potential overlap with {a[\"_slug\"]} in region {a.get(\"region\")} (shared employee range and verticals)')
" 2>/dev/null)
fi

# Validate propositions reference valid features and markets
if [ -d "$PROJECT_DIR/propositions" ]; then
  for s in "$PROJECT_DIR/propositions"/*.json; do
    [ -f "$s" ] || continue
    slug=$(basename "$s" .json)
    # Check naming convention: feature-slug--market-slug
    if [[ "$slug" != *"--"* ]]; then
      add_error "proposition" "$slug" "Invalid naming: expected feature-slug--market-slug"
      continue
    fi
    f_slug="${slug%%--*}"
    m_slug="${slug#*--}"
    # Check referenced feature exists
    if [ ! -f "$PROJECT_DIR/features/${f_slug}.json" ]; then
      add_error "proposition" "$slug" "References missing feature: $f_slug"
    fi
    # Check referenced market exists
    if [ ! -f "$PROJECT_DIR/markets/${m_slug}.json" ]; then
      add_error "proposition" "$slug" "References missing market: $m_slug"
    fi
    # Check required fields including foreign keys
    if ! python3 -c "
import json, sys
with open('$s') as fh:
    d = json.load(fh)
    for field in ['feature_slug', 'market_slug', 'is_statement', 'does_statement', 'means_statement']:
        if field not in d: sys.exit(1)
" 2>/dev/null; then
      add_error "proposition" "$slug" "Missing required fields (feature_slug, market_slug, is_statement, does_statement, means_statement)"
    fi
  done
fi

# Validate solutions reference valid propositions and have required structure
if [ -d "$PROJECT_DIR/solutions" ]; then
  for s in "$PROJECT_DIR/solutions"/*.json; do
    [ -f "$s" ] || continue
    slug=$(basename "$s" .json)
    if [ ! -f "$PROJECT_DIR/propositions/${slug}.json" ]; then
      add_error "solution" "$slug" "References missing proposition: $slug"
    fi
    exit_code=0
    python3 -c "
import json, sys
with open('$s') as fh:
    d = json.load(fh)
    if 'proposition_slug' not in d: sys.exit(1)
    sol_type = d.get('solution_type', 'project')

    if sol_type in ('project', ''):
        # Project solutions require implementation + pricing
        impl = d.get('implementation')
        if not isinstance(impl, list) or len(impl) == 0: sys.exit(2)
        for phase in impl:
            if 'phase' not in phase or 'duration_weeks' not in phase: sys.exit(3)
            dw = phase.get('duration_weeks')
            if not isinstance(dw, (int, float)) and not (isinstance(dw, str) and dw.isdigit()):
                sys.exit(6)
        pricing = d.get('pricing')
        if not isinstance(pricing, dict): sys.exit(4)
        for tier in ['proof_of_value', 'small', 'medium', 'large']:
            t = pricing.get(tier)
            if not isinstance(t, dict) or 'price' not in t or 'currency' not in t: sys.exit(5)

    elif sol_type in ('subscription', 'hybrid'):
        # Subscription/hybrid solutions require subscription object
        sub = d.get('subscription')
        if not isinstance(sub, dict): sys.exit(7)
        if 'tiers' not in sub or 'currency' not in sub: sys.exit(8)

    elif sol_type == 'partnership':
        # Partnership solutions require program object
        prog = d.get('program')
        if not isinstance(prog, dict): sys.exit(9)
        if 'stages' not in prog or 'revenue_share' not in prog: sys.exit(10)

    else:
        sys.exit(11)
" 2>/dev/null || exit_code=$?
    if [ "$exit_code" -eq 6 ]; then
      add_warning "solution" "$slug" "Non-numeric duration_weeks value (e.g. 'ongoing') — accepted but may affect duration totals"
    elif [ "$exit_code" -eq 7 ] || [ "$exit_code" -eq 8 ]; then
      add_error "solution" "$slug" "Subscription/hybrid solution missing required subscription object (needs tiers, currency)"
    elif [ "$exit_code" -eq 9 ] || [ "$exit_code" -eq 10 ]; then
      add_error "solution" "$slug" "Partnership solution missing required program object (needs stages, revenue_share)"
    elif [ "$exit_code" -eq 11 ]; then
      add_error "solution" "$slug" "Invalid solution_type — must be project, subscription, partnership, or hybrid"
    elif [ "$exit_code" -ne 0 ]; then
      add_error "solution" "$slug" "Missing required fields or invalid structure (needs proposition_slug, implementation phases, pricing tiers)"
    fi
  done
fi

# Validate packages reference valid products, markets, and solutions
if [ -d "$PROJECT_DIR/packages" ]; then
  for p in "$PROJECT_DIR/packages"/*.json; do
    [ -f "$p" ] || continue
    slug=$(basename "$p" .json)
    # Check naming convention: product-slug--market-slug
    if [[ "$slug" != *"--"* ]]; then
      add_error "package" "$slug" "Invalid naming: expected product-slug--market-slug"
      continue
    fi
    exit_code=0
    python3 -c "
import json, sys, os

with open('$p') as fh:
    d = json.load(fh)

# Required fields
for field in ['product_slug', 'market_slug', 'package_type', 'name', 'tiers']:
    if field not in d:
        sys.exit(1)

# Validate package_type
if d['package_type'] not in ('project', 'subscription', 'hybrid'):
    sys.exit(7)

# Validate product exists
if not os.path.exists(os.path.join('$PROJECT_DIR', 'products', d['product_slug'] + '.json')):
    sys.exit(2)

# Validate market exists
if not os.path.exists(os.path.join('$PROJECT_DIR', 'markets', d['market_slug'] + '.json')):
    sys.exit(3)

# Validate tiers
tiers = d.get('tiers', [])
if not isinstance(tiers, list) or len(tiers) == 0:
    sys.exit(4)

for tier in tiers:
    if 'tier' not in tier or 'name' not in tier or 'included_solutions' not in tier or 'scope' not in tier or 'currency' not in tier:
        sys.exit(5)
    # Check all included solutions exist
    for sol_slug in tier.get('included_solutions', []):
        if not os.path.exists(os.path.join('$PROJECT_DIR', 'solutions', sol_slug + '.json')):
            sys.exit(6)

# Validate package_type matches product revenue_model
try:
    with open(os.path.join('$PROJECT_DIR', 'products', d['product_slug'] + '.json')) as pf:
        product = json.load(pf)
    revenue_model = product.get('revenue_model', 'project')
    pkg_type = d['package_type']
    if revenue_model == 'partnership':
        sys.exit(8)  # partnerships don't typically use packages
    if revenue_model != pkg_type and not (revenue_model == '' and pkg_type == 'project'):
        sys.exit(8)
except (FileNotFoundError, json.JSONDecodeError):
    pass
" 2>/dev/null || exit_code=$?
    case "$exit_code" in
      1) add_error "package" "$slug" "Missing required fields (product_slug, market_slug, package_type, name, tiers)" ;;
      2) add_error "package" "$slug" "References missing product: $(python3 -c "import json; print(json.load(open('$p')).get('product_slug',''))" 2>/dev/null)" ;;
      3) add_error "package" "$slug" "References missing market: $(python3 -c "import json; print(json.load(open('$p')).get('market_slug',''))" 2>/dev/null)" ;;
      4) add_error "package" "$slug" "Tiers must be a non-empty array" ;;
      5) add_error "package" "$slug" "Tier missing required fields (tier, name, included_solutions, scope, currency)" ;;
      6) add_error "package" "$slug" "References missing solution in included_solutions" ;;
      7) add_error "package" "$slug" "Invalid package_type — must be project, subscription, or hybrid" ;;
      8) add_warning "package" "$slug" "package_type does not match product revenue_model" ;;
    esac
  done
fi

# Validate competitors reference valid propositions
if [ -d "$PROJECT_DIR/competitors" ]; then
  for c in "$PROJECT_DIR/competitors"/*.json; do
    [ -f "$c" ] || continue
    slug=$(basename "$c" .json)
    if [ ! -f "$PROJECT_DIR/propositions/${slug}.json" ]; then
      add_error "competitor" "$slug" "References missing proposition: $slug"
    fi
  done
fi

# Validate customers reference valid markets
if [ -d "$PROJECT_DIR/customers" ]; then
  for c in "$PROJECT_DIR/customers"/*.json; do
    [ -f "$c" ] || continue
    slug=$(basename "$c" .json)
    if [ ! -f "$PROJECT_DIR/markets/${slug}.json" ]; then
      add_error "customer" "$slug" "References missing market: $slug"
    fi
  done
fi

errors="$errors]"
warnings="$warnings]"

if $first; then
  echo "{\"valid\": true, \"errors\": [], \"warnings\": $warnings}"
  exit 0
else
  echo "{\"valid\": false, \"errors\": $errors, \"warnings\": $warnings}"
  exit 1
fi
