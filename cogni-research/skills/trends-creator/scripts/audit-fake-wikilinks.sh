#!/bin/bash
# Version: 1.0.0
# Purpose: Audit existing trends for fake claim wikilinks that reference non-existent files
# Exit codes: 0=no fake wikilinks found, 1=fake wikilinks detected or invalid project path
# Usage: ./audit-fake-wikilinks.sh [PROJECT_PATH]

PROJECT_PATH="${1:-.}"

if [ ! -d "${PROJECT_PATH}/11-trends/data" ]; then
  echo "Error: ${PROJECT_PATH}/11-trends/data directory not found"
  echo "Usage: $0 [PROJECT_PATH]"
  exit 1
fi

if [ ! -d "${PROJECT_PATH}/10-claims/data" ]; then
  echo "Error: ${PROJECT_PATH}/10-claims/data directory not found"
  exit 1
fi

echo "=== Auditing Trends for Fake Claim Wikilinks ==="
echo "Project: ${PROJECT_PATH}"
echo ""

total_trends=0
trends_with_fakes=0
total_claim_refs=0
fake_claim_refs=0

# Iterate through all trend files
for trend in "${PROJECT_PATH}"/11-trends/data/*.md; do
  [ -f "$trend" ] || continue

  total_trends=$((total_trends + 1))
  trend_name=$(basename "$trend")

  # Extract all claim wikilinks
  claim_ids=$(grep -oE '\[\[10-claims/data/claim-[^]|]+\|C[0-9]+\]\]' "$trend" | sed -E 's/\[\[10-claims\/data\/([^]|]+)\|.*/\1/' | sort -u)

  if [ -z "$claim_ids" ]; then
    continue
  fi

  # Check each claim ID for file existence
  trend_has_fakes=false
  for claim_id in $claim_ids; do
    total_claim_refs=$((total_claim_refs + 1))
    claim_file="${PROJECT_PATH}/10-claims/data/${claim_id}.md"

    if [ ! -f "$claim_file" ]; then
      if [ "$trend_has_fakes" = "false" ]; then
        echo "FAKE CLAIMS in ${trend_name}:"
        trend_has_fakes=true
        trends_with_fakes=$((trends_with_fakes + 1))
      fi
      echo "  ✗ ${claim_id} (file does not exist)"
      fake_claim_refs=$((fake_claim_refs + 1))
    fi
  done

  if [ "$trend_has_fakes" = "true" ]; then
    echo ""
  fi
done

echo "=== Audit Results ==="
echo "Total trends analyzed: ${total_trends}"
echo "Trends with fake claims: ${trends_with_fakes}"
echo "Total claim references: ${total_claim_refs}"
echo "Fake claim references: ${fake_claim_refs}"
echo ""

if [ ${fake_claim_refs} -gt 0 ]; then
  fabrication_rate=$(awk "BEGIN {printf \"%.1f\", (${fake_claim_refs}/${total_claim_refs})*100}")
  echo "Fabrication rate: ${fabrication_rate}% (${fake_claim_refs}/${total_claim_refs})"
  echo ""
  echo "⚠️  Fake claims detected - trends contain non-existent wikilinks"
  exit 1
else
  echo "✓ No fake claims detected - all wikilinks point to existing files"
  exit 0
fi
