#!/usr/bin/env bash
# Regression test for cogni-portfolio/scripts/validate-entities.sh covering the
# shared_solution / messaging_overlay contract (issue #246).
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each
# fixture builds a minimal portfolio project in a temp directory, runs the
# validator, and asserts on the resulting JSON error set.
#
# Usage: bash cogni-portfolio/tests/test-validate-entities.sh
# Exits non-zero on any assertion failure.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/validate-entities.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: validate-entities.sh not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Seed shared scaffolding (portfolio.json, product, feature, market, proposition)
# Returns the project directory path.
seed_project() {
  local name="$1"
  local product_type="${2:-subscription}"  # subscription | project
  local pdir="$TMPROOT/$name"
  mkdir -p "$pdir/products" "$pdir/features" "$pdir/markets" "$pdir/propositions" \
           "$pdir/solutions/_shared"

  cat > "$pdir/portfolio.json" <<EOF
{"company": {"name": "Acme", "products": ["acme-suite"]}, "taxonomy": {}}
EOF

  cat > "$pdir/products/acme-suite.json" <<EOF
{
  "slug": "acme-suite",
  "name": "Acme Suite",
  "description": "Acme product suite.",
  "revenue_model": "$product_type",
  "shared_solution": true
}
EOF

  cat > "$pdir/features/cogni-x.json" <<EOF
{
  "slug": "cogni-x",
  "name": "Cogni X",
  "description": "Acme feature for testing the validator's shared solution overlay contract end to end.",
  "product_slug": "acme-suite"
}
EOF

  cat > "$pdir/markets/dach.json" <<EOF
{
  "slug": "dach",
  "name": "DACH",
  "description": "DACH region for testing the validator's shared solution overlay contract.",
  "region": "dach"
}
EOF

  cat > "$pdir/propositions/cogni-x--dach.json" <<EOF
{
  "slug": "cogni-x--dach",
  "feature_slug": "cogni-x",
  "market_slug": "dach",
  "is_statement": "Cogni X is a tool that does things for buyers in DACH region effectively daily.",
  "does_statement": "It automates the things that buyers in DACH region need automated for productivity and growth.",
  "means_statement": "Buyers in DACH region save time and money by adopting Cogni X for productivity and growth here."
}
EOF

  echo "$pdir"
}

# Write a valid subscription-type shared reference at _shared/acme-suite--dach
write_subscription_ref() {
  local pdir="$1"
  cat > "$pdir/solutions/_shared/acme-suite--dach.json" <<EOF
{
  "slug": "_shared/acme-suite--dach",
  "shared_solution": true,
  "product_slug": "acme-suite",
  "market_slug": "dach",
  "solution_type": "subscription",
  "proposition_slug": "acme-suite--dach",
  "subscription": {
    "currency": "EUR",
    "tiers": {
      "pro": {"price_monthly": 149, "price_annual": 1490}
    }
  }
}
EOF
}

# Write a valid project-type shared reference at _shared/acme-suite--dach
write_project_ref() {
  local pdir="$1"
  cat > "$pdir/solutions/_shared/acme-suite--dach.json" <<EOF
{
  "slug": "_shared/acme-suite--dach",
  "shared_solution": true,
  "product_slug": "acme-suite",
  "market_slug": "dach",
  "solution_type": "project",
  "proposition_slug": "acme-suite--dach",
  "implementation": [
    {"phase": "discovery", "duration_weeks": 2}
  ],
  "pricing": {
    "proof_of_value": {"price": 10000, "currency": "EUR"},
    "small": {"price": 30000, "currency": "EUR"},
    "medium": {"price": 80000, "currency": "EUR"},
    "large": {"price": 200000, "currency": "EUR"}
  }
}
EOF
}

# Write an overlay for cogni-x--dach pointing at the shared reference.
# Args: pdir, solution_type, ref_path
write_overlay() {
  local pdir="$1"
  local sol_type="$2"
  local ref_path="$3"
  cat > "$pdir/solutions/cogni-x--dach.json" <<EOF
{
  "slug": "cogni-x--dach",
  "proposition_slug": "cogni-x--dach",
  "solution_type": "$sol_type",
  "messaging_overlay": true,
  "shared_solution_ref": "$ref_path"
}
EOF
}

