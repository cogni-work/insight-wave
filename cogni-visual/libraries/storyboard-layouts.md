---
library_id: storyboard-layouts
version: 2.0.0
created: 2026-02-27
---

# Storyboard Layout Library

Poster composition model, section stacking rules, portrait layout adaptations, dimension system, canvas arrangement, and print constraints for multi-poster storyboards rendered via Pencil MCP.

**Key design:** Storyboards reuse web section types (from `web-layouts.md`) but paginate them into max 5 portrait DIN A posters. Each poster contains 1-3 stacked web sections. The agent MUST read both this file AND `web-layouts.md` for complete rendering instructions.

---

## Dimension System

**Base design resolution:** 1440 x 2036 px (portrait DIN A ratio: 1 : sqrt(2))

All design is authored at base resolution. Scale factors multiply all dimensions for print at 150 DPI.

### Scale Factors to Print (150 DPI)

| Format | Print pixels (w x h) | Scale factor | Notes |
|--------|---------------------|--------------|-------|
| A0 | 4961 x 7016 | 3.445x | Exhibition / conference |
| A1 | 3508 x 4961 | 2.437x | Default poster size |
| A2 | 2480 x 3508 | 1.722x | Office / meeting room |
| A3 | 1754 x 2480 | 1.218x | Desktop / handout |

**Default:** A1 portrait (3508 x 4961 px at print, 1440 x 2036 px at design resolution).

**Orientation:** Portrait only. Landscape is not supported.

---

## Poster Composition Model

Every poster has 3 fixed zones: header strip, content area, and footer strip. The content area contains 1-3 stacked web section types.

```
+==================================================================+
|  HEADER STRIP (64px at base / 3%)                                 |
|  Dark background, sequence "2/4", arc station label "WHY NOW"     |
+==================================================================+
|                                                                   |
|  CONTENT AREA (1924px at base / 95%)                              |
|                                                                   |
|  +--------------------------------------------------------------+ |
|  |  Section 1 (e.g., stat-row, dark theme)                      | |
|  |  Height: proportional allocation (e.g., 45%)                 | |
|  +--------------------------------------------------------------+ |
|  |  --- 1px divider line, muted color ---                       | |
|  +--------------------------------------------------------------+ |
|  |  Section 2 (e.g., comparison, light theme)                   | |
|  |  Height: proportional allocation (e.g., 55%)                 | |
|  +--------------------------------------------------------------+ |
|                                                                   |
+==================================================================+
|  FOOTER STRIP (48px at base / 2%)                                 |
|  Customer | Provider | Date | Page N/M                            |
+==================================================================+
```

### Zone Heights (Base Resolution — 2036px total)

| Zone | Height | Percentage |
|------|--------|------------|
| Header strip | 64px | 3% |
| Content area | 1924px | 95% |
| Footer strip | 48px | 2% |

### Header Strip

- Background: `$--surface-dark`
- Sequence: bold, 28px, white (e.g., "2/4")
- Arc station label: bold, 14px, uppercase, `$--accent` (e.g., "WHY NOW")
- Padding: 24px horizontal

### Footer Strip

- Background: `$--surface-dark` at 80% opacity
- Content: `{customer} | {provider} | {date} | Page {n}/{total}`
- Font: 12px, regular, `$--surface-dark-muted`
- Padding: 24px horizontal

---

## Section Height Allocation

Sections within a poster's content area share the 1924px (base) height proportionally.

### Allocation Table

| Sections per poster | Allocation pattern | Example heights (base px) |
|--------------------|--------------------|---------------------------|
| 1 section | 100% | 1924 |
| 2 sections | 50/50, 55/45, or 60/40 | 962/962, 1058/866, 1154/770 |
| 3 sections | 40/30/30 or 35/35/30 | 770/577/577 or 673/673/578 |

### Allocation Heuristic

Choose the split ratio based on content density:

