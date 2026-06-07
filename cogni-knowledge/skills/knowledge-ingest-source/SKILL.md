---
name: knowledge-ingest-source
description: "Standalone single-source ingest for cogni-knowledge — deposit ONE source directly into the bound wiki with no research run: a web page or PDF URL, a local file (.docx/.html/.txt), pasted text, a local PDF, or a local interview note. Lands one wiki/sources/<slug>.md page (or wiki/interviews/<slug>.md with type: interview for an interview note) carrying pre_extracted_claims: and the same diff-before-write + citation discipline as the research path; local inputs deposit honestly via fetch_method: direct. Use whenever the user says 'ingest this URL into my wiki', 'add this file/source to the knowledge base', 'ingest this interview note', 'paste this into my wiki', or 'single-source ingest'. For batch research-fetched sources use knowledge-ingest instead."
allowed-tools: Read, Write, Bash, Task, WebFetch
---

# Knowledge Ingest — Single Source

The **standalone** single-source surface: deposit ONE source directly into the
bound wiki, with **no research run** (no `knowledge-plan` → `knowledge-curate`
→ `knowledge-fetch` scaffold, no `fetch-manifest.json`). A user drops one
input — a **URL** (web page or PDF), a **local file** (`.docx`/`.html`/`.txt`),
**pasted text**, a **local PDF**, or a **local interview note** — into their
bound base and it lands as a `type: source` page (or a `type: interview` page in
`wiki/interviews/` for an interview note) carrying `pre_extracted_claims:`,
indexed and backlinked exactly like a research-ingested source. A URL stores
via `fetch_method: webfetch`; every local input stores honestly via
`fetch_method: direct` (the additive non-web method in `fetch-cache.py`'s
`VALID_FETCH_METHODS`) — see Step 1 for why a local source is never stored as a
`webfetch` lie.

The mechanism **reuses the research write path byte-for-byte**: it populates
the shared fetch-cache, then dispatches the `source-ingester` agent (which reads
the cached body via `fetch-cache.py fetch`, dispatches `claim-extractor`, and
writes the page atomically with its Phase-3 pre-write integrity assertion),
then runs the same `backlink_audit.py` + `wiki_index_update.py` +
`config_bump.py` post-write lockstep `knowledge-ingest` Step 4 runs. The
`source-ingester` takes an additive `PAGE_TYPE` parameter (default `source`, so
a URL / file deposit is byte-identical to the research path; `interview` for a
local interview note → `wiki/interviews/`). The only single-source-specific
work is **before** the ingester: acquire the source body into the cache —
fetching a URL, or **normalizing a local file** (`.docx`/`.html`/`.txt` via the
vendored `convert_to_md.py`) / reading a local PDF (Read tool) / capturing
pasted text, all stored via `fetch_method: direct` — and dedup the source
against existing wiki pages so a collision routes to diff-before-write instead
of a blind overwrite.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 4 —
`knowledge-ingest`" and `references/claim-at-ingest.md` once if you have not —
the claim-shape and write contracts are shared.

## Parameters

