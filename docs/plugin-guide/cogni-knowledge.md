# cogni-knowledge

Wiki-first research orchestrator that binds a persistent knowledge base to N research projects so findings compound across runs instead of dying in chat history.

For the canonical IS/DOES/MEANS positioning of this plugin, see the [cogni-knowledge README](../../cogni-knowledge/README.md).

---

## Overview

cogni-knowledge solves a gap that every other deep-research tool leaves open: where do the findings go after the report ships? `research-report` produces a document and loses the underlying knowledge to context history. cogni-knowledge inverts that posture — a research run binds to a named knowledge base, deposits its verified synthesis into a persistent [cogni-wiki](cogni-wiki.md), and the next run reads from that wiki before going to the web.

The plugin is a thin orchestrator over `cogni-wiki`. It owns exactly one new artifact — a `binding.json` manifest that records "this wiki is the knowledge base for topic area X, and these research projects have contributed to it." All other state lives upstream: wiki pages in `cogni-wiki`, fetch bodies in the content-addressed fetch-cache, research project files in `cogni-research-<slug>/`.

The v0.1.0 inverted pipeline (Phases 1–7: plan → curate → fetch → ingest → compose → verify → finalize) forks dedicated agents locally and runs zero-network claim verification. The runtime path is 0% cogni-research — the bound wiki is the only evidence source for composition, verification, and finalization. A legacy v0.0.x chain that delegated to cogni-research is archived under `_archive/`.

> **Preview** (v0.1.x) — core skills defined but may change. Feedback welcome.

---

## Key Concepts

### The Inverted Pipeline (Phases 1–7)

The pipeline runs in sequence. Each phase writes to disk so interrupted runs resume from the first incomplete phase.

| Phase | Skill | What happens |
|-------|-------|--------------|
| 1 | `knowledge-plan` | Decomposes topic into 3–7 sub-questions with per-sub-question candidate domains (no web yet) |
| 2 | `knowledge-curate` | Fans out one `source-curator` per sub-question — WebSearch + score + WebFetch bodies into the shared fetch-cache in parallel |
| 3 | `knowledge-fetch` | Assembles `fetch-manifest.json` from curators' results; opt-in cobrowse recovery of misses (`--cobrowse`) |
| 4 | `knowledge-ingest` | Writes `wiki/sources/<slug>.md` per fetched URL with `type: source` + `pre_extracted_claims:` frontmatter — the wiki is populated before any draft runs |
| 5 | `knowledge-compose` | Reads the populated wiki and prior syntheses, emits `draft-vN.md` with `[[sources/<slug>]]` wikilink citations + `citation-manifest.json` |
| 6 | `knowledge-verify` | Scores every cited claim against the cited page's `pre_extracted_claims` — zero network; runs a revisor loop on `unsupported` deviations, capped at 2 iterations |
| 7 | `knowledge-finalize` | Deposits verified draft as `wiki/syntheses/<slug>.md` with `derived_from_research:` lineage; updates wiki index; appends project to `binding.json` — closes the compounding loop |

The loop closes at Phase 7: every `knowledge-compose` run reads `wiki/syntheses/*.md` as prior cross-source framing, so each successive project starts from a richer base.

### The Binding Manifest

`.cogni-knowledge/binding.json` is the only new state this plugin owns. It sits as a sibling to the wiki's `.cogni-wiki/config.json` and records:

- which cogni-wiki is the substrate (`wiki_path`)
- which research projects have been deposited (`research_projects[]`)
- topic lineage — covered themes and open themes (`topic_lineage`)
- curator defaults — score threshold, max candidates per sub-question, fetch-cache max age (`curator_defaults`)

Every skill that needs to know "where is the wiki?" or "what has been deposited?" reads `binding.json` rather than any external config.

### Wiki-First vs. One-Shot Research

One-shot tools (cogni-research in standalone mode, OpenAI Deep Research, Perplexity Spaces) produce a report and stop. Every subsequent run on a related topic starts from zero web.

Wiki-first means: run research on EU AI Act Article 6 today; tomorrow's run on foundation-model obligations reads what you already filed — source pages, pre-extracted claims, and the synthesized `wiki/syntheses/<slug>.md` deposit — before issuing a single new web search. Knowledge gets denser with every project.

### Zero-Network Claim Verification

`knowledge-verify` scores citations against the `pre_extracted_claims:` frontmatter that `knowledge-ingest` wrote into each source page during Phase 4. It never re-fetches a URL. The verifier fans out across parallel shards (default 40 citations per shard), runs a revisor loop on `unsupported` deviations, and converges in under 5 minutes per shard. The contrast with cogni-claims' URL re-verification approach (20–30 min baseline) is structural: the claims were extracted at ingest time and are already on disk.

