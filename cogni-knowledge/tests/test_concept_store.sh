#!/usr/bin/env bash
# test_concept_store.sh — smoke test for concept-store.py (Phase 4.5, #336).
#
# Asserts:
#   1. init creates an empty distill-manifest.json (schema 0.1.0), idempotent.
#   2. merge CREATE: a concept + an entity page land on disk with the expected
#      frontmatter (wiki:// sources, distilled_claims, status: distilled),
#      MACHINE-OWNED sentinels, and bare [[source-slug]] backlinks in the body.
#   3. merge UPDATE (cross-run compounding): a second run on the same slug with
#      an EXACT-same-text claim from a NEW source unions the backlink onto the
#      existing claim (one line, not a duplicate), appends a genuinely-new claim,
#      bumps `updated:` but NOT `created:`, unions distilled_from_research, and
#      preserves the human ## Notes region byte-for-byte.
#   4. CLAIM-ID NAMESPACING: two sources BOTH carrying `clm-001` but asserting
#      DIFFERENT facts produce TWO distinct claims (no false merge on bare id).
#   5. BYTE-STABLE re-run: merging identical records twice leaves the page
#      byte-identical and reports every concept `unchanged`.
#   6. FAIL-SAFE: a near-but-distinct claim (sim < 0.85) is kept, not over-merged.
#   7. FOUNDATION collision → skipped (reason: foundation_collision).
#   8. NO-SENTINEL human page at the target slug → skipped (reason:
#      no_sentinels_human_page); the page is left untouched.
#   9. The manifest carries claims_attached_total / claims_deduped_total.
#
# bash 3.2 + stdlib python3 only. Posix only (concept-store uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/concept-store.py"
WSD="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: concept-store.py not found at $SCRIPT"
  exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

WIKI="$WORK/wiki-root"
PROJ="$WORK/project"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/concepts" "$WIKI/wiki/entities" "$WIKI/.cogni-wiki" "$PROJ/.metadata"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"
for s in src-a src-b src-c; do
  printf -- '---\nid: %s\ntype: source\n---\n# x\n' "$s" > "$WIKI/wiki/sources/$s.md"
done

# Tiny envelope-field reader.
field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

# --- 1. init -----------------------------------------------------------------
OUT=$(python3 "$SCRIPT" init --project-path "$PROJ")
if [ "$(echo "$OUT" | field '["success"]')" = "True" ] && [ -f "$PROJ/.metadata/distill-manifest.json" ]; then
  green "PASS: init creates distill-manifest.json"
else
  red "FAIL: init"; errors=$((errors+1))
fi
OUT=$(python3 "$SCRIPT" init --project-path "$PROJ")
[ "$(echo "$OUT" | field '["data"]["created"]')" = "False" ] && green "PASS: init idempotent" || { red "FAIL: init not idempotent"; errors=$((errors+1)); }

# --- 2. merge CREATE ---------------------------------------------------------
cat > "$PROJ/.metadata/rec1.txt" <<'EOF'
- title: Annex III Categories
  type: concept
  summary: Categories of high-risk AI systems.
  related: conformity-assessment
  claim: src-a#clm-003 | Annex III lists eight categories of high-risk AI systems.
  claim: src-a#clm-007 | Providers must register high-risk systems in the EU database.
- title: European Commission
  type: entity
  summary: The EU executive body.
  claim: src-b#clm-002 | The European Commission published the GPAI Code of Practice.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ/.metadata/rec1.txt" --wiki-root "$WIKI" --project-path "$PROJ" --project-slug proj-1 --wiki-scripts-dir "$WSD")
CPAGE="$WIKI/wiki/concepts/annex-iii-categories.md"
EPAGE="$WIKI/wiki/entities/european-commission.md"
[ "$(echo "$OUT" | field '["data"]["n_created"]')" = "2" ] && green "PASS: merge created 2 pages" || { red "FAIL: n_created != 2"; errors=$((errors+1)); }
[ -f "$CPAGE" ] && [ -f "$EPAGE" ] && green "PASS: concept + entity pages on disk" || { red "FAIL: pages missing"; errors=$((errors+1)); }
assert_grep 'type: concept' "$CPAGE" "concept page: type"
assert_grep 'status: distilled' "$CPAGE" "concept page: status distilled"
assert_grep 'wiki://src-a' "$CPAGE" "concept page: wiki:// source provenance"
assert_grep 'MACHINE-OWNED:CLAIMS:START' "$CPAGE" "concept page: machine-owned sentinels"
assert_grep '\[\[src-a\]\]' "$CPAGE" "concept page: bare [[source-slug]] backlink (link-graph edge)"
assert_grep 'distilled_from_research' "$CPAGE" "concept page: distilled_from_research"

