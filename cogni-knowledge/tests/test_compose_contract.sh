#!/usr/bin/env bash
# test_compose_contract.sh — Phase 5 (knowledge-compose + wiki-composer)
# contract assertions.
#
# Per tests/README.md §"Contract tests": for pure LLM skills, regression
# coverage is SKILL.md / agent-md content invariants — these checks catch a
# path, flag, or step silently disappearing from the contract, not LLM
# behaviour. The assertions below are self-documenting; do not maintain a
# parallel coverage list here (it will drift from the actual asserts).
#
# bash 3.2 + grep only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

# --- knowledge-compose SKILL.md ------------------------------------------
COMPOSE="$PLUGIN_ROOT/skills/knowledge-compose/SKILL.md"
if [ ! -f "$COMPOSE" ]; then
  red "FAIL: skills/knowledge-compose/SKILL.md not found"
  exit 1
fi
assert_grep 'name: knowledge-compose' "$COMPOSE" "knowledge-compose: frontmatter name"
assert_grep 'plan.json' "$COMPOSE" "knowledge-compose: reads plan.json"
assert_grep 'ingest-manifest.json' "$COMPOSE" "knowledge-compose: reads ingest-manifest.json"
assert_grep 'draft-v' "$COMPOSE" "knowledge-compose: writes draft-vN.md"
assert_grep 'citation-manifest.json' "$COMPOSE" "knowledge-compose: writes citation-manifest.json"
assert_grep '"schema_version": "0.1.1"' "$COMPOSE" "knowledge-compose: citation-manifest schema 0.1.1 (#395 url field)"
# #383: Step 4.5's citation-store.py build cross-checks inline URLs against the ingest manifest.
assert_grep 'ingest-manifest' "$COMPOSE" "knowledge-compose: Step 4.5 passes --ingest-manifest to the build (#383 URL gate)"
assert_grep 'url_not_in_sources' "$COMPOSE" "knowledge-compose: documents the url_not_in_sources failed_check (#383)"
assert_grep 'Task(wiki-composer' "$COMPOSE" "knowledge-compose: dispatches wiki-composer via Task"
# Slice 13 (#300): threads the project's output_language into the composer dispatch.
assert_grep 'OUTPUT_LANGUAGE=' "$COMPOSE" "knowledge-compose: threads OUTPUT_LANGUAGE into the wiki-composer dispatch (#300)"
assert_grep 'output_language' "$COMPOSE" "knowledge-compose: reads plan.json::output_language (#300)"
# #309 P2: TONE + PROSE_DENSITY + a now-LIVE CITATION_FORMAT are threaded into the
# composer dispatch (resolved flag > plan.json > default).
assert_grep 'TONE=' "$COMPOSE" "knowledge-compose: threads TONE into the wiki-composer dispatch (#309 P2.3)"
assert_grep 'PROSE_DENSITY=' "$COMPOSE" "knowledge-compose: threads PROSE_DENSITY into the wiki-composer dispatch (#309 P2.1)"
assert_grep 'CITATION_FORMAT=' "$COMPOSE" "knowledge-compose: threads CITATION_FORMAT (now live) into the wiki-composer dispatch (#309 P2.2)"
assert_grep 'Over ceiling' "$COMPOSE" "knowledge-compose: executive-density over-ceiling warning (#309 P2.4)"
assert_grep 'probe_plugin cogni-wiki' "$COMPOSE" "knowledge-compose: probes cogni-wiki (clean-break)"
assert_grep 'RESUME_FROM_OUTLINE' "$COMPOSE" "knowledge-compose: F11 — passes RESUME_FROM_OUTLINE to composer"
assert_grep 'writer-outline-v' "$COMPOSE" "knowledge-compose: F11 — detects writer-outline-vN.json for recovery"
assert_grep 'wiki/log.md' "$COMPOSE" "knowledge-compose: appends to wiki/log.md"
# #385: the skill captures the per-kind citation breakdown from citation-store.py
# build and surfaces the distilled-citation (dcl-) rate — the measurement the
# inert-loop issue asked for (0 dcl- on a converging base is the symptom).
assert_grep 'claim_kinds' "$COMPOSE" "knowledge-compose: captures data.claim_kinds from the build (#385 dcl- measurement)"
assert_grep 'Distilled citations' "$COMPOSE" "knowledge-compose: Step 7 summary surfaces the distilled-citation rate (#385)"
assert_grep 'dcl=' "$COMPOSE" "knowledge-compose: Step 6 log line records dcl=<n> for cross-run measurement (#385)"
# #325: the orchestrator builds citation-manifest.json from the composer's raw
# records via citation-store.py (json.dumps, not LLM-hand-built JSON), and the
# Step-5 validator re-asserts every draft_sentence is in the draft (authoritative
# gate, issue #4). The '#325' marker tags the substring guard line.
assert_grep 'citation-store.py' "$COMPOSE" "knowledge-compose: builds the manifest via citation-store.py (#325)"
assert_grep 'verbatim substring of the draft' "$COMPOSE" "knowledge-compose: Step-5 asserts every draft_sentence is a verbatim substring of the draft"
# Match the actual log-line shape Step 6 emits (`## [DATE] compose | project=...`)
# rather than the bare word `compose`, which would also match the filename,
# skill name, and every doc paragraph.
assert_grep '\] compose | project=' "$COMPOSE" "knowledge-compose: emits the '## [DATE] compose | project=...' log-line shape"
# Defence-in-depth: confirm there is no obsolete Skill("cogni-knowledge:wiki-composer)
# dispatch. Agents go through Task.
assert_not_grep 'Skill("cogni-knowledge:wiki-composer' "$COMPOSE" "knowledge-compose: no Skill('cogni-knowledge:wiki-composer) — agents go through Task"
# Clean-break: no cogni-research input shapes leaking through.
assert_not_grep 'aggregated-context.json' "$COMPOSE" "knowledge-compose: does NOT reference aggregated-context.json (clean-break — that's cogni-research's input shape)"
assert_not_grep '01-contexts/data' "$COMPOSE" "knowledge-compose: does NOT reference cogni-research's 01-contexts/data"
assert_not_grep '02-sources/data' "$COMPOSE" "knowledge-compose: does NOT reference cogni-research's 02-sources/data"
# allowed-tools must include Task (we dispatch wiki-composer).
COMPOSE_TOOLS_LINE=$(grep '^allowed-tools:' "$COMPOSE" || true)
if echo "$COMPOSE_TOOLS_LINE" | grep -q Task; then
  green "PASS: knowledge-compose: allowed-tools includes Task"
