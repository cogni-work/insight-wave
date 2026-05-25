# Inverted pipeline — the v0.1.0 contract

> Status: contract written, implementation in progress. This document is the
> single source of truth for the v0.1.0 pipeline shape — every new skill and
> agent below must conform to the phase boundaries, manifest names, and data
> flow described here. When implementation diverges, update this doc first.

## Why we inverted

v0.0.15 chained `cogni-research → cogni-wiki:wiki-from-research → cogni-claims:verify`. Three structural problems surfaced in the Phase 4 alpha and the v0.0.16 re-run:

1. **The wiki is empty for ~80% of wall-clock** while research runs (alpha finding F6). The writer never sees source bodies as wiki pages — only research snippets.
2. **Sources are fetched twice.** `cogni-research`'s `section-researcher` fetches at research time; `cogni-claims` re-fetches every cited URL at verify time (`cogni-claims/skills/claims/SKILL.md:108`). The two pipelines do not share a cache.
3. **Unreachable sources reach the report.** A URL can be cited from a snippet bundle even if it's unreachable at verify time, leaving the user with a citation that fails the moment anyone clicks.

The inverted pipeline fixes all three by treating the wiki as the writer's substrate, fetching once before composition, and dropping unreachable sources before they can be cited.

## The seven phases

```
plan → curate → fetch → ingest → compose → verify → finalize
```

| Phase | Skill | Reads | Writes |
|-------|-------|-------|--------|
| 0 | `knowledge-setup` | — | `.cogni-knowledge/{binding.json, fetch-cache/}`, wiki dir |
| 1 | `knowledge-plan` | topic, optional sub-question hints | `<project>/.metadata/plan.json` |
| 2 | `knowledge-curate` | `plan.json` | `<project>/.metadata/candidates.json` (+ `fetch{}` per candidate), `.cogni-knowledge/fetch-cache/<sha256>.json` |
| 3 | `knowledge-fetch` | `candidates.json` | `<project>/.metadata/fetch-manifest.json` (+ opt-in cobrowse rescues to `fetch-cache/`) |
| 4 | `knowledge-ingest` | `fetch-manifest.json` + cache | `wiki/sources/<slug>.md` (with `pre_extracted_claims:`), updated `wiki/index.md`, `wiki/log.md` |
| 5 | `knowledge-compose` | `wiki/index.md` + selected `wiki/sources/*.md` + prior `wiki/syntheses/*.md` | `<project>/output/draft-vN.md`, `<project>/.metadata/citation-manifest.json` |
| 6 | `knowledge-verify` | draft + citation manifest + wiki page claims | `<project>/.metadata/verify-vN.json` (revisor loop, max 2 iterations) |
| 7 | `knowledge-finalize` | verified draft | `wiki/syntheses/<slug>.md` (cycle-guarded), updated binding |

Each phase is a separate skill so the operator can pause and inspect between phases — this is the F7 fix (mid-chain confirmation gate is per-phase, not per-run).

## Per-phase contracts

### Phase 1 — `knowledge-plan`

Reads the topic, decomposes into 3–7 sub-questions, identifies candidate authority domains per sub-question, computes a cost estimate. No web access.

Output: `<project>/.metadata/plan.json`:

```json
{
  "schema_version": "0.1.0",
  "topic": "EU AI Act Article 6 high-risk system classification",
  "sub_questions": [
    {"id": "sq-01", "query": "...", "search_guidance": "...", "candidate_domains": ["europa.eu", "..."]}
  ],
  "market": "dach",
  "output_language": "en",
  "cost_estimate_usd": 0.42,
  "created": "2026-05-20T..."
}
```

### Phase 2 — `knowledge-curate`

Fans out one `source-curator` agent per sub-question (≤ 3 concurrent). Each runs WebSearch, scores candidates on relevance/authority/recency/uniqueness, **then fetches each surviving candidate's body via WebFetch** through the shared fetch-cache (Option B, #292 — the body-pull moved here from the old Phase-3 `source-fetcher` so the fetch rides the existing per-sub-question parallelism). Cobrowse is **not** done here — it stays Phase 3, opt-in. Output is the union, deduped by URL.

