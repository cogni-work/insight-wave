#!/usr/bin/env bash
# test_ingest_source_contract.sh — grep-based contract assertions for the
# standalone single-source ingest surface: the knowledge-ingest-source skill.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md content invariants. These checks catch the most likely
# failure mode — a path, flag, or step silently disappearing from the contract.
# They do NOT assert LLM behaviour.
#
# Coverage:
#   - knowledge-ingest-source: deposits ONE source directly (no research run,
#     no fetch-manifest.json), reusing the research write path — populates the
#     fetch-cache via fetch-cache.py store (webfetch), dedups via
#     wiki-grounding.py rank (diff-before-write on collision), dispatches the
#     unchanged source-ingester via Task, and runs the same backlink_audit.py +
#     wiki_index_update.py + config_bump.py post-write lockstep as
#     knowledge-ingest Step 4. Writes wiki/sources/<slug>.md (type: source).
#   - Input modes: the surface accepts a URL, a local file (.docx/.html/.txt),
#     pasted text, a local PDF, and a local interview note. Local inputs deposit
#     via fetch-method direct (the additive non-web method, now live); .docx/
#     .html/.txt normalize via the vendored convert_to_md.py; queue mode via the
#     vendored wiki_queue.py; an interview note lands as type: interview in
#     wiki/interviews/ via the source-ingester PAGE_TYPE param.
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-ingest-source SKILL.md ------------------------------------
SRC="$PLUGIN_ROOT/skills/knowledge-ingest-source/SKILL.md"
if [ ! -f "$SRC" ]; then
  red "FAIL: skills/knowledge-ingest-source/SKILL.md not found"
  exit 1
fi

# Domain-prefixed generic name (the repo convention: 'ingest' must carry the
# plugin's 'knowledge-' prefix) — the exact-name assert proves it.
assert_grep 'name: knowledge-ingest-source' "$SRC" "knowledge-ingest-source: frontmatter name (domain-prefixed)"

# Standalone posture: NO research-pipeline scaffold.
assert_grep 'no research run' "$SRC" "knowledge-ingest-source: states the no-research-run standalone posture"
assert_not_grep 'reads .*fetch-manifest.json' "$SRC" "knowledge-ingest-source: does NOT consume a fetch-manifest (that is the batch knowledge-ingest path)"

# Binding + wiki-root resolution, same pre-flight as knowledge-ingest.
assert_grep 'knowledge-binding.py read' "$SRC" "knowledge-ingest-source: reads the binding via knowledge-binding.py"
assert_grep '[Pp]robe.*cogni-wiki' "$SRC" "knowledge-ingest-source: probes cogni-wiki"
assert_grep 'resolve_wiki_scripts' "$SRC" "knowledge-ingest-source: resolves the wiki-ingest script dir via the resolve_wiki_scripts probe"

# Cache population — fetch-cache.py store with the required flags.
assert_grep 'fetch-cache.py store' "$SRC" "knowledge-ingest-source: populates the cache via fetch-cache.py store"
assert_grep 'knowledge-root' "$SRC" "knowledge-ingest-source: store passes --knowledge-root"
assert_grep 'fetch-method webfetch' "$SRC" "knowledge-ingest-source: store uses the honest --fetch-method webfetch for a URL"
# Local inputs deposit honestly via the additive non-web --fetch-method direct
# (ratified in fetch-cache.py VALID_FETCH_METHODS) — never as a webfetch lie.
assert_grep 'fetch-method direct' "$SRC" "knowledge-ingest-source: local inputs store via the honest --fetch-method direct"

# Dedup via the shared wiki-grounding primitive, with diff-before-write.
assert_grep 'wiki-grounding.py rank' "$SRC" "knowledge-ingest-source: dedups via the shared wiki-grounding.py rank primitive"
assert_grep 'diff-before-write' "$SRC" "knowledge-ingest-source: routes a collision to the diff-before-write update path"

# Reuse the unchanged source-ingester via Task (NOT a Skill dispatch).
assert_grep 'Task(source-ingester' "$SRC" "knowledge-ingest-source: dispatches the unchanged source-ingester via Task"
assert_not_grep 'Skill("cogni-knowledge:source-ingester' "$SRC" "knowledge-ingest-source: no Skill('cogni-knowledge:source-ingester) — agents go through Task"
assert_grep 'wiki/sources/' "$SRC" "knowledge-ingest-source: lands a type: source page in wiki/sources/"

# Post-write lockstep — same three helpers as knowledge-ingest Step 4.
assert_grep 'backlink_audit.py' "$SRC" "knowledge-ingest-source: backlink lockstep via backlink_audit.py"
assert_grep 'apply-plan' "$SRC" "knowledge-ingest-source: writes backlinks via --apply-plan"
assert_grep 'wiki_index_update.py' "$SRC" "knowledge-ingest-source: index update via wiki_index_update.py"
assert_grep 'max-summary' "$SRC" "knowledge-ingest-source: passes the --max-summary clamp backstop"
assert_grep 'sanitize_summary' "$SRC" "knowledge-ingest-source: sanitizes the index one-liner before the index update"
assert_grep 'config_bump.py' "$SRC" "knowledge-ingest-source: bumps entries_count via config_bump.py"
assert_grep 'entries_count' "$SRC" "knowledge-ingest-source: references entries_count"

