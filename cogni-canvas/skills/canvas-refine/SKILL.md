---
name: canvas-refine
description: |
  Critique and improve an existing Lean Canvas section by section.
  This skill should be used when the user mentions "refine my canvas", "improve the canvas",
  "review my lean canvas", "canvas feedback", "strengthen my business model",
  "critique my canvas", "canvas is weak", "update the canvas", "evolve the canvas",
  "version my canvas", "pivot my canvas", "iterate on my canvas", "test assumptions",
  "is my canvas any good", "what's weak in my canvas", "stress-test my canvas",
  "challenge my assumptions", "poke holes in my business model", or has an existing
  canvas file they want to make better — even if they don't say "refine" explicitly.
  Also trigger when the user opens or references a lean canvas markdown file and asks
  for feedback, improvements, or simply says "look at this canvas" or "what do you think
  of my canvas". If the user says "pivot" in the context of a business model, use this skill.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: "<path to existing canvas file>"
---

# Refine a Lean Canvas

Critique an existing Lean Canvas and guide the user through improving it. Produces a new version with tracked changes in the evolution log.

## Format

Follow the file format specified in `$CLAUDE_PLUGIN_ROOT/references/canvas-format.md` for structure, frontmatter, and versioning rules.

## Workflow

### 1. Load the Canvas

Read the canvas file. If the user doesn't provide a path, search the workspace for lean canvas files:

```
Glob: **/*canvas*.md
```

If the file lacks YAML frontmatter, infer section status and note that frontmatter will be added on save.

### 2. Assess Current State

Produce a diagnostic overview:

**Section Health**

| Section | Status | Strength | Issue |
|---|---|---|---|
| Problem | filled | specific, measurable | Could add cost-of-inaction |
| Customer Segments | filled | well-segmented | Missing market size estimates |
| UVP | filled | clear | Too long — not a single sentence |
| Key Metrics | unfilled | — | Needs definition |
| ... | ... | ... | ... |

**Coherence Check** — flag misalignments between sections (consult the interdependency table in `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md`):
- Does the solution address the stated problems?
- Does the UVP speak to the primary segment's pain?
- Do revenue streams match what segments would pay for?
- Are channels realistic for reaching the defined segments?

**Maturity Assessment** — classify the canvas stage:
- **Draft**: Many unfilled or vague sections
- **Hypothesis**: All sections filled, untested
- **Validated**: Some assumptions tested with evidence
- **Evolved**: Multiple versions with data-driven changes

#### Example: Diagnostic Summary

> Your canvas is at **Hypothesis** stage — all 9 sections are filled, but none have been tested yet.
>
> **Strongest sections**: Problem (specific, quantified pain) and Customer Segments (clear beachhead market with budget signal).
>
> **Weakest section**: UVP — it reads like a feature list ("AI-powered automated proposal tool with templates and analytics") rather than a differentiator. Your segments aren't choosing between AI tools; they're choosing between hiring a proposal writer, using a template, or your product.
>
> **Coherence gap**: Your revenue model says "per-seat SaaS" but your customer segment is agencies with 3-5 people — per-seat pricing penalizes small teams, which is your primary segment. Consider per-project or flat-rate pricing.
>
> Want to fix the UVP first, or tackle the pricing misalignment?

Present the diagnostic to the user and ask: refine specific sections, or work through all issues systematically?

### 3. Refine Sections

For each section being refined, apply the quality criteria and guiding questions from `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md`.

**Refinement approach per section**:

1. **State what's strong** — acknowledge what works before critiquing
2. **Identify the gap** — be specific about what's missing or weak
3. **Suggest concrete improvements** — offer draft text, not just advice
4. **Ask for input** — the user knows their business better than any model
5. **Check ripple effects** — when a section changes, flag dependent sections that may need updating (e.g., changing Problem from "slow reporting" to "inaccurate reporting" means Solution, UVP, and Key Metrics all need review — consult the interdependency table)

**For unfilled sections** ("?" or empty):
- Ask focused questions to elicit content (2-3 questions, not a checklist)
- Offer hypotheses based on other sections ("Given your solution targets X, your key metric might be Y — does that resonate?")

**For draft sections** (vague or incomplete):
- Push for specificity: numbers, names, timelines
- Challenge assumptions: "How do you know customers will pay €15k?"
- Suggest structure: bullets, tiers, layers

**For filled sections** (substantive content):
- Stress-test coherence with other sections
- Check for common pitfalls specific to that section type
- Suggest sharpening, not rewriting

### 4. Track Changes

When refinements are confirmed:

1. Update the section content in the canvas
2. Bump the `version` number in frontmatter
3. Update the `updated` date
4. Update per-section `status` fields
5. Append a new entry to the Canvas Evolution log:

```markdown
### Version N — [Title summarizing the change]
**Date**: YYYY-MM-DD
**Key Insight**: What prompted this revision
**Changes**: What changed and why
```

6. Update Key Assumptions to Validate if new assumptions emerged
7. Update Next Iterations based on current state

### 5. Save and Summarize

Write the updated canvas file. Present a change summary:

| Section | Before | After | Change |
|---|---|---|---|
| UVP | draft | filled | Shortened to single sentence, segment-specific variants added |
| Key Metrics | unfilled | draft | Added 3 initial metrics |
| ... | ... | ... | ... |

**Version**: v1 -> v2
**Key insight**: [What drove this iteration]

Suggest next steps based on current maturity:
- **Draft → Hypothesis**: "N sections still unfilled — fill them next"
- **Hypothesis → Validated**: "Top assumptions to test: [list from evolution log]. Use `cogni-portfolio:portfolio-canvas` to extract entities, then validate with research-backed skills like `cogni-portfolio:markets` (TAM/SAM/SOM sizing) and `cogni-portfolio:compete` (competitive landscape)"
- **Validated → Evolved**: "Consider refining based on: [market feedback]"

## Refinement Modes

Support different refinement scopes:

- **Full review**: Assess all 9 sections, prioritize weakest
- **Section focus**: User specifies which section(s) to refine (e.g., "refine my UVP")
- **Coherence pass**: Focus only on cross-section alignment, not individual section quality
- **Assumption audit**: Extract all implicit assumptions, make them explicit, prioritize by risk

**Coherence pass example**: "Your Problem says 'agencies waste time on proposals' but your Channels section lists 'LinkedIn ads targeting enterprise procurement teams.' If your customer is small agencies, LinkedIn ads targeting enterprise buyers won't reach them. Either the channel or the segment needs to change."

**Assumption audit example**: "Your canvas contains at least 3 untested assumptions: (1) agencies spend 60-80 hrs/month on proposals — have you validated this? (2) they'd pay €99/month — based on what anchor? (3) 'word of mouth' as primary channel — do agency owners actually recommend tools to each other? I'd prioritize #1 since the entire value prop rests on it."

## Important Notes

- Read the existing canvas before suggesting changes — skipping this and guessing at content undermines trust immediately, since the user knows what they wrote and will notice if you get it wrong
- Present suggestions as options, not mandates — the user owns the business model
- Track every change in the evolution log — canvas history is valuable
- A section downgraded from "filled" to "draft" is fine if it surfaces a real weakness
- Preserve all evolution log entries — the history of *why* the canvas changed is often more valuable than the current version. Teams revisit evolution logs when pivoting to understand which assumptions failed and why
- When the user disagrees with a critique, respect their judgment and note the reasoning in the evolution log
