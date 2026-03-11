---
library_id: pptx-layouts
version: 1.0.0
created: 2026-02-04
updated: 2026-02-04
---

# PPTX Layout Library

Standard layout definitions for PptxGenJS presentation generation. Each layout specifies exact positioning (x, y, w, h in inches), required fields, and optional fields for consistent slide creation.

---

## Layout 1: title-slide

Opening slide with centered title, subtitle, and metadata.

### Elements

| Element | X | Y | W | H | Alignment |
|---------|---|---|---|---|-----------|
| title | 1.0 | 1.8 | 8.0 | 1.2 | center |
| subtitle | 1.0 | 3.2 | 8.0 | 0.6 | center |
| metadata | 1.0 | 4.2 | 8.0 | 0.4 | center |
| logo | 4.5 | 0.4 | 1.0 | 0.6 | center |

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

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| leftBorder | 0.62 | 1.2 | 0.08 | 3.0 | Accent strip (optional) |
| heroStatBox | 0.7 | 1.2 | 4.0 | 3.0 | Large stat card |
| statNumber | 0.85 | 1.4 | 3.7 | 0.55 | Number (36pt, bold) |
| statLabel | 0.85 | 1.95 | 3.7 | 0.3 | Label (13pt, bold) |
| statSublabel | 0.85 | 2.25 | 3.7 | 0.25 | Sublabel (10pt, optional) |
| impactBox | 0.85 | 3.7 | 3.7 | 0.35 | Impact callout (optional) |
| contextBox | 5.1 | 1.2 | 4.6 | 3.0 | Context area |
| contextHeadline | 5.25 | 1.35 | 4.3 | 0.4 | Context headline (16pt, bold) |
| contextBullets | 5.25 | 1.85 | 4.3 | 2.0 | Bullet points (14pt) |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer bar (optional) |

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
- **Source**: Clickable source attribution link(s) — see Note 10

### Visual Hierarchy

1. HERO (stat number - 36pt, dominant)
2. CONTEXT (headline + bullets - 16pt/14pt)
3. BANNER (optional footer - 12pt, muted)

### Color Fields (Optional)

Color fields (`Background`, `Text-Color`, `Icon-Color`) are **optional**. When present (v2-v3 briefs), the PPTX skill uses them directly. When absent (v4 briefs), the PPTX skill infers colors from the theme directly.

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

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| quadrant1 | 0.7 | 1.2 | 4.2 | 1.5 | Top-left card |
| quadrant2 | 5.1 | 1.2 | 4.2 | 1.5 | Top-right card |
| quadrant3 | 0.7 | 2.8 | 4.2 | 1.5 | Bottom-left card |
| quadrant4 | 5.1 | 2.8 | 4.2 | 1.5 | Bottom-right card |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

### Quadrant Internal Layout — Stat-Card Mode (default)

When `Number` is present, each quadrant renders as a stat card:
- **Number**: 24pt, bold, top-aligned
- **Label**: 12pt, bold, below number
- **Sublabel**: 10pt, optional, below label
- **Icon**: 32×32px, optional, top-right corner

### Quadrant Internal Layout — Text-Card Mode

When `Number` is absent and `Bullets` is present, each quadrant renders as a text card with a thin accent bar at top:
- **Accent bar**: 4px height, full card width, primary or accent color (Champion card uses theme accent)
- **Label**: 14pt, bold, muted color — role or category name
- **Sublabel**: 14pt, normal, body color — person title or description
- **Bullets**: 9pt, normal, body color — 3-4 key messages (first bullet often formatted as "Lead with: {approach}")

### Required Content

- **Slide Title**: Slide headline
- **Quadrant 1-4**: Each requires `Label` and either `Number` (stat mode) or `Bullets` (text mode)

### Optional Content

- **Sublabels**: Additional context per quadrant
- **Icons**: Visual indicators per quadrant (stat mode only)
- **Bottom Banner**: Footer context
- **Source**: Clickable source attribution link(s) — see Note 10

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

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| leftColumn | 0.7 | 1.2 | 4.0 | 3.3 | Left content area |
| rightColumn | 5.2 | 1.2 | 4.0 | 3.3 | Right content area |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

### Column Internal Layout

Each column can contain:
- **Headline**: 18pt, bold
- **Body Text**: 14pt, 3-6 bullet points
- **Image/Chart**: Variable height
- **Callout Box**: Highlighted info

### Required Content

- **Slide Title**: Slide headline
- **Left Column Content**: Headline + bullets or image
- **Right Column Content**: Headline + bullets or image

### Optional Content

