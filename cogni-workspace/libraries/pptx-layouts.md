---
library_id: pptx-layouts
version: 1.0.0
created: 2026-02-04
updated: 2026-02-04
---

# PPTX Layout Library

The **field schema** of the eleven slide layouts a presentation brief may use: for each layout, what it is for, which fields are required, which are optional, and a content-only example. This is the vocabulary a presentation brief is written in and every renderer reads — the pptx path and `render-html-slides`.

It carries **no geometry and no rendering instructions**. Canvas positions, point sizes, palette and font mapping, notes and citation rendering, Mermaid-to-shape rules and the QA loop for a pptxgenjs renderer live in `pptx-render-recipe.md`; the per-slide 4.1 keys (`Slide-Kind`, `intent`, `visual`) are defined in `libraries/presentation-brief-template.md`; the closed layout set is pinned across its homes by `tests/test-brief-layout-sync.sh`, and `scripts/check-brief.py` enforces the required fields below.

---

## Layout 1: title-slide

Opening slide with centered title, subtitle, and metadata.

### Required Content

- **Title**: Main presentation title (max 60 chars)
- **Subtitle**: Secondary description (max 100 chars)

### Optional Content

- **Metadata**: Date, author, version info
- **Logo**: Theme-specific logo placement

### Visual Hierarchy

1. Title (largest, bold, primary color)
2. Subtitle (medium, normal weight)
3. Metadata (smallest, muted color)

### Example

```yaml
Layout: title-slide
Title: Krise im deutschen Bahnnetz
Subtitle: Warum manuelle Überwachung nicht mehr ausreicht
Metadata: Deutsche Bahn AG | Januar 2026
```

---

## Layout 2: stat-card-with-context

Large stat card on left (40%), context bullets on right (55%), with optional bottom banner and left accent border.

### Required Content

- **Slide Title**: Slide headline text
- **Hero Stat Number**: Primary numeric value
- **Hero Stat Label**: What the number represents
- **Context Headline**: Title for context area
- **Context Bullets**: 3-5 bullet points explaining context

### Optional Content

- **Stat Sublabel**: Additional stat context
- **Impact Box**: Small callout within stat card
- **Bottom Banner**: Footer context or metadata
- **Left Border**: Colored accent strip
- **Source**: Clickable source attribution link(s) — see Common fields

### Visual Hierarchy

1. HERO (stat number - 36pt, dominant)
2. CONTEXT (headline + bullets - 16pt/14pt)
3. BANNER (optional footer - 12pt, muted)

### Example (v4 — content-only)

```yaml
Layout: stat-card-with-context

Slide-Title: Krise 1: Sicherheit außer Kontrolle

Hero-Stat-Box:
  Number: 688
  Label: Schienensuizide jährlich
  Sublabel: + 2.661 Übergriffe auf Bahnhöfen
  Icon: shield

Impact-Box:
  Text: Deutschland führt EU-Statistik an

Context-Box:
  Headline: Warum manuelle Überwachung versagt
  Bullets:
    - Sicherheitspersonal kann nicht alle Bereiche 24/7 abdecken
    - Kritische Ereignisse werden zu spät erkannt
    - Das Netzwerk ist zu groß für punktuelle Überwachung

Bottom-Banner:
  Text: Deutschland führt die EU-Statistik an
```

---

## Layout 3: four-quadrants

2×2 grid of equal cards. Supports two modes: **stat-card mode** (default, number-focused) and **text-card mode** (when `Number` is absent and `Bullets` is present — used for persona cards, feature summaries, etc.).

### Required Content

- **Slide Title**: Slide headline
- **Quadrant 1-4**: Each requires `Label` and either `Number` (stat mode) or `Bullets` (text mode)

### Optional Content

- **Sublabels**: Additional context per quadrant
- **Icons**: Visual indicators per quadrant (stat mode only)
- **Bottom Banner**: Footer context
- **Source**: Clickable source attribution link(s) — see Common fields

### Visual Hierarchy

All quadrants have equal visual weight (balanced 2×2 grid).

### Example (Stat-Card Mode)

