---
id: plugin-cogni-marketing
title: "cogni-marketing (plugin)"
type: entity
tags: [cogni-marketing, plugin, marketing, content-marketing, b2b, gtm, campaigns, bilingual]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/cogni-marketing/README.md
  - https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-marketing.md
status: stable
---

> **Incubating** (v0.0.2) — skills may change or be removed at any time.

B2B marketing content engine that bridges cogni-trends strategic themes (GTM paths) and cogni-portfolio propositions into channel-ready content. Supports thought leadership, demand generation, lead generation, sales enablement, and ABM across markets with configurable brand voice. Bilingual DE/EN.

## Layer

[[concept-four-layer-architecture|Output layer]]. Consumes data from cogni-trends (themes) and cogni-portfolio (propositions), produces content for human channels.

## Skills (11)

- **Setup & status**: `marketing-setup`, `marketing-resume`, `marketing-dashboard`
- **Strategy**: `content-strategy` (build the content matrix: market × GTM path × content type), `content-calendar` (publication dates, channel assignment, cadence)
- **Campaign**: `campaign-builder` (multi-channel orchestration with day-based timelines)
- **Content per funnel stage**:
  - `thought-leadership` — blogs, LinkedIn articles, keynotes, podcasts, op-eds
  - `demand-generation` — SEO articles, LinkedIn posts, carousels, video scripts, infographic specs
  - `lead-generation` — whitepapers, landing pages, email nurture, webinars, gated checklists
  - `sales-enablement` — battle cards, one-pagers, demo scripts, objection handlers, proposal sections
  - `abm` — account plans, personalized email sequences, executive briefings

## Strategy framing

Marketing content is generated against a market × GTM path × content type matrix. GTM paths come from cogni-trends investment themes; markets come from cogni-portfolio markets; content types are the funnel stages above. The `marketing-dashboard` visualizes coverage across this matrix.

## Brand voice

Configurable per project. The setup skill discovers cogni-trends and cogni-portfolio sources, captures brand voice, and selects markets with their GTM paths.

## Integration

Upstream: cogni-trends (TIPS investment themes as GTM paths), cogni-portfolio (propositions, customer profiles, competitor analysis). Downstream: cogni-workspace (content arcs and a Claude Design brief for slides or infographics via its `text-to-narrative` skill, polish via `copywriter`), cogni-website (landing page content).

**Source**: [cogni-marketing README](https://github.com/cogni-work/insight-wave/blob/main/cogni-marketing/README.md) · [plugin guide](https://github.com/cogni-work/insight-wave/blob/main/docs/plugin-guide/cogni-marketing.md)
