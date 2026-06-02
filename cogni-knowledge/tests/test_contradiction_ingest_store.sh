#!/usr/bin/env bash
# test_contradiction_ingest_store.sh — smoke test for contradiction-ingest-store.py
# (Phase 4 ingest-time contradiction tripwire fan-in).
#
# Asserts:
#   1. init writes an empty canonical contradiction-ingest.json (schema 0.1.0,
#      empty findings, zeroed counts, empty groups_compared).
#   2. merge concatenates two per-group fragments, re-ids findings globally
#      ctr-001.., recomputes aggregate counts, asserts the three count
#      invariants, and records one groups_compared[] row per fragment.
#   3. The aggregate counts match the union of the fragments and satisfy:
#      total == len(findings); contradiction+unknown == total;
#      high+medium+low == contradiction.
#   4. merge is idempotent (a re-merge overwrites the canonical file).
#   5. A malformed / wrong-schema fragment is skipped fail-soft (recorded in
#      skipped_shards[]) rather than aborting the merge.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/contradiction-ingest-store.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: contradiction-ingest-store.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

OUT="$WORK/contradiction-ingest.json"

# --- 1. init --------------------------------------------------------------
python3 "$SCRIPT" init --out "$OUT" --output-language en >/dev/null
if python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["schema_version"] == "0.1.0", d.get("schema_version")
assert d["findings"] == [], d["findings"]
assert d["groups_compared"] == [], d["groups_compared"]
c = d["counts"]
assert c == {"contradiction": 0, "unknown": 0, "total": 0, "high": 0, "medium": 0, "low": 0}, c
assert d["output_language"] == "en", d["output_language"]
PY
then
  green "PASS: init writes an empty canonical file (schema 0.1.0, zeroed counts)"
else
  red "FAIL: init canonical file shape wrong"
  errors=$((errors + 1))
fi

# --- 2 fragments ----------------------------------------------------------
# Group A: 2 findings — 1 high contradiction + 1 unknown.
cat > "$WORK/.contradiction-ingest.group-a.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "output_language": "en",
  "question_slug": "group-a",
  "compared": {"new_count": 2, "peer_count": 1, "missing_pages": []},
  "findings": [
    {"id": "ctr-001", "kind": "contradiction", "severity": "high", "new_page": "src-new-1", "new_claim_id": "clm-001", "new_excerpt": "12 months", "conflicting_page": "src-old-1", "conflicting_claim_id": "clm-009", "conflicting_excerpt": "24 months", "note": "12 vs 24"},
    {"id": "ctr-002", "kind": "unknown", "severity": null, "new_page": "src-new-1", "new_claim_id": "clm-002", "new_excerpt": "ambiguous", "conflicting_page": "src-new-2", "conflicting_claim_id": null, "conflicting_excerpt": "ambiguous", "note": "unclear"}
  ],
  "counts": {"contradiction": 1, "unknown": 1, "total": 2, "high": 1, "medium": 0, "low": 0}
}
JSON

# Group B: 2 findings — 1 medium + 1 low contradiction; one missing page.
cat > "$WORK/.contradiction-ingest.group-b.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "output_language": "en",
  "question_slug": "group-b",
  "compared": {"new_count": 1, "peer_count": 2, "missing_pages": ["src-vanished"]},
  "findings": [
    {"id": "ctr-001", "kind": "contradiction", "severity": "medium", "new_page": "src-new-3", "new_claim_id": "clm-003", "new_excerpt": "EU-wide", "conflicting_page": "concept-x", "conflicting_claim_id": "dcl-004", "conflicting_excerpt": "Germany only", "note": "scope"},
    {"id": "ctr-002", "kind": "contradiction", "severity": "low", "new_page": "src-new-3", "new_claim_id": "clm-005", "new_excerpt": "soft", "conflicting_page": "high-risk", "conflicting_claim_id": "acl-001", "conflicting_excerpt": "soft other", "note": "soft"}
  ],
  "counts": {"contradiction": 2, "unknown": 0, "total": 2, "high": 0, "medium": 1, "low": 1}
}
JSON

# --- 2/3. merge -----------------------------------------------------------
python3 "$SCRIPT" merge \
  --shards "$WORK/.contradiction-ingest.*.json" \
  --out "$OUT" \
  --output-language en >/dev/null

if python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
f = d["findings"]
# 4 findings total, re-id'd ctr-001..ctr-004 globally.
ids = [x["id"] for x in f]
assert ids == ["ctr-001", "ctr-002", "ctr-003", "ctr-004"], ids
# Aggregate counts.
c = d["counts"]
assert c["total"] == 4, c
assert c["contradiction"] == 3, c
assert c["unknown"] == 1, c
assert c["high"] == 1 and c["medium"] == 1 and c["low"] == 1, c
# Invariants.
assert c["total"] == c["contradiction"] + c["unknown"], c
assert c["contradiction"] == c["high"] + c["medium"] + c["low"], c
# groups_compared: one row per fragment, sorted by question_slug.
g = d["groups_compared"]
assert [x["question_slug"] for x in g] == ["group-a", "group-b"], g
assert g[0]["finding_count"] == 2 and g[1]["finding_count"] == 2, g
assert g[1]["missing_pages"] == ["src-vanished"], g
PY
then
  green "PASS: merge re-ids globally, recomputes aggregate counts, records groups_compared[], invariants hold"
else
  red "FAIL: merged canonical file wrong"
  errors=$((errors + 1))
fi

# --- 4. idempotent re-merge ----------------------------------------------
python3 "$SCRIPT" merge \
  --shards "$WORK/.contradiction-ingest.*.json" \
  --out "$OUT" \
  --output-language en >/dev/null
if python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert len(d["findings"]) == 4, len(d["findings"])
assert [x["id"] for x in d["findings"]] == ["ctr-001", "ctr-002", "ctr-003", "ctr-004"]
PY
then
  green "PASS: re-merge is idempotent (overwrites the canonical file)"
else
  red "FAIL: re-merge not idempotent"
  errors=$((errors + 1))
fi

# --- 5. fail-soft on a malformed / wrong-schema fragment ------------------
echo 'not json at all {' > "$WORK/.contradiction-ingest.broken.json"
cat > "$WORK/.contradiction-ingest.oldschema.json" <<'JSON'
{"schema_version": "9.9.9", "question_slug": "old", "findings": []}
JSON
python3 "$SCRIPT" merge \
  --shards "$WORK/.contradiction-ingest.*.json" \
  --out "$OUT" \
  --output-language en > "$WORK/merge-envelope.json"
if python3 - "$WORK/merge-envelope.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["success"] is True, d
skipped = {s["shard"] for s in d["data"]["skipped_shards"]}
assert ".contradiction-ingest.broken.json" in skipped, skipped
assert ".contradiction-ingest.oldschema.json" in skipped, skipped
# The two good fragments still merged.
assert d["data"]["shards_merged"] == 2, d["data"]
assert d["data"]["counts"]["total"] == 4, d["data"]
PY
then
  green "PASS: merge skips a malformed / wrong-schema fragment fail-soft (records skipped_shards[])"
else
  red "FAIL: fail-soft skip not handled"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
