---
id: ecosystem-plugin-selection
title: "Plugin selection: which plugin handles my task"
type: summary
tags: [ecosystem, plugin-selection, routing, discovery, getting-started]
created: 2026-08-13
updated: 2026-08-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/ecosystem-overview.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/getting-started.md
status: stable
related: [ecosystem-overview, ecosystem-command-reference, concept-four-layer-architecture]
---

Users usually know what they want to accomplish but not which of the eight plugins owns it. This page is the routing table from task to plugin. Match on what the user is trying to *produce*, not on keywords — "I need to make slides" can mean [[plugin-cogni-workspace]] (a deck from an existing narrative) or [[plugin-cogni-marketing]] (campaign materials), and picking wrong sends someone down a pipeline that was never going to work.

## Task → plugin

| If the task is… | Start with | Then usually |
|---|---|---|
| Research a topic into a cited synthesis that compounds across runs | cogni-knowledge | `cogni-workspace:narrative` → slides |
| Fact-check a document against its cited sources | cogni-workspace | — |
| Identify industry trends and their strategic implications | cogni-trends | cogni-portfolio |
| Define product/service propositions per market, size the opportunity, map competitors | cogni-portfolio | cogni-marketing or cogni-sales |
| Turn structured content into an executive story | `cogni-workspace:narrative` | `cogni-workspace:copywriter` → slides |
| Polish a rough draft, or stress-test it against stakeholder personas | `cogni-workspace:copywriter` | `cogni-workspace:copy-reader` |
| Produce slides, a web narrative, a poster storyboard, an infographic, or an enriched HTML report | cogni-workspace | — |
| Produce B2B marketing content across channels | cogni-marketing | `cogni-workspace:copywriter` |
| Build a customer-specific or segment sales pitch | cogni-sales | cogni-workspace |
| Generate a deployable customer website from portfolio content | cogni-website | — |
| Run a structured consulting engagement with a work-breakdown structure | cogni-consult | — |
| Set up the workspace, manage themes, install MCP servers, diagnose config | cogni-workspace | — |
| Find the right plugin, chain plugins, troubleshoot, file an issue | cogni-workspace | — |

## What each plugin owns

**cogni-knowledge** — Wiki-first research that compounds. Each project binds to a knowledge base and runs an inverted pipeline: plan → curate → fetch → ingest → distill → compose → verify → finalize, with zero-network citation-consistent claim verification. Use it when the knowledge should persist and sharpen rather than die in a one-off report. Works with `cogni-workspace:claims` (live-source resweep) and `cogni-workspace:narrative`.

**cogni-trends** — Trend scouting and reporting. Smarter Service Trendradar (4 dimensions) combined with the TIPS framework. DACH-focused, bilingual EN/DE. Feeds cogni-portfolio (investment themes) and cogni-marketing (GTM themes). See [[concept-trends-portfolio-bridge]].

**cogni-portfolio** — Portfolio messaging on IS/DOES/MEANS. Market-independent features (IS), market-specific advantages (DOES) and benefits (MEANS), plus TAM/SAM/SOM and competitor analysis. Standalone; pairs with cogni-trends for trend-backed features. Feeds cogni-marketing, cogni-sales and cogni-website.

**cogni-marketing** — B2B content engine bridging cogni-trends themes and cogni-portfolio propositions into channel-ready content across sixteen formats. Requires both upstream plugins to have data. Bilingual DE/EN.

**cogni-sales** — Pitch generation on the Corporate Visions Why Change methodology. Named-customer or reusable segment pitches. Requires cogni-portfolio propositions; optionally enriched by cogni-trends.

**cogni-website** — Assembles multi-page customer websites from portfolio, marketing, trend and research content produced by the other plugins.

**cogni-consult** — Consulting engagement orchestrator. Scoping derives 3–6 action fields (the work-breakdown structure) from one SMART key question; each deliverable runs its own design-thinking loop (empathize → define → ideate → prototype → test) with acting stakeholder personas challenging the work. Requires a cogni-knowledge base bound at setup as the research spine.

**cogni-workspace** — Horizontal workspace layer. Shared env vars and settings, theme management, market registry, MCP installation, workspace health, and this wiki. Other plugins read its shared workspace state when they need those services — see [[concept-theme-inheritance]]. It also owns claim verification against cited sources (`cogni-workspace:claims`), detecting deviations between what a document asserts and what the source actually says — use it before publishing research output; see [[concept-claim-lifecycle]] and [[concept-claims-propagation]]. Story-arc-driven transformation lives here too (`cogni-workspace:text-to-narrative`): the story-arc frameworks the skill registers (fifteen at the time of writing, including the TIPS-native trend panorama and its theme-aware sibling), executive synthesis, and citation bridging — structured content in, a narrative plus one design brief for Claude Design out; the narrative goes on to `cogni-workspace:copywriter`, which polishes with messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB), stress-tests a draft against stakeholder personas (`cogni-workspace:copy-reader`), optimizes readability, and also handles German documents in the Wolf Schneider register. It additionally renders hand-authored or caller-supplied briefs into visual deliverables: slide decks, scrollable web narratives, poster storyboards, single-page infographics, and themed HTML reports with charts. Brief-driven — see [[concept-brief-based-rendering]].


## When nothing fits

Say so plainly. Do not force-fit a plugin onto a task it was not designed for — a wrong recommendation costs more than an honest "the ecosystem does not cover this". Suggest checking whether a community plugin exists, or building one; `docs/contributing/plugin-development.md` covers that path.

## Where to read more

| Resource | Path | When |
|---|---|---|
| Getting started | `docs/getting-started.md` | New users, first-time setup |
| Ecosystem overview | `docs/ecosystem-overview.md` | "What plugins are available?", "How do they connect?" |
| Plugin guides | `docs/plugin-guide/<plugin>.md` | "How does cogni-X work?", full capabilities |
| Workflow guides | `docs/workflows/<id>.md` | "How do I go from X to Y?" |
| Architecture | `docs/architecture/` | Structure and design principles |
| Contributing | `docs/contributing/plugin-development.md` | Building a plugin |

For multi-plugin tasks, name the sequence rather than a single plugin, and check whether a canonical pipeline already covers it — see [[concept-canonical-workflow-ids]].

**Source**: [ecosystem overview](https://github.com/cogni-work/insight-wave/blob/main/docs/ecosystem-overview.md) · [getting started](https://github.com/cogni-work/insight-wave/blob/main/docs/getting-started.md)
