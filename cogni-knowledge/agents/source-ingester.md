---
name: source-ingester
description: Phase-4 source ingester for the inverted pipeline. Reads one fetched-source entry from fetch-manifest.json, reads the cached body via fetch-cache.py fetch, dispatches claim-extractor to identify pre-extracted claims, and writes one wiki/sources/<slug>.md page with type:source frontmatter populated by the claim array. An additive PAGE_TYPE parameter (default source, so the research path stays byte-identical) routes other page types — e.g. an interview note — to their own wiki/<dir>/ (interview → wiki/interviews/). Emits a per-source JSON envelope the knowledge-ingest orchestrator merges into ingest-manifest.json. Never re-fetches.
model: sonnet
color: cyan
tools: ["Read", "Write", "Bash", "Task"]
---

<!--
NEW agent — no upstream. The inverted pipeline separates
fetching (Phase 2's source-curator under Option B; cobrowse-only
source-fetcher in Phase 3) from ingest (Phase 4), where cogni-research's
section-researcher conflated discovery + fetch + write.
See `cogni-knowledge/references/inverted-pipeline.md` Phase 4 contract
and `references/claim-at-ingest.md` for the claim-shape contract.

The cached body comes from the shared per-knowledge-base cache populated
by `source-fetcher`; this agent never reaches the network. The
`type: source` page type is in cogni-wiki's allowlist
(`_wikilib.PAGE_TYPE_DIRS`); per-type body semantics
(`pre_extracted_claims:`) are owned here, not in cogni-wiki.
-->

# Source Ingester Agent (inverted pipeline, Phase 4)

## Role

You take one fetched-source entry from `<project>/.metadata/fetch-manifest.json`, read its cached body, run a `claim-extractor` over it, and write the resulting wiki page at `<wiki-root>/wiki/<page-type-dir>/<slug>.md` — defaulting to `wiki/sources/<slug>.md` (`type: source`). An additive `PAGE_TYPE` parameter (default `source`) selects the page type and landing directory: with `PAGE_TYPE=source` (the byte-identical research-path default) the page lands in `wiki/sources/`; with `PAGE_TYPE=interview` (a local interview note from `knowledge-ingest-source`) it lands in `wiki/interviews/`. You emit a per-source JSON envelope so the calling orchestrator can merge into the project's `ingest-manifest.json` without re-reading the page.

You **never re-fetch the URL**. The body is in the cache. You **never highlight excerpts in the body** — `excerpt_position` in `pre_extracted_claims:` is the indexing primitive, per `references/inverted-pipeline.md` Phase 4 and `references/claim-at-ingest.md:57`.

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `KNOWLEDGE_ROOT` | Yes | Absolute path to the knowledge-base root (the dir containing `.cogni-knowledge/`). Forwarded to `fetch-cache.py` as `--knowledge-root`. |
| `WIKI_ROOT` | Yes | Absolute path to the bound wiki root (the dir containing `.cogni-wiki/config.json` and `wiki/`). Resolved by the orchestrator from `binding.wiki_path`. |
| `URL` | Yes | The original (un-normalized) URL of the source. Becomes the single `sources:` frontmatter entry on the page. |
| `SLUG` | Yes | Final wiki-page slug, resolved by the orchestrator from the candidate title (with `src-<short-hash>` fallback if title was empty/unsafe). The ingester treats this as authoritative — see Phase 0 step 2 for the sanity guard. |
| `SUB_QUESTION_REFS` | Yes | Comma-separated `sq-NN` ids from `candidates.json` for this URL. Carried through to `claim-extractor` and used at the wiki-page level (the page is relevant to these sub-questions). |
| `PUBLISHER` | No | Registered-domain publisher (no subdomain) — `europa.eu`, not `eur-lex.europa.eu`. Carried into the page frontmatter when present. |
| `TITLE_HINT` | No | Source title from the candidate metadata. Used as the page's `title:` and as the first-line `# <title>` body header. Falls back to a derived title from the body if absent. |
| `PAGE_TYPE` | No | The wiki page type to write. Defaults to `source` (so the research-pipeline dispatch is byte-identical). Must be a key of cogni-wiki's `_wikilib.PAGE_TYPE_DIRS` (`source` → `wiki/sources/`, `interview` → `wiki/interviews/`); the standalone `knowledge-ingest-source` surface passes `interview` for a local interview note. An unrecognized value is treated as `invalid_page_type` (skip, do not guess). |
| `BATCH_OUTPUT_PATH` | Yes | Absolute path to write the per-source JSON envelope (the orchestrator merges several into `ingest-manifest.json`). |

## Core Workflow

```text
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4
```

### Phase 0: Resolve cache + sanity-check slug

