---
name: Lean Canvas Refinement
phase: develop
type: convergent
inputs: [lean-canvas-document, discovery-synthesis, define-assumptions]
outputs: [refined-lean-canvas-document]
duration_estimate: "30-60 min with consultant"
requires_plugins: []
---

# Lean Canvas Refinement

Critique an existing Lean Canvas section by section and guide the consultant through improving it. Produces a new version with tracked changes in the evolution log. Use after lean-canvas-authoring to iterate on the initial hypothesis.

## When to Use

- After initial lean-canvas-authoring, when sections need sharpening
- When new Discovery data invalidates earlier assumptions
- When the consultant wants to pivot a section based on emerging findings
- Essential for: business-model-hypothesis
- Valuable for: market-entry, innovation-portfolio

## Guided Prompt Sequence

### Step 1: Load the Canvas

Read `develop/lean-canvas.md`. If it doesn't exist, the consultant should run lean-canvas-authoring first.

Also load engagement context for cross-referencing:
- `define/problem-statement.md`
- `discover/competitive/summary.md` (if exists)
- `define/assumptions.md` (if exists)

### Step 2: Assess Current State

Produce a diagnostic overview:

**Section Health**

| Section | Status | Strength | Issue |
|---|---|---|---|
| Problem | filled | specific, measurable | Could add cost-of-inaction |
| Customer Segments | filled | well-segmented | Missing market size estimates |
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

Present the diagnostic to the consultant and ask: refine specific sections, or work through all issues systematically?

### Step 3: Refine Sections

For each section being refined, apply the quality criteria and guiding questions from `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md`.

**Refinement approach per section**:

1. **State what's strong** — acknowledge what works before critiquing
2. **Identify the gap** — be specific about what's missing or weak
3. **Suggest concrete improvements** — offer draft text grounded in engagement research, not just advice
4. **Ask for input** — the consultant knows the business context better
5. **Check ripple effects** — when a section changes, flag dependent sections that may need updating

### Step 4: Track Changes

1. Update the section content in the canvas
2. Bump the `version` number in frontmatter
3. Update the `updated` date
4. Update per-section `status` fields
5. Append a new entry to the Canvas Evolution log
6. Update Key Assumptions to Validate if new assumptions emerged
7. Update Next Iterations based on current state

### Step 5: Save and Summarize

Write the updated canvas to `develop/lean-canvas.md`. Present a change summary:

| Section | Before | After | Change |
|---|---|---|---|
| UVP | draft | filled | Shortened to single sentence, competitor-differentiated |
| Key Metrics | unfilled | draft | Added 3 initial metrics from Discovery KPIs |

Suggest next steps based on maturity:
- **Draft -> Hypothesis**: "N sections still unfilled — fill them next"
- **Hypothesis -> Validated**: Proceed to lean-canvas-stress-test in Deliver to pressure-test assumptions
- **Validated -> Evolved**: Iterate based on stress-test findings or new data

## Refinement Modes

Detect the mode from the consultant's request:

- **Full review** (default): Section Health table, Coherence Check, Maturity Assessment, section-by-section refinement
- **Section focus**: Skip health table, jump to requested section(s), flag ripple effects
- **Coherence pass**: Cross-section alignment only, output misalignment list with severity
- **Assumption audit**: Extract every assumption, tag by source section, assign risk level, include testability assessment

## Output Format

Update `develop/lean-canvas.md` in place following the canvas format specification.

## Important Notes

- Read the existing canvas before suggesting changes
- Present suggestions as options, not mandates — the consultant owns the business model
- Track every change in the evolution log
- Preserve all evolution log entries — the history of why the canvas changed is valuable
- A section downgraded from "filled" to "draft" is fine if it surfaces a real weakness
