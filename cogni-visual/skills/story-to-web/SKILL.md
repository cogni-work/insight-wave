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
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
version: 0.5.0
---

# Story-to-Web Skill

## Purpose

Read any narrative document with an existing story arc and produce an optimized web-brief that the Pencil MCP renderer can turn into a scrollable landing-page-style .pen file. You are a **web storytelling architect**: analyze the narrative's argument structure, select a visual style guide, decompose the story into web sections, and generate copy and image prompts for each section.

A web narrative is not a slide deck pasted into a tall page. It is a scroll-driven reading experience where each section has ONE clear message, supported by visual hierarchy that guides the reader toward a conversion action. Sections alternate between light and dark to create visual rhythm. This matters because walls of undifferentiated text lose readers within seconds — alternating visual weight creates natural pause points that let each message land before the next begins.

## Architecture

Two-layer intelligence:
1. **Story Arc Analysis** — read narrative, identify argument structure, extract governing thought, build audience model, map section roles
2. **Section Specification + Web Copywriting** — section type selection, assertion headlines, scroll-optimized copy, image prompts, CTA proposals, visual rhythm enforcement

The brief describes WHAT each section says and which section type to use. The Pencil renderer owns all visual decisions (colors, fonts, spacing) by reading the theme directly — briefs contain no color fields.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `source_path` | auto-discovered | Narrative file or directory. When omitted with `interactive=true`, Step 0 searches nearby. |
| `theme` | interactive | Absolute path to theme.md, or omit to trigger `cogni-workspace:pick-theme` interactive selection. |
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
| `audience_context` | none | Structured audience/buyer data for targeted section ordering and CTA calibration. |

### Caller-supplied overrides

These are typically set by an upstream agent (e.g., why-change-work), not by a human user:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `confidence_threshold` | `0.8` | Minimum confidence for automatic section-type mapping |
| `governing_thought` | auto-extracted | Pre-computed governing thought — Step 2 validates rather than re-derives. |
| `section_roles` | auto-detected | Pre-mapped section roles — Step 2 validates rather than re-derives. |
| `buyer_appendix_path` | none | Path to buyer-appendix.md for enriched audience model (Step 3 only). |

---

## Conventions

### Theme-driven visuals

The Pencil renderer owns all visual decisions — colors, fonts, spacing — by reading the theme directly. Briefs specify content and section type only. Omit visual fields (`Background:`, `Text-Color:`, `Icon-Color:`) because the renderer ignores them and their presence creates ambiguity about who controls styling.

### Interactive checkpoints

Interactive prompts let the user steer creative decisions without micromanaging. The structured format below ensures AskUserQuestion renders properly — unstructured prose produces empty prompts:

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

German web narratives go to executives and get embedded in reports. ASCII-ified umlauts (`ae`/`oe`/`ue`) immediately signal "machine-generated" and undermine credibility. Use real Unicode throughout: ae->ä oe->ö ue->ü ss->ß. German number formatting: 2.661 (dot as thousands separator).

---

## Quick Reference: Good vs Bad Output

**Headlines** — assert, don't label:
- Bad: "Our Approach" (topic label — reader must scroll through the section to get the point)
- Good: "AI-Powered Monitoring Cuts Response Time from Hours to Seconds" (assertion — message lands instantly)

**Number plays** — reframe for impact:
- Bad: "There were 688 incidents in 2023" (buried in body text)
- Good: Hero number `688` isolated in stat-row, sublabel `+ 2,661 related events`, supporting text explains scale

**Bullets** — scan-optimized, not sentences:
- Bad: "The security staff are unable to adequately cover all areas of the network on a 24/7 basis" (19 words)
- Good: "Staff cannot cover all areas 24/7" (6 words, max 10 words per bullet)

**CTAs** — imperative verb, not passive label:
- Bad: "Contact Us" (generic, no urgency)
- Good: "Schedule Your Security Assessment" (specific action tied to conversion goal)

---

## Workflow

When invoked without explicit parameters, search the filesystem first (Step 0) rather than prompting for paths. Users invoke this skill from project directories that already contain their narrative — asking for a path they're sitting next to creates unnecessary friction.

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

> Arc resolution and theme loading happen before reading the narrative because they shape how you interpret the story — a pre-resolved arc_type tells you what section pattern to look for.

Determine input type (directory with metadata vs single file) and load metadata.

**Arc resolution** (priority order):
1. `arc_id` parameter -> use directly
2. Source narrative frontmatter `arc_id` -> extract
3. Neither -> Step 2 auto-detects

If arc_id set: read `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md`, map to arc_type. Mapped arc_type overrides `arc_type` parameter. If `arc_definition_path` provided: extract element names and translations for section labels.