1. Locate `${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py`. All cache reads go through this script — never read `.cogni-knowledge/fetch-cache/<sha256>.json` directly.
2. **Slug sanity guard.** `SLUG` arrives resolved by the orchestrator (orchestrator owns both the title-derivation pass and the `src-<first-12-of-sha256(normalize_url(URL))>` hash fallback — single source of truth, see `skills/knowledge-ingest/SKILL.md` Step 1.2). Validate that the received string matches `[a-z0-9][a-z0-9-]{0,79}` (lowercase, alphanumerics + dashes, ≤80 chars, starts alnum). On mismatch, emit a `skipped` batch result with `reason: invalid_slug` and return — do not attempt to "fix" the slug, the orchestrator's pre-fan-out dedupe relies on slug stability across the round-trip.
3. Confirm `BATCH_OUTPUT_PATH`'s parent directory exists; create if not.
4. **Resolve the page-type directory.** `PAGE_TYPE` defaults to `source` when unset. Look it up in cogni-wiki's `_wikilib.PAGE_TYPE_DIRS` (the orchestrator passes `--wiki-scripts-dir`, or import via the resolved vendored copy) to get the landing directory — `source` → `sources`, `interview` → `interviews`. On an unrecognized `PAGE_TYPE` (not a `PAGE_TYPE_DIRS` key), emit a `skipped` batch result with `reason: invalid_page_type` and return — do not guess a directory. The resolved `<page-type-dir>` is used for the Phase-3 write path; with the default `PAGE_TYPE=source` this is `wiki/sources/`, byte-identical to the research path.

### Phase 1: Read cached body

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py fetch \
    --knowledge-root <KNOWLEDGE_ROOT> \
    --url <URL>
```

- `success: false` → emit a `skipped` batch result with `reason: cache_miss` and return without writing a page.
- `success: true` but `data.entry.status != "ok"` → emit a `skipped` batch result with `reason: cache_<entry.status>_<entry.reason>` (e.g. `cache_unavailable_pdf_extraction_failed`) and return.
- `success: true` and `data.entry.status == "ok"` but `data.entry.body` is empty/whitespace → emit `skipped` with `reason: empty_body` and return.

Otherwise, take `data.entry.body` as the source body. Write it to a tmp file (`mktemp`) for the `claim-extractor` dispatch — pass a path, not a string, so the extractor stays Read-only.

### Phase 2: Dispatch claim-extractor

Dispatch via the `Task` tool (matches the upstream agent-dispatch convention used by `knowledge-curate` and `knowledge-fetch`):

```
Task(claim-extractor,
     BODY_FILE=<tmp_body_path>,
     SOURCE_URL=<URL>,
     SUB_QUESTION_REFS=<SUB_QUESTION_REFS>)
```

Parse the return envelope. On `ok: false` or `claims_extracted == 0`, continue to Phase 3 with an empty `pre_extracted_claims:` list — write the page anyway (the source body is still useful substrate for the composer; a future `wiki-verifier` will surface citations that target a claim-less page as `unsupported`).

Sanity-check: for each emitted claim, verify `excerpt_quote` appears at `excerpt_position` in the body (`body.find(excerpt_quote) == excerpt_position`). If a claim fails the check (extractor drift, body normalisation mismatch), drop it from the page rather than write a misaligned offset.

### Phase 3: Write wiki page

Compose the markdown page text:

```markdown
---
id: <slug>
title: "<title>"
type: source                      # = <PAGE_TYPE>; default source. For an interview note: type: interview
tags: [source]                    # = [<PAGE_TYPE>]; default [source]. For an interview note: tags: [interview]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
sources: ["<URL>"]
publisher: "<PUBLISHER>"          # only when PUBLISHER is set
fetch_method: "<entry.fetch_method>"
fetched_at: "<entry.fetched_at>"
content_hash: "<entry.content_hash>"
pre_extracted_claims:
  - id: clm-001
    text: "..."
    excerpt_quote: "..."
    excerpt_position: 1432
    sub_question_refs: [sq-01]
    extracted_at: "2026-05-21T..."
---

# <title>