### The Delegation Contract

cogni-knowledge adds no logic that already exists upstream. `knowledge-setup` does not re-implement `wiki-setup` — it only handles the `binding.json` half. `knowledge-query` does not re-implement search — it resolves the wiki path from `binding.json` and delegates to `cogni-wiki:wiki-query`. If you find yourself writing a new agent or duplicating a cogni-wiki script, the right answer is almost always to push the change upstream and re-delegate. See `cogni-knowledge/references/delegation-contract.md`.

---

## Getting Started

Bootstrap a knowledge base with `knowledge-setup`, then run the pipeline phase by phase. The `knowledge-resume` skill is the entry point — it reads current state and tells you the next step whether you are starting fresh or returning to an in-progress base.

```
# Entry point: check status or start fresh
/cogni-knowledge:knowledge-resume --knowledge-slug eu-ai-act

# Bootstrap (first time only)
/cogni-knowledge:knowledge-setup --knowledge-slug eu-ai-act --knowledge-title "EU AI Act knowledge base"

# Inverted pipeline — run in order
/cogni-knowledge:knowledge-plan     --knowledge-slug eu-ai-act --topic "EU AI Act Article 6 high-risk systems"
/cogni-knowledge:knowledge-curate   --knowledge-slug eu-ai-act --project-path ./eu-ai-act-article-6/
/cogni-knowledge:knowledge-fetch    --knowledge-slug eu-ai-act --project-path ./eu-ai-act-article-6/
/cogni-knowledge:knowledge-ingest   --knowledge-slug eu-ai-act --project-path ./eu-ai-act-article-6/
/cogni-knowledge:knowledge-compose  --knowledge-slug eu-ai-act --project-path ./eu-ai-act-article-6/
/cogni-knowledge:knowledge-verify   --knowledge-slug eu-ai-act --project-path ./eu-ai-act-article-6/
/cogni-knowledge:knowledge-finalize --knowledge-slug eu-ai-act --project-path ./eu-ai-act-article-6/

# Inspect and query the accumulated base
/cogni-knowledge:knowledge-dashboard --knowledge-slug eu-ai-act --open yes
/cogni-knowledge:knowledge-query     --knowledge-slug eu-ai-act --question "what does the wiki say about foundation models?"
```

The second project reads the wiki the first one deposited. The compounding loop begins after the first `knowledge-finalize`.

---

## Capabilities

### knowledge-resume

Status skill and session entry point. Reads `binding.json` and delegates to `cogni-wiki:wiki-resume` (which runs `wiki-health` automatically). Adds a per-project inverted-pipeline depth column — sub-questions planned, sources curated/fetched/ingested, citations verified, phase reached — via `pipeline-summary.py`. Returns a suggested next action for the current state.

### knowledge-setup

Bootstraps a knowledge base. Dispatches `cogni-wiki:wiki-setup` to create the wiki if it does not exist, then writes `binding.json`. The only setup work this skill does beyond wiki creation is initializing the binding manifest; all wiki structure is owned by cogni-wiki.

### knowledge-plan

Phase 1 of the inverted pipeline. Decomposes a topic into 3–7 sub-questions with per-sub-question `candidate_domains[]`, using no web access. Writes `<project>/.metadata/plan.json`. When a market is configured, reads `cogni-workspace/scripts/get-market-config.py` to seed bilingual domain candidates for localized search in Phase 2.

### knowledge-curate

Phase 2. Fans out one `source-curator` agent per sub-question in parallel — each runs WebSearch + scoring + WebFetch body-pull for every surviving candidate into the shared fetch-cache. Merges per-sub-question batches into `candidates.json` via `candidate-store.py` (file-locked, URL-dedup, score-wins on collision). Each candidate carries a `fetch` sub-object so Phase 3 never has to re-fetch.

### knowledge-fetch

Phase 3. Builds `fetch-manifest.json` from the curators' existing `fetch` sub-objects — no additional WebFetch calls by default. If `--cobrowse` is passed (or confirmed interactively), dispatches `source-fetcher` to recover WebFetch misses via the `claude-in-chrome` extension. Cobrowse is off by default so unattended runs stay browser-free.

### knowledge-ingest

Phase 4. Reads `fetch-manifest.json`, dispatches one `source-ingester` per fetched source (which dispatches `claim-extractor` per body), and writes `wiki/sources/<slug>.md` with `type: source` and populated `pre_extracted_claims:` frontmatter. The wiki is populated before any draft runs — this is the structural precondition for zero-network verification in Phase 6.

