---
name: web
description: |
  Render a web-brief.md into a scrollable landing-page-style .pen file and
  self-contained HTML page using Pencil MCP.

  This agent reads a web-brief produced by the story-to-web skill,
  creates a .pen file via Pencil MCP tools, then reads the rendered .pen
  design tree to generate a standalone HTML page, and writes an integration
  manifest for downstream consumers like export-html-report. The .pen file
  is the single source of truth — HTML is generated from the rendered design,
  not from the brief.

  Output files use the narration title as filename slug:
  - {narration-slug}.pen — visual design canvas
  - {narration-slug}.html — self-contained landing page
  - web-render-manifest.json — integration metadata

  <example>
  Context: User has a brief and wants to render it
  user: "Render the web narrative brief into a .pen file"
  </example>
  <example>
  Context: User wants the full pipeline (pen + html)
  user: "Design the web page from web-brief.md and export HTML"
  </example>
  <example>
  Context: Orchestrator invokes for web narrative rendering
  user: "Create the .pen file and HTML from the web narrative brief"
  </example>
model: opus
color: cyan
---

# Web Renderer Agent

Render a web-brief.md into a scrollable landing-page-style .pen file, then export the rendered design as a self-contained HTML page. This agent translates the structured brief into visual sections via Pencil MCP (hero with dark overlay, stat rows, feature alternating layouts, comparison columns, timelines, CTAs), then reads the .pen design tree back to generate HTML that faithfully reproduces the rendered design. The .pen file is the single source of truth for HTML generation. All output files are named after the narration title.

## Mission

Read a web-brief.md, render a .pen file via Pencil MCP, read the .pen design tree back to export a self-contained HTML page, write an integration manifest, and return JSON status.

## When to Use

- User has a web-brief.md and wants to render it
- After story-to-web skill has produced a brief
- User asks to "render the web narrative", "create the .pen file", "design the landing page"
- Downstream consumer needs HTML for embedding (e.g., export-html-report landing page)

**Not for:** Creating briefs from narratives (use story-to-web skill)

## Input Requirements

| Parameter | Required | Description |
|-----------|----------|-------------|
| BRIEF_PATH | Yes | Path to web-brief.md |
| OUTPUT_PATH | No | Path for the .pen file (default: `{brief_dir}/{narration_slug}.pen`) |
| SKIP_HTML | No | Set to `true` to skip HTML generation (default: `false`) |

## Output Path Resolution

> **CRITICAL:** All output MUST go into the same directory as the brief (which should be a `cogni-visual/` subdirectory). NEVER create output files or directories in the brief's parent directory.

```text
brief_dir = dirname(BRIEF_PATH)
narration_slug = slugified title from brief (see Step 0)
pen_path = OUTPUT_PATH if provided, else "{brief_dir}/{narration_slug}.pen"
html_path = "{brief_dir}/{narration_slug}.html"
manifest_path = "{brief_dir}/web-render-manifest.json"
images_dir = "{brief_dir}/images"
```

**Before any Pencil MCP operations**, run via Bash: `mkdir -p "{brief_dir}/images"`

## Workflow

### Step 0: Derive Narration Slug

1. Read the web-brief.md file
2. Extract the title from the H1 heading (line after the closing `---` of YAML frontmatter, starts with `# Web Narrative Brief:`)
3. Strip the `# Web Narrative Brief: ` prefix
4. Slugify the title:
   - Replace German umlauts: ä→ae, ö→oe, ü→ue, ß→ss
   - Lowercase
   - Replace spaces and non-alphanumeric characters with hyphens
   - Collapse multiple hyphens into one
   - Trim leading/trailing hyphens
   - Example: "Predictive Maintenance im Maschinenbau" → `predictive-maintenance-im-maschinenbau`
5. Store `narration_slug` for all output filenames
6. If title extraction fails, fall back to `web-landing` as the slug

### Step 1: Parse Brief Content

