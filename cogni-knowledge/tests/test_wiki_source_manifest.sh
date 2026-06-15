#!/usr/bin/env bash
# test_wiki_source_manifest.sh — functional test for the wiki-only compose
# manifest synthesizer (knowledge-compose --source wiki).
#
# Builds a tiny wiki + plan, runs `wiki-source-manifest.py build`, and asserts
# the synthesized ingest-manifest maps each source page to the right CURRENT
# plan sub-question (via the shared wiki-grounding primitive) and matches the
# ingested[] entry shape the wiki-composer reads. bash 3.2 + python3.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/wiki-source-manifest.py"
. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/wiki/sources" "$TMP/proj/.metadata"
printf -- '---\ntype: index\n---\n# Index\n' > "$TMP/wiki/index.md"

cat > "$TMP/wiki/sources/eu-ai-act-high-risk.md" <<'EOF'
---
type: source
id: eu-ai-act-high-risk
title: "EU AI Act high-risk classification under Article 6"
publisher: "EUR-Lex"
sources: ["https://eur-lex.europa.eu/eli/reg/2024/1689"]
pre_extracted_claims:
  - id: clm-001
    text: "Article 6 classifies an AI system as high-risk when it is a safety component of a regulated product."
    excerpt_quote: "high-risk"
    excerpt_position: "1"
    sub_question_refs: ["sq-99"]
---
Body about high-risk AI system classification and Article 6.
EOF

cat > "$TMP/wiki/sources/gdpr-profiling.md" <<'EOF'
---
type: source
id: gdpr-profiling
title: "GDPR profiling safeguards and automated decisions"
publisher: "EUR-Lex"
sources: ["https://eur-lex.europa.eu/eli/reg/2016/679"]
pre_extracted_claims:
  - id: clm-010
    text: "Profiling of natural persons under GDPR Article 22 requires safeguards for automated decisions."
    excerpt_quote: "profiling"
    excerpt_position: "1"
    sub_question_refs: ["sq-50"]
---
Body about GDPR profiling and automated decision safeguards.
EOF

cat > "$TMP/proj/.metadata/plan.json" <<'EOF'
{ "schema_version": "0.1.1",
  "sub_questions": [
    {"id": "sq-01", "query": "How does the EU AI Act classify high-risk AI systems under Article 6?", "theme_label": "AI Act high-risk classification"},
    {"id": "sq-02", "query": "What GDPR profiling safeguards apply to automated decisions under Article 22?", "theme_label": "GDPR profiling safeguards"}
  ]
}
EOF

OUT="$TMP/proj/.metadata/ingest-manifest.json"
python3 "$SCRIPT" build --wiki-root "$TMP" --plan "$TMP/proj/.metadata/plan.json" --out "$OUT" > "$TMP/envelope.json" 2>"$TMP/err.txt" || true

# 1. Envelope success + correct counts.
if python3 - "$TMP/envelope.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1]))
assert env["success"] is True, env
d = env["data"]
assert d["ingested_count"] == 2, d
assert d["source_pages_scanned"] == 2, d
PY
then green "PASS: wiki-source-manifest: build succeeds, 2 sources ingested"
else red "FAIL: wiki-source-manifest: build envelope wrong"; errors=$((errors + 1)); cat "$TMP/err.txt"; fi

# 2. Manifest shape + per-source sub-question mapping is correct.
if python3 - "$OUT" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
assert m["schema_version"] == "0.1.0", m
assert m["source_mode"] == "wiki", m
assert m["skipped"] == [], m
by_slug = {e["slug"]: e for e in m["ingested"]}
ai = by_slug["eu-ai-act-high-risk"]
gd = by_slug["gdpr-profiling"]
# Each source maps to the CURRENT plan sub-question it covers, NOT the page's
# own stale sub_question_refs (sq-99 / sq-50 from another project).
assert ai["sub_question_refs"] == ["sq-01"], ai
assert gd["sub_question_refs"] == ["sq-02"], gd
# Entry carries the shape the wiki-composer reads.
for e in (ai, gd):
    for k in ("url", "slug", "title", "publisher", "summary", "claims_extracted", "sub_question_refs"):
        assert k in e, (k, e)
    assert e["url"].startswith("https://"), e
    assert e["claims_extracted"] == 1, e
