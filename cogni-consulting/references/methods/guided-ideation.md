---
name: guided-ideation
description: Facilitated creative session for generating and selecting solution ideas from HMW questions.
phase: develop
---

# Guided Ideation

A structured brainstorming method that moves from divergent idea generation to convergent solution selection. Designed for bounded challenges where the problem is understood and the goal is to design a concrete solution.

## When to Use

Best suited for `how-might-we` engagements and as a complement to plugin-powered methods in other vision classes. Works well when:
- The challenge is well-defined (a clear HMW question exists)
- Solutions require human judgment and creativity rather than data analysis
- The consultant and/or stakeholders have domain expertise to draw on
- Time is short — this method produces results in a single session

## Facilitation Flow

### 1. Restate the Challenge

Start by reading back the HMW question(s) from `define/hmw-questions.md`. Confirm the consultant still sees these as the right framing. If the HMW shifted during earlier phases, update before proceeding.

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

These sketches become the input for the option synthesis or directly for the solution brief.

### 6. Quick Feasibility Check

For each solution sketch, rate:
- Can we start this within 2 weeks? (yes/no/depends)
- Do we have the people? (yes/need to recruit/need external help)
- What's the biggest unknown?

This check prevents the engagement from producing a beautiful design that can't actually be executed.

## Output

Save the full ideation session to `develop/ideation/`:
- `ideation-log.md` — all raw ideas, clusters, and selection rationale
- Top solution sketches feed into `develop/options/option-synthesis.md` or directly into `deliver/solution-brief.md`

## Tips for the Facilitator

- Silence is productive — give the consultant time to think rather than filling gaps
- Capture the consultant's exact words — paraphrasing too early loses nuance
- If one idea dominates, deliberately explore alternatives before accepting it
- The best ideas often come from combining two weaker ones
