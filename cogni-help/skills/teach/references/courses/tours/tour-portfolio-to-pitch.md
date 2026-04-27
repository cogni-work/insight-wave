# Tour: Portfolio to Pitch

**Duration**: 60 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-portfolio`, `/cogni-help:cheatsheet cogni-narrative`, `/cogni-help:cheatsheet cogni-sales`, `/cogni-help:cheatsheet cogni-visual`; see also the matching `docs/plugin-guide/<plugin>.md` files.
**Audience**: Sales creating customer-specific or segment-specific pitch presentations

---

This tour walks the portfolio-to-pitch pipeline as one workflow. You start from
portfolio propositions, optionally shape a narrative arc, run the Why Change
methodology, and render an executive pitch deck. The cheatsheets and
`docs/plugin-guide/<plugin>.md` files cover each plugin in depth; this tour focuses
on the chain.

## Module 1: Pipeline Overview & Customer Setup

### Theory (5 min)

The portfolio-to-pitch pipeline produces a customer-specific or segment-specific
pitch deck: `cogni-portfolio` provides the proposition (IS/DOES/MEANS) and
competitive context, `cogni-narrative` shapes a story arc (often optional —
cogni-sales has Why Change built in), `cogni-sales` runs the Corporate Visions
Why Change methodology, and `cogni-visual` renders the deck.

Two pitch modes:
- **Named-customer pitch** — deal-specific, includes customer research, ABM-shaped
- **Segment pitch** — reusable across similar customers in a market segment

Customer research strengthens named-customer pitches. Without it, the pitch is a
proposition deck rebranded as a sales tool.

### Demo

Walk the audience through what a pitch artifact set looks like:
1. Open an example portfolio project — show one proposition.
2. Open the matching pitch project (if exists) — show `sales-presentation.md`.
3. Open the rendered slides — point at one Why Change moment.

### Exercise

Have the learner pick a real prospect or market segment they need a pitch for in
the next quarter. Decide: named-customer or segment? What's the deal value, and
how much customer research is justified?

### Quiz

1. **Multiple choice**: A sales lead asks for a pitch deck for a new vertical they
   haven't sold into yet. Named-customer or segment?
   - a) named-customer — b) segment
   **Answer**: b (segment — no specific customer yet; reusable across the vertical)

2. Why does the cogni-narrative step sometimes get skipped in this pipeline?
   **Answer**: cogni-sales has the Why Change arc built in. Adding cogni-narrative
   on top is for cases where a different arc fits better (SCQA for problem-first audiences).

### Recap

- Two modes: named-customer (deal-specific) or segment (reusable)
- Pipeline: portfolio → optional narrative → sales (Why Change) → visual
- Customer research is what turns a deck into a pitch

---

## Module 2: Confirm Portfolio Propositions (cogni-portfolio)

### Theory (6 min)

The pitch deck stands on portfolio data. `cogni-portfolio` provides:
- **Propositions** — IS/DOES/MEANS per Feature × Market combination
- **Competitor analysis** — battle cards, positioning, differentiation
- **Customer profiles** — ICP, buyer personas, buying centers
- **Market sizing** — TAM/SAM/SOM data for the target segment

For pitches, the most-used outputs are the proposition (the "what we sell"), the
competitor analysis (the "why us"), and the customer profile (the "who we sell to").

If portfolio data is incomplete (no proposition for the target market, no competitor
for the named account), the pitch will have gaps that show up as soft assertions.
Fill the data first; pitch second.

### Demo

Run `/portfolio-resume` or check status:
1. Confirm a proposition exists for the target market.
2. Run `/compete` if competitor data is missing.
3. Run `/customers` if the buyer persona is missing.
4. Open `portfolio-architecture` to visualize the product-feature structure — confirm
   nothing is misaligned before building the pitch.

### Exercise

For the prospect/segment chosen in Module 1, confirm portfolio coverage. List which
of (proposition, competitors, customer profile) are present and which are missing.
Generate any missing pieces before continuing.

### Quiz

1. Why visualize the portfolio architecture before building a pitch?
   **Answer**: Architecture surfaces structural gaps (orphan features, propositions
   without customers); easier to fix at the data layer than at the pitch layer.

2. **Hands-on**: Run `/portfolio-architecture` and find one orphan entity (a feature
   without a proposition, or a proposition without customer evidence).

### Recap

- Pitches stand on three pillars: proposition, competitor analysis, customer profile
- Fill portfolio data first; pitch second
- `portfolio-architecture` surfaces gaps before they hit the pitch
- Customer-specific pitches need customer-specific value — don't reuse segment DOES/MEANS

---

## Module 3: Optional Narrative Shaping (cogni-narrative)

### Theory (5 min)

For most sales pitches, skip cogni-narrative — `cogni-sales` has the Why Change arc
built in (Corporate Visions methodology: Why Change → Why Now → Why You → Why Pay).
That arc fits enterprise B2B pitch deals.

When to add cogni-narrative on top:
- The audience is problem-first (SCQA fits better than Why Change)
- The deal is consultative (Hero's Journey fits the transformation story)
- The pitch leads with a strategic point of view (Minto Pyramid fits)

If unsure, skip the narrative step. cogni-sales produces a workable arc by default.

### Demo

Show one named-customer pitch with `cogni-sales` only, and one with `cogni-narrative`
in front. Compare the opening slide:
- Sales-only: opens with a "Why Change" provocation (the unconsidered need)
- Narrative-shaped: opens with the arc the narrative chose (often Situation/Complication)

### Exercise

For the pitch chosen in Module 1, decide: skip the narrative step, or run it. Justify
the choice in one sentence based on the audience.

### Quiz

1. **Multiple choice**: A pitch to a CFO who wants the recommendation upfront — which arc?
   - a) Why Change — b) SCQA — c) Minto Pyramid — d) Hero's Journey
   **Answer**: c (Minto leads with the recommendation; CFOs want the answer first)

2. Why is "skip cogni-narrative" the default for sales pitches?
   **Answer**: cogni-sales has Why Change built in; doubling up adds overhead without
   improving most enterprise B2B pitches.

### Recap

- Skip cogni-narrative by default — Why Change is built into cogni-sales
- Add it for problem-first audiences (SCQA), consultative arcs (Hero's), or recommendation-first (Minto)
- One sentence of justification before adding overhead

---

## Module 4: Run the Why Change Pitch (cogni-sales)

### Theory (8 min)

`cogni-sales` runs the Corporate Visions Why Change methodology in four phases:
- **Why Change** — surface the unconsidered need (the prospect's status quo is broken)
- **Why Now** — establish urgency (the cost of inaction is rising)
- **Why You** — differentiate (your point of view, your provider strengths)
- **Why Pay** — quantify (business case, pricing model, expected outcome)

Each phase is a researched, sourced section. The unconsidered need is the
methodology's hardest move — without it, the pitch is just a feature list.

For named accounts, customer research feeds the Why Now and Why Pay phases. For
segments, the research draws on cogni-portfolio market sizing and cogni-trends
themes (if present).

The output is two artifacts: `sales-presentation.md` (the deck content) and
`sales-proposal.md` (the leave-behind). Both are arc-shaped.

### Demo

Run `/why-change` against the prospect/segment chosen in Module 1:
1. Pick named-customer or segment mode.
2. Watch the four phases run sequentially with stakeholder review at the end.
3. Open `sales-presentation.md` and `sales-proposal.md` — compare structures.
4. Run `/pitch-review` for stakeholder-perspective scoring.

### Exercise

Open the produced `sales-presentation.md` and find the Why Change unconsidered need.
Ask: would the prospect actually agree this is a need they're missing? If not, the
pitch is too generic — re-run with sharper customer research.

### Quiz

1. Why is the unconsidered need the hardest move in Why Change?
   **Answer**: It requires a specific insight about the prospect's blind spot;
   generic insights produce a feature list, not a pitch.

2. **Hands-on**: Compare the Why You section to your competitor battle cards. Does
   the pitch differentiate based on real provider strengths or generic claims?

### Recap

- Four-phase Why Change methodology: Change → Now → You → Pay
- The unconsidered need is the hardest move; generic = feature list
- Two artifacts: presentation (deck) and proposal (leave-behind)
- `/pitch-review` scores stakeholder perspectives (buyer / sales / marketing)

---

## Module 5: Render the Deck (cogni-visual)

### Theory (4 min)

`cogni-visual` renders `sales-presentation.md` as PPTX or HTML slides. The renderer
reads the Why Change arc from frontmatter and maps each phase to slide layouts —
provocation slides for Why Change, urgency slides for Why Now, differentiation
slides for Why You, business-case slides for Why Pay.

Theme inheritance applies: the active workspace theme drives colors, fonts, and
design variables. Don't add per-deck styling.

For pitches with a leave-behind, also render `sales-proposal.md` as a web narrative
(`/story-to-web`) — a scrollable single-page document the prospect can browse
asynchronously after the meeting.

### Demo

Run `/render-slides` on `sales-presentation.md`:
1. Pick slide count (10-15 for executive pitches).
2. Watch layout assignment — Why Change phases map to specific slide types.
3. Run `/story-to-web` on `sales-proposal.md` for the leave-behind.
4. Open both side by side.

### Exercise

The learner shows the rendered deck to a colleague (real or imagined). Does the
opening slide land the unconsidered need within 30 seconds? If not, the Why Change
text needs sharpening — go back and re-run.

### Quiz

1. Why render both the deck and the proposal?
   **Answer**: The deck drives the meeting; the proposal is the leave-behind.
   Different consumption modes need different formats.

2. **Hands-on**: Switch the workspace theme via `/pick-theme` and re-render. Note
   that no slide content needed to change.

### Recap

- The pipeline produces an arc-shaped deck + leave-behind proposal
- Theme inheritance from cogni-workspace — no per-deck styling
- Executive pitches: 10-15 slides; the opening must land the unconsidered need
- Leave-behind via `/story-to-web` for asynchronous review

---

## Tour Complete

Next steps:
- Run the pipeline for a real prospect
- Combine with `tour-trends-to-solutions` for trend-anchored pitches
- Use `/pitch-review` for stakeholder feedback before client delivery
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/portfolio-to-pitch.md`
- See the narrative tutorial: `docs/workflows/portfolio-to-pitch.md`
