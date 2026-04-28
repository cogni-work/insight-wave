# Tour: Trends to Solutions

**Duration**: 75 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-trends → cogni-portfolio → cogni-marketing
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-trends`, `/cogni-help:cheatsheet cogni-portfolio`, `/cogni-help:cheatsheet cogni-marketing`; see also the matching `docs/plugin-guide/<plugin>.md` files.
**Audience**: GTM teams turning strategic trends into marketing campaigns

---

This tour walks the trends-to-solutions pipeline as a single workflow. You scout
strategic trends, anchor them to portfolio propositions, and fan them out into
multi-channel marketing content — all sourced from the same evidence trail.
The cheatsheets and `docs/plugin-guide/<plugin>.md` files cover each plugin in depth;
this tour focuses on the hand-offs between them.

## Module 1: Pipeline Overview & TIPS Foundations

### Theory (6 min)

The trends-to-solutions pipeline chains three plugins around a single thread of
evidence: `cogni-trends` produces investment themes (Handlungsfelder) backed by
trend signals; `cogni-portfolio` translates themes into market-specific propositions;
`cogni-marketing` produces channel-ready content tagged with both trend and proposition
provenance.

The TIPS framework — Technology, Innovation, People, Strategy — drives trend scouting.
Each scouted trend is scored on multi-framework criteria (TIPS dimension, Ansoff
matrix, Rogers adoption curve, CRAAP source quality). The output isn't a single ranked
list; it's investment themes that bundle related trends into a strategic narrative.

For trends-to-solutions, the connecting fiber is the investment theme. A theme drives
which propositions you build (Step 2) and which campaigns you launch (Step 3). Without
themes, you produce content for whatever felt interesting last week.

### Demo

Walk the audience through the data flow:
1. Open an existing TIPS project, find one investment theme.
2. Open a portfolio project, find a proposition that traces back to that theme.
3. Open a marketing campaign, find content that cites both the theme and the proposition.

If the team has no TIPS project yet, sketch the chain on a whiteboard: theme →
proposition → campaign content. The artifacts come alive in Module 2.

### Exercise

Ask the learner to identify three industry shifts they think matter for the next 12
months. Don't research them yet — just name them. We'll test in Module 2 whether
cogni-trends produces matching evidence.

### Quiz

1. Why does the pipeline anchor on investment themes rather than individual trends?
   **Answer**: Themes bundle related trends into a strategic narrative; individual
   trends produce fragmented content with no through-line.

2. **Multiple choice**: A team scouts 60 trends, scores them on TIPS dimensions, and
   produces 4 themes. What's the next plugin in the pipeline?
   - a) cogni-marketing — b) cogni-portfolio — c) cogni-narrative — d) cogni-research
   **Answer**: b (themes hand off to portfolio for proposition mapping)

### Recap

- The pipeline anchors on investment themes, not raw trends
- TIPS framework drives multi-dimensional scoring (T/I/P/S, Ansoff, Rogers, CRAAP)
- Provenance flows: theme → proposition → campaign content

---

## Module 2: Scout Trends and Lock Themes (cogni-trends)

### Theory (8 min)

`cogni-trends` runs a multi-phase scouting workflow: bilingual web research (DE/EN)
across regional authority sources, signal curation, candidate generation (60 trends
scored across frameworks), stakeholder review, deep research on top candidates, and
investment-theme construction.

For DACH/EU markets, the regional authority source set is critical — `fraunhofer.de`,
`bitkom.org`, `vdma.org`, `destatis.de`, `handelsblatt.com` produce different
evidence than the EN/US default. Set `region` in the scout configuration.

The output of `/scout` is not a trend report; it's the input to `/report`, which
generates a polished trend report organized around themes (Handlungsfelder). For
trends-to-solutions, the themes are what cogni-portfolio consumes — the report is
optional unless stakeholders want a written justification.

### Demo

Run `/scout` against an industry the team cares about:
1. Configure: industry, language (DE/EN), region (DACH/US/EU), depth.
2. Watch the phases: web research → signal curation → 60 candidates → stakeholder
   review → deep research → investment themes.
3. Open the produced TIPS project — show the candidates table, the agreed themes,
   and the per-theme evidence pack.

If `/scout` already ran for this industry, use `/trends-resume` to skip to the
themes view.

### Exercise

Ask the learner to compare the themes cogni-trends produced to the three shifts they
named in Module 1. How many overlap? Where did cogni-trends find evidence the learner
didn't anticipate?

### Quiz

1. Why is the regional authority source set important for DACH scouting?
   **Answer**: DACH-specific sources (Fraunhofer, BITKOM, VDMA) surface evidence
   the EN/US default sources miss; without them, the scout produces a US-flavored
   view of a DACH market.

2. **Hands-on**: Open one investment theme and read the evidence trail. Find one
   trend signal that contradicts a common industry narrative.

### Recap

- `/scout` produces 60 scored candidates → reviewed → top candidates deep-researched → themes
- Regional authority sources matter — set `region` correctly for DACH/EU
- Themes (Handlungsfelder) are the hand-off to cogni-portfolio
- `/report` is optional; themes feed the next pipeline stage directly

---

## Module 3: Anchor Themes to Propositions (cogni-portfolio)

### Theory (6 min)

`cogni-portfolio` builds a structured product/market model — features (IS, market-
independent), advantages (DOES, market-specific), benefits (MEANS, market-specific).
The IS/DOES/MEANS triangle is what you sell.

For trends-to-solutions, the connecting move is binding investment themes to
propositions. A theme like "Edge AI for industrial maintenance" maps to features
(predictive-maintenance models, edge runtime, anomaly detection), advantages
(downtime reduction, data sovereignty), and benefits (uptime guarantees, regulatory
fit). One theme can drive multiple propositions across markets.

The `trends-bridge` skill imports TIPS themes as portfolio anchors — solution
templates from cogni-trends become structured features in cogni-portfolio. This
keeps provenance: every proposition traces to the trend evidence that justified it.

### Demo

Run `/portfolio-setup` (or `/portfolio-resume` if one exists) and the proposition
chain:
1. Confirm the portfolio project is configured for the target market(s).
2. Run `/trends-bridge` to import TIPS themes as portfolio anchors.
3. Run `/propositions` to generate IS/DOES/MEANS for one Feature × Market pair.
4. Open the produced proposition file — show the trend evidence in the lineage block.

### Exercise

Have the learner pick one TIPS theme and one of their target markets. Predict the
proposition's DOES (advantage) and MEANS (benefit) before running `/propositions`.
Compare against what the agent generates.

### Quiz

1. Why are features (IS) market-independent but advantages (DOES) and benefits (MEANS)
   market-specific?
   **Answer**: Features are what the product technically does; advantages and benefits
   are how the market interprets value, which varies by buyer context.

2. **Hands-on**: Open one proposition file and trace its lineage backward — find the
   TIPS theme it imported from and the trend signals that justified the theme.

### Recap

- IS = market-independent features, DOES/MEANS = market-specific advantages and benefits
- `trends-bridge` imports TIPS themes as portfolio anchors (provenance preserved)
- One theme drives multiple propositions across markets
- Proposition files include source lineage — corrections cascade

---

## Module 4: Generate Marketing Content (cogni-marketing)

### Theory (6 min)

`cogni-marketing` operates on a 3D content matrix: markets × GTM paths × content
formats. With propositions and themes in place, the matrix surfaces gaps — which
market × GTM-path × format intersections lack content. The strategy step
(`/content-strategy`) converts the matrix into a prioritized content plan.

Per funnel stage, dedicated skills produce content: `/thought-leadership` for
awareness, `/demand-gen` for engagement, `/lead-gen` for conversion,
`/sales-enablement` for decision, `/abm` for account-specific work. Each piece
references the propositions and themes it draws from — content traces back to
data, not to a writer's intuition.

For DACH content, language is set in the marketing brief — German content
auto-applies Wolf Schneider rules with Amstad readability scoring.

### Demo

Run `/marketing-setup` followed by `/content-strategy` and one content skill:
1. Setup: link the cogni-portfolio and cogni-trends projects.
2. Strategy: review the 3D matrix, pick the highest-priority cell.
3. Generate: pick a funnel stage and content type that matches the cell, run the
   matching skill (e.g. `/thought-leadership` for an awareness blog post).
4. Open the produced content — show the proposition + theme references in the metadata.

### Exercise

Pick one priority cell from the matrix. Run two pieces from different funnel stages
for the same market × GTM path (e.g. a thought-leadership blog and a demand-gen
LinkedIn carousel). Compare how each adapts the same source data to channel
conventions.

### Quiz

1. Why does cogni-marketing tag every produced piece with proposition + theme references?
   **Answer**: Provenance enables claim verification, correction cascades, and
   campaign-level attribution analysis. Untagged content is opaque.

2. **Hands-on**: Generate the same blog post twice — once with `language: de` and
   once with `language: en`. Compare opening sentence cadence.

### Recap

- 3D matrix: markets × GTM paths × formats — surfaces coverage gaps
- Five funnel-stage skills, 16 content formats supported
- Every piece tagged with provenance to propositions and themes
- DACH content auto-applies Wolf Schneider + Amstad scoring

---

## Module 5: End-to-End Recap & Campaign Orchestration

### Theory (4 min)

The trends-to-solutions tour produces a connected campaign-ready content set: a TIPS
project with themes, a cogni-portfolio project with propositions, and a cogni-marketing
project with multi-channel content. All three are linked by a single evidence trail.

For campaign orchestration, the `/campaign-builder` skill chains these into a
multi-channel sequence — touchpoints across LinkedIn, email, blog, and ABM, scheduled
on a day-based timeline. The campaign is the consumable artifact for the GTM team;
the pipeline produced the underlying content.

When iterating: a corrected trend signal (via `cogni-claims`) cascades through the
proposition layer to the content layer. Don't manually re-edit a campaign when the
upstream theme shifts — re-run the affected content skills and let the lineage
update propagate.

### Demo

Run `/campaign-builder`:
1. Pick a target market and a GTM path.
2. Watch the campaign timeline assemble — touchpoints sequenced across channels.
3. Open `/marketing-dashboard` to see content coverage and campaign progress.

### Exercise

Have the learner sketch a real campaign they need to ship in the next quarter. Map
the inputs back: which TIPS themes drive it? which propositions? which markets? If
any input is missing, that's a gap to fill before content generation.

### Quiz

1. Why use `/campaign-builder` instead of just generating content piece by piece?
   **Answer**: Campaigns sequence touchpoints — content alone is unstructured. The
   campaign's day-based timeline turns pieces into a buyer journey.

2. **Hands-on**: Open `/marketing-dashboard` and find one content gap (a market ×
   GTM path with no content). Decide which skill would fill it.

### Recap

- The pipeline produces a connected three-project artifact set with full lineage
- `/campaign-builder` sequences touchpoints; `/marketing-dashboard` visualizes coverage
- Corrections cascade — re-run skills, don't hand-edit campaigns
- Match GTM path to funnel stage to channel — the matrix is the planning grid

---

## Tour Complete

Next steps:
- Run the pipeline against a real industry/market combination
- Combine with `tour-portfolio-to-pitch` for proposition-to-pitch conversion
- Combine with `tour-content-pipeline` for deeper content polish workflows
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/trends-to-solutions.md`
- See the narrative tutorial: `docs/workflows/trends-to-solutions.md`
