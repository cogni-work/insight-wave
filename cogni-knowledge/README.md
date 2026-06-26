# cogni-knowledge

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-knowledge:knowledge-resume` for project status and next-step guidance — whether you're starting fresh or returning to an in-progress project.

A wiki-first research engine on an inverted pipeline: each run deposits verified findings into a persistent wiki the next run reads first — the compounding-knowledge core of insight-wave.

> **Multi-market & multilingual.** Bind a market to your knowledge base and research runs bilingually (local language + English) against curated regional authority sources — European-first across DACH/DE/FR/IT/ES/NL/PL plus UK/US, with 16+ output languages. See [Supported markets & languages](../cogni-workspace/README.md#supported-markets--languages).

## Why this exists

| Problem | One-shot research tools | cogni-knowledge |
|---|---|---|
| Where do findings go after the report ships? | Lost to chat history | Filed in a persistent wiki |
| Second research run on a related topic | Starts from zero | Reads the wiki first |
| Cross-project synthesis | Manual; copy-paste between sessions | Automatic — wiki accumulates and interlinks |
| Provenance of a stale fact | Forgotten by next session | `derived_from_research: <slug>` traces every page back to the run that filed it |
| Trust in a cited number | Hope the model quoted the source right | Every citation checked against the source's pre-extracted claims (zero network); unsupported ones auto-revise |
| Refresh stale claims | Manual re-research | `knowledge-refresh` (push-mode re-researches stale topics via the inverted pipeline) |

Every report you ship discards the research underneath it — so the next related question starts from zero, and the same web crawl is paid for again and again.

## What it is

A self-contained, wiki-first research engine built on two pillars: compounding — research accumulates in a persistent wiki instead of dying in chat history — and citation-consistent verification, where every claim is checked against its cited source with zero network calls. A knowledge base is a vendored wiki plus a `binding.json` manifest; the wiki engine ships inside the plugin, so there is nothing external to install.

## What it does

1. **Setup** a knowledge base — a vendored wiki plus a `binding.json` manifest that records every research project deposited
2. **Plan** a topic into 3–7 sub-questions with candidate domains (no web by default; an optional, fail-soft scoping search engages only on vague topics / `--frame`)
3. **Curate** candidate sources per sub-question via web search and scoring, fetching each survivor's body into a shared cache
4. **Fetch** assembles the fetch manifest from the curators' results; cobrowse recovery of misses via the `claude-in-chrome` extension is opt-in (`--cobrowse`)
5. **Ingest** fetched sources into the wiki as source pages with their pre-extracted claims — the wiki is populated before any draft runs
6. **Distill** source claims into concept and entity pages that successive runs enrich rather than duplicate, with claim-level dedup at deposit (optional, fail-soft — the compounding mechanism)
7. **Compose** the draft report from the populated wiki, with clickable numbered citations (localized per the project's output language) and a parallel citation manifest
8. **Verify** every cited claim against the cited page's pre-extracted claims (zero network) and loop with the revisor on unsupported deviations
9. **Finalize** the verified draft as a synthesis page with `derived_from_research:` lineage, refusing self-citing loops, updating the wiki index, and recording the project in the binding
10. **Resume** project status — deposited projects, wiki health, suggested next action
11. **Query** the bound base — a natural-language question answered natively on the vendored wiki engine
12. **Dashboard** the bound base — an HTML overview with a binding overlay sidecar
13. **Refresh** stale pages — re-research stale topics; opt-in `--resweep` re-verifies cited claims against live sources
14. **Refresh-synthesis** one existing synthesis from a newly-landed source — fold the new source into its existing evidence base (never thinning it) and re-compose, verify, and finalize
15. **Index** the bound base — rebuild the curated root index and per-type sub-indexes on demand, or migrate an existing old-structure wiki to the curated layout

See `references/absorption-roadmap.md` for the inverted-pipeline design. The plugin is on the Released 1.x line, with concise-by-default `executive` output the resting state; the older `knowledge-research` / `knowledge-report` chain lives in `_archive/` — see `_archive/README.md`.

## What it means for you

- **Build knowledge that compounds, not throwaway reports.** Each run deposits verified findings into a persistent wiki the next project reads before going to the web — so the base gets denser and more useful with every project instead of starting from zero.
- **Trust every citation, not hope it's right.** Each `[N]` marker is scored against its source's pre-extracted claims with zero network calls; the revisor auto-revises unsupported statements in up to 2 passes.
- **Defend any fact in one lookup.** A `derived_from_research:` lineage stamp points a disputed claim straight back to the run that filed it — no archaeology through old chat logs.
- **Own your base as plain markdown.** No vector store, no embeddings, no lock-in — the whole base is Obsidian-browsable markdown you read, grep, edit, and version in git.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note**: cogni-knowledge bundles a vendored wiki engine (under `scripts/vendor/cogni-wiki/`, resolved vendored-first) — there is no separate plugin to install. The pipeline runs its own local agents, fully self-contained. The older research+report chain lives in `_archive/`.

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

## Try it

Set up a base, then run one research project end to end:

> Run `/cogni-knowledge:knowledge-setup --knowledge-slug eu-ai-act --knowledge-title "EU AI Act knowledge base"`

This scaffolds the wiki and writes `eu-ai-act/.cogni-knowledge/binding.json`. Now research a topic:

> Run `/cogni-knowledge:knowledge-plan --knowledge-slug eu-ai-act --topic "EU AI Act Article 6 high-risk systems"`

then chain `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`. The verified synthesis lands at:

```
eu-ai-act/wiki/syntheses/<slug>.md
```

with a `derived_from_research:` lineage stamp and every citation scored against its source. Ask the accumulated base in plain language:

> Run `/cogni-knowledge:knowledge-query --knowledge-slug eu-ai-act --question "what does the wiki say about foundation models?"`

The answer cites `[[slug]]` pages already on the wiki — and the next research run reads them before touching the web. Open the wiki folder in Obsidian and you can browse every synthesis, source, and concept page as linked markdown, following citations back to where each claim came from. Each run you do compounds the base rather than starting over, so coverage deepens and repeat questions get faster, better-grounded answers.

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
  → knowledge-ingest    source-ingester writes wiki/sources/<slug>.md with pre_extracted_claims:; advisory tripwire: source-contradictor scores new source claims vs the base's existing claims
  → knowledge-distill   (optional) concept-distiller proposes → concept-store.py merges wiki/{concepts,entities}/<slug>.md (claim-dedup, enriched across runs)
  → knowledge-compose   wiki-composer reads the populated wiki (concepts as framing + citable evidence) → draft-vN.md + citation-manifest.json
  → knowledge-verify    wiki-verifier scores citations vs pre_extracted_claims / distilled_claims (zero network); revisor loop on unsupported
  → knowledge-finalize  cycle-guard.py → wiki/syntheses/<slug>.md (derived_from_research:) → index/entries_count/context_brief → knowledge-binding.py --append-project; advisory tripwires: wiki-contradictor + wiki-reviewer structural score

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

The order is the design. `knowledge-curate` resolves wiki coverage *before* searching the web (read-before-web), so a sub-question the base already answers narrows its search instead of re-crawling. Sources are ingested into the wiki *before* any draft runs — claims are pre-extracted at ingest time, which is what later lets verification score every citation with zero network calls. Composition reads only the populated wiki, so the draft can never cite a source the base hasn't filed. Verification runs after composition because a citation can only be checked once it exists, and the revisor loop repoints or rephrases unsupported sentences before finalize deposits anything.

Two design choices make the base compound rather than merely accumulate. The optional Phase 4.5 distillation merges recurring facts into concept and entity pages that successive runs enrich instead of duplicate. And finalize stamps each synthesis with `derived_from_research:` lineage and deposits it into `wiki/syntheses/` — where the next `knowledge-compose` run reads it as prior cross-source framing. The deposited synthesis pages are now part of the wiki and visible to that next run, closing the loop.

## Components

| Component | Type | Description |
|-----------|------|-------------|
| knowledge-resume | Skill | Show status of a cogni-knowledge base — slug, bound wiki, deposited projects, wiki health, next-step guidance |
| knowledge-setup | Skill | Bootstrap a cogni-knowledge base — wiki + a binding manifest that records every research project deposited |
| knowledge-plan | Skill | Decompose a topic into 3–7 sub-questions with candidate domains and a thematic `theme_label` per sub-question |
| knowledge-curate | Skill | Resolve wiki coverage once, then fan out one `source-curator` per sub-question (web search + score + body fetch); merge candidates into `candidates.json` |
| knowledge-fetch | Skill | Build `fetch-manifest.json` from the curators' fetch results; opt-in (`--cobrowse`) `source-fetcher` reconcile of fetch misses |
| knowledge-ingest | Skill | Per-source `source-ingester` writes `wiki/sources/<slug>.md` with pre-extracted claims, curated backlinks, and a thematic index category |
| knowledge-distill | Skill | `concept-distiller` proposes recurring concept/entity pages; `concept-store.py` create-or-merges them under a lock with claim-level dedup, so successive runs enrich the concept web rather than duplicate it (optional, fail-soft — the compounding mechanism) |
| knowledge-compose | Skill | `wiki-composer` reads the populated wiki (concept/entity pages as framing *and* citable evidence) and emits a cited draft plus a citation manifest |
| knowledge-verify | Skill | Zero-network claim alignment, fanned out across parallel `wiki-verifier` shards, plus a revisor loop on unsupported deviations |
| knowledge-finalize | Skill | Deposit the verified draft as a synthesis page with `derived_from_research:` lineage and reference backlinks; cycle-guard, index update, binding append, and a wiki conformance gate |
| knowledge-query | Skill | Ask a question against the bound base — answered natively on the vendored wiki engine (`wiki-grounding.py`, index-first) |
| knowledge-dashboard | Skill | Render an HTML overview with a `knowledge-overlay.md` sidecar listing deposited projects and claim drift |
| knowledge-run | Skill | Ordered-phase driver — run the whole inverted pipeline (plan → curate → fetch → ingest → distill → compose → verify → finalize) for ONE fresh topic in a single invocation; the fresh-topic sibling of `knowledge-refresh` push-mode |
| knowledge-refresh | Skill | Self-healing — re-research stale topics; opt-in `--resweep` re-verifies cited claims against live sources |
| knowledge-index | Skill | Rebuild the curated root index and per-type sub-indexes on demand, or migrate an existing old-structure wiki to the curated layout (dry-run preview first, `--apply` to execute) |
| knowledge-refresh-synthesis | Skill | Update ONE existing synthesis from a newly-landed source — union the source into the synthesis's existing evidence base (never thinning it), then re-compose, verify, and finalize |
| knowledge-ingest-source | Skill | Standalone single-source ingest — deposit ONE source (web/PDF URL, local `.docx`/`.html`/`.txt`, pasted text, local PDF, or interview note) into the bound wiki with no research run |
| knowledge-update | Skill | Manually curate a single page — revise an existing wiki page when knowledge changed; shows the diff before writing, requires a source citation per new claim, and sweeps related pages for now-stale statements |
| knowledge-prefill | Skill | Seed the base with curated foundation concept pages (Porter's Five Forces, JTBD, MECE, Pyramid, OODA, SWOT, BCG, Value Chain, Lean Canvas, Wardley, Double Diamond) on the vendored engine |
| knowledge-lint | Skill | Semantic lint — surface stale pages/drafts, claim drift, and broken reverse links; `--fix` repairs the mechanical classes |
| knowledge-health | Skill | Read-only structural health check — page/link/schema integrity plus entries-count and claim drift for the bound wiki |
| source-curator | Agent | Reads its sub-question's wiki-coverage verdict and narrows search on already-covered topics; per-sub-question web search + scoring + body fetch (incl. the PDF read loop) |
| source-fetcher | Agent | Cobrowse-only recovery of fetch misses via the `claude-in-chrome` extension |
| claim-extractor | Agent | Reads one cached source body + sub-question refs and emits the verifiable claims as a JSON array |
| source-ingester | Agent | Reads a cached body, dispatches `claim-extractor`, and writes `wiki/sources/<slug>.md` atomically |
| source-contradictor | Agent | Zero-network ingest-time scorer comparing this run's freshly-ingested source claims against the question group's existing claims; observability-only, never gates ingest |
| concept-distiller | Agent | Reads the run's source-claim bundle and clusters recurring facts into concept/entity proposals (raw-text records — never builds JSON, never computes slugs, never decides dedup) |
| concept-summary-narrator | Agent | Re-narrates the summary of each updated distilled page from its merged claims so the wiki compounds narratively (touches only the summary block) |
| answer-distiller | Agent | The per-question sibling of `concept-distiller` — selects the claims that answer each question node and writes records `question-store.py` splices into a citable answer-claims block |
| cross-lingual-claim-merger | Agent | Confirms which script-flagged DE↔EN candidate pairs are the same fact in two languages (may only confirm, never invents a merge) |
| wiki-composer | Agent | Reads wiki pages + prior syntheses and writes a draft with clickable numbered citations plus a raw-text citation-records file the orchestrator serializes into the manifest |
| wiki-verifier | Agent | Scores each citation's sentence as verbatim / paraphrase / unsupported / synthesis against the cited page's claims (zero network, shardable) |
| revisor | Agent | Re-points unsupported sentences to a covering on-page claim before dropping the citation (no new fetches) |
| wiki-contradictor | Agent | Zero-network scorer comparing the just-deposited synthesis against each cited source's claims and prior syntheses; observability report, no auto-resolution |
| wiki-reviewer | Agent | Zero-network structural-quality scorer rating the draft on 5 weighted dimensions (completeness/coherence/source-diversity/depth/clarity); advisory, never blocks |
| portal-narrator | Agent | (Re)writes the engine-owned per-theme lead-ins in `wiki/index.md` and the overview narrative so the curated Knowledge Portal compounds narratively (never touches a human lead-in or any bullet) |
| concepts-outliner | Agent | The concepts analog of `portal-narrator` — (re)writes the per-theme lead-ins of the grouped `/concepts` domain map so it reads as a domain guide, never a bullet dump |

## Architecture

```
cogni-knowledge/
├── .claude-plugin/plugin.json    Plugin manifest
├── README.md                     Plugin documentation
├── CLAUDE.md                     Developer guide
├── CHANGELOG.md                  Version history
├── LICENSE                       AGPL-3.0
├── _archive/                     Archived research+report chain (see _archive/README.md)
├── agents/                       16 forked + new pipeline agents
├── references/                   21 framework + design docs
├── scripts/                      27 utility scripts (binding, synthesis-impact, cycle-guard, fetch-cache, candidate-store, citation-store, verify-store, wiki-grounding, wiki-coverage, wiki-source-manifest, concept-store, question-store, ingest-integrity, contradiction-ingest-store, pipeline-summary, build_open_questions_payload; vendored wiki-engine: control-path, root_index, sub_index, concepts_index, perspectives_index, overview_update, pdf-extract; one-shot migrators: migrate-layout, migrate-question-index, reclassify-person-entities, backfill_concepts_index) + _knowledge_lib helper
├── skills/                       20 knowledge-* skills
└── tests/                        Contract tests (one per phase)
```

The plugin owns a vendored wiki engine (`scripts/vendor/cogni-wiki/`, resolved vendored-first) and dispatches zero external wiki-plugin skills — the wiki is the core data model, not a separate plugin you install. The agents under `agents/` are point-in-time snapshots, and the bound wiki is the only evidence source for composition, verification, and finalization. The older `knowledge-research` / `knowledge-report` chain lives in `_archive/`.

## Dependencies

- `cogni-wiki` — **not an external dependency**: the wiki engine is vendored under `scripts/vendor/cogni-wiki/` and resolved vendored-first, so the whole inverted pipeline (ingest, query, dashboard, lint, setup) runs with no separate `cogni-wiki` install.
- `cogni-workspace` — provides the market registry, read via `cogni-workspace/scripts/get-market-config.py` for localized (bilingual + per-market authority) search. `knowledge-curate` resolves the market config **once** in skill context and threads it to its `source-curator` agents — when a market is configured it **fails loudly** if the config can't be resolved or resolves to the unlocalized `_default`, rather than silently degrading per-curator. `knowledge-plan` reads the same helper for its candidate-domain suggestions.

### Optional dependencies

These are pure enhancements — the plugin runs without them and degrades to an honest outcome. Absence is never a hard error. They are not vendored; provision them with `/cogni-workspace:manage-workspace`, or install directly.

| Package | Enables | When it's absent | Install |
|---------|---------|------------------|---------|
| `pypdf` | Text-layer PDF recovery on poppler-less hosts — when the Read tool can't rasterize a saved PDF, the source-curator extracts the text layer instead of dropping the source as `pdf_render_unavailable`. | The source is recorded `pdf_render_unavailable` (today's behavior), operator-actionable. | `/cogni-workspace:manage-workspace`, or `pip install pypdf` |
| `markitdown` | `.docx` / office-format normalization for `knowledge-ingest-source` local-file ingest. | `.docx` ingest returns an honest error; stdlib formats (`.txt`/`.html`/`.pdf`) are unaffected. | `pip install markitdown` |

## Custom development

Need a knowledge base tuned to your domain, custom ingest sources, or a pipeline built on this engine? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code research automation for teams. To extend the plugin yourself, every skill delegates — see `references/delegation-contract.md` for the contract.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
