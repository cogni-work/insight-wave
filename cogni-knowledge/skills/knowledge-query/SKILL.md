---
name: knowledge-query
description: "Ask a question against a bound cogni-knowledge base — resolves the wiki path from binding.json, ranks the covering pages via the shared wiki-grounding primitive, reads them, and synthesizes a cited answer natively (no cogni-wiki dispatch). The shallow rung of the query↔research depth ladder: one question, index-first read of ≤12 pages, no web, no verify. Use this skill whenever the user says 'query my <slug> knowledge base', 'ask the eu-ai-act base about X', or 'knowledge-query <slug>'."
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
---

# Knowledge Query

Ask a question against a bound cogni-knowledge base. This skill is the **shallow
rung** of the query↔research depth ladder: it ranks the pages that cover the
question, reads them, and synthesizes a grounded, cited answer — one question,
index-first, ≤12 pages, **no web, no verify** (the deep wiki-only report rung is
owned by `knowledge-compose --source wiki`).

It runs **natively on the vendored wiki engine** — it consumes the shared
`wiki-grounding.py` discovery primitive directly and reads the wiki pages with
the `Read` tool, so a Karpathy base answers questions **without cogni-wiki
installed**. The cogni-knowledge value-add:

1. **Binding-aware wiki path resolution** — no `--wiki-root` from the user; read from `binding.json`.
2. **Index-first grounded synthesis** — rank covering pages via `wiki-grounding.py`, read them, answer **only** from what they say (with `[[slug]]` citations), and report honestly when coverage is thin.
3. **Knowledge-base footer** — every answer ends with one line tying it to the knowledge slug + deposit count + fetch-cache health, so the user remembers where the answer came from and how much evidence the base holds.

Read `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` once per session to anchor on the accumulation thesis. The synthesis discipline below — answer only from the pages you read, cite every claim, admit uncertainty — is the shallow rung's core contract.

## When to run

- User asks a question and references a knowledge base by slug — "what does my eu-ai-act base know about X?", "query the eu-ai-act base on Article 6"
- User explicitly invokes `/cogni-knowledge:knowledge-query`
- User asks a question that clearly lives in a bound knowledge base's domain after `knowledge-resume` has shown what is in the base

## Never run when

- No `binding.json` exists at the resolved knowledge root — route the user to `/cogni-knowledge:knowledge-setup` first.
- The user wants a **deep, multi-section, web-verified report** rather than a single grounded answer — that is `knowledge-compose --source wiki` (the deep rung), not this skill.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--question` | Yes (prompted) | Free-text question. Grounded against the bound wiki. |
| `--knowledge-root` | No | Override the default knowledge-base directory. Defaults to `cogni-knowledge/<knowledge-slug>/` (relative to the current working directory). |
| `--max-pages` | No | Cap on how many ranked pages to read and synthesize from. Default 12 (the shallow-rung ceiling). Passed to `wiki-grounding.py rank --top-k`. |
| `--theme` | No | Optional thematic label folded into the ranking (passed to `wiki-grounding.py rank --theme-label`) to sharpen page selection on a broad question. |
| `--file-back` | No | Opt-in synthesis deposit. **Absent → read-only** (the default; no writes, no prompt — autonomous/cron runs stay clean). `yes` → deposit the synthesized answer as an honestly-labeled un-verified `type: synthesis` wiki page (Step 4). |
| `--synthesis-slug` | No | Override the auto-derived deposit slug (only meaningful with `--file-back yes`). |
| `--overwrite` | No | With `--file-back yes`, replace an existing `wiki/syntheses/<slug>.md` instead of aborting on the collision guard. |

If `--question` is missing, ask the user once via `AskUserQuestion` (single free-text question — load the schema via `ToolSearch(query="select:AskUserQuestion")` if needed). Do not invent a question.

## Workflow

### 0. Pre-flight

**Required engine.** This skill resolves the wiki engine **vendored-first** —
cogni-knowledge ships a byte-identical copy of the engine in-tree under
`scripts/vendor/cogni-wiki/`, so a bound base is queryable without cogni-wiki
installed. The `cogni-wiki` install is only a fallback layout. Probe both so the
skill aborts cleanly here rather than failing mid-read:

```
# vendored-first: the in-tree engine is self-contained
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts" && WIKI_OK=yes || WIKI_OK=no

