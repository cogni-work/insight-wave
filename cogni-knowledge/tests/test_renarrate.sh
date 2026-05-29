#!/usr/bin/env bash
# test_renarrate.sh — smoke test for concept-store.py renarrate (Phase 4.5, #341).
#
# The renarrate subcommand swaps ONLY the `## Summary` machine block of an
# already-merged concept/entity page from the concept-summary-narrator's raw-text
# records, leaving every other block + the human ## Notes tail byte-identical.
#
# Asserts:
#   1. CHANGED: a records file with new prose replaces the SUMMARY inner, bumps
#      `updated:`, and leaves the ## Claims / ## Related / ## Sources blocks AND
#      the human ## Notes tail BYTE-IDENTICAL (only the summary region + the
#      frontmatter `updated:` scalar differ).
#   2. IDEMPOTENT: re-running the SAME records reports the slug `unchanged`, does
#      NOT write, and does NOT churn the `updated:` date.
#   3. NO-SENTINEL human page → skipped (reason: no_summary_sentinel), untouched.
#   4. MISSING page → skipped (reason: page_not_found).
#   5. Output validates as the {success, data{renarrated, unchanged, skipped}}
#      envelope.
#
# bash 3.2 + stdlib python3 only. Posix only (renarrate uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/concept-store.py"
WSD="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: concept-store.py not found at $SCRIPT"; exit 1
fi
if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD"; exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

WIKI="$WORK/wiki-root"
PROJ="$WORK/project"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/concepts" "$WIKI/wiki/entities" "$WIKI/.cogni-wiki" "$PROJ/.metadata"
echo '{"schema_version":"0.0.6","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"
for s in src-a src-b; do
  printf -- '---\nid: %s\ntype: source\n---\n# x\n' "$s" > "$WIKI/wiki/sources/$s.md"
done

field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

# Build a genuine concept page via merge (authentic structure + ## Notes region).
cat > "$PROJ/.metadata/rec.txt" <<'EOF'
- title: High-Risk Classification
  type: concept
  summary: Run-1 framing only.
  claim: src-a#clm-001 | Annex III lists eight categories of high-risk AI systems.
  claim: src-b#clm-002 | A system is high-risk when it is a safety component.
EOF
python3 "$SCRIPT" merge --records "$PROJ/.metadata/rec.txt" --wiki-root "$WIKI" \
  --project-path "$PROJ" --project-slug proj-1 --wiki-scripts-dir "$WSD" >/dev/null
PAGE="$WIKI/wiki/concepts/high-risk-classification.md"
[ -f "$PAGE" ] && green "PASS: setup — concept page merged" || { red "FAIL: setup page missing"; exit 1; }
# Pin a stale created/updated date so a bump is observable regardless of today.
python3 - "$PAGE" <<'PY'
import re,sys
p=sys.argv[1]; t=open(p,encoding="utf-8").read()
t=re.sub(r"(?m)^updated:.*$","updated: 2026-01-01",t,count=1)
open(p,"w",encoding="utf-8").write(t)
PY
cp "$PAGE" "$WORK/before.md"

# A hand-authored page with NO sentinels, and we won't create does-not-exist.
printf -- '---\nid: hand\ntitle: Hand\ntype: entity\n---\n\n# Hand\n\nHuman page body.\n' > "$WIKI/wiki/entities/hand.md"
cp "$WIKI/wiki/entities/hand.md" "$WORK/hand-before.md"

# --- renarrate records (changed prose for the concept; skips for the others) -
cat > "$PROJ/.metadata/renarrate-records.txt" <<'EOF'
- slug: high-risk-classification
  <<<SUMMARY
  High-risk classification turns on Annex III's eight system categories and
  the safety-component test. The merged evidence now frames both triggers.
  SUMMARY
- slug: hand
  <<<SUMMARY
  Should be skipped — no machine-owned summary block.
  SUMMARY
- slug: does-not-exist
  <<<SUMMARY
  Should be skipped — page not found.
  SUMMARY
EOF

