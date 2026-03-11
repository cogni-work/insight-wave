---
library_id: web-layouts
version: 1.0.0
created: 2026-02-26
---

# Web Narrative Layout Library

Section type schemas, typography scale, spacing system, theme-to-variable mapping, and section theming rules for scrollable landing-page-style .pen files rendered via Pencil MCP.

---

## Page Container

All web narratives use a single vertical page container that grows with content.

| Property | Value | Notes |
|----------|-------|-------|
| Width | 1440px | Standard web viewport width |
| Height | `fit_content(2000)` | Grows with content, minimum 2000px |
| Layout | `vertical` | Top-to-bottom section flow |
| Gap | 0 | Sections are edge-to-edge (spacing is internal to each section) |
| Background | `$--background` | Theme background color |

---

## Theme-to-Variable Mapping

The renderer maps theme.md fields to Pencil MCP design tokens via `set_variables`. These variables drive all colors and fonts consistently across sections.

### Color Variables

| Variable Name | Theme.md Field | Fallback | Usage |
|---------------|---------------|----------|-------|
| `--primary` | Primary color (e.g., "Cyan Blue: #009BDC") | `#2563EB` | CTA buttons, accent elements, section labels |
| `--primary-dark` | Dark variant of primary | `#1E40AF` | Dark section backgrounds, hover states |
| `--foreground` | Body text color (e.g., "Carbon Text: #313131") | `#1A1A1A` | Headlines, body text on light backgrounds |
| `--foreground-muted` | Muted text | `#6B7280` | Sublines, captions, secondary text |
| `--background` | Background color | `#FFFFFF` | Page background, light section backgrounds |
| `--background-alt` | Alternate background | `#F9FAFB` | Alternating light section backgrounds |
| `--accent` | Accent color (e.g., "Signal Orange: #FF6600") | `#F59E0B` | Hero numbers, stat highlights, visual accents |
| `--surface-dark` | Dark surface | `#111827` | Hero section, testimonial, dark backgrounds |
| `--surface-dark-text` | Text on dark surfaces | `#FFFFFF` | White text on dark section backgrounds |
| `--surface-dark-muted` | Muted text on dark surfaces | `#D1D5DB` | Subtext on dark backgrounds |

### Font Variables

| Variable Name | Theme.md Field | Fallback | Usage |
|---------------|---------------|----------|-------|
| `--font-primary` | Header font (e.g., "Raleway Bold") | `Inter` | Headlines, CTA buttons, stat numbers |
| `--font-primary-weight` | Header font weight | `Bold` | Weight for primary font |
| `--font-body` | Body font (e.g., "Open Sans") | `Inter` | Body text, bullets, descriptions |
| `--font-body-weight` | Body font weight | `Regular` | Weight for body font |

> **WARNING:** Variable names must NOT include `$`. The `$` prefix is reference syntax only.
> - **Define** as `--primary` (in `set_variables`)
> - **Reference** as `$--primary` (in fill, color, fontFamily properties)
> - If you include `$` in the variable name, Pencil MCP will not find the variable and all colors will resolve to `#000000` (black).

### Extraction Rules

Parse theme.md to extract values:

```
1. Scan for color definitions: "Name: #HEXCODE" or "name: #hexcode"
2. Map primary/accent/text colors by position and naming convention
3. Scan typography section for font families and weights
4. Apply fallback values for any unresolved fields
```

---

## Typography Scale

All font sizes are fixed (no canvas-size scaling — web narratives are always 1440px wide).

