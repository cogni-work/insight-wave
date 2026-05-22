# cogni-knowledge

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-knowledge:knowledge-resume` for project status and next-step guidance — whether you're starting fresh or returning to an in-progress project.

**Wiki-first research that compounds.** Every shipped deep-research tool today produces a document and loses the underlying knowledge to chat history. cogni-knowledge inverts that posture: a research run *binds* to a named knowledge base, deposits its findings into a persistent cogni-wiki, and the next run reads from the same wiki before going to the web. Knowledge gets denser with every project — instead of starting from zero each time.

This plugin is a thin orchestrator. It does not fork cogni-research or cogni-wiki. Every primitive delegates upward to those plugins; the only new state cogni-knowledge owns is a `binding.json` that records "this wiki is the knowledge base for topic area X, and these research projects have contributed to it."

## Why this exists

| Problem | One-shot research tools | cogni-knowledge |
|---|---|---|
| Where do findings go after the report ships? | Lost to chat history | Filed in a persistent wiki |
| Second research run on a related topic | Starts from zero | Reads the wiki first |
| Cross-project synthesis | Manual; copy-paste between sessions | Automatic — wiki accumulates and interlinks |
| Provenance of a stale fact | Forgotten by next session | `derived_from_research: <slug>` traces every page back to the run that filed it |
| Refresh stale claims | Manual re-research | `knowledge-refresh` (push: re-research stale topics; pull: re-deposit from a new project) |

## What it is

**IS:** A binding orchestrator that turns `cogni-research + cogni-wiki` into a wiki-first research workflow. A knowledge base = one cogni-wiki + a `binding.json` manifest. Every `knowledge-research` run deposits into that wiki and is recorded in the binding; every `knowledge-report` (Phase 2) reads from it.

**DOES** (Phase 1 + Phase 2 + Phase 3): seven skills — `knowledge-setup`, `knowledge-research`, `knowledge-report`, `knowledge-resume`, `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh` — and three scripts (`knowledge-binding.py`, `lineage-stamp.py`, `cycle-guard.py`). Phase 2 (`knowledge-report`) closes the round-trip: reports get composed by reading the deposited wiki pages, with a deterministic cycle-guard that refuses self-citing loops. Phase 3 makes the accumulated knowledge legible and self-healing.

**MEANS for you:** the work compounds. Run research on EU AI Act Article 6 today; tomorrow's run on foundation-model obligations reads what you already filed. Query the base by slug with `knowledge-query`; visualize it with `knowledge-dashboard`; keep it fresh with `knowledge-refresh`. No vector store, no embeddings — just markdown that compounds.

## What it does

1. **Setup** a knowledge base — one cogni-wiki + a `binding.json` manifest that records every research project deposited
2. **Plan** a topic into 3–7 sub-questions with per-sub-question candidate domains (no web yet) — Phase 1 of the v0.1.0 inverted pipeline
3. **Curate** candidate sources per sub-question via WebSearch + scoring (no fetch yet) — Phase 2
4. **Fetch** source bodies via WebFetch with `claude-in-chrome` cobrowse fallback through a shared fetch-cache — Phase 3
5. **Ingest** fetched sources into the wiki as `type: source` pages with `pre_extracted_claims:` frontmatter — Phase 4 (the wiki populated before any draft runs)
6. **Compose** the draft report by reading the populated wiki, with `[[sources/<slug>]]` wikilink citations + a parallel citation manifest — Phase 5
7. **Verify** every cited claim against the cited page's `pre_extracted_claims` (zero network) and loop with the revisor on `unsupported` deviations, capped at 2 iterations — Phase 6
8. **Finalize** the verified draft as `wiki/syntheses/<slug>.md` with `type: synthesis` + `derived_from_research:` lineage, refuse self-citing loops via `cycle-guard.py` (now with a citation-manifest fallback), update the wiki index + entries_count + context_brief, and append the project to the binding — Phase 7 (closes the inverted-pipeline loop)
9. **Research** a topic INTO the bound wiki via the legacy `cogni-wiki:wiki-from-research` Mode A path (pre-v0.1.0 surface)
10. **Report** by reading the bound wiki with `cycle-guard.py`, then re-deposit via `wiki-from-research` Mode B (pre-v0.1.0 surface)
11. **Resume** project status — deposited projects, wiki health, suggested next action
12. **Query** the bound base — natural-language question routed through `cogni-wiki:wiki-query`
13. **Dashboard** the bound base — HTML overview with a binding overlay sidecar
14. **Refresh** stale pages — pull-mode pipes a research project in; push-mode auto-researches stale topics

See `references/absorption-roadmap.md` for the v0.1.0 inverted-pipeline plan (M1–M9 shipped; M10 manifest-aware query/dashboard rebuild pending).

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note**: cogni-knowledge orchestrates `cogni-wiki` and (on the pre-v0.1.0 legacy path) `cogni-research`. The v0.1.0 inverted pipeline forks the agents locally so the runtime path is 0% cogni-research; the binding still records `report_source` so legacy projects keep working.

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

The second project reads the wiki the first one deposited — that is the compounding loop. The `dashboard` and `query` skills let you inspect and ask the accumulated base. Use `knowledge-refresh --mode push|pull` later to keep stale pages fresh.

## Data model

One new artifact: `<knowledge-base>/.cogni-knowledge/binding.json`, sibling to the wiki's `.cogni-wiki/config.json`. It records:

- `knowledge_slug`, `knowledge_title`
- `wiki_path` — absolute path to the bound cogni-wiki (the wiki's own slug is read live from `<wiki_path>/.cogni-wiki/config.json` so it cannot drift)
- `research_projects[]` — one entry per deposited run: `slug`, `deposited_at`, `report_path`, `report_source`
- `topic_lineage` — `covered_themes[]` and `open_themes[]` (populated as the base grows)

All other state lives upstream: wiki pages in `cogni-wiki`, research artifacts in `cogni-research-<slug>/`. cogni-knowledge owns nothing else.

## How it works

```
knowledge-setup
  → cogni-wiki:wiki-setup (creates the wiki)
  → knowledge-binding.py --init (writes binding.json)