```yaml
Layout: four-quadrants

Slide-Title: Vier kritische Handlungsfelder

Quadrant-1:
  Number: 688
  Label: Sicherheit
  Sublabel: Suizide p.a.
  Icon: shield

Quadrant-2:
  Number: 42%
  Label: Infrastruktur
  Sublabel: Veraltete Systeme
  Icon: wrench

Quadrant-3:
  Number: 156%
  Label: Kapazität
  Sublabel: Überlastung
  Icon: users

Quadrant-4:
  Number: €2.8M
  Label: Kosten
  Sublabel: Notfall-OPs
  Icon: euro

Bottom-Banner:
  Text: Alle Bereiche benötigen sofortige Intervention
```

### Example (Text-Card Mode — Buying Center)

```yaml
Layout: four-quadrants

Slide-Title: Buying Center

Quadrant-1:
  Label: Economic Buyer
  Sublabel: CFO Infrastruktur
  Bullets:
    - "Führen mit: MEANS"
    - "ROI, Risikomanagement, Budgeteffizienz"
    - "Kostenreduktion als Haupttreiber"
    - "Alle Antworten in ROI-Begriffen"

Quadrant-2:
  Label: Technical Evaluator
  Sublabel: CTO / IT-Leiter
  Bullets:
    - "Führen mit: IS"
    - "Integration, Open-Source-Architektur"
    - "Legacy-Kompatibilität sicherstellen"
    - "Datenschutz + BSI IT-Grundschutz"

Quadrant-3:
  Label: End Users
  Sublabel: Leitstelle, Sicherheitspersonal
  Bullets:
    - "Führen mit: DOES"
    - "Workflow-Vereinfachung, Schulung"
    - "Alarmübermüdung minimieren"
    - "24/7-Zuverlässigkeit"

Quadrant-4:
  Label: Champion
  Sublabel: Leiter Digitalisierung
  Bullets:
    - "Führen mit: Glaubwürdigkeit"
    - "Vorzeigeprojekt für Transformation"
    - "Mandat als internen Hebel nutzen"
    - "BVG/AVG als ÖPNV-Referenzen"

Bottom-Banner:
  Text: "INTERN — VOR KUNDENPRÄSENTATION ENTFERNEN"
```

---

## Layout 4: two-columns-equal

Side-by-side 45%/45% columns with 10% gap for comparisons or paired content.

### Required Content

- **Slide Title**: Slide headline
- **Left Column Content**: Headline + bullets or image
- **Right Column Content**: Headline + bullets or image

### Optional Content

- **Column Callouts**: Highlighted info boxes
- **Bottom Banner**: Summary or conclusion
- **Source**: Clickable source attribution link(s) — see Common fields

### Visual Hierarchy

Both columns have equal visual weight.

### Example

```yaml
Layout: two-columns-equal

Slide-Title: Manuell vs. KI-gestützt

Left-Column:
  Headline: Manuelle Überwachung
  Bullets:
    - 24/7 Personal erforderlich
    - Reaktiv statt proaktiv
    - Keine Mustererkennung
    - Hohe Personalkosten

Right-Column:
  Headline: KI-Videoanalyse
  Bullets:
    - Automatische 24/7 Überwachung
    - Proaktive Warnungen
    - Lernende Mustererkennung
    - Skalierbare Lösung

Bottom-Banner:
  Text: KI reduziert Reaktionszeit um 87% bei 60% Kosteneinsparung
```

---

## Layout 5: is-does-means

Three vertical progression boxes showing IS → DOES → MEANS capability structure.

### Label Localization

The Layer Label badge text must match the presentation language:

| Language | IS | DOES | MEANS |
|----------|-----|------|-------|
| `en` | IS | DOES | MEANS |
| `de` | IST | MACHT | BEDEUTET |

Generators must set the `Label` field per box according to the `language` parameter.

### Required Content

- **Slide Title**: Solution or capability name
- **IS**: What the solution is (positioning statement)
- **DOES**: How it works (key capabilities)
- **MEANS**: HOW it works (technology/methodology proof)

### Optional Content

- **Bottom Banner**: Value proposition summary
- **Source**: Clickable source attribution link(s) — see Common fields

### Visual Hierarchy

1. IS (top, foundational)
2. DOES (middle, functional)
3. MEANS (bottom, technical proof)

### Example

