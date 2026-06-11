---
name: Guided Ideation
stage: ideate
type: divergent-to-convergent
inputs: [deliverable-problem-spec, personas, consultant-expertise]
outputs: [solution-sketches]
duration_estimate: "45-60 min"
---

# Guided Ideation

A structured brainstorming method that moves from divergent idea generation to convergent solution selection. In cogni-consult it runs at the **ideate stage** of a deliverable's design-thinking loop: the input is the define-stage problem spec (the locked HMW questions), and the output feeds the prototype stage directly.

## When to Use

- At the ideate stage of any deliverable whose shape is not predetermined — when there is a real choice about what the deliverable should contain or recommend
- Works well when solutions require human judgment and creativity rather than data analysis, and when the consultant and/or stakeholders have domain expertise to draw on
- Keep it brief for deliverables with an obvious shape (e.g. a standard market-sizing table): one diverge-converge pass is enough

## Facilitation Flow

### 1. Restate the Challenge

Start by reading back the deliverable's define-stage problem spec (the locked HMW questions). Confirm the consultant still sees this as the right framing. If understanding shifted since define, loop back — the design-thinking loop may re-enter earlier stages.

### 2. Diverge — Generate Ideas

The goal is quantity, not quality. Suspend judgment. Ask the consultant to think broadly:

- "What are all the ways we could address this?"
- "What would you do if there were no constraints?"
- "What's the simplest possible version?"
- "What would a competitor do? A startup? A completely different industry?"

Capture every idea — even half-formed ones. Aim for 10-20 ideas. If the consultant stalls below 8, use creative constraints to unlock more:

| Constraint | Prompt |
|---|---|
| Time | "What if you had to solve this by Friday?" |
| Budget | "What if the budget were zero? What if it were unlimited?" |
| Scale | "What if this had to serve 10x the audience?" |
| Inversion | "What's the opposite of the current approach?" |
| Analogy | "How does [another domain] solve a similar problem?" |

### 3. Cluster Ideas

Group the raw ideas into 3-6 themes. Name each cluster. Some ideas will span clusters — note the connections but assign each idea to its primary cluster.

### 4. Converge — Select Top Ideas

For each cluster, ask the consultant to identify the most promising idea. Selection criteria to guide the conversation:

- **Impact**: How much does this move the needle on the HMW question?
- **Feasibility**: Can we actually do this with available resources?
- **Energy**: Does the consultant (or team) feel excited about this?

Narrow to 2-3 top ideas.

### 5. Solution Sketching

For each top idea, flesh it out into a rough solution design:

- **What**: Describe the solution in 2-3 sentences
- **Who**: Who does what? (roles, responsibilities)
- **How**: Key steps or activities involved
- **When**: Rough timeline or sequence
- **What could go wrong**: Top 1-2 risks and how to mitigate them

These sketches are the direct input for the prototype stage — the strongest sketch (or a deliberate combination) becomes the deliverable artifact's spine.

### 6. Quick Feasibility Check

For each solution sketch, rate:
- Can we start this within 2 weeks? (yes/no/depends)
- Do we have the people? (yes/need to recruit/need external help)
- What's the biggest unknown?

This check prevents the deliverable from recommending a beautiful design that can't actually be executed.

## Output

The ideation results live inline in the deliverable's working conversation and flow into the artifact at the prototype stage — record the selected idea(s), the rejected clusters, and the selection rationale as an "Options considered" section of the deliverable artifact. Log the method selection in `.metadata/method-log.json` (proposed vs. selected, with rationale) per the data model.

## Tips for the Facilitator

- Silence is productive — give the consultant time to think rather than filling gaps
- Capture the consultant's exact words — paraphrasing too early loses nuance
- If one idea dominates, deliberately explore alternatives before accepting it
- The best ideas often come from combining two weaker ones
