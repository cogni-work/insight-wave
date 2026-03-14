---
name: synthesis-hub
description: "[Internal] Generate cross-dimensional research reports from pre-synthesized dimensions. Invoked by deeper-research-3."
---

# Synthesis Hub

---

## ⛔ INVOCATION GUARD

**This is an EXECUTOR skill. Do NOT invoke directly.**

**Correct path:** `User → deeper-research-3 skill → Phase 10: Task tool → synthesis-hub AGENT → this skill`

**If reading this directly:** Use `Skill(skill="cogni-research:deeper-research-3")` instead.

**Exception:** If you are the `synthesis-hub` agent (invoked via Task tool from deeper-research-3 Phase 10), proceed to Phase 1.

---

## Hub-and-Spoke Architecture

This skill is the **HUB** in a hub-and-spoke progressive disclosure pattern:

```text
┌─────────────────────────────────────────────────────┐
│  HUB (this skill: synthesis-hub)                │
│  Loads: dimension syntheses + initial question ONLY │
│  Creates: Cross-dimensional synthesis               │
│  Output: research-hub.md + 5 supporting files       │
└─────────────────────────────────────────────────────┘
                         ↑
                    consumes
                         ↑
┌─────────────────────────────────────────────────────┐
│  SPOKES (synthesis-dimension)               │
│  Loads: trends + claims + concepts FOR dimension  │
│  Creates: Dimension-level synthesis                 │
│  Output: 12-synthesis/synthesis-{dim}.md            │
│          (800-1,200 words per dimension)            │
└─────────────────────────────────────────────────────┘
```

**Key Principle:** Hub adds unique value through cross-dimensional patterns. Spokes provide dimension-specific depth.

---

## ⛔ SPOKE REQUIREMENT

**Dimension synthesis documents MUST exist before running this skill.**

If `12-synthesis/synthesis-*.md` files don't exist, Phase 3 fails with error directing user to run synthesis-dimension first.

**Required prerequisite:**

```bash
# For each dimension, run:
synthesis-dimension --project-path {path} --dimension {dim-slug}
```

---

## Purpose

Generate cross-dimensional research report (hub) that synthesizes pre-existing dimension syntheses (spokes) into a cohesive narrative with:

- Executive Summary answering the research question
- Dimension Overview with navigation to spoke documents
- Cross-Dimensional Patterns (hub unique value)
- Strategic Recommendations (cross-dimensional)

**What hub does NOT do:**

- Load raw entities (trends, claims, concepts) - spokes already did this
- Repeat detailed trend analysis - that's in spokes
- Duplicate thematic analysis - spokes have cross-trend connections

---

## Output Language

⚠️ **CRITICAL:** Generate ALL report content in the project language (`project_language` from sprint-log.json).

### German (de) - MANDATORY REQUIREMENTS

| Element | Requirement | Example |
|---------|-------------|---------|
| Body text | **MUST** use proper umlauts | "für" NOT "fuer" |
| Section headings | **MUST** use proper umlauts | "Übersicht" NOT "Uebersicht" |
| Explanations | **MUST** use proper umlauts | "Änderungen" NOT "Aenderungen" |
| File names/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |

**⛔ NEVER write German body text with ASCII fallbacks like:**

- `grundsaetzlich` → write `grundsätzlich`
- `uebergreifend` → write `übergreifend`
- `Aenderung` → write `Änderung`
- `fuer` → write `für`

**Reference:** See `references/language-templates.md` for complete formatting rules.

---

## When to Use

- After synthesis-dimension has run for all dimensions
- To create final cross-dimensional research report
- When integrating dimension syntheses into unified hub narrative

**Not for:**

- Dimension-scoped synthesis (use synthesis-dimension)
- Intermediate trends (use trends-creator)
- Projects without dimension syntheses (run spokes first)

---

## Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite with all phases:

1. Phase 1: Setup & Environment [in_progress]
2. Phase 2: Research Type Detection [pending]
3. Phase 3: Load Dimension Syntheses [pending]
4. Phase 4: Cross-Dimensional Synthesis [pending]
5. Phase 5: Validation & Output [pending]

Each phase adds step-level todos when started.

---

## Core Workflow

```text
Setup → Detection → Load Syntheses → Cross-Dimensional Synthesis → Validation
```

**MANDATORY:** Read each phase reference file BEFORE executing that phase.

| Phase | Objective | Reference |
|-------|-----------|-----------|
| 1 | Validate parameters, initialize logging | [phase-1-setup.md](references/phase-workflows/phase-1-setup.md) |
| 2 | Detect research type, select template | [phase-2-detection.md](references/phase-workflows/phase-2-detection.md) |
| 3 | Load dimension syntheses (REQUIRED) | [phase-3-loading.md](references/phase-workflows/phase-3-loading.md) |
| 4 | Generate cross-dimensional report | See type-specific routing below |
| 5 | Validate citations, return summary | [phase-5-validation.md](references/phase-workflows/phase-5-validation.md) |

