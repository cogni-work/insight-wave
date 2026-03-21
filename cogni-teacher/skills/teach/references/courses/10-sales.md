# Course 10: Sales Pitches

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 6 + Course 3
**Plugin**: cogni-sales (v0.3.3, 1 skill, 2 agents)
**Audience**: Consultants creating B2B sales presentations and proposals

---

## Module 1: Why Change Methodology & Setup

### Theory (3 min)

**cogni-sales** generates B2B sales pitches that follow a proven four-part
narrative arc. Each element builds on the last to move a prospect from
comfortable inaction to confident investment:

| Element | Purpose | Core Question |
|---------|---------|---------------|
| Why Change | Reframe the status quo as unsafe | "What risks are you not seeing?" |
| Why Now | Create urgency with forcing functions | "Why can't this wait?" |
| Why You | Differentiate with proof | "Why us over the alternatives?" |
| Why Pay | Build the business case | "What's the return on this investment?" |

**Two pitch modes**:

| Mode | Use When | Research Style |
|------|----------|----------------|
| **Customer** | Deal-specific, named prospect | Company research, personalized proof points |
| **Segment** | Reusable template for a market | Industry research, scalable across prospects |

**Getting started**: The `/why-change` command launches the pitch workflow.
Aliases: `/pitch`, `/sales-pitch`, `/segment-pitch`.

**Phase 0 — Setup** configures the project:
1. **Portfolio discovery** — auto-finds cogni-portfolio projects in your workspace
2. **Market matching** — selects the relevant market segment
3. **TIPS discovery** — optionally pulls in trend data for enrichment
4. **Solution focus** — narrows to specific propositions
5. **Buyer role selection** — targets the pitch to the right audience:
   - Economic buyer (CFO) — cares about ROI and risk
   - Technical evaluator (CTO) — cares about architecture and integration
   - End users — care about day-to-day impact
   - Champion — your internal advocate who needs ammunition
6. **Language choice** — English or German (with DACH-specific formatting)
7. **Project initialization** — creates the directory structure for all phases

### Demo

Walk through `/why-change` setup:
1. Run `/why-change` and observe portfolio discovery
2. Show the list of available markets from your portfolio data
3. Select a market and configure buyer roles
4. Choose language and solution focus
5. Show the project directory structure created under your workspace

### Exercise

Ask the user to:
1. Decide: would your next real pitch be **customer** mode (specific prospect)
   or **segment** mode (reusable for a market)?
2. If you completed Course 6, select the matching market from your portfolio
3. Choose a buyer role — who is the primary audience for this pitch?
4. Run `/why-change` and complete Phase 0 setup

### Quiz

1. **Multiple choice**: When should you use customer mode instead of segment mode?
   - a) When you want a reusable template for multiple prospects
   - b) When you have a specific named prospect and want personalized research
   - c) When you don't have portfolio data yet
   - d) When the deal size is small
   **Answer**: b

2. **Multiple choice**: The four narrative elements in order are:
   - a) Why Pay, Why You, Why Now, Why Change
   - b) Why You, Why Change, Why Pay, Why Now
   - c) Why Change, Why Now, Why You, Why Pay
   - d) Why Now, Why Change, Why Pay, Why You
   **Answer**: c

### Recap

- cogni-sales produces B2B pitches following a four-part narrative arc
- Customer mode for named prospects; segment mode for reusable templates
- Phase 0 connects your portfolio, market, buyer role, and language
- The `/why-change` command (and its aliases) drives the entire workflow

---

## Module 2: Why Change & Why Now

### Theory (3 min)

**Phase 1 — Why Change** builds the case that the status quo is risky:

- **Problem-Solution-Benefit (PSB)** narrative structure drives each argument
- **Work backwards** from your portfolio capabilities to problems the buyer
  has not identified yet — these are the "unconsidered needs"
- Unconsidered needs are the key differentiator: challenges the prospect
  does not know they have, revealed through your unique insight
