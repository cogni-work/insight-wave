# Quality Standards and Validation Checklist

Comprehensive quality validation checklist for dimension-planner skill execution. Use this reference when validating outputs before returning final JSON response.

## Overview

The dimension-planner skill must meet rigorous quality standards across five categories:
1. Logging Infrastructure
2. MECE Validation
3. PICOT/FINER Quality
4. Entity Structure
5. Debugging Compliance

## Logging Infrastructure (Phase 0.3)

Validate logging setup before workflow execution:

- [ ] LOG_FILE initialized BEFORE sourcing enhanced-logging.sh
- [ ] LOG_FILE path follows pattern: `${PROJECT_PATH}/.metadata/dimension-planner-execution-log.txt`
- [ ] mkdir -p called to ensure .logs directory exists
- [ ] Log header written with agent name and timestamp
- [ ] Execution context captured to LOG_FILE

**Why this matters:** Proper logging initialization ensures debugging information is captured throughout execution. The LOG_FILE must be set before sourcing utilities to avoid silent failures.

**Common issues:**
- Sourcing enhanced-logging.sh before setting LOG_FILE → logs not written
- Missing mkdir -p → directory doesn't exist, writes fail
- Incorrect path pattern → logs scattered across filesystem

## MECE Validation (Phase 4)

Validate dimension structure meets Mutually Exclusive, Collectively Exhaustive criteria:

- [ ] Pairwise overlap analysis performed (<20% overlap)
- [ ] Coverage mapping confirms 100% question space addressed
- [ ] Independence verified (no dimension dependencies)

**Why this matters:** MECE validation ensures research dimensions are properly structured for parallel investigation without gaps or redundancy.

**Validation methodology:**
1. **Mutual Exclusivity:** Compare each dimension pair semantically - overlap should be <20%
2. **Collective Exhaustiveness:** Map all research question elements to dimensions - should cover 100%
3. **Independence:** Verify no dimension requires results from another - enables parallel execution

**Common issues:**
- Economic and Customer dimensions overlapping on pricing/willingness-to-pay
- Missing regulatory dimensions in healthcare/finance domains (coverage gap)
- Solution dimension depending on Problem dimension results (breaks independence)

## PICOT/FINER Quality (Phase 4)

Validate all questions meet PICOT structure and FINER scoring thresholds:

- [ ] All questions have PICOT components
- [ ] All questions scored ≥10/15 on FINER
- [ ] Average FINER score ≥11.0/15

**Why this matters:** PICOT ensures questions are concrete and researchable. FINER scores measure feasibility, relevance, and value.

**PICOT components (all required):**
- **P**opulation: Who/what is affected?
- **I**ntervention: What action/phenomenon?
- **C**omparison: Against what baseline?
- **O**utcome: What results matter?
- **T**imeframe: When?

**FINER thresholds:**
- Individual questions: ≥10/15 (below this requires reformulation)
- Average across all questions: ≥11.0/15 (ensures overall quality)
- High-priority questions: ≥13/15 (ideal target)

**Common issues:**
- Missing timeframe component (most frequent PICOT gap)
- Vague population definition ("companies" vs "B2B SaaS companies 50-500 employees")
- FINER scoring too generous without clear feasibility assessment

## Entity Structure (Phase 5)

Validate entity files meet structure and naming requirements:

- [ ] Dimension files use English slugs
- [ ] Question IDs use dimension slug prefix
- [ ] YAML frontmatter valid with Dublin Core metadata
- [ ] QUESTION_FILE variable assigned in Phase 0.1
- [ ] Dimension slugs tracked during Phase 5.1 (not via bash arrays)
- [ ] Initial Question has dimension_ids backlinks (Phase 5.4)
- [ ] Backlinks use YAML list format (NOT JSON array)
- [ ] Backlinks use workspace-relative wikilink format: `[[01-research-dimensions/data/{slug}]]`
- [ ] Edit tool used for Initial Question update (not sed pseudocode)
- [ ] File size verified non-zero after Edit operation

**Why this matters:** Consistent entity structure enables Obsidian knowledge graph navigation and ensures downstream pipeline compatibility.

**Critical requirements:**

1. **English slugs:** Always use English for file paths, even with non-English content
   - Correct: `economic-analysis.md` (file) with `display_name: "Wirtschaftliche Analyse"` (German)
   - Incorrect: `wirtschaftliche-analyse.md` (breaks cross-language compatibility)

