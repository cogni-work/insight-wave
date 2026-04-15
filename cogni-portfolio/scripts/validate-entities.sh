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

# Validate delivery_blueprint on products (optional — only checked when present)
if [ -d "$PROJECT_DIR/products" ]; then
  for p in "$PROJECT_DIR/products"/*.json; do
    [ -f "$p" ] || continue
    slug=$(basename "$p" .json)
    bp_exit=0
    python3 -c "
import json, sys
with open('$p') as fh:
    d = json.load(fh)
if 'delivery_blueprint' not in d:
    sys.exit(0)
bp = d['delivery_blueprint']
rm = d.get('revenue_model', 'project')
# blueprint_version is required
if 'blueprint_version' not in bp or not isinstance(bp['blueprint_version'], int) or bp['blueprint_version'] < 1:
    sys.exit(1)
# Structure must match revenue_model
if rm in ('project', '') or rm is None:
    if 'implementation' not in bp:
        sys.exit(2)
    phases = bp['implementation'].get('phases', [])
    for ph in phases:
        r = ph.get('duration_weeks_range', [])
        if len(r) != 2 or r[0] > r[1] or r[0] <= 0:
            sys.exit(3)
elif rm == 'subscription':
    if 'subscription' not in bp:
        sys.exit(2)
elif rm == 'partnership':
    if 'program' not in bp:
        sys.exit(2)
# Validate effort ratios sum to ~1.0 if present
cmd = bp.get('cost_model_defaults', {})
roles = cmd.get('roles', [])
if roles:
    total = sum(r.get('effort_ratio', 0) for r in roles)
    if abs(total - 1.0) > 0.05:
        sys.exit(4)
# Validate price_multipliers are ordered (project only)
pm = bp.get('pricing', {}).get('price_multipliers', {})
if pm:
    vals = [pm.get(t, 0) for t in ['proof_of_value','small','medium','large'] if t in pm]
    for i in range(1, len(vals)):
        if vals[i] < vals[i-1]:
            sys.exit(5)
" 2>/dev/null || bp_exit=$?
    case $bp_exit in
      0) ;; # no blueprint or valid
      1) add_error "product" "$slug" "delivery_blueprint.blueprint_version must be a positive integer" ;;
      2) add_error "product" "$slug" "delivery_blueprint structure does not match revenue_model" ;;
      3) add_error "product" "$slug" "delivery_blueprint phase duration_weeks_range must be [min, max] with min <= max and min > 0" ;;
      4) add_warning "product" "$slug" "delivery_blueprint cost_model_defaults.roles effort_ratios do not sum to ~1.0" ;;
      5) add_warning "product" "$slug" "delivery_blueprint pricing.price_multipliers are not in ascending order" ;;
    esac
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
    if 'sort_order' in d:
        so = d['sort_order']
        if not isinstance(so, int) or isinstance(so, bool): sys.exit(5)
" 2>/dev/null || exit_code=$?
    if [ "$exit_code" -eq 5 ]; then
      add_error "feature" "$slug" "sort_order must be an integer"
    elif [ "$exit_code" -eq 4 ]; then
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

# Validate excluded_markets entries on features
if [ -d "$PROJECT_DIR/features" ] && [ -d "$PROJECT_DIR/markets" ]; then
  while IFS='|' read -r level slug msg; do
    if [ "$level" = "ERROR" ]; then
      add_error "feature" "$slug" "$msg"
    else
      add_warning "feature" "$slug" "$msg"
    fi
  done < <(python3 -c "
import json, os, glob

market_files = set(os.path.basename(f)[:-5] for f in glob.glob('$PROJECT_DIR/markets/*.json'))
market_count = len(market_files)

for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        f_slug = os.path.basename(f)[:-5]
        excluded = d.get('excluded_markets', [])
        if not isinstance(excluded, list):
            print(f'ERROR|{f_slug}|excluded_markets must be an array')
            continue
        for i, exc in enumerate(excluded):
            if not isinstance(exc, dict):
                print(f'ERROR|{f_slug}|excluded_markets[{i}] must be an object with market_slug and reason')
                continue
            ms = exc.get('market_slug', '')
            reason = exc.get('reason', '')
            if not ms:
                print(f'ERROR|{f_slug}|excluded_markets[{i}] missing market_slug')
            elif ms not in market_files:
                print(f'WARN|{f_slug}|excluded_markets references non-existent market: {ms}')
            if not reason:
                print(f'ERROR|{f_slug}|excluded_markets entry for {ms} missing reason')
        if excluded and market_count > 0 and len([e for e in excluded if isinstance(e, dict) and e.get('market_slug', '') in market_files]) >= market_count:
            print(f'WARN|{f_slug}|Feature excludes ALL defined markets -- consider removing this feature from the portfolio')
    except Exception:
        pass
" 2>/dev/null)
fi

# Validate feature purpose field (optional -- only checked when present)
if [ -d "$PROJECT_DIR/features" ]; then
  while IFS='|' read -r slug msg; do
    add_warning "feature" "$slug" "$msg"
  done < <(python3 -c "
import json, os, glob
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        slug = os.path.basename(f)[:-5]
        purpose = d.get('purpose', '')
        if not purpose:
            continue
        if not isinstance(purpose, str) or not purpose.strip():
            print(f'{slug}|purpose field is present but empty')
            continue
        words = purpose.strip().split()
        if len(words) < 5:
            print(f'{slug}|purpose has only {len(words)} words (target is 5-12 words)')
        elif len(words) > 12:
            print(f'{slug}|purpose has {len(words)} words (target is 5-12 words)')
        name = d.get('name', '').strip().lower()
        if purpose.strip().lower() == name:
            print(f'{slug}|purpose is identical to name -- purpose should add information beyond the label')
    except Exception:
        pass
" 2>/dev/null)
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

# Warn on duplicate sort_order values within the same product
if [ -d "$PROJECT_DIR/features" ]; then
  while IFS='|' read -r slug msg; do
    add_warning "feature" "$slug" "$msg"
  done < <(python3 -c "
import json, os, glob
by_product = {}
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        ps = d.get('product_slug', '')
        so = d.get('sort_order')
        if so is not None and ps:
            by_product.setdefault(ps, []).append((so, os.path.basename(f)[:-5]))
    except Exception:
        pass
for ps, entries in by_product.items():
    seen = {}
    for order, slug in entries:
        if order in seen:
            print(f'{slug}|Duplicate sort_order {order} within product {ps} (also used by {seen[order]})')
        else:
            seen[order] = slug
" 2>/dev/null)
fi

# Feature description structural warning: descriptions outside 15-35 word target
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
        if len(words) < 10:
            print(f'{slug}|Description has only {len(words)} words (target is 15-35 words)')
        elif len(words) < 15:
            print(f'{slug}|Description has {len(words)} words (target is 15-35 words)')
        elif len(words) > 35:
            print(f'{slug}|Description has {len(words)} words (target is 15-35 words)')
    except Exception:
        pass
" 2>/dev/null)
fi

# Valid region codes derived from the taxonomy so the whitelist can never drift
# from regions.json. Falls back to the canonical minimum if the file is
# unreadable (defensive; should not occur in practice).
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGIONS_JSON="$PLUGIN_ROOT/skills/portfolio-setup/references/regions.json"
VALID_REGIONS=$(python3 -c "
import json
try:
    with open('$REGIONS_JSON') as fh:
        data = json.load(fh)
    print(' '.join(sorted(data.get('regions', {}).keys())))
except Exception:
    pass
" 2>/dev/null)
if [ -z "$VALID_REGIONS" ]; then
  VALID_REGIONS="de dach eu uk nordics us na cn apac jp latam mea global"
fi

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
    if 'sort_order' in d:
        so = d['sort_order']
        if not isinstance(so, int) or isinstance(so, bool): sys.exit(5)
" 2>/dev/null || exit_code=$?
    if [ "$exit_code" -eq 5 ]; then
      add_error "market" "$slug" "sort_order must be an integer"
    elif [ "$exit_code" -eq 4 ]; then
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

# Duplicate sort_order warnings
seen = {}
for m in markets:
    so = m.get('sort_order')
    slug = m['_slug']
    if so is not None:
        if so in seen:
            print(f'{slug}|Duplicate sort_order {so} (also used by {seen[so]})')
        else:
            seen[so] = slug
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

  # Validate proposition variants and tips_enrichment
  while IFS='|' read -r etype slug msg; do
    if [ "$etype" = "E" ]; then
      add_error "proposition" "$slug" "$msg"
    elif [ "$etype" = "W" ]; then
      add_warning "proposition" "$slug" "$msg"
    fi
  done < <(python3 -c "
import json, os, glob
valid_enrichment_types = {'does_refined', 'means_refined', 'evidence_added', 'variant_created', 'solution_proposed'}
valid_quality_values = {'pass', 'warn', 'fail'}
for f in glob.glob('$PROJECT_DIR/propositions/*.json'):
    try:
        d = json.load(open(f))
        slug = os.path.basename(f)[:-5]

        # Validate variants
        variants = d.get('variants', [])
        if variants:
            seen_ids = set()
            for i, v in enumerate(variants):
                vid = v.get('variant_id')
                if not vid:
                    print(f'E|{slug}|Variant at index {i} missing variant_id')
                elif vid in seen_ids:
                    print(f'E|{slug}|Duplicate variant_id: {vid}')
                else:
                    seen_ids.add(vid)
                for req in ['angle', 'tips_ref', 'value_chain_narrative', 'does_statement', 'means_statement']:
                    if req not in v:
                        print(f'E|{slug}|Variant {vid or i} missing required field: {req}')
                qs = v.get('quality_score')
                if qs is not None and qs not in valid_quality_values:
                    print(f'W|{slug}|Variant {vid} has unexpected quality_score: {qs}')

        # Validate tips_enrichment
        te = d.get('tips_enrichment')
        if te:
            if 'pursuit_slug' not in te:
                print(f'E|{slug}|tips_enrichment missing pursuit_slug')
            if 'enriched_at' not in te:
                print(f'W|{slug}|tips_enrichment missing enriched_at timestamp')
            for et in te.get('enrichment_type', []):
                if et not in valid_enrichment_types:
                    print(f'W|{slug}|tips_enrichment has unknown enrichment_type: {et}')

        # Validate quality_assessment
        qa = d.get('quality_assessment')
        if qa:
            if qa.get('overall') not in valid_quality_values:
                print(f'E|{slug}|quality_assessment.overall must be pass/warn/fail')
            if 'assessed_at' not in qa:
                print(f'W|{slug}|quality_assessment missing assessed_at date')
    except Exception:
        pass
" 2>/dev/null)

  # Proposition DOES/MEANS structural warning: word counts outside 15-30 target
  # Deep quality assessment (buyer-centricity, market-specificity, differentiation,
  # escalation, quantification) is handled by the proposition-quality-assessor agent.
  while IFS='|' read -r slug msg; do
    add_warning "proposition" "$slug" "$msg"
  done < <(python3 -c "
import json, os, glob
for f in glob.glob('$PROJECT_DIR/propositions/*.json'):
    try:
        d = json.load(open(f))
        slug = os.path.basename(f)[:-5]
        for field in ['does_statement', 'means_statement']:
            text = d.get(field, '')
            words = text.split()
            label = 'DOES' if 'does' in field else 'MEANS'
            if len(words) < 10:
                print(f'{slug}|{label} has only {len(words)} words (target is 15-30 words)')
            elif len(words) < 15:
                print(f'{slug}|{label} has {len(words)} words (target is 15-30 words)')
            elif len(words) > 30:
                print(f'{slug}|{label} has {len(words)} words (target is 15-30 words)')
    except Exception:
        pass
" 2>/dev/null)
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
    # Validate blueprint_ref consistency
    python3 -c "
import json, sys
with open('$s') as fh:
    d = json.load(fh)
bp_ref = d.get('blueprint_ref')
bp_ver = d.get('blueprint_version')
if bp_ref is None and bp_ver is None:
    sys.exit(0)  # no blueprint reference — OK
if bp_ref is not None and bp_ver is None:
    sys.exit(1)  # blueprint_ref without blueprint_version
if bp_ref is None and bp_ver is not None:
    sys.exit(2)  # blueprint_version without blueprint_ref
# Check referenced product exists and has a blueprint
import os
prod_path = os.path.join('$PROJECT_DIR', 'products', bp_ref + '.json')
if not os.path.isfile(prod_path):
    sys.exit(3)  # product not found
with open(prod_path) as pfh:
    prod = json.load(pfh)
if 'delivery_blueprint' not in prod:
    sys.exit(4)  # product has no blueprint
" 2>/dev/null && bp_rc=0 || bp_rc=$?
    case $bp_rc in
      0) ;; # valid or no blueprint ref
      1) add_warning "solution" "$slug" "blueprint_ref present but blueprint_version missing" ;;
      2) add_warning "solution" "$slug" "blueprint_version present but blueprint_ref missing" ;;
      3) add_warning "solution" "$slug" "blueprint_ref references non-existent product" ;;
      4) add_warning "solution" "$slug" "blueprint_ref references product without delivery_blueprint" ;;
    esac
    # Validate shared_solution_ref consistency
    python3 -c "
import json, sys, os
with open('$s') as fh:
    d = json.load(fh)
ref = d.get('shared_solution_ref')
overlay = d.get('messaging_overlay', False)
if ref is None and not overlay:
    sys.exit(0)  # not a shared solution — OK
if overlay and ref is None:
    sys.exit(1)  # messaging_overlay=true but no shared_solution_ref
if ref is not None and not overlay:
    sys.exit(2)  # shared_solution_ref present but messaging_overlay not set
# Check referenced shared solution exists
shared_path = os.path.join('$PROJECT_DIR', 'solutions', ref + '.json')
if not os.path.isfile(shared_path):
    sys.exit(3)  # shared reference not found
# Verify commercial fields match the reference
with open(shared_path) as sfh:
    shared = json.load(sfh)
# Compare pricing fields based on solution type
sol_type = d.get('solution_type', 'project')
if sol_type in ('subscription', 'hybrid'):
    s_tiers = d.get('subscription', {}).get('tiers', {})
    r_tiers = shared.get('subscription', {}).get('tiers', {})
    for tier_name in r_tiers:
        st = s_tiers.get(tier_name, {})
        rt = r_tiers[tier_name]
        if st.get('price_monthly') != rt.get('price_monthly') or st.get('price_annual') != rt.get('price_annual'):
            sys.exit(4)  # pricing drift
elif sol_type == 'project':
    s_pricing = d.get('pricing', {})
    r_pricing = shared.get('pricing', {})
    for tier_name in r_pricing:
        if s_pricing.get(tier_name, {}).get('price') != r_pricing[tier_name].get('price'):
            sys.exit(4)  # pricing drift
" 2>/dev/null && shared_rc=0 || shared_rc=$?
    case $shared_rc in
      0) ;; # valid or not a shared solution
      1) add_warning "solution" "$slug" "messaging_overlay is true but shared_solution_ref is missing" ;;
      2) add_warning "solution" "$slug" "shared_solution_ref present but messaging_overlay not set to true" ;;
      3) add_error "solution" "$slug" "shared_solution_ref references non-existent file" ;;
      4) add_warning "solution" "$slug" "Pricing drift detected — commercial fields differ from shared reference" ;;
    esac
  done
fi

# Validate shared reference solutions in solutions/_shared/
if [ -d "$PROJECT_DIR/solutions/_shared" ]; then
  for s in "$PROJECT_DIR/solutions/_shared"/*.json; do
    [ -f "$s" ] || continue
    slug="_shared/$(basename "$s" .json)"
    python3 -c "
import json, sys, os
with open('$s') as fh:
    d = json.load(fh)
if not d.get('shared_solution'):
    sys.exit(1)  # missing shared_solution marker
prod_slug = d.get('product_slug')
market_slug = d.get('market_slug')
if not prod_slug or not market_slug:
    sys.exit(2)  # missing product_slug or market_slug
prod_path = os.path.join('$PROJECT_DIR', 'products', prod_slug + '.json')
if not os.path.isfile(prod_path):
    sys.exit(3)  # referenced product not found
with open(prod_path) as pfh:
    prod = json.load(pfh)
if not prod.get('shared_solution'):
    sys.exit(4)  # product not marked as shared_solution
" 2>/dev/null && shared_ref_rc=0 || shared_ref_rc=$?
    case $shared_ref_rc in
      0) ;; # valid
      1) add_warning "solution" "$slug" "File in _shared/ but missing shared_solution: true marker" ;;
      2) add_error "solution" "$slug" "Shared reference missing product_slug or market_slug" ;;
      3) add_error "solution" "$slug" "Shared reference product_slug references non-existent product" ;;
      4) add_warning "solution" "$slug" "Shared reference product not marked with shared_solution: true" ;;
    esac
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

# Validate taxonomy_mapping on features when portfolio has taxonomy
if [ -f "$PROJECT_DIR/portfolio.json" ] && [ -d "$PROJECT_DIR/features" ]; then
  while IFS='|' read -r etype slug msg; do
    if [ "$etype" = "E" ]; then
      add_error "feature" "$slug" "$msg"
    elif [ "$etype" = "W" ]; then
      add_warning "feature" "$slug" "$msg"
    fi
  done < <(python3 -c "
import json, os, glob

pf = json.load(open('$PROJECT_DIR/portfolio.json'))
taxonomy = pf.get('taxonomy')
if not taxonomy:
    exit(0)

tax_type = taxonomy.get('type', '')

# Build valid category IDs for b2b-ict
valid_categories = {}
if tax_type == 'b2b-ict':
    dim_cats = {
        0: [('0.1','Financial Scale'),('0.2','Workforce Capacity'),('0.3','Geographic Presence'),('0.4','Market Position'),('0.5','Certifications & Accreditations'),('0.6','Partnership Ecosystem')],
        1: [('1.1','WAN Services'),('1.2','SASE'),('1.3','Internet & Cloud Connect'),('1.4','5G & IoT Connectivity'),('1.5','Voice Services'),('1.6','LAN/WLAN Services'),('1.7','Network-as-a-Service')],
        2: [('2.1','Security Operations (SOC/SIEM)'),('2.2','Identity & Access Management'),('2.3','Zero Trust Architecture'),('2.4','Cloud Security'),('2.5','Endpoint Security'),('2.6','Network Security'),('2.7','Vulnerability Management'),('2.8','Security Awareness'),('2.9','Compliance & GRC'),('2.10','Data Protection & Privacy')],
        3: [('3.1','Unified Communications'),('3.2','Modern Workplace / M365'),('3.3','Device Management'),('3.4','Virtual Desktop & DaaS'),('3.5','IT Support Services'),('3.6','Digital Employee Experience'),('3.7','IT Asset Management')],
        4: [('4.1','Managed Hyperscaler Services'),('4.2','Multi-Cloud Management'),('4.3','Private Cloud'),('4.4','Hybrid Cloud'),('4.5','Cloud Migration Services'),('4.6','Cloud-Native Platform'),('4.7','Sovereign Cloud'),('4.8','Enterprise Platforms on Cloud')],
        5: [('5.1','Data Center Services'),('5.2','Managed Compute & Storage'),('5.3','Backup & Disaster Recovery'),('5.4','Infrastructure Monitoring'),('5.5','IT Outsourcing (ITO)'),('5.6','Database Administration'),('5.7','Infrastructure Automation')],
        6: [('6.1','Custom Application Development'),('6.2','Application Modernization'),('6.3','Enterprise Platform Services'),('6.4','System Integration & API'),('6.5','Low-Code/No-Code Platforms'),('6.6','AI, Data & Analytics'),('6.7','DevOps & Platform Engineering')],
        7: [('7.1','IT Strategy & Architecture'),('7.2','Digital Transformation'),('7.3','Business & Industry Consulting'),('7.4','Program & Project Management'),('7.5','Vendor & Contract Management')],
    }
    for dim, cats in dim_cats.items():
        for cid, cname in cats:
            valid_categories[cid] = (dim, cname)

valid_horizons = {'current', 'emerging', 'future'}
features_with_mapping = 0
features_without_mapping = 0
dim_counts = {}

for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        slug = os.path.basename(f)[:-5]
        tm = d.get('taxonomy_mapping')
        if not tm:
            features_without_mapping += 1
            continue

        features_with_mapping += 1

        # Validate dimension range
        dim = tm.get('dimension')
        if dim is not None and (not isinstance(dim, int) or dim < 0 or dim > 7):
            print(f'E|{slug}|taxonomy_mapping.dimension must be 0-7, got {dim}')

        # Validate category_id against taxonomy
        cid = tm.get('category_id', '')
        if cid and valid_categories and cid not in valid_categories:
            print(f'E|{slug}|taxonomy_mapping.category_id {cid} is not a valid {tax_type} category')
        elif cid and valid_categories:
            expected_dim = valid_categories[cid][0]
            if dim is not None and dim != expected_dim:
                print(f'E|{slug}|taxonomy_mapping.dimension {dim} does not match category_id {cid} (expected dimension {expected_dim})')

        # Validate horizon
        horizon = tm.get('horizon')
        if horizon and horizon not in valid_horizons:
            print(f'E|{slug}|taxonomy_mapping.horizon must be current/emerging/future, got {horizon}')

        # Track dimension coverage
        if dim is not None:
            dim_counts[dim] = dim_counts.get(dim, 0) + 1

    except Exception:
        pass

# Warn if taxonomy set but no features mapped
if features_with_mapping == 0 and features_without_mapping > 0:
    print(f'W|portfolio|Portfolio has taxonomy set but no features have taxonomy_mapping')

# Warn on dimensions with zero features
if valid_categories:
    for dim in range(8):
        if dim_counts.get(dim, 0) == 0 and features_with_mapping > 0:
            dim_names = {0:'Provider Profile',1:'Connectivity',2:'Security',3:'Digital Workplace',4:'Cloud',5:'Managed Infrastructure',6:'Application',7:'Consulting'}
            print(f'W|portfolio|Dimension {dim} ({dim_names[dim]}) has no mapped features')
" 2>/dev/null)
fi

# Cross-validate TIPS blueprint building block references against portfolio features
# Looks for linked TIPS projects via portfolio-context.json back-references
if [ -d "$PROJECT_DIR/features" ]; then
  # Search for TIPS value models that reference this portfolio
  WORKSPACE_ROOT="$(dirname "$PROJECT_DIR")"
  WORKSPACE_PARENT="$(dirname "$WORKSPACE_ROOT")"
  for search_dir in "$WORKSPACE_ROOT" "$WORKSPACE_PARENT"; do
    if [ -d "$search_dir" ]; then
      for vm in "$search_dir"/cogni-trends/*/tips-value-model.json "$search_dir"/*/tips-value-model.json; do
        [ -f "$vm" ] 2>/dev/null || continue
        while IFS='|' read -r etype slug msg; do
          if [ "$etype" = "E" ]; then
            add_error "blueprint" "$slug" "$msg"
          elif [ "$etype" = "W" ]; then
            add_warning "blueprint" "$slug" "$msg"
          fi
        done < <(python3 -c "
import json, os, glob

vm = json.load(open('$vm'))
sts = vm.get('solution_templates', [])

# Collect all existing feature slugs
feature_slugs = set()
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    feature_slugs.add(os.path.basename(f)[:-5])

if not feature_slugs:
    exit(0)

for st in sts:
    bp = st.get('solution_blueprint')
    if not bp:
        continue
    st_name = st.get('name', st.get('st_id', 'unknown'))
    for block in bp.get('building_blocks', []):
        fs = block.get('feature_slug')
        if fs and fs not in feature_slugs:
            print(f'W|{st_name}|Blueprint building block references feature \"{fs}\" which does not exist in portfolio')
        ps = block.get('product_slug')
        if ps and not os.path.exists(os.path.join('$PROJECT_DIR', 'products', ps + '.json')):
            print(f'W|{st_name}|Blueprint building block references product \"{ps}\" which does not exist in portfolio')
" 2>/dev/null)
        break 2  # Only check the first value model found
      done
    fi
  done
fi

# Validate context entries
if [ -d "$PROJECT_DIR/context" ]; then
  VALID_CATEGORIES="competitive market pricing customer technical strategic"
  VALID_SKILLS="propositions solutions markets compete customers features packages"

  for ctx_file in "$PROJECT_DIR/context"/*.json; do
    [ -f "$ctx_file" ] || continue
    ctx_base=$(basename "$ctx_file")
    # Skip the index file
    [ "$ctx_base" = "context-index.json" ] && continue

    python3 -c "
import json, sys
with open('$ctx_file') as f:
    data = json.load(f)

errors_found = []
for field in ['slug', 'source_file', 'category', 'relevance', 'summary', 'detail', 'confidence', 'created']:
    if field not in data or not data[field]:
        errors_found.append(f'Missing required field: {field}')

cat = data.get('category', '')
if cat and cat not in '$VALID_CATEGORIES'.split():
    errors_found.append(f'Invalid category: {cat}')

conf = data.get('confidence', '')
if conf and conf not in ['high', 'medium', 'low']:
    errors_found.append(f'Invalid confidence: {conf}')

relevance = data.get('relevance', [])
if isinstance(relevance, list):
    for r in relevance:
        if r not in '$VALID_SKILLS'.split():
            errors_found.append(f'Invalid relevance skill: {r}')

# Validate entity references point to actual portfolio files
import os
entities = data.get('entities', {})
if isinstance(entities, dict):
    for entity_type in ['products', 'features', 'markets']:
        for slug in entities.get(entity_type, []):
            entity_path = os.path.join('$PROJECT_DIR', entity_type, slug + '.json')
            if not os.path.exists(entity_path):
                errors_found.append(f'entities.{entity_type} references missing {entity_type[:-1]}: {slug}')

for err in errors_found:
    print(f'E|{err}')
" 2>/dev/null | while IFS='|' read -r level msg; do
      add_error "context" "$ctx_base" "$msg"
    done
  done

  # Validate context-index.json consistency
  if [ -f "$PROJECT_DIR/context/context-index.json" ]; then
    python3 -c "
import json, os, glob, sys
with open('$PROJECT_DIR/context/context-index.json') as f:
    idx = json.load(f)

actual_files = set()
for f in glob.glob('$PROJECT_DIR/context/*.json'):
    b = os.path.basename(f)
    if b != 'context-index.json':
        actual_files.add(b[:-5])  # slug without .json

indexed_slugs = set()
for cat_slugs in idx.get('by_category', {}).values():
    indexed_slugs.update(cat_slugs)

missing_in_index = actual_files - indexed_slugs
extra_in_index = indexed_slugs - actual_files

if missing_in_index:
    print(f'W|Context files not in index: {sorted(missing_in_index)}')
if extra_in_index:
    print(f'W|Index references missing files: {sorted(extra_in_index)}')
" 2>/dev/null | while IFS='|' read -r level msg; do
      add_warning "context-index" "context-index.json" "$msg"
    done
  fi
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