### knowledge-compose

Phase 5. Dispatches `wiki-composer`, which reads `wiki/index.md` + selected `wiki/sources/*.md` + prior `wiki/syntheses/*.md`, and writes `draft-vN.md` with `[[sources/<slug>]]` wikilink citations plus `citation-manifest.json`. A leftover `writer-outline-vN.json` from a crashed prior run triggers outline-recovery so only Phase 2 of the composer reruns.

### knowledge-verify

Phase 6. Shards `citation-manifest.json` via `verify-store.py`, dispatches `wiki-verifier` agents in parallel across shards (each shard target: under 5 minutes), then merges into `verify-vN.json`. Each verifier scores `draft_sentence` against `pre_extracted_claims` as `verbatim` / `paraphrase` / `unsupported` / `synthesis` — no network calls, no URL re-fetch. Loops with `revisor` on `unsupported` deviations (max 2 iterations); the revisor re-points to a covering on-page claim before dropping a citation.

### knowledge-finalize

Phase 7. Runs `cycle-guard.py` to refuse self-citing loops, then atomically writes `wiki/syntheses/<slug>.md` with `type: synthesis`, `derived_from_research: <project-slug>`, and a reconstructed `## References` list. Updates the wiki index, bumps `entries_count`, rebuilds `context_brief`, and appends the project to `binding.json`. Writes a datestamped line to `wiki/log.md`. Future `knowledge-compose` runs read the deposited synthesis as prior framing.

### knowledge-query

Read-only. Resolves the wiki path from `binding.json`, delegates to `cogni-wiki:wiki-query` with the question, and appends a one-line footer showing the knowledge base slug and deposit count. Use this to ask natural-language questions against everything the base has accumulated.

### knowledge-dashboard

Renders the wiki's HTML dashboard via `cogni-wiki:wiki-dashboard`, then writes a `knowledge-overlay.md` sidecar: per-project inverted-pipeline columns, a global pipeline-health block from `pipeline-summary.py cache-health`, and the latest `claim_drift` count from a lint audit.

### knowledge-refresh

Self-healing skill with two modes. Pull-mode (`--mode pull --from-research <slug>`) delegates to `cogni-wiki:wiki-refresh` to deposit an externally produced research project. Push-mode (`--mode push`) lints the wiki to find stale pages, prompts you to select which topics to refresh, and runs the full seven-phase pipeline per selected topic — sequentially, fail-soft, idempotent.

---

## Integration Points

### Upstream (what cogni-knowledge consumes)

| Plugin | What is consumed |
|--------|-----------------|
| cogni-wiki | The substrate — wiki-setup, wiki-query, wiki-dashboard, wiki-refresh, wiki-lint, wiki-resume, wiki-health |
| cogni-workspace | Optional — `get-market-config.py` for bilingual, per-market authority search when a market is configured |

cogni-wiki is a hard dependency (requires v0.0.44+). cogni-workspace is optional — without it, search falls back to unlocalized defaults.

cogni-research is not a runtime dependency of the v0.1.0 inverted pipeline. The archived v0.0.x chain under `_archive/` delegated to it; it remains available as a sibling plugin for one-shot reports. For details on the one-shot pipeline, see [cogni-research](cogni-research.md).

### Downstream (what cogni-knowledge produces)

cogni-knowledge deposits into the bound cogni-wiki. Everything it writes — source pages (`wiki/sources/<slug>.md`), synthesis pages (`wiki/syntheses/<slug>.md`), log entries, and index updates — is owned by the wiki and browsable via Obsidian or any Markdown reader. The wiki itself can then feed [cogni-research](cogni-research.md) in `wiki` or `hybrid` source mode, or be queried directly via `knowledge-query`.

---

## Common Workflows

### Workflow 1: Bootstrap + First Deposit

Start here for a new topic area.

1. `/knowledge-resume --knowledge-slug <slug>` — check whether the base exists; if not, proceed to setup
2. `/knowledge-setup --knowledge-slug <slug> --knowledge-title "<title>"`
3. Run the seven-phase pipeline: `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` → `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` → `knowledge-finalize`
4. `/knowledge-dashboard --knowledge-slug <slug> --open yes` — inspect what was deposited

After `knowledge-finalize` completes, the first synthesis lives in `wiki/syntheses/`. The compounding base has begun.

### Workflow 2: Query the Compounding Base

After two or more projects have been deposited, the base has cross-project framing.