| Element | Font Size | Weight | Line Height | Max Width |
|---------|-----------|--------|-------------|-----------|
| Hero headline | 56px | Bold | 1.1 | 800px |
| Hero subline | 20px | Regular | 1.5 | 600px |
| Section headline | 40px | Bold | 1.2 | 700px |
| Section subline | 18px | Regular | 1.5 | 600px |
| Body text | 16px | Regular | 1.6 | 640px |
| Stat number | 48px | Bold | 1.0 | — |
| Stat label | 16px | Regular | 1.4 | — |
| CTA button text | 18px | Bold | 1.0 | — |
| Section label | 14px | Bold (uppercase) | 1.0 | — |
| Card headline | 20px | Bold | 1.3 | — |
| Card body | 14px | Regular | 1.5 | — |
| Quote text | 24px | Italic | 1.5 | 700px |
| Attribution text | 14px | Regular | 1.4 | — |
| Timeline step number | 32px | Bold | 1.0 | — |
| Timeline step label | 16px | Bold | 1.3 | — |
| Footer text | 14px | Regular | 1.5 | — |

---

## Spacing System

Consistent spacing tokens used across all sections.

| Token | Value | Usage |
|-------|-------|-------|
| `section-padding-y` | 80px | Vertical padding inside each section |
| `section-padding-x` | 120px | Horizontal padding inside each section |
| `content-max-width` | 1200px | Maximum content width within sections |
| `content-gap-lg` | 48px | Gap between major content blocks |
| `content-gap-md` | 32px | Gap between related elements |
| `content-gap-sm` | 16px | Gap between tightly coupled elements |
| `card-padding` | 32px | Padding inside cards |
| `card-gap` | 24px | Gap between cards in a grid |
| `card-radius` | 12px | Corner radius on cards |
| `button-padding-x` | 32px | Horizontal padding on CTA buttons |
| `button-padding-y` | 16px | Vertical padding on CTA buttons |
| `button-radius` | 8px | Corner radius on buttons |

---

## Section Theming

Sections alternate between light and dark backgrounds to create visual rhythm. The `section_theme` field on each section in the brief controls this.

