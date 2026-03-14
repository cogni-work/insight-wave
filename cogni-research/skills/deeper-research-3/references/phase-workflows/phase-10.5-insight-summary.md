# Phase 10.5: Insight Summary Generation

Generate arc-specific narrative (insight-summary.md) by delegating to `cogni-narrative:narrative-writer`.

---

## Phase Entry Verification

**Self-Verification:** Before running verification, check TodoWrite to verify Phase 10 is marked complete. Phase 10.5 cannot begin until Phase 10 is completed.

**THEN verify Phase 10 artifact exists:**

```bash
test -f {project_path}/research-hub.md
```

**THEN check arc_id exists (CONDITIONAL PHASE):**

```bash
arc_id=$(jq -r '.arc_id // ""' "{project_path}/.metadata/sprint-log.json")
```

**IF arc_id is empty:**

1. Log: "No arc_id set - Phase 10.5 skipped (no insight-summary needed)"
2. Mark Phase 10.5 as completed
3. Proceed directly to Phase 12

**IF arc_id is present:** Continue to Step 1.

---

## Step 1: Invoke Narrative-Writer Agent

**Add step-level todos via TodoWrite:**
- Phase 10.5, Step 1: Invoke narrative-writer agent [in_progress]
- Phase 10.5, Step 2: Validate insight-summary.md exists [pending]
- Phase 10.5, Step 3: Report completion and mark phase complete [pending]

**Read project language, research question, and sharpened question:**

```bash
project_language=$(jq -r '.project_language // "en"' "{project_path}/.metadata/sprint-log.json")
research_question=$(jq -r '.research_question // ""' "{project_path}/.metadata/sprint-log.json")
sharpened_question=$(jq -r '.sharpened_research_question // ""' "{project_path}/.metadata/sprint-log.json")
```

**Invoke narrative-writer agent:**

```python
Task(
  subagent_type="cogni-narrative:narrative-writer",
  prompt="""source_path: {project_path}/12-synthesis/
project_path: {project_path}
arc_id: {arc_id}
language: {project_language}
output_path: {project_path}/insight-summary.md
research_question: {sharpened_question if non-empty, else research_question}
original_research_question: {research_question}
sharpened_research_question: {sharpened_question}

content_map:
  executive_summary: {project_path}/12-synthesis/synthesis-cross-dimensional.md
  dimension_syntheses: {project_path}/12-synthesis/synthesis-*.md
  trends_summary: {project_path}/11-trends/README.md
  trend_entities: {project_path}/11-trends/data/
  megatrends_summary: {project_path}/06-megatrends/README.md
  megatrend_entities: {project_path}/06-megatrends/data/
  domain_concepts: {project_path}/05-domain-concepts/data/
  research_hub: {project_path}/research-hub.md
  initial_question: {project_path}/00-initial-question/data/
""",
  description="Generating insight summary ({arc_id})"
)
```

- Input: source_path (12-synthesis/), project_path, arc_id, language, output_path, research_question, original_research_question, sharpened_research_question, content_map
- Expected output: JSON with `success`, `arc_id`, `word_count`

**Narrative-writer instructions:**
- Use `sharpened_research_question` (if present) as the `subtitle` frontmatter field
- Use `sharpened_research_question` (if present) as the body research question text
- Preserve `original_research_question` in frontmatter for traceability
- Fall back to `research_question` if `sharpened_research_question` is empty

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate insight-summary.md Exists (Non-Blocking)

**Validate response:**

- Check JSON response for `success: true`
- Verify file exists:

```bash
test -f {project_path}/insight-summary.md
```

- **IF success AND file exists:** Log completion, proceed to Step 3
- **IF success=false OR file missing:** Log WARNING and proceed (non-blocking)

```text
WARNING: insight-summary.md not created (narrative-writer returned success=false).
This is non-blocking. Phase 13 Step 1.5 will flag this for manual review.
Continuing to Phase 12.
```

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Report Completion and Mark Phase Complete

**Report Completion (success case):**

```text
Phase 10.5: Generated insight summary ({arc_id})
- File: insight-summary.md (project root)
- Arc framework: {arc_display_name}
- Status: Created successfully
```

**Report Completion (skip case):**

```text
Phase 10.5: Skipped (no arc_id configured)
```

**Report Completion (warning case):**

```text
Phase 10.5: WARNING - insight-summary.md not created
- narrative-writer agent failed or unavailable
- Non-blocking: continuing to Phase 12
- Phase 13 Step 1.5 will flag for review
```

**Self-Verification Before Completion:**

1. Did you check arc_id in sprint-log.json? YES / NO
2. Did you invoke narrative-writer agent (if arc_id present)? YES / NO
3. Did you validate insight-summary.md exists? YES / NO

**Update TodoWrite:** Phase 10.5 -> completed, Phase 12 -> in_progress

**Mark Step 3 todo as completed** before proceeding to Phase 12.

---

## TodoWrite Template (for orchestrator)

When initializing Phase 10.5 todos:

```markdown
- Phase 10.5: Insight summary generation [in_progress]
  - Step 1: Invoke narrative-writer agent [in_progress]
  - Step 2: Validate insight-summary.md [pending]
  - Step 3: Report completion [pending]
```

**Skip variant (no arc_id):**

```markdown
- Phase 10.5: Insight summary generation [completed] (skipped: no arc_id)
```

---

## Error Handling

| Failure | Recovery |
|---------|----------|
| narrative-writer agent fails | WARNING only - continue to Phase 12 |
| insight-summary.md not created | WARNING only - Phase 13 flags for review |
| cogni-narrative plugin not installed | WARNING only - continue to Phase 12 |
| arc_id missing from sprint-log | Skip phase entirely (expected behavior) |

All failures in Phase 10.5 are **non-blocking**. The insight-summary.md is an enhancement, not a pipeline-critical artifact.

---

**End of Phase 10.5 Workflow**
