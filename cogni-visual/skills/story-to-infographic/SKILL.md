---
name: story-to-infographic
description: >
  Transform any narrative (insight summary, trend report, strategy document, sales pitch,
  research report) into a single-page infographic brief optimized for visual scanning. Use
  this skill whenever the user mentions "infographic", "Infografik", "visual summary",
  "one-page visual", "data poster", "single-page overview", "visuelle Zusammenfassung",
  "Dateninfografik", "create infographic from report", "make this visual", "infographic
  from narrative", "stat sheet", "KPI poster", or wants to distill a narrative into a
  scannable visual with hero numbers, icons, and minimal text. Also trigger for "dashboard
  poster", "Einseiter mit Zahlen", "visual one-pager", and requests to summarize a report
  as a single visual page. Trigger equally on named-style requests — "Economist-style
  one-pager", "Economist data page", "The Economist infographic", "data journalism
  infographic", "Tufte data-ink one-pager", "FT visual journalism infographic",
  "magazine-style data page", "Mike Rohde sketchnote", "RSA Animate whiteboard",
  "sketchnoting", "visual facilitation", "graphic recording", "Back of the Napkin
  diagram", "whiteboard explainer" — these are all valid entry points. Produces an
  infographic-brief.md in one of two style families: a hand-drawn family (sketchnote,
  whiteboard) rendered via /render-infographic-handdrawn into an Excalidraw scene, or
  an editorial family (economist — The Economist data page style, plus editorial,
  data-viz, corporate) rendered via /render-infographic-editorial into a Pencil MCP
  .pen file. The unified /render-infographic command auto-routes based on the brief's
  style_preset. Important: this skill CREATES the brief from a narrative source — it
  does NOT render an existing brief (use /render-infographic to auto-route or one of
  the direct render commands for that), does NOT create slides (use story-to-slides),
  does NOT create a scrollable web page (use story-to-web), does NOT create a
  multi-poster storyboard (use story-to-storyboard), and does NOT enrich an existing
  report with inline visuals (use enrich-report).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent
version: 0.2.1
---

# Story-to-Infographic Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized infographic
brief that one of the two render agents can turn into a single-page visual summary. You are a
**visual distillation architect**: extract the 3-5 most impactful data points, select the right
layout type, compose content blocks with strict word limits, and generate icon prompts — all
driven by the principle that less is categorically better.

The brief routes to one of two rendering families, picked by `style_preset`:

| Family | Presets | Render agent | Output |
|--------|---------|-------------|--------|
| Hand-drawn (sketchnote) | `sketchnote` | `render-infographic-sketchnote` (opus) | `.excalidraw` scene |
| Hand-drawn (whiteboard) | `whiteboard` | `render-infographic-whiteboard` (opus) | `.excalidraw` scene |
| Editorial | `economist`, `editorial`, `data-viz`, `corporate` | `render-infographic-pencil` (opus) | `.pen` file |

The universal entry point is `/render-infographic`, which reads the brief's `style_preset` and
auto-routes. This skill only produces the brief — rendering is a separate, downstream step.

> **Concurrency constraint.** Both Excalidraw render agents share a single MCP canvas. Never
> dispatch two Excalidraw-based renders in parallel — they will draw over each other. If a
> downstream flow needs to render multiple sketchnote or whiteboard briefs, serialize them.
> Pencil agents use file-backed `.pen` documents and can run alongside an Excalidraw render
> safely (one Excalidraw + any number of Pencil renders is fine).

An infographic is a single-page visual medium — it conveys its governing message in 10 seconds
of scanning. Every element earns its place by being the most impactful representation of one
data point or concept. Text walls, hedging language, and decorative elements are failures.

