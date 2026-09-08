#!/usr/bin/env bash
# Regression test for cogni-portfolio/scripts/validate-entities.sh covering the
# shared_solution / messaging_overlay contract (issue #246, follow-ups #250–#252).
#
# Fixtures are heredoc'd inline — no committed JSON blobs to maintain. Each
# fixture builds a minimal portfolio project in a temp directory, runs the
# validator, and asserts on the resulting JSON error set.
#
# Coverage:
#   1  overlay-valid                       happy path (subscription)
#   2  overlay-missing-ref                 shared_solution_ref → missing file (error)
#   3  overlay-type-mismatch               overlay vs ref solution_type mismatch (error)
#   4  ref-incomplete-subscription         _shared/ subscription missing commercial fields (error)
#   5  ref-incomplete-project              _shared/ project missing implementation phases (error)
#   6  overlay-hybrid                      happy path (hybrid) — closes #250
#   7  overlay-hybrid-drift                hybrid pricing drift warning — closes #250
#   8  ref-invalid-solution-type           _shared/ invalid solution_type (exit 9) — closes #251
#   9  overlay-half-declared-overlay-only  messaging_overlay without shared_solution_ref — closes #252
#  10  overlay-half-declared-ref-only      shared_solution_ref without messaging_overlay — closes #252
#  11  commercial-model-off-enum           out-of-enum commercial_model → warning on product + proposition
#  12  commercial-model-in-enum            in-enum commercial_model → no warning (negative twin)
#
# Usage: bash cogni-portfolio/tests/test-validate-entities.sh
# Exits non-zero on any assertion failure.
#
# This suite has NO per-case selector — every fixture is unconditional top-level
#   code, so an argument naming one is ignored. The recipe below therefore runs the
#   whole suite, and the harness classifies on the named fixture's own output line.
#
# Mutation recipe — the SHARED cogni-service harness. Replayable as written, from the
#   repo root:
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/scripts/validate-entities.sh \
#     --expr 's/if not os\.path\.isfile\(shared_path\)/if False/' \
#     --test 'bash cogni-portfolio/tests/test-validate-entities.sh' \
#     --case overlay-missing-ref
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.

# `set -u` only — `set -e` would abort on the first failing assertion and
# defeat the per-fixture failure counter below.
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
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one `<case>: <msg>` string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

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