else
  red "FAIL: knowledge-compose: allowed-tools must include Task"
  red "  got: $COMPOSE_TOOLS_LINE"
  errors=$((errors + 1))
fi

# --- wiki-composer agent -------------------------------------------------
COMPOSER="$PLUGIN_ROOT/agents/wiki-composer.md"
if [ ! -f "$COMPOSER" ]; then
  red "FAIL: agents/wiki-composer.md not found"
  exit 1
fi
assert_grep 'name: wiki-composer' "$COMPOSER" "wiki-composer: frontmatter name"
assert_grep 'Forked from cogni-research/agents/writer.md' "$COMPOSER" "wiki-composer: declares fork lineage"
assert_grep 'wiki/index.md' "$COMPOSER" "wiki-composer: reads wiki/index.md"
assert_grep 'wiki/sources/' "$COMPOSER" "wiki-composer: reads wiki/sources/<slug>.md pages"
assert_grep 'wiki/syntheses/' "$COMPOSER" "wiki-composer: reads prior wiki/syntheses/*.md"
assert_grep '\[\[sources/' "$COMPOSER" "wiki-composer: emits [[sources/<slug>]] wikilink citations"
assert_grep 'writer-outline-v' "$COMPOSER" "wiki-composer: F11 — persists writer-outline-vN.json"
assert_grep 'RESUME_FROM_OUTLINE' "$COMPOSER" "wiki-composer: F11 — honours RESUME_FROM_OUTLINE input"
assert_grep 'citation-manifest.json' "$COMPOSER" "wiki-composer: writes citation-manifest.json"
assert_grep 'draft_position' "$COMPOSER" "wiki-composer: citation-manifest entry has draft_position (best-effort locator)"
assert_grep 'wiki_slug' "$COMPOSER" "wiki-composer: citation-manifest entry has wiki_slug"
assert_grep 'claim_id' "$COMPOSER" "wiki-composer: citation-manifest entry has claim_id"
# F22: each citation carries a stable id and the verbatim cited sentence.
assert_grep 'draft_sentence' "$COMPOSER" "wiki-composer: citation-manifest entry has draft_sentence (F22 stable alignment surface)"
assert_grep 'cit-001' "$COMPOSER" "wiki-composer: citation ids are the cit-NNN stable join key"
assert_grep 'pre_extracted_claims' "$COMPOSER" "wiki-composer: looks up claim_id in pre_extracted_claims (zero-network alignment surface)"
assert_grep 'draft-v' "$COMPOSER" "wiki-composer: writes output/draft-vN.md"
# #325: the composer writes a RAW-TEXT citation-records file (never hand-built
# JSON); the orchestrator serializes it. The old "Compose the JSON envelope and
# Write it" instruction is the regression that shipped invalid JSON.
assert_grep 'citation-records' "$COMPOSER" "wiki-composer: writes a raw-text citation-records file (#325)"
assert_not_grep 'Compose the JSON envelope' "$COMPOSER" "wiki-composer: no longer hand-builds the manifest JSON (#325)"

