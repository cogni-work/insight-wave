# Tour: Trends to Solutions

**Duration**: 75 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-trends (trend-scout + value-modeler) → optional cogni-portfolio (trends-bridge) → cogni-visual (story-to-slides / enrich-report)
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-trends`, `/cogni-help:cheatsheet cogni-portfolio`, `/cogni-help:cheatsheet cogni-visual`; see also the matching `docs/plugin-guide/<plugin>.md` files.
**Audience**: Strategy and advisory teams turning scouted trends into ranked solution blueprints and stakeholder-ready visuals

---

This tour walks the trends-to-solutions pipeline as a single workflow. You scout
strategic trends, model investment themes and ranked Solution Templates, optionally
anchor them to a cogni-portfolio project, and render a visual deliverable — all
sourced from the same evidence trail.

The pipeline supports two scenarios that branch at Step 2 (value modeling):

- **Scenario A — Standalone**: no cogni-portfolio project; value-modeler uses a generic B2B ICT portfolio scaffold.
- **Scenario B — With portfolio connected**: `trends-bridge` exports portfolio context so Solution Templates map to real products and features, and ranked solutions can flow back into the portfolio.

The tour covers both. The cheatsheets and `docs/plugin-guide/<plugin>.md` files
cover each plugin in depth; this tour focuses on the hand-offs and the scenario split.

## Module 1: Pipeline Overview & Scenario Choice

### Theory (6 min)

The trends-to-solutions pipeline chains two or three plugins around a single thread
of evidence:

1. `cogni-trends` produces 60 scored trend candidates and consolidates them into
   3–7 MECE investment themes (Handlungsfelder) with T→I→P→S value chains.
2. `cogni-portfolio` (optional, Scenario B) exports portfolio context for value
   modeling and absorbs ranked Solution Templates back as new features and
   proposition variants.
3. `cogni-visual` renders the result as an executive slide deck or an interactive
   themed HTML report.

The connecting fiber is the **investment theme**. Each theme groups 1–4 value chains
and represents a CxO-level strategic decision — where to allocate budget and
executive attention. Each theme owns a portfolio of ranked Solution Templates
(SPIs, success metrics, evidence) which is what stakeholders can actually fund.

The scenario split lives at Step 2:

- **Scenario A** — value-modeler runs against a bundled **generic B2B ICT portfolio**
  (7 products, 51 features). Outputs are taxonomy-grounded; useful for advisory POVs
  but not company-specific.
- **Scenario B** — `trends-bridge portfolio-to-tips` exports the real portfolio first.
  value-modeler then maps Solution Templates to real features; readiness scoring
  reflects actual gaps.

Both scenarios reconverge at Step 4 (visual deliverables).

### Demo

Walk the audience through the artifact chain on an existing project (or sketch it
on a whiteboard if no project exists):

1. Open a TIPS pursuit. Show the 60 scored candidates and one investment theme.
2. Open the value model. Show one Solution Template, its T→I→P→S chain, and its
   Business Relevance score.
3. (Scenario B only) Open the connected cogni-portfolio project. Show one feature
   that traces back to the trend signal that justified it.
4. Open the rendered slide deck or HTML report. Show one slide that cites the
   theme + ST + evidence.

### Exercise

Ask the learner to declare upfront: are they doing a **discovery engagement**
(no portfolio yet) or a **portfolio-driven engagement** (existing cogni-portfolio
project)? Their answer determines whether they will run Scenario A or B in
Module 4.

### Quiz

1. Why does the pipeline anchor on investment themes rather than individual trends?
   **Answer**: Themes bundle related trends into a strategic narrative; individual
   trends produce fragmented advice with no through-line.

2. **Multiple choice**: A team has 60 scored trends and no cogni-portfolio project.
   Which scenario applies?
   - a) Scenario A — value-modeler with the generic B2B ICT portfolio fallback
   - b) Scenario B — must build a portfolio first
   - c) Skip value-modeler; go straight to visual rendering
   - d) Run trends-bridge in standalone mode
   **Answer**: a

### Recap

- The pipeline anchors on investment themes (Handlungsfelder), not raw trends
- Two scenarios branch at Step 2 and reconverge at Step 4
- Scenario A: standalone, generic blueprints (taxonomy-grounded, advisory)
- Scenario B: portfolio-anchored, with backflow into cogni-portfolio

---

## Module 2: Scout Trends and Refine the Candidate Set (cogni-trends)

### Theory (8 min)

`/trend-scout` runs a multi-phase scouting workflow: bilingual web research (DE/EN)
across regional authority sources, signal curation, candidate generation (60 trends
scored across frameworks: TIPS dimensions, Ansoff, Rogers, CRAAP), stakeholder
review, and deep research on top candidates.

For DACH/EU markets, the regional authority source set is critical — `fraunhofer.de`,
`bitkom.org`, `vdma.org`, `destatis.de`, `handelsblatt.com` produce different
evidence than the EN/US default. Set `region` in the scout configuration.

The scout produces 60 candidates — too many for a focused engagement. Cull to
**15–25 most relevant** before Step 2. The quality of the final deliverable depends
on this cull more than on any other single decision: bad selection here cascades
through every downstream step.

### Demo

Run `/trend-scout` against an industry the team cares about:

1. Configure: industry, language (DE/EN), region (DACH/US/EU), depth.
2. Watch the phases: web research → signal curation → 60 candidates → stakeholder
   review → deep research → agreed candidates.
3. Open the produced TIPS project — show the candidates table sorted by combined
   score, and the agreed set the user has committed to.

If `/trend-scout` already ran for this industry, use `/trends-resume` to skip
straight to the candidates view.

### Exercise

Have the learner name three industry shifts they think matter for the next 12
months — without research. Then open the scouted candidate set and check
overlap. Where did `/trend-scout` find evidence the learner didn't anticipate?
What gut-instinct trends did the scout fail to surface?

### Quiz

1. Why is the regional authority source set important for DACH scouting?
   **Answer**: DACH-specific sources (Fraunhofer, BITKOM, VDMA, destatis) surface
   evidence the EN/US default sources miss; without them, the scout produces a
   US-flavored view of a DACH market.

2. **Hands-on**: Open the candidates table and identify the cull. Pick the 15–25
   that will feed value-modeler. Justify each cut.

### Recap

- `/trend-scout` produces 60 scored candidates → reviewed → top candidates deep-researched → agreed set
- Regional authority sources matter — set `region` correctly for DACH/EU
- The cull from 60 → 15–25 is the most important quality gate in the pipeline
- The agreed set is the hand-off to Step 2 (value-modeler)

---

## Module 3: Model Investment Themes and Solution Templates (cogni-trends)

### Theory (8 min)

`/value-modeler` consolidates agreed candidates into 3–7 MECE investment themes
(Handlungsfelder) and expands each through the T→I→P→S value chain — Trend →
Implication → Possibility → Solution. For each theme it generates Solution Templates
with portfolio blueprints, SPIs (operational process changes), success metrics, and
Business Relevance scoring.

Phase 2 (Solution Template generation) is where the scenario split materializes:

- **Scenario A — Standalone**: With no cogni-portfolio project in the workspace,
  Phase 2 falls back to a **generic B2B ICT portfolio** (7 products, 51 features
  with IS-layer descriptions and taxonomy mappings derived from the B2B ICT
  taxonomy). DOES/MEANS propositions are generated dynamically from the project's
  research context. The output is a taxonomy-grounded view — each Solution
  Template maps to ICT capability dimensions with coverage data.
- **Scenario B — With portfolio**: First run `/trends-bridge portfolio-to-tips`
  to export portfolio context (writes `portfolio-context.json` v3.2 into the TIPS
  pursuit). Then `/value-modeler` Phase 2 maps Solution Templates to your **real
  features**; readiness scoring reflects actual portfolio gaps; Business Relevance
  scoring weighs real propositions and pricing.

Business Relevance scoring matters in either scenario. Default weights rarely match
a client's strategic priorities — adjust before generating final blueprints.

### Demo

Pick the scenario that matches the project state and run the matching path.

**Scenario A path:**
1. Confirm no cogni-portfolio project exists in the workspace.
2. Run `/value-modeler`. Watch Phase 2 announce the generic-portfolio fallback.
3. Open one investment theme. Show the T→I→P→S chain, the Solution Templates
   anchored to generic taxonomy products, and the BR scoring interface.

**Scenario B path:**
1. Confirm a cogni-portfolio project exists and is configured for the target market.
2. Run `/trends-bridge portfolio-to-tips`. Show `portfolio-context.json` written
   into the TIPS pursuit.
3. Run `/value-modeler`. Watch Phase 2 consume the exported context.
4. Open one investment theme. Show one Solution Template now mapped to a real
   feature; show the readiness gap.

### Exercise

Pick one investment theme. Walk the T→I→P→S chain end to end:

- Which trend signals justify the theme?
- What's the implication for the target market?
- What possibility does it open?
- What Solution Template is the concrete answer?

In Scenario B, also identify which real feature the ST anchors to and what readiness
gap (if any) the model surfaced.

### Quiz

1. Why must `/trends-bridge portfolio-to-tips` run **before** `/value-modeler` in
   Scenario B?
   **Answer**: value-modeler Phase 2 reads `portfolio-context.json` to anchor
   Solution Templates to real features. If the export step is skipped, value-modeler
   silently falls back to the generic B2B ICT portfolio (Scenario A) and the run
   produces generic blueprints despite the user thinking they're in Scenario B.

2. **Multiple choice**: Which artifact best represents the unit of investment for
   a CxO conversation?
   - a) An individual scored trend candidate
   - b) A Solution Template
   - c) An investment theme (Handlungsfeld)
   - d) A T→I→P→S value chain
   **Answer**: c — themes bundle related solutions into a fundable strategic
   decision; STs are the implementation detail.

### Recap

- `/value-modeler` produces 3–7 investment themes + ranked Solution Templates +
  SPIs + metrics + BR scoring
- Scenario A: generic B2B ICT portfolio fallback (7 products, 51 features)
- Scenario B: requires `/trends-bridge portfolio-to-tips` first; STs anchor to real features
- Business Relevance scoring is adjustable — defaults rarely match client priorities
- Forgetting the export step in Scenario B silently degrades to Scenario A

---

## Module 4: Backflow to Portfolio (Scenario B only) and Visual Deliverables

### Theory (6 min)

Scenario B closes the loop with `/trends-bridge tips-to-portfolio`. This pushes
ranked Solution Templates back into cogni-portfolio as **new features**,
**proposition variants**, **evidence entries**, and **innovation opportunities**
(written to `portfolio-opportunities.json`). Trend signals become portfolio
mutations the team can build against; lineage is preserved so corrections cascade.

Both scenarios then converge on `cogni-visual` for the executive deliverable:

- **Slide deck** — `/story-to-slides` on a narrative derived from the value-modeler
  output produces a themed presentation.
- **Enriched report** — `/enrich-report` on the trend report produces an interactive
  HTML report with Chart.js visualizations and themed sidebar navigation.

The underlying value-model JSON is the same shape in both scenarios, so visual
rendering is identical — only the semantic depth of the Solution Templates differs
(generic vs. portfolio-anchored).

### Demo

**Scenario B backflow (skip in Scenario A):**
1. Run `/trends-bridge tips-to-portfolio` against the ranked value model.
2. Open the connected cogni-portfolio project. Show one new feature that the
   bridge created and trace its lineage back to the original trend signal.
3. Open `portfolio-opportunities.json` and pick one innovation opportunity to
   discuss.

**Visual rendering (both scenarios):**
1. Generate the trend report (`/trend-report`) if it doesn't exist yet.
2. Run `/enrich-report path/to/tips-trend-report.md`. Open the HTML output and
   walk the sidebar navigation, the Chart.js visualizations, and the embedded
   evidence pack.
3. Alternatively run `/story-to-slides` for an executive deck.

### Exercise

Scenario B learners: pick one Solution Template, run `tips-to-portfolio`, and
verify that the resulting feature in cogni-portfolio still references the
original trend evidence. Curate (`/features`) before letting it propagate further.

All learners: render the visual deliverable. Compare the slide deck and the HTML
report — which form fits the upcoming stakeholder conversation better?

### Quiz

1. Why curate the entities `tips-to-portfolio` generates before downstream skills
   consume them?
   **Answer**: The bridge proposes — the team disposes. Auto-imported features and
   proposition variants are drafts; without curation, weak entries propagate into
   pitches, marketing content, and sales artifacts.

2. **Hands-on**: Open the rendered HTML report. Find one Solution Template and
   trace it back through the inline citations to the original web sources. Confirm
   the evidence chain is intact.

### Recap

- Scenario B only: `/trends-bridge tips-to-portfolio` writes new features,
  proposition variants, evidence, and `portfolio-opportunities.json`
- Curate generated entities before they propagate
- Visual deliverables are scenario-agnostic — value-model JSON has the same shape
- `/story-to-slides` for decks, `/enrich-report` for HTML reports

---

## Module 5: End-to-End Recap & Next Steps

### Theory (4 min)

The trends-to-solutions tour produces a connected, evidence-traceable artifact set:

- A TIPS pursuit with agreed candidates and a value model (3–7 investment themes,
  ranked Solution Templates, SPIs, metrics, BR scoring)
- (Scenario B only) New features, proposition variants, and innovation opportunities
  inside cogni-portfolio
- A visual deliverable — slide deck or interactive HTML report — with full lineage
  back through STs and themes to the original trend signals

When iterating, prefer re-running the affected step over hand-editing the artifact.
A corrected trend signal cascades through value-modeler and (in Scenario B) through
the portfolio backflow into the visual deliverable. Hand-edits break that chain.

### Demo

Walk the artifact chain end-to-end at executive pace:

1. Open the trend candidates table — show the cull (60 → 15–25).
2. Open the value model — pick one investment theme, walk its T→I→P→S chain,
   show the BR scoring.
3. (Scenario B) Open the cogni-portfolio project — show one new feature the
   bridge created and trace it back.
4. Open the visual deliverable — pick one slide or section, walk the lineage
   back to the trend evidence.

### Exercise

Have the learner sketch a real engagement they'll run in the next quarter:

- Which industry / market combination?
- Will it be Scenario A (discovery) or Scenario B (portfolio-driven)?
- For Scenario B: does a cogni-portfolio project already exist, or do they need
  to build one first?
- What's the executive deliverable — slides, HTML, or both?

The sketch becomes the engagement plan.

### Quiz

1. Why re-run a skill instead of hand-editing the visual deliverable when an
   upstream trend signal changes?
   **Answer**: Lineage is the value. Hand-edits break the trace from rendered
   slide back to trend evidence; re-running cascades the correction through every
   downstream artifact while preserving lineage.

2. **Hands-on**: Pick one Solution Template in the value model. Identify which
   downstream artifacts (portfolio entities, slides, report sections) would
   change if you removed it. That's the cascade radius.

### Recap

- The pipeline produces an evidence-traced artifact set: TIPS → (portfolio) → visual
- Scenario A is taxonomy-grounded; Scenario B is portfolio-anchored
- Iterate by re-running affected skills, not by hand-editing artifacts
- Match deliverable form to audience — slides for live executive sessions,
  HTML reports for asynchronous review

---

## Tour Complete

Next steps:
- Run the pipeline against a real industry/market combination
- Combine with `tour-portfolio-to-pitch` for proposition-to-pitch conversion (Scenario B follow-up)
- Combine with `tour-content-pipeline` if marketing content is also needed downstream
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/trends-to-solutions.md`
- See the narrative tutorial: `docs/workflows/trends-to-solutions.md`
