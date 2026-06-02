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

## The phases

```
plan → curate → fetch → ingest → distill → compose → verify → finalize
```

Phase 4.5 (`knowledge-distill`) is an **optional, fail-soft interphase** added in v0.1.13 (#336): it
sits between ingest and compose, never blocks the pipeline, and is the only phase that may be skipped
without affecting downstream correctness. The other seven phases are the v0.1.0 core.

| Phase | Skill | Reads | Writes |
|-------|-------|-------|--------|
| 0 | `knowledge-setup` | — | `.cogni-knowledge/{binding.json, fetch-cache/}`, wiki dir |
| 1 | `knowledge-plan` | topic, optional sub-question hints | `<project>/.metadata/plan.json` |
| 2 | `knowledge-curate` | `plan.json` | `<project>/.metadata/candidates.json` (+ `fetch{}` per candidate), `.cogni-knowledge/fetch-cache/<sha256>.json` |
| 3 | `knowledge-fetch` | `candidates.json` | `<project>/.metadata/fetch-manifest.json` (+ opt-in cobrowse rescues to `fetch-cache/`) |
| 4 | `knowledge-ingest` | `fetch-manifest.json` + cache | `wiki/sources/<slug>.md` (with `pre_extracted_claims:`), `wiki/questions/<slug>.md` (per sub-question, Step 4.5/#407 — sq↔finding backlinks), updated `wiki/index.md`, `wiki/log.md` |
| 4.5 | `knowledge-distill` (optional, fail-soft) | `ingest-manifest.json` + `wiki/sources/*.md` claims + existing distilled pages + `wiki/questions/*.md` | `wiki/{concepts,entities,summaries,learnings}/<slug>.md` (with `distilled_claims:`; summary/learning added at #342), `wiki/questions/<slug>.md` enriched with an `answer_claims:` surface (Step 6.9, #432), updated `wiki/index.md`, `wiki/log.md`, `<project>/.metadata/distill-manifest.json` |
| 5 | `knowledge-compose` | `wiki/index.md` + selected `wiki/sources/*.md` + prior `wiki/syntheses/*.md` + distilled `wiki/{concepts,entities,summaries,learnings}/*.md` (framing AND citable cross-source evidence — #344) | `<project>/output/draft-vN.md`, `<project>/.metadata/citation-manifest.json` |
| 6 | `knowledge-verify` | draft + citation manifest + wiki page claims | `<project>/.metadata/verify-vN.json` (revisor loop, max 2 iterations) |
| 7 | `knowledge-finalize` | verified draft | `wiki/syntheses/<slug>.md` (cycle-guarded), updated binding, `<project>/.metadata/contradictor-vN.json` (when `high > 0` or `unknown > 0`, #335), `<project>/.metadata/structural-review-vN.json` (advisory structural score, #309 P1.1) |

Each phase is a separate skill so the operator can pause and inspect between phases — this is the F7 fix (mid-chain confirmation gate is per-phase, not per-run).

## Per-phase contracts

### Phase 1 — `knowledge-plan`

Reads the topic, decomposes into 3–7 sub-questions, identifies candidate authority domains per sub-question, computes a cost estimate. No web access by default. Each sub-question also carries a `theme_label` — a short thematic label (in `output_language`) that Phase 4 uses as the source page's `wiki/index.md` category so the index reads thematically rather than by page type (#307).

**Preliminary scoping scan (optional, fail-soft).** The one web call this phase can make is an opt-in 2–3-query `WebSearch` scan folded into the optional Step 0.4 topic-framing pass (`references/topic-framing.md`, the *scan* move): it grounds decomposition in what's actually searchable (dominant angles, key organizations, recent developments, terminology) so sub-questions don't target dead-end angles. It **engages only when framing does** — a vague topic or `--frame`, never on a sharp topic, `--no-framing`, `--dry-run`, or `--no-prelim-search` — and is **fail-soft** (any error degrades to the pure-reasoning path). This mirrors the read-before-web pre-step's posture (Phase 2 below): the enrichment is opt-in and never blocks, so a run that skips it is byte-identical to pre-scan behaviour. The scan output is ephemeral working context (an optional `## Preliminary scan` note in `framing.md`); `plan.json` is unchanged.

Output: `<project>/.metadata/plan.json`:

```json
{
  "schema_version": "0.1.0",
  "topic": "EU AI Act Article 6 high-risk system classification",
  "sub_questions": [
    {"id": "sq-01", "query": "...", "search_guidance": "...", "theme_label": "High-risk Classification Scope", "candidate_domains": ["europa.eu", "..."]}
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

**Read-before-web coverage pre-step (P1.3, #309, v0.1.8).** Before any curator runs, the orchestrator resolves wiki coverage **once** (`wiki-coverage.py score --wiki-root <binding.wiki_path> --plan plan.json`, the same resolve-once posture as the market config), writes the manifest to `<project>/.metadata/wiki-coverage.json`, and threads `WIKI_ROOT` + `WIKI_COVERAGE_PATH` to every curator. Each curator reads its sub-question's verdict (`covered`/`partial`/`uncovered`) and, on a `covered`/`partial` verdict, reads the named `covered_pages[].page_path` under `WIKI_ROOT` and issues fewer new WebSearch queries — narrowing to genuine gaps so the next run on the same base does less web work (the differentiation thesis at research time). Unlike the market-config gate, this pre-step is **fail-soft**: a scorer error or unreadable wiki degrades to an all-`uncovered` manifest (every curator does a full search), and a fresh base is all-`uncovered` by construction, so run 1 is byte-identical to pre-#309 behaviour. The narrowing reduces *new web queries/fetches*, not citable coverage — the already-filed wiki pages are read directly by the Phase-5 composer.

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

**Step 4.5 — per-sub-question `type: question` nodes (#407).** After all source batches land, `knowledge-ingest` promotes each `plan.sub_questions[]` entry into a first-class research-question node at `<wiki>/questions/<slug>.md` (requires cogni-wiki **v0.0.50** `type: question` allowlist, schema_version `0.0.7`). The deterministic `scripts/question-store.py emit` joins `plan.json` + `candidates.json` (the URL→`sub_question_refs[]` map) + `ingest-manifest.json` (the URL→slug map) to build each sub-question's finding set, then writes one page per sub-question with ≥1 finding:

- frontmatter `type: question`, `theme_label:`, `sub_question_id: sq-NN`, `search_guidance:`, `candidate_domains: [...]`, `sources_answering: [<source-slug>, ...]`. `title:` is the sub-question `query`, JSON-quoted (#389) so a colon-bearing query is valid YAML.
- body: a machine-owned `## Findings` section listing `- [[<source-slug>]]` per answering source (regenerated each run), plus a human-owned `## Notes` tail preserved verbatim.
- slug = `slugify(theme_label)` (transliterated, `für`→`fuer`), fallback `sq-NN` for legacy plans. A collision with an existing **question** page merges (enrich-on-collision: union findings, preserve `created:` + `## Notes`, bump `updated:`); a collision with a different page type appends a `-q` disambiguator so a question node never shadows a non-question page.

**The sq↔finding `R1` contract:** the question page's `## Findings` `[[links]]` are the forward direction (question→source); the reverse (`source→question`) is backfilled by re-using `backlink_audit.py --apply-plan` with `--new-page <question-slug>`, inserting `[[<question-slug>]]` under a `## Research questions` heading in each answering source page. Both legs present ⇒ `wiki-lint` reports no `reverse_link_missing`. The question node is then indexed under a single additive `## Research questions` category and `entries_count` is bumped by the count of newly-inserted question rows. This is what makes the research-question structure survive long-term — it lives in the wiki backlink graph, not just in the archived `.metadata/`. Cross-run accumulation (one persistent node per recurring theme, coupled to `binding.json topic_lineage.covered_themes`) **shipped at v0.1.52 (#409)** — `question-store.py emit --binding` routes a recurring theme (a variant `theme_label`) to its prior-run node via a `_knowledge_lib.theme_norm_key → question_slug` map, and Step 4.5 persists the run's themes back via `knowledge-binding.py upsert-themes` (the single writer of `covered_themes[]`). The `synthesis→question` link (in `knowledge-finalize`) remains a deferred follow-up.

### Phase 4.5 — `knowledge-distill` (optional, fail-soft) — v0.1.13, #336

Phase 4 makes the wiki a **citation store** (verbatim source bodies + `pre_extracted_claims:`). Phase 4.5 turns those source claims into the distilled **concept/entity web** that makes a Karpathy wiki *compound* across runs instead of merely accumulate — the mechanism `references/differentiation-thesis.md` advertises. It also implements the **claim-level dedup** (Finding H) the thesis's success metric requires; URL-level dedup (`candidate-store.py`) was the only dedup before this.

**Optional + fail-soft.** A distill failure must never block `knowledge-compose`. Same posture as the `knowledge-curate` Step 0.5 coverage pre-step: the concept/entity layer is enrichment, not a correctness gate. A pipeline run that skips distill is byte-identical downstream to pre-v0.1.13 behaviour.

**Division of labor** (mirrors `claim-extractor`/`source-ingester`/`candidate-store.py`, and the #325 "script owns serialization" lesson):

- `agents/concept-distiller.md` — **pure proposal.** Reads the run's source-claim bundle + an index of existing concept/entity slugs; clusters recurring facts into `concept`/`entity` proposals; writes a **raw-text** concept-records file (one `- title:` block per concept, repeatable `claim:` lines as `<source_slug> | <claim_id> | <text>`). Writes no wiki pages, never builds JSON/YAML, never computes slugs, never decides dedup. `model: sonnet`, tools `Read`/`Write`.
- `skills/knowledge-distill/SKILL.md` — Phase-4.5 orchestrator. Builds the claim bundle (from `ingest-manifest.json` + each `wiki/sources/<slug>.md`'s `pre_extracted_claims:`) and the existing-slug index, dispatches the distiller, runs `concept-store.py merge`, then the script-level cogni-wiki helpers, writes `distill-manifest.json` + a `wiki/log.md` `distill` line. Fail-soft throughout.
- `scripts/concept-store.py` — the locked create-or-merge engine. Subcommands `init` / `merge` / `read`. Derives each slug via `_knowledge_lib.slugify(title)` (orchestrator-owns-slug), and under cogni-wiki's `_wiki_lock` (`<wiki-root>/.cogni-wiki/.lock`, imported via `--wiki-scripts-dir`) creates-or-merges each page. Owns all YAML serialization + the created-vs-updated decision (on-disk slug existence, under the lock) + a pre-write round-trip self-check.

**Claim-level dedup — deterministic, fail-safe, never the LLM.** The distiller proposes *which* claims attach to a concept; `concept-store.py` decides "same fact?" via `_knowledge_lib.norm_key` (exact) then `claim_similarity` (symmetric weighted-Jaccard ≥ 0.85). The dedup key is **`<source_slug>#<claim_id>`** (claim ids are per-page-unique — `clm-001` recurs on every source page). On a match: union the source backlinks onto the existing claim (one fact, multiple `[[backlinks]]`, one line), never a duplicate. **Fail-safe = keep both when uncertain** — a wrong merge silently destroys a distinct fact and is unrecoverable; a missed merge is a visible, measurable duplicate.

**Concept/entity page layout.** Frontmatter: `id`/`title`/`type`/`tags`/`created`/`updated`, `sources:` as `wiki://<source-slug>` (health validates targets), `related:`, `status: distilled`, `distilled_from_research: [<project-slug>]`, and a cogni-knowledge-owned `distilled_claims:` block (each: `claim_id` `dcl-NNN`, `text`, `norm_key`, `backlinks[]`, `source_claim_refs[]`, timestamps). Body: `## Summary` / `## Claims` / `## Related` / `## Sources` (bare `[[<source-slug>]]` wikilinks so the link graph forms real edges) wrapped in `<!-- MACHINE-OWNED:X:START/END -->` sentinels; a `## Notes` **human-owned** region below the last sentinel is preserved byte-for-byte across runs.

**Cross-run compounding.** Run N creates the page; run N+1 reads it, dedups incoming claims against `distilled_claims:`, appends genuinely-new claims, unions backlinks/`sources:`/`related:`/`distilled_from_research:`, bumps `updated:` (never `created:`), regenerates only the machine-owned blocks, splices the human region back unchanged. **The `## Summary` body is re-narrated too (Step 6.7, #341, v0.1.22):** for each `updated` page, the `concept-summary-narrator` agent rewrites the summary prose from the *merged* `distilled_claims[]` (in `OUTPUT_LANGUAGE`), and `concept-store.py renarrate` swaps **only** the SUMMARY machine block under the same `_wiki_lock` — every other block + the human `## Notes` tail stay byte-identical, `updated:` bumps only when the prose changed. This makes the wiki compound **narratively** (the reader's entry-point prose integrates new evidence), not just structurally (the claim/source/related lists accrete). It is **default-on, fail-soft** (a narrator failure leaves the existing summary in place and never blocks compose; `--no-renarrate` opts out) and **only fires on `updated` pages** — `created` pages keep the distiller's fresh summary. A pure re-run is byte-stable (action `unchanged`, no re-narration, no `entries_count` bump).

**Cross-lingual (DE↔EN) claim merge (Step 6.6, #345, v0.1.27).** Phase-1 dedup deliberately under-merges across languages — the only deterministic DE↔EN bridge is the article-number digit anchor (`token_weight` ×3.0), so a German claim and its English twin survive as two `distilled_claims[]` entries (the **safe** direction: a wrong cross-language merge silently destroys a distinct fact). On a **mixed-language base** that is lossy. Step 6.6 (between merge and the Step 6.7 renarrate) closes the gap with an LLM-judgment pass — **not** embedding similarity, which the differentiation thesis rejects (approach (c)). `concept-store.py xlingual-candidates` scans the run's touched pages and flags **candidate pairs** (two claims sharing an article-number anchor via `_knowledge_lib.digit_anchor_tokens` but below the auto-merge similarity and with near-disjoint non-digit tokens); the `cross-lingual-claim-merger` agent confirms which pairs are the *same fact in two languages* (raw-text `merge: <slug> | <survivor> | <absorbed>` records); `concept-store.py crossmerge` **re-validates the candidate gate server-side** (so the LLM can never widen scope) and **UNIONs** the absorbed claim's `backlinks` + `source_claim_refs` onto its survivor under the same `_wiki_lock` — **never dropping a provenance ref**, only the duplicate dcl-id. The merged slugs fold into `updated_slugs[]` so Step 6.7 re-narrates them. **Default-on, fail-soft, auto-skipping** — it emits nothing on a single-language base (zero LLM cost; `norm_key` already collapsed same-language twins) and `--no-crosslingual` forces it off. Re-runs are byte-stable (an already-absorbed dcl id re-validates to `claim_not_found`).

**Script-level cogni-wiki helpers** (no `wiki-ingest` dispatch), per new/updated slug: `concept-store.py merge` (locked page write) → `backlink_audit.py --apply-plan` (concept↔source / concept↔concept inbound edges, LLM-curated targets) → `wiki_index_update.py --category "Concepts"|"Entities" --max-summary 240` → `config_bump.py --key entries_count --delta <n_created>` (counts only `action: "inserted"`, the same #302 lockstep ingest/finalize use). The `lint_wiki.py --fix=all`/`health.py` conformance gate is **not** run here — `knowledge-finalize` Step 10.5 covers the whole run's writes (including the distilled pages) once, at the end.

**Safety branches.** A target slug that resolves to a `foundation: true` page → skipped (`foundation_collision`). A target that exists but has no MACHINE-OWNED sentinels (hand-authored / cogni-wiki page) → skipped (`no_sentinels_human_page`), left untouched (never clobber a page we did not author).

Output: `<project>/.metadata/distill-manifest.json` (schema `0.1.1` from v0.1.14, #340 tripwire bump):

```json
{
  "schema_version": "0.1.1",
  "project_slug": "eu-ai-act-de",
  "concepts": [
    {"slug": "high-risk-classification", "type": "concept", "action": "created", "summary": "...", "claims_total": 6, "claims_new": 6, "claims_deduped": 0, "claims_noop": 0, "near_existing_slug": {}}
  ],
  "claims_attached_total": 41,
  "claims_deduped_total": 7,
  "near_existing_total": 0,
  "near_existing_slugs": [],
  "bundle_hash": "<sha256 of the claim bundle — drives the resume no-op>"
}
```

`claims_deduped_total / claims_attached_total` is the Finding-H success metric (`differentiation-thesis.md` §"What success looks like"). `pipeline-summary.py project` surfaces the concept counts + this ratio for the read-side skills.

**#340 observable title→slug tripwire (v0.1.14).** Under the wiki lock, `concept-store.py merge` snapshots every existing concept/entity page's `(slug, title, type)` and, for each `created` action, scores `claim_similarity(new_title, each_existing_title)` (the same symmetric weighted-Jaccard primitive used for claim dedup). The highest-scoring entry above `NEAR_TITLE_SIMILARITY_THRESHOLD = 0.65` lands in the per-concept envelope's `near_existing_slug: {slug, title, type, score}` and is aggregated into manifest-level `near_existing_total` + `near_existing_slugs[]`. The orchestrator's Step-9 summary surfaces a `⚠ N concepts created near an existing slug — check title stability (#340)` warning when `near_existing_total > 0`. **Pure observability — no auto-merge, no skip, no behaviour change.** The tripwire is a human-visible signal that the LLM-driven distiller may have proposed a title whose `slugify()` silently forked a near-duplicate concept page, breaking compounding for that concept. The `updated` action never fires the tripwire (an existing slug warning against itself would be circular noise). Pure monolingual or near-monolingual signal — a cross-lingual title rename (`"Hochrisiko-Klassifizierung"` vs `"Einstufung als hochriskant"`) scores `≈ 0.0` and will not trip; the canonical-title map planned in #340 approach (c) covers that case.

**#342 — `summary` + `learning` page types (v0.1.24).** The distiller emits two more of cogni-wiki's ten page types beyond `concept`/`entity`: a cross-source **`summary`** (a topical overview — a region/market sketch, distinct from the per-run `synthesis`) and a run-level **`learning`** (a methodological lesson the evidence surfaced). Routing is purely additive — `concept-store.py::_TYPE_DIRS` gained `summary → summaries` / `learning → learnings`, and the two engine spots that hard-coded the binary world (`_build_title_index` snapshot + the slug-type-collision check) now iterate all four types, so the #340 tripwire and global slug-uniqueness span every distilled type. The frontmatter/body layout, claim-dedup, re-narration (#341), and index-category filing all work unchanged — only the type label and target dir differ. **Type selection is conservative** (`agents/concept-distiller.md`): most clusters remain `concept`/`entity`; the distiller reaches for `summary`/`learning` only when a cluster genuinely fits neither, honouring #342's "premature if shipped on speculation" caution — the route exists, the agent uses it sparingly. Deferred (still #264 follow-ups): feeding distilled pages into `wiki-coverage.py`, entity disambiguation, cross-lingual claim merge.

**Answer-claim synthesis for question nodes (Step 6.9, #432, v0.1.56).** The `type: question` nodes that Phase-4 Step 4.5 (#407) deposits carry only a `## Findings` list + a human `## Notes` tail — **no claim block**, so `wiki-composer` reads them framing-only and is hard-blocked from citing them (an inline citation to a claimless page scores `unsupported`). Step 6.9 gives each node a **citable answer surface** — exactly mirroring how distilled concept/entity pages got `distilled_claims:`. For each node, the orchestrator builds a per-question claim bundle (its `sources_answering:` sources' `pre_extracted_claims:`, the same 3-part `<slug> | <id> | <text>` lines the concept bundle uses), the new `answer-distiller` agent (`Read`/`Write`, sonnet — a constrained per-question clone of `concept-distiller`) selects the claims that *answer* the question and writes raw-text `- question: <slug>` records, and `question-store.py answer-merge` splices a deduped **`answer_claims:`** frontmatter block onto the node under the same `_wiki_lock`. The merge **reuses the distilled engine** field-for-field (claim-level dedup keyed on `<source_slug>#<claim_id>`, exact `norm_key` → `claim_similarity ≥ 0.85` fail-safe-keep-both, `backlinks[]`/`source_claim_refs[]` union never dropping a ref, pre-write round-trip self-check), minting `acl-NNN` ids (parity with source `clm-NNN` / distilled `dcl-NNN`). Unlike the concept page (a full re-render), the question node is **frontmatter surgery**: the block is spliced in place, preserving every other FM key, the `## Findings` block, and the `## Notes` tail **byte-for-byte**; the guard is `type == question` + not `foundation:` (question nodes have no MACHINE-OWNED sentinels by design). **Default-on, fail-soft, auto-skipping** — no question dir or no answerable node → clean skip; a failure leaves the node framing-only (today's behavior) and never blocks compose. Note: a later run's ingest `emit` re-renders the question frontmatter without `answer_claims:`, so the block is re-synthesized each distill run (transiently framing-only between ingest and distill, restored by distill).

**This Slice-1 surface lands INERT.** `wiki-composer` is **unchanged** — it still reads question nodes framing-only and cites none. The producer + the full verification chain (verify-store, wiki-verifier, wiki-contradictor, cycle-guard, finalize) recognize `answer_claims:` as the **4th evidence family**, ready for Slice 2 (the composer-activation follow-up, the #385 analog) — but with no composer citing a question node, zero draft behavior changes this slice.

### Phase 5 — `knowledge-compose`

Single `wiki-composer` agent. Reads `wiki/index.md` + selected `wiki/sources/*.md` + relevant prior `wiki/syntheses/*.md`, plus (since Phase 4.5) the distilled `wiki/{concepts,entities,summaries,learnings}/*.md` pages — topic-matched, lazily read — used **both for framing AND as citable cross-source evidence** (summary/learning added to the framing read at #342; citability added at #344). Distilled pages carry `distilled_claims:` (not `pre_extracted_claims:`); since #344 the composer may cite a distilled page directly (`wiki_slug: <distilled-slug>`, `claim_id: <dcl-NNN>`, wording drawn from `distilled_claims[].text`) when ≥2 sources converge on a fact and the cross-source "N sources agree" weight is wanted — the verifier scores that `draft_sentence` against the page's `distilled_claims[].text`. **Since #385 this is the *preferred* move, not an option:** each distilled claim carries `backlinks[]` / `source_claim_refs[]`, and the composer counts the distinct backing sources — a claim with **≥2 backlinks is a converged fact** whose preferred citation is the distilled page, and stacking the individual source markers is the anti-pattern (#385 fixed the prompt that had told the composer to *ignore* that convergence metadata, which is why a 60-source bake-in produced 0 `dcl-` citations). For a single-source fact the composer still cites the underlying **source** page (drawing wording from its `pre_extracted_claims:`). A run that cites no distilled page is byte-stable with pre-#344 behaviour. Drafts the report with `[[wiki-slug]]` citations (not URLs — URLs are looked up via the page's frontmatter when rendering; distilled pages have no external URL, so they cite like a synthesis page).

**Citable distilled pages (#344).** The cost the #336 framing-only posture imposed: when a fact is asserted by 5 sources and distilled onto one concept page, the composer had to either cite all 5 (verbose) or pick one (losing the cross-source signal). Citing the distilled page itself carries the right epistemic weight while staying verifiable. The contract extension is **additive** — the citation-manifest (`{wiki_slug, claim_id}`) and `verify-vN.json` schemas are unchanged (`wiki_slug` already carries any slug; the verifier resolves the four distilled dirs after `sources/`/`syntheses/` and scores against `distilled_claims[].text`, which has no `excerpt_quote`). `cycle-guard.py` "sees through" a cited distilled page to its backing sources (page-level `sources:`) and runs the lineage check on each; `knowledge-finalize` resolves distilled dirs in its cited-page lookup so a concept citation gets a title + bare `[[<slug>]]` backlink + `wiki://<slug>` synthesis source. `citation-store.py build` passes `wiki_slug` through and validates only the `draft_sentence`-in-draft substring; since #385 it additionally reports a per-kind `claim_kinds` breakdown (`{distilled, source, null, other}`, keyed on the `claim_id` prefix) on its **return envelope** — the per-run `dcl-` rate measurement `knowledge-compose` surfaces (`Distilled citations: X of Y` + a `dcl=<n>` `wiki/log.md` suffix). The manifest JSON + schema stay unchanged. **Deferred:** the `verify-store.py` prefilter still falls a distilled citation through to the LLM verifier (fail-safe), and `wiki-contradictor` still scores only against cited *source* pages (a concept-cited slug yields no findings — fail-soft, no regression).

Emits two files:

- `<project>/output/draft-vN.md` — the draft
- `<project>/.metadata/citation-manifest.json` — `{id, draft_position, draft_sentence, wiki_slug, claim_id, url}` per citation (schema `0.1.1` since #395; `url` is additive). `id` is a stable per-citation join key (`cit-001`, …); `draft_sentence` is the cited sentence copied verbatim — the verifier scores it directly against the claim and never re-tokenizes the draft (this dissolves the F20/F22 off-by-one). `draft_position` is a best-effort human locator only, no longer load-bearing for any verdict. `url` (#395) is the cited page's `sources:` URL copied byte-for-byte (empty for a synthesis/distilled citation) — the structured leg of the per-citation slug→URL binding gate, see Phase 5 below.

The composer has no `Bash`, so it does **not** author the manifest JSON itself (hand-typed JSON broke on an unescaped `"` — #325). Instead it writes a raw-text **citation-records** file (`<project>/.metadata/citation-records-vN.txt`, one labeled `- id:` block per citation, the sentence verbatim, plus a `url:` line copied byte-for-byte from the cited page's `sources:`), and `knowledge-compose` Step 4.5 runs `citation-store.py build --ingest-manifest` to `json.dumps` the manifest (`ensure_ascii=False` — escaping owned by the serializer) and self-check it (round-trip + verbatim-substring-in-draft). Step 5 re-asserts `draft_sentence`-in-draft as the authoritative gate.

**URL-integrity gates (`--ingest-manifest`).** Two complementary deterministic checks run at build time, both fail-soft when no ingest manifest is given:
- **Set-membership (#383, v0.1.40).** Every inline `<sup>[N](url)</sup>` URL must be a known ingested-source URL (`ingest-manifest.json::ingested[].url`, `normalize_url`-canonicalized) — else `failed_check: url_not_in_sources`. Kills a fabricated / slug-derived URL the composer reconstructed instead of copying `sources:`.
- **Per-citation slug→URL binding (#395, v0.1.41).** Set-membership can't catch a *real-but-mis-attributed* URL: source A's claim linking source B's genuinely-ingested URL passes (both are in the set). The structured per-record `url` field closes this by asserting `record.url == url_in(record.draft_sentence) == sources:(record.wiki_slug)` — the third leg resolved from the ingest manifest's per-slug `url` (each `ingested[]` entry carries both `slug` and `url`). A mismatch → `failed_check: url_slug_mismatch` (no manifest written). Additive + per-record fail-soft: it fires only when `record.url` is non-empty, and the slug leg is skipped when the cited slug is not in the ingest manifest (synthesis-page or prior-run citation).

Both gates are wired into **both** build call sites — `knowledge-compose` Step 4.5 and `knowledge-verify`'s revisor-round rebuild — so a revisor can't re-introduce a bad URL on a rephrase round.

**F11 recovery contract is preserved.** Phase 1 of the composer (outline) persists to `.metadata/writer-outline-v1.json` before Phase 2 (draft) attempts a write. If Phase 2 crashes mid-write, re-dispatch reads the outline and re-runs Phase 2 only.

### Phase 6 — `knowledge-verify`

`wiki-verifier` agent. For each citation, score the manifest's `draft_sentence` against the cited page's pre-extracted claim as `verbatim / paraphrase / unsupported` (plus the informational `synthesis` verdict). **No re-fetching** and **no draft re-tokenization** — the cost win versus cogni-claims, and the fix for the F22 off-by-one.

**Fan-out (F21, v0.0.28):** verification is embarrassingly parallel (each verdict is independent), so `knowledge-verify` shards `citations[]` via `verify-store.py shard`, dispatches N `wiki-verifier` instances in parallel (each scoped to a subset via `CITATIONS_PATH` / `VERIFY_OUT_PATH`), and reassembles the fragments via `verify-store.py merge`. Wall-clock drops ~linearly with shard count while the LLM judgment is preserved; the < 5 min C3 target is now per-shard. A deterministic substring pre-filter is a documented complementary option, not yet implemented.

Loop with `revisor` (forked from cogni-research at M8, kept in `cogni-knowledge/agents/` to preserve the clean-break commitment) up to 2 iterations on `unsupported` findings. The revisor **repoints to a covering on-page claim before dropping** (F23) — drop erodes the evidence base and is the last resort. **One exception inverts that order:** when an `unsupported` citation is a *redundant marker* on a sentence already covered by an **aligned sibling** (another same-sentence citation — keyed on an identical `draft_sentence` — already scored `verbatim`/`paraphrase` in `verified[]`), the revisor **drops** the surplus marker (keeping the sentence and the sibling's marker intact, and updating the surviving sibling's manifest `draft_sentence` to the marker-removed text) rather than hunting for a repoint target — dropping erodes no evidence there, so drop is correct, not last-resort. Like the composer, the revisor has no `Bash` and so **never hand-builds the manifest JSON** (#325): it `Edit`s the draft in place and writes a raw-text `citation-records-v{N+1}.txt`, which `knowledge-verify` serializes into `citation-manifest.json` via `citation-store.py build` after each revise round — so a rephrased German `„…"` sentence can't re-break `json.loads` and stall the loop.

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

**#337 verification semantics (v0.1.16).** Phase 6's verdicts are explicitly **citation-consistent**: the verifier scores each draft sentence against the cited page's `pre_extracted_claims:` extracted at *ingest time*, never against the live source URL. This is the structural cost win (< 5 min vs cogni-claims' 20–30 min) — and the explicit qualifier upstream (`knowledge-finalize` synthesis-page frontmatter `verification: citation_consistent_zero_network` + `verification_ratio:`; the dashboard's §"Claim verification scope" block; the finalize Step 11 / verify Step 6 summaries; the plugin description) makes the limitation explicit so a reader does not over-interpret a `verbatim` or `paraphrase` verdict as "the live source still says this." Two links stay structurally unchecked at verify time: extraction fidelity (the `source-ingester` `excerpt_position` sanity-check is positional, not semantic) and live ground-truth drift. For live-source re-verification on a cadence, `/cogni-knowledge:knowledge-refresh --resweep` (opt-in) dispatches `cogni-wiki:wiki-claims-resweep`, which WebFetches each cited URL once and LLM-compares the live source. **Two structurally separate surfaces — preserved by design; resweep is never auto-run from finalize.** The synthesis-page extractor adapter (so the resweep pulls cited URLs out of `[N]`/`[[slug]]`-style synthesis pages), the finalize-gate, and a cadence are deferred to v0.1.17+.

### Phase 7 — `knowledge-finalize`

Deposit the verified draft as `wiki/syntheses/<slug>.md` (frontmatter `type: synthesis`, `derived_from_research: <project-slug>`, `sources:` reconstructed from `citation-manifest.json::citations[].wiki_slug`; body is the verified draft verbatim plus an auto-generated `## References` list). Run `cycle-guard.py` to refuse self-citing loops — at v0.0.24 the guard gained an additive fallback that reads `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty, so direct-cycle detection works on v0.1.0 projects without further adapter code. Call three cogni-wiki helpers directly at script level (matches the M6 pattern of calling `backlink_audit.py` + `wiki_index_update.py` script-level): `wiki_index_update.py --category "Syntheses"` (so the page lands in `wiki/index.md`), `config_bump.py --key entries_count --delta 1` (so `.cogni-wiki/config.json` stays consistent), and `rebuild_context_brief.py` (so the next session's "first read" picks the synthesis up). Append the new entry to `binding.json::research_projects[]` via `knowledge-binding.py append-project --report-source wiki`. Write one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md` (additive log prefix — same posture as M7's `compose` and M8's `verify`).

**#338 (v0.1.19) — open-questions backlog refresh.** Step 10.5 sub-step 5 calls `rebuild_open_questions.py` (via the already-resolved `$WIKI_LINT_SCRIPTS`) so `wiki/open_questions.md` tracks finalize-time state instead of going stale until the next interactive `cogni-wiki:wiki-lint`. Fail-soft (the synthesis is already on disk — a rebuild failure surfaces loudly in Step 11 but never rolls back).

**#354 (v0.1.21) — research-time gap streaming (Option (b) of #338).** Sub-step 5 now pipes a **merged** payload — cogni-wiki's `lint_wiki.py` output **plus** this project's research-time gaps read from `<project>/.metadata/wiki-coverage.json::sub_questions[].coverage_verdict ∈ {uncovered, partial}` — through `build_open_questions_payload.py | rebuild_open_questions.py --findings -`. The gaps render as two new tail sections of `open_questions.md` (`research_uncovered` / `research_partial`, cogni-wiki v0.0.49) keyed by a synthetic `sq:<sq_id>` id. Step 10's `wiki/log.md` finalize line carries a `sqs=sq-01,sq-04` suffix (the gap sub-questions, from `gap_sq_ids_from_coverage`); because `finalize` is now in cogni-wiki's `CLOSING_OPS`, a *later* finalize credit-closes those items (`closed … by finalize`) once a fresh `knowledge-curate` re-scores them `covered`. `--no-research-gaps` narrows the rebuild to lint findings only; both helpers + the merge script are stdlib-only and fail-soft on a missing coverage manifest.

**#335 contradiction tripwire (v0.1.15, Phase 1 of approach (a)).** After the Step 10.5 conformance gate (and its four sub-steps — `lint_wiki.py --fix=all`, `health.py`+orphan re-lint, `overview.md` refresh, `rebuild_context_brief.py`), `knowledge-finalize` dispatches a new `wiki-contradictor` agent at Step 10.6 — a single-pass, zero-network LLM scorer that walks the just-deposited synthesis sentence-by-sentence against each cited *source* page's `pre_extracted_claims:`. The agent emits `<project>/.metadata/contradictor-v<N>.json` (schema `0.1.0`) with `findings[]` carrying `kind ∈ {contradiction, unknown}` and `severity ∈ {high, medium, low}`. **Pure observability — no auto-resolution, no rollback, no behaviour change downstream.** Step 11 surfaces `⚠ Contradiction tripwire: <H> high, <M> medium, <L> low, <U> unknown (#335)` plus the top-3 `high` findings only when `high > 0 OR unknown > 0`; clean runs are silent. The `--no-contradictor` CLI flag opts out. Partially defends `references/differentiation-thesis.md` Pillar 2 at *synthesis-write time*; the thesis's literal "wiki-ingest writes page B" framing — per-source ingest-time check — is approach **(b)**, which #431 decomposed out of #335 and shipped as the `source-contradictor` agent at `knowledge-ingest` Step 4.6 (v0.1.61). The third decomposed half — **synthesis-vs-prior-syntheses (approach (c))** — ships at v0.1.62 (see the #444 paragraph below). `type_drift` and `undercited_synthesis` checks remain deferred until this layer produces real-run noise data. (Note: an unrelated "thesis downgrade" fallback was once also informally lettered "(c)" in the #335 discussion — that is a distinct concept, the option of admitting Pillar 2 overclaims, not #431's approach (c); it stays off the table now that all three contradiction surfaces ship.)

**#444 synthesis-vs-prior-syntheses (v0.1.62, approach (c) of #431).** The `wiki-contradictor` agent at Step 10.6 now runs a SECOND comparison pass off the *same* sentence-split of the just-deposited synthesis body (no new agent, no new dispatch): **Pass B** scores the new synthesis's assertive sentences against the assertive sentences of each prior `wiki/syntheses/<slug>.md` page (its own page excluded; the orchestrator enumerates them most-recent-first, capped at `PRIOR_SYNTHESIS_MAX=20`, and threads `PRIOR_SYNTHESIS_SLUGS`). Synthesis pages carry no claim block, so the opposing corpus is the prior body's assertive sentences (not claim text) and a Pass B finding carries `conflicting_claim_id: null` with a synthesis-slug `conflicting_page` — no schema change (the finding shape already allowed a null claim id; `compared_against` gains additive `prior_syntheses[]` + `prior_synthesis_count`). The conservative assertive-sentence discipline is the relevance filter — unrelated prior syntheses produce no findings, so the agent scores ALL the (capped) prior slugs rather than similarity-ranking them. Step 11 splits the contradiction line into `<n_cited> vs cited evidence` + `<n_prior> vs prior syntheses` (partitioned by `conflicting_page` membership in `compared_against.prior_syntheses[]`). The new `--no-prior-syntheses` flag suppresses Pass B only (Pass A still runs); `--no-contradictor` still kills both. The skip-condition widens: the agent is dispatched whenever EITHER the cited-peer list OR the prior-synthesis list is non-empty, so a 2nd+ synthesis with no claim-bearing cited peers now runs Pass B alone. **Pure observability — no auto-resolution, no rollback, no behaviour change downstream**, exactly like Pass A. Closes #444 and, with approach (b) already shipped, lets #431 close.

**#309 P1.1 structural-review tripwire (v0.1.29).** Immediately after Step 10.6, `knowledge-finalize` dispatches a new `wiki-reviewer` agent at **Step 10.7** — a single-pass, zero-network LLM scorer ported from `cogni-research/agents/reviewer.md`. It is the **structural-quality** half of the cogni-research feature-parity gate (#309): Phase 6 (`knowledge-verify`) checks only citation-claim *alignment*, so a synthesis can cite every source cleanly and still treat a sub-question superficially, be incoherent, or be single-sourced. The reviewer reads `output/draft-v<N>.md` + `plan.json` (sub-questions, `output_language`) + `ingest-manifest.json` (source diversity) and scores the draft on the upstream reviewer's **5 weighted dimensions** (Completeness 0.25, Coherence 0.20, Source-Diversity 0.20, Depth 0.20, Clarity 0.15) with an inline citation-density gate (keyed on the composer's `<sup>[N](url)</sup>` shape) that caps Depth. It emits `<project>/.metadata/structural-review-v<N>.json` (schema `0.1.0`) with `structural_scores`, `citation_density`, `source_diversity`, `issues[]`, `strengths[]`, `verdict`, `score`. **Pure observability — advisory, non-blocking, fail-soft.** A `revise` verdict drives **no** fix loop: the composer is single-pass and the revisor is zero-network/citation-only, so there is no automated content-expansion path a structural verdict could trigger; the verdict is surfaced for the operator (re-run `knowledge-compose` or accept). Step 11 surfaces `⚠ Structural review: score=<S> (verdict=<V>) — <H> high-severity issue(s)` only when `verdict == revise OR high_severity_count > 0`; clean `accept` runs are silent. The `--no-reviewer` CLI flag opts out. The fork **drops** the upstream claims-verification multiplier (Phase 6 owns alignment), the Arc-Structural Gate (cogni-knowledge is arc-agnostic), the Word-Count/prose-density gate (no `target_words` floor plumbing), and the Diagram Quality Gate (no Mermaid) — see `agents/wiki-reviewer.md`'s comment block. P1.1 closes one increment of the #309 Phase-6-readiness gate; #309 stays open (P1.2-rest UX + P2 remain).

## What is no longer in the runtime path

- **cogni-research.** v0.1.0 dispatches zero cogni-research skills and zero cogni-research agents. The forked agents (source-curator, claim-extractor, writer→wiki-composer, revisor) are point-in-time copies under `cogni-knowledge/agents/`; drift from upstream is acceptable. cogni-research stays installed only for users who want one-shot reports via its own skills, and for cross-plugin callers (cogni-trends, cogni-narrative).
- **cogni-claims.** v0.1.0 dispatches zero cogni-claims skills for its own consumers. cogni-claims stays alive for cogni-trends and cogni-portfolio submitters. `wiki-verifier` replaces it for cogni-knowledge.
- **cogni-wiki:wiki-from-research.** Replaced by the inverted pipeline. `knowledge-ingest` calls `wiki-ingest`'s low-level scripts (backlink_audit, wiki_index_update) directly instead of dispatching the orchestrator.

## What is still delegated upstream

- `cogni-wiki:wiki-setup` for wiki bootstrap (called from `knowledge-setup`).
- `cogni-wiki:wiki-query`, `wiki-dashboard`, `wiki-health`, `wiki-resume`, `wiki-lint`, `wiki-refresh` — `knowledge-query`, `knowledge-dashboard`, `knowledge-resume`, `knowledge-refresh` remain thin wrappers around these.
- `cogni-wiki:wiki-claims-resweep` — opt-in live-source re-verification of the bound wiki's cited claims (#337). Dispatched via `knowledge-refresh --resweep`; **never auto-run** from finalize or any other per-run path (would re-introduce the WebFetch cost the inverted pipeline structurally fixed). The dashboard reads its `last-resweep.json` to surface the cadence.
- `cogni-wiki/skills/wiki-ingest/scripts/{backlink_audit,wiki_index_update}.py` — called from `source-ingester` directly (script-level, not skill-level).
- `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py` — `knowledge-distill`'s `concept-store.py` **imports** `_wiki_lock` / `is_foundation_page` / `parse_frontmatter` from it (via the orchestrator-resolved `--wiki-scripts-dir`) rather than re-inlining the lock, honouring cogni-wiki's "new shared-state writers MUST import `_wiki_lock`" contract. cogni-knowledge thus becomes a **locked writer into the wiki tree** (the concept/entity page RMW runs under the canonical `<wiki-root>/.cogni-wiki/.lock`). `knowledge-distill` also calls `backlink_audit.py` / `wiki_index_update.py` / `config_bump.py` at script level, same posture as `knowledge-ingest`.
- `cogni-wiki/skills/wiki-ingest/scripts/{wiki_index_update,config_bump,rebuild_context_brief}.py` — called from `knowledge-finalize` at script level. `wiki_index_update.py` was added to the helper trio at v0.0.24 — without it the new synthesis page would not appear in `wiki/index.md` (the catalog), matching the same posture `wiki-query --file-back` and `knowledge-ingest` already adopt for their new pages.

## Cross-plugin coordination prerequisites

- **cogni-wiki v0.0.44** must release before milestone 6 (`knowledge-ingest`). It adds `type: source` to the recognized page-type allowlist in `wiki-lint` and `wiki-health`.

## See also

- `fetch-cache-design.md` — content-addressing, eviction policy, freshness window
- `claim-at-ingest.md` — why claims are pre-extracted from source bodies, not from drafts
- `absorption-roadmap.md` — how this fits the broader v0.1.0 / v1.0.0 sequence
