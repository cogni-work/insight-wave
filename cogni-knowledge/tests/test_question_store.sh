#!/usr/bin/env bash
# test_question_store.sh — functional test for scripts/question-store.py
# (the #407 knowledge-ingest Step 4.5 engine that emits per-sub-question
# `type: question` wiki nodes). Executes the real code path against a
# synthetic wiki + plan.json + candidates.json + ingest-manifest.json.
#
# Covers:
#   1. One wiki/questions/<slug>.md per sub-question that has ≥1 finding;
#      slug derived from theme_label via _knowledge_lib.slugify (transliterated).
#   2. Forward links: ## Findings lists - [[<source-slug>]] for each answering
#      source; sources_answering[] frontmatter matches.
#   3. A sub-question with zero findings writes NO page (skipped_no_findings[]).
#   4. Idempotent re-run: merges in place (action=merged), preserves a human
#      ## Notes tail, unions findings, no duplicate pages.
#   5. Cross-type slug collision (a source page already owns the theme slug)
#      disambiguates with a -q suffix rather than shadowing the source page.
#   6. Legacy plan with no theme_label falls back to the sq-NN slug.
#   7. Within-run collision: two DISTINCT sub-questions whose theme_label
#      slugifies identically split into two -q-disambiguated nodes (own
#      sub_question_id + findings) rather than conflating onto the last writer.
#   8. wiki/questions/ is created on demand by the first emit (not pre-made).
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/question-store.py"
WSD="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -d "$WSD" ]; then
  red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD"
  exit 1
fi

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

WIKI="$WORK/wiki-root"
PROJ="$WORK/project"
# NB: wiki/questions/ is deliberately NOT pre-created — the first emit must
# mkdir it on demand (atomic_write_text -> path.parent.mkdir), asserted below.
mkdir -p "$WIKI/wiki/sources" "$WIKI/.cogni-wiki" "$PROJ/.metadata"
echo '{"schema_version":"0.0.7","entries_count":0}' > "$WIKI/.cogni-wiki/config.json"

# --- synthetic findings on disk (the Step 3/4 source pages) ----------------
for s in records-scope controller-obligations risk-classes; do
  cat > "$WIKI/wiki/sources/$s.md" <<EOF
---
id: $s
title: $s
type: source
created: 2026-01-01
updated: 2026-01-01
---

Body for $s, long enough to clear the stub threshold for any later health run.
EOF
done

# --- plan.json: 3 sub-questions; sq-03 has a German theme_label (für->fuer),
#     sq-02 will end up with no findings ---------------------------------------
cat > "$PROJ/.metadata/plan.json" <<'EOF'
{
  "sub_questions": [
    {"id": "sq-01", "query": "What is the scope of records of processing?",
     "search_guidance": "regulatory text", "theme_label": "Records of Processing Scope",
     "candidate_domains": ["europa.eu", "bfdi.bund.de"]},
    {"id": "sq-02", "query": "How do court rulings interpret it?",
     "search_guidance": "case law", "theme_label": "Court Interpretation",
     "candidate_domains": ["eur-lex.europa.eu"]},
    {"id": "sq-03", "query": "Welche Pflichten gelten für Risikoklassen?",
     "search_guidance": "Gesetzestext", "theme_label": "Pflichten für Risikoklassen",
     "candidate_domains": ["artificialintelligenceact.eu"]}
  ]
}
EOF

# --- candidates.json: URL -> sub_question_refs --------------------------------
cat > "$PROJ/.metadata/candidates.json" <<'EOF'
{
  "schema_version": "0.1.0",
  "candidates": [
    {"url": "https://europa.eu/records", "sub_question_refs": ["sq-01"]},
    {"url": "https://bfdi.bund.de/obligations", "sub_question_refs": ["sq-01", "sq-03"]},
    {"url": "https://aia.eu/risk", "sub_question_refs": ["sq-03"]}
  ]
}
EOF

