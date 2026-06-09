#!/usr/bin/env bash
# test_ingest_contract.sh — grep-based contract assertions for the v0.0.20
# Phase 4 ingest surface: knowledge-ingest skill, source-ingester agent,
# claim-extractor agent. Plus the #275 (PDF) and #276 (cobrowse_unavailable)
# additions to source-fetcher.md, and the new helpers in _knowledge_lib.py.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md / agent-md content invariants. These checks catch
# the most likely failure mode — a path, flag, or step silently disappearing
# from the contract. They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-ingest: reads fetch-manifest.json, dispatches source-ingester
#     via Task, calls cogni-wiki helper scripts directly (backlink_audit.py +
#     wiki_index_update.py — NOT cogni-wiki:wiki-ingest skill dispatch),
#     appends wiki/log.md ingest line, writes ingest-manifest.json schema
#     0.1.0.
#   - source-ingester: reads via fetch-cache.py fetch, dispatches
#     claim-extractor via Task, writes wiki/sources/<slug>.md with type:
#     source frontmatter + pre_extracted_claims, uses atomic_write_text,
#     does NOT WebFetch.
#   - claim-extractor: reads BODY_FILE (cached body), emits excerpt_position,
#     does NOT write files, does NOT create entities.
#   - source-curator: #275 is_pdf_response branch + #278 pdf_pages_read/
#     pdf_truncated + the Read tool — moved here from source-fetcher at
#     v0.0.29 (Option B, #292; the WebFetch body-pull now lives in Phase 4).
#   - source-fetcher: #276 cobrowse_unavailable reason (cobrowse-only after #292).
#   - _knowledge_lib.py: is_pdf_response + atomic_write_text exist.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-ingest SKILL.md -------------------------------------------
INGEST="$PLUGIN_ROOT/skills/knowledge-ingest/SKILL.md"
if [ ! -f "$INGEST" ]; then
  red "FAIL: skills/knowledge-ingest/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-ingest' "$INGEST" "knowledge-ingest: frontmatter name"