- **Contrast technique**: paint the "before" (hidden risks in the current
  approach) vs "after" (with your solution in place)
- Output: `research.json` + `narrative.md`
- **Quality gate**: you review the key findings before proceeding

**Phase 2 — Why Now** creates urgency through forcing functions:

| Forcing Function | Example |
|-----------------|---------|
| Regulatory deadlines | NIS2, DORA — scoped to industry applicability |
| Competitive pressure | Competitors already acting on this |
| Technology tipping points | Window of opportunity closing |
| Revenue cliffs | Compounding cost of continued inaction |

**Best practice**: Stack 2-3 forcing functions for maximum urgency.

**Cost-of-inaction** must be calibrated to the prospect's revenue range.
If the number is less than 0.5% of their annual revenue, a CFO will consider
it immaterial. Always sanity-check your figures against company size.

**TIPS enrichment** (optional): regulatory timelines from trend data and
gap analysis strengthen the urgency with external evidence.

### Demo

Walk through Phase 1 and Phase 2:
1. Show how the researcher agent discovers unconsidered needs by working
   backwards from portfolio features
2. Review the generated `research.json` — what did it find?
3. Move to Phase 2 — observe forcing function identification
4. Show the cost-of-inaction calculation and how it scales to revenue
5. Review the quality gate before proceeding

### Exercise

Ask the user to:
1. For their chosen market or customer, brainstorm 2 unconsidered needs —
   problems the buyer likely has not identified
2. Brainstorm 2 forcing functions — why must they act now?
3. Estimate a cost of inaction: what does one year of delay cost?
4. Sanity-check: is that number material relative to their revenue?

### Quiz

1. **Multiple choice**: What are "unconsidered needs"?
   - a) Features the buyer has already requested
   - b) Challenges the prospect has not identified, revealed by your insight
   - c) Needs that are too small to matter
   - d) Requirements listed in the RFP
   **Answer**: b

2. **Multiple choice**: Why must cost-of-inaction be calibrated to revenue?
   - a) Smaller numbers are easier to calculate
   - b) It looks more professional
   - c) If the amount is immaterial relative to revenue, leadership will not act
   - d) Regulators require it
   **Answer**: c

### Recap

- Phase 1 reveals unconsidered needs by working backwards from your capabilities
- The contrast technique makes the status quo feel unsafe
- Phase 2 stacks forcing functions to create urgency
- Cost-of-inaction must be material relative to the prospect's revenue
- TIPS data enriches both phases with external evidence

---

## Module 3: Why You & Why Pay

### Theory (3 min)

**Phase 3 — Why You** differentiates your offering using a three-layer
structure from your portfolio (Course 6):

| Layer | Question | Example |
|-------|----------|---------|
| **IS** | What is this capability? | "A real-time threat detection platform" |
| **DOES** | What does it do for the buyer? | "Reduces incident response time by 60%" |
| **MEANS** | Why can't competitors replicate it? | "Built on 15 years of proprietary threat intelligence" |

The **MEANS** layer is the competitive moat — the strategic reason your
solution is defensible. This is what separates a pitch from a feature list.

**Source authority matrix** scores evidence credibility from 1-5 to ensure
your claims are backed by trustworthy sources.

**DACH markets**: When language is set to German, the researcher performs
site-specific searches across German-language business sources.

**Phase 4 — Why Pay** builds the financial case:

- **ROI models**: quantified return on investment
- **TCO comparisons**: total cost of ownership vs alternatives
- **Compound cost calculation**: accumulated impact over a 3-year horizon
- **Revenue-scaled projections**: amounts calibrated to the prospect's
  revenue range (ARR min/max from segment data)
- **Three dimensions of impact**: direct savings, revenue growth, risk reduction
- **Quality gate**: you review and approve the business case before synthesis

### Demo

