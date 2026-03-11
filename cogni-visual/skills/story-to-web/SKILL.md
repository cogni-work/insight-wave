---
name: story-to-web
description: >
  Transform any narrative (insight summary, trend report, strategy document, sales pitch,
  project update) into an optimized scrollable web narrative brief that the web agent
  renders via Pencil MCP into a .pen file. Use this skill whenever the user mentions
  "web narrative", "landing page from narrative", "scrollable web page", "web story",
  "Webseite aus Bericht", "Landingpage erstellen", "Web-Narrative", "scrollbare Webseite",
  "create a web page from report", "single-page narrative", or wants to convert prose
  into a scroll-driven section architecture with design tokens and auto-layout. Also
  trigger when the user needs style guide selection, section type mapping, hero/CTA
  optimization, or image prompt generation for a web-format narrative. Covers Why Change
  projects, research reports, competitive intelligence, trend panoramas, and both English
  and German output. Produces a web-brief.md that the web agent renders. Important: this
  skill CREATES the brief from a narrative source — it does NOT render an existing brief
  (use web agent for that), does NOT create slides (use story-to-slides), does NOT create
  a single-canvas poster (use story-to-big-picture), does NOT create print storyboard
  posters (use story-to-storyboard), and does NOT polish prose (use Copywriter skill).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, AskUserQuestion
version: 0.4.0
---

# Story-to-Web Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized web-brief that the Pencil MCP renderer can turn into a scrollable landing-page-style .pen file. You are a **web storytelling architect**: analyze the narrative's argument structure, select a visual style guide, decompose the story into web sections, and generate copy and image prompts for each section.

A web narrative is not a slide deck pasted into a tall page. It is a scroll-driven reading experience where each section has ONE clear message, supported by visual hierarchy that guides the reader toward a conversion action. Sections alternate between light and dark to create visual rhythm. This matters because walls of undifferentiated text lose readers within seconds — alternating visual weight creates natural pause points that let each message land before the next begins.

The brief describes WHAT each section says and which section type to use. All visual decisions (colors, fonts, spacing) are delegated to the Pencil renderer via the theme and style guide. Briefs contain no color fields.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | `smarter-service` | Theme ID from `/cogni-workplace/themes/{theme}/theme.md`. Use `auto` for interactive selection. |
| `language` | `en` | Language code (en/de) |
| `title` | auto-detected | Web page title (extracted from narrative if not provided) |
| `customer_name` / `provider_name` | from metadata | Organization names |
| `output_path` | `{source_dir}/cogni-visual/web-brief.md` | Brief output location |
| `conversion_goal` | `consultation` | CTA type: consultation, demo, download, trial, contact, calculate |
| `max_sections` | `10` | Maximum section count (forces consolidation if narrative is long) |
| `style_guide` | `auto` | Pre-selected style guide name. When provided, skip selection. |
| `arc_type` | `auto` | Story arc hint: why-change, problem-solution, journey, argument, report |
| `arc_id` | from frontmatter | Narrative arc ID from cogni-narrative. Mapped to visual `arc_type` in Step 1. |
| `arc_definition_path` | none | Path to arc definition file — element names become `section_label` values. |
| `interactive` | `true` | When `true`, present choices via AskUserQuestion. When `false`, auto-select. |
| `governing_thought` | auto-extracted | Pre-computed governing thought from caller |

---

## Conventions

These three rules prevent the most common failure modes. They emerged from repeated test runs where the executing model broke interactive prompts, mangled German text, or injected visual fields into the brief.

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

German web narratives are shared with executives and embedded in reports. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout: ae->ä oe->ö ue->ü ss->ß. German number formatting: 2.661 (not 2,661).

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

Before reading content, initialize TodoWrite with workflow steps: Parse parameters, Read narrative, Select style guide, Decompose into sections, Write section copy, Propose CTAs, Section preview, Generate header/footer, Validate, Write brief.

### Execution Protocol

Each step: mark todo `in_progress` -> verify previous output (entry gate) -> read reference file -> execute -> mark `completed`. Do NOT skip reference reads — each contains rules that prevent common errors.

---

### Step 1: Parse Parameters & Resolve Context

> **WHY:** Arc resolution and theme loading happen before reading the narrative because they shape how you interpret the story. A pre-resolved arc_type tells you what section pattern to look for; a loaded style guide drives the visual system.

Determine input type (directory with metadata vs single file) and load metadata.

**Arc resolution** (priority order):
1. `arc_id` parameter → use directly
2. Source narrative frontmatter `arc_id` → extract
3. Neither → Step 2 auto-detects