# Scope-discipline negatives — these deferred surfaces may appear in the
# header HTML comment (as provenance documenting what the fork dropped)
# but MUST NOT appear in the input parameter table or as live workflow.
# Pattern is the parameter-table-row form `| \`TOKEN\` |`.
assert_not_grep '01-contexts/data' "$COMPOSER" "wiki-composer: does NOT reference cogni-research's 01-contexts/data"
assert_not_grep '02-sources/data' "$COMPOSER" "wiki-composer: does NOT reference cogni-research's 02-sources/data"
# Slice 13 (#300): OUTPUT_LANGUAGE + CITATION_FORMAT are LIVE parameter rows.
# #309 P2: TONE + PROSE_DENSITY are now ALSO live (the composer honours the
# project's tone register and standard/executive density).
# #384 (v0.1.44): EXPANSION_MODE is a NEW live parameter — the orchestrator may
# re-dispatch the composer ONCE to deepen thin sections from not-yet-cited wiki
# claims (bounded, fail-soft, ZERO-NETWORK). This is a DISTINCT token from the
# upstream web-backed EXPANSION_NOTES / STORY_ARC_ID, which stay deferred (the
# negative loop below still guards them — that is the non-port boundary).
for token in OUTPUT_LANGUAGE CITATION_FORMAT TONE PROSE_DENSITY EXPANSION_MODE; do
  if grep -q "| \`${token}\` |" "$COMPOSER"; then
    green "PASS: wiki-composer: ${token} parameter row present (live writer-quality input)"
  else
    red "FAIL: wiki-composer: ${token} parameter row missing (expected as a live input)"
    errors=$((errors + 1))
  fi
done
for token in EXPANSION_NOTES STORY_ARC_ID; do
  if grep -q "| \`${token}\` |" "$COMPOSER"; then
    red "FAIL: wiki-composer: ${token} parameter row present (deferred surface — no expansion loop / no arcs)"
    errors=$((errors + 1))
  else
    green "PASS: wiki-composer: no ${token} parameter row (deferred)"
  fi
