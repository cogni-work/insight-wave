#!/usr/bin/env bash
# Repository guard for publishing consumer ownership and public arc contracts.
#
# Mutation recipe (mutated red, restored green):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-consult/skills/consult-design-thinking/SKILL.md \
#     --expr 's/cogni-publishing:copywriter/cogni-workspace:copywriter/' \
#     --test 'bash tests/test-publishing-consumers.sh' \
#     --case publishing-consumers-01-no-workspace-dispatch

set -u

SUITE_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SUITE_DIR/.." && pwd)
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

SURFACES=(
  "$REPO_ROOT/cogni-consult"
  "$REPO_ROOT/cogni-knowledge"
  "$REPO_ROOT/cogni-marketing"
  "$REPO_ROOT/cogni-portfolio"
  "$REPO_ROOT/cogni-sales"
  "$REPO_ROOT/cogni-trends"
  "$REPO_ROOT/cogni-website"
  "$REPO_ROOT/cogni-workspace/skills/workspace-dashboard"
)

scan_forbidden() {
  pattern=$1
  rg -n --glob '!CHANGELOG.md' --glob '!**/tests/**' --glob '!tests/test-publishing-consumers.sh' \
    "$pattern" "${SURFACES[@]}" 2>/dev/null
}

workspace_dispatch='cogni-workspace:(copywriter|text-to-narrative|manage-themes)'
if hits=$(scan_forbidden "$workspace_dispatch"); then
  fail publishing-consumers-01-no-workspace-dispatch "$hits"
else
  pass publishing-consumers-01-no-workspace-dispatch
fi

private_editorial='cogni-workspace/skills/(copywriter|text-to-narrative)/references/'
if hits=$(scan_forbidden "$private_editorial"); then
  fail publishing-consumers-02-no-private-editorial-path "$hits"
else
  pass publishing-consumers-02-no-private-editorial-path
fi

private_theme='cogni-workspace/(skills/manage-themes|libraries/(arc-taxonomy|presentation-intent|web-section|infographic))'
if hits=$(scan_forbidden "$private_theme"); then
  fail publishing-consumers-03-no-private-theme-path "$hits"
else
  pass publishing-consumers-03-no-private-theme-path
fi

check_arc() {
  case_id=$1
  arc=$2
  file="$REPO_ROOT/cogni-publishing/references/arc-$arc.md"
  if [ ! -f "$file" ]; then
    fail "$case_id" "missing public arc contract $file"
    return
  fi
  for heading in Intent Selection Headings Composition Validation; do
    if ! grep -q "^## $heading$" "$file"; then
      fail "$case_id" "arc-$arc.md lacks ## $heading"
      return
    fi
  done
  pass "$case_id"
}

check_arc publishing-consumers-04-corporate-visions corporate-visions
check_arc publishing-consumers-05-jtbd-portfolio jtbd-portfolio
check_arc publishing-consumers-06-smarter-service smarter-service

WORK_DIR=$(mktemp -d)
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT
cp "$REPO_ROOT/cogni-publishing/references/arc-corporate-visions.md" "$WORK_DIR/arc-corporate-visions.md"
sed 's/^## Headings$/## Renamed/' "$WORK_DIR/arc-corporate-visions.md" > "$WORK_DIR/mutated.md"
if grep -q '^## Headings$' "$WORK_DIR/mutated.md"; then
  fail publishing-consumers-07-heading-falsifier "renamed heading escaped detection"
else
  pass publishing-consumers-07-heading-falsifier
fi

if [ "$failures" -ne 0 ]; then
  printf 'publishing consumers: %s failing case(s)\n' "$failures"
  exit 1
fi
printf 'publishing consumers: all cases green\n'
