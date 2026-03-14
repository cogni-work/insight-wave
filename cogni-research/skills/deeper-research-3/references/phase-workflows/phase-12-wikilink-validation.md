# Phase 12: Wikilink Validation

Ensure all wikilinks are functional before finalizing research.

**MANDATORY:** This phase MUST be executed before Phase 13. Knowledge graph integrity is critical for synthesis quality.

**Automated Prevention:** The `post-write-validate-wikilinks.sh` hook validates wikilinks immediately after entity file writes during Phases 4-8, catching broken links when entities are created. This fail-fast approach prevents cascading failures before this final Phase 12 validation. Manual validation below serves as comprehensive verification across all entities.

---

## ⛔ PHASE ENTRY VERIFICATION (MANDATORY)

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 10 is marked complete. Phase 12 cannot begin until Phase 10 todos are completed.

**THEN verify Phase 10 completion (synthesis creation):**

```bash
# Check synthesis documents exist
ls -la research-hub.md README.md
```

**If files missing:** STOP, return to Phase 10.

---

## Step 0.5: Initialize Phase 12 TodoWrite

Add step-level todos for Phase 12:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 12, Step 1: Select validation mode based on token budget [in_progress]
- Phase 12, Step 2: Execute wikilink validation script [pending]
- Phase 12, Step 3: Handle broken links (if any) [pending]
- Phase 12, Step 4: Report validation results and mark phase complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

---

## Step 1: Select Validation Mode

Choose validation approach based on token budget:

- **Full Validation** (recommended, budget > 100k tokens remaining):
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-wikilinks.sh" \
    --project-path "{project-path}" --json
  ```

- **Token-Constrained Mode** (budget 50k-100k tokens):
  - Execute full validation but accept warnings instead of halting on non-critical issues
  - Prioritize synthesis completion over exhaustive validation
  - Document any warnings for post-pipeline review

**Future Enhancement:** Add `--quick` flag for rapid validation (sample-based instead of exhaustive)

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Execute Wikilink Validation Script

Run validation script with selected mode:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-wikilinks.sh" \
  --project-path "{project-path}" --json
```

**Expected response:**

```json
{"valid_links": 245, "broken_links": 0, "orphaned_entities": 3}
```

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Handle Broken Links

**IF broken_links > 0:**
1. Report error with broken link details and affected entities
2. Ask: "Fix wikilinks before proceeding?"
3. If yes: Halt workflow for manual review
4. If no: Continue with warning (not recommended)

**IF broken_links == 0:**
- Report: `✓ Phase 12: Validated knowledge graph ({valid_links} valid links, 0 broken)`

**Mark Step 3 todo as completed** before proceeding to Step 4.

---

## Step 4: Report Validation Results and Mark Phase Complete

### Report Completion

```text
✓ Phase 12: Validated knowledge graph

Wikilink Validation Summary:
- Valid links: {valid_links}
- Broken links: {broken_links}
- Orphaned entities: {orphaned_entities}

Knowledge graph integrity: {status}
```

### Self-Verification Before Completion

**Verify all steps completed:**

1. Did you select validation mode based on token budget? ✅ YES / ❌ NO
2. Did you execute the wikilink validation script? ✅ YES / ❌ NO
3. Did you handle broken links appropriately (if any)? ✅ YES / ❌ NO
4. Did you report validation results? ✅ YES / ❌ NO
5. Is the knowledge graph valid (0 broken links or user accepted warnings)? ✅ YES / ❌ NO

⛔ **IF ANY NO: STOP.** Return to incomplete step before proceeding.

### Mark Phase 12 Complete

- Update TodoWrite: Phase 12 → completed, Phase 13 → in_progress
- Update sprint metadata: `current_phase → "phase-13"`

**Mark Step 4 todo as completed** before proceeding to Phase 13.

---

## Phase 12 Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 13

Before marking Phase 12 complete in TodoWrite, verify:

- [ ] Phase entry verification passed (Phase 10 complete)
- [ ] Validation mode selected based on token budget
- [ ] Wikilink validation script executed
- [ ] Broken links handled (fixed or user accepted warnings)
- [ ] Validation results reported
- [ ] Knowledge graph integrity confirmed
- [ ] All step-level todos marked as completed
- [ ] All self-verification questions answered YES
- [ ] Phase 12 todo marked completed in TodoWrite

---

## Important Notes

**Never skip this phase entirely.** Use quick mode for token-constrained scenarios instead of skipping.

**Orphaned entities** (entities with no incoming links) are acceptable warnings. They indicate entities that exist but aren't referenced by other entities. This is common for foundational concepts or standalone findings.

**Broken links** (links pointing to non-existent entities) are critical errors that should be fixed before synthesis finalization. They indicate data integrity issues in the knowledge graph.