```yaml
Layout: is-does-means

Slide-Title: KI-Videoanalytik für Bahnsicherheit

IS-Box:
  Label: IS
  Text: Eine KI-gestützte Plattform für automatisierte Echtzeit-Überwachung von Bahninfrastruktur

DOES-Box:
  Label: DOES
  Text: Analysiert 24/7 Videomaterial, erkennt kritische Ereignisse (Personen auf Gleisen, Vandalismus, unbefugter Zugang) und sendet Echtzeitwarnungen

MEANS-Box:
  Label: MEANS
  Text: Computer Vision Modelle (YOLOv8, Faster R-CNN) + Anomaly Detection + Edge Computing für <2s Latenz

Bottom-Banner:
  Text: Reduziert kritische Vorfälle um 73% in ersten 6 Monaten
```

---

## Layout 6: three-options

Comparison of 3 choices with equal width columns for pricing, features, or alternatives.

### Required Content

- **Slide Title**: Comparison category
- **Option 1-3**: Each requires name and features

### Optional Content

- **Pricing**: Cost per option
- **Badges**: Highlight recommended option
- **Bottom Banner**: Selection guidance
- **Source**: Clickable source attribution link(s) — see Common fields

### Visual Hierarchy

Center option often highlighted as recommended (accent border/background).

### Example

```yaml
Layout: three-options

Slide-Title: Rollout-Strategien im Vergleich

Option-1:
  Name: Pilot (3 Monate)
  Price: €50k
  Features:
    - 5 Bahnhöfe
    - 20 Kameras
    - Basisanalyse
    - Proof of Concept

Option-2:
  Name: Regional (12 Monate)
  Price: €280k
  Badge: Empfohlen
  Features:
    - 25 Bahnhöfe
    - 150 Kameras
    - Erweiterte Analysen
    - 24/7 Monitoring
    - Integration DB-Systeme

Option-3:
  Name: National (36 Monate)
  Price: €1.2M
  Features:
    - 100+ Bahnhöfe
    - 800+ Kameras
    - KI-Training
    - Zentrale Leitstelle
    - Vollintegration

Bottom-Banner:
  Text: Regionale Rollout bietet optimales Kosten-Nutzen-Verhältnis
```

---

## Layout 7: timeline-steps

Sequential process with 4-6 steps and connecting arrows.

### Required Content

- **Slide Title**: Process or timeline name
- **Steps 1-4**: Each requires number, label, description

### Optional Content

- **Durations**: Time per step
- **Step 5-6**: Additional steps (adjust spacing)
- **Bottom Banner**: Total duration or outcome
- **Source**: Clickable source attribution link(s) — see Common fields

### Visual Hierarchy

Left-to-right progression (step 1 → 2 → 3 → 4).

### Example

```yaml
Layout: timeline-steps

Slide-Title: Implementierungs-Roadmap

Step-1:
  Number: "1"
  Label: Discovery
  Description: Anforderungsanalyse, Stakeholder-Interviews, Infrastruktur-Assessment
  Duration: 4 Wochen

Step-2:
  Number: "2"
  Label: Pilot
  Description: Installation an 5 Bahnhöfen, KI-Training, erste Validierung
  Duration: 8 Wochen

Step-3:
  Number: "3"
  Label: Rollout
  Description: Skalierung auf 25 Standorte, Leitstand-Integration, Team-Training
  Duration: 12 Wochen

Step-4:
  Number: "4"
  Label: Optimize
  Description: Kontinuierliche Optimierung, erweiterte Features, Expansion
  Duration: Laufend

Bottom-Banner:
  Text: Gesamtdauer: 6 Monate bis Vollbetrieb
```

---

## Layout 8: layered-architecture

Architecture box diagram with 2-3 vertical lanes, boxes within each lane, and labeled arrow connectors between boxes. Always rendered left-to-right (optimized for 16:9). Used for solution sketches, system architectures, and data flow diagrams.

### Required Content

- **Slide Title**: Architecture description headline (assertion, not label)
- **Diagram**: Mermaid `graph LR` source with subgraphs defining lanes, nodes within subgraphs, and edges between nodes

### Optional Content

- **Bottom Banner**: Summary statement
- **Speaker-Notes**: Full architecture detail from original source
- **Source**: Architecture documentation reference

### Constraints

- **2-3 lanes** (subgraphs), max 4 nodes per lane, max 10 nodes total
- **Always LR** — brief must pre-transpose TB/TD
- Node labels max ~25 chars, edge labels max ~15 chars
- Dashed edges (`-.->`) render as dashed arrows

### Example

