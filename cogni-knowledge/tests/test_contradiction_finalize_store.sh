#!/usr/bin/env bash
# test_contradiction_finalize_store.sh — smoke test for contradiction-finalize-store.py
# (Phase 7 synthesis-side consistency-rate scoreboard, #908).
#
# Asserts:
#   1. init writes an empty canonical contradiction-finalize.json (schema 0.1.0,
#      zeroed consistency_rate + resolution_coverage, empty syntheses[]).
#   2. record on a contradictor-vN.json whose only high contradiction IS resolved
#      (resolution.survivor_claim_id present) → the synthesis is CLEAN:
#      consistency_rate.pct == 100.0, resolution_coverage reflects the resolved share.
#   3. record on a contradictor-vN.json with an UNRESOLVED high contradiction
#      (no resolution / null survivor) → NOT clean: consistency_rate.pct == 0.0.
#   4. record picks the LATEST contradictor-vN.json (v2 over v1).
#   5. record is fail-soft on a missing contradictor file → zeroed artifact with
#      a skipped_reason, never a non-zero exit.
#   6. record is idempotent (a re-record overwrites the canonical file).
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/contradiction-finalize-store.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: contradiction-finalize-store.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

errors=0

OUT="$WORK/contradiction-finalize.json"

# --- 1. init --------------------------------------------------------------
python3 "$SCRIPT" init --out "$OUT" --output-language en >/dev/null
if python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["schema_version"] == "0.1.0", d.get("schema_version")
assert d["syntheses"] == [], d["syntheses"]
assert d["consistency_rate"] == {"syntheses_total": 0, "syntheses_clean": 0, "pct": 0.0}, d["consistency_rate"]
assert d["resolution_coverage"] == {"resolved": 0, "contradictions": 0, "pct": 0.0}, d["resolution_coverage"]
assert d["output_language"] == "en", d["output_language"]
PY
then
  green "PASS: init writes an empty canonical file (schema 0.1.0, zeroed rates)"
else
  red "FAIL: init canonical file shape wrong"
  errors=$((errors + 1))
fi

# --- project scaffold -----------------------------------------------------
PROJ="$WORK/proj"
mkdir -p "$PROJ/.metadata"

# --- 2. record: a RESOLVED high contradiction → clean ---------------------
cat > "$PROJ/.metadata/contradictor-v1.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "synthesis_slug": "eu-ai-act-classification",
  "output_language": "en",
  "compared_against": {"sources": ["src-a"], "source_count": 1, "prior_syntheses": [], "prior_synthesis_count": 0, "missing_pages": []},
  "findings": [
    {"id": "ctr-001", "kind": "contradiction", "severity": "high", "synthesis_excerpt": "12 months", "conflicting_page": "src-a", "conflicting_claim_id": "clm-004", "conflicting_excerpt": "24 months", "note": "12 vs 24", "resolution": {"survivor_claim_id": "clm-004", "strategy": "recency", "rationale": "cited newer"}}
  ],
  "counts": {"contradiction": 1, "unknown": 0, "total": 1, "high": 1, "medium": 0, "low": 0}
}
JSON
OUT2="$PROJ/.metadata/contradiction-finalize.json"
python3 "$SCRIPT" record --project-path "$PROJ" --out "$OUT2" --output-language en >/dev/null
if python3 - "$OUT2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
cr = d["consistency_rate"]
assert cr["syntheses_total"] == 1, cr
assert cr["syntheses_clean"] == 1, cr            # resolved high -> clean
assert cr["pct"] == 100.0, cr
rc = d["resolution_coverage"]
assert rc == {"resolved": 1, "contradictions": 1, "pct": 100.0}, rc
s = d["syntheses"][0]
assert s["synthesis_slug"] == "eu-ai-act-classification", s
assert s["unresolved_high"] == 0 and s["clean"] is True, s
PY
then
  green "PASS: record marks a resolved-high synthesis clean (pct=100, coverage=1/1)"
else
  red "FAIL: record clean-synthesis shape wrong"
  errors=$((errors + 1))
fi