done
# #309 P2: the executive-density discipline (BLUF + Pyramid + one citation per
# claim) must be present, and the agent must stay single-pass (no re-dispatch).
assert_grep 'BLUF' "$COMPOSER" "wiki-composer: executive density applies BLUF (#309 P2.1)"
assert_grep 'Pyramid' "$COMPOSER" "wiki-composer: executive density applies the Pyramid Principle (#309 P2.1)"
assert_grep 'One citation per claim\|one citation per claim' "$COMPOSER" "wiki-composer: executive density is one-citation-per-claim (#309 P2.1)"
assert_grep 'writing-tones.md' "$COMPOSER" "wiki-composer: TONE references the writing-tones catalog (#309 P2.3)"
assert_grep 'chicago' "$COMPOSER" "wiki-composer: CITATION_FORMAT renders chicago end-to-end (#309 P2.2)"
# Single-pass invariant must survive the density knob — no re-dispatch loop.
assert_grep 'does NOT re-dispatch\|never loops\|NEVER loop\|single pass\|Single pass\|single-pass' "$COMPOSER" "wiki-composer: stays single-pass under prose_density (#309 P2 — advisory floor/ceiling, no loop)"
# #300 inline-citation convention: numbered [N] inline, wikilinks confined to
# the reference list (never in prose), numbered in first-appearance order.
assert_grep 'first-appearance order' "$COMPOSER" "wiki-composer: numbers [N] in first-appearance order (#300)"
assert_grep '\[\[N\]\]' "$COMPOSER" "wiki-composer: forbids the Obsidian-colliding [[N]] form (#300)"
assert_grep 'reference list, never in prose' "$COMPOSER" "wiki-composer: wikilinks confined to the reference list, not prose (#300)"
assert_grep 'OUTPUT_LANGUAGE' "$COMPOSER" "wiki-composer: honours OUTPUT_LANGUAGE for output + headings (#300)"
# #385: distilled-page citation must be PREFERRED on ≥2-source convergence, and the
# convergence trigger (backlinks[] / source_claim_refs[]) must be DISCOVERABLE — the
# pre-#385 prompt told the composer those were "writer-side metadata you can ignore",
# which is exactly the data that signals ≥2-source convergence, so dcl- citations
# never fired. Assert the metadata is now read, the preference is explicit, and the
# old ignore instruction is gone.
assert_grep 'backlinks' "$COMPOSER" "wiki-composer: reads distilled-claim backlinks[] (the ≥2-source convergence signal, #385)"
assert_grep 'source_claim_refs' "$COMPOSER" "wiki-composer: reads source_claim_refs[] to count distinct backing sources (#385)"
assert_grep 'dcl-NNN' "$COMPOSER" "wiki-composer: cites a distilled page via its dcl-NNN claim_id (#344/#385)"
assert_grep '≥2 distinct backlinks\|≥2 distinct sources\|≥2 sources converge' "$COMPOSER" "wiki-composer: ≥2-source convergence is the distilled-citation trigger (#385)"
assert_grep 'PREFER\|prefer the\|prefer a\|prefer ONE\|prefer one' "$COMPOSER" "wiki-composer: PREFERS a distilled-page citation over stacking source markers on convergence (#385)"
assert_not_grep 'writer-side metadata you can ignore' "$COMPOSER" "wiki-composer: no longer tells the composer to IGNORE the convergence metadata (#385 root cause)"
# `aggregated-context.json` is cogni-research's input shape. The fork
# header explains it was dropped; the composer must not READ it. The
# read-input contract lives in Phase 0 — assert the workflow phase
# doesn't mention it (the header HTML comment is exempt).
if awk '/^### Phase 0/{p=1; next} /^### Phase/{p=0} p' "$COMPOSER" | grep -q 'aggregated-context.json'; then
  red "FAIL: wiki-composer: Phase 0 reads aggregated-context.json (clean-break broken)"
  errors=$((errors + 1))
else
  green "PASS: wiki-composer: Phase 0 does NOT read aggregated-context.json (clean-break)"
fi

# Frontmatter tools: single-pass agent — must include Read/Write/Glob/Grep,
# must NOT include Task (no sub-dispatch) or WebFetch (no re-fetch).
COMPOSER_TOOLS_LINE=$(grep '^tools:' "$COMPOSER" || true)
for required in '"Read"' '"Write"' '"Glob"' '"Grep"'; do
  if echo "$COMPOSER_TOOLS_LINE" | grep -q "$required"; then
    green "PASS: wiki-composer: frontmatter tools: includes $required"
  else
    red "FAIL: wiki-composer: frontmatter tools: missing $required"
    red "  got: $COMPOSER_TOOLS_LINE"
    errors=$((errors + 1))
  fi
done
if echo "$COMPOSER_TOOLS_LINE" | grep -qE 'WebFetch|"Task"'; then
  red "FAIL: wiki-composer: frontmatter tools: must not include WebFetch or Task (single-pass, no sub-dispatch)"
  red "  got: $COMPOSER_TOOLS_LINE"
  errors=$((errors + 1))
else
  green "PASS: wiki-composer: frontmatter tools: no WebFetch, no Task (single-pass, read-the-wiki only)"
fi

