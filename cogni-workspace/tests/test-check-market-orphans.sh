#!/usr/bin/env bash
# test-check-market-orphans.sh — suite for cogni-workspace/scripts/check-market-orphans.py
#
# What this suite is for. The orphan check — an overlay carrying metadata for a
# domain the canonical registry does not hold — was the market taxonomy's one
# named drift signal for a long time, and it lived only as prose in a skill
# body. Nothing computed it and nothing proved it could fire. Moving it into a
# script is only half the repair; the other half is a suite whose fixtures
# discriminate, so a future refactor that quietly stops detecting orphans turns
# a case red instead of continuing to report a clean registry.
#
# The discriminating pair is the point. Every orphan-reporting case is written
# against a fixture PAIR that differs in exactly one property — one overlay
# domain the registry carries, one it does not — so a constant verdict of any
# kind fails one half of the pair. A single "the tree is clean" case would pass
# under a check that returns an empty orphan set unconditionally, which is the
# defect this suite has to be able to see.
#
# Mutation recipe (the discriminator is mo04-research-orphan-is-reported):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-market-orphans.py \
#     --expr 's{^    found = \[\]$}{    return []}m' \
#     --test 'bash cogni-workspace/tests/test-check-market-orphans.sh' \
#     --case mo04-research-orphan-is-reported
#
# The mutant makes find_orphans return an empty set unconditionally — the exact
# reversion of the property this script adds. mo04 goes RED because its
# orphan-bearing fixture reports no orphan; its control half mo05, and the other
# clean-fixture cases mo07, mo09, mo18 and mo23, all stay GREEN, because a clean
# tree and a constantly-empty result are indistinguishable from their side. That
# asymmetry is why the orphan-bearing half is the named discriminator and the
# clean half is only its control. Verified: mutated red, restored green.
#
# Second recipe, for the trends reader (the discriminator is
# mo08-trends-site-token-orphan-is-reported):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-market-orphans.py \
#     --expr 's{site:\(\[A-Za-z0-9\._-\]\+\)}{site:(NEVERMATCHESXX)}' \
#     --test 'bash cogni-workspace/tests/test-check-market-orphans.sh' \
#     --case mo08-trends-site-token-orphan-is-reported
#
# The two overlays key their domains through different fields, so one reader
# going blind leaves the other reporting normally and the whole-script cases
# stay green. mo08 is the only case that can see it. Verified: mutated red,
# restored green.
#
# Third recipe, for the DEFAULT invocation path (the discriminator is
# mo24-the-default-cascade-resolves-the-trends-overlay):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-market-orphans.py \
#     --expr 's{^        return module, None$}{        return None, None}m' \
#     --test 'bash cogni-workspace/tests/test-check-market-orphans.sh' \
#     --case mo24-the-default-cascade-resolves-the-trends-overlay
#
# The mutant neutralises the cascade loader in its quietest possible form: no
# module, no error, so every plugin reports "overlay not resolvable" under
# success:true and the live report goes blind on both overlays while claiming a
# clean registry. Sections B-G cannot see it — they all supply an explicit
# --overlay and never enter the cascade at all — which is exactly why section H
# exists. Verified: mutated red, restored green.
#
# Fourth recipe, for the crash arm (the discriminator is
# mo26-a-crashed-merge-utility-reports-failure):
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/scripts/check-market-orphans.py \
#     --expr 's{^        return None, f"\{type\(exc\)\.__name__\}: \{exc\}"$}{        return None, None}m' \
#     --test 'bash cogni-workspace/tests/test-check-market-orphans.sh' \
#     --case mo26-a-crashed-merge-utility-reports-failure
#
# The mutant swallows the import error, collapsing "our own merge utility does
# not load" back into "the sibling plugin is not installed" — the first is a
# failure of the subject, the second is legitimate degradation, and reporting
# the first as the second renders a clean audit over a registry nothing read.
# mo18 stays GREEN under it, which is the point: that case asserts the
# degradation half and must not move. Verified: mutated red, restored green.
#
# Fixtures are written rather than pointed at the live tree, except the three
# cases in section G, which deliberately join the real registry with the real
# in-repo trends overlay. mo23 is the one that turns red if someone hand-edits a
# `site:` domain into the overlay without adding it to the registry — the
# concrete event this whole check exists to catch — and mo21/mo22 are its
# anti-vacuity floor, since a registry that stopped yielding markets would let
# mo23 pass while seeing nothing. All three pass an explicit --overlay path so
# they read the repository rather than whatever happens to sit in the author's
# plugin cache; CI has no cache at all, and a case whose subject depends on the
# host is not a case.
#
# Result lines are plain "PASS: <case>" / "FAIL: <case>" with no escape
# sequences, and every case id is unique across the emitted lines. Case ids are
# mo-prefixed and never bare numerals, so the closing summary is not read as a
# result.
#
# bash-3.2 portable (stock macOS /bin/bash is 3.2.57): no declare -A, no
# mapfile, no ${var^^}. stdlib-only: bash + coreutils + python3, no pip deps,
# no network.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
SCRIPT="$WS_ROOT/scripts/check-market-orphans.py"
LIVE_REGISTRY="$WS_ROOT/references/supported-markets-registry.json"
LIVE_TRENDS_OVERLAY="$REPO_ROOT/cogni-trends/skills/trend-research/references/region-authority-sources.json"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