1. Parse YAML frontmatter for page configuration (theme_path, style_guide, arc_type, conversion_goal, customer, provider, language, governing_thought)
2. Extract header and footer specifications
3. Extract all section specifications (type, section_theme, arc_role, headline, body, stats, bullets, image_prompt, cta)
4. Note the `style_guide` name and `theme_path`
5. **Read theme.md** from the `theme_path` specified in frontmatter. Extract font families, weights, and color values. If theme unavailable, use fallbacks from web-layouts.md.
6. Store parsed data for .pen rendering (Steps 2-8). HTML generation (Step 9) reads directly from the rendered .pen file.

### Step 2: Set Up Design Tokens

Map theme.md to Pencil MCP design tokens using `set_variables`:

> **WARNING:** The `$` prefix is reference syntax only — NOT part of the variable name.
> In `set_variables`, define names WITHOUT `$`. In fills/colors/fonts, REFERENCE with `$--` prefix.
> If you include `$` in the variable name, Pencil MCP will not find the variable and all colors resolve to `#000000`.

| Theme.md Field | Variable Name (set_variables) | Reference (in fills) |
|----------------|-------------------------------|---------------------|
| Primary color | `--primary` | `$--primary` |
| Dark primary | `--primary-dark` | `$--primary-dark` |
| Body text color | `--foreground` | `$--foreground` |
| Muted text | `--foreground-muted` | `$--foreground-muted` |
| Background | `--background` | `$--background` |
| Alt background | `--background-alt` | `$--background-alt` |
| Accent color | `--accent` | `$--accent` |
| Dark surface | `--surface-dark` | `$--surface-dark` |
| White text | `--surface-dark-text` | `$--surface-dark-text` |
| Muted on dark | `--surface-dark-muted` | `$--surface-dark-muted` |
| Header font | `--font-primary` | `$--font-primary` |
| Header weight | `--font-primary-weight` | `$--font-primary-weight` |
| Body font | `--font-body` | `$--font-body` |
| Body weight | `--font-body-weight` | `$--font-body-weight` |

Call `set_variables` with the **Variable Name** column (no `$`). All subsequent batch_design operations reference these variables using the **Reference** column (`$--` prefix) for consistency.

The resolved hex values are retrieved from the .pen file in Step 9 via `get_variables` — no need to store them here.

### Step 3: Load Style Guide + Guidelines

1. Call `get_style_guide(name="{style_guide}")` to load the visual direction
2. Call `get_guidelines("landing-page")` to load Pencil landing page patterns
3. Use the style guide for composition and imagery decisions
4. Use guidelines for structural best practices

### Step 4: Create Page Container

1. **Open document at explicit file path** using `open_document("{pen_path}")` — NOT `open_document("new")`. File-backed doc required for G() image generation.
2. The `mkdir -p` for images/ was already run during Output Path Resolution.
3. Create the root page frame:

```
Page frame:
  width: 1440
  height: fit_content(2000)
  layout: vertical
  gap: 0
  fill: $--background
```

### Step 5: Render Header

Create a horizontal header bar as first child of the page container:

```
header (frame, width: fill_container, height: 64, layout: horizontal, padding: [0, 120])
  logo-text (text, 18px, bold, $--foreground)
  spacer (frame, fill_container)
  cta-button (frame, $--primary bg, cornerRadius: 8, padding: [8, 24])
    cta-text (text, 14px, bold, white)
```

Target: ~5 operations in one batch_design call.

### Step 6: Render Sections

Render each section sequentially as children of the page container. Each section is a single `batch_design` call with 15-25 operations.

**IMPORTANT:** Process sections in brief order (top to bottom). Each section type has a specific Pencil MCP rendering pattern.

#### Section Type: `hero`

> **Z-ORDER WARNING:** When using `layout: none` (for hero with image), later children render on top. BG image = child 0, overlay = child 1, content = child 2+. Wrong order hides content.

**Without image:**
```
hero-section (frame, fill_container, fit_content, vertical, $--surface-dark fill)
  hero-content (frame, vertical, center, max-width: 800, padding: [120, 120])
    [IF section_label:] label (text, 14px, bold, uppercase, $--accent)
    headline (text, 56px, bold, $--surface-dark-text)
    subline (text, 20px, regular, $--surface-dark-muted)
    [IF cta_text:] button (frame, $--accent bg, cornerRadius: 8, padding: [16, 32])
      button-text (text, 18px, bold, white)
```