- **Column Callouts**: Highlighted info boxes
- **Bottom Banner**: Summary or conclusion
- **Source**: Clickable source attribution link(s) — see Note 10

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

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| isBox | 0.7 | 1.2 | 8.6 | 0.9 | IS layer (What) |
| doesBox | 0.7 | 2.2 | 8.6 | 0.9 | DOES layer (How) |
| meansBox | 0.7 | 3.2 | 8.6 | 0.9 | MEANS layer (Evidence) |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

### Box Internal Layout

Each box contains:
- **Layer Label**: "IS" / "DOES" / "MEANS" (12pt, badge)
- **Content**: 14pt text, 1-2 sentences
- **Separator**: Subtle divider line

### Required Content

- **Slide Title**: Solution or capability name
- **IS**: What the solution is (positioning statement)
- **DOES**: How it works (key capabilities)
- **MEANS**: Why it works (evidence/technology)

### Optional Content

- **Bottom Banner**: Value proposition summary
- **Source**: Clickable source attribution link(s) — see Note 10

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

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| option1 | 0.7 | 1.2 | 2.7 | 3.0 | Left option |
| option2 | 3.6 | 1.2 | 2.7 | 3.0 | Center option |
| option3 | 6.5 | 1.2 | 2.7 | 3.0 | Right option |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

### Option Internal Layout

Each option contains:
- **Header**: 14pt, bold, option name
- **Price/Value**: 18pt, bold (if pricing)
- **Features**: 12pt bullets, 3-5 items
- **Badge**: "Recommended" or similar (optional)

### Required Content

- **Slide Title**: Comparison category
- **Option 1-3**: Each requires name and features

### Optional Content

- **Pricing**: Cost per option
- **Badges**: Highlight recommended option
- **Bottom Banner**: Selection guidance
- **Source**: Clickable source attribution link(s) — see Note 10

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

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| step1 | 0.7 | 1.5 | 1.5 | 1.8 | Step 1 box |
| arrow1 | 2.3 | 2.3 | 0.3 | 0.2 | Arrow 1→2 |
| step2 | 2.7 | 1.5 | 1.5 | 1.8 | Step 2 box |
| arrow2 | 4.3 | 2.3 | 0.3 | 0.2 | Arrow 2→3 |
| step3 | 4.7 | 1.5 | 1.5 | 1.8 | Step 3 box |
| arrow3 | 6.3 | 2.3 | 0.3 | 0.2 | Arrow 3→4 |
| step4 | 6.7 | 1.5 | 1.5 | 1.8 | Step 4 box |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

### Step Internal Layout

Each step contains:
- **Number**: 18pt, bold, top
- **Label**: 13pt, bold, step name
- **Description**: 11pt, 2-3 lines
- **Duration**: 10pt, optional

### Required Content

- **Slide Title**: Process or timeline name
- **Steps 1-4**: Each requires number, label, description

### Optional Content

- **Durations**: Time per step
- **Step 5-6**: Additional steps (adjust spacing)
- **Bottom Banner**: Total duration or outcome
- **Source**: Clickable source attribution link(s) — see Note 10

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

**Geometry reference:** See `diagram-layouts.md` for dynamic position calculations.

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| lane1Zone | 0.7 | 1.2 | dynamic | 3.3 | Lane 1 background zone |
| lane2Zone | dynamic | 1.2 | dynamic | 3.3 | Lane 2 background zone |
| lane3Zone | dynamic | 1.2 | dynamic | 3.3 | Lane 3 background zone (optional) |
| laneHeaders | per lane | 1.2 | per lane | 0.3 | Lane labels (muted, uppercase) |
| nodeBoxes | per node | per node | per node | 0.55 | Rounded rectangles with text |
| arrows | computed | computed | computed | - | Connectors with optional labels |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

Lane widths are computed dynamically: `laneWidth = (8.6 - (laneCount - 1) × 0.3) / laneCount`. Nodes are centered vertically within their lane.

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

**Geometry reference:** See `diagram-layouts.md` for dynamic position calculations.

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| node1-N | computed | 1.8 | computed | 1.2 | Node boxes (3-6) |
| arrow1-N | computed | 2.3 | 0.3 | - | Arrow connectors between nodes |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

Node widths are computed dynamically: `nodeWidth = min(2.0, (8.6 - (nodeCount - 1) × 0.3) / nodeCount)`.

### Required Content

- **Slide Title**: Process description headline
- **Diagram**: Mermaid `graph LR` source with nodes and edges (no subgraphs)

### Optional Content

- **Bottom Banner**: Summary or outcome statement
- **Speaker-Notes**: Process detail