# Write a valid hybrid-type shared reference at _shared/acme-suite--dach.
# The _shared/ block treats ('subscription', 'hybrid') identically, so this
# mirrors write_subscription_ref's envelope (validate-entities.sh:768–771).
write_hybrid_ref() {
  local pdir="$1"
  cat > "$pdir/solutions/_shared/acme-suite--dach.json" <<EOF
{
  "slug": "_shared/acme-suite--dach",
  "shared_solution": true,
  "product_slug": "acme-suite",
  "market_slug": "dach",
  "solution_type": "hybrid",
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

# Run the validator on $pdir once, stashing exit code (RC) and stdout
# (VALIDATOR_OUTPUT) in globals so each fixture invokes the script exactly
# once and downstream counters operate on the same result.
run_validator() {
  VALIDATOR_OUTPUT=$(bash "$SCRIPT" "$1" 2>/dev/null)
  RC=$?
}

# Count solution-entity entries of $kind (errors|warnings) matching $substring.
# Other entities are ignored so each fixture stays focused on the contract
# under test.
count_solution_entries() {
  local kind="$1"
  local substring="${2:-}"
  printf '%s' "$VALIDATOR_OUTPUT" | python3 -c "
import json, sys
kind = sys.argv[1]
substring = sys.argv[2] if len(sys.argv) > 2 else ''
doc = json.load(sys.stdin)
n = 0
for e in doc.get(kind, []):
    if e.get('entity') != 'solution':
        continue
    if substring and substring not in e.get('message', ''):
        continue
    n += 1
print(n)
" "$kind" "$substring"
}

# Count entries of $kind (errors|warnings) for an arbitrary $entity matching
# $substring — the entity-agnostic sibling of count_solution_entries, used by
# the commercial_model fixtures below (which assert on product and proposition
# entities rather than solutions).
count_entity_entries() {
  local kind="$1" entity="$2" substring="${3:-}"
  printf '%s' "$VALIDATOR_OUTPUT" | python3 -c "
import json, sys
kind, entity = sys.argv[1], sys.argv[2]
substring = sys.argv[3] if len(sys.argv) > 3 else ''
doc = json.load(sys.stdin)
n = 0
for e in doc.get(kind, []):
    if e.get('entity') != entity:
        continue
    if substring and substring not in e.get('message', ''):
        continue
    n += 1
print(n)
" "$kind" "$entity" "$substring"
}

# Print solution errors and warnings (for diagnostic output on failure).
dump_solution_entries() {
  printf '%s' "$VALIDATOR_OUTPUT" | python3 -c "
import json, sys
doc = json.load(sys.stdin)
for kind in ('errors', 'warnings'):
    for e in doc.get(kind, []):
        if e.get('entity') == 'solution':
            print('  ' + kind[0].upper() + ' ' + e.get('file','') + ': ' + e.get('message',''))
"
}

# ─── Fixture 1: overlay-valid ───────────────────────────────────────────────
# Asserts the contract surface: clean overlay over a well-formed reference
# must produce 0 solution errors, 0 solution warnings, and validator rc 0.
pdir="$(seed_project overlay-valid subscription)"
write_subscription_ref "$pdir"
write_overlay "$pdir" subscription "solutions/_shared/acme-suite--dach"
run_validator "$pdir"
n_err=$(count_solution_entries errors)
n_warn=$(count_solution_entries warnings)
if [ "$RC" = "0" ] && [ "$n_err" = "0" ] && [ "$n_warn" = "0" ]; then
  pass "overlay-valid" "rc=0, 0 solution errors, 0 solution warnings"
else
  fail "overlay-valid" "expected rc=0/0/0, got rc=$RC errors=$n_err warnings=$n_warn"
  dump_solution_entries >&2
fi

# ─── Fixture 2: overlay-missing-ref ─────────────────────────────────────────
pdir="$(seed_project overlay-missing-ref subscription)"
write_subscription_ref "$pdir"
write_overlay "$pdir" subscription "solutions/_shared/does-not-exist"
run_validator "$pdir"
n_total=$(count_solution_entries errors)
n_match=$(count_solution_entries errors "references non-existent file")
if [ "$RC" != "0" ] && [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "overlay-missing-ref" "rc!=0, 1 error naming the missing path"
else
  fail "overlay-missing-ref" "expected rc!=0 and 1 error matching 'references non-existent file', got rc=$RC total=$n_total match=$n_match"
  dump_solution_entries >&2
fi

# ─── Fixture 3: overlay-type-mismatch ───────────────────────────────────────
pdir="$(seed_project overlay-type-mismatch subscription)"
write_subscription_ref "$pdir"
write_overlay "$pdir" project "solutions/_shared/acme-suite--dach"
run_validator "$pdir"
n_total=$(count_solution_entries errors)
n_match=$(count_solution_entries errors "does not match shared reference type")
if [ "$RC" != "0" ] && [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "overlay-type-mismatch" "rc!=0, 1 error naming the mismatch"
else
  fail "overlay-type-mismatch" "expected rc!=0 and 1 error matching 'does not match shared reference type', got rc=$RC total=$n_total match=$n_match"
  dump_solution_entries >&2
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
run_validator "$pdir"
n_total=$(count_solution_entries errors)
n_match=$(count_solution_entries errors "Shared reference (subscription/hybrid) missing required subscription object")
if [ "$RC" != "0" ] && [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "ref-incomplete-subscription" "rc!=0, 1 error on the reference, not the overlay"
else
  fail "ref-incomplete-subscription" "expected rc!=0 and 1 error on the reference, got rc=$RC total=$n_total match=$n_match"
  dump_solution_entries >&2
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
run_validator "$pdir"
n_total=$(count_solution_entries errors)
n_match=$(count_solution_entries errors "Shared reference (project) missing implementation phases")
if [ "$RC" != "0" ] && [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "ref-incomplete-project" "rc!=0, 1 error on the reference"
else
  fail "ref-incomplete-project" "expected rc!=0 and 1 error on the reference, got rc=$RC total=$n_total match=$n_match"
  dump_solution_entries >&2
fi

# ─── Fixture 6: overlay-hybrid ──────────────────────────────────────────────
# Closes #250 (happy path). Exercises the ('subscription', 'hybrid') branch in
# the main solutions block (validate-entities.sh:603) and in the _shared/
# consistency block (validate-entities.sh:768).
pdir="$(seed_project overlay-hybrid subscription)"
write_hybrid_ref "$pdir"
write_overlay "$pdir" hybrid "solutions/_shared/acme-suite--dach"
run_validator "$pdir"
n_err=$(count_solution_entries errors)
n_warn=$(count_solution_entries warnings)
if [ "$RC" = "0" ] && [ "$n_err" = "0" ] && [ "$n_warn" = "0" ]; then
  pass "overlay-hybrid" "rc=0, 0 solution errors, 0 solution warnings"
else
  fail "overlay-hybrid" "expected rc=0/0/0, got rc=$RC errors=$n_err warnings=$n_warn"
  dump_solution_entries >&2
fi

# ─── Fixture 7: overlay-hybrid-drift ────────────────────────────────────────
# Closes #250 (drift path). Overlay carries inline subscription.tiers with
# pricing that differs from the shared reference → shared_rc=4 → warning at
# validate-entities.sh:710.
pdir="$(seed_project overlay-hybrid-drift subscription)"
write_hybrid_ref "$pdir"
cat > "$pdir/solutions/cogni-x--dach.json" <<EOF
{
  "slug": "cogni-x--dach",
  "proposition_slug": "cogni-x--dach",
  "solution_type": "hybrid",
  "messaging_overlay": true,
  "shared_solution_ref": "solutions/_shared/acme-suite--dach",
  "subscription": {
    "currency": "EUR",
    "tiers": {
      "pro": {"price_monthly": 199, "price_annual": 1990}
    }
  }
}
EOF
run_validator "$pdir"
n_err=$(count_solution_entries errors)
n_warn_drift=$(count_solution_entries warnings "Pricing drift detected")
if [ "$RC" = "0" ] && [ "$n_err" = "0" ] && [ "$n_warn_drift" = "1" ]; then
  pass "overlay-hybrid-drift" "rc=0, 0 errors, 1 warning matching 'Pricing drift detected'"
else
  fail "overlay-hybrid-drift" "expected rc=0, 0 errors, 1 drift warning; got rc=$RC errors=$n_err drift=$n_warn_drift"
  dump_solution_entries >&2
fi

# ─── Fixture 8: ref-invalid-solution-type ───────────────────────────────────
# Closes #251. _shared/ reference declares solution_type "consulting" (not in
# the allowed set) → exit 9 in the _shared/ block (validate-entities.sh:777) →
# error at line 789. Overlay uses matching "consulting" + messaging_overlay so
# the main block short-circuits at L585 (no exit-11) and the shared_solution_ref
# block sees matching types (no exit-5 mismatch).
pdir="$(seed_project ref-invalid-solution-type subscription)"
cat > "$pdir/solutions/_shared/acme-suite--dach.json" <<EOF
{
  "slug": "_shared/acme-suite--dach",
  "shared_solution": true,
  "product_slug": "acme-suite",
  "market_slug": "dach",
  "solution_type": "consulting",
  "proposition_slug": "acme-suite--dach"
}
EOF
cat > "$pdir/solutions/cogni-x--dach.json" <<EOF
{
  "slug": "cogni-x--dach",
  "proposition_slug": "cogni-x--dach",
  "solution_type": "consulting",
  "messaging_overlay": true,
  "shared_solution_ref": "solutions/_shared/acme-suite--dach"
}
EOF
run_validator "$pdir"
n_total=$(count_solution_entries errors)
# Acceptance criteria from #251: error message must surface BOTH the offending
# value and the reference file path. Single substring covers both.
n_match=$(count_solution_entries errors "_shared/acme-suite--dach has invalid solution_type 'consulting'")
if [ "$RC" != "0" ] && [ "$n_total" = "1" ] && [ "$n_match" = "1" ]; then
  pass "ref-invalid-solution-type" "rc!=0, 1 error naming the invalid type"
else
  fail "ref-invalid-solution-type" "expected rc!=0 and 1 error naming the invalid type and ref path, got rc=$RC total=$n_total match=$n_match"
  dump_solution_entries >&2
fi

# ─── Fixture 9: overlay-half-declared-overlay-only ──────────────────────────
# Closes #252 (exit-1 warning). messaging_overlay=true with no
# shared_solution_ref → shared_rc=1 → warning at validate-entities.sh:704.
# Main block short-circuits at L585 (overlay=true → exit 0); no _shared/ file
# is written, so the _shared/ block iterates zero times.
pdir="$(seed_project overlay-half-declared-overlay-only subscription)"
cat > "$pdir/solutions/cogni-x--dach.json" <<EOF
{
  "slug": "cogni-x--dach",
  "proposition_slug": "cogni-x--dach",
  "solution_type": "subscription",
  "messaging_overlay": true,
  "subscription": {
    "currency": "EUR",
    "tiers": {
      "pro": {"price_monthly": 149, "price_annual": 1490}
    }
  }
}
EOF
run_validator "$pdir"
n_err=$(count_solution_entries errors)
n_match=$(count_solution_entries warnings "shared_solution_ref is missing")
if [ "$RC" = "0" ] && [ "$n_err" = "0" ] && [ "$n_match" = "1" ]; then
  pass "overlay-half-declared-overlay-only" "rc=0, 0 errors, 1 warning naming the missing ref"
else
  fail "overlay-half-declared-overlay-only" "expected rc=0, 0 errors, 1 warning matching 'shared_solution_ref is missing', got rc=$RC errors=$n_err match=$n_match"
  dump_solution_entries >&2
fi

# ─── Fixture 10: overlay-half-declared-ref-only ─────────────────────────────
# Closes #252 (exit-2 warning). shared_solution_ref present, messaging_overlay
# omitted → shared_rc=2 → warning at validate-entities.sh:705. Overlay must be
# structurally complete (subscription.tiers + currency) since the main block
# no longer short-circuits at L585. Overlay pricing must mirror the reference
# exactly so the drift check (L687–693) does not also fire shared_rc=4.
pdir="$(seed_project overlay-half-declared-ref-only subscription)"
write_subscription_ref "$pdir"
cat > "$pdir/solutions/cogni-x--dach.json" <<EOF
{
  "slug": "cogni-x--dach",
  "proposition_slug": "cogni-x--dach",
  "solution_type": "subscription",
  "shared_solution_ref": "solutions/_shared/acme-suite--dach",
  "subscription": {
    "currency": "EUR",
    "tiers": {
      "pro": {"price_monthly": 149, "price_annual": 1490}
    }
  }
}
EOF
run_validator "$pdir"
n_err=$(count_solution_entries errors)
n_match=$(count_solution_entries warnings "messaging_overlay not set to true")
if [ "$RC" = "0" ] && [ "$n_err" = "0" ] && [ "$n_match" = "1" ]; then
  pass "overlay-half-declared-ref-only" "rc=0, 0 errors, 1 warning naming the missing overlay flag"
else
  fail "overlay-half-declared-ref-only" "expected rc=0, 0 errors, 1 warning matching 'messaging_overlay not set to true', got rc=$RC errors=$n_err match=$n_match"
  dump_solution_entries >&2
fi

# ─── Fixture 11: commercial-model-off-enum ──────────────────────────────────
# The consolidation gate silently ignores an out-of-enum commercial_model, so a
# casing slip would disable a signal with no diagnostic at all. The validator
# raises a warning (never an error — the field is optional) on both the product
# and the proposition surface. Without this fixture that documented behaviour
# had nothing pinning it.
pdir="$(seed_project commercial-model-off-enum subscription)"
python3 - "$pdir" <<'PY'
import json, sys
p = sys.argv[1]
prod = json.load(open(p + '/products/acme-suite.json'))
prod['commercial_model'] = 'Catalog'          # casing slip — off-enum
json.dump(prod, open(p + '/products/acme-suite.json', 'w'))
json.dump({
    "slug": "cogni-x--dach", "feature_slug": "cogni-x", "market_slug": "dach",
    "commercial_model": "bogus",
    "is_statement": "Cogni X is a tool that helps DACH buyers daily reliably here now today.",
    "does_statement": "It automates what DACH buyers need for productivity and steady measurable growth.",
    "means_statement": "DACH buyers save time and money adopting Cogni X for productivity and growth.",
}, open(p + '/propositions/cogni-x--dach.json', 'w'))
PY
run_validator "$pdir"
n_prod=$(count_entity_entries warnings product "commercial_model 'Catalog'")
n_prop=$(count_entity_entries warnings proposition "commercial_model 'bogus'")
n_prod_err=$(count_entity_entries errors product "commercial_model")
if [ "$n_prod" = "1" ] && [ "$n_prop" = "1" ] && [ "$n_prod_err" = "0" ]; then
  pass "commercial-model-off-enum" "1 product + 1 proposition warning, 0 errors (warning-level, not fatal)"
else
  fail "commercial-model-off-enum" "expected 1/1/0, got product=$n_prod proposition=$n_prop product_errors=$n_prod_err"
fi

# ─── Fixture 12: commercial-model-in-enum ───────────────────────────────────
# The negative twin: a valid value on either surface must stay silent, or the
# warning would fire on every well-formed project and be ignored as noise.
pdir="$(seed_project commercial-model-in-enum subscription)"
python3 - "$pdir" <<'PY'
import json, sys
p = sys.argv[1]
prod = json.load(open(p + '/products/acme-suite.json'))
prod['commercial_model'] = 'catalog'
json.dump(prod, open(p + '/products/acme-suite.json', 'w'))
json.dump({
    "slug": "cogni-x--dach", "feature_slug": "cogni-x", "market_slug": "dach",
    "commercial_model": "subscription",
    "is_statement": "Cogni X is a tool that helps DACH buyers daily reliably here now today.",
    "does_statement": "It automates what DACH buyers need for productivity and steady measurable growth.",
    "means_statement": "DACH buyers save time and money adopting Cogni X for productivity and growth.",
}, open(p + '/propositions/cogni-x--dach.json', 'w'))
PY
run_validator "$pdir"
n_prod=$(count_entity_entries warnings product "commercial_model")
n_prop=$(count_entity_entries warnings proposition "commercial_model")
if [ "$n_prod" = "0" ] && [ "$n_prop" = "0" ]; then
  pass "commercial-model-in-enum" "valid values raise no commercial_model warning"
else
  fail "commercial-model-in-enum" "expected 0/0, got product=$n_prod proposition=$n_prop"
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
