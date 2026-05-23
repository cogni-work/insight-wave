# cogni-knowledge — developer guide

Wiki-first research orchestrator. Binds a `cogni-wiki` knowledge base to N research projects so the work compounds across runs instead of dying in chat history. The v0.0.x legacy path (`knowledge-research` / `knowledge-report`) delegates upward to cogni-research + cogni-wiki; the v0.1.0 inverted-pipeline path (Phases 1–7, in flight) forks dedicated agents under `agents/` and runs zero-network claim verification, with no cogni-research dispatch in the runtime path. `agents/` and `scripts/` are populated accordingly.

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
| `knowledge-setup` | Bootstrap a knowledge base. Dispatches `cogni-wiki:wiki-setup` if no wiki exists, then writes `binding.json`. |
| `knowledge-research` | Research a topic INTO the bound wiki. Dispatches `cogni-wiki:wiki-from-research --topic ...` (Mode A), then stamps lineage and appends to the binding. Records the live `report_source` from `<project>/.metadata/project-config.json` (v0.0.7+). |
| `knowledge-report` | Compose a report BY READING the bound wiki, refuse self-citing loops via `cycle-guard.py`, then re-deposit via `cogni-wiki:wiki-from-research` Mode B with `--allow-wiki-source --cycle-guard-cleared`. Records the live `report_source` (wiki/hybrid) in the binding. Phase 2 of the absorption roadmap. |
| `knowledge-resume` | Status. Reads `binding.json` and delegates to `cogni-wiki:wiki-resume` (which itself runs `wiki-health`). Per-project inverted-pipeline depth + a fetch-cache verdict come from `pipeline-summary.py`. Probes only `cogni-wiki` (clean break, M10a v0.0.25+). |
| `knowledge-query` | Ask a question against the bound base. Resolves the wiki path from `binding.json`, dispatches `cogni-wiki:wiki-query` against it, appends a one-line knowledge-base footer (deposit count + fetch-cache health via `pipeline-summary.py cache-health`). Read-only. Probes only `cogni-wiki` (clean break, M10a v0.0.25+). Phase 3, v0.0.8+. |
| `knowledge-dashboard` | Render an HTML overview. Dispatches `cogni-wiki:wiki-dashboard` against the bound wiki, then writes a `knowledge-overlay.md` sidecar: deposited projects with per-project inverted-pipeline columns (sub-questions, fetched/unavailable, verifier verdicts via `pipeline-summary.py project`), a knowledge-base-global `## Pipeline health` block (`pipeline-summary.py cache-health`), and the latest lint-audit `claim_drift` count. Probes only `cogni-wiki` (clean break, M10a v0.0.25+). Phase 3, v0.0.9+. |
| `knowledge-refresh` | Self-healing loop. Pull-mode delegates to `cogni-wiki:wiki-refresh`. Push-mode lints the wiki, asks which stale topics to re-research, then sequentially dispatches `knowledge-research` + `wiki-refresh` per selected topic. Phase 3, v0.0.10+. |
| `knowledge-plan` | **v0.1.0 inverted pipeline, Phase 1.** Decomposes a topic into 3-7 sub-questions with per-sub-question `candidate_domains[]` (no web). Writes `<project>/.metadata/plan.json` schema `0.1.0`. Probes only `cogni-wiki` — the v0.1.0 path does not dispatch cogni-research. Phase 5, v0.0.17+. |
| `knowledge-curate` | **v0.1.0 inverted pipeline, Phase 2.** Reads `plan.json`, fans out one `source-curator` dispatch per sub-question (WebSearch + score, no fetch), merges per-sub-question batches into `<project>/.metadata/candidates.json` via `candidate-store.py append-batch`. Phase 5, v0.0.17+. |
| `knowledge-fetch` | **v0.1.0 inverted pipeline, Phase 3.** Reads `candidates.json`, dispatches `source-fetcher` per batch (WebFetch + cobrowse fallback), merges into `<project>/.metadata/fetch-manifest.json`. Successful bodies land in the shared `.cogni-knowledge/fetch-cache/`; unavailable URLs are negatively cached. Phase 5, v0.0.17+. |
| `knowledge-ingest` | **v0.1.0 inverted pipeline, Phase 4.** Reads `fetch-manifest.json`, dispatches `source-ingester` per fetched source (which dispatches `claim-extractor` per body), merges per-source results into `<project>/.metadata/ingest-manifest.json`, then calls cogni-wiki's `backlink_audit.py` + `wiki_index_update.py` directly at script level per new slug. Writes one `<wiki>/sources/<slug>.md` page per fetched URL with `type: source` + populated `pre_extracted_claims:` — the F6 fix (wiki populated before any draft runs). Phase 5, v0.0.20+. |
| `knowledge-compose` | **v0.1.0 inverted pipeline, Phase 5.** Reads `plan.json` + `ingest-manifest.json` + the populated wiki (`wiki/index.md` + selected `wiki/sources/*.md` + prior `wiki/syntheses/*.md`), dispatches `wiki-composer` once via `Task`, and verifies `<project>/output/draft-vN.md` + `<project>/.metadata/citation-manifest.json` land on disk. Citations are `[[sources/<slug>]]` wikilinks (not URLs); URL/APA rendering deferred to M9 finalize. Preserves the **F11 outline-recovery contract** — a leftover `writer-outline-vN.json` from a crashed prior run triggers `RESUME_FROM_OUTLINE=true` so only Phase 2 re-runs. Phase 5, v0.0.22+. |
| `knowledge-verify` | **v0.1.0 inverted pipeline, Phase 6.** Reads `citation-manifest.json` + latest `draft-vN.md`, dispatches `wiki-verifier` once per round via `Task` to score every citation against each cited page's `pre_extracted_claims:` (zero-network — the structural cost win versus cogni-claims, target < 5 min vs 20–30 min baseline), and loops with `revisor` via `Task` on `unsupported` deviations — capped at 2 revisor iterations per `references/inverted-pipeline.md` Phase 6. Writes `<project>/.metadata/verify-vN.json` per round and (when the revisor fires) `draft-v{N+1}.md` plus a rewritten citation manifest. Phase 5, v0.0.23+. |
| `knowledge-finalize` | **v0.1.0 inverted pipeline, Phase 7.** Reads the latest `output/draft-vN.md` + `verify-vN.json` + `citation-manifest.json`, runs `cycle-guard.py` (with the v0.0.24 citation-manifest fallback) to refuse self-citing loops, atomically writes `<wiki>/syntheses/<synthesis-slug>.md` with `type: synthesis` + `derived_from_research: <project-slug>` + `sources:` reconstructed as `wiki://<wiki_slug>/<cited-slug>` entries + an auto-generated `## References` list. Calls cogni-wiki's `wiki_index_update.py --category "Syntheses"` + `config_bump.py --key entries_count --delta 1` + `rebuild_context_brief.py` directly at script level. Appends the project to `binding.json::research_projects[]` with `report_source: wiki`. Writes one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md`. Closes the inverted-pipeline loop — future `knowledge-compose` runs read `wiki/syntheses/*.md` as prior cross-source framing. Phase 5, v0.0.24+. |

