---
name: render-html-slides
description: >
  Render a presentation-brief.md into a self-contained HTML slide presentation
  with speaker notes toggle, keyboard navigation, themed styling, and Mermaid diagram
  support. After rendering, supports an interactive refinement loop where users can
  adjust individual slides — text fixes are applied directly to HTML, structural changes
  trigger a targeted re-render. Use this skill whenever the user mentions "HTML slides",
  "HTML presentation", "browser presentation", "render slides as HTML", "self-contained
  slides", "slide deck in browser", "web slides", "present in browser", or wants a
  presentation without PowerPoint. Also use when the user asks to "open slides in
  browser", "export slides as HTML", "refine slides", "adjust slide", "fix slide",
  or says "no PowerPoint". Works with any presentation-brief.md that meets the brief
  contract in libraries/brief-pipeline.md, hand-authored or caller-supplied.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Skill
---

# Render HTML Slides

Transform a presentation-brief.md into a stunning, self-contained HTML slide deck
that runs in any browser. Themed styling, keyboard navigation, smooth transitions,
speaker notes panel, Mermaid diagram rendering, touch swipe support, and print mode —
all in a single `.html` file.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `brief_path` | auto-discovered | Path to presentation-brief.md |
| `theme` | from brief frontmatter | Path to theme.md (or omit to select one through manage-themes) |
| `design_variables` | derived from theme | Pre-computed design-variables.json path |
| `output_path` | `{brief_dir}/{slug}-slides.html` | HTML output path. `{slug}` is the deck title Phase 1 assembles into `metadata.title`, lowercased with every run of non-alphanumerics collapsed to a single `-`. |
| `transition` | `fade` | Slide transition: `fade`, `slide`, `none` |
| `aspect_ratio` | `16:9` | Slide aspect ratio: `16:9`, `4:3` |
| `language` | from brief frontmatter | `en` or `de` |
| `max_refinements` | `3` | Max refinement rounds after rendering (0 = skip refinement) |
| `theme_slug` | `` (off) | Optional Theme System v2 slug (e.g. `cogni-work`). When set, imports `tokens.css` from the resolved tiered theme. Omit for byte-equivalent legacy output. See the Theme System v2 subsection in Phase 3 and `${CLAUDE_PLUGIN_ROOT}/references/theme-component-loader.md`. |
| `themes_dir` | auto-discovered | Override the workspace `themes/` directory used to resolve `theme_slug`. Default: `$COGNI_WORKSPACE_ROOT/themes`, then auto-discovery. |

## Execution Protocol

### Phase 0: Brief Discovery & Setup

1. If `brief_path` provided, use it directly
2. Otherwise, glob for `**/presentation-brief.md` (max 3 levels deep)
3. If multiple found, present options via AskUserQuestion
4. Read the brief, validate frontmatter:
   - `type: presentation-brief` (must match)
   - `version: "4.0"` or `"4.1"` (must match one of these — the 4.1 delta is content-only, so nothing this renderer parses changed)
5. Extract metadata: `theme`, `theme_path`, `language`, `customer`, `provider`, `arc_type`, `governing_thought`
6. Resolve `brief_dir` — the project directory that *contains* `cogni-visual/`, which every artifact path below is anchored on. A brief discovered inside a `cogni-visual/` folder (where a brief lives by convention) resolves to that folder's **parent**, not the brief's own directory — otherwise `{brief_dir}/cogni-visual/` doubles the path. An explicit `brief_path` outside any `cogni-visual/` folder resolves to the brief's own directory.

**Theme resolution** (3-stage, same as enrich-report):
1. If `design_variables` parameter provided → use directly, skip to Phase 1
2. If `theme` parameter provided → read that theme.md
3. Otherwise read `theme_path` from brief frontmatter
4. If no theme found → invoke `cogni-workspace:manage-themes` (Operation 11, Select Theme) via Skill tool

### Phase 1: Brief Parsing

Parse the presentation-brief.md body into structured slide data. The brief uses `## Slide N: {headline}` sections with fenced YAML blocks.

**Parse deterministically.** Run the shared parser rather than reading the brief yourself — it is the same parser the other brief consumers use, so this renderer cannot drift away from them:

```bash
mkdir -p "{brief_dir}/cogni-visual"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/parse-brief.py" \
  --brief "{brief_path}" --emit slide-data \
  --output "{brief_dir}/cogni-visual/slide-data.json"
```

`mkdir -p` runs first because the parser opens `--output` directly without creating its parent.

`--brief` is required (omitting it exits with `--brief is required`). The `{"success": ..., "data": ..., "error": ...}` envelope prints on **stdout**, while `--output` writes only the payload (`{version, slides, warnings}`) to the file.

