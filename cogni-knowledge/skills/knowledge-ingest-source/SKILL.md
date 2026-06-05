---
name: knowledge-ingest-source
description: "Standalone single-source ingest for cogni-knowledge — deposit ONE source directly into the bound wiki without a research run. Reads a URL (a web page, or a PDF URL via the Read-tool page loop), claim-extracts it, and writes one wiki/sources/<slug>.md page with pre_extracted_claims: and the same diff-before-write + citation discipline as the research path. Use whenever the user says 'ingest this URL into my wiki', 'add this source to the knowledge base', 'drop this page into my wiki', 'single-source ingest', 'ingest one source', or wants to deposit a single source directly without running knowledge-plan → curate → fetch. For a batch of research-fetched sources use knowledge-ingest instead."
allowed-tools: Read, Write, Bash, Task, WebFetch
---

# Knowledge Ingest — Single Source

The **standalone** single-source surface: deposit ONE source directly into the
bound wiki, with **no research run** (no `knowledge-plan` → `knowledge-curate`
→ `knowledge-fetch` scaffold, no `fetch-manifest.json`). This is the
standalone-Karpathy-wiki capability — a user drops one URL into their bound
base and it lands as a `type: source` page carrying `pre_extracted_claims:`,
indexed and backlinked exactly like a research-ingested source.

The mechanism **reuses the research write path byte-for-byte**: it populates
the shared fetch-cache, then dispatches the unchanged `source-ingester` agent
(which reads the cached body via `fetch-cache.py fetch`, dispatches
`claim-extractor`, and writes the page atomically with its Phase-3 pre-write
integrity assertion), then runs the same `backlink_audit.py` +
`wiki_index_update.py` + `config_bump.py` post-write lockstep
`knowledge-ingest` Step 4 runs. The only single-source-specific work is
**before** the ingester: fetch the URL into the cache, and dedup the source
against existing wiki pages so a collision routes to diff-before-write instead
of a blind overwrite.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 4 —
`knowledge-ingest`" and `references/claim-at-ingest.md` once if you have not —
the claim-shape and write contracts are shared.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--url` | Yes | The source URL to ingest (a web page, or a direct PDF URL). The original, un-normalized URL — it becomes the page's single `sources:` entry. |
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
- The input is a **local file, pasted text, a local PDF, or a local interview
  note** (not a URL). These are deferred — see "Out of scope" below — so this
  skill ingests **URLs** only.

## Out of scope (deferred)

This increment ships the **URL → `type: source`** path — the clean, fully
honest slice that reuses existing primitives end-to-end. Deferred to
follow-ups:

- **Local sources** — pasted text, a local file (`.docx`/`.html`/`.txt`), a
  local PDF, or a local interview note. Blocked on the fetch-cache
  `fetch_method` vocabulary: `VALID_FETCH_METHODS = {webfetch,
  cobrowse_interactive}` is web-coupled and **coordinated additively with
  cogni-claims** (see `scripts/fetch-cache.py`). A local source is neither
  method, so depositing it honestly needs that vocabulary question resolved
  first (add a `direct` method on both sides, or a parallel non-web store) —
  not an autonomous in-this-PR change.
- **The `interview` page type** (`type: interview` → `wiki/interviews/`). The
  unchanged `source-ingester` writes `type: source` → `wiki/sources/` only;
  interview routing needs an additive `PAGE_TYPE` on that agent, which lands
  with the interview-input work above (an interview note is almost always a
  local source, so the two defer together).
- **File normalization** via the not-yet-vendored `convert_to_md.py`
  (`.docx`/`.html` → markdown).
- **Queue mode** via the not-yet-vendored `wiki_queue.py`
  (`--enqueue`/`--next`/`--complete`).
- **Cross-lingual** single-source handling.

## Workflow

### 0. Pre-flight

**Required plugin + script dir.** Probe `cogni-wiki` and resolve the
`wiki-ingest` script dir exactly as `knowledge-ingest` Step 0 does (vendored
copy first, sibling/cache fallback), so Step 5's post-write lockstep can call
`backlink_audit.py` / `wiki_index_update.py` / `config_bump.py`:

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
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest) || abort "cogni-wiki wiki-ingest scripts not found"
```

