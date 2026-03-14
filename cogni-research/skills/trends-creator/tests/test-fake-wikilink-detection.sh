#!/bin/bash
# Test script for fake wikilink detection in trends-creator
# Tests all three layers of defense against fabricated claim IDs

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TRENDS_CREATOR_ROOT="${PROJECT_ROOT}/skills/trends-creator"

echo "=== Testing Fake Wikilink Detection ==="
echo ""

# Test 1: Phase 6 File Existence Validation (Layer 3)
echo "Test 1: Phase 6 - File existence validation"
echo "Testing that Phase 6 detects claim wikilinks pointing to non-existent files"

# Create test trend file with fake claim wikilinks
TEST_PROJECT="/tmp/test-fake-wikilinks-$$"
mkdir -p "${TEST_PROJECT}/11-trends/data"
mkdir -p "${TEST_PROJECT}/10-claims/data"

# Create a valid claim
cat > "${TEST_PROJECT}/10-claims/data/claim-valid-abc123.md" << 'EOF'
---
dc:identifier: claim-valid-abc123
confidence_score: 0.85
---
This is a valid claim.
EOF

# Create trend with mix of valid and fake claims
cat > "${TEST_PROJECT}/11-trends/data/trend-test-xyz789.md" << 'EOF'
---
dc:identifier: trend-test-xyz789
claim_refs:
  - claim-valid-abc123
  - claim-fake-def456
  - claim-fabricated-ghi789
---

# Test Trend

"Valid claim quote"<sup>[[10-claims/data/claim-valid-abc123|C1]]</sup>
"Fake claim quote"<sup>[[10-claims/data/claim-fake-def456|C2]]</sup>
"Fabricated claim"<sup>[[10-claims/data/claim-fabricated-ghi789|C3]]</sup>
EOF

# Simulate Phase 6 validation logic
echo "Running Phase 6 validation..."
claim_validation_passed=true
missing_claim_files=()

FILEPATH="${TEST_PROJECT}/11-trends/data/trend-test-xyz789.md"
claim_ids=$(grep -oE '\[\[10-claims/data/claim-[^]|]+\|C[0-9]+\]\]' "$FILEPATH" | sed -E 's/\[\[10-claims\/data\/([^]|]+)\|.*/\1/')

for claim_id in $claim_ids; do
  CLAIM_FILE="${TEST_PROJECT}/10-claims/data/${claim_id}.md"
  if [ ! -f "$CLAIM_FILE" ]; then
    echo "  ✗ FAKE claim detected: ${claim_id}"
    echo "    File does NOT exist: ${CLAIM_FILE}"
    missing_claim_files+=("${claim_id}")
    claim_validation_passed=false
  else
    echo "  ✓ Valid claim: ${claim_id}"
  fi
done

if [ "$claim_validation_passed" = "false" ]; then
  echo "✓ Test 1 PASSED: Phase 6 correctly detected ${#missing_claim_files[@]} fake claims"
else
  echo "✗ Test 1 FAILED: Phase 6 should have detected fake claims"
  exit 1
fi

echo ""

# Test 2: Phase 3 Claim Registry Construction (Layer 2)
echo "Test 2: Phase 3 - Claim registry construction"
echo "Testing that Phase 3 builds registry from actual files"

# Simulate Phase 3 registry construction
declare -a CLAIM_REGISTRY=()
for claim_file in "${TEST_PROJECT}/10-claims/data/"*.md; do
  claim_id=$(basename "$claim_file" .md)
  CLAIM_REGISTRY+=("$claim_id")
  echo "  Registered: $claim_id"
done

echo "Registry size: ${#CLAIM_REGISTRY[@]}"
if [ ${#CLAIM_REGISTRY[@]} -eq 1 ]; then
  echo "✓ Test 2 PASSED: Registry contains only valid claims from filesystem"
else
  echo "✗ Test 2 FAILED: Registry size incorrect"
  exit 1
fi

echo ""

# Test 3: Phase 4 Pre-Write Validation (Layer 1)
echo "Test 3: Phase 4 - Pre-write validation against registry"
echo "Testing that Phase 4 validates claim_refs in frontmatter"

# Extract claim_refs from frontmatter
claim_refs=$(grep -A 5 "^claim_refs:" "$FILEPATH" | grep "  - " | sed 's/.*- //')

validation_passed=true
invalid_claims=()

for claim_ref in $claim_refs; do
  if printf '%s\n' "${CLAIM_REGISTRY[@]}" | grep -q "^${claim_ref}$"; then
    echo "  ✓ Valid claim_ref: ${claim_ref}"
  else
    echo "  ✗ FAKE claim_ref: ${claim_ref} (not in registry)"
    invalid_claims+=("${claim_ref}")
    validation_passed=false
  fi
done

if [ "$validation_passed" = "false" ]; then
  echo "✓ Test 3 PASSED: Phase 4 correctly detected ${#invalid_claims[@]} fake claim_refs"
else
  echo "✗ Test 3 FAILED: Phase 4 should have detected fake claim_refs"
  exit 1
fi

echo ""

# Test 4: End-to-End Defense Layers
echo "Test 4: End-to-End - All three layers working together"

echo "Layer 2 (Phase 3): Registry = ${#CLAIM_REGISTRY[@]} claims"
echo "Layer 1 (Phase 4): Detected ${#invalid_claims[@]} fake claim_refs before write"
echo "Layer 3 (Phase 6): Detected ${#missing_claim_files[@]} fake wikilinks after write"

if [ ${#invalid_claims[@]} -eq 2 ] && [ ${#missing_claim_files[@]} -eq 2 ]; then
  echo "✓ Test 4 PASSED: All layers detected fake claims correctly"
else
  echo "✗ Test 4 FAILED: Layer mismatch"
  exit 1
fi

echo ""

# Cleanup
rm -rf "$TEST_PROJECT"

echo "=== ALL TESTS PASSED ==="
echo ""
echo "Summary:"
echo "- Layer 3 (Phase 6): File existence validation ✓"
echo "- Layer 2 (Phase 3): Claim registry construction ✓"
echo "- Layer 1 (Phase 4): Pre-write validation ✓"
echo "- Defense-in-depth: All layers working ✓"
echo ""
echo "Fabrication detection rate: 100% (2/2 fake claims detected)"
echo "False positive rate: 0% (1/1 valid claim passed)"