```yaml
Layout: layered-architecture

Slide-Title: Edge-to-Cloud Architektur

Diagram: |
  graph LR
    subgraph Edge["Edge"]
      A["IP-Kameras + Jetson AI"]
    end
    subgraph Cloud["Open Telekom Cloud"]
      B["Kafka Streaming"]
      C["KI-Analyse-Engine"]
      D["PostgreSQL + Redis"]
    end
    subgraph Operations["Operations"]
      E["Dashboard + Grafana"]
      F["Alerting"]
    end
    A -->|Metadaten| B
    B --> C
    C --> D
    C --> E
    C -.->|Alarme| F

Bottom-Banner:
  Text: Strikte Trennung Edge/Cloud — Videodaten bleiben lokal
```

---

## Layout 9: process-flow

Horizontal chain of evenly-spaced boxes with arrow connectors. For linear pipelines and simple sequential processes that don't fit the step-by-step structure of timeline-steps.

### Required Content

- **Slide Title**: Process description headline
- **Diagram**: Mermaid `graph LR` source with nodes and edges (no subgraphs)

### Optional Content

- **Bottom Banner**: Summary or outcome statement
- **Speaker-Notes**: Process detail
- **Detail-Grid**: Per-node key concepts (3-4 short items keyed by node id) — the Methodology prep slide uses this to list each phase's concepts under the pipeline

### Constraints

- **3-6 nodes**, no subgraphs
- **Always LR** — linear chain only
- Node labels max ~20 chars
- Optional edge labels between nodes

### Example

```yaml
Layout: process-flow

Slide-Title: Datenverarbeitung in 4 Schritten

Diagram: |
  graph LR
    A["Videoerfassung"] --> B["Edge-Inferenz"]
    B -->|Metadaten| C["Cloud-Analyse"]
    C --> D["Echtzeit-Dashboard"]

Bottom-Banner:
  Text: Ende-zu-Ende-Latenz unter 2 Sekunden
```

---

## Layout 10: gantt-chart

Horizontal Gantt chart with phase groups on the left and time bars on the right. For project plans, implementation roadmaps, and rollout timelines.

### Required Content

- **Slide Title**: Timeline headline (e.g., "In 34 Wochen vom PoV zum Pilotbetrieb")
- **Diagram**: Mermaid `gantt` source with sections and tasks

### Optional Content

- **Bottom Banner**: Total duration or outcome statement
- **Speaker-Notes**: Task detail, dependencies, resource allocation

### Constraints

- **Max 8 tasks**, max 4 phases (sections)
- Date format: `YYYY-MM-DD`
- Row height auto-adjusts based on task count
- Time axis shows months or quarters depending on total duration

### Example

```yaml
Layout: gantt-chart

Slide-Title: In 34 Wochen vom PoV zum Pilotbetrieb

Diagram: |
  gantt
    dateFormat YYYY-MM-DD
    section Phase 1
    Proof of Value      :done, pov, 2026-03-01, 42d
    section Phase 2
    Small Scale Pilot   :active, ssp, 2026-04-12, 84d
    section Phase 3
    Medium Scale        :ms, 2026-07-05, 56d
    section Phase 4
    Enterprise Rollout  :er, 2026-08-30, 84d

Bottom-Banner:
  Text: Jede Phase liefert eigenständigen Geschäftswert
```

---

## Layout 11: closing-slide

Closing slide with centered CTA, key takeaway, and contact information.

### Required Content

- **Title**: CTA headline (max 60 chars) - action-oriented
- **Subtitle**: Key takeaway or next step (max 100 chars)

### Optional Content

- **Metadata**: Contact info, presenter details
- **Logo**: Theme-specific logo placement

### Visual Hierarchy

1. Title (largest, bold, accent color)
2. Subtitle (medium, normal weight)
3. Metadata (smallest, muted color)

### Example

```yaml
Layout: closing-slide
Title: Handeln Sie jetzt — Förderfenster schließt
Subtitle: Pilotprojekt in 6 Wochen starten
Metadata: kontakt@t-systems.com | +49 123 456 789
```

---

## Layout Selection Guide

| Use Case | Recommended Layout |
|----------|-------------------|
| Opening slide | title-slide |
| Closing slide / CTA | closing-slide |
| Crisis or stat-focused slide | stat-card-with-context |
| Multiple metrics | four-quadrants |
| Comparison (2 items) | two-columns-equal |
| Solution capability (IS/DOES/MEANS) | is-does-means |
| Pricing/Features | three-options |
| Process/Timeline (text steps) | timeline-steps |
| Architecture / system diagram (Mermaid) | layered-architecture |
| Linear data pipeline (Mermaid) | process-flow |
| Project plan / Gantt chart (Mermaid) | gantt-chart |

