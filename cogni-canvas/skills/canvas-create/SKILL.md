---
name: canvas-create
description: |
  Create a new Lean Canvas from scratch through guided conversation.
  This skill should be used when the user mentions "new canvas", "create a lean canvas",
  "start a business model", "build a canvas", "lean canvas from scratch",
  "new business hypothesis", "business model canvas", "BMC", "one-pager",
  "startup idea", "validate my idea", "structure my idea", "plan my business",
  "map out my business", "business plan on a page", or wants to define a business
  model on a single page — even if they don't say "canvas" explicitly. Also trigger
  when the user describes a business idea and wants to structure, validate, or
  pressure-test it, or when they say something like "I have an idea for..."
  and want to go from vague concept to structured hypothesis.
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

#### Example: Natural Section Guidance

Good conversational flow for the Problem section — notice how it asks one question at a time, builds on the answer, and pushes for specificity without sounding like a survey:

> **Assistant**: Let's start with the problem. Who is struggling, and what's the pain? Don't worry about getting it perfect — we'll sharpen it as we go.
>
> **User**: Small agencies waste too much time on proposals.
>
> **Assistant**: That's a solid starting point. Let me push on it — do you know roughly how much time? Like, 5 hours per proposal or 2 days? And what part of the process is the bottleneck — the research, the writing, the design?
>
> **User**: Mostly the writing. Probably 6-8 hours per proposal, and they do maybe 10 a month.
>
> **Assistant**: So that's 60-80 hours a month on proposal writing alone — basically a full-time person. Let me capture this:
>
> **Problem**: Small agencies spend 60-80 hours/month writing proposals manually, with writing (not research or design) as the primary bottleneck.
>
> Does that feel right? Then we'll figure out who exactly these agencies are.

One question leads to the next. Quantify, reflect back, move forward — not a checklist of 5 questions dumped at once.

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
- If cogni-portfolio is available, use `portfolio-canvas` to extract portfolio entities (products, features, markets) — from there, `cogni-portfolio:markets` can size your markets with real data and `cogni-portfolio:compete` can map competitors

## Important Notes

- Canvas is a hypothesis document — "wrong" answers are expected, "missing" answers are acceptable
- Push for specificity but respect the user's current knowledge level
- Don't fill sections without user input or confirmation — the canvas is a *thinking tool*, not a deliverable. If you fill it for them, they skip the hard thinking that makes the canvas valuable. Pre-filling from a provided business description is fine, but always present it for confirmation
- Keep the conversation flowing — don't turn it into a form-filling exercise
- A canvas with 5 filled sections and 4 honest "?" is better than 9 sections of vague filler
- **Form-filling** (avoid): "What is the problem? Who is the customer? What is your UVP?" all at once
- **Conversational** (preferred): Guide one section, reflect back, let the answer inform the question for the next. It should feel like a conversation about their business, not a questionnaire
