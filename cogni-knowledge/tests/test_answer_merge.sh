#!/usr/bin/env bash
# test_answer_merge.sh — smoke test for question-store.py answer-merge (Phase 4.5
# Step 6.9, #432 — the citable answer surface for type:question nodes).
#
# Asserts:
#   1. CREATE: answer-merge splices an answer_claims: block (acl-NNN ids, backlinks +
#      source_claim_refs provenance) into an existing question node, bumps updated:,
#      and leaves the ## Findings block + the human ## Notes tail BYTE-FOR-BYTE intact.
#   2. BYTE-STABLE re-run: merging identical records twice leaves the page byte-identical
#      and reports the question `unchanged` (every incoming ref is already present).
#   3. CROSS-RUN compounding: a second run with a same-text claim from a NEW source unions
#      the backlink onto the existing claim (one line, not a duplicate → deduped), and a
#      genuinely-new claim appends as a fresh acl- id; provenance refs are never dropped.
#   4. FAIL-SAFE: a near-but-distinct claim (sim < 0.85) is kept, not over-merged.
#   5. TYPE guard: a non-question page at the slug → skipped (reason not_a_question_page),
#      page untouched.
#   6. FOUNDATION guard: a foundation:true question page → skipped (foundation_collision).
#   7. MALFORMED claim line (no claim_id) → counted in claims_rejected, not silently lost.
#
# bash 3.2 + stdlib python3 only. Posix only (answer-merge uses fcntl.flock via
# cogni-wiki's _wiki_lock).

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/question-store.py"
WSD="$PLUGIN_ROOT/../cogni-wiki/skills/wiki-ingest/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

if [ ! -f "$SCRIPT" ]; then red "FAIL: question-store.py not found at $SCRIPT"; exit 1; fi
if [ ! -d "$WSD" ]; then red "FAIL: cogni-wiki wiki-ingest scripts not found at $WSD"; exit 1; fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
errors=0

WIKI="$WORK/wiki-root"
PROJ="$WORK/project"
mkdir -p "$WIKI/wiki/questions" "$WIKI/wiki/sources" "$WIKI/.cogni-wiki" "$PROJ/.metadata"
echo '{"schema_version":"0.0.7","slug":"kb","entries_count":2}' > "$WIKI/.cogni-wiki/config.json"

field() { python3 -c 'import sys,json;d=json.load(sys.stdin);print(eval("d"+sys.argv[1]))' "$1"; }

# A question node exactly as question-store.py emit writes one.
write_q() {  # $1=slug  $2=type  $3=extra-fm-line
  cat > "$WIKI/wiki/questions/$1.md" <<EOF
---
id: $1
title: "What defines a high-risk AI system?"
type: $2
tags: [question]
created: 2026-05-01
updated: 2026-05-01
theme_label: "high risk"
sub_question_id: sq-01
search_guidance: "annex III"
candidate_domains: ["eur-lex.europa.eu"]
sources_answering: [src-a, src-b]
$3---

## Findings

- [[src-a]]
- [[src-b]]

## Notes

Human-owned note — keep verbatim.
EOF
}

# Helper: byte content of the body (everything after the FM close).
body_of() { python3 -c 'import re,sys;t=open(sys.argv[1],encoding="utf-8").read();m=re.match(r"^---.*?\n---[ \t]*\n",t,re.S);sys.stdout.write(t[m.end():])' "$1"; }

run() { python3 "$SCRIPT" answer-merge --records "$1" --wiki-root "$WIKI" --wiki-scripts-dir "$WSD"; }

# --- 1. CREATE ---------------------------------------------------------------
write_q q-hr question ""
BODY_BEFORE=$(body_of "$WIKI/wiki/questions/q-hr.md")
cat > "$PROJ/.metadata/rec1.txt" <<'EOF'
- question: q-hr
  answer_claim: src-a | clm-003 | Annex III lists eight categories of high-risk AI systems.
  answer_claim: src-b | clm-009 | High-risk systems must be registered in the EU database.
EOF
OUT=$(run "$PROJ/.metadata/rec1.txt")
PAGE=$(cat "$WIKI/wiki/questions/q-hr.md")
if [ "$(echo "$OUT" | field '["success"]')" = "True" ] \
   && [ "$(echo "$OUT" | field '["data"]["questions"][0]["action"]')" = "created_block" ] \
   && echo "$PAGE" | grep -q "answer_claims:" \
   && echo "$PAGE" | grep -q "claim_id: acl-001" \
   && echo "$PAGE" | grep -q "claim_id: acl-002" \
   && echo "$PAGE" | grep -q 'source_claim_refs: \["src-a#clm-003"\]' \
   && echo "$PAGE" | grep -q "updated: 2026-"; then
  green "PASS: CREATE — answer_claims: block spliced with acl ids + provenance"
