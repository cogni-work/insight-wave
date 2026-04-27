# Tour: Consulting Engagement

**Duration**: 75 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-consulting setup → Discover → Define → Develop → Deliver
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-consulting`, `/cogni-help:cheatsheet cogni-research`, `/cogni-help:cheatsheet cogni-trends`, `/cogni-help:cheatsheet cogni-portfolio`; see also `docs/plugin-guide/cogni-consulting.md`.
**Audience**: Consultants running structured Double Diamond engagements

---

This tour walks the cogni-consulting Double Diamond engagement as one workflow.
You set up an engagement, run the four phases (Discover → Define → Develop →
Deliver) with their dispatched plugins, and produce final deliverables. The
cheatsheets and `docs/plugin-guide/<plugin>.md` files cover the dispatched plugins
in depth; this tour focuses on the phase orchestration.

## Module 1: Setup & Vision Framing

### Theory (6 min)

`cogni-consulting` orchestrates the British Design Council's Double Diamond model:
divergent-convergent thinking applied twice — once to the problem (Discover →
Define) and once to the solution (Develop → Deliver). Each phase has gates;
each gate has success criteria.

The setup phase frames the engagement: client name, scope, vision statement,
phase gate criteria. The vision statement is high-leverage — every subsequent
phase tests itself against the vision. Without it, phases drift.

`consulting-project.json` tracks phase progress, dispatched plugins, and gate
sign-offs. This is the engagement's audit trail.

### Demo

Run `/consulting-setup`:
1. Enter client name, scope, and a draft vision statement.
2. Define gate criteria for each phase (what does "Discover complete" mean?).
3. Show the produced `consulting-project.json`.
4. Show how the orchestrator will dispatch to plugins per phase.

### Exercise

Have the learner draft a vision statement for a real engagement they're working
on (or a hypothetical one). Test it: is it specific enough that you could fail
to deliver it?

### Quiz

1. Why does the Double Diamond apply divergence-convergence twice?
   **Answer**: First diamond explores the problem space (Discover diverges, Define
   converges); second explores the solution space (Develop diverges, Deliver
   converges). Solving the wrong problem with the right solution is the failure
   mode each diamond prevents.

2. **Hands-on**: Open `consulting-project.json` after setup and find the gate
   criteria. Are they testable?

### Recap

- Double Diamond: Discover → Define → Develop → Deliver, each with gates
- Vision statement is high-leverage — it tests every phase's output
- `consulting-project.json` is the engagement audit trail
- Set gate criteria upfront; they prevent ambiguous phase advances

---

## Module 2: Discover Phase

### Theory (6 min)

The Discover phase diverges to build a rich understanding of the problem
landscape. `/consulting-discover` dispatches to `cogni-research` (targeted
deep-dives on specific questions) and `cogni-trends` (mapping the strategic
trend landscape).

The phase is about breadth. Cast a wide net — gathering signals you'll converge
on in Define. The temptation is to skip ahead to solutions; resist it. Define
phase quality depends on Discover thoroughness.

Key outputs: research findings, trend analysis, landscape map, stakeholder
interview notes (if conducted offline).

### Demo

Run `/consulting-discover`:
1. Dispatch cogni-research with a specific deep-dive question.
2. Dispatch cogni-trends to map the trend landscape.
3. Show the produced research artifacts and TIPS project.
4. Walk through the landscape map output.

If the engagement has stakeholder interview notes, show how to import them as
structured context for Define.

### Exercise

For the engagement framed in Module 1, draft three Discover questions: one for
deep research, one for trend scouting, one for stakeholder interviews. Run at
least one via `/consulting-discover`.

### Quiz

1. Why is Discover about breadth, not depth?
   **Answer**: Depth on the wrong question wastes time; breadth surfaces the right
   questions. Define is where breadth converges to focus — Discover's job is to
   give Define enough material.

2. **Hands-on**: After running `/consulting-discover`, find one finding you didn't
   anticipate. That's the value of breadth — surfacing the unknown unknowns.

### Recap

- Discover diverges; gather signals broadly
- Dispatches to cogni-research (deep-dives) and cogni-trends (landscape)
- Don't skip to solutions; Define depends on Discover thoroughness
- Stakeholder interview notes can be imported as structured context

---

## Module 3: Define Phase

### Theory (6 min)

The Define phase converges from discovery insights to a clear problem statement.
`/consulting-define` dispatches to `cogni-portfolio` (propositions),
`cogni-consulting` lean canvas methods (business-model-hypothesis vision class),
and `cogni-narrative` (problem framing).

This is where breadth becomes focus. Select the strongest opportunities surfaced
in Discover; reject the rest. The lean canvas methods test business model
hypotheses quickly — does this opportunity make sense as a business?

Key outputs: defined problem space, portfolio propositions, business model
hypothesis, problem-framing narrative.

### Demo

Run `/consulting-define`:
1. Review Discover artifacts.
2. Pick 1-3 opportunities to converge on.
3. Dispatch cogni-portfolio for IS/DOES/MEANS propositions.
4. Use lean canvas methods to test business model viability.
5. Run cogni-narrative for problem framing.

### Exercise

For the engagement, take three opportunities from Discover and rank them by:
business model viability, alignment with the vision, evidence strength. Pick the
top one to converge on.

### Quiz

1. **Multiple choice**: Define produces a problem statement. What's the test for "good"?
   - a) Specific enough that you could fail to solve it — b) Broad enough to cover
     all opportunities — c) Aligned with the vision — d) Approved by the client
   **Answer**: a (specificity is the test; broad statements lead to fuzzy solutions)

2. **Hands-on**: Compare your problem statement to the engagement vision. Does
   solving the problem advance the vision? If not, redefine.

### Recap

- Define converges; pick the strongest opportunities
- Dispatches to cogni-portfolio (propositions), lean canvas (hypothesis), cogni-narrative (framing)
- Test business model viability before committing
- Problem statement test: specific enough to fail

---

## Module 4: Develop Phase

### Theory (6 min)

The Develop phase diverges to generate and explore solution options.
`/consulting-develop` dispatches to `cogni-copywriting` (polish), `cogni-narrative`
(solution story), and `cogni-claims` (verify).

Develop is about quality — take time to polish and verify. Run claims verification
before any client-facing content. The Develop phase produces the artifacts that
will become Deliverables, so quality compounds.

Stakeholder review (via `cogni-copywriting`) pressure-tests the narrative from
multiple perspectives — buyer, sales, marketer, technical reviewer. Verbal
agreement in a meeting is not the same as multi-stakeholder review.

Key outputs: polished solution narrative, verified claims, refined content.

### Demo

Run `/consulting-develop`:
1. Take the problem statement from Define.
2. Generate 2-3 solution options via cogni-narrative.
3. Polish each via `/copywrite`.
4. Run `/verify-claims` against the polished narrative.
5. Run `/review-doc` for stakeholder-perspective scoring.

### Exercise

For one solution option, run the full polish + verify + review chain. Note where
each step caught issues the previous didn't.

### Quiz

1. Why run claims verification in Develop, not Deliver?
   **Answer**: Verification surfaces source quality issues that take time to fix.
   In Deliver, you don't have time. Verifying in Develop keeps Deliver focused
   on packaging.

2. **Hands-on**: After `/review-doc`, identify one stakeholder perspective that
   raised an issue the others missed. That's why multi-perspective review matters.

### Recap

- Develop diverges (solution options) but emphasizes quality
- Dispatches to cogni-copywriting (polish), cogni-narrative (story), cogni-claims (verify)
- Multi-stakeholder review pressure-tests beyond verbal agreement
- Verify in Develop; Deliver focuses on packaging

---

## Module 5: Deliver Phase

### Theory (6 min)

The Deliver phase converges on validated, actionable outcomes.
`/consulting-deliver` dispatches to `cogni-visual` (slides/maps), `cogni-sales`
(pitch), and `cogni-marketing` (go-to-market materials).

Match deliverable format to audience: exec deck for sponsors, detailed report for
operations, sales pitch for revenue teams, marketing campaign for external launch.
Often a single engagement produces multiple deliverable formats from the same
Develop output.

For sales-oriented engagements, dispatch cogni-sales for the pitch deck. For
marketing-oriented engagements, dispatch cogni-marketing for GTM materials. For
strategic engagements, both.

`/consulting-export` packages final deliverables into a single bundle — PPTX,
DOCX, XLSX, Excalidraw, themed HTML — for client handoff.

### Demo

Run `/consulting-deliver` followed by `/consulting-export`:
1. Pick deliverable formats based on the engagement's audience mix.
2. Dispatch cogni-visual for slides and any architecture diagrams.
3. Dispatch cogni-sales if a pitch is needed.
4. Dispatch cogni-marketing if GTM materials are needed.
5. Run `/consulting-export` for the bundled handoff.

### Exercise

For the engagement, decide the audience mix (sponsor, ops, sales, external) and
pick the matching deliverable formats. Justify each format choice in one sentence.

### Quiz

1. Why does Deliver produce multiple formats from one Develop output?
   **Answer**: Different audiences consume content differently. Same insight, three
   formats — exec deck for board, detailed report for ops, pitch for sales.

2. **Hands-on**: Run `/consulting-export` and open the bundle. Confirm every
   deliverable is present and themed consistently.

### Recap

- Deliver converges on validated outcomes; multiple formats possible
- Dispatches to cogni-visual (slides), cogni-sales (pitch), cogni-marketing (GTM)
- Match format to audience: sponsor, ops, sales, external
- `/consulting-export` bundles the handoff package

---

## Tour Complete

Next steps:
- Run the engagement against a real client problem
- Use `tour-research-to-report` for deeper Discover work
- Use `tour-portfolio-to-pitch` for sales-oriented engagements
- Use `tour-trends-to-solutions` for marketing-oriented engagements
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/consulting-engagement.md`
- See the narrative tutorial: `docs/workflows/consulting-engagement.md`