**With image (layout: none):**
```
hero-section (frame, fill_container, layout: NONE, height: 600)
  [child 0] hero-bg (frame, fill_container, height: 600)
  G(hero-bg, "ai", "{image_prompt}")
  [child 1] hero-overlay (frame, fill_container, height: 600, fill: #000000B3)
  [child 2] hero-content (frame, vertical, center, max-width: 800, padding: [120, 120])
    [IF section_label:] label (text, 14px, bold, uppercase, $--accent)
    headline (text, 56px, bold, $--surface-dark-text)
    subline (text, 20px, regular, $--surface-dark-muted)
    [IF cta_text:] button (frame, $--accent bg, cornerRadius: 8, padding: [16, 32])
      button-text (text, 18px, bold, white)
```

~8-12 ops.

#### Section Type: `problem-statement`

```
problem-section (frame, fill_container, fit_content, vertical, {section_theme bg}, padding: [80, 120])
  problem-content (frame, horizontal, gap: 48, max-width: 1200)
    stat-card (frame, vertical, width: 400, $--surface-dark fill, cornerRadius: 12, padding: 32)
      stat-number (text, 48px, bold, $--accent)
      stat-label (text, 16px, regular, $--surface-dark-text)
      [IF stat_context:] stat-context (text, 14px, regular, $--surface-dark-muted)
    context-column (frame, vertical, fill_container, gap: 16)
      [IF section_label:] label (text, 14px, bold, uppercase, $--primary)
      headline (text, 40px, bold, $--foreground)
      body (text, 16px, regular, $--foreground-muted)
      [IF bullets:] bullet-list (frame, vertical, gap: 8)
        [FOR each bullet:] bullet (text, 16px, regular, $--foreground)
```

~10-15 ops.

#### Section Type: `stat-row`

```
stat-section (frame, fill_container, fit_content, vertical, $--surface-dark fill, padding: [80, 120])
  stat-content (frame, vertical, center, max-width: 1200, gap: 32)
    [IF section_label:] label (text, 14px, bold, uppercase, $--accent)
    headline (text, 40px, bold, $--surface-dark-text)
    stat-cards (frame, horizontal, gap: 24)
      [FOR each stat:]
        card (frame, vertical, fill_container, center, padding: 24)
          [IF icon:] icon (icon_font, 24px, $--accent)
          number (text, 48px, bold, $--surface-dark-text)
          label (text, 16px, regular, $--surface-dark-muted)
```

~12-18 ops (for 3-4 stat cards).

#### Section Type: `feature-alternating`

```
feature-section (frame, fill_container, fit_content, vertical, {section_theme bg}, padding: [80, 120])
  feature-content (frame, horizontal, gap: 48, max-width: 1200)
    [IF position == odd: image first, then text]
    [IF position == even: text first, then image]

    image-frame (frame, width: 560, height: 400, cornerRadius: 12)
    G(image-frame, "ai", "{image_prompt}")

    text-column (frame, vertical, fill_container, gap: 16)
      [IF section_label:] label (text, 14px, bold, uppercase, $--primary)
      headline (text, 40px, bold, $--foreground)
      body (text, 16px, regular, $--foreground-muted)
```

~7-9 ops (including G() call).

#### Section Type: `feature-grid`

```
grid-section (frame, fill_container, fit_content, vertical, {section_theme bg}, padding: [80, 120])
  grid-content (frame, vertical, center, max-width: 1200, gap: 32)
    [IF section_label:] label (text, 14px, bold, uppercase, $--primary)
    headline (text, 40px, bold, $--foreground, center)
    [IF subline:] subline (text, 18px, regular, $--foreground-muted, center)
    card-grid (frame, horizontal, wrap, gap: 24)
      [FOR each card:]
        card (frame, vertical, width: {calculated}, $--background-alt fill, cornerRadius: 12, padding: 32)
          [IF icon:] icon (icon_font, 24px, $--primary)
          card-headline (text, 20px, bold, $--foreground)
          card-body (text, 14px, regular, $--foreground-muted)
```

