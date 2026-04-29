#!/bin/bash
# Show cogni-trends project status with phase detection, candidate counts, and report status.
# Usage: project-status.sh <project-dir> [--health-check]
# Outputs JSON with counts, phase, next_actions, and completion ratios.
# With --health-check: also includes staleness detection and quality warnings.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-}"
HEALTH_CHECK=false
if [ "${2:-}" = "--health-check" ]; then
  HEALTH_CHECK=true
fi

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Valid project directory required. Usage: project-status.sh <project-dir> [--health-check]"}' >&2
  exit 1
fi

# Check for project identity files
SCOUT_OUTPUT="$PROJECT_DIR/.metadata/trend-scout-output.json"
PROJECT_FILE="$PROJECT_DIR/tips-project.json"

if [ ! -f "$SCOUT_OUTPUT" ] && [ ! -f "$PROJECT_FILE" ]; then
  echo '{"error": "Not a cogni-trends project (missing .metadata/trend-scout-output.json and tips-project.json)"}' >&2
  exit 1
fi

# Extract project metadata
PROJECT_SLUG=""
PROJECT_LANGUAGE="en"
INDUSTRY=""
SUBSECTOR=""
RESEARCH_TOPIC=""

if [ -f "$PROJECT_FILE" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$PROJECT_FILE'))
    print(f'PROJECT_SLUG={chr(39)}{d.get(\"slug\", \"\")}{chr(39)}')
    print(f'PROJECT_LANGUAGE={chr(39)}{d.get(\"language\", \"en\")}{chr(39)}')
    ind = d.get('industry', {})
    primary_en = ind.get('primary_en') or ind.get('primary', '')
    subsector_en = ind.get('subsector_en') or ind.get('subsector', '')
    print(f'INDUSTRY={chr(39)}{primary_en}{chr(39)}')
    print(f'SUBSECTOR={chr(39)}{subsector_en}{chr(39)}')
    print(f'RESEARCH_TOPIC={chr(39)}{d.get(\"research_topic\", \"\")}{chr(39)}')
except Exception:
    pass
" 2>/dev/null)"
elif [ -f "$SCOUT_OUTPUT" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$SCOUT_OUTPUT'))
    print(f'PROJECT_SLUG={chr(39)}{d.get(\"project_id\", \"\")}{chr(39)}')
    print(f'PROJECT_LANGUAGE={chr(39)}{d.get(\"project_language\", \"en\")}{chr(39)}')
    cfg = d.get('config', {})
    ind = cfg.get('industry', {})
    primary_en = ind.get('primary_en') or ind.get('primary', '')
    subsector_en = ind.get('subsector_en') or ind.get('subsector', '')
    print(f'INDUSTRY={chr(39)}{primary_en}{chr(39)}')
    print(f'SUBSECTOR={chr(39)}{subsector_en}{chr(39)}')
    print(f'RESEARCH_TOPIC={chr(39)}{cfg.get(\"research_topic\", \"\")}{chr(39)}')
except Exception:
    pass
" 2>/dev/null)"
fi

# Extract workflow state and candidate counts from trend-scout-output.json
WORKFLOW_STATE="unknown"
CURRENT_PHASE=0
CANDIDATES_TOTAL=0
CANDIDATES_WEB=0
CANDIDATES_TRAINING=0
CANDIDATES_USER=0
WEB_RESEARCH_STATUS="unknown"
AVG_SCORE=0
LEADING_PCT=0
AGREED_AT=""

if [ -f "$SCOUT_OUTPUT" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$SCOUT_OUTPUT'))
    exe = d.get('execution', {})
    print(f'WORKFLOW_STATE={chr(39)}{exe.get(\"workflow_state\", \"unknown\")}{chr(39)}')
    print(f'CURRENT_PHASE={exe.get(\"current_phase\", 0)}')
    print(f'AGREED_AT={chr(39)}{exe.get(\"agreed_at\", \"\")}{chr(39)}')

    tc = d.get('tips_candidates', {})
    print(f'CANDIDATES_TOTAL={tc.get(\"total\", 0)}')

    sd = tc.get('source_distribution', {})
    print(f'CANDIDATES_WEB={sd.get(\"web_signal\", 0)}')
    print(f'CANDIDATES_TRAINING={sd.get(\"training\", 0)}')
    print(f'CANDIDATES_USER={sd.get(\"user_proposed\", 0)}')

    print(f'WEB_RESEARCH_STATUS={chr(39)}{tc.get(\"web_research_status\", \"unknown\")}{chr(39)}')

    sm = tc.get('scoring_metadata', {})
    print(f'AVG_SCORE={sm.get(\"avg_score\", 0)}')
    id_dist = sm.get('indicator_distribution', {})
    print(f'LEADING_PCT={id_dist.get(\"leading_pct\", 0)}')
except Exception as e:
    print(f'# Error: {e}')
" 2>/dev/null)"
fi

# Count candidates by dimension and horizon
DIMENSION_COUNTS="{}"
if [ -f "$SCOUT_OUTPUT" ]; then
  DIMENSION_COUNTS=$(python3 -c "
import json
try:
    d = json.load(open('$SCOUT_OUTPUT'))
    items = d.get('tips_candidates', {}).get('items', [])
    DIMS = ['externe-effekte', 'neue-horizonte', 'digitale-wertetreiber', 'digitales-fundament']
    counts = {}
    for i, item in enumerate(items):
        dim = item.get('dimension') or DIMS[min(i // 15, 3)]
        hor = item.get('horizon', 'unknown')
        if dim not in counts:
            counts[dim] = {'act': 0, 'plan': 0, 'observe': 0, 'total': 0}
        counts[dim][hor] = counts[dim].get(hor, 0) + 1
        counts[dim]['total'] += 1
    print(json.dumps(counts))
except Exception:
    print('{}')
" 2>/dev/null || echo "{}")
fi

# Confidence distribution
CONFIDENCE_COUNTS="{}"
if [ -f "$SCOUT_OUTPUT" ]; then
  CONFIDENCE_COUNTS=$(python3 -c "
import json
try:
    d = json.load(open('$SCOUT_OUTPUT'))
    sm = d.get('tips_candidates', {}).get('scoring_metadata', {})
    cd = sm.get('confidence_distribution', {})
    print(json.dumps(cd))
except Exception:
    print('{}')
" 2>/dev/null || echo "{}")
fi

# Check for log files and report artifacts
HAS_WEB_RESEARCH="false"
HAS_GENERATOR_LOG="false"
HAS_CANDIDATES_MD="false"
HAS_SELECTOR_APP="false"
HAS_REPORT="false"
HAS_CLAIMS="false"
HAS_INSIGHT="false"
HAS_VERIFICATION="false"
HAS_ENRICHED_REPORT="false"
HAS_COPYWRITER="false"
COPYWRITER_SCOPE=""
HAS_VALUE_MODEL="false"
VALUE_MODEL_PHASE=""
THEMES_COUNT=0
SOLUTIONS_COUNT=0
RANKED_COUNT=0
BLUEPRINT_COUNT=0
ANCHORED_COUNT=0
AVG_READINESS=0
ANCHOR_QUALITY_COUNT=0
ANCHOR_NEEDS_DELIVERED=0
ANCHOR_NEEDS_UNDELIVERED=0
ANCHOR_PRODUCTS_JSON='[]'
CLAIMS_TOTAL=0

[ -f "$PROJECT_DIR/.logs/web-research-raw.json" ] && HAS_WEB_RESEARCH="true"
[ -f "$PROJECT_DIR/.logs/trend-generator-candidates.json" ] && HAS_GENERATOR_LOG="true"
[ -f "$PROJECT_DIR/trend-candidates.md" ] && HAS_CANDIDATES_MD="true"
[ -f "$PROJECT_DIR/trend-selector-app.html" ] && HAS_SELECTOR_APP="true"
[ -f "$PROJECT_DIR/tips-value-model.json" ] && HAS_VALUE_MODEL="true"
[ -f "$PROJECT_DIR/tips-trend-report.md" ] && HAS_REPORT="true"
[ -f "$PROJECT_DIR/tips-trend-report-claims.json" ] && HAS_CLAIMS="true"
[ -f "$PROJECT_DIR/tips-insight-summary.md" ] && HAS_INSIGHT="true"
[ -f "$PROJECT_DIR/.metadata/trend-report-verification.json" ] && HAS_VERIFICATION="true"
# Fallback: detect verification from cogni-claims registry (created by /claims skill)
CLAIMS_STORE_SCRIPT="$(cd "$(dirname "$0")/../.." && pwd)/cogni-claims/skills/claims/scripts/claims-store.sh"
if [ "$HAS_VERIFICATION" = "false" ] && [ -f "$PROJECT_DIR/cogni-claims/claims.json" ] && [ -f "$CLAIMS_STORE_SCRIPT" ]; then
  CLAIMS_STATUS=$(bash "$CLAIMS_STORE_SCRIPT" count-by-status "$PROJECT_DIR" 2>/dev/null || echo "")
  if [ -n "$CLAIMS_STATUS" ]; then
    eval "$(python3 -c "
import json, sys
try:
    d = json.loads('$CLAIMS_STATUS')
    total = d.get('total', 0)
    unverified = d.get('unverified', 0)
    if total > 0 and unverified == 0:
        verified = d.get('verified', 0) + d.get('resolved', 0) + d.get('source_unavailable', 0)
        deviated = d.get('deviated', 0)
        verdict = 'PASS' if deviated == 0 else 'REVIEW'
        print(f'HAS_VERIFICATION=true')
        print(f'VERIFICATION_VERDICT={chr(39)}{verdict}{chr(39)}')
        print(f'VERIFICATION_PASSED={verified}')
        print(f'VERIFICATION_FAILED=0')
        print(f'VERIFICATION_REVIEW={deviated}')
except Exception:
    pass
" 2>/dev/null)"
  fi
fi
# Detect revision state: claims resolved but report not yet revised
HAS_REVISION_PENDING="false"
HAS_REVISION_DONE="false"
if [ -f "$PROJECT_DIR/cogni-claims/claims.json" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$PROJECT_DIR/cogni-claims/claims.json'))
    claims = d if isinstance(d, list) else d.get('claims', [])
    removals = sum(1 for c in claims if isinstance(c, dict) and c.get('verification', {}).get('resolution') in ('remove', 'correct'))
    if removals > 0:
        print('HAS_REVISION_PENDING=true')
        print(f'REVISION_CHANGES={removals}')
except Exception:
    pass
" 2>/dev/null)"
fi
# Check if revision was already applied
for vfile in "$PROJECT_DIR"/tips-trend-report-v*.md; do
  [ -f "$vfile" ] && HAS_REVISION_DONE="true" && HAS_REVISION_PENDING="false" && break
done

[ -f "$PROJECT_DIR/output/tips-trend-report-enriched.html" ] && HAS_ENRICHED_REPORT="true"
HAS_DASHBOARD="false"
[ -f "$PROJECT_DIR/output/trends-dashboard.html" ] && HAS_DASHBOARD="true"

if [ "$HAS_CLAIMS" = "true" ]; then
  CLAIMS_TOTAL=$(python3 -c "
import json
try:
    d = json.load(open('$PROJECT_DIR/tips-trend-report-claims.json'))
    print(d.get('total_claims', len(d.get('claims', []))))
except Exception:
    print(0)
" 2>/dev/null || echo "0")
fi

# Verification status — only set defaults if not already populated by cogni-claims fallback
if [ -z "${VERIFICATION_VERDICT:-}" ]; then
  VERIFICATION_VERDICT=""
  VERIFICATION_PASSED=0
  VERIFICATION_FAILED=0
  VERIFICATION_REVIEW=0
  if [ -f "$PROJECT_DIR/.metadata/trend-report-verification.json" ]; then
    eval "$(python3 -c "
import json
try:
    d = json.load(open('$PROJECT_DIR/.metadata/trend-report-verification.json'))
    print(f'VERIFICATION_VERDICT={chr(39)}{d.get(\"verdict\", \"\")}{chr(39)}')
    print(f'VERIFICATION_PASSED={d.get(\"passed\", 0)}')
    print(f'VERIFICATION_FAILED={d.get(\"failed\", 0)}')
    print(f'VERIFICATION_REVIEW={d.get(\"review\", 0)}')
except Exception:
    pass
" 2>/dev/null)"
  fi
fi

# Check for copywriter metadata in trend-scout-output.json
if [ -f "$SCOUT_OUTPUT" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$SCOUT_OUTPUT'))
    meta = d.get('metadata', {})
    if meta.get('copywriter_applied'):
        print('HAS_COPYWRITER=true')
        print(f'COPYWRITER_SCOPE={chr(39)}{meta.get(\"copywriter_scope\", \"\")}{chr(39)}')
except Exception:
    pass
" 2>/dev/null)"
fi

# Extract value-modeler status
if [ "$HAS_VALUE_MODEL" = "true" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$PROJECT_DIR/tips-value-model.json'))
    themes = d.get('investment_themes', d.get('themes', []))
    print(f'THEMES_COUNT={len(themes)}')
    sts = d.get('solution_templates', [])
    print(f'SOLUTIONS_COUNT={len(sts)}')
    ranked = [s for s in sts if s.get('ranking_value') is not None or s.get('business_relevance_calculated') is not None]
    print(f'RANKED_COUNT={len(ranked)}')
    # Blueprint and portfolio anchor metrics
    blueprints = [s for s in sts if s.get('solution_blueprint')]
    print(f'BLUEPRINT_COUNT={len(blueprints)}')
    anchored = [s for s in sts if s.get('generation_mode') == 'portfolio-anchored']
    print(f'ANCHORED_COUNT={len(anchored)}')
    if blueprints:
        scores = [s['solution_blueprint']['readiness'].get('readiness_score', 0)
                  for s in blueprints if isinstance(s.get('solution_blueprint', {}).get('readiness'), dict)]
        avg = round(sum(scores) / len(scores), 2) if scores else 0
        print(f'AVG_READINESS={avg}')
    # Portfolio anchor per-product aggregation
    anchor_agg = {}
    anchor_quality = 0
    anchor_delivered = 0
    anchor_undelivered = 0
    for s in anchored:
        pa = s.get('portfolio_anchor') or {}
        prod = pa.get('product_slug', 'unknown')
        feat = pa.get('feature_slug', 'unknown')
        nd = len(pa.get('investment_theme_needs_delivered', pa.get('theme_needs_delivered', [])))
        nu = len(pa.get('investment_theme_needs_undelivered', pa.get('theme_needs_undelivered', [])))
        qi = 1 if s.get('quality_flag') == 'quality_investment_needed' else 0
        anchor_quality += qi
        anchor_delivered += nd
        anchor_undelivered += nu
        if prod not in anchor_agg:
            anchor_agg[prod] = {'product_slug': prod, 'features': set(), 'solutions': 0, 'needs_delivered': 0, 'needs_undelivered': 0, 'quality_issues': 0}
        anchor_agg[prod]['features'].add(feat)
        anchor_agg[prod]['solutions'] += 1
        anchor_agg[prod]['needs_delivered'] += nd
        anchor_agg[prod]['needs_undelivered'] += nu
        anchor_agg[prod]['quality_issues'] += qi
    products_list = [{'product_slug': p['product_slug'], 'features': len(p['features']), 'solutions': p['solutions'], 'needs_delivered': p['needs_delivered'], 'needs_undelivered': p['needs_undelivered'], 'quality_issues': p['quality_issues']} for p in sorted(anchor_agg.values(), key=lambda x: x['solutions'], reverse=True)]
    print(f'ANCHOR_QUALITY_COUNT={anchor_quality}')
    print(f'ANCHOR_NEEDS_DELIVERED={anchor_delivered}')
    print(f'ANCHOR_NEEDS_UNDELIVERED={anchor_undelivered}')
    print('ANCHOR_PRODUCTS_JSON=' + chr(39) + json.dumps(products_list) + chr(39))
except Exception:
    pass
" 2>/dev/null)"
fi

# Detect value-modeler sub-phase from output metadata
VM_OUTPUT="$PROJECT_DIR/.metadata/value-modeler-output.json"
if [ -f "$VM_OUTPUT" ]; then
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$VM_OUTPUT'))
    phase = d.get('execution', {}).get('workflow_state', '')
    print(f'VALUE_MODEL_PHASE={chr(39)}{phase}{chr(39)}')
except Exception:
    pass
" 2>/dev/null)"
fi

# Detect portfolio context and portfolio projects in workspace
HAS_PORTFOLIO_CONTEXT="false"
PORTFOLIO_CONTEXT_VERSION=""
HAS_PORTFOLIO_PROJECT="false"
PORTFOLIO_FEATURES_COUNT=0
PORTFOLIO_DIFFERENTIATORS_COUNT=0

# Check for portfolio-context.json in the TIPS project directory
if [ -f "$PROJECT_DIR/portfolio-context.json" ]; then
  HAS_PORTFOLIO_CONTEXT="true"
  eval "$(python3 -c "
import json
try:
    d = json.load(open('$PROJECT_DIR/portfolio-context.json'))
    ver = d.get('schema_version', '1.0')
    print(f'PORTFOLIO_CONTEXT_VERSION={chr(39)}{ver}{chr(39)}')
    products = d.get('products', [])
    feat_count = sum(len(p.get('features', [])) for p in products)
    print(f'PORTFOLIO_FEATURES_COUNT={feat_count}')
    diff_count = len(d.get('differentiators', []))
    print(f'PORTFOLIO_DIFFERENTIATORS_COUNT={diff_count}')
except Exception:
    pass
" 2>/dev/null)"
fi

# Check for portfolio projects in workspace (sibling directories with portfolio.json)
WORKSPACE_ROOT="$(dirname "$PROJECT_DIR")"
WORKSPACE_PARENT="$(dirname "$WORKSPACE_ROOT")"
for search_dir in "$WORKSPACE_ROOT" "$WORKSPACE_PARENT"; do
  if [ -d "$search_dir" ]; then
    for pf in "$search_dir"/*/portfolio.json "$search_dir"/cogni-portfolio/*/portfolio.json; do
      if [ -f "$pf" ] 2>/dev/null; then
        HAS_PORTFOLIO_PROJECT="true"
        break 2
      fi
    done
  fi
done

# Count report section files
REPORT_SECTIONS=0
if [ -d "$PROJECT_DIR/.logs" ]; then
  for dim in externe-effekte digitale-wertetreiber neue-horizonte digitales-fundament; do
    [ -f "$PROJECT_DIR/.logs/report-section-${dim}.md" ] && REPORT_SECTIONS=$((REPORT_SECTIONS + 1))
  done
fi

# Determine workflow phase (evaluated in priority order)
# Maps workflow_state to a simplified phase name for resume-tips
if [ "$WORKFLOW_STATE" = "unknown" ] || [ "$WORKFLOW_STATE" = "initialized" ]; then
  if [ "$CANDIDATES_TOTAL" -eq 0 ] && [ "$HAS_WEB_RESEARCH" = "false" ]; then
    PHASE="scouting"
  elif [ "$HAS_WEB_RESEARCH" = "true" ] && [ "$HAS_GENERATOR_LOG" = "false" ]; then
    PHASE="generating"
  elif [ "$HAS_CANDIDATES_MD" = "true" ] && [ "$CANDIDATES_TOTAL" -eq 0 ]; then
    PHASE="selecting"
  else
    PHASE="scouting"
  fi
elif [ "$WORKFLOW_STATE" = "phase-1" ]; then
  PHASE="researching"
elif [ "$WORKFLOW_STATE" = "phase-2" ]; then
  PHASE="generating"
elif [ "$WORKFLOW_STATE" = "phase-3" ]; then
  PHASE="presenting"
elif [ "$WORKFLOW_STATE" = "phase-4" ] || [ "$WORKFLOW_STATE" = "agreed" ]; then
  if [ "$HAS_REPORT" = "true" ]; then
    if [ "$HAS_REVISION_PENDING" = "true" ]; then
      PHASE="revision"
    elif [ "$HAS_VERIFICATION" = "true" ]; then
      PHASE="complete"
    elif [ "$HAS_CLAIMS" = "true" ] && [ "$CLAIMS_TOTAL" -gt 0 ]; then
      PHASE="verification"
    else
      PHASE="complete"
    fi
  elif [ "$HAS_VALUE_MODEL" = "true" ]; then
    # Value model exists — check sub-phase or fall through to reporting
    if [ -n "$VALUE_MODEL_PHASE" ]; then
      case "$VALUE_MODEL_PHASE" in
        initialized) PHASE="modeling" ;;
        investment-themes-built) PHASE="modeling-paths" ;;
        solutions-generated) PHASE="modeling-scoring" ;;
        scored) PHASE="modeling-curating" ;;
        curated|complete) PHASE="reporting" ;;
        *) PHASE="reporting" ;;
      esac
    elif [ "$RANKED_COUNT" -gt 0 ]; then
      PHASE="reporting"
    elif [ "$SOLUTIONS_COUNT" -gt 0 ]; then
      PHASE="modeling-scoring"
    elif [ "$THEMES_COUNT" -gt 0 ]; then
      PHASE="modeling-paths"
    else
      PHASE="modeling"
    fi
  else
    PHASE="modeling"
  fi
elif [ "$WORKFLOW_STATE" = "report-enriching" ] || [ "$WORKFLOW_STATE" = "report-assembling" ]; then
  PHASE="reporting"
elif [ "$WORKFLOW_STATE" = "report-verifying" ]; then
  PHASE="verification"
elif [ "$WORKFLOW_STATE" = "report-complete" ]; then
  PHASE="complete"
else
  PHASE="scouting"
fi

# Pre-compute stages[] array — one entry per progress-table row with status + details.
# Centralizes per-stage decision logic here so SKILL.md only renders the array verbatim
# and never has to apply derivation rules in prose. This is the load-bearing fix for
# the "value-modeler done but still rendered as Pending" class of bug: the LLM no
# longer sees "Done if counts.X > 0, else Pending" — it just reads stage.status.
export HAS_WEB_RESEARCH HAS_GENERATOR_LOG CANDIDATES_TOTAL CANDIDATES_WEB \
  WORKFLOW_STATE HAS_PORTFOLIO_CONTEXT HAS_PORTFOLIO_PROJECT \
  PORTFOLIO_CONTEXT_VERSION PORTFOLIO_FEATURES_COUNT \
  THEMES_COUNT SOLUTIONS_COUNT RANKED_COUNT BLUEPRINT_COUNT ANCHORED_COUNT \
  AVG_READINESS ANCHOR_NEEDS_DELIVERED ANCHOR_NEEDS_UNDELIVERED \
  ANCHOR_QUALITY_COUNT ANCHOR_PRODUCTS_JSON \
  HAS_REPORT REPORT_SECTIONS HAS_CLAIMS CLAIMS_TOTAL \
  HAS_INSIGHT HAS_VERIFICATION VERIFICATION_VERDICT \
  VERIFICATION_PASSED VERIFICATION_FAILED \
  HAS_COPYWRITER HAS_ENRICHED_REPORT HAS_DASHBOARD DIMENSION_COUNTS

STAGES_JSON=$(python3 <<'PYEOF' 2>/dev/null || echo "[]"
import json, os

def b(name):
    return os.environ.get(name, 'false') == 'true'

def i(name, default=0):
    try: return int(os.environ.get(name, default) or default)
    except (ValueError, TypeError): return default

def fl(name, default=0.0):
    try: return float(os.environ.get(name, default) or default)
    except (ValueError, TypeError): return default

def s(name, default=''):
    return os.environ.get(name, default) or default

stages = []

# 1. Web Research
stages.append({
    'name': 'Web Research',
    'status': 'done' if b('HAS_WEB_RESEARCH') else 'pending',
    'details': f"{i('CANDIDATES_WEB')} signals found"
})

# 2. Candidate Generation
gen_done = b('HAS_GENERATOR_LOG') or i('CANDIDATES_TOTAL') > 0
stages.append({
    'name': 'Candidate Generation',
    'status': 'done' if gen_done else 'pending',
    'details': '60 generated' if gen_done else 'pending generation'
})

# 3. Candidate Selection
sel_done = s('WORKFLOW_STATE') in ('agreed', 'phase-4')
stages.append({
    'name': 'Candidate Selection',
    'status': 'done' if sel_done else 'pending',
    'details': f"{i('CANDIDATES_TOTAL')}/60 agreed"
})

# 4. Portfolio Bridge
if b('HAS_PORTFOLIO_PROJECT'):
    if b('HAS_PORTFOLIO_CONTEXT'):
        ver = s('PORTFOLIO_CONTEXT_VERSION') or 'unknown'
        details = f"v{ver} context, {i('PORTFOLIO_FEATURES_COUNT')} features"
        # Mark "upgrade available" when version is below 3.1
        if ver and ver != 'unknown' and ver < '3.1':
            details += ' (upgrade available)'
        stages.append({'name': 'Portfolio Bridge', 'status': 'done', 'details': details})
    else:
        stages.append({
            'name': 'Portfolio Bridge',
            'status': 'ready',
            'details': 'portfolio project found — run /bridge portfolio-to-tips'
        })
else:
    stages.append({
        'name': 'Portfolio Bridge',
        'status': 'n_a',
        'details': 'no portfolio project in workspace'
    })

# 5. Value Chains & Themes
themes = i('THEMES_COUNT')
stages.append({
    'name': 'Value Chains & Themes',
    'status': 'done' if themes > 0 else 'pending',
    'details': f"{themes} strategic themes"
})

# 6. Solution Templates
sols = i('SOLUTIONS_COUNT')
stages.append({
    'name': 'Solution Templates',
    'status': 'done' if sols > 0 else 'pending',
    'details': f"{sols} solutions generated"
})

# 7. BR Scoring & Ranking
ranked = i('RANKED_COUNT')
stages.append({
    'name': 'BR Scoring & Ranking',
    'status': 'done' if ranked > 0 else 'pending',
    'details': f"{ranked} solutions ranked"
})

# 8. Solution Blueprints
bps = i('BLUEPRINT_COUNT')
anc = i('ANCHORED_COUNT')
avg_r = fl('AVG_READINESS')
if bps > 0:
    bp_status = 'done'
    bp_details = f"{bps}/{sols} blueprinted, avg readiness {avg_r}, {anc} portfolio-anchored"
elif sols > 0:
    bp_status = 'pending'
    bp_details = f"{sols} solutions but no blueprints generated yet"
else:
    bp_status = 'n_a'
    bp_details = 'no solutions generated yet'
stages.append({'name': 'Solution Blueprints', 'status': bp_status, 'details': bp_details})

# 9. Portfolio Anchors
try:
    products = json.loads(os.environ.get('ANCHOR_PRODUCTS_JSON') or '[]')
except Exception:
    products = []
if anc > 0:
    pa_details = (f"{len(products)} products, "
                  f"{i('ANCHOR_NEEDS_DELIVERED')}/{i('ANCHOR_NEEDS_UNDELIVERED')} delivered/unmet, "
                  f"{i('ANCHOR_QUALITY_COUNT')} quality flags")
    stages.append({'name': 'Portfolio Anchors', 'status': 'done', 'details': pa_details})
else:
    stages.append({
        'name': 'Portfolio Anchors',
        'status': 'n_a',
        'details': 'no portfolio-anchored solutions'
    })

# 10. Trend Report
stages.append({
    'name': 'Trend Report',
    'status': 'done' if b('HAS_REPORT') else 'pending',
    'details': f"{i('REPORT_SECTIONS')}/4 sections"
})

# 11. Claims Registry
ct = i('CLAIMS_TOTAL')
stages.append({
    'name': 'Claims Registry',
    'status': 'done' if (b('HAS_CLAIMS') and ct > 0) else 'pending',
    'details': f"{ct} claims extracted"
})

# 12. Insight Summary
stages.append({
    'name': 'Insight Summary',
    'status': 'done' if b('HAS_INSIGHT') else 'skipped',
    'details': 'condensed executive narrative' if b('HAS_INSIGHT') else 'optional'
})

# 13. Claim Verification
if b('HAS_VERIFICATION'):
    vv = s('VERIFICATION_VERDICT')
    vd = (f"{vv}: {i('VERIFICATION_PASSED')} passed, {i('VERIFICATION_FAILED')} failed"
          if vv else 'verified')
    stages.append({'name': 'Claim Verification', 'status': 'done', 'details': vd})
elif b('HAS_CLAIMS') and ct > 0:
    stages.append({
        'name': 'Claim Verification',
        'status': 'pending',
        'details': f"{ct} claims awaiting verification — run /verify-trend-report"
    })
else:
    stages.append({
        'name': 'Claim Verification',
        'status': 'skipped',
        'details': 'no claims to verify'
    })

# 14. Executive Polish
stages.append({
    'name': 'Executive Polish',
    'status': 'done' if b('HAS_COPYWRITER') else 'skipped',
    'details': 'tone (cogni-copywriting)' if b('HAS_COPYWRITER') else 'optional'
})

# 15. Visual Report
stages.append({
    'name': 'Visual Report',
    'status': 'done' if b('HAS_ENRICHED_REPORT') else 'skipped',
    'details': ('themed HTML with charts (cogni-visual:enrich-report)'
                if b('HAS_ENRICHED_REPORT') else 'optional')
})

# 16. Dashboard
stages.append({
    'name': 'Dashboard',
    'status': 'done' if b('HAS_DASHBOARD') else 'skipped',
    'details': 'interactive HTML visualization' if b('HAS_DASHBOARD') else 'optional'
})

print(json.dumps(stages))
PYEOF
)

# Pre-compute dimension_balance[] from dimension_counts so SKILL.md renders a
# table by iteration instead of binding N placeholders against a nested object.
DIMENSION_BALANCE_JSON=$(python3 <<'PYEOF' 2>/dev/null || echo "[]"
import json, os
DIMS = [
    ('externe-effekte', 'Externe Effekte'),
    ('neue-horizonte', 'Neue Horizonte'),
    ('digitale-wertetreiber', 'Digitale Wertetreiber'),
    ('digitales-fundament', 'Digitales Fundament'),
]
try:
    dc = json.loads(os.environ.get('DIMENSION_COUNTS') or '{}')
except Exception:
    dc = {}
balance = []
for slug, label in DIMS:
    row = dc.get(slug, {})
    balance.append({
        'dimension': label,
        'act': int(row.get('act', 0)),
        'plan': int(row.get('plan', 0)),
        'observe': int(row.get('observe', 0)),
        'total': int(row.get('total', 0)),
    })
print(json.dumps(balance))
PYEOF
)

# Build next_actions array
next_actions="["
na_first=true
add_action() {
  if $na_first; then na_first=false; else next_actions="$next_actions, "; fi
  next_actions="$next_actions{\"skill\": \"$1\", \"reason\": \"$2\"}"
}

case "$PHASE" in
  scouting)
    add_action "trend-scout" "Start or continue trend scouting"
    ;;
  researching)
    add_action "trend-scout" "Web research in progress — re-invoke to continue"
    ;;
  generating)
    add_action "trend-scout" "Candidate generation in progress — re-invoke to continue"
    ;;
  selecting)
    add_action "trend-scout" "Candidates ready for selection — edit trend-candidates.md then re-invoke"
    ;;
  modeling)
    if [ "$HAS_PORTFOLIO_PROJECT" = "true" ] && [ "$HAS_PORTFOLIO_CONTEXT" = "false" ]; then
      add_action "trends-bridge" "Run /bridge portfolio-to-tips first to ground solutions in actual products"
    fi
    add_action "value-modeler" "Candidates agreed — build value model next"
    ;;
  modeling-paths)
    if [ "$HAS_PORTFOLIO_PROJECT" = "true" ] && [ "$HAS_PORTFOLIO_CONTEXT" = "false" ]; then
      add_action "trends-bridge" "Run /bridge portfolio-to-tips before Phase 2 to ground solutions in actual products"
    fi
    add_action "value-modeler" "Relationship networks built — continue to generate solution templates"
    ;;
  modeling-scoring)
    add_action "value-modeler" "Solutions generated — continue to BR scoring and ranking"
    ;;
  modeling-curating)
    add_action "value-modeler" "Ranked solutions complete — continue for optional catalog curation"
    ;;
  reporting)
    add_action "trend-report" "Value model complete — ready to generate trend report"
    if [ "$HAS_PORTFOLIO_CONTEXT" = "true" ] && [ -n "$PORTFOLIO_CONTEXT_VERSION" ] && [ "$PORTFOLIO_CONTEXT_VERSION" \< "3.1" ]; then
      add_action "trends-bridge" "Re-run /bridge portfolio-to-tips for v3.1 provider differentiators in trend-report"
    fi
    ;;
  verification)
    add_action "cogni-trends:verify-trend-report" "$CLAIMS_TOTAL claims extracted — verify, review, and apply corrections via the extended pipeline"
    ;;
  revision)
    add_action "cogni-trends:verify-trend-report" "${REVISION_CHANGES:-0} claims resolved — re-enter the verify pipeline to apply corrections and removals"
    ;;
  complete)
    # Polish
    if [ "$HAS_COPYWRITER" = "false" ]; then
      add_action "cogni-copywriting:copywrite" "Polish report prose for executive readability"
    fi
    # Visualize
    if [ "$HAS_ENRICHED_REPORT" = "false" ]; then
      add_action "cogni-visual:enrich-report" "Generate themed HTML with charts and diagrams"
    fi
    add_action "cogni-visual:story-to-slides" "Create a PowerPoint presentation from the report"
    add_action "cogni-visual:story-to-web" "Create a scrollable landing page from the report"
    add_action "cogni-visual:story-to-storyboard" "Create a multi-poster print storyboard"
    # Accumulate
    add_action "cogni-trends:trends-catalog" "Import to industry catalog for cross-pursuit reuse"
    # Dashboard
    if [ "$HAS_DASHBOARD" = "false" ]; then
      add_action "cogni-trends:trends-dashboard" "Generate interactive TIPS project dashboard"
    fi
    # Portfolio bridge upgrade
    if [ "$HAS_PORTFOLIO_CONTEXT" = "true" ] && [ -n "$PORTFOLIO_CONTEXT_VERSION" ] && [ "$PORTFOLIO_CONTEXT_VERSION" \< "3.1" ]; then
      add_action "trends-bridge" "Re-run /bridge portfolio-to-tips for v3.1 provider differentiators"
    fi
    ;;