# fallback: an installed cogni-wiki sibling / marketplace cache (legacy layout)
if [ "$WIKI_OK" = "no" ]; then
  probe_plugin() {
    local plugin="$1" skill="$2"
    test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
    for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
      [ -f "$d" ] && return 0
    done
    return 1
  }
  probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
fi
```

If `WIKI_OK` is `no`, abort:

> cogni-knowledge's vendored wiki engine is missing and no `cogni-wiki`
> install was found. Reinstall cogni-knowledge, then retry.

Then continue with the binding-resolution checks:

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract `wiki_path`, `knowledge_slug`, and `research_projects[]` from the binding. Validate that `binding.knowledge_slug == --knowledge-slug` — mismatch indicates the user is pointing at the wrong directory.

4. Confirm the wiki is still there: `<wiki_path>/.cogni-wiki/config.json` must exist. If not, abort with a clear "the binding points at a wiki that no longer exists" error.

### 1. Rank the covering pages (index-first discovery)

Run the shared wiki-grounding primitive against the bound wiki — the same
`rank` mechanism `wiki-coverage.py` and `wiki-source-manifest.py` resolve to:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/wiki-grounding.py rank \
    --wiki-root <wiki_path> \
    --question "<question>" \
    --top-k <max-pages, default 12> \
    [--theme-label "<theme>"]
```

Capture `data.pages[]` (each `{slug, type, page_path, title, overlap_score,
reasons}`, ranked highest-overlap first; `page_path` is wiki-root-relative) and
`data.coverage_verdict` (`covered` / `partial` / `uncovered`).

- **`uncovered` (no covering pages)** → do **not** synthesize from nothing. Tell
  the user the base has no page covering this question, suggest
  `knowledge-resume` to see what the base holds (or running the research
  pipeline / `knowledge-ingest-source` to add a source), then go straight to
  Step 3's footer. This honest-empty report is the shallow rung's contract.
- **`covered` / `partial`** → continue to Step 2.

### 2. Read the pages and synthesize a grounded answer

Read each covering page in `data.pages[]` order via the `Read` tool at
`<wiki_path>/<page_path>`, up to `--max-pages` (default 12). Then synthesize the
answer **in context**, following the grounded-research discipline:

- **Answer only from the pages you read** — never from model memory. If the
  pages do not fully answer the question, say what they cover and what they do
  not.
- **Cite every claim** with a bare `[[<slug>]]` wikilink to the page it came
  from (use the page's `slug`), so the answer is auditable against the base and
  the backlink graph stays intact.
- **Prefer a distilled / synthesis / question page** when one covers the point
  (a `type` of `summary`/`concept`/`entity`/`synthesis`/`question` is
  cross-source evidence) over restating one raw source.
- **Admit uncertainty** on a `partial` verdict — lead with what the base
  confirms, then flag the gap.

This is a single pass: rank → read → synthesize. No web search, no claim
verification loop (those are the deeper rungs).

### 3. Print the answer + footer

Before printing, read the knowledge-base-global fetch-cache health so the
footer can show how much evidence the base has cached:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py cache-health \
    --knowledge-root <knowledge_root>
```

Capture `entries` (cached source count `<M>`) and `unavailable` (`<U>`) from `data`. On `success: false`, treat the counts as unknown and drop the fetch-cache clause from the footer rather than aborting — the answer itself is the deliverable.

Print the synthesized answer, then append a single footer line on its own line:

```
Knowledge base: <knowledge_slug> · <N> deposited projects · fetch-cache: <M> sources cached (<U> unavailable) · /cogni-knowledge:knowledge-resume for status.
```

`<N>` is `len(research_projects)` from the binding; `<M>`/`<U>` come from `cache-health`. The footer reminds the user which base the answer came from, how much evidence the inverted pipeline has cached, and points at the status skill.

### 4. Deposit the answer (opt-in, `--file-back` only)

**Default: skip entirely.** When `--file-back` is absent, this skill is
**read-only** — it never modifies the binding **or** the wiki. It reads ranked
pages and synthesizes; the workflow ends at Step 3's footer and writes nothing.
This keeps the per-run no-write invariant intact for autonomous / cron runs.

When `--file-back yes` is passed, deposit the synthesized answer as a wiki page —
the **shallow-rung analog** of the deep rung's `knowledge-finalize` synthesis
deposit, reusing the same vendored write lockstep (no new write path). The
shallow rung runs **no verify pass**, so the deposit is **honestly labeled
un-verified**. Do not deposit on a `uncovered` verdict (there is no grounded
answer to file) or when the answer admits it could not be grounded.

**4.1 Resolve the vendored write lockstep.** Resolve the `wiki-ingest` script
dir vendored-first, exactly as `knowledge-finalize` / `knowledge-ingest-source`
do (the deposit reuses the already-vendored helpers — never a new script):

```
resolve_wiki_scripts() {  # $1 = skill name, e.g. wiki-ingest
  local skill="$1"
  local vend="${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/${skill}/scripts"
  test -d "$vend" && { echo "$vend"; return 0; }
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-wiki/skills/${skill}/scripts"
  test -d "$sib" && { echo "$sib"; return 0; }
  local newest ver
  newest=$(for d in "${CLAUDE_PLUGIN_ROOT}/../../cogni-wiki/"*/skills/"${skill}"/scripts; do
    [ -d "$d" ] || continue
    ver=${d%/skills/${skill}/scripts}; ver=${ver##*/}
    case "$ver" in ''|*[!0-9.]*) continue ;; esac
    printf '%s\n' "$d"
  done | sort -V | tail -1)
  [ -n "$newest" ] && { echo "$newest"; return 0; }
  return 1
}
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest) \
  || { echo "cogni-wiki wiki-ingest scripts not found — cannot --file-back"; exit 1; }
