#!/usr/bin/env bash
# test_synthesis_impact.sh — functional test for synthesis-impact.py scan.
#
# The evidence-aware refresh detector: when a new source lands, flag every
# existing synthesis whose cited slugs intersect the new source's neighborhood
# AND whose `updated:` predates the new source's wiki-arrival `created:`.
#
# Asserts:
#   1. Positive — a synthesis citing a neighborhood source, updated BEFORE the new
#      source, is flagged (source-mediated → confidence high, age_gap_days set).
#   2. Negative — a synthesis with no slug intersection is NOT flagged.
#   3. Negative — a synthesis UPDATED AFTER the new source (already fresh) is NOT
#      flagged (the newer-evidence gate).
#   4. Negative — a synthesis with a missing/unparseable `updated:` is skipped
#      (keep-on-doubt).
#   5. --min-confidence high drops a concept/entity-mediated-only overlap.
#   6. The self-compute neighborhood path (no --related) agrees with the --related
#      reuse path on the flagged-synthesis set.
#
# bash 3.2 + stdlib python3 only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/synthesis-impact.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: synthesis-impact.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

W="$WORK/wiki-root"
mkdir -p "$W/wiki/sources" "$W/wiki/concepts" "$W/wiki/syntheses"

# --- new source (arrives 2026-06-08), strongly overlaps src-a via the "99" anchor ---
cat > "$W/wiki/sources/src-b.md" <<'EOF'
---
id: src-b
title: EU AI Act Article 99 penalties update for high-risk systems
type: source
sources: ["https://example.com/b"]
created: 2026-06-08
updated: 2026-06-08
pre_extracted_claims:
  - id: clm-001
    text: Article 99 raises penalties for high-risk systems providers.
---
body
EOF

# --- existing source in the neighborhood ---
cat > "$W/wiki/sources/src-a.md" <<'EOF'
---
id: src-a
title: EU AI Act Article 99 penalties analysis for high-risk systems
type: source
sources: ["https://example.com/a"]
created: 2025-12-01
updated: 2025-12-01
pre_extracted_claims:
  - id: clm-001
    text: Article 99 sets penalties for high-risk systems.
---
body
EOF

# --- concept the synthesis also leaned on ---
cat > "$W/wiki/concepts/concept-x.md" <<'EOF'
---
id: concept-x
title: High-risk AI penalties
type: concept
created: 2025-12-01
updated: 2025-12-01
---
body
EOF

# --- synthesis citing src-a + concept-x, updated BEFORE the new source ---
cat > "$W/wiki/syntheses/syn-old.md" <<'EOF'
---
id: syn-old
title: AI Act Compliance Synthesis
type: synthesis
created: 2026-01-01
updated: 2026-01-01
sources:
  - wiki://src-a
  - wiki://concept-x
derived_from_research: proj-1
---
body
EOF

# --- synthesis with no overlap ---
cat > "$W/wiki/syntheses/syn-unrelated.md" <<'EOF'
---
id: syn-unrelated
title: Unrelated Topic
type: synthesis
created: 2026-01-01
updated: 2026-01-01
sources:
  - wiki://src-zzz
---
body
EOF

# --- synthesis already newer than the source ---
cat > "$W/wiki/syntheses/syn-fresh.md" <<'EOF'
---
id: syn-fresh
title: Already Fresh
type: synthesis
created: 2026-06-09
updated: 2026-06-09
sources:
  - wiki://src-a
---
body
EOF

# --- synthesis with a missing updated: (keep-on-doubt) ---
cat > "$W/wiki/syntheses/syn-nodate.md" <<'EOF'
---
id: syn-nodate
title: No Update Date
type: synthesis
created: 2026-01-01
sources:
  - wiki://src-a
---
body
EOF

# 1–4. --related reuse path: only syn-old is flagged.
if python3 "$SCRIPT" scan --wiki-root "$W" --new-page src-b --related "src-a,concept-x" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['success'] is True, d
rc = d['data']['refresh_candidates']
slugs = {c['synthesis_slug'] for c in rc}
assert slugs == {'syn-old'}, ('only syn-old expected', slugs)
c = rc[0]
assert c['confidence'] == 'high', ('source-mediated → high', c)
assert c['synthesis_updated'] == '2026-01-01', c
assert c['age_gap_days'] == 158, ('2026-01-01 → 2026-06-08', c)
assert sorted(c['via_pages']) == ['concept-x', 'src-a'], c
print('OK')
" | grep -q OK; then
  green "PASS: --related scan flags only the older overlapping synthesis (high confidence)"
else
  red "FAIL: --related positive/negative set wrong"; errors=$((errors+1))
fi

# 5. --min-confidence high with a concept-only neighborhood → empty (concept-mediated).
if python3 "$SCRIPT" scan --wiki-root "$W" --new-page src-b --related "concept-x" --min-confidence high | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['data']['refresh_candidates'] == [], d['data']['refresh_candidates']
print('OK')
" | grep -q OK; then
  green "PASS: --min-confidence high drops a concept/entity-mediated-only overlap"
else
  red "FAIL: --min-confidence high filtering wrong"; errors=$((errors+1))
fi

# 5b. medium (default) keeps the concept-only overlap (still flags syn-old).
if python3 "$SCRIPT" scan --wiki-root "$W" --new-page src-b --related "concept-x" | python3 -c "
import json, sys
d = json.load(sys.stdin)
slugs = {c['synthesis_slug'] for c in d['data']['refresh_candidates']}
assert slugs == {'syn-old'}, slugs
assert d['data']['refresh_candidates'][0]['confidence'] == 'medium', d['data']
print('OK')
" | grep -q OK; then
  green "PASS: default (medium) keeps a concept-mediated overlap (confidence medium)"
else
  red "FAIL: medium concept-mediated retention wrong"; errors=$((errors+1))
fi

# 6. Self-compute neighborhood (no --related) agrees on the flagged set.
if python3 "$SCRIPT" scan --wiki-root "$W" --new-page src-b | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['success'] is True, d
nb = d['data']['neighborhood']
assert 'src-b' not in nb, ('new page must self-exclude from its neighborhood', nb)
assert 'src-a' in nb, ('strong overlap src-a must be found self-computed', nb)
slugs = {c['synthesis_slug'] for c in d['data']['refresh_candidates']}
assert slugs == {'syn-old'}, ('self-compute agrees on flagged set', slugs)
print('OK')
" | grep -q OK; then
  green "PASS: self-compute neighborhood self-excludes the new page and agrees on the flagged set"
else
  red "FAIL: self-compute path wrong"; errors=$((errors+1))
fi

# 7. Fail-soft on an absent new page → success, empty candidates.
if python3 "$SCRIPT" scan --wiki-root "$W" --new-page ghost --related "src-a" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['refresh_candidates'] == [], d['data']
print('OK')
" | grep -q OK; then
  green "PASS: absent new page degrades fail-soft to empty candidates"
else
  red "FAIL: absent-new-page fail-soft wrong"; errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