assert_grep 'fetch-manifest.json' "$INGEST" "knowledge-ingest: reads fetch-manifest.json"
assert_grep 'ingest-manifest.json' "$INGEST" "knowledge-ingest: writes ingest-manifest.json"
assert_grep '"schema_version": "0.1.0"' "$INGEST" "knowledge-ingest: ingest-manifest schema 0.1.0"
assert_grep 'Task(source-ingester' "$INGEST" "knowledge-ingest: dispatches source-ingester via Task"
assert_grep 'backlink_audit.py' "$INGEST" "knowledge-ingest: calls backlink_audit.py directly (clean-break)"
assert_grep 'wiki_index_update.py' "$INGEST" "knowledge-ingest: calls wiki_index_update.py directly (clean-break)"
assert_grep 'wiki/log.md' "$INGEST" "knowledge-ingest: appends to wiki/log.md"
assert_grep 'control-path.py" log' "$INGEST" "knowledge-ingest: resolves the log path via control-path.py (no hardcoded wiki/log.md write target)"
assert_grep 'probe_plugin cogni-wiki' "$INGEST" "knowledge-ingest: probes cogni-wiki"
assert_grep 'Task' "$INGEST" "knowledge-ingest: Task listed in allowed-tools"
# #302 (Slice 14): Step 4 bumps entries_count by the count of NEWLY-INDEXED
# source pages via config_bump.py --delta <n_new>, gated on the index update's
# action == "inserted" (same lockstep as knowledge-finalize Step 7→8), so
# wiki-health / wiki-resume stop reporting an N-page entries_count_drift. The
# re-run no-op (Step 1.3 skips ingested URLs → n_new == 0 → no bump) must be stated.
assert_grep 'config_bump.py' "$INGEST" "knowledge-ingest: bumps entries_count via config_bump.py (#302)"
assert_grep 'entries_count' "$INGEST" "knowledge-ingest: references entries_count (#302)"
assert_grep 'delta' "$INGEST" "knowledge-ingest: config_bump uses --delta (#302)"
assert_grep 'n_new' "$INGEST" "knowledge-ingest: counts newly-indexed pages in n_new (#302)"
assert_grep '"inserted"' "$INGEST" "knowledge-ingest: gates the bump on action == inserted — lockstep invariant (#302)"
assert_grep 'no-op' "$INGEST" "knowledge-ingest: states the re-run no-op (n_new == 0 → no bump) (#302)"
# Slice 16 (#308/#307): write backlinks via --apply-plan (no longer audit-only),
# and file sources under their sub-question's thematic theme_label category.
assert_grep 'apply-plan' "$INGEST" "knowledge-ingest: writes backlinks via backlink_audit.py --apply-plan (#308)"
assert_grep 'targets' "$INGEST" "knowledge-ingest: curates a targets[] backlink plan (#308)"
assert_not_grep 'audit-only' "$INGEST" "knowledge-ingest: no 'audit-only' wording remains (#308)"
assert_not_grep 'No \`--apply-plan\`' "$INGEST" "knowledge-ingest: no 'No --apply-plan' deferral wording remains (#308)"
assert_grep 'theme_label' "$INGEST" "knowledge-ingest: index category derived from the sub-question theme_label (#307)"
assert_grep 'sub_question_refs\[0\]' "$INGEST" "knowledge-ingest: joins on sub_question_refs[0] to pick the theme_label (#307)"
# #409: Step 4.5 sub-step 1 passes --binding to question-store.py (lineage-couple
# question-node accumulation), and sub-step 5 persists the returned theme_bindings[]
# into topic_lineage.covered_themes[] via knowledge-binding.py upsert-themes (the
# single binding writer). Guard the read-side flag, the writer call, and the field.
assert_grep 'question-store.py' "$INGEST" "knowledge-ingest: Step 4.5 runs question-store.py emit (#407)"
assert_grep '\-\-binding' "$INGEST" "knowledge-ingest: Step 4.5 passes --binding to question-store.py for theme lineage (#409)"
assert_grep 'theme_bindings' "$INGEST" "knowledge-ingest: Step 4.5 consumes theme_bindings[] (#409)"
assert_grep 'upsert-themes' "$INGEST" "knowledge-ingest: Step 4.5 sub-step 5 calls knowledge-binding.py upsert-themes (#409)"
assert_grep 'covered_themes' "$INGEST" "knowledge-ingest: Step 4.5 persists into topic_lineage.covered_themes[] (#409)"
# #410: Step 4.5.1 persists the emit envelope's data.questions[] to
# question-manifest.json as the phase handoff knowledge-finalize Step 4.7 reads to
# forward-link the deposited synthesis to the research-question nodes it answers.
assert_grep 'question-manifest.json' "$INGEST" "knowledge-ingest: Step 4.5.1 persists question-manifest.json handoff (#410)"
assert_not_grep 'category "Sources"' "$INGEST" "knowledge-ingest: no hard-coded --category \"Sources\" as the only category (#307; Sources is a fallback now)"
# #411: Step 4.5.3 files each question node under its sub-question's own theme_label
# heading (the same section its answering sources occupy), replacing the additive flat
# "## Research questions" index category from #408 — so the index is anchored on the
# question nodes instead of carrying two parallel groupings of the same themes. The
# category is now derived from theme_label (keyed by sub_question_id) and NO LONGER a
# hard-coded sole --category "Research questions". "Research questions" survives only as
# (a) the legacy-no-theme_label fallback category and (b) the Step 4.5.2 source-page-body
# heading, so do NOT assert the string is wholly absent — assert it is the fallback.
assert_not_grep 'category "Research questions"' "$INGEST" "knowledge-ingest: no hard-coded --category \"Research questions\" as the sole question category (#411; theme_label-derived now)"
assert_grep 'own .theme_label. heading' "$INGEST" "knowledge-ingest: Step 4.5.3 files each question under its own theme_label heading — question-anchored grouping (#411)"
assert_grep 'Research questions fallback' "$INGEST" "knowledge-ingest: \"Research questions\" kept as the legacy-no-theme_label fallback category (#411)"
# #324: Step 4.2 passes the --max-summary word-boundary clamp backstop (cogni-wiki
# v0.0.47+), and the "≤180 chars" authoring contract that caused the mid-word
# artifact is gone (the summary is authored as one crisp, complete sentence).
assert_grep 'max-summary' "$INGEST" "knowledge-ingest: Step 4.2 passes --max-summary clamp backstop (#324)"
assert_not_grep '180' "$INGEST" "knowledge-ingest: no '≤180 chars' authoring contract remains (#324)"
# #387: Step 4.2 sanitizes the authored summary (typographic-substitute guard:
# stray U+2020 dagger / NBSP -> regular space) before the index update.
assert_grep 'sanitize_summary' "$INGEST" "knowledge-ingest: Step 4.2 sanitizes the summary before the index update (#387)"
assert_grep 'CLEAN_SUMMARY' "$INGEST" "knowledge-ingest: Step 4.2 passes the sanitized \$CLEAN_SUMMARY to --summary (#387)"
# #323 (one-wave fan-out): Step 3 dispatches each batch as ONE wave (mirroring the
# knowledge-curate #299 one-wave precedent), and --batch-size is an advisory cap
# raised 8 -> 25 (the proven #311 live wave). Guard the new cadence wording, the
# new default, and the cross-reference; assert_not the dropped per-wave-barrier
# phrasing and the old default so a future edit can't silently reintroduce them.
assert_grep 'one wave' "$INGEST" "knowledge-ingest: Step 3 dispatches each batch as one wave (#323)"
assert_grep 'default 25' "$INGEST" "knowledge-ingest: --batch-size default is 25 (#323)"
assert_grep 'fan-out-concurrency' "$INGEST" "knowledge-ingest: cross-references references/fan-out-concurrency.md (#323)"
assert_not_grep 'sequential across batches' "$INGEST" "knowledge-ingest: dropped the 'sequential across batches' per-wave-barrier wording (#323)"
assert_not_grep '[Dd]efault 8' "$INGEST" "knowledge-ingest: no 'Default 8'/'default 8' --batch-size default remains (#323)"
# #413: Step 3.5 post-wave integrity sweep. The orchestrator persists an
# authoritative per-batch dispatch record (.ingest.dispatch.<NNN>.json), runs
# ingest-integrity.py sweep against it, quarantines cross-contaminated pages,
# and drops them from ingested[] with reason: integrity_mismatch. Guard the
# step, the script call, the quarantine move, and the skip reason — but NOT a
# #NNN ref in the SKILL prose (feedback_no_issue_refs_in_skills).
assert_grep 'Step 3.5' "$INGEST" "knowledge-ingest: names the Step 3.5 integrity sweep (#413)"
assert_grep 'ingest-integrity.py' "$INGEST" "knowledge-ingest: calls ingest-integrity.py sweep (#413)"
assert_grep '.ingest.dispatch.' "$INGEST" "knowledge-ingest: persists the authoritative dispatch record (#413)"
assert_grep 'quarantine' "$INGEST" "knowledge-ingest: quarantines contaminated pages (#413)"
assert_grep 'integrity_mismatch' "$INGEST" "knowledge-ingest: skip reason integrity_mismatch (#413)"
# #413 follow-up: the Step 3.5 sweep input must be keyed by per-source dispatch
# INDEX (contamination-proof), never by agent-returned URL membership in
# ingested[] — a contaminated source that echoes a sibling's URL would otherwise
# filter its own slug out of the sweep and escape detection.
assert_grep 'per-source index' "$INGEST" "knowledge-ingest: Step 3.5 keys the sweep input by per-source index, not agent-returned url (#413)"
# #421: the Step 3.5 sweep must pass --knowledge-root to enable the content_hash
# leg (otherwise the body-only cross-talk variant ships); without this guard a
# future edit could drop the flag and silently disable the leg with CI green.
assert_grep 'knowledge-root' "$INGEST" "knowledge-ingest: Step 3.5 sweep passes --knowledge-root to enable the content_hash leg (#421)"
assert_grep 'content_hash_mismatch' "$INGEST" "knowledge-ingest: documents the content_hash_mismatch reason (#421)"
# #431 approach (b): the Step 4.6 ingest-time contradiction tripwire dispatches
# source-contradictor per qualifying question group and merges the per-group
# fragments via contradiction-ingest-store.py into contradiction-ingest.json.
# Pure observability — never gates ingest, never rolls back a page. Guard the
# step, the agent dispatch, the merge script, the opt-out flag, the artifact,
# and the fail-soft posture — but NOT a #NNN ref in the SKILL prose (breadcrumb guard).
assert_grep 'Step 4.6' "$INGEST" "knowledge-ingest: names the Step 4.6 ingest-time contradiction tripwire"
assert_grep 'source-contradictor' "$INGEST" "knowledge-ingest: dispatches source-contradictor at Step 4.6"
assert_grep 'contradiction-ingest-store.py' "$INGEST" "knowledge-ingest: merges fragments via contradiction-ingest-store.py"
assert_grep 'contradiction-ingest.json' "$INGEST" "knowledge-ingest: writes the canonical contradiction-ingest.json artifact"
assert_grep '\-\-no-contradictor' "$INGEST" "knowledge-ingest: --no-contradictor opts out of Step 4.6"
assert_grep 'never rolls back\|never gates ingest\|never gate ingest' "$INGEST" "knowledge-ingest: Step 4.6 is fail-soft — never rolls back / never gates ingest"
# The qualify gate must NOT count the always-present question node toward the
# threshold (else it collapses to len(NEW) >= 1 and wastes a no-op dispatch per
# single-new-source group on a first run). Pin the corrected predicate + carve-out.
assert_grep 'len(NEW) ≥ 2' "$INGEST" "knowledge-ingest: Step 4.6 qualify gate requires ≥2 NEW or a prior-run peer (not the always-present node)"
assert_grep 'does \*\*NOT\*\* count toward this threshold\|not count toward' "$INGEST" "knowledge-ingest: Step 4.6 excludes the question node from the qualify count"
# Defence-in-depth: confirm the obsolete Skill("cogni-knowledge:source-ingester)
# dispatch is not lingering. Agents go through Task.
assert_not_grep 'Skill("cogni-knowledge:source-ingester' "$INGEST" "knowledge-ingest: no Skill('cogni-knowledge:source-ingester) — agents go through Task"
# knowledge-ingest allowed-tools must include only what Steps 0-6 actually
# use. Trimmed to Read, Write, Bash, Task at v0.0.20 per #277 review.
INGEST_TOOLS_LINE=$(grep '^allowed-tools:' "$INGEST" || true)
if echo "$INGEST_TOOLS_LINE" | grep -qE 'Glob|Skill'; then
  red "FAIL: knowledge-ingest: allowed-tools must not include Glob or Skill (unused)"
  red "  got: $INGEST_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: knowledge-ingest: allowed-tools trimmed (no unused Glob / Skill)"
