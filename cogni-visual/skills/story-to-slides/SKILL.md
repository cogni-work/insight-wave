---
name: story-to-slides
description: >
  Transform any narrative (insight summary, trend report, strategy document, sales pitch,
  project update) into an optimized multi-slide presentation brief that the PPTX skill
  renders into PowerPoint. Use this skill whenever the user mentions "presentation",
  "slide deck", "slides", "PowerPoint", "Foliensatz", "Praesentation erstellen",
  "Folien aus Bericht", "pitch deck", "create slides from report", or wants to convert
  prose into slide-level message architecture. Also trigger when the user needs pyramid
  communication, number plays, assertion headlines, or speaker notes for a presentation.
  Covers Why Change projects, research reports, competitive intelligence, trend panoramas,
  and both English and German output. Produces a presentation-brief.md (v4.0) that the
  PPTX agent renders. Important: this skill CREATES the brief from a narrative source —
  it does NOT render an existing brief (use PPTX skill for that), does NOT create a
  single-canvas poster (use story-to-big-picture), does NOT create a web page
  (use story-to-web), and does NOT enhance prose (use Copywriter skill).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# Story-to-Slides Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized presentation brief that the PPTX skill can render into slides. You are a **presentation strategist**: analyze the narrative's argument structure, distill it into slide-level messages using pyramid communication, apply copywriting techniques, and select the right visual layout for each message.

A great presentation brief is not a transcript of the narrative. It is a re-architecture of the narrative's argument into a visual medium where every slide has ONE clear message, supported by evidence the audience can absorb in 3 seconds. Slides that try to convey multiple messages become walls of text that audiences tune out — the presenter loses control of the room.

## Architecture

Two-layer intelligence:
1. **Story Arc Analysis** — read narrative, identify argument structure, extract governing thought, map section roles
2. **Message Architecture + Slide Specification** — pyramid communication, one message per slide, copywriting, layout selection, speaker notes

The brief describes WHAT each slide says and which layout to use. The PPTX renderer owns all visual decisions (colors, fonts, spacing) by reading the theme directly — briefs contain no color fields.

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
| `arc_id` | from frontmatter | Narrative arc ID from cogni-narrative (e.g., `industry-transformation`). Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become methodology slide phase labels. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `audience_context` | none | Structured audience/buyer data for targeted evidence selection and Q&A prep (Rich mode). |

### Caller-supplied overrides

These are typically set by an upstream agent (e.g., why-change-work), not by a human user:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `confidence_threshold` | `0.8` | Minimum confidence for automatic layout mapping |
| `governing_thought` | auto-extracted | Pre-computed governing thought — Step 4 validates rather than re-derives. |
| `section_roles` | auto-detected | Pre-mapped section roles — Step 4 validates rather than re-derives. |
| `buyer_appendix_path` | none | Path to buyer-appendix.md for enriched Q&A prep (Step 8.2 only). |

---

## Conventions

### Theme-driven visuals

The PPTX renderer owns all visual decisions — colors, fonts, spacing — by reading the theme directly. Briefs specify content and layout only. Omit visual fields (`Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:`, `Mood:`) because the renderer ignores them and their presence creates ambiguity about who controls styling.

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

German presentations go to executives. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout: ae→ä oe→ö ue→ü ss→ß. German number formatting: 2.661 (dot as thousands separator).

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
- Good: "Staff cannot cover all areas 24/7" (6 words, max 10 words per bullet)

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

When invoked without explicit parameters, search the filesystem first (Step 0) rather than prompting for paths. Users invoke this skill from project directories that already contain their narrative — asking for a path they're sitting next to creates unnecessary friction. The two interactive checkpoints are: (1) narrative selection in Step 0, and (2) theme selection in Step 1 via `cogni-workspace:pick-theme`.

### Execution protocol

Each step: verify the previous step's output is available (entry gate), read the reference file for that step, execute, then state your output summary before moving on. Reference files contain step-specific rules that prevent downstream rework — read them at the start of each step.

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