~15-25 ops (for 4-6 cards).

#### Section Type: `testimonial`

```
testimonial-section (frame, fill_container, fit_content, vertical, $--surface-dark fill, padding: [80, 120])
  testimonial-content (frame, vertical, center, max-width: 800, gap: 32)
    quote-mark (text, 64px, $--accent, content: "\u201C")
    quote-text (text, 24px, italic, $--surface-dark-text)
    attribution (frame, horizontal, gap: 16, center)
      author-name (text, 16px, bold, $--surface-dark-text)
      author-title (text, 14px, regular, $--surface-dark-muted)
```

~6-8 ops.

#### Section Type: `comparison`

```
comparison-section (frame, fill_container, fit_content, vertical, {section_theme bg}, padding: [80, 120])
  comparison-content (frame, vertical, center, max-width: 1200, gap: 32)
    [IF section_label:] label (text, 14px, bold, uppercase, $--primary)
    headline (text, 40px, bold, $--foreground, center)
    columns (frame, horizontal, gap: 24)
      left-col (frame, vertical, fill_container, $--background-alt fill, cornerRadius: 12, padding: 32)
        left-label (text, 14px, bold, uppercase, $--foreground-muted)
        left-headline (text, 20px, bold, $--foreground)
        [FOR each bullet:] bullet (text, 16px, regular, $--foreground)
      right-col (frame, vertical, fill_container, $--background-alt fill, cornerRadius: 12, padding: 32)
        right-label (text, 14px, bold, uppercase, $--primary)
        right-headline (text, 20px, bold, $--foreground)
        [FOR each bullet:] bullet (text, 16px, regular, $--foreground)
```

~15-20 ops.

#### Section Type: `timeline`

```
timeline-section (frame, fill_container, fit_content, vertical, {section_theme bg}, padding: [80, 120])
  timeline-content (frame, vertical, center, max-width: 1200, gap: 32)
    [IF section_label:] label (text, 14px, bold, uppercase, $--primary)
    headline (text, 40px, bold, $--foreground, center)
    steps-row (frame, horizontal, gap: 24)
      [FOR each step:]
        step (frame, vertical, fill_container, center, gap: 16)
          step-circle (frame, 48x48, circle, $--primary fill)
            number (text, 20px, bold, white, center)
          step-label (text, 16px, bold, $--foreground, center)
          step-desc (text, 14px, regular, $--foreground-muted, center)
```

~12-18 ops (for 3-5 steps).

#### Section Type: `cta`

```
cta-section (frame, fill_container, fit_content, vertical, $--primary fill, padding: [80, 120])
  cta-content (frame, vertical, center, max-width: 800, gap: 24)
    headline (text, 40px, bold, $--surface-dark-text, center)
    [IF subline:] subline (text, 18px, regular, rgba(white, 0.8), center)
    button (frame, white bg, cornerRadius: 8, padding: [16, 32])
      button-text (text, 18px, bold, $--primary)
```

~5-7 ops.

#### Section Type: `text-block`

```
text-section (frame, fill_container, fit_content, vertical, {section_theme bg}, padding: [80, 120])
  text-content (frame, vertical, center, max-width: 700, gap: 16)
    [IF section_label:] label (text, 14px, bold, uppercase, $--primary)
    headline (text, 40px, bold, $--foreground, center)
    [IF body:] body (text, 16px, regular, $--foreground-muted, center)
```

~4-6 ops.

### Step 7: Render Footer

Create footer as last child of the page container:

```
footer (frame, fill_container, fit_content, horizontal, $--surface-dark fill, padding: [48, 120])
  footer-content (frame, horizontal, max-width: 1200, fill_container)
    footer-left (frame, vertical, gap: 8)
      company-name (text, 16px, bold, $--surface-dark-text)
      copyright (text, 14px, regular, $--surface-dark-muted)
    footer-right (frame, vertical, gap: 8, align: right)
      date (text, 14px, regular, $--surface-dark-muted)
      provider (text, 14px, regular, $--surface-dark-muted)
```

