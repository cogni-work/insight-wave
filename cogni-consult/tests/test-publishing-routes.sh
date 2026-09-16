#!/usr/bin/env bash
# Pins consult-native routing and the bounded optional publishing continuation.

set -u

SUITE_DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_DIR=$(cd "$SUITE_DIR/.." && pwd)
SKILL="$PLUGIN_DIR/skills/consult-publish/SKILL.md"
ROUTING="$PLUGIN_DIR/references/publish-routing.md"
MODEL="$PLUGIN_DIR/references/data-model.md"
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

require_pattern() {
  case_id=$1
  pattern=$2
  shift 2
  if rg -q "$pattern" "$@"; then pass "$case_id"; else fail "$case_id" "missing $pattern"; fi
}
reject_pattern() {
  case_id=$1
  pattern=$2
  shift 2
  if rg -q "$pattern" "$@"; then fail "$case_id" "forbidden $pattern"; else pass "$case_id"; fi
}

require_pattern publishing-routes-01-native-direct 'direct-brief@1|artifact_type: "direct-brief"' "$SKILL" "$ROUTING"
reject_pattern publishing-routes-02-no-renarration 'Skill: cogni-publishing:text-to-narrative' "$SKILL" "$ROUTING"
require_pattern publishing-routes-03-validate 'cogni-publishing:publishing-validate' "$SKILL" "$ROUTING"
require_pattern publishing-routes-04-compose 'cogni-publishing:design-compose' "$SKILL" "$ROUTING"
require_pattern publishing-routes-05-render 'cogni-publishing:design-render' "$SKILL" "$ROUTING"
require_pattern publishing-routes-06-slides-pptx 'pptx.*slides|slides.*pptx' "$SKILL" "$ROUTING"
require_pattern publishing-routes-07-poster-html 'html.*web-poster|web-poster.*html' "$SKILL" "$ROUTING"
require_pattern publishing-routes-08-unsupported-handoff 'report.*infographic.*unsupported|report and infographic.*Claude Design|report and infographic.*handoff' "$SKILL" "$ROUTING"
require_pattern publishing-routes-09-brief-provenance 'brief_path' "$SKILL" "$MODEL"
require_pattern publishing-routes-10-artifact-provenance 'artifact_path' "$SKILL" "$MODEL"
require_pattern publishing-routes-11-additive 'additive|optional' "$MODEL"

if [ "$failures" -ne 0 ]; then
  printf 'publishing routes: %s failing case(s)\n' "$failures"
  exit 1
fi
printf 'publishing routes: all cases green\n'
