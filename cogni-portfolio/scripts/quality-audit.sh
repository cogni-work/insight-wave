#!/bin/bash
# Run structural quality checks on portfolio entities.
# Usage: quality-audit.sh <project-dir> [--quick]
# --quick: structural checks only (default on resume, ~2s)
# Without --quick: also delegates to quality assessor agents for deep LLM assessment
# Outputs JSON with quality_audit object.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-}"
QUICK=false
if [ "${2:-}" = "--quick" ]; then
  QUICK=true
fi

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Valid project directory required. Usage: quality-audit.sh <project-dir> [--quick]"}' >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/portfolio.json" ]; then
  echo '{"error": "Not a cogni-portfolio project (missing portfolio.json)"}' >&2
  exit 1
fi

# Run structural quality checks via Python
python3 -c "
import json, os, glob, re

proj = '$PROJECT_DIR'

# Parity language patterns (feature descriptions)
PARITY_WORDS = re.compile(r'\b(robust|innovative|cutting-edge|best-in-class|world-class)\b', re.IGNORECASE)
# Outcome leak patterns (benefit language in IS layer)
OUTCOME_LEAK = re.compile(r'\b(reduces|enables|ensures|improves|drives)\b', re.IGNORECASE)
# Generic outcome patterns in DOES statements
PARITY_DOES = re.compile(r'\b(improves efficiency|reduces costs|saves time|enhances productivity)\b', re.IGNORECASE)

features_flagged = []
features_checked = 0
propositions_flagged = []
propositions_checked = 0

# --- Feature checks ---
# Load features and sort by sort_order (value-to-utility), then slug
_feature_files = glob.glob(os.path.join(proj, 'features', '*.json'))
_feature_data = []
for _ff in _feature_files:
    try:
        _fd = json.load(open(_ff))
        _feature_data.append((_ff, _fd))
    except Exception:
        pass
_feature_data.sort(key=lambda x: (x[1].get('sort_order') if x[1].get('sort_order') is not None else float('inf'), os.path.basename(x[0])))

for f, d in _feature_data:
    features_checked += 1
    slug = os.path.basename(f)[:-5]
    issues = []
    desc = d.get('description', '')
    words = desc.split()
    wc = len(words)

    # Word count checks
    if wc < 15 or wc > 50:
        issues.append({'dimension': 'word_count', 'severity': 'flag',
                       'detail': f'Description has {wc} words (target 20-35, acceptable 15-50)'})
    elif wc < 20 or wc > 35:
        issues.append({'dimension': 'word_count', 'severity': 'warn',
                       'detail': f'Description has {wc} words (target 20-35)'})

    # Parity language check
    matches = PARITY_WORDS.findall(desc)
    if matches:
        issues.append({'dimension': 'parity_language', 'severity': 'warn',
                       'detail': f'Parity language detected: {\", \".join(set(m.lower() for m in matches))}'})

    # Outcome leak check
    matches = OUTCOME_LEAK.findall(desc)
    if matches:
        issues.append({'dimension': 'outcome_leak', 'severity': 'warn',
                       'detail': f'Benefit language in IS layer: {\", \".join(set(m.lower() for m in matches))}'})

    if issues:
        features_flagged.append({'slug': slug, 'issues': issues})

# --- Proposition checks ---
for f in sorted(glob.glob(os.path.join(proj, 'propositions', '*.json'))):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    propositions_checked += 1
    slug = os.path.basename(f)[:-5]
    issues = []

    # DOES statement checks
    does = d.get('does_statement', '')
    does_words = does.split()
    does_wc = len(does_words)

    if does_wc < 10 or does_wc > 40:
        issues.append({'dimension': 'does_word_count', 'severity': 'flag',
                       'detail': f'DOES has {does_wc} words (target 15-30, acceptable 10-40)'})
    elif does_wc < 15 or does_wc > 30:
        issues.append({'dimension': 'does_word_count', 'severity': 'warn',
                       'detail': f'DOES has {does_wc} words (target 15-30)'})

    # Parity DOES check
    parity = PARITY_DOES.findall(does)
    if parity:
        issues.append({'dimension': 'parity_does', 'severity': 'warn',
                       'detail': f'Generic outcome language in DOES: {\", \".join(set(m.lower() for m in parity))}'})

    # MEANS statement checks
    means = d.get('means_statement', '')
    means_words = means.split()
    means_wc = len(means_words)

    if means_wc < 10 or means_wc > 40:
        issues.append({'dimension': 'means_word_count', 'severity': 'flag',
                       'detail': f'MEANS has {means_wc} words (target 15-30, acceptable 10-40)'})
    elif means_wc < 15 or means_wc > 30:
        issues.append({'dimension': 'means_word_count', 'severity': 'warn',
                       'detail': f'MEANS has {means_wc} words (target 15-30)'})

    # Missing evidence check
    evidence = d.get('evidence', None)
    if evidence is None or (isinstance(evidence, list) and len(evidence) == 0):
        issues.append({'dimension': 'missing_evidence', 'severity': 'info',
                       'detail': 'No evidence array or empty'})

    # Circular MEANS check (first 5 words overlap with DOES)
    if does_words and means_words:
        does_start = set(w.lower().strip('.,;:') for w in does_words[:5])
        means_start = set(w.lower().strip('.,;:') for w in means_words[:5])
        # Exclude common stop words from overlap check
        stop = {'the', 'a', 'an', 'and', 'or', 'to', 'of', 'in', 'for', 'by', 'with', 'is', 'it', 'that', 'this'}
        overlap = (does_start - stop) & (means_start - stop)
        if len(overlap) >= 2:
            issues.append({'dimension': 'circular_means', 'severity': 'warn',
                           'detail': f'MEANS opening overlaps with DOES: {\", \".join(sorted(overlap))}'})

    if issues:
        propositions_flagged.append({'slug': slug, 'issues': issues})

result = {
    'quality_audit': {
        'features_flagged': features_flagged,
        'propositions_flagged': propositions_flagged,
        'summary': {
            'features_checked': features_checked,
            'features_flagged': len(features_flagged),
            'propositions_checked': propositions_checked,
            'propositions_flagged': len(propositions_flagged)
        }
    }
}
print(json.dumps(result, indent=2))
"
