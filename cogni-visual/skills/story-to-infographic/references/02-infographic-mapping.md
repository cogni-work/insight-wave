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
| Trend report, market analysis, research report | `data-viz` | Data-forward aesthetic matches analytical content |
| Executive summary, board presentation, investment thesis | `editorial` | Clean magazine aesthetic signals authority |
| Workshop material, ideation output, brainstorm summary | `sketchnote` | Informal feel matches collaborative context |
| Compliance report, governance overview, regulatory content | `corporate` | Conservative aesthetic builds trust |
| Strategy session, internal alignment, team planning | `whiteboard` | Minimal aesthetic avoids distraction |

### Arc Type → Style Preset (secondary heuristic)

When source context is ambiguous, arc type provides a signal:

| Arc Type | Preferred Style | Why |
|----------|----------------|-----|
| `why-change` | `data-viz` or `editorial` | Evidence-heavy arcs need data-forward or authoritative aesthetics |
| `problem-solution` | `editorial` or `corporate` | Solution framing benefits from clean, trustworthy aesthetics |
| `journey` | `sketchnote` or `whiteboard` | Journey arcs have a narrative quality that informal styles support |
| `argument` | `editorial` | Rhetorical structure benefits from strong type hierarchy |
| `report` | `data-viz` | Reports are inherently data-forward |

### User Override

Style preset should always be presented as a recommendation, not a decision. If interactive,
present the top 2-3 recommendations with reasoning. The user's context awareness (audience,
setting, brand requirements) overrides any heuristic.

## Layout + Style Compatibility

All 7 layouts work with all 5 style presets — there are no forbidden combinations. However,
some combinations are particularly effective:

| | editorial | data-viz | sketchnote | corporate | whiteboard |
|---|---|---|---|---|---|
| stat-heavy | good | **excellent** | ok | good | ok |
| timeline-flow | good | ok | **excellent** | ok | good |
| comparison | **excellent** | good | ok | good | good |
| hub-spoke | good | ok | **excellent** | ok | **excellent** |
| funnel-pyramid | good | good | ok | **excellent** | ok |
| list-grid | good | ok | **excellent** | good | good |
| flow-diagram | good | **excellent** | ok | good | good |
