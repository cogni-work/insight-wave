#!/usr/bin/env bash
# test_check_breadcrumbs.sh — self-test for the maintainer-breadcrumb guard.
#
# Cases:
#   1. Negative controls (hex color, F1 formula, bare schema version) -> exit 0.
#   2. Breadcrumb-laden fixture (#999, v9.9.9, M9, Slice 9, F99) -> exit 1,
#      with the offending file + line reported (issue #377 acceptance test).
#   3. Real tree against the committed baseline -> exit 0 (ratchet passes today).
#
# bash 3.2 + stdlib python3 only.

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-breadcrumbs.py"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

FAILED=0
check() {  # check <label> <condition-exit-code>
  if [ "$2" -eq 0 ]; then
    green "PASS: $1"
  else
    red "FAIL: $1"
    FAILED=1
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# A baseline path that does not exist -> guard treats the baseline as empty, so
# every detected occurrence counts as a (new) violation. This is what lets the
# breadcrumb fixture fail deterministically without depending on the real baseline.
EMPTY_BASELINE="$WORK/no-such-baseline.json"

# ---------------------------------------------------------------------------
# Case 1 — negative controls: nothing here may trip the guard.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/clean/skills/demo"
cat > "$WORK/clean/skills/demo/SKILL.md" <<'EOF'
---
name: demo
---
Overlay fill uses #000000B3 for readability.
Rankings use the F1 averaging formula from the patent.
Schema is pinned at "version": "0.1.0" in the JSON envelope.
Filenames follow the draft-vN convention.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/clean" --baseline "$EMPTY_BASELINE" \
        "skills/demo/SKILL.md" 2>/dev/null)
CODE=$?
set -e
check "negative controls exit 0" "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"
echo "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['success'] is True, d
assert d['data']['summary']['total']==0, d['data']['summary']
"
check "negative controls report zero violations" "$?"

# ---------------------------------------------------------------------------
# Case 2 — breadcrumb-laden fixture: must fail, naming file + lines.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/dirty/agents"
cat > "$WORK/dirty/agents/bad.md" <<'EOF'
Internal note about #999 regression handling.
This behaviour shipped in v9.9.9 last release.
Tracked under M9 and the Slice 9 scope cut.
Root cause is finding F99 from the audit.
EOF

set +e
OUT=$(python3 "$GUARD" --root "$WORK/dirty" --baseline "$EMPTY_BASELINE" \
        "agents/bad.md" 2>/dev/null)
CODE=$?
set -e
check "breadcrumb fixture exits 1" "$([ "$CODE" -eq 1 ] && echo 0 || echo 1)"
echo "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
v=d['data']['violations']
got={(x['pattern'],x['match'],x['line']) for x in v}
want={
  ('issue_ref','#999',1),
  ('version_tag','v9.9.9',2),
  ('milestone','M9',3),
  ('slice','Slice 9',3),
  ('finding','F99',4),
}
missing=want-got
assert not missing, 'missing: %r (got %r)' % (missing, got)
assert all(x['file']=='agents/bad.md' for x in v), v
assert d['success'] is False, d
"
check "breadcrumb fixture names every token with correct file+line" "$?"

# ---------------------------------------------------------------------------
# Case 3 — real tree against the committed baseline: ratchet passes.
# ---------------------------------------------------------------------------
set +e
python3 "$GUARD" >/dev/null 2>&1
CODE=$?
set -e
check "real tree passes against committed baseline" \
  "$([ "$CODE" -eq 0 ] && echo 0 || echo 1)"

echo ""
if [ "$FAILED" -eq 0 ]; then
  green "All breadcrumb-guard tests passed."
  exit 0
else
  red "Some breadcrumb-guard tests failed."
  exit 1
fi
