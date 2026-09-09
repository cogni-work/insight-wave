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
# Also a regression guard for issue #1717 — the `complete)` arm of the script's
# next_actions block was reachable by no suite, so its dispatch tokens (notably
# cogni-workspace:copywriter) had no coverage. The second fixture below drives the
# script to PHASE=complete and pins that token set by exact whole-token equality.
#
# Mutation recipe proving that guard has teeth (cogni-service instrument):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root <repo-root> \
#     --file cogni-trends/scripts/project-status.sh \
#     --expr 's/cogni-workspace:copywriter/cogni-workspace:copywrite/g' \
#     --test 'bash cogni-trends/tests/test-project-status.sh' \
#     --case 'project-status-03-next-actions-copywriter'
# Verdict must be guard_verified: cases -03 and -04 go RED under the mutation and
# GREEN on restore. The token has exactly one occurrence in the script, so the
# expression cannot silently no-op.
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
        print(f"PASS: {label} - {actual}")
    else:
        print(f"FAIL: {label} - got {actual!r}, expected {expected!r}")
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
        print(f"FAIL: stages-{idx} - missing, only {len(stages)} stages emitted")
        failures.append(f"stages-{idx}")
        continue
    s = stages[idx]
    name_ok = s.get("name") == expected_name
    status_ok = s.get("status") == "done"
    if name_ok and status_ok:
        print(f"PASS: stages-{idx} - {s['name']!r} status=done")
    else:
        print(f"FAIL: stages-{idx} - name={s.get('name')!r} status={s.get('status')!r} (expected {expected_name!r}/done)")
        failures.append(f"stages-{idx}")

if failures:
    print(f"\n{len(failures)} assertion(s) failed", file=sys.stderr)
    sys.exit(1)
print("\nAll assertions passed.")
PYEOF

# ---------------------------------------------------------------------------
# Second fixture — complete phase (issue #1717).
# ---------------------------------------------------------------------------
PROJECT_DIR_COMPLETE="$TMPROOT/complete-project"
mkdir -p "$PROJECT_DIR_COMPLETE/.metadata"

cat > "$PROJECT_DIR_COMPLETE/tips-project.json" <<EOF
{
  "project_id": "fixture-complete-phase",
  "project_slug": "fixture-complete-phase",
  "project_language": "en",
  "industry": "test",
  "subsector": "test",
  "research_topic": "test"
}
EOF

# workflow_state "report-complete" is the unconditional route to PHASE=complete
# (project-status.sh:509-510) — it depends on no artifact file. There is no
# metadata.copywriter_applied key, so HAS_COPYWRITER stays at its default of
# false (:162, flip site :303-315) and the guard at :862 is entered. No booklet,
# enriched-report, dashboard or portfolio-context artifacts are written either,
# which is what makes the token set asserted below an exact seven.
cat > "$PROJECT_DIR_COMPLETE/.metadata/trend-scout-output.json" <<EOF
{
  "execution": {
    "workflow_state": "report-complete"
  }
}
EOF

# --health-check is DELIBERATELY omitted here, and the omission is load-bearing:
# project-status.sh:1040-1106 injects additional next_actions entries under
# `if $HEALTH_CHECK`, and `complete` is in the gated case list at :1053. Passing
# the flag would put the exact-set pin below at the mercy of the staleness
# detector. Do not copy the --health-check from the invocation above.
OUTPUT_COMPLETE="$(bash "$SCRIPT" "$PROJECT_DIR_COMPLETE" 2>/dev/null)"
RC_RUN_COMPLETE=$?
if [ $RC_RUN_COMPLETE -ne 0 ]; then
  echo "FAIL: project-status.sh exited $RC_RUN_COMPLETE on the complete-phase fixture" >&2
  echo "$OUTPUT_COMPLETE" >&2
  exit 1
fi

ASSERT_COMPLETE="$TMPROOT/assert-complete.py"
cat > "$ASSERT_COMPLETE" <<'PYEOF'
import json, sys

doc = json.load(sys.stdin)
artifacts = doc.get("artifacts", {})
skills = [a.get("skill") for a in doc.get("next_actions", [])]

failures = []

def check(label, actual, expected):
    if actual == expected:
        print(f"PASS: {label} - {actual}")
    else:
        print(f"FAIL: {label} - got {actual!r}, expected {expected!r}")
        failures.append(label)

# Anti-vacuity. Without this, a fixture that silently stops reaching `complete`
# would leave the token cases below asserting over some other phase's
# next_actions instead of failing loudly.
check("project-status-01-complete-phase", doc.get("phase"), "complete")

# project-status.sh:1151 emits `"copywriter_applied": $HAS_COPYWRITER` unquoted,
# so this is a real JSON boolean. False proves the :862 guard was entered rather
# than skipped, which is the precondition for the copywriter token being emitted.
check("project-status-02-copywriter-applied-false", artifacts.get("copywriter_applied"), False)

# Exact whole-token membership, never a substring or prefix test:
# "cogni-workspace:copywrite" is a strict PREFIX of the correct token, so any
# containment check would match both spellings and prove nothing.
check("project-status-03-next-actions-copywriter", "cogni-workspace:copywriter" in skills, True)

# The full set the `complete)` arm emits under this minimal fixture
# (project-status.sh:858-876). Every optional-artifact branch fires because every
# HAS_* flag sits at its false default; the trends-bridge arm at :873 does not,
# because it also requires a portfolio context below v3.1.
check(
    "project-status-04-next-actions-token-set",
    sorted(skills),
    [
        "cogni-trends:trend-booklet",
        "cogni-trends:trends-catalog",
        "cogni-trends:trends-dashboard",
        "cogni-workspace:copywriter",
        "cogni-workspace:enrich-report",
        "cogni-workspace:text-to-narrative",
    ],
)

if failures:
    print(f"\n{len(failures)} assertion(s) failed", file=sys.stderr)
    sys.exit(1)
print("\nAll complete-phase assertions passed.")
PYEOF

# Exit-code aggregation. This file runs under `set -u` with no `set -e` and no
# `pipefail`, so the exit status of the LAST statement is the script's own. With
# two assertion blocks, capturing each rc and exiting explicitly is what stops a
# green second block from swallowing a red first one — scripts/run-plugin-tests.py
# classifies purely on exit code and would report a false green otherwise.
# Nothing may sit between a pipeline and its `$?` capture.
printf '%s' "$OUTPUT" | python3 "$ASSERT_SCRIPT"
RC_ASSERT_MAIN=$?
printf '%s' "$OUTPUT_COMPLETE" | python3 "$ASSERT_COMPLETE"
RC_ASSERT_COMPLETE=$?

if [ "$RC_ASSERT_MAIN" -ne 0 ] || [ "$RC_ASSERT_COMPLETE" -ne 0 ]; then
  exit 1
fi
exit 0