fi

# --- source-ingester agent -----------------------------------------------
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
if [ ! -f "$INGESTER" ]; then
  red "FAIL: agents/source-ingester.md not found"
  exit 1
fi
assert_grep 'name: source-ingester' "$INGESTER" "source-ingester: frontmatter name"
assert_grep 'fetch-cache.py fetch' "$INGESTER" "source-ingester: reads via fetch-cache.py fetch"
assert_grep 'Task(claim-extractor' "$INGESTER" "source-ingester: dispatches claim-extractor via Task"
assert_grep 'wiki/sources/' "$INGESTER" "source-ingester: writes wiki/sources/<slug>.md (PAGE_TYPE=source default)"
assert_grep 'type: source' "$INGESTER" "source-ingester: emits type: source frontmatter (PAGE_TYPE=source default)"
# #533: the additive PAGE_TYPE param routes other page types (interview →
# wiki/interviews/) while keeping PAGE_TYPE=source byte-identical to the research
# path — contract-lock it so the parametrization can't silently regress (the
# type: source / wiki/sources/ literals above are the preserved source default).
assert_grep 'PAGE_TYPE' "$INGESTER" "source-ingester: gained the additive PAGE_TYPE param (default source)"
assert_grep 'wiki/interviews/' "$INGESTER" "source-ingester: PAGE_TYPE=interview routes to wiki/interviews/"
assert_grep 'pre_extracted_claims' "$INGESTER" "source-ingester: populates pre_extracted_claims frontmatter"
assert_grep 'atomic_write_text' "$INGESTER" "source-ingester: writes via _knowledge_lib.atomic_write_text"
# #421: the Phase-3 pre-write guard threads CONTENT_HASH so the in-agent leg
# mirrors the orchestrator sweep — guard it so the agent leg can't be silently dropped.
assert_grep 'CONTENT_HASH' "$INGESTER" "source-ingester: Phase 3 guard threads CONTENT_HASH for the content_hash leg (#421)"
# Slice 16 (#308): id: must be UNQUOTED (quoted form trips wiki-health id_mismatch),
# and source pages default to a non-empty tags list.
assert_grep 'UNQUOTED' "$INGESTER" "source-ingester: emits id: unquoted (#308 — quoted id trips health id_mismatch)"
assert_grep 'tags: \[source\]' "$INGESTER" "source-ingester: default tags: [source] (#308)"
assert_not_grep 'tags: \[\]' "$INGESTER" "source-ingester: no empty tags: [] remains (#308)"
# #324: the summary field is semantic (one self-contained sentence), no char count.
assert_grep 'self-contained sentence' "$INGESTER" "source-ingester: summary authored as one self-contained sentence (#324)"
assert_not_grep '180' "$INGESTER" "source-ingester: no character-count contract remains in the summary field (#324)"
# #387: the summary field documents the regular-space authoring guard + names the
# orchestrator-side sanitize_summary normalization (no stray U+2020 dagger / NBSP).
assert_grep 'regular space' "$INGESTER" "source-ingester: summary contract requires regular spaces (#387)"
assert_grep 'sanitize_summary' "$INGESTER" "source-ingester: names the orchestrator's sanitize_summary normalization (#387)"
# #413: Phase 3 pre-write integrity assertion — the wrapper asserts the composed
# page's id/sources match the dispatched SLUG/URL (the ground truth) and exits 3
# on mismatch, writing nothing; the agent then emits integrity_mismatch.
assert_grep 'integrity' "$INGESTER" "source-ingester: documents the pre-write integrity assertion (#413)"
assert_grep 'sys.exit(3)' "$INGESTER" "source-ingester: pre-write guard exits 3 on mismatch, writes nothing (#413)"
assert_grep 'integrity_mismatch' "$INGESTER" "source-ingester: emits skip reason integrity_mismatch (#413)"
# Frontmatter tools must not include WebFetch (re-fetch is forbidden in Phase 4).
INGESTER_TOOLS_LINE=$(grep '^tools:' "$INGESTER" || true)
if ! echo "$INGESTER_TOOLS_LINE" | grep -q WebFetch; then
  green "PASS: source-ingester: frontmatter tools: does NOT include WebFetch (Phase 3's job)"
