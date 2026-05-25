# Layout Renderers: Brief YAML → HTML Mapping

This reference documents how each presentation-brief layout type maps to HTML. The Python
generator (`generate-html-slides.py`) handles rendering. This file is for understanding
the field contracts when parsing the brief in Phase 1.

## Layout Field Contracts

Each layout's YAML fields must be preserved exactly when parsing into `slide-data.json`.
The Python script expects these field names and structures.

### Bottom-Banner (all layouts)

`Bottom-Banner` is layout-independent — it renders as a shared footer on every
layout, so its contract is documented once here rather than per layout. Parse it to
the **top-level** `bottom_banner` field (a sibling of `fields`). The value may be a
dict with a `Text:` key or a plain string. The legacy nested form (`Bottom-Banner`
inside `fields`, shown in some per-layout examples below) is also accepted.

### title-slide

```yaml
Title: "Main title"
Subtitle: "Supporting subtitle"
Metadata: "Customer | Provider | Date"
```

Rendered as: Full-viewport dark background, centered title with accent underline.

### stat-card-with-context

```yaml
Hero-Stat-Box:
  Number: "688"
  Label: "Description"
  Sublabel: "Additional context"
  Icon: "shield"           # optional, not rendered in HTML

Impact-Box:                 # optional
  Text: "Callout text"

Context-Box:
  Headline: "Supporting headline"
  Bullets:
    - "Bullet 1"
    - "Bullet 2 <sup>[1](url)</sup>"

Bottom-Banner:              # optional
  Text: "Banner text"
```

Rendered as: CSS Grid 40/55 split. Hero number in oversized accent-colored font.

### four-quadrants

```yaml
Quadrant-1:
  Number: "42"              # optional (stat mode)
  Label: "Category name"
  Bullets:
    - "Detail 1"
    - "Detail 2"
Quadrant-2: ...
Quadrant-3: ...
Quadrant-4: ...
```

Rendered as: CSS Grid 2x2. Each card with accent left-border.

### two-columns-equal

```yaml
Left-Column:
  Headline: "Left title"
  Bullets:
    - "Point 1"
    - "Point 2"
Right-Column:
  Headline: "Right title"
  Bullets:
    - "Point A"
    - "Point B"

Bottom-Banner:              # optional
  Text: "Banner text"
```

Rendered as: CSS Grid 50/50 with subtle divider line.

### is-does-means

```yaml
IS-Box:
  Label: "IS"               # or "IST" for German
  Text: "What it is"
DOES-Box:
  Label: "DOES"             # or "MACHT"
  Text: "What it does"
MEANS-Box:
  Label: "MEANS"            # or "BEDEUTET"
  Text: "What it means"
```

Rendered as: 3 horizontal bands with localized badges. The Python script uses the
`--language` parameter for badge labels, not the Label field.

### three-options

```yaml
Option-1:
  Title: "Option name"
  Subtitle: "Price or description"
  Bullets:
    - "Feature 1"
    - "Feature 2"
  Recommended: false
Option-2:
  Title: "Recommended option"
  Recommended: true
  ...
Option-3: ...
```

Rendered as: 3-column pricing cards. Recommended option has accent border and scale bump.

### timeline-steps

```yaml
Steps:
  - Title: "Phase 1"
    Detail: "Q1 2026"
    Bullets:
      - "Activity 1"
  - Title: "Phase 2"
    Detail: "Q2 2026"
```

Alternative format: `Step-1:`, `Step-2:`, etc. as separate fields.

Rendered as: Horizontal timeline with connected accent dots and labels below.

### process-flow

```yaml
Diagram: |
  graph LR
    A["Step 1"] --> B["Step 2"]
    B --> C["Step 3"]

Detail-Grid:                # optional
  "Step 1":
    - "Detail A"
    - "Detail B"
  "Step 2":
    - "Detail C"

Bottom-Banner:              # optional
  Text: "Banner text"
```

Rendered as: Mermaid diagram (via CDN) + optional grid of detail cards below.

### layered-architecture

Same structure as process-flow (Diagram + optional Detail-Grid). Uses Mermaid `flowchart`.

### gantt-chart

Same structure as process-flow (Diagram field only). Uses Mermaid `gantt`.

### closing-slide

```yaml
Headline: "Call to action headline"
Key-Takeaway: "One-sentence takeaway"
CTA: "Action text"          # optional
```

Rendered as: Full-viewport dark background matching title-slide. Accent underline.

### references

```yaml
References:
  - Title: "Source title"
    URL: "https://..."
  - Title: "Another source"
    URL: "https://..."
```

Alternative: plain text list or numbered items.

Rendered as: Numbered citation list with clickable links, auto-counted via CSS counter.