The brief describes WHAT each block contains and which block types to use. All visual decisions
(colors, fonts, spacing, style) are delegated to the renderer via the theme and style preset.
Briefs contain no color fields.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | `smarter-service` | Theme ID from `/cogni-workspace/themes/{theme}/theme.md`. Use `auto` for interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` / `subtitle` | auto-detected | Extracted from narrative if not provided |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/infographic-brief.md` | Brief output location |
| `layout_type` | `auto` | Pre-selected layout. When `auto`, Step 4 auto-selects based on content. |
| `style_preset` | `auto` | Style preset: editorial, data-viz, sketchnote, corporate, whiteboard, economist. When `auto`, Step 4 selects. |
| `orientation` | `auto` | Page orientation (DIN A4 ratio). When `auto`: economist/funnel-pyramid default to portrait (1080x1528), others to landscape (1528x1080). |
| `conversion_goal` | `consultation` | CTA type: consultation, demo, download, trial, contact, calculate |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from cogni-narrative |
| `voice_tone` | auto-detected | Micro-copy register: `executive`, `analytical`, `punchy`, `playful`. Inherits from upstream narrative frontmatter if present; otherwise inferred in Step 2 from tone cues. Renderers use it to calibrate section subheads and CTA verbs — they never override brief text with it. |
| `palette_override` | `theme` | Either `theme` (default — renderers derive the Economist-discipline palette from the project theme) or `canonical` (force Economist's canonical red/amber/near-black/cream regardless of theme). Only meaningful for `style_preset: economist`. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion |
| `stakeholder_review` | `interactive` | When `true`, run brief-review-assessor after validation |
| `governing_thought` | auto-extracted | Pre-computed governing thought from caller |

---

## Conventions

### User Interaction

Interactive checkpoints use the structured AskUserQuestion format:

```
questions: [{
  question: "Your question here?",
  header: "Short Label",
  options: [
    { label: "Option Name", description: "What this means" },
    { label: "Another Option", description: "What this means" }
  ],
  multiSelect: false
}]
```

**On empty or blank responses, auto-select the best option and move on.** Never retry AskUserQuestion on empty responses. When `interactive` is `false`, skip all AskUserQuestion calls.

### Language & Formatting

German infographics are displayed to executives and shared externally. Use real Unicode
throughout: ae->ä oe->ö ue->ü ss->ß. German number formatting: 2.661 (not 2,661).
Always specify language explicitly in the brief frontmatter.

### No Color Fields

Briefs contain ZERO visual fields: no `Background:`, `Text-Color:`, `Icon-Color:`. The renderer reads the theme and style preset directly.

### Content Density by Style Preset

Content density varies by style preset. The "less is more" principle applies to all presets
but the threshold differs:

| Style Preset | Max Content Blocks | Max Word Count | Philosophy |
|-------------|-------------------|----------------|------------|
| sketchnote, whiteboard | 6-8 | 150 | Minimal — scan in 10 seconds |
| editorial, data-viz, corporate | 6-8 | 150 | Focused — scan in 10 seconds |
| **economist** | **10-14** | **250** | **Dense editorial — read in 60 seconds** |

The **economist** preset produces magazine-density content: prose text blocks sit alongside
stat callouts in a multi-column grid. Extract more data points from the narrative, include
short explanatory paragraphs (2-3 sentences), and fill a 2-3 column editorial layout.
Aim for 10-14 content blocks including 3-5 text-blocks with prose alongside the stats.

For all other presets, the original "less is more" principle applies: 3-8 content blocks,
max 150 words total, 10-second scan test.

---

## Workflow

> **CRITICAL:** When this skill loads without explicit parameter values, DO NOT ask the user for `source_path`, `theme`, `language`, or any other parameter. Execute Step 0 immediately — search the filesystem, present findings, then proceed.

### Step 0: Narrative Auto-Discovery (YOUR FIRST ACTION)

If `source_path` was explicitly provided: set `source_dir` to its parent directory and skip to Step 1.

Otherwise, search without asking:

1. **Primary:** Glob `**/insight-summary.md` from CWD (max 3 levels)
2. For each candidate: read first 30 lines, extract title, arc_id, estimate word count
3. **Secondary** (if 0 primary results): Glob `**/*.md`, filter for `arc_id:` in first 30 lines. Exclude SKILL.md, README.md, CLAUDE.md.
4. Sort: insight-summary.md files first, then by path depth (shallow first)

**If candidates found:** Present via AskUserQuestion (max 4 options with filename, title, arc_id, word count). On empty response, auto-select top candidate.

**If no candidates:** Ask for path or cancel. On empty response, stop with: "No narrative path provided. Stopping."

Set `source_dir` = parent directory of selected `source_path`.

---

### Step 1: Parse Parameters & Resolve Context

**Arc resolution** (priority order):
1. `arc_id` parameter → use directly
2. Source narrative frontmatter `arc_id` → extract
3. Neither → Step 2 auto-detects

If arc_id set: read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`, map to arc_type.

**Theme resolution:** If interactive and theme not explicitly set: invoke `cogni-workspace:pick-theme` via Skill tool. Otherwise use provided theme or default. Read theme.md, store absolute path.

**Load libraries:** `$CLAUDE_PLUGIN_ROOT/libraries/infographic-layouts.md`, `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_INFOGRAPHIC_BRIEF.md` (data-viz, stat-heavy), `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_SKETCHNOTE_BRIEF.md` (sketchnote, timeline-flow, hand-drawn family anchor), `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_ECONOMIST_BRIEF.md` (economist, stat-heavy, editorial family anchor), `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`.

---

### Step 2: Read Narrative & Extract Data Inventory

Read all source files. Build a **data inventory** — the raw material for distillation:

1. **Numbers**: Every statistic, percentage, currency value, count, date, duration. Record the number, its context sentence, and its source (if cited).
2. **Assertions**: Every claim that contains a verb and a consequence. These are headline candidates.
3. **Sequences**: Every process, timeline, or ordered list. These are process-strip candidates.
4. **Comparisons**: Every before/after, vs., or contrast pair. These are comparison-pair candidates.
5. **Concepts**: Key terms, frameworks, or models mentioned. These are icon-grid or hub-spoke candidates.

**Arc type resolution** (if not resolved in Step 1):
- Detect from narrative content using the same heuristics as other story-to-* skills
- Heavy on numbers → `why-change` or `report`
- Sequential/chronological → `journey`
- Before/after → `problem-solution`

Extract governing thought (single sentence that captures the core message).

**Voice-tone detection.** If `voice_tone` was not provided and upstream narrative frontmatter
does not carry it, infer one register from the source:

- `executive` — formal, hedged, board-safe. Typical of strategy memos and investor briefs.
- `analytical` — dry, measured, citation-heavy. Typical of research reports and trend analyses.
- `punchy` — active verbs, short sentences, high contrast. Typical of sales pitches and launch narratives.
- `playful` — warm, irreverent, conversational. Typical of workshop recaps and internal brainstorms.

Record the inferred tone verbatim in the brief frontmatter — renderers use it as a
micro-copy signal, nothing more.

**Pull-quote candidates.** Scan the source for direct quotations attributed to a named speaker
or for a single sentence so striking the brief should lift it verbatim. At most one survives to
the brief; if none qualifies, omit the `pull-quote` block entirely.

**Output:** Data inventory (numbers, assertions, sequences, comparisons, concepts, quotes) + governing thought + arc type + voice_tone.

---

### Step 3: Content Distillation

> This is the core differentiating step. The Substack methodology says: "AI generators must guess countless decisions — style, colors, text, icons, layout — simultaneously. This guessing produces generic results." The brief format constrains visual decisions; this step constrains content decisions.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/skills/story-to-infographic/references/01-content-distillation.md`

Apply the distillation rules to reduce the data inventory to infographic-ready content:

1. **Select governing assertion** → becomes the title headline
2. **Select 3-5 hero numbers** → the most impactful statistics (ratio-framed, hero-isolated)
3. **Select 1 process/sequence** (if present) → max 4-8 steps
4. **Select 1 comparison** (if present) → max 5 bullets per side
5. **Discard everything else** — the infographic carries only what survives distillation

**Output:** Distilled content set with tagged elements (hero_numbers, governing_assertion, process, comparison, supporting_stats).

---

### Step 4: Select Layout Type & Style Preset (INTERACTIVE)

**Read references:**
- `$CLAUDE_PLUGIN_ROOT/skills/story-to-infographic/references/02-infographic-mapping.md`
- `$CLAUDE_PLUGIN_ROOT/skills/story-to-infographic/references/03-style-presets.md`

**Layout type selection** (if `layout_type` is `auto`):
Map the distilled content to the best layout type. The mapping rules in the reference file
match content patterns to layout types — e.g., 3+ hero numbers → stat-heavy, clear process
sequence → timeline-flow, before/after comparison → comparison.

**Style preset selection — two-step disclosure** (if `style_preset` is `auto`):

People think about infographic style in two steps, not six. The first cognitive split is
**hand-drawn feel vs editorial feel** — that single choice determines the rendering family
and eliminates four of the six presets. The second step narrows to a preset inside the
chosen family. Presenting all six at once asks the user to hold too much in their head.

**Step 4a — Family choice.** Infer the likely family from source cues (workshop recap or
learning content → hand-drawn; trend report, investor brief, or board deck → editorial)
and present via AskUserQuestion:

- **Hand-drawn (sketchnote / whiteboard)** — Mike Rohde sketchnote and RSA Animate
  whiteboard traditions. Warm, human, feels like a facilitator drew it at a conference.
  Best for workshops, team alignment, learning material, internal brainstorms.
- **Editorial (economist / editorial / data-viz / corporate)** — The Economist data page
  and data journalism tradition. Dense, disciplined, data-ink honest. Best for trend
  reports, investor briefs, board decks, flagship insights.

On empty response, auto-select the inferred family.

**Step 4b — Preset narrowing inside the chosen family.** Only present the 2–3 presets that
belong to the chosen family, with recommendations grounded in source cues:

- **Hand-drawn family** → pick between `sketchnote` (warm, organic, dashed borders, accent
  color on several marks) and `whiteboard` (disciplined minimalism, solid borders, accent
  color only on hero numbers and CTA).
- **Editorial family** → pick among `economist` (flagship dense 10–14 blocks, 250-word),
  `editorial` (HBR/McKinsey 6–8 blocks, generous whitespace), `data-viz` (Bloomberg Terminal
  dashboard feel, monospace numbers), `corporate` (annual report / governance, structured
  grid, serif-friendly).

Present via AskUserQuestion with 2–3 options. On empty response, auto-select top
recommendation.

**Output:** Selected layout_type + style_preset.

---

### Step 5: Compose Block Architecture

**Read references:**
- `$CLAUDE_PLUGIN_ROOT/skills/story-to-infographic/references/04-block-copywriting.md`
- `$CLAUDE_PLUGIN_ROOT/libraries/infographic-layouts.md` (block type schemas)

Map distilled content to block types following the selected layout's composition rules:

1. **Title block** — governing assertion as headline (max 12 words), supporting context as subline
2. **Content blocks** — map hero numbers to kpi-cards, sequences to process-strips, comparisons to comparison-pairs, charts to chart blocks, concepts to icon-grids or svg-diagrams
3. **CTA block** — from `conversion_goal` + governing thought
4. **Footer block** — customer, provider, date, sources

Apply block copywriting rules:
- **Assertion headlines**: every headline contains a verb + consequence
- **Number plays**: hero number isolation, ratio framing, before/after contrast
- **Icon over text**: where a concept can be an icon + 2-3 word label, prefer that over prose
- **Word limits**: strict per block type (see infographic-layouts.md)
- **No maps, use flags**: geographic references use flag icons per article guidance

**Self-check:** Count content blocks (max 8 excluding title/CTA/footer). If over 8, merge or cut the weakest blocks.

**Output:** Ordered list of block specifications with all content fields filled.

---

### Step 6: Generate YAML Block Specifications

For each block, generate the content YAML following the block type schemas from
`infographic-layouts.md`. No color fields, no visual fields.

Write icon prompts for concept-diagram-svg agent: descriptive, specific, focused on the
concept (e.g., "shield with downward arrow, security improvement" not "a pretty icon").

---

### Step 7: Propose CTA

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

Generate the CTA block:
1. Extract implicit CTA from governing thought and arc type
2. Match to `conversion_goal` parameter
3. Generate CTA headline (max 8 words, imperative verb) and CTA text (max 4 words)
4. Assign CTA type and urgency from cta-taxonomy.md

If interactive: present CTA proposal via AskUserQuestion (Approve/Adjust). On empty response, treat as approval.

---

### Step 8: Validate

**Read reference:** `$CLAUDE_PLUGIN_ROOT/skills/story-to-infographic/references/05-validation-checklist.md`

Four layers — stop on first failure, fix, re-check:

1. **Schema** — block types valid, required fields present, valid YAML, no color fields
2. **Content density** — max 8 content blocks, word counts within limits per block type, total word count under 150
3. **Data integrity** — numbers match source narrative, chart data valid, no fabricated statistics
4. **Distillation quality** — title is assertion (not topic label), hero numbers isolated, icon prompts specific, 10-second scan test passes

---

### Step 8b: Stakeholder Review (when `stakeholder_review=true`)

**Skip this step** if `stakeholder_review=false`.

Launch the `brief-review-assessor` agent with:
- `brief_type`: `infographic`
- Brief content (write to a `.draft` temp file if the brief hasn't been written yet)
- `source_narrative`: the narrative path from Step 0
- `round`: 1

**On accept (all perspectives >=85):** Proceed to Step 9.

**On revise:**
1. Apply CRITICAL improvements first, then HIGH improvements
2. Re-run Step 8 validation
3. Re-launch the assessor (round 2)
4. If round 2 accepts or scores 70+ with no CRITICAL issues: proceed to Step 9

**On reject:** Surface the verdict to the user via AskUserQuestion.

Write the review verdict to `{output_dir}/infographic-brief.review.json`.

---

### Step 9: Write infographic-brief.md

**Output path resolution** (run via Bash before writing):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/infographic-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

Generate the final brief with YAML frontmatter and block specifications following
`EXAMPLE_INFOGRAPHIC_BRIEF.md` format. Write using Write tool.

**Frontmatter fields:**
```yaml
type: infographic-brief
version: "1.1"
theme: {theme_id}
theme_path: "{absolute_theme_path}"
customer: "{customer_name}"
provider: "{provider_name}"
language: "{language}"
generated: "{YYYY-MM-DD}"
layout_type: "{layout_type}"
style_preset: "{style_preset}"
orientation: "{orientation}"
dimensions: "{dimensions}"
arc_type: "{arc_type}"
arc_id: "{arc_id}"
governing_thought: "{governing_thought}"
voice_tone: "{executive|analytical|punchy|playful}"   # v1.1 — micro-copy register
palette_override: "{theme|canonical}"                 # v1.1 — economist palette source
confidence_score: {0.0-1.0}
transformation_notes: |
  Story-to-infographic transformation.
  Theme: {theme}. Style: {style_preset}. Layout: {layout_type}. Voice: {voice_tone}.
  {blocks_content} content blocks, {number_plays} number plays, {icon_count} icons.
```

**Final checks:**
- YAML frontmatter complete (all fields above)
- Each block has Block-Type and all required fields per infographic-layouts.md
- Title block headline is an assertion (verb + consequence)
- Total content blocks <= 8 (excluding title, CTA, footer)
- Word count per block within limits
- Zero color fields in entire document
- Generation metadata block at end

---

### Step 10: Guide to Rendering

Tell the user the brief is ready. The universal entry point is `/render-infographic`, which
auto-routes to the right rendering family based on the brief's `style_preset`. Power users
who want to skip the dispatch step can call the direct commands.

| Style Preset | Family | Output | Universal | Direct |
|--------------|--------|--------|-----------|--------|
| `sketchnote`, `whiteboard` | Hand-drawn (Mike Rohde / RSA Animate) | `.excalidraw` scene | `/render-infographic` | `/render-infographic-handdrawn` |
| `economist` | Editorial (The Economist data page — flagship) | `.pen` file | `/render-infographic` | `/render-infographic-editorial` |
| `editorial`, `data-viz`, `corporate` | Editorial (data journalism tradition) | `.pen` file | `/render-infographic` | `/render-infographic-editorial` |

Example message (sketchnote/whiteboard):

> "Infographic brief written to `{output_path}`.
> Style preset: **{style_preset}** (hand-drawn family) — run **`/render-infographic`** to
> render. After the render completes, the scene is live in your Excalidraw browser and
> you can tweak anything on the canvas; just tell me **`save`** when you're done and I'll
> re-export the final version to disk."

Example message (economist):

> "Infographic brief written to `{output_path}`.
> Style preset: **economist** (The Economist data page) — run **`/render-infographic`** to
> render. After the render completes, the scene is live in your Pencil browser and you can
> tweak any frame; tell me **`save`** when you're done and I'll refresh the PNG preview."

Example message (editorial/data-viz/corporate):

> "Infographic brief written to `{output_path}`.
> Style preset: **{style_preset}** (editorial family) — run **`/render-infographic`** to
> render. After the render completes, the scene is live in your Pencil browser and you can
> tweak any frame; tell me **`save`** when you're done and I'll refresh the PNG preview."

Report: layout type, style preset, orientation, block count, total word count, distillation ratio (source words → brief words).

**Post-render edit checkpoint** (reminder for the user and for future maintainers of this
skill): the render commands (`/render-infographic`, `/render-infographic-handdrawn`,
`/render-infographic-editorial`) all include an interactive edit checkpoint as their final
step. After the agent finishes drawing, the command prints a prompt telling the user they
can edit the live canvas in the browser and say `save` to re-export the final state. This
is the mechanism that lets a user's manual touch-ups (move a zone, fix a typo, swap an
icon, adjust an accent mark) become the persisted result. The checkpoint is load-bearing
— without it, manual edits in the browser would be silently lost the next time the
pipeline runs. Do not remove it from the render commands when editing them in the future;
if you restructure the commands, preserve the post-render `save` affordance.

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **01-content-distillation.md** | 3 | "Less is more" rules, 10-second test, number selection, icon-over-text |
| **02-infographic-mapping.md** | 4 | Layout type selection heuristics, content pattern → layout mapping |
| **03-style-presets.md** | 4 | 5 style presets with character descriptions and selection heuristics |
| **04-block-copywriting.md** | 5 | Per-block-type copy rules, assertion headlines, number plays, icon prompts |
| **05-validation-checklist.md** | 8 | 4-layer validation framework (schema, density, integrity, distillation) |

### Libraries (loaded in Step 1)

| Library | Purpose |
|---------|---------|
| **infographic-layouts.md** | Layout type schemas, block type catalog with field schemas and word limits (schema v1.1) |
| **EXAMPLE_INFOGRAPHIC_BRIEF.md** | Reference output — stat-heavy layout, data-viz style |
| **EXAMPLE_SKETCHNOTE_BRIEF.md** | Reference output — timeline-flow layout, sketchnote style (hand-drawn family anchor, Mike Rohde tradition) |
| **EXAMPLE_ECONOMIST_BRIEF.md** | Reference output — stat-heavy layout, economist style (editorial family anchor, The Economist data page tradition, dense 10-14 blocks) |
| **cta-taxonomy.md** | CTA types, urgency levels, arc-to-CTA heuristics |
| **arc-taxonomy.md** | Arc ID → arc type mapping (loaded only if arc_id set) |
