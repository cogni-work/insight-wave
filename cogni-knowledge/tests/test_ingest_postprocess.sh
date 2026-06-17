#!/usr/bin/env bash
# test_ingest_postprocess.sh — contract + functional coverage for the first-party
# ingest post-processing orchestrator (scripts/knowledge-ingest-postprocess.py) and
# the knowledge-ingest SKILL.md surface that now calls it instead of the per-slug
# shell loop.
#
# Why this test exists: the orchestrator consolidates the model-managed
# wiki-integration loop (Steps 4.1–4.5.6, the LLM backlink *curation* and Step 4.6
# tripwire excepted) into one structured call to kill two real fragility footguns —
# the env-var-as-trailing-arg slug/summary interpolation and the mid-loop n_new /
# n_new_q counter drift. This is a fragility cleanup, NOT a perf change (the whole
# post-processing budget measured ~2.2s across 21 slugs; the dominant cost is the
# LLM backlink curation that stays in SKILL.md).
#
# Coverage:
#   Contract (grep) —
#     - the orchestrator script exists, is stdlib-only, exposes the documented CLI
#       flags, and shells out to the UNCHANGED vendored helpers (no acquire-once-
#       then-shell-out deadlock shape; each child takes _wiki_lock in its own
#       process), to question-store emit, sub_index render, and upsert-themes.
#     - knowledge-ingest/SKILL.md calls the orchestrator and no longer carries the
#       per-slug shell loop's env-var sanitize python3 -c block.
#   Functional (run) —
#     - structural error envelope on a missing ingest-manifest.json
#     - no-op path (empty new-slugs): success, n_new == 0, sub-indexes "unchanged"
#     - happy path (one new source slug): n_new == 1, the source filed under its
#       theme_label heading with a sanitized summary (dagger normalized), a question
#       node emitted + reverse-linked, entries_count bumped, both sub-indexes
#       rendered, question-manifest written.
#
# byte-identical wiki output vs the old loop is NOT asserted here (a grep/fixture
# test cannot run a real ingest) — that is a human pre-merge gate (one live
# knowledge-ingest on the branch vs main, diff wiki/). See the issue.
#
# bash 3.2 + grep + python3 stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

SCRIPT="$PLUGIN_ROOT/scripts/knowledge-ingest-postprocess.py"
INGEST="$PLUGIN_ROOT/skills/knowledge-ingest/SKILL.md"
VENDOR="scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts"

# === Contract: the orchestrator script ===================================
if [ ! -f "$SCRIPT" ]; then
  red "FAIL: scripts/knowledge-ingest-postprocess.py not found"
  exit 1