else
  red "FAIL: source-ingester: frontmatter tools: must not include WebFetch"
  red "  got: $INGESTER_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- claim-extractor agent -----------------------------------------------
CLAIM_EXTRACTOR="$PLUGIN_ROOT/agents/claim-extractor.md"
if [ ! -f "$CLAIM_EXTRACTOR" ]; then
  red "FAIL: agents/claim-extractor.md not found"
  exit 1
fi
assert_grep 'name: claim-extractor' "$CLAIM_EXTRACTOR" "claim-extractor: frontmatter name"
assert_grep 'Forked from cogni-research/agents/claim-extractor.md' "$CLAIM_EXTRACTOR" "claim-extractor: declares fork lineage"
assert_grep 'excerpt_position' "$CLAIM_EXTRACTOR" "claim-extractor: emits excerpt_position"
assert_grep 'BODY_FILE' "$CLAIM_EXTRACTOR" "claim-extractor: input is BODY_FILE (cached body), not draft"
assert_grep 'sub_question_refs' "$CLAIM_EXTRACTOR" "claim-extractor: carries sub_question_refs"
# Negative assertion: must NOT create entities (no cogni-research side-effects).
assert_not_grep 'scripts/create-entity.sh' "$CLAIM_EXTRACTOR" "claim-extractor: does NOT call create-entity.sh (clean-break from cogni-research's Phase 3)"
assert_not_grep '02-sources/data' "$CLAIM_EXTRACTOR" "claim-extractor: does NOT touch cogni-research's 02-sources/data"
# Frontmatter tools: no Write (the ingester writes the page), no WebFetch.
EXTRACTOR_TOOLS_LINE=$(grep '^tools:' "$CLAIM_EXTRACTOR" || true)
if echo "$EXTRACTOR_TOOLS_LINE" | grep -qE 'Write|WebFetch'; then
  red "FAIL: claim-extractor: frontmatter tools: must not include Write or WebFetch"
  red "  got: $EXTRACTOR_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: claim-extractor: frontmatter tools: read-only (no Write, no WebFetch)"