| section_theme | Background | Text Color | Muted Color | Notes |
|---------------|-----------|------------|-------------|-------|
| `light` | `$--background` (#FFFFFF) | `$--foreground` | `$--foreground-muted` | Default for most content sections |
| `light-alt` | `$--background-alt` (#F9FAFB) | `$--foreground` | `$--foreground-muted` | Alternating light sections |
| `dark` | `$--surface-dark` (#111827) | `$--surface-dark-text` | `$--surface-dark-muted` | Hero, testimonial, stat-row |
| `accent` | `$--primary` | `$--surface-dark-text` | `$--surface-dark-muted` | CTA sections |

### Alternation Rules

1. **Hero** section is always `dark`
2. **CTA** section is always `accent`
3. **Testimonial** and **stat-row** are always `dark`
4. Remaining content sections alternate between `light` and `light-alt`
5. No two adjacent sections should have the same background (except dark sections separated by light ones)

---

## Section Type Schemas

Each section type defines its Pencil MCP structure. The renderer creates these as vertical auto-layout frames within the page container.

### Common Section Frame Properties

Every section is a frame with:

```
type: frame
layout: vertical
width: fill_container
height: fit_content
padding: [section-padding-y, section-padding-x]
alignment: center
```

> **Pencil MCP values are unitless.** The `px` units in documentation tables (typography, spacing) are for human readability only. When passing values to Pencil MCP operations (`batch_design`, `set_variables`), use bare numbers: `width: 1440`, `gap: 48`, `cornerRadius: 12` — not `1440px`, `48px`, `12px`. The pseudocode structures below use `px` annotations for clarity, but the renderer must strip them.

Content within each section is constrained to `content-max-width` (1200) using a nested content frame.

---

### Section Type 1: `hero`

Full-width opening section with headline, subline, and CTA.

**Arc role:** hook

**Structure (without image):**
```
hero-section (frame, fill_container, layout: vertical, dark bg)
  hero-content (frame, vertical, center-aligned, max-width 800px, padding [120, 120])
    section-label (text, 14px, uppercase, accent color)
    headline (text, 56px, bold, white)
    subline (text, 20px, regular, muted-light)
    cta-button (frame, accent bg, rounded)
      button-text (text, 18px, bold, white)
```

**Structure (with image):**
```
hero-section (frame, fill_container, layout: NONE, height: 600)
  [child 0] hero-bg (frame, fill_container, height: 600)          ← bottom layer
  [child 1] hero-overlay (frame, fill_container, height: 600, fill: #000000B3)  ← middle layer
  [child 2] hero-content (frame, vertical, center, max-width 800px, padding [120, 120])  ← top layer
    section-label (text, 14px, uppercase, accent color)
    headline (text, 56px, bold, white)
    subline (text, 20px, regular, muted-light)
    cta-button (frame, accent bg, rounded)
      button-text (text, 18px, bold, white)
```

> **Z-ORDER WARNING:** When using `layout: none` (absolute positioning), later children render on top of earlier children. The background image MUST be child 0, overlay MUST be child 1, and content MUST be child 2+. Inserting them in the wrong order will hide the content behind the image.

**Image pattern:** If `image_prompt` is present, use `layout: none` with `height: 600`. Create bg image frame (child 0), generate image via G(), add semi-transparent dark overlay frame (child 1, `#000000B3` — 70% opacity), then content frame (child 2) sits on top.

**Required fields:** `headline`, `subline`
**Optional fields:** `section_label`, `cta_text`, `cta_url`, `image_prompt`

---

### Section Type 2: `problem-statement`

Split layout with stat card on one side and context on the other.

**Arc role:** problem

**Structure:**
```
problem-section (frame, fill_container, light bg)
  problem-content (frame, horizontal, gap 48px, max-width 1200px)
    stat-card (frame, vertical, width 400px, dark bg, rounded)
      stat-number (text, 48px, bold, accent)
      stat-label (text, 16px, regular, white)
      stat-context (text, 14px, regular, muted-light)
    context-column (frame, vertical, fill_container, gap 16px)
      section-label (text, 14px, uppercase, primary)
      headline (text, 40px, bold, foreground)
      body (text, 16px, regular, foreground-muted)
      bullets (frame, vertical, gap 8px)
        bullet-item (text, 16px, regular, foreground)
```

**Required fields:** `headline`, `body` or `bullets`
**Optional fields:** `section_label`, `stat_number`, `stat_label`, `stat_context`, `image_prompt`

---

### Section Type 3: `stat-row`

3-4 metric cards in a horizontal row on a dark background.

**Arc role:** urgency, evidence

**Structure:**
```
stat-section (frame, fill_container, dark bg)
  stat-content (frame, vertical, center-aligned, max-width 1200px)
    section-label (text, 14px, uppercase, accent)
    headline (text, 40px, bold, white)
    stat-cards (frame, horizontal, gap 24px)
      stat-card (frame, vertical, fill_container, center)  [repeat 3-4x]
        icon (icon_font, 24px, accent)
        number (text, 48px, bold, white)
        label (text, 16px, regular, muted-light)
```

**Required fields:** `headline`, `stats` (array of 3-4 objects with `number` and `label`)
**Optional fields:** `section_label`, stats[].`icon`

---

### Section Type 4: `feature-alternating`

Image and text side by side, alternating left/right between instances.

**Arc role:** solution

**Structure (image-left variant):**
```
feature-section (frame, fill_container, light/light-alt bg)
  feature-content (frame, horizontal, gap 48px, max-width 1200px)
    image-frame (frame, width 560px, height 400px, rounded)
      [G() generated image]
    text-column (frame, vertical, fill_container, gap 16px)
      section-label (text, 14px, uppercase, primary)
      headline (text, 40px, bold, foreground)
      body (text, 16px, regular, foreground-muted)
```

**Alternation:** Odd instances: image left, text right. Even instances: text left, image right. Implement by changing the order of children in the horizontal frame.

**Image dimensions:** 560 x 400 (16:10 ratio). Use `cornerRadius: 12` on the image frame.

**Required fields:** `headline`, `body`, `image_prompt`
**Optional fields:** `section_label`

---

### Section Type 5: `feature-grid`

2x2 or 3x2 grid of icon+text cards.

**Arc role:** solution, capabilities

**Structure:**
```
grid-section (frame, fill_container, light/light-alt bg)
  grid-content (frame, vertical, center-aligned, max-width 1200px, gap 32px)
    section-label (text, 14px, uppercase, primary)
    headline (text, 40px, bold, foreground, center)
    subline (text, 18px, regular, foreground-muted, center)
    card-grid (frame, horizontal, wrap, gap 24px)
      card (frame, vertical, width calc, padding 32px, light-alt bg, rounded)  [repeat 4-6x]
        icon (icon_font, 24px, primary)
        card-headline (text, 20px, bold, foreground)
        card-body (text, 14px, regular, foreground-muted)
```

**Card width calculation:** For 2-column: `(1200 - 24) / 2 = 588px`. For 3-column: `(1200 - 48) / 3 = 384px`.

**Required fields:** `headline`, `cards` (array of objects with `card_headline` and `card_body`)
**Optional fields:** `section_label`, `subline`, cards[].`icon`

---

### Section Type 6: `testimonial`

Large quote with attribution on a dark background.

**Arc role:** proof

**Structure:**
```
testimonial-section (frame, fill_container, dark bg)
  testimonial-content (frame, vertical, center-aligned, max-width 800px, gap 32px)
    quote-mark (text, 64px, accent, "\u201C")
    quote-text (text, 24px, italic, white)
    attribution (frame, horizontal, gap 16px, center)
      author-name (text, 16px, bold, white)
      author-title (text, 14px, regular, muted-light)
```

**Required fields:** `quote`, `author_name`
**Optional fields:** `author_title`, `author_company`

---

### Section Type 7: `comparison`

Two-column before/after or versus layout.

**Arc role:** proof

**Structure:**
```
comparison-section (frame, fill_container, light bg)
  comparison-content (frame, vertical, center-aligned, max-width 1200px, gap 32px)
    section-label (text, 14px, uppercase, primary)
    headline (text, 40px, bold, foreground, center)
    columns (frame, horizontal, gap 24px)
      left-column (frame, vertical, fill_container, padding 32px, light-alt bg, rounded)
        column-label (text, 14px, bold, uppercase, foreground-muted)
        column-headline (text, 20px, bold, foreground)
        bullets (frame, vertical, gap 8px)
          bullet-item (text, 16px, regular, foreground)
      right-column (frame, vertical, fill_container, padding 32px, light-alt bg, rounded)
        column-label (text, 14px, bold, uppercase, primary)
        column-headline (text, 20px, bold, foreground)
        bullets (frame, vertical, gap 8px)
          bullet-item (text, 16px, regular, foreground)
```

**Required fields:** `headline`, `left_label`, `left_headline`, `left_bullets`, `right_label`, `right_headline`, `right_bullets`
**Optional fields:** `section_label`

---

### Section Type 8: `timeline`

Numbered horizontal steps showing a process or roadmap.

**Arc role:** roadmap

**Structure:**
```
timeline-section (frame, fill_container, light/light-alt bg)
  timeline-content (frame, vertical, center-aligned, max-width 1200px, gap 32px)
    section-label (text, 14px, uppercase, primary)
    headline (text, 40px, bold, foreground, center)
    steps-row (frame, horizontal, gap 24px)
      step (frame, vertical, fill_container, center, gap 16px)  [repeat 3-5x]
        step-number (frame, 48x48px, circle, primary bg)
          number-text (text, 20px, bold, white, center)
        step-label (text, 16px, bold, foreground, center)
        step-description (text, 14px, regular, foreground-muted, center)
```

**Required fields:** `headline`, `steps` (array of objects with `label` and `description`)
**Optional fields:** `section_label`, steps[].`duration`

---

### Section Type 9: `cta`

Call-to-action section with headline, subline, and button on accent background.

**Arc role:** call-to-action

**Structure:**
```
cta-section (frame, fill_container, accent bg)
  cta-content (frame, vertical, center-aligned, max-width 800px, gap 24px)
    headline (text, 40px, bold, white, center)
    subline (text, 18px, regular, white at 80%, center)
    cta-button (frame, white bg, rounded)
      button-text (text, 18px, bold, primary color)
```

**Note:** CTA button is inverted — white background with primary-color text (opposite of hero button).

**Required fields:** `headline`, `cta_text`
**Optional fields:** `subline`

---

### Section Type 10: `text-block`

Centered prose bridge between sections.

**Arc role:** any (transition/bridge)

**Structure:**
```
text-section (frame, fill_container, light/light-alt bg)
  text-content (frame, vertical, center-aligned, max-width 700px, gap 16px)
    section-label (text, 14px, uppercase, primary)
    headline (text, 40px, bold, foreground, center)
    body (text, 16px, regular, foreground-muted, center)
```

**Required fields:** `headline`
**Optional fields:** `section_label`, `body`

---

## Header and Footer

### Header

A minimal header bar at the top of the page.

```
header (frame, fill_container, height 64px, horizontal, padding [0, 120px])
  logo-text (text, 18px, bold, foreground)
  nav-spacer (frame, fill_container)
  cta-mini (frame, primary bg, rounded, padding [8px, 24px])
    cta-text (text, 14px, bold, white)
```

### Footer

A minimal footer at the bottom of the page.

```
footer (frame, fill_container, dark bg, padding [48px, 120px])
  footer-content (frame, horizontal, max-width 1200px)
    footer-left (frame, vertical, gap 8px)
      company-name (text, 16px, bold, white)
      copyright (text, 14px, regular, muted-light)
    footer-right (frame, vertical, gap 8px, align-right)
      date (text, 14px, regular, muted-light)
      provider (text, 14px, regular, muted-light)
```

---

## Rendering Order

Sections render top-to-bottom. No z-order complexity (unlike big-picture posters).

| Order | Element | Notes |
|-------|---------|-------|
| 1 | Page container | Root frame at 1440px wide |
| 2 | Header | Sticky-style top bar |
| 3 | Hero section | Always first content section |
| 4-N | Content sections | In brief order |
| N+1 | CTA section | Always last content section |
| N+2 | Footer | Bottom bar |

---

## Pencil MCP Rendering Notes

When the web agent renders a brief via Pencil MCP:

1. **Open document at explicit file path** (NOT `open_document("new")`) for G() image support
2. **Set design tokens** via `set_variables` mapping theme.md to `--` prefixed variable names (referenced as `$--` in fills)
3. **Load style guide** via `get_style_guide` using the brief's `style_guide` name
4. **Load guidelines** via `get_guidelines("landing-page")` for Pencil landing page patterns
5. **Create page container** at 1440px wide, vertical layout, `fit_content(2000)`
6. **Render header** as first child
7. **Render each section** sequentially as children of the page container
8. **Render footer** as last child
9. **Validate** via `get_screenshot` and `snapshot_layout`

### Batching Strategy

Aim for 15-25 operations per `batch_design` call. One batch per section is typical:

- **Header:** ~5 ops (frame + logo + spacer + button + text)
- **Hero:** ~8 ops (frame + content frame + label + headline + subline + button frame + button text + optional image)
- **Feature-alternating:** ~7 ops (frame + content + image frame + G() + label + headline + body)
- **Stat-row:** ~12 ops (frame + content + label + headline + 3-4 stat cards x 2-3 ops each)
- **CTA:** ~6 ops (frame + content + headline + subline + button frame + button text)
- **Footer:** ~6 ops (frame + content + left + right + texts)

### Image Generation

- Use G() on dedicated frames — never on text-containing frames
- Hero background: create image frame, G(), then overlay frame with `#000000B3`
- Feature images: 560x400px frames with `cornerRadius: 12`
- Default to `"ai"` type for all images. Use `"stock"` only for simple 2-3 keyword searches (Unsplash fails with >4 keywords)
