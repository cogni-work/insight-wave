#!/usr/bin/env bash
# test_portal_staleness.sh — contract test for pipeline-summary.py portal-staleness.
#
# The #491 curated-portal auto-refresh stamps each engine-owned lead-in span with
# `MACHINE-OWNED:PORTAL-LEADIN:START refreshed:<date> bullets:<N>`, where <N> is
# the slug-bullet count under that theme at stamp time. This subcommand is the
# read-only consumer of that stamp (the producer shipped ahead of it): drift =
# a theme's live slug-bullet count exceeds the stamped <N> by more than the
# threshold.
#
# Asserts:
#   1. A theme stale by > threshold is flagged with correct stamped/live/delta.
#   2. A theme within threshold is NOT flagged.
#   3. A theme with no machine lead-in span (no stamp) is skipped.
#   4. A zero-drift base yields stale_count 0 + empty list (silent — the
#      acceptance criterion).
#   5. A missing index.md is fail-soft success (stale_count 0).
#   6. --threshold overrides the default (2).
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/pipeline-summary.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: pipeline-summary.py not found at $SCRIPT"; exit 1
fi

field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki"
cat > "$WIKI/wiki/index.md" <<'EOF'
# Index

## AI Act
<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-05-01 bullets:2 -->
This theme covers the EU AI Act. Read the obligations first.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->
- [[src-a]] — first source
- [[src-b]] — second source
- [[src-c]] — third source
- [[src-d]] — fourth source
- [[src-e]] — fifth source

## Data Act
<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-05-01 bullets:1 -->
Framing for the Data Act.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->
- [[d-a]] — one
- [[d-b]] — two

## Human-curated (no machine lead-in)
- [[h-a]] — alpha
- [[h-b]] — beta
- [[h-c]] — gamma
- [[h-d]] — delta
- [[h-e]] — epsilon
EOF

# --- 1 + 2 + 3: default threshold (2) on the mixed base -----------------------
OUT=$(python3 "$SCRIPT" portal-staleness --wiki-root "$WIKI")
[ "$(echo "$OUT" | field '["success"]')" = "True" ] && green "PASS: portal-staleness envelope success" || { red "FAIL: not success"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["stale_count"]')" = "1" ] && green "PASS: exactly one stale theme (AI Act, delta 3 > 2)" || { red "FAIL: stale_count != 1"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["stale_themes"][0]["theme"]')" = "AI Act" ] && green "PASS: stale theme is 'AI Act'" || { red "FAIL: wrong stale theme"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["stale_themes"][0]["stamped_bullets"]')" = "2" ] && green "PASS: stamped_bullets=2" || { red "FAIL: stamped_bullets wrong"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["stale_themes"][0]["live_bullets"]')" = "5" ] && green "PASS: live_bullets=5" || { red "FAIL: live_bullets wrong"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["stale_themes"][0]["delta"]')" = "3" ] && green "PASS: delta=3" || { red "FAIL: delta wrong"; errors=$((errors+1)); }
# Data Act (delta 1) is within threshold → not flagged; Human-curated has no stamp → skipped.
echo "$OUT" | grep -q "Data Act" && { red "FAIL: Data Act flagged despite within-threshold delta"; errors=$((errors+1)); } || green "PASS: within-threshold theme (Data Act) not flagged"
echo "$OUT" | grep -q "Human-curated" && { red "FAIL: no-machine-lead-in theme flagged"; errors=$((errors+1)); } || green "PASS: no-machine-lead-in theme skipped"

# --- 6: --threshold override --------------------------------------------------
# threshold 0 → Data Act (delta 1 > 0) AND AI Act (delta 3 > 0) both flag.
OUT0=$(python3 "$SCRIPT" portal-staleness --wiki-root "$WIKI" --threshold 0)
[ "$(echo "$OUT0" | field '["data"]["stale_count"]')" = "2" ] && green "PASS: --threshold 0 flags both stamped themes" || { red "FAIL: threshold-0 stale_count != 2"; errors=$((errors+1)); }
# threshold 5 → nobody is stale (max delta is 3).
OUT5=$(python3 "$SCRIPT" portal-staleness --wiki-root "$WIKI" --threshold 5)
[ "$(echo "$OUT5" | field '["data"]["stale_count"]')" = "0" ] && green "PASS: --threshold 5 flags nothing (silent)" || { red "FAIL: threshold-5 stale_count != 0"; errors=$((errors+1)); }

# --- 4: zero-drift base is silent ---------------------------------------------
WIKI2="$WORK/wiki-clean"
mkdir -p "$WIKI2/wiki"
cat > "$WIKI2/wiki/index.md" <<'EOF'
# Index

## Fresh theme
<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-06-05 bullets:2 -->
Lead-in authored at the same moment the two bullets landed.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->
- [[f-a]] — one
- [[f-b]] — two
EOF
OUTC=$(python3 "$SCRIPT" portal-staleness --wiki-root "$WIKI2")
[ "$(echo "$OUTC" | field '["data"]["stale_count"]')" = "0" ] && green "PASS: zero-drift base reports stale_count 0 (silent)" || { red "FAIL: zero-drift stale_count != 0"; errors=$((errors+1)); }
[ "$(echo "$OUTC" | field '["data"]["stale_themes"]')" = "[]" ] && green "PASS: zero-drift stale_themes empty" || { red "FAIL: zero-drift list not empty"; errors=$((errors+1)); }

# --- 5: missing index.md is fail-soft success ---------------------------------
OUTM=$(python3 "$SCRIPT" portal-staleness --wiki-root "$WORK/does-not-exist")
[ "$(echo "$OUTM" | field '["success"]')" = "True" ] && green "PASS: missing index.md is fail-soft success" || { red "FAIL: missing index not success"; errors=$((errors+1)); }
[ "$(echo "$OUTM" | field '["data"]["stale_count"]')" = "0" ] && green "PASS: missing index.md stale_count 0" || { red "FAIL: missing index stale_count != 0"; errors=$((errors+1)); }

if [ "$errors" -eq 0 ]; then
  green "All portal-staleness tests passed."
  exit 0
else
  red "$errors portal-staleness test(s) failed."
  exit 1
fi
