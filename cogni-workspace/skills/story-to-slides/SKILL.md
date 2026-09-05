---
name: story-to-slides
description: >
  Transform any narrative into an optimized multi-slide presentation brief that a slide
  renderer turns into a deck. Use this skill whenever the user mentions "presentation",
  "slide deck", "slides", "PowerPoint", "Foliensatz", "Praesentation erstellen",
  "Folien aus Bericht", "pitch deck", "create slides from report", "presentation outline",
  or wants to convert prose into slide-level message architecture. Also trigger when the
  user needs pyramid communication, number plays, assertion headlines, or speaker notes.
  Covers Why Change projects, research reports and trend panoramas, in English and
  German. Produces a presentation-brief.md (v4.1) under a
  renderer-neutral Rendering Contract, plus a presentation-outline.md render handoff for
  claude.ai/design. Important: this skill CREATES the brief from a narrative source —
  it does NOT render an existing brief (use PPTX skill for that), does NOT create a web page
  (use story-to-web), and does NOT enhance prose (use cogni-workspace:copywriter).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent, Skill
---

# Story-to-Slides Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized presentation brief that a slide renderer turns into slides. You are a **presentation strategist**: analyze the narrative's argument structure, distill it into slide-level messages using pyramid communication, apply copywriting techniques, and select the right visual layout for each message.

A great presentation brief is not a transcript of the narrative. It is a re-architecture of the narrative's argument into a visual medium where every slide has ONE clear message, supported by evidence the audience can absorb in 3 seconds. Slides that try to convey multiple messages become walls of text that audiences tune out — the presenter loses control of the room.

## Architecture

Two-layer intelligence:
1. **Story Arc Analysis** — read narrative, identify argument structure, extract governing thought, map section roles
2. **Message Architecture + Slide Specification** — pyramid communication, one message per slide, copywriting, layout selection, speaker notes

The brief describes WHAT each slide says and which layout to use. The renderer owns all visual decisions (colors, fonts, spacing) by reading the theme directly — briefs contain no color fields.

**Density principle:** Slides carry the anchor; speaker notes carry the detail. A McKinsey partner's slide has one assertion headline and 3-5 scannable phrases — the partner delivers the depth from memory. Same principle here: when content exceeds a layout's physical capacity, the excess moves to speaker notes. Never force-fit paragraphs on-slide.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | interactive | Absolute path to theme.md, or omit to trigger `cogni-workspace:pick-theme` interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` / `subtitle` | auto-detected | Extracted from narrative if not provided |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/presentation-brief.md` | Brief output location |
| `max_slides` | `15` | Maximum slide count (forces consolidation if narrative is long) |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from the `narrative` skill (e.g., `industry-transformation`). Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become methodology slide phase labels. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `stakeholder_review` | `interactive` | When `true`, run brief-review-assessor after validation. Defaults to value of `interactive`. |
| `audience_context` | none | Structured audience/buyer data for targeted evidence selection and Q&A prep (Rich mode). |

### Caller-supplied overrides

These are typically set by an upstream agent (e.g., why-change-work), not by a human user:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `confidence_threshold` | `0.8` | Minimum confidence for automatic layout mapping |
| `governing_thought` | auto-extracted | Pre-computed governing thought — Step 4 validates rather than re-derives. |
| `section_roles` | auto-detected | Pre-mapped section roles — Step 4 validates rather than re-derives. |
| `buyer_appendix_path` | none | Path to buyer-appendix.md for enriched Q&A prep (Step 8.2 only). |
| `design` | per `$CLAUDE_PLUGIN_ROOT/libraries/presentation-intent.md` | The deck's design intent — `register`, `dark_slides`, `speaker_notes`, `imagery`, `variations`. Unsupplied sub-keys fall back to that library's defaults (Step 8.2). |

---

## Conventions

### Theme-driven visuals

The renderer owns all visual decisions — colors, fonts, spacing — by reading the theme directly. Briefs specify content and layout only. Omit color/styling fields (`Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:`, `Mood:`) because the renderer ignores them and their presence creates ambiguity about who controls styling. The nested `intent.role` key is a different, permitted 4.1 key and is not covered by this prohibition.

