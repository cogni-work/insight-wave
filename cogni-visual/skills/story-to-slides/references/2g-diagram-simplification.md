# Diagram Detection & Simplification

## Purpose

Define how story-to-slides detects Mermaid diagrams in narrative input, classifies their topology, simplifies complex diagrams to slide-friendly structures, and preserves original detail in speaker notes.

**Core principle:** Slides communicate ONE message per slide. A 12-node architecture diagram communicates "complexity" — not "architecture." Simplification extracts the message-relevant structure and moves implementation detail to speaker notes.

---

## Step 2g: Diagram Detection

During Step 2 (Read Narrative Content), scan each input `.md` file for Mermaid fenced code blocks:

```text
DETECT Mermaid blocks:
  1. SCAN for ```mermaid ... ``` fenced blocks in narrative files
  2. For each block found:
     a. EXTRACT the Mermaid source text
     b. IDENTIFY the diagram type from the first keyword line
     c. CLASSIFY the topology (see Classification below)
     d. REASON through simplification needs (see Simplification Reasoning Protocol)
     e. APPLY simplification rules if needed
     f. VERIFY the simplified diagram still communicates the slide message
     g. STORE: simplified Mermaid + type + topology for Step 6 layout selection
     h. STORE: original detail for speaker notes generation in Step 8c
```

**Detection also applies to solution-sketch files:** When the input directory contains files named `solution-sketch-*.md`, these typically contain architecture Mermaid blocks and a Components table. The Mermaid block becomes a diagram slide; the Components table becomes speaker notes material.

---

## Classification Decision Tree

```text
READ the first non-empty line after ```mermaid:

  "gantt"
    → TYPE: gantt
    → LAYOUT: gantt-chart

  "graph" or "flowchart"
    → CHECK for subgraph blocks:
      HAS subgraph blocks?
        → TYPE: layered-graph
        → LAYOUT: layered-architecture

      NO subgraph blocks?
        → CHECK topology:
          All edges form a single chain (A→B→C→D)?
            → TYPE: linear-graph
            → LAYOUT: process-flow

          One node has ≥3 edges (hub)?
            → TYPE: hub-graph
            → INFER 3 implicit lanes: inputs | hub | outputs
            → LAYOUT: layered-architecture

          Otherwise (branches, cycles, complex)?
            → TYPE: complex-graph
            → SIMPLIFY to linear happy path
            → LAYOUT: process-flow

  "timeline"
    → TYPE: timeline (DEFERRED — Phase 2)
    → For now: extract steps as text → use existing timeline-steps layout with Step-N fields

  "pie"
    → TYPE: pie (DEFERRED — Phase 2)
    → For now: extract data as bullets → use stat-card-with-context or four-quadrants

  "mindmap"
    → TYPE: mindmap (DEFERRED — Phase 2)
    → For now: flatten to bullets → use four-quadrants or two-columns-equal

  "sequenceDiagram", "classDiagram", "erDiagram", "stateDiagram"
    → TYPE: unsupported
    → DECOMPOSE: extract key relationships as text → use process-flow or two-columns-equal
    → FLAG: <!-- DIAGRAM: Unsupported type '{type}' decomposed to text layout -->
```

---

## Simplification Reasoning Protocol

Before applying mechanical simplification rules, reason through WHAT the diagram should communicate on this slide. This protocol ensures simplification serves the message rather than just reducing node count.

**For every diagram that exceeds layout constraints, complete these reasoning steps:**

```text
STEP 1 — IDENTIFY THE SLIDE MESSAGE:
  Ask: "What is the ONE thing this slide must communicate?"

  Consider the narrative section where this diagram appeared:
    - What argument does the surrounding text make?
    - Is this diagram showing architecture, process, timeline, or comparison?
    - What would the audience remember 5 minutes after seeing this slide?

  Output: A single assertion sentence (not a topic label).

  GOOD: "Edge-to-Cloud in 3 Schichten — von der Kamera bis zum Dashboard"
  BAD:  "System Architecture"
  BAD:  "Technical Overview"

