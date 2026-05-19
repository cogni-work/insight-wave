# cogni-knowledge

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

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

| Skill | Purpose | Delegates to |
|---|---|---|
| `knowledge-setup` | Bootstrap a knowledge base (wiki + binding manifest) | `cogni-wiki:wiki-setup` |
| `knowledge-research` | Research a topic INTO the bound wiki and record the project | `cogni-wiki:wiki-from-research` (Mode A) |
| `knowledge-report` | Compose a report BY READING the bound wiki, with cycle-guard, then re-deposit | `cogni-wiki:wiki-from-research` (Mode B, with opt-in flags) |
| `knowledge-resume` | Status: deposited projects, wiki health, suggested next action | `cogni-wiki:wiki-resume` |
| `knowledge-query` | Ask a question against the bound base | `cogni-wiki:wiki-query` |
| `knowledge-dashboard` | Render an HTML overview with a binding overlay sidecar | `cogni-wiki:wiki-dashboard` |
| `knowledge-refresh` | Refresh stale pages — pull-mode pipes a research project in, push-mode auto-researches stale topics | `cogni-wiki:wiki-refresh`, `cogni-wiki:wiki-lint`, `cogni-knowledge:knowledge-research` |

See `references/absorption-roadmap.md` for the full epic plan — Phase 4 (internal alpha) and onward.

## Installation

Install via the insight-wave marketplace:

```
/plugin install cogni-knowledge@insight-wave
```

Requires both `cogni-wiki` and `cogni-research` installed (they are the delegate targets).

## Quick start

```
/cogni-knowledge:knowledge-setup --knowledge-slug eu-ai-act --knowledge-title "EU AI Act knowledge base"
/cogni-knowledge:knowledge-research --knowledge-slug eu-ai-act --topic "EU AI Act Article 6 high-risk systems"
/cogni-knowledge:knowledge-research --knowledge-slug eu-ai-act --topic "EU AI Act foundation model obligations"
/cogni-knowledge:knowledge-resume --knowledge-slug eu-ai-act
/cogni-knowledge:knowledge-dashboard --knowledge-slug eu-ai-act --open yes
/cogni-knowledge:knowledge-query --knowledge-slug eu-ai-act --question "what does the wiki say about foundation models?"
```

The second `knowledge-research` reads the wiki that the first deposited — that is the compounding loop. The `dashboard` and `query` calls let you inspect and ask the accumulated base. Use `knowledge-refresh --mode push|pull` later to keep stale pages fresh.

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

- 7 skills (`knowledge-setup`, `knowledge-research`, `knowledge-report`, `knowledge-resume`, `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh`)
- 3 scripts (`knowledge-binding.py`, `lineage-stamp.py`, `cycle-guard.py`)
- 3 references (`differentiation-thesis.md`, `delegation-contract.md`, `absorption-roadmap.md`)

## Architecture

cogni-knowledge sits **between the user and `cogni-research`+`cogni-wiki`**. Direct user → `cogni-research` and direct user → `cogni-wiki` paths remain unchanged. The plugin's only value-add is the binding (`binding.json`), lineage stamping, and one-prompt workflow choreography.

```
user ──> cogni-knowledge ──> cogni-wiki:wiki-from-research ──> cogni-research:research-setup → research-report
                                                          └──> cogni-wiki:wiki-ingest
```

## Dependencies

- `cogni-wiki` ≥ 0.0.40 (Phase 2 needs the `--allow-wiki-source --cycle-guard-cleared` flag pair on `wiki-from-research`)
- `cogni-research` ≥ 0.8.3

## Custom development

Adding a skill: every skill delegates. If you find yourself writing a new agent or duplicating cogni-wiki/cogni-research logic, the right answer is almost always to push the change upstream and re-delegate. See `references/delegation-contract.md` for the contract.

## License

AGPL-3.0-only. See [LICENSE](LICENSE).

---

Built by [Cogni Work](https://cogni-work.ai). Part of [insight-wave](../README.md).
