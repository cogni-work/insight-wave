# Tour: Content Pipeline

**Duration**: 75 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-marketing → cogni-narrative (long-form only) → cogni-copywriting → cogni-visual
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-marketing`, `/cogni-help:cheatsheet cogni-narrative`, `/cogni-help:cheatsheet cogni-copywriting`, `/cogni-help:cheatsheet cogni-visual`; see also the matching `docs/plugin-guide/<plugin>.md` files.
**Audience**: Marketing teams producing multi-channel content sourced from portfolio + trends data

---

This tour walks the content-pipeline workflow as one continuous chain. You set up
a marketing project, build a content strategy, generate raw content, polish it,
and optionally render it visually. The cheatsheets and `docs/plugin-guide/<plugin>.md`
files cover each plugin in depth; this tour focuses on the chain — especially the
narrative-bridge decision (skip for short-form, run for long-form).

## Module 1: Set Up the Marketing Project (cogni-marketing)

### Theory (6 min)

`cogni-marketing` orchestrates content production around a project that links
brand voice, target markets, and GTM-path-to-theme mapping. The setup step
configures all three.

Brand voice: tone, language, industry conventions, voice attributes.
Target markets: the markets the content will address (DACH, US, FR, etc.).
GTM-path-to-theme mapping: which strategic themes drive which go-to-market paths.

Two upstream dependencies feed the project: `cogni-portfolio` provides
propositions (the IS/DOES/MEANS the content sells), `cogni-trends` provides
investment themes (the strategic context). Without portfolio, content has no
"what we sell"; without trends, content has no "why now". Both can be optional —
the engine uses generic themes if cogni-trends is missing — but the result is
generic content.

For DACH content, set `language: de` during setup. The pipeline auto-applies
Wolf Schneider rules with Amstad readability scoring during polish.

### Demo

Run `/marketing-setup`:
1. Link the cogni-portfolio project.
2. Optionally link a cogni-trends TIPS project.
3. Configure brand voice (tone, language, voice attributes).
4. Configure target markets.
5. Map GTM paths to themes.
6. Show the produced `marketing-project.json`.

### Exercise

For a real campaign the team needs, draft the brand voice (3-5 voice attributes)
and decide which markets and GTM paths apply. Run setup with these answers.

### Quiz

1. Why does the marketing project need both portfolio and trends as inputs?
   **Answer**: Portfolio provides "what we sell" (IS/DOES/MEANS), trends provide
   "why now" (strategic context). Without both, content is either feature-list
   or trend-talk — not GTM content.

2. **Hands-on**: Open `marketing-project.json` and confirm the GTM-path-to-theme
   mapping. Does each GTM path have at least one theme?

### Recap

- Setup configures brand voice, markets, and GTM-path-to-theme mapping
- Portfolio + trends are upstream dependencies; both feed the engine
- DACH content auto-applies Wolf Schneider + Amstad readability scoring
- The mapping is the planning grid for downstream content generation

---

## Module 2: Build the Content Strategy (cogni-marketing)

### Theory (6 min)

`/content-strategy` produces a 3D matrix: markets × GTM paths × content types.
The matrix surfaces gaps — which intersections lack content. Treat the matrix
as a plan, not a target — you don't need to fill every cell to ship a campaign.

The strategy step is the converging move: with the matrix in hand, you pick
high-priority cells (most important market × strongest theme × highest-leverage
format) and commit to producing content for those. Without strategy, you produce
content for whatever felt interesting last week.

Re-run after adding new propositions or themes; the diff shows where coverage
changed.

### Demo

Run `/content-strategy`:
1. Watch the matrix assemble across markets × GTM paths × content types.
2. Identify the highest-priority cell (where market importance × theme strength × format leverage is maximal).
3. Show the gap visualization — cells with no content yet.
4. Open `content-strategy.json` and review priorities.

### Exercise

Pick three high-priority cells from the matrix. For each, decide which content
format and which funnel stage best fits. Justify in one sentence per cell.

### Quiz

1. Why is the strategy step converging while the matrix is comprehensive?
   **Answer**: The matrix shows possibility; strategy picks priorities. Without
   prioritization, teams produce a uniform spread of content with no campaign
   shape.

2. **Hands-on**: Find one cell in the matrix that has shallow input data (a
   market without a TIPS theme). Decide: drop the cell, or fill the input?

### Recap

- 3D matrix: markets × GTM paths × content types — surfaces gaps
- Strategy converges from possibility to priority
- Re-run after upstream changes; the diff drives campaign updates
- Matrix is the planning grid; strategy is the prioritized plan

---

## Module 3: Generate Content (cogni-marketing)

### Theory (8 min)

`cogni-marketing` exposes one skill per funnel stage:

| Funnel stage | Skill | Output formats |
|--------------|-------|----------------|
| Awareness | `/thought-leadership` | Blog, LinkedIn article, keynote, podcast outline, op-ed |
| Engagement | `/demand-gen` | LinkedIn posts, SEO articles, carousels, video scripts, infographics |
| Conversion | `/lead-gen` | Whitepaper, landing page, email nurture, webinar outline, gated checklist |
| Decision | `/sales-enablement` | Battle card, one-pager, demo script, objection handler, proposal section |
| Account-specific | `/abm` | Account plan, personalized email sequence, executive briefing |

Each skill reads the marketing project, picks relevant propositions and themes,
and generates content tagged with provenance — every piece references the
propositions and themes it draws from.

Content-writer agents run in parallel — request multiple pieces in one prompt to
generate a batch. For named-account work, skip strategy and go straight to
`/abm` with the target account.

### Demo

Pick the highest-priority cell from Module 2. Run the matching skill:
1. Pick funnel stage and content type.
2. Configure: market, GTM path, propositions to anchor.
3. Watch the content-writer produce raw content.
4. Open the produced file — show the provenance tags (proposition refs, theme refs).

### Exercise

Generate two pieces from different funnel stages for the same market × GTM path:
one awareness piece (`/thought-leadership`) and one conversion piece (`/lead-gen`).
Compare how each adapts the same source data to channel conventions.

### Quiz

1. **Multiple choice**: A team needs a battle card for a specific competitor in
   a specific market. Which skill?
   - a) `/demand-gen` — b) `/sales-enablement` — c) `/abm` — d) `/lead-gen`
   **Answer**: b (battle cards are decision-stage sales enablement)

2. **Hands-on**: Compare a `/thought-leadership` blog post to a `/demand-gen`
   LinkedIn carousel for the same theme. How does channel convention shape voice?

### Recap

- Five funnel-stage skills covering 16 content formats
- Provenance tags on every piece — content traces back to data
- Parallel generation: request batches in one prompt
- ABM bypasses strategy; goes account-first

---

## Module 4: Polish with cogni-copywriting

### Theory (6 min)

`cogni-copywriting` polishes raw content for executive readability and channel
conventions. The polish skill applies framework-aware rewrites: Pyramid Principle,
BLUF (Bottom Line Up Front), active voice, readability scoring.

For long-form content (thought leadership, whitepapers, keynote abstracts),
`cogni-narrative` should run between generation and polish — it applies a story
arc framework and writes `arc_id` frontmatter that cogni-copywriting reads for
arc-aware polishing. Short-form formats (LinkedIn posts, battle cards, emails)
skip the narrative step.

For multi-stakeholder content (whitepapers, executive briefings), run
`/review-doc` after polish — five reader personas score and synthesize feedback.
This is the closest thing to a real audience test before publication.

For German content, the polish skill auto-detects and applies Wolf Schneider
rules with Amstad readability scoring (German equivalent of Flesch-Kincaid).

### Demo

Polish one long-form piece from Module 3:
1. Run `/narrate` on the raw content (long-form only).
2. Run `/copywrite <path>` on the narrative-shaped content.
3. Run `/review-doc` for stakeholder feedback.
4. Compare raw, narrated, polished, reviewed versions.

### Exercise

For one short-form piece (e.g. LinkedIn post), run `/copywrite` directly (skip
the narrative step). For one long-form piece (e.g. whitepaper), run the full
chain. Compare how the narrative step shapes the long-form differently.

### Quiz

1. Why skip cogni-narrative for short-form content?
   **Answer**: Short-form content (a 200-word LinkedIn post) doesn't have room
   for a story arc. The narrative step adds overhead without adding insight.

2. **Hands-on**: Run `/review-doc` and identify one finding from a stakeholder
   perspective you didn't anticipate. That's the value of multi-perspective review.

### Recap

- Polish applies framework-aware rewrites: Pyramid, BLUF, active voice, readability
- Long-form gets cogni-narrative first; short-form skips it
- `/review-doc` for multi-stakeholder content — five reader personas
- DACH content auto-applies Wolf Schneider + Amstad

---

## Module 5: Render Visually & Recap (cogni-visual, optional)

### Theory (4 min)

`cogni-visual` is optional in the content pipeline. Stop at Step 4 if the content
stays in markdown — blog posts, LinkedIn articles, whitepapers don't need a
slide layer. Run cogni-visual when the content needs a visual deliverable:

- **Presentation deck** — `/render-slides` for keynote, exec briefing, sales deck
- **Web narrative** — `/story-to-web` for scrollable single-page documents
- **Infographic** — `/story-to-infographic` for one-page visual summaries
- **Campaign summary deck** — for internal review or board updates

The renderer reads the story arc from the polished narrative and maps content to
slide layouts with assertion headlines. Theme inheritance applies — the active
workspace theme drives every visual deliverable.

For campaign orchestration, `/campaign-builder` chains pieces into a multi-channel
sequence with day-based timelines. `/marketing-dashboard` visualizes content
coverage and campaign progress.

### Demo

Render one polished long-form piece as both a deck and a web narrative:
1. Run `/render-slides` on the polished whitepaper.
2. Run `/story-to-web` on the same source.
3. Compare the two outputs.
4. Run `/marketing-dashboard` to see the full project state.

### Exercise

For the engagement, decide which pieces need a visual layer and which stay in
markdown. Justify each choice based on the consumption channel.

### Quiz

1. Why is cogni-visual optional in this pipeline?
   **Answer**: Most marketing content is consumed in markdown-rendering channels
   (blog, email, social). Visual rendering is for presentation, web-narrative,
   and infographic deliverables.

2. **Hands-on**: Open `/marketing-dashboard` and find one campaign with thin
   visual coverage. Decide whether to render or leave as markdown.

### Recap

- cogni-visual is opt-in; not every content piece needs a visual layer
- Render targets: slides, web narrative, infographic, campaign deck
- `/campaign-builder` sequences touchpoints; `/marketing-dashboard` visualizes coverage
- Match render format to consumption channel

---

## Tour Complete

Next steps:
- Run the pipeline for a real campaign
- Combine with `tour-trends-to-solutions` for trend-anchored content
- Combine with `tour-portfolio-to-pitch` for sales enablement chains
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/content-pipeline.md`
- See the narrative tutorial: `docs/workflows/content-pipeline.md`
