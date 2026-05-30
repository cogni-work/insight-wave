---
name: knowledge-compose
description: "Phase 5 of the inverted pipeline. Reads <project>/.metadata/plan.json + <project>/.metadata/ingest-manifest.json + the populated cogni-wiki, dispatches a single wiki-composer pass, and lands <project>/output/draft-vN.md + <project>/.metadata/citation-manifest.json. Inline citations are clickable numbered [N] markers; [[sources/<slug>]] wikilinks live only in the reference list. Output language + reference heading follow plan.json::output_language (threaded as OUTPUT_LANGUAGE). Preserves the outline-recovery contract — a leftover writer-outline-vN.json from a crashed prior run causes Phase 1 of the composer to be skipped. Use this skill whenever the user says 'compose the draft', 'write the report from the wiki', 'phase 5 of the knowledge pipeline', 'knowledge compose', 'draft v1', or 'run the writer'. After compose, knowledge-verify will run the zero-network claim alignment."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Compose

Phase 5 of the inverted pipeline. Reads the per-project `plan.json` + `ingest-manifest.json` + the populated wiki at `<binding.wiki_path>/wiki/`, dispatches `wiki-composer` once, and verifies the two output files land on disk. The composer reads `wiki/index.md` + selected `wiki/sources/*.md` (lazily) + prior `wiki/syntheses/*.md` — and, since the distillation interphase (`knowledge-distill`), the distilled `wiki/concepts/*.md` + `wiki/entities/*.md` pages as **framing context only** (topic-matched, lazily). Concept/entity pages shape the narrative but are **never cited**: they carry `distilled_claims:` (not `pre_extracted_claims:`), are absent from the citation manifest, and the verifier does not score them — so Phases 5/6/7 stay byte-stable whether or not distill ran. The composer then writes:

- `<project>/output/draft-v{N}.md` — the draft, with clickable numbered `[N]` inline citations (wikilinks confined to the reference list).
- `<project>/.metadata/citation-records-v{N}.txt` — one raw-text record per citation (the composer writes this; it never hand-builds JSON). This skill then runs `citation-store.py build` to serialize and validate `<project>/.metadata/citation-manifest.json` (schema `0.1.0`, one `{id, draft_position, draft_sentence, wiki_slug, claim_id}` entry per citation). Escaping is owned by `json.dumps`, never the LLM — a straight `"` in a `draft_sentence` would otherwise break a hand-built manifest's `json.loads` and kill the verify phase.

A `writer-outline-v{N}.json` is persisted by the composer's Phase 1 before any draft `Write` attempt — this is the **outline-recovery contract**. If the composer crashes between outlining and drafting, re-running this skill detects the leftover outline and re-dispatches the composer with `RESUME_FROM_OUTLINE=true` so only Phase 2 runs.

`citation-manifest.json` shape (consumed by the `wiki-verifier`):

```json
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "citations": [
    {"id": "cit-001", "draft_position": "02:03", "draft_sentence": "Article 6 classifies a system as high-risk…<sup>[1](https://…)</sup>.", "wiki_slug": "eu-ai-act-article-6", "claim_id": "clm-001"}
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
| `--target-words` | No | Soft target word count. Default reads `target_words` from `plan.json` if present, else `5000`. Advisory — no re-dispatch on shortfall. |
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
INGESTED_SOURCES=<count from ingest-manifest.json>
```

and stop.

### 3. Resolve TARGET_WORDS

Order of resolution:

1. `--target-words` if passed.
2. `plan.json` `target_words` if present.
3. Default `5000`.

This is a **soft target** — the composer does not re-dispatch on shortfall.

### 4. Dispatch wiki-composer (single Task call)

Dispatch via the `Task` tool (matches the upstream `knowledge-ingest` / `knowledge-fetch` agent-dispatch convention):

```
Task(wiki-composer,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<N>,
     TARGET_WORDS=<resolved>,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>,
     RESUME_FROM_OUTLINE=<true|false>)
```

`OUTPUT_LANGUAGE` is read from `<project_path>/.metadata/plan.json` (`output_language`, default `en` — the same value `knowledge-finalize` reads for its reference heading). It controls the draft body, section headings, and the reference-section heading. The agent derives the plan and ingest-manifest paths from `PROJECT_PATH` (fixed `.metadata/plan.json` and `.metadata/ingest-manifest.json`). `wiki-composer` lives at `${CLAUDE_PLUGIN_ROOT}/agents/wiki-composer.md` — dispatched via `Task`, not `Skill`. Single-pass, no fan-out, no per-section sharding — the agent reads the wiki itself and writes both output files atomically.

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
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/citation-store.py build \
    --records "$RECORDS_PATH" --draft "$DRAFT_PATH" --out "$OUT_PATH" --draft-version <N>
