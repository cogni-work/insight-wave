# Research-Type Development Kit

## Overview

This kit provides templates, checklists, and guidance for adding new research types to the deeper-research pipeline. Following this kit ensures consistent WHAT/HOW separation across all research types.

---

## Core Architecture Principles

### WHAT vs HOW Separation

| Layer | Location | Content | Updates |
|-------|----------|---------|---------|
| **WHAT** (Master) | `research-types/{type}.md` | Pure definitions | Single source of truth |
| **HOW** (Skills) | `skills/{skill}/references/phase-workflows/` | Operational guidance | Derived from WHAT |

### Design-Time Compilation

Skills embed WHAT content at **design time** (when prompts are authored), not at **runtime** (when skills execute).

```text
WHAT File (Master)          →    HOW File (Skill)
research-types/my-type.md   →    phase-4a-synthesis-hub-cross.md (generic)
                                  (arc-specific: delegated to cogni-narrative:narrative-writer)
                                  (with version markers)
```

---

## Step 1: Create Master WHAT File

### Template: `research-types/{type}.md`

```markdown
# {Research Type Name} Definition

## Purpose

{1-2 sentences describing what this research type is for}

**Framework Source:** {Original source if applicable, or "Custom"}

---

## Dimension Definitions

The framework uses exactly {N} dimensions:

### 1. {Dimension Name}

**Layer/Role:** {Position in framework}

**Core Question:** *"{Primary question this dimension answers}"*

**Focus:** {What this dimension analyzes}

**MECE Role:** {How it complements other dimensions}

---

### 2. {Dimension Name}

{Same structure...}

---

## MECE Validation

**Mutually Exclusive:**

- {How dimensions don't overlap}

**Collectively Exhaustive:**

- {How dimensions cover all aspects}

---

## {Type-Specific Structures}

{Add any unique structural elements - e.g., action horizons, canvas blocks, maturity phases}

---

## Cross-References

{References to other research-types files if applicable}

**Reference:** [tips-framework.md](tips-framework.md) — if using TIPS structure

---

## Version History

- **v1.0 (Sprint {N}):** Initial research type definition
```

### Naming Convention

- File: `{type-slug}.md` (lowercase, hyphens)
- Examples: `smarter-service.md`, `lean-canvas.md`, `tips-framework.md`

---

## Step 2: Update README Index

Add entry to `research-types/README.md`:

```markdown
| {type-slug} | {Brief description} | {N} dimensions | {framework reference if any} |
```

---

## Step 3: Create Skill HOW Files

For each skill that needs to consume the new research type:

### 3.1 dimension-planner

Create: `skills/dimension-planner/references/phase-workflows/phase-2-analysis-{type}.md`
Create: `skills/dimension-planner/references/phase-workflows/phase-3-planning-{type}.md`

### 3.2 trends-creator

Create: `skills/trends-creator/references/phase-workflows/phase-4-synthesis-{type}.md`

### 3.3 synthesis-hub

**Note:** synthesis-hub uses `phase-4a-synthesis-hub-cross.md` for generic synthesis. Arc-specific narratives are delegated to `cogni-narrative:narrative-writer` via Task tool. No type-specific files needed.

Optional: `skills/synthesis-hub/references/templates/{type}-report.md` (if custom report structure required)

### 3.4 executive-synthesizer

Update: `skills/executive-synthesizer/references/framework-support.md`
Update: `skills/executive-synthesizer/references/phase-workflows/phase-2.5-template-loading.md`

---

## Step 4: Add Version Markers

Every skill HOW file must include version markers:

```yaml
---
source_what: research-types/{type}.md
source_version: v1.0
last_propagated: {ISO-date}
propagated_by: Sprint {N}
---
```

And HTML comments:

```html
<!-- COMPILED FROM: research-types/{type}.md -->
<!-- VERSION: {ISO-date} -->
<!-- PROPAGATE: When {type}.md changes, regenerate this file -->
```

---

## Step 5: Update Propagation Protocol

Add checklist to `PROPAGATION-PROTOCOL.md`:

```markdown
### {type}.md Changes

**Affected Skills:**

- [ ] `dimension-planner` — Phase 2/3 planning files
- [ ] `trends-creator` — Phase 4 synthesis files
- [ ] `synthesis-hub` — Phase 4 synthesis files
- [ ] `executive-synthesizer` — Framework support files

**Propagation Steps:**

1. Read updated `{type}.md`
2. For each affected skill, update phase files
3. Update version markers in skill phase files
```

---

## Checklist: Adding New Research Type

### Master WHAT Definition

- [ ] Created `research-types/{type}.md` with all dimensions defined
- [ ] MECE validation section present
- [ ] Cross-references to related frameworks (if any)
- [ ] Version history section added
- [ ] README.md index updated

### Skill HOW Files

- [ ] dimension-planner: Phase 2 analysis file created
- [ ] dimension-planner: Phase 3 planning file created
- [ ] trends-creator: Phase 4 synthesis file created
- [ ] synthesis-hub: Phase 4 synthesis file created
- [ ] synthesis-hub: Report template created
- [ ] executive-synthesizer: Framework support updated
- [ ] executive-synthesizer: Template loading updated

### Version Markers

- [ ] All skill HOW files have YAML frontmatter with `source_what`
- [ ] All skill HOW files have HTML comment markers
- [ ] Propagation protocol checklist added

### Validation

- [ ] detect-research-mode.sh recognizes new type
- [ ] End-to-end test with new research type passes
- [ ] No runtime Read calls to master WHAT files

---

## Claude-Assisted Generation Prompt

Use this prompt when asking Claude to help create skill HOW files:

```markdown
## Generate HOW File for New Research Type

**Research Type:** {type}
**Skill:** {skill-name}
**Phase:** {phase-number}

**Master WHAT File:** research-types/{type}.md

**Task:**

1. Read the master WHAT file to understand dimension structure
2. Generate phase-{N}-{phase-name}-{type}.md for {skill-name}
3. Include all WHAT content embedded (not runtime loaded)
4. Add operational HOW guidance specific to this skill
5. Add version markers (source_what, source_version, last_propagated)

**Constraints:**

- No runtime Read calls to master WHAT files
- All dimension definitions embedded directly
- Skill-specific word counts and citation targets included
- Gate checks and TodoWrite patterns preserved
```

---

## Example: Adding "competitive-analysis" Research Type

### Step 1: Master WHAT

```markdown
# Competitive Analysis Definition

## Purpose

Framework for systematic competitor assessment across market positioning, capabilities, and strategic intent.

---

## Dimension Definitions

### 1. Market Position

**Core Question:** "Where do competitors stand in the market?"
**Focus:** Market share, segments, geographic presence

### 2. Capability Assessment

**Core Question:** "What can competitors do?"
**Focus:** Technology, talent, resources, partnerships

### 3. Strategic Intent

**Core Question:** "Where are competitors headed?"
**Focus:** Stated strategy, investments, M&A activity

### 4. Competitive Response

**Core Question:** "How will competitors react?"
**Focus:** Historical patterns, cultural factors, decision speed

---

## MECE Validation

**Mutually Exclusive:** Position vs. Capability vs. Intent vs. Response
**Collectively Exhaustive:** Covers current state, capabilities, direction, and dynamics
```

### Step 2-5: Follow Checklist

Create skill files, add version markers, update propagation protocol.

---

## Version History

- **v1.0 (Sprint 438):** Initial Development Kit for research-type creation