# --- ingest-manifest.json: URL -> slug ---------------------------------------
cat > "$PROJ/.metadata/ingest-manifest.json" <<'EOF'
{
  "schema_version": "0.1.0",
  "ingested": [
    {"url": "https://europa.eu/records", "slug": "records-scope"},
    {"url": "https://bfdi.bund.de/obligations", "slug": "controller-obligations"},
    {"url": "https://aia.eu/risk", "slug": "risk-classes"}
  ],
  "skipped": []
}
EOF

emit() {
  python3 "$SCRIPT" emit \
    --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
    --plan "$PROJ/.metadata/plan.json" \
    --candidates "$PROJ/.metadata/candidates.json" \
    --ingest-manifest "$PROJ/.metadata/ingest-manifest.json"
}

# ===== Run 1 =================================================================
OUT="$(emit)"
echo "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] else 1)' \
  && green "PASS: emit returns success" || { red "FAIL: emit not success"; echo "$OUT"; errors=$((errors+1)); }

# 0) questions/ was created on demand by the first emit (not pre-made above).
[ -d "$WIKI/wiki/questions" ] \
  && green "PASS: wiki/questions/ created on demand by first emit" \
  || { red "FAIL: wiki/questions/ not created on demand"; errors=$((errors+1)); }

# 1) sq-01 + sq-03 pages exist; sq-02 (no findings) does not.
SQ1="$WIKI/wiki/questions/records-of-processing-scope.md"
SQ3="$WIKI/wiki/questions/pflichten-fuer-risikoklassen.md"
[ -f "$SQ1" ] && green "PASS: sq-01 question page written at slugified theme_label" \
  || { red "FAIL: missing $SQ1"; errors=$((errors+1)); }
[ -f "$SQ3" ] && green "PASS: sq-03 page uses transliterated slug (für->fuer)" \
  || { red "FAIL: missing $SQ3"; errors=$((errors+1)); }
[ ! -f "$WIKI/wiki/questions/court-interpretation.md" ] \
  && green "PASS: sq-02 (zero findings) wrote no page" \
  || { red "FAIL: sq-02 page should not exist"; errors=$((errors+1)); }

echo "$OUT" | grep -q '"sq-02"' && green "PASS: sq-02 reported in skipped_no_findings" \
  || { red "FAIL: sq-02 not in skipped_no_findings"; errors=$((errors+1)); }

# 2) forward links + frontmatter
assert_grep 'type: question' "$SQ1" "sq-01 page is type: question"
assert_grep 'sub_question_id: sq-01' "$SQ1" "sq-01 page carries sub_question_id"
assert_grep '## Findings' "$SQ1" "sq-01 page has ## Findings section"
# sq-01 is answered by records-scope (sq-01 ref) AND controller-obligations (sq-01+sq-03 ref)
assert_grep '\[\[records-scope\]\]' "$SQ1" "sq-01 Findings links its source finding"
assert_grep 'sources_answering: \[records-scope, controller-obligations\]' "$SQ1" "sq-01 sources_answering lists both findings in order"
# sq-03 has two findings (controller-obligations via sq-03 ref + risk-classes)
assert_grep '\[\[controller-obligations\]\]' "$SQ3" "sq-03 links shared finding controller-obligations"
assert_grep '\[\[risk-classes\]\]' "$SQ3" "sq-03 links risk-classes finding"

# ===== Idempotency: add a human ## Notes tail, re-run ========================
printf '\n## Notes\n\nHuman annotation that must survive a re-run.\n' >> "$SQ1"
OUT2="$(emit)"
echo "$OUT2" | grep -q '"action": "merged"' && green "PASS: re-run reports action=merged" \
  || { red "FAIL: re-run did not merge"; echo "$OUT2"; errors=$((errors+1)); }