else
  red "FAIL: CREATE"; echo "$OUT"; errors=$((errors+1))
fi
# Body (## Findings + ## Notes) byte-identical.
if [ "$(body_of "$WIKI/wiki/questions/q-hr.md")" = "$BODY_BEFORE" ]; then
  green "PASS: CREATE — ## Findings + ## Notes preserved byte-for-byte"
else
  red "FAIL: body changed on answer-merge"; errors=$((errors+1))
fi
# updated: bumped past created: 2026-05-01.
grep -q "^updated: 2026-05-01" "$WIKI/wiki/questions/q-hr.md" && { red "FAIL: updated not bumped"; errors=$((errors+1)); } || green "PASS: updated: bumped"

# --- 2. BYTE-STABLE re-run ---------------------------------------------------
SNAP=$(cat "$WIKI/wiki/questions/q-hr.md")
OUT=$(run "$PROJ/.metadata/rec1.txt")
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["action"]')" = "unchanged" ] \
   && [ "$(cat "$WIKI/wiki/questions/q-hr.md")" = "$SNAP" ]; then
  green "PASS: re-run is unchanged + byte-identical (idempotent)"
else
  red "FAIL: re-run not idempotent"; echo "$OUT"; errors=$((errors+1))
fi

# --- 3. CROSS-RUN compounding (provenance union + new claim) -----------------
cat > "$PROJ/.metadata/rec2.txt" <<'EOF'
- question: q-hr
  answer_claim: src-c | clm-050 | Annex III lists eight categories of high-risk AI systems.
  answer_claim: src-c | clm-051 | The AI Office oversees GPAI providers.
EOF
OUT=$(run "$PROJ/.metadata/rec2.txt")
PAGE=$(cat "$WIKI/wiki/questions/q-hr.md")
# acl-001 should now carry src-c in backlinks (union), acl-003 should be the new claim.
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["claims_deduped"]')" = "1" ] \
   && [ "$(echo "$OUT" | field '["data"]["questions"][0]["claims_new"]')" = "1" ] \
   && echo "$PAGE" | grep -q 'backlinks: \["src-a", "src-c"\]' \
   && echo "$PAGE" | grep -q "claim_id: acl-003"; then
  green "PASS: cross-run — same-text claim unions backlink (deduped=1), new claim appends acl-003"
else
  red "FAIL: cross-run compounding"; echo "$OUT"; echo "$PAGE" | grep -A1 backlinks; errors=$((errors+1))
fi
# No provenance ref dropped: src-a#clm-003 AND src-c#clm-050 both on acl-001.
echo "$PAGE" | grep -q 'source_claim_refs: \["src-a#clm-003", "src-c#clm-050"\]' \
  && green "PASS: cross-run — source_claim_refs unioned, none dropped" \
  || { red "FAIL: provenance ref dropped/altered"; echo "$PAGE" | grep source_claim_refs; errors=$((errors+1)); }

# --- 4. FAIL-SAFE: near-but-distinct claim kept, not over-merged -------------
write_q q-fs question ""
cat > "$PROJ/.metadata/recfs.txt" <<'EOF'
- question: q-fs
  answer_claim: src-a | clm-100 | The transition period is twenty-four months for high-risk systems.
  answer_claim: src-b | clm-101 | The transition period is twelve months for GPAI providers.
EOF
OUT=$(run "$PROJ/.metadata/recfs.txt")
# Two distinct facts (12 vs 24, GPAI vs high-risk) → two claims, neither merged.
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["claims_new"]')" = "2" ] \
   && [ "$(echo "$OUT" | field '["data"]["questions"][0]["claims_deduped"]')" = "0" ]; then
  green "PASS: fail-safe — near-but-distinct claims kept (2 new, 0 deduped)"
else
  red "FAIL: fail-safe over-merge"; echo "$OUT"; errors=$((errors+1))
fi

# --- 5. TYPE guard: non-question page at the slug → skipped ------------------
write_q q-notq source ""   # type: source, not question
SNAP=$(cat "$WIKI/wiki/questions/q-notq.md")
cat > "$PROJ/.metadata/recnq.txt" <<'EOF'
- question: q-notq
  answer_claim: src-a | clm-001 | A claim.
