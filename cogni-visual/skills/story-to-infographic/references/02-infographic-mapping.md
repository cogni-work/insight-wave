# Infographic Mapping Rules

How to map distilled content to the right layout type and style preset. The mapping is
deterministic — the content profile points to a layout, and the context points to a style.

## Layout Type Selection

### Content Pattern → Layout Type

After distillation, classify the content profile and match to a layout:

| Content Profile | Layout Type | Why |
|----------------|-------------|-----|
| 3+ hero numbers, chart data present | `stat-heavy` | Numbers are the story; visual hierarchy centers on data |
| Clear 4-8 step process or timeline | `timeline-flow` | The sequence IS the message; chronological order matters |
| Before/after, vs., or contrast pair | `comparison` | Two-column contrast is the clearest way to show difference |
| Central concept with 4-6 related topics | `hub-spoke` | Radial layout shows relationships to a center |
| Hierarchical narrowing (3-5 tiers) | `funnel-pyramid` | Tiered bands show filtering or prioritization |
| 4-8 equal-weight tips, features, or items | `list-grid` | Grid shows parallel items without implying order |
| Complex branching workflow or decision tree | `flow-diagram` | SVG diagram handles complexity that strips can't |

### Disambiguation Rules

When content matches multiple layouts:

1. **Numbers + Process:** If the process is the primary story arc and numbers support it → `timeline-flow`. If numbers are the primary story and process is context → `stat-heavy` with a process-strip block.

2. **Numbers + Comparison:** If the comparison defines the narrative structure (before/after transformation) → `comparison` with kpi-cards. If numbers stand alone and comparison is supporting → `stat-heavy` with stat-row.

3. **Tips + Numbers:** If each tip has associated data → `list-grid` with stats in sublabels. If tips are qualitative → `list-grid` without numbers.

4. **Process + Comparison:** If comparing two processes → `comparison`. If single process with before/after context → `timeline-flow` with a comparison-pair block above or below.

### Orientation Heuristics

| Layout Type | Default Orientation | Why |
|-------------|-------------------|-----|
| `stat-heavy` | landscape | Hero numbers need horizontal space |
| `timeline-flow` | landscape (horizontal) or portrait (vertical) | Horizontal flows read left-to-right; vertical flows work better in portrait |
| `comparison` | landscape | Side-by-side needs width |
| `hub-spoke` | landscape | Radial layout needs balanced dimensions |
| `funnel-pyramid` | portrait | Vertical narrowing reads top-to-bottom |
| `list-grid` | landscape (2x2) or portrait (2x4) | Depends on item count |
| `flow-diagram` | landscape | SVG diagrams need horizontal space |

## Style Preset Selection

### Context → Style Preset

| Source Context | Style Preset | Why |
|---------------|-------------|-----|
| C-suite insight summary, investor data story, leadership briefing, flagship trend report | `economist` | The Economist magazine aesthetic — dense stats, red accent, cream background, maximum editorial credibility |
| Trend report, market analysis, research report (data-forward) | `data-viz` | Dashboard aesthetic matches analytical content when density isn't the goal |
| Executive summary, board presentation, investment thesis | `editorial` | Clean magazine aesthetic signals authority without Economist-level density |
| Workshop material, ideation output, brainstorm summary | `sketchnote` | Informal hand-drawn feel matches collaborative context |
| Compliance report, governance overview, regulatory content | `corporate` | Conservative aesthetic builds trust |
| Strategy session, internal alignment, team planning | `whiteboard` | Minimal hand-drawn aesthetic avoids distraction |

**Family rule:** `economist`, `editorial`, `data-viz`, and `corporate` all belong to the
**editorial family** (rendered via Pencil MCP). `sketchnote` and `whiteboard` belong to the
**hand-drawn family** (rendered via Excalidraw). Picking a preset also picks the renderer —
see `03-style-presets.md` for the full family description.

### Arc Type → Style Preset (secondary heuristic)

When source context is ambiguous, arc type provides a signal:

| Arc Type | Preferred Style | Why |
|----------|----------------|-----|
| `why-change` | `economist`, `data-viz`, or `editorial` | Evidence-heavy arcs need dense, data-forward or authoritative aesthetics — `economist` when the audience is C-suite |
| `problem-solution` | `editorial` or `corporate` | Solution framing benefits from clean, trustworthy aesthetics |
| `journey` | `sketchnote` or `whiteboard` | Journey arcs have a narrative quality that informal hand-drawn styles support |
| `argument` | `editorial` or `economist` | Rhetorical structure benefits from strong type hierarchy; `economist` when the argument rests on dense data |
| `report` | `economist` or `data-viz` | Reports are inherently data-forward — `economist` for flagship leadership reports, `data-viz` for dashboards |