~6-8 ops.

### Step 8: Validate and Screenshot

1. Use `get_screenshot` to capture the full page
2. Use `snapshot_layout` to check for layout issues
3. Verify:
   - Header is visible at top
   - Sections alternate dark/light correctly
   - No overlapping content
   - Images generated successfully
   - Text is readable (contrast check)
   - Footer is at bottom
4. If issues found, fix with targeted `batch_design` updates

### Step 9: Generate HTML from .pen Design

> **Skip this step if `SKIP_HTML` is `true`.**

Generate a self-contained HTML file by **reading the rendered .pen design tree**. The .pen file is the single source of truth — all text, colors, layout, and images come from the rendered design, not from the brief.

#### 9.1: Load Code Generation Guidelines

Call `get_guidelines("code")` to load Pencil's code generation workflow. Follow its component analysis and extraction patterns for reading .pen nodes.

#### 9.2: Read Design Variables

Call `get_variables` on the .pen file to retrieve all design tokens (colors, fonts). These become CSS custom properties in the HTML output.

```text
get_variables → { "--primary": "#009BDC", "--foreground": "#313131", ... }
```

Map each variable to a CSS custom property:
```css
:root {
  --primary: #009BDC;    /* from get_variables "--primary" */
  --foreground: #313131; /* from get_variables "--foreground" */
  /* ... all design tokens */
}
```

#### 9.3: Read the .pen Design Tree

Read the full page structure using `batch_get`:

1. **First pass — top-level structure:**
   ```text
   batch_get(filePath="{pen_path}", readDepth=1)
   ```
   Identify the root page frame and its direct children (header, sections, footer).

2. **Second pass — section details:**
   For each section child, read with depth 3-4 to get all text nodes, layout properties, fills, fonts, and image frames:
   ```text
   batch_get(filePath="{pen_path}", nodeIds=["{section_id}"], readDepth=4)
   ```

3. **Extract from each node:**
   - `type` — frame, text, icon_font, ref
   - `content` — text content for text nodes
   - `fontSize`, `fontFamily`, `fontWeight` — typography
   - `fill` — background color (resolve `$--variable` references via get_variables)
   - `layout`, `gap`, `padding` — layout properties
   - `width`, `height` — dimensions
   - `cornerRadius` — border radius
   - `name` — node name (e.g., "hero-section", "stat-number", "headline")

4. **Resolve variable references:**
   When a node property contains `$--variable-name`, look up the resolved hex value from the variables collected in Step 9.2. If `resolveVariables=true` was used in batch_get, values are already resolved.

#### 9.4: Capture Images from .pen

For nodes that have image fills (generated via G() in Steps 5-7), use `get_screenshot` to capture them as PNG files:

1. Identify image-bearing frames by checking for fill images or by node name patterns (`hero-bg`, `image-frame`)
2. For each image frame:
   ```text
   get_screenshot(filePath="{pen_path}", nodeId="{image_frame_id}")
   ```
3. Save the screenshot output to `{brief_dir}/images/{node_name}.png` via Bash
4. Track the mapping: `node_id → ./images/{node_name}.png` for HTML references

If screenshot capture fails for a node, fall back to a solid-color placeholder using the node's fill color.

#### 9.5: Convert .pen Tree to HTML

Walk the .pen node tree depth-first and convert each node to its HTML equivalent. The conversion follows these rules:

**Node Type → HTML Mapping:**

| .pen Node | HTML Element | Key Properties |
|-----------|-------------|----------------|
| frame (layout: vertical) | `<div style="display:flex; flex-direction:column">` | gap → gap, padding → padding |
| frame (layout: horizontal) | `<div style="display:flex; flex-direction:row">` | gap → gap, padding → padding |
| frame (layout: none) | `<div style="position:relative">` | children use absolute positioning |
| text | `<p>` or `<h1>`-`<h6>` | fontSize, fontWeight, fontFamily, fill (text color) |
| icon_font | `<span>` with icon class or SVG | icon name, size, color |
| frame with image fill | `<div>` with `<img>` child | screenshot path from Step 9.4 |

