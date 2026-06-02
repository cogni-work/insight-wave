---
name: knowledge-compose
description: "Phase 5 of the inverted pipeline. Reads <project>/.metadata/plan.json + <project>/.metadata/ingest-manifest.json + the populated cogni-wiki, dispatches a wiki-composer pass (plus, under standard density, ONE bounded fail-soft zero-network floor-expansion re-dispatch when the draft lands under its word floor with headroom), and lands <project>/output/draft-vN.md + <project>/.metadata/citation-manifest.json. Inline citations are clickable numbered [N] markers; [[sources/<slug>]] wikilinks live only in the reference list. Output language + reference heading follow plan.json::output_language (threaded as OUTPUT_LANGUAGE). Preserves the outline-recovery contract — a leftover writer-outline-vN.json from a crashed prior run causes Phase 1 of the composer to be skipped. Use this skill whenever the user says 'compose the draft', 'write the report from the wiki', 'phase 5 of the knowledge pipeline', 'knowledge compose', 'draft v1', or 'run the writer'. After compose, knowledge-verify will run the zero-network claim alignment."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Compose

Phase 5 of the inverted pipeline. Reads the per-project `plan.json` + `ingest-manifest.json` + the populated wiki at `<binding.wiki_path>/wiki/`, dispatches `wiki-composer` once, and verifies the output files land on disk.

The composer reads `wiki/index.md` + selected `wiki/sources/*.md` (lazily) + prior `wiki/syntheses/*.md`. Since the distillation interphase (`knowledge-distill`), it also reads the distilled `wiki/{concepts,entities,summaries,learnings}/*.md` pages (topic-matched, lazily) — these serve **both** as narrative framing **and** as citable cross-source evidence: when ≥2 sources converge on a fact the distilled page already captures, the composer cites the distilled page itself via its `dcl-NNN` claim id, so the convergence carries epistemic weight rather than a row of source markers. Distilled pages carry `distilled_claims:` (not `pre_extracted_claims:`), and a distilled-page citation is scored by the verifier against that claim's `text`. Distillation stays optional and fail-soft: when it hasn't run, the composer simply has no distilled pages to draw on and composes from sources + syntheses alone.