---

## Common fields

Fields every layout may carry in addition to its own. The per-slide keys new in 4.1 — `Slide-Kind`, `intent` (with `role`, `emphasis`) and `visual` (with `kind`, `chart`, `image_prompt`) — are defined once in `libraries/presentation-brief-template.md` → Slide grammar and are not restated here.

1. **Layout**: the layout name, exactly as headed above — `Layout: stat-card-with-context`. `scripts/check-brief.py` (`layout-enum`) rejects any other spelling.
2. **Slide-Title**: the on-slide headline for every layout except `title-slide` and `closing-slide`, which use `Title`/`Subtitle`. The `## Slide N:` heading carries the assertion headline; `Slide-Title` is what the slide shows and is usually the same sentence.
3. **Bottom-Banner**: optional on every layout, `Bottom-Banner: { Text: ... }`, at most 12 words. Internal prep slides carry the INTERNAL warning here (`INTERNAL — REMOVE FROM CLIENT PRESENTATION` / `INTERN — VOR KUNDENPRÄSENTATION ENTFERNEN`).
4. **Speaker-Notes**: optional on every layout; a multi-line `|` block in two sections — `>> WHAT YOU SAY` (delivery script with `[Opening]`, `[Key point]`, `[Pause]`, `[Emphasis]`, `[Transition]` tags) and `>> WHAT YOU NEED TO KNOW` (sources, context, Q&A prep). German: `>> WAS SIE SAGEN` / `>> WAS SIE WISSEN MÜSSEN` with `[Einstieg]`, `[Kernaussage]`, `[Pause]`, `[Betonung]`, `[Überleitung]`. Target 200–400 words per content slide (150 minimum, 450 maximum). Citations inside notes are plain `[N](url)` links, never superscript. The renderer carries notes complete into its native notes channel.
5. **Source**: optional on every content layout (not `title-slide` or `closing-slide`): `Source: "[Label](URL)"`, at most two sources separated by ` | `. Only written when the source narrative provides a URL — never invented.
6. **Inline citations**: body text fields (bullets, box texts, features, descriptions) carry claim-level markers as `<sup>[N](url)</sup>`, numbered sequentially across the deck. They never appear in headlines, `Bottom-Banner`, `Hero-Stat-Box` fields, or step labels and numbers — the exclusion zones `check-brief.py` (`cite-zones`) enforces.
7. **Diagram**: required on `layered-architecture`, `process-flow` and `gantt-chart` — Mermaid source as a `|` block, pre-simplified by the brief's author to each layout's Constraints. The Mermaid text is data, not an image: renderers build native shapes from it.
8. **cta**: optional per-slide `{ text, type, urgency }` with `type` one of `explore`, `evaluate`, `commit`, `share`; summarised in the brief's `## CTA Summary`. Renderers do not draw it.
9. **Icon**: optional on stat cards and quadrants — a short icon name (`shield`, `wrench`, `users`, `euro`). The renderer maps it to its own icon set or omits it.
10. **Section roles**: a 4.1 brief declares each slide's role as `intent.role` (`hook`, `problem`, `urgency`, `evidence`, `solution`, `proof`, `options`, `roadmap`, `investment`, `call-to-action`); read it rather than re-deriving it. A 4.0 brief carries none.
11. **Internal prep slides**: declared by `Slide-Kind: internal-prep` (4.1); a `Bottom-Banner` containing `INTERNAL`/`INTERN` is the 4.0 fallback. They follow Slide 1 directly — Methodology (`process-flow` with `Detail-Grid`) then, in Rich audience mode, Buying Center (`four-quadrants` text-card mode) — and are not counted against `max_slides`.
12. **References slide**: declared by `Slide-Kind: references` (4.1) on a `two-columns-equal` slide; last-in-deck position is the 4.0 fallback. It is always the last slide, after `closing-slide`, so sources read as an appendix rather than an interruption before the call-to-action.
13. **Required vs optional**: renderers may assume the required fields are present because `check-brief.py` (`layout-required-fields`) rejects a brief that lacks one; an optional field that is absent is simply not rendered.
