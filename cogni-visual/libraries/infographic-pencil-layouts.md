# Infographic Pencil Reference

Pencil MCP reference for the `render-infographic-pencil` agent. Contains tool-specific
knowledge the LLM cannot derive from design experience alone: token overrides, icon mapping,
and API syntax patterns.

---

## Canvas Specification

| Orientation | Width | Height | Margin | Usable Area |
|-------------|-------|--------|--------|-------------|
| portrait (default) | 1080 | 1528 | 48 | 984 x 1432 |
| landscape | 1528 | 1080 | 48 | 1432 x 984 |

---

## Economist Design Tokens — Discipline, Not Red

The Economist style is **structural discipline**, not a specific red. The agent renders every
editorial preset (`economist`, `editorial`, `data-viz`, `corporate`) using exactly three
colors on a cream surface: primary accent, secondary accent, and near-black text. The source
of those colors is the **project theme** by default — the page reads as "Economist-shaped,
wearing the brand". Only when the brief sets `palette_override: canonical` does the agent
fall back to the hard-coded Economist palette below.

### Theme-driven path (default — all editorial presets)

The agent derives the tokens from `theme.md` in Step 2 of the workflow. The canonical
mapping lives in `agents/render-infographic-pencil.md:Step 2`. The short version:

- `--accent-primary` ← `theme.primary`
- `--accent-secondary` ← `theme.secondary` (or amber-ish fallback)
- `--text-base` ← near-black (`theme.foreground` if near-black, else `#1A1A1A`)
- `--surface` ← cream-leaning (`theme.background` if cream, else `#FBF9F3`)
- `--rule-color` ← `--accent-primary` (rules are always the primary accent)
- `--chart-fill` ← `--accent-primary`
- `--chart-fill-2` ← `--accent-secondary`

No fourth accent color. No tinted block backgrounds. No card borders.

**One-color icon discipline.** Every icon on the page (`type: "icon_font"` elements in
kpi-cards, stat-rows, icon-grids, process-strips, CTA buttons) uses `$--accent-primary` —
never `$--accent-secondary`. The secondary accent exists **only** for `chart-fill-2` on
contrast bar charts. A stat-row icon in amber while an adjacent kpi-card icon is red reads
as traffic-light coding and breaks editorial authority. This is a firm rule, not a guideline.

### Canonical Economist palette (opt-in — `palette_override: canonical`)

When the brief explicitly sets `palette_override: canonical` (and `style_preset: economist`),
call `set_variables` with these exact values. They reproduce a canonical Economist data page.

```
--accent-primary:     #C00000    (Economist red)
--accent-secondary:   #D4A017    (Economist amber)
--text-base:          #1A1A1A    (near-black)
--text-muted:         #666666    (mid-grey for sublabels)
--surface:            #FBF9F3    (cream)
--surface-alt:        #F0EDE4    (darker cream for alternate zones)
--surface-dark:       #1A1A1A    (dark bands)
--surface-dark-text:  #FFFFFF    (white on dark)
--surface-dark-muted: #AAAAAA    (muted on dark)
--rule-color:         #C00000    (section divider rule lines = primary)
--chart-fill:         #C00000    (primary bar fill = primary)
--chart-fill-2:       #D4A017    (secondary bar = amber)
```

Use only when reproducing The Economist aesthetic verbatim (portfolio examples, editorial-
anchor demonstrations). Do not force canonical silently — the brief must opt in.

### Canonical fallback (theme unavailable)

If `theme.md` cannot be read and `palette_override` is unset, use the canonical Economist
palette as a safe default — a faithful Economist reproduction is always better than an
uncoordinated mix of brand-agnostic guesses.

---

## Lucide Icon Mapping

Map brief `Icon-Prompt` descriptions to Lucide icon names for `icon_font` elements.

