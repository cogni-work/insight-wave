# Poster Architecture

## Purpose

Define how to map arc stations to posters, decompose each poster into stacked web sections, and assign section themes for visual rhythm. Each poster represents one arc station (Why Change, Why Now, Why You, Why Pay) containing 1-3 web section types stacked vertically.

---

## Arc-to-Poster Mapping

The narrative's arc stations drive poster composition. Posters are NOT 1:1 with web sections — they are 1:1 with **arc stations**, and each station can contain multiple web section types stacked vertically.

### Mapping Heuristic

```
1. Load arc definition elements (e.g., Why Change has 4 elements)
2. Count elements: if elements <= 5, one poster per element
3. If elements > 5 or max_posters < elements:
   - Condense related stations:
     - problem + urgency → single "Why Change/Why Now" poster
     - solution + capabilities → single "Why You" poster
     - proof + testimonial → single "Proof" poster
     - roadmap + cta → single "Why Pay" poster
4. First poster always starts with hero section (can be hero-only or hero + content)
5. Last poster always ends with cta section (can be cta-only or content + cta)
```

### Arc Type to Poster Templates

**4-poster why-change (condensed, default):**
```
Poster 1: "Why Change" = hero (dark, top 40%) + problem-statement (light, bottom 60%)
Poster 2: "Why Now"    = stat-row (dark, top 45%) + comparison (light, bottom 55%)
Poster 3: "Why You"    = feature-alternating (light, top 50%) + feature-grid (light-alt, bottom 50%)
Poster 4: "Why Pay"    = timeline (light-alt, top 55%) + cta (accent, bottom 45%)
```

**5-poster why-change (full):**
```
Poster 1: "Why Change" = hero (dark, full height — establishing shot)
Poster 2: "Why Now"    = problem-statement (light, top 50%) + stat-row (dark, bottom 50%)
Poster 3: "Why You"    = feature-alternating (light, top 55%) + feature-alternating (light-alt, bottom 45%)
Poster 4: "Proof"      = comparison (light, top 55%) + testimonial (dark, bottom 45%)
Poster 5: "Why Pay"    = timeline (light-alt, top 55%) + cta (accent, bottom 45%)
```

**3-poster argument (minimal):**
```
Poster 1: "Opening"    = hero (dark, top 40%) + stat-row (dark, bottom 60%)
Poster 2: "Evidence"   = feature-grid (light, top 50%) + comparison (light-alt, bottom 50%)
Poster 3: "Conclusion" = text-block (light, top 40%) + cta (accent, bottom 60%)
```

**4-poster journey:**
```
Poster 1: "Setting"    = hero (dark, full height)
Poster 2: "Challenge"  = feature-alternating (light, top 50%) + feature-alternating (light-alt, bottom 50%)
Poster 3: "Discovery"  = stat-row (dark, top 45%) + feature-grid (light, bottom 55%)
Poster 4: "Resolution" = timeline (light-alt, top 55%) + cta (accent, bottom 45%)
```

**3-poster report:**
```
Poster 1: "Context"    = hero (dark, top 40%) + stat-row (dark, bottom 60%)
Poster 2: "Findings"   = feature-grid (light, top 50%) + comparison (light-alt, bottom 50%)
Poster 3: "Action"     = text-block (light, top 40%) + cta (accent, bottom 60%)
```

---

## Section Stacking Rules

Each poster contains 1-3 web section types stacked vertically within the content area (1924px at base resolution).

### Height Allocation

- A single-section poster gives the section the full 1924px
- A 2-section poster splits based on content density (50/50, 55/45, or 60/40)
- A 3-section poster splits based on content density (40/30/30 or 35/35/30)

### Split Ratio Selection

```
2-section poster:
  IF section 1 has image_prompt AND section 2 does not → 55/45
  IF section 2 has image_prompt AND section 1 does not → 45/55
  IF section 1 is hero → 60/40
  IF both sections have image_prompt or neither → 50/50

3-section poster:
  IF first section is hero → 40/30/30
  OTHERWISE → 35/35/30 (last section slightly smaller)
```

