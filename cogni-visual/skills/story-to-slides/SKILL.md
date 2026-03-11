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
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, AskUserQuestion
---

# Story-to-Slides Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized presentation brief that the PPTX skill can render into slides. You are a **presentation strategist**: analyze the narrative's argument structure, distill it into slide-level messages using pyramid communication, apply copywriting techniques, and select the right visual layout for each message.

A great presentation brief is not a transcript of the narrative. It is a re-architecture of the narrative's argument into a visual medium where every slide has ONE clear message, supported by evidence the audience can absorb in 3 seconds. This matters because slides that try to convey multiple messages become walls of text that audiences tune out — the presenter loses control of the room.

## Architecture

Two-layer intelligence:
1. **Story Arc Analysis** — read narrative, identify argument structure, extract governing thought, map section roles
2. **Message Architecture + Slide Specification** — pyramid communication, one message per slide, copywriting, layout selection, speaker notes

The brief describes WHAT each slide says and which layout to use. All visual decisions (colors, fonts, spacing) are delegated to the PPTX renderer via the theme. Briefs contain no color fields.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | `smarter-service` | Theme ID from `/cogni-workplace/themes/{theme}/theme.md`. Use `auto` for interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` / `subtitle` | auto-detected | Extracted from narrative if not provided |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/presentation-brief.md` | Brief output location |
| `max_slides` | `15` | Maximum slide count (forces consolidation if narrative is long) |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from cogni-narrative (e.g., `industry-transformation`). Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become methodology slide phase labels. |
| `confidence_threshold` | `0.8` | Minimum confidence for automatic layout mapping |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `audience_context` | none | Structured audience/buyer data for targeted evidence selection and Q&A prep (Rich mode). |
| `buyer_appendix_path` | none | Path to buyer-appendix.md for enriched Q&A prep (Step 7c only). |
| `governing_thought` | auto-extracted | Pre-computed governing thought from caller — Step 3 validates rather than re-derives. |
| `section_roles` | auto-detected | Pre-mapped section roles from caller — Step 3 validates rather than re-derives. |

---

## Conventions

These three rules prevent the most common failure modes. They emerged from repeated test runs where the executing model either broke interactive prompts, mangled German text, or injected visual fields into the brief.

### User Interaction

Interactive checkpoints let the user steer creative decisions without micromanaging. The structured format below ensures AskUserQuestion renders properly — unstructured prose produces empty prompts.

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

German presentations are printed, projected, and shared with executives. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout: ae->ä oe->ö ue->ü ss->ß. German number formatting: 2.661 (not 2,661).

### No Color Fields

Briefs contain ZERO visual fields: no `Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:`, `Mood:`. The PPTX skill reads the theme directly.

---

## Mandatory Slide Structure

| Position | Layout | Role |
|----------|--------|------|
| **First** | `title-slide` | Opening with title, subtitle, metadata |
| **After title** | 1-2 internal prep slides | Methodology (always) + Buying Center (Rich mode only) |
| **Body** | Content slides | One message per slide |
| **Second-to-last** | `closing-slide` | CTA headline, key takeaway |
| **Last** | References slide | Consolidated citations |

Internal prep slides carry `Bottom-Banner` with "INTERNAL — REMOVE FROM CLIENT PRESENTATION" and are NOT counted against `max_slides`.

---

## Workflow

> **CRITICAL:** When this skill loads without explicit parameter values, DO NOT ask the user for `source_path`, `theme`, `language`, or any other parameter. Execute Step 0 immediately — search the filesystem, present findings, then proceed. The only user interaction should be choosing from options YOU discovered.

### Step 0: Narrative Auto-Discovery (YOUR FIRST ACTION)

> **WHY:** Users typically invoke this skill from a project directory that already contains their narrative. Searching first and presenting candidates eliminates the most common friction point — the user fumbling for a file path.

If `source_path` was explicitly provided: set `source_dir` to its parent directory and skip to TodoWrite initialization.

Otherwise, search without asking:

1. **Primary:** Glob `**/insight-summary.md` from CWD (max 3 levels)
2. For each candidate: read first 30 lines, extract title, arc_id, estimate word count
3. **Secondary** (if 0 primary results): Glob `**/*.md`, filter for `arc_id:` in first 30 lines. Exclude SKILL.md, README.md, CLAUDE.md.
4. Sort: insight-summary.md files first, then by path depth (shallow first)

**If candidates found:** Present via AskUserQuestion (max 4 options with filename, title, arc_id, word count). On empty response, auto-select top candidate.

**If no candidates:** Ask for path or cancel. On empty response, stop with: "No narrative path provided. Stopping."

Set `source_dir` = parent directory of selected `source_path`.

---

### TodoWrite Initialization

Before reading content, initialize TodoWrite with workflow steps: Parse parameters, Read narrative, Build audience model, Analyze story arc, Architect slide messages, Apply copywriting, Propose CTAs, Select layouts, Generate YAML specs, Generate references slide, Generate internal prep + speaker notes, Validate, Write brief.

### Execution Protocol

Each step: mark todo `in_progress` -> verify previous output (entry gate) -> read reference file -> execute -> mark `completed`. Do NOT skip reference reads — each contains rules that prevent common errors.

---

### Step 1: Parse Parameters & Resolve Context

> **WHY:** Arc resolution and theme loading happen before reading the narrative because they shape how you interpret the story. A pre-resolved arc_type tells you what argument pattern to look for.

Determine input type (directory with metadata vs single file) and load metadata.

**Arc resolution** (priority order):
1. `arc_id` parameter → use directly
2. Source narrative frontmatter `arc_id` → extract
3. Neither → Step 3 auto-detects