assert_eq() {
  case_id="$1"; expected="$2"; actual="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$case_id"
  else
    fail "$case_id"
    printf '  expected %s, got %s\n' "$expected" "$actual"
  fi
}

# write <name> <json> -> writes $TMPROOT/<name>.json and echoes the path
write() {
  printf '%s' "$2" > "$TMPROOT/$1.json"
  printf '%s' "$TMPROOT/$1.json"
}

# probe <python-expr-over-data> <args...> -> evaluates the expression against
# the script's envelope. The expression sees `payload` and `data`; a crashed or
# unparseable run prints PARSE_ERROR rather than an empty string, so a case
# cannot pass by comparing two blanks.
probe() {
  expr="$1"; shift
  python3 "$SCRIPT" "$@" 2>/dev/null | python3 -c "
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print('PARSE_ERROR'); raise SystemExit(0)
data = payload.get('data') or {}
try:
    print($expr)
except Exception as exc:
    print('EXPR_ERROR: %s' % exc)
" 2>/dev/null
}

echo "=== A. script surface ==="

if [ -f "$SCRIPT" ]; then
  pass "mo01-script-exists"
else
  fail "mo01-script-exists"
  echo "  $SCRIPT is missing; the remaining cases cannot run."
  echo "$failures test(s) failed."
  exit 1
fi

# A registry with two markets. `de` carries two canonical domains; `zz` carries
# none, which is what makes the uncanonical-market case below meaningful.
BASE_REGISTRY="$(write registry '{
  "schema_version": "1.0",
  "markets": {
    "de": {
      "code": "de", "name": "Germany", "tier": "primary",
      "default_output_language": "de",
      "authority_sources": [
        {"name": "Fraunhofer", "domain": "fraunhofer.de"},
        {"name": "Bitkom", "domain": "bitkom.org"}
      ]
    },
    "fr": {
      "code": "fr", "name": "France", "tier": "primary",
      "default_output_language": "fr",
      "authority_sources": [{"name": "INRIA", "domain": "inria.fr"}]
    }
  }
}')"

ENVELOPE="$(probe "sorted(payload.keys())" --registry "$BASE_REGISTRY" --plugin research \
  --overlay research="$(write empty_overlay '{}')")"
assert_eq "mo02-envelope-has-the-standard-three-keys" "['data', 'error', 'success']" "$ENVELOPE"

# The no-pip constraint is a property of the file, not of one run: an import
# added on a rarely-taken branch would never surface in a passing run.
NONSTDLIB="$(python3 - "$SCRIPT" <<'PY'
import ast, sys
sys.path.insert(0, '')
tree = ast.parse(open(sys.argv[1], encoding='utf-8').read())
roots = set()
for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            roots.add(alias.name.split('.')[0])
    elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
        roots.add(node.module.split('.')[0])
stdlib = set(getattr(sys, 'stdlib_module_names', ()))
print(sorted(r for r in roots if stdlib and r not in stdlib))
PY
)"
assert_eq "mo03-imports-are-stdlib-only" "[]" "$NONSTDLIB"

echo "=== B. the research overlay — authority_metadata is keyed BY domain ==="

# The pair. Both overlays curate exactly one domain for `de`; they differ only
# in whether the registry carries that domain.
RESEARCH_ORPHAN="$(write research_orphan '{
  "_default": {"local_language": "en"},
  "de": {"authority_metadata": {"handelsblatt-invented.de": {"category": "media", "tier": 2}}}
}')"
RESEARCH_CLEAN="$(write research_clean '{
  "_default": {"local_language": "en"},
  "de": {"authority_metadata": {"fraunhofer.de": {"category": "research", "tier": 1}}}
}')"

