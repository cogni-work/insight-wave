# cogni-knowledge

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-knowledge:knowledge-resume` for project status and next-step guidance — whether you're starting fresh or returning to an in-progress project.

**Wiki-first research that compounds — and stays honest.** Every shipped deep-research tool today produces a document and loses the underlying knowledge to chat history. cogni-knowledge inverts that posture: a research run *binds* to a named knowledge base, deposits its findings into a persistent wiki, and the next run reads from the same wiki before going to the web. Knowledge gets denser with every project — instead of starting from zero each time — and every citation is verified against the cited source's pre-extracted claims (zero network), so the base you build is one you can trust.

cogni-knowledge is **self-contained**: it bundles its own wiki engine (the formerly-separate cogni-wiki, vendored under `scripts/vendor/cogni-wiki/` and resolved vendored-first), so it dispatches zero external wiki-plugin skills. The inverted pipeline forks the agents it needs locally, and the only new state cogni-knowledge owns is a `binding.json` that records "this wiki is the knowledge base for topic area X, and these research projects have contributed to it."

## Why this exists

| Problem | One-shot research tools | cogni-knowledge |
|---|---|---|
| Where do findings go after the report ships? | Lost to chat history | Filed in a persistent wiki |
| Second research run on a related topic | Starts from zero | Reads the wiki first |
| Cross-project synthesis | Manual; copy-paste between sessions | Automatic — wiki accumulates and interlinks |
| Provenance of a stale fact | Forgotten by next session | `derived_from_research: <slug>` traces every page back to the run that filed it |
| Trust in a cited number | Hope the model quoted the source right | Every citation checked against the source's pre-extracted claims (zero network); unsupported ones auto-revise |
| Refresh stale claims | Manual re-research | `knowledge-refresh` (push-mode re-researches stale topics via the inverted pipeline) |

## What it is

**IS:** A self-contained, wiki-first research engine built on two pillars — **compounding** (every run deposits a verified synthesis into a persistent wiki the next run reads first) and **citation-consistent verification** (every claim is checked against its cited source's ingest-time pre-extracted claims, zero network). A knowledge base = a vendored wiki + a `binding.json` manifest; the wiki engine ships inside the plugin (`scripts/vendor/cogni-wiki/`), not as an external install. Every inverted-pipeline run deposits a verified synthesis into that wiki and is recorded in the binding; the next run reads what previous runs filed before going to the web.

**DOES:** the inverted pipeline — `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-distill` (Phase 4.5, optional) → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize` — plus the read-side skills (`knowledge-setup`, `knowledge-resume`, `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh`) and stdlib scripts (`knowledge-binding.py`, `cycle-guard.py`, `fetch-cache.py`, `candidate-store.py`, `citation-store.py`, `concept-store.py`, `question-store.py`, `ingest-integrity.py`, `contradiction-ingest-store.py`, `pipeline-summary.py`, `verify-store.py`, `wiki-coverage.py`, `build_open_questions_payload.py`). Sources are fetched once before composition; **`knowledge-distill` deduplicates claims and grows a `concept`/`entity` web that successive runs enrich rather than duplicate** (the compounding mechanism, #336); **`knowledge-verify` scores every citation against the cited source's pre-extracted claims — zero network, no live re-fetch — and the revisor loop auto-revises unsupported ones (capped at 2 passes); three fail-soft contradiction tripwires (`source-contradictor` at ingest, `wiki-contradictor` at synthesis-write, plus a synthesis-vs-prior-syntheses pass) surface disagreements without gating the run.** `knowledge-finalize` closes the loop by depositing a synthesis a future run can read. The legacy v0.0.x research+report chain is archived under `_archive/`.

**MEANS for you:** the work compounds. Run research on EU AI Act Article 6 today; tomorrow's run on foundation-model obligations reads what you already filed. Query the base by slug with `knowledge-query`; visualize it with `knowledge-dashboard`; keep it fresh with `knowledge-refresh`. No vector store, no embeddings — just markdown that compounds.

## What it does

1. **Setup** a knowledge base — a vendored wiki + a `binding.json` manifest that records every research project deposited
2. **Plan** a topic into 3–7 sub-questions with per-sub-question candidate domains (no web by default; an optional, fail-soft preliminary scoping search engages only inside topic-framing on vague topics / `--frame`) — Phase 1 of the inverted pipeline
3. **Curate** candidate sources per sub-question via WebSearch + scoring, then fetch each survivor's body via WebFetch into a shared fetch-cache (Option B — the fetch rides the parallel curators) — Phase 2
4. **Fetch** assembles the fetch-manifest from the curators' results; cobrowse recovery of WebFetch misses via the `claude-in-chrome` extension is opt-in (`--cobrowse`) — Phase 3
5. **Ingest** fetched sources into the wiki as `type: source` pages with `pre_extracted_claims:` frontmatter — Phase 4 (the wiki populated before any draft runs)
6. **Distill** the source claims into `type: concept` / `type: entity` pages that successive runs enrich (claims appended, source backlinks unioned) instead of duplicating, with deterministic **claim-level dedup** at deposit — Phase 4.5 (optional, fail-soft; the compounding mechanism, #336)
7. **Compose** the draft report by reading the populated wiki (concept/entity pages as framing *and* citable cross-source evidence — #344), with clickable numbered `[N]` inline citations (localized per the project's `output_language`) + a parallel citation manifest; `[[sources/<slug>]]` wikilinks are confined to the reference list — Phase 5
8. **Verify** every cited claim against the cited page's `pre_extracted_claims` (zero network) and loop with the revisor on `unsupported` deviations, capped at 2 iterations — Phase 6
9. **Finalize** the verified draft as `wiki/syntheses/<slug>.md` with `type: synthesis` + `derived_from_research:` lineage, refuse self-citing loops via `cycle-guard.py` (now with a citation-manifest fallback), update the wiki index + entries_count + context_brief, and append the project to the binding — Phase 7 (closes the inverted-pipeline loop)
10. **Resume** project status — deposited projects, wiki health, suggested next action
11. **Query** the bound base — natural-language question answered natively on the vendored wiki engine (`wiki-grounding.py`)
12. **Dashboard** the bound base — HTML overview with a binding overlay sidecar
13. **Refresh** stale pages — push-mode re-runs the inverted pipeline on stale topics; opt-in `--resweep` re-verifies cited claims against live sources
14. **Refresh-synthesis** one existing synthesis from a newly-landed source — *union-not-rederive*: fold the new source into the synthesis's existing evidence base (never thinning it) and re-run compose → verify → finalize, resolving a flagged `refresh_candidates[]` entry
15. **Index** the bound base — rebuild the curated root index + all per-type sub-indexes on demand, or migrate an existing old-structure wiki to the curated layout (dry-run default with a staged content-diff surface, `--apply` to execute)

See `references/absorption-roadmap.md` for the inverted-pipeline plan (M1–M12 shipped; the plugin is now on the Released 1.x line, with concise-by-default `executive` output the resting state). The legacy v0.0.x `knowledge-research` / `knowledge-report` chain is archived under `_archive/` — see `_archive/README.md`.

## What it means for you

- **Stop producing throwaway reports — start building knowledge that compounds.** Each run deposits its verified findings into a persistent, interlinked wiki you refine and re-query, and the next project reads what you already filed before going to the web. The deliverable isn't a document that ages out in a folder — it's a knowledge base that gets denser, more trusted, and more useful with every project.
- **Ship a report whose every citation is backed, not hopeful — fact-checking is a first-class pillar, not an afterthought.** Every claim is held to a **citation-consistent** standard: scored against the cited source's ingest-time pre-extracted claims with zero network calls, with the revisor auto-revising unsupported statements (capped at 2 passes) and three contradiction tripwires flagging sources that disagree. This is consistency against what was ingested — deliberately distinct from `cogni-claims`, which re-fetches live source URLs — so every numbered `[N]` marker traces to evidence already on the page, in seconds, not to a model's recollection.
- **Defend any fact in one lookup.** A `derived_from_research:` lineage stamp on every page points a stale or disputed claim straight back to the run that filed it — no archaeology through old chat logs when a number gets challenged weeks later.
- **Own your knowledge base as plain markdown.** No vector store, no embeddings, no lock-in — the whole base is Obsidian-browsable markdown you can read, grep, edit, and version in git. Inspect it with `knowledge-dashboard`, ask it in natural language with `knowledge-query`, and keep it current with `knowledge-refresh`.
- **Read the answer in seconds, not skim a wall of text.** New projects are concise by default — `executive` density front-loads the bottom line (BLUF + Minto Pyramid, a document-level Key Takeaways block, a ~2000-word ceiling) so a busy reader absorbs the findings at a glance; opt into the long-form, exhaustively-cited document with `--prose-density standard --target-words 4000`. (Conciseness is a supporting benefit — the compounding knowledge base above is still the point.)

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note**: cogni-knowledge bundles a vendored wiki engine (under `scripts/vendor/cogni-wiki/`, resolved vendored-first) — there is no separate plugin to install. The inverted pipeline forks the agents it needs locally and runs fully self-contained. The legacy v0.0.x research+report chain is archived under `_archive/`.

## Quick start

```
/cogni-knowledge:knowledge-resume --knowledge-slug eu-ai-act  # ← entry point: status + next step
/cogni-knowledge:knowledge-setup --knowledge-slug eu-ai-act --knowledge-title "EU AI Act knowledge base"
/cogni-knowledge:knowledge-plan --knowledge-slug eu-ai-act --topic "EU AI Act Article 6 high-risk systems"
/cogni-knowledge:knowledge-curate --knowledge-slug eu-ai-act --project-path ...
/cogni-knowledge:knowledge-fetch --knowledge-slug eu-ai-act --project-path ...
/cogni-knowledge:knowledge-ingest --knowledge-slug eu-ai-act --project-path ...
/cogni-knowledge:knowledge-compose --knowledge-slug eu-ai-act --project-path ...
/cogni-knowledge:knowledge-verify --knowledge-slug eu-ai-act --project-path ...
/cogni-knowledge:knowledge-dashboard --knowledge-slug eu-ai-act --open yes
/cogni-knowledge:knowledge-query --knowledge-slug eu-ai-act --question "what does the wiki say about foundation models?"
```

Or just describe what you want in natural language:

- "Set up a new knowledge base for EU AI Act compliance"
- "Plan a research project on Article 6 high-risk systems"
- "What does my wiki say about foundation model obligations?"
- "Show me the dashboard for the EU AI Act knowledge base"
- "Refresh the stale pages in my wiki"

The second project reads the wiki the first one deposited — that is the compounding loop. The `dashboard` and `query` skills let you inspect and ask the accumulated base. Use `knowledge-refresh --mode push` later to keep stale pages fresh.

## Data model

One new artifact: `<knowledge-base>/.cogni-knowledge/binding.json`, sibling to the wiki's `.cogni-wiki/config.json`. It records:

- `knowledge_slug`, `knowledge_title`
- `wiki_path` — absolute path to the bound wiki (the wiki's own slug is read live from `<wiki_path>/.cogni-wiki/config.json` so it cannot drift)
- `research_projects[]` — one entry per deposited run: `slug`, `deposited_at`, `report_path`, `report_source`
- `topic_lineage` — `covered_themes[]` and `open_themes[]` (populated as the base grows)

All other state lives in the wiki itself: wiki pages under `wiki/`, research artifacts in `cogni-research-<slug>/`. cogni-knowledge owns nothing else.

## How it works

```
knowledge-setup
  → native scaffold (mkdir wiki skeleton + .cogni-wiki/config.json)
  → knowledge-binding.py --init (writes binding.json)

inverted pipeline (knowledge-plan → … → knowledge-finalize) --knowledge-slug X --topic T
  → knowledge-plan      decompose T into 3–7 sub-questions → plan.json
  → knowledge-curate    wiki-coverage.py (read-before-web: which sub-questions the wiki already covers) → source-curator per sub-question (narrowed WebSearch + score + WebFetch bodies → shared fetch-cache) → candidates.json
  → knowledge-fetch     build fetch-manifest.json from the curators' results; opt-in cobrowse reconcile of WebFetch misses
  → knowledge-ingest    source-ingester writes wiki/sources/<slug>.md with pre_extracted_claims:; advisory tripwire: source-contradictor scores new source claims vs the base's existing claims (#431)
  → knowledge-distill   (optional) concept-distiller proposes → concept-store.py merges wiki/{concepts,entities}/<slug>.md (claim-dedup, enriched across runs)
  → knowledge-compose   wiki-composer reads the populated wiki (concepts as framing + citable evidence) → draft-vN.md + citation-manifest.json
  → knowledge-verify    wiki-verifier scores citations vs pre_extracted_claims / distilled_claims (zero network); revisor loop on unsupported
  → knowledge-finalize  cycle-guard.py → wiki/syntheses/<slug>.md (derived_from_research:) → index/entries_count/context_brief → knowledge-binding.py --append-project; advisory tripwires: wiki-contradictor (#335) + wiki-reviewer structural score (#309 P1.1)

knowledge-query --knowledge-slug X --question Q
  → wiki-grounding.py rank  (native index-first query against the bound wiki)
  → footer: knowledge base + deposit count

knowledge-dashboard --knowledge-slug X
  → vendored render_dashboard.py --wiki-root <bound>  (writes wiki-dashboard.html)
  → writes knowledge-overlay.md sidecar  (binding view: deposits + lint claim_drift)

knowledge-refresh --knowledge-slug X --mode push
  → vendored lint_wiki.py --wiki-root <bound>  (find stale_page / stale_draft)
  → multi-select + batch confirm  (which topics, then yes/no to launch)
  → per selected topic, sequentially: the seven-phase inverted pipeline
       knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest
         → knowledge-distill (optional) → knowledge-compose → knowledge-verify → knowledge-finalize
```

The deposited synthesis pages are now part of the wiki and visible to the next `knowledge-compose` run, which reads `wiki/syntheses/*.md` as prior cross-source framing — the compounding loop.

## Components

| Component | Type | Description |
|-----------|------|-------------|
| knowledge-resume | Skill | Show status of a cogni-knowledge base — slug, bound wiki, deposited projects, wiki health, next-step guidance |
| knowledge-setup | Skill | Bootstrap a cogni-knowledge base — wiki + a binding manifest that records every research project deposited |
| knowledge-plan | Skill | Phase 1 of the v0.1.0 inverted pipeline — decompose a topic into 3–7 sub-questions with candidate domains + a thematic `theme_label` per sub-question |
| knowledge-curate | Skill | Phase 2 — resolve wiki coverage once (`wiki-coverage.py`, read-before-web #309) then fan out one `source-curator` per sub-question (WebSearch + score + WebFetch bodies); merge candidates (each with a `fetch` sub-object) into `candidates.json` |
| knowledge-fetch | Skill | Phase 3 — build `fetch-manifest.json` from the curators' fetch results; opt-in (`--cobrowse`) `source-fetcher` reconcile of WebFetch misses |
| knowledge-ingest | Skill | Phase 4 — per-source `source-ingester` writes `wiki/sources/<slug>.md` with `pre_extracted_claims` frontmatter; writes curated backlinks (`backlink_audit.py --apply-plan`) and files each source under its sub-question's thematic index category |
| knowledge-distill | Skill | Phase 4.5 (optional, fail-soft, #336) — `concept-distiller` proposes recurring `concept`/`entity` pages; `concept-store.py` create-or-merges them under a lock with **claim-level dedup**, so successive runs enrich the concept web rather than duplicate it (the compounding mechanism); an optional cross-lingual pass merges DE↔EN twin claims on mixed-language bases (#345) |
| knowledge-compose | Skill | Phase 5 — `wiki-composer` reads the populated wiki (concept/entity pages as framing *and* citable cross-source evidence — #344) and emits `draft-vN.md` + a `[[sources/<slug>]]` citation manifest |
| knowledge-verify | Skill | Phase 6 — zero-network claim alignment, fanned out across parallel `wiki-verifier` shards (`verify-store.py`) + revisor loop on `unsupported` deviations (max 2 iterations) |
| knowledge-finalize | Skill | Phase 7 — deposit the verified draft as `wiki/syntheses/<slug>.md` with `derived_from_research:` lineage + bare `[[<slug>]]` reference backlinks; cycle-guard, index update, entries_count bump, context_brief rebuild, binding append, then a `wiki-lint --fix=all` + `wiki-health` conformance gate (closes the inverted-pipeline loop) |
| knowledge-query | Skill | Ask a question against the bound base — natural-language query answered natively on the vendored wiki engine (`wiki-grounding.py rank`, index-first) |
| knowledge-dashboard | Skill | Render an HTML overview with a `knowledge-overlay.md` sidecar listing deposited projects + lint claim_drift |
| knowledge-refresh | Skill | Self-healing — push-mode auto-researches stale topics via the inverted pipeline; opt-in `--resweep` re-verifies cited claims against live sources |
| knowledge-index | Skill | Rebuild the curated root index + per-type sub-indexes on demand, or migrate an existing pre-curated-layout wiki (control files into `wiki/meta/`, overview folded into the index intro, flat root split into root-map + sub-indexes, schema bump) — dry-run preview first, `--apply` to execute |
| knowledge-refresh-synthesis | Skill | Update ONE existing synthesis from a newly-landed source (*union-not-rederive*): unions the source into the synthesis's existing project ingest-manifest rather than re-deriving via wiki-grounding (which thins the page), then orchestrates `knowledge-compose` → `knowledge-verify` → `knowledge-finalize --overwrite`; resolves a `binding.json::refresh_candidates[]` entry flagged by `synthesis-impact.py` |
| knowledge-ingest-source | Skill | Standalone single-source ingest — deposit ONE source (web/PDF URL, local `.docx`/`.html`/`.txt`, pasted text, local PDF, or interview note) directly into the bound wiki with no research run; reuses the research write path to land one `wiki/sources/<slug>.md` (or `wiki/interviews/<slug>.md`) page |
| knowledge-update | Skill | Manually curate a single page — revise an existing wiki page when knowledge changed; shows the diff before writing, requires a source citation per new claim, and sweeps related pages for now-stale statements |
| knowledge-prefill | Skill | Seed the base with curated foundation concept pages (Porter's Five Forces, JTBD, MECE, Pyramid, OODA, SWOT, BCG, Value Chain, Lean Canvas, Wardley, Double Diamond) on the vendored prefill engine — no cogni-wiki install needed |
| knowledge-lint | Skill | Semantic lint — surface stale pages/drafts, claim drift, and broken reverse links; `--fix` repairs the mechanical classes |
| knowledge-health | Skill | Read-only structural health check — page/link/schema integrity plus entries-count and claim drift for the bound wiki |
| source-curator | Agent | Phase 2 fork — reads its sub-question's wiki-coverage verdict and narrows search on already-covered topics (read-before-web #309); per-sub-question WebSearch + scoring + Phase-4 WebFetch body-pull (incl. the PDF Read-loop) through `fetch-cache.py`; emits a batch JSON array (each candidate carries a `fetch` sub-object) |
| source-fetcher | Agent | Phase 3 NEW — cobrowse-only recovery of WebFetch misses via the `claude-in-chrome` extension; reads/writes through `fetch-cache.py` |
| claim-extractor | Agent | Phase 4 fork — reads one cached source body + sub-question refs, emits a JSON array of `{id, text, excerpt_quote, …}` |
| source-ingester | Agent | Phase 4 NEW — reads cached body, dispatches `claim-extractor`, writes `wiki/sources/<slug>.md` atomically |
| source-contradictor | Agent | Phase 4 Step 4.6 NEW (#431) — zero-network ingest-time scorer comparing this run's freshly-ingested source claims against the related question group's existing claims (prior-run sources + the question node) and each other; emits per-group fragments merged into `contradiction-ingest.json` (observability-only, never gates ingest) |
| concept-distiller | Agent | Phase 4.5 NEW (#336) — reads the run's source-claim bundle + an existing-slug index, clusters recurring facts into `concept`/`entity`/`summary`/`learning` proposals, writes a raw-text records file (never builds JSON/YAML, never computes slugs, never decides dedup) |
| concept-summary-narrator | Agent | Phase 4.5 Step 6.7 NEW (#341) — re-narrates the `## Summary` of each updated distilled page from its merged claims so the wiki compounds narratively; raw-text records, touches only the summary block |
| answer-distiller | Agent | Phase 4.5 Step 6.9 NEW (#432) — the constrained per-question sibling of `concept-distiller`; selects the claims that answer each `type: question` node and writes a raw-text answer-records file `question-store.py answer-merge` splices into a citable `answer_claims` block |
| cross-lingual-claim-merger | Agent | Phase 4.5 Step 6.6 NEW (#345) — confirms which script-flagged DE↔EN candidate pairs are the same fact in two languages; raw-text `merge:` records the orchestrator applies via `concept-store.py crossmerge` (may only confirm, never invents a merge) |
| wiki-composer | Agent | Phase 5 fork — reads wiki pages + prior syntheses, writes `draft-vN.md` with clickable numbered `[N]` citations (localized per `output_language`) plus a raw-text citation-records file the orchestrator serializes into the manifest via `citation-store.py` (#325) |
| wiki-verifier | Agent | Phase 6 NEW — scores each citation's verbatim `draft_sentence` as `verbatim` / `paraphrase` / `unsupported` / `synthesis` (zero network, never re-tokenizes; shardable via `CITATIONS_PATH`) |
| revisor | Agent | Phase 6 fork — re-points unsupported sentences to a covering on-page claim before dropping the citation (no new fetches) |
| wiki-contradictor | Agent | Phase 7 Step 10.6 NEW (#335) — zero-network scorer comparing the just-deposited synthesis against each cited source's claims; emits a `contradictor-vN.json` observability report (no auto-resolution) |
| wiki-reviewer | Agent | Phase 7 Step 10.7 NEW (#309 P1.1) — zero-network structural-quality scorer rating the draft on 5 weighted dimensions (completeness/coherence/source-diversity/depth/clarity) with a citation-density gate; emits an advisory `structural-review-vN.json` (no auto-fix, never blocks) |
| portal-narrator | Agent | Phase 7 sub-step 3.5 NEW (#491) — (re)writes the engine-owned per-theme lead-ins in `wiki/index.md` + the overview narrative so the curated Knowledge Portal compounds narratively; raw-text records, never touches a human (non-sentineled) lead-in or any bullet |
| concepts-outliner | Agent | Phase 7 sub-step 3.6 NEW — the concepts analog of `portal-narrator`; (re)writes the per-theme lead-ins of the grouped `/concepts` domain map (`wiki/concepts/index.md`) so it reads as a domain guide, never a bullet dump (the deterministic `concepts_index.py` renderer owns the bullets) |

## Architecture

```
cogni-knowledge/
├── .claude-plugin/plugin.json    Plugin manifest
├── README.md                     Plugin documentation
├── CLAUDE.md                     Developer guide
├── CHANGELOG.md                  Version history
├── LICENSE                       AGPL-3.0
├── _archive/                     Retired v0.0.x research+report chain (see _archive/README.md)
├── agents/                       16 forked + new pipeline agents
├── references/                   20 framework + design docs
├── scripts/                      27 utility scripts (binding, synthesis-impact, cycle-guard, fetch-cache, candidate-store, citation-store, verify-store, wiki-grounding, wiki-coverage, wiki-source-manifest, concept-store, question-store, ingest-integrity, contradiction-ingest-store, pipeline-summary, build_open_questions_payload; vendored wiki-engine: control-path, root_index, sub_index, concepts_index, perspectives_index, overview_update, pdf-extract; one-shot migrators: migrate-layout, migrate-question-index, reclassify-person-entities, backfill_concepts_index) + _knowledge_lib helper
├── skills/                       20 knowledge-* skills
└── tests/                        Contract tests (one per phase)
```

The plugin owns a vendored wiki engine (`scripts/vendor/cogni-wiki/`, resolved vendored-first) and dispatches zero external wiki-plugin skills — the wiki is the core data model, not a separate plugin you install. Forked agents under `agents/` are point-in-time copies and the bound wiki is the only evidence source for composition, verification, and finalization. The legacy v0.0.x chain (`knowledge-research` / `knowledge-report`) is archived under `_archive/`.

## Dependencies

- `cogni-wiki` — **not an external dependency**: the wiki engine is vendored under `scripts/vendor/cogni-wiki/` and resolved vendored-first, so the whole inverted pipeline (ingest, query, dashboard, lint, setup) runs with no separate `cogni-wiki` install.
- `cogni-workspace` — provides the market registry, read via `cogni-workspace/scripts/get-market-config.py` for localized (bilingual + per-market authority) search. `knowledge-curate` resolves the market config **once** in skill context and threads it to its `source-curator` agents (#304, v0.1.5) — when a market is configured it **fails loudly** if the config can't be resolved or resolves to the unlocalized `_default`, rather than silently degrading per-curator. `knowledge-plan` reads the same helper for its candidate-domain suggestions.

### Optional dependencies

These are pure enhancements — the plugin runs without them and degrades to an honest outcome. Absence is never a hard error. They are not vendored; provision them with `/cogni-workspace:manage-workspace`, or install directly.

| Package | Enables | When it's absent | Install |
|---------|---------|------------------|---------|
| `pypdf` | Text-layer PDF recovery on poppler-less hosts — when the Read tool can't rasterize a saved PDF, the source-curator extracts the text layer instead of dropping the source as `pdf_render_unavailable`. | The source is recorded `pdf_render_unavailable` (today's behavior), operator-actionable. | `/cogni-workspace:manage-workspace`, or `pip install pypdf` |
| `markitdown` | `.docx` / office-format normalization for `knowledge-ingest-source` local-file ingest. | `.docx` ingest returns an honest error; stdlib formats (`.txt`/`.html`/`.pdf`) are unaffected. | `pip install markitdown` |

## Custom development

Adding a skill: every skill delegates. If you find yourself writing a new agent or duplicating the vendored wiki-engine logic, the right answer is almost always to push the change upstream and re-delegate. See `references/delegation-contract.md` for the contract.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
