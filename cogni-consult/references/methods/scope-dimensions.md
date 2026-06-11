---
name: Scope Dimensions
inputs: [desired-outcome]
outputs: [key-question, scoping-dimensions, action-fields]
duration_estimate: "20-40 min with consultant"
requires_plugins: []
---

# Scope Dimensions

Anchor the engagement in one SMART framing question and five scoping dimensions, then close by declaring the 3-6 action fields that become the engagement's work-breakdown structure. The Key Question is the reference point every deliverable converges against — a sharp scope here makes every action field cheaper and crisper to work.

## When to Use

- Every engagement, immediately after setup — scoping precedes the existence of any action field
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

Draft it together with the consultant: propose 2–3 candidate framings from the desired outcome, stress each against the five criteria, and converge on one. A question failing two or more criteria is reframed, not accepted.

## The Five Scoping Dimensions

Work through each dimension as a guided conversation, capturing concise structured notes:

1. **Strategic Context** — strategic market context; company context; main competitors and customers and their behavior. What larger movement is this engagement embedded in?
2. **Scope** — the project focus; which companies/areas are affected; what is explicitly OUT of scope; adjacent problems being solved in parallel (and by whom).
3. **Stakeholder** — who is responsible; who is affected; their interests; how decisions are made (governance, veto points, cadence).
4. **Constraints / Barriers** — risks and mitigations; capability/competence gaps; missing facts, data, or analysis; resource and time restrictions; leadership or commitment gaps.
5. **Success factors** — how success is measured; key deliverables; KPIs; other performance measures the sponsor will actually be judged on.

## Action Fields — the WBS Close

Close by naming the main areas of action needed to resolve the central problem — 3–6 fields, each one line. Unlike research-seed approaches, action fields here ARE the work-breakdown structure: every later deliverable lives inside exactly one of them. Each field carries a kebab-case slug, a title, and a one-line framing (its intent phrased as a question or charge); the persistence shape is defined in `references/data-model.md`.

## Output Convention

Write the result to `scope/key-question.md`:

```markdown
---
slug: key-question
updated: {ISO date}
---

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
1. **{Field title}** (`{field-slug}`) — {one-line intent}
2. ...
```

## Quality Signals

- The key question fits in one sentence a sponsor would recognize as *their* question
- Every dimension has at least one concrete, falsifiable statement (names, numbers, dates)
- The out-of-scope list is non-empty — a scope with nothing excluded is not a scope
- Action fields map forward: each should be concrete enough to host named deliverables, and together they cover the key question without overlap