**Then add the `metadata` block.** `--emit slide-data` carries no `metadata` key, but the renderer reads `metadata.title` / `.customer` / `.provider` / `.generated` — skip this and every deck silently renders with the title "Presentation" and today's date. Run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/parse-brief.py" --brief "{brief_path}" --emit metadata
```

That returns `{version, frontmatter, generation_metadata, cta_summary, unowned_sections, warnings}` — a source to map from, not a ready-made block. Assemble `metadata` and merge it into the written JSON as a top-level key:

- `customer`, `provider`, `language`, `arc_type`, `governing_thought` — from `frontmatter`
- `generated` — from `frontmatter.generated`, else today's date
- `title` — slide 1's `fields.Title`, else slide 1's `headline` (the frontmatter carries no title)
- `subtitle` — slide 1's `fields.Subtitle`

Read `{brief_dir}/cogni-visual/slide-data.json` back, add the assembled `metadata` object as a
top-level key alongside `slides`, and write the file out again. Leaving the parser's own
`version` and `warnings` keys in place is harmless — the renderer reads only `metadata` and
`slides`. Surface any `warnings` to the user.

**Fall back to the LLM parse only when the parser fails to parse** — that is, when an envelope comes back with `success: false` for a parse reason, or the script cannot be run at all. A successful parse is authoritative and is never second-guessed or "corrected" by re-reading the brief.

**A `cannot write output:` envelope is not a parse failure and must not trigger the fallback.** Fix the write — the parent directory is missing or unwritable — and re-run. Falling back on it would hide the broken write behind a silently LLM-parsed deck, which is exactly the outcome the deterministic path exists to retire.

#### LLM fallback parse

Used only on the failure condition above. Parse the brief body directly.

For each slide section, extract:
- `number` — slide number
- `headline` — the assertion headline from the H2 heading
- `layout` — the Layout field value
- `fields` — all layout-specific fields as a nested object (preserving structure)
- `speaker_notes` — the Speaker-Notes field (multi-line string, preserve verbatim)
- `bottom_banner` — Bottom-Banner field if present
- `diagram_mermaid` — the Diagram field content if it contains Mermaid syntax
- `citations` — extracted `<sup>[N](url)</sup>` patterns

Also assemble the top-level `metadata` block by the same mapping the deterministic path uses
above — the renderer reads it on both paths, and omitting it carries the same silent
"Presentation"/today's-date default.

Run `mkdir -p "{brief_dir}/cogni-visual"` here too — this branch writes into the same directory
and must not depend on the deterministic block above having run. Then write the parsed data to
`{brief_dir}/cogni-visual/slide-data.json`, in the shape both paths share — see the
`slide-data.json shape` section of `references/01-layout-renderers.md`.

**Parsing rules:**
- Each slide is separated by `---` (horizontal rule) in the brief
- The YAML block is inside ``` fences — parse the YAML content
- Nested structures (Hero-Stat-Box, Context-Box, Detail-Grid) must be preserved as nested objects
- Speaker-Notes is a multi-line YAML string (after `|`) — preserve the full text
- Mermaid diagrams appear in the `Diagram:` field as multi-line strings
- IS/DOES/MEANS labels come from each box's `Label:` field — pass it through. The renderer prefers that `Label:` for the badge and falls back to its own `--language` localization only when it is absent
- Bottom-Banner can be a dict with a `Text:` key or a plain string. Write it to the **top-level** `bottom_banner` field, not inside `fields` (the legacy nested form is also accepted) — footer contract in `references/01-layout-renderers.md`.

### Phase 2: Theme → Design Variables

If `design_variables` path was not provided:

1. Read the theme.md file
2. Derive a `design-variables.json` with this structure:

```json
{
  "theme_name": "smarter-service",
  "colors": {
    "primary": "#111111",
    "secondary": "#333333",
    "accent": "#C8E62E",
    "accent_muted": "#A8C424",
    "accent_dark": "#8BA31E",
    "background": "#FAFAF8",
    "surface": "#F2F2EE",
    "surface2": "#E8E8E4",
    "surface_dark": "#111111",
    "border": "#E0E0DC",
    "text": "#111111",
    "text_light": "#FFFFFF",
    "text_muted": "#6B7280"
  },
  "status": {
    "success": "#2E7D32",
    "warning": "#E5A100",
    "danger": "#D32F2F",
    "info": "#1565C0"
  },
  "fonts": {
    "headers": "'Bricolage Grotesque', -apple-system, sans-serif",
    "body": "'Outfit', -apple-system, sans-serif",
    "mono": "'JetBrains Mono', monospace"
  },
  "google_fonts_import": "@import url('https://fonts.googleapis.com/css2?family=...');",
  "radius": "12px",
  "shadows": {
    "sm": "0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)",
    "md": "0 4px 16px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)",
    "lg": "0 12px 40px rgba(0,0,0,0.1), 0 4px 12px rgba(0,0,0,0.05)",
    "xl": "0 24px 64px rgba(0,0,0,0.14), 0 8px 20px rgba(0,0,0,0.06)"
  }
}
```

