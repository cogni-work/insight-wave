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
assert_grep 'probe_plugin cogni-wiki' "$INGEST" "knowledge-ingest: probes cogni-wiki"
assert_grep 'Task' "$INGEST" "knowledge-ingest: Task listed in allowed-tools"
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
assert_grep 'wiki/sources/' "$INGESTER" "source-ingester: writes wiki/sources/<slug>.md"
assert_grep 'type: source' "$INGESTER" "source-ingester: emits type: source frontmatter"
assert_grep 'pre_extracted_claims' "$INGESTER" "source-ingester: populates pre_extracted_claims frontmatter"
assert_grep 'atomic_write_text' "$INGESTER" "source-ingester: writes via _knowledge_lib.atomic_write_text"
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

# --- fetch-cache.py VALID_REASONS constant -------------------------------
FETCH_CACHE="$PLUGIN_ROOT/scripts/fetch-cache.py"
assert_grep 'VALID_REASONS' "$FETCH_CACHE" "fetch-cache: VALID_REASONS constant (closes the vocabulary at the script boundary)"
assert_grep 'pdf_extraction_failed' "$FETCH_CACHE" "fetch-cache: VALID_REASONS includes pdf_extraction_failed (#275)"
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


check("is_pdf_response", test_is_pdf_response)
check("atomic_write_text", test_atomic_write_text)
check("slugify", test_slugify)
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

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
