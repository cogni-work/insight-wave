---
name: Key Question Scoping
phase: 0-scope
type: convergent
inputs: [engagement-vision]
outputs: [key-question, scoping-dimensions, action-fields]
duration_estimate: "20-40 min with consultant"
requires_plugins: []
---

# Key Question Scoping

Anchor the engagement in one SMART framing question and five scoping dimensions before divergent Discover work begins. The Key Question becomes the reference point every later phase converges against — a sharp scope here makes every downstream phase cheaper and crisper.

## When to Use

- Every engagement, immediately after setup — the 0-scope phase exists for this method
- Re-run when the engagement pivots (new sponsor, changed market context, scope dispute)

## The Key Question

One framing question for the whole engagement, tested against SMART:

| Criterion | Test |
|---|---|
| **S**pecific | Names the actor, the domain, and the decision — no "improve things" vagueness |
| **M**easurable | Success can be observed or counted; ties to the Success-factors dimension below |
| **A**chievable | Within the client's capability and mandate to act on |
| **R**ealistic | Answerable within the engagement's resources and access |
| **T**ime-oriented | Carries an explicit horizon ("by FY27", "within 12 months") |

Draft it WITH the consultant: propose 2–3 candidate framings from the engagement vision, stress each against the five criteria, and converge on one. A question failing two or more criteria is reframed, not accepted.

## The Five Scoping Dimensions

Work through each dimension as a guided conversation, capturing concise structured notes:

1. **Strategic Context** — strategic market context; company context; main competitors and customers and their behavior. What larger movement is this engagement embedded in?
2. **Scope** — the project focus; which companies/areas are affected; what is explicitly OUT of scope; adjacent problems being solved in parallel (and by whom).
3. **Stakeholder** — who is responsible; who is affected; their interests; how decisions are made (governance, veto points, cadence).
4. **Constraints / Barriers** — risks and mitigations; capability/competence gaps; missing facts, data, or analysis; resource and time restrictions; leadership or commitment gaps.
5. **Success factors** — how success is measured; key deliverables; KPIs; other performance measures the sponsor will actually be judged on.

## Action Fields

Close by naming the main areas of action needed to resolve the central problem — 3–6 fields, each one line. These seed the Discover phase's research topics and the Define phase's assumption inventory.

## Output Convention

Write the result to `0-scope/key-question.md`:

```markdown
# Key Question

> {the SMART key question}

## SMART check
{one line per criterion: how the question satisfies it}

## Strategic Context
...

## Scope
**In:** ...
**Out:** ...
**Adjacent:** ...

## Stakeholder
...

## Constraints / Barriers
...

## Success factors
...

## Action fields
1. ...
2. ...
```

## Quality Signals

- The key question fits in one sentence a sponsor would recognize as *their* question
- Every dimension has at least one concrete, falsifiable statement (names, numbers, dates)
- The out-of-scope list is non-empty — a scope with nothing excluded is not a scope
- Action fields map forward: each should be traceable into a Discover research topic