```
2-section poster:
  IF section 1 has image_prompt AND section 2 does not → 55/45
  IF section 2 has image_prompt AND section 1 does not → 45/55
  IF both have image_prompt or neither does → 50/50
  IF section 1 is hero → 60/40

3-section poster:
  IF first section is hero → 40/30/30
  OTHERWISE → 35/35/30 (last section slightly smaller)
```

### Section Divider

Between stacked sections within a poster:

- Line: 1px height, full content width
- Color: `$--foreground-muted` at 20% opacity
- Margin: 0px (sections are edge-to-edge, divider sits between)

---

## Portrait Layout Adaptations

Web section types are designed for 1440px wide horizontal layouts. On portrait posters (1440px wide but vertically constrained), some section types need adaptation.

### Adapted Section Types

| Section Type | Web Layout | Portrait Adaptation |
|-------------|-----------|---------------------|
| `stat-row` | 3-4 cards in horizontal row | **2x2 grid** (2 columns, 2 rows) |
| `feature-alternating` | Image and text side-by-side | **Vertical stack**: image on top (40%), text below (60%) |
| `timeline` | Horizontal numbered steps | **Vertical steps**: numbers on left, text on right |
| `comparison` | Two columns side-by-side | Keep horizontal (fits 1440px width) |
| `feature-grid` | 2x2 or 3x2 card grid | Keep horizontal (fits 1440px width) |
| `hero` | Full-width, 600px height | Scale height to section allocation |
| `problem-statement` | Stat card + context side-by-side | Keep horizontal (fits 1440px width) |
| `testimonial` | Centered quote | Keep centered (fits 1440px width) |
| `text-block` | Centered prose | Keep centered (fits 1440px width) |
| `cta` | Centered headline + button | Keep centered (fits 1440px width) |

### stat-row: 2x2 Grid

```
stat-section (frame, fill_container, dark bg)
  stat-content (frame, vertical, center-aligned, padding [40, 60])
    headline (text, 32px scaled, bold, white)
    stat-grid (frame, horizontal, wrap, gap 24)
      stat-card (frame, vertical, width 50%, center) [repeat 2-4x]
        number (text, 40px scaled, bold, white)
        label (text, 14px scaled, regular, muted-light)
```

### feature-alternating: Vertical Stack

```
feature-section (frame, fill_container, light/light-alt bg, vertical)
  image-frame (frame, fill_container, height 40% of section, rounded)
    [G() generated image]
  text-column (frame, vertical, fill_container, padding [24, 60], gap 12)
    section-label (text, 12px scaled, uppercase, primary)
    headline (text, 32px scaled, bold, foreground)
    body (text, 14px scaled, regular, foreground-muted)
```

### timeline: Vertical Steps

```
timeline-section (frame, fill_container, light/light-alt bg, vertical)
  timeline-content (frame, vertical, padding [40, 60], gap 24)
    headline (text, 32px scaled, bold, foreground)
    steps-column (frame, vertical, gap 20)
      step (frame, horizontal, gap 16, align-center) [repeat 3-5x]
        step-circle (frame, 40x40, circle, primary bg)
          number-text (text, 16px, bold, white, center)
        step-content (frame, vertical, fill_container)
          step-label (text, 14px scaled, bold, foreground)
          step-description (text, 12px scaled, regular, foreground-muted)
```

---

## Typography Scale

All font sizes are specified at **base design resolution** (1440x2036). Multiply by scale factor for print.

| Element | Base Size | A0 (x3.445) | A1 (x2.437) | A2 (x1.722) | A3 (x1.218) |
|---------|-----------|-------------|-------------|-------------|-------------|
| Section headline | 32px | 110px | 78px | 55px | 39px |
| Section subline | 16px | 55px | 39px | 28px | 19px |
| Body text | 14px | 48px | 34px | 24px | 17px |
| Stat number | 40px | 138px | 97px | 69px | 49px |
| Stat label | 14px | 48px | 34px | 24px | 17px |
| Card headline | 18px | 62px | 44px | 31px | 22px |
| Card body | 12px | 41px | 29px | 21px | 15px |
| CTA button text | 16px | 55px | 39px | 28px | 19px |
| Section label | 12px | 41px | 29px | 21px | 15px |
| Quote text | 20px | 69px | 49px | 34px | 24px |
| Header sequence | 28px | 96px | 68px | 48px | 34px |
| Header arc label | 14px | 48px | 34px | 24px | 17px |
| Footer text | 12px | 41px | 29px | 21px | 15px |