---

### Phase 1: Setup & Environment

**Read:** [phase-1-setup.md](references/phase-workflows/phase-1-setup.md)

Validate `--project-path`, verify project structure.

**Outputs:** Logging initialized, project validated

---

### Phase 2: Research Type Detection

**Gate Check:** Phase 1 complete

**Read:** [phase-2-detection.md](references/phase-workflows/phase-2-detection.md)

Extract `research_type` from sprint-log.json, select report template.

**Outputs:** Research type detected, template selected

---

### Phase 3: Load Dimension Syntheses [BLOCKING]

**Gate Check:** Phase 2 complete

**Read:** [phase-3-loading.md](references/phase-workflows/phase-3-loading.md)

**CRITICAL:** This phase requires dimension synthesis documents to exist.

**Load Order:**

1. `00-initial-question/` - Research question
2. `12-synthesis/synthesis-*.md` - Dimension syntheses (REQUIRED)
3. `06-megatrends/data/*.md` - **FULL megatrend content** (NEW in v2.1)

**What we DON'T load (spokes already synthesized these):**

- Full trend content (11-trends/data/) - spokes already analyzed these
- Refined questions (02-refined-questions/)
- Domain concepts (05-domain-concepts/)
- Claims (10-claims/)
- Findings (04-findings/)

**What we DO load (metadata only for kanban table navigation):**

- Trend YAML frontmatter: `dc:identifier`, `dc:title`, `dimension`, `planning_horizon`

**What we DO load (FULL CONTENT for megatrend narrative synthesis):**

- **Megatrend entities:** YAML frontmatter + Trend/Implication/Possibility/Solution sections
- **Rationale:** Hub generates 300-500 word cross-dimensional megatrend narrative. No single spoke synthesizes ALL megatrends, so hub must read content to synthesize meaningfully.

⚠️ **CRITICAL:** Trends and megatrends MUST appear as wikilinks in the kanban table, not plain text.

**Blocking Verification:** Build DIMENSION_REGISTRY and MEGATREND_REGISTRY from loaded content.

**Outputs:** Initial question + dimension syntheses + megatrends loaded, registries built

---

### Phase 4: Cross-Dimensional Synthesis

**Gate Check:** Phase 3 complete (syntheses and arc entities loaded)

**⛔ STOP:** Read the workflow BEFORE writing ANY content.

### Phase 4 Execution

**Objective:** Execute phase-4a to generate the hub ecosystem (cross-dimensional synthesis).

**Implementation:**

```bash
# Phase 4a: Hub Ecosystem (ALWAYS EXECUTE)
echo "=== Phase 4a: Hub Ecosystem Generation ==="
hub_workflow="references/phase-workflows/phase-4a-synthesis-hub-cross.md"

# Load and execute phase-4a workflow
echo "Loading hub ecosystem workflow..."
# USE: Read tool with file_path: ${hub_workflow}
# EXECUTE: All steps in phase-4a workflow
```

**Workflow:**

| Workflow File | Purpose |
|--------------|---------|
| `phase-4a-synthesis-hub-cross.md` | Hub ecosystem with cross-dimensional synthesis |

**Note:** Arc-specific narratives (insight-summary.md) are generated by deeper-research-3 Phase 10.5, not by synthesis-hub. This avoids 3-level agent nesting and keeps narrative delegation at the orchestrator level.

**Type-Specific Targets:**

| Metric | Hub Target |
|--------|------------|
| Word count | 1,900-2,850 |
| Citations | 15-25 |
| Unique value | Cross-dimensional patterns |

**Citation Format:** `Claim text<sup>[N](12-synthesis/synthesis-{dim}.md)</sup>` (to syntheses, not raw entities)

**Output:** `${PROJECT_PATH}/research-hub.md` + 5 supporting files (including generic `synthesis-cross-dimensional.md`)

---

### Phase 5: Validation & Output

**Gate Check:** Phase 4 complete (research-hub.md exists)

**Read:** [phase-5-validation.md](references/phase-workflows/phase-5-validation.md)

Verify all cited synthesis files exist.

**Success Response:**

```json
{
  "success": true,
  "hub_path": "/path/to/research-hub.md",
  "dimensions_synthesized": 4,
  "total_trends": 18,
  "citations_created": 22,
  "arc_id": "corporate-visions"
}
```

**Concise Summary (5 lines max):**

```text
✅ Hub synthesis complete.
- Hub: research-hub.md ({research_type})
- Dimensions synthesized: {count}
- Cross-dimensional citations: {count}
- Spokes: 12-synthesis/synthesis-*.md
```

---

## Input Requirements

**Required:**

- Research project path
- `.metadata/sprint-log.json` with `research_type`
- `00-initial-question/data/` - Research question
- `12-synthesis/synthesis-*.md` - At least 1 dimension synthesis (from synthesis-dimension)