fi
assert_grep 'argparse' "$SCRIPT" "postprocess: stdlib argparse (no pip deps)"
assert_grep '--project-path' "$SCRIPT" "postprocess: --project-path flag"
assert_grep '--wiki-root' "$SCRIPT" "postprocess: --wiki-root flag"
assert_grep '--wiki-scripts-dir' "$SCRIPT" "postprocess: --wiki-scripts-dir flag"
assert_grep '--new-slugs' "$SCRIPT" "postprocess: --new-slugs structured input (no shell interpolation)"
assert_grep '--binding' "$SCRIPT" "postprocess: --binding flag (question-store emit + upsert-themes)"
assert_grep '--knowledge-root' "$SCRIPT" "postprocess: --knowledge-root flag (upsert-themes)"
assert_grep 'from _knowledge_lib import sanitize_summary' "$SCRIPT" "postprocess: sanitizes summaries via _knowledge_lib (no env-var python3 -c)"
assert_grep 'backlink_audit.py' "$SCRIPT" "postprocess: shells out to backlink_audit.py (unchanged vendored helper)"
assert_grep 'wiki_index_update.py' "$SCRIPT" "postprocess: shells out to wiki_index_update.py (unchanged vendored helper)"
assert_grep 'config_bump.py' "$SCRIPT" "postprocess: shells out to config_bump.py (unchanged vendored helper)"
assert_grep 'question-store.py' "$SCRIPT" "postprocess: shells out to question-store.py emit"
assert_grep 'sub_index.py' "$SCRIPT" "postprocess: shells out to sub_index.py render"
assert_grep 'knowledge-binding.py' "$SCRIPT" "postprocess: shells out to knowledge-binding.py upsert-themes"
assert_grep 'entries_count' "$SCRIPT" "postprocess: bumps entries_count"
assert_grep 'inserted' "$SCRIPT" "postprocess: counts n_new/n_new_q on action == inserted (drift fix in one place)"
assert_grep 'max-summary' "$SCRIPT" "postprocess: passes --max-summary clamp (byte-identical arg)"
assert_grep 'create-missing-heading' "$SCRIPT" "postprocess: R1 reverse link uses --create-missing-heading"
assert_grep 'question-manifest.json' "$SCRIPT" "postprocess: persists question-manifest.json handoff"
# No acquire-once-then-shell-out deadlock shape: the orchestrator must NOT take the
# wiki lock itself — each shelled child takes _wiki_lock in its own process.
assert_not_grep '_wiki_lock(' "$SCRIPT" "postprocess: does NOT acquire _wiki_lock itself (no deadlock shape)"
assert_not_grep 'import requests' "$SCRIPT" "postprocess: stdlib only (no requests)"

# === Contract: knowledge-ingest SKILL.md =================================
if [ ! -f "$INGEST" ]; then
  red "FAIL: skills/knowledge-ingest/SKILL.md not found"
  exit 1
fi
assert_grep 'knowledge-ingest-postprocess.py' "$INGEST" "SKILL: Step 4 calls the orchestrator script"
assert_grep '--new-slugs' "$INGEST" "SKILL: passes the this-run slug list as structured input"
# The LLM backlink audit + curation middle step STAYS in SKILL.md.
assert_grep 'backlink_audit.py' "$INGEST" "SKILL: keeps the per-slug backlink audit (LLM-curated middle step)"
assert_grep '.backlink-plan' "$INGEST" "SKILL: writes per-slug curated backlink plan files the orchestrator applies"
# Step 4.6 contradiction tripwire stays in SKILL.md (agent dispatch).
assert_grep 'source-contradictor' "$INGEST" "SKILL: keeps the Step 4.6 contradiction tripwire (agent dispatch)"

# === Functional: error envelope on missing manifest =====================
ERR_OUT="$(cd "$PLUGIN_ROOT" && python3 scripts/knowledge-ingest-postprocess.py \
  --project-path /tmp/iw-no-such-proj-$$ --wiki-root /tmp/iw-no-wiki-$$ \
  --wiki-scripts-dir "$VENDOR" --new-slugs - <<< '[]' || true)"
if printf '%s' "$ERR_OUT" | python3 -c "import json,sys;d=json.load(sys.stdin);sys.exit(0 if (d['success'] is False and 'ingest-manifest' in (d['error'] or '')) else 1)" 2>/dev/null; then
  green "PASS: postprocess: structural error envelope on missing ingest-manifest.json"
else
  red "FAIL: postprocess: expected success=false + ingest-manifest error; got: $ERR_OUT"
  errors=$((errors + 1))
fi

# === Functional: no-op + happy path against a minimal wiki ==============
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
WIKI="$TMP/wiki"; PROJ="$TMP/proj"
mkdir -p "$WIKI/.cogni-wiki" "$WIKI/wiki/sources" "$WIKI/wiki/questions" "$PROJ/.metadata"
echo '{"schema_version":"0.0.9","entries_count":0,"title":"t"}' > "$WIKI/.cogni-wiki/config.json"
printf '# Knowledge Portal\n\n## Categories\n\n_No pages yet…_\n' > "$WIKI/wiki/index.md"
echo '{"topic":"t","output_language":"en","sub_questions":[{"id":"sq-01","query":"What is X?","theme_label":"Theme One"}]}' > "$PROJ/.metadata/plan.json"
echo '{"candidates":[{"url":"https://example.org/x","sub_question_refs":["sq-01"],"title":"Source X","publisher":"example.org"}]}' > "$PROJ/.metadata/candidates.json"