If arc_id set: read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`, map to arc_type. If `arc_definition_path` provided: extract element names for methodology slide.

**Theme resolution:** If interactive and theme not explicitly set: scan `themes/*/theme.md`, present via AskUserQuestion. Otherwise use provided theme or default. Read theme.md, store absolute path.

**Load libraries:** `pptx-layouts.md`, `EXAMPLE_BRIEF.md`, `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set).

---

### Step 2: Read Narrative Content

> **WHY:** The tagged narrative with section boundaries and citation maps is the foundation everything downstream builds on. Getting the citation renumbering right here prevents broken links in 6 downstream steps.

Read all source files, preserve section boundaries (H1/H2/H3), extract citation URL map, assign sequential citation numbers. Store renumber map for Steps 5d, 7b, 9.

**Citation rules:** See `references/07-output-template.md` (Citation Handling Rules section) for preservation rules, exclusion zones, and Source field generation priority.

**Step 2g — Diagram detection:** Read `references/2g-diagram-simplification.md`. Scan for Mermaid fenced blocks, classify type (gantt/layered-architecture/process-flow), check complexity against layout constraints, simplify if needed. IS-DOES-MEANS slides are NOT affected by diagram detection.

---

### Step 2.5: Build Audience Model

> **WHY:** The audience model determines how downstream steps select evidence, frame the governing thought, and prepare Q&A. Rich mode (with structured stakeholder data) enables targeted speaker notes; Lean mode infers from narrative vocabulary.

**Read reference:** `references/02-audience-model.md`

Build Audience Model: Rich mode (from `audience_context` or pitch-log.json) or Lean mode (inferred from narrative). Identify primary decision-maker, priorities, objections.

**Content checkpoint:** State mode, confidence, decision-maker, top priority, top objection.

---

### Step 3: Analyze Story Arc [CORE INTELLIGENCE]

> **WHY:** The governing thought and arc type cascade through everything downstream — message architecture, consolidation, layout selection, and speaker notes coaching. Getting them right here prevents rework in later steps.

**Read reference:** `references/03-story-arc-analysis.md`

- **3a. Detect arc type** — why-change, problem-solution, journey, argument, or report
- **3b. Extract governing thought** — single sentence, audience-weighted
- **3c. Map section roles** — hook, problem, urgency, evidence, solution, proof, options, roadmap, investment, call-to-action

When caller provides `governing_thought`/`section_roles`: validate against narrative rather than re-deriving. When `arc_context` populated from Step 1: use resolved arc_type directly.

**Content checkpoint:** State arc type, governing thought, sections mapped count.

---

### Step 4: Architect Slide Messages [CORE INTELLIGENCE]

> **WHY:** Pyramid communication is what separates a professional deck from a content dump. Without explicit one-message-per-slide discipline, the natural tendency is to pack 3-4 points per slide — which means the audience remembers none of them.

**Read reference:** `references/04-message-architecture.md`

- **4a. Pyramid Principle** — governing thought -> arguments -> evidence
- **4b. One message per slide** — each slide gets exactly ONE message sentence
- **4c. Consolidation** — merge/cut when narrative exceeds `max_slides`. Rich mode protects slides aligned with decision-maker priorities.
- **4d. MECE check** — mutually exclusive, collectively exhaustive, logically ordered

**Content checkpoint:** State slide count, argument count, consolidation status.

---

### Step 5: Apply Copywriting Techniques [CORE INTELLIGENCE]

> **WHY:** Headlines are the first thing an audience reads on every slide. A topic label ("Market Overview") tells the audience nothing — they have to read the body to understand the point, which means you've lost their attention. An assertion headline ("European market contracts 12% as regulation tightens") delivers the message in 3 seconds.

**Read reference:** `references/05a-slide-copywriting.md`

- **5a. Headline optimization** — every title is an assertion (max 60 chars, contains verb)
- **5b. Number plays** — ratio framing, hero number isolation, before/after contrast
- **5c. Bullet consolidation** — 8-12 points -> 3-5 scannable bullets (max 10 words each)
- **5d. Evidence selection** — top 3-5 per slide, audience-weighted, inline citations preserved

Speaker-Notes are generated later in Step 7c (after layouts finalize). Step 5 focuses on slide copy only.

---

### Step 5b: Propose CTAs

> **WHY:** Without explicit CTAs, the audience leaves the room impressed but without a next step. CTAs convert attention into action — the primary CTA gives the presenter something concrete to propose.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

1. Extract implicit CTAs from narrative + generate from governing thought, arc type, hero numbers
2. Per content slide: assign `cta.text` (max 50 chars, imperative verb), `cta.type` (explore/evaluate/commit/share), `cta.urgency`
3. Build `cta_summary`: 3-5 proposals, `primary_cta` = highest-urgency commit CTA

If interactive: present CTA plan via AskUserQuestion (Approve/Adjust). On empty response, treat as approval.

---

### Step 6: Select Layouts

> **WHY:** Layout selection translates message type into visual structure. A hero number on a `two-columns-equal` layout wastes its impact — `stat-card-with-context` isolates the number and makes it the focal point.

**Read reference:** `references/06-slide-mapping-rules.md`

Map each slide to best layout from `pptx-layouts.md`. Mandatory rules apply first (title-slide, closing-slide), then diagram rules (Mermaid blocks), then content pattern matching. Ensure layout variety and confidence >= threshold.

---

### Step 7: Generate YAML Slide Specifications

> **WHY:** The YAML specification is the contract between this skill and the PPTX renderer. Every field must contain final, copy-paste-ready text because the renderer reproduces it exactly — no interpretation, no cleanup.

**Read reference:** `references/07-output-template.md` (Slide YAML Example section)

For each slide, generate content-only YAML following `pptx-layouts.md` field names. Zero color fields. Every slide heading is an assertion headline.

---

### Step 7b: Generate References Slide

> **WHY:** A consolidated references slide with working links gives the presentation academic credibility and lets readers verify claims independently.

**Read reference:** `references/08b-references-slide.md`

Generate from citation renumber map (Step 2). Position AFTER closing-slide as last slide in deck.

---

### Step 7c: Generate Internal Prep Slides and Speaker-Notes

> **WHY:** Speaker notes are what transform a slide deck from a document into a performance tool. The methodology slide and buying center card give the presenter strategic context before they walk into the room. The 200-400 word notes per slide ensure the presenter never gets stuck mid-delivery.

**Read BOTH references:**
- `references/08c-presenter-prep.md` — prep slide generation, 10-step speaker notes process, arc-position coaching
- `references/05b-speaker-notes.md` — two-section format, tags, worked example

**Sub-step 1: Internal prep slides** (placed after Slide 1):
- **Slide 2: Methodology** (always) — `process-flow` with Mermaid pipeline + Detail-Grid. PEAK/RELEASE pacing in notes.
- **Slide 3: Buying Center** (Rich mode only) — `four-quadrants` text-card mode with stakeholder cards.

Both get `Bottom-Banner` with localized INTERNAL warning.

**Sub-step 2: Speaker-Notes for ALL slides** — two-section format ("WHAT YOU SAY" + "WHAT YOU NEED TO KNOW"), 200-400 words per slide, arc-position coaching, layout-aware openings, comprehensive Q&A.

---

### Step 8: Validate Against Schema

> **WHY:** Self-assessment is unreliable without explicit measurement. In early tests, models reported "pass" while producing topic-label headlines and missing citations. The five-layer gate forces honest evaluation.

**Read reference:** `references/09-validation-checklist.md`

Five layers — stop on first failure, fix, re-check:
1. **Schema** — layout types exist, required fields present, no color fields, valid YAML
2. **Message quality** — assertion headlines, MECE sequence, isolated hero numbers
3. **Copywriting** — number plays applied, bullets consolidated, no hedging
4. **Presentation logic** — bookend slides enforced, within max_slides, layout variety
5. **Content integrity** — all sections represented, citations preserved, German characters correct

---

### Step 9: Write Presentation Brief

> **WHY:** The output path convention keeps generated briefs separate from source narratives in a `cogni-visual/` subdirectory, preventing clutter and making it easy for downstream agents to find the brief.

**Read reference:** `references/07-output-template.md` (Brief Output Template section)

**Output path resolution** (run via Bash before writing):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/presentation-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

Write the brief following the output template. YAML frontmatter must include: type, version (4.0), theme, theme_path, arc_type, arc_id, governing_thought, confidence_score. Include PPTX Rendering Requirements section (localized). Include Generation Metadata at end.

**Final checks:**
- YAML frontmatter valid and complete
- PPTX Rendering Requirements present (localized)
- Internal prep slides follow Slide 1 with INTERNAL Bottom-Banner
- Slide 1 = title-slide, closing-slide = second-to-last, references = last
- Zero color fields in entire document
- Inline citations use `<sup>[N](url)</sup>`, Speaker-Notes citations use `[N](url)`
- Generation Metadata populated
- Output directory created, file written

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **02-audience-model.md** | 2.5 | Audience Model construction (Rich/Lean mode) |
| **03-story-arc-analysis.md** | 3 | Arc detection, governing thought, section roles |
| **04-message-architecture.md** | 4 | Pyramid Principle, one-message-per-slide, MECE, consolidation |
| **05a-slide-copywriting.md** | 5 | Assertion headlines, number plays, bullet consolidation |
| **05b-speaker-notes.md** | 7c | Two-section speaker notes format reference |
| **06-slide-mapping-rules.md** | 6 | Layout selection, confidence scoring, fallback strategies |
| **07-output-template.md** | 7, 9 | Slide YAML example, brief output template, citation rules |
| **08b-references-slide.md** | 7b | References slide construction |
| **08c-presenter-prep.md** | 7c | Internal prep slides + per-slide speaker notes process |
| **09-validation-checklist.md** | 8 | Five-layer validation framework |
| **2g-diagram-simplification.md** | 2g | Mermaid diagram detection and simplification |

### Libraries (loaded as needed)

| Library | Step | Purpose |
|---------|------|---------|
| **arc-taxonomy.md** | 1 | Arc ID -> visual arc type mapping, element names |
| **pptx-layouts.md** | 1, 6 | Slide layout schemas and field definitions |
| **cta-taxonomy.md** | 5b | CTA types, urgency, arc-to-CTA heuristics |
| **EXAMPLE_BRIEF.md** | 1 | Output format reference |

## Backward Compatibility

- `arc_type: why-change` activates Why Change file discovery
- `project_path` parameter still accepted (mapped to `source_path`)
- Power Position extraction still supported