Walk through Phase 3 and Phase 4:
1. Take a proposition from your portfolio and show the IS-DOES-MEANS pitch
2. Show the source authority scoring for evidence used
3. Demonstrate competitor moat analysis
4. Move to Phase 4 — show a 3-year business case with revenue-scaled projections
5. Review the three dimensions of impact

### Exercise

Ask the user to:
1. Take one proposition from their portfolio (Course 6)
2. Write the three-layer pitch:
   - **IS**: What is it? (one sentence)
   - **DOES**: What does it do for the buyer? (include a number)
   - **MEANS**: Why can't competitors copy this? (your moat)
3. Estimate a 3-year business impact — even rough numbers help:
   - Direct savings
   - Revenue growth potential
   - Risk reduction value

### Quiz

1. **Multiple choice**: What does the MEANS layer represent?
   - a) The price of your solution
   - b) The features of your product
   - c) The competitive moat — why competitors cannot replicate this
   - d) The implementation timeline
   **Answer**: c

2. **Multiple choice**: Why must financial projections be revenue-scaled?
   - a) To impress the prospect with large numbers
   - b) To ensure amounts are credible and material for the prospect's size
   - c) Because all prospects have the same revenue
   - d) To simplify the calculation
   **Answer**: b

### Recap

- IS-DOES-MEANS turns features into a defensible competitive pitch
- The MEANS layer is the moat — the hardest and most important part
- Source authority scoring ensures credible evidence
- Financial projections must be calibrated to the prospect's revenue
- Three impact dimensions: savings, growth, and risk reduction

---

## Module 4: Synthesis & Deliverables

### Theory (3 min)

**Phase 5 — Synthesize** assembles all four phases into client-ready
deliverables using the pitch-synthesizer agent:

**Two output documents**:

| Document | Purpose | Structure |
|----------|---------|-----------|
| `sales-presentation.md` | Narrative arc for presenting | Flows from "your world is at risk" through "here's the return" |
| `sales-proposal.md` | Formal proposal for decision-makers | Executive summary, detailed sections, pricing rationale |

**Key synthesis rules**:
- Citations are renumbered sequentially across the full document
- German-language output uses proper headers and formatting (Umlauts, formal tone)
- **No methodology jargon in client-facing text** — terms like the internal
  phase names, "unconsidered needs", or "forcing functions" never appear
  in the output. These are your internal strategy; the client sees only
  the persuasive narrative

**Claims registration**: Key claims from the pitch are automatically
registered for verification through cogni-claims (Course 3).

**Quality gates**: You review and approve each phase before the synthesizer
runs. Nothing goes to the client without your sign-off.

**Cross-plugin polishing** — after synthesis, enhance with other tools:
- **cogni-copywriting** for executive-level language polish
- **cogni-visual** for PowerPoint presentation generation
- **cogni-claims** for source verification of all citations

### Demo

Walk through Phase 5:
1. Show how the synthesizer combines all four phases
2. Open `sales-presentation.md` — trace the narrative arc from risk
   through urgency to differentiation to business case
3. Open `sales-proposal.md` — show the formal structure with executive summary
4. Compare the two: same content, different format and tone
5. Show that no internal methodology terms appear in either document

### Exercise

Ask the user to:
1. Review the structure of a sales presentation: does the arc flow naturally?
   - "Your world is at risk" (from Phase 1)
   - "The clock is ticking" (from Phase 2)
   - "Only we can solve this" (from Phase 3)
   - "Here's what it's worth" (from Phase 4)
2. Check: would a client understand every heading and term?
3. Identify one section that could benefit from cogni-copywriting polish
4. Identify one claim that should be verified through cogni-claims

### Quiz

1. **Multiple choice**: What is the difference between the presentation and the proposal?
   - a) The presentation is longer
   - b) The presentation is a narrative arc for presenting; the proposal is a formal document for decision-makers
   - c) The proposal is less detailed
   - d) They contain completely different content
   **Answer**: b