If arc_id set: read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`, map to arc_type. Mapped arc_type overrides `arc_type` parameter. If `arc_definition_path` provided: extract element names and translations for section labels.

**Theme resolution:** If interactive and theme not explicitly set: scan `themes/*/theme.md`, present via AskUserQuestion (max 4 options with name, description, primary color). Otherwise use provided theme or default. Read theme.md, store absolute path.

> **Path convention:** The `theme_path` stored in the brief frontmatter must be the **absolute filesystem path** to the theme.md file, so the renderer agent can read it without path resolution ambiguity.

**Load libraries:** `web-layouts.md`, `EXAMPLE_WEB_BRIEF.md`, `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set), theme.md.

---

### Step 2: Read Narrative & Analyze Story Arc

> **WHY:** The governing thought and arc type cascade through everything downstream — section architecture, copy direction, CTA proposals. Getting them right here prevents rework in later steps.

**Read reference:** `references/02-section-architecture.md` (Arc-to-Section Mapping section)

Read all source files. Extract governing thought.

**Arc type resolution** (priority order):
1. **Pre-resolved from Step 1:** If `arc_context` was populated, use mapped `arc_type` directly. Validate against content but prefer pre-resolved value.
2. **Caller-provided `arc_type`:** If set (not `auto`), use directly.
3. **Auto-detect:** Detect from narrative content. For detailed rules, read `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/03-story-arc-analysis.md` if available.

**Key difference from slides:** The arc type influences *section type selection and visual rhythm* rather than slide order.

**Output:** Tagged narrative with arc type, governing thought, and section roles.

---

### Step 3: Select Style Guide (INTERACTIVE)

> **WHY:** The style guide determines the visual personality of every section — typography weight, illustration approach, color usage patterns. Selecting it before decomposition ensures consistent design language across all sections.

**Read reference:** `references/01-style-guide-selection.md`

If `style_guide` parameter provided (not `auto`): skip selection, use directly.

Otherwise:
1. Call Pencil MCP `get_style_guide_tags()` to retrieve available tags
2. Select 5-10 tags based on theme, tone, industry, arc type
3. Call Pencil MCP `get_style_guide(tags)` to retrieve candidates
4. Score candidates using weighted algorithm in reference file

If interactive: present top 2-3 via AskUserQuestion (score + 1-sentence why). On empty response, auto-select top.

**Output:** Selected style guide name.

---

### Step 4: Decompose Narrative into Sections

> **WHY:** Section decomposition is the structural backbone of the web narrative. Each section maps to a part of the story arc and gets a section type that determines its visual container. Getting the type-to-role mapping right here means the renderer produces the intended visual impact without manual correction.

**Read reference:** `references/02-section-architecture.md`

Break the narrative into 6-10 sections (capped by `max_sections`). Each section maps to a part of the story arc and has a section type.

For each section:
1. Determine arc role (hook, problem, urgency, solution, proof, roadmap, CTA)
2. Map arc role to section type using arc-to-section mapping
3. Assign `section_theme` (dark/light/light-alt/accent)
4. Identify hero message and key data points
5. Enforce bookend rules (hero first, CTA last)
6. Set feature-alternating positions (odd/even)
7. Assign `section_label` (content-source-first, role-based fallback):
   - If arc_elements available: check which narrative H2 chapter content came from → match to arc element name (content-source method). Fall back to role-based mapping for intro/synthesized content. Use localized names per `language`. See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for full heuristic.
   - If no arc_elements: use generic role-based labels (e.g., "Das Problem", "Die Lösung", "Der Weg")

**Output:** Ordered section list with types, themes, messages, and evidence inventory.

---

### Step 5: Write Section Copy & Image Prompts

> **WHY:** Web copy must work in a scroll context where readers decide within 2 seconds whether to keep scrolling or bounce. Assertion headlines deliver the message instantly; number plays make statistics memorable; image prompts ensure the visual layer reinforces rather than decorates.

**Read references:**
- `references/03-section-copywriting.md`
- `references/04-image-prompts.md`

For each section, generate:

1. **Assertion headline** (max 70 chars — longer than big-picture for web readability)
2. **Body text** or **bullets** (per section type constraints)
3. **Stat numbers** with reframed number plays (where applicable)
4. **Image prompt** (for hero background, feature images — per section type)
5. **Section label** (optional, per arc role)
6. **CTA text** matching `conversion_goal` (for hero and CTA sections)

**Output:** Complete section specifications with copy and image prompts.

---

### Step 5b: Propose CTAs (INTERACTIVE)

> **WHY:** Without explicit CTAs, the reader scrolls to the bottom and leaves. CTAs convert attention into action — the primary CTA gives the page a concrete conversion endpoint. Per-section micro-CTAs create multiple entry points for engagement.

**Entry gate:** Verify Step 5 outputs — all sections have assertion headlines, copy, and image prompts.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/libraries/cta-taxonomy.md`

1. Extract implicit CTAs from narrative + generate from governing thought, arc type, hero numbers, `conversion_goal`
2. Per section: assign `cta.text` (max 50 chars, imperative verb), `cta.type` (explore/evaluate/commit/share), `cta.urgency` (low/medium/high)
3. Build `cta_summary`: 3-5 proposals, `primary_cta` = highest-urgency commit CTA matching `conversion_goal`

**Web-specific CTA rendering:**
- `commit` CTAs -> rendered as buttons in hero and CTA sections
- `evaluate` CTAs -> rendered as secondary buttons or highlighted links
- `explore` and `share` CTAs -> rendered as text links within section copy

If interactive: present CTA plan via AskUserQuestion (Approve/Adjust, with primary_cta in question text). On empty response, treat as approval.

**Output:** Per-section CTA assignments and CTA summary block.

---

### Step 6: Section Preview Checkpoint (INTERACTIVE)

> **WHY:** The section plan is the last structural checkpoint before final validation. Catching composition errors here (wrong section types, missing arc stations, bad theme alternation) is far cheaper than fixing them after the full brief is generated.

If interactive:

First, output the section plan table as a regular message:

```
| # | Type | Theme | Headline | Arc Role | Section Label |
|---|------|-------|----------|----------|---------------|
| 1 | hero | dark | {headline} | hook | -- |
| 2 | problem-statement | light | {headline} | problem | {label} |
| ... | ... | ... | ... | ... | ... |

Style guide: {name} | Sections: {count} | Arc: {arc_id or arc_type} | CTA: {cta_text}
```

Then present via AskUserQuestion (Approve/Adjust). On empty response, treat as approval.

If not interactive: skip this checkpoint.

---

### Step 7: Generate Header & Footer Content

> **WHY:** Header and footer provide the page's navigation frame and brand presence. Generating them from metadata ensures consistency with the theme without requiring the user to specify boilerplate.

Generate header and footer content based on metadata:

```yaml
header:
  logo_text: "{provider_name}"
  cta_text: "{cta_text from conversion_goal}"

footer:
  company_name: "{provider_name}"
  copyright: "{year} {provider_name}"
  provider: "{provider_description or empty}"
  date: "{month year in language}"
```

---

### Step 8: Validate Against Schema

> **WHY:** Self-assessment is unreliable without explicit measurement. In early tests, models reported "pass" while producing topic-label headlines and missing image prompts. The four-layer gate forces honest evaluation.

**Read reference:** `references/05-validation.md`

Four layers — stop on first failure, fix, re-check:

1. **Schema** — required fields present, valid YAML, correct section types
2. **Message quality** — assertion headlines, number plays, parallel bullets
3. **Visual coherence** — section theme alternation, feature position alternation, image consistency
4. **Content integrity** — all narrative sections represented, language consistency

---

### Step 9: Write web-brief.md

> **WHY:** The output path convention keeps generated briefs separate from source narratives in a `cogni-visual/` subdirectory, preventing clutter and making it easy for downstream agents to find the brief.

**Output path resolution** (run via Bash before writing):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/web-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

Generate the final brief with YAML frontmatter and section specifications following `EXAMPLE_WEB_BRIEF.md` format. Write using Write tool.

**Final checks:**
- YAML frontmatter complete (type, version, theme, style_guide, conversion_goal, arc_id if available)
- Header and footer sections present
- All sections specified with type, section_theme, arc_role, headline
- First section is hero (dark), last content section is CTA (accent)
- Image prompts present for hero and feature-alternating sections
- CTA summary block present
- Generation metadata populated
- Zero color fields in entire document

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **01-style-guide-selection.md** | 3 | Tag scoring algorithm, theme-to-tag mapping |
| **02-section-architecture.md** | 2, 4 | Arc-to-section mapping, decomposition rules, section_theme alternation |
| **03-section-copywriting.md** | 5 | Web headline hierarchy, CTA copy patterns, number plays |
| **04-image-prompts.md** | 5 | Web image formats, hero bg+overlay pattern, stock vs AI guidance |
| **05-validation.md** | 8 | Four-layer validation framework |
| **cta-taxonomy.md** (library) | 5b | CTA types, urgency levels, arc-to-CTA heuristics |

### Libraries (loaded in Step 1)

| Library | Purpose |
|---------|---------|
| **web-layouts.md** | Section type schemas, typography scale, spacing, theme-to-variable mapping |
| **EXAMPLE_WEB_BRIEF.md** | Complete output format reference |
