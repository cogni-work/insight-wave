#!/usr/bin/env bash
# check-skill-names.sh — Validate skill names across the insight-wave monorepo.
# Reports duplicate bare names and generic words without a domain prefix.
# Exit non-zero if violations found.
#
# Portable to bash 3.2 (the macOS system bash), so the documented pre-PR check
# runs on a default macOS toolchain, not just CI's bash 5. The name->plugin
# aggregation and both checks run in a single awk pass — awk's own associative
# arrays are POSIX-portable, so no `declare -A` (a bash 4+ feature) is needed.

set -euo pipefail

# REPO_ROOT is overridable so the regression harness can point the check at a
# temp fixture tree; it defaults to the repo root two levels up from this script.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
GENERIC_WORDS="setup scan ingest export dashboard verify bridge catalog reader config status analyze resume"

violations=0

# Collect one name<TAB>plugin pair per SKILL.md frontmatter. An empty name is a
# violation surfaced here (the awk pass below only sees named skills).
pairs_file="$(mktemp)"
trap 'rm -f "$pairs_file"' EXIT

while IFS= read -r skill_md; do
  name=$(grep -m1 '^name:' "$skill_md" | sed 's/^name:[[:space:]]*//')
  if [[ -z "$name" ]]; then
    echo "WARNING: No name field in $skill_md"
    violations=$((violations + 1))
    continue
  fi
  rel_path="${skill_md#"$REPO_ROOT/"}"
  plugin=$(echo "$rel_path" | cut -d/ -f1)
  printf '%s\t%s\n' "$name" "$plugin" >> "$pairs_file"
done < <(find "$REPO_ROOT"/cogni-*/skills/*/SKILL.md -type f 2>/dev/null)

# Single awk pass replaces the two `${!skill_map[@]}` loops the script used to
# need. It rebuilds the name->plugins mapping (appending every occurrence, so a
# name that appears twice — even within one plugin — still reads as a duplicate,
# matching the original behaviour), then emits duplicate-name and generic-name
# violations in a stable, name-sorted order. The trailing `__VIOLATIONS__ N`
# line carries the count back to the shell. The single-quote and em-dash are
# passed in as variables (q, dash) to keep the awk program free of escapes that
# vary across awk implementations.
awk_out=$(awk -F'\t' -v generic="$GENERIC_WORDS" -v q="'" -v dash="—" '
  BEGIN { split(generic, g, " ") }
  NF < 2 { next }
  {
    if ($1 in plugins) plugins[$1] = plugins[$1] ", " $2
    else { plugins[$1] = $2; names[++n] = $1 }
  }
  END {
    # sort names so output ordering is deterministic (bash hash-order was not)
    for (i = 1; i <= n; i++)
      for (j = i + 1; j <= n; j++)
        if (names[j] < names[i]) { t = names[i]; names[i] = names[j]; names[j] = t }
    v = 0
    for (i = 1; i <= n; i++) {
      nm = names[i]
      if (plugins[nm] ~ /, /) {
        print "ERROR: Duplicate skill name " q nm q " in: " plugins[nm]
        v++
      }
    }
    for (i = 1; i <= n; i++) {
      nm = names[i]
      for (k in g) {
        if (nm == g[k]) {
          print "ERROR: Generic skill name " q nm q " requires a domain prefix (e.g., portfolio-" nm ") " dash " in " plugins[nm]
          v++
        }
      }
    }
    print "__VIOLATIONS__ " v
  }
' "$pairs_file")

# Print the awk ERROR lines (everything but the sentinel) and fold its count in.
awk_violations=$(printf '%s\n' "$awk_out" | sed -n 's/^__VIOLATIONS__ //p')
printf '%s\n' "$awk_out" | grep -v '^__VIOLATIONS__' || true
violations=$((violations + ${awk_violations:-0}))

if [[ $violations -gt 0 ]]; then
  echo ""
  echo "FAIL: $violations naming violation(s) found."
  exit 1
else
  echo "OK: All skill names follow the naming convention."
  exit 0
fi