assert_eq "mo04-research-orphan-is-reported" "1" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin research \
      --overlay research="$RESEARCH_ORPHAN")"

assert_eq "mo05-research-registry-backed-domain-is-not-an-orphan" "0" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin research \
      --overlay research="$RESEARCH_CLEAN")"

assert_eq "mo06-orphan-finding-names-market-domain-and-field" \
  "('de', 'handelsblatt-invented.de', 'authority_metadata')" \
  "$(probe "(data['orphans'][0]['market'], data['orphans'][0]['domain'], data['orphans'][0]['field'])" \
      --registry "$BASE_REGISTRY" --plugin research --overlay research="$RESEARCH_ORPHAN")"

# `_`-prefixed keys are overlay metadata, not markets. Reading `_default` as a
# market would report its fields as orphans on arrival.
RESEARCH_META_ONLY="$(write research_meta '{
  "_description": "notes",
  "_default": {"authority_metadata": {"nowhere.example": {"tier": 3}}}
}')"
assert_eq "mo07-underscore-keys-are-not-scanned-as-markets" "0" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin research \
      --overlay research="$RESEARCH_META_ONLY")"

echo "=== C. the trends overlay — domains live inside a site: query token ==="

TRENDS_ORPHAN="$(write trends_orphan '{
  "de": {"site_searches": [
    {"dimension": "externe-effekte", "query": "site:invented-institute.de {TOPIC} Trends"}
  ]}
}')"
TRENDS_CLEAN="$(write trends_clean '{
  "de": {"site_searches": [
    {"dimension": "externe-effekte", "query": "site:bitkom.org {TOPIC} Digitalisierung"}
  ]}
}')"

assert_eq "mo08-trends-site-token-orphan-is-reported" "1" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin trends \
      --overlay trends="$TRENDS_ORPHAN")"

assert_eq "mo09-trends-registry-backed-site-token-is-not-an-orphan" "0" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin trends \
      --overlay trends="$TRENDS_CLEAN")"

assert_eq "mo10-trends-finding-names-the-site-searches-field" "'site_searches'" \
  "$(probe "repr(data['orphans'][0]['field'])" --registry "$BASE_REGISTRY" --plugin trends \
      --overlay trends="$TRENDS_ORPHAN")"

# One overlay routinely queries the same domain across several dimensions.
# Counting each hit would inflate the orphan count without adding a finding.
TRENDS_REPEATED="$(write trends_repeated '{
  "de": {"site_searches": [
    {"dimension": "externe-effekte", "query": "site:invented-institute.de A"},
    {"dimension": "neue-horizonte", "query": "site:invented-institute.de B"},
    {"dimension": "digitales-fundament", "query": "site:invented-institute.de C"}
  ]}
}')"
assert_eq "mo11-a-repeated-orphan-domain-is-reported-once" "1" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin trends \
      --overlay trends="$TRENDS_REPEATED")"

echo "=== D. a market the registry does not carry at all ==="

# The registry is the taxonomy, so an overlay market absent from it has an empty
# canonical domain set and every domain it curates is uncanonical. The finding
# says so rather than silently skipping the market.
UNCANONICAL="$(write uncanonical '{
  "zz": {"authority_metadata": {"a.example": {}, "b.example": {}}}
}')"
assert_eq "mo12-an-uncanonical-market-orphans-every-domain-it-curates" "2" \
  "$(probe "data['orphan_count']" --registry "$BASE_REGISTRY" --plugin research \
      --overlay research="$UNCANONICAL")"

assert_eq "mo13-an-uncanonical-market-is-flagged-as-absent-from-the-registry" "False" \
  "$(probe "data['orphans'][0]['market_in_registry']" --registry "$BASE_REGISTRY" \
      --plugin research --overlay research="$UNCANONICAL")"

echo "=== E. the coverage matrix carries all three consuming plugins ==="

MATRIX_KEYS="$(probe "all(k in row for row in data['matrix'] for k in ('research', 'trends', 'portfolio'))" \
  --registry "$BASE_REGISTRY" --plugin research --overlay research="$RESEARCH_CLEAN")"
assert_eq "mo14-matrix-row-carries-research-trends-and-portfolio" "True" "$MATRIX_KEYS"

# cogni-portfolio curates no overlay — it reads the registry directly — so its
# cell is the canonical domain count. Reporting it as uncurated would misread a
# consumer as a non-consumer.
assert_eq "mo15-portfolio-cell-is-the-canonical-domain-count" "(2, 1)" \
  "$(probe "tuple(row['portfolio'] for row in data['matrix'])" --registry "$BASE_REGISTRY" \
      --plugin research --overlay research="$RESEARCH_CLEAN")"