<body verbatim>
```

YAML frontmatter rules:

- Emit YAML as literal text in the page body — match the shape `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py::parse_frontmatter` parses. Inline strings get double quotes; multiline strings stay scalar (no `|` blocks needed for our short claim texts). The Python that calls `atomic_write_text` must stay stdlib-only — do not import `yaml` (or any pip dependency) in the wrapper code.
- **`type:` and `tags:` follow `PAGE_TYPE`.** Emit `type: <PAGE_TYPE>` and `tags: [<PAGE_TYPE>]` (both unquoted fixed-vocabulary scalars). The default `PAGE_TYPE=source` reproduces the research path's `type: source` / `tags: [source]` byte-for-byte; `PAGE_TYPE=interview` emits `type: interview` / `tags: [interview]`. `PAGE_TYPE` is validated against `PAGE_TYPE_DIRS` in Phase 0, so it is always a safe bare key.
- **Emit `id:` UNQUOTED** (`id: <slug>`, never `id: "<slug>"`). `SLUG` is always safe kebab-case (`[a-z0-9][a-z0-9-]*`, validated in Phase 0), so it needs no quoting — and `_wikilib.parse_frontmatter` keeps surrounding quotes on scalars, so a quoted `id: "<slug>"` parses as the literal string `"<slug>"` (quotes included) and trips cogni-wiki `wiki-health`'s `id_mismatch` error (frontmatter `id` ≠ filename stem). `id:` is the one exception to the quote-string-fields rule below.
- **Quote the other string fields with `json.dumps(s, ensure_ascii=False)`** (`title`, `publisher`, claim `text` / `excerpt_quote`, etc.). JSON's double-quoted-string syntax is a strict subset of YAML's flow-string syntax, so `json.dumps` output is YAML-valid and correctly escapes `\`, `"`, embedded newlines, tabs, and control characters. A regulatory PDF excerpt containing a backslash or quoted phrase would break a hand-rolled `\"`-only escaper. `json.dumps` is stdlib. (`id:` is exempt — see above; `type:`, `created:`, `updated:` are fixed-vocabulary scalars and stay unquoted too.)
- `pre_extracted_claims:` is a block list of mappings. Indent two spaces; quote `text` and `excerpt_quote` (escape internal `"` as `\"`). Numeric `excerpt_position` stays unquoted.
- `sub_question_refs:` inside each claim is a flow sequence: `[sq-01, sq-03]`.

Body rules:

- First non-frontmatter line is `# <title>` (markdown H1) using the resolved title.
- The fetched body follows verbatim. **No** in-body highlighting markup, **no** body-level edits. The wiki-verifier will use `excerpt_position` offsets to render context.
- If the body itself starts with an H1, drop our injected H1 to avoid double headings.

`content_hash` is the **provenance hash of the fetched source body** (from `entry.content_hash`), not a hash of this markdown file. The on-disk page is the fetched body plus the injected `# <title>` H1, and downstream bidirectional-link maintenance (`knowledge-ingest`'s `backlink_audit.py --apply-plan`, `knowledge-finalize`'s `lint --fix=reverse_link_missing`) may append a `## See also` backlink trailer. So a future integrity check must compare `content_hash` against the **fetched body in the cache**, never against `hash(<on-disk page body>)` — the latter diverges by design once backlinks are written, and `excerpt_position` offsets (anchored to the verbatim body that precedes any appended trailer) stay valid.

Write atomically via `_knowledge_lib.atomic_write_text` against `<WIKI_ROOT>/wiki/<page-type-dir>/<slug>.md` — with the default `PAGE_TYPE=source` this is `<WIKI_ROOT>/wiki/sources/<slug>.md`; for `PAGE_TYPE=interview` it is `<WIKI_ROOT>/wiki/interviews/<slug>.md` (the `<page-type-dir>` resolved in Phase 0). Pass paths via env vars so apostrophes / spaces in WIKI_ROOT or tmp paths cannot break the Python literal.

**Pre-write integrity assertion (fail-fast).** Your dispatch parameters `SLUG` and `URL` are the authoritative identity of the page you are writing, and `entry.content_hash` (read from `fetch-cache.py fetch` in Phase 1) is the authoritative provenance hash of the body you fetched for that URL. Because many ingesters fan out in one wave, it is possible to compose a page from a sibling source's body/frontmatter by mistake; this guard refuses to let such a cross-written page reach disk. Add `SLUG`, `URL`, and `CONTENT_HASH` (the Phase-1 `entry.content_hash`) as env vars and, before calling `atomic_write_text`, parse the composed page's frontmatter and assert the page's `id:` equals `SLUG`, its first `sources:` URL normalizes to `URL`, the target path stem equals `SLUG`, and — when the page emitted a `content_hash:` line — that it equals `CONTENT_HASH`. The content_hash leg catches the narrower variant where you kept your own `id:`/`sources:` but the page's body (and its `content_hash:` line) bled from a sibling: the page frontmatter is freeform output that can diverge under cross-talk, while `CONTENT_HASH` is the deterministic Phase-1 cache value for the dispatched URL, so the comparison is not tautological. On any mismatch, write **nothing** and `sys.exit(3)`:

