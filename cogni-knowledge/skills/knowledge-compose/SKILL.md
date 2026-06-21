---
name: knowledge-compose
description: "Phase 5 of the inverted pipeline. Reads <project>/.metadata/plan.json + <project>/.metadata/ingest-manifest.json + the populated cogni-wiki, dispatches a wiki-composer pass (plus, under standard density, ONE bounded fail-soft zero-network coverage-gated re-dispatch when a sub-question has ingested evidence the draft left uncited — target_words is a soft upper budget, never a floor), and lands <project>/output/draft-vN.md + <project>/.metadata/citation-manifest.json. Inline citations are clickable numbered [N] markers; [[sources/<slug>]] wikilinks live only in the reference list. Surfaces the per-kind citation breakdown — the distilled-citation rate (dcl) and the question-node answer-citation rate (acl) — in its claim_kinds output, the wiki/log.md line, and the run summary. Output language + reference heading follow plan.json::output_language (threaded as OUTPUT_LANGUAGE). Preserves the outline-recovery contract — a leftover writer-outline-vN.json from a crashed prior run causes Phase 1 of the composer to be skipped. Supports --source wiki to compose a report grounded only in the bound wiki + fetch-cache with no web crawl (default web unchanged; local/hybrid staged). Use this skill whenever the user says 'compose the draft', 'write the report from the wiki', 'wiki-only report', 'compose from the wiki only', 'no web crawl report', 'phase 5 of the knowledge pipeline', 'knowledge compose', 'draft v1', or 'run the writer'. After compose, knowledge-verify will run the zero-network claim alignment."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Compose

Phase 5 of the inverted pipeline. Reads the per-project `plan.json` + `ingest-manifest.json` + the populated wiki at `<binding.wiki_path>/wiki/`, dispatches `wiki-composer` once, and verifies the output files land on disk.

The default `--source web` path composes from this run's web-ingested sources (the `ingest-manifest.json` Phase 4 produced). `--source wiki` is the **wiki-only rung** — a full structured, verified report grounded **only** in the already-populated wiki (`wiki/sources/*.md` + `wiki/syntheses/*.md` + distilled pages) and the `.cogni-knowledge/fetch-cache/`, with **no web crawl**: it preserves the retired `research-report --source wiki` capability so that capability does not vanish when cogni-research is archived.

The wiki-only mode does **not** change the composer or the verify/finalize tail at all. Instead, Step 0 **synthesizes** an `ingest-manifest.json` from the bound wiki's `wiki/sources/*.md` pages — mapping each source to the *current* plan's sub-questions via the shared `wiki-grounding` discovery primitive (`scripts/wiki-source-manifest.py`) — so the dispatched `wiki-composer` reads a normal manifest and runs byte-for-byte identically whether that manifest came from a web crawl or from the wiki. The composer does not branch on source mode and needs no new input. (See `--source` in Parameters and the Step 0 pre-flight.)

The composer reads `wiki/index.md` + selected `wiki/sources/*.md` (lazily) + prior `wiki/syntheses/*.md`. Since the distillation interphase (`knowledge-distill`), it also reads the distilled `wiki/{concepts,entities}/*.md` pages (topic-matched, lazily) — these serve **both** as narrative framing **and** as citable cross-source evidence: when ≥2 sources converge on a fact the distilled page already captures, the composer cites the distilled page itself via its `dcl-NNN` claim id, so the convergence carries epistemic weight rather than a row of source markers. Distilled pages carry `distilled_claims:` (not `pre_extracted_claims:`), and a distilled-page citation is scored by the verifier against that claim's `text`. Distillation stays optional and fail-soft: when it hasn't run, the composer simply has no distilled pages to draw on and composes from sources + syntheses alone.

The composer also reads the `type: question` nodes at `wiki/questions/*.md` (topic-matched, lazily) — first-class wiki pages each recording one research question the base has already explored, with `## Findings` `[[links]]` to the sources that answered it. These serve **both** as narrative framing **and** as a citable cross-source answer surface: a question node may carry an `answer_claims:` block (`acl-NNN` ids, synthesized by `knowledge-distill`), and when its `backlinks[]` list ≥2 distinct sources the composer cites the node directly via its `acl-NNN` claim — one citation carrying "N sources agree on the answer" — exactly mirroring the distilled-page rule just above. A single-source answer, or a question node with no `answer_claims:` block yet, stays framing-only: the composer reads it for orientation but cites the backing **source** page, never the node (an inline citation to a claim-less node would score `unsupported`). A question-node citation is scored by the verifier against that answer claim's `text`.

The composer then writes:

- `<project>/output/draft-v{N}.md` — the draft, with clickable numbered `[N]` inline citations (wikilinks confined to the reference list).
- `<project>/.metadata/citation-records-v{N}.txt` — one raw-text record per citation (the composer writes this; it never hand-builds JSON). This skill then runs `citation-store.py build` to serialize and validate `<project>/.metadata/citation-manifest.json` (schema `0.1.1`, one `{id, draft_position, draft_sentence, wiki_slug, claim_id, url}` entry per citation). Escaping is owned by `json.dumps`, never the LLM — a straight `"` in a `draft_sentence` would otherwise break a hand-built manifest's `json.loads` and kill the verify phase.

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

