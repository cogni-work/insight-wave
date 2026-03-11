#!/bin/bash
# Show cogni-portfolio project status with entity counts and gap analysis.
# Usage: project-status.sh <project-dir> [--health-check]
# Outputs JSON with counts, feature/market slugs, missing propositions, and completion ratios.
# With --health-check: also includes stale_entities array (downstream entities
# whose upstream updated date or mtime is newer).
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-}"
HEALTH_CHECK=false
if [ "${2:-}" = "--health-check" ]; then
  HEALTH_CHECK=true
fi

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Valid project directory required. Usage: project-status.sh <project-dir>"}' >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/portfolio.json" ]; then
  echo '{"error": "Not a cogni-portfolio project (missing portfolio.json)"}' >&2
  exit 1
fi

# Count JSON files in a subdirectory
count_json() {
  local dir="$PROJECT_DIR/$1"
  if [ -d "$dir" ]; then
    local n
    n=$(find "$dir" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l)
    echo "$n" | tr -d ' '
  else
    echo "0"
  fi
}

PRODUCTS=$(count_json "products")
FEATURES=$(count_json "features")
MARKETS=$(count_json "markets")
PROPOSITIONS=$(count_json "propositions")
SOLUTIONS=$(count_json "solutions")
PACKAGES=$(count_json "packages")
COMPETITORS=$(count_json "competitors")
CUSTOMERS=$(count_json "customers")
EXPECTED_PROPOSITIONS=$((FEATURES * MARKETS))