**Minimum body text:** Never below 14px at base (17px at A3). Below this, text becomes unreadable at arm's length.

---

## Canvas Arrangement

All posters are placed as side-by-side root-level frames in a single .pen document, arranged left-to-right in sequence order.

```
+--------+  gap  +--------+  gap  +--------+  gap  +--------+
| Poster |       | Poster |       | Poster |       | Poster |
|   1    |       |   2    |       |   3    |       |   4    |
+--------+       +--------+       +--------+       +--------+
```

### Gap and Position

| Property | Base value | Scaled (A1) |
|----------|-----------|-------------|
| Gap between posters | 200px | 487px |
| poster_x formula | `n * (poster_width + gap)` | — |
| poster_y | 0 | 0 |

Where `n` = 0-based poster index. At print resolution, use `poster_width` and `gap` in print pixels.

**Example (A1, 4 posters):**
```
Poster 0: x=0,    y=0  (3508 x 4961)
Poster 1: x=3995, y=0
Poster 2: x=7990, y=0
Poster 3: x=11985, y=0
```

---

## Print Constraints

### Bleed Margin

| Format | Bleed (all edges) |
|--------|-------------------|
| A0 | 56px |
| A1 | 40px |
| A2 | 28px |
| A3 | 20px |

### Safe Text Area

All text must stay within the safe text area (bleed margin inset from poster edges):

| Format | Safe Area Inset |
|--------|----------------|
| A0 | 80px |
| A1 | 60px |
| A2 | 40px |
| A3 | 30px |

### Color Advisory

- Use rich black (`#1A1A1A` or theme `$--surface-dark`) for large fills — avoid pure `#000000`
- Minimum contrast ratio: 4.5:1 for body text, 3:1 for large headlines
- Test accent colors for print vibrancy

### Resolution

- All AI-generated images should be prompted at print resolution
- Image prompts include "print resolution, high detail" suffix
- Minimum effective resolution: 150 DPI at final print size

---

## Pencil MCP Rendering Notes

When the storyboard agent renders a brief via Pencil MCP:

1. **Open document at explicit file path** (NOT `open_document("new")`) — ensures images directory exists for G() calls
2. **Set design tokens** via `set_variables` mapping theme.md to `--` prefixed variable names (same 14 variables as web)
3. **Load style guide** via `get_style_guide` using the brief's `style_guide` name
4. **Load guidelines** via `get_guidelines("design-system")` for composition patterns
5. **Read BOTH** this file AND `web-layouts.md` for section type schemas
6. **Create each poster** as a root-level frame at computed x position (print dimensions)
7. **Render poster zones** in order: frame → header strip → section frames → section content → footer strip
8. **For each section within a poster**: calculate section height from allocation, create section frame, render content per web section schema (with portrait adaptations)
9. **Generate images** using G() with AI type (default) — max 2 images per poster
10. **Screenshot each poster** individually for validation
11. **Run `snapshot_layout(problemsOnly: true)`** for overlap detection

### Batching Strategy

Aim for 15-25 operations per `batch_design` call. One batch per poster is typical:

- **1-section poster:** ~12 ops (poster frame + header + section frame + section content + footer)
- **2-section poster:** ~20 ops (poster frame + header + 2 section frames + 2x section content + divider + footer)
- **3-section poster:** ~25 ops (poster frame + header + 3 section frames + 3x section content + 2 dividers + footer)

### Image Generation

- Use G() on dedicated image frames — never on text-containing frames
- Hero sections: create bg image frame, G(), then overlay frame with `#000000B3`
- Feature images: full-width within section, height proportional to section allocation
- Default to `"ai"` type for all images. Stock type fails with >4 keyword prompts.
- Max 2 images per poster (one per image-capable section within the poster)