fi

# --- source-curator PDF branch (#275, #278) — moved here from source-fetcher
# at v0.0.29 (Option B, #292): the WebFetch body-pull + PDF Read-loop moved
# into the curator's Phase 4, so the PDF contract now lives on source-curator.
CURATOR="$PLUGIN_ROOT/agents/source-curator.md"
if [ ! -f "$CURATOR" ]; then
  red "FAIL: agents/source-curator.md not found"
  exit 1
fi
assert_grep 'is_pdf_response' "$CURATOR" "source-curator: uses is_pdf_response helper (#275, moved in #292)"
assert_grep 'pdf_extraction_failed' "$CURATOR" "source-curator: closed vocab includes pdf_extraction_failed (#275)"
assert_grep 'pdf_truncated' "$CURATOR" "source-curator: documents pdf_truncated for the 200-page hard-cap case (#278)"
assert_grep 'pdf_pages_read' "$CURATOR" "source-curator: records pdf_pages_read in the candidate fetch sub-object (#278)"
# #458/#583: the saved-but-unrenderable PDF case keeps its own honest,
# operator-actionable reason — but it is now reserved for genuinely image-only
# PDFs: before recording it, the curator tries the optional pure-Python text-layer
# fallback (pdf-extract.py / optional pypdf), and only falls through when that also fails.
assert_grep 'pdf_render_unavailable' "$CURATOR" "source-curator: PDF branch records pdf_render_unavailable when the Read tool can't render a saved file (#458)"
assert_grep 'pdf-extract.py\|pdf_text_extracted\|text-layer fallback' "$CURATOR" "source-curator: PDF branch tries the optional pypdf text-layer fallback before pdf_render_unavailable (#583)"
# Regression guard for the #277 review-blocker, now on the curator: the PDF
# branch instructs `Read pages: "1-20"` the saved binary; the Read tool MUST
# be in the frontmatter tools list or the PDF rail fails at runtime.
CURATOR_TOOLS_LINE=$(grep '^tools:' "$CURATOR" || true)
if echo "$CURATOR_TOOLS_LINE" | grep -q '"Read"'; then
  green "PASS: source-curator: frontmatter tools: includes Read (required by the moved PDF branch)"
