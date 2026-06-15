# cogni-marketing

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-marketing:marketing-resume` for project status and next-step guidance — whether you're starting fresh or returning to an in-progress project.

A B2B marketing content engine that turns cogni-trends strategic themes and cogni-portfolio propositions into channel-ready content — the bridge from structured strategy to publishable work.

> **Multi-market & multilingual.** cogni-marketing inherits the target market from cogni-portfolio — European-first across DACH/DE/FR/IT/ES/NL/PL plus UK/US — and produces bilingual DE/EN content with per-market brand voice. See [Supported markets & languages](../cogni-workspace/README.md#supported-markets--languages).

## Why this exists

Portfolio data and trend insights sit in structured JSON — but marketing teams need blog posts, whitepapers, battle cards, and campaigns. The gap between structured strategy and publishable content is where most B2B marketing stalls. The strategy already exists; the work of turning it into channel-ready pieces, market by market, is what never quite gets done:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Strategy-to-content gap | Trend insights and portfolio propositions live in planning tools, not in content pipelines | Marketing content disconnected from actual product strategy |
| Channel fragmentation | Each channel (LinkedIn, email, web, events) needs different formats from the same core message | Manual reformatting burns hours per piece |
| Inconsistent brand voice | Different writers produce different tones across markets and formats | Brand dilution across touchpoints |
| No content coverage visibility | Teams can't see which market × theme × funnel stage combinations have content gaps | Wasted effort on saturated topics, blind spots on others |

Every piece below is a symptom of the same root cause: strategy and content live in two different places, and bridging them by hand does not scale.

## What it is

A content-generation bridge between strategy and execution in the insight-wave ecosystem. cogni-trends produces strategic themes (GTM paths) and cogni-portfolio produces propositions and competitive intelligence; cogni-marketing is the consumer that sits downstream of both. Its organizing model is a 3D content matrix — market × GTM path × content type — so every piece traces back to a theme and a proposition, and coverage stays visible across the whole portfolio.

## What it does

1. **Setup** a marketing project linked to your cogni-portfolio and cogni-trends data — configure brand voice, select markets, map strategic themes to GTM paths → `marketing-project.json` → content-strategy, campaign-builder
2. **Strategize** by building a 3D content matrix (market × GTM path × content type) with auto-recommended formats and priority sequencing → `content-matrix.json` → campaign-builder, content-calendar
3. **Generate** content per type — thought leadership, demand generation, lead generation, sales enablement, or ABM — using parallel content-writer agents → `content/{type}/*.md` → campaign-builder, content-calendar
4. **Campaign** by orchestrating content into multi-channel campaigns with day-based timelines and phased funnel progression (attract → engage → convert) → `campaigns/*.json` → content-calendar, marketing-dashboard
5. **Schedule** via a content calendar with publication dates, channel assignments, and cadence tracking → `calendar/*.yaml` → marketing-dashboard
6. **Track** coverage and progress through an interactive HTML dashboard → `output/dashboard.html` (interactive dashboard)

## What it means for you

- **Connect every piece to strategy.** Each generated piece traces back to a TIPS theme and a portfolio proposition — no generic filler, no orphan posts.
- **Generate 16 formats from one brief.** Blogs, LinkedIn articles, whitepapers, battle cards, email nurtures, video scripts, carousels, and more — each adapted to channel conventions in a single run.
- **Run content batches in parallel.** Content-writer agents run concurrently, producing a full batch in minutes instead of the days a sequential workflow takes.
- **See coverage gaps at a glance.** The dashboard maps which market × GTM path × content type combinations have content and which don't, on one screen.
- **Publish bilingual without re-authoring.** DE/EN support with language-specific brand voice — one strategy, two languages, no manual translation pass.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/cogni-marketing:marketing-resume   # ← entry point: status + next step
/marketing-setup                # initialize project from portfolio + TIPS data
/content-strategy               # build the content matrix
/thought-leadership             # generate awareness-stage content
/demand-gen                     # generate engagement content (LinkedIn, SEO, carousels)
/lead-gen                       # generate gated content (whitepapers, landing pages, nurtures)
/sales-enablement               # generate decision-stage content (battle cards, one-pagers)
/abm                            # generate account-based content for named accounts
/campaign                       # orchestrate content into campaigns
/content-calendar               # schedule and manage editorial calendar
/marketing-dashboard            # visualize coverage and progress
```

Or describe what you want in natural language:

- "Set up a marketing project for our cloud portfolio"
- "Generate thought leadership content for the AI automation theme"
- "Build a demand gen campaign for the DACH mid-market"
- "Show me our content coverage gaps"

## Try it

Set up a project, then run the resume skill to see where you stand:

> Run `/cogni-marketing:marketing-setup`, then `/cogni-marketing:marketing-resume`

Setup discovers your cogni-portfolio and cogni-trends data, configures brand voice defaults, and writes `marketing-project.json`. The resume skill then reports project status, content gaps, and the recommended next step:

```
cogni-marketing — DACH/EN, 2 GTM paths
  Strategy: content-matrix.json present — 18 cells, 3 with content
  Gap: lead-generation (consideration stage) — 0 of 6 cells filled
  Next: /cogni-marketing:content-strategy, then /cogni-marketing:lead-gen
```

Generate content for any cell — e.g. `/cogni-marketing:thought-leadership` for awareness pieces — and content-writer agents produce the batch in parallel, each piece following its format spec and your configured brand voice. Because the matrix knows which cells are filled, you can keep generating until coverage is complete and watch the gap report shrink run by run. When you are ready to publish, the campaign-builder and content-calendar skills sequence the pieces into multi-channel timelines. Results land in your project directory:

```
cogni-marketing/{project-slug}/
├── marketing-project.json       Brand config, sources, markets, GTM paths
├── content-strategy.json        3D matrix with narrative angles and status
├── content/
│   ├── thought-leadership/      Awareness-stage content pieces
│   ├── demand-generation/       Engagement content (LinkedIn, SEO, carousels)
│   ├── lead-generation/         Gated content (whitepapers, nurtures)
│   ├── sales-enablement/        Decision-stage content (battle cards, one-pagers)
│   └── abm/                     Account-based content
├── campaigns/                   Multi-channel campaign definitions
├── calendar/                    Editorial calendar (YAML + rendered MD)
└── output/
    └── dashboard.html           Interactive coverage dashboard
```

## Data model

Content pieces are markdown files with YAML frontmatter tracking type, format, market, GTM path, funnel stage, language, brand voice, and source traceability back to TIPS claims and portfolio propositions. See [references/data-model.md](references/data-model.md) for the full schema.

16 content formats: blog, linkedin-article, linkedin-post, whitepaper, email-nurture, landing-page, battle-card, one-pager, webinar-outline, carousel, video-script, keynote-abstract, podcast-outline, demo-script, objection-handler, executive-briefing.

## How it works

The pipeline runs in dependency order: `marketing-setup → content-strategy → content generators → campaign-builder → content-calendar → marketing-dashboard`. Setup comes first because everything downstream needs a single source of truth — `marketing-setup` reads cogni-portfolio propositions and cogni-trends themes, resolves brand voice and markets, and writes `marketing-project.json`.

`content-strategy` then builds the 3D matrix (market × GTM path × content type) and detects gaps, so the generators always know which cells are empty and in what priority order to fill them. The five content generators — thought-leadership, demand-generation, lead-generation, sales-enablement, and abm — map to the five funnel stages; each dispatches content-writer agents in parallel against a format spec, the resolved brand voice, and the cited source data. Generation is sharded per cell so a batch can run concurrently rather than one piece at a time.

Downstream, `campaign-builder` sequences finished pieces into multi-channel campaigns with phased funnel progression (attract → engage → convert), `content-calendar` assigns publication dates and channels, and `marketing-dashboard` renders coverage across the whole matrix. The ordering matters: campaigns can only sequence content that exists, and the dashboard can only report coverage once the matrix and the generated pieces are both in place. Source traceability is carried in each file's YAML frontmatter, so a TIPS claim or proposition can be traced from any published piece back to its origin.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `marketing-resume` | skill | Resume a session — show status, gaps, and recommended next actions |
| `marketing-setup` | skill | Initialize project from portfolio + TIPS data, configure brand voice and markets |
| `content-strategy` | skill | Build 3D content matrix with gap detection and priority sequencing |
| `thought-leadership` | skill | Generate awareness-stage content (blogs, keynotes, op-eds, podcasts) |
| `demand-generation` | skill | Generate engagement content (LinkedIn posts, SEO articles, carousels, video scripts) |
| `lead-generation` | skill | Generate gated content (whitepapers, landing pages, email nurtures, webinars) |
| `sales-enablement` | skill | Generate decision-stage content (battle cards, one-pagers, demo scripts, objection handlers) |
| `abm` | skill | Generate account-based content (account plans, personalized emails, executive briefings) |
| `campaign-builder` | skill | Orchestrate content into multi-channel campaigns with phased funnel progression |
| `content-calendar` | skill | Generate and manage editorial calendar with cadence tracking |
| `marketing-dashboard` | skill | Interactive HTML dashboard for coverage and progress visualization |
| `content-writer` | agent (sonnet) | Generates individual content pieces per format spec, brand voice, and source data |
| `channel-adapter` | agent (haiku) | Adapts existing content to different channels while preserving core message |
| `seo-researcher` | agent (sonnet) | Researches SEO keywords and competitor content for GTM path/market combinations |
| `/marketing-setup` | command | Initialize a cogni-marketing project with brand, markets, and GTM paths |
| `/content-strategy` | command | Build the content matrix (market x GTM path x content type) with format recommendations |
| `/thought-leadership` | command | Generate thought leadership content (blog, LinkedIn article, keynote, podcast, op-ed) |
| `/demand-gen` | command | Generate demand generation content (LinkedIn posts, SEO articles, carousels, video scripts) |
| `/lead-gen` | command | Generate lead generation content (whitepapers, landing pages, email nurture, webinars) |
| `/sales-enablement` | command | Generate sales enablement content (battle cards, one-pagers, demo scripts, objection handlers) |
| `/abm` | command | Generate account-based marketing content (account plans, personalized emails, executive briefings) |
| `/campaign` | command | Build a multi-channel campaign with touch sequences and timeline |
| `/content-calendar` | command | Generate or update the editorial content calendar |
| `/marketing-dashboard` | command | Generate interactive HTML dashboard visualizing content coverage and campaign progress |
| `/marketing-resume` | command | Resume a marketing project — show status, content gaps, and recommended next action |

## Architecture

```
cogni-marketing/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       11 marketing skills
│   ├── marketing-setup/
│   ├── content-strategy/
│   ├── thought-leadership/
│   ├── demand-generation/
│   ├── lead-generation/
│   ├── sales-enablement/
│   ├── abm/
│   ├── campaign-builder/
│   ├── content-calendar/
│   ├── marketing-dashboard/
│   └── marketing-resume/
├── agents/                       3 content agents
│   ├── content-writer.md
│   ├── channel-adapter.md
│   └── seo-researcher.md
├── commands/                     11 slash commands
└── references/                   Data model + marketing frameworks
    ├── data-model.md
    └── content-formats.md
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-portfolio | Yes | Products, propositions, markets, competitors, solutions |
| cogni-trends | Yes | Strategic themes (Handlungsfelder), trend data, claims |
| cogni-copywriting | No | Polish generated content with messaging frameworks |
| cogni-visual | No | Slide decks and visual assets from content briefs |

## Contributing

Contributions welcome — content formats, channel adapters, brand voice presets, and documentation. See the [insight-wave contribution guide](https://github.com/cogni-work/insight-wave/blob/main/CONTRIBUTING.md) for guidelines.

## Custom development

Need custom content formats, a CRM integration, or a marketing engine tailored to your channels and markets? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for B2B marketing teams.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
