#!/usr/bin/env bash
# Pins consult-native routing and the bounded optional publishing continuation.
#
# Mutation recipe (mutated red, restored green):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-consult/references/publish-routing.md \
#     --expr 's/Never re-narrate through `cogni-publishing:text-to-narrative`\./Skill: cogni-publishing:text-to-narrative./' \
#     --test 'bash cogni-consult/tests/test-publishing-routes.sh' \
#     --case publishing-routes-03-no-renarration-dispatch

set -u

SUITE_DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_DIR=$(cd "$SUITE_DIR/.." && pwd)
SKILL="$PLUGIN_DIR/skills/consult-publish/SKILL.md"
ROUTING="$PLUGIN_DIR/references/publish-routing.md"
MODEL="$PLUGIN_DIR/references/data-model.md"
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

dependencies_ok=true
for dependency in grep mktemp rm; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    fail publishing-routes-01-dependency-floor "missing required command: $dependency"
    dependencies_ok=false
  fi
done
if [ "$dependencies_ok" = true ]; then
  pass publishing-routes-01-dependency-floor
else
  printf 'publishing routes: %s failing case(s)\n' "$failures"
  exit 1
fi

require_pattern() {
  case_id=$1
  pattern=$2
  shift 2
  if grep -Eq -- "$pattern" "$@"; then pass "$case_id"; else fail "$case_id" "missing $pattern"; fi
}

validate_no_renarration_dispatch() {
  dispatch='Skill[[:space:]]*:[[:space:]]*cogni-(workspace|publishing):text-to-narrative|Skill[[:space:]]*\([[:space:]]*cogni-(workspace|publishing):text-to-narrative[[:space:]]*\)'
  ! grep -Eq -- "$dispatch" "$@"
}

validate_local_render_routes() {
  unsupported='cogni-publishing:design-render[^[:cntrl:]]*(report|infographic|document|print)|(report|infographic|document|print)[^[:cntrl:]]*cogni-publishing:design-render'
  grep -Eq -- 'pptx[^[:cntrl:]]*slides|slides[^[:cntrl:]]*pptx' "$@" || return 1
  grep -Eq -- 'html[^[:cntrl:]]*web-poster|web-poster[^[:cntrl:]]*html' "$@" || return 1
  ! grep -Eq -- "$unsupported" "$@"
}

require_pattern publishing-routes-02-native-direct 'direct-brief@1|artifact_type: "direct-brief"' "$SKILL" "$ROUTING"
if validate_no_renarration_dispatch "$SKILL" "$ROUTING"; then
  pass publishing-routes-03-no-renarration-dispatch
else
  fail publishing-routes-03-no-renarration-dispatch "found a Skill: or Skill(...) text-to-narrative dispatch"
fi
require_pattern publishing-routes-04-validate 'cogni-publishing:publishing-validate' "$SKILL" "$ROUTING"
require_pattern publishing-routes-05-compose 'cogni-publishing:design-compose' "$SKILL" "$ROUTING"
require_pattern publishing-routes-06-render 'cogni-publishing:design-render' "$SKILL" "$ROUTING"
if validate_local_render_routes "$SKILL" "$ROUTING"; then
  pass publishing-routes-07-supported-local-routes
else
  fail publishing-routes-07-supported-local-routes "local render routes are not limited to slides/PPTX and web-poster/HTML"
fi
require_pattern publishing-routes-08-unsupported-handoff 'report.*infographic.*unsupported|report and infographic.*Claude Design|report and infographic.*handoff' "$SKILL" "$ROUTING"
require_pattern publishing-routes-09-brief-provenance 'brief_path' "$SKILL" "$MODEL"
require_pattern publishing-routes-10-artifact-provenance 'artifact_path' "$SKILL" "$MODEL"
require_pattern publishing-routes-11-additive 'additive|optional' "$MODEL"

WORK_DIR=$(mktemp -d)
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

case_number=12
workspace_target='cogni-work''space:text-to-narrative'
publishing_target='cogni-publishing:text-to-narrative'
for dispatch in \
  "Skill: $workspace_target" \
  "Skill: $publishing_target" \
  "Skill($workspace_target)" \
  "Skill($publishing_target)"; do
  printf '%s\n' "$dispatch" > "$WORK_DIR/renarration.md"
  case_id=$(printf 'publishing-routes-%02d-renarration-falsifier' "$case_number")
  if validate_no_renarration_dispatch "$WORK_DIR/renarration.md"; then
    fail "$case_id" "$dispatch escaped the dispatch validator"
  else
    pass "$case_id"
  fi
  case_number=$((case_number + 1))
done

for format in report infographic document print; do
  fixture="$WORK_DIR/local-render-$format.md"
  printf 'Skill: cogni-publishing:design-render target %s\nslides to pptx\nweb-poster to html\n' "$format" > "$fixture"
  case_id=$(printf 'publishing-routes-%02d-no-local-%s' "$case_number" "$format")
  if validate_local_render_routes "$fixture"; then
    fail "$case_id" "planted $format local-render claim escaped the route validator"
  else
    pass "$case_id"
  fi
  case_number=$((case_number + 1))
done

if [ "$failures" -ne 0 ]; then
  printf 'publishing routes: %s failing case(s)\n' "$failures"
  exit 1
fi
printf 'publishing routes: all cases green\n'