STEP 2 — DETERMINE THE PRIMARY DATA FLOW:
  Ask: "What is the dominant direction of information/value through this system?"

  Trace the main path from input to output:
    - Where does data/value enter the system?
    - What transforms it?
    - Where does it exit (to the user, customer, or business)?

  This flow becomes the left-to-right spine of the simplified diagram.

STEP 3 — CLASSIFY NODES BY MESSAGE RELEVANCE:
  For each node in the original diagram, ask:
    "Does this node appear in the slide message or directly support it?"

  Classify each node:
    ESSENTIAL — Appears in or directly supports the slide message
    SUPPORTING — Adds context but isn't in the message itself
    DETAIL — Implementation/infrastructure the audience doesn't need to see

  Rule: ESSENTIAL nodes always survive simplification.
        SUPPORTING nodes survive if within constraints.
        DETAIL nodes move to speaker notes.

STEP 4 — GROUP INTO LOGICAL ZONES:
  Ask: "How do the essential + supporting nodes cluster into 2-3 zones?"

  Common zone patterns:
    Input → Processing → Output
    Source → Platform → Consumer
    Edge → Cloud → Operations
    Data → Intelligence → Action

  Name zones with audience-facing labels (not technical jargon).

STEP 5 — APPLY MECHANICAL RULES:
  Now apply the constraint-specific rules below (architecture, linear, gantt, hub).
  The reasoning from Steps 1-4 guides WHICH nodes to keep and HOW to group them.

STEP 6 — VERIFY:
  Ask: "Does the simplified diagram still communicate the slide message from Step 1?"

  Check:
    - Can someone read the simplified diagram and understand the assertion?
    - Are the essential nodes visible?
    - Does the primary data flow (Step 2) read left-to-right?
    - Is the slide message achievable as a headline for this diagram?

  If NO: Adjust — keep more essential nodes or rename zones.
```

---

## Simplification Rules

### Architecture Diagrams (layered-graph, hub-graph)

Architecture sketches are the primary use case. Solution sketches often have 4-5 layers with 10+ components — far too dense for one slide.

**Constraints:**
- Max **3 lanes** (subgraphs/layers)
- Max **4 nodes per lane**
- Max **10 nodes total**
- **Always LR direction** — Mermaid TB/TD is transposed to LR (16:9 aspect ratio)

```text
SIMPLIFY architecture diagram:

  1. COUNT layers (subgraphs) and nodes
     → ≤3 layers AND ≤10 nodes? → No simplification needed, use as-is (transpose to LR if TB)
     → Otherwise, apply rules below:

  2. MERGE LAYERS to max 3:
     → Use the PRIMARY DATA FLOW from Reasoning Step 2
     → Group subgraphs into 3 logical zones from Reasoning Step 4:
       Lane 1: Data sources / inputs (Edge, sensors, integrations)
       Lane 2: Processing / core platform (APIs, engines, databases)
       Lane 3: Consumers / outputs (dashboards, alerts, users)
     → Use descriptive lane names that match the slide's message
     → PRESERVE: Full layer list in speaker notes

  3. COLLAPSE NODES within each lane:
     → Use the node classification from Reasoning Step 3:
       ESSENTIAL nodes → keep as individual boxes
       SUPPORTING nodes → keep if within lane limit (max 4)
       DETAIL nodes → collapse or absorb

     → Collapse strategies:
       Multiple similar components → single box with count
         Example: "Camera 1", "Camera 2", "Camera 3" → "3× IP-Kameras"
       Middleware chain → single integration box
         Example: "MQTT" → "Kafka" → "Kafka Streaming" (absorbs MQTT)
       Storage components → combined data box
         Example: "PostgreSQL" + "Redis" → "PostgreSQL + Redis"
     → PRESERVE: Full component list in speaker notes

  4. SIMPLIFY EDGES:
     → Keep only edges on the PRIMARY DATA FLOW path (from Reasoning Step 2)
     → Remove feedback loops, monitoring edges, secondary paths
     → Bidirectional edges → pick dominant direction
     → Dotted/dashed edges in Mermaid (-.->): keep if message-relevant (e.g., alerts)
     → PRESERVE: Full edge list in speaker notes

  5. ADD EDGE LABELS only for protocol/format transitions:
     → Good: |RTSP|, |Metadaten|, |REST|, |Alarme|
     → Skip: generic edges without meaningful label

  6. TRANSPOSE direction:
     → If original is TB/TD: rewrite as LR with lanes reordered left-to-right
     → Mapping: top→left, bottom→right (data flows left-to-right)