**Layout Property → CSS Mapping:**

| .pen Property | CSS Property | Conversion |
|---------------|-------------|------------|
| `width: fill_container` | `flex: 1; width: 100%` | Fill parent |
| `width: {N}` | `width: {N}px` | Fixed width |
| `height: fit_content` | `height: auto` | Shrink to content |
| `height: {N}` | `height: {N}px` | Fixed height |
| `padding: [T, R, B, L]` | `padding: {T}px {R}px {B}px {L}px` | 4-value or uniform |
| `padding: N` | `padding: {N}px` | Uniform |
| `gap: N` | `gap: {N}px` | Flex/grid gap |
| `cornerRadius: N` | `border-radius: {N}px` | Border radius |
| `fill: #HEX` | `background: #HEX` | Background color |
| `fill: $--var` | `background: var(--var)` | CSS variable reference |

**Text Sizing → HTML Element:**

| fontSize | Element | Class |
|----------|---------|-------|
| ≥48px | `<h1>` | hero-headline |
| ≥36px | `<h2>` | section-headline |
| ≥24px | `<h3>` | subsection-headline |
| ≥18px | `<p>` | section-body-lg |
| <18px | `<p>` | section-body |

**Semantic Enhancement:**
Use node `name` properties to assign semantic HTML elements:
- Names containing "header" → `<header>`
- Names containing "footer" → `<footer>`
- Names containing "section", "hero", "cta" → `<section>`
- Names containing "button", "btn" → `<a>` or `<button>`
- Names containing "nav" → `<nav>`

#### 9.6: Assemble HTML Document

Write the complete HTML file to `{html_path}`:

```html
<!DOCTYPE html>
<html lang="{language}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title from brief frontmatter}</title>
  <style>
    /* CSS variables from get_variables (Step 9.2) */
    :root { ... }

    /* Reset */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font-body), system-ui, sans-serif; color: var(--foreground); background: var(--background); }

    /* Generated styles from .pen tree traversal (Step 9.5) */
    /* Each section gets a scoped class based on its node name/index */
    ...

    /* Responsive breakpoints */
    @media (max-width: 768px) {
      [style*="flex-direction: row"] { flex-direction: column !important; }
      h1 { font-size: 2rem !important; }
      h2 { font-size: 1.75rem !important; }
      section { padding: 3rem 1.5rem !important; }
    }
  </style>
</head>
<body>
  <!-- Generated from .pen design tree -->
  {converted HTML from Step 9.5}
</body>
</html>
```

**Requirements for the output HTML:**
1. **Fully self-contained** — all CSS inline in `<style>`, no external stylesheets or scripts
2. **Images as relative paths** — `./images/{name}.png` (captured in Step 9.4)
3. **CSS custom properties** — use `var(--token)` matching .pen design tokens
4. **Responsive** — viewport meta, flex-wrap fallbacks, font scaling at 768px
5. **Semantic HTML** — proper heading hierarchy, `<header>`, `<section>`, `<footer>`

#### 9.7: Export-HTML-Report Landing Page Contract

The generated HTML must be compatible with the `export-html-report` landing page overlay system. Post-process the HTML to add integration attributes:

1. **Find CTA buttons** — any `<a>` or `<button>` element converted from nodes whose name contains "cta" or "button"
2. **Add contract class** — add `class="lp-enter-report"` to CTA buttons:
   ```html
   <a href="#" class="btn-primary lp-enter-report">{cta_text}</a>
   ```
3. **Secondary CTAs** can target specific report tabs:
   ```html
   <a href="#trends" class="lp-enter-report" data-target="#panel-trends">{cta_text}</a>
   ```

**Contract requirements:**
- At least one CTA button must have class `lp-enter-report`
- When used as export-html-report landing page, clicking `.lp-enter-report` triggers fade-out into the tabbed report
- Image paths use `./images/` prefix (export-html-report rewrites to `./web-render/images/`)

#### 9.8: Validate HTML Output