Exactly **one** input mode is required — `--url`, `--file`, `--paste`, or
`--interview` (the `--type interview` form). They are mutually exclusive; supplying
more than one is an error.

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--url` | One-of | A source URL to ingest (a web page, or a direct PDF URL). The original, un-normalized URL — it becomes the page's single `sources:` entry. Stored with `fetch_method: webfetch`. |
| `--file` | One-of | Path to a **local file** to ingest: `.txt` / `.html`/`.htm` (stdlib normalization) or `.docx` (via the optional `markitdown` external tool), or a local `.pdf` (read via the Read-tool page loop). Normalized to markdown via the vendored `convert_to_md.py`, then stored with `fetch_method: direct`. The `sources:` entry is a `file://<abspath>` provenance URI. |
| `--paste` | One-of | Path to a tempfile holding **pasted text** to ingest verbatim (the orchestrator writes the user's pasted block to a tempfile and passes its path — never interpolate the text into a shell literal). Stored with `fetch_method: direct`; `sources:` is a `paste:<sha256-prefix>` provenance URI. |
| `--interview` | One-of | Path to a local **interview note** file (markdown / `.txt`). Ingested like `--file` but lands as a `type: interview` page in `wiki/interviews/` (implies `--type interview`). Stored with `fetch_method: direct`. |
| `--type` | No | The wiki page type. Defaults to `source` for `--url`/`--file`/`--paste`; pass `--type interview` (or use `--interview`) to land the page in `wiki/interviews/` as `type: interview`. Threaded to `source-ingester` as `PAGE_TYPE`. Only `source` and `interview` are supported here. |
| `--queue` | No | Queue mode: instead of ingesting now, **enqueue** the resolved source for later draining via the vendored `wiki_queue.py --enqueue` (and report the job id). Useful for batching several local notes. Omitted = ingest immediately. |
| `--knowledge-slug` | No | Slug of the bound knowledge base (for display / disambiguation when several bases share a parent dir). |
| `--knowledge-root` | No | Override the knowledge-base directory (the dir containing `.cogni-knowledge/`). Defaults to the resolved knowledge root, same logic as `knowledge-ingest`. |
| `--title` | No | Title hint for the page (`title:` frontmatter + `# <title>` body header). Falls back to a body-derived title when absent. |
| `--publisher` | No | Registered-domain publisher (`europa.eu`, not `eur-lex.europa.eu`). Carried into the page frontmatter when present. |
| `--sub-question-refs` | No | Comma-separated `sq-NN` ids to tag the page (carried to `claim-extractor` and the page frontmatter). Defaults to a single synthetic `sq-00` so the claim-extractor contract is satisfied; the standalone surface has no plan. |
| `--theme` | No | Thematic index category (the `## <theme>` heading the source is filed under in `wiki/index.md`). Defaults to `Sources`. |
| `--dry-run` | No | Print the resolved plan (URL, slug, dedup verdict) without fetching, writing, or indexing. |

## When to run

- The user wants to deposit a single source directly into a bound knowledge
  base without running the research pipeline.
- A `binding.json` exists at the resolved knowledge root and its `wiki_path`
  resolves to a directory containing `.cogni-wiki/config.json`.

## Never run when

- No `binding.json` exists at the resolved knowledge root — offer
  `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing
  `.cogni-wiki/config.json` — the binding is stale.
- No input mode is supplied, or more than one of `--url` / `--file` /
  `--paste` / `--interview` is supplied — exactly one is required.

## Out of scope (deferred)

This surface accepts a **URL, a local file, pasted text, a local PDF, or a
local interview note** → `type: source` (or `type: interview`), reusing existing
primitives end-to-end. Still deferred to follow-ups:

- **Cross-lingual** single-source handling (a DE↔EN claim merge on a single
  deposited source — the Phase-4.5 `cross-lingual-claim-merger` operates on the
  distilled layer, not the single-source ingest path).

## Workflow

### 0. Pre-flight

**Required plugin + script dir.** Probe `cogni-wiki` and resolve the
`wiki-ingest` script dir exactly as `knowledge-ingest` Step 0 does (vendored
copy first, sibling/cache fallback), so this skill's Step 5 post-write lockstep
(mirroring `knowledge-ingest`'s Step 4) can call `backlink_audit.py` /
`wiki_index_update.py` / `config_bump.py`:

```
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || abort "cogni-wiki wiki-ingest scripts not found"
```

The vendored `convert_to_md.py` (local-file → markdown normalization) and
`wiki_queue.py` (queue mode) live in the **same** `wiki-ingest` script dir, so
they resolve through the same probe — `$WIKI_INGEST_SCRIPTS/convert_to_md.py`
and `$WIKI_INGEST_SCRIPTS/wiki_queue.py`. No separate resolution is needed
(resolve them only when the chosen input mode / `--queue` actually requires
them).

**Binding + wiki root.** Resolve `knowledge_root` (same logic as
`knowledge-ingest` / `knowledge-fetch`) and read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`. Parse
`data.binding.wiki_path` as `WIKI_ROOT`; confirm `<WIKI_ROOT>/.cogni-wiki/config.json`
exists and `<WIKI_ROOT>/wiki/` is writeable; abort otherwise.

### 1. Acquire the source body into the shared cache

The `source-ingester` reads its body via `fetch-cache.py fetch`, so the
source's body must be in the cache first, keyed by a stable `SOURCE_URL` (the
real URL for `--url`, or a `file://` / `paste:` provenance URI for a local
input). **Do not re-acquire if a fresh entry already exists** —
`fetch-cache.py fetch --knowledge-root <knowledge_root> --url <SOURCE_URL>`
returning `success: true` (with the cached entry's `data.entry.status == "ok"`)
means the body is already cached; skip to Step 2.

Otherwise branch on the chosen input mode. **A URL stores with
`--fetch-method webfetch`; every local input (`--file`/`--paste`/`--interview`)
stores with `--fetch-method direct`** — the honest non-web method already in
`fetch-cache.py`'s `VALID_FETCH_METHODS`. Never store a local input as
`webfetch` (dishonest provenance).

**`--url` (web page):** `SOURCE_URL` = the URL. `WebFetch` it. On success, write
the body to a tempfile and store it:
```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py store \
    --knowledge-root <knowledge_root> \
    --url "<SOURCE_URL>" \
    --fetch-method webfetch \
    --status ok \
    --body-file <tmp_body_file> \
    --publisher "<publisher, if known>"
```
On a fetch failure (4xx/5xx/timeout/empty): store
`--status unavailable --reason <webfetch_*>` and stop — nothing to ingest.

**`--url` (PDF URL) and `--file` of a local `.pdf`:** replicate the established
PDF posture (`agents/source-curator.md` PDF branch) — for a URL detect via
`_knowledge_lib.is_pdf_response`; for a local `.pdf`, read it **with the Read
tool's page loop** directly. Read in `1-20` windows (cap 200 pages), concatenate
the extracted text, then `fetch-cache.py store … --status ok` (`--fetch-method
webfetch` for a PDF URL; `--fetch-method direct` for a local `.pdf`, with
`SOURCE_URL` = `file://<abspath>`). **No homegrown / external PDF parser** — the
Read tool is the only PDF path (the vendored `convert_to_md.py`'s `noop-pdf`
backend does **not** parse and is not used for body text). On a
render/extraction failure, store `--status unavailable --reason
pdf_render_unavailable` (or `pdf_extraction_failed`) and stop with an honest
message — do not fabricate a body.

**`--file` of `.txt` / `.html`/`.htm` / `.docx`:** normalize to markdown via the
vendored `convert_to_md.py`, then store the converted text with
`--fetch-method direct` and `SOURCE_URL` = `file://<abspath>`:
```
python3 "$WIKI_INGEST_SCRIPTS/convert_to_md.py" --source "<abspath>"
# → {success, data: {converted_path, backend, ...}}  — read data.converted_path
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py store \
    --knowledge-root <knowledge_root> \
    --url "file://<abspath>" \
    --fetch-method direct \
    --status ok \
    --body-file <data.converted_path>
```
`.txt` uses the `stdlib-passthrough` backend and `.html`/`.htm` the
`stdlib-html` backend (both stdlib-only). `.docx` uses the **optional external
`markitdown` CLI**: when `convert_to_md.py` returns `success: false` with a
`markitdown`-absent / `unsupported` backend, **degrade to an honest error**
(tell the user `.docx` ingest needs `markitdown` installed) — do **not** crash
and do **not** fabricate a body. An unsupported extension is an honest error,
not a guess.

**`--paste` (pasted text):** the orchestrator already holds the pasted block in
a tempfile (`--paste <tmpfile>`). `SOURCE_URL` = `paste:<first-12-hex of
sha256(body)>` — hash the body text (not the tempfile path, which is not stable
across runs) so re-pasting the same text dedups. Store the tempfile verbatim
with `--fetch-method direct --status ok --body-file <tmpfile>`.

**`--interview` (local interview note):** identical to `--file` (markdown/`.txt`
normalization, `--fetch-method direct`, `SOURCE_URL` = `file://<abspath>`), but
`PAGE_TYPE=interview` carries through Step 4 so the page lands in
`wiki/interviews/`.

**Retain the acquired body text in context** — Steps 2 (title fallback) and 3
(the grounding query) derive from the same body's first ~100 words / a
body-derived title. Reuse the body you just acquired; do not re-read it from the
cache or the tempfile (a 200-page PDF concatenation is expensive to re-load).

`--dry-run` stops here after printing the resolved `SOURCE_URL`, input mode,
slug (Step 2), and dedup verdict (Step 3) — no acquire, no store, no write.

**`--queue` short-circuit.** When `--queue` is set, do **not** ingest now —
after acquiring the body into the cache (above), enqueue the source for later
draining instead of dispatching the ingester:
```
python3 "$WIKI_INGEST_SCRIPTS/wiki_queue.py" --wiki-root <WIKI_ROOT> \
    --enqueue --source "<SOURCE_URL>" --type "<--type, default source>" \
    --title "<--title, if set>"
```
Report the returned `job_id` and stop (Steps 2–6 run when the queue is later
drained). Omit `--queue` for the default ingest-now path.

### 2. Resolve the slug

Single source of truth — `_knowledge_lib.slugify` (the same helper
`knowledge-ingest` Step 1.2 uses). Pass the title via env var (never
interpolate untrusted text into a Python literal):

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
CANDIDATE_TITLE="<--title, or a body-derived title>" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import slugify
print(slugify(os.environ["CANDIDATE_TITLE"]) or "")
'
```

On an empty result (title was non-alnum / missing), fall back to
`src-<first-12-of-sha256(normalize_url(SOURCE_URL))>` via
`python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py key --url <SOURCE_URL> --bare`
(first 12 hex chars). The resolved string must match `[a-z0-9][a-z0-9-]{0,79}`.
For a local file with no `--title`, a body-derived title (the note's first
heading / first line) is preferred over the `src-<hash>` fallback so an
interview note lands under a readable slug.

### 3. Dedup against existing wiki pages (diff-before-write gate)

Before writing, check whether the bound wiki already covers this source, via
the shared wiki-grounding discovery primitive (the same one `wiki-coverage.py`
and `wiki-source-manifest.py` resolve to):

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/wiki-grounding.py rank \
    --wiki-root <WIKI_ROOT> \
    --question "<--title + first ~100 words of the body>" \
    --theme-label "<--theme, if set>"
```

Read `data.pages[]` (ranked covering pages) and `data.coverage_verdict`:

- **A covering page resolves to an existing `wiki/sources/<that-slug>.md`** (or,
  for an interview note, `wiki/interviews/<that-slug>.md`) — a genuine collision,
  the same source already on the wiki → **do not blind-write.** Surface the
  collision and hand to the **diff-before-write update path**: tell the user the
  existing page covers this source and offer to update it via
  `cogni-wiki:wiki-update` (or the re-homed equivalent) rather than creating a
  duplicate. Stop here unless the user confirms a forced re-ingest under a new
  slug.
- **No covering page (or only weak/partial thematic overlap)** → continue to
  Step 4. (Thematic neighbours are expected and are fine — they become
  backlink candidates in Step 5, not collisions.)

### 4. Dispatch source-ingester (single entry)

Dispatch the `source-ingester` agent via `Task` with one entry — the same
parameter shape `knowledge-ingest` Step 3 uses, **plus the additive `PAGE_TYPE`**
(default `source`; `interview` for an interview note). With `PAGE_TYPE=source`
this dispatch is byte-identical to the research path:

```
Task(source-ingester,
     KNOWLEDGE_ROOT=<knowledge_root>,
     WIKI_ROOT=<WIKI_ROOT>,
     URL=<SOURCE_URL>,
     SLUG=<resolved slug from Step 2>,
     PAGE_TYPE=<source | interview>,
     SUB_QUESTION_REFS=<--sub-question-refs, or sq-00>,
     PUBLISHER=<--publisher, if set>,
     TITLE_HINT=<--title, if set>,
     BATCH_OUTPUT_PATH=<tmp>/.ingest.single.<slug>.json)
```

The agent reads the cached body, runs `claim-extractor`, and writes
`<WIKI_ROOT>/wiki/<page-type-dir>/<slug>.md` (`wiki/sources/` for `source`,
`wiki/interviews/` for `interview`) atomically with its Phase-3 pre-write
integrity assertion (`id == SLUG`, first `sources:` URL normalizes to
`SOURCE_URL`, path stem == `SLUG`, `content_hash:` matches the cache). Read the
`BATCH_OUTPUT_PATH` envelope:

- `ok: true` → the page is on disk; continue to Step 5.
- `ok: false` (`cache_miss` / `invalid_slug` / `invalid_page_type` /
  `slug_collision` / `integrity_mismatch` / empty body) → surface the `reason`
  and stop. No index or backlink work for a page that was not written.

### 5. Post-write lockstep (same as knowledge-ingest Step 4)

For the one new slug, run the identical sequence `knowledge-ingest` Step 4 runs
(reuse `$WIKI_INGEST_SCRIPTS`):

1. **Backlink audit + apply** — `backlink_audit.py --new-page <slug> --top 8
   --min-confidence medium`, then curate a `targets[]` write-back plan (one
   `[[<slug>]]` trailer per genuinely-related sibling page) and apply it via
   `backlink_audit.py --new-page <slug> --apply-plan -`. Skip apply for a slug
   with no genuine relation — never invent a backlink.
2. **Index update** — sanitize the one-sentence summary via
   `_knowledge_lib.sanitize_summary` (env-var pattern), then
   `wiki_index_update.py --slug <slug> --summary "$CLEAN_SUMMARY" --category
   "<--theme, or the page-type default: Sources for a source, Interviews for an
   interview note>" --max-summary 240`. Capture the envelope; when
   `data.action == "inserted"` the index gained a new row.
3. **entries_count bump** — only when Step 5.2 inserted a new row:
   `config_bump.py --wiki-root "$WIKI_ROOT" --key entries_count --delta 1`.
   Non-fatal on failure (the page is already discoverable; surface in the
   summary, reconcilable via `wiki-lint --fix=entries_count_drift`).

### 6. Summary

Print a short summary: the deposited page path, claims extracted, the dedup
verdict (new / collision-routed-to-update), backlinks applied, and whether
`entries_count` bumped. One line, no follow-up question — the source is on the
wiki and future `knowledge-compose` / `knowledge-query` runs read it like any
research-ingested source.