**Theme resolution:** Delegate to `cogni-workspace:pick-theme` — the ecosystem-standard theme picker.

1. If `theme` parameter was explicitly provided with an absolute path: use it directly, skip the picker.
2. Otherwise: invoke the `cogni-workspace:pick-theme` skill via the Skill tool. The picker scans standard and workspace theme directories, presents an interactive AskUserQuestion, and returns the absolute `theme_path`.
3. Store the returned `theme_path` (absolute path to `theme.md`), `theme_name`, and `theme_slug` for downstream use.
4. Read the selected `theme.md` to confirm it loads correctly.

If pick-theme is unavailable (e.g., cogni-workspace not installed), fall back to Glob scanning `$COGNI_WORKSPACE_ROOT/themes/*/theme.md` and present via AskUserQuestion manually.

> **Path convention:** The `theme_path` stored in the brief frontmatter must be the **absolute filesystem path** to the theme.md file, so the renderer agent can read it without path resolution ambiguity.

**Provider/customer resolution:** Extract `provider_name` and `customer_name` from source metadata. If not found in the source file's frontmatter, search parent and sibling directories for files with `provider:` or `customer:` fields (e.g., sales-presentation.md, pitch-log.json). If still not found, leave empty — never default to the theme name.

**Load libraries:** `web-layouts.md`, `EXAMPLE_WEB_BRIEF.md`, `cta-taxonomy.md`, `arc-taxonomy.md` (if arc_id set), theme.md.

---

### Step 2: Read Narrative & Analyze Story Arc

> The governing thought and arc type cascade through everything downstream. Getting them right here prevents rework.

**Read reference:** `references/02-section-architecture.md` (Arc-to-Section Mapping section)

Read all source files. Extract governing thought.

**Arc type resolution** (priority order):
1. **Pre-resolved from Step 1:** If `arc_context` was populated, use mapped `arc_type` directly. Validate against content but prefer pre-resolved value.
2. **Caller-provided `arc_type`:** If set (not `auto`), use directly.
3. **Auto-detect:** Detect from narrative content. For detailed rules, read `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/03-story-arc-analysis.md` if available.

When caller provides `governing_thought`/`section_roles`: validate against narrative rather than re-deriving. Accept if valid, re-derive if narrative contradicts.

**Content checkpoint:** State arc type, governing thought, section count estimate.

---

### Step 3: Build Audience Model

> The audience model shapes how downstream steps order sections, frame headlines, and calibrate CTA urgency — Rich mode enables targeted prioritization, Lean mode infers from narrative vocabulary.

**Read reference:** `$CLAUDE_PLUGIN_ROOT/skills/story-to-slides/references/02-audience-model.md`

Build Audience Model: Rich mode (from `audience_context`, `buyer_appendix_path`, or pitch-log.json) or Lean mode (inferred from narrative). Identify primary decision-maker, priorities, objections.

**Web-specific usage** (differs from slides):
- **Section ordering:** Decision-maker priorities surface earlier in scroll sequence
- **Headline framing:** Technical audience = precise language; executive = business impact language
- **CTA urgency calibration:** Known champion -> higher urgency; known blockers -> address objections before CTA
- **Body text depth:** Expert audience = fewer words, more data; general audience = more context

**Content checkpoint:** State mode, confidence, decision-maker, top priority, top objection.

---

### Step 4: Select Style Guide (INTERACTIVE)

> The style guide determines every section's visual personality. Selecting it before decomposition ensures consistent design language.

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

### Step 5: Decompose Narrative into Sections

> Section decomposition is the structural backbone. Each section maps to a part of the story arc and gets a section type that determines its visual container.

**Read reference:** `references/02-section-architecture.md`

Break the narrative into 6-10 sections (capped by `max_sections`). Each section maps to a part of the story arc and has a section type.

For each section:
1. Determine arc role (hook, problem, urgency, solution, proof, roadmap, CTA)
2. Map arc role to section type using arc-to-section mapping
3. **Score mapping confidence** (0.0-1.0) and record it in each section's YAML as `confidence: 0.XX`. Primary section type with strong evidence = high (0.9+). Alternate type or ambiguous mapping = medium (0.7-0.8). No clear match = low (<0.7). Flag mappings below `confidence_threshold` for manual review.
4. Assign `section_theme` (dark/light/light-alt/accent)
5. Identify hero message and key data points
6. Enforce bookend rules (hero first, CTA last)
7. Set feature-alternating positions (odd/even)
8. Assign `section_label` (content-source-first, role-based fallback):
   - If arc_elements available: check which narrative H2 chapter content came from -> match to arc element name (content-source method). Fall back to role-based mapping for intro/synthesized content. Use localized names per `language`. See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for full heuristic.
   - If no arc_elements: use generic role-based labels (e.g., "Das Problem", "Die Losung", "Der Weg")

