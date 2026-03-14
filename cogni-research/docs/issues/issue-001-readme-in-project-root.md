---
issue_id: "001"
title: "README.md should be generated in project root for better navigation"
status: "open"
priority: "high"
created_at: "2025-11-16"
labels: ["enhancement", "ux", "navigation", "executive-synthesizer"]
affected_phase: "Phase 8.4"
affected_agent: "executive-synthesizer"
---

# Issue #001: README.md in Project Root

## Problem Statement

Currently, the executive-synthesizer agent generates `README.md` in the `12-research-synthesis/` directory. This creates a navigation barrier for users who expect the project entry point at the root level.

**Current Behavior:**
```
project-name/
├── 00-initial-question/
├── ...
├── 12-research-synthesis/
│   └── README.md          # ← Navigation starts here (hidden)
└── (no root README)
```

**Expected Behavior:**
```
project-name/
├── README.md              # ← Project entry point (visible)
├── 00-initial-question/
├── ...
└── 12-research-synthesis/
    └── (other synthesis docs)
```

## User Impact

1. **Discovery Problem:** Users opening project folder in Obsidian/VSCode don't immediately see navigation
2. **Onboarding Friction:** New users must know to look in `12-research-synthesis/` for entry point
3. **Convention Violation:** Standard software projects have README.md at root level

## Proposed Solution

### Option A: Generate README at Root (Recommended)

Modify `executive-synthesizer` agent to write README.md directly to project root:

```python
# In executive-synthesizer prompt
output_path = f"{project_path}/README.md"  # Not /12-research-synthesis/README.md
```

**Pros:**
- Follows standard conventions
- Immediate discoverability
- No post-processing required

**Cons:**
- Potential conflict if user has existing README.md

### Option B: Post-Phase Move

Add Phase 10.1 to move README after synthesis:

```bash
mv "${PROJECT_PATH}/12-research-synthesis/README.md" "${PROJECT_PATH}/README.md"
```

**Pros:**
- Non-invasive to existing workflow
- Can be optional flag

**Cons:**
- Extra processing step
- Breaks wikilinks if not updated

### Option C: Symlink Approach

Create symlink at root pointing to synthesis README:

```bash
ln -s 12-research-synthesis/README.md "${PROJECT_PATH}/README.md"
```

**Pros:**
- No file duplication
- Maintains synthesis directory structure

**Cons:**
- Not portable across systems
- May confuse Git tracking

## Recommended Implementation

**Implement Option A** with fallback handling:

1. Check if root README.md exists
2. If exists, backup as `README.original.md`
3. Write new README.md to root
4. Update all wikilinks in README to use relative paths from root

### Files to Modify

1. **`skills/deeper-synthesis/references/phase-workflows/phase-8-synthesis-pipeline.md`**
   - Update output path specification

2. **`agents/executive-synthesizer/prompt.md`**
   - Change output directory from `12-research-synthesis/` to project root

3. **`skills/deeper-synthesis/SKILL.md`**
   - Update Phase 10 checklist to verify root README exists

### Wikilink Path Updates

Since README moves from `12-research-synthesis/` to root, relative paths change:

**Before (from 12-research-synthesis/):**
```markdown
[[../10-claims/data/claim-xyz]]
```

**After (from root/):**
```markdown
[[10-claims/data/claim-xyz]]
```

## Acceptance Criteria

- [ ] README.md generated at project root by default
- [ ] All wikilinks in README use correct relative paths from root
- [ ] Existing root README.md handled gracefully (backup or merge)
- [ ] Phase 10 validation confirms root README existence
- [ ] Documentation updated to reflect new behavior

## Testing

1. Create new research project
2. Verify README.md at project root after Phase 8.4
3. Click all wikilinks in Obsidian - should resolve correctly
4. Run with existing README.md at root - should not overwrite without backup

## Priority Justification

**High Priority** because:
- Affects all new research projects
- Direct user experience impact
- Simple implementation with high ROI
- Aligns with standard conventions

## Related Issues

- None currently

## Notes

User feedback from caravan-stellplatz-lean-canvas project confirmed this navigation issue. Manual move was required post-research completion.

---

**Reported by:** deeper-research orchestration skill
**Assigned to:** Unassigned
**Milestone:** v1.1.0