```

**Before/After Example with Reasoning Trace:**

Original (5 layers, 12 nodes, 13 edges):
```
flowchart TB
    subgraph Presentation["Präsentationsschicht"]
        DASHBOARD["Operations Dashboard"]
        ALERTS["Alerting & Notifications"]
    end
    subgraph Application["Applikationsschicht"]
        API["API Gateway"]
        CORE["KI-Analyse-Engine"]
        LOGIC["Geschäftslogik & Regelwerk"]
    end
    subgraph Data["Datenschicht"]
        DB[("Betriebsdatenbank")]
        CACHE[("Stream Cache")]
    end
    subgraph Edge["Edge Layer"]
        JETSON["NVIDIA Jetson Orin"]
        CAMS["IP67 Kameras"]
    end
    subgraph Integrations["Integrationsschicht"]
        MQTT_BUS["MQTT Broker"]
        KAFKA["Apache Kafka"]
        GRAFANA["Grafana Enterprise"]
    end
```

**Reasoning trace:**

```text
Step 1 — Slide message: "Edge-to-Cloud in 3 Schichten — von der Kamera bis zum Dashboard"
  The narrative section describes how video feeds flow from edge devices through
  cloud processing to operational dashboards. The message is about the end-to-end
  architecture simplicity, not implementation detail.

Step 2 — Primary data flow: Camera → Edge AI → Streaming → Analysis → Dashboard
  Data enters at cameras, gets pre-processed on Jetson edge devices, streams via
  Kafka to the KI-Analyse-Engine, and surfaces in dashboards. This is the spine.

Step 3 — Node classification:
  ESSENTIAL (in the message): Cameras, Jetson AI, KI-Analyse-Engine, Dashboard
  SUPPORTING (adds context): Kafka, PostgreSQL+Redis, Alerting
  DETAIL (infrastructure): MQTT Broker, API Gateway, Business Logic, Stream Cache, Grafana

  Reasoning: The audience cares about the data path (cameras→AI→dashboard), not
  about middleware (MQTT, API Gateway) or where Grafana runs. Alerting is kept
  because the narrative mentions alerts as a key output.

Step 4 — Zone grouping:
  Lane 1 "Edge": Cameras + Jetson (data enters here)
  Lane 2 "Cloud": Kafka + Engine + DB (processing happens here)
  Lane 3 "Operations": Dashboard + Alerting (value exits here)

  5 original layers → 3 zones following the input→processing→output pattern.
  "Integrationsschicht" absorbed into Cloud (Kafka is processing infrastructure).
  "Datenschicht" absorbed into Cloud (DB serves the engine).

Step 5 — Apply mechanical rules: See simplified output below.

Step 6 — Verification: The simplified diagram shows cameras flowing through
  cloud processing to dashboards — exactly the slide message. ✓
```

Simplified (3 lanes, 6 nodes, 6 edges):
```
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
```

Simplification summary:
- 5 layers → 3 lanes: Edge (cameras+jetson), Cloud (kafka+engine+db), Operations (dashboard+alerts)
- MQTT + Kafka → "Kafka Streaming" (MQTT absorbed as detail)
- PostgreSQL + Redis → combined "PostgreSQL + Redis"
- API Gateway + Business Logic → absorbed into edges (API implicit, logic behind engine)
- Grafana merged into Dashboard box
- TB direction → LR

---

### Linear Flowcharts (linear-graph)

**Constraints:**
- Max **6 nodes** in the chain
- **Always LR direction** — transpose TD linear chains to LR

```text
SIMPLIFY linear flowchart:

  1. COUNT nodes
     → ≤6? → No simplification needed (transpose to LR if TD)
     → >6? → Reason through compression:

  2. IDENTIFY the slide message (Reasoning Step 1):
     → What process does this flowchart illustrate?
     → Which steps are ESSENTIAL to understanding the message?

  3. COMPRESS to ≤6 nodes:
     → Keep the first node (entry point), last node (outcome), and key decision/transformation points
     → Merge consecutive similar steps into one labeled node
     → Use "..." or count labels for absorbed steps: "3 Validation Steps"
     → Detail in speaker notes

  4. TRANSPOSE if TD:
     → Rewrite as LR
