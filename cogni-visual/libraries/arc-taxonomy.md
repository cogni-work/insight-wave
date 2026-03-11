---
type: shared-library
version: "1.0"
purpose: "Single source of truth for arc_id → arc_type mapping and arc element names across all cogni-visual skills"
consumers:
  - story-to-slides (Step 1)
  - story-to-big-picture (Step 1)
  - story-to-web (Step 1)
  - story-to-storyboard (Step 1)
---

# Arc Taxonomy

## Purpose

Map narrative arc IDs from cogni-narrative to visual arc types used by cogni-visual skills. Provide arc element names and translations for labeling (station labels, section labels, methodology phases).

**How this library is used:** Loaded at Step 1 of any visual skill when `arc_id` is present (from parameter or narrative frontmatter). Provides the mapping table and element names consumed by downstream steps.

---

## Arc ID to Visual Arc Type Mapping

When the source narrative carries an `arc_id` from cogni-narrative (in YAML frontmatter or passed as parameter), map it to the visual arc type used for decomposition. This bridges the rich narrative taxonomy (6 arc types with 4-element structures) to the visual taxonomy (5 visual arc types optimized for layout selection).

| cogni-narrative `arc_id` | Visual `arc_type` | Display Name | Reasoning |
|--------------------------|-------------------|--------------|-----------|
| `corporate-visions` | `why-change` | Corporate Visions | Elements (Why Change/Why Now/Why You/Why Pay) map directly to tension-release-action |
| `industry-transformation` | `why-change` | Industry Transformation | Elements (Forces/Friction/Evolution/Leadership) follow the same tension-release pattern |
| `technology-futures` | `journey` | Technology Futures | Elements (Emerging/Converging/Possible/Required) describe a chronological progression |
| `strategic-foresight` | `argument` | Strategic Foresight | Elements (Signals/Scenarios/Strategies/Decisions) build an analytical case |
| `competitive-intelligence` | `argument` | Competitive Intelligence | Elements (Landscape/Shifts/Positioning/Implications) build an analytical case |
| `trend-panorama` | `journey` | Trend Panorama | Elements (Forces/Impact/Horizons/Foundations) describe a progression from external pressures to capability requirements |

**Fallback:** If `arc_id` is not in this table, fall back to auto-detection from narrative content (same behavior as when no `arc_id` is present).

---

## Arc Element Names

Each arc has 4 ordered elements that represent the phases of the narrative structure. These elements have English names and German translations.

### corporate-visions

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Why Change | Warum Veränderung | What drives the need for change |
| 2 | Why Now | Warum Jetzt | Why the change is urgent |
| 3 | Why You | Warum Wir | How the solution addresses the need |
| 4 | Why Pay | Warum Investieren | The business case and path forward |

### industry-transformation

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Forces | Kräfte | External forces driving transformation |
| 2 | Friction | Reibung | Resistance and obstacles encountered |
| 3 | Evolution | Evolution | How the industry is evolving |
| 4 | Leadership | Führung | What leadership is required |

### technology-futures

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Emerging | Aufkommend | Technologies that are emerging |
| 2 | Converging | Konvergierend | Technologies that are converging |
| 3 | Possible | Möglich | What becomes possible |
| 4 | Required | Erforderlich | What actions are required |

### strategic-foresight

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Signals | Signale | Early signals and indicators |
| 2 | Scenarios | Szenarien | Possible future scenarios |
| 3 | Strategies | Strategien | Strategic responses |
| 4 | Decisions | Entscheidungen | Decision points and actions |

### competitive-intelligence

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Landscape | Wettbewerbslandschaft | Current competitive landscape |
| 2 | Shifts | Verschiebungen | Market and competitive shifts |
| 3 | Positioning | Positionierung | Strategic positioning options |
| 4 | Implications | Implikationen | Business implications and actions |

### trend-panorama

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Forces | Kräfte | External pressures and market signals (TIPS T-dimension) |
| 2 | Impact | Wirkung | Value chain disruption and digital value drivers (TIPS I-dimension) |
| 3 | Horizons | Horizonte | Strategic possibilities and new opportunities (TIPS P-dimension) |
| 4 | Foundations | Fundamente | Capability requirements and digital foundations (TIPS S-dimension) |

---

## Element-to-Label Assignment Heuristic

