# Phase 10: Synthesis Creation

Create comprehensive research report from trends and evidence catalog.

---

## Phase Entry Verification

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 8.5 AND Phase 9 are marked complete. Phase 10 cannot begin until both phases are completed.

**THEN verify Phase 8.5 artifacts exist:**

```bash
ls -la 12-synthesis/synthesis-*.md
```

**IF dimension syntheses are missing:**

1. STOP immediately
2. Return to Phase 8.5
3. Create the required dimension synthesis documents via synthesis-dimension
4. Only then proceed to verify Phase 9

**THEN verify Phase 9 artifacts exist:**

```bash
ls -la 09-citations/README.md
```

**IF 09-citations/README.md is missing:**

1. STOP immediately
2. Return to Phase 9
3. Create the required evidence catalog
4. Only then return to Phase 10

**This is not optional.** Skipping Phase 8.5 means synthesis-hub will fail (Phase 3 explicitly requires dimension syntheses). Skipping Phase 9 artifacts means the synthesis lacks evidence catalog.

---

## Step 1: Invoke Synthesis-Creator Agent

**Add step-level todos via TodoWrite:**
- Phase 10, Step 1: Invoke synthesis-hub agent [in_progress]
- Phase 10, Step 2: Validate research report exists (research-hub.md) [pending]
- Phase 10, Step 3: Extract synthesis metrics [pending]
- Phase 10, Step 4: Report completion and mark phase complete [pending]

**Invoke synthesis-hub agent:**

```python
Task(
  subagent_type="cogni-research:synthesis-hub",
  prompt="Create research report at {project_path}. Language: {project_language}",
  description="Creating research report"
)
```

- Input: `{"PROJECT_PATH": "{project_path}", "LANGUAGE": "{project_language}"}`
- Expected output: JSON with `success`, `files_created`, `trends_integrated`, `evidence_citations`

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate Research Report Exists

**Validate response:**

- Expect JSON response with `success: true`
- Research report exists:

```bash
test -f {project_path}/research-hub.md  # Comprehensive research report at project root
```

- IF file missing: Abort Phase 10 with error "Synthesis creation incomplete: research-hub.md not found"

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Extract Synthesis Metrics

**Extract synthesis metrics:**

```bash
trends=$(echo "$response" | jq -r '.trends_integrated')
citations=$(echo "$response" | jq -r '.evidence_citations')
```

**Mark Step 3 todo as completed** before proceeding to Step 4.

---

## Step 4: Report Completion and Mark Phase Complete

**Report Completion:**

```text
✓ Phase 10: Generated research synthesis ({trends} trends integrated, {citations} evidence citations)

Synthesis structure:
- Research report: research-hub.md (project root)
- Evidence catalog: 09-citations/README.md (from Phase 9)
- Trends: 11-trends/data/ (from Phase 8)

Project root: {project_path}/
```

**Self-Verification Before Completion:**

1. Did you run the phase entry verification gate (ls command)? ✅ YES / ❌ NO
2. Did you invoke synthesis-hub agent? ✅ YES / ❌ NO
3. Did you validate research report exists (research-hub.md)? ✅ YES / ❌ NO
4. Did you extract synthesis metrics? ✅ YES / ❌ NO

⛔ **IF ANY NO: STOP.** Return to incomplete step before proceeding.

**Update TodoWrite:** Phase 10 → completed, Phase 12 → in_progress

**Mark Step 4 todo as completed** before proceeding to Phase 12.

**Required outputs:** `research-hub.md`