PY
then green "PASS: wiki-source-manifest: maps each source to the current plan sub-question, correct ingested[] shape"
else red "FAIL: wiki-source-manifest: manifest shape/mapping wrong"; errors=$((errors + 1)); fi

# 3. A plan whose sub-questions cover no source page yields ingested_count 0.
cat > "$TMP/proj/.metadata/plan-novel.json" <<'EOF'
{ "schema_version": "0.1.1",
  "sub_questions": [
    {"id": "sq-01", "query": "What are the maritime cabotage tariffs for container shipping in Patagonia?", "theme_label": "maritime cabotage tariffs"}
  ]
}
EOF
python3 "$SCRIPT" build --wiki-root "$TMP" --plan "$TMP/proj/.metadata/plan-novel.json" --out "$TMP/proj/.metadata/m2.json" > "$TMP/env2.json" 2>/dev/null || true
if python3 - "$TMP/env2.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1]))
assert env["success"] is True, env
assert env["data"]["ingested_count"] == 0, env["data"]
PY
then green "PASS: wiki-source-manifest: a novel plan covering no source yields ingested_count 0 (caller abort signal)"
else red "FAIL: wiki-source-manifest: novel-plan empty-result path wrong"; errors=$((errors + 1)); fi

# 4. Error path: bad threshold rejected.
if python3 "$SCRIPT" build --wiki-root "$TMP" --plan "$TMP/proj/.metadata/plan.json" --out "$TMP/x.json" --threshold 0 \
     | python3 -c "import json,sys; assert json.load(sys.stdin)['success'] is False" 2>/dev/null
then green "PASS: wiki-source-manifest: rejects --threshold 0"
else red "FAIL: wiki-source-manifest: did not reject --threshold 0"; errors=$((errors + 1)); fi

# 5. Interview pages are source-class: an interview note covering a current plan
#    sub-question is mapped into the synthesized ingested[] (the wiki read-side
#    first-class interview policy — importer passes include_interviews=True and
#    admits type=='interview' in the source-filter).
mkdir -p "$TMP/wiki/interviews"
cat > "$TMP/wiki/interviews/expert-ai-act-interview.md" <<'EOF'
---
type: interview
id: expert-ai-act-interview
title: "Expert interview on EU AI Act high-risk classification"
publisher: "Internal interview"
sources: ["file:///interviews/expert-ai-act.md"]
pre_extracted_claims:
  - id: clm-100
    text: "The interviewee confirmed Article 6 high-risk classification hinges on the AI system being a safety component of a regulated product."
    excerpt_quote: "high-risk"
    excerpt_position: "1"
    sub_question_refs: ["sq-77"]
---
Interview transcript on high-risk AI system classification under Article 6.
EOF
python3 "$SCRIPT" build --wiki-root "$TMP" --plan "$TMP/proj/.metadata/plan.json" --out "$TMP/proj/.metadata/m3.json" > "$TMP/env3.json" 2>/dev/null || true
if python3 - "$TMP/env3.json" "$TMP/proj/.metadata/m3.json" <<'PY'
import json, sys
env = json.load(open(sys.argv[1]))
m = json.load(open(sys.argv[2]))
assert env["success"] is True, env
# 2 sources + 1 interview now scanned and mapped.
assert env["data"]["source_pages_scanned"] == 3, env["data"]
assert env["data"]["ingested_count"] == 3, env["data"]
by_slug = {e["slug"]: e for e in m["ingested"]}
assert "expert-ai-act-interview" in by_slug, by_slug
iv = by_slug["expert-ai-act-interview"]
# Interview maps to the CURRENT AI Act sub-question, carries the source shape.
assert iv["sub_question_refs"] == ["sq-01"], iv
assert iv["url"].startswith("file://"), iv
assert iv["claims_extracted"] == 1, iv
PY
then green "PASS: wiki-source-manifest: an interview page is mapped into ingested[] (source-class read-side)"
else red "FAIL: wiki-source-manifest: interview page not treated as source-class"; errors=$((errors + 1)); fi

if [ "$errors" -eq 0 ]; then
  green "ALL PASS"
  exit 0
else
  red "FAILED: $errors assertion(s)"
  exit 1
fi
