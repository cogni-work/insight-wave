# Tour: Consulting Engagement

**Duration**: 60 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: consult-setup → consult-scope → consult-action-fields → consult-design-thinking → consult-personas (resume anytime via consult-resume)
**Prerequisites**: None required — for deeper plugin context use `/cogni-help:cheatsheet cogni-consult` and `/cogni-help:cheatsheet cogni-knowledge`; see also `docs/plugin-guide/cogni-consult.md`.
**Audience**: Consultants running action-field engagements with compounding research

> **Note**: This tour previously covered the Double Diamond engagement of the
> archived cogni-consulting plugin; that content was retired with the archive.
> Legacy Double Diamond engagements still resolve via
> `cogni-consulting:consulting-resume` — everything below covers cogni-consult.

---

This tour walks a cogni-consult engagement as one workflow. You set up an
engagement with a bound cogni-knowledge base, scope one SMART key question into
3-6 action fields, run each deliverable through its own design-thinking loop,
and let acting stakeholder personas challenge the work before it counts as
done. The cheatsheets and `docs/plugin-guide/<plugin>.md` files cover the
supporting plugins in depth; this tour focuses on the engagement shape.

## Module 1: Setup & the Knowledge-Base Binding

### Theory (6 min)

`cogni-consult` organizes an engagement around three ideas: action fields as
the work-breakdown structure, a design-thinking loop per deliverable, and one
cogni-knowledge base as the central research tool. There are no engagement-wide
phase gates — each deliverable progresses at its own pace.

Setup frames the desired outcome, scaffolds the engagement directory
(`scope/`, `action-fields/`, `personas/`, `.metadata/`), and — critically —
binds one cogni-knowledge base to the engagement. Every later research run
deposits into that base, so the tenth deliverable starts with nine
deliverables' worth of prior synthesis instead of a blank search.

`consult-project.json` records the engagement fields and the knowledge-base
binding. This is the engagement's anchor file.

### Demo

Run `/cogni-consult:consult-setup`:
1. Enter engagement name, client, desired outcome, market, and language.
2. Show the scaffolded `cogni-consult/{slug}/` directory and `consult-project.json`.
3. Show the dispatched `knowledge-setup` creating the engagement's knowledge base.
4. Show the engagement registered for cross-session discovery.

### Exercise

Have the learner draft a one-sentence desired outcome for a real engagement
(or a hypothetical one). Test it: would you know at the end whether you
delivered it?

### Quiz

1. Why must the knowledge base be bound at setup rather than added later?
   **Answer**: The binding is what makes research compound — every deliverable's
   evidence run routes through the one base. Without it, each deliverable starts
   cold, and the binding cannot be retrofitted cleanly.

2. **Hands-on**: Open `consult-project.json` after setup and find the
   knowledge-base reference. One base per engagement, always.

### Recap

- cogni-consult: action fields as WBS, a DT loop per deliverable, one knowledge base
- Setup scaffolds the engagement and binds the cogni-knowledge base
- `consult-project.json` anchors the engagement
- No phase gates — deliverables track independently

---

## Module 2: Scoping — the SMART Key Question

### Theory (6 min)

`consult-scope` is the keystone conversation. It frames one SMART key question
(Specific, Measurable, Achievable, Relevant, Time-bound), then walks five
guided scoping dimensions: Strategic Context, Scope, Stakeholder,
Constraints / Barriers, and Success factors.

When a dimension needs market data or regulatory context the consultant cannot
supply, scoping routes the research through the engagement's bound knowledge
base — never raw web search. The synthesis lands in `scope/research/` for the
engagement record.

Scoping closes by deriving 3-6 action fields — thematic containers like
`market-evidence`, `portfolio-fit`, `go-to-market` — which become the
engagement's work-breakdown structure. The key question and field list are
written to `scope/key-question.md` and `consult-project.json`.

### Demo

Run `/cogni-consult:consult-scope`:
1. Frame a draft key question and sharpen it against the SMART criteria.
2. Walk the five scoping dimensions, noting where each surfaces a research gap.
3. Route one gap through the knowledge base and show the synthesis landing.
4. Derive the action fields and show them written to the project file.

### Exercise

For the engagement framed in Module 1, draft a key question and check it
against SMART. Then propose three candidate action fields and justify why each
is a distinct theme rather than a sub-task.

### Quiz

1. **Multiple choice**: How many action fields should scoping derive?
   - a) Exactly 4 — b) 3-6 — c) As many as the work needs — d) One per stakeholder
   **Answer**: b (six is the ceiling; more fields mean thinner deliverable sets
   and a harder-to-read WBS — merge closely related themes at scoping time)

2. **Hands-on**: Open `scope/key-question.md` and test the question: is it
   specific enough that you could fail to answer it?

### Recap

- One SMART key question anchors the engagement
- Five dimensions: Strategic Context, Scope, Stakeholder, Constraints, Success factors
- Research gaps route through the bound knowledge base, never raw web search
- Scoping closes with 3-6 action fields — the WBS

---

## Module 3: The Action-Field WBS

### Theory (6 min)

`consult-action-fields` turns the fields into a working plan. It renders the
fields × deliverables dashboard, plans each field's deliverable set, and
recommends the next deliverable to work.

For each field with an empty deliverable set, the skill reads the
deliverable-types catalog and proposes 1-3 deliverables by field-type affinity.
Confirmed entries are written to the field's `field.json` manifest.

Fields can be added, split, or merged at any point. Each deliverable lives in
exactly one field; splitting moves entries, it never duplicates them. Multiple
fields can have deliverables in-progress simultaneously — the WBS tracks them
independently.

### Demo

