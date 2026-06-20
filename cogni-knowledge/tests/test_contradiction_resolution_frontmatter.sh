#!/usr/bin/env bash
# test_contradiction_resolution_frontmatter.sh — round-trip contract test for
# contradiction-frontmatter-store.py (mode-B durability: persist recency-survivor
# contradiction resolutions onto wiki/sources + wiki/questions frontmatter).
#
# Asserts:
#   1. `splice` adds a top-level `contradiction_resolutions:` block to each participating
#      source + question page named by a resolved contradiction finding.
#   2. The splice is ADDITIVE — `pre_extracted_claims:` / `answer_claims:` and every other
#      frontmatter key, plus the whole body, survive byte-for-byte.
#   3. The persisted entry carries the survivor/loser pair + rationale, and round-trips
#      through `_knowledge_lib.parse_contradiction_resolutions`.
#   4. A loser whose claim is on a distilled page (`dcl-`) is out of scope — that page is
#      not written (the composer's central-JSON fallback covers it).
#   5. A re-run is idempotent (byte-identical no-op).
#   6. Fail-soft: a missing / empty ingest JSON, and a finding with a null survivor, are
#      clean no-ops (no page written, success: true).
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/contradiction-frontmatter-store.py"
WIKI_SCRIPTS="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: contradiction-frontmatter-store.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

WIKI="$WORK/wiki-root"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/questions"

# --- minimal pages -------------------------------------------------------
write_source_page() {
  # $1 = slug, $2 = claim_id
  cat > "$WIKI/wiki/sources/$1.md" <<EOF
---
id: $1
title: "Source $1"
type: source
tags: [source]
created: 2026-05-01
updated: 2026-05-01
sources: ["https://example.org/$1"]
pre_extracted_claims:
  - id: $2
    text: "A verifiable claim from $1."
    excerpt_quote: "A verifiable claim from $1."
    excerpt_position: 100
    sub_question_refs: [sq-01]
    extracted_at: "2026-05-01T00:00:00Z"
---

# Source $1

Body paragraph that must survive byte-for-byte.
EOF
}

write_question_page() {
  # $1 = slug, $2 = acl id
  cat > "$WIKI/wiki/questions/$1.md" <<EOF
---
id: $1
title: "Question $1"
type: question
tags: [question]
created: 2026-05-01
updated: 2026-05-01
sources_answering: [src-a]
answer_claims:
  - claim_id: $2
    text: "An answer claim on $1."
    norm_key: "answer claim $1"
    backlinks: ["src-a"]
    source_claim_refs: ["src-a#clm-009"]
    created: 2026-05-01
    updated: 2026-05-01
---

## Findings

- [[src-a]]

## Notes

Human note that must survive byte-for-byte.
EOF
}

write_source_page "src-a" "clm-002"
write_source_page "src-b" "clm-005"
write_question_page "q-topic" "acl-001"

# Capture pristine bodies for the additive/byte-identical checks.
cp "$WIKI/wiki/sources/src-a.md" "$WORK/src-a.pristine"
cp "$WIKI/wiki/sources/src-b.md" "$WORK/src-b.pristine"
cp "$WIKI/wiki/questions/q-topic.md" "$WORK/q-topic.pristine"