Phase 2 closes the round-trip — `knowledge-report` reads the wiki, re-deposits via `wiki-from-research` Mode B with the opt-in flags, and `cycle-guard.py` refuses self-citing loops. The differentiation thesis (knowledge compounds across projects) holds only with this loop closed; before v0.0.6 a second research run could only deposit, never compose-and-deposit.

## Agents (v0.1.0 inverted pipeline)

Starting at v0.0.17, cogni-knowledge has an `agents/` directory. v0.0.x had none by design (everything delegated to upstream cogni-research agents); the v0.1.0 clean break forks agents locally so the runtime path is 0% cogni-research. The v0.0.x "What about `agents/`?" paragraph in `references/delegation-contract.md` is the legacy contract — `references/inverted-pipeline.md` is the v0.1.0 source of truth.

| Agent | Role |
|---|---|
| `source-curator` | Phase 2. Forked from `cogni-research/agents/source-curator.md` (point-in-time copy; drift acceptable). Per-sub-question WebSearch + scoring. Emits a batch JSON array for merge into `candidates.json`. v0.0.17+. |
| `source-fetcher` | Phase 3. NEW (no upstream). Per-URL WebFetch with `claude-in-chrome` cobrowse fallback; reads/writes through `fetch-cache.py`. PDF branch added at v0.0.20 (#275): WebFetch saves the binary, `Read pages: "1-20"` transcribes text; EUR-Lex-style no-saved-path responses record `pdf_extraction_failed`. Closed `webfetch_error_class` vocabulary documented in `references/fetch-cache-design.md` §"Reason semantics". v0.0.17+. |
| `claim-extractor` | Phase 4. Forked from `cogni-research/agents/claim-extractor.md` (point-in-time copy). Reads one cached source body + sub-question refs, emits a JSON array of `{id, text, excerpt_quote, excerpt_position, sub_question_refs, extracted_at}` per `references/claim-at-ingest.md:37-49`. Pure extraction — never writes files; the calling source-ingester embeds the array into the wiki page's `pre_extracted_claims:` frontmatter. v0.0.20+. |
| `source-ingester` | Phase 4. NEW (no upstream). Reads one cached body via `fetch-cache.py fetch`, dispatches `claim-extractor`, writes `<wiki>/sources/<slug>.md` atomically via `_knowledge_lib.atomic_write_text`. Frontmatter carries `type: source`, `sources: [<URL>]`, `pre_extracted_claims:`. Body is the cached source verbatim — no in-body highlighting (`excerpt_position` is the indexing primitive). v0.0.20+. |
| `wiki-composer` | Phase 5. Forked from `cogni-research/agents/writer.md` (305 lines) at v0.0.22; point-in-time copy, drift acceptable. Reads `wiki/index.md` + selected `wiki/sources/*.md` (lazily, per-section) + prior `wiki/syntheses/*.md`, writes `<project>/output/draft-vN.md` with `[[sources/<slug>]]` wikilink citations, and emits `<project>/.metadata/citation-manifest.json` with one `{draft_position, wiki_slug, claim_id}` entry per citation. Persists `writer-outline-vN.json` in Phase 1 before any draft `Write` (F11 anchor). Single-pass (no `Task` in tools list) — no expansion loop, no per-section sharding, English-only, standard density. v0.0.22+. |
| `wiki-verifier` | Phase 6. NEW (no upstream — cogni-claims re-fetches; this verifier does zero network). Reads `<project>/output/draft-vN.md` + `<project>/.metadata/citation-manifest.json` + each cited `wiki/sources/<slug>.md`'s `pre_extracted_claims:` frontmatter, scores every citation as `verbatim` / `paraphrase` / `unsupported` (plus the informational `synthesis` verdict for `claim_id: null` wikilinks — never triggers the revisor), and writes `<project>/.metadata/verify-vN.json` schema `0.1.0`. Single-pass, read-only tools (`Read` / `Write` / `Glob` / `Grep`) — no `WebFetch`, no `WebSearch`, no `Task`. Excerpt match uses `text` + `excerpt_quote`; `excerpt_position` offsets stay as the M9+ context-rendering primitive. v0.0.23+. |
| `revisor` | Phase 6. Forked from `cogni-research/agents/revisor.md` (288 lines) at v0.0.23; point-in-time copy, drift acceptable. Reads `<project>/.metadata/verify-vN.json::deviations[]` + `<project>/output/draft-vN.md` + each deviation's cited page's `pre_extracted_claims:`, rephrases the draft sentence to align with an existing claim or drops the citation (cross-page substitute search deferred), and writes `draft-v{N+1}.md` plus a rewritten `citation-manifest.json` with `draft_version: N+1`. Zero-network: tools list drops `WebSearch` / `WebFetch` / `Bash` from upstream. Also drops upstream expansion mode (`citation_density{}`, placed-evidence ledger, density self-check), Source-Mode Evidence Gathering, arc-preservation discipline, oscillation detection, and confidence-assessment — all upstream-only per `references/absorption-roadmap.md` Slice 4 notes. v0.0.23+. |

## Scripts

| Script | Purpose | LLM? |
|---|---|---|
| `knowledge-binding.py` | `init` / `append-project` / `read` subcommands against `.cogni-knowledge/binding.json` | No (stdlib only) |
| `lineage-stamp.py` | Stamps `derived_from_research: <slug>` into the YAML frontmatter of deposited wiki pages | No (stdlib only) |
| `cycle-guard.py` | Detects direct self-cycles before a wiki-mode re-deposit. Two citation input shapes: **legacy** (cogni-research v0.0.x) walks the candidate's `02-sources/data/src-*.md` for `wiki://<bound-slug>/<page-id>` citations; **citation-manifest** (v0.1.0 inverted pipeline, v0.0.24+ adapter) walks `<project>/.metadata/citation-manifest.json::citations[].wiki_slug`. The fallback is additive — legacy wins when the glob is non-empty; manifest fires when it's empty. The resulting `data.input_shape` is surfaced in the envelope. Both shapes resolve cited pages by the same slug index and check `derived_from_research:` frontmatter. Exit 1 on `cycle_detected`, exit 0 on `clear` or `not_applicable` (web/local mode). | No (stdlib only) |
| `fetch-cache.py` | **v0.1.0 inverted pipeline.** Content-addressed URL→body cache at `.cogni-knowledge/fetch-cache/<sha256>.json`. Subcommands `store` / `fetch` (with `--max-age-days` staleness gate) / `evict` / `stat` / `key`. Negative caching for unavailable URLs; freshness symmetric with positive entries. Atomic temp+rename per entry. v0.0.16-foundation (shipped via PR #269, no version bump); consumed by `source-fetcher` at v0.0.17. | No (stdlib only) |
| `candidate-store.py` | **v0.1.0 inverted pipeline.** File-locked (`fcntl.flock`) merge of parallel `source-curator` output batches into `<project>/.metadata/candidates.json`. Subcommands `init` / `append-batch` / `read`. Dedup key URL-normalized (lowercase scheme+host, trailing-slash-stripped, common tracking params dropped). On collision: higher score wins, earliest `discovered_at` wins, `sub_question_refs[]` unioned, `tier` + `fetch_priority` recomputed. Posix-only. v0.0.17+. | No (stdlib only) |
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
- `knowledge-research` does NOT call `cogni-research:research-setup` directly — that already happens transitively inside `cogni-wiki:wiki-from-research`. Going one level lower would re-implement the same orchestration.
- `knowledge-resume` does NOT compute wiki health. `wiki-resume` already calls `wiki-health` automatically as of cogni-wiki v0.0.27.

## Lineage stamping

`cogni-wiki:wiki-ingest --discover research:<slug>` deposits per-sub-question pages and creates the directory `<wiki-root>/raw/research-<slug>/`. The directory itself records the lineage implicitly (which raw files seeded which page), but Phase 2's cycle-guard needs a queryable `derived_from_research: <slug>` field in the page YAML frontmatter to detect circular evidence without a filesystem walk. `lineage-stamp.py` adds that field, idempotently.

The script:

1. Globs `<wiki-root>/wiki/**/*.md`.
2. For each page, reads the YAML `sources:` field. If any `sources[]` entry path contains `raw/research-<slug>/`, the page is derived from that research project.
3. If the page already has `derived_from_research: <slug>`, skip (idempotent). Otherwise, insert the field into the frontmatter.

Only the frontmatter changes — page bodies are never touched.

## Conventions

- Skill names: `knowledge-*` (generic skill names like `setup`, `research`, `resume` MUST be prefixed per `../CLAUDE.md` §"Contributing").
- Skill frontmatter: `name`, `description`, `allowed-tools` — same shape as cogni-wiki/cogni-research skills.
- Script CLI: `python3 scripts/<name>.py --action ...`, JSON envelope output.
- Path conventions: knowledge bases default to `<cwd>/<knowledge-slug>/` (matching `cogni-wiki/{slug}/`).
- Versioning: bump patch on any skill/script change; mirror in `marketplace.json` (`../CLAUDE.md` §"Version Management").

## Future phases

Phases 1-3 shipped (v0.0.1 → v0.0.11), 2/3 follow-up debt cleared at v0.0.13, Phase 4 alpha completed at v0.0.15 with a **GO** recommendation. **Phase 5 is in flight as one big v0.1.0 inverted-pipeline clean break** — see `references/absorption-roadmap.md` for the canonical 12-milestone (M1–M12) table and current status. The plugin stays at `0.0.x`/maturity `incubating` until M12 ships the alpha re-run + version bump to 0.1.0 + maturity flip in a single landing. Phase 6 (cogni-research deprecation cleanup) follows Phase 5.

Inverted-pipeline progress: M1 (plumbing) + M2-script (fetch-cache.py) shipped at PR #269 with no version bump. M2-finish (`source-fetcher` agent) + M3 (`source-curator` fork) + M4 (`knowledge-plan` / `knowledge-curate` / `knowledge-fetch` skills + `candidate-store.py`) shipped at v0.0.17. M4 end-to-end smoke shipped docs-only at v0.0.19 (GO for Slice 2). **M5 (`claim-extractor` fork + `source-ingester` agent) + M6 (`knowledge-ingest` skill) shipped at v0.0.20**, alongside #275 (PDF detection in source-fetcher) and #276 (`cobrowse_unavailable` reason). PDF Read-loop past page 20 shipped at v0.0.21 (#278). **M7 (`wiki-composer` agent + `knowledge-compose` skill) shipped at v0.0.22 — Slice 3** with the F11 outline-recovery contract preserved through the fork; the writer now reads the populated wiki and emits `[[sources/<slug>]]`-cited drafts plus a citation manifest M8's verifier will consume. **M8 (`wiki-verifier` agent + `revisor` fork + `knowledge-verify` skill) shipped at v0.0.23 — Slice 4**; the citation manifest is now consumed by a zero-network claim-alignment pass against each cited page's `pre_extracted_claims:` (verifier verdicts: `verbatim` / `paraphrase` / `unsupported` / `synthesis`), with a max-2-iteration revisor loop on `unsupported` deviations — the structural cost win versus cogni-claims (target < 5 min vs 20–30 min baseline). **M9 (`knowledge-finalize` skill + `cycle-guard.py` v0.1.0 adapter) shipped at v0.0.24 — Slice 5**; the verified draft is now deposited as `<wiki>/syntheses/<synthesis-slug>.md` with `type: synthesis` + `derived_from_research: <project-slug>` + an auto-generated `## References` list. Three cogni-wiki helpers (`wiki_index_update.py` + `config_bump.py` + `rebuild_context_brief.py`) run at script level so the new page is discoverable + the wiki health stays consistent. `cycle-guard.py` gained a strict additive fallback that reads `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty — direct-cycle detection now works on v0.1.0 projects, and the new envelope field `data.input_shape` signals which path ran. The inverted-pipeline loop closes here — future `knowledge-compose` runs read `wiki/syntheses/*.md` as prior cross-source framing. **M10a (read-side adapters) shipped at v0.0.25** — `knowledge-query` / `knowledge-dashboard` / `knowledge-resume` now read inverted-pipeline state via the new `pipeline-summary.py` (`project` + `cache-health`), and all three drop their cogni-research pre-flight probe to cogni-wiki-only (honouring the clean break ahead of M11's archive). Next slice: M10b (rewrite `knowledge-refresh --mode push` on the seven-phase chain so it stops dispatching `knowledge-research`; + cogni-wiki log-enum cleanup for the `compose`/`verify`/`finalize` prefixes).
