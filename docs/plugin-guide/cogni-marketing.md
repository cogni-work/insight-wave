# cogni-marketing

B2B marketing content engine — bridges strategy data into channel-ready content.

> For the canonical IS/DOES/MEANS positioning and installation instructions, see the [cogni-marketing README](../../cogni-marketing/README.md).

---

## Overview

cogni-marketing sits at the execution layer of the insight-wave ecosystem. cogni-portfolio holds your product propositions, markets, and competitive intelligence. cogni-trends holds your strategic themes and trend evidence. cogni-marketing reads both and produces the content your marketing team actually publishes.

The bridge is a 3D content matrix: market × GTM path × content type. Each cell in the matrix represents a specific combination — for example, "enterprise manufacturing in DACH, using the AI automation theme, awareness stage" — and the plugin tracks whether content exists for that combination. You generate content per cell, run campaigns that sequence cells into multi-channel initiatives, schedule publications in an editorial calendar, and view the overall coverage picture in an HTML dashboard.

All content traces back to source data: every piece carries frontmatter linking it to the TIPS claim IDs and portfolio proposition IDs that informed it. This means content is not generic filler — it is grounded in the same evidence your analysts produced.

### When to reach for this plugin

- You have a portfolio and trend data and need to generate marketing content from them
- You want to see where your content coverage has gaps across markets, themes, and funnel stages
- You need to run a coordinated multi-channel campaign and track it
- You need multilingual content (bilingual local+EN, e.g. DE/EN) with consistent brand voice across formats and markets

### Prerequisites

cogni-marketing requires two upstream plugins to be set up first:

- **cogni-portfolio** — provides products, propositions, markets, customers, and competitors
- **cogni-trends** — provides strategic themes (GTM paths), trend data, and TIPS claims

---

## Key Concepts

### 3D content matrix

The content matrix maps three dimensions:

- **Market** — a geographic and segment definition from your portfolio (e.g., "enterprise-manufacturing-dach")
- **GTM path** — a strategic theme from cogni-trends value-modeler output (e.g., "ai-automation")
- **Content type** — the funnel stage category: thought leadership, demand generation, lead generation, sales enablement, or ABM

Each cell in the matrix can hold multiple content pieces in different formats. The matrix shows planned vs. generated counts per cell, so you can see gaps at a glance.

### Content types and funnel stages

| Content type | Funnel stage | Formats |
|-------------|-------------|---------|
| Thought leadership | Awareness | Blog, LinkedIn article, keynote abstract, podcast outline, op-ed |
| Demand generation | Awareness / consideration | SEO article, LinkedIn post, carousel, video script, infographic spec |
| Lead generation | Consideration | Whitepaper, landing page, email nurture, webinar outline, gated checklist |
| Sales enablement | Decision | Battle card, one-pager, demo script, objection handler, proposal section |
| ABM | Full funnel | Account plan, personalised email, executive briefing, custom landing page |

### Project structure

When you initialise a marketing project, all output lands in a structured directory:

```
cogni-marketing/{project-slug}/
├── marketing-project.json       Brand config, source links, markets, GTM paths
├── content-strategy.json        3D content matrix with priorities and status
├── content/
│   ├── thought-leadership/
│   ├── demand-generation/
│   ├── lead-generation/
│   ├── sales-enablement/
│   └── abm/
├── campaigns/                   Multi-channel campaign definitions (JSON)
├── calendar/                    Editorial calendar (YAML + rendered MD)
└── output/
    └── dashboard.html           Interactive coverage dashboard
```

Content files follow the naming convention `{market}--{gtm-path}--{format}.md` and carry YAML frontmatter with type, format, funnel stage, language, brand voice, and source traceability.

### Brand voice

Brand voice is configured once at setup and applied consistently across all generated content. Tone modifiers vary by format category (formal for whitepapers, conversational for social posts) but the core voice — language, register, approved terminology — stays constant.

---

## Getting Started

Start by initialising a marketing project linked to your portfolio and trend data:

```
/marketing-setup
```

Expected interaction:

1. The skill scans for cogni-portfolio projects (`portfolio.json`) and cogni-trends projects (`tips-project.json`) in the workspace
2. It lists what it found and asks you to confirm sources
3. You configure brand voice: company name, output language (inherited from the selected market), tone descriptors, avoided terms
4. You select markets from the portfolio
5. For each market, you map TIPS strategic themes to GTM paths
6. The project directory is scaffolded