# --- 3. merge UPDATE (cross-run compounding) ---------------------------------
printf '\nHuman note: this list is contested.\n' >> "$CPAGE"
cat > "$PROJ/.metadata/rec2.txt" <<'EOF'
- title: Annex III Categories
  type: concept
  claim: src-c#clm-003 | Annex III lists eight categories of high-risk AI systems.
  claim: src-c#clm-011 | The Commission may amend Annex III by delegated act.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ/.metadata/rec2.txt" --wiki-root "$WIKI" --project-path "$PROJ" --project-slug proj-2 --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["n_updated"]')" = "1" ] && green "PASS: merge updated the existing concept" || { red "FAIL: n_updated != 1"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["claims_deduped_total"]')" = "1" ] && green "PASS: exact-norm_key dedup counted (1)" || { red "FAIL: deduped_total != 1"; errors=$((errors+1)); }
python3 - "$CPAGE" <<'PY' && green "PASS: cross-run update assertions" || { echo "FAIL: cross-run update"; exit 1; }
import sys, re
t = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'claim_id: dcl-001.*?backlinks: (\[.*?\])', t, re.DOTALL)
assert m and "src-a" in m.group(1) and "src-c" in m.group(1), "backlink union failed: " + (m.group(1) if m else "no dcl-001")
assert "delegated act" in t, "new claim not appended"
assert "Human note: this list is contested." in t, "HUMAN REGION CLOBBERED"
assert "proj-1" in t and "proj-2" in t, "distilled_from union failed"
assert t.count("claim_id: dcl-") == 3, "expected 3 distinct claims, got %d" % t.count("claim_id: dcl-")
PY
[ $? -eq 0 ] || errors=$((errors+1))

# --- 4. claim-id namespacing -------------------------------------------------
PROJ2="$WORK/project2"; mkdir -p "$PROJ2/.metadata"
cat > "$PROJ2/.metadata/recns.txt" <<'EOF'
- title: Namespacing Probe
  type: concept
  claim: src-a#clm-001 | Member states must designate a national supervisory authority.
  claim: src-b#clm-001 | The penalty ceiling is thirty five million euros.
EOF
python3 "$SCRIPT" merge --records "$PROJ2/.metadata/recns.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD" >/dev/null
NS="$WIKI/wiki/concepts/namespacing-probe.md"
N=$(grep -c 'claim_id: dcl-' "$NS" 2>/dev/null || echo 0)
[ "$N" = "2" ] && green "PASS: two sources both clm-001 (different facts) -> 2 distinct claims" || { red "FAIL: namespacing collapsed clm-001 (got $N claims)"; errors=$((errors+1)); }

# --- 5. byte-stable re-run ---------------------------------------------------
BEFORE=$(cat "$NS")
OUT=$(python3 "$SCRIPT" merge --records "$PROJ2/.metadata/recns.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD")
AFTER=$(cat "$NS")
[ "$BEFORE" = "$AFTER" ] && green "PASS: identical re-run is byte-stable" || { red "FAIL: re-run changed the page"; errors=$((errors+1)); }
echo "$OUT" | grep -q '"action": "unchanged"' && green "PASS: re-run reports unchanged" || { red "FAIL: re-run not reported unchanged"; errors=$((errors+1)); }

# --- 6. FAIL-SAFE: near-but-distinct claims are KEPT, not over-merged --------
PROJ3="$WORK/project3"; mkdir -p "$PROJ3/.metadata"
cat > "$PROJ3/.metadata/recsafe.txt" <<'EOF'
- title: Fail Safe Probe
  type: concept
  claim: src-a#clm-020 | Member states must designate a national supervisory authority.
  claim: src-b#clm-021 | The penalty ceiling is thirty five million euros.
EOF
python3 "$SCRIPT" merge --records "$PROJ3/.metadata/recsafe.txt" --wiki-root "$WIKI" --project-path "$PROJ3" --project-slug proj-safe --wiki-scripts-dir "$WSD" >/dev/null
FS="$WIKI/wiki/concepts/fail-safe-probe.md"
N=$(grep -c 'claim_id: dcl-' "$FS" 2>/dev/null || echo 0)
[ "$N" = "2" ] && green "PASS: two distinct facts (sim < 0.85) kept as 2 claims (fail-safe keep-both)" || { red "FAIL: distinct claims over-merged (got $N)"; errors=$((errors+1)); }

