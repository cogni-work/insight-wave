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

If the user provides an argument path, use it as the output location. Otherwise suggest saving to `{workspace}/cogni-canvas/{project-slug}/lean-canvas.md` — this convention keeps canvases organized by project and makes them easy for sibling skills (canvas-refine, canvas-stress-test) to find.

### 2. Guide Section by Section

Work through sections in this order — it follows the natural flow of business model thinking:

1. **Problem** — Start here. What pain exists? For whom? Ask what customers do today instead (existing alternatives/workarounds) — this grounds the problem in reality and feeds the UVP later.
2. **Customer Segments** — Who has this problem? Primary segment first. Push for a bottom-up market size estimate: how many potential customers exist, and what's the rough addressable market in currency? Even a back-of-napkin calculation (number of targets x average deal size) is far more useful than "?".
3. **UVP** — Given the problem and segment, what's the one-line differentiator? It must explain why switching from the current alternative (identified in Problem) is worth it. If the user can't articulate this, flag it as the most critical gap in the canvas.
4. **Solution** — What capabilities address the problem? After listing components, ask: "Which of these are essential for the first paying customer?" Help separate MVP (v1, ship in 90 days) from future iterations (v2+). A canvas with a clear v1/v2 split is dramatically more useful than a flat feature list.
5. **Channels** — How to reach the segments? Match channels to the domain — a medical device sells through KOLs and conferences, not LinkedIn ads; a B2B SaaS sells through content and partnerships, not trade shows.
6. **Revenue Streams** — How does the business make money? If the user hasn't determined pricing, don't just accept "?" — help anchor to what customers currently spend on the problem or alternatives. Even "current spend is roughly X, so our price needs to be in the Y range to justify switching" is far more useful than unfilled. A rough range beats a blank.
7. **Cost Structure** — What does it cost to operate? Push systematically for: fixed vs. variable breakdown, top 3 cost drivers, customer acquisition cost estimate, onboarding/setup costs per customer, and support headcount. These are the costs that Operations & Finance personas consistently find missing in canvases.
8. **Key Metrics** — What numbers indicate health? Aim for 3-5 metrics max with a mix of leading (predictive) and lagging (outcome) indicators. Include at least one metric each for acquisition, activation, and revenue. Ask: "What single number would tell you the business is working?"
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
- Is the person who pays the same as the person who benefits? If not (e.g., lab pays but ICU benefits), flag the payer/beneficiary misalignment — it changes the sales motion and pricing justification
- Are channels realistic for reaching the segments?
- Do channels depend on a single person or relationship? If so, flag the concentration risk and ask what the fallback channel is

Present any inconsistencies to the user for resolution.

### 4. Write the Canvas File

Write the canvas markdown file with:
- YAML frontmatter with accurate per-section status — double-check that the status values (filled/draft/unfilled) match the actual section content, and that the summary table counts match the frontmatter. Discrepancies between these are a common error.
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
- Use `/cogni-canvas:canvas-stress-test` to pressure-test the canvas from 4 stakeholder perspectives (Investor, Customer, Technical, Operations) — this reveals blind spots that a single-perspective review misses
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
