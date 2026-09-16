# cogni-marketing

B2B marketing content engine — bridges cogni-trends strategic themes and cogni-portfolio propositions into channel-ready content across five funnel stages.

## Plugin Architecture

```
skills/                         11 marketing skills
  marketing-setup/                Initialize project from portfolio + TIPS data, configure brand voice
  content-strategy/               Build 3D content matrix (market x GTM path x content type)
  thought-leadership/             Awareness content: blogs, LinkedIn articles, keynotes, podcasts, op-eds
  demand-generation/              Engagement content: SEO articles, LinkedIn posts, carousels, video scripts
  lead-generation/                Gated content: whitepapers, landing pages, email nurtures, webinars
  sales-enablement/               Decision content: battle cards, one-pagers, demo scripts, objection handlers
  abm/                            Account-based: account plans, personalized emails, executive briefings
  campaign-builder/               Multi-channel campaigns with day-based timelines
  content-calendar/               Editorial calendar with publication dates and cadence tracking
  marketing-dashboard/            Interactive HTML dashboard for coverage and progress
  marketing-resume/               Resume session — status, gaps, recommended next actions

agents/                         3 content agents
  content-writer.md               Generates individual content pieces per format spec and brand voice
  channel-adapter.md              Adapts existing content to different channels preserving core message
  seo-researcher.md               Researches keywords and competitor content for GTM path/market combos

commands/                       11 slash commands
references/
  data-model.md                   Full schema: project structure, content formats, tone modifiers
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 11 | marketing-setup, content-strategy, thought-leadership, demand-generation, lead-generation, sales-enablement, abm, campaign-builder, content-calendar, marketing-dashboard, marketing-resume |
| Agents | 3 | content-writer, channel-adapter, seo-researcher |
| Commands | 11 | marketing-setup, content-strategy, thought-leadership, demand-gen, lead-gen, sales-enablement, abm, campaign, content-calendar, marketing-dashboard, marketing-resume |

## Data Model

Each project lives in `cogni-marketing/{project-slug}/` with:
- `marketing-project.json` — Root manifest (brand config, sources, selected markets, GTM paths)
- `content-strategy.json` — 3D content matrix with priority sequencing
- `content/` — Generated content by type (thought-leadership, demand-generation, lead-generation, sales-enablement, abm)
- `campaigns/` — Multi-channel campaign definitions (JSON)
- `calendar/` — Editorial calendar (YAML source + rendered markdown)
- `output/` — Dashboard HTML and exports
- `.logs/` — SEO research results per market

Content files follow the naming convention: `{market}--{gtm-path}--{format}.md`

## Content Format Matrix

| Content Type | Funnel Stage | Formats | Word Range |
|-------------|-------------|---------|------------|
| Thought Leadership | awareness | blog, linkedin-article, keynote-abstract, podcast-outline, op-ed | 150-1200 |
| Demand Generation | awareness/consideration | seo-article, linkedin-post, carousel, video-script, infographic-spec | 200-1500 |
| Lead Generation | consideration | whitepaper, landing-page, email-nurture, webinar-outline, gated-checklist | 150-4000 |
| Sales Enablement | decision | battle-card, one-pager, demo-script, objection-handler, proposal-section | 300-600 |
| ABM | full-funnel | account-plan, personalized-email, executive-briefing, custom-landing-page | 150-1000 |

Formats with `evidence: true` embed TIPS claims inline as `[claim_id](source_url)` markers.

## Cross-Plugin Integration

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-portfolio | Yes | Products, propositions, markets, competitors, solutions, customer profiles |
| cogni-trends | Yes | Strategic themes (GTM paths), trend data, TIPS claims with sources |
| cogni-workspace | No | Evidence verification for sourced claims via `cogni-workspace:claims` |
| cogni-publishing | No | Copy polish, arc narratives, theme selection, and design briefs/rendered assets |

## Key Conventions

- Brand voice configured once at setup, applied consistently across all content
- Tone modifiers per format category (formal for whitepapers, conversational for social)
- Bilingual DE/EN: German follows Wolf Schneider principles, English follows AP/Chicago style
- Evidence integration: quantitative claims with source URLs when format requires it
- Content-writer agents follow format specs strictly — no improvised structure
- SEO research uses live web search, not training knowledge
