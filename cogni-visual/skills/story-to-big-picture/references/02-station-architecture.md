# Station Architecture

## Purpose

Define how to decompose a narrative into journey stations for a big picture visual. Stations are the core content units -- each one is a "stop" along the journey where the viewer pauses to absorb a key message, supported by an illustration and data.

---

## Arc Analysis for Big Pictures

Big pictures reuse the same arc detection logic as story-to-slides (see `story-to-slides/references/03-story-arc-analysis.md`). The key difference is how the arc maps to *spatial position* rather than slide order.

### Arc-to-Space Mapping

| Arc Type | Spatial Pattern | Station Distribution |
|----------|----------------|---------------------|
| `why-change` | Ascending (valley to summit) | Problem stations low, solution stations high |
| `problem-solution` | Crossing (dark to light) | Problem stations left in shadow, solution right in light |
| `journey` | Linear flow (source to destination) | Chronological left-to-right |
| `argument` | Convergent (branches to trunk) | Evidence stations scattered, thesis at focal point |
| `report` | Panoramic (equal weight) | Findings distributed evenly across landscape |

### Governing Thought Placement

The governing thought appears in the **title banner** at the top of the canvas, NOT as a station. It frames the entire journey. On the canvas:

```
[ TITLE BANNER: Governing Thought ]
--------------------------------------
|                                    |
|    Station 1 --> Station 2 -->     |
|         Station 3 --> Station 4    |
|              Station 5 --> Sta 6   |
|                                    |
--------------------------------------
[ FOOTER: Branding, logos, credits  ]
```

---

## Station Decomposition

### From Sections to Stations

Not every narrative section becomes a station. Stations consolidate multiple sections into single, digestible messages.

```
PHASE 1 -- Map sections to candidate stations:

  FOR each narrative section with a role:
    IF role is "hook" -> Title banner (not a station)
    IF role is "call-to-action" -> Final station or footer CTA
    IF role is "problem" or "urgency" -> Candidate station (early position)
    IF role is "evidence" or "proof" -> Candidate station (mid position)
    IF role is "solution" -> Candidate station (climax position)
    IF role is "roadmap" or "investment" -> Candidate station (late position)
    IF role is "options" -> Candidate station (late position)

PHASE 2 -- Consolidate to max_stations:

  IF candidate_count > max_stations:
    1. Merge sections with same role (e.g., two "evidence" sections -> one station)
    2. Merge adjacent minor sections into the nearest major section
    3. Prioritize: sections with hero numbers survive consolidation
    4. Prioritize: sections aligned with primary decision-maker's priorities (Rich mode)

  IF candidate_count < 4:
    1. Split multi-topic sections into separate stations
    2. Minimum 4 stations for visual balance

PHASE 3 -- Assign positions:

  FOR each station:
    position_fraction = station_index / total_stations
    journey_position = map position_fraction to metaphor's spatial flow
    (e.g., mountain: fraction 0.0 = valley, 0.5 = mid-slope, 1.0 = summit)

PHASE 4 -- Assign station labels (content-source-first, when arc_elements available):

  IF arc_elements loaded (from arc_definition_path):
    FOR each station:
      FIRST: Check source_chapter — which narrative H2 chapter was this station's content drawn from?
        IF source_chapter matches an arc element name:
          → Set station_label = that element's localized name (content-source method)
        ELSE (no chapter match — intro content, synthesized, or unmatched H2):
          → Fall back to role-based mapping:
            problem + urgency stations → first element (what drives change)
            solution stations         → middle elements (what changes)
            proof/evidence stations   → penultimate element (friction/resistance)
            roadmap/options stations  → final element (leadership/path forward)
          → Set station_label = localized element name (DE or EN per language)
    NOTE: Multiple stations can share the same element label
    See $CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md for the full heuristic with chapter detection
```

### Station as Landscape Object

Each station IS an object in the scene — not a card placed on top of a background. The station's `landscape_object` defines what the station BECOMES in the Story World.

**Key concept:** A "Broken CNC Machine" station doesn't have a card with an image of a broken machine. Instead, the station IS a broken machine shape on the canvas, with an accent-colored station number inline with the headline and text nearby.

**Visual components of a station:**