**Content checkpoint:** State section count, section types used, theme alternation pattern, any low-confidence mappings.

---

### Step 6: Write Section Copy & Image Prompts

> Web copy must work in a scroll context where readers decide within 2 seconds whether to keep scrolling or bounce.

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

### Step 6b: Propose CTAs (INTERACTIVE)

> Without explicit CTAs, the reader scrolls to the bottom and leaves. CTAs convert attention into action.

**Entry gate:** Verify Step 6 outputs — all sections have assertion headlines, copy, and image prompts.

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

### Step 7: Section Preview Checkpoint (INTERACTIVE)

> The section plan is the last structural checkpoint before final validation. Catching errors here is cheaper than fixing the full brief.

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

### Step 8: Generate Header & Footer Content

> Header and footer provide the page's navigation frame and brand presence.

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

### Step 9: Validate Against Schema

> Self-assessment is unreliable without explicit measurement. The four-layer gate forces honest evaluation.

**Read reference:** `references/05-validation.md`

Four layers — stop on first failure, fix, re-check:

1. **Schema** — required fields present, valid YAML, correct section types
2. **Message quality** — assertion headlines, number plays, parallel bullets
3. **Visual coherence** — section theme alternation, feature position alternation, image consistency
4. **Content integrity** — all narrative sections represented, language consistency

---

### Step 10: Write web-brief.md

> The output path convention keeps briefs in `cogni-visual/` to prevent clutter.

**Output path resolution** (run via Bash before writing):
- If `output_path` explicit: `mkdir -p "$(dirname "${output_path}")"`
- Otherwise: set `output_path = {source_dir}/cogni-visual/web-brief.md` and `mkdir -p "{source_dir}/cogni-visual"`

Generate the final brief with YAML frontmatter and section specifications following `EXAMPLE_WEB_BRIEF.md` format. Write using Write tool.

**Final checks:**
- YAML frontmatter complete (type, version, theme, theme_path, style_guide, conversion_goal, arc_id if available, confidence_score as average of per-section scores)
- Header and footer sections present
- All sections specified with type, section_theme, arc_role, headline, confidence
- First section is hero (dark), last content section is CTA (accent)
- Image prompts present for hero and feature-alternating sections
- CTA summary block present
- Generation metadata populated
- Zero color fields in entire document

---

### Step 11: Generate Web Rendering Prompt

> The user needs a ready-to-use prompt for a fresh Claude chat with the web agent. Absolute paths make it self-contained.

After the brief is written and validated, **append** a rendering prompt section to the end of web-brief.md (after Generation Metadata), then also print it to the conversation so the user can copy it directly.

Use the absolute paths resolved during the workflow:

```markdown
---

## Rendering Prompt

Copy this prompt into a new Claude chat to render the web narrative:

> Please render a web narrative using:
> - Web brief: {absolute_path_to_web_brief}
> - Theme: {absolute_path_to_theme_md}
```

Replace `{absolute_path_to_web_brief}` with the resolved `output_path` and `{absolute_path_to_theme_md}` with the `theme_path` from Step 1.

Both paths must be absolute — never use `~`, `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or relative paths, because the receiving Claude session has no access to variables from this session.

---

## Bundled Resources

### References (loaded at specific steps — progressive disclosure)

| Reference | Step | Purpose |
|-----------|------|---------|
| **02-audience-model.md** (from story-to-slides) | 3 | Audience Model construction (Rich/Lean mode) |
| **01-style-guide-selection.md** | 4 | Tag scoring algorithm, theme-to-tag mapping |
| **02-section-architecture.md** | 2, 5 | Arc-to-section mapping, decomposition rules, section_theme alternation |
| **03-section-copywriting.md** | 6 | Web headline hierarchy, CTA copy patterns, number plays |
| **04-image-prompts.md** | 6 | Web image formats, hero bg+overlay pattern, stock vs AI guidance |
| **05-validation.md** | 9 | Four-layer validation framework |
| **cta-taxonomy.md** (library) | 6b | CTA types, urgency levels, arc-to-CTA heuristics |

### Libraries (loaded as needed)

| Library | Step | Purpose |
|---------|------|---------|
| **arc-taxonomy.md** | 1 | Arc ID -> visual arc type mapping, element names |
| **web-layouts.md** | 1 | Section type schemas, typography scale, spacing, theme-to-variable mapping |
| **cta-taxonomy.md** | 6b | CTA types, urgency, arc-to-CTA heuristics |
| **EXAMPLE_WEB_BRIEF.md** | 1 | Output format reference |
