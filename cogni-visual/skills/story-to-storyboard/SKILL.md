---
name: story-to-storyboard
description: >
  Transform any narrative (insight summary, trend report, strategy document, sales pitch)
  into a multi-poster print storyboard brief for executive walkthroughs. Use this skill
  whenever the user mentions "storyboard", "poster series", "print posters from narrative",
  "Poster erstellen", "Storyboard aus Bericht", "Posterpraesentation", "Druckposter",
  "Poster fuer Workshop", "poster walkthrough", "create poster storyboard", "physical
  walkthrough posters", or wants to paginate a narrative into 3-5 portrait DIN A posters
  with stacked web sections. Also trigger for room-tour materials, guided exhibition posters,
  and arc-station-per-poster layouts in both English and German. Produces a storyboard-brief.md
  that the storyboard agent renders via Pencil MCP. Important: this skill CREATES the brief
  from a narrative source — it does NOT render an existing brief (use storyboard agent for
  that), does NOT create slides (use story-to-slides), does NOT create a single-canvas
  journey map (use story-to-big-picture), does NOT create a web page (use story-to-web),
  and does NOT polish prose (use Copywriter skill).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, AskUserQuestion
version: 0.7.0
---

# Story-to-Storyboard Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized storyboard brief that the Pencil MCP renderer can turn into a sequence of portrait poster storyboards. You are a **print storytelling architect**: analyze the narrative's argument structure, select a visual style guide, map arc stations to posters, decompose each poster into stacked web sections, and generate print-optimized copy and image prompts.

A storyboard is a physical walkthrough medium — each poster represents one arc station (Why Change, Why Now, Why You, Why Pay) containing 1-3 rich web section types stacked vertically. Posters reuse the same 10 section types as web narratives but paginate them into exactly 3-5 portrait DIN A posters. There are NO separate title or summary bookend posters — the first poster starts with a hero section and the last poster ends with a CTA section.

The brief describes WHAT each poster contains and which section types to use. All visual decisions (colors, fonts, spacing) are delegated to the Pencil renderer via the theme and style guide. Briefs contain no color fields.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | `smarter-service` | Theme ID from `/cogni-workplace/themes/{theme}/theme.md`. Use `auto` for interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` / `subtitle` | auto-detected | Extracted from narrative if not provided |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/storyboard-brief.md` | Brief output location |
| `poster_size` | `A1` | DIN format: A0, A1, A2, A3 (portrait only) |
| `max_posters` | `4` | Maximum poster count (3-5) |
| `conversion_goal` | `consultation` | CTA type: consultation, demo, download, trial, contact, calculate |
| `style_guide` | `auto` | Pre-selected style guide name. When provided, skip selection. |
| `industry` | `auto` | Industry context for image prompts and tag selection |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from cogni-narrative. Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become poster labels. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `governing_thought` | auto-extracted | Pre-computed governing thought from caller |

**Poster sizes:** See `$CLAUDE_PLUGIN_ROOT/libraries/storyboard-layouts.md` for dimensions, section stacking, and portrait layout adaptations. See `$CLAUDE_PLUGIN_ROOT/libraries/web-layouts.md` for section type schemas.

---

## Conventions

These rules prevent the most common failure modes. They emerged from repeated test runs where the executing model broke interactive prompts, mangled German text, or injected visual fields.

### User Interaction

Interactive checkpoints let the user steer creative decisions. The structured format below ensures AskUserQuestion renders properly — unstructured prose produces empty prompts.

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

German posters are printed and displayed at executive walkthroughs. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout: ae->ä oe->ö ue->ü ss->ß. German number formatting: 2.661 (not 2,661).

### No Color Fields

Briefs contain ZERO visual fields: no `Background:`, `Text-Color:`, `Icon-Color:`. The Pencil renderer reads the theme and style guide directly.

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

Before reading content, initialize TodoWrite with workflow steps: Parse parameters, Read narrative, Select style guide, Map arc stations to posters, Decompose into sections, Write section copy, Propose CTAs, Poster preview, Validate, Write brief.

### Execution Protocol

Each step: mark todo `in_progress` -> verify previous output (entry gate) -> read reference file -> execute -> mark `completed`. Do NOT skip reference reads — each contains rules that prevent common errors.

---

### Step 1: Parse Parameters & Resolve Context

> **WHY:** Arc resolution and theme loading happen before reading the narrative because they shape how you interpret the story. A pre-resolved arc_type tells you what poster structure to look for.

Determine input type (directory with metadata vs single file) and load metadata.

**Arc resolution** (priority order):
1. `arc_id` parameter → use directly
2. Source narrative frontmatter `arc_id` → extract
3. Neither → Step 2 auto-detects

