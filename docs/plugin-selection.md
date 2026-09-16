# Plugin selection: which plugin handles my task

Users usually know what they want to accomplish but not which plugin owns it. This page is the routing table from task to plugin. Match on what you are trying to *produce*, not on keywords: "I need to make slides" can mean cogni-publishing (a design brief or rendered deck) or cogni-marketing (campaign materials). For the exact invocation once you know the plugin, see the [Command reference](command-reference.md).

## Task to plugin

| If the task is… | Start with | Then usually |
|---|---|---|
| Research a topic into a cited synthesis that compounds across runs | cogni-knowledge | `cogni-publishing:text-to-narrative` |
| Fact-check a document against its cited sources | `cogni-workspace:claims` | — |
| Identify industry trends and their strategic implications | cogni-trends | cogni-portfolio |
| Define product or service propositions per market, size the opportunity, map competitors | cogni-portfolio | cogni-marketing or cogni-sales |
| Turn structured content into an executive story with a design brief for slides, a document, an infographic or a web page | `cogni-publishing:text-to-narrative` | `cogni-publishing:copywriter` |
| Polish a rough draft, or stress-test it against stakeholder personas (`--scope=review`) | `cogni-publishing:copywriter` | `cogni-publishing:text-to-narrative` |
| Produce B2B marketing content across channels | cogni-marketing | `cogni-publishing:copywriter` |
| Build a customer-specific or segment sales pitch | cogni-sales | `cogni-publishing:text-to-narrative` |
| Generate a deployable customer website from portfolio content | cogni-website | — |
| Check that a brief is ready to publish — frozen copy, sources and references intact, before anything renders it | `cogni-publishing:publishing-validate` | `cogni-publishing:design-compose` |
| Run a structured consulting engagement with a work-breakdown structure | cogni-consult | cogni-knowledge |
| Set up the workspace, manage themes, install MCP servers, diagnose configuration | cogni-workspace | — |
| Troubleshoot a plugin failure, or file an issue against a plugin | cogni-workspace (`/troubleshoot`, `cogni-issues`) | — |

## What each plugin owns

**cogni-knowledge** — Wiki-first research that compounds. Each project binds to a knowledge base and runs an inverted pipeline (plan → curate → fetch → ingest → distill → compose → verify → finalize) with zero-network, citation-consistent claim verification. Use it when the knowledge should persist and sharpen rather than die in a one-off report. Pairs with `cogni-workspace:claims` for an opt-in live-source resweep and with `cogni-publishing:text-to-narrative` for the executive story.

**cogni-trends** — Trend scouting and TIPS reporting. Combines the Smarter Service Trendradar with the TIPS framework (Trends, Implications, Possibilities, Solutions) and researches bilingually in EN and DE against regional authorities across eight European and Anglo markets. Feeds cogni-portfolio (investment themes) and cogni-marketing (GTM themes).

**cogni-portfolio** — Portfolio messaging on IS/DOES/MEANS. Market-independent features (IS), market-specific advantages (DOES) and benefits (MEANS), plus TAM/SAM/SOM sizing and competitor analysis across pluggable industry taxonomies. Standalone; pairs with cogni-trends for trend-backed features. Feeds cogni-marketing, cogni-sales and cogni-website.

**cogni-marketing** — B2B content engine bridging cogni-trends themes and cogni-portfolio propositions into channel-ready content across sixteen formats. Needs both upstream plugins to have data. Bilingual DE/EN.

**cogni-sales** — Pitch generation on the Corporate Visions Why Change methodology, for a named customer or a reusable market segment. Needs cogni-portfolio propositions; optionally enriched by cogni-trends.

**cogni-website** — Assembles multi-page customer websites from the portfolio, marketing, trend and research content the other plugins produce, with shared navigation and theming.

**cogni-publishing** — The standalone publishing and theme layer. It owns narrative composition, copywriting, theme lifecycle, brief normalization, semantic composition, branded HTML/PPTX rendering, and independent verification while preserving frozen copy and source lineage. Needs no other plugin installed.

**cogni-consult** — Consulting engagement orchestrator. Scoping derives three to six action fields, the work-breakdown structure, from one SMART key question; each deliverable then runs its own design-thinking loop (empathize → define → ideate → prototype → test) with acting stakeholder personas challenging the work in their own voice. One cogni-knowledge base, bound at setup, is the research spine. It orchestrates; the content work is dispatched to the plugins that own it.

**cogni-workspace** — The horizontal runtime layer: shared environment and settings, supported-market registry, MCP installation, workspace health, troubleshooting, issue filing, project discovery, and claim verification. Publishing capabilities and themes are owned by cogni-publishing; workspace's old publishing names are compatibility delegates only.

## When nothing fits

Say so plainly. Do not force-fit a plugin onto a task it was not designed for; a wrong recommendation costs more than an honest "the ecosystem does not cover this". Check whether a community plugin exists, or build one: [Plugin development](contributing/plugin-development.md) covers that path.

## Where to read more

| Resource | Path | When |
|---|---|---|
| Install to Infographic | [workflows/install-to-infographic.md](workflows/install-to-infographic.md) | New users, first-time setup |
| Ecosystem overview | [ecosystem-overview.md](ecosystem-overview.md) | "What plugins are available?", "How do they connect?" |
| Command reference | [command-reference.md](command-reference.md) | "What are the commands for cogni-X?" |
| Plugin guides | [plugin-guide/](plugin-guide/) | "How does cogni-X work?", full capabilities |
| Workflow guides | [workflows/](workflows/) | "How do I go from X to Y?" |
| Architecture | [architecture/](architecture/) | Structure and design principles |
| Contributing | [contributing/plugin-development.md](contributing/plugin-development.md) | Building a plugin |

For a multi-plugin task, name the sequence rather than a single plugin, and check whether one of the seven workflow guides already covers it.