assert_eq "mo16-matrix-has-one-row-per-registry-market" "2" \
  "$(probe "len(data['matrix'])" --registry "$BASE_REGISTRY" --plugin research \
      --overlay research="$RESEARCH_CLEAN")"

# A market no plugin curates renders as absent, not as zero. "Curated nothing"
# and "curates zero entries" are different states and the matrix keeps them apart.
assert_eq "mo17-an-uncurated-market-cell-is-null-not-zero" "None" \
  "$(probe "[row['research'] for row in data['matrix'] if row['market'] == 'fr'][0]" \
      --registry "$BASE_REGISTRY" --plugin research --overlay research="$RESEARCH_CLEAN")"

echo "=== F. degradation and failure surfaces ==="

# An overlay that does not resolve is the ordinary state for a plugin installed
# outside the monorepo. It is reported as uncurated; it is not an error and it
# does not move the exit code.
MISSING_OVERLAY="$(probe "(payload['success'], data['plugins']['research']['curated'], data['plugins']['research']['orphan_count'])" \
  --registry "$BASE_REGISTRY" --plugin research --overlay research="$TMPROOT/does-not-exist.json")"
assert_eq "mo18-an-unresolvable-overlay-is-uncurated-not-an-error" "(True, False, 0)" "$MISSING_OVERLAY"

# A missing registry is the opposite: the taxonomy is the subject, so its
# absence is a failure that still reports through the envelope.
BAD_REGISTRY_OUT="$(python3 "$SCRIPT" --registry "$TMPROOT/no-registry.json" --plugin research 2>/dev/null)"
BAD_REGISTRY_RC=$?
BAD_REGISTRY_SUCCESS="$(printf '%s' "$BAD_REGISTRY_OUT" | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('success'))
except Exception:
    print('PARSE_ERROR')
" 2>/dev/null)"
assert_eq "mo19-a-missing-registry-fails-through-the-envelope" "False" "$BAD_REGISTRY_SUCCESS"
assert_eq "mo20-a-missing-registry-exits-non-zero" "1" "$BAD_REGISTRY_RC"

echo "=== G. the live tree ==="

# The anti-vacuity floor: if the real registry stops yielding markets, every
# fixture case above would still pass while the live check had gone blind.
LIVE_MARKETS="$(probe "data['markets_canonical'] > 0" --registry "$LIVE_REGISTRY" \
  --plugin trends --overlay trends="$LIVE_TRENDS_OVERLAY")"
assert_eq "mo21-the-live-registry-yields-markets" "True" "$LIVE_MARKETS"

LIVE_CURATED="$(probe "len(data['plugins']['trends']['curated_markets']) > 0" \
  --registry "$LIVE_REGISTRY" --plugin trends --overlay trends="$LIVE_TRENDS_OVERLAY")"
assert_eq "mo22-the-in-repo-trends-overlay-curates-markets" "True" "$LIVE_CURATED"

# The event this whole check exists to catch: a `site:` domain hand-edited into
# the in-repo overlay without being added to the canonical registry.
LIVE_ORPHANS="$(probe "data['orphan_count']" --registry "$LIVE_REGISTRY" \
  --plugin trends --overlay trends="$LIVE_TRENDS_OVERLAY")"
assert_eq "mo23-the-in-repo-trends-overlay-carries-no-orphan" "0" "$LIVE_ORPHANS"

echo "=== H. the DEFAULT invocation path — no --overlay, through the cascade ==="

# Sections B-G all pass an explicit --overlay, which is what makes them
# deterministic; the cost is that none of them touches _load_merge_utility() or
# _overlay_path(). That is the path the skill actually runs (`python3 "$ORPHANS"`
# with no arguments), so without this section a neutralised cascade loader leaves
# every case green while the live report goes blind on both plugins.
#
# Layer 1 of the cascade — the {NAME}_PLUGIN_ROOT env var — is what makes this
# deterministic in CI: layer 2 reads the author's plugin cache, which CI does not
# have, and layer 3 depends on the checkout being a monorepo sibling.
DEFAULT_PATH="$(TRENDS_PLUGIN_ROOT="$REPO_ROOT/cogni-trends" probe \
  "(data['plugins']['trends']['overlay_path'], data['plugins']['trends']['curated'])" \
  --registry "$LIVE_REGISTRY" --plugin trends)"