Run `/cogni-consult:consult-action-fields`:
1. Show the WBS dashboard (field, deliverable, state, DT stage, persona review).
2. Plan the deliverable set for one empty field from the catalog proposals.
3. Show the entries written to `field.json`.
4. Note the recommended next deliverable.

### Exercise

For the action fields drafted in Module 2, plan 1-3 deliverables per field.
For each, name the deliverable's audience in one phrase — if you can't, the
deliverable is probably a task, not a deliverable.

### Quiz

1. Why are action fields — not engagement phases — the work-breakdown structure?
   **Answer**: Fields contain deliverables that track independently, so nothing
   waits on an engagement-level gate. Parallel progress across fields is normal;
   the dashboard keeps it readable.

2. **Hands-on**: Re-render the WBS dashboard and find the recommended next
   deliverable. Does the recommendation match what you would have picked?

### Recap

- `consult-action-fields` renders the WBS dashboard and plans deliverable sets
- Catalog proposals seed empty fields; confirmed entries land in `field.json`
- One deliverable, one field; splitting moves, never duplicates
- Parallel in-progress deliverables across fields are fine

---

## Module 4: The Design-Thinking Loop

### Theory (7 min)

`consult-design-thinking` runs one deliverable at a time through five stages:

- **Empathize** — stakeholder empathy mapping; research gaps checked against the knowledge base first
- **Define** — lock 1-3 How-Might-We questions; evidence gaps routed through the base before the spec is locked
- **Ideate** — guided diverge → cluster → converge → sketch against the locked spec
- **Prototype** — draft the artifact with full `sources[]` lineage on every evidence-backed claim
- **Test** — acting personas challenge the draft; revise until it survives

The loop scales to fit — a simple deliverable converges in one pass through
each stage. Skipping it means no decision log and no persona challenge record,
which weakens the artifact's defensibility.

Research compounds here: at empathize, the skill first queries the engagement's
knowledge base. If a previous deliverable already researched the topic, the
prior synthesis is reused; only when the base is silent does a full research
pipeline run. The finalized synthesis is copied to
`action-fields/{field}/research/{topic}.md` for a stable path.

### Demo

Run `/cogni-consult:consult-design-thinking` on one deliverable:
1. Empathize — query the knowledge base for an evidence gap; show a hit vs. a miss.
2. Define — lock the HMW questions.
3. Ideate — walk one diverge → converge pass.
4. Prototype — show the drafted artifact with `sources[]` lineage on its claims.
5. Note that Test hands off to personas (Module 5).

### Exercise

Take one planned deliverable through empathize and define. At empathize, run
one knowledge-base query and note whether it hit prior research or triggered a
fresh run.

### Quiz

1. Why query the knowledge base before running new research?
   **Answer**: The base compounds — earlier deliverables' research runs are
   reusable synthesis. Querying first avoids re-researching covered topics and
   gets faster and richer as the engagement progresses.

2. **Hands-on**: Open the prototyped artifact and find one claim's `sources[]`
   lineage. Could you trace it back to its source if a correction were needed?

### Recap

- Five stages per deliverable: empathize → define → ideate → prototype → test
- Knowledge base queried first; full research only when the base is silent
- Syntheses copied to `action-fields/{field}/research/` at stable paths
- Every evidence-backed claim carries `sources[]` lineage

---

## Module 5: Persona Challenges & Resuming

### Theory (7 min)

`consult-personas` runs before a deliverable counts as tested. Two acting
personas ship by default: the **consulting partner** (frameworks, commercial
defensibility) and the **project manager** (delivery realism). They challenge
each deliverable in their own voice — what's missing, what they'd contest and
why, what would make them accept it.

Three modes: **Define** seeds 1-4 client-side personas from the scope's
Stakeholder dimension; **Enrich** populates a persona's empathy map with
engagement evidence; **Challenge** has the persona push back on a deliverable.
Each challenge is dispositioned by the consultant (accepted / revised /
rejected with reason) — the challenge informs, it never blocks.

Multi-session engagements are the norm. `consult-resume` is the read-only
re-entry point: it discovers registered engagements, renders the WBS dashboard,
and recommends exactly one next action — scope if scoping is open, the DT loop
for a mid-loop deliverable, personas for an open challenge pass.

### Demo

Run `/cogni-consult:consult-personas`, then `/cogni-consult:consult-resume`:
1. Have the partner persona challenge the Module 4 draft; show the pushback.
2. Disposition one challenge and show it recorded in the deliverable's
   `## Persona Challenges` section and the persona's work log.
3. Enrich one empathy-map quadrant with engagement evidence.
4. Run `consult-resume` and show the single recommended next action.

### Exercise

Have the project manager persona challenge your prototyped deliverable. Find
one objection the partner persona would not have raised — that's why two
perspectives ship by default.

### Quiz

1. Why enrich a persona before challenging with it?
   **Answer**: An unenriched persona challenges with generic frameworks. Enriched
   with the client's known pressures, it pushes back specifically — and specific
   objections surface while the draft is still cheap to change.

2. **Hands-on**: Start a fresh session and run `/cogni-consult:consult-resume`.
   Confirm it finds the engagement and recommends exactly one next action — not
   a menu.

### Recap

- Shipped personas: consulting partner and project manager; define/enrich/challenge modes
- Challenges are dispositioned and recorded; they inform, never block
- `consult-resume` is read-only: dashboard + exactly one recommendation
- Enrich early — specific personas give specific pushback

---

## Tour Complete

Next steps:
- Run the engagement against a real client problem
- Use `tour-research-to-report` to go deeper on the research pipeline behind the knowledge base
- Use `tour-portfolio-to-pitch` for sales-oriented deliverables
- Use `tour-trends-to-solutions` for marketing-oriented deliverables
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/consulting-engagement.md`
- See the narrative tutorial: `docs/workflows/consulting-engagement.md`
