# Infographic Layouts

Layout type schemas and block type catalog for infographic briefs. The `story-to-infographic`
skill selects one layout type based on content analysis, and the rendering agents
(`render-infographic-excalidraw` and `render-infographic-pencil`, dispatched by the
`/render-infographic` command) use these schemas to compose the visual output.

Infographics are single-page visual summaries — they distill a narrative into a scannable
composition of numbers, icons, short text, and optional charts. Every infographic has exactly
one layout type that determines the page-level composition.

## Layout Types

- [timeline-flow](#timeline-flow)
- [comparison](#comparison)
- [stat-heavy](#stat-heavy)
- [hub-spoke](#hub-spoke)
- [funnel-pyramid](#funnel-pyramid)
- [list-grid](#list-grid)
- [flow-diagram](#flow-diagram)

---

## timeline-flow

Horizontal or vertical step sequence showing a process, journey, or chronological arc.

**Best for:** Process narratives, chronological arcs, implementation roadmaps, before/after journeys.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├────┬────┬────┬────┬────┬────┬───────────┤
│ S1 → S2 → S3 → S4 → S5 → S6           │  4-8 step blocks with connector arrows
├─────────────────────────────────────────┤
│  optional: stat-row or text-block       │  supporting context below the flow
├─────────────────────────────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- 4-8 step blocks (fewer makes it trivial, more overflows)
- Each step: icon + label (2-4 words) + optional sublabel (max 8 words)
- Connector arrows between steps (rendered by generator, not in brief)
- Orientation auto-selected: landscape → horizontal, portrait → vertical

**Required blocks:** title, process-strip, footer
**Optional blocks:** stat-row, text-block, cta

---

## comparison

Side-by-side or before/after showing contrast between two states, options, or approaches.

**Best for:** Competitive analysis, transformation arcs, before/after, option evaluation, Handeln vs. Nichthandeln.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├──────────────────┬──────────────────────┤
│   LEFT COLUMN    │   RIGHT COLUMN       │  comparison-pair blocks
│   (Before/A)     │   (After/B)          │  mirrored structure
│   - bullet       │   - bullet           │
│   - bullet       │   - bullet           │
├──────────────────┴──────────────────────┤
│  optional: kpi-card or stat-row         │  summary evidence
├─────────────────────────────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- Exactly 2 columns (no 3-way comparison — use list-grid for that)
- Each column: label + 3-5 bullets (max 6 words each)
- Optional icon per column
- Color coding: left column uses muted tones, right column uses accent tones (theme-driven)

**Required blocks:** title, comparison-pair, footer
**Optional blocks:** kpi-card, stat-row, text-block, cta

---

## stat-heavy

Hero numbers with supporting evidence — the dashboard-style infographic.

**Best for:** Data-rich narratives, trend reports, market sizing, KPI dashboards, impact summaries.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├──────────┬──────────┬───────────────────┤
│ KPI card │ KPI card │ KPI card          │  1-3 hero numbers (kpi-card)
├──────────┴──────────┴───────────────────┤
│  chart block (bar, doughnut, line)      │  1-2 Chart.js visualizations
├─────────────────────────────────────────┤
│  stat-row (3-4 supporting stats)        │  secondary evidence
├─────────────────────────────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- 1-3 KPI cards (hero numbers) — the visual anchor
- 0-2 chart blocks — quantitative evidence
- 0-1 stat-row — secondary statistics
- Maximum 5 distinct numbers on the page (avoid number overload)

**Required blocks:** title, kpi-card (at least 1), footer
**Optional blocks:** chart, stat-row, text-block, cta

---

## hub-spoke

Central concept with radiating topic nodes — for strategic overviews and capability maps.

**Best for:** Strategic overviews, capability maps, ecosystem views, stakeholder maps, technology landscapes.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├─────────────────────────────────────────┤
│         ┌───┐                           │
│    ┌──┐ │HUB│ ┌──┐                      │  Central hub + 4-6 radiating nodes
│    │S1│←┤   ├→│S2│                      │  (rendered as icon-grid or svg-diagram)
│    └──┘ │   │ └──┘                      │
│         └─┬─┘                           │
│      ┌──┐ │ ┌──┐                        │
│      │S3│←┘→│S4│                        │
│      └──┘   └──┘                        │
├─────────────────────────────────────────┤
│  optional: text-block or stat-row       │
├─────────────────────────────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- Exactly 1 central hub concept
- 4-6 spoke nodes (fewer is sparse, more overwhelms)
- Each spoke: icon + label (2-4 words) + optional sublabel (max 8 words)
- Hub uses svg-diagram block (type: relationship-map) or icon-grid

**Required blocks:** title, svg-diagram or icon-grid, footer
**Optional blocks:** text-block, stat-row, cta

---

## funnel-pyramid

Hierarchical narrowing — tiered horizontal bands showing filtering, prioritization, or layering.

**Best for:** Investment theses, filtering processes, maturity models, value chains, organizational layers.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├─────────────────────────────────────────┤
│  ╔═══════════════════════════════════╗   │
│  ║   TIER 1 (widest / foundation)   ║   │  3-5 tiered horizontal bands
│  ╠═════════════════════════════╣     ║   │  each band: label + description
│  ║   TIER 2                   ║     ║   │  progressive narrowing or widening
│  ╠═══════════════════╣       ║     ║   │
│  ║   TIER 3          ║       ║     ║   │
│  ╠═══════════╣       ║       ║     ║   │
│  ║  TIER 4   ║       ║       ║     ║   │
│  ╚═══════════╩═══════╩═══════╩═════╝   │
├─────────────────────────────────────────┤
│  optional: stat-row                     │
├─────────────────────────────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- 3-5 tiers (bands)
- Each tier: label (2-4 words) + description (max 15 words) + optional icon
- Direction configurable: funnel (wide→narrow, top→bottom) or pyramid (narrow→wide)
- Color intensity increases toward the apex (theme accent scaling)

**Required blocks:** title, icon-grid (used as tier bands), footer
**Optional blocks:** stat-row, text-block, kpi-card, cta

---

## list-grid

Card grid showing equal-weight items — tips, recommendations, capabilities, or checklists.

**Best for:** Best practices, recommendations, feature overviews, pros/cons lists, team capabilities.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├──────────┬──────────┬───────────────────┤
│  Card 1  │  Card 2  │  Card 3           │  2x2, 2x3, or 2x4 grid
│  icon    │  icon    │  icon             │  each card: icon + label + description
│  label   │  label   │  label            │
│  desc    │  desc    │  desc             │
├──────────┼──────────┼───────────────────┤
│  Card 4  │  Card 5  │  Card 6           │
│  icon    │  icon    │  icon             │
│  label   │  label   │  label            │
│  desc    │  desc    │  desc             │
├──────────┴──────────┴───────────────────┤
│  optional: text-block                   │
├─────────────────────────────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- 4-8 cards in a grid (2 columns, 2-4 rows)
- Each card: icon + label (2-4 words) + description (max 20 words)
- All cards must be structurally parallel (same fields, similar length)
- Grid renders as CSS Grid with equal-width columns

**Required blocks:** title, icon-grid, footer
**Optional blocks:** text-block, stat-row, cta

---

## flow-diagram

Complex workflow or decision tree — leveraging SVG concept diagrams for the central visual.

**Best for:** Complex workflows, decision trees, system architectures, integration maps, process flows with branching.

**Composition:**
```
┌─────────────────────────────────────────┐
│  title block                            │
├─────────────────────────────────────────┤
│                                         │
│  SVG process diagram                    │  Central svg-diagram block
│  (via concept-diagram-svg agent)        │  occupies 50-60% of vertical space
│                                         │
├──────────┬──────────┬───────────────────┤
│  Note 1  │  Note 2  │  Note 3           │  2-4 annotation blocks below
├──────────┴──────────┴───────────────────┤
│  cta + footer                           │
└─────────────────────────────────────────┘
```

**Constraints:**
- Exactly 1 svg-diagram block (central visual)
- SVG diagram types: process-flow, concept-sketch (convergence, phase-progression)
- 2-4 annotation text-blocks below the diagram
- SVG viewport: min 800x400px, max 1200x600px

**Required blocks:** title, svg-diagram, footer
**Optional blocks:** text-block (2-4 annotations), stat-row, cta

---

## Block Type Catalog

These are the content primitives that compose infographic layouts. Each block type has a
fixed schema — the brief specifies content, the renderer handles all visual treatment.

### title

Page title area. Every infographic has exactly one.

```yaml
Block-Type: title
Headline: "Assertion headline with verb + consequence"  # max 12 words
Subline: "Supporting context"                            # max 15 words, optional
Metadata: "Customer | Provider | Date"                   # optional
```

### kpi-card

Single hero statistic with context. The visual anchor of stat-heavy infographics.

```yaml
Block-Type: kpi-card
Hero-Number: "73%"                    # The number, formatted for display
Hero-Label: "weniger Vorfälle"        # max 4 words
Sublabel: "nach 6 Monaten Pilot"      # max 8 words, optional
Icon-Prompt: "shield with checkmark"   # for concept-diagram-svg, optional
Source: "Interne Pilotdaten, 2025"     # attribution, optional
```

**Word limits:** 15 words total across all fields.

### stat-row

Row of 2-4 small statistics. Supporting evidence, not hero numbers.

```yaml
Block-Type: stat-row
Stats:
  - number: "688"
    label: "Bahnsuizide 2023"          # max 4 words
    icon-prompt: "warning triangle"     # optional
  - number: "2.661"
    label: "Übergriffe an Bahnhöfen"
    icon-prompt: "alert circle"
```

**Constraints:** 2-4 stats. Each stat: number + label (max 4 words) + optional icon.

### chart

Chart.js data visualization. Quantitative evidence.

```yaml
Block-Type: chart
Chart-Type: bar                        # bar, doughnut, line, radar, stacked-bar
Chart-Title: "Vorfälle pro Quartal"    # max 6 words
Data:
  labels: ["Q1", "Q2", "Q3", "Q4"]
  datasets:
    - label: "Vorfälle"
      values: [172, 168, 89, 47]
```

**Chart types:** bar (default), doughnut, line, radar, stacked-bar. Theme colors auto-applied.
**Constraints:** Max 2 chart blocks per infographic. Keep data series to 1-2 datasets.

### process-strip

Horizontal or vertical step sequence. The backbone of timeline-flow layouts.

```yaml
Block-Type: process-strip
Steps:
  - label: "Kameradaten"               # max 3 words
    icon-prompt: "camera lens"
  - label: "KI-Analyse"
    icon-prompt: "brain circuit"
  - label: "Echtzeit-Alert"
    icon-prompt: "bell notification"
```

**Constraints:** 4-8 steps. Each step: label (2-4 words) + icon-prompt. Connector arrows between steps are rendered automatically.

### text-block

Short prose block with optional icon. Use sparingly — infographics prefer visual elements.

```yaml
Block-Type: text-block
Headline: "Assertion headline"         # max 8 words, must contain verb
Body: "Short supporting text."         # max 40 words
Icon-Prompt: "lightbulb idea"          # optional
```

**Word limits:** Headline max 8 words, body max 40 words. If body exceeds 40 words, the content needs further distillation.

### comparison-pair

Two-column comparison. The core block for comparison layouts.

```yaml
Block-Type: comparison-pair
Left:
  label: "Heute"                       # max 3 words
  icon-prompt: "warning triangle"      # optional
  bullets:
    - "Manuelle Überwachung"           # max 6 words each
    - "Reaktiv statt präventiv"
    - "Hohe Personalkosten"
Right:
  label: "Mit KI-Videoanalytik"
  icon-prompt: "shield checkmark"
  bullets:
    - "Automatisierte Erkennung"
    - "Präventive Intervention"
    - "73% weniger Vorfälle"
```

**Constraints:** 3-5 bullets per side. Max 6 words per bullet. Structurally parallel (same number of bullets).

### icon-grid

Grid of icon-labeled items. Used for list-grid layouts and funnel tiers.

```yaml
Block-Type: icon-grid
Columns: 2                             # 2 or 3
Items:
  - icon-prompt: "shield security"
    label: "Echtzeiterkennung"         # max 3 words
    sublabel: "KI erkennt Bedrohungen in < 2 Sekunden"  # max 15 words
  - icon-prompt: "chart trending up"
    label: "Skalierbarkeit"
    sublabel: "Von 1 auf 500 Kameras ohne Mehraufwand"
```

**Constraints:** 4-8 items. Each: icon-prompt + label (2-4 words) + sublabel (max 15 words).

### svg-diagram

Dispatched to concept-diagram-svg agent. For hub-spoke and flow-diagram layouts.

```yaml
Block-Type: svg-diagram
Diagram-Type: relationship-map          # relationship-map, process-flow, concept-sketch
Concept-Subtype: convergence            # only for concept-sketch: layered-stack, convergence, phase-progression, 2x2-matrix
Data:
  hub: "KI-Videoanalytik"
  spokes:
    - label: "Echtzeiterkennung"
    - label: "Verhaltensanalyse"
    - label: "Anomalieerkennung"
    - label: "Eskalationssteuerung"
```

**Constraints:** Data format must match concept-diagram-svg agent's DATA payload schema per diagram type. See `$CLAUDE_PLUGIN_ROOT/libraries/svg-patterns.md`.

### cta

Call to action. Optional but recommended — gives the viewer a next step.

```yaml
Block-Type: cta
Headline: "Pilot in 12 Wochen starten"  # max 8 words, imperative verb
CTA-Text: "Erstgespräch buchen"         # max 4 words, action verb
CTA-Type: commit                         # explore, evaluate, commit, share
CTA-Urgency: high                        # low, medium, high
```

### footer

Page footer with attribution. Every infographic has exactly one.

```yaml
Block-Type: footer
Left: "Deutsche Bahn AG"
Center: "April 2026"
Right: "TechVision Solutions"
Source-Line: "Quellen: BKA Bundeslagebild 2023, Interne Pilotdaten"  # optional
```
