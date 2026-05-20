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
| 2 | `knowledge-curate` | `plan.json` | `<project>/.metadata/candidates.json` |
| 3 | `knowledge-fetch` | `candidates.json` | `.cogni-knowledge/fetch-cache/<sha256>.json`, `<project>/.metadata/fetch-manifest.json` |
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

Fans out one `source-curator` agent per batch of sub-questions. Each runs WebSearch, scores candidates on relevance/authority/recency/uniqueness, **does not fetch**. Output is the union, deduped by URL.

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
      "discovered_at": "2026-05-20T..."
    }
  ]
}
```

`tier ∈ {primary, secondary, supporting}`. `fetch_priority` is an integer; lower = fetch first. Writes through `candidate-store.py` with a file-lock so parallel curators can't race.

### Phase 3 — `knowledge-fetch`

For each candidate, attempt fetch via:

1. WebFetch (default)
2. claude-in-chrome cobrowse fallback (only if the user is present — same gate cogni-claims uses)
3. Mark `unavailable` if both fail

Successful fetches go to the global cache at `.cogni-knowledge/fetch-cache/<sha256(url)>.json`. The per-project `fetch-manifest.json` records what's in the cache for this project and what was marked unavailable.

Output: `<project>/.metadata/fetch-manifest.json`:

```json
{
  "schema_version": "0.1.0",
  "fetched": [
    {"url": "...", "cache_key": "<sha256>", "content_hash": "<sha256-of-body>", "fetch_method": "webfetch", "fetched_at": "..."}
  ],
  "unavailable": [
    {"url": "...", "reason": "webfetch_timeout", "attempted_at": "...", "fallback_attempted": false}
  ]
}
```

Cache hit semantics: if a cache file exists for the URL and `fetched_at` is within the freshness window (default 30 days, configurable in `binding.curator_defaults`), reuse without re-fetching. The fetch-cache is content-addressed by URL, not by content — so the same URL fetched twice produces one cache file with the latest body.

### Phase 4 — `knowledge-ingest`

For each fetched source, dispatch `source-ingester` to emit one wiki page at `<wiki>/sources/<slug>.md`. The page carries:

- frontmatter `type: source` (requires cogni-wiki v0.0.44 type:source allowlist)
- frontmatter `sources: [<original URL>]`
- frontmatter `pre_extracted_claims:` — list of `{id, text, excerpt_quote, sub_question_refs}` extracted from the source body by `claim-extractor` (forked from cogni-research)
- body: the fetched source content, with claim excerpts highlighted

After per-source emission, run `backlink_audit.py` + `wiki_index_update.py` once per dispatch (atomic) via reused cogni-wiki scripts. Append to `wiki/log.md`.

This is the F6 fix — by the end of phase 4 the wiki is populated, and the operator can browse it before the writer runs.

### Phase 5 — `knowledge-compose`

Single `wiki-composer` agent. Reads `wiki/index.md` + selected `wiki/sources/*.md` + relevant prior `wiki/syntheses/*.md`. Drafts the report with `[[wiki-slug]]` citations (not URLs — URLs are looked up via the page's frontmatter when rendering).

Emits two files:

- `<project>/output/draft-vN.md` — the draft
- `<project>/.metadata/citation-manifest.json` — `{draft_position, wiki_slug, claim_id}` per citation, so verifier can locate claims without parsing the draft

**F11 recovery contract is preserved.** Phase 1 of the composer (outline) persists to `.metadata/writer-outline-v1.json` before Phase 2 (draft) attempts a write. If Phase 2 crashes mid-write, re-dispatch reads the outline and re-runs Phase 2 only.

### Phase 6 — `knowledge-verify`

`wiki-verifier` agent. For each cited statement in the draft, locate via `citation-manifest.json` → wiki page → pre-extracted claims. Score alignment as `verbatim / paraphrase / unsupported`. **No re-fetching** — this is the cost win versus cogni-claims.

Loop with `cogni-research:revisor` (cross-plugin dispatch, not forked — revisor isn't on the bottleneck path) up to 2 iterations on `unsupported` findings.

Output: `<project>/.metadata/verify-vN.json`:

```json
{
  "schema_version": "0.1.0",
  "verified": [{"draft_position": "...", "verdict": "verbatim", "wiki_slug": "...", "claim_id": "..."}],
  "deviations": [{"draft_position": "...", "verdict": "unsupported", "...": "..."}],
  "revision_round": 1
}
```

### Phase 7 — `knowledge-finalize`

Deposit the verified draft as `wiki/syntheses/<slug>.md`. Run `cycle-guard.py` (reused as-is from v0.0.x) to refuse self-citing loops. Update `binding.json` `research_projects[]` with the new entry. Refresh dashboard.

## What is no longer in the runtime path

- **cogni-research.** v0.1.0 dispatches zero cogni-research skills. The forked agents (source-curator, claim-extractor, writer→wiki-composer) are point-in-time copies; drift from upstream is acceptable. cogni-research stays installed only for users who want one-shot reports via its own skills, and for cross-plugin callers (cogni-trends, cogni-narrative).
- **cogni-claims.** v0.1.0 dispatches zero cogni-claims skills for its own consumers. cogni-claims stays alive for cogni-trends and cogni-portfolio submitters. `wiki-verifier` replaces it for cogni-knowledge.
- **cogni-wiki:wiki-from-research.** Replaced by the inverted pipeline. `knowledge-ingest` calls `wiki-ingest`'s low-level scripts (backlink_audit, wiki_index_update) directly instead of dispatching the orchestrator.

## What is still delegated upstream

- `cogni-wiki:wiki-setup` for wiki bootstrap (called from `knowledge-setup`).
- `cogni-wiki:wiki-query`, `wiki-dashboard`, `wiki-health`, `wiki-resume`, `wiki-lint`, `wiki-refresh` — `knowledge-query`, `knowledge-dashboard`, `knowledge-resume`, `knowledge-refresh` remain thin wrappers around these.
- `cogni-wiki/skills/wiki-ingest/scripts/{backlink_audit,wiki_index_update}.py` — called from `source-ingester` directly (script-level, not skill-level).
- `cogni-wiki/scripts/{config_bump,rebuild_context_brief}.py` — called from `knowledge-finalize`.

## Cross-plugin coordination prerequisites

- **cogni-wiki v0.0.44** must release before milestone 6 (`knowledge-ingest`). It adds `type: source` to the recognized page-type allowlist in `wiki-lint` and `wiki-health`.

## See also

- `fetch-cache-design.md` — content-addressing, eviction policy, freshness window
- `claim-at-ingest.md` — why claims are pre-extracted from source bodies, not from drafts
- `absorption-roadmap.md` — how this fits the broader v0.1.0 / v1.0.0 sequence
