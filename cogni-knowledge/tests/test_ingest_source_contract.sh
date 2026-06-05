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
#   - Scope guards: the increment is URL-only — it must NOT reach for the
#     not-yet-vendored convert_to_md.py / wiki_queue.py, and must NOT invent a
#     new fetch-cache fetch-method (the enum is cross-plugin-contracted).
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
# The fetch-method enum is cross-plugin-contracted — the increment must NOT
# invent a new local method (that is the deferred local-source work).
assert_not_grep 'fetch-method direct' "$SRC" "knowledge-ingest-source: does NOT invent a 'direct' fetch-method (enum is cross-plugin-contracted)"

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
assert_grep 'No homegrown / external PDF parser' "$SRC" "knowledge-ingest-source: states no homegrown PDF parser (Read tool only)"
# The skill must not call out to an external/homegrown PDF library.
assert_not_grep 'pdfplumber\|PyPDF\|pdfminer\|poppler' "$SRC" "knowledge-ingest-source: no external PDF-parser dependency"

# Deferred scope guards: this increment is URL-only and must not reach for the
# not-yet-vendored engine scripts.
assert_grep 'convert_to_md.py' "$SRC" "knowledge-ingest-source: names convert_to_md.py as deferred"
assert_grep 'wiki_queue.py' "$SRC" "knowledge-ingest-source: names wiki_queue.py (queue mode) as deferred"
assert_grep 'interview' "$SRC" "knowledge-ingest-source: records the interview page type as deferred"

# allowed-tools must include WebFetch (URL fetch), Task (source-ingester), and
# Bash (the script calls). Must NOT include Skill (agents go through Task).
assert_grep 'allowed-tools:.*WebFetch' "$SRC" "knowledge-ingest-source: allowed-tools includes WebFetch"
assert_grep 'allowed-tools:.*Task' "$SRC" "knowledge-ingest-source: allowed-tools includes Task"
assert_grep 'allowed-tools:.*Bash' "$SRC" "knowledge-ingest-source: allowed-tools includes Bash"
assert_not_grep 'allowed-tools:.*Skill' "$SRC" "knowledge-ingest-source: allowed-tools excludes Skill (agents go through Task)"

# --- source-ingester unchanged by this increment -------------------------
# The standalone surface REUSES the research write path byte-for-byte; the
# agent must still emit type: source so the reuse is exact.
INGESTER="$PLUGIN_ROOT/agents/source-ingester.md"
assert_grep 'type: source' "$INGESTER" "source-ingester: still emits type: source (reused unchanged by the standalone surface)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