# no-op (empty ingested, empty new-slugs)
echo '{"schema_version":"0.1.0","ingested":[],"skipped":[]}' > "$PROJ/.metadata/ingest-manifest.json"
NOOP_OUT="$(cd "$PLUGIN_ROOT" && python3 scripts/knowledge-ingest-postprocess.py \
  --project-path "$PROJ" --wiki-root "$WIKI" --wiki-scripts-dir "$VENDOR" --new-slugs - <<< '[]')"
if printf '%s' "$NOOP_OUT" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];sys.exit(0 if (d['n_new']==0 and d['sources_subindex']=='unchanged' and d['questions_subindex']=='unchanged') else 1)" 2>/dev/null; then
  green "PASS: postprocess: no-op path (n_new=0, sub-indexes unchanged)"
else
  red "FAIL: postprocess: no-op path; got: $NOOP_OUT"
  errors=$((errors + 1))
fi

# happy path (one new source slug; summary carries a U+2020 dagger to exercise sanitize)
cat > "$WIKI/wiki/sources/src-x.md" <<'EOF'
---
id: src-x
type: source
title: Source X
theme_label: Theme One
sources: ["https://example.org/x"]
pre_extracted_claims: []
---
# Source X
Body.
EOF
printf '{"schema_version":"0.1.0","ingested":[{"url":"https://example.org/x","slug":"src-x","title":"Source X","summary":"Explains X\\u2020topic.","sub_question_refs":["sq-01"],"claims_extracted":0}],"skipped":[]}' > "$PROJ/.metadata/ingest-manifest.json"
HAPPY_OUT="$(cd "$PLUGIN_ROOT" && python3 scripts/knowledge-ingest-postprocess.py \
  --project-path "$PROJ" --wiki-root "$WIKI" --wiki-scripts-dir "$VENDOR" --new-slugs - <<< '["src-x"]')"
if printf '%s' "$HAPPY_OUT" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];sys.exit(0 if (d['n_new']==1 and d['n_new_q']==1 and d['reverse_links_applied']==1 and d['sources_subindex']=='rendered' and d['questions_subindex']=='rendered' and d['question_manifest']=='written') else 1)" 2>/dev/null; then
  green "PASS: postprocess: happy path (n_new=1, question emitted+reverse-linked, sub-indexes rendered)"
else
  red "FAIL: postprocess: happy path; got: $HAPPY_OUT"
  errors=$((errors + 1))
fi
# sanitize_summary applied: the dagger must NOT survive into the index one-liner.
if grep -q 'X†topic' "$WIKI/wiki/index.md"; then
  red "FAIL: postprocess: summary dagger leaked into wiki/index.md (sanitize_summary not applied)"
  errors=$((errors + 1))
else
  green "PASS: postprocess: summary sanitized before reaching wiki/index.md"
fi
# entries_count bumped (+1 source +1 question == 2)
if [ "$(python3 -c "import json;print(json.load(open('$WIKI/.cogni-wiki/config.json'))['entries_count'])")" = "2" ]; then
  green "PASS: postprocess: entries_count bumped once per newly-inserted row (=2)"
else
  red "FAIL: postprocess: entries_count != 2"
  errors=$((errors + 1))
fi
# question-manifest handoff written
if [ -f "$PROJ/.metadata/question-manifest.json" ]; then
  green "PASS: postprocess: question-manifest.json handoff written"
else
  red "FAIL: postprocess: question-manifest.json not written"
  errors=$((errors + 1))
fi

# === Summary ============================================================
echo
if [ "$errors" -eq 0 ]; then
  green "All ingest-postprocess contract + functional checks passed."
  exit 0
else
  red "$errors check(s) failed."
  exit 1
fi
