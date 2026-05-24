# cogni-knowledge — developer guide

Wiki-first research orchestrator. Binds a `cogni-wiki` knowledge base to N research projects so the work compounds across runs instead of dying in chat history. The v0.1.0 inverted-pipeline path (Phases 1–7) forks dedicated agents under `agents/` and runs zero-network claim verification, with no cogni-research dispatch in the runtime path — it is the only live path. The legacy v0.0.x chain (`knowledge-research` / `knowledge-report`) was archived under `_archive/` at M11 (v0.0.27). `agents/` and `scripts/` are populated accordingly.

## Architecture

```
.cogni-knowledge/binding.json   ← the only new state cogni-knowledge owns
       │
       ▼
knowledge-* skills (orchestrators)
       │
       ▼
cogni-wiki / cogni-research (delegate targets)
```

A "knowledge base" is one directory that contains both:

- `.cogni-wiki/config.json` — the wiki manifest (owned by `cogni-wiki`)
- `.cogni-knowledge/binding.json` — the binding manifest (owned by this plugin)

They live as siblings. The wiki is the substrate; the binding records which research projects have contributed.

## Skills

| Skill | Role |
|---|---|
| `knowledge-setup` | Bootstrap a knowledge base. Dispatches `cogni-wiki:wiki-setup` if no wiki exists, then writes `binding.json`. Probes only `cogni-wiki` (clean break, M11 v0.0.27+). |
| `knowledge-resume` | Status. Reads `binding.json` and delegates to `cogni-wiki:wiki-resume` (which itself runs `wiki-health`). Per-project inverted-pipeline depth + a fetch-cache verdict come from `pipeline-summary.py`. Probes only `cogni-wiki` (clean break, M10a v0.0.25+). |
| `knowledge-query` | Ask a question against the bound base. Resolves the wiki path from `binding.json`, dispatches `cogni-wiki:wiki-query` against it, appends a one-line knowledge-base footer (deposit count + fetch-cache health via `pipeline-summary.py cache-health`). Read-only. Probes only `cogni-wiki` (clean break, M10a v0.0.25+). Phase 3, v0.0.8+. |
| `knowledge-dashboard` | Render an HTML overview. Dispatches `cogni-wiki:wiki-dashboard` against the bound wiki, then writes a `knowledge-overlay.md` sidecar: deposited projects with per-project inverted-pipeline columns (sub-questions, fetched/unavailable, verifier verdicts via `pipeline-summary.py project`), a knowledge-base-global `## Pipeline health` block (`pipeline-summary.py cache-health`), and the latest lint-audit `claim_drift` count. Probes only `cogni-wiki` (clean break, M10a v0.0.25+). Phase 3, v0.0.9+. |
| `knowledge-refresh` | Self-healing loop. Pull-mode delegates to `cogni-wiki:wiki-refresh` (legacy bridge, unchanged). **Push-mode (rewritten at M10b, v0.0.26)** lints the wiki, asks which stale topics to refresh, then runs the seven-phase inverted pipeline per topic (`knowledge-plan` → … → `knowledge-finalize`) — fail-soft per topic, idempotent resume, zero cogni-research dispatch. Probes only `cogni-wiki` (clean break). Phase 3, v0.0.10+. |
| `knowledge-plan` | **v0.1.0 inverted pipeline, Phase 1.** Decomposes a topic into 3-7 sub-questions with per-sub-question `candidate_domains[]` (no web). Writes `<project>/.metadata/plan.json` schema `0.1.0`. Probes only `cogni-wiki` — the v0.1.0 path does not dispatch cogni-research. Phase 5, v0.0.17+. |
| `knowledge-curate` | **v0.1.0 inverted pipeline, Phase 2.** Reads `plan.json`, fans out one `source-curator` dispatch per sub-question (WebSearch + score, **then WebFetch each survivor's body** into the shared `.cogni-knowledge/fetch-cache/` — Option B, #292, v0.0.29), merges per-sub-question batches into `<project>/.metadata/candidates.json` via `candidate-store.py append-batch`. Each candidate carries a `fetch` sub-object. Phase 5, v0.0.17+ (fetch folded in v0.0.29). |
| `knowledge-fetch` | **v0.1.0 inverted pipeline, Phase 3.** Under Option B (v0.0.29) builds `<project>/.metadata/fetch-manifest.json` directly from the curators' `fetch` sub-objects (no WebFetch — that moved to Phase 2). Cobrowse recovery of WebFetch misses is **opt-in** (`--cobrowse` / interactive prompt; default OFF so autonomous runs stay browser-free): probes + walks the user through the Claude-in-Chrome extension, then dispatches `source-fetcher` (cobrowse-only) sequentially and merges rescues. Phase 5, v0.0.17+ (cobrowse-reconcile in v0.0.29). |
| `knowledge-ingest` | **v0.1.0 inverted pipeline, Phase 4.** Reads `fetch-manifest.json`, dispatches `source-ingester` per fetched source (which dispatches `claim-extractor` per body), merges per-source results into `<project>/.metadata/ingest-manifest.json`, then calls cogni-wiki's `backlink_audit.py` + `wiki_index_update.py` directly at script level per new slug. Writes one `<wiki>/sources/<slug>.md` page per fetched URL with `type: source` + populated `pre_extracted_claims:` — the F6 fix (wiki populated before any draft runs). Phase 5, v0.0.20+. |
| `knowledge-compose` | **v0.1.0 inverted pipeline, Phase 5.** Reads `plan.json` + `ingest-manifest.json` + the populated wiki (`wiki/index.md` + selected `wiki/sources/*.md` + prior `wiki/syntheses/*.md`), dispatches `wiki-composer` once via `Task`, and verifies `<project>/output/draft-vN.md` + `<project>/.metadata/citation-manifest.json` land on disk. Citations are `[[sources/<slug>]]` wikilinks (not URLs); URL/APA rendering deferred to M9 finalize. Preserves the **F11 outline-recovery contract** — a leftover `writer-outline-vN.json` from a crashed prior run triggers `RESUME_FROM_OUTLINE=true` so only Phase 2 re-runs. Phase 5, v0.0.22+. |
| `knowledge-verify` | **v0.1.0 inverted pipeline, Phase 6.** Reads `citation-manifest.json` + latest `draft-vN.md`. **Fans the verifier out (v0.0.28):** shards `citations[]` via `verify-store.py shard`, dispatches N `wiki-verifier` in parallel via `Task` (each scoped to a shard subset; verdicts score each citation's verbatim `draft_sentence` against the cited page's `pre_extracted_claims:`, zero-network — the structural cost win vs cogni-claims, target < 5 min per shard), then `verify-store.py merge` reassembles `verify-vN.json`. Loops with `revisor` via `Task` on `unsupported` deviations — capped at 2 revisor iterations per `references/inverted-pipeline.md` Phase 6; the inline prune of `sentence_not_in_draft` deviations keys on the stable citation `id`. Writes `<project>/.metadata/verify-vN.json` per round and (when the revisor fires) `draft-v{N+1}.md` plus a rewritten citation manifest. Phase 5, v0.0.23+ (fan-out v0.0.28). |
| `knowledge-finalize` | **v0.1.0 inverted pipeline, Phase 7.** Reads the latest `output/draft-vN.md` + `verify-vN.json` + `citation-manifest.json`, runs `cycle-guard.py` (with the v0.0.24 citation-manifest fallback) to refuse self-citing loops, atomically writes `<wiki>/syntheses/<synthesis-slug>.md` with `type: synthesis` + `derived_from_research: <project-slug>` + `sources:` reconstructed as `wiki://<wiki_slug>/<cited-slug>` entries + an auto-generated `## References` list. Calls cogni-wiki's `wiki_index_update.py --category "Syntheses"` + `config_bump.py --key entries_count --delta 1` + `rebuild_context_brief.py` directly at script level. Appends the project to `binding.json::research_projects[]` with `report_source: wiki`. Writes one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md`. Closes the inverted-pipeline loop — future `knowledge-compose` runs read `wiki/syntheses/*.md` as prior cross-source framing. Phase 5, v0.0.24+. |

The inverted pipeline closes the round-trip — `knowledge-finalize` deposits a verified synthesis into `wiki/syntheses/`, and future `knowledge-compose` runs read those syntheses as prior cross-source framing. The differentiation thesis (knowledge compounds across projects) holds because of this loop.

## Agents (v0.1.0 inverted pipeline)

Starting at v0.0.17, cogni-knowledge has an `agents/` directory. v0.0.x had none by design (everything delegated to upstream cogni-research agents); the v0.1.0 clean break forks agents locally so the runtime path is 0% cogni-research. See `references/delegation-contract.md` §"What about `agents/`?" and `references/inverted-pipeline.md` (the v0.1.0 source of truth).

| Agent | Role |
|---|---|
| `source-curator` | Phase 2. Forked from `cogni-research/agents/source-curator.md` (point-in-time copy; drift acceptable). Per-sub-question WebSearch + scoring, **then a Phase-4 WebFetch body-pull** of each survivor into the fetch-cache (Option B, #292, v0.0.29) — incl. the PDF branch (`_knowledge_lib.is_pdf_response` + 20-page `Read`-loop + 200-page cap, moved here from `source-fetcher`). Emits a batch JSON array (each candidate carries a `fetch` sub-object) for merge into `candidates.json`. Gained `WebFetch` in its `tools:` at v0.0.29; no cobrowse tools. v0.0.17+. |
| `source-fetcher` | Phase 3, **cobrowse-only** (v0.0.29). NEW (no upstream). Recovers the curator's WebFetch misses via the `claude-in-chrome` extension and writes through `fetch-cache.py`; dispatched only when the user opts into cobrowse. The WebFetch + PDF branch moved to `source-curator` (Option B, #292), so `WebFetch`/`Read` were dropped from its `tools:`. Closed reason vocabulary in `references/fetch-cache-design.md` §"Reason semantics". v0.0.17+ (shrank to cobrowse-only v0.0.29). |
| `claim-extractor` | Phase 4. Forked from `cogni-research/agents/claim-extractor.md` (point-in-time copy). Reads one cached source body + sub-question refs, emits a JSON array of `{id, text, excerpt_quote, excerpt_position, sub_question_refs, extracted_at}` per `references/claim-at-ingest.md:37-49`. Pure extraction — never writes files; the calling source-ingester embeds the array into the wiki page's `pre_extracted_claims:` frontmatter. v0.0.20+. |
| `source-ingester` | Phase 4. NEW (no upstream). Reads one cached body via `fetch-cache.py fetch`, dispatches `claim-extractor`, writes `<wiki>/sources/<slug>.md` atomically via `_knowledge_lib.atomic_write_text`. Frontmatter carries `type: source`, `sources: [<URL>]`, `pre_extracted_claims:`. Body is the cached source verbatim — no in-body highlighting (`excerpt_position` is the indexing primitive). v0.0.20+. |
| `wiki-composer` | Phase 5. Forked from `cogni-research/agents/writer.md` (305 lines) at v0.0.22; point-in-time copy, drift acceptable. Reads `wiki/index.md` + selected `wiki/sources/*.md` (lazily, per-section) + prior `wiki/syntheses/*.md`, writes `<project>/output/draft-vN.md` with `[[sources/<slug>]]` wikilink citations, and emits `<project>/.metadata/citation-manifest.json` with one `{draft_position, wiki_slug, claim_id}` entry per citation. Persists `writer-outline-vN.json` in Phase 1 before any draft `Write` (F11 anchor). Single-pass (no `Task` in tools list) — no expansion loop, no per-section sharding, English-only, standard density. v0.0.22+. |
| `wiki-verifier` | Phase 6. NEW (no upstream — cogni-claims re-fetches; this verifier does zero network). Reads `<project>/output/draft-vN.md` + a citation manifest (full, or a shard via `CITATIONS_PATH`) + each cited `wiki/sources/<slug>.md`'s `pre_extracted_claims:` frontmatter, and scores each citation's verbatim `draft_sentence` (carried in the manifest since v0.0.28) as `verbatim` / `paraphrase` / `unsupported` (plus the informational `synthesis` verdict for `claim_id: null` wikilinks). Writes `verify-vN.json` (or a per-shard fragment via `VERIFY_OUT_PATH`) schema `0.1.0`, echoing each entry's stable `id`. **Never re-tokenizes the draft** — it reads the draft only for a `draft_sentence` substring staleness check (`sentence_not_in_draft`), which dissolves the F20/F22 off-by-one. Single-pass, read-only tools (`Read` / `Write` / `Glob` / `Grep`) — no `WebFetch`, no `WebSearch`, no `Task`; the v0.0.28 fan-out is orchestrator-driven. v0.0.23+ (draft_sentence + shard params v0.0.28). |
| `revisor` | Phase 6. Forked from `cogni-research/agents/revisor.md` at v0.0.23; point-in-time copy, drift acceptable. Reads `<project>/.metadata/verify-vN.json::deviations[]` + `<project>/output/draft-vN.md` + each deviation's cited page's `pre_extracted_claims:`. Locates the sentence by exact-string-search of the manifest's `draft_sentence` (joined by `id`), never by re-tokenizing. **Re-points to a covering on-page claim before dropping (v0.0.28, #288)** — drop is the last resort; `fixes_summary` carries a `repoint` count alongside `rephrase`/`drop`/`skip`. Writes `draft-v{N+1}.md` plus a rewritten `citation-manifest.json` (`draft_version: N+1`, `id` + updated `draft_sentence` preserved). Zero-network: tools list drops `WebSearch` / `WebFetch` / `Bash` from upstream. Also drops upstream expansion mode, Source-Mode Evidence Gathering, arc-preservation, oscillation detection, and confidence-assessment — all upstream-only. v0.0.23+ (repoint + draft_sentence locate v0.0.28). |

## Scripts

| Script | Purpose | LLM? |
|---|---|---|
| `knowledge-binding.py` | `init` / `append-project` / `read` subcommands against `.cogni-knowledge/binding.json` | No (stdlib only) |
| `cycle-guard.py` | Detects direct self-cycles before a wiki-mode re-deposit. Two citation input shapes: **legacy** (cogni-research v0.0.x) walks the candidate's `02-sources/data/src-*.md` for `wiki://<bound-slug>/<page-id>` citations; **citation-manifest** (v0.1.0 inverted pipeline, v0.0.24+ adapter) walks `<project>/.metadata/citation-manifest.json::citations[].wiki_slug`. The fallback is additive — legacy wins when the glob is non-empty; manifest fires when it's empty. The resulting `data.input_shape` is surfaced in the envelope. Both shapes resolve cited pages by the same slug index and check `derived_from_research:` frontmatter. Exit 1 on `cycle_detected`, exit 0 on `clear` or `not_applicable` (web/local mode). | No (stdlib only) |
| `fetch-cache.py` | **v0.1.0 inverted pipeline.** Content-addressed URL→body cache at `.cogni-knowledge/fetch-cache/<sha256>.json`. Subcommands `store` / `fetch` (with `--max-age-days` staleness gate) / `evict` / `stat` / `key`. Negative caching for unavailable URLs; freshness symmetric with positive entries. Atomic temp+rename per entry. v0.0.16-foundation (shipped via PR #269, no version bump); consumed by `source-fetcher` at v0.0.17. | No (stdlib only) |
| `candidate-store.py` | **v0.1.0 inverted pipeline.** File-locked (`fcntl.flock`) merge of parallel `source-curator` output batches into `<project>/.metadata/candidates.json`. Subcommands `init` / `append-batch` / `read`. Dedup key URL-normalized (lowercase scheme+host, trailing-slash-stripped, common tracking params dropped). On collision: higher score wins, earliest `discovered_at` wins, `sub_question_refs[]` unioned, `tier` + `fetch_priority` recomputed. Posix-only. v0.0.17+. | No (stdlib only) |
| `verify-store.py` | **v0.1.0 inverted pipeline, Phase 6 fan-out (v0.0.28).** `shard` splits `<project>/.metadata/citation-manifest.json::citations[]` into ⌈N/size⌉ per-shard manifests under `.metadata/verify-shards/` (default `--shard-size 40`); `merge` concatenates the per-shard `wiki-verifier` fragments into the canonical `verify-vN.json`, recomputes `counts`, and enforces `counts.total == verified+deviations` + reports `shards_merged` (so the orchestrator catches a crashed shard). **No `fcntl.flock`** — shards are partition-disjoint and `merge` is single-shot, so there is no shared-write contention (the one structural difference from `candidate-store.py`). Writes via `_knowledge_lib.atomic_write`. | No (stdlib only) |
| `pipeline-summary.py` | **v0.1.0 inverted pipeline, read-side (M10a).** Read-only summaries for `knowledge-query` / `knowledge-dashboard` / `knowledge-resume`. `project --project-path` returns per-project state from the six `.metadata/` manifests (sub-questions, candidates, fetched/unavailable, ingested/skipped, citations, latest-`verify-vN` verdict `counts`, `phase_reached`), degrading to zeros + `phase_reached: "none"` on a legacy v0.0.x project. `cache-health --knowledge-root` joins `fetch-cache.py stat` (knowledge-base-global) with `binding.curator_defaults.fetch_cache_max_age_days` to emit `{entries, negative_ratio, oldest_age_days, max_age_days, verdict ∈ empty/healthy/stale}`. v0.0.25+. | No (stdlib only) |

All scripts return `{"success": bool, "data": {...}, "error": "..."}` per the insight-wave convention (`../CLAUDE.md` §"Script Output Format"). Stdlib only — no pip dependencies.

## Data model — `binding.json`

```json
{
  "knowledge_slug": "<kebab-case>",
  "knowledge_title": "<human readable>",
  "wiki_path": "<absolute path to wiki root>",
  "research_projects": [
    {
      "slug": "<research-project-slug>",
      "deposited_at": "<YYYY-MM-DD>",
      "report_path": "<absolute path to output/report.md>",
      "report_source": "web | local | wiki | hybrid",
      "project_path": "<absolute path to project root>"
    }
  ],
  "topic_lineage": {
    "covered_themes": [],
    "open_themes": []
  },
  "curator_defaults": {
    "max_candidates_per_sq": 12,
    "score_threshold": 0.5,
    "fetch_cache_max_age_days": 30
  },
  "created": "<YYYY-MM-DD>",
  "schema_version": "0.0.3"
}
```

`curator_defaults` (added at schema 0.0.3) configures the inverted pipeline's `knowledge-curate` and `knowledge-fetch` phases — see `references/inverted-pipeline.md` and `references/fetch-cache-design.md`. The fetch-cache itself lives at `<knowledge-root>/.cogni-knowledge/fetch-cache/` by convention; the path is derivable from the knowledge root and is therefore not echoed into the binding.

Schema bumps mirror the data shape, not the plugin tag. The schema goes `0.0.1 → 0.0.2 → 0.0.3` for additive field adds; the next jump to `0.1.0` aligns with the `plugin.json` v0.1.0 maturity-flip at M12. Consumers that need v0.0.3 fields on a pre-v0.0.3 binding MUST `.get(..., DEFAULT)` — `cmd_read` returns the binding as-is and does not auto-migrate.

The file is small (< 4 KiB even at 20+ deposited projects). It is *not* a database — it is a narrative manifest that records what the user has chosen to bind together. Search across the wiki itself for content; consult the binding only for "what projects fed this base".

## Delegation contract

The hard rule: **no logic that already exists upstream**. If you find yourself writing code that duplicates a `cogni-wiki` script or a `cogni-research` agent, stop and re-delegate. The full mapping lives in `references/delegation-contract.md`.

A few specifics:

- `knowledge-setup` does NOT re-implement `wiki-setup`. It only handles the `binding.json` half.
- `knowledge-ingest` does NOT dispatch `cogni-wiki:wiki-ingest` — it calls the helper scripts (`backlink_audit.py`, `wiki_index_update.py`) directly at script level (M6 contract).
- `knowledge-resume` does NOT compute wiki health. `wiki-resume` already calls `wiki-health` automatically as of cogni-wiki v0.0.27.

## Lineage stamping

`derived_from_research: <slug>` in a wiki page's YAML frontmatter is what cycle-guard reads to detect circular evidence without a filesystem walk. In the v0.1.0 inverted pipeline, `knowledge-finalize` sets this field inline when it atomically writes the synthesis page — no separate stamping pass runs. The legacy `lineage-stamp.py` helper (which globbed `wiki/**/*.md` and stamped Mode-A deposits derived from `raw/research-<slug>/`) is archived under `_archive/scripts/` alongside the chain that used it.

## Conventions

- Skill names: `knowledge-*` (generic skill names like `setup`, `research`, `resume` MUST be prefixed per `../CLAUDE.md` §"Contributing").
- Skill frontmatter: `name`, `description`, `allowed-tools` — same shape as cogni-wiki/cogni-research skills.
- Script CLI: `python3 scripts/<name>.py --action ...`, JSON envelope output.
- Path conventions: knowledge bases default to `<cwd>/<knowledge-slug>/` (matching `cogni-wiki/{slug}/`).
- Versioning: bump patch on any skill/script change; mirror in `marketplace.json` (`../CLAUDE.md` §"Version Management").

## Future phases

Phases 1-3 shipped (v0.0.1 → v0.0.11), 2/3 follow-up debt cleared at v0.0.13, Phase 4 alpha completed at v0.0.15 with a **GO** recommendation. **Phase 5 is in flight as one big v0.1.0 inverted-pipeline clean break** — see `references/absorption-roadmap.md` for the canonical 12-milestone (M1–M12) table and current status. The plugin stays at `0.0.x`/maturity `incubating` until M12 ships the alpha re-run + version bump to 0.1.0 + maturity flip in a single landing. Phase 6 (cogni-research deprecation cleanup) follows Phase 5.

Inverted-pipeline progress: M1 (plumbing) + M2-script (fetch-cache.py) shipped at PR #269 with no version bump. M2-finish (`source-fetcher` agent) + M3 (`source-curator` fork) + M4 (`knowledge-plan` / `knowledge-curate` / `knowledge-fetch` skills + `candidate-store.py`) shipped at v0.0.17. M4 end-to-end smoke shipped docs-only at v0.0.19 (GO for Slice 2). **M5 (`claim-extractor` fork + `source-ingester` agent) + M6 (`knowledge-ingest` skill) shipped at v0.0.20**, alongside #275 (PDF detection in source-fetcher) and #276 (`cobrowse_unavailable` reason). PDF Read-loop past page 20 shipped at v0.0.21 (#278). **M7 (`wiki-composer` agent + `knowledge-compose` skill) shipped at v0.0.22 — Slice 3** with the F11 outline-recovery contract preserved through the fork; the writer now reads the populated wiki and emits `[[sources/<slug>]]`-cited drafts plus a citation manifest M8's verifier will consume. **M8 (`wiki-verifier` agent + `revisor` fork + `knowledge-verify` skill) shipped at v0.0.23 — Slice 4**; the citation manifest is now consumed by a zero-network claim-alignment pass against each cited page's `pre_extracted_claims:` (verifier verdicts: `verbatim` / `paraphrase` / `unsupported` / `synthesis`), with a max-2-iteration revisor loop on `unsupported` deviations — the structural cost win versus cogni-claims (target < 5 min vs 20–30 min baseline). **M9 (`knowledge-finalize` skill + `cycle-guard.py` v0.1.0 adapter) shipped at v0.0.24 — Slice 5**; the verified draft is now deposited as `<wiki>/syntheses/<synthesis-slug>.md` with `type: synthesis` + `derived_from_research: <project-slug>` + an auto-generated `## References` list. Three cogni-wiki helpers (`wiki_index_update.py` + `config_bump.py` + `rebuild_context_brief.py`) run at script level so the new page is discoverable + the wiki health stays consistent. `cycle-guard.py` gained a strict additive fallback that reads `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty — direct-cycle detection now works on v0.1.0 projects, and the new envelope field `data.input_shape` signals which path ran. The inverted-pipeline loop closes here — future `knowledge-compose` runs read `wiki/syntheses/*.md` as prior cross-source framing. **M10a (read-side adapters) shipped at v0.0.25** — `knowledge-query` / `knowledge-dashboard` / `knowledge-resume` now read inverted-pipeline state via the new `pipeline-summary.py` (`project` + `cache-health`), and all three drop their cogni-research pre-flight probe to cogni-wiki-only (honouring the clean break ahead of M11's archive). **M10b shipped at v0.0.26** — `knowledge-refresh --mode push` was rewritten to run the seven-phase inverted pipeline (`knowledge-plan` → … → `knowledge-finalize`) per stale topic instead of dispatching the legacy `knowledge-research` + `wiki-refresh` pair, dropping its cogni-research probe; paired with cogni-wiki v0.0.45's additive `compose`/`verify`/`finalize` log-enum cleanup. **M11 shipped at v0.0.27** — the legacy `knowledge-research` + `knowledge-report` skills and their two private helper scripts (`lineage-stamp.py`, `read-project-config.py`) were archived to `_archive/`, `knowledge-setup` dropped its cogni-research probe, and README/CLAUDE.md/references were rewritten so the inverted pipeline is the only live path; a permanent audit-grep in `test_skill_contracts.sh` now guards the boundary. **M12's first alpha gate ran 2026-05-23 and was HELD** on C3 (verify ~16–18 min/pass at 169 citations) + C4 (verify→revise doesn't converge in 2 rounds), both rooted in F20 (composer/verifier/revisor independently re-tokenize the draft and drift by one). **Slice 10 (v0.0.28) cleared the three blockers:** F22 (#287) carries a stable `id` + verbatim `draft_sentence` per citation so the verifier scores the sentence directly and never re-tokenizes (`draft_position` demoted to best-effort; `draft_position_out_of_range` → `sentence_not_in_draft`); F21 (#286) fans the verifier out across parallel shards via the new `verify-store.py`; F23 (#288) makes the revisor re-point to a covering on-page claim before dropping (new `repoint` metric). The F20 tokenizer rewrite is deliberately **not** done — `draft_sentence` makes it non-load-bearing. **Slice 11 (v0.0.29) parallelized the fetch (#292, Option B):** the WebFetch body-pull + PDF branch moved from `source-fetcher` (Phase 3) into `source-curator`'s new Phase 4, so the fetch rides the already-parallel per-sub-question curators instead of a strictly-sequential batch loop; `source-fetcher` shrank to a cobrowse-only fallback that `knowledge-fetch` dispatches only on user opt-in (`--cobrowse`, default OFF). Each `candidates.json` entry now carries a `fetch` sub-object, and `candidate-store.py` prefers the `ok`-fetch side on a cross-SQ dedup. C1 was reworded to a content-addressed-cache-entry basis (same-wave double-fetch collapses to one entry). Next: **re-run the M12 gate** on a fresh `.alpha/` base, then (only on green) bump to v0.1.0 + flip maturity to Preview in a separate landing.