knowledge-research --knowledge-slug X --topic T
  → cogni-wiki:wiki-from-research --topic T --wiki-root <bound>
       → cogni-research:research-setup → research-report  (produces report.md)
       → cogni-wiki:wiki-setup (skipped if wiki exists)
       → cogni-wiki:wiki-ingest --discover research:<slug>  (deposits per-sub-question pages)
  → lineage-stamp.py  (stamps derived_from_research: <slug> into deposited pages)
  → knowledge-binding.py --append-project  (records the project in binding.json with the live report_source)

knowledge-query --knowledge-slug X --question Q
  → cogni-wiki:wiki-query --question Q  (against the bound wiki)
  → footer: knowledge base + deposit count

knowledge-dashboard --knowledge-slug X
  → cogni-wiki:wiki-dashboard --wiki-root <bound>  (writes wiki-dashboard.html)
  → writes knowledge-overlay.md sidecar  (binding view: deposits + lint claim_drift)

knowledge-refresh --knowledge-slug X --mode pull --from-research S
  → cogni-wiki:wiki-refresh --from-research S --wiki-root <bound>

knowledge-refresh --knowledge-slug X --mode push
  → cogni-wiki:wiki-lint --wiki-root <bound>  (find stale_page / stale_draft)
  → multi-select + batch confirm  (which topics, then yes/no to launch)
  → per selected topic, sequentially:
       knowledge-research --knowledge-slug X --topic <page title>
       cogni-wiki:wiki-refresh --from-research <new-slug>