Then build the content matrix:

```
/content-strategy
```

The skill reads your portfolio propositions and TIPS themes, builds the matrix, identifies which cells are highest priority, and recommends a generation sequence.

---

## Capabilities

### marketing-setup — Initialise a marketing project

Discovers available portfolio and trend data, configures brand voice, selects markets, maps GTM paths, and scaffolds the project directory.

**Example prompt:**
```
Set up a marketing project for our cloud portfolio
```

Run once at the start of a new marketing project. Re-run if you add markets or change the brand voice configuration.

### content-strategy — Build the 3D content matrix

Reads portfolio propositions and TIPS themes, builds the market × GTM path × content type matrix, detects gaps, and recommends a generation sequence.

**Example prompt:**
```
/content-strategy
```

Output: `content-strategy.json` with all planned content pieces, their priorities, and generation status. The dashboard visualises this matrix as a heatmap.

### thought-leadership — Generate awareness-stage content

Creates expert-positioning content (blogs, LinkedIn articles, keynote abstracts, podcasts, op-eds) grounded in TIPS trend data.

**Example prompt:**
```
Generate a thought leadership blog post for the AI automation theme in the DACH manufacturing market
```

The content-writer agent uses the TIPS claim evidence and portfolio domain authority to write content that educates without hard-selling. Format-specific length and structure rules apply automatically.

### demand-generation — Generate social and search content

Creates high-frequency, channel-optimised content (SEO articles, LinkedIn posts, carousels, video scripts) that drives traffic and engagement.

**Example prompt:**
```
/demand-gen
```

The skill asks which market, GTM path, and format you want, then generates accordingly. SEO articles use a dedicated `seo-researcher` agent for live keyword research.

### lead-generation — Generate gated conversion content

Creates consideration-stage content (whitepapers, landing pages, email nurtures, webinar outlines) designed to convert interest into qualified leads.

**Example prompt:**
```
Create a whitepaper on AI automation for enterprise manufacturing — 3,000 words, DACH market, German language
```

Whitepapers embed TIPS claim citations inline as `[claim_id](source_url)` markers. Lead generation content requires portfolio solutions to be populated for the target market.

### sales-enablement — Generate decision-stage content for sales teams

Creates internal-facing materials (battle cards, one-pagers, demo scripts, objection handlers) that give sales teams competitive intelligence and deal-closing tools.

**Example prompt:**
```
Create a battle card for our AI automation solution against the top three competitors in the enterprise manufacturing market
```

This skill reads competitor data from the portfolio's compete phase. Battle cards follow a standard structure: their situation, their objections, your differentiators, proof points.

### abm — Generate account-based content for named accounts

Creates hyper-personalised content (account plans, personalised email sequences, executive briefings) tailored to specific companies.

**Example prompt:**
```
Build an account plan for Siemens Energy targeting the AI automation theme
```

The skill reads the named customer profile from the portfolio and uses web research to add company-specific context. ABM content spans the full funnel — one account, all stages.

### campaign-builder — Orchestrate content into multi-channel campaigns

Assembles existing and new content pieces into a coordinated campaign with day-based timing, touch sequences, and phased funnel progression (attract → engage → convert).

**Example prompt:**
```
/campaign
```

Output: a campaign definition JSON with channel assignments, day offsets per touchpoint, and content piece references. One campaign covers one market × one GTM path combination.

### content-calendar — Generate and manage an editorial calendar

Turns the campaign timelines and content matrix into a dated, channel-assigned publication schedule.

**Example prompt:**
```
/content-calendar
```

Output: `calendar/content-calendar.yaml` (machine-readable) and `calendar/content-calendar.md` (human-readable). CSV export available for import into HubSpot, Notion, or Asana.

### marketing-dashboard — Visualise content coverage and progress

Generates an interactive HTML dashboard with five views: coverage heatmap, campaign progress, funnel distribution, channel mix, and production status.

**Example prompt:**
```
/marketing-dashboard
```

Output: `output/dashboard.html` — a self-contained HTML file with inline CSS and vanilla JavaScript, no external dependencies. Open in any browser.

### marketing-resume — Re-enter an existing project session

Shows current project status, identifies gaps, and recommends the highest-priority next action. Designed for multi-session workflows.