### Node Internal Layout

Each node contains:
- **Label**: 13pt, bold, centered
- **Description**: 10pt, normal, below label (from Mermaid node text after `\n`)

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

**Geometry reference:** See `diagram-layouts.md` for dynamic position calculations.

### Elements

| Element | X | Y | W | H | Description |
|---------|---|---|---|---|-------------|
| slideTitle | 0.7 | 0.35 | 9.0 | 0.6 | Slide headline |
| timeAxis | 3.4 | 1.2 | 6.2 | 0.35 | Month/quarter labels |
| phaseHeaders | 0.7 | per phase | 2.6 | 0.25 | Phase group labels |
| taskLabels | 0.7 | per task | 2.6 | 0.30 | Task name labels (left) |
| taskBars | computed | per task | computed | 0.30 | Colored bars (right) |
| bottomBanner | 0.7 | 4.7 | 8.6 | 0.5 | Footer (optional) |

Bar X and width are computed from task start dates and durations relative to the total date range.

### Required Content

- **Slide Title**: Timeline headline (e.g., "In 34 Wochen vom PoV zum Pilotbetrieb")
- **Diagram**: Mermaid `gantt` source with sections and tasks

### Optional Content

- **Bottom Banner**: Total duration or outcome statement
- **Speaker-Notes**: Task detail, dependencies, resource allocation

### Status Styling

| Mermaid Status | Visual Style |
|----------------|-------------|
| `:done` | Primary color, 40% transparency, checkmark |
| `:active` | Primary color, full opacity, accent border |
| `:crit` | Danger/warning color, full opacity |
| (unmarked) | Tertiary background, dashed border |

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

### Elements

| Element | X | Y | W | H | Alignment |
|---------|---|---|---|---|-----------|
| title | 1.0 | 1.8 | 8.0 | 1.2 | center |
| subtitle | 1.0 | 3.2 | 8.0 | 0.6 | center |
| metadata | 1.0 | 4.2 | 8.0 | 0.4 | center |
| logo | 4.5 | 0.4 | 1.0 | 0.6 | center |

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

## Notes for Generators

1. **Coordinates**: All x, y, w, h values are in inches from top-left origin (0,0)
2. **Safe Margins**: Layouts respect contentStartX (0.7") and contentWidth (8.6")
3. **Color Fields**: Optional in v4.0 briefs. When present, PPTX skill uses them directly. When absent, PPTX skill infers from theme directly
4. **Layout Prefix**: Briefs should specify `Layout: stat-card-with-context` etc.
5. **Required vs Optional**: Generators should validate required fields before rendering
6. **Flexible Heights**: Some layouts allow variable heights within constraints
7. **Bottom Banner**: Always optional, use for context/metadata when needed
8. **Icons**: Icon placement varies by layout, reference icon-library.md for mappings
9. **Speaker-Notes**: Optional field for all layouts. Contains comprehensive presenter notes in two sections, rendered via PptxGenJS `slide.addNotes()`. Format is multi-line YAML string with `>> WHAT YOU SAY` (delivery script with `[Opening]`, `[Key point]`, `[Pause]`, `[Emphasis]`, `[Transition]` tags) and `>> WHAT YOU NEED TO KNOW` (bullet list of sources, context, Q&A prep). German: `>> WAS SIE SAGEN` / `>> WAS SIE WISSEN MÜSSEN` with tags `[Einstieg]`, `[Kernaussage]`, `[Pause]`, `[Betonung]`, `[Überleitung]`. Target 100-200 words per slide.
10. **Source**: Optional field for all content layouts (not title-slide or closing-slide). Contains markdown-formatted clickable link(s) to the data source for the slide's key claim. Format: `Source: "[Label](URL)"`. For multiple sources use pipe separation: `Source: "[Label1](URL1) | [Label2](URL2)"`. Maximum 2 sources per slide. Only generated when the source narrative actually provides URLs — never invented or guessed. When the `>> WHAT YOU NEED TO KNOW` section of Speaker-Notes references a source, use inline markdown links there as well.

    **PptxGenJS rendering:** Use `createSourceFooter()` from pptx-components.js to render the Source field as a clickable footer positioned above the Bottom-Banner area:

    ```javascript
    // Single source
    createSourceFooter(slide, theme, {
      text: '[Federal Rail Safety Report 2024](https://eba.bund.de/report)'
    });

    // Multiple pipe-separated sources
    createSourceFooter(slide, theme, {
      text: '[Bundesbericht 2024](https://eba.bund.de/report) | [EBA Statistik](https://eba.bund.de/stats)'
    });
    ```