else
  red "FAIL: source-curator: frontmatter tools: must include Read for the PDF branch"
  red "  got: $CURATOR_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- source-fetcher (#276) — cobrowse-only after #292 --------------------
FETCHER="$PLUGIN_ROOT/agents/source-fetcher.md"
assert_grep 'cobrowse_unavailable' "$FETCHER" "source-fetcher: closed vocab includes cobrowse_unavailable (#276)"

# --- _knowledge_lib.py new helpers ---------------------------------------
LIB="$PLUGIN_ROOT/scripts/_knowledge_lib.py"
assert_grep 'def is_pdf_response' "$LIB" "_knowledge_lib: defines is_pdf_response"
assert_grep 'def atomic_write_text' "$LIB" "_knowledge_lib: defines atomic_write_text"
assert_grep 'def slugify' "$LIB" "_knowledge_lib: defines slugify (lifted from inline SKILL prose)"
assert_grep 'def sanitize_summary' "$LIB" "_knowledge_lib: defines sanitize_summary (#387 index-one-liner guard)"
# #413: the frontmatter id+sources extractor is shared by ingest-integrity.py
# (sweep) and source-ingester's Phase 3 pre-write assertion — one impl, no drift.
assert_grep 'def extract_page_id_and_url' "$LIB" "_knowledge_lib: defines extract_page_id_and_url shared by sweep + agent (#413)"
assert_grep 'def extract_page_content_hash' "$LIB" "_knowledge_lib: defines extract_page_content_hash shared by sweep + Phase-3 guard (#421)"

