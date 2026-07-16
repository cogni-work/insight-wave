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
| `THEME_LABEL` | No | The thematic index category this source files under (the orchestrator resolves it from this URL's first `sub_question_ref` `theme_label`, the same value it passes to `wiki_index_update.py --category`). Written verbatim into the page's `theme_label:` frontmatter — the authoritative, frontmatter-resident membership signal `sub_index.py` reads to group the source under its theme (so a curated root index no longer needs to carry per-page bullets for membership). Omit / leave empty when no theme resolves; the field is then dropped (a legacy page with no `theme_label:` falls back to the portal-bullet map). |
| `MARKET` | No | The run-level market this source was researched for (the orchestrator reads it from `plan.json::market` — one value per research run, e.g. `dach`). Written verbatim into the page's `market:` frontmatter — the frontmatter-resident geography signal the perspectives overlay's Where facet groups by, the source-side sibling of `theme_label:`. Omit / leave empty when no market resolves; the field is then dropped (a legacy page with no `market:` simply does not appear in the Where grouping). |
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
2. **Slug sanity guard.** `SLUG` arrives resolved by the orchestrator (orchestrator owns both the title-derivation pass and the `src-<first-12-of-sha256(normalize_url(URL))>` hash fallback — single source of truth, see `skills/knowledge-ingest/SKILL.md` Step 1.2). Validate that the received string matches the anchored full-string guard `^[a-z0-9][a-z0-9-]{0,79}$` (a full-string match — lowercase, alphanumerics + dashes, ≤80 chars, starts alnum; the same guard the orchestrator applies pre-dispatch in Step 1.2, so an over-80-char slug is rejected, never accepted by an 80-char prefix). On mismatch, emit a `skipped` batch result with `reason: invalid_slug` and return — do not attempt to "fix" the slug, the orchestrator's pre-fan-out dedupe relies on slug stability across the round-trip.
3. Confirm `BATCH_OUTPUT_PATH`'s parent directory exists; create if not.
4. **Resolve the page-type directory.** `PAGE_TYPE` defaults to `source` when unset. Look it up in cogni-wiki's `_wikilib.PAGE_TYPE_DIRS` (the orchestrator passes `--wiki-scripts-dir`, or import via the resolved vendored copy) to get the landing directory — `source` → `sources`, `interview` → `interviews`. On an unrecognized `PAGE_TYPE` (not a `PAGE_TYPE_DIRS` key), emit a `skipped` batch result with `reason: invalid_page_type` and return — do not guess a directory. The resolved `<page-type-dir>` is used for the Phase-3 write path; with the default `PAGE_TYPE=source` this is `wiki/sources/`, byte-identical to the research path.
5. **Capture the dispatch start time** for the Phase-4 `duration_ms` field. Record a monotonic millisecond timestamp at the very start of work, before the Phase-1 cache read and the Phase-2 `claim-extractor` dispatch, so the measured wall clock spans this agent's full lifetime (including the sub-agent):

   ```bash
   START_MS=$(python3 -c 'import time; print(int(time.time() * 1000))')
   ```

   Hold `START_MS` for Phase 4. (This runs even on the skip paths so a skip envelope can still report its `duration_ms`.)

6. **Create the per-dispatch scratch root.** The session scratchpad is **shared across every parallel sibling `source-ingester` dispatch in the same ingest wave** (many ingesters fan out at once). Writing any intermediate artifact to a fixed, generic name there lets a concurrent sibling clobber it mid-dispatch — so this dispatch could read *another* source's body and mis-attribute its claims/provenance. Guard against that by giving **this** dispatch its own isolated scratch directory and homing every intermediate artifact under it:

   ```bash
   WORK_DIR=$(mktemp -d)
   ```

   `mktemp -d` returns a fresh, uniquely-named directory (never a fixed template — a bare `mktemp` template without `XXXXXX` is *not* randomized on macOS BSD `mktemp`). `WORK_DIR` is the load-bearing isolation boundary for this dispatch: the Phase-1 body file and the Phase-3 composed page (the only two scratch artifacts this agent writes) both live under it, and Phase 4's cleanup removes the whole directory. Hold `WORK_DIR` for Phases 1, 3, and the cleanup invariant.

### Phase 1: Read cached body

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py fetch \
    --knowledge-root <KNOWLEDGE_ROOT> \
    --url <URL>
```

- `success: false` → emit a `skipped` batch result with `reason: cache_miss` and return without writing a page.
- `success: true` but `data.entry.status != "ok"` → emit a `skipped` batch result with `reason: cache_<entry.status>_<entry.reason>` (e.g. `cache_unavailable_pdf_extraction_failed`) and return.
- `success: true` and `data.entry.status == "ok"` but `data.entry.body` is empty/whitespace → emit `skipped` with `reason: empty_body` and return.

Otherwise, take `data.entry.body` as the source body. Write it to the per-dispatch body file `$WORK_DIR/body.txt` (under the Phase-0 scratch root — never a bare `mktemp` or a fixed name in the shared scratchpad) for the `claim-extractor` dispatch — pass a path, not a string, so the extractor stays Read-only.

### Phase 2: Dispatch claim-extractor

Dispatch via the `Task` tool (matches the upstream agent-dispatch convention used by `knowledge-curate` and `knowledge-fetch`):

```
Task(claim-extractor,
     BODY_FILE=$WORK_DIR/body.txt,
     SOURCE_URL=<URL>,
     SUB_QUESTION_REFS=<SUB_QUESTION_REFS>)
```

Parse the return envelope. On `ok: false` or `claims_extracted == 0`, continue to Phase 3 with an empty `pre_extracted_claims:` list — write the page anyway (the source body is still useful substrate for the composer; a future `wiki-verifier` will surface citations that target a claim-less page as `unsupported`).

**Capture the extractor's `cost_estimate`** from the return envelope (`{input_words, output_words, estimated_usd}`) and hold it for the Phase-4 cost sum — do not discard it. On an `ok: false` / missing envelope, treat it as `{input_words: 0, output_words: 0, estimated_usd: 0.0}`. The claim-extractor is your only sub-call; its cost is real ingest spend (the dominant per-run cost) and must flow into the ledger rather than being swallowed here.

Decide presence and recompute `excerpt_position` — never trust the extractor's hand-counted value. **Decide present-vs-absent with the normalized matcher, not a raw substring test**: run a `python3` one-liner that puts `${CLAUDE_PLUGIN_ROOT}/scripts` on `sys.path`, does `from _knowledge_lib import excerpt_present`, and evaluates `excerpt_present(excerpt_quote, body)`. The matcher tolerates the mechanical PDF-vs-HTML drift (ligature codepoints, smart quotes, column-wrap intra-word newlines) that a raw `in` / `find()` test penalizes — without it, PDF sources are systematically penalized vs their clean HTML twins (claims dropped, the page quarantined at the Step 3.5 integrity sweep). Then, per emitted claim:

- **present (`excerpt_present(...)` is `True`)** → **keep the claim**. Recompute its `excerpt_position` with `body.find(excerpt_quote)`: when `find() >= 0`, overwrite with the recomputed offset (a position that differs from the extractor's value — offset drift on multi-byte / typographic characters — is **not** a drop condition, the recomputed offset is correct by construction); when `find() == -1` (the quote matched only after normalization, so there is no exact raw offset), leave the extractor's `excerpt_position` as-is. This is the fix for the silent-claim-loss failure class: a present quote is never dropped just because the LLM mis-counted code-points or the body's typography drifted.
- **absent (`excerpt_present(...)` is `False`)** → the quote is genuinely absent from the body (an extractor hallucination, not mere typographic drift). **Drop only this claim**, and surface it as a per-claim warning in the Phase 4 batch envelope's `notes` field (e.g. `"dropped 1 claim: excerpt_quote not found in body"`) so a real extraction error is visible rather than silently lost.

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
theme_label: "<THEME_LABEL>"      # only when THEME_LABEL is set — the frontmatter-resident theme-membership signal sub_index.py reads
market: "<MARKET>"                # only when MARKET is set — the frontmatter-resident geography signal the Where facet groups by
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

Type: Source · raw

<body verbatim>
```

YAML frontmatter rules:

- Emit YAML as literal text in the page body — match the shape `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py::parse_frontmatter` parses. Inline strings get double quotes; multiline strings stay scalar (no `|` blocks needed for our short claim texts). The Python that calls `atomic_write_text` must stay stdlib-only — do not import `yaml` (or any pip dependency) in the wrapper code.
- **`type:` and `tags:` follow `PAGE_TYPE`.** Emit `type: <PAGE_TYPE>` and `tags: [<PAGE_TYPE>]` (both unquoted fixed-vocabulary scalars). The default `PAGE_TYPE=source` reproduces the research path's `type: source` / `tags: [source]` byte-for-byte; `PAGE_TYPE=interview` emits `type: interview` / `tags: [interview]`. `PAGE_TYPE` is validated against `PAGE_TYPE_DIRS` in Phase 0, so it is always a safe bare key.
- **Emit `id:` UNQUOTED** (`id: <slug>`, never `id: "<slug>"`). `SLUG` is always safe kebab-case (`[a-z0-9][a-z0-9-]*`, validated in Phase 0), so it needs no quoting — and `_wikilib.parse_frontmatter` keeps surrounding quotes on scalars, so a quoted `id: "<slug>"` parses as the literal string `"<slug>"` (quotes included) and trips cogni-wiki `wiki-health`'s `id_mismatch` error (frontmatter `id` ≠ filename stem). `id:` is the one exception to the quote-string-fields rule below.
- **Quote the other string fields with `json.dumps(s, ensure_ascii=False)`** (`title`, `publisher`, `theme_label`, claim `text` / `excerpt_quote`, etc.). JSON's double-quoted-string syntax is a strict subset of YAML's flow-string syntax, so `json.dumps` output is YAML-valid and correctly escapes `\`, `"`, embedded newlines, tabs, and control characters. A regulatory PDF excerpt containing a backslash or quoted phrase would break a hand-rolled `\"`-only escaper. `json.dumps` is stdlib. (`id:` is exempt — see above; `type:`, `created:`, `updated:` are fixed-vocabulary scalars and stay unquoted too.)
- **Emit `theme_label:` only when `THEME_LABEL` is set and non-empty** (drop the line entirely otherwise — a missing field reads as "no frontmatter membership", and `sub_index.py` falls back to the legacy portal-bullet map). When present, quote it with `json.dumps` like any other string field. This is the source side of the same on-page theme signal the `question` type already carries (`theme_via_frontmatter`) and the distilled types resolve transitively (`theme_via_backing_sources`).
- **Emit `market:` only when `MARKET` is set and non-empty** (drop the line entirely otherwise — a missing field reads as "no market membership", and the perspectives overlay's Where facet simply omits the page from its grouping). When present, quote it with `json.dumps` like any other string field. This is the geography sibling of `theme_label:` — a run-level value (one market per research run, from `plan.json::market`) persisted per source so the Where facet has a frontmatter-resident signal to group by.
- `pre_extracted_claims:` is a block list of mappings. Indent two spaces; quote `text` and `excerpt_quote` (escape internal `"` as `\"`). Numeric `excerpt_position` stays unquoted.
- `sub_question_refs:` inside each claim is a flow sequence: `[sq-01, sq-03]`.

Body rules:

- First non-frontmatter line is `# <title>` (markdown H1) using the resolved title.
- **Immediately under the H1, emit one deterministic reader-facing type line, then a blank line.** The line is a fixed constant keyed off `PAGE_TYPE` — emit `Type: Source · raw` for the default `PAGE_TYPE=source`, or `Type: Interview · raw` for `PAGE_TYPE=interview`. The separator is the U+00B7 MIDDLE DOT (`·`), and `raw` is the stage word (a source/interview page is never distilled). This is a verbatim literal, not a judgment call — re-rendering an unchanged page must produce a byte-identical line. It mirrors the engine-owned `_knowledge_lib.page_type_line(<PAGE_TYPE>)` projection the other page renderers emit (concept/entity/person, question, synthesis), so a reader landing mid-wiki can state what the page is on arrival.
- The fetched body follows verbatim. **No** in-body highlighting markup, **no** body-level edits. The wiki-verifier will use `excerpt_position` offsets to render context.
- If the body itself starts with an H1, drop our injected `# <title>` H1 to avoid double headings — but **still emit the type line** (it is reader-facing metadata, not a heading), so it leads the body in that case.

`content_hash` is the **provenance hash of the fetched source body** (from `entry.content_hash`), not a hash of this markdown file. The on-disk page is the fetched body plus the injected `# <title>` H1 and the deterministic `Type: …` line, and downstream bidirectional-link maintenance (`knowledge-ingest`'s `backlink_audit.py --apply-plan`, `knowledge-finalize`'s `lint --fix=reverse_link_missing`) may append a `## See also` backlink trailer. So a future integrity check must compare `content_hash` against the **fetched body in the cache**, never against `hash(<on-disk page body>)` — the latter diverges by design once backlinks are written, and `excerpt_position` offsets (anchored to the verbatim body that precedes any appended trailer) stay valid.

First write the composed page markdown to the per-dispatch scratch file `$WORK_DIR/page.md` (the Phase-0 scratch root — never a bare `mktemp` or a fixed name in the shared scratchpad; a sibling dispatch owns its own `$WORK_DIR`, so this file cannot collide). Then write atomically via `_knowledge_lib.atomic_write_text` against `<WIKI_ROOT>/wiki/<page-type-dir>/<slug>.md` — with the default `PAGE_TYPE=source` this is `<WIKI_ROOT>/wiki/sources/<slug>.md`; for `PAGE_TYPE=interview` it is `<WIKI_ROOT>/wiki/interviews/<slug>.md` (the `<page-type-dir>` resolved in Phase 0). Pass paths via env vars so apostrophes / spaces in WIKI_ROOT or tmp paths cannot break the Python literal.

**Pre-write integrity assertion (fail-fast).** Your dispatch parameters `SLUG` and `URL` are the authoritative identity of the page you are writing, and `entry.content_hash` (read from `fetch-cache.py fetch` in Phase 1) is the authoritative provenance hash of the body you fetched for that URL. Because many ingesters fan out in one wave, it is possible to compose a page from a sibling source's body/frontmatter by mistake; this guard refuses to let such a cross-written page reach disk. Add `SLUG`, `URL`, and `CONTENT_HASH` (the Phase-1 `entry.content_hash`) as env vars and, before calling `atomic_write_text`, parse the composed page's frontmatter and assert the page's `id:` equals `SLUG`, its first `sources:` URL normalizes to `URL`, the target path stem equals `SLUG`, and — when the page emitted a `content_hash:` line — that it equals `CONTENT_HASH`. The content_hash leg catches the narrower variant where you kept your own `id:`/`sources:` but the page's body (and its `content_hash:` line) bled from a sibling: the page frontmatter is freeform output that can diverge under cross-talk, while `CONTENT_HASH` is the deterministic Phase-1 cache value for the dispatched URL, so the comparison is not tautological. On any mismatch, write **nothing** and `sys.exit(3)`:

```bash
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PAGE_PATH="<WIKI_ROOT>/wiki/<page-type-dir>/<slug>.md" \
TMP_PAGE_PATH="$WORK_DIR/page.md" \
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
  "sub_question_refs": ["sq-01", "sq-03"],
  "summary": "<one crisp, self-contained sentence describing what the page is about>",
  "publisher": "europa.eu",
  "fetched_at": "<entry.fetched_at>",
  "notes": "<optional: per-claim warnings, e.g. 'dropped 1 claim: excerpt_quote not found in body'>",
  "duration_ms": 18430,
  "cost_estimate": {"input_words": 6900, "output_words": 2000, "estimated_usd": 0.045}
}
```

`duration_ms` is this agent's full wall-clock in milliseconds — `int(time.time() * 1000) - START_MS` using the Phase-0 `START_MS`. It spans the cache read, the `claim-extractor` sub-dispatch, and the page write, so it is the per-agent figure the orchestrator maxes into the phase's `max_agent_duration_ms`. Compute it once, just before writing this envelope, e.g. `python3 -c 'import os,time; print(int(time.time()*1000) - int(os.environ["START_MS"]))'`.

`cost_estimate` is the **sum of this ingester's own cost and the `claim-extractor` sub-call's cost** (the Phase-2 captured envelope) — `input_words`, `output_words`, and `estimated_usd` are each the union (your own + the extractor's), so the single biggest per-run spend is measured rather than estimated by the orchestrator. Estimate your own words using the per-word→USD formula and Sonnet pricing constants in `cogni-workspace/references/agent-model-cost.md` and add the extractor's `cost_estimate` field-by-field; the extractor's contribution is `{0, 0, 0.0}` on an `ok: false` / claim-less ingest.

`notes` is an **optional** free-text field carrying per-claim warnings raised during the write — most importantly a Phase-2 `find() == -1` claim drop (a quote genuinely absent from the body) and a claim-extractor failure (the failure-mode invariant below). Omit it on a clean ingest; when present it makes a real extraction error visible to the orchestrator's batch summary rather than silently lost. A position recompute (offset drift corrected via `body.find()`) is **not** a warning — the claim was kept and the offset fixed, so it never appears here.

`sub_question_refs` echoes the dispatched `SUB_QUESTION_REFS` input back as a list — split the comma-separated value on `,` and trim each `sq-NN` id (the same input already parsed for `sub_question_refs[0]`/`THEME_LABEL` resolution). The field is load-bearing downstream: the orchestrator merges it onto this source's `ingest-manifest.json::ingested[]` entry, which the compose-time coverage reader filters on per sub-question — an envelope without it would make this source invisible to every sub-question's coverage. No new input, no network.

For the skip cases (cache miss / unavailable / empty body / invalid slug / invalid page type / slug collision / integrity mismatch):

```json
{
  "ok": false,
  "url": "https://...",
  "reason": "cache_unavailable_pdf_extraction_failed",
  "duration_ms": 120,
  "cost_estimate": {"input_words": 0, "output_words": 0, "estimated_usd": 0.0}
}
```

A skip path still reports `duration_ms` (`int(time.time() * 1000) - START_MS`) so a wave where every dispatch skipped still records a meaningful `max_agent_duration_ms` for the phase.

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
- The whole per-dispatch scratch directory (holding the body file and the composed page) is removed at end of dispatch (`trap 'rm -rf "$WORK_DIR"' EXIT` or equivalent) — sweep the directory, not individual files, so no intermediate artifact leaks. A leftover `$WORK_DIR` is tolerable but unsightly.