```

`citation-store.py build` parses the records, `json.dumps` the manifest (`ensure_ascii=False` — escaping owned by the serializer, never the LLM), asserts every `draft_sentence` is a verbatim substring of the draft, and round-trips the file it wrote (`json.loads` + count). Parse the envelope:

- `success: true` → capture `data.citations_count` (the authoritative count) and continue to Step 5.
- `success: false, error: "write_failed"` → surface `error` + `data` (e.g. `failed_check: "sentence_not_in_draft"` with the offending `ids`) verbatim and **stop** — do not auto-retry. A sentence the composer claims to have written verbatim is not in the draft it just wrote, or the manifest did not round-trip.
- `success: false, error: "records_not_found"` / `"draft_not_found"` → surface and stop; the composer's write did not land (re-run the composer).

**Reconcile the count.** Compare the composer's returned `citations` (its own tally) against `data.citations_count` (the authoritative manifest length). If they differ, surface a `⚠ citation count mismatch: composer claimed <X>, manifest built <Y>` line — a smaller manifest count points at a phantom/truncated records write (records the composer thought it wrote but didn't land), which would otherwise sail through as a silently-undersized manifest. Do not hard-fail (the composer's count is an LLM tally and may be slightly off), but the operator must see the discrepancy.

### 5. Verify outputs on disk

One Python subprocess validates all three artefacts (draft non-empty + carries a `[[sources/` wikilink; citation-manifest parses with `schema_version == "0.1.0"` and a list-typed `citations[]` each carrying `id` / `draft_sentence` / `wiki_slug` / `claim_id` and a `draft_sentence` that is a verbatim NFC substring of the draft; outline file is on disk). An empty `citations[]` is NOT a hard fail — it emits a stderr `WARN` line and surfaces in the final summary per the edge-case section below (zero claims is an upstream-data symptom, not a composer bug). On any structural failure, the subprocess exits non-zero with the assertion message; surface verbatim in the summary and stop — do not auto-retry. Paths go via env vars so spaces / apostrophes in project paths can't break the Python literal:

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
assert schema == "0.1.0", "bad schema: " + repr(schema)
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

### 6. Append wiki/log.md

Append one summary line (Bash `>>` append; `wiki/log.md` is append-only by cogni-wiki convention):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_WORDS=<words from composer return>
N_CITES=<the script-derived count from Step 5's print(len(cites)) — NOT the composer return's "citations" field>
echo "## [${DATE_STAMP}] compose | project=${TOPIC} draft=v${N} words=${N_WORDS} citations=${N_CITES}" >> "${WIKI_ROOT}/wiki/log.md"
```

Note on the `compose` prefix: cogni-wiki's log-format enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") does not yet list `compose`, but the same paragraph notes that "pre-v0.0.35 readers count unknown prefixes in their catch-all bucket without crashing" — `compose` is additive and safe.

### 7. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Draft: `output/draft-v<N>.md` (`<N_WORDS>` words across `<N_SECTIONS>` sections)
- Citations: `<N_CITES>` (authoritative count = `len(citation-manifest.json::citations)`, from Step 5)
- Outline: `.metadata/writer-outline-v<N>.json` (outline-recovery anchor; recovery used: `<RESUME_FROM_OUTLINE>`)
- Cost: `$X.XXX` (from composer return)
- Next: `knowledge-verify` will run zero-network claim alignment by reading the citation manifest + each cited page's `pre_extracted_claims[]`.

If the composer returned a word-count well below `TARGET_WORDS`, surface a `⚠ Below target (N/TARGET)` warning line — but do not auto-retry.

## Edge cases

- **Outline recovery in action.** The outline file exists from a prior crashed run. The composer skips Phase 1 (saves model time and avoids re-deriving the section plan), runs Phase 2 fresh, and writes the draft + citation manifest. The outline's `drafted_words` placeholders get filled by the resume pass. Surface "RESUME_FROM_OUTLINE=true (outline recovery)" in the summary so the operator sees what happened.
- **Re-run with same N.** The user explicitly passes `--draft-version <N>` against an existing draft. The composer overwrites `draft-v<N>.md` and `citation-manifest.json` (and re-writes the outline — Phase 1 runs unless `writer-outline-v<N>.json` is present and `RESUME_FROM_OUTLINE=true` was inferred). No automatic backup — the user asked for it.
- **Empty `ingested[]` after a re-ingest cleanup.** Step 0 aborts with the "no ingested sources" message; do not dispatch the composer against an empty manifest.
- **Citation manifest empty.** If the composer returns `ok: true` but `citations[] == 0` (every page had zero `pre_extracted_claims:` — unusual but possible if the claim-extractor failed across the board), surface as `⚠ Zero citations — every cited statement will fail verification`. Do not block — that's an upstream-data issue, not a composer bug.
- **Plan changed between ingest and compose.** Step 1.2 of the composer aligns `covers_sub_questions` from `ingest-manifest.json` (resolved sources carry `sub_question_refs[]`), so a sub-question added to `plan.json` after `knowledge-ingest` ran will have no sources mapped to it. The introduction and conclusion still list it (synthesis sections list all `plan.json` sub-question ids), but a topical section for that sub-question won't have evidence. Surface in the summary as `⚠ Sub-question <id> has no ingested sources`.

## Out of scope

- Does NOT verify citations — Phase 6 (`knowledge-verify`).
- Does NOT deposit the draft into the wiki as `wiki/syntheses/<slug>.md` — Phase 7 (`knowledge-finalize`).
- Does NOT modify `binding.json` — Phase 7 appends the project entry.
- Does NOT re-run any earlier phase.
- Does NOT support executive density, story arcs, or expansion loops.

## Output

- `<project_path>/output/draft-v<N>.md`
- `<project_path>/.metadata/citation-records-v<N>.txt` (composer's raw-text records; input to `citation-store.py build`)
- `<project_path>/.metadata/citation-manifest.json` (schema 0.1.0; built by `citation-store.py build`)
- `<project_path>/.metadata/writer-outline-v<N>.json` (outline-recovery anchor)
- One new `## [YYYY-MM-DD] compose | …` line in `<WIKI_ROOT>/wiki/log.md`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 5 contract
- `${CLAUDE_PLUGIN_ROOT}/references/claim-at-ingest.md` — claim shape on the wiki page
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — deferrals (density, arcs, expansion)
- `${CLAUDE_PLUGIN_ROOT}/agents/wiki-composer.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/citation-store.py --help` — builds + self-checks citation-manifest.json
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
