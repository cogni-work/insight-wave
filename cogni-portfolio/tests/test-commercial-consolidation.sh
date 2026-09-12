#!/usr/bin/env bash
# Acceptance suite for issue #1230 — commercial-model consolidation gate.
#
# A shared/fixed revenue model (product.revenue_model in
# {subscription, hybrid, partnership}) must make the solutions layer recommend
# CONSOLIDATION (a shared reference cut / a package ladder) instead of fanning
# out one tiered solution per proposition; a `project` revenue model keeps the
# existing 1:1 behavior. project-status.sh emits `commercial_model_shared` per
# product x market and drives the recommendation via next_actions.
#
# Named acceptance tests:
#   test_hybrid_consolidates                   hybrid + 3 propositions -> consolidation, no 1:1 action
#   test_project_still_one_to_one              project + 3 propositions -> standard 1:1 action (regression)
#   test_status_emits_shared_flag              commercial_model_shared=true per product x market
#   test_recommendation_names_shared_solution  recommendation names shared_solution / Paketleiter / packages
#   test_no_stale_one_to_one_wording           stale 1:1 wording absent from the three surfaces
#   test_catalog_consolidates                  fixed/catalog commercial_model -> consolidation (rm=project)
#   test_models_ratio_consolidates             one distinct proposition commercial_model across >=3 props -> consolidation
#   test_off_enum_disposition_shared           off-enum revenue_model (product_and_license) -> documented shared disposition
#   test_project_models_ratio_stays_one_to_one unanimous `project` across 3 propositions -> NOT shared (ratio negative)
#   test_off_enum_project_fee_stays_one_to_one off-enum `project-fee` -> NOT shared (disposition negative)
#   test_partial_models_ratio_stays_one_to_one mixed models, and below the >=3 threshold -> NOT shared (ratio negatives)
#
# Usage: bash cogni-portfolio/tests/test-commercial-consolidation.sh [test_name ...]
#   No args -> run every test (the CI path). One or more names -> run only those
#   (used by scripts/mutation-check.sh to run a single assertion against a mutant).
# Honors PROJECT_STATUS_SCRIPT to point at an alternate project-status.sh.
# Exits non-zero on any assertion failure.
#
# Mutation recipe — the SHARED cogni-service harness, which classifies on the output
#   labels below (the plugin-local scripts/mutation-check.sh named above covers this
#   same mutation by exit status instead, and takes no flags). Replayable as written,
#   from the repo root:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/project-status.sh \
#     --expr 's/shared = rm in SHARED_MODELS/shared = False/' \
#     --test 'bash cogni-portfolio/tests/test-commercial-consolidation.sh test_hybrid_consolidates' \
#     --case test_hybrid_consolidates
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the per-test failure counter below.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="${PROJECT_STATUS_SCRIPT:-$PLUGIN_DIR/scripts/project-status.sh}"
SOLUTIONS_SKILL="$PLUGIN_DIR/skills/solutions/SKILL.md"
RESUME_SKILL="$PLUGIN_DIR/skills/portfolio-resume/SKILL.md"

# The exact stale-1:1 literal the AC forbids from surfacing on any of the three surfaces.
STALE_LITERAL='N Propositions -> N Solutions (solution-planner je Proposition)'
# The real pre-change Step-8 fan-out wording (gives the assertion actual teeth).
STALE_STEP8='launch `solution-planner` agents in parallel for each proposition'
# The standard 1:1 next_action reason a non-shared project keeps.
ONE_TO_ONE_ACTION='proposition(s) lack solution plans'

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: project-status.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one `<case>: <msg>` string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

