# Phase 8.5: Dimension Synthesis Generation

Generate comprehensive dimension synthesis documents from trends for integration into final research report.

---

## Phase Entry Verification

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 8 is marked complete. Phase 8.5 cannot begin until Phase 8 todos are completed.

**THEN verify Phase 8 artifacts exist:**

```bash
ls -la 11-trends/data/*.md  # trend files must exist
ls -la 11-trends/README-*.md  # dimension READMEs must exist
```

**IF trend files or READMEs are missing:**

1. STOP immediately
2. Return to Phase 8
3. Create the required trend files via trends-creator
4. Only then return to Phase 8.5

---

## Step 1: Extract Dimension Slugs

**Add step-level todos via TodoWrite:**
- Phase 8.5, Step 1: Extract dimension slugs from READMEs [in_progress]
- Phase 8.5, Step 2: Invoke synthesis-dimension per dimension [pending]
- Phase 8.5, Step 3: Validate synthesis documents created [pending]
- Phase 8.5, Step 4: Mark phase complete [pending]

**Extract dimension slugs:**

```bash
# List all dimension READMEs
ls 11-trends/README-*.md | sed 's/.*README-//' | sed 's/\.md$//'
```

This produces dimension slugs like:
- governance-transformationssteuerung
- wirtschaftlichkeit-business-case
- etc.

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Invoke Dimension-Synthesis-Creator Per Dimension

**Invoke synthesis-dimension agent for ALL dimensions in SINGLE message (parallel):**

```python
# ALL dimensions in ONE message for parallel execution
Task(
  subagent_type="cogni-research:synthesis-dimension",
  prompt="Generate dimension synthesis at {project_path} for dimension: {dimension_slug_1}. Language: {project_language}",
  description="Creating synthesis for {dimension_slug_1}"
)
Task(
  subagent_type="cogni-research:synthesis-dimension",
  prompt="Generate dimension synthesis at {project_path} for dimension: {dimension_slug_2}. Language: {project_language}",
  description="Creating synthesis for {dimension_slug_2}"
)
# ... one Task per dimension in SAME message
```

**Parallel execution rationale:** Each agent runs in isolated context. Wrapper agents handle their own token budget independently, enabling parallel processing across all dimensions.

**Expected output per dimension:** JSON with `success`, `dimension`, `file`, `trends_synthesized`, `citations_created`, `word_count`

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Validate Synthesis Documents Created

**Validate synthesis documents exist:**

```bash
ls -la 12-synthesis/synthesis-*.md
```

**Expected files:** One synthesis-{dimension}.md per dimension processed in `12-synthesis/`.

**IF any synthesis missing:**
- Log ERROR with missing dimension(s)
- HALT Phase 8.5 - do NOT continue to Phase 9
- Return error JSON: `{"success": false, "error": "Dimension synthesis failed", "missing_dimensions": [...]}`
- **This is not optional.** Skipping Phase 8.5 artifacts means the final report lacks dimension-scoped synthesis narratives

**Mark Step 3 todo as completed** before proceeding to Step 4.

---

## Step 4: Mark Phase Complete

**Self-Verification Before Completion:**

1. Did you run the phase entry verification gate (ls command)? ✅ YES / ❌ NO
2. Did you extract dimension slugs? ✅ YES / ❌ NO
3. Did you invoke synthesis-dimension for each dimension? ✅ YES / ❌ NO
4. Did you validate synthesis documents exist? ✅ YES / ❌ NO

⛔ **IF ANY NO: STOP.** Return to incomplete step before proceeding.

**Update TodoWrite:** Phase 8.5 → completed, Phase 9 → in_progress

**Mark Step 4 todo as completed** before proceeding to Phase 9.

**Required outputs:** synthesis-{dimension}.md files in `12-synthesis/`
