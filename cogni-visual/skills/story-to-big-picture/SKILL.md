---
name: story-to-big-picture
description: >
  Transform any narrative (insight summary, trend report, strategy document) into
  a single-canvas visual journey map — a "big picture" — where each narrative section
  becomes an illustrated landscape object in a cohesive scene. Use this skill whenever
  the user mentions "big picture", "visual journey map", "landscape poster",
  "illustrated canvas", "visual story map", "spatial journey", "poster for workshop",
  "Poster für die Geschäftsführung", or "Big Picture erstellen". Also trigger when
  the user wants to convert a narrative into a single illustrated scene with stations
  (not slides, not a web page, not a storyboard — those are different skills). Covers
  requests for A0-A3 poster formats, dark/light themes, factory/cityscape/airport
  panorama metaphors, and both English and German output. Produces a big-picture-brief.md
  (v3.0) that the big-picture agent renders via Excalidraw MCP. Important: this skill
  CREATES the brief from a narrative source — it does NOT render an existing brief
  (use render-big-picture for that).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, AskUserQuestion
version: 1.4.0
---

# Story-to-Big-Picture Skill

## Purpose

Transform any narrative into a big-picture-brief (v3.0) that the Excalidraw renderer turns into an integrated illustrated scene. You are a **visual storytelling architect**: analyze the narrative's argument structure, brainstorm a Story World, decompose the story into landscape objects, and write station copy that tells the story spatially.

A big picture is NOT cards on a colored background. It's a **cohesive illustrated scene** where each station IS an object in the landscape — a broken CNC machine, a sensor-equipped robot arm, a control tower. The landscape is the story itself, made spatial. This matters because card-based layouts are generic and forgettable, while integrated scenes create memorable spatial narratives that audiences navigate intuitively.

## Architecture

Two-layer intelligence:
1. **Story Arc Analysis** — read narrative, identify argument structure, map the arc to spatial flow
2. **Scene Architecture** — brainstorm Story World, decompose into stations, map to landscape objects, write copy with `object_name` + `narrative_connection`

The brief describes WHAT to show, not HOW to draw it. Rendering agents own visual interpretation via shape-recipes-v3.md. Briefs contain no `shape_composition`, `landscape_composition`, or color fields — the renderer reads the theme directly.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | `smarter-service` | Theme ID from `/cogni-workplace/themes/{theme}/theme.md`. Use `auto` for interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` / `subtitle` | auto-detected | Extracted from narrative if not provided |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/big-picture-brief.md` | Brief output location |
| `max_stations` | `6` | Maximum station count (4-8, auto-determined from narrative) |
| `canvas_size` | `A1` | DIN format: A0, A1, A2, A3 (always landscape) |
| `metaphor` | `auto` | Story World hint — classic name (`mountain`, `river`, `road`, `archipelago`, `garden`, `cityscape`) or free text. When `auto`, brainstorm from content. |
| `visual_style` | `auto` | `flat-illustration` or `sketch`. Maps to Excalidraw roughness. Alias `art_style` accepted. |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from cogni-narrative (e.g., `industry-transformation`). Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become `station_label` values. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `audience_context` | none | Structured audience/buyer data for station prioritization |
| `governing_thought` | auto-extracted | Pre-computed governing thought from caller |

Canvas size details: See `$CLAUDE_PLUGIN_ROOT/libraries/big-picture-layouts.md` for dimensions, zones, and station constraints per DIN format.

---

## Conventions

These three rules prevent the most common failure modes across all workflow steps. They emerged from repeated test runs where the executing model either broke interactive prompts, mangled German text, or injected drawing instructions into the brief.

### User Interaction

Interactive checkpoints (Story World selection, theme, CTAs, preview) let the user steer creative decisions without micromanaging every step. The structured format below ensures AskUserQuestion renders properly — unstructured prose in the `question` field produces empty prompts.

When presenting choices, use AskUserQuestion with this structure:

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

**On empty or blank responses, auto-select the best option and move on.** Never retry AskUserQuestion on empty responses — the user either has no preference or the tool couldn't capture input. This rule applies to every AskUserQuestion call in the workflow.

When `interactive` is `false`, skip all AskUserQuestion calls and auto-select.

### Language & Formatting

German big pictures are typically printed as A1 posters for workshops and boardrooms. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" to German-speaking executives and undermine credibility. Use real Unicode umlauts throughout the entire brief: ä ö ü Ä Ö Ü ß. The source narrative already contains correct umlauts — preserve them in every text field: frontmatter, headlines, body, labels, CTAs, metadata.