# Seed a minimal enrichment-phase project: 1 product (revenue_model=$2), 3 features,
# 1 market, 1 customer, 3 propositions (all pairs covered -> MISSING_COUNT=0), and 0
# solutions (SOLUTIONS_PCT<100) so PHASE=enrichment and the solutions next_action fires.
# Optional $3 sets the product's commercial_model; optional $4 sets the
# propositions' commercial_model (both omitted -> the field is absent, matching a
# pre-#1232 project). $4 is either a single value applied to every proposition,
# or a comma-separated per-proposition list in a,b,c order whose empty entries
# leave that proposition's commercial_model absent — which is what lets a test
# seed a mixed-value or below-threshold set, not just a unanimous one.
seed_project() {
  local name="$1" rm="$2" pcm="${3:-}" prop_cm="${4:-}"
  local d="$TMPROOT/$name"
  local pcm_field=""
  [ -n "$pcm" ] && pcm_field="\"commercial_model\": \"$pcm\", "
  mkdir -p "$d/products" "$d/features" "$d/markets" "$d/customers" "$d/propositions" "$d/solutions"
  printf '{"company": {"name": "Acme", "products": ["acme"]}, "taxonomy": {}}\n' > "$d/portfolio.json"
  cat > "$d/products/acme.json" <<EOF
{"slug": "acme", "name": "Acme", "description": "Acme product suite for tests.", "revenue_model": "$rm", ${pcm_field}"shared_solution": true}
EOF
  local f
  for f in a b c; do
    cat > "$d/features/feat-$f.json" <<EOF
{"slug": "feat-$f", "name": "Feat $f", "description": "Feature $f for testing the commercial consolidation gate end to end here now.", "product_slug": "acme"}
EOF
  done
  cat > "$d/markets/dach.json" <<EOF
{"slug": "dach", "name": "DACH", "description": "DACH region for testing the commercial consolidation gate end to end here now.", "region": "dach"}
EOF
  cat > "$d/customers/kunde.json" <<EOF
{"slug": "kunde", "name": "Kunde", "description": "A customer profile for DACH satisfying the customers phase gate here now.", "market_slug": "dach"}
EOF
  local idx=1
  for f in a b c; do
    # `cut` echoes the whole line when the string carries no delimiter, so a
    # single value replicates across all three propositions for free and the
    # existing callers keep their meaning.
    local this_cm prop_cm_field=""
    this_cm="$(printf '%s' "$prop_cm" | cut -d',' -f"$idx")"
    [ -n "$this_cm" ] && prop_cm_field="\"commercial_model\": \"$this_cm\", "
    cat > "$d/propositions/feat-$f--dach.json" <<EOF
{"slug": "feat-$f--dach", "feature_slug": "feat-$f", "market_slug": "dach", ${prop_cm_field}"is_statement": "Feat $f is a tool that helps DACH buyers daily reliably here now today.", "does_statement": "It automates what DACH buyers need for productivity and steady measurable growth here now.", "means_statement": "DACH buyers save time and money adopting Feat $f for productivity and growth here now."}
EOF
    idx=$((idx + 1))
  done
  echo "$d"
}

# Run project-status.sh once; stash STATUS_OUT + RC in globals.
run_status() { STATUS_OUT="$(bash "$SCRIPT" "$1" 2>/dev/null)"; RC=$?; }

# Print the solutions next_action reason (empty if none).
solutions_reason() {
  printf '%s' "$STATUS_OUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for a in d.get('next_actions', []):
    if a.get('skill') == 'solutions':
        print(a.get('reason', '')); break
"
}

# Print the commercial_model_status.any_shared value (True/False/None).
any_shared_value() {
  printf '%s' "$STATUS_OUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('commercial_model_status', {}).get('any_shared'))"
}

# Assert a seeded project is NOT shared: no consolidation recommendation and the
# standard 1:1 action kept. $1 test name, $2 project dir, $3 case label.
# Every signal needs a negative case as well as a positive one — asserting only
# the positive direction is how an over-broad predicate passes a green run.
assert_one_to_one() {
  local tname="$1" d="$2" label="$3"
  run_status "$d"
  [ "$RC" = "0" ] || { fail "$tname" "$label: status rc=$RC"; return 1; }
  local reason; reason="$(solutions_reason)"
  local any_shared; any_shared="$(any_shared_value)"
  if [ "$any_shared" = "False" ] \
     && printf '%s' "$reason" | grep -qF "$ONE_TO_ONE_ACTION" \
     && ! printf '%s' "$reason" | grep -qiE 'shared_solution|Paketleiter|packages'; then
    return 0
  fi
  fail "$tname" "$label: any_shared=$any_shared reason='$reason'"
  return 1
}

