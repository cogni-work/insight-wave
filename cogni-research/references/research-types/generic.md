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

---

## Version History

- **v2.0 (v1.0.0):** Rebuilt for cogni-research v1.0.0 — removed megatrend entity structure (no longer part of entity pipeline), simplified to core DOK-based planning
- **v1.1 (Sprint 443):** Added Megatrend Entity Structure section with 3-part domain-based template (What it is/does/means)
- **v1.0 (Sprint 441):** Initial WHAT file creation to align with workflow constraints