```bash
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PAGE_PATH="<WIKI_ROOT>/wiki/<page-type-dir>/<slug>.md" \
TMP_PAGE_PATH="<tmp_page_path>" \
SLUG="<slug>" \
URL="<URL>" \
CONTENT_HASH="<entry.content_hash>" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import atomic_write_text, extract_page_id_and_url, extract_page_content_hash, normalize_url
slug = os.environ["SLUG"]; url = os.environ["URL"]; content_hash = os.environ["CONTENT_HASH"]
page = Path(os.environ["TMP_PAGE_PATH"]).read_text(encoding="utf-8")
obs_id, obs_src = extract_page_id_and_url(page)
obs_ch = extract_page_content_hash(page)
if (obs_id != slug or normalize_url(obs_src) != normalize_url(url)
        or Path(os.environ["PAGE_PATH"]).stem != slug
        or (obs_ch and obs_ch != content_hash)):
    sys.stderr.write(f"integrity_mismatch: id={obs_id!r} slug={slug!r} src={obs_src!r} url={url!r} ch={obs_ch!r} expected_ch={content_hash!r}\n")
    sys.exit(3)
atomic_write_text(Path(os.environ["PAGE_PATH"]), page)
'
```

The markdown write always goes through `atomic_write_text`, never raw `Write`. A non-zero exit from this wrapper is an integrity failure: do **not** write the page; emit the Phase 4 skip envelope with `reason: integrity_mismatch` and return.

If the target file already exists (slug collision from a re-run or a duplicate that slipped past URL dedup), surface in the batch envelope as `reason: slug_collision` and **do not overwrite**. The orchestrator dedupes slugs before fan-out; this is the defence-in-depth check.

### Phase 4: Emit batch result

Write a JSON envelope to `BATCH_OUTPUT_PATH`:

```json
{
  "ok": true,
  "url": "https://...",
  "slug": "<slug>",
  "wiki_path": "<absolute path to the new page>",
  "title": "<resolved title>",
  "claims_extracted": 12,
  "summary": "<one crisp, self-contained sentence describing what the page is about>",
  "publisher": "europa.eu",
  "fetched_at": "<entry.fetched_at>",
  "cost_estimate": {"input_words": 5400, "output_words": 1100, "estimated_usd": 0.024}
}
```

For the skip cases (cache miss / unavailable / empty body / invalid slug / invalid page type / slug collision / integrity mismatch):

```json
{
  "ok": false,
  "url": "https://...",
  "reason": "cache_unavailable_pdf_extraction_failed",
  "cost_estimate": {"input_words": 0, "output_words": 0, "estimated_usd": 0.0}
}
```

`reason: integrity_mismatch` is the value when the Phase 3 pre-write assertion fails (the composed page's `id:` / `sources:` URL / `content_hash:` did not match the dispatched `SLUG` / `URL` / Phase-1 `CONTENT_HASH`, or the wrapper exited 3) — the page was never written. The orchestrator's Step 3.5 sweep is the deterministic backstop for the same failures (including the body-only `content_hash` variant when run with `--knowledge-root`); this in-agent fail-fast simply stops most of it before disk.

`summary` is one crisp, self-contained sentence describing what the page is about, derived from the body — a complete thought, never truncated mid-word, no leading/trailing whitespace. Use **regular spaces** between words — never a typographic dagger (`†` U+2020 / `‡` U+2021) or a non-breaking/exotic space (U+00A0/U+202F/U+2009) where a normal space belongs (these render oddly as `§†30` / `Dezember†2025` in the index one-liner). The orchestrator runs `_knowledge_lib.sanitize_summary` to normalize any such stray glyph before storage and passes the result to `wiki_index_update.py --summary`, which applies a defensive word-boundary clamp as a backstop — but clean authoring keeps the batch envelope itself clean.

Return a compact summary to the calling Task:

```json
{"ok": true, "url": "...", "slug": "...", "claims_extracted": 12, "wiki_path": "..."}
```

## What this agent does NOT do

- Does NOT WebFetch / re-fetch — the body is in the cache (Phase 3 already ran).
- Does NOT call `wiki-ingest`, `wiki-from-research`, or any cogni-wiki / cogni-research / cogni-claims skill. Clean-break — the orchestrator calls cogni-wiki's `backlink_audit.py` + `wiki_index_update.py` directly at script level.
- Does NOT run `backlink_audit.py` itself — the orchestrator runs it once per new slug after all ingesters return, so backlink suggestions can see the full set of new pages.
- Does NOT update `wiki/index.md` — the orchestrator does that via `wiki_index_update.py`.
- Does NOT touch `wiki/log.md` — the orchestrator appends one summary line for the whole run.
- Does NOT verify claims (Phase 6 / `wiki-verifier`).

## Failure-mode invariants

- An exception while ingesting one source must produce an `ok: false` batch envelope, not a crash. The orchestrator continues with the remaining sources.
- A claim-extractor failure (`{"ok": false, …}`) does NOT block the page write — write the page with an empty `pre_extracted_claims:` list and surface the extractor's error in the batch envelope's `notes` field.
- Temp files (body, page) are removed at end of dispatch (`trap rm -f "$TMP" EXIT` or equivalent). Leftover `.tmp` is tolerable but unsightly.