# --- #384 bounded floor-expansion (Step 5.5) contract --------------------
# knowledge-compose gained a Step 5.5 that re-dispatches wiki-composer ONCE in
# EXPANSION_MODE on a standard-density floor deficit (zero-network, capped,
# fail-soft). Guard the contract surface so a path/flag/branch can't silently
# disappear.
assert_grep 'no-expand' "$COMPOSE" "knowledge-compose: --no-expand opt-out flag present (#384)"
assert_grep '5.5' "$COMPOSE" "knowledge-compose: Step 5.5 bounded floor-expansion present (#384)"
assert_grep 'EXPANSION_MODE=true' "$COMPOSE" "knowledge-compose: Step 5.5 re-dispatches with EXPANSION_MODE=true (#384)"
assert_grep 'EXPAND_SECTIONS=' "$COMPOSE" "knowledge-compose: Step 5.5 threads EXPAND_SECTIONS into the re-dispatch (#384)"
# #401 note 1: EXPAND_SECTIONS must fall back to the largest topical sections by
# budget when a real total deficit holds but no section is individually flagged
# (the RESUME_FROM_OUTLINE / null drafted_words path) — else a genuine deficit
# silently skips. Guard the fallback so it can't regress to thin-only.
assert_grep 'largest topical sections by budget' "$COMPOSE" "knowledge-compose: Step 5.5 falls back to the largest topical sections by budget when none is individually thin (#401)"
assert_grep 'BASELINE_DRAFT_VERSION=' "$COMPOSE" "knowledge-compose: Step 5.5 threads BASELINE_DRAFT_VERSION (#384)"
assert_grep 'ceiling_hit' "$COMPOSE" "knowledge-compose: Step 5.5 gate keys on the composer's ceiling_hit (#384)"
assert_grep 'kept draft-vN' "$COMPOSE" "knowledge-compose: Step 5.5 fail-soft keeps draft-vN as latest (#384)"
# Fail-soft must keep the canonical manifest consistent with vN: a successful N+1
# build overwrites citation-manifest.json BEFORE Step 5 verify runs, so a
# build-OK-but-verify-fail (or no-growth) outcome must snapshot vN's manifest
# first and restore it — else verify/finalize read a stale manifest pointing at a
# deleted draft-v(N+1).
assert_grep 'citation-manifest.pre-expand' "$COMPOSE" "knowledge-compose: Step 5.5 snapshots the manifest before the expansion build (#384)"
assert_grep 'manifest restored\|restore the snapshot\|restore the manifest' "$COMPOSE" "knowledge-compose: Step 5.5 restores the vN manifest on expansion failure (#384)"
# Regression guard: keep v(N+1) only if it actually grew the draft.
assert_grep 'did not grow\|words<N+1> > words<N>\|words<N+1> ≤ words<N>\|grew the draft' "$COMPOSE" "knowledge-compose: Step 5.5 keeps vN when the expansion did not grow the draft (#384)"
# The cap is exactly ONE expansion — the skill must say so (defends against a
# future edit re-introducing an unbounded loop).
assert_grep 'capped at ONE\|capped at one\|cap = 1\|ONE bounded\|one bounded\|ONE expansion\|once in' "$COMPOSE" "knowledge-compose: Step 5.5 is capped at ONE expansion (#384)"

# wiki-composer must declare the EXPANSION_MODE input parameters + the ceiling_hit
# return field. (The EXPANSION_MODE param-row presence is asserted in the live-token
# loop above; here we check the companion params + the return contract.)
assert_grep 'BASELINE_DRAFT_VERSION' "$COMPOSER" "wiki-composer: declares BASELINE_DRAFT_VERSION input (#384)"
assert_grep 'EXPAND_SECTIONS' "$COMPOSER" "wiki-composer: declares EXPAND_SECTIONS input (#384)"
assert_grep 'ceiling_hit' "$COMPOSER" "wiki-composer: reports ceiling_hit in the return JSON (#384)"
# Zero-network non-port: the expansion deepens from EXISTING wiki claims only —
# it must say 'not yet cited' / 'not-yet-cited', and must NOT gain WebFetch/WebSearch
# (the single-pass tools check above already forbids those; this asserts the prose).
assert_grep 'not-yet-cited\|not yet cited' "$COMPOSER" "wiki-composer: expansion deepens from not-yet-cited wiki claims (zero-network non-port, #384)"
# Single-pass-per-dispatch invariant must survive: the agent never self-loops.
assert_grep 'single pass per dispatch\|Single pass per dispatch\|single-pass per dispatch\|single pass: read baseline\|once in .EXPANSION_MODE.\|re-dispatch you exactly ONCE\|re-dispatch you ONCE\|re-dispatch you once' "$COMPOSER" "wiki-composer: stays single-pass per dispatch under EXPANSION_MODE (orchestrator drives the one re-dispatch, #384)"

# --- Phase 5 contract token match ----------------------------------------
# The inverted-pipeline.md Phase 5 contract names three reads and two
# writes; the composer must mention all of them at least once.
PIPELINE="$PLUGIN_ROOT/references/inverted-pipeline.md"
assert_grep 'Phase 5 — `knowledge-compose`' "$PIPELINE" "inverted-pipeline.md: Phase 5 section header anchored"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