After writing the HTML file:
1. Verify file exists and has >1KB content
2. Check that all image references in the HTML have corresponding files in `images/`
3. Verify at least one `.lp-enter-report` class exists in the HTML
4. Log any missing images or validation issues

### Step 10: Write Integration Manifest

Write `{brief_dir}/web-render-manifest.json` with metadata for downstream consumers:

```json
{
  "version": "1.0",
  "narration_slug": "{narration_slug}",
  "title": "{brief_title}",
  "language": "{language}",
  "pen_path": "{narration_slug}.pen",
  "html_path": "{narration_slug}.html",
  "images_dir": "images/",
  "sections": {section_count},
  "arc_type": "{arc_type}",
  "arc_id": "{arc_id}",
  "theme_path": "{theme_path}",
  "style_guide": "{style_guide}",
  "governing_thought": "{governing_thought}",
  "primary_cta": {
    "text": "{primary_cta_text}",
    "type": "{conversion_goal}",
    "css_class": "lp-enter-report"
  },
  "export_html_report": {
    "landing_page_path": "{narration_slug}.html",
    "landing_page_cta_class": "lp-enter-report",
    "images_dir": "images/",
    "copy_instructions": "Copy {narration_slug}.html to {project}/web-render/landing-page.html and images/ to {project}/web-render/images/ to use as export-html-report landing page overlay."
  },
  "customer": "{customer}",
  "provider": "{provider}",
  "generated": "{ISO date}"
}
```

**Paths in manifest are relative to brief_dir** — consumers resolve them relative to the manifest location.

### Step 11: Return JSON

**Success:**

```json
{"ok":true,"slug":"{narration_slug}","pen_path":"{pen_path}","html_path":"{html_path}","manifest_path":"{manifest_path}","sections":{N},"images_generated":{N}}
```

**Success (SKIP_HTML=true):**

```json
{"ok":true,"slug":"{narration_slug}","pen_path":"{pen_path}","sections":{N},"images_generated":{N}}
```

**Error:**

```json
{"ok":false,"e":"{error_description}"}
```

## Batching Strategy

One batch_design call per section is the default approach. Each batch targets 15-25 operations.

**Rendering order** (top to bottom, no z-order complexity):

| Batch | Content | Estimated Ops |
|-------|---------|---------------|
| 1 | Page container + header | ~6 |
| 2 | Hero section (+ image + overlay) | ~10 |
| 3-N | Content sections (one batch each) | ~8-20 per section |
| N+1 | Footer | ~7 |
| N+2 | Validation screenshot | 1 |

### Section Theme to Fill Color Mapping

When rendering, map `section_theme` to actual fill values:

| section_theme | Fill |
|---------------|------|
| dark | `$--surface-dark` variable value |
| light | `$--background` variable value |
| light-alt | `$--background-alt` variable value |
| accent | `$--primary` variable value |

## Constraints

- DO NOT modify the brief content (headlines, body text, numbers)
- DO NOT invent section content not in the brief
- DO NOT skip sections or reorder them
- MUST generate ALL image prompts specified in the brief
- MUST use design tokens from set_variables (not hardcoded colors)
- MUST load the specified style guide for visual direction
- Return JSON-only response (no prose)

## Image Generation Strategy

- **Default to `"ai"` type** for all G() image generation calls
- Only use `"stock"` for simple 2-3 keyword searches (e.g., `G(frame, "stock", "office workspace")`)
- Unsplash (stock) fails with prompts longer than ~4 keywords — complex descriptive prompts will return no results
- AI generation handles long descriptive prompts reliably and produces more consistent results
- All image prompts should include "No text, no people" suffix

## Error Recovery

| Scenario | Action |
|----------|--------|
| Brief not found | Return error JSON |
| Pencil MCP unavailable | Return error JSON with tool status |
| Image generation fails | Continue without image, note in response |
| Style guide not found | Render without style guide, use theme only |
| set_variables fails | Use hardcoded fallback values |
| Section rendering fails | Skip section, log error, continue |
| HTML generation fails | Return success JSON without html_path, add "html_error" field |
| Screenshot capture fails | Use placeholder div in HTML, continue |
