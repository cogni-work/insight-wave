#!/usr/bin/env bash
# check-skill-names.sh — Validate skill names across the cogni-works monorepo.
# Reports duplicate bare names and generic words without a domain prefix.
# Exit non-zero if violations found.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GENERIC_WORDS="setup scan ingest export dashboard verify bridge catalog reader config status analyze resume"

violations=0

# Collect all skill names from SKILL.md frontmatter
declare -A skill_map  # name -> plugin path(s)

while IFS= read -r skill_md; do
  name=$(grep -m1 '^name:' "$skill_md" | sed 's/^name:[[:space:]]*//')
  if [[ -z "$name" ]]; then
    echo "WARNING: No name field in $skill_md"
    violations=$((violations + 1))
    continue
  fi
  rel_path="${skill_md#"$REPO_ROOT/"}"
  plugin=$(echo "$rel_path" | cut -d/ -f1)
  if [[ -n "${skill_map[$name]+_}" ]]; then
    skill_map[$name]="${skill_map[$name]}, $plugin"
  else
    skill_map[$name]="$plugin"
  fi
done < <(find "$REPO_ROOT"/cogni-*/skills/*/SKILL.md -type f 2>/dev/null)

# Check for duplicate names across plugins
for name in "${!skill_map[@]}"; do
  plugins="${skill_map[$name]}"
  if [[ "$plugins" == *","* ]]; then
    echo "ERROR: Duplicate skill name '$name' in: $plugins"
    violations=$((violations + 1))
  fi
done

# Check for generic words without a domain prefix
for name in "${!skill_map[@]}"; do
  for word in $GENERIC_WORDS; do
    if [[ "$name" == "$word" ]]; then
      echo "ERROR: Generic skill name '$name' requires a domain prefix (e.g., portfolio-$word) — in ${skill_map[$name]}"
      violations=$((violations + 1))
    fi
  done
done

if [[ $violations -gt 0 ]]; then
  echo ""
  echo "FAIL: $violations naming violation(s) found."
  exit 1
else
  echo "OK: All skill names follow the naming convention."
  exit 0
fi