**Load libraries:** `pptx-layouts.md`, `EXAMPLE_BRIEF.md`, `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set).

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

> Headlines are the first thing an audience reads. A topic label ("Market Overview") tells them nothing — they have to read the body to get the point, and you've lost their attention. An assertion headline ("European market contracts 12% as regulation tightens") delivers the message in 3 seconds.

**Read reference:** `references/05a-slide-copywriting.md`

- **6a. Headline optimization** — every title is an assertion (max 60 chars, contains verb)
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

**Read reference:** `references/06-slide-mapping-rules.md`

Map each slide to best layout from `pptx-layouts.md`. Mandatory rules apply first (title-slide, closing-slide), then diagram rules (Mermaid blocks), then content pattern matching. Ensure layout variety and confidence >= threshold.

---

### Step 8: Generate YAML Slide Specifications

> The YAML specification is the contract between this skill and the PPTX renderer. Every field must contain final, copy-paste-ready text because the renderer reproduces it exactly — no interpretation, no cleanup.

**Read reference:** `references/07-output-template.md` (Slide YAML Example section)

For each slide, generate content-only YAML following `pptx-layouts.md` field names. Omit all visual fields — the renderer reads the theme. Every slide heading is an assertion headline.

---

#### Step 8.1: Generate References Slide

> A consolidated references slide with working links gives the presentation credibility and lets readers verify claims independently.

**Read reference:** `references/08b-references-slide.md`

Generate from citation renumber map (Step 2). Position after closing-slide as last slide in deck.

---

#### Step 8.2: Generate Internal Prep Slides and Speaker-Notes

> Speaker notes transform a deck from a document into a performance tool. Prep slides give the presenter strategic context before entering the room.

**Read BOTH references:**
- `references/08c-presenter-prep.md` — prep slide generation, 10-step speaker notes process, arc-position coaching
- `references/05b-speaker-notes.md` — two-section format, tags, worked example

**Sub-step 1: Internal prep slides** (placed after Slide 1):
- **Slide 2: Methodology** (always) — `process-flow` with Mermaid pipeline + Detail-Grid. PEAK/RELEASE pacing in notes.
- **Slide 3: Buying Center** (Rich mode only) — `four-quadrants` text-card mode with stakeholder cards.

Both get `Bottom-Banner` with localized INTERNAL warning.

**Sub-step 2: Speaker-Notes for all slides** — two-section format ("WHAT YOU SAY" + "WHAT YOU NEED TO KNOW"), 200-400 words per slide, arc-position coaching, layout-aware openings, comprehensive Q&A.

---

### Step 9: Validate Against Schema

> Self-assessment is unreliable without explicit measurement — in early tests, models reported "pass" while producing topic-label headlines and missing citations. The five-layer gate forces honest evaluation.

**Read reference:** `references/09-validation-checklist.md`

Five layers — stop on first failure, fix, re-check:
1. **Schema** — layout types exist, required fields present, no visual fields, valid YAML
2. **Message quality** — assertion headlines, MECE sequence, isolated hero numbers
3. **Copywriting** — number plays applied, bullets consolidated, no hedging
4. **Presentation logic** — bookend slides enforced, within max_slides, layout variety
5. **Content integrity** — all sections represented, citations preserved, German characters correct

---

### Step 10: Write Presentation Brief

> The output path convention keeps generated briefs in a `cogni-visual/` subdirectory, preventing clutter and making it easy for downstream agents to find the brief.

**Read reference:** `references/07-output-template.md` (Brief Output Template section)

**Output path resolution** (run via Bash before writing):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/presentation-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

Write the brief following the output template. YAML frontmatter must include: type, version (4.0), theme, theme_path, arc_type, arc_id, governing_thought, confidence_score. Include PPTX Rendering Requirements section (localized). Include Generation Metadata at end.

Run the validation checklist (reference `09-validation-checklist.md`) one final time against the written file. The most commonly missed items at this stage: mispositioned PPTX Rendering Requirements section, and superscript `<sup>[N](url)</sup>` in body text vs plain `[N](url)` in speaker notes.

---

### Step 11: Generate PPTX Prompt

> The user needs a ready-to-use prompt for a fresh Claude chat with the PPTX skill. Absolute paths make it self-contained — no path-hunting needed.

After the brief is written and validated, generate a copy-paste prompt block using the absolute paths resolved during the workflow:

```
─── Copy this prompt into a new Claude chat ───

Please create a PPTX presentation using:
- Presentation brief: {absolute_path_to_presentation_brief}
- Theme: {absolute_path_to_theme_md}

────────────────────────────────────────────────
```

Replace `{absolute_path_to_presentation_brief}` with the resolved `output_path` and `{absolute_path_to_theme_md}` with the `theme_path` from Step 1.

Both paths must be absolute — never use `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative paths, because the receiving Claude session has no access to variables from this session.

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **02-audience-model.md** | 3 | Audience Model construction (Rich/Lean mode) |
| **03-story-arc-analysis.md** | 4 | Arc detection, governing thought, section roles |
| **04-message-architecture.md** | 5 | Pyramid Principle, one-message-per-slide, MECE, consolidation |
| **05a-slide-copywriting.md** | 6 | Assertion headlines, number plays, bullet consolidation |
| **05b-speaker-notes.md** | 8.2 | Two-section speaker notes format reference |
| **06-slide-mapping-rules.md** | 7 | Layout selection, confidence scoring, fallback strategies |
| **07-output-template.md** | 8, 10 | Slide YAML example, brief output template, citation rules |
| **08b-references-slide.md** | 8.1 | References slide construction |
| **08c-presenter-prep.md** | 8.2 | Internal prep slides + per-slide speaker notes process |
| **09-validation-checklist.md** | 9 | Five-layer validation framework |
| **2g-diagram-simplification.md** | 2.1 | Mermaid diagram detection and simplification |

### Libraries (loaded as needed)

| Library | Step | Purpose |
|---------|------|---------|
| **arc-taxonomy.md** | 1 | Arc ID → visual arc type mapping, element names |
| **pptx-layouts.md** | 1, 7 | Slide layout schemas and field definitions |
| **cta-taxonomy.md** | 6.1 | CTA types, urgency, arc-to-CTA heuristics |
| **EXAMPLE_BRIEF.md** | 1 | Output format reference |

## Backward Compatibility

- `arc_type: why-change` activates Why Change file discovery
- `project_path` parameter still accepted (mapped to `source_path`)
- Power Position extraction still supported
