# Phase 5.2 Progress Tracker Template

This template shows the format for the progress tracker file created during Phase 5.2.0.

---

# Phase 5.2 Progress Tracker

**Project:** {PROJECT_ID}
**Total Questions Planned:** {TOTAL_QUESTIONS}
**Dimensions:** {DIMENSION_COUNT}
**Started:** {TIMESTAMP}

---

## Progress Checklist

### Dimension: {dimension-1-slug} ({question_count_1} questions)

- [ ] {dimension-1-slug}-q1
- [ ] {dimension-1-slug}-q2
- [ ] {dimension-1-slug}-q3
- [ ] {dimension-1-slug}-q4

**Dimension Status:** Pending

### Dimension: {dimension-2-slug} ({question_count_2} questions)

- [ ] {dimension-2-slug}-q1
- [ ] {dimension-2-slug}-q2
- [ ] {dimension-2-slug}-q3

**Dimension Status:** Pending

### Dimension: {dimension-3-slug} ({question_count_3} questions)

- [ ] {dimension-3-slug}-q1
- [ ] {dimension-3-slug}-q2
- [ ] {dimension-3-slug}-q3
- [ ] {dimension-3-slug}-q4
- [ ] {dimension-3-slug}-q5

**Dimension Status:** Pending

---

## Write Attempts Log

| Question ID | Status | File Size | Timestamp | Notes |
|-------------|--------|-----------|-----------|-------|
| {dimension-1-slug}-q1 | ✅ Success | 2.5 KB | 2025-11-21T20:00:01Z | PICOT complete, FINER 14/15 |
| {dimension-1-slug}-q2 | ✅ Success | 2.4 KB | 2025-11-21T20:00:05Z | PICOT complete, FINER 13/15 |
| {dimension-1-slug}-q3 | ❌ Failed | 0 bytes | 2025-11-21T20:00:10Z | Empty content - missing PICOT Comparison |
| {dimension-1-slug}-q3 | ✅ Success | 2.6 KB | 2025-11-21T20:00:15Z | Retry successful after PICOT fix |

---

## Verification Results

### Dimension 1: {dimension-1-slug}
- **Planned:** {question_count_1} questions
- **Created:** {actual_count_1} questions
- **Status:** ✅ Complete / ❌ Incomplete
- **Verified:** {TIMESTAMP}

### Dimension 2: {dimension-2-slug}
- **Planned:** {question_count_2} questions
- **Created:** {actual_count_2} questions
- **Status:** ✅ Complete / ❌ Incomplete
- **Verified:** {TIMESTAMP}

### Dimension 3: {dimension-3-slug}
- **Planned:** {question_count_3} questions
- **Created:** {actual_count_3} questions
- **Status:** ✅ Complete / ❌ Incomplete
- **Verified:** {TIMESTAMP}

---

## Final Verification (Phase 5.2.5)

**Total Planned:** {TOTAL_QUESTIONS}
**Total Created:** {ACTUAL_TOTAL}
**Total Skipped:** {SKIPPED_COUNT}

**Status:** ✅ PASSED / ❌ FAILED

**Completed:** {TIMESTAMP}

---

## Usage Instructions

### During Phase 5.2.0 Initialization

1. Copy this template structure
2. Replace {variables} with actual values:
   - {PROJECT_ID}: From sprint-log.json
   - {TOTAL_QUESTIONS}: From Phase 4 validation
   - {DIMENSION_COUNT}: Number of dimensions
   - {dimension-X-slug}: Dimension slugs from SELECTED_DIMENSIONS
   - {question_count_X}: Questions per dimension from Phase 3

3. Write to: `${PROJECT_PATH}/.metadata/phase5-progress.md`

### During Phase 5.2.{index} Question Writing

After EACH question Write tool call:

1. Check if file exists: `ls "${PROJECT_PATH}/02-refined-questions/data/${question_id}.md"`
2. Check file size: `wc -c < "${PROJECT_PATH}/02-refined-questions/data/${question_id}.md"`
3. Update progress tracker:
   - If success: Mark checkbox [x], add success row to Write Attempts Log
   - If failed: Keep checkbox [ ], add failure row with notes
4. Use Edit tool to update the tracker file

### During Phase 5.2.{index}.5 Per-Dimension Verification

After completing all questions for a dimension:

1. Count actual files: `find "${PROJECT_PATH}/02-refined-questions" -name "${dimension_slug}-q*.md" | wc -l`
2. Compare against planned count
3. Update Verification Results section for this dimension
4. If counts match: Mark dimension status as ✅ Complete
5. If counts don't match: Mark as ❌ Incomplete and STOP execution

### During Phase 5.2.5 Final Verification

Before proceeding to Phase 5.3:

1. Read progress tracker file
2. Count unchecked [ ] items in Progress Checklist
3. Count total files in 02-refined-questions/data/
4. Update Final Verification section
5. If all checks pass: Mark status ✅ PASSED, proceed to Phase 5.3
6. If any check fails: Mark status ❌ FAILED, return error JSON

---

## Example Completed Tracker

See below for an example of a fully completed progress tracker showing all questions successfully created:

```markdown
# Phase 5.2 Progress Tracker

**Project:** digitalisierungstrends-deutscher-maschinenbau-mittelstand
**Total Questions Planned:** 12
**Dimensions:** 3
**Started:** 2025-11-21T20:00:00Z

## Progress Checklist

### Dimension: customer-analysis (4 questions)

- [x] customer-analysis-q1
- [x] customer-analysis-q2
- [x] customer-analysis-q3
- [x] customer-analysis-q4

**Dimension Status:** ✅ Complete

### Dimension: competitive-landscape (4 questions)

- [x] competitive-landscape-q1
- [x] competitive-landscape-q2
- [x] competitive-landscape-q3
- [x] competitive-landscape-q4

**Dimension Status:** ✅ Complete

### Dimension: technical-feasibility (4 questions)

- [x] technical-feasibility-q1
- [x] technical-feasibility-q2
- [x] technical-feasibility-q3
- [x] technical-feasibility-q4

**Dimension Status:** ✅ Complete

## Final Verification (Phase 5.2.5)

**Total Planned:** 12
**Total Created:** 12
**Total Skipped:** 0

**Status:** ✅ PASSED

**Completed:** 2025-11-21T20:15:30Z
```

---

## Notes

- Progress tracker is created in `.metadata/` directory (not tracked in main research output)
- Tracker provides audit trail for debugging
- Checkbox format [x]/[ ] is visually salient for Claude
- Write Attempts Log helps identify patterns in failures
- Verification sections enforce accountability at multiple levels
