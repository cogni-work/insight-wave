---
type: shared-library
version: "1.0"
purpose: "Single source of truth for arc_id → arc_type mapping and arc element names across cogni-workspace's brief-rendering surfaces. The consumers list below is scoped to this plugin; the one external, out-of-plugin reader, cogni-website:website-plan, is named here but deliberately not listed."
consumers:
  - brief-pipeline.md § Arc resolution (the contract every brief author or caller meets)
  - render-html-slides (arc_type read from brief frontmatter)
  - the pptx, html-slides, web and storyboard render agents (arc_type and per-unit roles read from brief frontmatter)
---

# Arc Taxonomy

## Purpose

Map narrative arc IDs — the `arc_id` a `text-to-narrative` run writes into its narrative's frontmatter, in the registry the retired `narrative` skill established — to the visual arc types the brief-rendering surfaces of this plugin use. Provide arc element names and translations for labeling (station labels, section labels, methodology phases).

**How this library is used:** Loaded when a brief is authored or supplied and `arc_id` is present (from parameter or narrative frontmatter). Provides the mapping table and element names the brief's `arc_type` and labels are derived from.

---

## Arc ID to Visual Arc Type Mapping

When the source narrative carries an `arc_id` (in YAML frontmatter or passed as parameter), map it to the visual arc type used for decomposition. This bridges the rich narrative taxonomy (every registered arc, each a 4-element structure) to the visual taxonomy (5 visual arc types optimized for layout selection).

| Narrative `arc_id` | Visual `arc_type` | Display Name | Reasoning |
|--------------------------|-------------------|--------------|-----------|
| `corporate-visions` | `why-change` | Corporate Visions | Elements (Why Change/Why Now/Why You/Why Pay) map directly to tension-release-action |
| `industry-transformation` | `why-change` | Industry Transformation | Elements (Forces/Friction/Evolution/Leadership) follow the same tension-release pattern |
| `technology-futures` | `journey` | Technology Futures | Elements (Emerging/Converging/Possible/Required) describe a chronological progression |
| `strategic-foresight` | `argument` | Strategic Foresight | Elements (Signals/Scenarios/Strategies/Decisions) build an analytical case |
| `competitive-intelligence` | `argument` | Competitive Intelligence | Elements (Landscape/Shifts/Positioning/Implications) build an analytical case |
| `trend-panorama` | `journey` | Trend Panorama | Elements (Forces/Impact/Horizons/Foundations) describe a progression from external pressures to capability requirements |
| `theme-thesis` | `why-change` | Theme Thesis | Elements (Why Change/Why Now/Why You/Why Pay) follow the same tension-to-action pattern as Corporate Visions, purpose-built for investment theme narratives |
| `jtbd-portfolio` | `argument` | JTBD Portfolio | Elements (Job Landscape/Friction Map/Portfolio Map/Invitation) build an analytical case from buyer jobs through friction to solutions |
| `company-credo` | `argument` | Company Credo | Elements (Mission/Conviction/Credibility/Promise) build a belief-driven argument: the company states what it believes, backs it with receipts, and closes with a forward commitment |
| `engagement-model` | `journey` | Engagement Model | Elements (Principles/Process/Partnership/Outcomes) describe a chronological progression through an engagement — Process is the longest element and reads as a phase sequence with artifacts and time bands |
| `smarter-service` | `journey` | Smarter Service | Elements (Forces/Impact/Horizons/Foundations) describe the same progression from external pressures to capability requirements as Trend Panorama — the theme-aware sibling arc shares the identical TIPS dimension mapping, so it takes the same visual arc type |
| `consulting-problem-solving` | `problem-solution` | Consulting Problem-Solving | Elements (Situation/Complication/Resolution/Implications) move from a problem through its diagnosis to the answer — the only arc that maps to the problem-solution visual type by `arc_id` rather than by auto-detection |
| `strategic-choice` | `argument` | Strategic Choice | Elements (Context/Tension/Options/Choice) build an analytical case: criteria, alternatives evaluated against them, one recommendation |
| `customer-transformation` | `journey` | Customer Transformation | Elements (Before/Struggle/Change/Outcome) follow one customer chronologically from starting point to verified result |
| `category-creation` | `why-change` | Category Creation | Elements (Status Quo/Shift/New Frame/Leadership) follow the tension-release-action pattern: the old frame breaks, a new one resolves it, leadership acts on it |

**Fallback:** If `arc_id` is not in this table, fall back to auto-detection from narrative content (same behavior as when no `arc_id` is present).

---

## Arc Element Names

Each arc has 4 ordered elements that represent the phases of the narrative structure. These elements have English names and German translations.

### corporate-visions

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Why Change | Warum Wandel | What drives the need for change |
| 2 | Why Now | Warum Jetzt | Why the change is urgent |
| 3 | Why You | Warum Sie | How the solution addresses the need |
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
| 1 | What's Emerging | Was Entsteht | Technologies that are emerging |
| 2 | What's Converging | Was Konvergiert | Technologies that are converging |
| 3 | What's Possible | Was Möglich Ist | What becomes possible |
| 4 | What's Required | Was Erforderlich Ist | What actions are required |

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
| 1 | Landscape | Landschaft | Current competitive landscape |
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

