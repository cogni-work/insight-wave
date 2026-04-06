# cogni-marketing

B2B marketing content engine for [Claude Cowork](https://claude.ai/cowork). Bridges cogni-trends strategic themes and cogni-portfolio propositions into channel-ready content. Supports thought leadership, demand generation, lead generation, sales enablement, and ABM across markets with configurable brand voice. Bilingual DE/EN.

## Why this exists

Portfolio data and trend insights sit in structured JSON — but marketing teams need blog posts, whitepapers, battle cards, and campaigns. The gap between structured strategy and publishable content is where most B2B marketing stalls:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Strategy-to-content gap | Trend insights and portfolio propositions live in planning tools, not in content pipelines | Marketing content disconnected from actual product strategy |
| Channel fragmentation | Each channel (LinkedIn, email, web, events) needs different formats from the same core message | Manual reformatting burns hours per piece |
| Inconsistent brand voice | Different writers produce different tones across markets and formats | Brand dilution across touchpoints |
| No content coverage visibility | Teams can't see which market × theme × funnel stage combinations have content gaps | Wasted effort on saturated topics, blind spots on others |

This plugin automates the bridge: it reads your portfolio propositions and TIPS trend themes, generates content across 16 formats and 5 content types, orchestrates campaigns, and tracks coverage via a dashboard.

## What it is

A content generation bridge between strategy and execution in the insight-wave ecosystem. cogni-trends produces strategic themes (GTM paths); cogni-portfolio produces propositions and competitive intelligence. cogni-marketing consumes both and generates channel-ready content across five funnel stages — from thought leadership that builds awareness to battle cards that close deals. A 3D content matrix (market x GTM path x content type) ensures coverage visibility across the entire portfolio.

## What it does

1. **Setup** a marketing project linked to your cogni-portfolio and cogni-trends data — configure brand voice, select markets, map strategic themes to GTM paths → `marketing-project.json` → content-strategy, campaign-builder
2. **Strategize** by building a 3D content matrix (market × GTM path × content type) with auto-recommended formats and priority sequencing → `content-matrix.json` → campaign-builder, content-calendar
3. **Generate** content per type — thought leadership, demand generation, lead generation, sales enablement, or ABM — using parallel content-writer agents → `content-matrix.json` → campaign-builder, content-calendar
4. **Campaign** by orchestrating content into multi-channel campaigns with day-based timelines and phased funnel progression (attract → engage → convert) → `campaigns/*.json` → content-calendar, marketing-dashboard
5. **Schedule** via a content calendar with publication dates, channel assignments, and cadence tracking → `campaigns/*.json` → content-calendar, marketing-dashboard
6. **Track** coverage and progress through an interactive HTML dashboard → `output/dashboard.html` (interactive dashboard)

## What it means for you

- **Strategy-connected content.** Every piece traces back to a TIPS theme and portfolio proposition — no generic filler.
- **16 formats from one brief.** Blog posts, LinkedIn articles, whitepapers, battle cards, email nurtures, video scripts, carousels, and more — each adapted to channel conventions.
- **Parallel generation.** Content-writer agents run concurrently, producing a full content batch in minutes rather than days.
- **Coverage visibility.** The dashboard shows exactly where you have content and where you don't, across markets, themes, and funnel stages.
- **Bilingual.** Full DE/EN support with language-specific brand voice configuration.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- **cogni-portfolio** (required — provides propositions, markets, competitors)
- **cogni-trends** (required — provides strategic themes and trend data)
- Optional: **cogni-copywriting** (polish generated content), **cogni-narrative** (long-form arc transformation), **cogni-visual** (slides and visual assets), **cogni-claims** (evidence verification)

## Quick start

```
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

After installing, type one prompt:

> Set up a marketing project and generate a content strategy

Claude discovers your portfolio and TIPS data, configures brand voice defaults, builds a content matrix showing where content is needed, and recommends a generation sequence. Then generate content for any cell in the matrix.

Results land in your project directory:

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

## Components

| Component | Type | What it does |
|-----------|------|--------------|
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
| `marketing-resume` | skill | Resume a session — show status, gaps, and recommended next actions |
| `content-writer` | agent (sonnet) | Generates individual content pieces per format spec, brand voice, and source data |
| `channel-adapter` | agent (sonnet) | Adapts existing content to different channels while preserving core message |
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
| cogni-narrative | No | Arc-driven transformation for long-form thought leadership |
| cogni-visual | No | Slide decks and visual assets from content briefs |
| cogni-claims | No | Evidence verification for sourced claims in content |

## Contributing

Contributions welcome — content formats, channel adapters, brand voice presets, and documentation. See the [insight-wave contribution guide](https://github.com/cogni-work/insight-wave/blob/main/CONTRIBUTING.md) for guidelines.

## Custom development

Need custom content formats, CRM integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