German number formatting: 2.661 (not 2,661). Compound nouns: hyphenate if over 20 chars.

### Brief Format v3.0

Separating WHAT from HOW is the core design principle: the brief author describes what each station represents (`object_name` + `narrative_connection`), and the rendering agents decide how to draw it. This separation means briefs stay stable even when the rendering pipeline evolves. No drawing instructions (`shape_composition`, `landscape_composition`) and no color fields on stations — the renderer reads the theme directly and composes illustrations using shape-recipes-v3.md.

---

## Workflow

Parameters have sensible defaults and are auto-discovered. Search the filesystem first, present findings, then proceed. Never ask open-ended questions like "What file do you want?" when you can search and present candidates instead.

### Step 0: Narrative Auto-Discovery

> **WHY:** Users typically invoke this skill from a project directory that already contains their narrative. Searching first and presenting candidates eliminates the most common friction point — the user fumbling for a file path. This turns a cold start into a one-click selection.

If `source_path` was explicitly provided, set `source_dir` to its parent directory and skip to Step 1.

Otherwise, search without asking the user:

1. **Primary:** Glob `**/insight-summary.md` from CWD (max 3 levels)
2. For each candidate: read first 30 lines, extract title (H1 or frontmatter), arc_id, estimate word count
3. **Secondary** (if 0 primary results): Glob `**/*.md`, filter for `arc_id:` in first 30 lines. Exclude SKILL.md, README.md, CLAUDE.md, agent files.
4. Sort: insight-summary.md files first, then by path depth (shallow first)

**If candidates found:** Present via AskUserQuestion (max 4 options, each showing filename, title, arc_id, word count). On selection, set `source_path`.

**If no candidates:** Ask user for a path or cancel. If they cancel or respond empty, stop with: "No narrative path provided. Stopping."

Set `source_dir` to the parent directory of the selected `source_path`.

---

### Step 1: Parse Parameters & Resolve Context

> **WHY:** Arc resolution and theme loading happen here — before reading the narrative — because they shape how you interpret the story in Step 2. A pre-resolved arc_type tells you what spatial pattern to look for; a loaded theme tells you what visual world fits the brand.

Determine input type (directory with metadata files vs single file) and load available metadata (customer_name, provider_name, language, industry).

**Arc resolution** (priority order):
1. `arc_id` parameter provided by caller → use directly
2. Source narrative frontmatter contains `arc_id` → extract it
3. Neither → arc_id remains unset (Step 2 auto-detects from content)