When arc element names are available, map them to content units (slides, stations, sections, posters) by **content source first, role-based as fallback**. Arc elements map to content units **excluding bookends** (title/hero and closing/CTA).

### Priority Chain

1. **Content-source (primary):** If the content unit's material was drawn from a narrative chapter whose H2 header matches an arc element name, use that element as the label.
2. **Role-based fallback:** If no chapter match (intro content, synthesized content, or narrative has no H2 headers matching elements), fall back to the role-based mapping below.
3. **Generic fallback:** If no `arc_elements` are available at all, use generic labels ("Das Problem", "Die Lösung", etc.).

### Chapter-to-Element Mapping (Content-Source Detection)

During decomposition, track which narrative chapter each content unit's material originates from:

```
CHAPTER DETECTION:
  1. Scan narrative for H2 headers (## headings)
  2. FOR each H2 header text:
       Normalize: lowercase, strip whitespace
       FOR each arc element name (and localized name):
         Normalize: lowercase, strip whitespace
         IF header contains element name OR element name contains header:
           MAP chapter → arc element
  3. FOR each content unit:
       Identify which H2 chapter(s) the unit's content was drawn from
       IF content drawn from a single mapped chapter:
         SET source_chapter = that chapter's matched arc element
       ELSE IF content drawn from multiple mapped chapters:
         SET source_chapter = the chapter contributing the MOST content
       ELSE:
         SET source_chapter = none (use role-based fallback)
```

### Role-Based Mapping (Fallback)

When `source_chapter` is `none` (content is from intro, synthesized, or from chapters that don't match arc element names):

```
problem + urgency content  → first element (what drives change)
solution content           → middle elements (what changes, how it evolves)
proof/evidence content     → penultimate element (resistance overcome, evidence)
roadmap/options content    → final element (leadership, path forward, decisions)
```

**When there are more content units than arc elements (4):** Multiple units can share an element label. Adjacent units with the same narrative function share the same element.

**When there are fewer content units than elements:** Some elements may be omitted. Prioritize: first element (always), last element (always), then fill middle elements based on content.

### Example — `industry-transformation` arc with 6 content units

Narrative chapters: `## Kräfte`, `## Reibung`, `## Evolution`, `## Führung`

| Content Unit | Arc Role | Source Chapter | Method | Element Label (DE) |
|-------------|----------|---------------|--------|-------------------|
| Unit 1 | problem | Kräfte | content-source | Kräfte |
| Unit 2 | urgency | (intro stats) | role-based fallback | Kräfte |
| Unit 3 | solution | Evolution | content-source | Evolution |
| Unit 4 | solution | Evolution | content-source | Evolution |
| Unit 5 | proof | Evolution | content-source | Evolution |
| Unit 6 | roadmap | Führung | content-source | Führung |

Note: Unit 5 contains proof content (EBIT comparison, servitization data) but that material was drawn from the "Evolution" chapter, so it gets label "Evolution" — not "Reibung" which the role-based fallback would have assigned.

---

## Arc Resolution Pseudocode

Reusable across all four visual skills. Execute in Step 1 after parameter parsing, before theme loading.

```
ARC_ID RESOLUTION:
  1. IF `arc_id` parameter provided by caller → use it directly
  2. ELSE IF source narrative frontmatter contains `arc_id` field → extract it
  3. ELSE → arc_id remains unset (downstream step detects arc from content)

IF arc_id is set:
  READ $CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md
  LOOKUP arc_id in the mapping table
  IF found:
    MAP arc_id to visual arc_type
    STORE arc_context = { arc_id, arc_type, arc_display_name }
    NOTE: Mapped arc_type overrides the `arc_type` parameter if both are provided
  ELSE:
    WARN: Unknown arc_id "{arc_id}" — falling back to auto-detection
    arc_id remains set but arc_context is not populated

IF `arc_definition_path` parameter provided AND file exists:
  READ arc definition file
  EXTRACT element names (ordered list, 4 elements)
  EXTRACT element translations (localized names matching `language` parameter)
  STORE arc_elements = { names: [...], names_localized: [...] }
  NOTE: These element names are used for labeling in downstream steps
```

---

## Arc Definition File Format

Arc definition files live in cogni-narrative at:
`cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md`

Each file defines the 4 arc elements with their English and German names, descriptions, and narrative function. The skill extracts the element name lists from these files.
