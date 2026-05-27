#!/usr/bin/env bash
# test_wiki_coverage_bilingual.sh — cross-lingual regression guard for
# scripts/wiki-coverage.py (#326).
#
# WHY THIS EXISTS: the #311 German bake-in (Run 2, 2026-05-27) proved the
# original symmetric-Jaccard scorer was a NO-OP on a German base — a
# deliberately-overlapping German plan scored ALL sub-questions `uncovered`, so
# read-before-web (P1.3, #309) never fired for any non-English market. #326
# rewrote the matcher (digit anchors, denylisted boilerplate, prefix-compound
# matching, directional weighted recall + an absolute floor). The live .alpha
# re-score is gitignored and not reproducible in CI, so THIS test is the
# committed proof that the scorer now fires correctly on German content.
#
# Fixtures mirror the real shape: source pages keep ENGLISH titles (as ingested)
# but carry GERMAN index one-liners + GERMAN pre_extracted_claims[].text — the
# exact configuration that defeated the old Jaccard matcher.
#
# Contract under test:
#   1. A German covering page is surfaced (penalties SQ -> the Art-99 page),
#      and an unrelated page is NOT (precision).
#   2. A lone article-number anchor alone clears the matched-weight floor.
#   3. An all-boilerplate sub-question stays `uncovered` (the denylist guard).
#   4. A genuinely-novel sub-question (Art 51/52, absent from the base) stays
#      `uncovered` — the floor preserves novelty, the whole point of the gate.
#   5. RANKING: the topically-correct Art-71 page outranks a generic oversight
#      page for the governance SQ (the old scorer surfaced the wrong pages on
#      top — #326 defect 5).
#   6. Compound false-positive guard: a SUFFIX (`managementsystem` inside
#      `risikomanagementsystem`) and a boilerplate-headed compound
#      (`managementsystem`/`datenerfassung`) do NOT spuriously match.
#   7. A one-page German base -> `partial` (exercises the middle branch).
#
# bash 3.2 + python3 stdlib only (no pytest, no pip). Matches tests/README.md.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/wiki-coverage.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

WIKI="$WORK/wiki"
mkdir -p "$WIKI/wiki/sources" "$WIKI/wiki/syntheses"

run_score() {  # run_score <wiki-root> <plan> [extra args...]
  python3 "$SCRIPT" score --wiki-root "$1" --plan "$2" "${@:3}"
}

run_score_ok() {  # run_score_ok <label> <wiki-root> <plan> [extra args...]
  local label="$1"; shift
  if ! OUT=$(run_score "$@"); then
    red "FAIL: $label — wiki-coverage.py exited non-zero on a VALID plan"
    errors=$((errors + 1))
    OUT='{}'
  fi
}

check() {  # check <description> <json-envelope>  (program via heredoc on stdin)
  local desc="$1" payload="$2"
  if RESULT=$(PAYLOAD="$payload" python3 2>&1) && [ "$RESULT" = "OK" ]; then
    green "PASS: $desc"
  else
    red "FAIL: $desc"
    red "  $RESULT"
    errors=$((errors + 1))
  fi
}

# --- German base: 3 source pages, English titles + German one-liners/claims ---

# Penalties (Art 99) — the page the penalties SQ must find.
cat > "$WIKI/wiki/sources/article-99-penalties.md" <<'MD'
---
id: article-99-penalties
title: "Article 99 Penalties — administrative fines under the EU AI Act"
type: source
tags: [source]
pre_extracted_claims:
  - id: c1
    text: "Artikel 99 regelt das dreistufige Bußgeldsystem der KI-Verordnung."
    excerpt_quote: "Article 99 establishes administrative fines."
  - id: c2
    text: "Der Bußgeldrahmen reicht bis zu 35 Millionen Euro oder sieben Prozent des Jahresumsatzes."
    excerpt_quote: "up to 35 million EUR."
  - id: c3
    text: "Sanktionen für verbotene Praktiken treffen Anbieter und Betreiber gleichermaßen."
    excerpt_quote: "Sanctions apply to providers."
---
# Article 99
body
MD