assert_grep 'Human annotation that must survive' "$SQ1" "## Notes tail preserved across re-run"
# exactly one page per slug (no duplication)
N=$(ls "$WIKI/wiki/questions/" | wc -l | tr -d ' ')
[ "$N" = "2" ] && green "PASS: still exactly 2 question pages after re-run" \
  || { red "FAIL: expected 2 question pages, found $N"; errors=$((errors+1)); }

# ===== Cross-type collision: a source page owns 'court-interpretation' =======
# Give sq-02 a finding so it would now want the slug, but plant a same-slug source first.
cat > "$WIKI/wiki/sources/court-interpretation.md" <<'EOF'
---
id: court-interpretation
title: pre-existing source
type: source
created: 2026-01-01
updated: 2026-01-01
---
A pre-existing non-question page that owns the court-interpretation slug.
EOF
cat > "$PROJ/.metadata/candidates.json" <<'EOF'
{"schema_version":"0.1.0","candidates":[
  {"url":"https://europa.eu/records","sub_question_refs":["sq-01"]},
  {"url":"https://bfdi.bund.de/obligations","sub_question_refs":["sq-01","sq-03"]},
  {"url":"https://aia.eu/risk","sub_question_refs":["sq-03","sq-02"]}
]}
EOF
OUT3="$(emit)"
[ -f "$WIKI/wiki/questions/court-interpretation-q.md" ] \
  && green "PASS: cross-type collision disambiguated to court-interpretation-q" \
  || { red "FAIL: expected court-interpretation-q.md"; echo "$OUT3"; errors=$((errors+1)); }
assert_grep 'type: source' "$WIKI/wiki/sources/court-interpretation.md" \
  "pre-existing source page left untouched (still type: source)"
[ ! -f "$WIKI/wiki/questions/court-interpretation.md" ] \
  && green "PASS: did not write a question at the colliding bare slug" \
  || { red "FAIL: question shadowed the source slug"; errors=$((errors+1)); }

# ===== Within-run collision: two DISTINCT sub-questions, identical slug ======
# Two sub-questions whose theme_label slugifies to the same base must NOT
# conflate into one node — the second disambiguates with -q and keeps its own
# sub_question_id + findings (regression guard for the same-run merge bug).
cat > "$PROJ/.metadata/plan.json" <<'EOF'
{"sub_questions":[
  {"id":"sq-31","query":"Retention under Art 5?","search_guidance":"x","theme_label":"Data Retention","candidate_domains":["europa.eu"]},
  {"id":"sq-32","query":"Retention under sector rules?","search_guidance":"x","theme_label":"Data Retention","candidate_domains":["bfdi.bund.de"]}
]}
EOF
cat > "$PROJ/.metadata/candidates.json" <<'EOF'
{"schema_version":"0.1.0","candidates":[
  {"url":"https://europa.eu/retain-a","sub_question_refs":["sq-31"]},
  {"url":"https://europa.eu/retain-b","sub_question_refs":["sq-32"]}
]}
EOF
cat > "$PROJ/.metadata/ingest-manifest.json" <<'EOF'
{"schema_version":"0.1.0","ingested":[
  {"url":"https://europa.eu/retain-a","slug":"retain-a"},
  {"url":"https://europa.eu/retain-b","slug":"retain-b"}
],"skipped":[]}
EOF
OUTC="$(emit)"
DR1="$WIKI/wiki/questions/data-retention.md"
DR2="$WIKI/wiki/questions/data-retention-q.md"
{ [ -f "$DR1" ] && [ -f "$DR2" ]; } \
  && green "PASS: two same-slug sub-questions wrote two distinct pages (-q disambiguation)" \
  || { red "FAIL: within-run collision did not split into two pages"; echo "$OUTC"; errors=$((errors+1)); }