**Not Required (spokes handle these):**

- 11-trends/data/ (spokes load these)
- 02-refined-questions/data/ (spokes load this)
- 05-domain-concepts/data/ (spokes load this)

---

## Output Format

**Primary Output:** `research-hub.md` in project root

**Structure (Pyramid Principle):**

The report follows McKinsey's Pyramid Principle with Answer First architecture:

```markdown
---
title: "{Research Question}"
research_type: "generic"
tags: [answer, synthesis-level/executive]
synthesis_framework: "Hub-and-Spoke Progressive Disclosure"
date_created: "{ISO 8601}"
dimension_count: {N}
total_trends: {N}
confidence_level: "{level}"
---

# {Title}

## PYRAMID LEVEL 1: Answer + Action (Executive Priority)
## Executive Summary
{200-300 words - direct answer to research question}

## Strategic Recommendations
{300-400 words - actionable cross-dimensional guidance}

## PYRAMID LEVEL 2: Context (Establish Credibility)
## Research Scope & Methodology
{150-200 words - evidence scale, methodology, scope boundaries}

## Research Question
{50-100 words - formal research question with dimensions}

## PYRAMID LEVEL 3: Evidence (Hierarchical Synthesis)
## Megatrends: Cross-Dimensional Forces
{400-600 words - strategic megatrend synthesis with evidence}

## Cross-Dimensional Patterns
{300-400 words - thematic patterns across dimensions}

## Trend Landscape
{150-250 words - dimension overview table + dimension briefs}

## PYRAMID LEVEL 4: Technical (Appendix)
## Appendix: Research Scope
{Report Generation metadata + Pipeline Metrics + Methodology link}
```

---

## Progressive Disclosure Flow

```text
Reader opens research-hub.md (hub)
         ↓
LEVEL 1: Reads Executive Summary + Strategic Recommendations (600 words)
         ↓ [Got answer? STOP]
         ↓
LEVEL 2: Scans Research Scope & Methodology, reads Research Question (250 words)
         ↓ [Need evidence? CONTINUE]
         ↓
LEVEL 3: Reads Megatrends narrative (500 words)
         ↓
       Reads Cross-Dimensional Patterns (350 words)
         ↓
       Scans Trend Landscape table, reads dimension briefs (200 words)
         ↓ [Need detail? DRILL DOWN]
         ↓
Clicks dimension wikilink → Opens spoke document (800-1,200 words)
         ↓
Clicks trend wikilink → Opens trend entity (400-600 words)
         ↓
LEVEL 4: Reviews Appendix for technical metrics
```

**Pyramid Principle Benefits:**

- **Answer First:** Executives get actionable insights in first 600 words
- **Credibility Early:** Research Scope section establishes evidence scale upfront
- **Evidence Flows Down:** Megatrends → Patterns → Landscape (general to specific)
- **Technical Last:** Pipeline metrics deferred to appendix (don't interrupt narrative)

Each level adds depth without repeating previous levels.

---

## Constraints

- DO NOT load raw entities (spokes already synthesized)
- DO NOT repeat detailed trends (those are in spokes)
- ALWAYS require dimension syntheses to exist
- ALWAYS cite dimension syntheses (not raw entities)
- ALWAYS focus on cross-dimensional patterns (hub unique value)

---

## Error Handling

| Phase | Failure | Action |
|-------|---------|--------|
| 1 | Setup validation | HALT with error JSON |
| 2 | Type detection | HALT with error JSON |
| 3 | No syntheses found | HALT with spoke requirement error |
| 4 | Synthesis | HALT with error JSON |
| 5 | Invalid citations | HALT with fabricated entity report |

---

## Token Budget (Optimized)

Estimated: ~15,000-18,000 tokens (7.5-9% of 200K budget)

| Phase | Est. Tokens | Old Est. | v2.1 Notes |
|-------|-------------|----------|------------|
| 1 | 2,000 | 2,000 | Project setup |
| 2 | 1,500 | 1,500 | Research type detection |
| 3 | 7,000-10,000 | 15,000 | Syntheses (4K) + Megatrends (3-6K) |
| 4 | 3,500 | 14,000 | Cross-dimensional synthesis |
| 5 | 1,000 | 2,500 | Validation |

**Key changes in v2.1:**
- Added megatrend content loading (+3K-6K tokens) for substantive narrative
- Still 60-65% reduction from loading syntheses instead of raw entities
- Quality gain: Evidence-grounded megatrend synthesis vs. title listing

---

## Related Skills

- **synthesis-dimension** - Creates spoke documents (PREREQUISITE)
- **trends-creator** - Creates trend entities


---

## Version History

- v1.0.0 - Initial release with 5-phase progressive disclosure
- v1.1.0 - Streamlined SKILL.md, implementation details moved to workflow references
- v2.0.0 - Hub-and-spoke architecture: requires dimension syntheses, focuses on cross-dimensional patterns
