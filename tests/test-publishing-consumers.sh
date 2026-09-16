#!/usr/bin/env bash
# Repository guard for publishing consumer ownership and public arc contracts.
#
# Mutation recipe (mutated red, restored green):
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-consult/skills/consult-design-thinking/SKILL.md \
#     --expr 's/cogni-publishing:copywriter/cogni-workspace:copywriter/' \
#     --test 'bash tests/test-publishing-consumers.sh' \
#     --case publishing-consumers-03-no-workspace-dispatch

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

dependencies_ok=true
for dependency in find grep sed cp mkdir mktemp mv rm; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    fail publishing-consumers-01-dependency-floor "missing required command: $dependency"
    dependencies_ok=false
  fi
done
if [ "$dependencies_ok" = true ]; then
  pass publishing-consumers-01-dependency-floor
else
  printf 'publishing consumers: %s failing case(s)\n' "$failures"
  exit 1
fi

discover_files() {
  find "$@" -type f ! -name CHANGELOG.md ! -path '*/tests/*' -print
}

count_discovered() {
  count=0
  while IFS= read -r _path; do
    count=$((count + 1))
  done < <(discover_files "$@")
  printf '%s\n' "$count"
}

scan_forbidden() {
  pattern=$1
  shift
  found=1
  while IFS= read -r file; do
    if grep -EnH -- "$pattern" "$file"; then
      found=0
    fi
  done < <(discover_files "$@")
  return "$found"
}

consumer_count=$(count_discovered "${SURFACES[@]}")
if [ "$consumer_count" -gt 0 ]; then
  pass publishing-consumers-02-discovery-floor
else
  fail publishing-consumers-02-discovery-floor "no consumer files discovered"
fi

workspace_dispatch='cogni-workspace:(copywriter|text-to-narrative|manage-themes)'
if hits=$(scan_forbidden "$workspace_dispatch" "${SURFACES[@]}"); then
  fail publishing-consumers-03-no-workspace-dispatch "$hits"
else
  pass publishing-consumers-03-no-workspace-dispatch
fi

private_editorial='cogni-workspace/skills/(copywriter|text-to-narrative)/references/'
if hits=$(scan_forbidden "$private_editorial" "${SURFACES[@]}"); then
  fail publishing-consumers-04-no-private-editorial-path "$hits"
else
  pass publishing-consumers-04-no-private-editorial-path
fi

private_theme='cogni-workspace/(skills/manage-themes|libraries/(arc-taxonomy|presentation-intent|web-section|infographic))'
if hits=$(scan_forbidden "$private_theme" "${SURFACES[@]}"); then
  fail publishing-consumers-05-no-private-theme-path "$hits"
else
  pass publishing-consumers-05-no-private-theme-path
fi

WORK_DIR=$(mktemp -d)
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

mkdir "$WORK_DIR/empty" "$WORK_DIR/planted"
if [ "$(count_discovered "$WORK_DIR/empty")" -eq 0 ]; then
  pass publishing-consumers-06-zero-discovery-falsifier
else
  fail publishing-consumers-06-zero-discovery-falsifier "empty fixture reported discovered files"
fi

printf '%s\n' \
  'Skill: cogni-workspace:copywriter' \
  'Read cogni-workspace/skills/text-to-narrative/references/story-arcs.md' \
  > "$WORK_DIR/planted/consumer.md"
if scan_forbidden "$workspace_dispatch" "$WORK_DIR/planted" >/dev/null; then
  pass publishing-consumers-07-workspace-dispatch-falsifier
else
  fail publishing-consumers-07-workspace-dispatch-falsifier "planted workspace dispatch escaped the production scanner"
fi
if scan_forbidden "$private_editorial" "$WORK_DIR/planted" >/dev/null; then
  pass publishing-consumers-08-private-path-falsifier
else
  fail publishing-consumers-08-private-path-falsifier "planted private path escaped the production scanner"
fi

ARC_IDS=(
  jtbd-portfolio
  company-credo
  corporate-visions
  engagement-model
  competitive-intelligence
  industry-transformation
  smarter-service
)

validate_arc() {
  root=$1
  arc=$2
  file="$root/arc-$arc.md"
  [ -f "$file" ] || { printf 'missing %s\n' "$file"; return 1; }
  for heading in Headings Composition Elements Validation; do
    grep -q "^## $heading$" "$file" || {
      printf 'arc-%s.md lacks ## %s\n' "$arc" "$heading"
      return 1
    }
  done
  if [ "$arc" = corporate-visions ]; then
    for subsection in '1. Why Change' '2. Why Now' '3. Why You' '4. Why Pay'; do
      grep -q "^### $subsection$" "$file" || {
        printf 'arc-corporate-visions.md lacks ### %s\n' "$subsection"
        return 1
      }
    done
  fi
}

validate_techniques() {
  root=$1
  file="$root/techniques-overview.md"
  [ -f "$file" ] || { printf 'missing %s\n' "$file"; return 1; }
  grep -q '^## Core Techniques$' "$file" || return 1
  grep -q '^## Application by Arc Element$' "$file" || return 1
}

validate_public_contracts() {
  root=$1
  for arc in "${ARC_IDS[@]}"; do
    validate_arc "$root" "$arc" || return 1
  done
  validate_techniques "$root"
}

case_number=9
for arc in "${ARC_IDS[@]}"; do
  case_id=$(printf 'publishing-consumers-%02d-arc-%s' "$case_number" "$arc")
  if detail=$(validate_arc "$REPO_ROOT/cogni-publishing/references" "$arc"); then
    pass "$case_id"
  else
    fail "$case_id" "$detail"
  fi
  case_number=$((case_number + 1))
done

if detail=$(validate_techniques "$REPO_ROOT/cogni-publishing/references"); then
  pass publishing-consumers-16-techniques-overview
else
  fail publishing-consumers-16-techniques-overview "${detail:-required headings missing}"
fi

ARC_FIXTURE="$WORK_DIR/arcs"
mkdir "$ARC_FIXTURE"
for arc in "${ARC_IDS[@]}"; do
  cp "$REPO_ROOT/cogni-publishing/references/arc-$arc.md" "$ARC_FIXTURE/arc-$arc.md"
done
cp "$REPO_ROOT/cogni-publishing/references/techniques-overview.md" "$ARC_FIXTURE/techniques-overview.md"

mv "$ARC_FIXTURE/arc-smarter-service.md" "$WORK_DIR/arc-smarter-service.removed"
if validate_public_contracts "$ARC_FIXTURE" >/dev/null; then
  fail publishing-consumers-17-removed-file-falsifier "removed arc escaped the shared validator"
else
  pass publishing-consumers-17-removed-file-falsifier
fi
mv "$WORK_DIR/arc-smarter-service.removed" "$ARC_FIXTURE/arc-smarter-service.md"

sed 's/^## Headings$/## Renamed/' "$ARC_FIXTURE/arc-corporate-visions.md" > "$WORK_DIR/arc-mutated.md"
mv "$WORK_DIR/arc-mutated.md" "$ARC_FIXTURE/arc-corporate-visions.md"
if validate_public_contracts "$ARC_FIXTURE" >/dev/null; then
  fail publishing-consumers-18-renamed-heading-falsifier "renamed heading escaped the shared validator"
else
  pass publishing-consumers-18-renamed-heading-falsifier
fi

if [ "$failures" -ne 0 ]; then
  printf 'publishing consumers: %s failing case(s)\n' "$failures"
  exit 1
fi
printf 'publishing consumers: all cases green\n'
