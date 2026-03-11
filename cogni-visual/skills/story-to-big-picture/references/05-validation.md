# Big Picture Brief Validation (v3.0)

## Purpose

Define the four-layer validation framework for big-picture-brief.md v3.0 files. Every brief must pass all four layers before being written to output. Validation is **active verification** — each check produces a concrete measurement, not a passive checkbox.

**v3.0 change:** Briefs no longer contain `shape_composition` or `landscape_composition`. Stations are specified via `object_name` + `narrative_connection` — rendering agents own the visual interpretation using shape-recipes-v3.md.

---

## Layer 1: Schema Compliance

Verify the brief structure matches the v3.0 format.

### Frontmatter Checks

- [ ] `type` field is `"big-picture-brief"`
- [ ] `version` field is `"3.0"`
- [ ] `theme` field references a valid theme ID
- [ ] `theme_path` points to an existing theme.md
- [ ] `canvas_size` is one of: A0, A1, A2, A3
- [ ] `canvas_pixels` matches DIN format at 150 DPI
- [ ] `visual_style` is a valid style ID (`flat-illustration`, `sketch`)
- [ ] `roughness` is 0, 1, or 2
- [ ] `language` is "en" or "de"
- [ ] `max_stations` is 4-8
- [ ] `governing_thought` is exactly ONE sentence (count periods — must be 1)
- [ ] `arc_type` is a valid arc type
- [ ] `story_world` object present with `name`, `type` (literal/lateral), `description`

### Station Checks

For each station:

- [ ] Has `headline` (string, max 50 chars)
- [ ] Has `body` (string, 100-120 words — count and record)
- [ ] Has `reading_flow_number` (integer, 1..N, unique, sequential)
- [ ] Has `text_placement` (one of: below, above, right, left, auto)
- [ ] Has `landscape_object` with:
  - [ ] `object_name` (string, specific and descriptive — not "Shape 1")
  - [ ] `narrative_connection` (string, 2-3 sentences describing visual intent for rendering agents)
  - [ ] `scale` (one of: hero, standard, supporting)
- [ ] Has `position` with `x` and `y` coordinates
- [ ] Has `arc_role` (valid role)
- [ ] `hero_number` and `hero_label` are paired (both or neither)
- [ ] Maximum 1 station with `scale: hero`
- [ ] Synthesis/CTA stations have `station_label` set to "Synthese" (de) or "Synthesis" (en)
- [ ] NO `shape_composition` field present (v3.0 removed this — rendering agents own composition)
- [ ] NO color fields on stations (renderer reads theme directly)

### Canvas Layout Checks

- [ ] `title_banner` zone defined with position and size
- [ ] `journey_zone` zone defined with position and size
- [ ] `footer` zone defined with position and size
- [ ] `coordinate_system` field present and set to `"journey_zone_relative"`
- [ ] Station positions are within journey zone bounds
- [ ] No station bounding boxes overlap another (minimum 50px gap)
- [ ] All station `y` positions >= 100 (minimum distance from journey zone top)
- [ ] All station `y` positions leave >= 80px to journey zone bottom
- [ ] NO `landscape_composition` field present (v3.0 removed this — rendering agents own scene composition)

---

## Layer 2: Message Quality

Verify that station content communicates effectively. This layer requires **explicit measurement** — record actual values and compare against thresholds.

### Headline Quality

For each headline, measure:
- Character count → must be <= 50
- Contains a verb → must be true (assertion, not topic label)
- Contains a number → track count

Aggregate:
- [ ] All headlines are assertions (contain a verb)
- [ ] No topic labels ("Overview", "Summary", "Introduction")
- [ ] Headlines are unique (no duplicates)
- [ ] At least 80% of headlines contain a number (count: {N} of {total} = {pct}%)
- [ ] All headlines are under 50 characters (longest: {N} chars)

### Body Text Quality — Word Count Gate

This is the most frequently failed check. Run it with explicit counts:

```
FOR each station:
  word_count = count words in body text
  sentence_count = count sentences in body text
  RECORD: "Station {N}: {word_count} words, {sentence_count} sentences"
  IF word_count < 100:
    FAIL — "Station {N} body is {word_count} words (minimum 100). Return to Step 5,
            expand with source evidence using the 5-part formula."
  IF word_count > 120:
    FAIL — "Station {N} body is {word_count} words (maximum 120). Cut weakest sentence."
  IF sentence_count < 4 OR sentence_count > 6:
    WARN — "Station {N} has {sentence_count} sentences (target 4-6)."

REPORT: "Body word counts: S1={w1}, S2={w2}, ... | avg={avg} | range={min}-{max}"
```

- [ ] Every body text is 100-120 words (record: S1=___, S2=___, S3=___, ...)
- [ ] Every body text is 4-6 complete sentences
- [ ] Body text supports the headline's claim
- [ ] No placeholder or generic text ("Lorem ipsum", "Details here")
- [ ] 5-part formula applied: each body covers state/prove/explain/impact/connect

### Hero Number Quality (where present)

- [ ] Numbers are reframed (not raw data dumps)
- [ ] Units/labels included
- [ ] Numbers are contextually meaningful (not arbitrary)

### Narrative Connection Quality

- [ ] Every `narrative_connection` is 2-3 sentences long
- [ ] Describes concrete physical details (shapes, colors, distinctive features)
- [ ] Explains why this object represents the station's message
- [ ] Provides enough visual cues for rendering agents to compose an illustration

---

## Layer 3: Visual Coherence

Verify that the brief will produce a visually coherent illustrated scene.

