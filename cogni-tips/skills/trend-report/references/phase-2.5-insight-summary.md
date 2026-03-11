# Phase 2.5: Insight Summary Generation (trend-panorama)

Generate an arc-aware narrative insight summary by delegating to `cogni-narrative:narrative-writer` using the `trend-panorama` arc.

**This phase runs automatically** — no user prompts required. The `trend-panorama` arc is purpose-built for TIPS output, mapping dimensions directly to narrative elements:

| TIPS Dimension | Arc Element | Narrative Focus |
|----------------|-------------|-----------------|
| T (Trends) — Externe Effekte | Forces | External pressure synthesis |
| I (Implications) — Digitale Wertetreiber | Impact | Value chain disruption mapping |
| P (Possibilities) — Neue Horizonte | Horizons | Strategic opportunity articulation |
| S (Solutions) — Digitales Fundament | Foundations | Capability requirement sequencing |

---

## Phase Entry Verification

**Self-Verification:** Before running verification, check TodoWrite to verify Phase 2 is marked complete. Phase 2.5 cannot begin until Phase 2 is completed.

**THEN verify Phase 2 artifact exists:**

Read `{PROJECT_PATH}/tips-trend-report.md`.
- IF Read succeeds: Phase 2 artifact confirmed. Continue.
- IF Read fails (file not found): HALT — Phase 2 incomplete.

---

## Step 1: Invoke Narrative-Writer Agent

**Add step-level todos via TodoWrite:**
- Phase 2.5, Step 1: Invoke narrative-writer agent [in_progress]
- Phase 2.5, Step 2: Validate tips-insight-summary.md exists [pending]
- Phase 2.5, Step 3: Report completion and mark phase complete [pending]

**Read project language from trend-scout output:**

These values were already extracted during Phase 0 Step 0.2. Reuse them directly:
- `language` = `project_language` (top-level field, NOT config.language)
- `industry` = `config.industry.primary_en` or `config.industry.primary_de`
- `topic` = `config.research_topic`

If Phase 0 context is unavailable, re-read `{PROJECT_PATH}/.metadata/trend-scout-output.json`
and extract from the correct paths above.

**Invoke narrative-writer agent with trend-panorama arc:**

```python
Task(
  subagent_type="cogni-narrative:narrative-writer",
  prompt="""source_path: {PROJECT_PATH}/
project_path: {PROJECT_PATH}
arc_id: trend-panorama
language: {language}
output_path: {PROJECT_PATH}/tips-insight-summary.md
research_question: {topic}

content_map:
  executive_summary: {PROJECT_PATH}/tips-trend-report.md
  dimension_sections:
    - {PROJECT_PATH}/.logs/report-section-externe-effekte.md
    - {PROJECT_PATH}/.logs/report-section-digitale-wertetreiber.md
    - {PROJECT_PATH}/.logs/report-section-neue-horizonte.md
    - {PROJECT_PATH}/.logs/report-section-digitales-fundament.md
  claims_registry: {PROJECT_PATH}/tips-trend-report-claims.json
  full_report: {PROJECT_PATH}/tips-trend-report.md
""",
  description="Generating insight summary (trend-panorama)"
)
```

- Input: source_path (project root), project_path, arc_id (`trend-panorama`), language, output_path, research_question, content_map
- Expected output: JSON with `success`, `arc_id`, `word_count`

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate tips-insight-summary.md Exists (Non-Blocking)

**Validate response:**

- Check JSON response for `success: true`
- Verify file exists:

Read `{PROJECT_PATH}/tips-insight-summary.md`.
- IF Read succeeds: File confirmed. Proceed to Step 3.
- IF Read fails (file not found): Log WARNING and proceed (non-blocking).

```text
WARNING: tips-insight-summary.md not created (narrative-writer returned success=false).
This is non-blocking. Continuing to Phase 3.
```

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Report Completion and Mark Phase Complete

**Report Completion (success case):**

```text
Phase 2.5: Generated insight summary (trend-panorama)
- File: tips-insight-summary.md (project root)
- Arc framework: Trend Panorama (Forces → Impact → Horizons → Foundations)
- Status: Created successfully
```

**Report Completion (warning case):**

```text
Phase 2.5: WARNING - tips-insight-summary.md not created
- narrative-writer agent failed or unavailable
- Non-blocking: continuing to Phase 3
```

**Self-Verification Before Completion:**

1. Did you check tips-trend-report.md exists? YES / NO
2. Did you invoke narrative-writer agent with arc_id=trend-panorama? YES / NO
3. Did you validate tips-insight-summary.md exists? YES / NO

**Update TodoWrite:** Phase 2.5 -> completed, Phase 3 -> in_progress

**Mark Step 3 todo as completed** before proceeding to Phase 3.

---

## TodoWrite Template (for orchestrator)

When initializing Phase 2.5 todos:

```markdown
- Phase 2.5: Insight summary generation (trend-panorama) [in_progress]
  - Step 1: Invoke narrative-writer agent [in_progress]
  - Step 2: Validate tips-insight-summary.md [pending]
  - Step 3: Report completion [pending]
```

---

## Error Handling

| Failure | Recovery |
|---------|----------|
| narrative-writer agent fails | WARNING only - continue to Phase 3 |
| tips-insight-summary.md not created | WARNING only - continue to Phase 3 |
| cogni-narrative plugin not installed | WARNING only - continue to Phase 3 |
| tips-trend-report.md missing | HALT - Phase 2 incomplete |

All failures in Phase 2.5 are **non-blocking** (except the entry gate). The insight summary is an enhancement, not a pipeline-critical artifact.

---

**End of Phase 2.5 Workflow**