| Prompt Pattern | Lucide Icon |
|---------------|-------------|
| shield, security, protection | `shield` |
| chart, graph, trending | `bar-chart-2` |
| brain, AI, intelligence | `brain` |
| camera, video, surveillance | `camera` |
| bell, alert, notification | `bell` |
| clock, time, speed | `clock` |
| check, success, complete | `check-circle` |
| warning, danger, risk | `triangle-alert` |
| users, people, team | `users` |
| globe, world, international | `globe` |
| target, goal, focus | `target` |
| lightbulb, idea, insight | `lightbulb` |
| arrow-up, increase, growth | `trending-up` |
| arrow-down, decrease, decline | `trending-down` |
| lock, secure, privacy | `lock` |
| euro, money, cost, price | `euro` |
| dollar, revenue, profit | `dollar-sign` |
| calendar, date, schedule | `calendar` |
| zap, energy, power, fast | `zap` |
| layers, stack, tiers | `layers` |

Default fallback: `circle-dot`

---

## Pencil batch_design Syntax

Target 15-25 operations per `batch_design` call. Create parent frames before child elements
in the same batch.

**Insert:** `foo=I("parent_id", { properties })`
**Update:** `U("node_id", { properties })`
**Copy:** `bar=C("source_id", "parent_id", { overrides })`
**Replace:** `baz=R("old_id", { properties })`

Variable references use `$--` prefix in property values: `fill: "$--accent-primary"`,
`fontFamily: "$--font-body"`. Variable names are defined WITHOUT `$` in `set_variables`.

---

## Composition Patterns for Economist Pages

These patterns show how to build the specific visual elements that make an Economist
data page feel like The Economist, not a dashboard.

### Two-Column Row (data beside data)

A chart in the left column, context stats in the right column — separated by space, not borders:

```
row=I(page, {x: 48, y: Y, width: 984, height: 280, layout: "horizontal", gap: 32})
  left=I(row, {width: 600, layout: "vertical", gap: 8})
    I(left, {type: "text", fontSize: 13, fontWeight: "Bold", content: "Sicherheitsvorfälle pro Quartal"})
    // ... chart bars here
  right=I(row, {width: 352, layout: "vertical", gap: 16})
    I(right, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--accent-primary", content: "KONTEXT DEUTSCHLAND"})
    // ... context stats here
```

### Hero KPI with Inline Stats (single row)

The hero number shares its row with 3 supporting stats — everything on one line:

```
row=I(page, {x: 48, y: Y, width: 984, height: 140, layout: "horizontal", gap: 0})
  hero=I(row, {width: 360, layout: "vertical", gap: 4})
    I(hero, {type: "icon_font", fontSize: 36, fill: "$--accent-primary", content: "shield"})
    I(hero, {type: "text", fontSize: 96, fontWeight: "Bold", fill: "$--accent-primary", content: "73%"})
    I(hero, {type: "text", fontSize: 14, fontWeight: "Bold", content: "weniger Vorfälle"})
  stats=I(row, {width: 624, layout: "horizontal", gap: 24, padding: [24, 0, 0, 48]})
    // 3 stat columns here, each with icon + number (44px) + label (11px)
```

### Red Rule Line (section divider)

```
I(page, {x: 48, y: Y, width: 984, height: 2, fill: "$--rule-color"})
```

### Editorial Annotation (prose beside data)

Short prose text that sits beside a chart or stat block, explaining context:

```
ann=I(row, {width: 300, layout: "vertical", gap: 8, padding: [8, 16, 8, 16]})
  I(ann, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--accent-primary", content: "WARUM DAS WICHTIG IST"})
  I(ann, {type: "text", fontSize: 12, lineHeight: 1.5, content: "Seit dem Pilotstart in München sinken die Vorfälle rapide. Der Trend zeigt: KI-gestützte Überwachung wirkt präventiv."})
```

### Large Illustration Icon (visual landmark)

An icon at editorial scale — serves as visual anchor, not UI element:

```
icon_bg=I(parent, {width: 80, height: 80, fill: "$--accent-primary at 8%", cornerRadius: 0})
  I(icon_bg, {type: "icon_font", fontSize: 48, fill: "$--accent-primary", content: "shield"})
```

### Section Subheading (red uppercase label)

```
I(parent, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--accent-primary", letterSpacing: 1.5, content: "DAS PROBLEM"})
```

### Proportional Bar Chart

Compute bar heights from data. With max_bar_height = 180px:

```
bar_h = (value / max_value) * 180
```

Each bar: rectangle with `fill: "$--chart-fill"`, value label (11px bold) above, category
label (10px muted) below. Bars sit directly on the cream background with thin baseline rule.

### Editorial Sketch (one-color line-art landmark beside data)

Editorial sketches arrive as pre-rasterized PNGs on disk — the `render-infographic-pencil`
agent runs Step 2.5 before opening the document, so by the time you call `batch_design` the
PNG file already exists at `{brief_dir}/.sketches/{block_id}.png`. You never call `G()` for
these — the image is deterministic, disciplined, and brand-accent-locked by the
`editorial-sketch` worker agent plus `scripts/rasterize-sketch.py`.

The sketch **pairs with its Data-Link partner inside the same row** — it is never placed on
its own row, and it is never placed in a different row from its partner. Read the brief's
`Max-Width-Ratio` to decide how much of the row width the sketch gets. **Defaults by
subtype:** `cartographic-outline` defaults to `0.4` (cartography needs pixels to stay
legible), other subtypes default to `0.33`. Give the partner the complement. Use the
standard row `gap: 32` — the sketch and its partner are a pair, not a pair-plus-gutter.

**Frame dimensions are driven by the rasterizer output, not pre-allocated.** Read `width`
and `height` from the `rasterize-sketch.py` response JSON and size the Pencil frame to
match the actual PNG aspect ratio. A portrait sketch (480×620) gets a portrait frame; a
landscape sketch (640×360) gets a landscape frame. Do not stretch, do not crop.

```
# Partner is a kpi-card on the left, sketch sits on the right, portrait PNG (480x620):
# sketch_col gets 394px (≈0.4 of 984), so the frame is ~394x509 preserving the 480:620 ratio.
row=I(page, {x: 48, y: Y, width: 984, height: 540, layout: "horizontal", gap: 32})
  kpi=I(row, {width: 546, layout: "vertical", gap: 8})
    // ... hero number, label, sublabel ...
  sketch_col=I(row, {width: 394, layout: "vertical", gap: 8, padding: [16, 0, 0, 0]})
    I(sketch_col, {type: "text", fontSize: 11, fontWeight: "Bold", fill: "$--accent-primary", letterSpacing: 1.5, content: "DACH-REGION"})
    I(sketch_col, {type: "frame", name: "sketch-block-3", width: 394, height: 509, fill: {type: "image", src: "{brief_dir}/.sketches/block-3.png", fit: "contain"}})
```

**Caption discipline:** render exactly the brief's `Caption` field as a single uppercase
letterspaced primary-accent label above (or below) the sketch frame — nothing else. No
agent-invented sub-captions like "Cities: X, Y, Z", no marker list, no attribution line.
If the brief has no `Caption`, the sketch carries no label at all. The markers are
already visible in the sketch; labeling them redundantly violates data-ink discipline.

**Discipline rules for sketch frames:**

- `cornerRadius: 0` — never rounded, even when other Pencil examples show rounded image frames.
- No `filter`, no shadow, no border — the sketch is already outline-only and any Pencil-side
  effect would double-decorate it.
- `fit: "contain"` — preserve the rasterized aspect ratio. Never `fit: "cover"` (would crop).
- The caption label (11px bold primary-accent uppercase, letterSpacing 1.5) is a **separate
  Pencil text node above or below the sketch frame**, never drawn inside the SVG. This is
  how the caption stays in brand typography.
- `width`/`height` on the frame match the PNG's real rasterized dimensions (the rasterizer
  returned them in its JSON output). Do not stretch or squash the image.

**When to place the sketch on the left vs right of its partner:**

- If the partner's heaviest visual element sits on the partner's left edge (e.g., a hero
  number in the left column of a kpi-card), put the sketch on the right to keep the eye's
  landing point anchored.
- If the partner is a chart with bars stepping up from left to right, put the sketch on the
  left so the eye doesn't bounce back from the growth direction.
- If the partner is a pull-quote, put the sketch on the opposite side from the quote's
  emphasis mark / attribution.
- Default when unsure: sketch right, partner left.