### Interactive checkpoints

Interactive prompts let the user steer creative decisions at two points: narrative selection (Step 0) and theme selection (Step 1). Use the structured format below — unstructured prose renders as empty prompts:

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

On empty or blank responses, auto-select the best option and move on. When `interactive` is `false`, skip all AskUserQuestion calls.

### German fidelity

German presentations go to executives. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout the generated copy: ae→ä oe→ö ue→ü ss→ß. German number formatting: 2.661 (dot as thousands separator).

This rule governs generated output copy only — headlines, body text, section labels, and CTA text. It does not govern filenames, slugs, or other machine identifiers, which transliterate umlauts deliberately. It also does not govern the trigger phrases in this skill's frontmatter description, where any ASCII spellings are deliberate: a user on a non-German keyboard types them that way, so respelling one silently drops German triggering coverage. Leave the frontmatter block unchanged when correcting umlauts anywhere else in this file.

### Client-facing copy hygiene

Presentation briefs are client-facing deliverables. Strip all internal sales methodology vocabulary from slide titles, headlines, and body copy:

- **Never expose:** "Power Position", "Why Change", "Why Now", "Why You", "Why Pay", "Unconsidered Need", "Buying Center" in any client-visible field (Slide-Title, headlines, bullets, Bottom-Banner)
- **Transform to:** customer-benefit language that asserts a specific capability the customer cares about.
  - Bad: `"Why You — Power Position 2 & 3: Compliance & Sovereign Cloud"`
  - Good: `"Warum T-Systems — Compliance-native Architektur eliminiert 90% der Audit-Findings"`
- **One Power Position = one slide.** Never combine multiple Power Positions into a single slide title or body. Each gets its own slide with its own assertion headline.
- **Internal-only slides** (Methodology, Buying Center) are exempt — they carry the INTERNAL warning banner.

### IS/DOES/MEANS label localization

The `is-does-means` layout uses layer labels rendered as badges on each box. These labels must match the presentation language:

| Language | IS label | DOES label | MEANS label |
|----------|----------|------------|-------------|
| `en` | IS | DOES | MEANS |
| `de` | IST | MACHT | BEDEUTET |

Apply the localized labels in every `IS-Box.Label`, `DOES-Box.Label`, `MEANS-Box.Label` field. English labels in a German presentation signal "template not adapted" and undermine credibility.

---

## Quick Reference: Good vs Bad Output

**Headlines** — assert, don't label:
- Bad: "Market Overview" (topic label — audience must read the body to get the point)
- Good: "European Rail Market Contracts 12% as Regulation Tightens" (assertion — message lands in 3 seconds)

**Number plays** — reframe for impact:
- Bad: "There were 688 rail suicides in 2023" (buried in prose)
- Good: Hero number `688` isolated in stat-card, sublabel `+ 2,661 station attacks`, context box explains why manual monitoring fails

**Bullets** — scan-optimized, not sentences:
- Bad: "The security staff are unable to adequately cover all areas of the rail network on a 24/7 basis" (19 words)
- Good: "Staff cannot cover all areas 24/7" (6 words — scannable in ~3 seconds at presentation distance, ~8-10 words max)

---

## Slide Structure

| Position | Layout | Role |
|----------|--------|------|
| **First** | `title-slide` | Opening with title, subtitle, metadata |
| **After title** | 1-2 internal prep slides | Methodology (always) + Buying Center (Rich mode only) |
| **Body** | Content slides | One message per slide |
| **Second-to-last** | `closing-slide` | CTA headline, key takeaway |
| **Last** | References slide | Consolidated citations |

Internal prep slides carry `Bottom-Banner` with "INTERNAL — REMOVE FROM CLIENT PRESENTATION" and are not counted against `max_slides`.

---

## Workflow

When invoked without explicit parameters, search the filesystem first (Step 0) rather than prompting for paths.

### Execution protocol