# PDF posture: Read-tool page loop only, no homegrown parser.
assert_grep 'is_pdf_response' "$SRC" "knowledge-ingest-source: detects PDFs via is_pdf_response"
assert_grep 'Read tool' "$SRC" "knowledge-ingest-source: reads PDFs via the Read tool page loop"
assert_grep 'pdf_render_unavailable' "$SRC" "knowledge-ingest-source: honest pdf_render_unavailable reason on a render failure"
assert_grep 'text-layer extractor\|pdf-extract.py\|pdf_extract_text' "$SRC" "knowledge-ingest-source: documents the optional pypdf text-layer fallback (#583)"
# The skill must not call out to a compiled PDF library — the optional
# pure-Python `pypdf` (lowercase) is the only permitted parser, so
# pdfplumber/pdfminer/poppler stay blocked (the assert is case-sensitive, so
# lowercase 'pypdf' never matched 'PyPDF'; 'PyPDF' is dropped from the set).
assert_not_grep 'pdfplumber\|pdfminer\|poppler' "$SRC" "knowledge-ingest-source: no compiled PDF-parser dependency"

# Input modes: the surface accepts a URL OR a local input — exactly one of
# --url / --file / --paste / --interview.
assert_grep '\-\-file' "$SRC" "knowledge-ingest-source: accepts a local file via --file"
assert_grep '\-\-paste' "$SRC" "knowledge-ingest-source: accepts pasted text via --paste"
assert_grep '\-\-interview' "$SRC" "knowledge-ingest-source: accepts a local interview note via --interview"

# Local-file normalization via the vendored convert_to_md.py, queue mode via the
# vendored wiki_queue.py — both resolved through the existing wiki-ingest probe.
assert_grep 'convert_to_md.py' "$SRC" "knowledge-ingest-source: normalizes local files via the vendored convert_to_md.py"
assert_grep 'wiki_queue.py' "$SRC" "knowledge-ingest-source: queue mode via the vendored wiki_queue.py"

# Interview page type → wiki/interviews/ via the source-ingester PAGE_TYPE param.
assert_grep 'type: interview' "$SRC" "knowledge-ingest-source: an interview note lands as type: interview"
assert_grep 'wiki/interviews/' "$SRC" "knowledge-ingest-source: an interview note lands in wiki/interviews/"
assert_grep 'PAGE_TYPE' "$SRC" "knowledge-ingest-source: threads PAGE_TYPE to the source-ingester dispatch"

# .docx normalization is the OPTIONAL external markitdown tool — its absence must
# degrade to an honest error, never a fabricated body / crash.
assert_grep 'markitdown' "$SRC" "knowledge-ingest-source: names markitdown as the optional external .docx normalizer"

# allowed-tools must include WebFetch (URL fetch), Task (source-ingester), and
# Bash (the script calls). Must NOT include Skill (agents go through Task).
assert_grep 'allowed-tools:.*WebFetch' "$SRC" "knowledge-ingest-source: allowed-tools includes WebFetch"
assert_grep 'allowed-tools:.*Task' "$SRC" "knowledge-ingest-source: allowed-tools includes Task"
assert_grep 'allowed-tools:.*Bash' "$SRC" "knowledge-ingest-source: allowed-tools includes Bash"
assert_not_grep 'allowed-tools:.*Skill' "$SRC" "knowledge-ingest-source: allowed-tools excludes Skill (agents go through Task)"

# --- source-ingester: additive PAGE_TYPE param ---------------------------
# The standalone surface reuses the research write path with PAGE_TYPE=source as
# the byte-identical default; the agent gained an additive PAGE_TYPE param that
# routes interview → wiki/interviews/. The source default literals must survive.
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
assert_grep 'type: source' "$INGESTER" "source-ingester: still emits type: source (PAGE_TYPE=source is the byte-identical default)"
assert_grep 'PAGE_TYPE' "$INGESTER" "source-ingester: gained the additive PAGE_TYPE param"
assert_grep 'wiki/interviews/' "$INGESTER" "source-ingester: PAGE_TYPE=interview routes to wiki/interviews/"

# --- Step 5.4 evidence-aware refresh signal (synthesis-impact) -----------
# A new source may outdate an existing synthesis built on related evidence; the
# post-write lockstep scans for that and persists refresh candidates, surfaced in
# the Step-6 summary. Pure observability, fail-soft — must not roll back the page.
assert_grep 'synthesis-impact.py scan' "$SRC" "knowledge-ingest-source: Step 5.4 scans dependent syntheses via synthesis-impact.py"
assert_grep 'add-refresh-candidates' "$SRC" "knowledge-ingest-source: persists refresh candidates via knowledge-binding.py add-refresh-candidates"
assert_grep '\-\-related' "$SRC" "knowledge-ingest-source: reuses the Step-3 dedup neighborhood as --related"
assert_grep 'may be outdated by this source' "$SRC" "knowledge-ingest-source: Step 6 surfaces the dependent-synthesis warning line"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