# Count solution-entity errors matching a substring. Other entity errors are
# ignored so each fixture stays focused on the contract under test.
count_solution_errors() {
  local pdir="$1"
  local substring="${2:-}"
  bash "$SCRIPT" "$pdir" 2>/dev/null | python3 -c "
import json, sys
substring = sys.argv[1] if len(sys.argv) > 1 else ''
doc = json.load(sys.stdin)
n = 0
for e in doc.get('errors', []):
    if e.get('entity') != 'solution':
        continue
    if substring and substring not in e.get('message', ''):
        continue
    n += 1
print(n)
" "$substring"
}

# Print solution errors (for diagnostic output on failure).
dump_solution_errors() {
  local pdir="$1"
  bash "$SCRIPT" "$pdir" 2>/dev/null | python3 -c "
import json, sys
doc = json.load(sys.stdin)
for e in doc.get('errors', []):
    if e.get('entity') == 'solution':
        print('  ' + e.get('file','') + ': ' + e.get('message',''))
"
}

# ─── Fixture 1: overlay-valid ───────────────────────────────────────────────
pdir="$(seed_project overlay-valid subscription)"
write_subscription_ref "$pdir"
write_overlay "$pdir" subscription "solutions/_shared/acme-suite--dach"
n=$(count_solution_errors "$pdir")
if [ "$n" = "0" ]; then
  pass "overlay-valid: 0 solution errors"
else
  fail "overlay-valid" "expected 0 solution errors, got $n"
  dump_solution_errors "$pdir" >&2
fi

# ─── Fixture 2: overlay-missing-ref ─────────────────────────────────────────
pdir="$(seed_project overlay-missing-ref subscription)"
write_subscription_ref "$pdir"
write_overlay "$pdir" subscription "solutions/_shared/does-not-exist"
n_total=$(count_solution_errors "$pdir")
n_match=$(count_solution_errors "$pdir" "references non-existent file")
if [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "overlay-missing-ref: 1 error naming the missing path"
else
  fail "overlay-missing-ref" "expected 1 error matching 'references non-existent file', got total=$n_total match=$n_match"
  dump_solution_errors "$pdir" >&2
fi

# ─── Fixture 3: overlay-type-mismatch ───────────────────────────────────────
pdir="$(seed_project overlay-type-mismatch subscription)"
write_subscription_ref "$pdir"
write_overlay "$pdir" project "solutions/_shared/acme-suite--dach"
n_total=$(count_solution_errors "$pdir")
n_match=$(count_solution_errors "$pdir" "does not match shared reference type")
if [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "overlay-type-mismatch: 1 error naming the mismatch"
else
  fail "overlay-type-mismatch" "expected 1 error matching 'does not match shared reference type', got total=$n_total match=$n_match"
  dump_solution_errors "$pdir" >&2
fi

# ─── Fixture 4: ref-incomplete-subscription ─────────────────────────────────
pdir="$(seed_project ref-incomplete-subscription subscription)"
cat > "$pdir/solutions/_shared/acme-suite--dach.json" <<EOF
{
  "slug": "_shared/acme-suite--dach",
  "shared_solution": true,
  "product_slug": "acme-suite",
  "market_slug": "dach",
  "solution_type": "subscription",
  "proposition_slug": "acme-suite--dach"
}
EOF
write_overlay "$pdir" subscription "solutions/_shared/acme-suite--dach"
n_total=$(count_solution_errors "$pdir")
n_match=$(count_solution_errors "$pdir" "Shared reference (subscription/hybrid) missing required subscription object")
if [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "ref-incomplete-subscription: 1 error on the reference, not the overlay"
else
  fail "ref-incomplete-subscription" "expected 1 error on the reference, got total=$n_total match=$n_match"
  dump_solution_errors "$pdir" >&2
fi

# ─── Fixture 5: ref-incomplete-project ──────────────────────────────────────
pdir="$(seed_project ref-incomplete-project project)"
cat > "$pdir/solutions/_shared/acme-suite--dach.json" <<EOF
{
  "slug": "_shared/acme-suite--dach",
  "shared_solution": true,
  "product_slug": "acme-suite",
  "market_slug": "dach",
  "solution_type": "project",
  "proposition_slug": "acme-suite--dach"
}
EOF
write_overlay "$pdir" project "solutions/_shared/acme-suite--dach"
n_total=$(count_solution_errors "$pdir")
n_match=$(count_solution_errors "$pdir" "Shared reference (project) missing implementation phases")
if [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "ref-incomplete-project: 1 error on the reference"
else
  fail "ref-incomplete-project" "expected 1 error on the reference, got total=$n_total match=$n_match"
  dump_solution_errors "$pdir" >&2
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
