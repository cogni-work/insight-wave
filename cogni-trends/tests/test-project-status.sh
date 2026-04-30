#!/usr/bin/env bash
# Smoke test for cogni-trends/scripts/project-status.sh against a fully-populated
# tips-value-model.json fixture. Pins the script's contract for value-modeler
# counts and stage-status derivation. Stdlib-only (bash + python3, no pip deps).
#
# Regression guard for issue #183 — script returning zero counts despite a
# fully-populated value model. Root cause was LLM rendering (fixed in e70b59c,
# v0.4.22), but this fixture pins the script's own contract so any future
# schema-drift or silent-exception regression in the read path surfaces fast.
#
# Usage: bash cogni-trends/tests/test-project-status.sh
# Exits non-zero on any assertion failure.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/project-status.sh"
FIXTURE="$TESTS_DIR/fixtures/tips-value-model-complete.json"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: script not found at $SCRIPT" >&2
  exit 1
fi
if [ ! -f "$FIXTURE" ]; then
  echo "FAIL: fixture not found at $FIXTURE" >&2
  exit 1
fi

# Build a minimal project workspace in a temp dir so project-status.sh has the
# files it needs to skip the early-phase short-circuits and actually read the
# value-model fixture.
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT
PROJECT_DIR="$TMPROOT/fixture-project"
mkdir -p "$PROJECT_DIR/.metadata" "$PROJECT_DIR/.logs"

cp "$FIXTURE" "$PROJECT_DIR/tips-value-model.json"

# Minimal tips-project.json so the script can identify the project
cat > "$PROJECT_DIR/tips-project.json" <<EOF
{
  "project_id": "fixture-complete",
  "project_slug": "fixture-complete",
  "project_language": "en",
  "industry": "test",
  "subsector": "test",
  "research_topic": "test"
}
EOF

OUTPUT="$(bash "$SCRIPT" "$PROJECT_DIR" --health-check 2>/dev/null)"
RC=$?
if [ $RC -ne 0 ]; then
  echo "FAIL: project-status.sh exited $RC" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

# Run all assertions in one Python pass for terse output and non-zero exit on any failure.
# OUTPUT is passed via stdin; the assertion script lives in a here-doc'd temp file.
ASSERT_SCRIPT="$TMPROOT/assert.py"
cat > "$ASSERT_SCRIPT" <<'PYEOF'
import json, sys

doc = json.load(sys.stdin)
counts = doc.get("counts", {})
stages = doc.get("stages", [])

failures = []

def check(label, actual, expected):
    if actual == expected:
        print(f"OK   {label}: {actual}")
    else:
        print(f"FAIL {label}: got {actual!r}, expected {expected!r}")
        failures.append(label)

check("counts.investment_themes", counts.get("investment_themes"), 5)
check("counts.solutions",         counts.get("solutions"),         12)
check("counts.ranked_solutions",  counts.get("ranked_solutions"),  12)
check("counts.blueprints",        counts.get("blueprints"),        12)
check("counts.anchored_solutions",counts.get("anchored_solutions"),12)
check("counts.avg_readiness",     counts.get("avg_readiness"),     1.0)

# stages 4..8 (zero-indexed) cover the five value-modeler rows the issue named:
# Value Chains & Themes, Solution Templates, BR Scoring & Ranking,
# Solution Blueprints, Portfolio Anchors.
expected_stage_names = [
    "Value Chains & Themes",
    "Solution Templates",
    "BR Scoring & Ranking",
    "Solution Blueprints",
    "Portfolio Anchors",
]
for offset, expected_name in enumerate(expected_stage_names):
    idx = 4 + offset
    if idx >= len(stages):
        print(f"FAIL stages[{idx}] missing — only {len(stages)} stages emitted")
        failures.append(f"stages[{idx}]")
        continue
    s = stages[idx]
    name_ok = s.get("name") == expected_name
    status_ok = s.get("status") == "done"
    if name_ok and status_ok:
        print(f"OK   stages[{idx}] {s['name']!r} status=done")
    else:
        print(f"FAIL stages[{idx}] name={s.get('name')!r} status={s.get('status')!r} (expected {expected_name!r}/done)")
        failures.append(f"stages[{idx}]")

if failures:
    print(f"\n{len(failures)} assertion(s) failed", file=sys.stderr)
    sys.exit(1)
print("\nAll assertions passed.")
PYEOF

printf '%s' "$OUTPUT" | python3 "$ASSERT_SCRIPT"