2. **Question ID prefixes:** Use full dimension slug, no truncation
   - Correct: `economic-analysis-q1`, `economic-analysis-q2`
   - Incorrect: `econ-q1` (ambiguous, can't reverse-map to dimension)

3. **Backlink format:** YAML list with workspace-relative wikilinks
   - Correct: `dimension_ids:\n  - "[[01-research-dimensions/data/slug]]"`
   - Incorrect: `dimension_ids: ["[[slug]]"]` (JSON array, wrong path)

4. **Edit tool requirement:** Never use sed/awk for YAML frontmatter updates
   - Correct: Use Edit tool with old_string/new_string
   - Incorrect: `sed -i 's/foo/bar/' file.md` (risks corrupting YAML)

5. **Zero-byte check:** Verify file size after Edit operations
   - Prevents Sprint 310-style corruption where Edit created empty files
   - Use: `[ -s "$QUESTION_FILE" ] || error "File is empty after Edit"`

**Common issues:**
- Localized dimension slugs breaking filesystem operations
- Truncated question IDs causing ambiguity
- JSON array format in YAML (Obsidian can't parse)
- sed operations corrupting frontmatter with special characters
- Empty files after Edit failures

## Debugging Compliance

Validate debugging infrastructure meets logging architecture standards:

- [x] All phases have log_phase markers (for stderr visibility) ✅ COMPLETE
- [x] All variables have assignment + log_conditional + log_metric calls ✅ COMPLETE
- [x] JSON report (Phase 5.3) contains all metrics for persistent audit trail ✅ COMPLETE

**Why this matters:** Comprehensive logging enables troubleshooting skill execution issues and provides audit trail for research workflow.

**Requirements:**

1. **Phase markers:** Every phase must call `log_phase "Phase N" "Description"`
   - Enables progress tracking in terminal output
   - Provides structure for log analysis

2. **Variable logging:** Every computed variable must have three-part logging
   ```bash
   DIMENSION_COUNT=4  # Assignment
   log_conditional INFO "${DIMENSION_COUNT} dimensions selected"  # Context
   log_metric "dimension_count" "${DIMENSION_COUNT}" "count"  # Metric
   ```

3. **JSON report:** Phase 5.3 must include all critical metrics
   - Enables programmatic validation
   - Provides persistent record (LOG_FILE may be incomplete due to tool call isolation)

**Note:** These checklist items are marked complete because they were implemented in Sprint 310 debugging enhancements. Future skill updates should maintain this compliance.

## Validation Workflow

Recommended validation sequence before returning JSON:

1. **Quick checks first:**
   - Dimension count in range (2-10)
   - Question count in range (8-50)
   - Average FINER ≥11.0

2. **Structural validation:**
   - All entity files created
   - File sizes non-zero
   - YAML frontmatter valid

3. **Quality validation:**
   - MECE criteria met (if domain-based mode)
   - PICOT components present
   - Individual FINER scores ≥10

4. **Integration validation:**
   - Backlinks added to Initial Question
   - Wikilink format correct
   - Dimension slugs match file names

5. **Logging validation:**
   - All phase markers logged
   - All variables have metrics
   - JSON report complete

## Troubleshooting

**Issue:** Average FINER score below 11.0
- **Cause:** Questions too vague or not feasible
- **Fix:** Reformulate low-scoring questions with stricter PICOT structure
- **Retry:** Re-score after reformulation (allow one retry per question)

**Issue:** MECE validation fails (overlap >20%)
- **Cause:** Dimension definitions too broad or overlapping semantically
- **Fix:** Refine dimension boundaries, consider merging overlapping dimensions
- **Prevention:** Use more specific domain templates

**Issue:** Backlink update fails
- **Cause:** QUESTION_FILE not set, file structure changed, Edit operation failure
- **Fix:** Verify QUESTION_FILE assigned in Phase 0.1, check file exists, use correct old_string
- **Prevention:** Always verify file exists before Edit operations

**Issue:** Empty files after Edit
- **Cause:** Edit tool failure, incorrect old_string, file permissions
- **Fix:** Check file size after Edit, restore from backup if zero bytes
- **Prevention:** Always verify file size non-zero after Edit operations

## References

- MECE methodology: [references/mece-validation.md](mece-validation.md)
- PICOT framework: [references/picot-framework.md](picot-framework.md)
- FINER criteria: [references/finer-criteria.md](finer-criteria.md)
- Entity creation (batched): [workflow-phases/phase-5-entity-creation.md](workflow-phases/phase-5-entity-creation.md)
- Logging architecture: [references/error-recovery-patterns.md](error-recovery-patterns.md)
- Multilingual patterns: [references/multilingual-patterns.md](multilingual-patterns.md)
- Validation patterns: [references/validation-patterns.md](validation-patterns.md)