# --- 3. record: an UNRESOLVED high contradiction → not clean --------------
cat > "$PROJ/.metadata/contradictor-v1.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "synthesis_slug": "eu-ai-act-classification",
  "output_language": "en",
  "compared_against": {"sources": ["src-a"], "source_count": 1, "prior_syntheses": [], "prior_synthesis_count": 0, "missing_pages": []},
  "findings": [
    {"id": "ctr-001", "kind": "contradiction", "severity": "high", "synthesis_excerpt": "12 months", "conflicting_page": "src-a", "conflicting_claim_id": "clm-004", "conflicting_excerpt": "24 months", "note": "12 vs 24", "resolution": {"survivor_claim_id": null, "strategy": "recency", "rationale": "no timestamp"}},
    {"id": "ctr-002", "kind": "contradiction", "severity": "medium", "synthesis_excerpt": "x", "conflicting_page": "src-a", "conflicting_claim_id": "clm-005", "conflicting_excerpt": "y", "note": "m"}
  ],
  "counts": {"contradiction": 2, "unknown": 0, "total": 2, "high": 1, "medium": 1, "low": 0}
}
JSON
python3 "$SCRIPT" record --project-path "$PROJ" --out "$OUT2" --output-language en >/dev/null
if python3 - "$OUT2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
cr = d["consistency_rate"]
assert cr["syntheses_total"] == 1, cr
assert cr["syntheses_clean"] == 0, cr            # unresolved high -> not clean
assert cr["pct"] == 0.0, cr
s = d["syntheses"][0]
assert s["unresolved_high"] == 1 and s["clean"] is False, s
# A medium contradiction never breaks consistency, but it DOES count toward coverage.
rc = d["resolution_coverage"]
assert rc["contradictions"] == 2 and rc["resolved"] == 0, rc
PY
then
  green "PASS: record marks an unresolved-high synthesis not-clean (pct=0); medium ignored for cleanliness"
else
  red "FAIL: record unresolved-high shape wrong"
  errors=$((errors + 1))
fi

# --- 4. record picks the LATEST contradictor-vN.json ----------------------
# v2 is clean; with v1 (not-clean) still present, record must read v2.
cat > "$PROJ/.metadata/contradictor-v2.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "draft_version": 2,
  "synthesis_slug": "eu-ai-act-classification",
  "output_language": "en",
  "compared_against": {"sources": ["src-a"], "source_count": 1, "prior_syntheses": [], "prior_synthesis_count": 0, "missing_pages": []},
  "findings": [],
  "counts": {"contradiction": 0, "unknown": 0, "total": 0, "high": 0, "medium": 0, "low": 0}
}
JSON
python3 "$SCRIPT" record --project-path "$PROJ" --out "$OUT2" --output-language en >/dev/null
if python3 - "$OUT2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["syntheses"][0]["draft_version"] == 2, d["syntheses"]   # latest, not v1
assert d["consistency_rate"]["pct"] == 100.0, d["consistency_rate"]  # v2 has no findings -> clean
PY
then
  green "PASS: record reads the latest contradictor-vN.json (v2 over v1)"
else
  red "FAIL: record did not select the latest contradictor version"
  errors=$((errors + 1))
fi

# --- 5. record fail-soft on a missing contradictor file -------------------
EMPTY_PROJ="$WORK/empty"
mkdir -p "$EMPTY_PROJ/.metadata"
OUT3="$EMPTY_PROJ/.metadata/contradiction-finalize.json"
if python3 "$SCRIPT" record --project-path "$EMPTY_PROJ" --out "$OUT3" --output-language en >/dev/null; then
  if python3 - "$OUT3" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["consistency_rate"] == {"syntheses_total": 0, "syntheses_clean": 0, "pct": 0.0}, d["consistency_rate"]
assert d["syntheses"] == [], d["syntheses"]
PY
  then
    green "PASS: record is fail-soft on a missing contradictor (zeroed artifact, exit 0)"
  else
    red "FAIL: fail-soft artifact shape wrong"
    errors=$((errors + 1))
  fi
else
  red "FAIL: record exited non-zero on a missing contradictor (must be fail-soft)"
  errors=$((errors + 1))
fi

# --- 6. record idempotent -------------------------------------------------
python3 "$SCRIPT" record --project-path "$PROJ" --out "$OUT2" --output-language en >/dev/null
H1=$(python3 -c "import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$OUT2")
python3 "$SCRIPT" record --project-path "$PROJ" --out "$OUT2" --output-language en >/dev/null
H2=$(python3 -c "import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$OUT2")
if [ "$H1" = "$H2" ]; then
  green "PASS: record is idempotent (byte-identical re-record)"
else
  red "FAIL: record is not idempotent"
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