# --- fetch-cache.py VALID_REASONS constant -------------------------------
FETCH_CACHE="$PLUGIN_ROOT/scripts/fetch-cache.py"
assert_grep 'VALID_REASONS' "$FETCH_CACHE" "fetch-cache: VALID_REASONS constant (closes the vocabulary at the script boundary)"
assert_grep 'pdf_extraction_failed' "$FETCH_CACHE" "fetch-cache: VALID_REASONS includes pdf_extraction_failed (#275)"
assert_grep 'pdf_render_unavailable' "$FETCH_CACHE" "fetch-cache: VALID_REASONS includes pdf_render_unavailable (#458)"
assert_grep 'cobrowse_unavailable' "$FETCH_CACHE" "fetch-cache: VALID_REASONS includes cobrowse_unavailable (#276)"

# Behavioural check: is_pdf_response + atomic_write_text actually work.
OUT=$(python3 - "$PLUGIN_ROOT/scripts" <<'PY'
import importlib.util
import sys
import tempfile
from pathlib import Path

scripts = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location("_knowledge_lib", scripts / "_knowledge_lib.py")
kl = importlib.util.module_from_spec(spec)
sys.modules["_knowledge_lib"] = kl
spec.loader.exec_module(kl)


def check(tag, fn):
    try:
        fn()
        print(f"{tag}: OK")
    except AssertionError as exc:
        print(f"{tag}: FAIL {exc}")


def test_is_pdf_response():
    # Content-Type signal
    assert kl.is_pdf_response("application/pdf", "https://example.org/foo")
    assert kl.is_pdf_response("application/pdf; charset=binary", "https://example.org/foo")
    assert kl.is_pdf_response("APPLICATION/PDF", "https://example.org/foo")
    # URL suffix signal
    assert kl.is_pdf_response(None, "https://arxiv.org/pdf/2401.12345.pdf")
    assert kl.is_pdf_response("text/plain", "https://example.org/foo.PDF")
    # Negatives
    assert not kl.is_pdf_response("text/html", "https://example.org/foo")
    assert not kl.is_pdf_response(None, "https://example.org/foo.html")
    assert not kl.is_pdf_response(None, "")


def test_atomic_write_text():
    with tempfile.TemporaryDirectory() as td:
        target = Path(td) / "sub" / "page.md"
        text = "---\nid: foo\n---\n# Hello\n"
        returned = kl.atomic_write_text(target, text)
        assert returned == target, (returned, target)
        assert target.read_text(encoding="utf-8") == text, target.read_text(encoding="utf-8")
        # No .tmp debris
        leftover = [p.name for p in target.parent.iterdir() if p.name.endswith(".tmp")]
        assert leftover == [], leftover


def test_slugify():
    # Happy paths
    assert kl.slugify("Article 6 — High-risk AI") == "article-6-high-risk-ai", kl.slugify("Article 6 — High-risk AI")
    assert kl.slugify("EU AI Act, GPAI Code of Practice") == "eu-ai-act-gpai-code-of-practice"
    assert kl.slugify("  Lots   of  spaces  ") == "lots-of-spaces"
    # Length cap, strip trailing dash after cap
    long_in = "a" * 200
    assert kl.slugify(long_in, max_len=20) == "a" * 20
    capped = kl.slugify("aa" + ("-" * 10) + "b" * 100, max_len=15)
    assert capped == capped.rstrip("-") and len(capped) <= 15, capped
    # Edge cases: empty / non-alnum → empty (caller applies hash fallback)
    assert kl.slugify("") == ""
    assert kl.slugify("---") == ""
    assert kl.slugify("!@#$%^&*") == ""


def test_sanitize_summary():
    # The exact #387 case: U+2020 DAGGER where a space belongs (\u00a730, Dezember2025).
    # \u escapes keep the substitute codepoints unambiguous in ASCII source.
    raw = (
        "\u2026 die 10 verpflichtenden Mindestma\u00dfnahmen nach "
        "\u00a7\u202030 BSIG, die seit Dezember\u20202025 ohne "
        "\u00dcbergangsfrist \u2026"
    )
    out = kl.sanitize_summary(raw)
    # Every targeted substitute codepoint is gone.
    for cp in ("\u2020", "\u2021", "\u00a0", "\u202f", "\u2009"):
        assert cp not in out, (hex(ord(cp)), repr(out))
    assert "\u00a7 30 BSIG" in out, repr(out)   # \u00a7 30, single regular space
    assert "Dezember 2025" in out, repr(out)
    # Exotic spaces (NBSP / NNBSP / THIN SPACE) collapse to a single regular space.
    assert kl.sanitize_summary("Artikel\u00a09\u202fund\u2009Absatz 2") == "Artikel 9 und Absatz 2"
    # NOT slugify - accents / non-ASCII letters preserved verbatim, no transliteration.
    assert kl.sanitize_summary("Mindestma\u00dfnahmen f\u00fcr \u00dcbergangsfrist") == "Mindestma\u00dfnahmen f\u00fcr \u00dcbergangsfrist"
    # Falsy passthrough (callers surface a bad value rather than coalescing to "").
    assert kl.sanitize_summary("") == ""
    assert kl.sanitize_summary(None) is None


check("is_pdf_response", test_is_pdf_response)
check("atomic_write_text", test_atomic_write_text)
check("slugify", test_slugify)
check("sanitize_summary", test_sanitize_summary)
PY
)

errors_before=$errors

grade() {
  local tag="$1" description="$2"
  local line
  line=$(printf '%s\n' "$OUT" | grep "^${tag}:" || true)
  case "$line" in
    "${tag}: OK")     green "PASS: $description" ;;
    "${tag}: FAIL "*) red   "FAIL: $description"; red "  ${line#${tag}: FAIL }"; errors=$((errors + 1)) ;;
    *)                red   "FAIL: $description (no result line — python crashed?)"
                      red   "  output: $OUT"; errors=$((errors + 1)) ;;
  esac
}

grade is_pdf_response   "is_pdf_response — Content-Type and .pdf suffix detection"
grade atomic_write_text "atomic_write_text round-trips text and leaves no .tmp debris"
grade slugify           "slugify — lower-kebab, dash-collapse, length cap, empty-on-non-alnum"
grade sanitize_summary  "sanitize_summary — U+2020 dagger / NBSP -> regular space, accents preserved (#387)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