If arc_id set: read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`, map to arc_type. Mapped arc_type overrides `arc_type` parameter. If `arc_definition_path` provided: extract element names and translations for poster labels.

**Theme resolution:** If interactive and theme not explicitly set: scan `themes/*/theme.md`, present via AskUserQuestion (max 4 options). Otherwise use provided theme or default. Read theme.md, store absolute path.

**Load libraries:** `storyboard-layouts.md`, `web-layouts.md`, `EXAMPLE_STORYBOARD_BRIEF.md`, `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set).

Resolve poster dimensions from `poster_size` using `storyboard-layouts.md` dimension system (portrait only).

---

### Step 2: Read Narrative & Analyze Story Arc

> **WHY:** The governing thought and arc type cascade through everything downstream — poster architecture, section decomposition, copy direction, and CTA proposals. Getting them right here prevents rework in later steps.

Read all source files. Extract governing thought (single sentence).

**Arc type resolution** (priority order):
1. **Pre-resolved from Step 1:** If `arc_context` was populated, use mapped `arc_type` directly.
2. **Caller-provided `arc_type`:** If set (not `auto`), use directly.
3. **Auto-detect:** Detect from narrative content.

**Key difference from other skills:** The arc type influences *poster count and arc-station-to-poster mapping* rather than slide order (slides) or section type (web).

**Output:** Tagged narrative with arc type, governing thought, section roles, and evidence inventory.

---

### Step 3: Select Style Guide (INTERACTIVE)

> **WHY:** The style guide determines the visual personality of every poster — typography weight, illustration approach, color usage patterns. Selecting it before decomposition ensures consistent design language.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/skills/story-to-web/references/01-style-guide-selection.md`

If `style_guide` parameter provided (not `auto`): skip selection, use directly.

Otherwise:
1. Call Pencil MCP `get_style_guide_tags()` to retrieve available tags
2. Select 5-10 tags based on theme, tone, industry, arc type. Always include `"website"` first (storyboards reuse web visual system). Reject `mobile-*` guides.
3. Call Pencil MCP `get_style_guide(tags)` to retrieve candidates
4. Score candidates using weighted algorithm in reference file

If interactive: present top 2-3 via AskUserQuestion (score + 1-sentence why). On empty response, auto-select top.

**Output:** Selected style guide name.

---

### Step 4: Map Arc Stations to Posters

> **WHY:** This is the core intelligence step. The poster count and station-to-poster mapping determine the storyboard's narrative rhythm. Too few posters compress the argument; too many dilute it. The arc templates provide proven structures that match how audiences process sequential arguments during a physical walkthrough.

**Read reference:** `references/01-poster-architecture.md`

Determine how many posters (3-5) and which arc stations map to which posters.

**Hard constraints:**
- Total poster count 3-5, NEVER more than 5
- NO separate "title" or "summary" posters — every poster is a content poster
- First poster's first section is hero (this IS the title)
- Last poster's last section is cta (this IS the close)
- If decomposition yields >5 posters, MERGE related stations

**Mapping process:** Load arc type template from reference. Count narrative sections. Determine poster count by word count (< 800 → 3, 800-1500 → 4, > 1500 → 5), capped at `max_posters`. Map arc stations to posters, condensing if needed.

**Poster labels** (content-source-first, role-based fallback): If `arc_elements` available, check which H2 chapter content came from → match to arc element name. Fall back to role-based mapping. Use localized names per `language`. See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`.

**Self-check:** Count posters (3-5?). Any "title" or "summary" type posters? Remove and fold into first/last.

**Output:** Poster assignment plan with labels.

---

### Step 5: Decompose Each Poster into Stacked Sections

> **WHY:** Section type selection translates each poster's narrative content into the right visual container. A poster with 4 statistics needs a stat-row, not a text-block. Getting the section types right here means the renderer produces the intended visual impact without manual correction.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/skills/story-to-web/references/02-section-architecture.md`

For each poster, determine 1-3 web section types to stack vertically using the section type decision tree.

**Per poster:**
1. Walk content through the section type decision tree
2. Assign `section_theme` (hero→dark, stat-row/testimonial→dark, cta→accent, others→alternate light/light-alt)
3. Calculate height allocation from `storyboard-layouts.md` ratios (1 section→100%, 2→50/50 or 55/45, 3→40/30/30 or 35/35/30)
4. Apply portrait layout adaptations: stat-row→2x2 grid, feature-alternating→vertical stack, timeline→vertical steps
5. Validate minimum section heights

**Output:** Per poster: ordered sections with types, themes, height allocations.

---

### Step 6: Write Section Copy per Poster

> **WHY:** Poster copy must work at 1-2 meter reading distance during a physical walkthrough. This means shorter text, bolder assertions, and more impactful number plays than web or slide copy. The print-specific constraints in the reference files encode what works at poster scale.

**Read references:**
- `references/02-poster-copywriting.md` (print overrides)
- `$CLAUDE_PLUGIN_ROOT/skills/story-to-web/references/03-section-copywriting.md` (web copy base)
- `references/03-image-prompts.md` (print image prompts)

For each section within each poster, generate content per the section type's required fields (see `web-layouts.md` schemas). Key constraints:
- Headline: max 70 chars, assertion with verb
- Body: max 50 words, 2-3 sentences
- Image prompts: "print resolution, high detail" suffix
- Max 2 images per poster

**Output:** Complete section specifications with copy and image prompts.

---

### Step 6b: Propose CTAs

> **WHY:** Without explicit CTAs, the audience leaves the walkthrough impressed but without a next step. CTAs convert attention into action — the primary CTA gives the presenter something concrete to propose at the final poster.

**Entry gate:** Verify Step 6 outputs — all sections have headlines, copy, and image prompts.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

1. Extract implicit CTAs from narrative + generate from governing thought, arc type, hero numbers, `conversion_goal`
2. Per section (excluding hero): assign `cta.text` (max 50 chars, imperative verb), `cta.type` (explore/evaluate/commit/share), `cta.urgency`
3. Build `cta_summary`: 3-5 proposals, `primary_cta` = highest-urgency commit CTA matching `conversion_goal`

**Storyboard-specific:** CTAs guide the presenter's verbal delivery. Per-section CTAs appear as verbal prompts. Primary CTA drives the final poster's cta section.

If interactive: present CTA plan via AskUserQuestion (Approve/Adjust, with primary_cta in question text). On empty response, treat as approval.

**Output:** Per-section CTA assignments and CTA summary block.

---

### Step 7: Poster Preview Checkpoint

> **WHY:** The poster plan is the last structural checkpoint before final validation. Catching composition errors here (wrong section types, missing arc stations, bad poster count) is far cheaper than fixing them after the full brief is generated.

**If interactive:**

First, output the poster plan table as a regular message:

```
| Poster | Label | Sections | Section Types |
|--------|-------|----------|---------------|
| 1/N | {label} | 2 | hero (dark) + problem-statement (light) |
| ... | ... | ... | ... |

Size: {poster_size} portrait | Posters: {count} | Style: {style_guide} | Arc: {arc_id or arc_type}
SELF-CHECK: Total posters = {count}. Must be 3-5.
```

Then present via AskUserQuestion (Approve/Adjust). On empty response, treat as approval.

**If not interactive:** Skip — auto-proceed.

---

### Step 8: Validate (Hybrid Web + Print)

> **WHY:** Self-assessment is unreliable without explicit measurement. In early tests, models reported "pass" while producing topic-label headlines and violating poster count constraints. The four-layer gate plus print checks force honest evaluation.

**Read reference:** `references/04-validation.md`

Four layers — stop on first failure, fix, re-check:
1. **Schema** — required fields, valid YAML, section type validity, sequence format
2. **Message quality** — assertion headlines, number plays, body text limits
3. **Visual coherence** — section theme rhythm, type variety, image consistency
4. **Content integrity** — all narrative sections represented, language consistency

**Print-specific checks:** poster count 3-5, section minimum heights, font size minimums, contiguous sequence numbers, hero first, CTA last, max 2 images per poster.

---

### Step 9: Write storyboard-brief.md

> **WHY:** The output path convention keeps generated briefs separate from source narratives in a `cogni-visual/` subdirectory, preventing clutter and making it easy for downstream agents to find the brief.

**Output path resolution** (run via Bash before writing):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/storyboard-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

Generate the final brief with YAML frontmatter and poster specifications following `EXAMPLE_STORYBOARD_BRIEF.md` format. Write using Write tool.

**Final checks:**
- YAML frontmatter complete (type, version, theme, style_guide, poster_size, arc_id)
- Each poster has poster_label, sequence "N/M", and 1-3 sections
- First poster starts with hero, last ends with cta
- All section types have required fields per web-layouts.md
- Image prompts present for hero and feature-alternating sections
- CTA summary block present
- Generation metadata populated
- Zero color fields in entire document

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **story-to-web/01-style-guide-selection.md** | 3 | Tag scoring algorithm, theme-to-tag mapping |
| **01-poster-architecture.md** | 4 | Arc-to-poster mapping, section stacking, poster templates |
| **story-to-web/02-section-architecture.md** | 5 | Section type decision tree, decomposition rules |
| **02-poster-copywriting.md** | 6 | Print headline rules, body constraints, number plays |
| **story-to-web/03-section-copywriting.md** | 6 | Web copywriting rules (base for poster copy) |
| **03-image-prompts.md** | 6 | Print-resolution prompt patterns, image count constraints |
| **cta-taxonomy.md** (library) | 6b | CTA types, urgency levels, arc-to-CTA heuristics |
| **04-validation.md** | 8 | Hybrid web + print validation framework |

### Libraries (loaded in Step 1)

| Library | Purpose |
|---------|---------|
| **storyboard-layouts.md** | Poster dimensions, section stacking, portrait adaptations |
| **web-layouts.md** | Section type schemas, typography, spacing |
| **EXAMPLE_STORYBOARD_BRIEF.md** | Complete output format reference |