Each step: verify the previous step's output is available (entry gate), read the reference file for that step, execute, then state the output summary before moving on. Reference files contain step-specific rules that prevent downstream rework — read them at the start of each step.

---

### Step 0: Narrative Auto-Discovery

> Users invoke from project directories containing their narrative. Searching first eliminates path-fumbling.

If `source_path` was explicitly provided: set `source_dir` to its parent directory and proceed to Step 1.

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

> Arc resolution and theme loading happen before reading the narrative because they shape how you interpret the story — a pre-resolved arc_type tells you what argument pattern to look for.

Determine input type (directory with metadata vs single file) and load metadata.

**Arc resolution** (priority order):
1. `arc_id` parameter → use directly
2. Source narrative frontmatter `arc_id` → extract
3. Neither → Step 4 auto-detects

If arc_id set: read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`, map to arc_type. If `arc_definition_path` provided: extract element names for methodology slide.

**Theme resolution:** Delegate to `cogni-workspace:pick-theme` — the ecosystem-standard theme picker.

1. If `theme` parameter was explicitly provided with an absolute path: use it directly, skip the picker.
2. Otherwise: invoke the `cogni-workspace:pick-theme` skill via the Skill tool. The picker scans standard and workspace theme directories, presents an interactive AskUserQuestion, and returns the absolute `theme_path`.
3. Store the returned `theme_path` (absolute path to `theme.md`), `theme_name`, and `theme_slug` for downstream use.
4. Read the selected `theme.md` to confirm it loads correctly.

If pick-theme is unavailable (e.g., cogni-workspace not installed), fall back to Glob scanning `$COGNI_WORKSPACE_ROOT/themes/*/theme.md` and present via AskUserQuestion manually.

**Load libraries:** `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set). The heavier libraries (`pptx-layouts.md` and `EXAMPLE_BRIEF.md`) are deferred to the steps that consume them (Steps 7 and 8), and `presentation-intent.md` is deferred to Step 8.2, to keep context lean during the creative intelligence steps.

---

### Step 2: Read Narrative Content

> Citation renumbering feeds 6 downstream steps — errors here propagate everywhere.

Read all source files, preserve section boundaries (H1/H2/H3), extract citation URL map, assign sequential citation numbers. Store renumber map for Steps 6, 8.1, 10.

**Citation rules:** See `references/07-output-template.md` (Citation Handling Rules section) for preservation rules, exclusion zones, and Source field generation priority.

#### Step 2.1: Diagram Detection

Read `references/2g-diagram-simplification.md`. Scan for Mermaid fenced blocks, classify type (gantt/layered-architecture/process-flow), check complexity against layout constraints, simplify if needed. IS-DOES-MEANS slides are not affected by diagram detection.

---

### Step 3: Build Audience Model

> The audience model shapes how downstream steps select evidence, frame the governing thought, and prepare Q&A — Rich mode enables targeted speaker notes, Lean mode infers from narrative vocabulary.

**Read reference:** `references/02-audience-model.md`

Build Audience Model: Rich mode (from `audience_context` or pitch-log.json) or Lean mode (inferred from narrative). Identify primary decision-maker, priorities, objections.

**Content checkpoint:** State mode, confidence, decision-maker, top priority, top objection.

---

### Step 4: Analyze Story Arc

> The governing thought and arc type cascade through everything downstream — message architecture, consolidation, layout selection, and speaker notes coaching. Getting them right here prevents rework in later steps.

**Read reference:** `references/03-story-arc-analysis.md`

- **4a. Detect arc type** — why-change, problem-solution, journey, argument, or report
- **4b. Extract governing thought** — single sentence, audience-weighted
- **4c. Map section roles** — hook, problem, urgency, evidence, solution, proof, options, roadmap, investment, call-to-action

When caller provides `governing_thought`/`section_roles`: validate against narrative rather than re-deriving. When `arc_context` populated from Step 1: use resolved arc_type directly.

**Content checkpoint:** State arc type, governing thought, sections mapped count.

---

### Step 5: Architect Slide Messages

> Pyramid communication separates a professional deck from a content dump. Without one-message-per-slide discipline, the natural tendency is to pack 3-4 points per slide — and the audience remembers none of them.

**Read reference:** `references/04-message-architecture.md`

- **5a. Pyramid Principle** — governing thought → arguments → evidence
- **5b. One message per slide** — each slide gets exactly ONE message sentence
- **5c. Consolidation** — merge/cut when narrative exceeds `max_slides`. Rich mode protects slides aligned with decision-maker priorities.
- **5d. MECE check** — mutually exclusive, collectively exhaustive, logically ordered

**Content checkpoint:** State slide count, argument count, consolidation status.

---

### Step 6: Apply Copywriting Techniques

> Headlines are the first thing an audience reads. A topic label ("Market Overview") tells them nothing — they have to read the body to get the point, and their attention is gone. An assertion headline ("European market contracts 12% as regulation tightens") delivers the message in 3 seconds.

**Read reference:** `references/05a-slide-copywriting.md`

- **6a. Headline optimization** — every title is a complete action assertion (up to ~100 chars, contains verb + quantified consequence)
- **6b. Number plays** — ratio framing, hero number isolation, before/after contrast
- **6c. Bullet consolidation** — 8-12 points → 3-5 scannable bullets (max 10 words each)
- **6d. Evidence selection** — top 3-5 per slide, audience-weighted, inline citations preserved

Speaker-Notes are generated later in Step 8.2 (after layouts finalize). This step focuses on slide copy only.

---

#### Step 6.1: Propose CTAs

> Without explicit CTAs, the audience leaves impressed but without a next step. CTAs convert attention into action.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

1. Extract implicit CTAs from narrative + generate from governing thought, arc type, hero numbers
2. Per content slide: assign `cta.text` (max 50 chars, imperative verb), `cta.type` (explore/evaluate/commit/share), `cta.urgency`
3. Build `cta_summary`: 3-5 proposals, `primary_cta` = highest-urgency commit CTA

If interactive: present CTA plan via AskUserQuestion (Approve/Adjust). On empty response, treat as approval.

---

### Step 7: Select Layouts

> Layout selection translates message type into visual structure. A hero number on a `two-columns-equal` wastes its impact — `stat-card-with-context` isolates the number and makes it the focal point.

**Read library:** `$CLAUDE_PLUGIN_ROOT/libraries/pptx-layouts.md` — slide layout schemas needed for layout selection (this step) and YAML field names (Step 8). Deferred from Step 1 to keep context lean during creative Steps 2-6.

**Read reference:** `references/06-slide-mapping-rules.md`

Map each slide to best layout from `pptx-layouts.md`. Mandatory rules apply first (title-slide, closing-slide), then diagram rules (Mermaid blocks), then content pattern matching. Ensure layout variety and confidence >= threshold.

---

### Step 7.5: Density Pass — Compress to Layout Limits

> Steps 5-6 optimized for message clarity. Now that layouts are assigned, compress each slide's copy to fit its layout's physical box dimensions. Speaker notes absorb the overflow. Think of this step as the difference between a draft memo and a billboard campaign — same message, radically different word budget.

Apply the layout density budget. These are ceilings the layout enforces physically — exceeding one overflows the box or shrinks the font to illegibility — not stylistic targets:

| Layout | Field | Max Words | Think of it as... |
|--------|-------|-----------|-------------------|
| is-does-means | IS-Box | 15 | Conference badge tagline |
| is-does-means | DOES-Box | 20 | McKinsey "so what" bullet |
| is-does-means | MEANS-Box | 15 | Résumé skills line |
| stat-card | Context-Box Bullets (each) | 10 | Dashboard KPI label |
| four-quadrants | Bullets (each) | 10 | McKinsey slide bullet |
| two-columns-equal | Bullets (each) | 10 | McKinsey slide bullet |
| ALL | Bottom-Banner | 12 | Billboard tagline |

Content exceeding the budget moves to speaker notes (Step 8.2 incorporates it) — preserved, not deleted. This works because the audience scans each slide in ~3 seconds before the presenter speaks: a 40-word IS-box becomes a reading competition where they read instead of listen and the presenter loses the room, while a 15-word phrase lets them absorb the anchor and look up, ready for the elaboration.

Content checkpoint: State slides compressed count, total words moved to notes.

---

### Step 8: Generate YAML Slide Specifications

> The YAML specification is the contract between this skill and the renderer. Every field must contain final, copy-paste-ready text because the renderer reproduces it exactly — no interpretation, no cleanup.

**Read library:** `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_BRIEF.md` — output format reference needed for YAML spec generation and final brief output (Step 10). Deferred from Step 1 to keep context lean during creative Steps 2-6.

**Read reference:** `references/07-output-template.md` (Per-slide YAML pattern section)

For each slide, generate content-only YAML following `pptx-layouts.md` field names. Omit all color/styling fields — the renderer reads the theme. Every slide heading is an assertion headline.

Every slide also carries the three per-slide keys 4.1 requires: `Slide-Kind`, `intent` (with `role` and `emphasis`) and `visual` (with `kind`). Read `references/07-output-template.md` for their value sets — `pptx-layouts.md` defines layout fields only and does not define these three.

**Density enforcement:** carry the Step 7.5 budget into the YAML unchanged — that table is the authority on every per-field word count. Phrase notation throughout: no full sentences in any box or bullet field.

---

#### Step 8.1: Generate References Slide

> A consolidated references slide with working links gives the presentation credibility and lets readers verify claims independently.

**Read reference:** `references/08b-references-slide.md`

Generate from citation renumber map (Step 2). Position after closing-slide as last slide in deck.

---

#### Step 8.2: Enrich and Write Complete Brief (Delegated)

> Speaker notes transform a deck from a document into a performance tool. Prep slides give the presenter strategic context before entering the room. The `slides-enrichment-artist` agent loads its own heavy references in a separate context, generates prep slides and speaker notes, and **writes the complete presentation-brief.md directly** — eliminating the token-heavy JSON round-trip and the integration step that can stall the orchestrator.

**Deriving the `design:` values.** `register`, `dark_slides`, `speaker_notes`,
`imagery` and `variations` come from the `design` caller-supplied override when it
is passed, and otherwise from the defaults defined in
`$CLAUDE_PLUGIN_ROOT/libraries/presentation-intent.md`. Resolve them here before
interpolating the prompt — the values below are never invented at write time.

**Read library:** `$CLAUDE_PLUGIN_ROOT/libraries/presentation-intent.md` — the
design defaults the `design:` block below falls back to.

**Prepare the enrichment prompt** with these fields from previous steps. Emit the
FRONTMATTER payload per the conditionality in `references/07-output-template.md` →
Frontmatter — omit `arc_id` when unresolved, and `climax` when no slide carries
`emphasis: climax`:

| Field | Source |
|-------|--------|
| `OUTPUT_PATH` | Resolved output path (from parameters or default `{source_dir}/cogni-visual/presentation-brief.md`) |
| `OUTPUT_TEMPLATE_PATH` | `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/07-output-template.md` |
| `FRONTMATTER` | All YAML frontmatter fields **as defined in `references/07-output-template.md` → Frontmatter**, which is the canonical key set and the authority on which keys are required, conditional or optional. Interpolated in the block below. |
| `TITLE` / `SUBTITLE` | From Step 2 or parameters |
| `SLIDE_SPECS` | All slide YAML specs from Steps 8 + 8.1 (the complete deck so far) |
| `AUDIENCE_MODEL` | From Step 3 — mode (Rich/Lean), decision-maker, priorities, objections, champion, blockers |
| `ARC_ANALYSIS` | From Step 4 — arc_type, governing_thought, section_roles, arc phases |
| `LANGUAGE` | `en` or `de` |
| `ARC_ID` | If set |
| `ARC_DEFINITION_PATH` | If set (element names for methodology slide phase labels) |
| `BUYER_APPENDIX_PATH` | If set (enriched Q&A prep) |
| `CTA_SUMMARY` | From Step 6.1 (or "none") |
| `GENERATION_METADATA_STATS` | Raw stats: number_plays, headlines_optimized, bullets_consolidated, source_links, layout_distribution, avg_confidence, manual_review |

**Resolve output path** before launching (run via Bash):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/presentation-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

The `FRONTMATTER:` block in the prompt below is a deliberate interpolation payload — it supplies values for the keys, not a second definition of the key set; `references/07-output-template.md` → Frontmatter remains the authority, so re-derive this payload from it whenever the Frontmatter key set or any of its value annotations change.

**Launch the `slides-enrichment-artist` agent:**

```
Agent tool:
  subagent_type: "cogni-workspace:slides-enrichment-artist"
  prompt: |
    OUTPUT_PATH: {resolved_output_path}
    OUTPUT_TEMPLATE_PATH: $CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/07-output-template.md

    FRONTMATTER:
      type: presentation-brief
      version: "4.1"
      theme: {theme_id}
      theme_path: "{theme_path}"
      customer: "{customer_name}"
      provider: "{provider_name}"
      language: "{language}"
      generated: "{date}"
      arc_type: "{arc_type}"
      arc_id: "{arc_id}"
      governing_thought: "{governing_thought}"
      confidence_score: {avg_confidence}
      max_slides: {max_slides}
      slides: {slides_total}
      climax: {climax_slide}
      design:
        register: {register}
        dark_slides: {dark_slides}
        speaker_notes: {speaker_notes}
        imagery: {imagery}
        variations: {variations}
      key_figures:
        - "{hero number promoted out of prose, provenance marker kept if it carries one}"
      transformation_notes: |
        Story-to-slides transformation.
        Theme: {theme_id}. Arc: {arc_type}.
        {N} slides, {avg}% avg confidence.
        {number_plays} number plays, {headlines_optimized} headlines optimized.

    TITLE: {title}
    SUBTITLE: {subtitle}

    SLIDE_SPECS:
    {all slide YAML from Steps 8 + 8.1}

    AUDIENCE_MODEL:
    {audience model from Step 3}

    ARC_ANALYSIS:
    {arc analysis from Step 4}

    LANGUAGE: {language}
    ARC_ID: {arc_id or "none"}
    ARC_DEFINITION_PATH: {path or "none"}
    BUYER_APPENDIX_PATH: {path or "none"}

    CTA_SUMMARY:
    {cta_summary from Step 6.1 or "none"}

    GENERATION_METADATA_STATS:
      number_plays: {count}
      headlines_optimized: {count}
      bullets_consolidated: {count}
      source_links: {count}
      layout_distribution: "{layout_type: count, ...}"
      avg_confidence: {score}
      manual_review: [{slide list or "none"}]
```

**On success** (`ok: true`): The agent wrote the complete brief to `output_path`. Read back the first 30 lines to confirm the file exists and has correct frontmatter. **Skip Step 10** — the brief is already written. Proceed directly to Step 9 (validation).

**On failure** (`ok: false`): Log the error. Fall back to inline execution: read `references/08c-presenter-prep.md` and `references/05b-speaker-notes.md`, generate prep slides and speaker notes inline, insert prep slides after Slide 1, renumber, append speaker notes. Then proceed to Step 10 to write the brief.

---

### Step 9: Validate Against Schema

> Self-assessment is unreliable without explicit measurement — in early tests, models reported "pass" while producing topic-label headlines and missing citations. The five-layer gate forces honest evaluation.

**Read reference:** `references/09-validation-checklist.md`

Five layers — stop on first failure, fix, re-check:
1. **Schema** — layout types exist, required fields present, no color/styling fields, valid YAML
2. **Message quality** — assertion headlines, MECE sequence, isolated hero numbers
3. **Copywriting** — number plays applied, bullets consolidated, no hedging
4. **Presentation logic** — bookend slides enforced, within max_slides, layout variety
5. **Content integrity** — all sections represented, citations preserved, German characters correct

---

### Step 9b: Stakeholder Review (when `stakeholder_review=true`)

> Structural validation (Step 9) catches schema and formatting issues, but cannot tell whether the brief will actually work for the audience, the presenter, or as a visual communication. The brief-review-assessor evaluates from three stakeholder perspectives — catching weak headlines that pass schema checks, layout monotony that passes variety rules, and CTA gaps that pass structural validation. Reviewing at the brief stage is efficient because changes are text edits, not re-renders.

**Skip this step** if `stakeholder_review=false`.

Launch the `brief-review-assessor` agent with:
- `brief_type`: `slides`
- Brief content at `output_path` (the file was written by the enrichment agent in Step 8.2, or will be written in Step 10 on the fallback path)
- `source_narrative`: the narrative path from Step 0
- `audience_context`: if provided
- `round`: 1

**On accept (all perspectives ≥85):** Proceed to Step 10 (or Step 11 if brief already written).

**On revise:**
1. Apply CRITICAL improvements first, then HIGH improvements — edit the brief content surgically (change specific headlines, layout types, speaker notes, CTAs as recommended)
2. Re-run Step 9 validation to ensure structural integrity after edits
3. Re-launch the assessor (round 2)
4. If round 2 accepts or scores 70+ with no CRITICAL issues: proceed to Step 10
5. If round 2 still has issues: present remaining issues to user, proceed to Step 10

**On reject:** Surface the verdict to the user via AskUserQuestion and let them decide whether to proceed, edit manually, or abandon.

Write the review verdict to `{output_dir}/presentation-brief.review.json`.

---

### Step 10: Write Presentation Brief (fallback path only)

> If Step 8.2 succeeded (`ok: true`), the enrichment agent already wrote the complete brief. **Skip this step** and proceed to Step 11. This step only executes on the fallback path (agent failure → inline enrichment).

**Read reference:** `references/07-output-template.md` (Brief Output Template section)

**Output path:** reuse the value Step 8.2 resolved before the agent launch — this step runs only on the 8.2 fallback path, so the path is already set and its parent directory already `mkdir -p`ed. If it is somehow unset, resolve it by the same rule Step 8.2 states.

Write the brief following the output template. Take the YAML frontmatter key set — and which keys are required, conditionally required or optional pass-through — from `references/07-output-template.md` → Frontmatter, which is the authority; do not re-derive it here. Include the Rendering Contract section (localized). Include the fenced Generation Metadata block at end.

Run the validation checklist (reference `09-validation-checklist.md`) one final time against the written file. The most commonly missed items at this stage: a mispositioned Rendering Contract section, and superscript `<sup>[N](url)</sup>` in body text vs plain `[N](url)` in speaker notes.

---

### Step 11: Guide User to PPTX Rendering

> The presentation brief is ready. Produce both render handoffs — **PPTX** via claude.ai chat with the Anthropic PPTX skill, and an **outline** for Claude Design. Neither handoff asks the user anything, so `interactive=false` changes nothing in this step; the `narrative-publish` pipeline runs it non-interactively.

#### Handoff A — PPTX (claude.ai chat)

After the brief is written and validated, tell the user:

1. **Open a new chat on claude.ai** (not Claude Code — the PPTX skill works best in the claude.ai web interface)
2. **Paste these two files** into the chat window as attachments:
   - `presentation-brief.md` (the brief you just generated)
   - `theme.md` (the theme file used in this workflow)
3. **Use this prompt:**

```
Please create a PPTX presentation using the attached presentation-brief.md and theme.md
```

Print the absolute paths to both files so the user can locate them easily:

```
─── Files to attach in claude.ai ───

Presentation brief: {absolute_path_to_presentation_brief}
Theme:              {absolute_path_to_theme_md}

Open claude.ai → new chat → attach both files → paste the prompt above.
─────────────────────────────────────────────────
```

Replace `{absolute_path_to_presentation_brief}` with the resolved `output_path` and `{absolute_path_to_theme_md}` with the `theme_path` from Step 1. Both paths **printed to the user** must be absolute — never use `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative paths. That governs printed handoff paths only; `$CLAUDE_PLUGIN_ROOT` remains the correct way to invoke a bundled script.

**Why claude.ai?** The web interface handles file attachments natively, which is what makes the PPTX skill render best there. Claude Code can also render via the `document-skills:pptx` skill — a working fallback, not the recommended path.

#### Handoff B — Outline (claude.ai/design)

Claude Design consumes an **outline**, not a brief: it has no meaning for the brief's `Layout:` vocabulary (`title-slide`, `is-does-means`, `four-quadrants`, ...), so handed the brief unchanged it re-derives the structure and paraphrases copy the client already approved. Export the outline as well:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/scripts/brief-to-outline.py" \
  --brief "{absolute_path_to_presentation_brief}"
```

It writes `presentation-outline.md` next to the brief and returns the absolute path as `data.outline_path`. Pass `--include-internal` only when the presenter-prep slides (Methodology, Buying Center) belong in the handoff; by default they are excluded, since they are internal preparation rather than client-facing copy.

The exporter prints one `{success, data, error}` envelope. On `success: false`, report the `error` to the user, skip the outline block below, and still deliver Handoff A — a failed outline export degrades the handoff, it does not invalidate the brief. Any `data.warnings` entries are advisory: report a `slide_points capped` warning, since it names slides whose on-slide copy did not fit the outline.

Then print the second boxed block:

```
─── File to attach in claude.ai/design ───

Presentation outline: {absolute_path_to_presentation_outline}

Hand the outline to Claude Design at claude.ai/design — the organization
design system applies, so attach theme.md only when none is configured.
──────────────────────────────────────────
```

Replace `{absolute_path_to_presentation_outline}` with the exporter's `data.outline_path`. As above, the printed path must be absolute — never `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative.

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **02-audience-model.md** | 3 | Audience Model construction (Rich/Lean mode) |
| **03-story-arc-analysis.md** | 4 | Arc detection, governing thought, section roles |
| **04-message-architecture.md** | 5 | Pyramid Principle, one-message-per-slide, MECE, consolidation |
| **05a-slide-copywriting.md** | 6 | Assertion headlines, number plays, bullet consolidation |
| **05b-speaker-notes.md** | 8.2 | Two-section speaker notes format reference (loaded by slides-enrichment-artist agent) |
| **06-slide-mapping-rules.md** | 7 | Layout selection, confidence scoring, fallback strategies |
| **07-output-template.md** | 2, 8, 8.2, 10 | Slide YAML example, brief output template, citation rules (also loaded by slides-enrichment-artist agent) |
| **08b-references-slide.md** | 8.1 | References slide construction |
| **08c-presenter-prep.md** | 8.2 | Internal prep slides + per-slide speaker notes process (loaded by slides-enrichment-artist agent) |
| **09-validation-checklist.md** | 9, 10 | Five-layer validation framework |
| **2g-diagram-simplification.md** | 2.1 | Mermaid diagram detection and simplification |

### Libraries (loaded as needed — progressive disclosure)

| Library | Step | Purpose |
|---------|------|---------|
| **arc-taxonomy.md** | 1 | Arc ID → visual arc type mapping, element names |
| **cta-taxonomy.md** | 1, 6.1 | CTA types, urgency, arc-to-CTA heuristics |
| **pptx-layouts.md** | 7 | Slide layout schemas and field definitions (deferred from Step 1) |
| **EXAMPLE_BRIEF.md** | 8 | Output format reference (deferred from Step 1) |
| **presentation-intent.md** | 8.2 | `design` / `climax` / `key_figures` vocabulary and the design defaults the `design` override falls back to |

### Scripts (executed, never loaded into context)

| Script | Step | Purpose |
|--------|------|---------|
| **brief-to-outline.py** | 11 | Export the Claude Design outline from a written brief; returns `data.outline_path` |

## Backward Compatibility

- Schema 4.1 is additive over 4.0 — both versions stay valid and an unfenced 4.0 brief
  stays readable. `references/07-output-template.md` is the authority on 4.1 frontmatter
  requiredness; `references/09-validation-checklist.md` carries the 4.0 key set for the
  checker.
- `arc_type: why-change` activates Why Change file discovery
- `project_path` parameter still accepted (mapped to `source_path`)
- Power Position extraction still supported