# Governance (Art 71).
cat > "$WIKI/wiki/sources/article-71-governance.md" <<'MD'
---
id: article-71-governance
title: "Article 71 — EU database for high-risk AI systems"
type: source
tags: [source]
pre_extracted_claims:
  - id: c1
    text: "Artikel 71 schafft eine EU-Datenbank für Hochrisiko-Systeme und regelt die Governance."
    excerpt_quote: "Article 71 sets up the EU database."
  - id: c2
    text: "Die Aufsichtsbehörde überwacht die Einhaltung der Governance-Pflichten."
    excerpt_quote: "The supervisory authority monitors compliance."
---
# Article 71
body
MD

# Human oversight (Art 14) — the generic page that must NOT outrank the others.
# Its claim mentions `Risikomanagementsystem` to exercise the suffix guard (#6).
cat > "$WIKI/wiki/sources/article-14-oversight.md" <<'MD'
---
id: article-14-oversight
title: "Article 14 Human oversight requirements"
type: source
tags: [source]
pre_extracted_claims:
  - id: c1
    text: "Hochrisiko-Systeme erfordern wirksame menschliche Aufsicht durch geschulte Personen."
    excerpt_quote: "human oversight."
  - id: c2
    text: "Das Risikomanagementsystem muss kontinuierlich betrieben werden."
    excerpt_quote: "risk management system."
---
# Article 14
body
MD

cat > "$WIKI/wiki/index.md" <<'MD'
# Index
## Categories
### Sanktionen
- [[article-99-penalties]] — Artikel 99 regelt das dreistufige Bußgeldsystem mit einem Bußgeldrahmen bis 35 Millionen Euro.
### Governance
- [[article-71-governance]] — Artikel 71 schafft die EU-Datenbank für Hochrisiko-Systeme und regelt die Governance-Aufsicht.
### Aufsicht
- [[article-14-oversight]] — Artikel 14 verlangt wirksame menschliche Aufsicht über Hochrisiko-Systeme.
MD

# A six-sub-question German plan exercising every branch.
cat > "$WORK/plan.json" <<'JSON'
{
  "schema_version": "0.1.0",
  "sub_questions": [
    {"id": "sq-penalties", "query": "Bußgelder und Sanktionen nach Artikel 99 der KI-Verordnung",
     "theme_label": "Sanktionen", "search_guidance": "Bußgeldrahmen und Sanktionen für Anbieter"},
    {"id": "sq-governance", "query": "Governance und Aufsichtsbehörde nach Artikel 71",
     "theme_label": "Governance", "search_guidance": "EU-Datenbank und Aufsicht"},
    {"id": "sq-gpai-novel", "query": "GPAI Definition und Schwellenwerte nach Artikel 51 und 52",
     "theme_label": "GPAI", "search_guidance": "Allzweck-KI-Modelle Definition"},
    {"id": "sq-boilerplate", "query": "KI-Verordnung Artikel System Hochrisiko EU Anbieter",
     "theme_label": "Verordnung", "search_guidance": "Verordnung System"},
    {"id": "sq-anchor", "query": "Übergangsfristen nach Artikel 71",
     "theme_label": "Fristen", "search_guidance": "Übergangsfristen"},
    {"id": "sq-falsepos", "query": "Managementsystem und Datenerfassung",
     "theme_label": "Verwaltung", "search_guidance": "Managementsystem Datenerfassung"}
  ]
}
JSON

run_score_ok "german-base" "$WIKI" "$WORK/plan.json"

# --- Case 1: German covering page surfaced; unrelated page excluded ----------
check "penalties SQ: Art-99 page surfaced (covered/partial), generic oversight page excluded" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
p = sq["sq-penalties"]
assert p["coverage_verdict"] in ("covered", "partial"), p["coverage_verdict"]
slugs = [c["slug"] for c in p["covered_pages"]]
assert slugs and slugs[0] == "article-99-penalties", slugs
# Precision: the unrelated human-oversight page must NOT cover the penalties SQ.
assert "article-14-oversight" not in slugs, slugs
print("OK")
PY

