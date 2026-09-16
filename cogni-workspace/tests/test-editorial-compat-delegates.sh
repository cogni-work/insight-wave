#!/usr/bin/env bash
# Workspace keeps routing compatibility, never a second editorial implementation.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS="${EDITORIAL_COMPAT_WS:-$(cd "$HERE/.." && pwd)}"
ROOT="$(cd "$WS/.." && pwd)"
INVENTORY="$ROOT/cogni-publishing/tests/fixtures/editorial-transfer-inventory.tsv"
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s - %s\n' "$1" "$2"; failures=$((failures + 1)); }

bad=""
for skill in text-to-narrative copywriter; do
  file="$WS/skills/$skill/SKILL.md"
  grep -qx '<!-- compatibility-delegate: cogni-publishing -->' "$file" || bad="$bad marker:$skill"
  grep -q "cogni-publishing:$skill" "$file" || bad="$bad target:$skill"
  grep -Eq 'Dispatch `(cogni-workspace:)?(text-to-narrative|copywriter)`' "$file" && bad="$bad recursive:$skill"
  grep -q 'unchanged' "$file" || bad="$bad unchanged:$skill"
  grep -qi 'not installed' "$file" || bad="$bad missing-plugin:$skill"
  body="$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$file")"
  printf '%s\n' "$body" | grep -Eq 'python3|readability\.sh|scripts/|evals/|references/' && bad="$bad implementation:$skill"
done
if [ -z "$bad" ]; then pass "ecd-01-delegate-shape"; else fail "ecd-01-delegate-shape" "$bad"; fi

bad=""
for command in text-to-narrative copywrite; do
  file="$WS/commands/$command.md"
  grep -q '^Invoke `cogni-publishing:' "$file" || bad="$bad target:$command"
  grep -Eq '^Invoke `(cogni-workspace:)?(text-to-narrative|copywriter)`' "$file" && bad="$bad recursive:$command"
  grep -q '\$ARGUMENTS.*unchanged' "$file" || bad="$bad arguments:$command"
  grep -qi 'unavailable' "$file" || bad="$bad missing-plugin:$command"
done
if [ -z "$bad" ]; then pass "ecd-02-command-routes"; else fail "ecd-02-command-routes" "$bad"; fi

bad=""; inventory_tmp="$(mktemp -d)"; expected="$inventory_tmp/expected"; actual="$inventory_tmp/actual"
trap 'rm -rf "$inventory_tmp"' EXIT
awk -F '\t' '$1 == "pointer" {print $2 "\t" $3}' "$INVENTORY" | sort > "$expected"
for file in "$WS"/skills/text-to-narrative/references/*.md "$WS"/libraries/*.md; do
  source=${file#$ROOT/}; target="$(sed -n 's/^Canonical publishing target: `\([^`]*\)`.*/\1/p' "$file")"
  printf '%s\t%s\n' "$source" "$target"
  [ "$(wc -l < "$file" | tr -d ' ')" -le 15 ] || bad="$bad long:$source"
  [ -n "$target" ] && [ -f "$ROOT/$target" ] || bad="$bad target:$source"
  grep -q '^Read that target' "$file" || bad="$bad instruction:$source"
  grep -q '|' "$file" && bad="$bad table:$source"
done > "$inventory_tmp/unsorted"
sort "$inventory_tmp/unsorted" > "$actual"
if cmp -s "$expected" "$actual" && [ "$(wc -l < "$expected" | tr -d ' ')" -eq 31 ] && [ -z "$bad" ]; then
  pass "ecd-03-pointers"
else
  fail "ecd-03-pointers" "exact 31-path inventory differs$bad"
  diff -u "$expected" "$actual" || true
fi

if find "$WS/skills/text-to-narrative" "$WS/skills/copywriter" -type f \
  ! -name SKILL.md ! -path '*/references/*.md' | grep -q .; then
  fail "ecd-04-no-implementation" "workspace scripts, evals or copywriter references survive"
else
  pass "ecd-04-no-implementation"
fi

# A pointer can retain its exact path and target while violating the read contract.
# Run this same checker on isolated copies so pipeline state loss is observable.
if [ "${EDITORIAL_COMPAT_MUTANT:-}" != 1 ]; then
  fixture_root="$inventory_tmp/repo"
  mkdir -p "$fixture_root/cogni-workspace/skills/text-to-narrative" "$fixture_root/cogni-publishing/tests/fixtures"
  cp -R "$WS/skills/text-to-narrative/references" "$fixture_root/cogni-workspace/skills/text-to-narrative/"
  cp -R "$WS/libraries" "$fixture_root/cogni-workspace/"
  cp -R "$WS/skills/copywriter" "$fixture_root/cogni-workspace/skills/"
  cp "$WS/skills/text-to-narrative/SKILL.md" "$fixture_root/cogni-workspace/skills/text-to-narrative/"
  cp -R "$WS/commands" "$fixture_root/cogni-workspace/"
  cp -R "$ROOT/cogni-publishing/references" "$fixture_root/cogni-publishing/"
  cp "$INVENTORY" "$fixture_root/cogni-publishing/tests/fixtures/"
  victim="$fixture_root/cogni-workspace/libraries/arc-taxonomy.md"
  cp "$victim" "$inventory_tmp/pointer-original"
  for mutation in instruction table length; do
    python3 - "$inventory_tmp/pointer-original" "$victim" "$mutation" <<'MUTATE'
from pathlib import Path
import sys
text=Path(sys.argv[1]).read_text()
if sys.argv[3] == 'instruction':
    text='\n'.join(line for line in text.splitlines() if not line.startswith('Read that target'))+'\n'
elif sys.argv[3] == 'table':
    text+='\n| Copied | Rules |\n'
else:
    text+='\n' * 16
Path(sys.argv[2]).write_text(text)
MUTATE
    result="$(EDITORIAL_COMPAT_WS="$fixture_root/cogni-workspace" EDITORIAL_COMPAT_MUTANT=1 bash "$HERE/$(basename "$0")" 2>&1)"
    rc=$?
    if [ "$rc" -ne 0 ] && printf '%s\n' "$result" | grep -q '^FAIL: ecd-03-pointers '; then
      pass "ecd-05-$mutation-red"
    else
      fail "ecd-05-$mutation-red" "invalid pointer did not fail ecd-03-pointers"
    fi
  done
fi

[ "$failures" -eq 0 ] || exit 1