```

`WIKI_ROOT` is the `wiki_path` already resolved in Step 0; confirm
`<WIKI_ROOT>/wiki/` is writeable before continuing.

**4.2 Derive the synthesis slug.** Single source of truth —
`_knowledge_lib.slugify` (the same helper `knowledge-finalize` uses). Pass the
question via env var (never interpolate untrusted text into a Python literal):

```
SYNTHESIS_SLUG=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
  QUESTION="<question>" \
  python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import slugify
print(slugify(os.environ["QUESTION"]) or "")
')
```

If `--synthesis-slug` was passed, use it instead. On an empty result, abort and
ask the user to supply `--synthesis-slug`. The resolved string must match
`[a-z0-9][a-z0-9-]{0,79}`.

**4.3 Collision guard.** If `<WIKI_ROOT>/wiki/syntheses/<SYNTHESIS_SLUG>.md`
already exists, **do not blind-overwrite**: abort with a clear message naming
the existing page and offering `--overwrite` (replace) or `--synthesis-slug`
(deposit under a new slug). Only proceed past an existing page when `--overwrite`
was passed.

**4.4 Write the synthesis page.** Atomically write
`<WIKI_ROOT>/wiki/syntheses/<SYNTHESIS_SLUG>.md` via
`_knowledge_lib.atomic_write_text`. The frontmatter labels the deposit
un-verified; the body leads with a visible blockquote so a human reading the
page in Obsidian is never misled:

```yaml
---
id: <SYNTHESIS_SLUG>
title: <question verbatim>
type: synthesis
tags: [synthesis, knowledge-query]
created: <YYYY-MM-DD UTC>
updated: <YYYY-MM-DD UTC>
sources:
  - wiki://<covering-page-slug-1>
  - wiki://<covering-page-slug-2>
verification: unverified_shallow_rung
---

> **Un-verified shallow-rung answer.** Filed from `knowledge-query` — grounded
> in the cited wiki pages but **not** claim-verified (the shallow rung runs no
> verify pass). Treat as a convenience capture, not a vetted synthesis.

<the synthesized answer from Step 2, with its bare [[slug]] citations preserved>
```

`sources:` lists one `wiki://<slug>` entry per covering page read in Step 2 (the
`data.pages[].slug` values), so the deposit is grounded and de-orphaned. The
`type: synthesis` + `knowledge-query` tag distinguishes a query-filed-back page
from a `knowledge-finalize` deposit in the same `wiki/syntheses/` directory.
Quote the `title:` via `json.dumps(..., ensure_ascii=False)` so a
colon-containing question deposits valid YAML (the `knowledge-finalize` posture).

