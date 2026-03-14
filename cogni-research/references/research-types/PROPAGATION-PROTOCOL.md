# Research-Types Propagation Protocol

## Overview

When master WHAT definitions change, dependent skill HOW files must be updated. This protocol defines the Claude-assisted propagation workflow.

---

## When to Propagate

### Trigger Events

1. **Dimension change** — Adding, removing, or renaming a dimension
2. **Structure change** — Modifying MECE organization or relationships
3. **Framework reference change** — Updating how frameworks compose (e.g., smarter-service → TIPS)
4. **Terminology change** — Renaming concepts or updating definitions

### Non-Trigger Events (No Propagation Needed)

- Typo fixes in WHAT files
- Version history updates
- Cross-reference link fixes
- Comment/documentation clarifications

---

## Propagation Checklist by Research Type

### tips-framework.md Changes

**Affected Skills:**

- [ ] `trends-creator` — phase-4-synthesis-tips.md
- [ ] `synthesis-hub` — phase-4a-synthesis-hub-cross.md (generic) + cogni-narrative:narrative-writer (arc-specific)
- [ ] `executive-synthesizer` — framework-support.md, phase-2.5-template-loading.md

**Propagation Steps:**

1. Read updated `tips-framework.md`
2. For each affected skill, update phase files that reference TIPS structure
3. Verify word counts, citation requirements align with new TIPS definition
4. Update version markers in skill phase files

### smarter-service.md Changes

**Affected Skills:**

- [ ] `dimension-planner` — Phase 2/3 planning files
- [ ] `synthesis-hub` — phase-4a-synthesis-hub-cross.md (generic) + cogni-narrative:narrative-writer (arc-specific)
- [ ] `executive-synthesizer` — framework-support.md, phase-2.5-template-loading.md

**Propagation Steps:**

1. Read updated `smarter-service.md`
2. For each affected skill, update:
   - Dimension names and slugs
   - Action horizon definitions
   - MECE validation references
3. Update version markers in skill phase files

### lean-canvas.md Changes

**Affected Skills:**

- [ ] `dimension-planner` — Phase 2/3 planning files
- [ ] `synthesis-hub` — phase-4a-synthesis-hub-cross.md (generic) + cogni-narrative:narrative-writer (arc-specific)
- [ ] `executive-synthesizer` — framework-support.md

**Propagation Steps:**

1. Read updated `lean-canvas.md`
2. Update dimension-planner phase files for lean-canvas research type
3. Update version markers in skill phase files

---

## Version Marker Format

Each skill phase file that references a master WHAT should include:

```yaml
---
source_what: research-types/smarter-service.md
source_version: v3.0
last_propagated: 2024-12-04
propagated_by: Sprint 438
---
```

**Fields:**

- `source_what` — Path to master WHAT file
- `source_version` — Version of WHAT file when HOW was generated
- `last_propagated` — Date of last propagation
- `propagated_by` — Sprint or commit that performed propagation

---

## Claude-Assisted Propagation Workflow

### Step 1: Identify Changes

```markdown
Compare old vs new WHAT file:
- What definitions changed?
- What structures changed?
- What references changed?
```

### Step 2: Map Impact

```markdown
For each change, identify:
- Which skills are affected?
- Which phase files need updates?
- What specific content needs to change?
```

### Step 3: Generate Updates

```markdown
For each affected phase file:
1. Read current content
2. Apply WHAT changes to HOW content
3. Preserve skill-specific operational guidance
4. Update version markers
```

### Step 4: Validate

```markdown
For each updated phase file:
- [ ] Version markers updated
- [ ] WHAT content correctly reflected
- [ ] HOW guidance preserved
- [ ] No orphaned references
```

---

## Propagation Prompt Template

Use this prompt when requesting Claude-assisted propagation:

```markdown
## Propagation Request

**Changed WHAT file:** research-types/{file}.md
**Change type:** {dimension|structure|reference|terminology}
**Change summary:** {brief description}

**Task:**
1. Read the updated WHAT file
2. Identify all skill phase files that reference this WHAT
3. Update each affected phase file to reflect the changes
4. Add/update version markers
5. List all files modified

**Constraints:**
- Preserve all HOW content (operational guidance)
- Only update WHAT-derived content
- Maintain backward compatibility where possible
```

---

## Drift Detection

To detect when skill HOW files have drifted from master WHAT:

### Manual Check

```bash
# List all phase files with version markers
grep -r "source_what:" skills/*/references/phase-workflows/

# Compare versions
# If source_version in phase file != current version in WHAT file, drift detected
```

### Automated Check (Future)

```bash
# Proposed: scripts/check-what-how-drift.sh
# Compares version markers across all skills
# Reports mismatches for propagation
```

---

## Version History

- **v1.0 (Sprint 438):** Initial propagation protocol document