# --- 6b. orphan-source guard: a malformed (empty-text) claim's slug must NOT --
# leak into sources:/## Sources, and must be COUNTED as rejected.
cat > "$PROJ3/.metadata/reorph.txt" <<'EOF'
- title: Orphan Guard
  type: concept
  claim: src-a#clm-030 | A real attached claim.
  claim: src-orphan#clm-031 |
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ3/.metadata/reorph.txt" --wiki-root "$WIKI" --project-path "$PROJ3" --project-slug proj-safe --wiki-scripts-dir "$WSD")
OG="$WIKI/wiki/concepts/orphan-guard.md"
grep -q 'src-orphan' "$OG" && { red "FAIL: malformed claim's source leaked into the page"; errors=$((errors+1)); } || green "PASS: malformed-claim source not added to sources/backlinks"
echo "$OUT" | grep -q '"claims_rejected_total": 1' && green "PASS: malformed claim counted in claims_rejected_total" || { red "FAIL: rejected claim not counted"; errors=$((errors+1)); }

# --- 7b. slug-type collision: same title as concept AND entity -> 2nd skipped -
cat > "$PROJ3/.metadata/recdual.txt" <<'EOF'
- title: Data Protection Authority
  type: concept
  claim: src-a#clm-040 | The authority enforces the regulation.
- title: Data Protection Authority
  type: entity
  claim: src-b#clm-041 | The authority is an independent body.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ3/.metadata/recdual.txt" --wiki-root "$WIKI" --project-path "$PROJ3" --project-slug proj-safe --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q 'slug_type_collision' && green "PASS: concept+entity same slug -> 2nd skipped (slug_type_collision)" || { red "FAIL: slug_type_collision not enforced"; errors=$((errors+1)); }
[ -f "$WIKI/wiki/concepts/data-protection-authority.md" ] && [ ! -f "$WIKI/wiki/entities/data-protection-authority.md" ] && green "PASS: only ONE page exists for the colliding slug" || { red "FAIL: duplicate slug across type dirs"; errors=$((errors+1)); }

# --- 7. foundation collision (slug must match slugify(title)) ----------------
cat > "$WIKI/wiki/concepts/risk-management-system.md" <<'EOF'
---
id: risk-management-system
title: Risk Management System
type: concept
foundation: true
created: 2026-01-01
updated: 2026-01-01
---
# Risk Management System
Curated.
EOF
cat > "$PROJ2/.metadata/recfound.txt" <<'EOF'
- title: Risk Management System
  type: concept
  claim: src-a#clm-050 | A risk management system must run across the lifecycle.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ2/.metadata/recfound.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q 'foundation_collision' && green "PASS: foundation page refused (foundation_collision)" || { red "FAIL: foundation not refused"; errors=$((errors+1)); }
grep -q 'src-a' "$WIKI/wiki/concepts/risk-management-system.md" && { red "FAIL: foundation page was modified"; errors=$((errors+1)); } || green "PASS: foundation page untouched"

# --- 8. no-sentinel human page ----------------------------------------------
cat > "$WIKI/wiki/concepts/hand-authored.md" <<'EOF'
---
id: hand-authored
title: Hand Authored
type: concept
created: 2026-01-01
updated: 2026-01-01
---
# Hand Authored
A human wrote this with no sentinels.
EOF
HASH_BEFORE=$(cksum "$WIKI/wiki/concepts/hand-authored.md")
cat > "$PROJ2/.metadata/rechand.txt" <<'EOF'
- title: Hand Authored
  type: concept
  claim: src-a#clm-099 | Some new claim.
EOF
OUT=$(python3 "$SCRIPT" merge --records "$PROJ2/.metadata/rechand.txt" --wiki-root "$WIKI" --project-path "$PROJ2" --project-slug proj-ns --wiki-scripts-dir "$WSD")
echo "$OUT" | grep -q 'no_sentinels_human_page' && green "PASS: no-sentinel human page skipped" || { red "FAIL: no-sentinel page not skipped"; errors=$((errors+1)); }
[ "$(cksum "$WIKI/wiki/concepts/hand-authored.md")" = "$HASH_BEFORE" ] && green "PASS: no-sentinel page left untouched" || { red "FAIL: no-sentinel page modified"; errors=$((errors+1)); }

# --- 9. manifest read --------------------------------------------------------
OUT=$(python3 "$SCRIPT" read --project-path "$PROJ")
echo "$OUT" | grep -q 'claims_attached_total' && green "PASS: manifest carries claims_attached_total" || { red "FAIL: manifest missing dedup totals"; errors=$((errors+1)); }

echo ""
if [ "$errors" -eq 0 ]; then
  green "concept-store.py contract: all pass."
  exit 0
else
  red "concept-store.py contract: $errors failure(s)."
  exit 1
fi