test_hybrid_consolidates() {
  local d; d="$(seed_project hybrid-consolidates hybrid)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_hybrid_consolidates "status rc=$RC"; return; }
  local reason; reason="$(solutions_reason)"
  local any_shared; any_shared="$(any_shared_value)"
  # Shared model detected + exactly one consolidation recommendation, and NOT the
  # standard per-proposition tiering action (stands in for "0 solution-planner runs").
  if [ "$any_shared" = "True" ] \
     && printf '%s' "$reason" | grep -qiE 'shared_solution|Paketleiter|packages' \
     && ! printf '%s' "$reason" | grep -qF "$ONE_TO_ONE_ACTION"; then
    pass test_hybrid_consolidates "consolidation recommended, no per-proposition tiering"
  else
    fail test_hybrid_consolidates "any_shared=$any_shared reason='$reason'"
  fi
}

test_project_still_one_to_one() {
  # Regression guard: a project revenue model keeps the standard 1:1 action and
  # triggers no consolidation recommendation.
  local d; d="$(seed_project project-1to1 project)"
  assert_one_to_one test_project_still_one_to_one "$d" "project revenue_model" \
    && pass test_project_still_one_to_one "standard per-proposition action kept"
}

test_status_emits_shared_flag() {
  local d; d="$(seed_project status-flag hybrid)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_status_emits_shared_flag "status rc=$RC"; return; }
  local ok; ok="$(printf '%s' "$STATUS_OUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
mx = d.get('commercial_model_status', {}).get('matrix')
ok = bool(mx) \
    and all(e.get('commercial_model_shared') is True for e in mx) \
    and all(('product' in e and 'market' in e) for e in mx)
print('yes' if ok else 'no')
")"
  if [ "$ok" = "yes" ]; then
    pass test_status_emits_shared_flag "commercial_model_shared=true per product x market"
  else
    fail test_status_emits_shared_flag "matrix missing or a pair not shared"
  fi
}

test_recommendation_names_shared_solution() {
  local d; d="$(seed_project rec-names hybrid)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_recommendation_names_shared_solution "status rc=$RC"; return; }
  local reason; reason="$(solutions_reason)"
  if printf '%s' "$reason" | grep -qiE 'shared_solution|Paketleiter|packages'; then
    pass test_recommendation_names_shared_solution "names the shared path"
  else
    fail test_recommendation_names_shared_solution "reason='$reason'"
  fi
}

test_no_stale_one_to_one_wording() {
  local d; d="$(seed_project no-stale hybrid)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_no_stale_one_to_one_wording "status rc=$RC"; return; }
  local bad=0
  # 1) The AC literal must appear on none of the three surfaces (next_actions/status
  #    output, the solutions Step-5 bootstrap, the portfolio-resume rendering).
  if printf '%s' "$STATUS_OUT"        | grep -qF "$STALE_LITERAL"; then bad=1; fi
  if grep -qF "$STALE_LITERAL" "$SOLUTIONS_SKILL"; then bad=1; fi
  if grep -qF "$STALE_LITERAL" "$RESUME_SKILL"; then bad=1; fi
  # 2) Real teeth: the pre-change Step-8 fan-out phrasing must be gone from the skill,
  #    and the standard 1:1 status action must be suppressed for the shared fixture.
  if grep -qF "$STALE_STEP8" "$SOLUTIONS_SKILL"; then bad=1; fi
  if printf '%s' "$STATUS_OUT" | grep -qF "$ONE_TO_ONE_ACTION"; then bad=1; fi
  if [ "$bad" = "0" ]; then
    pass test_no_stale_one_to_one_wording "stale 1:1 wording absent from all surfaces"
  else
    fail test_no_stale_one_to_one_wording "stale 1:1 wording still present"
  fi
}

test_catalog_consolidates() {
  # A fixed/catalog commercial_model shares structure even when revenue_model is
  # `project` (not-shared under the revenue_model signal alone).
  local d; d="$(seed_project catalog-consolidates project catalog)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_catalog_consolidates "status rc=$RC"; return; }
  local reason; reason="$(solutions_reason)"
  local any_shared; any_shared="$(any_shared_value)"
  if [ "$any_shared" = "True" ] \
     && printf '%s' "$reason" | grep -qiE 'shared_solution|Paketleiter|packages' \
     && ! printf '%s' "$reason" | grep -qF "$ONE_TO_ONE_ACTION"; then
    pass test_catalog_consolidates "catalog commercial_model drives consolidation"
  else
    fail test_catalog_consolidates "any_shared=$any_shared reason='$reason'"
  fi
}