esac
next_actions="$next_actions]"

# Health check: detect staleness (must run before the re-anchor injection
# below, which reads $stale_warnings — under `set -u` reading it before this
# block initializes it raised an unbound-variable error that was silently
# swallowed, leaving HAS_STALE_BLUEPRINTS=false and the re-anchor recommendation
# never reaching next_actions for any gated phase).
stale_warnings="[]"
if $HEALTH_CHECK; then
  stale_warnings=$(python3 -c "
import json, os
from datetime import datetime

warnings = []
proj = '$PROJECT_DIR'

# Check if report is stale relative to candidates
scout_file = os.path.join(proj, '.metadata', 'trend-scout-output.json')
report_file = os.path.join(proj, 'tips-trend-report.md')

if os.path.exists(scout_file) and os.path.exists(report_file):
    scout_mtime = os.path.getmtime(scout_file)
    report_mtime = os.path.getmtime(report_file)
    if scout_mtime > report_mtime:
        warnings.append({
            'type': 'stale_report',
            'message': 'Trend-scout output was modified after the report was generated — report may need refresh'
        })

# Check if report is stale relative to value model
value_model_file = os.path.join(proj, 'tips-value-model.json')
if os.path.exists(value_model_file) and os.path.exists(report_file):
    vm_mtime = os.path.getmtime(value_model_file)
    report_mtime = os.path.getmtime(report_file)
    if vm_mtime > report_mtime:
        warnings.append({
            'type': 'stale_report',
            'message': 'Value model was modified after the report was generated — report may need refresh'
        })

# Check if portfolio context is newer than value model (re-anchor needed)
portfolio_ctx = os.path.join(proj, 'portfolio-context.json')
value_model = os.path.join(proj, 'tips-value-model.json')
if os.path.exists(portfolio_ctx) and os.path.exists(value_model):
    ctx_mtime = os.path.getmtime(portfolio_ctx)
    vm_mtime = os.path.getmtime(value_model)
    if ctx_mtime > vm_mtime:
        warnings.append({
            'type': 'stale_blueprints',
            'message': 'Portfolio context was updated after blueprints were generated — consider re-anchoring solution templates'
        })

# Check if web research signals are old (> 30 days)
raw_signals = os.path.join(proj, '.logs', 'web-research-raw.json')
if os.path.exists(raw_signals):
    age_days = (datetime.now().timestamp() - os.path.getmtime(raw_signals)) / 86400
    if age_days > 30:
        warnings.append({
            'type': 'stale_research',
            'message': f'Web research signals are {int(age_days)} days old — consider re-running trend-scout for fresh data'
        })

# Check candidate distribution balance
if os.path.exists(scout_file):
    try:
        d = json.load(open(scout_file))
        items = d.get('tips_candidates', {}).get('items', [])
        if items:
            DIMS = ['externe-effekte', 'neue-horizonte', 'digitale-wertetreiber', 'digitales-fundament']
            dim_counts = {}
            for i, item in enumerate(items):
                dim = item.get('dimension') or DIMS[min(i // 15, 3)]
                hor = item.get('horizon', 'unknown')
                key = f'{dim}/{hor}'
                dim_counts[key] = dim_counts.get(key, 0) + 1

            expected = {'act': 5, 'plan': 5, 'observe': 5}
            for dim in ['externe-effekte', 'neue-horizonte', 'digitale-wertetreiber', 'digitales-fundament']:
                for hor, exp in expected.items():
                    actual = dim_counts.get(f'{dim}/{hor}', 0)
                    if actual != exp:
                        warnings.append({
                            'type': 'distribution_imbalance',
                            'message': f'{dim}/{hor}: expected {exp} candidates, found {actual}'
                        })

            # Check low-confidence candidates (missing confidence_tier counts as uncertain)
            low_conf = sum(1 for i in items if i.get('confidence_tier', 'uncertain') in ('low', 'uncertain'))
            if low_conf > len(items) * 0.3:
                warnings.append({
                    'type': 'low_confidence',
                    'message': f'{low_conf} of {len(items)} candidates have low or uncertain confidence'
                })

            # Check evidence coverage — only web-signal candidates should have URLs
            # Training-sourced candidates legitimately have no source_url
            web_candidates = [i for i in items if i.get('source') == 'web-signal']
            if web_candidates:
                web_no_url = sum(1 for i in web_candidates if not i.get('source_url'))
                if web_no_url > len(web_candidates) * 0.3:
                    warnings.append({
                        'type': 'low_evidence',
                        'message': f'{web_no_url} of {len(web_candidates)} web-signal candidates have no source URL — report evidence may be thin'
                    })
    except Exception:
        pass

print(json.dumps(warnings))
" 2>/dev/null || echo "[]")
fi

# Inject re-anchor action when stale blueprints detected (prepend before existing actions)
if $HEALTH_CHECK; then
  # Defensive default: guard against unbound $stale_warnings if a future edit
  # decouples the staleness-detection block above from this injection block.
  stale_warnings="${stale_warnings:-[]}"
  HAS_STALE_BLUEPRINTS=$(echo "$stale_warnings" | python3 -c "
import json, sys
try:
    w = json.load(sys.stdin)
    print('true' if any(x.get('type') == 'stale_blueprints' for x in w) else 'false')
except:
    print('false')
" 2>/dev/null || echo "false")

  if [ "$HAS_STALE_BLUEPRINTS" = "true" ]; then
    case "$PHASE" in
      modeling-scoring|modeling-curating|reporting|complete)
        next_actions=$(echo "$next_actions" | python3 -c "
import json, sys
try:
    actions = json.load(sys.stdin)
    reanchor = {'skill': 'value-modeler', 'reason': 'Portfolio has changed since blueprints were generated — run re-anchor to update solution mappings'}
    actions.insert(0, reanchor)
    print(json.dumps(actions))
except:
    sys.stdout.write(sys.stdin.read())
" 2>/dev/null || echo "$next_actions")
        ;;
    esac
  fi
fi

cat << EOF
{
  "project": {
    "slug": "$PROJECT_SLUG",
    "language": "$PROJECT_LANGUAGE",
    "industry": "$INDUSTRY",
    "subsector": "$SUBSECTOR",
    "research_topic": "$RESEARCH_TOPIC"
  },
  "counts": {
    "candidates_total": $CANDIDATES_TOTAL,
    "candidates_web": $CANDIDATES_WEB,
    "candidates_training": $CANDIDATES_TRAINING,
    "candidates_user": $CANDIDATES_USER,
    "claims_total": $CLAIMS_TOTAL,
    "report_sections": $REPORT_SECTIONS,
    "investment_themes": $THEMES_COUNT,
    "solutions": $SOLUTIONS_COUNT,
    "ranked_solutions": $RANKED_COUNT,
    "blueprints": $BLUEPRINT_COUNT,
    "anchored_solutions": $ANCHORED_COUNT,
    "avg_readiness": $AVG_READINESS
  },
  "scoring": {
    "avg_score": $AVG_SCORE,
    "leading_pct": $LEADING_PCT,
    "confidence_distribution": $CONFIDENCE_COUNTS
  },
  "dimension_counts": $DIMENSION_COUNTS,
  "artifacts": {
    "web_research": $HAS_WEB_RESEARCH,
    "generator_log": $HAS_GENERATOR_LOG,
    "candidates_md": $HAS_CANDIDATES_MD,
    "selector_app": $HAS_SELECTOR_APP,
    "value_model": $HAS_VALUE_MODEL,
    "report": $HAS_REPORT,
    "claims": $HAS_CLAIMS,
    "insight_summary": $HAS_INSIGHT,
    "verification": $HAS_VERIFICATION,
    "copywriter_applied": $HAS_COPYWRITER,
    "copywriter_scope": "$COPYWRITER_SCOPE",
    "enriched_report": $HAS_ENRICHED_REPORT,
    "dashboard": $HAS_DASHBOARD
  },
  "web_research_status": "$WEB_RESEARCH_STATUS",
  "workflow_state": "$WORKFLOW_STATE",
  "agreed_at": "$AGREED_AT",
  "verification": {
    "verdict": "$VERIFICATION_VERDICT",
    "passed": $VERIFICATION_PASSED,
    "failed": $VERIFICATION_FAILED,
    "review": $VERIFICATION_REVIEW
  },
  "portfolio_bridge": {
    "portfolio_project_found": $HAS_PORTFOLIO_PROJECT,
    "context_file": $HAS_PORTFOLIO_CONTEXT,
    "context_version": $(if [ -n "$PORTFOLIO_CONTEXT_VERSION" ]; then echo "\"$PORTFOLIO_CONTEXT_VERSION\""; else echo "null"; fi),
    "features_count": $PORTFOLIO_FEATURES_COUNT,
    "differentiators_count": ${PORTFOLIO_DIFFERENTIATORS_COUNT:-0}
  },
  "portfolio_anchors": {
    "total": $ANCHORED_COUNT,
    "needs_delivered": $ANCHOR_NEEDS_DELIVERED,
    "needs_undelivered": $ANCHOR_NEEDS_UNDELIVERED,
    "quality_issues": $ANCHOR_QUALITY_COUNT,
    "products": $ANCHOR_PRODUCTS_JSON
  },
  "phase": "$PHASE",
  "next_actions": $next_actions,
  "stages": $STAGES_JSON,
  "dimension_balance": $DIMENSION_BALANCE_JSON,
  "stale_warnings": $stale_warnings
}
EOF