### Station Count and Balance

- [ ] 4-8 stations (within canvas_size limits)
- [ ] Stations distributed across the journey zone (not clustered)
- [ ] First station is in the early/left position
- [ ] Last station is in the late/right position (or focal point for hub layouts)

### Scene Integration

- [ ] Station objects vary in scale (not all identical)
- [ ] Object names are specific and distinct (not generic "Shape 1", "Shape 2")
- [ ] Object names fit the selected Story World (not mixing unrelated domains)
- [ ] Reading flow numbers progress spatially (1 starts left/bottom, N ends right/top)
- [ ] Text blocks don't extend off-canvas (check text_placement + position + text area width)
- [ ] Visual style is consistent (same roughness across all stations)

### Story World Consistency

- [ ] Story world type matches station object vocabulary (literal world = domain objects)
- [ ] All station objects belong to the same visual world
- [ ] Narrative connections describe objects consistent with the world theme

### Spatial Layout

- [ ] Station positions follow a clear flow pattern (ascending, linear, winding, hub)
- [ ] No stations are placed off-canvas
- [ ] Title banner does not overlap with stations
- [ ] Footer does not overlap with stations

---

## Layer 4: Content Integrity

Verify that the brief faithfully represents the source narrative. This layer includes **active scans** — not just reading and judging, but searching for specific patterns.

### Umlaut Integrity (German only)

When `language` is `de`, actively scan ALL text fields for umlaut substitutions. This is the second most common failure mode — the model frequently writes `ae`/`oe`/`ue` instead of `ä`/`ö`/`ü`.

```
SCAN these fields for ae/oe/ue/ss patterns:
  - governing_thought (frontmatter)
  - title, subtitle (canvas layout)
  - ALL station_labels
  - ALL headlines
  - ALL body texts
  - ALL CTA texts
  - footer text

COMMON FAILURES to check for:
  Kraefte → Kräfte          Kapazitaet → Kapazität
  Flughaefen → Flughäfen    Mobilitaet → Mobilität
  waechst → wächst          Maerz → März
  Verhaeltnis → Verhältnis  Foerderprogramme → Förderprogramme
  ermoeglichen → ermöglichen naechsten → nächsten
  Prioritaet → Priorität    schliesst → schließt
  Fuenf → Fünf              Kapazitaetsdruck → Kapazitätsdruck

IF any substitution found:
  FAIL — list each instance with field name, wrong text, correct text
  Fix ALL instances before proceeding
```

### Governing Thought Structure

- [ ] Exactly ONE sentence (count sentence-ending periods — must be 1)
- [ ] Names the subject domain (industry, technology, or audience)
- [ ] Self-test passes: "Could someone read ONLY this sentence and know the industry AND stakes?"

### Completeness

- [ ] Every major narrative section has a corresponding station or is part of the title/footer
- [ ] No important sub-topics completely absent (check: does any narrative H2 section have zero data points in the brief?)
- [ ] Governing thought is supported by the station content
- [ ] Arc type is correctly identified (compare with narrative structure)

### Data Point Coverage

- [ ] Count quantitative claims in source narrative
- [ ] Count quantitative claims used across all stations
- [ ] Coverage ratio >= 60% (data points used / data points available)
- [ ] No major narrative sub-topic (H2 section) contributes zero data points to the brief

### Language Consistency

- [ ] All text is in the specified language (en or de)
- [ ] German umlauts preserved (ä, ö, ü, ß) — verified by umlaut scan above
- [ ] Number formatting matches language (EN: 2,661 / DE: 2.661)
- [ ] No mixed-language content within a station

### Source Preservation

- [ ] Citations with URLs preserved in station `source` fields
- [ ] No URLs invented or fabricated
- [ ] Key statistics traceable to source material

---

## Agent-Side Validation (Post-Render)

After the big-picture agent renders the brief, these additional checks apply to the Excalidraw output:

### Structural Checks (via `describe_scene`)

- [ ] Station number text elements exist (>= N for N stations — "number-{N}" IDs)
- [ ] No circle/ellipse elements used for reading flow (v4.2: inline text numbers only)
- [ ] Title banner group exists with solid #1A1A1A background
- [ ] Footer group exists
- [ ] Total groups >= N + 2 (N station groups + banner + footer)

### Visual Checks (if screenshot available)

- [ ] Scene looks cohesive (objects integrate with landscape, not floating on top)
- [ ] Station numbers are visible and readable (accent color, inline LEFT of headline)
- [ ] Text is readable against glow backgrounds
- [ ] No overlapping stations
- [ ] No off-canvas content

---

## Validation Execution

Run validation as a sequential gate — each layer must pass before the next begins:

```
FOR each layer (1 → 2 → 3 → 4):
  Run all checks with explicit measurements
  IF any check fails:
    Log: layer, check, expected value, actual value
    STOP — return to the responsible step and fix
    Re-run this layer after fixing
  IF all checks pass:
    Record: "Layer {N}: PASS"

AFTER all 4 layers pass:
  Record in Generation Metadata:
    "Validation: Schema PASS | Messages PASS | Visual PASS | Integrity PASS"
    "Body word counts: S1={w1}, S2={w2}, ... | avg={avg}"
    "Data point coverage: {used}/{total} ({pct}%)"
    "Umlaut check: PASS (0 substitutions found)" or "N/A (language=en)"

THEN write the brief.
```

If any layer fails, return to the responsible step and fix before writing the brief. Never write a brief that reports "Validation: pass" while actual measurements show failures (e.g., reporting "pass" with 43-word bodies).