```

---

### Gantt Charts (gantt)

**Constraints:**
- Max **8 tasks** (rows)
- Max **4 phases** (sections)

```text
SIMPLIFY gantt chart:

  1. COUNT tasks and sections
     → ≤8 tasks AND ≤4 sections? → No simplification needed
     → Otherwise:

  2. IDENTIFY the slide message:
     → Is this about timeline (when things happen)?
     → Is this about parallelism (what happens simultaneously)?
     → Is this about duration (how long phases take)?

  3. GROUP tasks by section → one bar per section (phase-level)
     → Phase start = earliest task start
     → Phase end = latest task end
     → Phase status = done (all done) | active (any active) | future (all future)
     → Individual tasks → speaker notes

  4. LIMIT sections to 4:
     → Merge related phases if >4
     → Keep phases that align with the slide message
```

---

### Hub-and-Spoke (hub-graph)

**Constraints:**
- Max **3 inputs**, **1 hub**, **3 outputs**

```text
SIMPLIFY hub-and-spoke:

  1. IDENTIFY hub node (most edges)
  2. IDENTIFY the slide message:
     → Is the message about the hub's central role?
     → Or about the diversity of inputs/outputs?
  3. PARTITION other nodes: inputs (edges TO hub) | outputs (edges FROM hub)
  4. LIMIT: max 3 inputs, max 3 outputs
     → Collapse similar inputs/outputs if >3
     → Keep the nodes most relevant to the slide message
  5. REWRITE as 3-lane layered architecture:
     subgraph Inputs: [input nodes]
     subgraph Core: [hub node]
     subgraph Outputs: [output nodes]
```

---

## Speaker Notes Preservation

When simplification removes detail, the original information MUST be preserved in speaker notes material for Step 8c to consume.

```text
GENERATE speaker notes material from simplification:

  For architecture simplification:
    → "Vollständige Architektur: {N} Schichten, {M} Komponenten (siehe {filename})"
    → List each original layer with its components
    → Note collapsed components: "Edge: NVIDIA Jetson Orin NX + IP67-Industriekameras (RTSP)"
    → Note removed edges: "Monitoring: Grafana Enterprise für Echtzeit-Dashboards"
    → Note data privacy/compliance implications if relevant

  For gantt simplification:
    → "Detaillierter Projektplan: {N} Aufgaben in {M} Phasen (siehe {filename})"
    → List individual tasks per phase with original durations
    → Note dependencies between tasks

  For flowchart simplification:
    → "Vollständiger Prozess: {N} Schritte (siehe {filename})"
    → List removed branches and their conditions
    → Note error handling paths

  Language: Match the presentation language (de/en)
```

---

## Integration with Other Steps

- **Step 2g** (this): Detect + classify + simplify → store diagram data
- **Step 3** (Story Arc): Diagram slides get role assignment like any other slide (typically `solution` or `roadmap`)
- **Step 4** (Message Architecture): The diagram slide's message is the simplified diagram's headline — NOT "here's the architecture" but "Edge-to-Cloud in 3 Schichten" (specific, assertive)
- **Step 5a** (Copywriting): Diagram slide titles follow the same headline rules (assertion, not label)
- **Step 8c** (Speaker Notes): Consume preserved detail from simplification for `>> WAS SIE WISSEN MÜSSEN`
- **Step 6** (Layout Selection): Use diagram type + topology to select layout (see 06-slide-mapping-rules.md)
- **Step 7** (Validation): Validate Diagram field constraints (see 09-validation-checklist.md)