# Distinct sub_question_ids, not conflated onto the last writer.
DR1ID="$(grep '^sub_question_id:' "$DR1" | awk '{print $2}')"
DR2ID="$(grep '^sub_question_id:' "$DR2" | awk '{print $2}')"
[ "$DR1ID" != "$DR2ID" ] \
  && green "PASS: each page kept its own sub_question_id ($DR1ID / $DR2ID)" \
  || { red "FAIL: sub_question_id conflated ($DR1ID == $DR2ID)"; errors=$((errors+1)); }
# No finding bleed: the base page links only its own source, not both.
if grep -q '\[\[retain-a\]\]' "$DR1" && ! grep -q '\[\[retain-b\]\]' "$DR1"; then
  green "PASS: base page lists only its own finding (no finding conflation)"
else
  red "FAIL: findings conflated across the two same-slug sub-questions"; errors=$((errors+1))
fi

# ===== Legacy plan: no theme_label -> sq-NN slug fallback ====================
cat > "$PROJ/.metadata/plan.json" <<'EOF'
{"sub_questions":[{"id":"sq-09","query":"Legacy plan question?","search_guidance":"x"}]}
EOF
cat > "$PROJ/.metadata/candidates.json" <<'EOF'
{"schema_version":"0.1.0","candidates":[{"url":"https://europa.eu/records","sub_question_refs":["sq-09"]}]}
EOF
cat > "$PROJ/.metadata/ingest-manifest.json" <<'EOF'
{"schema_version":"0.1.0","ingested":[{"url":"https://europa.eu/records","slug":"records-scope"}],"skipped":[]}
EOF
OUT4="$(emit)"
[ -f "$WIKI/wiki/questions/sq-09.md" ] \
  && green "PASS: legacy plan (no theme_label) falls back to sq-NN slug" \
  || { red "FAIL: expected sq-09.md fallback"; echo "$OUT4"; errors=$((errors+1)); }

# ===== Lineage match (#409): variant theme_label routes to existing node ======
# A binding pre-seeded with a covered_theme whose theme_key == the norm key of
# "Records of Processing Scope" and question_slug == an EXISTING prior-run
# question page. A plan whose theme_label is a VARIANT ("Scope of Processing
# Records") must route to that same node (merge), NOT fork a second one — and
# emit theme_bindings[].action == lineage_reused. Backward compat: a run WITHOUT
# --binding stays byte-identical (slug-only accumulation).
LINKB="$WORK/kb-binding.json"
# Compute the canonical theme_key from the SSOT primitive (no hand-coding).
TKEY="$(python3 -c "import sys; sys.path.insert(0,'$PLUGIN_ROOT/scripts'); from _knowledge_lib import theme_norm_key; print(theme_norm_key('Records of Processing Scope'))")"
# A prior-run question node already on disk at the recorded slug.
LSLUG="records-of-processing-scope"
cat > "$WIKI/wiki/questions/$LSLUG.md" <<EOF
---
id: $LSLUG
title: "Original prior-run question?"
type: question
tags: [question]
created: 2025-12-01
updated: 2025-12-01
theme_label: "Records of Processing Scope"
sub_question_id: sq-prior
search_guidance: ""
candidate_domains: []
sources_answering: [records-scope]
---

## Findings

- [[records-scope]]

## Notes

