# Research Type Pipeline Routing

Single source of truth for how `research_type` affects pipeline behavior across all deeper-research skills. Consult this file when implementing conditional logic based on research type.

For WHAT definitions (dimensions, frameworks), see [research-types/README.md](research-types/README.md).

---

## DOK Auto-Determination

| Research Type | DOK Level | Rationale |
|---------------|-----------|-----------|
| `smarter-service` | **4** (auto) | 52 TIPS = extended complexity |
| `b2b-ict-portfolio` | **3** (auto) | 8-dimension portfolio analysis (0-7) |
| `lean-canvas` | **2** (auto) | 9 canvas blocks |
| `customer-value-mapping` | **3** (auto) | Value mapping synthesis |
| `generic` | **ASK USER** | Only type where DOK is variable |

---

## Conditional Phases

| Phase | Condition | Applicable Types | Action for Others |
|-------|-----------|------------------|-------------------|
| **Phase 1** (deeper-research-0) | DOK selection | `generic` only | Auto-set DOK from table above |
| **Phase 1** (deeper-research-0) | Research-type clarifications | `smarter-service`: ask about portfolio linking; `customer-value-mapping`: validate customer; `lean-canvas`: gather business context | Skip for `generic` and `b2b-ict-portfolio` |
| **Phase 2b** (deeper-research-0) | Megatrend seed validation | `generic`, `smarter-service` | Skip for `b2b-ict-portfolio`, `lean-canvas`, `customer-value-mapping` |
| **Phase 0.5** (deeper-research-3) | Arc detection | All types | Map to arc_id (see below) |
| **Phase 8** (deeper-research-3) | Portfolio integration | `smarter-service`, `customer-value-mapping` | Skip portfolio validation |

---

## Arc Detection Mapping (Phase 0.5)

| research_type | Detected arc_id | Framework Elements |
|---------------|-----------------|-------------------|
| `technology` | `technology-futures` | What's Emerging → Converging → Possible → Required |
| `competitive` | `competitive-intelligence` | Landscape → Shifts → Positioning → Implications |
| `foresight`, `scenarios` | `strategic-foresight` | Signals → Scenarios → Strategies → Decisions |
| `industry`, `transformation` | `industry-transformation` | Forces → Friction → Evolution → Leadership |
| `market`, `generic`, (default) | `corporate-visions` | Why Change → Why Now → Why You → Why Pay |

---

## Findings-Creator Selection

| Research Type | Primary Source | Agent |
|---------------|---------------|-------|
| `generic` | Web search | `findings-creator` |
| `smarter-service` | Web + file-based RAG | `findings-creator` + `findings-creator-file` |
| `b2b-ict-portfolio` | Web search | `findings-creator` |
| `lean-canvas` | Web search | `findings-creator` |
| `customer-value-mapping` | Web + existing research | `findings-creator` |
| All types | LLM knowledge (supplementary) | `findings-creator-llm` |

---

## Dimension Planning Mode

| Research Type | Dimension Source | Count |
|---------------|-----------------|-------|
| `generic` | Generated dynamically from question + DOK | 2-10 |
| `smarter-service` | Pre-defined (4 compass dimensions) | 4 |
| `b2b-ict-portfolio` | Pre-defined (8 portfolio dimensions) | 8 |
| `lean-canvas` | Pre-defined (9 canvas blocks) | 9 |
| `customer-value-mapping` | Pre-defined (4 value story stages) | 4 |

---

## Synthesis Routing

| Research Type | Trend Format | Synthesis Template |
|---------------|-------------|-------------------|
| `smarter-service` | TIPS (T→I→P→S) | Trendbook-style with action horizons |
| `b2b-ict-portfolio` | Portfolio entity (9 attributes) | Portfolio catalog + strategic analysis |
| `customer-value-mapping` | Customer need mapping | Value story with COT chain |
| `lean-canvas` | Generic | Canvas-block synthesis |
| `generic` | Generic | Executive report |