11. **Section Roles** (internal concept): story-to-slides assigns section roles (hook/problem/urgency/evidence/solution/proof/options/roadmap/investment/call-to-action) during Step 3c arc analysis for internal workflow decisions (layout tiebreaking, speaker-note coaching, PEAK/RELEASE detection). These roles do NOT appear in the brief output. The PPTX skill reads `theme.md` directly for all color decisions.
12. **Internal Prep Slides**: Slides with `Bottom-Banner` text containing "INTERNAL" (EN) or "INTERN" (DE) are presenter preparation slides auto-generated by story-to-slides Step 7c. They are numbered sequentially after Slide 1 (title): Slide 2 (Methodology — `process-flow` layout with `Detail-Grid`) and Slide 3 (Buying Center — `four-quadrants` text-card mode). Methodology comes first (shows pitch phases), Buying Center second (shows stakeholder cards). They are not counted against `max_slides`. Content slides begin at the next sequential number after the internal prep slides.
16. **References Slide Positioning**: The references slide (consolidated citations) is placed AFTER the closing-slide as the **last slide in the deck**. This positions sources as an appendix after the call-to-action, not as a content interruption before it.
13. **Inline Citations**: Body text fields (Bullets, Text boxes, Features, Descriptions) may contain inline citation markers in `[N](url)` format, where N is a sequential reference number. These are claim-level source attributions that complement the slide-level Source field. The PPTX skill renders these as clickable hyperlinks using `parseMarkdownLinks()` from pptx-components.js. Inline citations do NOT appear in Headlines, Bottom-Banner, Hero-Stat-Box Number/Label/Sublabel, or Step Labels/Numbers.

    **PptxGenJS rendering:** Component functions `createContextBox()` and `createLayerBox()` handle this internally. For inline PptxGenJS code in other layouts, use `parseMarkdownLinks()`:

    ```javascript
    // Bullet with inline citation
    const bulletText = 'Security staff cannot cover all areas 24/7 [1](https://eba.bund.de/report)';
    const parsed = parseMarkdownLinks(bulletText);
    // => [{ text: 'Security staff...' }, { text: '1', options: { hyperlink: { url: '...' }, color: '0563C1', underline: true } }]

    // For bulleted text: set bullet on the first run
    if (Array.isArray(parsed)) {
      parsed[0].options = { ...parsed[0].options, bullet: true };
    }
    slide.addText(parsed, { x: 1, y: 1, w: 8, h: 2, fontSize: 14 });
    ```
14. **Diagram**: Optional field for diagram layouts (`layered-architecture`, `process-flow`, `gantt-chart`). Contains Mermaid source text as the data input — the `Layout:` value determines the rendering strategy. The PPTX skill extracts structured data (nodes, edges, tasks) from the Mermaid text and applies geometry calculations from `diagram-layouts.md` to render native PptxGenJS shapes. Mermaid source in the `Diagram:` field must be pre-simplified by story-to-slides to respect layout constraints (max nodes, max lanes, max tasks). The Mermaid text is NOT rendered as an image — it serves as a compact, previewable data description that produces editable native PPTX shapes. Backward compatible: briefs without `Diagram:` work unchanged.
15. **Text Hyperlinks (PptxGenJS API)**: PptxGenJS supports clickable hyperlinks on text runs via the `hyperlink: { url }` option in text run arrays. This is the authoritative reference for hyperlink rendering — use it whenever generating inline PptxGenJS code for links.

    ```javascript
    // Single hyperlink text
    slide.addText([
      { text: 'Click here', options: { hyperlink: { url: 'https://example.com' }, color: '0563C1', underline: true } }
    ], { x: 1, y: 1, w: 8, h: 1 });

    // Mixed text with hyperlinks
    slide.addText([
      { text: 'See ' },
      { text: 'source', options: { hyperlink: { url: 'https://example.com' }, color: '0563C1', underline: true } },
      { text: ' for details' }
    ], { x: 1, y: 1, w: 8, h: 1 });

    // Bulleted text with hyperlink (bullet on first run only)
    slide.addText([
      { text: 'Claim with evidence ', options: { bullet: true } },
      { text: '1', options: { hyperlink: { url: 'https://example.com/report' }, color: '0563C1', underline: true } }
    ], { x: 1, y: 1, w: 8, h: 2, fontSize: 14 });
    ```

    **Utility:** Use `parseMarkdownLinks(text)` from pptx-components.js to convert `[text](url)` patterns into the text run array format above. Returns the original string unchanged when no links are present (backward compatible). Standard hyperlink color: `0563C1`.

---
