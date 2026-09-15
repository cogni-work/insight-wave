#!/usr/bin/env bash
# Workspace keeps routing compatibility, never a second editorial implementation.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS="$(cd "$HERE/.." && pwd)"
ROOT="$(cd "$WS/.." && pwd)"
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

bad=""
for skill in text-to-narrative copywriter; do
  file="$WS/skills/$skill/SKILL.md"
  grep -qx '<!-- compatibility-delegate: cogni-publishing -->' "$file" || bad="$bad marker:$skill"
  grep -q "cogni-publishing:$skill" "$file" || bad="$bad target:$skill"
  grep -q 'unchanged' "$file" || bad="$bad unchanged:$skill"
  grep -qi 'not installed' "$file" || bad="$bad missing-plugin:$skill"
  body="$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$file")"
  printf '%s\n' "$body" | grep -Eq 'python3|readability\.sh|scripts/|evals/|references/' && bad="$bad implementation:$skill"
done
if [ -z "$bad" ]; then pass "ecd-01-delegate-shape"; else fail "ecd-01-delegate-shape" "$bad"; fi

bad=""
for command in text-to-narrative copywrite; do
  file="$WS/commands/$command.md"
  grep -q 'cogni-publishing:' "$file" || bad="$bad target:$command"
  grep -q '\$ARGUMENTS.*unchanged' "$file" || bad="$bad arguments:$command"
  grep -qi 'unavailable' "$file" || bad="$bad missing-plugin:$command"
done
if [ -z "$bad" ]; then pass "ecd-02-command-routes"; else fail "ecd-02-command-routes" "$bad"; fi

bad=""
count=0
for file in "$WS"/skills/text-to-narrative/references/*.md "$WS"/libraries/*.md; do
  count=$((count + 1))
  [ "$(wc -l < "$file" | tr -d ' ')" -le 15 ] || bad="$bad long:${file#$ROOT/}"
  target="$(sed -n 's/^Canonical publishing target: `\([^\`]*\)`.*/\1/p' "$file")"
  [ -n "$target" ] && [ -f "$ROOT/$target" ] || bad="$bad target:${file#$ROOT/}"
  grep -q '^Read that target' "$file" || bad="$bad instruction:${file#$ROOT/}"
  grep -q '|' "$file" && bad="$bad table:${file#$ROOT/}"
done
if [ "$count" -eq 31 ] && [ -z "$bad" ]; then pass "ecd-03-pointers"; else fail "ecd-03-pointers" "count=$count$bad"; fi

if find "$WS/skills/text-to-narrative" "$WS/skills/copywriter" -type f \
  ! -name SKILL.md ! -path '*/references/*.md' | grep -q .; then
  fail "ecd-04-no-implementation" "workspace scripts, evals or copywriter references survive"
else
  pass "ecd-04-no-implementation"
fi

[ "$failures" -eq 0 ] || exit 1