**4.5 Post-write lockstep (lighter than `knowledge-finalize`).** Run the
vendored index/config/backlink helpers — the same ones `knowledge-ingest`
Step 4 runs (each acquires and releases its own `_wiki_lock` internally, so the
calls are sequential and deadlock-free; the synthesis page itself is
unique-by-construction and needs no lock):

1. **Index update** — sanitize the one-sentence summary via
   `_knowledge_lib.sanitize_summary` (env-var pattern), then
   `python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" --wiki-root "$WIKI_ROOT"
   --slug "$SYNTHESIS_SLUG" --summary "$CLEAN_SUMMARY" --category "Syntheses"
   --max-summary 240`. Capture the envelope; `data.action == "inserted"` means a
   new row landed.
2. **entries_count bump** — only when 4.5.1 inserted a new row (not on an
   `--overwrite` re-deposit): `python3 "$WIKI_INGEST_SCRIPTS/config_bump.py"
   --wiki-root "$WIKI_ROOT" --key entries_count --delta 1`. Non-fatal on failure
   (the page is already discoverable; reconcilable via
   `wiki-lint --fix=entries_count_drift`).
3. **Backlink audit (best-effort)** — curate a `targets[]` plan inserting one
   bare `[[<SYNTHESIS_SLUG>]]` sentence under each covering page's `## See also`,
   then `python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" --wiki-root "$WIKI_ROOT"
   --new-page "$SYNTHESIS_SLUG" --apply-plan -`. **Fail-soft** — a backlink
   failure never blocks the deposit; never invent a backlink to an unrelated
   page.

**4.6 Log line.** Append one line to `<WIKI_ROOT>/wiki/log.md`:
`## [<YYYY-MM-DD>] synthesis | <SYNTHESIS_SLUG> — <short question>` (the same
prefix the deep rung uses), so the deposit is visible in the wiki log.

The binding is **not** touched — `research_projects[]` records inverted-pipeline
deposits (from `knowledge-finalize`), not shallow-rung query answers. After
depositing, add one line to the printed answer noting the page path and that it
was filed un-verified.

## Edge cases

- **Empty knowledge base.** `research_projects[]` is empty and `wiki-grounding.py rank` returns no covering pages → the `uncovered` path (Step 1) reports honestly (`0 deposited projects` in the footer) instead of fabricating.
- **Wiki path resolves to a different cogni-wiki than the binding records.** Pre-flight Step 0(4) catches this — abort rather than querying the wrong wiki.
- **Knowledge slug mismatch.** Pre-flight Step 0(3) catches this — abort.

## Out of scope

- **Multi-question scoping.** This skill takes one question per run; chaining is a future enhancement.
- **Deep web-verified reporting.** That is `knowledge-compose --source wiki` (the deep rung).
- **Verifying a filed-back answer.** The opt-in `--file-back` deposit (Step 4) is honestly labeled `verification: unverified_shallow_rung` — the shallow rung runs no claim-alignment pass. A vetted synthesis is the deep rung's `knowledge-finalize` deposit, not this one.
- **`--file-back auto` (prompt-to-deposit) and multi-question deposits** — a future enhancement; today `--file-back` is the explicit `yes`/absent opt-in only.

## Output

- The synthesized, `[[slug]]`-cited answer grounded in the ranked wiki pages.
- One footer line appended: `Knowledge base: <slug> · <N> deposited projects · ...`

By default **no files are written** (read-only). When `--file-back yes` is
passed, the answer is additionally deposited as
`<wiki>/syntheses/<slug>.md` (`type: synthesis`, `verification:
unverified_shallow_rung`) with the index row, `entries_count` bump, backlinks,
and a `wiki/log.md` line (Step 4).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` — the accumulation thesis the shallow rung serves
- `${CLAUDE_PLUGIN_ROOT}/scripts/wiki-grounding.py` — the shared `rank` discovery primitive (index-first page selection)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/pipeline-summary.py cache-health --help` — fetch-cache health for the footer
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts/` — the vendored `wiki_index_update.py` / `config_bump.py` / `backlink_audit.py` write lockstep the `--file-back` deposit (Step 4) reuses
- `${CLAUDE_PLUGIN_ROOT}/skills/knowledge-finalize/SKILL.md` — the deep-rung synthesis deposit the shallow-rung `--file-back` mirrors (verified vs un-verified)