**Example prompt:**
```
Resume my marketing project and tell me what to work on next
```

Useful when returning to a project after days or weeks. The skill reads all project files and presents a concise status block before asking how to proceed.

---

## Integration Points

### Upstream inputs (required)

| Plugin | What cogni-marketing reads |
|--------|---------------------------|
| cogni-portfolio | Products, features, propositions, solutions, markets, competitors, customer profiles |
| cogni-trends | Strategic themes (GTM paths), TIPS claims with source URLs, trend evidence |

### Upstream inputs (optional enrichment)

| Plugin | Purpose |
|--------|---------|
| cogni-claims | Verifies that TIPS claims embedded in content are still supported by their sources |

### Downstream consumers

| Plugin | How it uses cogni-marketing output |
|--------|-----------------------------------|
| cogni-copywriting | Polishes generated content pieces with messaging frameworks before publication |
| cogni-narrative | Transforms long-form thought leadership briefs into arc-structured narratives |
| cogni-visual | Converts content briefs and keynote abstracts into slide decks and visual assets |

---

## Common Workflows

### Strategy to first content batch

The standard onboarding sequence for a new marketing project:

1. `/marketing-setup` — connect portfolio and trend sources, configure brand voice, select markets
2. `/content-strategy` — build the matrix; review the priority recommendations
3. `/thought-leadership` for the highest-priority GTM path — generates 2-3 anchor pieces
4. `/demand-gen` — derive social content from the anchor pieces
5. `/marketing-dashboard` — review coverage; identify remaining gaps

See [../workflows/portfolio-to-content.md](../workflows/portfolio-to-content.md) for the full end-to-end pipeline.

### Campaign launch for a specific GTM path

When you need a coordinated push around one theme:

1. Ensure content exists for the target market × GTM path combination (run `marketing-resume` to check)
2. `/campaign` — build the multi-channel campaign; review the touchpoint timeline
3. `/content-calendar` — add campaign dates to the editorial calendar
4. Generate any content pieces the campaign references but doesn't have yet
5. `/marketing-dashboard` — verify campaign coverage before launch

### ABM preparation for a named account

Before a major account pursuit:

1. Confirm the account exists in the portfolio customer profiles (`customers/{market}.json`)
2. `/abm` — specify account name and GTM path; receive account plan, personalised email sequence, executive briefing
3. Pass the executive briefing to `/copywrite` (cogni-copywriting) for a final polish pass
4. Use cogni-sales' `/why-change` skill to build the deal-specific pitch on the same foundation

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| marketing-setup finds no portfolio projects | cogni-portfolio project not in workspace | Run cogni-portfolio setup first; ensure `portfolio.json` exists in the workspace directory tree |
| marketing-setup finds no TIPS projects | cogni-trends value-modeler not completed | Complete the value-modeler step in cogni-trends before running marketing-setup |
| Content is generated but has no citations | Format does not require evidence markers | Only formats with `evidence: true` in the data model embed citations; battle cards and social posts do not |
| SEO article quality is poor | seo-researcher agent could not access live search | Verify web search is enabled in your Claude Code environment |
| Dashboard does not reflect latest generated files | Dashboard was generated before latest content | Re-run `/marketing-dashboard` — it re-reads all content files each time |
| German content uses English structure | Brand language set to EN during setup | Re-run `/marketing-setup` and set `language: de`; or edit `marketing-project.json` directly |
| Content calendar dates conflict | Campaign day offsets produce overlapping publication dates | Edit `campaigns/*.json` to adjust day offsets; re-run `/content-calendar` |
| Named account not found during ABM | Customer not in portfolio's named_customers list | Add the account to `customers/{market}.json` via cogni-portfolio; or specify the company name directly when prompted |

---

## Extending This Plugin

Contribution areas with the most impact:

- **New content formats** — Add a format entry to `references/data-model.md` with its word range, evidence flag, and tone modifier; update the relevant skill's format list
- **New channel adapters** — The `channel-adapter` agent can be extended to handle additional channels (e.g., newsletter, podcast show notes) with format-specific rules
- **Brand voice presets** — Add preset configurations for common B2B voice archetypes to `skills/marketing-setup/references/` so teams can select a preset rather than configure from scratch
- **CRM integration** — The content calendar YAML output is designed for export; a new adapter skill could push calendar entries to HubSpot, Salesforce, or Notion directly

See [../../CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.