test_models_ratio_consolidates() {
  # revenue_model=project, no product commercial_model, but all 3 propositions
  # declare the same commercial_model -> the propositions:distinct-models ratio
  # collapses to one -> shared.
  local d; d="$(seed_project models-ratio project "" subscription)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_models_ratio_consolidates "status rc=$RC"; return; }
  local reason; reason="$(solutions_reason)"
  local any_shared; any_shared="$(any_shared_value)"
  if [ "$any_shared" = "True" ] \
     && printf '%s' "$reason" | grep -qiE 'shared_solution|Paketleiter|packages' \
     && ! printf '%s' "$reason" | grep -qF "$ONE_TO_ONE_ACTION"; then
    pass test_models_ratio_consolidates "single distinct proposition commercial_model drives consolidation"
  else
    fail test_models_ratio_consolidates "any_shared=$any_shared reason='$reason'"
  fi
}

test_off_enum_disposition_shared() {
  # An off-enum revenue_model with a documented shared disposition
  # (product_and_license) is shared, not silently not-shared.
  local d; d="$(seed_project off-enum product_and_license)"
  run_status "$d"
  [ "$RC" = "0" ] || { fail test_off_enum_disposition_shared "status rc=$RC"; return; }
  local reason; reason="$(solutions_reason)"
  local any_shared; any_shared="$(any_shared_value)"
  if [ "$any_shared" = "True" ] \
     && printf '%s' "$reason" | grep -qiE 'shared_solution|Paketleiter|packages' \
     && ! printf '%s' "$reason" | grep -qF "$ONE_TO_ONE_ACTION"; then
    pass test_off_enum_disposition_shared "off-enum revenue_model maps to shared disposition"
  else
    fail test_off_enum_disposition_shared "any_shared=$any_shared reason='$reason'"
  fi
}

test_project_models_ratio_stays_one_to_one() {
  # The negative twin of test_models_ratio_consolidates. Three propositions can
  # agree unanimously on `project` — that is agreeing to stay bespoke, so the
  # ratio must NOT fire. Without the shared-set membership test, the ratio
  # signal disagrees with the catalog signal about `project` and silently
  # reverses the project-stays-1:1 guarantee this gate exists to hold.
  local d; d="$(seed_project project-ratio-1to1 project "" "project,project,project")"
  assert_one_to_one test_project_models_ratio_stays_one_to_one "$d" "unanimous project" \
    && pass test_project_models_ratio_stays_one_to_one "unanimous bespoke model stays 1:1"
}

test_off_enum_project_fee_stays_one_to_one() {
  # The negative twin of test_off_enum_disposition_shared. `project-fee` is
  # off-enum but carries the documented NOT-shared disposition, so signal 3 must
  # not treat "off-enum" as a synonym for "shared".
  local d; d="$(seed_project off-enum-1to1 project-fee)"
  assert_one_to_one test_off_enum_project_fee_stays_one_to_one "$d" "project-fee" \
    && pass test_off_enum_project_fee_stays_one_to_one "undocumented off-enum value stays 1:1"
}

test_partial_models_ratio_stays_one_to_one() {
  # Two ways the ratio must decline even on shared-set values: propositions that
  # disagree (3 distinct models), and a set below the >=3 declared threshold
  # (one declares, two are silent). Both keep the standard 1:1 action.
  local mixed; mixed="$(seed_project mixed-ratio-1to1 project "" "subscription,usage,catalog")"
  local sparse; sparse="$(seed_project sparse-ratio-1to1 project "" "subscription,,")"
  assert_one_to_one test_partial_models_ratio_stays_one_to_one "$mixed" "3 distinct models" || return
  assert_one_to_one test_partial_models_ratio_stays_one_to_one "$sparse" "1 declared, below threshold" || return
  pass test_partial_models_ratio_stays_one_to_one "mixed and below-threshold sets stay 1:1"
}

ALL_TESTS="test_hybrid_consolidates test_project_still_one_to_one test_status_emits_shared_flag test_recommendation_names_shared_solution test_no_stale_one_to_one_wording test_catalog_consolidates test_models_ratio_consolidates test_off_enum_disposition_shared test_project_models_ratio_stays_one_to_one test_off_enum_project_fee_stays_one_to_one test_partial_models_ratio_stays_one_to_one"

if [ "$#" -gt 0 ]; then
  for t in "$@"; do "$t"; done
else
  for t in $ALL_TESTS; do "$t"; done
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