Prior-run human note that must survive the lineage merge.
EOF
python3 - "$LINKB" "$TKEY" "$LSLUG" <<'PY'
import json, sys
path, tkey, qslug = sys.argv[1], sys.argv[2], sys.argv[3]
binding = {
    "knowledge_slug": "kb", "topic_lineage": {
        "covered_themes": [
            {"theme_key": tkey, "question_slug": qslug,
             "labels": ["Records of Processing Scope"],
             "first_seen": "2025-12-01", "last_seen": "2025-12-01"}
        ],
        "open_themes": []},
    "schema_version": "0.1.3",
}
json.dump(binding, open(path, "w"))
PY
# A plan with the VARIANT phrasing + a new finding (controller-obligations).
cat > "$PROJ/.metadata/plan.json" <<'EOF'
{"sub_questions":[
  {"id":"sq-77","query":"Scope of records of processing, revisited?","search_guidance":"x",
   "theme_label":"Scope of Processing Records","candidate_domains":["europa.eu"]}
]}
EOF
cat > "$PROJ/.metadata/candidates.json" <<'EOF'
{"schema_version":"0.1.0","candidates":[
  {"url":"https://bfdi.bund.de/obligations","sub_question_refs":["sq-77"]}
]}
EOF
cat > "$PROJ/.metadata/ingest-manifest.json" <<'EOF'
{"schema_version":"0.1.0","ingested":[
  {"url":"https://bfdi.bund.de/obligations","slug":"controller-obligations"}
],"skipped":[]}
EOF
OUTL="$(python3 "$SCRIPT" emit \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
  --plan "$PROJ/.metadata/plan.json" \
  --candidates "$PROJ/.metadata/candidates.json" \
  --ingest-manifest "$PROJ/.metadata/ingest-manifest.json" \
  --binding "$LINKB")"
# Routed to the EXISTING node (merge), did NOT create a scope-of-processing-records page.
echo "$OUTL" | grep -q '"action": "merged"' \
  && green "PASS: variant theme_label lineage-merged into the existing node (action=merged)" \
  || { red "FAIL: variant did not merge into the lineage node"; echo "$OUTL"; errors=$((errors+1)); }
[ ! -f "$WIKI/wiki/questions/scope-of-processing-records.md" ] \
  && green "PASS: did NOT fork a second node for the variant theme_label" \
  || { red "FAIL: variant forked a second question node"; errors=$((errors+1)); }
echo "$OUTL" | grep -q '"action": "lineage_reused"' \
  && green "PASS: theme_bindings[] records action=lineage_reused" \
  || { red "FAIL: no lineage_reused theme_binding emitted"; echo "$OUTL"; errors=$((errors+1)); }
# created: preserved; human ## Notes tail survived; new finding unioned in.
assert_grep 'created: 2025-12-01' "$WIKI/wiki/questions/$LSLUG.md" "lineage merge preserves created:"
assert_grep 'Prior-run human note that must survive' "$WIKI/wiki/questions/$LSLUG.md" "lineage merge preserves human ## Notes tail"
assert_grep '\[\[controller-obligations\]\]' "$WIKI/wiki/questions/$LSLUG.md" "lineage merge unions the new finding"

# ===== Fail-soft binding read error (#426): degrade to slug-only success ======
# A corrupt / unreadable --binding must NOT abort emit — lineage is an
# enhancement layer, so a binding read failure degrades to slug-only
# accumulation (empty map) and surfaces the reason as data.binding_skipped.
# Reuses the variant plan/candidates/manifest from the lineage block above
# (still produces >=1 question page routing into $LSLUG by slug).

# -- Corrupt-JSON arm (JSONDecodeError) --
printf 'not json{' > "$WORK/corrupt-binding.json"
OUTCB="$(python3 "$SCRIPT" emit \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
  --plan "$PROJ/.metadata/plan.json" \
  --candidates "$PROJ/.metadata/candidates.json" \
  --ingest-manifest "$PROJ/.metadata/ingest-manifest.json" \
  --binding "$WORK/corrupt-binding.json")"
echo "$OUTCB" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] and d["data"].get("binding_skipped") else 1)' \
  && green "PASS: corrupt --binding degrades to success + data.binding_skipped (no abort)" \
  || { red "FAIL: corrupt --binding did not fail-soft"; echo "$OUTCB"; errors=$((errors+1)); }
# No lineage map -> the variant theme_label falls back to slugify(theme_label)
# and writes its OWN node (it does NOT route into $LSLUG), proving the degrade
# to slug-only accumulation actually changed behavior vs the lineage case.
[ -f "$WIKI/wiki/questions/scope-of-processing-records.md" ] \
  && green "PASS: corrupt --binding ran slug-only (variant got its own slug node, no lineage routing)" \
  || { red "FAIL: corrupt --binding did not degrade to slug-only"; errors=$((errors+1)); }

