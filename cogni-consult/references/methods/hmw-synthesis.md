---
name: HMW Synthesis
stage: define
type: convergent
inputs: [empathize-outputs, field-framing]
outputs: [deliverable-problem-spec]
duration_estimate: "20-30 min with consultant"
---

# How Might We (HMW) Synthesis

Sharpen the problem a single deliverable must solve into actionable "How Might We" questions. In cogni-consult this runs at the **define stage** of a deliverable's design-thinking loop: the inputs are the empathize-stage outputs (enriched personas, surfaced tensions) plus the action field's `framing` line, and the output is the deliverable's problem spec — recorded inline in the deliverable conversation and artifact, not as a separate file.

## When to Use

- At the define stage of every deliverable — the bridge between understanding (empathize) and option generation (ideate)
- Especially valuable when the empathize stage surfaced contradictions or tensions; the HMW question is where they become productive

## Guided Prompt Sequence

### Step 1: Review the Inputs
Restate the action field's `framing` (from `field.json`) and the key insights from the empathize stage — persona needs, say-do contradictions, think-feel tensions. Confirm with the consultant that these are the right raw material for this deliverable.

### Step 2: Draft HMW Questions
Draft 2-3 HMW questions for the deliverable. When personas exist in `personas/`, use **persona-centered framing** — this shifts the question from organizational outcomes to human outcomes, keeping the people the deliverable serves at the center.

**Persona-centered format** (recommended when personas exist):
- "How might we help [persona] to [need/outcome]?"
- Example: "How might we help shift leaders make data-driven decisions without adding to their cognitive load?"
- When a HMW addresses multiple personas, name the primary one and note secondary stakeholders.

**Outcome-centered format** (use when no personas exist or for system-level questions):
- "How might we [outcome]?"
- Example: "How might we make our monitoring platform the default choice for mid-market hybrid environments?"

The persona-centered format is more powerful because it forces specificity — "reduce costs" becomes "help shift leaders spend less time on paperwork." When both formats seem equally valid, prefer the persona-centered one.

Good HMW questions:

**Are the right scope**:
- Too broad: "How might we grow the business?" (useless)
- Too narrow: "How might we add a dark mode toggle?" (premature)
- Just right: "How might we help shift leaders make data-driven decisions without adding to their cognitive load?"

**Contain a tension**:
- "How might we help the field service team reduce response times while preserving the personal relationships customers depend on?"
- "How might we enter the French market without cannibalizing our DACH partnerships?"

**Are actionable**:
- Each HMW should be something the ideate stage can brainstorm solutions for
- If it's purely analytical ("How might we understand..."), reframe toward action

### Step 3: Refine with Consultant
Present the HMW questions and iterate:
- Are these the right questions for *this deliverable* to be answering?
- Do they capture the most important tensions?
- Is the scope right — not too broad, not too narrow?
- Missing any critical dimensions?

### Step 4: Lock the Problem Spec
Converge on 1-3 HMW questions that frame this deliverable's problem space — fewer than an engagement-level synthesis, because the scope is one deliverable, not a whole diamond. The locked spec is the brief for the ideate stage. Record it:

- Inline in the deliverable conversation summary, and
- As the deliverable artifact's opening "Problem" section once the prototype stage drafts the artifact, and
- As a decision-log entry (the define-stage decision: which problem framing was locked, and why).

No separate `hmw-questions.md` file — the deliverable artifact is the single home for this deliverable's content.
