---
name: canvas-create
description: |
  Create a new Lean Canvas from scratch through guided conversation.
  This skill should be used when the user mentions "new canvas", "create a lean canvas",
  "start a business model", "build a canvas", "lean canvas from scratch",
  "new business hypothesis", or wants to define a business model on a single page —
  even if they don't say "canvas" explicitly. Also trigger when the user describes
  a business idea and wants to structure it.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: "[optional: path to save canvas, or business idea as starting context]"
---

# Create a Lean Canvas

Guide the user through defining a Lean Canvas — a one-page business model hypothesis. The output is a markdown file with YAML frontmatter tracking version and section status.

## Format

Follow the file format specified in `$CLAUDE_PLUGIN_ROOT/references/canvas-format.md`. Every canvas has YAML frontmatter (canvas type, version, dates, per-section status) and 9 numbered markdown sections followed by an evolution log.

## Workflow

### 1. Determine Starting Point

Two paths depending on what the user provides:

- **Business idea provided**: Extract initial hypotheses from the description and pre-fill sections where possible. Present the pre-filled canvas for confirmation before writing.
- **No idea yet**: Start with Section 1 (Problem) and guide through each section sequentially.

If the user provides an argument path, use it as the output location. Otherwise ask where to save the canvas file.

### 2. Guide Section by Section

Work through sections in this order — it follows the natural flow of business model thinking:

1. **Problem** — Start here. What pain exists? For whom?
2. **Customer Segments** — Who has this problem? Primary segment first.
3. **UVP** — Given the problem and segment, what's the one-line differentiator?
4. **Solution** — What capabilities address the problem?
5. **Channels** — How to reach the segments?
6. **Revenue Streams** — How does the business make money?
7. **Cost Structure** — What does it cost to operate?
8. **Key Metrics** — What numbers indicate health?
9. **Unfair Advantage** — What can't be copied? (It's OK to leave this as "?" early on.)

For each section:
- Ask focused questions (2-3 max per section, not a wall of questions)
- Offer concrete suggestions based on what's been filled so far
- Challenge vague answers — push for specificity
- Allow "?" or "skip" — unfilled sections are normal for early canvases
- Track dependencies: if Problem changes, flag that UVP and Solution may need updating

Consult `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md` for section-specific quality criteria, common pitfalls, and guiding questions.

### 3. Review Coherence

After all sections are addressed, review the canvas as a whole:

- Do segments actually have the stated problems?
- Does the solution address the problems?
- Does the UVP differentiate from alternatives the segments use today?
- Do revenue streams match what segments would pay for?
- Are channels realistic for reaching the segments?

Present any inconsistencies to the user for resolution.

### 4. Write the Canvas File

Write the canvas markdown file with:
- YAML frontmatter with accurate per-section status
- Version 1, created and updated dates set to today
- All 9 sections with content or "?" placeholders
- Evolution log with Version 1 entry
- Key Assumptions to Validate (extract from the discussion)
- Next Iterations (suggest what to test first)

### 5. Summarize

Present a summary table:

| Section | Status | Summary |
|---|---|---|
| Problem | filled | ... |
| Customer Segments | filled | ... |
| ... | ... | ... |

Suggest next steps:
- Use `/cogni-canvas:canvas-refine` to critique and improve specific sections
- If cogni-portfolio is available, use `portfolio-canvas` to extract portfolio entities

## Important Notes

- Canvas is a hypothesis document — "wrong" answers are expected, "missing" answers are acceptable
- Push for specificity but respect the user's current knowledge level
- Never fill sections without user input or confirmation
- Keep the conversation flowing — don't turn it into a form-filling exercise
- A canvas with 5 filled sections and 4 honest "?" is better than 9 sections of vague filler