```

The deposited pages are now part of the wiki and visible to the next `knowledge-research` run via the upstream `wiki-researcher` agent when `report_source=wiki` is selected (Phase 2 lights this up automatically).

## Components

| Component | Type | Description |
|-----------|------|-------------|
| knowledge-resume | Skill | Show status of a cogni-knowledge base — slug, bound wiki, deposited projects, wiki health, next-step guidance |
| knowledge-setup | Skill | Bootstrap a cogni-knowledge base — wiki + a binding manifest that records every research project deposited |
| knowledge-plan | Skill | Phase 1 of the v0.1.0 inverted pipeline — decompose a topic into 3–7 sub-questions with candidate domains |
| knowledge-curate | Skill | Phase 2 — fan out one `source-curator` per sub-question; merge scored candidates into `candidates.json` |
| knowledge-fetch | Skill | Phase 3 — per-batch `source-fetcher` dispatch with WebFetch + cobrowse fallback through a shared fetch-cache |
| knowledge-ingest | Skill | Phase 4 — per-source `source-ingester` writes `wiki/sources/<slug>.md` with `pre_extracted_claims` frontmatter |
| knowledge-compose | Skill | Phase 5 — `wiki-composer` reads the populated wiki and emits `draft-vN.md` + a `[[sources/<slug>]]` citation manifest |
| knowledge-verify | Skill | Phase 6 — zero-network claim alignment + revisor loop on `unsupported` deviations (max 2 iterations) |
| knowledge-finalize | Skill | Phase 7 — deposit the verified draft as `wiki/syntheses/<slug>.md` with `derived_from_research:` lineage; cycle-guard, index update, entries_count bump, context_brief rebuild, binding append (closes the inverted-pipeline loop) |
| knowledge-research | Skill | Legacy v0.0.x — research a topic INTO the bound wiki via `cogni-wiki:wiki-from-research` Mode A |
| knowledge-report | Skill | Legacy v0.0.x — compose a report by reading the bound wiki with `cycle-guard.py`, then re-deposit Mode B |
| knowledge-query | Skill | Ask a question against the bound base — natural-language query routed through `cogni-wiki:wiki-query` |
| knowledge-dashboard | Skill | Render an HTML overview with a `knowledge-overlay.md` sidecar listing deposited projects + lint claim_drift |
| knowledge-refresh | Skill | Self-healing — pull-mode pipes a research project in; push-mode auto-researches stale topics |
| source-curator | Agent | Phase 2 fork — per-sub-question WebSearch + scoring; emits a batch JSON array for merge into `candidates.json` |
| source-fetcher | Agent | Phase 3 NEW — per-URL WebFetch with cobrowse fallback; reads/writes through `fetch-cache.py`; PDF branch via Read pages |
| claim-extractor | Agent | Phase 4 fork — reads one cached source body + sub-question refs, emits a JSON array of `{id, text, excerpt_quote, …}` |
| source-ingester | Agent | Phase 4 NEW — reads cached body, dispatches `claim-extractor`, writes `wiki/sources/<slug>.md` atomically |
| wiki-composer | Agent | Phase 5 fork — reads wiki pages + prior syntheses, writes `draft-vN.md` with wikilink citations and a citation manifest |
| wiki-verifier | Agent | Phase 6 NEW — scores every citation as `verbatim` / `paraphrase` / `unsupported` / `synthesis` (zero network) |
| revisor | Agent | Phase 6 fork — rephrases unsupported draft sentences toward existing claims or drops the citation (no new fetches) |

## Architecture

```
cogni-knowledge/
├── .claude-plugin/plugin.json    Plugin manifest
├── README.md                     Plugin documentation
├── CLAUDE.md                     Developer guide
├── CHANGELOG.md                  Version history
├── LICENSE                       AGPL-3.0
├── agents/                       7 forked + new pipeline agents
├── references/                   7 framework + design docs
├── scripts/                      7 utility scripts (binding, lineage, cycle-guard, fetch-cache, candidate-store, …)
├── skills/                       13 knowledge-* skills
└── tests/                        Contract tests (one per phase)
```

The plugin sits between the user and `cogni-wiki`. On the v0.1.0 inverted pipeline (Phases 1–7 shipped), the runtime path is 0% `cogni-research` — forked agents under `agents/` are point-in-time copies and the bound wiki is the only evidence source for composition, verification, and finalization. The pre-v0.1.0 legacy path (`knowledge-research` / `knowledge-report`) still delegates to `cogni-wiki:wiki-from-research`, which internally calls `cogni-research`.

## Dependencies

- `cogni-wiki` ≥ 0.0.44 (Phase 4 `knowledge-ingest` needs the `type: source` allowlist added to `wiki-lint` / `wiki-health` at 0.0.44; legacy `knowledge-report` needs the `--allow-wiki-source --cycle-guard-cleared` flag pair from 0.0.40 and the `--wiki-root` flag on `wiki-query` from 0.0.41)
- `cogni-research` — installed for the pre-v0.1.0 legacy `knowledge-research` / `knowledge-report` path only; the v0.1.0 inverted pipeline has no runtime dependency (forked agents are local point-in-time copies)

## Custom development

Adding a skill: every skill delegates. If you find yourself writing a new agent or duplicating cogni-wiki/cogni-research logic, the right answer is almost always to push the change upstream and re-delegate. See `references/delegation-contract.md` for the contract.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