```
              ┌─────────────┐
              │  Base Shape  │           ← landscape_object (composed from recipe)
              │  + Accents   │           ← 2-4 accent shapes (details)
              └─────────────┘
     ┌──────────────────────────┐
     │  KRÄFTE                  │        ← Station label (uppercase, accent color)
     │ 1 HEADLINE TEXT (bold)   │        ← Number text (accent) inline LEFT of headline
     │  Body text (4-6 sent.)   │        ← text_placement determines where text goes
     │  HERO NUMBER  label      │           relative to the object
     └──────────────────────────┘
        (semi-transparent glow bg)       ← Rectangle at ~85% opacity behind text
```

**Station object assignment (Step 4):**
1. From the selected Story World's station_objects mapping, assign each station its `object_name`
2. The `narrative_connection` explains why this object represents this station's message
3. The `scale` (hero/standard/supporting) determines the object's relative size

**Reading flow:**
- Each station gets a `reading_flow_number` (1..N)
- Numbers progress spatially: left-to-right for linear flows, bottom-to-top for ascending
- The station number (accent-colored text inline with headline) guides the viewer's eye

**Text placement:**
- `below` (default): text area below the object
- `above`: text area above the object (for stations near canvas bottom)
- `right`: text area to the right of the object
- `left`: text area to the left of the object (for rightmost stations)
- `auto`: renderer decides based on available space

---

### Station Anatomy

Each station consists of:

| Element | Required | Max Length | Purpose |
|---------|----------|-----------|---------|
| `headline` | Yes | 50 chars | Assertion (not topic label) |
| `body` | Yes | 100-120 words | Key message, detailed prose |
| `hero_number` | No | -- | Reframed statistic (number play) |
| `hero_label` | No | 20 chars | What the number represents |
| `station_label` | No | 30 chars | Arc element name (e.g., "Kräfte"). Set from arc_elements when available via `arc_definition_path`. Rendered as a category label above the headline. |
| `reading_flow_number` | Yes | -- | Integer 1..N, spatial reading order |
| `text_placement` | Yes | -- | below, above, right, left, or auto |
| `landscape_object` | Yes | -- | Object name + narrative_connection + scale |
| `source` | No | -- | Citation URL if available |
| `position` | Yes | -- | `{x, y}` on canvas (from layout) |
| `arc_role` | Yes | -- | Internal: problem/evidence/solution/etc. |

### Station Sizing Rules

| Canvas | Station Image | Station Text Box | Max Stations |
|--------|--------------|-----------------|--------------|
| A0 | 600x400 px | 500x300 px | 8 |
| A1 | 450x300 px | 380x240 px | 7 |
| A2 | 320x220 px | 280x195 px | 6 |
| A3 | 240x160 px | 200x150 px | 5 |

---

## Station Flow Patterns

### Linear (left-to-right)

```
[S1] -----> [S2] -----> [S3] -----> [S4] -----> [S5] -----> [S6]
```

Best for: `road`, `river`, `journey` arcs. Simple, clear progression.

### Ascending (zigzag upward)

```
                                              [S6]
                                        ___--/
                                  [S5] /
                            ___--/
                      [S4] /
                ___--/
          [S3] /
    ___--/
[S1]----[S2]
```

Best for: `mountain`, `why-change` arcs. Builds tension visually.

### Winding (S-curve)

```
[S1] -----> [S2] -----> [S3]
                              \
                               \
[S6] <----- [S5] <----- [S4]
```

Best for: `garden`, `problem-solution` arcs. Encourages exploration.

### Hub-and-spoke (radial)

```
         [S2]
        /
[S1] ------ [CENTER] ------ [S4]
        \          \
         [S3]      [S5]
```

Best for: `archipelago`, `report` arcs. Parallel, non-sequential topics.

---

## Quality Criteria

A well-decomposed station set satisfies:

1. **Completeness** -- Every major narrative section is represented
2. **Balance** -- Stations are roughly equal in content weight
3. **Progression** -- The spatial order matches the story arc
4. **Independence** -- Each station makes sense on its own (scannable)
5. **Visual variety** -- Not all stations have the same structure (some stats, some text, some comparison)
6. **Density** -- 4-8 stations. Fewer than 4 feels empty; more than 8 feels cluttered