# Collect product slugs as JSON array
product_arr="["
first=true
if [ -d "$PROJECT_DIR/products" ]; then
  for p in "$PROJECT_DIR/products"/*.json; do
    [ -f "$p" ] || continue
    slug=$(basename "$p" .json)
    if $first; then first=false; else product_arr="$product_arr, "; fi
    product_arr="$product_arr\"$slug\""
  done
fi
product_arr="$product_arr]"

# Collect feature slugs as JSON array
feature_arr="["
first=true
if [ -d "$PROJECT_DIR/features" ]; then
  for f in "$PROJECT_DIR/features"/*.json; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .json)
    if $first; then first=false; else feature_arr="$feature_arr, "; fi
    feature_arr="$feature_arr\"$slug\""
  done
fi
feature_arr="$feature_arr]"

# Collect market slugs as JSON array and build region summary
market_arr="["
first=true
if [ -d "$PROJECT_DIR/markets" ]; then
  for m in "$PROJECT_DIR/markets"/*.json; do
    [ -f "$m" ] || continue
    slug=$(basename "$m" .json)
    if $first; then first=false; else market_arr="$market_arr, "; fi
    market_arr="$market_arr\"$slug\""
  done
fi
market_arr="$market_arr]"

# Build region summary: {"dach": 2, "us": 1, ...}
region_summary="{}"
if [ -d "$PROJECT_DIR/markets" ]; then
  region_summary=$(python3 -c "
import json, os, glob
counts = {}
for f in glob.glob('$PROJECT_DIR/markets/*.json'):
    try:
        with open(f) as fh:
            d = json.load(fh)
        r = d.get('region', 'unknown')
        counts[r] = counts.get(r, 0) + 1
    except Exception:
        pass
print(json.dumps(counts, sort_keys=True))
" 2>/dev/null || echo "{}")
fi

# Build readiness summary: {"ga": 3, "beta": 1, "planned": 2, "unset": 1}
readiness_summary="{}"
features_without_readiness=0
if [ -d "$PROJECT_DIR/features" ]; then
  eval "$(python3 -c "
import json, os, glob
counts = {}
unset = 0
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        r = d.get('readiness')
        if r:
            counts[r] = counts.get(r, 0) + 1
        else:
            unset += 1
    except Exception:
        pass
if unset > 0:
    counts['unset'] = unset
import json as j
print(f'readiness_summary={chr(39)}{j.dumps(counts, sort_keys=True)}{chr(39)}')
print(f'features_without_readiness={unset}')
" 2>/dev/null)"
fi

# Build priority summary: {"beachhead": 1, "expansion": 2, "aspirational": 1, "unset": 0}
priority_summary="{}"
markets_without_priority=0
if [ -d "$PROJECT_DIR/markets" ]; then
  eval "$(python3 -c "
import json, os, glob
counts = {}
unset = 0
for f in glob.glob('$PROJECT_DIR/markets/*.json'):
    try:
        d = json.load(open(f))
        p = d.get('priority')
        if p:
            counts[p] = counts.get(p, 0) + 1
        else:
            unset += 1
    except Exception:
        pass
if unset > 0:
    counts['unset'] = unset
import json as j
print(f'priority_summary={chr(39)}{j.dumps(counts, sort_keys=True)}{chr(39)}')
print(f'markets_without_priority={unset}')
" 2>/dev/null)"
fi

# Count feature structural warnings (short descriptions only).
# Deep quality assessment (mechanism, customer relevance, language) is handled
# by the feature-quality-assessor agent, which works in any language.
feature_quality_warnings=0
feature_quality_slugs="["
fq_first=true
if [ -d "$PROJECT_DIR/features" ]; then
  eval "$(python3 -c "
import json, os, glob
warned = []
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        slug = os.path.basename(f)[:-5]
        desc = d.get('description', '')
        words = desc.split()
        if len(words) < 15:
            warned.append(slug)
    except Exception:
        pass
import json as j
print(f'feature_quality_warnings={len(warned)}')
slugs = ', '.join(f'\"' + s + '\"' for s in warned)
print(f'feature_quality_slugs={chr(39)}[{slugs}]{chr(39)}')
" 2>/dev/null)"
fi

# Find missing propositions (Feature x Market pairs without a proposition file)
missing_arr="["
missing_sol_arr="["
first=true
sol_first=true
if [ "$FEATURES" -gt 0 ] && [ "$MARKETS" -gt 0 ]; then
  for f in "$PROJECT_DIR/features"/*.json; do
    [ -f "$f" ] || continue
    f_slug=$(basename "$f" .json)
    for m in "$PROJECT_DIR/markets"/*.json; do
      [ -f "$m" ] || continue
      m_slug=$(basename "$m" .json)
      pair="${f_slug}--${m_slug}"
      prop="$PROJECT_DIR/propositions/${pair}.json"
      if [ ! -f "$prop" ]; then
        if $first; then first=false; else missing_arr="$missing_arr, "; fi
        missing_arr="$missing_arr\"${pair}\""
      else
        # Only check for missing solution if proposition exists
        sol="$PROJECT_DIR/solutions/${pair}.json"
        if [ ! -f "$sol" ]; then
          if $sol_first; then sol_first=false; else missing_sol_arr="$missing_sol_arr, "; fi
          missing_sol_arr="$missing_sol_arr\"${pair}\""
        fi
      fi
    done
  done
fi
missing_arr="$missing_arr]"
missing_sol_arr="$missing_sol_arr]"

# Find missing packages and packageable pairs (product x market with 2+ solutions)
missing_pkg_arr="["
packageable_arr="["
pkg_first=true
pkgable_first=true
if [ "$PRODUCTS" -gt 0 ] && [ "$MARKETS" -gt 0 ] && [ -d "$PROJECT_DIR/features" ]; then
  eval "$(python3 -c "
import json, os, glob

proj = '$PROJECT_DIR'

# Build product -> features map
product_features = {}
for f in glob.glob(os.path.join(proj, 'features', '*.json')):
    try:
        d = json.load(open(f))
        p_slug = d.get('product_slug', '')
        f_slug = os.path.basename(f)[:-5]
        product_features.setdefault(p_slug, []).append(f_slug)
    except Exception:
        pass

missing = []
packageable = []

for pf in glob.glob(os.path.join(proj, 'products', '*.json')):
    p_slug = os.path.basename(pf)[:-5]
    features = product_features.get(p_slug, [])
    if not features:
        continue

    for mf in glob.glob(os.path.join(proj, 'markets', '*.json')):
        m_slug = os.path.basename(mf)[:-5]
        # Count solutions for this product x market
        sol_count = 0
        for f_slug in features:
            sol_path = os.path.join(proj, 'solutions', f'{f_slug}--{m_slug}.json')
            if os.path.exists(sol_path):
                sol_count += 1

        if sol_count < 2:
            continue

        pair = f'{p_slug}--{m_slug}'
        packageable.append(pair)
        pkg_path = os.path.join(proj, 'packages', f'{pair}.json')
        if not os.path.exists(pkg_path):
            missing.append(pair)

m_str = ', '.join(f'\"' + s + '\"' for s in missing)
p_str = ', '.join(f'\"' + s + '\"' for s in packageable)
print(f'missing_pkg_arr={chr(39)}[{m_str}]{chr(39)}')
print(f'packageable_arr={chr(39)}[{p_str}]{chr(39)}')
" 2>/dev/null || echo "missing_pkg_arr='[]'
packageable_arr='[]'")"
fi

# Compute relevance matrix: tier each Feature x Market pair
relevance_matrix="[]"
if [ "$FEATURES" -gt 0 ] && [ "$MARKETS" -gt 0 ]; then
  relevance_matrix=$(python3 -c "
import json, os, glob

features = {}
for f in glob.glob('$PROJECT_DIR/features/*.json'):
    try:
        d = json.load(open(f))
        features[os.path.basename(f)[:-5]] = d
    except Exception:
        pass

markets = {}
for m in glob.glob('$PROJECT_DIR/markets/*.json'):
    try:
        d = json.load(open(m))
        markets[os.path.basename(m)[:-5]] = d
    except Exception:
        pass

matrix = []
for f_slug, feat in sorted(features.items()):
    readiness = feat.get('readiness', 'ga')
    for m_slug, mkt in sorted(markets.items()):
        priority = mkt.get('priority', 'expansion')
        pair = f'{f_slug}--{m_slug}'
        has_proposition = os.path.exists(os.path.join('$PROJECT_DIR', 'propositions', pair + '.json'))

        # Skip tier: planned features or aspirational markets
        if readiness == 'planned' or priority == 'aspirational':
            tier = 'skip'
        # High tier: GA feature + beachhead market
        elif readiness == 'ga' and priority == 'beachhead':
            tier = 'high'
        # Low tier: beta feature + expansion market
        elif readiness == 'beta' and priority == 'expansion':
            tier = 'low'
        # Medium tier: everything else
        else:
            tier = 'medium'

        matrix.append({
            'pair': pair,
            'feature_slug': f_slug,
            'market_slug': m_slug,
            'readiness': readiness,
            'priority': priority,
            'tier': tier,
            'has_proposition': has_proposition
        })

print(json.dumps(matrix))
" 2>/dev/null || echo "[]")
fi

MISSING_COUNT=$((EXPECTED_PROPOSITIONS - PROPOSITIONS))
if [ "$MISSING_COUNT" -lt 0 ]; then MISSING_COUNT=0; fi

if [ "$EXPECTED_PROPOSITIONS" -gt 0 ]; then
  PROPOSITIONS_PCT=$(( PROPOSITIONS * 100 / EXPECTED_PROPOSITIONS ))
else
  PROPOSITIONS_PCT=0
fi
if [ "$PROPOSITIONS" -gt 0 ]; then
  SOLUTIONS_PCT=$(( SOLUTIONS * 100 / PROPOSITIONS ))
  COMPETITORS_PCT=$(( COMPETITORS * 100 / PROPOSITIONS ))
else
  SOLUTIONS_PCT=0
  COMPETITORS_PCT=0
fi
# Package completion: packages / packageable pairs
PACKAGEABLE_COUNT=$(python3 -c "import json; print(len(json.loads('$packageable_arr')))" 2>/dev/null || echo "0")
if [ "$PACKAGEABLE_COUNT" -gt 0 ]; then
  PACKAGES_PCT=$(( PACKAGES * 100 / PACKAGEABLE_COUNT ))
else
  PACKAGES_PCT=0
fi
if [ "$MARKETS" -gt 0 ]; then
  CUSTOMERS_PCT=$(( CUSTOMERS * 100 / MARKETS ))
else
  CUSTOMERS_PCT=0
fi

HAS_README="false"
if [ -f "$PROJECT_DIR/output/README.md" ]; then HAS_README="true"; fi
HAS_XLSX="false"
if [ -f "$PROJECT_DIR/output/portfolio.xlsx" ]; then HAS_XLSX="true"; fi

# Count unprocessed uploads (exclude processed/ subdirectory)
UPLOADS=0
if [ -d "$PROJECT_DIR/uploads" ]; then
  UPLOADS=$(find "$PROJECT_DIR/uploads" -maxdepth 1 -type f \( -name '*.md' -o -name '*.docx' -o -name '*.pptx' -o -name '*.xlsx' -o -name '*.pdf' \) 2>/dev/null | wc -l)
  UPLOADS=$(echo "$UPLOADS" | tr -d ' ')
fi

# Count claims by status
CLAIMS_TOTAL=0
CLAIMS_UNVERIFIED=0
CLAIMS_VERIFIED=0
CLAIMS_DEVIATED=0
CLAIMS_RESOLVED=0
CLAIMS_UNAVAILABLE=0
HAS_CLAIMS="false"
if [ -f "$PROJECT_DIR/cogni-claims/claims.json" ]; then
  HAS_CLAIMS="true"
  eval "$(python3 -c "
import json, sys
try:
    with open('$PROJECT_DIR/cogni-claims/claims.json') as f:
        data = json.load(f)
    claims = data.get('claims', [])
    counts = {}
    for c in claims:
        s = c.get('status', 'unverified')
        counts[s] = counts.get(s, 0) + 1
    print(f'CLAIMS_TOTAL={len(claims)}')
    print(f'CLAIMS_UNVERIFIED={counts.get(\"unverified\", 0)}')
    print(f'CLAIMS_VERIFIED={counts.get(\"verified\", 0)}')
    print(f'CLAIMS_DEVIATED={counts.get(\"deviated\", 0)}')
    print(f'CLAIMS_RESOLVED={counts.get(\"resolved\", 0)}')
    print(f'CLAIMS_UNAVAILABLE={counts.get(\"source_unavailable\", 0)}')
except Exception:
    print('CLAIMS_TOTAL=0')
" 2>/dev/null)"
fi
CLAIMS_CLEAN=$((CLAIMS_VERIFIED + CLAIMS_RESOLVED))
CLAIMS_PENDING=$((CLAIMS_UNVERIFIED + CLAIMS_DEVIATED))

# Determine workflow phase (evaluated in priority order)
if [ "$PRODUCTS" -eq 0 ]; then
  PHASE="products"
elif [ "$FEATURES" -eq 0 ]; then
  PHASE="features"
elif [ "$MARKETS" -eq 0 ]; then
  PHASE="markets"
elif [ "$MISSING_COUNT" -gt 0 ]; then
  PHASE="propositions"
elif [ "$SOLUTIONS_PCT" -lt 100 ] || [ "$COMPETITORS_PCT" -lt 100 ] || [ "$CUSTOMERS_PCT" -lt 100 ]; then
  PHASE="enrichment"
elif [ "$HAS_CLAIMS" = "true" ] && [ "$CLAIMS_PENDING" -gt 0 ]; then
  PHASE="verification"
elif [ "$HAS_README" = "false" ]; then
  PHASE="synthesis"
elif [ "$HAS_XLSX" = "false" ]; then
  PHASE="export"
else
  PHASE="complete"
fi

# Build next_actions array
next_actions="["
na_first=true
add_action() {
  if $na_first; then na_first=false; else next_actions="$next_actions, "; fi
  next_actions="$next_actions{\"skill\": \"$1\", \"reason\": \"$2\"}"
}

# Recommend ingest when uploads exist (phase-independent)
if [ "$UPLOADS" -gt 0 ]; then
  add_action "ingest" "$UPLOADS file(s) in uploads/ awaiting ingestion"
fi

case "$PHASE" in
  products)
    add_action "products" "No products defined yet"
    ;;
  features)
    add_action "features" "$PRODUCTS product(s) exist but no features defined"
    ;;
  markets)
    add_action "markets" "Features defined but no target markets yet"
    ;;
  propositions)
    add_action "propositions" "$MISSING_COUNT of $EXPECTED_PROPOSITIONS Feature x Market pairs pending"
    ;;
  enrichment)
    if [ "$SOLUTIONS_PCT" -lt 100 ]; then
      missing_sol=$((PROPOSITIONS - SOLUTIONS))
      add_action "solutions" "$missing_sol proposition(s) lack solution plans"
    fi
    if [ "$PACKAGES_PCT" -lt 100 ] && [ "$PACKAGEABLE_COUNT" -gt 0 ]; then
      missing_pkg=$((PACKAGEABLE_COUNT - PACKAGES))
      add_action "packages" "$missing_pkg product x market pair(s) ready for packaging"
    fi
    if [ "$COMPETITORS_PCT" -lt 100 ]; then
      missing_comp=$((PROPOSITIONS - COMPETITORS))
      add_action "compete" "$missing_comp proposition(s) lack competitor analysis"
    fi
    if [ "$CUSTOMERS_PCT" -lt 100 ]; then
      missing_cust=$((MARKETS - CUSTOMERS))
      add_action "customers" "$missing_cust market(s) lack customer profiles"
    fi
    ;;
  verification)
    add_action "verify" "$CLAIMS_PENDING claim(s) pending verification ($CLAIMS_UNVERIFIED unverified, $CLAIMS_DEVIATED deviated)"
    ;;
  synthesis)
    add_action "synthesize" "All entities complete -- ready to generate portfolio overview"
    ;;
  export)
    add_action "export" "Synthesis done -- ready to generate deliverables"
    ;;
  complete)
    ;;
esac
next_actions="$next_actions]"

# Solutions by type: count solution_type values
solutions_by_type="{}"
if [ -d "$PROJECT_DIR/solutions" ]; then
  solutions_by_type=$(python3 -c "
import json, os, glob
counts = {}
for f in glob.glob('$PROJECT_DIR/solutions/*.json'):
    try:
        d = json.load(open(f))
        t = d.get('solution_type', 'project')
        counts[t] = counts.get(t, 0) + 1
    except Exception:
        pass
print(json.dumps(counts, sort_keys=True))
" 2>/dev/null || echo "{}")
fi

# Margin health: analyze cost_model data across solutions, separated by type
margin_health="{}"
solutions_with_cost_model=0
solutions_below_target=0
negative_margin_tiers=0
if [ -d "$PROJECT_DIR/solutions" ]; then
  eval "$(python3 -c "
import json, os, glob

# Read target margin from portfolio.json delivery_defaults
target = 30
try:
    with open('$PROJECT_DIR/portfolio.json') as f:
        pf = json.load(f)
    target = pf.get('delivery_defaults', {}).get('target_margin_pct', 30)
except Exception:
    pass

with_cm = 0
below_target = 0
negative = 0
project_margins = []
subscription_margins = []

for sf in glob.glob('$PROJECT_DIR/solutions/*.json'):
    try:
        d = json.load(open(sf))
        cm = d.get('cost_model')
        if not cm:
            continue
        with_cm += 1
        sol_type = d.get('solution_type', 'project')

        if sol_type in ('subscription', 'hybrid'):
            # Subscription: check unit_economics
            ue = cm.get('unit_economics', {})
            gm = ue.get('gross_margin_pct')
            if gm is not None:
                subscription_margins.append(gm)
                if gm < 70:
                    below_target += 1
            ltv_cac = ue.get('ltv_cac_ratio')
            if ltv_cac is not None and ltv_cac < 3:
                below_target += 1
            churn = ue.get('churn_monthly_pct')
            if churn is not None and churn > 5:
                below_target += 1
        else:
            # Project: check effort_by_tier margins
            ebt = cm.get('effort_by_tier', {})
            for tier_name in ['proof_of_value', 'small', 'medium', 'large']:
                tier = ebt.get(tier_name, {})
                m = tier.get('margin_pct')
                if m is not None:
                    project_margins.append(m)
                    if m < 0:
                        negative += 1
                    # PoV gets lower threshold (10%), standard tiers use target
                    threshold = 10 if tier_name == 'proof_of_value' else target
                    if m < threshold:
                        below_target += 1
    except Exception:
        pass

avg_project = round(sum(project_margins) / len(project_margins), 1) if project_margins else 0
avg_subscription = round(sum(subscription_margins) / len(subscription_margins), 1) if subscription_margins else 0
print(f'solutions_with_cost_model={with_cm}')
print(f'solutions_below_target={below_target}')
print(f'negative_margin_tiers={negative}')
print(f'margin_health={chr(39)}{{\"target_margin_pct\": {target}, \"solutions_with_cost_model\": {with_cm}, \"below_target_tiers\": {below_target}, \"negative_margin_tiers\": {negative}, \"avg_project_margin_pct\": {avg_project}, \"avg_subscription_margin_pct\": {avg_subscription}}}{chr(39)}')
" 2>/dev/null || echo "margin_health='{}'")"
fi

# Health check: detect stale downstream entities
stale_entities="[]"
if $HEALTH_CHECK && [ -d "$PROJECT_DIR/propositions" ]; then
  stale_entities=$(python3 -c "
import json, os, glob
from datetime import datetime

def get_updated(filepath):
    \"\"\"Get updated date from JSON field or fall back to file mtime.\"\"\"
    try:
        d = json.load(open(filepath))
        u = d.get('updated')
        if u:
            return u, 'field'
    except Exception:
        pass
    try:
        mtime = os.path.getmtime(filepath)
        return datetime.fromtimestamp(mtime).strftime('%Y-%m-%d'), 'mtime'
    except Exception:
        return None, None

stale = []
proj = '$PROJECT_DIR'

# Check propositions against their upstream feature and market
for pf in glob.glob(os.path.join(proj, 'propositions', '*.json')):
    slug = os.path.basename(pf)[:-5]
    if '--' not in slug:
        continue
    f_slug = slug.split('--')[0]
    m_slug = '--'.join(slug.split('--')[1:])
    prop_date, prop_src = get_updated(pf)
    if not prop_date:
        continue

    reasons = []
    # Check feature
    feat_path = os.path.join(proj, 'features', f_slug + '.json')
    if os.path.exists(feat_path):
        feat_date, feat_src = get_updated(feat_path)
        if feat_date and feat_date > prop_date:
            reasons.append(f'feature {f_slug} updated {feat_date} ({feat_src}) > proposition {prop_date}')

    # Check market
    mkt_path = os.path.join(proj, 'markets', m_slug + '.json')
    if os.path.exists(mkt_path):
        mkt_date, mkt_src = get_updated(mkt_path)
        if mkt_date and mkt_date > prop_date:
            reasons.append(f'market {m_slug} updated {mkt_date} ({mkt_src}) > proposition {prop_date}')

    if reasons:
        stale.append({'entity': 'proposition', 'slug': slug, 'reasons': reasons})

# Check solutions against their upstream proposition
for sf in glob.glob(os.path.join(proj, 'solutions', '*.json')):
    slug = os.path.basename(sf)[:-5]
    sol_date, sol_src = get_updated(sf)
    if not sol_date:
        continue
    prop_path = os.path.join(proj, 'propositions', slug + '.json')
    if os.path.exists(prop_path):
        prop_date, prop_src = get_updated(prop_path)
        if prop_date and prop_date > sol_date:
            stale.append({'entity': 'solution', 'slug': slug, 'reasons': [f'proposition {slug} updated {prop_date} ({prop_src}) > solution {sol_date}']})

# Check propositions whose features have structural warnings (short description)
# Deep quality assessment is handled by the feature-quality-assessor agent.
warned_features = set()
for ff in glob.glob(os.path.join(proj, 'features', '*.json')):
    try:
        d = json.load(open(ff))
        desc = d.get('description', '')
        words = desc.split()
        if len(words) < 15:
            warned_features.add(os.path.basename(ff)[:-5])
    except Exception:
        pass

for pf in glob.glob(os.path.join(proj, 'propositions', '*.json')):
    slug = os.path.basename(pf)[:-5]
    if '--' not in slug:
        continue
    f_slug = slug.split('--')[0]
    if f_slug in warned_features:
        existing = [s for s in stale if s['slug'] == slug and s['entity'] == 'proposition']
        reason = f'feature {f_slug} has structural quality warnings -- proposition may need rework'
        if existing:
            existing[0]['reasons'].append(reason)
        else:
            stale.append({'entity': 'proposition', 'slug': slug, 'reasons': [reason]})

print(json.dumps(stale))
" 2>/dev/null || echo "[]")
fi

cat << EOF
{
  "counts": {
    "products": $PRODUCTS,
    "features": $FEATURES,
    "markets": $MARKETS,
    "propositions": $PROPOSITIONS,
    "expected_propositions": $EXPECTED_PROPOSITIONS,
    "solutions": $SOLUTIONS,
    "packages": $PACKAGES,
    "competitors": $COMPETITORS,
    "customers": $CUSTOMERS,
    "uploads": $UPLOADS,
    "features_without_readiness": $features_without_readiness,
    "markets_without_priority": $markets_without_priority,
    "feature_quality_warnings": $feature_quality_warnings
  },
  "feature_quality_warning_slugs": $feature_quality_slugs,
  "readiness_summary": $readiness_summary,
  "priority_summary": $priority_summary,
  "claims": {
    "total": $CLAIMS_TOTAL,
    "unverified": $CLAIMS_UNVERIFIED,
    "verified": $CLAIMS_VERIFIED,
    "deviated": $CLAIMS_DEVIATED,
    "resolved": $CLAIMS_RESOLVED,
    "source_unavailable": $CLAIMS_UNAVAILABLE
  },
  "products": $product_arr,
  "features": $feature_arr,
  "markets": $market_arr,
  "regions": $region_summary,
  "missing_propositions": $missing_arr,
  "missing_solutions": $missing_sol_arr,
  "missing_packages": $missing_pkg_arr,
  "packageable_pairs": $packageable_arr,
  "solutions_by_type": $solutions_by_type,
  "relevance_matrix": $relevance_matrix,
  "phase": "$PHASE",
  "next_actions": $next_actions,
  "completion": {
    "propositions_pct": $PROPOSITIONS_PCT,
    "solutions_pct": $SOLUTIONS_PCT,
    "packages_pct": $PACKAGES_PCT,
    "competitors_pct": $COMPETITORS_PCT,
    "customers_pct": $CUSTOMERS_PCT
  },
  "margin_health": $margin_health,
  "stale_entities": $stale_entities
}
EOF
