---
name: Lean Canvas Authoring
phase: develop
type: divergent
inputs: [problem-statement, hmw-questions, discovery-synthesis, engagement-constraints]
outputs: [lean-canvas-document]
duration_estimate: "60-120 min with consultant"
requires_plugins: []
---

# Lean Canvas Authoring

Guide the consultant through creating a research-backed Lean Canvas — a one-page business model hypothesis informed by the Discovery and Define phases of the engagement.

## When to Use

- When the engagement needs to define a business model hypothesis
- Essential for: business-model-hypothesis
- Valuable for: market-entry, innovation-portfolio, gtm-roadmap

## Key Difference from Standalone Canvas Work

In a consulting engagement, the canvas is NOT built from cold Q&A. The Discovery phase has already produced market research, competitive intelligence, and trend data. The Define phase has framed the core problem and identified HMW questions. The canvas authoring method uses this research context to pre-populate and validate each section — producing a canvas that is grounded in evidence from day one.

## Guided Prompt Sequence

### Step 1: Load Engagement Context

Before starting the canvas, read these engagement artifacts:
- `define/problem-statement.md` — the core opportunity framing
- `define/hmw-questions.md` — the key questions the canvas should answer
- `discover/research/` — desk research findings
- `discover/competitive/` — competitive baseline (if exists)
- `discover/trends/` — trend scan findings (if exists)
- `define/assumptions.md` — mapped assumptions (if exists)

Summarize the key findings that will inform the canvas: market size data, competitive landscape, customer pain points, and trend signals.

### Step 2: Guide Section by Section

Work through sections in this order, using engagement research to inform each:

1. **Problem** — Start with pain points validated by discovery research. Reference specific findings. Ask what customers do today instead (existing alternatives/workarounds). Push for quantified impact (time, money, reputation cost).

2. **Customer Segments** — Use market research from Discovery to define segments. Primary segment first (beachhead market). Include bottom-up market size estimate using TAM/SAM/SOM data from research if available.

3. **UVP** — Given the problem and segment, what's the one-line differentiator? It must explain why switching from the current alternative (identified in Problem) is worth it. Cross-reference competitive baseline — the UVP must differentiate from named competitors.

4. **Solution** — What capabilities address the problem? Use trend signals and competitive gaps from Discovery to inform the solution. Separate MVP (v1, ship in 90 days) from future iterations (v2+).

5. **Channels** — How to reach the segments? Match channels to domain-specific buying behavior identified in Discovery research.

6. **Revenue Streams** — How does the business make money? Anchor pricing to competitive benchmarks from Discovery and customer willingness-to-pay signals.

7. **Cost Structure** — What does it cost to operate? Push for fixed vs. variable breakdown, top 3 cost drivers, CAC estimate, onboarding costs per customer, and support headcount.

8. **Key Metrics** — What numbers indicate health? 3-5 metrics max with leading and lagging indicators. Include at least one metric each for acquisition, activation, and revenue.

9. **Unfair Advantage** — What can't be copied? Cross-reference with competitive baseline — if competitors already have similar advantages, they're not unfair.

For each section:
- Pre-fill with hypotheses derived from engagement research where possible
- Present pre-filled content for consultant confirmation — don't assume
- Ask focused questions (2-3 max per section)
- Challenge vague answers with specific data from Discovery
- Allow "?" or "skip" — unfilled sections are normal for early canvases
- Track dependencies: if Problem changes, flag that UVP and Solution may need updating

Consult `$CLAUDE_PLUGIN_ROOT/references/lean-canvas-sections.md` for section-specific quality criteria, common pitfalls, and guiding questions.

### Step 3: Review Coherence

After all sections are addressed, review the canvas as a whole:
- Do segments actually have the stated problems (cross-reference with Discovery)?
- Does the solution address the problems?
- Does the UVP differentiate from competitors identified in Discovery?
- Do revenue streams match what segments would pay for?
- Are channels realistic for reaching the segments?
- Is there payer/beneficiary misalignment? If so, flag it.

Present any inconsistencies to the consultant for resolution.

### Step 4: Write the Canvas File

Follow the file format in `$CLAUDE_PLUGIN_ROOT/references/canvas-format.md`.

Write the canvas to `develop/lean-canvas.md` with:
- YAML frontmatter with accurate per-section status
- Version 1, created and updated dates set to today
- All 9 sections with content or "?" placeholders
- Evolution log with Version 1 entry noting engagement research context
- Key Assumptions to Validate (extract from discussion + cross-reference with Define assumptions)
- Next Iterations (suggest what to test first)

### Step 5: Summarize

Present a summary table:

| Section | Status | Summary | Evidence Source |
|---|---|---|---|
| Problem | filled | ... | Discovery research |
| Customer Segments | filled | ... | Market assessment |
| ... | ... | ... | ... |

Suggest next steps within the engagement:
- Continue to **lean-canvas-refinement** for iterative improvement
- Proceed to **lean-canvas-stress-test** in Deliver for multi-perspective pressure testing
- Use `cogni-portfolio:portfolio-canvas` to extract portfolio entities (products, features, markets) for downstream messaging

## Output Format

Save as `develop/lean-canvas.md` following the canvas format specification.

## Important Notes

- Canvas is a hypothesis document — "wrong" answers are expected, "missing" answers are acceptable
- Unlike standalone canvas creation, engagement canvases should cite Discovery findings as evidence
- Don't fill sections without consultant input — the canvas is a thinking tool, not a deliverable
- Keep the conversation flowing — don't turn it into a form-filling exercise
- A canvas with 5 filled sections and 4 honest "?" is better than 9 sections of vague filler