EOF
OUT=$(run "$PROJ/.metadata/recnq.txt")
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["action"]')" = "skipped" ] \
   && [ "$(echo "$OUT" | field '["data"]["questions"][0]["reason"]')" = "not_a_question_page" ] \
   && [ "$(cat "$WIKI/wiki/questions/q-notq.md")" = "$SNAP" ]; then
  green "PASS: type guard — non-question page skipped (not_a_question_page), untouched"
else
  red "FAIL: type guard"; echo "$OUT"; errors=$((errors+1))
fi

# --- 6. FOUNDATION guard -----------------------------------------------------
write_q q-found question "foundation: true"$'\n'
SNAP=$(cat "$WIKI/wiki/questions/q-found.md")
cat > "$PROJ/.metadata/recf.txt" <<'EOF'
- question: q-found
  answer_claim: src-a | clm-001 | A claim.
EOF
OUT=$(run "$PROJ/.metadata/recf.txt")
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["reason"]')" = "foundation_collision" ] \
   && [ "$(cat "$WIKI/wiki/questions/q-found.md")" = "$SNAP" ]; then
  green "PASS: foundation guard — foundation:true question skipped, untouched"
else
  red "FAIL: foundation guard"; echo "$OUT"; errors=$((errors+1))
fi

# --- 7. MALFORMED claim line counted, not lost -------------------------------
write_q q-mal question ""
cat > "$PROJ/.metadata/recmal.txt" <<'EOF'
- question: q-mal
  answer_claim: src-a | just text with no id
  answer_claim: src-a | clm-001 | A valid claim.
EOF
OUT=$(run "$PROJ/.metadata/recmal.txt")
if [ "$(echo "$OUT" | field '["data"]["claims_rejected_total"]')" = "1" ] \
   && [ "$(echo "$OUT" | field '["data"]["questions"][0]["claims_new"]')" = "1" ]; then
  green "PASS: malformed claim line counted in claims_rejected_total, valid claim kept"
else
  red "FAIL: malformed-claim accounting"; echo "$OUT"; errors=$((errors+1))
fi

# --- 8. EMPTY-then-NONEMPTY: no empty block persisted, no duplicate key -------
# A question whose distiller emitted NO answer_claim lines on one run, then real
# claims on a later run. Run 1 must NOT persist an `answer_claims: []` block (which
# would dodge the key-only regex and fork a SECOND top-level key on run 2's splice).
write_q q-empty question ""
cat > "$PROJ/.metadata/recempty.txt" <<'EOF'
- question: q-empty
EOF
OUT=$(run "$PROJ/.metadata/recempty.txt")
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["action"]')" = "unchanged" ] \
   && [ "$(echo "$OUT" | field '["data"]["questions"][0]["reason"]')" = "no_claims" ] \
   && ! grep -q "answer_claims" "$WIKI/wiki/questions/q-empty.md"; then
  green "PASS: zero-claim question stays framing-only (no empty answer_claims: [] block)"
else
  red "FAIL: empty answer_claims block was persisted"; echo "$OUT"; errors=$((errors+1))
fi
cat > "$PROJ/.metadata/recempty2.txt" <<'EOF'
- question: q-empty
  answer_claim: src-a | clm-001 | A real answer claim arrives on the second run.
EOF
OUT=$(run "$PROJ/.metadata/recempty2.txt")
# Exactly ONE top-level answer_claims key in the frontmatter (no duplicate fork).
N_KEYS=$(python3 -c 'import re,sys;t=open(sys.argv[1],encoding="utf-8").read();fm=re.match(r"^---\n(.*?)\n---",t,re.S).group(1);print(sum(1 for l in fm.splitlines() if l.startswith("answer_claims")))' "$WIKI/wiki/questions/q-empty.md")
if [ "$(echo "$OUT" | field '["data"]["questions"][0]["action"]')" = "created_block" ] && [ "$N_KEYS" = "1" ]; then
  green "PASS: later real claim creates exactly one answer_claims key (no duplicate-key fork)"
else
  red "FAIL: duplicate/again-empty answer_claims key (got $N_KEYS)"; echo "$OUT"; errors=$((errors+1))
fi

if [ $errors -gt 0 ]; then red "$errors case(s) failed."; exit 1; fi
green ""
green "All question-store.py answer-merge cases pass."