The composer also reads the `type: question` nodes at `wiki/questions/*.md` (topic-matched, lazily) — first-class wiki pages each recording one research question the base has already explored, with `## Findings` `[[links]]` to the sources that answered it. These serve **both** as narrative framing **and** as a citable cross-source answer surface (since #432 Slice 2): a question node may carry an `answer_claims:` block (`acl-NNN` ids, synthesized by `knowledge-distill` Step 6.9), and when its `backlinks[]` list ≥2 distinct sources the composer cites the node directly via its `acl-NNN` claim — one citation carrying "N sources agree on the answer" — exactly mirroring the distilled-page rule just above. A single-source answer, or a question node with no `answer_claims:` block yet, stays framing-only: the composer reads it for orientation but cites the backing **source** page, never the node (an inline citation to a claim-less node would score `unsupported`). A question-node citation is scored by the verifier against that answer claim's `text`.

The composer then writes:

- `<project>/output/draft-v{N}.md` — the draft, with clickable numbered `[N]` inline citations (wikilinks confined to the reference list).
- `<project>/.metadata/citation-records-v{N}.txt` — one raw-text record per citation (the composer writes this; it never hand-builds JSON). This skill then runs `citation-store.py build` to serialize and validate `<project>/.metadata/citation-manifest.json` (schema `0.1.0`, one `{id, draft_position, draft_sentence, wiki_slug, claim_id}` entry per citation). Escaping is owned by `json.dumps`, never the LLM — a straight `"` in a `draft_sentence` would otherwise break a hand-built manifest's `json.loads` and kill the verify phase.

A `writer-outline-v{N}.json` is persisted by the composer's Phase 1 before any draft `Write` attempt — this is the **outline-recovery contract**. If the composer crashes between outlining and drafting, re-running this skill detects the leftover outline and re-dispatches the composer with `RESUME_FROM_OUTLINE=true` so only Phase 2 runs.

`citation-manifest.json` shape (consumed by the `wiki-verifier`):

```json
{
  "schema_version": "0.1.1",
  "draft_version": 1,
  "citations": [
    {"id": "cit-001", "draft_position": "02:03", "draft_sentence": "Article 6 classifies a system as high-risk…<sup>[1](https://…)</sup>.", "wiki_slug": "eu-ai-act-article-6", "claim_id": "clm-001", "url": "https://…"}
  ]
}
```

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 5 — `knowledge-compose`" and `references/claim-at-ingest.md` once to anchor on the contract.

## When to run

- `<project>/.metadata/ingest-manifest.json` exists with non-empty `ingested[]` (Phase 4 has run) AND either no draft yet OR the user explicitly wants a new draft version.
- User explicitly invokes `/cogni-knowledge:knowledge-compose`.

## Never run when

- No `<project>/.metadata/plan.json` — offer `knowledge-plan` first.
- No `<project>/.metadata/ingest-manifest.json` or `ingested[]` empty — offer `knowledge-ingest` first.
- No `binding.json` at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--target-words` | No | Soft target word count. Default reads `target_words` from `plan.json` if present, else `4000`. Floor under `standard` density, ceiling under `executive`. Under `standard`, a floor deficit may trigger ONE bounded expansion re-dispatch (Step 5.5); under `executive` it is advisory with no re-dispatch. |
| `--no-expand` | No | Skip the Step 5.5 bounded floor-expansion. Default: OFF (expansion may run under `standard` density on a real deficit). Pass to keep the single composer pass even when the draft lands under the floor (e.g. you want the advisory shortfall surfaced without a re-roll). Mirrors finalize's `--no-reviewer`/`--no-contradictor`. |
| `--prose-density` | No | Override `plan.json::prose_density` for this draft: `standard` (floor, cite aggressively) or `executive` (BLUF + Pyramid ceiling, one citation per claim). Default reads `plan.json`, else `standard`. |
| `--tone` | No | Override `plan.json::tone` for this draft (see `references/writing-tones.md`). Default reads `plan.json`, else `objective`. |
| `--citation-format` | No | Override `plan.json::citation_format`: `ieee`/`chicago` (wired) or `apa`/`mla`/`harvard` (staged). Default reads `plan.json`, else `ieee`. |
| `--draft-version` | No | Force a specific draft version N. Default: `max(existing output/draft-v*.md) + 1`, or `1`. |
| `--dry-run` | No | Print the resolved inputs (WIKI_ROOT, DRAFT_VERSION, RESUME_FROM_OUTLINE) without dispatching the composer. |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break — no cogni-research, no cogni-claims):

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK=no`, abort with the standard missing-plugin message.

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-ingest`). Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`.

Parse `data.binding.wiki_path` as `WIKI_ROOT`. Confirm `<WIKI_ROOT>/.cogni-wiki/config.json` exists; abort otherwise. Confirm `<WIKI_ROOT>/wiki/` exists.

**Project manifests.** Confirm both files exist; abort with "run knowledge-plan first" / "run knowledge-ingest first" otherwise:

- `<project_path>/.metadata/plan.json`
- `<project_path>/.metadata/ingest-manifest.json`

Read `ingest-manifest.json`. If `ingested[]` is empty, abort with "no ingested sources to compose from — re-run knowledge-ingest".

### 1. Resolve draft version N

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PROJECT_PATH="<project_path>" \
python3 -c '
import os, re
from pathlib import Path
out = Path(os.environ["PROJECT_PATH"]) / "output"
existing = sorted(int(m.group(1)) for p in out.glob("draft-v*.md")
                  for m in [re.match(r"draft-v(\d+)\.md$", p.name)] if m)
print(existing[-1] + 1 if existing else 1)
'
```

If `--draft-version` is passed, use that integer instead and overwrite any existing file with the same N (the user asked for it explicitly).

### 2. Outline-recovery check

Check for `<project_path>/.metadata/writer-outline-v{N}.json`:

- **Exists** (and `--draft-version` is the same N): a prior dispatch wrote the outline before crashing. Pass `RESUME_FROM_OUTLINE=true` to the composer so Phase 1 is skipped. Surface this in the dry-run summary and the final summary — the operator should know a recovery happened.
- **Absent**: the composer runs both phases. Pass `RESUME_FROM_OUTLINE=false` (or omit; the agent treats unset as `false`).

If `--dry-run`, print the resolved inputs:

```
WIKI_ROOT=<wiki_root>
PROJECT_PATH=<project_path>
DRAFT_VERSION=<N>
RESUME_FROM_OUTLINE=<true|false>
TARGET_WORDS=<resolved>
PROSE_DENSITY=<resolved>
TONE=<resolved>
CITATION_FORMAT=<resolved>
OUTPUT_LANGUAGE=<resolved>
INGESTED_SOURCES=<count from ingest-manifest.json>
```

and stop.

### 3. Resolve composer knobs (TARGET_WORDS, PROSE_DENSITY, TONE, CITATION_FORMAT)

Each knob resolves `--<flag>` if passed, else the matching `plan.json` field, else the hard default. They were already resolved + validated in `knowledge-plan` Step 0.5 and written to `plan.json`, so this is a read-with-override (the `--flag` lets an operator re-compose a single draft with a different knob without re-planning):

| Knob | `--flag` | `plan.json` field | Default |
|---|---|---|---|
| `TARGET_WORDS` | `--target-words` | `target_words` | `4000` |
| `PROSE_DENSITY` | `--prose-density` | `prose_density` | `standard` |
| `TONE` | `--tone` | `tone` | `objective` |
| `CITATION_FORMAT` | `--citation-format` | `citation_format` | `ieee` |

`TARGET_WORDS` is a **soft target** — a floor under `standard`, a ceiling under `executive`. The composer itself is single-pass per dispatch; under `standard` density a floor deficit may trigger ONE bounded expansion re-dispatch in Step 5.5 (below), but never under `executive` (a ceiling has no shortfall to close). `CITATION_FORMAT` is now **live**: `ieee`/`chicago` render end-to-end (the composer differs only in the reference-list string); `apa`/`mla`/`harvard` are accepted but render as numbered until the author-date follow-up lands (`references/citation-formats.md`).

### 4. Dispatch wiki-composer (single Task call)

Dispatch via the `Task` tool (matches the upstream `knowledge-ingest` / `knowledge-fetch` agent-dispatch convention):

```
Task(wiki-composer,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<N>,
     TARGET_WORDS=<resolved>,
     PROSE_DENSITY=<resolved, default standard>,
     TONE=<resolved, default objective>,
     CITATION_FORMAT=<resolved, default ieee>,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>,
     RESUME_FROM_OUTLINE=<true|false>)
```

`OUTPUT_LANGUAGE` is read from `<project_path>/.metadata/plan.json` (`output_language`, default `en` — the same value `knowledge-finalize` reads for its reference heading). It controls the draft body, section headings, and the reference-section heading. `PROSE_DENSITY` / `TONE` / `CITATION_FORMAT` (Step 3) shape the draft's structural discipline, rhetorical register, and citation rendering respectively — all single-pass (the composer never loops on any of them). The agent derives the plan and ingest-manifest paths from `PROJECT_PATH` (fixed `.metadata/plan.json` and `.metadata/ingest-manifest.json`). `wiki-composer` lives at `${CLAUDE_PLUGIN_ROOT}/agents/wiki-composer.md` — dispatched via `Task`, not `Skill`. Single-pass, no fan-out, no per-section sharding — the agent reads the wiki itself and writes both output files atomically.

Parse the return envelope:

- `ok: true` → continue to Step 4.5 (build the manifest).
- `ok: false, error: "no_ingested_sources"` → re-emit the abort message and stop (shouldn't happen if Step 0 ran, but defence-in-depth).
- `ok: false, error: "write_failed"` → surface the reason; do not retry blindly. The composer already retried once internally. Direct the user to inspect output token-budget conditions or re-run.
- `ok: false, error: "outline_write_failed"` → surface; no recovery in this slice (Phase 1 couldn't even land the outline).

### 4.5 Build citation-manifest.json from the composer's records

The composer wrote a raw-text **citation-records** file (`<project_path>/.metadata/citation-records-v<N>.txt`), never JSON — so a `draft_sentence` containing a straight `"` (routine in German/FR/IT/ES/PL prose) can't break the manifest. Serialize and self-check the manifest with `citation-store.py build`. Paths go via env vars so spaces / apostrophes in project paths can't break the literal:

```
RECORDS_PATH="<project_path>/.metadata/citation-records-v<N>.txt" \
DRAFT_PATH="<project_path>/output/draft-v<N>.md" \
OUT_PATH="<project_path>/.metadata/citation-manifest.json" \
INGEST_PATH="<project_path>/.metadata/ingest-manifest.json" \
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/citation-store.py build \
    --records "$RECORDS_PATH" --draft "$DRAFT_PATH" --out "$OUT_PATH" --draft-version <N> \
    --ingest-manifest "$INGEST_PATH"
```

`citation-store.py build` parses the records, `json.dumps` the manifest (`ensure_ascii=False` — escaping owned by the serializer, never the LLM), asserts every `draft_sentence` is a verbatim substring of the draft, **asserts every inline citation URL is a known ingested-source URL** (the `--ingest-manifest` gate; the composer must copy each cited page's real `sources:` URL, never reconstruct it from the slug), and round-trips the file it wrote (`json.loads` + count). Parse the envelope:

- `success: true` → capture `data.citations_count` (the authoritative count) **and `data.claim_kinds`** (the per-kind breakdown — `{distilled, source, answer, null, other}`, keyed by `claim_id` prefix; `distilled` is the `dcl-NNN` cross-source-convergence count and `answer` is the `acl-NNN` question-node answer-citation count (#432 Slice 2 activation) — both surfaced in Step 6 + Step 7) and continue to Step 5.
- `success: false, error: "write_failed"` → surface `error` + `data` (e.g. `failed_check: "sentence_not_in_draft"` with the offending `ids`; or `failed_check: "url_not_in_sources"` with the offending `urls` — an inline citation URL the composer slug-derived instead of copying the cited page's `sources:` value) verbatim and **stop** — do not auto-retry. A sentence the composer claims to have written verbatim is not in the draft it just wrote, the manifest did not round-trip, or a cited URL is not a real ingested source (re-compose).
- `success: false, error: "records_not_found"` / `"draft_not_found"` → surface and stop; the composer's write did not land (re-run the composer).

**Reconcile the count.** Compare the composer's returned `citations` (its own tally) against `data.citations_count` (the authoritative manifest length). If they differ, surface a `⚠ citation count mismatch: composer claimed <X>, manifest built <Y>` line — a smaller manifest count points at a phantom/truncated records write (records the composer thought it wrote but didn't land), which would otherwise sail through as a silently-undersized manifest. Do not hard-fail (the composer's count is an LLM tally and may be slightly off), but the operator must see the discrepancy.

### 5. Verify outputs on disk

One Python subprocess validates all three artefacts (draft non-empty + carries a `[[sources/` wikilink; citation-manifest parses with `schema_version ∈ {"0.1.0", "0.1.1"}` and a list-typed `citations[]` each carrying `id` / `draft_sentence` / `wiki_slug` / `claim_id` and a `draft_sentence` that is a verbatim NFC substring of the draft; outline file is on disk). An empty `citations[]` is NOT a hard fail — it emits a stderr `WARN` line and surfaces in the final summary per the edge-case section below (zero claims is an upstream-data symptom, not a composer bug). On any structural failure, the subprocess exits non-zero with the assertion message; surface verbatim in the summary and stop — do not auto-retry. Paths go via env vars so spaces / apostrophes in project paths can't break the Python literal:

```
DRAFT_PATH="<project_path>/output/draft-v<N>.md" \
MANIFEST_PATH="<project_path>/.metadata/citation-manifest.json" \
OUTLINE_PATH="<project_path>/.metadata/writer-outline-v<N>.json" \
python3 -c '
import json, os, sys, unicodedata
from pathlib import Path
draft    = Path(os.environ["DRAFT_PATH"])
manifest = Path(os.environ["MANIFEST_PATH"])
outline  = Path(os.environ["OUTLINE_PATH"])
assert draft.exists() and draft.stat().st_size > 0, f"draft missing or empty: {draft}"
dtext = draft.read_text(encoding="utf-8")
assert "[[sources/" in dtext, "draft contains no [[sources/...]] wikilink"
nfc_draft = unicodedata.normalize("NFC", dtext)
m = json.loads(manifest.read_text(encoding="utf-8"))
schema = m.get("schema_version")
assert schema in ("0.1.0", "0.1.1"), "bad schema: " + repr(schema)
cites = m.get("citations", [])
assert isinstance(cites, list), "citations must be a list, got " + type(cites).__name__
for c in cites:
    assert "id" in c and "draft_sentence" in c and "wiki_slug" in c and "claim_id" in c, c
    # Authoritative gate: citation-store.py already builds + self-checks the
    # manifest, but re-assert here that every draft_sentence is a verbatim (NFC)
    # substring of the draft so a future regression cannot ship a stale surface.
    assert unicodedata.normalize("NFC", c["draft_sentence"]) in nfc_draft, "draft_sentence not in draft: " + repr(c.get("id"))
assert outline.exists(), f"outline missing: {outline}"
if not cites:
    print("WARN: citations[] empty — every cited statement will fail verification", file=sys.stderr)
print(len(cites))
'
```

The trailing `print(len(cites))` is captured for the final summary's `citations` count; the stderr `WARN` line is captured separately so the summary can surface the `⚠ Zero citations` line documented in the edge-case section below.

### 5.5 Bounded floor-expansion (standard density only — capped at ONE, fail-soft)

A `standard`-density draft that lands well under its word floor is thin in *treatment*, not coverage (every sub-question is present and cited — the deficit is breadth). This step closes that gap **during compose** with ONE bounded, zero-network expansion pass, so the downstream `knowledge-verify` re-verifies the expanded draft naturally and finalize's `wiki-reviewer` becomes an advisory backstop rather than a dead-end detector. It cannot pull new evidence (cogni-knowledge is zero-network) — it only re-elaborates claims already on the wiki, so it fixes "treatment too thin", not "wiki too sparse" (the latter routes to more ingestion via `knowledge-curate`/`-fetch`).

**Skip this step entirely (proceed to Step 6 with `draft-vN`) when ANY of:**
- `--no-expand` was passed → log `expansion skipped: --no-expand`.
- `PROSE_DENSITY != standard` (a ceiling has no floor deficit) → log `expansion skipped: density=<PROSE_DENSITY>`.
- This dispatch is already an expansion round (defence-in-depth against a manual re-entry) → log `expansion skipped: already an expansion round`.

**Gate (fire only when BOTH hold):** the composer's returned `words < TARGET_WORDS × 0.85` **AND** the composer's returned `ceiling_hit == false`. If `words ≥ TARGET_WORDS × 0.85`, skip silently (the floor is effectively met). If `ceiling_hit == true`, skip with `expansion skipped: at single-call ceiling — raise coverage via more ingestion (knowledge-curate/-fetch)` — re-rolling the composer cannot fit more words in one call; the fix is more wiki coverage.

This `0.85` is the **real-deficit actuator trigger** and is deliberately independent of the `wiki-reviewer` advisory Word-Count Gate's tiered completeness caps (finalize Step 10.7, which scores the *post*-expansion draft): the two thresholds serve different roles — actuator vs advisory backstop — and a future tweak to one need not track the other.

**Derive the thin sections** from the just-written outline `<project_path>/.metadata/writer-outline-v<N>.json` — the topical sections whose `drafted_words < budget × 0.9`, excluding the References section (`covers_sub_questions: []`). Paths via env vars:

```
OUTLINE_PATH="<project_path>/.metadata/writer-outline-v<N>.json" \
python3 -c '
import json, os
from pathlib import Path
o = json.loads(Path(os.environ["OUTLINE_PATH"]).read_text(encoding="utf-8"))
# Evidence-bearing sections = any section covering ≥1 sub-question (this excludes
# only the structural References section, covers_sub_questions: []). Synthesis
# sections (Introduction / cross-cutting / Conclusion) also cover sub-questions,
# so they remain eligible — but their budgets (400–800w) run smaller than topical
# body sections (600–1200w), so the budget-ordered fallback below naturally
# prefers the body sections without a fragile heading/cluster-count heuristic.
topical = [s for s in o.get("sections", [])
           if s.get("covers_sub_questions")
           and isinstance(s.get("budget"), int)]
thin = [s for s in topical
        if isinstance(s.get("drafted_words"), int)
        and s["drafted_words"] < s["budget"] * 0.9]
# Fallback: the Step-5.5 gate already established a real TOTAL deficit, but no
# section is individually flagged thin — deepen the largest-budget sections so a
# real deficit still gets an expansion attempt. This covers the RESUME_FROM_OUTLINE
# path (and any composer that under-reports per-section drafted_words), where
# drafted_words may be null/unfilled and thin comes back empty on a genuine shortfall.
chosen = thin if thin else sorted(topical, key=lambda s: s["budget"], reverse=True)[:3]
print(",".join(str(s["index"]) for s in chosen))
'
```

Capture this as `EXPAND_SECTIONS` and compute `WORD_DEFICIT = TARGET_WORDS - words`. The fallback to the largest topical sections by budget means a real total deficit normally yields a non-empty `EXPAND_SECTIONS` even when no section is individually under-budget (the actuator's effectiveness no longer depends on the composer reliably populating every `sections[].drafted_words`). If `EXPAND_SECTIONS` is still empty — the degenerate case where the outline carries no topical section with a valid integer `budget` — skip with `expansion skipped: no topical section in the outline to deepen` — there is nothing to target.

**Re-dispatch the composer ONCE** at `N+1` in expansion mode (same knob values as Step 4):

```
Task(wiki-composer,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<N+1>,
     EXPANSION_MODE=true,
     BASELINE_DRAFT_VERSION=<N>,
     EXPAND_SECTIONS=<comma-list>,
     WORD_DEFICIT=<TARGET_WORDS - words>,
     TARGET_WORDS=<resolved>,
     PROSE_DENSITY=<resolved>,
     TONE=<resolved>,
     CITATION_FORMAT=<resolved>,
     OUTPUT_LANGUAGE=<resolved>)
```

**Snapshot the canonical manifest before the re-dispatch.** A successful `N+1` build overwrites `citation-manifest.json` (to describe `v<N+1>`) *before* Step 5 runs, so a copy of the current (`vN`) manifest is the only way a failed expansion can restore consistent `vN` state — the same discipline `knowledge-verify` uses before a revise round (`.citation-manifest.pre-r<round>.json`):

```
cp "<project_path>/.metadata/citation-manifest.json" \
   "<project_path>/.metadata/.citation-manifest.pre-expand.json"
```

On `ok: true`, **re-run Step 4.5** (`citation-store.py build … --draft-version <N+1>` with the same `--ingest-manifest` gate, writing the canonical `citation-manifest.json` from `citation-records-v<N+1>.txt`) **and Step 5** (the on-disk verifier) against `v<N+1>`. Keep `v<N+1>` only when **both pass AND it grew the draft** (`words<N+1> > words<N>` — a re-roll that did not add words is treated as a failure below). On success, `v<N+1>` becomes the canonical latest draft — set `N := N+1` so Steps 6/7 report on it, then drop the now-stale snapshot:

```
rm -f "<project_path>/.metadata/.citation-manifest.pre-expand.json"
```

**Cap = 1; fail-soft (the orchestrator must leave `vN` AND its matching manifest as the canonical state on any failure):** if the expansion dispatch returns `ok: false`, OR its Step-4.5 manifest build is rejected, OR its Step-5 on-disk verify fails, OR it did not grow the draft (`words<N+1> ≤ words<N>`) — **remove the partial `v<N+1>` artifacts** (`output/draft-v<N+1>.md`, `.metadata/citation-records-v<N+1>.txt`, `.metadata/writer-outline-v<N+1>.json`) so the latest-draft resolver lands back on `vN`, **and restore the snapshot** so the canonical `citation-manifest.json` describes `vN` again:

```
mv "<project_path>/.metadata/.citation-manifest.pre-expand.json" \
   "<project_path>/.metadata/citation-manifest.json"
```

then log `⚠ expansion failed — kept draft-vN (manifest restored)` (or `⚠ expansion did not grow the draft — kept draft-vN (manifest restored)` on the no-growth branch) and proceed to Step 6 with `vN`. The restore is load-bearing precisely in the build-OK-but-verify-fail (and no-growth) window: a successful `N+1` build has *already* overwritten `citation-manifest.json` to describe the about-to-be-removed `draft-v<N+1>`, so removing the artifacts alone would leave a stale manifest pointing at a deleted draft (its `draft_sentence`s no longer verbatim substrings of `vN`), breaking the downstream `knowledge-verify`/`knowledge-finalize` read. (After a *rejected* `N+1` build the manifest is still the `vN` one — `citation-store.py build` writes only on success — but the unconditional restore is correct there too: it simply moves the snapshot back over an identical file.)

### 6. Append wiki/log.md

Append one summary line (Bash `>>` append; `wiki/log.md` is append-only by cogni-wiki convention):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_WORDS=<words from composer return>
N_CITES=<the script-derived count from Step 5's print(len(cites)) — NOT the composer return's "citations" field>
N_DCL=<data.claim_kinds.distilled from Step 4.5, default 0>
N_ACL=<data.claim_kinds.answer from Step 4.5, default 0>
echo "## [${DATE_STAMP}] compose | project=${TOPIC} draft=v${N} words=${N_WORDS} citations=${N_CITES} dcl=${N_DCL} acl=${N_ACL}" >> "${WIKI_ROOT}/wiki/log.md"
```

The `dcl=<n>` suffix is the cross-run record of the distilled-citation rate, and `acl=<n>` the question-node answer-citation rate — the cross-source-convergence loops firing (or not) show up directly in `wiki/log.md`.

Note on the `compose` prefix: cogni-wiki's log-format enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") does not yet list `compose`, but readers count unknown prefixes in their catch-all bucket without crashing — `compose` is additive and safe.

### 7. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Draft: `output/draft-v<N>.md` (`<N_WORDS>` words across `<N_SECTIONS>` sections)
- Citations: `<N_CITES>` (authoritative count = `len(citation-manifest.json::citations)`, from Step 5)
- Distilled citations: `<N_DCL>` of `<N_CITES>` (`dcl-NNN` cross-source convergence cited directly, from Step 4.5's `data.claim_kinds.distilled`) — `0` on a base with no distilled pages is expected; `0` on a base with distilled pages whose claims show ≥2 backlinks is the inert-loop symptom the operator should notice (the cross-source-convergence evidence is never load-bearing).
- Answer citations: `<N_ACL>` of `<N_CITES>` (`acl-NNN` question-node answers cited directly, from Step 4.5's `data.claim_kinds.answer`) — `0` on a base whose question nodes carry no `answer_claims:` is expected; `0` on a base with `answer_claims:` whose claims show ≥2 backlinks is the inert symptom the operator should notice (same posture as the distilled-citation rate above).
- Outline: `.metadata/writer-outline-v<N>.json` (outline-recovery anchor; recovery used: `<RESUME_FROM_OUTLINE>`)
- Expansion (standard density only): one of `floor-expansion ran (vN-1 → vN, deepened <sections>)` / `expansion skipped: <reason>` / `⚠ expansion failed — kept draft-vN (manifest restored)` / `⚠ expansion did not grow the draft — kept draft-vN (manifest restored)` — from Step 5.5; omit the line on a non-`standard` density run.
- Cost: `$X.XXX` (from composer return; accumulate the expansion dispatch's `cost_estimate` when it ran)
- Next: `knowledge-verify` will run zero-network claim alignment by reading the citation manifest + each cited page's claim block — `pre_extracted_claims[]` on a source/synthesis page, `distilled_claims[]` on a cited distilled page, or `answer_claims[]` on a cited question node.

Surface a density-aware word-count warning from the composer's returned `words` — but do not auto-retry:
- Under `PROSE_DENSITY=standard`: if `words` is well below `TARGET_WORDS` (the floor), `⚠ Below target (N/TARGET)`.
- Under `PROSE_DENSITY=executive`: if `words` is over `TARGET_WORDS` (the ceiling), `⚠ Over ceiling (N/TARGET)`. Under-ceiling is the correct executive outcome — no warning.

Under `standard` density this warning reflects the **post-expansion** draft (Step 5.5 already attempted to close a real deficit), so a residual `⚠ Below target` here means the wiki lacked the uncited evidence to deepen further — a coverage signal, not a composer miss. The advisory `wiki-reviewer` (finalize Step 10.7) independently re-scores this with its Word Count Gate as the advisory backstop; the compose-time line is a fast heads-up, not a gate.

## Edge cases

- **Outline recovery in action.** The outline file exists from a prior crashed run. The composer skips Phase 1 (saves model time and avoids re-deriving the section plan), runs Phase 2 fresh, and writes the draft + citation manifest. The outline's `drafted_words` placeholders get filled by the resume pass. Surface "RESUME_FROM_OUTLINE=true (outline recovery)" in the summary so the operator sees what happened.
- **Re-run with same N.** The user explicitly passes `--draft-version <N>` against an existing draft. The composer overwrites `draft-v<N>.md` and `citation-manifest.json` (and re-writes the outline — Phase 1 runs unless `writer-outline-v<N>.json` is present and `RESUME_FROM_OUTLINE=true` was inferred). No automatic backup — the user asked for it.
- **Empty `ingested[]` after a re-ingest cleanup.** Step 0 aborts with the "no ingested sources" message; do not dispatch the composer against an empty manifest.
- **Citation manifest empty.** If the composer returns `ok: true` but `citations[] == 0` (every cited page had zero claims — no source `pre_extracted_claims:` and no distilled `distilled_claims:` — unusual but possible if the claim-extractor failed across the board), surface as `⚠ Zero citations — every cited statement will fail verification`. Do not block — that's an upstream-data issue, not a composer bug.
- **Plan changed between ingest and compose.** Step 1.2 of the composer aligns `covers_sub_questions` from `ingest-manifest.json` (resolved sources carry `sub_question_refs[]`), so a sub-question added to `plan.json` after `knowledge-ingest` ran will have no sources mapped to it. The introduction and conclusion still list it (synthesis sections list all `plan.json` sub-question ids), but a topical section for that sub-question won't have evidence. Surface in the summary as `⚠ Sub-question <id> has no ingested sources`.

## Out of scope

- Does NOT verify citations — Phase 6 (`knowledge-verify`).
- Does NOT deposit the draft into the wiki as `wiki/syntheses/<slug>.md` — Phase 7 (`knowledge-finalize`).
- Does NOT modify `binding.json` — Phase 7 appends the project entry.
- Does NOT re-run any earlier phase.
- Does NOT run an unbounded expansion loop or story arcs — the composer is single-pass per dispatch. Under `standard` density this skill runs ONE bounded, fail-soft, zero-network floor-expansion (Step 5.5) on a real deficit with headroom; `prose_density: executive` shapes that single pass (BLUF + Pyramid ceiling) and adds **no** re-dispatch (a ceiling has no shortfall to close). The expansion re-elaborates existing wiki claims only — it never fetches new evidence (that is `knowledge-curate`/`-fetch`'s job).

## Output

- `<project_path>/output/draft-v<N>.md`
- `<project_path>/.metadata/citation-records-v<N>.txt` (composer's raw-text records; input to `citation-store.py build`)
- `<project_path>/.metadata/citation-manifest.json` (schema 0.1.0; built by `citation-store.py build`)
- `<project_path>/.metadata/writer-outline-v<N>.json` (outline-recovery anchor)
- One new `## [YYYY-MM-DD] compose | …` line in `<WIKI_ROOT>/wiki/log.md`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 5 contract
- `${CLAUDE_PLUGIN_ROOT}/references/claim-at-ingest.md` — claim shape on the wiki page
- `${CLAUDE_PLUGIN_ROOT}/references/writing-tones.md` — the `TONE` catalog threaded to the composer
- `${CLAUDE_PLUGIN_ROOT}/references/citation-formats.md` — the `CITATION_FORMAT` menu (ieee/chicago wired)
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — remaining deferrals (story arcs, author-date citation rendering, expansion loops)
- `${CLAUDE_PLUGIN_ROOT}/agents/wiki-composer.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/citation-store.py --help` — builds + self-checks citation-manifest.json
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