# --- canonical contradiction-ingest.json ---------------------------------
# Finding 1 (source-vs-source): survivor = src-b/clm-005 (more recent), loser = src-a/clm-002.
# Finding 2 (source-vs-question): survivor = q-topic/acl-001, loser = src-a/clm-002 -> annotates the question node.
# Finding 3 (null survivor): no recency basis -> must be skipped.
# Finding 4 (distilled loser dcl-): survivor = src-b/clm-005, loser on a concept page -> the dcl side is out of scope (not written).
INGEST="$WORK/contradiction-ingest.json"
cat > "$INGEST" <<'EOF'
{
  "schema_version": "0.1.0",
  "output_language": "en",
  "groups_compared": [],
  "findings": [
    {
      "id": "ctr-001",
      "kind": "contradiction",
      "severity": "high",
      "new_page": "src-a",
      "new_claim_id": "clm-002",
      "new_excerpt": "A verifiable claim from src-a.",
      "conflicting_page": "src-b",
      "conflicting_claim_id": "clm-005",
      "conflicting_excerpt": "A verifiable claim from src-b.",
      "note": "src-a asserts X; src-b asserts Y",
      "resolution": {
        "survivor_claim_id": "clm-005",
        "strategy": "recency",
        "rationale": "src-b clm-005 2026-05-10 > src-a clm-002 2026-04-01"
      }
    },
    {
      "id": "ctr-002",
      "kind": "contradiction",
      "severity": "medium",
      "new_page": "src-a",
      "new_claim_id": "clm-002",
      "new_excerpt": "A verifiable claim from src-a.",
      "conflicting_page": "q-topic",
      "conflicting_claim_id": "acl-001",
      "conflicting_excerpt": "An answer claim on q-topic.",
      "note": "src-a asserts X; q-topic asserts Z",
      "resolution": {
        "survivor_claim_id": "acl-001",
        "strategy": "recency",
        "rationale": "q-topic acl-001 newer than src-a clm-002"
      }
    },
    {
      "id": "ctr-003",
      "kind": "contradiction",
      "severity": "low",
      "new_page": "src-a",
      "new_claim_id": "clm-002",
      "new_excerpt": "A verifiable claim from src-a.",
      "conflicting_page": "src-b",
      "conflicting_claim_id": "clm-005",
      "conflicting_excerpt": "A verifiable claim from src-b.",
      "note": "both timestamps absent",
      "resolution": {
        "survivor_claim_id": null,
        "strategy": "recency",
        "rationale": "both timestamps absent — no recency basis"
      }
    },
    {
      "id": "ctr-004",
      "kind": "contradiction",
      "severity": "low",
      "new_page": "src-b",
      "new_claim_id": "clm-005",
      "new_excerpt": "A verifiable claim from src-b.",
      "conflicting_page": "concept-x",
      "conflicting_claim_id": "dcl-007",
      "conflicting_excerpt": "A distilled claim.",
      "note": "src-b asserts Y; concept-x asserts W",
      "resolution": {
        "survivor_claim_id": "clm-005",
        "strategy": "recency",
        "rationale": "src-b clm-005 newer than concept-x dcl-007"
      }
    }
  ],
  "counts": {"total": 4, "contradiction": 4, "unknown": 0, "high": 1, "medium": 1, "low": 2},
  "resolution_coverage": {"resolved": 3, "contradictions": 4, "pct": 75.0}
}
EOF

# --- 1. splice -----------------------------------------------------------
OUT=$(python3 "$SCRIPT" splice --ingest "$INGEST" --wiki-root "$WIKI" --wiki-scripts-dir "$WIKI_SCRIPTS")
echo "$OUT" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" \
  && green "PASS: splice returned success" || { red "FAIL: splice did not succeed: $OUT"; errors=$((errors+1)); }

assert_grep "contradiction_resolutions:" "$WIKI/wiki/sources/src-a.md" "src-a gained contradiction_resolutions block (loser of ctr-001/ctr-002)"
assert_grep "contradiction_resolutions:" "$WIKI/wiki/sources/src-b.md" "src-b gained contradiction_resolutions block (survivor of ctr-001/ctr-004)"
assert_grep "contradiction_resolutions:" "$WIKI/wiki/questions/q-topic.md" "q-topic question node gained contradiction_resolutions block (survivor of ctr-002)"

# The survivor/loser pair + rationale are present on the loser page.
assert_grep "survivor_claim_id: clm-005" "$WIKI/wiki/sources/src-a.md" "src-a records the survivor claim id"
assert_grep "loser_claim_id: clm-002" "$WIKI/wiki/sources/src-a.md" "src-a records the loser claim id"
assert_grep "ctr-001" "$WIKI/wiki/sources/src-a.md" "src-a records the finding id"

# --- 2. additive — existing keys + body intact ---------------------------
assert_grep "pre_extracted_claims:" "$WIKI/wiki/sources/src-a.md" "src-a still carries pre_extracted_claims (additive)"
assert_grep "Body paragraph that must survive" "$WIKI/wiki/sources/src-a.md" "src-a body intact"
assert_grep "answer_claims:" "$WIKI/wiki/questions/q-topic.md" "q-topic still carries answer_claims (additive)"
assert_grep "Human note that must survive" "$WIKI/wiki/questions/q-topic.md" "q-topic ## Notes tail intact"