### Section Theme Rules Within a Poster

Section themes can differ within a poster. Follow these rules:

1. **hero** sections are always `dark`
2. **stat-row** and **testimonial** sections are always `dark`
3. **cta** sections are always `accent`
4. Other content sections alternate between `light` and `light-alt`
5. Avoid two adjacent `dark` sections within the same poster — if needed, insert a `light-alt` section between them
6. A visual divider line (1px, muted color) separates stacked sections

---

## Section Type Selection per Poster

Use the **web section type decision tree** (from `story-to-web/references/02-section-architecture.md`) to select section types. The same logic applies, but adapted for poster context:

### Decision Tree (Poster-Adapted)

```
FOR each section within a poster:

  IF this is the first section of the first poster:
    → Use "hero" (dark theme, image background with overlay)

  IF this is the last section of the last poster:
    → Use "cta" (accent theme)

  IF narrative content for this section has 3+ statistics:
    → Use "stat-row" (dark theme, 2x2 grid on portrait)

  IF narrative content has before/after or explicit comparison:
    → Use "comparison" (light theme, two columns)

  IF narrative content has a direct quote:
    → Use "testimonial" (dark theme)

  IF narrative content lists 4+ capabilities/features in parallel:
    → Use "feature-grid" (light/light-alt theme)

  IF narrative content describes 3-5 sequential steps:
    → Use "timeline" (light/light-alt theme, vertical on portrait)

  IF narrative content has a single argument with image opportunity:
    → Use "feature-alternating" (light/light-alt, vertical stack on portrait)

  DEFAULT:
    → Use "text-block" (light/light-alt)
```

---

## Poster Count Decision

The skill determines poster count (3-5) based on narrative length and arc type:

```
IF narrative word count < 800:
  → 3 posters (minimal)
IF narrative word count 800-1500:
  → 4 posters (default)
IF narrative word count > 1500:
  → 5 posters (full)

CONSTRAINTS:
  - Never exceed max_posters parameter (default 4)
  - Never fewer than 3 posters
  - Each poster must have substantive content (no padding posters)

PROHIBITED PATTERNS:
  - Separate "title poster" or "opening poster" with only hero content
    → Instead: first content poster starts with hero section
  - Separate "summary poster" or "closing poster" with only CTA
    → Instead: last content poster ends with cta section
  - More than 5 posters under any circumstances
  - Poster count that exceeds max_posters parameter
  - Any poster labeled as "title", "intro", "summary", or "closing"
    that is not a content poster with 1-3 stacked web sections
```

---

## Arc Label Assignment

When `arc_elements` are available (from `arc_definition_path`), assign labels **content-source-first, role-based as fallback**:

```
FOR each poster:
  FIRST: Check source_chapter — which narrative H2 chapter(s) was this poster's content drawn from?
    IF the dominant source chapter matches an arc element name:
      → Set poster_label = that element's localized name (content-source method)
    ELSE (no chapter match — intro content, synthesized, or mixed sources):
      → Fall back to role-based mapping:
        Poster 1 (problem/hook)     → first element (what drives change)
        Poster 2 (urgency/evidence) → first or second element
        Poster 3 (solution)         → middle element(s) (what changes)
        Poster 4 (proof)            → penultimate element (friction overcome)
        Poster 5 (roadmap/CTA)      → final element (leadership/path forward)
  Set poster_label = localized element name (DE or EN per language)
```

See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for the full heuristic with chapter detection pseudocode.

---

## Quality Criteria

A well-composed storyboard satisfies:

1. **Completeness** — Every major narrative section is represented across posters
2. **Standalone clarity** — Each poster makes sense as a single arc station
3. **Visual variety** — No two adjacent posters have identical section compositions
4. **Section fit** — Section types match content characteristics (stats→stat-row, comparison→comparison, etc.)
5. **Poster count** — 3-5 posters total
6. **Bookend integrity** — First poster starts with hero, last poster ends with CTA
7. **Theme rhythm** — Light/dark alternation within and across posters