The orchestrator resolves the market config **once** (cogni-workspace `get-market-config.py --plugin research --market <market>`), aborts loudly if the market resolves to the `_default` fallback (no `data.code`), writes the envelope to `<project>/.metadata/market-config.json`, and threads `MARKET_CONFIG_PATH` to every curator — so all curators in a run score against the same authority list instead of each re-resolving it from a flaky `WORKSPACE_PLUGIN_ROOT` glob (#304).

Output: `<project>/.metadata/candidates.json`:

```json
{
  "schema_version": "0.1.0",
  "candidates": [
    {
      "url": "https://europa.eu/...",
      "title": "Article 6 — High-risk AI systems",
      "score": 0.91,
      "tier": "primary",
      "fetch_priority": 1,
      "sub_question_refs": ["sq-01", "sq-03"],
      "publisher": "europa.eu",
      "discovered_at": "2026-05-20T...",
      "fetch": {
        "status": "ok",
        "cache_key": "<sha256>", "content_hash": "sha256:...",
        "fetch_method": "webfetch", "fetched_at": "2026-05-20T...",
        "from_cache": false
      }
    }
  ]
}
```

`tier ∈ {primary, secondary, supporting}`. `fetch_priority` is an integer; lower = fetch first. The optional `fetch` sub-object records the Phase-2 body fetch: `status ∈ {ok, unavailable}`; on `ok` it carries `cache_key`/`content_hash`/`fetch_method`/`fetched_at` (+ `pdf_pages_read`/`pdf_truncated` for PDFs); on `unavailable` it carries `reason` (a `webfetch_*` or `pdf_extraction_failed` token), `fallback_attempted`, and `cobrowse_eligible` (true for the `webfetch_*` classes — Phase 3 can retry them; false for `pdf_extraction_failed`). Writes through `candidate-store.py` with a file-lock so parallel curators can't race; on a cross-SQ dedup the merge prefers the side with `fetch.status == "ok"` so a good body is never discarded.

**C1 under Option B.** Because the fetch now lives inside the per-SQ curators (which run before the merge), two curators in the same concurrency wave can both miss the cache on a shared cross-SQ URL and each WebFetch it. The cache is content-addressed by URL, so both writes collapse to **one** entry (last-write-wins) — C1 holds when measured as `fetch-cache.py stat` entries == distinct normalized URLs. The curator's Phase-4 Step-1 cache lookup short-circuits all the other repeat classes (re-runs, prior projects, cross-wave repeats). Same-wave double-fetch is an accepted, bounded cost.

### Phase 3 — `knowledge-fetch` (cobrowse reconcile, opt-in)

Under Option B the bodies are already fetched, so this phase no longer WebFetches. It:

1. Builds `fetch-manifest.json` directly from each candidate's Phase-2 `fetch` sub-object — `fetched[]` from `status: ok`, `unavailable[]` from the rest. No `source-fetcher` dispatch for the WebFetch results.
2. Offers **opt-in** cobrowse recovery of the WebFetch misses (`--cobrowse`, or an interactive prompt; default OFF so autonomous runs stay browser-free). When opted in, it walks the user through enabling the Claude-in-Chrome extension (mirroring cogni-claims — `claude-in-chrome` is the browser extension, not an `install-mcp` server), then dispatches `source-fetcher` (cobrowse-only, `fetch_method: cobrowse_interactive`) **sequentially** over the cobrowse-eligible misses. A rescue upgrades the manifest's `unavailable[]` entry to `fetched[]` and overwrites the cache's negative entry with a positive one.

Successful fetches live in the global cache at `.cogni-knowledge/fetch-cache/<sha256(url)>.json`. The per-project `fetch-manifest.json` records what's in the cache for this project and what stayed unavailable.

Output: `<project>/.metadata/fetch-manifest.json`:

```json
{
  "schema_version": "0.1.0",
  "fetched": [
    {"url": "...", "cache_key": "<sha256>", "content_hash": "<sha256-of-body>", "fetch_method": "webfetch", "fetched_at": "..."},
    {"url": "https://example.org/paper.pdf", "cache_key": "<sha256>", "content_hash": "<sha256-of-body>", "fetch_method": "webfetch", "fetched_at": "...", "pdf_pages_read": 13}
  ],
  "unavailable": [
    {"url": "...", "reason": "webfetch_timeout", "attempted_at": "...", "fallback_attempted": false}
  ]
}
```

`pdf_pages_read` (added v0.0.21, #278) is **PDF-only and optional**: it carries the cumulative page count successfully read by the curator's 20-page-window Read-loop. Non-PDF rows omit it. `pdf_truncated: true` (also optional, PDF-only) is set only when the 200-page hard cap fired before the PDF ended — for PDFs that fit under the cap, `pdf_pages_read` alone conveys completeness.

Cache hit semantics: if a cache file exists for the URL and `fetched_at` is within the freshness window (default 30 days, configurable in `binding.curator_defaults`), the curator's Phase-4 lookup reuses it without re-fetching. The fetch-cache is content-addressed by URL, not by content — so the same URL fetched twice produces one cache file with the latest body.

### Phase 4 — `knowledge-ingest`

For each fetched source, dispatch `source-ingester` to emit one wiki page at `<wiki>/sources/<slug>.md`. The page carries:

- frontmatter `type: source` (requires cogni-wiki v0.0.44 type:source allowlist)
- frontmatter `sources: [<original URL>]`
- frontmatter `pre_extracted_claims:` — list of `{id, text, excerpt_quote, excerpt_position, sub_question_refs, extracted_at}` extracted from the source body by `claim-extractor` (forked from cogni-research). Claim shape: `references/claim-at-ingest.md:37-49`.
- body: the fetched source content, verbatim. `excerpt_position` offsets inside `pre_extracted_claims:` are the indexing primitive — the future `wiki-verifier` renders context around each excerpt from the offset; there is no in-body highlighting markup. See `references/claim-at-ingest.md:57` for the Unicode-code-point offset contract.

After per-source emission, run `backlink_audit.py` + `wiki_index_update.py` per new slug via reused cogni-wiki scripts, then `config_bump.py --key entries_count --delta <n_new>` once — where `n_new` is the count of source pages whose `wiki_index_update.py` returned `action: "inserted"` (the same Step 7→8 lockstep `knowledge-finalize` uses), so `.cogni-wiki/config.json::entries_count` tracks the on-disk page count and `wiki-health` stops reporting an N-page drift (#302). Append to `wiki/log.md`.

This is the F6 fix — by the end of phase 4 the wiki is populated, and the operator can browse it before the writer runs.

### Phase 5 — `knowledge-compose`

Single `wiki-composer` agent. Reads `wiki/index.md` + selected `wiki/sources/*.md` + relevant prior `wiki/syntheses/*.md`. Drafts the report with `[[wiki-slug]]` citations (not URLs — URLs are looked up via the page's frontmatter when rendering).

Emits two files:

- `<project>/output/draft-vN.md` — the draft
- `<project>/.metadata/citation-manifest.json` — `{id, draft_position, draft_sentence, wiki_slug, claim_id}` per citation. `id` is a stable per-citation join key (`cit-001`, …); `draft_sentence` is the cited sentence copied verbatim — the verifier scores it directly against the claim and never re-tokenizes the draft (this dissolves the F20/F22 off-by-one). `draft_position` is a best-effort human locator only, no longer load-bearing for any verdict.

**F11 recovery contract is preserved.** Phase 1 of the composer (outline) persists to `.metadata/writer-outline-v1.json` before Phase 2 (draft) attempts a write. If Phase 2 crashes mid-write, re-dispatch reads the outline and re-runs Phase 2 only.

### Phase 6 — `knowledge-verify`

`wiki-verifier` agent. For each citation, score the manifest's `draft_sentence` against the cited page's pre-extracted claim as `verbatim / paraphrase / unsupported` (plus the informational `synthesis` verdict). **No re-fetching** and **no draft re-tokenization** — the cost win versus cogni-claims, and the fix for the F22 off-by-one.

**Fan-out (F21, v0.0.28):** verification is embarrassingly parallel (each verdict is independent), so `knowledge-verify` shards `citations[]` via `verify-store.py shard`, dispatches N `wiki-verifier` instances in parallel (each scoped to a subset via `CITATIONS_PATH` / `VERIFY_OUT_PATH`), and reassembles the fragments via `verify-store.py merge`. Wall-clock drops ~linearly with shard count while the LLM judgment is preserved; the < 5 min C3 target is now per-shard. A deterministic substring pre-filter is a documented complementary option, not yet implemented.

Loop with `revisor` (forked from cogni-research at M8, kept in `cogni-knowledge/agents/` to preserve the clean-break commitment) up to 2 iterations on `unsupported` findings. The revisor **repoints to a covering on-page claim before dropping** (F23) — drop erodes the evidence base and is the last resort.

Output: `<project>/.metadata/verify-vN.json` (merged from the shard fragments):

```json
{
  "schema_version": "0.1.0",
  "verified": [{"id": "cit-001", "draft_position": "...", "verdict": "verbatim", "wiki_slug": "...", "claim_id": "..."}],
  "deviations": [{"id": "cit-023", "draft_position": "...", "verdict": "unsupported", "reason": "...", "note": "..."}],
  "revision_round": 1
}
```

The `id` echoed into each entry is the join key the orchestrator's inline prune (on `reason: "sentence_not_in_draft"`) and the revisor both key on — `draft_position` is best-effort and never matched against.

### Phase 7 — `knowledge-finalize`

Deposit the verified draft as `wiki/syntheses/<slug>.md` (frontmatter `type: synthesis`, `derived_from_research: <project-slug>`, `sources:` reconstructed from `citation-manifest.json::citations[].wiki_slug`; body is the verified draft verbatim plus an auto-generated `## References` list). Run `cycle-guard.py` to refuse self-citing loops — at v0.0.24 the guard gained an additive fallback that reads `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty, so direct-cycle detection works on v0.1.0 projects without further adapter code. Call three cogni-wiki helpers directly at script level (matches the M6 pattern of calling `backlink_audit.py` + `wiki_index_update.py` script-level): `wiki_index_update.py --category "Syntheses"` (so the page lands in `wiki/index.md`), `config_bump.py --key entries_count --delta 1` (so `.cogni-wiki/config.json` stays consistent), and `rebuild_context_brief.py` (so the next session's "first read" picks the synthesis up). Append the new entry to `binding.json::research_projects[]` via `knowledge-binding.py append-project --report-source wiki`. Write one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md` (additive log prefix — same posture as M7's `compose` and M8's `verify`).

## What is no longer in the runtime path

- **cogni-research.** v0.1.0 dispatches zero cogni-research skills and zero cogni-research agents. The forked agents (source-curator, claim-extractor, writer→wiki-composer, revisor) are point-in-time copies under `cogni-knowledge/agents/`; drift from upstream is acceptable. cogni-research stays installed only for users who want one-shot reports via its own skills, and for cross-plugin callers (cogni-trends, cogni-narrative).
- **cogni-claims.** v0.1.0 dispatches zero cogni-claims skills for its own consumers. cogni-claims stays alive for cogni-trends and cogni-portfolio submitters. `wiki-verifier` replaces it for cogni-knowledge.
- **cogni-wiki:wiki-from-research.** Replaced by the inverted pipeline. `knowledge-ingest` calls `wiki-ingest`'s low-level scripts (backlink_audit, wiki_index_update) directly instead of dispatching the orchestrator.

## What is still delegated upstream

- `cogni-wiki:wiki-setup` for wiki bootstrap (called from `knowledge-setup`).
- `cogni-wiki:wiki-query`, `wiki-dashboard`, `wiki-health`, `wiki-resume`, `wiki-lint`, `wiki-refresh` — `knowledge-query`, `knowledge-dashboard`, `knowledge-resume`, `knowledge-refresh` remain thin wrappers around these.
- `cogni-wiki/skills/wiki-ingest/scripts/{backlink_audit,wiki_index_update}.py` — called from `source-ingester` directly (script-level, not skill-level).
- `cogni-wiki/skills/wiki-ingest/scripts/{wiki_index_update,config_bump,rebuild_context_brief}.py` — called from `knowledge-finalize` at script level. `wiki_index_update.py` was added to the helper trio at v0.0.24 — without it the new synthesis page would not appear in `wiki/index.md` (the catalog), matching the same posture `wiki-query --file-back` and `knowledge-ingest` already adopt for their new pages.

## Cross-plugin coordination prerequisites

- **cogni-wiki v0.0.44** must release before milestone 6 (`knowledge-ingest`). It adds `type: source` to the recognized page-type allowlist in `wiki-lint` and `wiki-health`.

## See also

- `fetch-cache-design.md` — content-addressing, eviction policy, freshness window
- `claim-at-ingest.md` — why claims are pre-extracted from source bodies, not from drafts
- `absorption-roadmap.md` — how this fits the broader v0.1.0 / v1.0.0 sequence
