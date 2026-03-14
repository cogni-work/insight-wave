# Phase 9: Evidence Synthesis

Generate comprehensive source and citation catalog.

---

## Phase Entry Verification

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 8 is marked complete. Phase 9 cannot begin until Phase 8 todos are completed.

**THEN verify Phase 8 artifacts exist:**

```bash
ls -la 11-trends/data/*.md  # trend-*.md or portfolio-*.md based on research_type
```

**IF trend files are missing:**

1. STOP immediately
2. Return to Phase 8
3. Create the required trend files via trends-creator
4. Only then return to Phase 9

**This is not optional.** Skipping Phase 8 artifacts means the synthesis lacks dimension-scoped trends.

---

## Step 1: Invoke Evidence-Synthesizer Agent

**Add step-level todos via TodoWrite:**
- Phase 9, Step 1: Invoke evidence-synthesizer agent [in_progress]
- Phase 9, Step 2: Validate 09-citations/README.md creation [pending]
- Phase 9, Step 3: Extract and report metrics [pending]
- Phase 9, Step 4: Mark phase complete [pending]

**Invoke evidence-synthesizer agent:**

```python
Task(
  subagent_type="cogni-research:evidence-synthesizer",
  prompt="Generate evidence synthesis at {project_path}. Language: {project_language}",
  description="Creating evidence catalog",
  run_in_background=false  # MUST block - orchestrator needs response metrics
)
```

- Input: `{"PROJECT_PATH": "{project_path}", "LANGUAGE": "{project_language}"}`
- Expected output: JSON with `sources_cataloged`, `citations_formatted`, `institutions_mapped`, `tier1_sources`, `tier2_sources`, `tier3_sources`

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate 09-citations/README.md Creation

**Validate response:**

- Expect JSON response with `success: true`
- Evidence catalog exists: `test -f {project_path}/09-citations/README.md`
- IF fails: Abort Phase 9 with error "Evidence synthesis failed"

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Extract and Report Metrics

**Extract metrics:**

```bash
sources_cataloged=$(echo "$response" | jq -r '.sources_cataloged')
tier1=$(echo "$response" | jq -r '.tier1_sources')
tier2=$(echo "$response" | jq -r '.tier2_sources')
tier3=$(echo "$response" | jq -r '.tier3_sources')
```

**Report:**

```text
✓ Phase 9: Cataloged {sources_cataloged} sources ({tier1} Tier 1, {tier2} Tier 2, {tier3} Tier 3)

Evidence catalog: 09-citations/README.md
- Source reliability distribution
- Institutional authority mapping
- Complete bibliography
```

**Mark Step 3 todo as completed** before proceeding to Step 4.

---

## Step 4: Mark Phase Complete

**Self-Verification Before Completion:**

1. Did you run the phase entry verification gate (ls command)? ✅ YES / ❌ NO
2. Did you invoke evidence-synthesizer agent? ✅ YES / ❌ NO
3. Did you validate 09-citations/README.md exists? ✅ YES / ❌ NO
4. Did you extract and report source/tier metrics? ✅ YES / ❌ NO

⛔ **IF ANY NO: STOP.** Return to incomplete step before proceeding.

**Update TodoWrite:** Phase 9 → completed, Phase 10 → in_progress

**Mark Step 4 todo as completed** before proceeding to Phase 10.

**Required outputs:** `09-citations/README.md`