# --- 1. CHANGED --------------------------------------------------------------
OUT=$(python3 "$SCRIPT" renarrate --records "$PROJ/.metadata/renarrate-records.txt" \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["success"]')" = "True" ] && green "PASS: renarrate envelope success" || { red "FAIL: renarrate not success"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["n_renarrated"]')" = "1" ] && green "PASS: 1 page renarrated" || { red "FAIL: n_renarrated != 1"; errors=$((errors+1)); }
[ "$(echo "$OUT" | field '["data"]["n_skipped"]')" = "2" ] && green "PASS: 2 pages skipped" || { red "FAIL: n_skipped != 2"; errors=$((errors+1)); }
grep -q "the safety-component test" "$PAGE" && green "PASS: new prose written into SUMMARY" || { red "FAIL: new prose missing"; errors=$((errors+1)); }
grep -q "updated: 2026-01-01" "$PAGE" && { red "FAIL: updated: not bumped"; errors=$((errors+1)); } || green "PASS: updated: bumped off the pinned date"

# Other machine blocks + ## Notes tail must be byte-identical. Compare the page
# with the SUMMARY block region and the frontmatter `updated:` scalar masked.
mask() {
  python3 - "$1" <<'PY'
import re,sys
t=open(sys.argv[1],encoding="utf-8").read()
t=re.sub(r"(?m)^updated:.*$","updated: <MASKED>",t,count=1)
t=re.sub(r"(<!-- MACHINE-OWNED:SUMMARY:START -->\r?\n).*?(\r?\n?<!-- MACHINE-OWNED:SUMMARY:END -->)",
         r"\1<MASKED>\2",t,flags=re.DOTALL)
sys.stdout.write(t)
PY
}
if diff <(mask "$WORK/before.md") <(mask "$PAGE") >/dev/null; then
  green "PASS: all non-SUMMARY bytes (claims/related/sources/notes/frontmatter) identical"
else
  red "FAIL: renarrate changed bytes outside the SUMMARY block"; errors=$((errors+1))
  diff <(mask "$WORK/before.md") <(mask "$PAGE") || true
fi
# Spot-check the human ## Notes region survived intact.
grep -q "human-owned and preserved" "$PAGE" && green "PASS: ## Notes human region intact" || { red "FAIL: ## Notes region lost"; errors=$((errors+1)); }

# --- 2. IDEMPOTENT -----------------------------------------------------------
cp "$PAGE" "$WORK/after1.md"
OUT=$(python3 "$SCRIPT" renarrate --records "$PROJ/.metadata/renarrate-records.txt" \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD")
[ "$(echo "$OUT" | field '["data"]["n_unchanged"]')" = "1" ] && green "PASS: re-run reports unchanged" || { red "FAIL: re-run not unchanged"; errors=$((errors+1)); }
if diff "$WORK/after1.md" "$PAGE" >/dev/null; then
  green "PASS: idempotent — byte-identical, no date churn"
else
  red "FAIL: idempotent re-narrate churned the page"; errors=$((errors+1))
fi

# --- 3 + 4. skips left targets untouched -------------------------------------
SKIP_REASONS=$(echo "$OUT" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(",".join(sorted(s["reason"] for s in d["data"]["skipped"])))')
echo "$SKIP_REASONS" | grep -q "no_summary_sentinel" && green "PASS: no-sentinel page → no_summary_sentinel" || { red "FAIL: missing no_summary_sentinel"; errors=$((errors+1)); }
echo "$SKIP_REASONS" | grep -q "page_not_found" && green "PASS: missing page → page_not_found" || { red "FAIL: missing page_not_found"; errors=$((errors+1)); }
if diff "$WORK/hand-before.md" "$WIKI/wiki/entities/hand.md" >/dev/null; then
  green "PASS: hand-authored page left untouched"
else
  red "FAIL: hand-authored page was modified"; errors=$((errors+1))
fi

# --- 5. records_not_found is a clean failure (fail-soft caller continues) ----
OUT=$(python3 "$SCRIPT" renarrate --records "$WORK/nope.txt" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" || true)
echo "$OUT" | grep -q "records_not_found" && green "PASS: missing records file → records_not_found error" || { red "FAIL: no records_not_found error"; errors=$((errors+1)); }

if [ "$errors" -eq 0 ]; then
  green ""
  green "concept-store.py renarrate: all pass."
  exit 0
else
  red "concept-store.py renarrate: $errors failure(s)."
  exit 1
fi