### theme-thesis

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Why Change | Warum Veränderung | Investment context and market forces |
| 2 | Why Now | Warum jetzt | Urgency and window of opportunity |
| 3 | Why You | Warum Sie | Strategic capabilities and differentiation |
| 4 | Why Pay | Geschäftliche Auswirkungen | Business case and expected returns |

### jtbd-portfolio

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Job Landscape | Job-Landschaft | Functional jobs the buyer hires solutions for |
| 2 | Friction Map | Reibungskarte | Per-job obstacles and cost of inaction |
| 3 | Portfolio Map | Portfolio-Zuordnung | Solutions mapped 1:1 to jobs via IS/DOES/MEANS |
| 4 | Invitation | Einladung | Low-commitment entry point with cogni-sales handoff |

### company-credo

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Mission | Mission | Why the company exists — the belief-with-a-verb |
| 2 | Conviction | Überzeugung | 3–4 non-negotiable judgment calls the Mission implies |
| 3 | Credibility | Glaubwürdigkeit | Receipts: track record, external validation, outcomes, expertise |
| 4 | Promise | Versprechen | Forward commitment in You-voice, closing the arc |

### engagement-model

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Principles | Prinzipien | Operating principles — what the company always/never does |
| 2 | Process | Prozess | Canonical 4–6 phases with artifacts and time bands |
| 3 | Partnership | Partnerschaft | Reciprocal — what the buyer must bring for the engagement to work |
| 4 | Outcomes | Ergebnisse | Cross-cutting results the buyer can observe |

### smarter-service

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Forces | Kräfte | External pressures and market signals (TIPS T-dimension) |
| 2 | Impact | Wirkung | Value chain disruption and digital value drivers (TIPS I-dimension) |
| 3 | Horizons | Horizonte | Strategic possibilities and new opportunities (TIPS P-dimension) |
| 4 | Foundations | Fundamente | Capability requirements and digital foundations (TIPS S-dimension) |

Same four elements as Trend Panorama — `smarter-service` is its theme-aware sibling. Element labels are identical; only the narrative wrapper differs (investment themes nest under each element).

### consulting-problem-solving

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Situation | Situation | The agreed, material baseline |
| 2 | Complication | Komplikation | What breaks the baseline |
| 3 | Resolution | Lösung | The evidence-led answer |
| 4 | Implications | Implikationen | Decisions and next moves that follow |

### strategic-choice

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Context | Kontext | The decision frame and its constraints |
| 2 | Tension | Spannungsfeld | The discriminating trade-offs |
| 3 | Options | Optionen | The alternatives evaluated against the same criteria |
| 4 | Choice | Entscheidung | The recommended path, its trade-off, its trigger |

### customer-transformation

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Before | Ausgangslage | Where the customer stood, with its baseline |
| 2 | Struggle | Herausforderung | What stood in the way |
| 3 | Change | Veränderung | The intervention and the turning point |
| 4 | Outcome | Ergebnis | The verified transformation and the transferable lesson |

### category-creation

| # | Element (EN) | Element (DE) | Narrative Function |
|---|-------------|-------------|-------------------|
| 1 | Status Quo | Status Quo | The existing category, represented fairly |
| 2 | Shift | Verschiebung | What breaks the old frame |
| 3 | New Frame | Neuer Bezugsrahmen | The category that fits the new reality |
| 4 | Leadership | Führungsanspruch | What defines the category leader |

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
     (also check `report_arc` as legacy alias — trend reports generated before this fix used that field name)
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

Arc contracts live in the `text-to-narrative` skill at:
`cogni-workspace/skills/text-to-narrative/references/arc-{arc-id}.md`

Each contract's `## Headings` table carries the four full section headings per language (EN, DE, and further columns where the arc supports them). The short element names in this file are derived from those headings — the segment before the first colon, or the whole heading when it carries none — and `cogni-workspace/tests/test-arc-taxonomy-sync.sh` case H1 checks that derivation for every migrated arc.

---

## Arc Roles

The closed set of section roles a brief assigns to a narrative's parts after the arc is resolved, declared here once. A 4.1 presentation brief writes the role on each slide as `intent.role`; a web or storyboard brief writes it as `arc_role`; an infographic brief orders its blocks by it. The renderer reads the declared role rather than re-deriving it.

| Role | Meaning |
|------|---------|
| `hook` | opens — the title, the framing, the reason to listen |
| `problem` | the situation that cannot stay as it is |
| `urgency` | why now — the deadline, the trend, the closing window |
| `evidence` | the numbers and sources that make the problem undeniable |
| `solution` | what is proposed |
| `proof` | why it works — pilots, comparisons, capability detail |
| `options` | the choices and their trade-offs |
| `roadmap` | the sequence and timing of getting there |
| `investment` | what it costs and what it returns |
| `call-to-action` | the next step the audience is asked to take |

The order above is the expected emotional trajectory: tension (`problem`, `urgency`, `evidence`) → release (`solution`, `proof`) → momentum (`options`, `roadmap`, `investment`, `call-to-action`). A `solution` before any `problem` or `evidence`, or a `proof` before its `solution`, is the arc-flow defect the validation checklists ask the model to catch.