**Binding + wiki root.** Resolve `knowledge_root` (same logic as
`knowledge-ingest` / `knowledge-fetch`) and read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`. Parse
`data.binding.wiki_path` as `WIKI_ROOT`; confirm `<WIKI_ROOT>/.cogni-wiki/config.json`
exists and `<WIKI_ROOT>/wiki/` is writeable; abort otherwise.

### 1. Fetch the URL into the shared cache

The `source-ingester` reads its body via `fetch-cache.py fetch`, so the URL's
body must be in the cache first. **Do not re-fetch if a fresh entry already
exists** — `fetch-cache.py fetch --knowledge-root <knowledge_root> --url <URL>`
returning `status: ok` means the body is cached; skip to Step 2.

Otherwise fetch and store:

1. **Web page:** `WebFetch` the URL. On success, write the body to a tempfile
   and store it:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py store \
       --knowledge-root <knowledge_root> \
       --url "<URL>" \
       --fetch-method webfetch \
       --status ok \
       --body-file <tmp_body_file> \
       --publisher "<publisher, if known>"
   ```
2. **PDF URL:** replicate the established PDF posture (`agents/source-curator.md`
   PDF branch) — detect via `_knowledge_lib.is_pdf_response`, read with the
   **Read tool's page loop** in `1-20` windows (cap 200 pages), concatenate the
   extracted text, then `fetch-cache.py store … --fetch-method webfetch
   --status ok`. **No homegrown / external PDF parser** — the Read tool is the
   only PDF path. On a render/extraction failure, store
   `--status unavailable --reason pdf_render_unavailable` (or
   `pdf_extraction_failed`) and stop with an honest message — do not fabricate
   a body.
3. **Fetch failure** (4xx/5xx/timeout/empty): store
   `--status unavailable --reason <webfetch_*>` and stop — nothing to ingest.

**Retain the fetched body text in context** — Steps 2 (title fallback) and 3
(the grounding query) derive from the same body's first ~100 words / a
body-derived title. Reuse the body you just fetched; do not re-read it from the
cache or the tempfile (a 200-page PDF concatenation is expensive to re-load).

`--dry-run` stops here after printing the resolved URL, slug (Step 2), and
dedup verdict (Step 3) — no fetch, no store, no write.

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
`src-<first-12-of-sha256(normalize_url(URL))>` via
`python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py key --url <URL> --bare`
(first 12 hex chars). The resolved string must match `[a-z0-9][a-z0-9-]{0,79}`.

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

- **A covering page resolves to an existing `wiki/sources/<that-slug>.md`** (a
  genuine collision — same source already on the wiki) → **do not blind-write.**
  Surface the collision and hand to the **diff-before-write update path**: tell
  the user the existing page covers this source and offer to update it via
  `cogni-wiki:wiki-update` (or the re-homed equivalent) rather than creating a
  duplicate. Stop here unless the user confirms a forced re-ingest under a new
  slug.
- **No covering page (or only weak/partial thematic overlap)** → continue to
  Step 4. (Thematic neighbours are expected and are fine — they become
  backlink candidates in Step 5, not collisions.)

### 4. Dispatch source-ingester (single entry)

Dispatch the **unchanged** `source-ingester` agent via `Task` with one entry —
the same parameter shape `knowledge-ingest` Step 3 uses:

```
Task(source-ingester,
     KNOWLEDGE_ROOT=<knowledge_root>,
     WIKI_ROOT=<WIKI_ROOT>,
     URL=<URL>,
     SLUG=<resolved slug from Step 2>,
     SUB_QUESTION_REFS=<--sub-question-refs, or sq-00>,
     PUBLISHER=<--publisher, if set>,
     TITLE_HINT=<--title, if set>,
     BATCH_OUTPUT_PATH=<tmp>/.ingest.single.<slug>.json)
```

The agent reads the cached body, runs `claim-extractor`, and writes
`<WIKI_ROOT>/wiki/sources/<slug>.md` atomically with its Phase-3 pre-write
integrity assertion (`id == SLUG`, first `sources:` URL normalizes to `URL`,
path stem == `SLUG`, `content_hash:` matches the cache). Read the
`BATCH_OUTPUT_PATH` envelope:

- `ok: true` → the page is on disk; continue to Step 5.
- `ok: false` (`cache_miss` / `invalid_slug` / `slug_collision` /
  `integrity_mismatch` / empty body) → surface the `reason` and stop. No index
  or backlink work for a page that was not written.

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
   "<--theme, or Sources>" --max-summary 240`. Capture the envelope; when
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