If arc_id is set:
- Read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`
- Map arc_id to visual arc_type using the mapping table
- Store arc_context (arc_id, arc_type, arc_display_name)
- The mapped arc_type takes priority over the `arc_type` parameter

If `arc_definition_path` is provided and exists:
- Read the file, extract the 4 ordered element names with translations
- These become `station_label` values in Step 4

**Theme resolution:**
- If `interactive=true` and theme wasn't explicitly set by caller: scan for `themes/*/theme.md` files, present discovered themes via AskUserQuestion
- Otherwise: use provided theme ID or default `smarter-service`
- Resolve theme directory: absolute path → use directly; theme ID → check `{WORKPLACE_ROOT}/themes/{theme}/theme.md`, fall back to `/cogni-workplace/themes/{theme}/theme.md`
- Read `{THEME_DIR}/theme.md`, store theme_path

**Load libraries:**
- `$CLAUDE_PLUGIN_ROOT/libraries/big-picture-layouts.md` — canvas dimensions and zone specs
- `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md` — CTA types and heuristics

Resolve canvas dimensions from `canvas_size` parameter.

---

### Step 2: Read Narrative & Analyze Story Arc

> **WHY:** The governing thought and arc type are the two decisions that cascade through everything downstream — the Story World, station decomposition, spatial layout, and reading flow. Getting them right here prevents rework in later steps.

**Read reference:** `references/02-station-architecture.md` (Arc Analysis section)

Read all source files. Write a governing thought in your own words — synthesize, don't copy multi-sentence passages from the source.

The governing thought must be a **single sentence** that names the narrative's subject domain — the specific industry, technology, or audience. It anchors the entire canvas: viewers scan the title banner first and need immediate orientation. A multi-sentence governing thought dilutes impact; a generic one fails to orient.

**Self-test:** "Could someone read ONLY this sentence and know what industry this big picture is about AND what's at stake?" If not, rewrite with domain-specific nouns and a concrete consequence.

**Examples:**
- Bad (multi-sentence copy-paste): "Externe Kräfte erzwingen Investitionen. Digitale Werttreiber rechtfertigen sie. Neue Horizonte geben Richtung. Das Fundament bestimmt den Erfolg."
- Bad (generic): "Wer 2026 nicht investiert, verliert den Anschluss"
- Good (single sentence, domain-specific): "Flughafenbetreiber, die 2026 nicht in digitale Infrastruktur investieren, verlieren den Anschluss an automatisierte Hubs"
- Good (single sentence, domain-specific): "Der Maschinenbau verliert 23 % Produktivität an manuelle Prozesse, die KI-gestützte Fertigung bereits heute eliminiert"

**Arc type resolution:**
1. Pre-resolved from Step 1 (arc_id mapping) — preferred
2. Caller-provided `arc_type` parameter (if not `auto`)
3. Auto-detect from narrative content using the reference. For detailed rules, also read `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/03-story-arc-analysis.md`

The arc type drives spatial flow (left-to-right, bottom-to-top, winding) rather than slide order — the key difference from story-to-slides.

---

### Step 3: Brainstorm Story World

> **WHY:** The Story World is what separates a memorable big picture from a generic card layout. Brainstorming multiple concepts (literal + lateral) before committing prevents the first-idea trap and gives the user a real creative choice. The scoring rubric keeps the selection grounded in narrative fit rather than novelty alone.

**Read reference:** `references/01-story-worlds.md`

Follow the three-phase brainstorming method:

**Phase 1 — Content World Analysis:** Extract concrete nouns, industry domain, physical objects, spatial language, and transformation verbs from the narrative.

**Phase 2 — Generate 2-3 Story World Concepts.** Each includes:
- `world_name`: descriptive name (e.g., "Smart Factory Evolution")
- `world_type`: `literal` or `lateral` — generate at least one of each
- `world_description`: 1-2 sentence scene description
- `station_objects`: for EACH station, what it BECOMES (object_name + narrative_connection)
- `world_score`: narrative_fit (40%) + visual_composability (30%) + brand_fit (30%)

If `metaphor` parameter is provided, use it as a brainstorming starting point. Classic names map to the reference's classic worlds; free text seeds the content analysis.

**Phase 3 — Score and present.** Present worlds via AskUserQuestion for selection. Include world_name, type, description, and score in each option. Auto-select the highest-scored world if non-interactive or on empty response.

---

### Step 4: Decompose Narrative into Stations

> **WHY:** Station decomposition is the structural backbone of the big picture. If you skip the data inventory, stations lose their quantitative authority. If you merge too aggressively, important sub-topics disappear. The coverage check at the end catches both failure modes before you invest time writing copy.

**Read reference:** `references/02-station-architecture.md` (Station Decomposition section)

Break the narrative into 4-8 stations (capped by `max_stations`). Each station maps to a section of the story arc and becomes a landscape object in the selected Story World.

**Before decomposing:** Inventory the source's quantitative claims. List every number, percentage, market size, date, and comparison in the narrative. This inventory drives data point allocation in Step 5 — stations that lose their numbers lose their authority.

For each station, determine:

1. **Whether to merge or split** — consolidate minor sections into adjacent stations; split multi-topic sections if under 4 stations total. Sections with hero numbers survive consolidation.
2. **Position** along journey (early/mid/late), mapped to the arc type's spatial pattern
3. **Hero message** and key data point
4. **Data point allocation** — assign 5-7 quantitative claims from the inventory to each station. Every station needs enough evidence to fill 100-120 words of prose. If a source section has more claims than fit in one station, prioritize: (a) claims with specific numbers over qualitative statements, (b) claims that contrast before/after or old/new, (c) claims that name specific actors or organizations.
5. **station_label** using content-source-first assignment:
   - If arc_elements loaded: check which narrative H2 chapter this station's content came from. If the chapter matches an arc element name, use that element. Otherwise fall back to role-based mapping (problem→first element, solution→middle, proof→penultimate, roadmap→final). Use localized names per language. See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for the full heuristic.
   - If no arc_elements: leave station_label unset
   - Synthesis/CTA stations that span multiple dimensions **always** get station_label `"Synthese"` (de) or `"Synthesis"` (en) — this rule applies regardless of whether arc_elements are loaded
6. **landscape_object** from Story World mapping:
   - `object_name`: what this station becomes in the scene
   - `narrative_connection`: why this object represents the message (include visual adjectives)
   - `scale`: hero (max 1) | standard | supporting
7. **reading_flow_number** (1..N, spatial left-to-right / bottom-to-top order)
8. **text_placement**: below (default) | above (near canvas bottom) | right (space available) | left (rightmost stations) | auto

**Coverage check:** After allocation, scan the data point inventory. If more than 40% of source quantitative claims are unrepresented in any station, redistribute — either add claims to under-populated stations or reconsider whether a merge dropped an important sub-topic.

---

### Step 5: Write Station Copy

> **WHY:** Station copy is the most failure-prone step. The natural tendency is to compress prose into bullet-style facts (~40 words), but A1 station text areas are 380x240px — half-empty text boxes look broken on printed posters. The 100-120 word target and 5-part formula exist because they produce bodies that fill the text area and build a coherent argument, not just list facts.

**Read reference:** `references/04-text-station-copy.md`

For each station, generate:

1. **Assertion headline** (max 50 chars) — shorter than slides because stations share canvas space with illustrations. Every headline must contain a verb and ideally a specific number from the narrative. Target: 80%+ of headlines contain numbers. "Das digitale Fundament bestimmt alles" is too vague — rewrite as "73 % der Flughäfen priorisieren IT-Sicherheit".

2. **Body text** (4-6 sentences, **100-120 words** — this is a hard range, not a suggestion).

   Big picture station text areas are large: A1 stations have 380x240px text boxes that feel visibly empty below 100 words. A 43-word body — typical when compressing to bullet-style facts — wastes half the text area and strips the station of its argumentative depth.

   Write each body using the **5-part formula** (state/prove/explain/impact/connect), weaving in the 5-7 data points allocated in Step 4. Each sentence should contain at least one specific fact — a number, a name, a date, or a comparison. Avoid compressed fact-list style ("X does Y. Z grows to W.") — use connective prose that builds an argument.

   **After writing each station body, count the words.** If under 100: go back to the source narrative section and add evidence — a market size, a percentage, an example, a timeline. If over 120: cut the weakest sentence. Record the final word count per station in your working notes — you will report these counts in the Generation Metadata.

3. **Hero number** (if applicable) — reframed with number plays (ratio framing, hero number isolation, before/after contrast)

4. **Refined narrative_connection** — the rendering agent needs enough visual detail to compose an illustration from shape-recipes. The connection should answer: "Why does this object represent this station's message?" Include visual adjectives (weathered, glowing, cracked, modern).

---

### Step 5b: Propose CTAs

> **WHY:** Big pictures are decision tools, not just information displays. Without explicit CTAs, viewers admire the poster and walk away. CTAs convert attention into action — the primary CTA gives the presenter a concrete next step to propose in the room.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

1. Extract implicit CTAs from narrative content
2. Generate additional CTAs from governing thought, arc type, hero numbers
3. For each station: assign `cta.text` (max 50 chars, imperative verb start), `cta.type` (explore/evaluate/commit/share), `cta.urgency` (low/medium/high)
4. Build `cta_summary`: 3-5 proposals ordered by urgency, `primary_cta` = highest-urgency commit CTA, `supporting_sections` per proposal, `conversion_goal` from arc type

If interactive: present CTA plan via AskUserQuestion with Approve/Adjust options. Mention the primary CTA in the question text.

---

### Step 5c: Station Preview

> **WHY:** This is the last checkpoint before the brief is written. Catching a misaligned station or weak headline here costs seconds; catching it after rendering costs minutes of re-rendering. The table format lets the user scan all stations at once rather than reading through YAML.

If interactive: output the station plan as a table showing each station's #, headline, landscape object, hero number, and arc role. Include Story World name, station count, and canvas size below the table. Then present via AskUserQuestion with Approve/Adjust options.

If non-interactive: skip this checkpoint.

---

### Step 6: Define Canvas Layout

> **WHY:** Spatial layout translates the arc type into physical reading flow. An ascending arc with a left-to-right layout contradicts the story's tension-building structure. Getting the flow pattern right here means the viewer's eye follows the argument naturally.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/big-picture-layouts.md`

Define the spatial arrangement:
1. Canvas dimensions from `canvas_size`
2. Zone allocation — title banner, journey zone, footer
3. Station x/y coordinates along the path (within journey zone bounds, minimum 50px gaps)
4. Path routing matching the arc type's flow pattern

---

### Step 7: Validate & Write Brief

> **WHY:** Validation exists because self-assessment is unreliable without explicit measurement. In early tests, models reported "pass" while producing 43-word bodies and ASCII umlauts. The four-layer gate with recorded counts forces honest evaluation — you can't claim the brief passes if the numbers say otherwise.

**Read references:**
- `references/05-validation.md` — four-layer validation framework
- `$CLAUDE_PLUGIN_ROOT/libraries/EXAMPLE_BIG_PICTURE_BRIEF.md` — output format reference

**Validate four layers — stop on first failure, fix, then re-check:**

Run these checks as active verification steps, not a passive checklist. Each layer is a gate: if any check fails, fix the issue before proceeding to the next layer.

**Layer 1: Schema** — required fields present, valid YAML, station positions within journey zone, no overlaps (50px min gap), no off-canvas content, `coordinate_system: "journey_zone_relative"`

**Layer 2: Message quality** — run these checks with explicit counts:
- Headlines: count characters per headline. Any over 50 → shorten. Count headlines with numbers → must be >= 80%.
- Body text: **count words per station body and record the counts.** Any under 100 → return to Step 5 and expand with source evidence. Any over 120 → trim. This is the single most common failure mode — do not skip the count.
- Narrative connections: count sentences per connection → must be 2-3 with visual detail.

**Layer 3: Visual coherence** — 4-8 stations, objects fit Story World, reading flow numbers progress spatially, scale variety (max 1 hero), consistent visual style

**Layer 4: Content integrity** — run these checks actively:
- **Umlaut scan (German only):** Search all text fields for the patterns `ae`, `oe`, `ue`, `ss` that should be `ä`, `ö`, `ü`, `ß`. Specifically check: governing_thought, title, subtitle, all station_labels, all headlines, all body texts, all CTAs, footer text. Common failures: `Kraefte`→`Kräfte`, `Kapazitaet`→`Kapazität`, `Flughaefen`→`Flughäfen`, `Maerz`→`März`, `waechst`→`wächst`, `Mobilitaet`→`Mobilität`. If ANY umlaut substitution is found, fix it before writing.
- **Governing thought:** Verify it is exactly ONE sentence (one period at the end). If multi-sentence, rewrite per Step 2 rules.
- **Synthesis label:** If any station has arc_role `call-to-action` or spans multiple dimensions, verify it has station_label `"Synthese"` (de) or `"Synthesis"` (en).
- All major narrative sections represented, numbers formatted per language.

**Output path resolution** (run via Bash before writing):
- If `output_path` explicitly provided: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/big-picture-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

The `cogni-visual/` subdirectory keeps generated briefs separate from source narratives.

**Write the brief** following EXAMPLE_BIG_PICTURE_BRIEF.md format. YAML frontmatter must include: type (`big-picture-brief`), version (`3.0`), theme, theme_path, canvas_size, canvas_pixels, story_world (name/type/description), visual_style, roughness, arc_type, arc_id (if resolved), governing_thought, language, max_stations, confidence_score. All stations with headline, body, reading_flow_number, text_placement, landscape_object, arc_role, position.

**Generation metadata** section at end must include: word count per station body (e.g., "Station body words: S1=108, S2=115, S3=103, S4=112, S5=106 | avg 109"), data points used vs source total, and umlaut check result.

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **01-story-worlds.md** | 3 | Story World brainstorming, classic worlds, industry vocabularies, scoring |
| **02-station-architecture.md** | 2, 4 | Arc-to-space mapping, station decomposition, station-as-landscape-object |
| **04-text-station-copy.md** | 5 | Headlines, body text, number plays for stations |
| **05-validation.md** | 7 | Four-layer validation framework |

### Libraries (loaded as needed)

| Library | Step | Purpose |
|---------|------|---------|
| **arc-taxonomy.md** | 1 | Arc ID → visual arc type mapping, element names |
| **big-picture-layouts.md** | 1, 6 | Canvas dimensions, zones, station positioning |
| **cta-taxonomy.md** | 5b | CTA types, urgency, arc-to-CTA heuristics |
| **EXAMPLE_BIG_PICTURE_BRIEF.md** | 7 | Output format reference |