assert_eq "mo24-the-default-cascade-resolves-the-trends-overlay" \
  "('$LIVE_TRENDS_OVERLAY', True)" "$DEFAULT_PATH"

# A plugin the run never scanned is not the same fact as a plugin that curates
# nothing, and the matrix must not state the second when it means the first.
assert_eq "mo25-an-unscanned-plugin-cell-is-marked-not-null" "'not-scanned'" \
  "$(TRENDS_PLUGIN_ROOT="$REPO_ROOT/cogni-trends" probe "repr(data['matrix'][0]['research'])" \
      --registry "$LIVE_REGISTRY" --plugin trends)"

echo "=== I. a crashed merge utility is a failure, not a clean audit ==="

# The subject of this arm is the difference between two absences. A sibling
# plugin that is not installed is legitimate degradation (mo18). Our OWN merge
# utility failing to import is a failure of the subject: nothing read an
# overlay, so "0 orphans" would be a clean audit over nothing.
#
# It is exercised by relocating the script beside a broken copy of the helper it
# imports, because the import path is derived from the script's own directory
# and cannot be overridden by a flag. --registry keeps the real registry in play
# so only the helper differs between this arm and its control.
RELOC="$TMPROOT/relocated/scripts"
mkdir -p "$RELOC"
cp "$SCRIPT" "$RELOC/check-market-orphans.py"
RELOC_SCRIPT="$RELOC/check-market-orphans.py"

printf 'import argparse\nraise RuntimeError("boom")\n' > "$RELOC/get-market-config.py"

CRASH_OUT="$(TRENDS_PLUGIN_ROOT="$REPO_ROOT/cogni-trends" \
  python3 "$RELOC_SCRIPT" --registry "$LIVE_REGISTRY" --plugin trends 2>/dev/null)"
CRASH_RC=$?
CRASH_SUCCESS="$(printf '%s' "$CRASH_OUT" | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('success'))
except Exception:
    print('PARSE_ERROR')
" 2>/dev/null)"
CRASH_ERROR="$(printf '%s' "$CRASH_OUT" | python3 -c "
import json, sys
try:
    print('named' if 'get-market-config.py' in (json.load(sys.stdin).get('error') or '') else 'unnamed')
except Exception:
    print('PARSE_ERROR')
" 2>/dev/null)"

assert_eq "mo26-a-crashed-merge-utility-reports-failure" "False" "$CRASH_SUCCESS"
assert_eq "mo27-a-crashed-merge-utility-exits-non-zero" "1" "$CRASH_RC"
assert_eq "mo28-the-crash-error-names-the-utility-that-failed" "named" "$CRASH_ERROR"

# The control. Same relocated tree, same flags, a WORKING helper — so a green
# mo26/mo27 cannot be an artifact of the relocation itself.
cp "$WS_ROOT/scripts/get-market-config.py" "$RELOC/get-market-config.py"
assert_eq "mo29-the-same-relocated-tree-succeeds-with-a-working-utility" "(True, True)" \
  "$(TRENDS_PLUGIN_ROOT="$REPO_ROOT/cogni-trends" python3 "$RELOC_SCRIPT" \
      --registry "$LIVE_REGISTRY" --plugin trends 2>/dev/null | python3 -c "
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print('PARSE_ERROR'); raise SystemExit(0)
print((payload.get('success'), ((payload.get('data') or {}).get('plugins') or {}).get('trends', {}).get('curated')))
" 2>/dev/null)"

# The import stays LAZY, and that is a property rather than an optimisation: a
# run naming every overlay explicitly never needs the cascade, so a broken
# helper must not fail it. Without this, the fix for mo26 would have taken the
# whole fixture suite down with the helper.
printf 'import argparse\nraise RuntimeError("boom")\n' > "$RELOC/get-market-config.py"
assert_eq "mo30-an-explicit-overlay-run-survives-a-broken-utility" "(True, 0)" \
  "$(python3 "$RELOC_SCRIPT" --registry "$LIVE_REGISTRY" --plugin trends \
      --overlay trends="$LIVE_TRENDS_OVERLAY" 2>/dev/null | python3 -c "
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print('PARSE_ERROR'); raise SystemExit(0)
print((payload.get('success'), (payload.get('data') or {}).get('orphan_count')))
" 2>/dev/null)"

echo
if [ "$failures" -eq 0 ]; then
  echo "All check-market-orphans tests passed."
  exit 0
else
  echo "$failures test(s) failed."
  exit 1
fi
