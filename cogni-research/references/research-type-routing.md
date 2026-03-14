# Research Type Pipeline Routing

Single source of truth for how `research_type` affects pipeline behavior across all stages. Consult this file when implementing conditional logic based on research type.

For WHAT definitions (dimensions, frameworks), see [research-types/](research-types/).

---

## DOK Auto-Determination

| Research Type | DOK Level | Rationale |
|---------------|-----------|-----------|
| `b2b-ict-portfolio` | **3** (auto) | 8-dimension portfolio analysis (0-7) |
| `lean-canvas` | **2** (auto) | 9 canvas blocks |
| `generic` | **ASK USER** | Only type where DOK is variable |

---

## Dimension Planning Mode

| Research Type | Dimension Source | Count |
|---------------|-----------------|-------|
| `generic` | Generated dynamically from question + DOK | 2-10 |
| `b2b-ict-portfolio` | Pre-defined (8 portfolio dimensions) | 8 |
| `lean-canvas` | Pre-defined (9 canvas blocks) | 9 |

---

## Question Strategy

| Research Type | Question Source | Count |
|---------------|----------------|-------|
| `generic` | Generated from DOK level + dimension analysis | 8-50 (DOK-based) |
| `b2b-ict-portfolio` | Category question templates (57 categories) | 57 |
| `lean-canvas` | Block-specific questions (9 blocks) | 27-36 (3-4 per block) |

---

## Findings-Creator Selection

| Research Type | Primary Source | Agent |
|---------------|---------------|-------|
| `generic` | Web search | `findings-creator` |
| `b2b-ict-portfolio` | Web search | `findings-creator` |
| `lean-canvas` | Web search | `findings-creator` |
| All types | LLM knowledge (supplementary) | `findings-creator-llm` |
| All types | File-based RAG (if PDF store available) | `findings-creator-file` |

---

## Synthesis Arc Mapping

| Research Type | Detected arc_id | Framework Elements |
|---------------|-----------------|-------------------|
| `technology` | `technology-futures` | What's Emerging > Converging > Possible > Required |
| `competitive` | `competitive-intelligence` | Landscape > Shifts > Positioning > Implications |
| `foresight`, `scenarios` | `strategic-foresight` | Signals > Scenarios > Strategies > Decisions |
| `industry`, `transformation` | `industry-transformation` | Forces > Friction > Evolution > Leadership |
| `market`, `generic`, (default) | `corporate-visions` | Why Change > Why Now > Why You > Why Pay |

---

## Synthesis Routing

| Research Type | Synthesis Template |
|---------------|-------------------|
| `b2b-ict-portfolio` | Portfolio catalog + strategic analysis |
| `lean-canvas` | Canvas-block synthesis |
| `generic` | Executive report |

---

## Conditional Phases

| Phase | Condition | Applicable Types | Action for Others |
|-------|-----------|------------------|-------------------|
| **research-plan** | DOK selection | `generic` only | Auto-set DOK from table above |
| **research-plan** | Research-type clarifications | `lean-canvas`: gather business context | Skip for `generic` and `b2b-ict-portfolio` |
| **synthesis** | Arc detection | All types | Map to arc_id (see table above) |
