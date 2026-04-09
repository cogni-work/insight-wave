---
name: HMW Synthesis
phase: define
type: convergent
inputs: [theme-clusters, insight-statements]
outputs: [hmw-questions]
duration_estimate: "20-30 min with consultant"
requires_plugins: []
---

# How Might We (HMW) Synthesis

Transform theme clusters into actionable "How Might We" questions that frame the problem space for solution generation.

## When to Use

- After affinity clustering has produced prioritized theme clusters
- The bridge between Define and Develop — HMW questions become the brief for option generation
- Essential for all vision classes

## Guided Prompt Sequence

### Step 1: Review Clusters
Present the top 3-5 theme clusters with their insight statements. Confirm these are the right focus areas.

### Step 2: Draft HMW Questions
For each priority cluster, draft 2-3 HMW questions. When personas exist in `personas/`, use **persona-centered framing** — this shifts the question from organizational outcomes to human outcomes, keeping the people we design for at the center.

**Persona-centered format** (recommended when personas exist):
- "How might we help [persona] to [need/outcome]?"
- Example: "How might we help shift leaders make data-driven decisions without adding to their cognitive load?"
- When a HMW addresses multiple personas, name the primary one and note secondary stakeholders: "How might we help the IT team (3 people) manage a platform that shift leaders trust — without creating a vendor dependency they can't exit?"

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
- Each HMW should be something a team could brainstorm solutions for
- If it's purely analytical ("How might we understand..."), reframe toward action

### Step 3: Refine with Consultant
Present the HMW questions and iterate:
- Are these the right questions to be answering?
- Do they capture the most important tensions?
- Is the scope right — not too broad, not too narrow?
- Missing any critical dimensions?

### Step 4: Converge on 3-5
Select the 3-5 HMW questions that best frame the engagement's problem space. These become the brief for Diamond 2.

## Output Format

Save as `define/hmw-questions.md`:

```markdown
# How Might We Questions

Based on [N] discovery themes and [N] verified assumptions.

1. **HMW help [persona] to [need/outcome]?**
   Cluster: [source cluster] | Priority: [1-5] | Persona: [persona-slug or "system-level"]

2. **HMW help [persona] to [need/outcome]?**
   Cluster: [source cluster] | Priority: [1-5] | Persona: [persona-slug or "system-level"]

...
```