Extract all values from the theme.md. For any color not explicitly stated in the theme, derive sensible defaults:
- `accent_muted` — accent color darkened ~15%
- `accent_dark` — accent color darkened ~30%
- `surface2` — slightly darker than surface
- `surface_dark` — use primary or darkest color
- `border` — light gray matching surface tone

The schema matches `${CLAUDE_PLUGIN_ROOT}/skills/enrich-report/schemas/design-variables.schema.json`.

Write to `{brief_dir}/cogni-visual/design-variables.json`.

### Phase 3: HTML Generation

Run the Python generator script:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/render-html-slides/scripts/generate-html-slides.py" \
  --slide-data "{brief_dir}/cogni-visual/slide-data.json" \
  --design-variables "{brief_dir}/cogni-visual/design-variables.json" \
  --output "{output_path}" \
  --transition "{transition}" \
  --aspect-ratio "{aspect_ratio}" \
  --language "{language}" \
  ${theme_slug:+--theme-slug "$theme_slug"}
```

The script outputs JSON: `{"status": "ok", "path": "...", "slides": N, "size_kb": N.N, "theme_slug": "...", "tokens_css_imported": true|false, "theme_slug_resolution": "imported"|"<reason>"|null, "theme_slug_resolution_detail": "<hint>"|null}` or `{"error": "..."}`. The `--theme-slug` flag is optional — see the Theme System v2 subsection below for the fallback contract.

If error, read the error message and attempt to fix the input data. Common issues:
- Missing required fields in slide-data.json → re-parse the brief
- Invalid JSON in slide-data.json → fix and retry

#### Theme System v2 (tier-aware rendering)

Tier-1 tokens are wired: pass `theme_slug: cogni-work` to import that theme's canonical CSS custom properties. Tier-3 deck-component substitution is not: every layout renderer uses its inline template regardless of theme, because no shipped theme carries a `tiers.components.deck` family. The loader at `${CLAUDE_PLUGIN_ROOT}/scripts/load-theme-component.py` (see `${CLAUDE_PLUGIN_ROOT}/references/theme-component-loader.md`) is the probe a deck family would go through; a renderer that prefers theme-supplied primitives and falls back to inline on miss is the intended shape once one ships.

**Backwards-compat contract.** Omitting `--theme-slug` preserves the legacy (pre-Theme-System-v2) rendering path byte-for-byte — `theme.md`-derived design variables still apply; only the tier-1 `tokens.css` import is skipped. With `--theme-slug` set, themes without `tiers.tokens` (and tier-0 themes generally) exercise the same fallback path — there is no failure case for unmigrated themes. `evals/run.py` enforces this with dedicated regression cases — among them a tier-0 baseline, tier-1 cogni-work tokens.css imported, and tier-0 `_template` with `--theme-slug` set (graceful fallback).

**Fallback diagnostics.** When `--theme-slug` is set, the output envelope's `theme_slug_resolution` field names *why* the tier-1 path was (or wasn't) taken. It is always a **bare reason code** — exact-matchable: `imported` on success, or a fallback code — `manifest_missing` (tier-0 theme), `manifest_unreadable`, `tokens_tier_absent`, `tokens_css_missing`, or `themes_dir_unresolved` (workspace not found — e.g. `$COGNI_WORKSPACE_ROOT` unset or unexported). The field is `null` when `--theme-slug` is omitted. A companion `theme_slug_resolution_detail` field carries an optional human-readable hint for the cases that warrant one (today, `themes_dir_unresolved`); it is `null` otherwise. Machines branch on `theme_slug_resolution`; humans read `theme_slug_resolution_detail`. This distinguishes "this theme is tier-0" from "I couldn't find the workspace" without re-walking the resolution. Add `--verbose` to additionally write a one-line `themes_dir=… manifest_path=… tokens_css=… resolution=…` diagnostic (using the bare reason code) to stderr (off by default; the stdout JSON contract is unchanged).

### Phase 4: Validation

After successful generation, verify:

1. **Slide count**: The number of `<section class="slide">` elements in the HTML matches the slide count in the brief
2. **Speaker notes**: Every slide that had Speaker-Notes in the brief has a non-empty `<template class="slide-notes-data">` block
3. **Citations**: All `<sup>[N](url)</sup>` patterns from the brief appear as `<a class="citation">` elements in the HTML
4. **Mermaid**: If the brief contained Diagram fields with Mermaid syntax, the HTML includes the Mermaid CDN script tag and `<pre class="mermaid">` blocks
5. **Theme tokens**: The HTML contains `:root` CSS with design variable tokens

Read the generated HTML and spot-check these. If any fail, diagnose and fix.

### Phase 5: Output

1. Report the output path, slide count, file size, and theme name
2. If running in an environment with browser access, open the HTML file:
   ```bash
   open "{output_path}"
   ```
3. Tell the user about keyboard navigation:
   - Arrow keys / Space: navigate slides
   - **S**: toggle speaker notes panel
   - **F**: fullscreen mode
   - **?**: keyboard shortcuts help
   - Click right half to advance, left half to go back
   - Print with Ctrl+P for handout mode (slides + notes)

### Phase 6: Refinement Loop

After the user has seen the slides in the browser, offer an interactive refinement loop.
Skip this phase entirely if `max_refinements` is `0`.

#### Step 6.1: Gather Feedback

Ask via AskUserQuestion:

> "The slides are open in your browser. Would you like to refine anything? Describe what to change (e.g. 'Slide 3 headline too long', 'Slide 7 should use four-quadrants layout'), or say 'done' to finish."

Exit the loop if the user says "done", "looks good", "no", or gives an empty response.

#### Step 6.2: Classify Changes

Parse the user's feedback and classify each change request:

| Category | Examples | Channel |
|----------|----------|---------|
| **text-fix** | Typo, number correction, headline rewording, bullet text | HTML edit |
| **style-fix** | Font size, spacing, color on a specific element | HTML edit |
| **speaker-notes** | Add/change/remove speaker notes content | HTML edit |
| **layout-swap** | Change from two-columns to four-quadrants | Re-render |
| **content-restructure** | Split slide, merge slides, reorder slides | Re-render |
| **add-slide** | Insert a new slide | Re-render |
| **remove-slide** | Delete a slide | Re-render |
| **theme-adjust** | Global color/font change across all slides | Re-render |
| **data-change** | Mermaid diagram content, chart data | Re-render |

**Decision rule:** If the change affects only the text or inline styles of an existing slide element, use the HTML edit channel. If it changes layout structure, slide count, slide order, or global styling, use the re-render channel.

#### Step 6.3: Apply Changes

**For HTML-edit changes:**
1. Read the generated HTML file
2. Locate the target `<section class="slide" data-slide="N">` block
3. Apply surgical edits using the Edit tool
4. For speaker notes: locate the corresponding `<template class="slide-notes-data">` block

**For re-render changes:**
1. Read `{brief_dir}/cogni-visual/slide-data.json`
2. Modify the affected slide entries (layout, fields, add/remove slides)
3. Write updated slide-data.json
4. Re-run the Python script (Phase 3 command)
5. Re-run validation (Phase 4 checks)

**For mixed changes in the same round:**
Apply re-render changes FIRST (they produce a fresh HTML file), then apply HTML-edit changes to the fresh file. This ordering prevents HTML edits from being overwritten.

#### Step 6.4: Verify and Loop

1. Re-open the HTML in the browser:
   ```bash
   open "{output_path}"
   ```
2. Report what was changed: "Updated slide N: [description]"
3. Increment refinement counter
4. If counter < `max_refinements`: return to Step 6.1
5. If counter >= `max_refinements`: inform the user the refinement cap is reached

## Additional Resources

- **`references/01-layout-renderers.md`** — per-layout field contracts (including the accepted
  aliases for each slot), the Bottom-Banner footer contract, and the shared `slide-data.json` shape
- **`references/02-slide-navigation.md`** — navigation, transitions and keyboard behaviour
- **`references/03-speaker-notes.md`** — speaker-notes parsing and the notes-panel format

## Features

**Navigation:** Arrow keys, Space, Page Up/Down, Home/End. Click right = next, left = prev. Touch swipe on mobile.

**Speaker Notes:** Press `S` to toggle the notes panel at the bottom. Notes show "WHAT YOU SAY" coaching tags and "WHAT YOU NEED TO KNOW" context, fully parsed from the brief's speaker notes format.

**Transitions:** Smooth fade (default), slide, or instant. Configurable via `transition` parameter.

**Theming:** Full design token injection from theme.md via CSS custom properties. Every color, font, shadow, and radius is theme-driven.

**Mermaid Diagrams:** Automatically detected and rendered via Mermaid.js CDN for process-flow, layered-architecture, and gantt-chart layouts.

**Print Mode:** `Ctrl+P` renders all slides sequentially with speaker notes visible and navigation controls hidden. Each slide gets its own page.

**Responsive:** Aspect ratio is preserved via CSS `aspect-ratio` + `min()` constraints. Graceful degradation on mobile with stacked layouts.

**Self-contained:** Single HTML file. All CSS inline. All JS inline. Only external dependency is Mermaid.js CDN (conditional, only included when diagrams are present).

**Refinement Loop:** Natural-language feedback per slide after viewing — text and style fixes edit the HTML directly, structural changes trigger a targeted re-render. Channels and round cap: Phase 6.