1. `/knowledge-query --knowledge-slug <slug> --question "<natural language question>"` — ask against everything filed
2. If the answer is thin, check `knowledge-dashboard` for which topics are covered and which are open
3. Run the pipeline on an open theme to fill the gap

### Workflow 3: Refresh Stale Topics

Use this when the wiki has pages flagged `stale` by `wiki-lint` or when a topic area needs an update from a new source.

- **Pull mode** — you have a recent research project: `/knowledge-refresh --knowledge-slug <slug> --mode pull --from-research <project-slug>`. Delegates to `wiki-refresh` to deposit the new findings.
- **Push mode** — re-research from scratch: `/knowledge-refresh --knowledge-slug <slug> --mode push`. The skill lints the wiki, presents a multi-select of stale topics, and runs the full inverted pipeline per confirmed topic.

---

## Data Model

### binding.json

```json
{
  "knowledge_slug": "eu-ai-act",
  "knowledge_title": "EU AI Act knowledge base",
  "wiki_path": "/absolute/path/to/eu-ai-act/",
  "research_projects": [
    {
      "slug": "article-6-high-risk",
      "deposited_at": "2026-05-24",
      "report_path": "/absolute/path/to/output/report.md",
      "report_source": "wiki",
      "project_path": "/absolute/path/to/project/"
    }
  ],
  "topic_lineage": {
    "covered_themes": ["high-risk classification", "conformity assessment"],
    "open_themes": ["foundation model obligations"]
  },
  "curator_defaults": {
    "max_candidates_per_sq": 12,
    "score_threshold": 0.5,
    "fetch_cache_max_age_days": 30
  },
  "created": "2026-05-20",
  "schema_version": "0.1.0"
}
```

The file is small (< 4 KiB even at 20+ deposited projects) and is a narrative manifest — not a database. To search content, use `knowledge-query` against the wiki itself.

### Wiki Pages Written

| Path | Type | Key frontmatter |
|------|------|-----------------|
| `wiki/sources/<slug>.md` | source | `type: source`, `sources: [<URL>]`, `pre_extracted_claims:` |
| `wiki/syntheses/<slug>.md` | synthesis | `type: synthesis`, `derived_from_research: <project-slug>`, `sources: [wiki://<slug>/<cited-slug>]` |

The fetch-cache lives at `<knowledge-root>/.cogni-knowledge/fetch-cache/<sha256>.json` — content-addressed, URL → body, with negative caching for unavailable URLs and a configurable freshness gate (`fetch_cache_max_age_days`).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `knowledge-finalize` refuses with "cycle detected" | The project's citations include a page that was itself derived from this project | This is `cycle-guard.py` working correctly — the synthesis would cite itself. Start a new project with a different topic framing |
| `knowledge-verify` shard count is 0 | `citation-manifest.json` is missing `id` / `draft_sentence` fields (pre-v0.0.28 manifest) | Re-run `knowledge-compose` to regenerate the manifest with the current schema, then re-run `knowledge-verify` |
| Cobrowse step hangs | `claude-in-chrome` extension not running | Either start the extension and retry, or skip cobrowse — misses are recorded as `unavailable` and the pipeline continues without those sources |
| Dashboard shows no deposits | `knowledge-finalize` was not run to completion | Check `wiki/log.md` — if no finalize entry appears, run `knowledge-finalize` for the project |
| `knowledge-query` returns thin results | Few sources ingested, or syntheses cover a narrow slice | Run `knowledge-dashboard` to inspect coverage; run additional pipeline projects on open themes |
| Binding reads a stale wiki path | `wiki_path` in `binding.json` no longer resolves | Edit `binding.json::wiki_path` to the current absolute path of the wiki root |

---

## Extending This Plugin

The delegation contract is the primary constraint on extension: no logic that already exists in cogni-wiki or cogni-research should be duplicated here. If a new capability belongs to wiki structure, file it upstream in cogni-wiki. If it belongs to web research patterns, file it upstream in cogni-research.

What does belong here:

- New binding manifest fields (additive schema changes — bump `schema_version`)
- New read-side skills that combine `pipeline-summary.py` data with binding data
- New `curator_defaults` options that configure inverted-pipeline agent behavior
- Adjustments to `cycle-guard.py` for new citation input shapes

See `cogni-knowledge/references/delegation-contract.md` for the full mapping of which work goes where, and `cogni-knowledge/references/inverted-pipeline.md` for the phase-by-phase design spec.

For contribution guidelines, see the [insight-wave contribution guide](../../CONTRIBUTING.md).