# -- Unreadable-path arm (OSError) --
OUTMB="$(python3 "$SCRIPT" emit \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
  --plan "$PROJ/.metadata/plan.json" \
  --candidates "$PROJ/.metadata/candidates.json" \
  --ingest-manifest "$PROJ/.metadata/ingest-manifest.json" \
  --binding "$WORK/does-not-exist.json")"
echo "$OUTMB" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] and d["data"].get("binding_skipped") else 1)' \
  && green "PASS: missing --binding path degrades to success + data.binding_skipped (OSError arm)" \
  || { red "FAIL: missing --binding path did not fail-soft"; echo "$OUTMB"; errors=$((errors+1)); }

# ===== Fail-soft structurally-invalid binding (#428): valid JSON, wrong shape =
# A binding that PARSES as valid JSON but is the wrong shape for the lineage
# read (a JSON array/scalar, or a present-but-null topic_lineage) must ALSO
# degrade to slug-only accumulation + data.binding_skipped, not raise past the
# (OSError, JSONDecodeError) catch into the top-level guard (failure envelope).
# Uniform with the #426 read-error arms above. Reuses the same variant
# plan/candidates/manifest fixtures.

# -- JSON-array arm (binding.get(...) -> AttributeError pre-#428) --
printf '[]' > "$WORK/array-binding.json"
OUTAB="$(python3 "$SCRIPT" emit \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
  --plan "$PROJ/.metadata/plan.json" \
  --candidates "$PROJ/.metadata/candidates.json" \
  --ingest-manifest "$PROJ/.metadata/ingest-manifest.json" \
  --binding "$WORK/array-binding.json")"
echo "$OUTAB" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] and d["data"].get("binding_skipped") else 1)' \
  && green "PASS: JSON-array --binding degrades to success + data.binding_skipped (not-a-dict)" \
  || { red "FAIL: JSON-array --binding did not fail-soft"; echo "$OUTAB"; errors=$((errors+1)); }

# -- topic_lineage: null arm (None.get(...) -> AttributeError pre-#428; the {}
#    default only fires on an ABSENT key, so a present-but-null is unprotected) --
printf '{"topic_lineage": null}' > "$WORK/null-tl-binding.json"
OUTTL="$(python3 "$SCRIPT" emit \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
  --plan "$PROJ/.metadata/plan.json" \
  --candidates "$PROJ/.metadata/candidates.json" \
  --ingest-manifest "$PROJ/.metadata/ingest-manifest.json" \
  --binding "$WORK/null-tl-binding.json")"
echo "$OUTTL" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] and d["data"].get("binding_skipped") else 1)' \
  && green "PASS: topic_lineage:null --binding degrades to success + data.binding_skipped" \
  || { red "FAIL: topic_lineage:null --binding did not fail-soft"; echo "$OUTTL"; errors=$((errors+1)); }

# ===== Backward compat: emit WITHOUT --binding still works (slug-only) ========
OUTNB="$(python3 "$SCRIPT" emit \
  --wiki-root "$WIKI" --wiki-scripts-dir "$WSD" \
  --plan "$PROJ/.metadata/plan.json" \
  --candidates "$PROJ/.metadata/candidates.json" \
  --ingest-manifest "$PROJ/.metadata/ingest-manifest.json")"
echo "$OUTNB" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["success"] and "theme_bindings" in d["data"] else 1)' \
  && green "PASS: no-binding emit succeeds and still carries theme_bindings[] (back-compat)" \
  || { red "FAIL: no-binding emit broke"; echo "$OUTNB"; errors=$((errors+1)); }

if [ "$errors" -eq 0 ]; then
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) FAILED"
  exit 1
fi