- **`web` mode (default):** `<project>/.metadata/ingest-manifest.json` exists with non-empty `ingested[]` (Phase 4 has run) AND either no draft yet OR the user explicitly wants a new draft version.
- **`--source wiki` mode:** the bound wiki has `wiki/sources/*.md` to compose from (Phase 4 ran for an earlier project on this base, or the wiki was populated by another path). No `ingest-manifest.json` is required — the wiki itself is the evidence base.
- User explicitly invokes `/cogni-knowledge:knowledge-compose`.

## Never run when

- No `<project>/.metadata/plan.json` — offer `knowledge-plan` first.
- **`web` mode only:** no `<project>/.metadata/ingest-manifest.json` or `ingested[]` empty — offer `knowledge-ingest` first. (Under `--source wiki` this is **not** a block — the wiki/sources/ glob is the evidence base; see the `--source wiki` gate below.)
- **`--source wiki` mode only:** the bound wiki has **no** `wiki/sources/*.md` pages — there is nothing to compose from. Offer `knowledge-ingest` (to web-ingest sources) or point the operator at a populated base.
- No `binding.json` at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--source` | No | Evidence source mode. `web` (default when omitted) is the standard inverted-pipeline path — compose from the web-ingested `ingest-manifest.json` sources. `wiki` is the **wiki-only rung**: compose a full structured report grounded **only** in the bound wiki (`wiki/sources/*.md` + `wiki/syntheses/*.md` + distilled pages) and the `.cogni-knowledge/fetch-cache/`, with **no web crawl** — the preserved `research-report --source wiki` capability. `local`/`hybrid` are **accepted but staged** (treated as `wiki` until implemented), mirroring the staged `apa`/`mla`/`harvard` citation formats. Omitting the flag is byte-identical to the prior behavior. |
| `--target-words` | No | Soft target word count. Default reads `target_words` from `plan.json` if present, else `2000`. A **soft upper budget** under `standard` density (never a floor — a tight, fully-grounded draft is the better outcome), a ceiling under `executive`. It drives no expansion under either density — Step 5.5 expands on a **coverage** deficit, not a word count. |
| `--no-expand` | No | Skip the Step 5.5 bounded coverage-gated expansion. Default: OFF (expansion may run under `standard` density when a sub-question has uncited ingested evidence). Pass to keep the single composer pass even when a coverage deficit exists. Mirrors finalize's `--no-reviewer`/`--no-contradictor`. |
| `--no-contradiction-surfacing` | No | Skip threading the ingest-time recency-survivor annotations into the composer. Default: OFF — when the project's `.metadata/contradiction-ingest.json` carries ≥1 recency-resolved contradiction, its path is threaded to the composer (Step 3.5) so the composer can build the recency-survivor map. Pass to suppress the surfacing entirely (dispatch byte-identical to the pre-surfacing form). Mirrors `--no-expand` / finalize's `--no-contradictor`. |
| `--contradiction-act` | No | **Mode-C opt-in (default OFF).** Gates whether the composer *acts* on the recency-survivor surfacing — i.e. actually prefers the more-recent **survivor** claim over a superseded **loser** for **high-severity** contradictions. Default OFF: the central `contradiction-ingest.json` is still threaded for the composer to read (observability), but Phase 2 never prefers a survivor (dispatch byte-identical to the pre-acting form). Pass to enable acting; only takes effect when a non-empty `CONTRADICTION_INGEST_PATH` also resolves (Step 3.5). Independent of `--no-contradiction-surfacing` (which suppresses the path — and therefore acting — entirely). |
| `--prose-density` | No | Override `plan.json::prose_density` for this draft: `standard` (soft upper budget, cite/ground every claim) or `executive` (BLUF + Pyramid ceiling, one citation per claim). Default reads `plan.json`, else `standard`. |
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

**Source mode.** Resolve `SOURCE_MODE` from `--source` (default `web` when the flag is absent — byte-identical to the prior behavior). `local`/`hybrid` are staged: when either is passed, print `staged: --source=<mode> treated as wiki (not yet implemented)` **here at pre-flight** (before any dispatch), then proceed as `wiki`. `SOURCE_MODE` decides how `<project_path>/.metadata/ingest-manifest.json` is obtained below — it does **not** change anything downstream of Step 0, because both modes hand the composer a normal manifest.

**Project manifests.** `<project_path>/.metadata/plan.json` is always required — abort with "run knowledge-plan first" otherwise. How the ingest manifest is obtained is **source-mode-dependent**, but the *result* is the same: a populated `<project_path>/.metadata/ingest-manifest.json` the composer reads in Step 4.

- **`SOURCE_MODE=web` (default):** confirm `<project_path>/.metadata/ingest-manifest.json` exists; read it and, if `ingested[]` is empty, abort with "no ingested sources to compose from — re-run knowledge-ingest". This is the unchanged web path — the manifest was produced by `knowledge-ingest` from a web crawl.
- **`SOURCE_MODE=wiki`:** **synthesize** the ingest manifest from the bound wiki (no web crawl) by mapping each `wiki/sources/*.md` page to the current plan's sub-questions via the shared `wiki-grounding` primitive:

  ```
  python3 ${CLAUDE_PLUGIN_ROOT}/scripts/wiki-source-manifest.py build \
      --wiki-root "<WIKI_ROOT>" \
      --plan "<project_path>/.metadata/plan.json" \
      --out "<project_path>/.metadata/ingest-manifest.json"
  ```

  Parse the envelope: on `success: true` read `data.ingested_count`. If it is `0`, abort with "no wiki sources cover this plan's sub-questions — ingest more sources (knowledge-ingest), broaden the plan, or check the bound wiki". On `success: false`, surface `error` and abort. The synthesized manifest carries `source_mode: "wiki"` and the same `ingested[]` shape (`{url, slug, title, publisher, summary, claims_extracted, sub_question_refs[]}`) the web path produces, so **Steps 1–7 run identically** — the composer reads it in Step 4 with no awareness it was wiki-sourced. `INGESTED_SOURCES` for the dry-run/summary is `data.ingested_count`.

**Phase timing accumulators.** Capture `PHASE_START=$(date -u +%FT%TZ)` (the phase wall-clock the Step 8 ledger records) **and** initialise `MAX_DURATION_MS=0` (the slowest single composer dispatch, the orchestrator-measured Option B serial-tail signal) now, at the top of the run. They are run-level — set once here so a run that also re-dispatches the composer in Step 5.5 folds across both dispatches. The composer agents (`wiki-composer`) have no `Bash` tool to self-report `duration_ms`, so this phase measures each dispatched `Task`'s wall-clock itself (Option B); see `references/run-metrics-wiring.md`.

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
SOURCE_MODE=<web|wiki>
RESUME_FROM_OUTLINE=<true|false>
TARGET_WORDS=<resolved>
PROSE_DENSITY=<resolved>
TONE=<resolved>
CITATION_FORMAT=<resolved>
OUTPUT_LANGUAGE=<resolved>
INGESTED_SOURCES=<web: count from ingest-manifest.json; wiki: count of wiki/sources/*.md>
```

and stop.

### 3. Resolve composer knobs (TARGET_WORDS, PROSE_DENSITY, TONE, CITATION_FORMAT)

Each knob resolves `--<flag>` if passed, else the matching `plan.json` field, else the hard default. They were already resolved + validated in `knowledge-plan` Step 0.5 and written to `plan.json`, so this is a read-with-override (the `--flag` lets an operator re-compose a single draft with a different knob without re-planning):

| Knob | `--flag` | `plan.json` field | Default |
|---|---|---|---|
| `TARGET_WORDS` | `--target-words` | `target_words` | `2000` |
| `PROSE_DENSITY` | `--prose-density` | `prose_density` | `standard` |
| `TONE` | `--tone` | `tone` | `objective` |
| `CITATION_FORMAT` | `--citation-format` | `citation_format` | `ieee` |

`TARGET_WORDS` is a **soft target** — a soft upper budget under `standard` (never a floor), a ceiling under `executive`. The composer itself is single-pass per dispatch; under `standard` density a **coverage** deficit (a sub-question whose ingested evidence the draft left uncited) may trigger ONE bounded expansion re-dispatch in Step 5.5 (below), but never under `executive` (no coverage actuator there). Word count drives no re-dispatch under either density. `CITATION_FORMAT` is now **live**: `ieee`/`chicago` render end-to-end (the composer differs only in the reference-list string); `apa`/`mla`/`harvard` are accepted but render as numbered until the author-date follow-up lands (`references/citation-formats.md`).

### 3.5. Resolve the recency-survivor surfacing path (`CONTRADICTION_INGEST_PATH`) + the mode-C acting gate (`CONTRADICTION_ACT`)

`knowledge-ingest` Step 4.6 may have written `<project_path>/.metadata/contradiction-ingest.json` — the ingest-time contradiction tripwire, where each `contradiction` finding optionally carries a zero-network `resolution {survivor_claim_id, strategy: "recency", rationale}` recency-survivor *suggestion* (the more-recent side of a contradicting claim pair) plus a `severity` ∈ `{high, medium, low}`. When that file holds ≥1 **resolved** contradiction, thread its path so the composer can build the recency-survivor map. **Acting on that map — preferring the survivor over the superseded loser — is mode C: gated behind the explicit `--contradiction-act` opt-in AND restricted to high-severity contradictions** (the classification decision for the shipped slice). By default the path is threaded for observability but the composer never prefers a survivor. This is pure surfacing — it changes only *which* of an existing claim pair the composer cites, never the citation-manifest schema, the verifier, or any wiki page.

Resolve `CONTRADICTION_INGEST_PATH` — **fail-soft**, where any miss leaves it empty and the dispatch is byte-identical to the pre-surfacing form:

- If `--no-contradiction-surfacing` was passed → leave empty (omit the param).
- Else if `<project_path>/.metadata/contradiction-ingest.json` does not exist → leave empty.
- Else read it and check the canonical file's top-level `resolution_coverage.resolved` (the merged `contradiction-ingest.json` is a canonical artifact, **not** a `{success,data,error}` script envelope — there is no `data.` wrapper): when it is a **positive integer** → set `CONTRADICTION_INGEST_PATH` to that file path; when it is `0`, absent, or the file is unreadable / malformed JSON → leave empty.

```bash
CONTRADICTION_INGEST_PATH=""
ci="<project_path>/.metadata/contradiction-ingest.json"
# (skip this block entirely when --no-contradiction-surfacing was passed)
if [ -f "$ci" ]; then
  resolved=$(CI="$ci" python3 -c "import json,os; d=json.load(open(os.environ['CI'])); print(int((d.get('resolution_coverage') or {}).get('resolved', 0) or 0))" 2>/dev/null || echo 0)
  [ "${resolved:-0}" -gt 0 ] 2>/dev/null && CONTRADICTION_INGEST_PATH="$ci"
fi

# Mode C (acting) is a separate, explicit opt-in. CONTRADICTION_ACT=1 ONLY when
# --contradiction-act was passed AND a non-empty CONTRADICTION_INGEST_PATH resolved.
CONTRADICTION_ACT=""
[ -n "$CONTRADICTION_INGEST_PATH" ] && [ "${contradiction_act:-0}" = "1" ] && CONTRADICTION_ACT="1"
```

Pass `CONTRADICTION_INGEST_PATH` to the composer (Step 4, and the Step 5.5 expansion re-dispatch) **only when it resolved to a non-empty path** — omit the parameter entirely otherwise, so a project with no resolved contradictions dispatches exactly as before. **Mode C (acting) is gated separately:** pass `CONTRADICTION_ACT=1` to the composer (both dispatches) **only when `--contradiction-act` was passed AND `CONTRADICTION_INGEST_PATH` is non-empty** — omit it otherwise, so the default run threads the path for the composer to *read* but never *acts* on it (the survivor preference is suppressed unless the maintainer explicitly opts in, and even then only for high-severity contradictions).

This central path is the **fallback layer**: `knowledge-ingest` Step 4.6.4 also persists each resolution durably onto the participating pages' `contradiction_resolutions:` frontmatter (mode-B), and the composer prefers a page's own frontmatter block over this central file when present (fallback hierarchy frontmatter-resident → central → none, resolved entirely composer-side in Phase 0 step 7.1). No orchestrator change is needed — the resolution here, and the `resolution_coverage.resolved` gate, are unchanged; the frontmatter preference is invisible to this skill.

### 4. Dispatch wiki-composer (single Task call)

Stamp `START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')` immediately before the dispatch (the Option B per-dispatch timing — see Step 0 + `references/run-metrics-wiring.md`). Dispatch via the `Task` tool (matches the upstream `knowledge-ingest` / `knowledge-fetch` agent-dispatch convention):

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
     CONTRADICTION_INGEST_PATH=<resolved in Step 3.5; OMIT this param when empty>,
     CONTRADICTION_ACT=<resolved in Step 3.5; OMIT this param when empty>,
     RESUME_FROM_OUTLINE=<true|false>)
```

`OUTPUT_LANGUAGE` is read from `<project_path>/.metadata/plan.json` (`output_language`, default `en` — the same value `knowledge-finalize` reads for its reference heading). It controls the draft body, section headings, and the reference-section heading. `PROSE_DENSITY` / `TONE` / `CITATION_FORMAT` (Step 3) shape the draft's structural discipline, rhetorical register, and citation rendering respectively — all single-pass (the composer never loops on any of them). The agent derives the plan and ingest-manifest paths from `PROJECT_PATH` (fixed `.metadata/plan.json` and `.metadata/ingest-manifest.json`). `wiki-composer` lives at `${CLAUDE_PLUGIN_ROOT}/agents/wiki-composer.md` — dispatched via `Task`, not `Skill`. Single-pass, no fan-out, no per-section sharding — the agent reads the wiki itself and writes both output files atomically.

Parse the return envelope:

- `ok: true` → fold this dispatch's wall-clock into the accumulator: `MAX_DURATION_MS=$(python3 -c "import time; print(max($MAX_DURATION_MS, int(time.time()*1000) - $START_MS))")` (fail-soft — an unset `START_MS` contributes 0, never aborts), then continue to Step 4.5 (build the manifest).
- `ok: false, error: "no_ingested_sources"` → re-emit the abort message and stop (shouldn't happen if Step 0 ran, but defence-in-depth).
- `ok: false, error: "write_failed"` → surface the reason; do not retry blindly. The composer already retried once internally. Direct the user to inspect output token-budget conditions or re-run.
- `ok: false, error: "outline_write_failed"` → surface; no recovery in this slice (Phase 1 couldn't even land the outline).

### 4.5 Build citation-manifest.json from the composer's records

The composer wrote a raw-text **citation-records** file (`<project_path>/.metadata/citation-records-v<N>.txt`), never JSON — so a `draft_sentence` containing a straight `"` (routine in German/FR/IT/ES/PL prose) can't break the manifest. Serialize and self-check the manifest with `citation-store.py build`. Pass each path as a **quoted literal CLI arg** — a quoted string is one space-/apostrophe-safe argv element, so quoting alone is sufficient. Do **not** wrap this in a command-prefix env-var form (`RECORDS_PATH=… python3 … --records "$RECORDS_PATH"`): the shell expands `"$RECORDS_PATH"` against the *current* environment — where the var is still unset — **before** applying the prefix assignment and exec'ing, so `--records` would receive an empty string and the build aborts resolving the cwd as the records path.

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/citation-store.py build \
    --records "<project_path>/.metadata/citation-records-v<N>.txt" \
    --draft "<project_path>/output/draft-v<N>.md" \
    --out "<project_path>/.metadata/citation-manifest.json" \
    --draft-version <N> \
    --ingest-manifest "<project_path>/.metadata/ingest-manifest.json"
```

This is unchanged in `--source wiki` mode: the synthesized manifest from Step 0 carries each source's real `sources:` URL in `ingested[].url`, so the `--ingest-manifest` URL gate (every inline citation URL must be a known source URL) runs exactly as it does on the web path — pass the same `--ingest-manifest "<project_path>/.metadata/ingest-manifest.json"`. The wiki-only rung gets the *same* integrity checks as the web path, not fewer.

`citation-store.py build` parses the records, `json.dumps` the manifest (`ensure_ascii=False` — escaping owned by the serializer, never the LLM), asserts every `draft_sentence` is a verbatim substring of the draft, **asserts every inline citation URL is a known ingested-source URL** (the `--ingest-manifest` gate; the composer must copy each cited page's real `sources:` URL, never reconstruct it from the slug), and round-trips the file it wrote (`json.loads` + count). Parse the envelope:

- `success: true` → capture `data.citations_count` (the authoritative count) **and `data.claim_kinds`** (the per-kind breakdown — `{distilled, source, answer, null, other}`, keyed by `claim_id` prefix; `distilled` is the `dcl-NNN` cross-source-convergence count and `answer` is the `acl-NNN` question-node answer-citation count — both surfaced in Step 6 + Step 7) and continue to Step 5.
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

### 5.5 Bounded coverage-gated expansion (standard density only — capped at ONE, fail-soft)

A `standard`-density draft is **complete** when every sub-question is grounded in the evidence the wiki actually holds — not when it reaches a word count. `target_words` is a soft upper budget, never a floor, so a tight draft that grounds every sub-question is the *better* outcome and must NOT trigger a second LLM call. This step fires ONE bounded, zero-network expansion pass **only** when a sub-question has ingested evidence the draft never cited — a real **coverage** deficit with evidence on hand to close it. It cannot pull new evidence (cogni-knowledge is zero-network); it only deepens the named sections from claims already on the wiki, so it fixes "a thin section left grounded evidence uncited", not "wiki too sparse" (the latter routes to more ingestion via `knowledge-curate`/`-fetch`). The load-bearing safety net is the accept check below: an expansion that adds no new grounded citation is discarded, so the system can never ship padding.

**Skip this step entirely (proceed to Step 6 with `draft-vN`) when ANY of:**
- `--no-expand` was passed → log `expansion skipped: --no-expand`.
- `PROSE_DENSITY != standard` (a soft upper budget has no coverage actuator) → log `expansion skipped: density=<PROSE_DENSITY>`.
- This dispatch is already an expansion round (defence-in-depth against a manual re-entry) → log `expansion skipped: already an expansion round`.

**Compute the coverage deficit (deterministic).** Word count plays **no** role in deciding to expand. Read `plan.json` + `ingest-manifest.json` + `citation-manifest.json` and call `_knowledge_lib.coverage_report` (the single canonical coverage surface, unit-tested in `tests/test_knowledge_lib.sh`) to get, per sub-question, the ingested source slugs `available` / `cited` / `uncited`, plus `uncited_evidence_sq_ids` (the sub-questions with ≥1 uncited ingested source — a coverage deficit WITH evidence to close it). Paths via env vars:

```
COVERAGE=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PLAN_PATH="<project_path>/.metadata/plan.json" \
INGEST_PATH="<project_path>/.metadata/ingest-manifest.json" \
MANIFEST_PATH="<project_path>/.metadata/citation-manifest.json" \
python3 -c '
import json, os, sys
from pathlib import Path
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import coverage_report
def _load(p):
    return json.loads(Path(p).read_text(encoding="utf-8"))
rep = coverage_report(_load(os.environ["PLAN_PATH"]),
                      _load(os.environ["INGEST_PATH"]),
                      _load(os.environ["MANIFEST_PATH"]))
# The deficit sq-id set + the per-sq zero-cited set drive section selection below.
zero_cited = [sq for sq, v in rep["per_sq"].items() if not v["cited"]]
print(json.dumps({"uncited_evidence_sq_ids": rep["uncited_evidence_sq_ids"],
                  "zero_cited_sq_ids": zero_cited}))
')
```

If the snippet errors or returns empty (e.g. an unreadable manifest), treat it as no deficit and skip expansion with `expansion skipped: coverage report unavailable` — the whole step is fail-soft, so a missing measurement never blocks the deposit. If `uncited_evidence_sq_ids` is empty, skip with `expansion skipped: coverage met (every sub-question's ingested evidence is cited)` — a short-but-fully-grounded draft is the intended outcome, not a deficit.

**Gate on `ceiling_hit`.** If the composer's returned `ceiling_hit == true`, skip with `expansion skipped: at single-call ceiling — raise coverage via more ingestion (knowledge-curate/-fetch)` — re-rolling the composer cannot fit more in one call; the fix is more wiki coverage, not a re-roll.

The coverage gate is deliberately independent of the `wiki-reviewer` advisory Word-Count Gate (finalize Step 10.7): that gate is now a brevity-neutral backstop (it flags only a likely-*truncated* draft at `< 0.50` of budget, never a short-but-complete one), while this actuator fires on a coverage deficit regardless of word count. The two serve different roles and neither tracks the other.

**Select `EXPAND_SECTIONS`** from the just-written outline `<project_path>/.metadata/writer-outline-v<N>.json` — the topical sections (excluding the References section, `covers_sub_questions: []`) that **cover ≥1 sq in `uncited_evidence_sq_ids`** AND are **thin** (`drafted_words < budget × 0.9`) **or cover a zero-cited sq** (a sq in `zero_cited_sq_ids`). This is conservative by design — the brevity-first intent prefers under-firing (no padding) over over-firing. Paths via env vars (`COVERAGE` is the JSON the snippet above printed):

```
OUTLINE_PATH="<project_path>/.metadata/writer-outline-v<N>.json" \
COVERAGE_JSON="$COVERAGE" \
python3 -c '
import json, os
from pathlib import Path
o = json.loads(Path(os.environ["OUTLINE_PATH"]).read_text(encoding="utf-8"))
cov = json.loads(os.environ["COVERAGE_JSON"])
deficit = set(cov["uncited_evidence_sq_ids"])
zero = set(cov["zero_cited_sq_ids"])
chosen = []
for s in o.get("sections", []):
    covers = s.get("covers_sub_questions") or []
    budget = s.get("budget")
    if not covers or not isinstance(budget, int):
        continue  # References / structural section (covers_sub_questions: [])
    if not (deficit & set(covers)):
        continue  # no uncited evidence maps to this section — leave it alone
    drafted = s.get("drafted_words")
    thin = isinstance(drafted, int) and drafted < budget * 0.9
    if thin or (zero & set(covers)):
        chosen.append(str(s["index"]))
print(",".join(chosen))
'
```

Capture this as `EXPAND_SECTIONS`. **The gate fires iff `EXPAND_SECTIONS` is non-empty.** If it is empty — the deficit sub-questions map only to sections already at budget and not zero-cited — skip with `expansion skipped: no thin/zero-cited section maps to the uncited evidence` — deepening a section already at budget would only pad.

Stamp `START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')` immediately before the re-dispatch (same Option B timing as Step 4). **Re-dispatch the composer ONCE** at `N+1` in expansion mode (same knob values as Step 4). Its purpose is to deepen the named sections **from the specific not-yet-cited wiki evidence** for their sub-questions, not to close a word count:

```
Task(wiki-composer,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<N+1>,
     EXPANSION_MODE=true,
     BASELINE_DRAFT_VERSION=<N>,
     EXPAND_SECTIONS=<comma-list>,
     TARGET_WORDS=<resolved>,
     PROSE_DENSITY=<resolved>,
     TONE=<resolved>,
     CITATION_FORMAT=<resolved>,
     OUTPUT_LANGUAGE=<resolved>,
     CONTRADICTION_INGEST_PATH=<same as Step 4; OMIT when empty>,
     CONTRADICTION_ACT=<same as Step 4; OMIT when empty>)
```

**Snapshot the canonical manifest before the re-dispatch.** A successful `N+1` build overwrites `citation-manifest.json` (to describe `v<N+1>`) *before* Step 5 runs, so a copy of the current (`vN`) manifest is the only way a failed expansion can restore consistent `vN` state — the same discipline `knowledge-verify` uses before a revise round (`.citation-manifest.pre-r<round>.json`):

```
cp "<project_path>/.metadata/citation-manifest.json" \
   "<project_path>/.metadata/.citation-manifest.pre-expand.json"
```

On `ok: true`, fold this dispatch's wall-clock into the accumulator: `MAX_DURATION_MS=$(python3 -c "import time; print(max($MAX_DURATION_MS, int(time.time()*1000) - $START_MS))")` (fail-soft, same as Step 4), then **re-run Step 4.5** (`citation-store.py build … --draft-version <N+1>` with the same `--ingest-manifest` gate, writing the canonical `citation-manifest.json` from `citation-records-v<N+1>.txt`) **and Step 5** (the on-disk verifier) against `v<N+1>`. **Accept check (load-bearing) — keep `v<N+1>` only when both pass AND the expansion added at least one grounded citation:** `data.citations_count` from the `v<N+1>` build must exceed the `data.citations_count` Step 4.5 captured for `vN` (the one authoritative citation count — `len(citation-manifest::citations)`, never an LLM tally). An expansion that grew the prose but added no new citation is **padding** → treated as a failure below; words alone never survive. On success, `v<N+1>` becomes the canonical latest draft — set `N := N+1` so Steps 6/7 report on it, then drop the now-stale snapshot:

```
rm -f "<project_path>/.metadata/.citation-manifest.pre-expand.json"
```

**Cap = 1; fail-soft (the orchestrator must leave `vN` AND its matching manifest as the canonical state on any failure):** if the expansion dispatch returns `ok: false`, OR its Step-4.5 manifest build is rejected, OR its Step-5 on-disk verify fails, OR it added no new grounded citation (`citations_count<N+1> ≤ citations_count<N>`) — **remove the partial `v<N+1>` artifacts** (`output/draft-v<N+1>.md`, `.metadata/citation-records-v<N+1>.txt`, `.metadata/writer-outline-v<N+1>.json`) so the latest-draft resolver lands back on `vN`, **and restore the snapshot** so the canonical `citation-manifest.json` describes `vN` again:

```
mv "<project_path>/.metadata/.citation-manifest.pre-expand.json" \
   "<project_path>/.metadata/citation-manifest.json"
```

then log `⚠ expansion failed — kept draft-vN (manifest restored)` (or `⚠ expansion added no new citation — kept draft-vN (manifest restored)` on the no-citation branch) and proceed to Step 6 with `vN`. The restore is load-bearing precisely in the build-OK-but-verify-fail (and no-citation) window: a successful `N+1` build has *already* overwritten `citation-manifest.json` to describe the about-to-be-removed `draft-v<N+1>`, so removing the artifacts alone would leave a stale manifest pointing at a deleted draft (its `draft_sentence`s no longer verbatim substrings of `vN`), breaking the downstream `knowledge-verify`/`knowledge-finalize` read. (After a *rejected* `N+1` build the manifest is still the `vN` one — `citation-store.py build` writes only on success — but the unconditional restore is correct there too: it simply moves the snapshot back over an identical file.)

### 6. Append wiki/log.md

Append one summary line (Bash `>>` append; `wiki/log.md` is append-only by cogni-wiki convention):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_WORDS=<words from composer return>
N_CITES=<the script-derived count from Step 5's print(len(cites)) — NOT the composer return's "citations" field>
N_DCL=<data.claim_kinds.distilled from Step 4.5, default 0>
N_ACL=<data.claim_kinds.answer from Step 4.5, default 0>
LOG_PATH=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/control-path.py" log --wiki-root "${WIKI_ROOT}")
echo "## [${DATE_STAMP}] compose | project=${TOPIC} draft=v${N} words=${N_WORDS} citations=${N_CITES} dcl=${N_DCL} acl=${N_ACL}" >> "${LOG_PATH}"
```

The `dcl=<n>` suffix is the cross-run record of the distilled-citation rate, and `acl=<n>` the question-node answer-citation rate — the cross-source-convergence loops firing (or not) show up directly in `wiki/log.md`.

Note on the `compose` prefix: cogni-wiki's log-format enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") does not yet list `compose`, but readers count unknown prefixes in their catch-all bucket without crashing — `compose` is additive and safe.

### 7. Final summary

Print ≤ 11 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Source: `<SOURCE_MODE>` (`wiki` = composed only from the bound wiki + fetch-cache via a synthesized manifest, no web crawl, `<INGESTED_SOURCES>` wiki sources mapped to the plan; `web` = `<INGESTED_SOURCES>` web-ingested sources). The staged `--source local|hybrid` notice, if any, was already printed at pre-flight.
- Draft: `output/draft-v<N>.md` (`<N_WORDS>` words across `<N_SECTIONS>` sections)
- Citations: `<N_CITES>` (authoritative count = `len(citation-manifest.json::citations)`, from Step 5)
- Sources (cited vs ingested): print `Sources: <X> of <Y> ingested cited (<Z> compounding on wiki)`, computed **fail-soft** from the two on-disk manifests — `X` = distinct ingested sources cited (`{c.wiki_slug for c in citation-manifest::citations} ∩ {s.slug for s in ingest-manifest::ingested}`, the same field pair the canonical `_knowledge_lib.coverage_report` intersects), `Y` = `len(ingest-manifest::ingested)`, `Z = Y − X`. Compute via the env-var `python3 -c` pattern (never interpolate paths into the literal), e.g. `C="$PROJECT_PATH/.metadata/citation-manifest.json" I="$PROJECT_PATH/.metadata/ingest-manifest.json" python3 -c 'import json,os;c=json.load(open(os.environ["C"]));g=json.load(open(os.environ["I"]));cit={x.get("wiki_slug") for x in c.get("citations",[])};ing={s.get("slug") for s in g.get("ingested",[]) if s.get("slug")};X=len(cit&ing);Y=len(ing);print(f"Sources: {X} of {Y} ingested cited ({Y-X} compounding on wiki)")' 2>/dev/null || echo "Sources: (signal unavailable)"`. The `<Z>` uncited-but-ingested pages are the deliberate **read-before-web investment** — they compound for future `knowledge-curate` runs (`references/differentiation-thesis.md` §"The compounding loop"), not waste.
- Distilled citations: `<N_DCL>` of `<N_CITES>` (`dcl-NNN` cross-source convergence cited directly, from Step 4.5's `data.claim_kinds.distilled`) — `0` on a base with no distilled pages is expected; `0` on a base with distilled pages whose claims show ≥2 backlinks is the inert-loop symptom the operator should notice (the cross-source-convergence evidence is never load-bearing).
- Answer citations: `<N_ACL>` of `<N_CITES>` (`acl-NNN` question-node answers cited directly, from Step 4.5's `data.claim_kinds.answer`) — `0` on a base whose question nodes carry no `answer_claims:` is expected; `0` on a base with `answer_claims:` whose claims show ≥2 backlinks is the inert symptom the operator should notice (same posture as the distilled-citation rate above).
- Outline: `.metadata/writer-outline-v<N>.json` (outline-recovery anchor; recovery used: `<RESUME_FROM_OUTLINE>`)
- Expansion (standard density only): one of `coverage-expansion ran (vN-1 → vN, deepened <sections>)` / `expansion skipped: <reason>` / `⚠ expansion failed — kept draft-vN (manifest restored)` / `⚠ expansion added no new citation — kept draft-vN (manifest restored)` — from Step 5.5; omit the line on a non-`standard` density run.
- Cost: `$X.XXX` (from composer return; accumulate the expansion dispatch's `cost_estimate` when it ran)
- Next: `knowledge-verify` will run zero-network claim alignment by reading the citation manifest + each cited page's claim block — `pre_extracted_claims[]` on a source/synthesis page, `distilled_claims[]` on a cited distilled page, or `answer_claims[]` on a cited question node.

Surface a density-aware summary line — but do not auto-retry. The two densities now read oppositely:
- Under `PROSE_DENSITY=standard`: `target_words` is a **soft upper budget**, so a draft under it is the intended brevity-first outcome — **emit no under-budget word warning at all.** Instead surface a coverage line `coverage: <#grounded>/<#sub-questions> sub-questions grounded` (grounded = sub-questions NOT in `coverage_report`'s `uncited_evidence_sq_ids`; reuse the `COVERAGE` JSON from Step 5.5, or recompute it cheaply when Step 5.5 was skipped via `--no-expand`). A `coverage:` line below full is the honest coverage signal — and, when uncited evidence remained, Step 5.5 already attempted to deepen it.
- Under `PROSE_DENSITY=executive`: `target_words` is a **ceiling**, so compute `BODY_WORDS` for `<project_path>/output/draft-v<N>.md` with the `_knowledge_lib.body_word_count` helper (the `wiki-reviewer`-aligned surface, reference list excluded — body words, not the composer's total `words`, so the ~1.1k-word bibliography never triggers a false warning) and, if `BODY_WORDS` is over `TARGET_WORDS`, print `⚠ Over ceiling (BODY_WORDS/TARGET_WORDS)`. Under-ceiling is the correct executive outcome — no warning.

The advisory `wiki-reviewer` (finalize Step 10.7) independently re-scores the draft — under `standard` it only flags a likely-*truncated* draft (`< 0.50` of budget), never a short-but-complete one; under `executive` it caps on excess. The compose-time line is a fast heads-up, not a gate.

### 8. Record run metrics (phase-exit ledger)

Persist this phase's timing + cost to `<project_path>/.metadata/run-metrics.json` so the run leaves a durable per-phase ledger (read by `knowledge-resume` / `knowledge-dashboard` / a perf study). Capture `PHASE_START=$(date -u +%FT%TZ)` and init `MAX_DURATION_MS=0` at the top of this skill's run (Step 0); the composer dispatches (Step 4, and Step 5.5 when it runs) fold their wall-clock into `MAX_DURATION_MS`; then at exit:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" record \
    --project-path "<project_path>" --phase compose \
    --started-at "$PHASE_START" --ended-at "$(date -u +%FT%TZ)" \
    --agent-count <1 composer, +1 if Step 5.5 expansion ran> \
    --cost-usd <composer cost_estimate.estimated_usd (+ expansion when it ran)> \
    --max-agent-duration-ms <MAX_DURATION_MS — the slowest single composer dispatch (Option B orchestrator-measured)>
```

Fail-soft — a record failure never blocks the phase. Full contract: `${CLAUDE_PLUGIN_ROOT}/references/run-metrics-wiring.md`.

## Edge cases

- **Outline recovery in action.** The outline file exists from a prior crashed run. The composer skips Phase 1 (saves model time and avoids re-deriving the section plan), runs Phase 2 fresh, and writes the draft + citation manifest. The outline's `drafted_words` placeholders get filled by the resume pass. Surface "RESUME_FROM_OUTLINE=true (outline recovery)" in the summary so the operator sees what happened.
- **Re-run with same N.** The user explicitly passes `--draft-version <N>` against an existing draft. The composer overwrites `draft-v<N>.md` and `citation-manifest.json` (and re-writes the outline — Phase 1 runs unless `writer-outline-v<N>.json` is present and `RESUME_FROM_OUTLINE=true` was inferred). No automatic backup — the user asked for it.
- **Empty `ingested[]` after a re-ingest cleanup.** Step 0 aborts with the "no ingested sources" message; do not dispatch the composer against an empty manifest.
- **Citation manifest empty.** If the composer returns `ok: true` but `citations[] == 0` (every cited page had zero claims — no source `pre_extracted_claims:`, no distilled `distilled_claims:`, and no question-node `answer_claims:` — unusual but possible if the claim-extractor failed across the board), surface as `⚠ Zero citations — every cited statement will fail verification`. Do not block — that's an upstream-data issue, not a composer bug.
- **Plan changed between ingest and compose.** Step 1.2 of the composer aligns `covers_sub_questions` from `ingest-manifest.json` (resolved sources carry `sub_question_refs[]`), so a sub-question added to `plan.json` after `knowledge-ingest` ran will have no sources mapped to it. The introduction and conclusion still list it (synthesis sections list all `plan.json` sub-question ids), but a topical section for that sub-question won't have evidence. Surface in the summary as `⚠ Sub-question <id> has no ingested sources`.

## Out of scope

- Does NOT verify citations — Phase 6 (`knowledge-verify`).
- Does NOT deposit the draft into the wiki as `wiki/syntheses/<slug>.md` — Phase 7 (`knowledge-finalize`).
- Does NOT modify `binding.json` — Phase 7 appends the project entry. `knowledge-finalize` records `report_source: wiki` for every inverted-pipeline deposit regardless of compose `--source` (the deposit always lands in the wiki), so the new mode changes nothing here.
- Does NOT re-run any earlier phase. In particular `--source wiki` does **not** trigger `knowledge-curate`/`-fetch`/`-ingest` — it synthesizes its manifest from the already-populated wiki (Step 0), which is the whole point of the wiki-only rung (a report with no new web crawl).
- Does NOT implement the `local` or `hybrid` source modes yet — they are accepted-but-staged (treated as `wiki`, with a pre-flight notice); a real `local` (fetch-cache-only) / `hybrid` (wiki + bounded top-up curate on uncovered sub-questions) path is a deferred follow-up.
- Does NOT run an unbounded expansion loop or story arcs — the composer is single-pass per dispatch. Under `standard` density this skill runs ONE bounded, fail-soft, zero-network **coverage-gated** expansion (Step 5.5) only when a sub-question has uncited ingested evidence AND the expansion adds a grounded citation; `prose_density: executive` shapes that single pass (BLUF + Pyramid ceiling) and adds **no** re-dispatch. The expansion re-elaborates existing wiki claims only — it never fetches new evidence (that is `knowledge-curate`/`-fetch`'s job), and never pads toward a word count.

## Output

- `<project_path>/output/draft-v<N>.md`
- `<project_path>/.metadata/citation-records-v<N>.txt` (composer's raw-text records; input to `citation-store.py build`)
- `<project_path>/.metadata/citation-manifest.json` (schema 0.1.1; built by `citation-store.py build`)
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