### User Override

Style preset should always be presented as a recommendation, not a decision. If interactive,
present the top 2-3 recommendations with reasoning. The user's context awareness (audience,
setting, brand requirements) overrides any heuristic.

## Layout + Style Compatibility

All 7 layouts work with all 6 style presets — there are no forbidden combinations. However,
some combinations are particularly effective. Columns are grouped by family:

| | **economist** | editorial | data-viz | corporate | **sketchnote** | whiteboard |
|---|---|---|---|---|---|---|
| | *editorial family (Pencil)* | editorial | editorial | editorial | *hand-drawn family (Excalidraw)* | hand-drawn |
| stat-heavy | **excellent** | good | **excellent** | good | ok | ok |
| timeline-flow | good | good | ok | ok | **excellent** | good |
| comparison | **excellent** | **excellent** | good | good | ok | good |
| hub-spoke | good | good | ok | ok | **excellent** | **excellent** |
| funnel-pyramid | good | good | good | **excellent** | ok | ok |
| list-grid | good | good | ok | good | **excellent** | good |
| flow-diagram | **excellent** | good | **excellent** | good | ok | good |

## Editorial Sketch Blocks (v1.2)

**Only emit editorial-sketch blocks when the chosen `style_preset` is in the editorial
family** (`economist`, `editorial`, `data-viz`, `corporate`). The hand-drawn family
(`sketchnote`, `whiteboard`) already covers illustration natively via Excalidraw primitives
and must not receive editorial-sketch blocks — the two rendering traditions would clash.

An editorial sketch is a one-color outline line-art landmark (the `editorial-sketch` agent
rasterizes it to PNG and the render-infographic-pencil agent drops it into a Pencil frame
beside its `Data-Link` partner). It exists to make a data block read faster — a map next
to a regional GDP stat, a factory silhouette next to a productivity number, a stakeholder
silhouette next to a pull-quote. It never spans a row alone, and it never carries its own
information.

### When to emit an editorial-sketch block

| Content Pattern | Sketch-Subtype | Example Subject |
|---|---|---|
| A data block's scope is a named region, country, territory, or market | `cartographic-outline` | "Outline of Germany with 4 city dot markers" |
| A data block rests on a single stakeholder's quote or role | `stakeholder-silhouette` | "Head-and-shoulders silhouette, neutral pose" |
| A data block is about a concrete physical artifact (building, machine, product, tool) | `object-line-art` | "Line-art view of a factory with two smokestacks" |
| A data block explains a 3–5 step process and the process strip would be too heavy | `process-diagram` | "Circular 4-step loop with arrows" |
| A narrative passage leans on a clear visual metaphor (rising tide, spiral, growing tree, branching path) | `metaphor-sketch` | "Upward rising-tide curve over a flat horizon line" |

### When NOT to emit an editorial-sketch block

- The page has no room — editorial density already saturates the rows.
- The data block has no clear illustrative anchor (numbers only, no geographic / physical /
  metaphorical subject). Forced illustration is worse than no illustration.
- The chosen layout is `flow-diagram` or `hub-spoke` — those layouts already use the
  `svg-diagram` block in **concept mode** for their central diagram. Mixing modes on the
  same page fights itself.
- The `style_preset` is `sketchnote` or `whiteboard`. Use Excalidraw primitives instead.

### Budget and discipline

- **Max 2 editorial-sketch blocks per page.** One is usually the right answer; two only
  when the narrative genuinely has two distinct visual anchors (e.g., a regional scope
  *and* a stakeholder voice). Three or more becomes decoration.
- **Ratio rule:** at most **one editorial-sketch per 3 content blocks**. A 4-block brief
  gets at most one sketch; a 10-block brief gets at most two.
- **Subject must be concrete.** A reader should be able to name what the sketch depicts in
  one noun phrase. No abstract swirls, no decorative flourishes, no "innovation
  representing progress."
- **Pair with a specific partner.** Every editorial-sketch block declares `Data-Link:` —
  the id (or 1-based index) of the sibling block it illustrates. The sketch renders beside
  that partner in the same row.

### Block shape

```yaml
Block-Type: svg-diagram
Mode: editorial-sketch
Sketch-Subtype: cartographic-outline
Subject: "Outline of Germany with dot markers for Berlin, Munich, Hamburg, Cologne"
Data-Link: block-3                 # the kpi-card or chart this illustrates
Caption: "DACH-Region"             # optional, max 4 words — rendered in adjacent Pencil text node
Max-Width-Ratio: 0.33              # default 0.33; 0.25 or 0.4 for tighter/wider variants
```

Full schema and constraint details live in `libraries/infographic-layouts.md` under the
`svg-diagram` section, and the rendering discipline lives in `agents/editorial-sketch.md`.