2. **Multiple choice**: Why must methodology terms never appear in client-facing output?
   - a) They are copyrighted
   - b) Clients expect to see internal process language
   - c) They are internal strategy terms that would confuse or distract the client
   - d) They make the document too long
   **Answer**: c

### Recap

- The synthesizer combines four phases into two client-ready documents
- Presentation for narrative delivery; proposal for formal decision-making
- No internal methodology terms in client-facing output — ever
- Claims are registered for verification automatically
- Cross-plugin polishing elevates the final quality

---

## Module 5: Research, TIPS Integration & Full Pipeline

### Theory (3 min)

**Source authority matrix** — every piece of evidence is scored for credibility:

| Score | Source Type | Example |
|-------|-----------|---------|
| 5 | Government, regulatory, peer-reviewed | EU regulations, academic journals |
| 4 | Industry associations, major consulting firms | Gartner, McKinsey, industry bodies |
| 3 | Quality business media, established analysts | Financial Times, Bloomberg |
| 2 | Trade publications, company blogs | Industry magazines, vendor whitepapers |
| 1 | Forums, social media, unverified | Reddit, Twitter, anonymous posts |

**DACH-specific research**: For German-language markets, the researcher
performs site-specific searches across Bundesanzeiger, IHK, BSI, and other
authoritative German sources.

**TIPS integration** enriches every phase of the pitch:

| Phase | TIPS Contribution |
|-------|-------------------|
| Why Change | TIPS themes surface as unconsidered needs |
| Why Now | Regulatory timelines from TIPS trend data |
| Why You | Solution templates enriched by TIPS possibilities |
| Why Pay | Gap analysis from TIPS informs cost-of-inaction |

**Resume workflow**: The `pitch-status.sh` script checks project state.
Use `/why-change --project-path` to resume an interrupted pitch at the
last completed phase.

**Error recovery**:
- Web research fails: the agent retries with alternative search strategies
- Portfolio data incomplete: the pitch proceeds with available data and
  flags gaps for your review

### Demo

Compare customer mode vs segment mode for the same market:
1. Show a customer-mode pitch — named company, specific research,
   personalized proof points
2. Show a segment-mode pitch — industry template, reusable across prospects
3. Compare: where does personalization make the biggest difference?
4. Show `pitch-status.sh` output for a multi-phase project
5. Demonstrate resuming an interrupted pitch

### Exercise

Ask the user to:
1. Map the full sales pipeline for a real scenario:
   - **Portfolio** (Course 6): Define your propositions and messaging
   - **Marketing** (Course 9): Generate awareness content for the segment
   - **Sales pitch** (Course 10): Create the prospect-specific pitch
   - **Visual** (Course 7): Generate the presentation deck
2. Which plugin handles each step?
3. Where does TIPS data (Courses 4-5) add the most value?

### Quiz

1. **Hands-on**: Describe the sales pitch you would create for your next
   real prospect. What mode would you use? Who is the buyer? What are the
   two strongest forcing functions?

2. **Multiple choice**: What score does a government regulatory source get
   in the authority matrix?
   - a) 3
   - b) 4
   - c) 5
   - d) 2
   **Answer**: c

### Recap

- Source authority scoring ensures every claim has credible backing
- DACH research taps German-language authoritative sources
- TIPS data enriches all four phases of the pitch
- Resume interrupted pitches with `pitch-status.sh` and `--project-path`
- The full pipeline: Portfolio, Marketing, Sales, Visual — each step has a tool

---

## Course Completion

Congratulations! You now know how to:
- Set up and configure sales pitches with the Why Change methodology
- Build compelling Why Change and Why Now arguments with unconsidered needs and forcing functions
- Differentiate with IS/DOES/MEANS and build revenue-scaled business cases
- Synthesize four phases into client-ready presentations and proposals
- Integrate TIPS data and manage multi-phase pitch workflows

**Something unclear or broken?** Tell Claude what happened — cogni-issues will help you file it.

**Next recommended course**: Course 11 — Consulting Orchestration (Double Diamond)
