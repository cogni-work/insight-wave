#!/bin/bash
# Show cogni-tips project status with phase detection, candidate counts, and report status.
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
  echo '{"error": "Not a cogni-tips project (missing .metadata/trend-scout-output.json and tips-project.json)"}' >&2
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
    counts = {}
    for item in items:
        dim = item.get('dimension', 'unknown')
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
HAS_COPYWRITER="false"
COPYWRITER_SCOPE=""
CLAIMS_TOTAL=0

[ -f "$PROJECT_DIR/.logs/web-research-raw.json" ] && HAS_WEB_RESEARCH="true"
[ -f "$PROJECT_DIR/.logs/trend-generator-candidates.json" ] && HAS_GENERATOR_LOG="true"
[ -f "$PROJECT_DIR/trend-candidates.md" ] && HAS_CANDIDATES_MD="true"
[ -f "$PROJECT_DIR/trend-selector-app.html" ] && HAS_SELECTOR_APP="true"
[ -f "$PROJECT_DIR/tips-trend-report.md" ] && HAS_REPORT="true"
[ -f "$PROJECT_DIR/tips-trend-report-claims.json" ] && HAS_CLAIMS="true"
[ -f "$PROJECT_DIR/tips-insight-summary.md" ] && HAS_INSIGHT="true"
[ -f "$PROJECT_DIR/.metadata/trend-report-verification.json" ] && HAS_VERIFICATION="true"

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

# Verification status
VERIFICATION_VERDICT=""
VERIFICATION_PASSED=0
VERIFICATION_FAILED=0
VERIFICATION_REVIEW=0
if [ "$HAS_VERIFICATION" = "true" ]; then
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
    if [ "$HAS_VERIFICATION" = "true" ]; then
      PHASE="complete"
    elif [ "$HAS_CLAIMS" = "true" ] && [ "$CLAIMS_TOTAL" -gt 0 ]; then
      PHASE="verification"
    else
      PHASE="complete"
    fi
  else
    PHASE="reporting"
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
  reporting)
    add_action "trend-report" "Candidates agreed — ready to generate trend report"
    ;;
  verification)
    add_action "cogni-claims:claim-work" "$CLAIMS_TOTAL claims extracted — ready for verification"
    ;;
  complete)
    ;;
esac
next_actions="$next_actions]"

# Health check: detect staleness
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
            dim_counts = {}
            for item in items:
                dim = item.get('dimension', 'unknown')
                hor = item.get('horizon', 'unknown')
                key = f'{dim}/{hor}'
                dim_counts[key] = dim_counts.get(key, 0) + 1

            expected = {'act': 5, 'plan': 5, 'observe': 3}
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
    "report_sections": $REPORT_SECTIONS
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
    "report": $HAS_REPORT,
    "claims": $HAS_CLAIMS,
    "insight_summary": $HAS_INSIGHT,
    "verification": $HAS_VERIFICATION,
    "copywriter_applied": $HAS_COPYWRITER,
    "copywriter_scope": "$COPYWRITER_SCOPE"
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
  "phase": "$PHASE",
  "next_actions": $next_actions,
  "stale_warnings": $stale_warnings
}
EOF