# --- Case 2: a lone article-number anchor clears the matched-weight floor ----
check "anchor SQ: a lone article-number anchor (71) alone is enough to cover the Art-71 page" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
a = sq["sq-anchor"]
assert a["coverage_verdict"] in ("covered", "partial"), a["coverage_verdict"]
gov = [c for c in a["covered_pages"] if c["slug"] == "article-71-governance"]
assert gov, [c["slug"] for c in a["covered_pages"]]
# The covering reason must be the numeric article anchor, not a content term.
assert any("anchor" in r and "71" in r for r in gov[0]["reasons"]), gov[0]["reasons"]
print("OK")
PY

# --- Case 3: an all-boilerplate sub-question stays uncovered ------------------
check "boilerplate SQ: a sub-question made only of denylisted terms -> uncovered" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-boilerplate"]["coverage_verdict"] == "uncovered", sq["sq-boilerplate"]
assert sq["sq-boilerplate"]["covered_pages"] == [], sq["sq-boilerplate"]["covered_pages"]
print("OK")
PY

# --- Case 4: a genuinely-novel sub-question stays uncovered (novelty kept) ----
check "novel GPAI SQ: Art 51/52 absent from the base -> uncovered (floor preserves novelty)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-gpai-novel"]["coverage_verdict"] == "uncovered", sq["sq-gpai-novel"]
print("OK")
PY

# --- Case 5: RANKING — the right page tops the governance SQ ------------------
check "governance SQ: Art-71 page ranks ABOVE the generic oversight page (defect-5 ranking fix)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
g = sq["sq-governance"]
assert g["coverage_verdict"] == "covered", g["coverage_verdict"]
slugs = [c["slug"] for c in g["covered_pages"]]
scores = [c["overlap_score"] for c in g["covered_pages"]]
assert slugs[0] == "article-71-governance", slugs
assert "article-14-oversight" in slugs, slugs
# The topically-correct page must score strictly higher than the generic one.
top = g["covered_pages"][0]["overlap_score"]
gen = [c["overlap_score"] for c in g["covered_pages"] if c["slug"] == "article-14-oversight"][0]
assert top > gen, (top, gen)
assert scores == sorted(scores, reverse=True), scores
print("OK")
PY

# --- Case 6: compound false-positive guard -----------------------------------
# `Managementsystem` must NOT suffix-match `Risikomanagementsystem` (prefix-only
# matching), and the boilerplate-headed compound must not slip through, so the
# SQ finds no real overlap and stays uncovered.
check "false-positive guard: a suffix/boilerplate-head compound does NOT spuriously cover" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
assert sq["sq-falsepos"]["coverage_verdict"] == "uncovered", sq["sq-falsepos"]
print("OK")
PY

# --- Case 7: one-page German base -> partial ---------------------------------
WIKI1="$WORK/wiki1"
mkdir -p "$WIKI1/wiki/sources" "$WIKI1/wiki/syntheses"
cat > "$WIKI1/wiki/sources/article-99-penalties.md" <<'MD'
---
id: article-99-penalties
title: "Article 99 Penalties — administrative fines"
type: source
tags: [source]
pre_extracted_claims:
  - id: c1
    text: "Artikel 99 regelt das dreistufige Bußgeldsystem der KI-Verordnung."
  - id: c2
    text: "Der Bußgeldrahmen reicht bis 35 Millionen Euro; Sanktionen treffen Anbieter."
---
# A99
MD
cat > "$WIKI1/wiki/index.md" <<'MD'
# Index
### Sanktionen
- [[article-99-penalties]] — Artikel 99 regelt das dreistufige Bußgeldsystem mit Bußgeldrahmen.
MD
run_score_ok "one-page-german" "$WIKI1" "$WORK/plan.json"
check "one-page German base: the penalties SQ is exactly 'partial' (single covering page)" "$OUT" <<'PY'
import os, json
d = json.loads(os.environ["PAYLOAD"])
sq = {s["sq_id"]: s for s in d["data"]["sub_questions"]}
p = sq["sq-penalties"]
assert p["coverage_verdict"] == "partial", p["coverage_verdict"]
assert len(p["covered_pages"]) == 1, p["covered_pages"]
print("OK")
PY

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi
green ""
green "wiki-coverage.py cross-lingual (German) contract all pass."
