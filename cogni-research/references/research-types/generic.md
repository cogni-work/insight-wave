# Generic Research Type Definition

## Purpose

Flexible, domain-based research type for questions that don't fit established frameworks. Uses Webb's Depth of Knowledge (DOK) for dynamic dimension and question generation.

---

## Structure Definition

| Attribute | Value |
|-----------|-------|
| Framework | None (domain-based) |
| Dimensions | 2-10 (DOK-adaptive) |
| Questions | 8-50 (DOK-based) |
| Template | None (dynamically generated) |

---

## DOK-Based Scaling

| DOK Level | Description | Dimensions | Questions |
|-----------|-------------|------------|-----------|
| DOK-1 (Recall) | Facts, definitions, statistics | 2-3 | 8-12 |
| DOK-2 (Skills) | Compare, classify, apply frameworks | 3-4 | 15-20 |
| DOK-3 (Strategic) | Synthesize, analyze patterns | 5-7 | 25-35 |
| DOK-4 (Extended) | Complex synthesis, interdisciplinary | 8-10 | 40-50 |

---

## User Input Requirements

### Mandatory (Phase 1)
- DOK Level: User must select 1-4 (no auto-determination)

### Optional
- None (all other inputs derived from question analysis)

---

## Usage Context

Generic is the **default research type** when:
- `research_type` field is omitted from sprint-log.json
- `research_type: generic` is explicitly set
- Question doesn't align with specialized frameworks

**Dimension Generation:** Based on DOK level and question domain, using domain templates:
- Business Domain
- Academic Domain
- Product Domain

**Reference:** [phase-2-analysis-generic.md](../../skills/dimension-planner/references/workflow-phases/phase-2-analysis-generic.md)

---

## Megatrend Entity Structure

Generic research uses a domain-based 3-part megatrend structure instead of TIPS megatrend narrative:

| Section | Purpose | Word Target |
|---------|---------|-------------|
| **What it is** | Primer on the subject - definition, concepts, scope | 150-200 words |
| **What it does** | Use cases relevant to research stakeholders | 100-150 words |
| **What it means** | Implications (qualitative narrative + quantitative metrics table) | 150-200 words |
| **Total** | | **400-600 words** |

**Key Differences from TIPS (smarter-service):**

| Aspect | Generic | TIPS (smarter-service) |
|--------|---------|------------------------|
| Structure | What it is / does / means | Trend / Implication / Possibility / Solution |
| Seed megatrends | Not used | Yes (user-validated seeds) |
| Planning horizon | Not applicable | act / plan / observe |
| Word count | 400-600 | 600-900 |
| `megatrend_structure` | `"generic"` | `"tips"` |

**Template Reference:** [entity-templates.md](../../skills/knowledge-extractor/references/domain/entity-templates.md#generic-megatrend-entity-template)

**Workflow Reference:** [phase-5-megatrend-clustering.md](../../skills/knowledge-extractor/references/workflows/phase-5-megatrend-clustering.md#step-32a-generate-generic-megatrend-content-if-megatrend_structuregeneric)

---

## Version History

- **v1.1 (Sprint 443):** Added Megatrend Entity Structure section with 3-part domain-based template (What it is/does/means)
- **v1.0 (Sprint 441):** Initial WHAT file creation to align with workflow constraints