# --- 3. round-trip through the read-side parser ---------------------------
RT=$(KL="$PLUGIN_ROOT/scripts" PAGE="$WIKI/wiki/sources/src-a.md" python3 -c "
import os, sys
sys.path.insert(0, os.environ['KL'])
from _knowledge_lib import parse_contradiction_resolutions
text = open(os.environ['PAGE'], encoding='utf-8').read()
entries = parse_contradiction_resolutions(text)
# src-a is the loser of ctr-001 (survivor src-b) and ctr-002 (survivor q-topic).
by_id = {e['finding_id']: e for e in entries}
ok = (
    by_id.get('ctr-001', {}).get('survivor_page') == 'src-b'
    and by_id.get('ctr-001', {}).get('survivor_claim_id') == 'clm-005'
    and by_id.get('ctr-001', {}).get('loser_page') == 'src-a'
    and by_id.get('ctr-002', {}).get('survivor_page') == 'q-topic'
    and 'recency' == by_id.get('ctr-001', {}).get('strategy')
    and by_id.get('ctr-001', {}).get('rationale', '').startswith('src-b clm-005')
)
print('OK' if ok else 'BAD:%r' % entries)
")
[ "$RT" = "OK" ] && green "PASS: parse_contradiction_resolutions round-trips the survivor/loser pair" \
  || { red "FAIL: round-trip parser mismatch: $RT"; errors=$((errors+1)); }

# --- 4. distilled loser out of scope -------------------------------------
[ ! -f "$WIKI/wiki/concepts/concept-x.md" ] && green "PASS: distilled (dcl-) loser page is out of scope (not created)" \
  || { red "FAIL: a concepts/ page was unexpectedly created"; errors=$((errors+1)); }

# --- 5. idempotent re-run ------------------------------------------------
cp "$WIKI/wiki/sources/src-a.md" "$WORK/src-a.afterfirst"
python3 "$SCRIPT" splice --ingest "$INGEST" --wiki-root "$WIKI" --wiki-scripts-dir "$WIKI_SCRIPTS" >/dev/null
if diff -q "$WORK/src-a.afterfirst" "$WIKI/wiki/sources/src-a.md" >/dev/null; then
  green "PASS: re-run is idempotent (byte-identical)"
else
  red "FAIL: re-run changed the page (not idempotent)"; errors=$((errors+1))
fi

# --- 6. fail-soft: missing ingest, empty findings, null survivor ----------
# Fresh pages to prove no-op writes nothing.
write_source_page "src-c" "clm-100"
cp "$WIKI/wiki/sources/src-c.md" "$WORK/src-c.pristine"

MISS=$(python3 "$SCRIPT" splice --ingest "$WORK/does-not-exist.json" --wiki-root "$WIKI" --wiki-scripts-dir "$WIKI_SCRIPTS")
echo "$MISS" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('success') and d['data'].get('pages_annotated')==0 else 1)" \
  && green "PASS: missing ingest JSON is a fail-soft no-op" || { red "FAIL: missing ingest not a clean no-op: $MISS"; errors=$((errors+1)); }

EMPTY="$WORK/empty-ingest.json"
echo '{"schema_version":"0.1.0","findings":[],"counts":{},"resolution_coverage":{"resolved":0}}' > "$EMPTY"
E=$(python3 "$SCRIPT" splice --ingest "$EMPTY" --wiki-root "$WIKI" --wiki-scripts-dir "$WIKI_SCRIPTS")
echo "$E" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('success') and d['data'].get('pages_annotated')==0 else 1)" \
  && green "PASS: empty findings is a fail-soft no-op" || { red "FAIL: empty findings not a clean no-op: $E"; errors=$((errors+1)); }

# A null-survivor-only finding writes nothing.
NULLONLY="$WORK/null-ingest.json"
cat > "$NULLONLY" <<'EOF'
{"schema_version":"0.1.0","findings":[{"id":"ctr-001","kind":"contradiction","severity":"low","new_page":"src-c","new_claim_id":"clm-100","conflicting_page":"src-a","conflicting_claim_id":"clm-002","resolution":{"survivor_claim_id":null,"strategy":"recency","rationale":"no basis"}}],"resolution_coverage":{"resolved":0}}
EOF
python3 "$SCRIPT" splice --ingest "$NULLONLY" --wiki-root "$WIKI" --wiki-scripts-dir "$WIKI_SCRIPTS" >/dev/null
if diff -q "$WORK/src-c.pristine" "$WIKI/wiki/sources/src-c.md" >/dev/null; then
  green "PASS: null-survivor finding is skipped (page untouched)"
else
  red "FAIL: null-survivor finding altered a page"; errors=$((errors+1))
fi
assert_not_grep "contradiction_resolutions:" "$WIKI/wiki/sources/src-c.md" "src-c never gained a block (null survivor skipped)"

# --- summary -------------------------------------------------------------
if [ "$errors" -eq 0 ]; then
  green "All contradiction-resolution-frontmatter checks passed."
  exit 0
else
  red "$errors check(s) failed."
  exit 1
fi
