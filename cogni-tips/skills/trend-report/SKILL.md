---
name: trend-report
description: |
  Generate a narrative TIPS trend report with inline citations and verifiable claims from trend-scout output. Reads agreed trend candidates, enriches each with web-sourced quantitative evidence via parallel agents, assembles a full report with executive summary and portfolio analysis, generates a trend-panorama insight summary via cogni-narrative, and invokes cogni-claims:claim-work for automated verification. Use when: (1) trend-scout has completed and candidates are agreed, (2) user wants a written trend report, (3) user mentions "trend report", "TIPS report", "write up trends", "summarize trends", "trend analysis document", (4) preparing a deliverable from scouted trends, (5) user asks to "generate report from trends" or "create trend deliverable". Always use this skill when trend-scout output exists and the user wants any kind of written trend analysis — even if they don't use the exact phrase "trend report".
---

# Trend Report

Generate a narrative TIPS trend report from agreed trend-scout candidates. Dispatches 4 parallel agents (one per TIPS dimension) to enrich trends with web-sourced quantitative evidence, then assembles a full report with executive summary, dimension sections, portfolio analysis, and a claims registry for automated verification.

## Purpose

Transform agreed trend-scout candidates into a polished, evidence-backed report:

1. Enrich each trend with quantitative evidence from web research
2. Generate inline citations for every quantitative claim
3. Produce a claims registry compatible with `cogni-claims:claim-work`
4. Generate a trend-panorama narrative insight summary via cogni-narrative
5. Optionally verify claims via cogni-claims:claim-work

## Bilingual Support

Full German and English support. **Always ask the user** for the deliverable language (DE or EN) at the start of Phase 0 — do not silently inherit from `trend-scout-output.json`. Default priority for pre-filling: (1) trend-scout `project_language` from output JSON, (2) workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD), (3) `en`. User must always confirm or override. Report prose, section headers, and TIPS labels all adapt to the chosen language. Web searches run bilingually for maximum coverage. German text uses proper umlauts (never ASCII transliterations).

## Prerequisites

- `trend-scout` completed with `execution.workflow_state == "agreed"` and 52 candidates
- Web access enabled for evidence enrichment
- Optional: `cogni-narrative` plugin for insight summary (graceful fallback if absent)
- Optional: `cogni-claims` plugin for claim verification

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-tips` |
| `COGNI_WORKSPACE_ROOT` | Optional workspace root override (default: `$PWD`) | Current working directory |

`CLAUDE_PLUGIN_ROOT` is injected automatically from `settings.local.json`. `COGNI_WORKSPACE_ROOT` is optional — defaults to the current working directory if not set.

## Shell Usage

This skill is a pure orchestrator. All file I/O uses Read/Write tools; web research is delegated to agents. The only shell commands needed are:
- `cat file1 file2 ... > output` — concatenation of log files into the final report
- `rm -f pattern` — cleanup of stale output files on re-run
- `[ -f file ]` — existence checks before concatenation

Avoid `jq`, `sed`, `awk`, or `grep` for data processing — parsing JSON through the LLM keeps the workflow self-contained and avoids dependency issues.

## References Index

Read references **only when needed** for the specific phase:

| Reference | Read when... |
|-----------|--------------|
| [references/report-structure.md](references/report-structure.md) | Assembling the final report (Phase 2) |
| [references/evidence-enrichment.md](references/evidence-enrichment.md) | Configuring agent web search strategy (Phase 1) |
| [references/claims-format.md](references/claims-format.md) | Extracting/merging claims (Phase 1-2) |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English report headings and labels |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German report headings and labels |
| [references/phase-2.5-insight-summary.md](references/phase-2.5-insight-summary.md) | Generating arc-aware insight summary (Phase 2.5) |

## Workflow Overview

Track progress through these phases as you go:

```text
Phase 0 → Phase 1 → Phase 2 → Phase 2.5 → Phase 3 → Phase 4
   │          │          │         │            │          │
   │          │          │         │            │          └─ Update metadata, display summary
   │          │          │         │            └─ Optional claim-work verification
   │          │          │         └─ trend-panorama narrative via cogni-narrative
   │          │          └─ Exec summary + portfolio analysis + assemble report
   │          └─ 4 parallel agents: enrich trends, write sections, extract claims
   └─ Project discovery, load trend-scout output, validate gate
```

---

### Phase 0: Project Discovery + Input Loading

#### Step 0.1: Project Discovery

> Trend-scout projects use `trend-scout-output.json` (not `sprint-log.json`), so the shared `project-picker.md` pattern does not apply.

1. If `--project-path` was provided as argument, use it directly
2. Otherwise, run `discover-projects.sh --json` to enumerate all projects
3. For each project, check if `{path}/.metadata/trend-scout-output.json` exists
4. Read the file and check `execution.workflow_state == "agreed"` and `tips_candidates.total >= 52`
5. Collect eligible projects:
   - 0 eligible: ERROR — "No agreed trend-scout projects found. Run trend-scout first."
   - 1 eligible: Auto-select
   - 2+ eligible: Present via AskUserQuestion

#### Step 0.2: Load Input Data

```
REQUIRED:
  {PROJECT_PATH}/.metadata/trend-scout-output.json
    → Extract: config.industry, config.research_topic
    → Extract: project_language (top-level, NOT config.language)
    → Extract: tips_candidates.items (52 candidates)

OPTIONAL (raw web signals — try in order):
  1. {PROJECT_PATH}/.logs/web-research-raw.json
     → .raw_signals_before_dedup array (full field names)
  2. FALLBACK: {PROJECT_PATH}/phase1-research-summary.json
     → .items array (abbreviated fields: d→dimension, n→signal, k→keywords, u→source, f→freshness, a→authority, t→source_type, i→indicator_type, lt→lead_time)
```

#### Step 0.3: Validate Entry Gate

| Check | Condition | On Failure |
|-------|-----------|------------|
| Output exists | `.metadata/trend-scout-output.json` | HALT: Run trend-scout first |
| Workflow state | `== "agreed"` | HALT: Complete trend-scout selection |
| Candidate count | `>= 52` | HALT: Expected 52 agreed candidates |
| Config complete | industry, subsector, language present | HALT: Incomplete config |

#### Step 0.4: Prepare Agent Inputs

Group the 52 candidates by dimension (4 groups of ~13):

| Dimension Slug | TIPS Role | Expected Count |
|----------------|-----------|----------------|
| `externe-effekte` | T (Trends) | 13 |
| `digitale-wertetreiber` | I (Implications) | 13 |
| `neue-horizonte` | P (Possibilities) | 13 |
| `digitales-fundament` | S (Solutions) | 13 |

For each dimension, prepare: candidate list, matching raw web signals (filtered by dimension, or "none"), and shared config (industry en/de, subsector en/de, topic, language).

#### Step 0.5: Ask User for Deliverable Language

The `project_language` from trend-scout-output.json is the **default**, but always confirm with the user:

```yaml
AskUserQuestion:
  question: "Report language? trend-scout used '{project_language}'. Keep or change?"
  header: "Language"
  options:
    - label: "Deutsch (DE)"
    - label: "English (EN)"
```

Set `LANGUAGE` to the user's choice. Update `project_language` in trend-scout-output.json if changed.

#### Step 0.6: Load i18n Labels

Read the labels file matching the chosen language:
- English: [references/i18n/labels-en.md](references/i18n/labels-en.md)
- German: [references/i18n/labels-de.md](references/i18n/labels-de.md)

#### Step 0.7: Clean Up Stale Output Files

On re-runs, remove stale files to prevent mixing old and new content:

```bash
rm -f "{PROJECT_PATH}/.logs/report-header.md" \
      "{PROJECT_PATH}/.logs/report-section-"*.md \
      "{PROJECT_PATH}/.logs/claims-"*.json \
      "{PROJECT_PATH}/.logs/report-portfolio.md" \
      "{PROJECT_PATH}/.logs/report-claims-registry.md" \
      "{PROJECT_PATH}/tips-trend-report.md" \
      "{PROJECT_PATH}/tips-trend-report-claims.json"
```

---

### Phase 1: Evidence Enrichment + Section Generation (PARALLEL)

Read [references/evidence-enrichment.md](references/evidence-enrichment.md) for web search strategy.
Read [references/claims-format.md](references/claims-format.md) for claims extraction schema.

#### Step 1.1: Dispatch 4 Agents

Dispatch all 4 agents in a single message (parallel tool calls) so they run concurrently:

```yaml
Per agent:
  subagent_type: "cogni-tips:trend-report-writer"
  model: sonnet
  prompt: |
    Dimension: {DIMENSION}
    TIPS Role: {TIPS_ROLE}
    Project Path: {PROJECT_PATH}
    Language: {LANGUAGE}
    Industry EN/DE: {INDUSTRY_EN} / {INDUSTRY_DE}
    Subsector EN/DE: {SUBSECTOR_EN} / {SUBSECTOR_DE}
    Topic: {TOPIC}
    Candidates: {JSON array of ~13 candidates}
    Raw Signals: {JSON array of matching web signals, or "none"}
    Labels: {relevant i18n labels}
```

Dimensions: `externe-effekte` (T), `digitale-wertetreiber` (I), `neue-horizonte` (P), `digitales-fundament` (S).

Each agent writes:
- `{PROJECT_PATH}/.logs/report-section-{dimension}.md`
- `{PROJECT_PATH}/.logs/claims-{dimension}.json`

#### Step 1.2: Collect Agent Results

Each agent returns compact JSON with `ok`, `dimension`, `trends_covered`, `claims_extracted`, signal reuse metrics.

If an agent returns `ok: false`: retry once. If retry also fails: HALT with the dimension name. All 4 must succeed before Phase 2.

---

### Phase 2: Report Assembly

Read [references/report-structure.md](references/report-structure.md) for templates.

#### Step 2.1: Read All Section and Claims Files

Read the 4 section files and 4 claims files from `.logs/`.

#### Step 2.2: Generate Executive Summary

Write a ~500-word executive summary identifying 3-5 cross-cutting themes, highlighting the most impactful trends with evidence, noting the leading/lagging indicator balance, and summarizing strategic posture. Use the project language.

#### Step 2.3: Generate Portfolio Analysis

Create quantitative tables: horizon distribution, confidence distribution, signal intensity, leading/lagging balance, and evidence coverage — all per dimension.

#### Step 2.4: Write Component Files

Write these three files (each ending with two trailing newlines for clean concatenation):

| File | Content |
|------|---------|
| `.logs/report-header.md` | YAML frontmatter + H1 title + executive summary |
| `.logs/report-portfolio.md` | Portfolio analysis H2 + all tables |
| `.logs/report-claims-registry.md` | Claims registry H2 + markdown table of all claims |

For the claims registry, read all 4 `.logs/claims-{dimension}.json` files and transform each claim into a table row: `| # | claim text | value + unit | [title](url) | dimension |`.

#### Step 2.5: Assemble Final Report

Verify all 7 files exist, then concatenate. The dimension sections go straight from disk to disk — never through LLM output — which avoids token overflow on these large sections:

```bash
for f in \
  "{PROJECT_PATH}/.logs/report-header.md" \
  "{PROJECT_PATH}/.logs/report-section-externe-effekte.md" \
  "{PROJECT_PATH}/.logs/report-section-digitale-wertetreiber.md" \
  "{PROJECT_PATH}/.logs/report-section-neue-horizonte.md" \
  "{PROJECT_PATH}/.logs/report-section-digitales-fundament.md" \
  "{PROJECT_PATH}/.logs/report-portfolio.md" \
  "{PROJECT_PATH}/.logs/report-claims-registry.md"; do
  [ -f "$f" ] || { echo "MISSING: $f"; exit 1; }
done

cat \
  "{PROJECT_PATH}/.logs/report-header.md" \
  "{PROJECT_PATH}/.logs/report-section-externe-effekte.md" \
  "{PROJECT_PATH}/.logs/report-section-digitale-wertetreiber.md" \
  "{PROJECT_PATH}/.logs/report-section-neue-horizonte.md" \
  "{PROJECT_PATH}/.logs/report-section-digitales-fundament.md" \
  "{PROJECT_PATH}/.logs/report-portfolio.md" \
  "{PROJECT_PATH}/.logs/report-claims-registry.md" \
  > "{PROJECT_PATH}/tips-trend-report.md"
```

Verify: read first 3 + last 3 lines to confirm frontmatter opens with `---` and file ends with claims total.

#### Step 2.6: Merge Claims

Merge all 4 dimension claims into `{PROJECT_PATH}/tips-trend-report-claims.json`:

```json
{
  "status": "success",
  "file_path": "tips-trend-report.md",
  "language": "{LANGUAGE}",
  "total_claims": N,
  "claims": [... all claims ordered ee → dw → nh → df ...]
}
```

---

### Phase 2.5: Insight Summary (trend-panorama)

Read [references/phase-2.5-insight-summary.md](references/phase-2.5-insight-summary.md) for the full workflow.

Verify `tips-trend-report.md` exists, then invoke `cogni-narrative:narrative-writer` with arc_id `trend-panorama`. This arc maps TIPS dimensions to narrative elements (Forces → Impact → Horizons → Foundations).

All failures in this phase are non-blocking — the insight summary enhances the report but isn't required for downstream consumers.

---

### Phase 3: Claim Verification (Optional)

#### Step 3.1: Ask User

```yaml
AskUserQuestion:
  question: "{total_claims} quantitative claims were extracted. Verify them now?"
  header: "Verify"
  options:
    - label: "Verify now (Recommended)"
      description: "Run automated claim verification against source URLs"
    - label: "Skip verification"
      description: "Save claims file for later verification"
```

#### Step 3.2: Run Verification (if chosen)

```yaml
Skill:
  skill: "cogni-claims:claim-work"
  args: "--file-path {PROJECT_PATH}/tips-trend-report.md --claims-file {PROJECT_PATH}/tips-trend-report-claims.json --verdict-mode --language {LANGUAGE}"
```

If `cogni-claims` is not installed, display a warning and skip — do not halt.

#### Step 3.3: Process Results

Parse the QualityGateResult, display PASS/REVIEW/FAIL summary, write verification metadata to `.metadata/trend-report-verification.json`:

```json
{
  "verified_at": "ISO-8601",
  "verdict": "PASS|REVIEW|FAIL",
  "total_claims": N,
  "verified": N,
  "passed": N,
  "failed": N,
  "review": N
}
```

If FAIL: present failed claims as information only — do not auto-correct the report.

---

### Phase 4: Finalization

#### Step 4.1: Update Metadata

Add to `{PROJECT_PATH}/.metadata/trend-scout-output.json`:

```json
{
  "trend_report_complete": true,
  "trend_report_path": "tips-trend-report.md",
  "trend_report_claims_path": "tips-trend-report-claims.json",
  "trend_report_generated_at": "ISO-8601",
  "insight_summary_path": "tips-insight-summary.md or null",
  "insight_summary_arc": "trend-panorama or null"
}
```

#### Step 4.2: Display Summary

```
Trend Report Complete
─────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json
Insight:      {PROJECT_PATH}/tips-insight-summary.md (or "skipped")
Trends:       52 across 4 dimensions
Claims:       {total_claims} quantitative claims extracted
Verification: {verdict or "skipped"}

Recommended next steps:
  1. export-html-report — Generate interactive HTML report
  2. export-pdf-report — Generate formal PDF report
  3. cogni-claims:claim-work — Verify claims (if skipped)
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `trend-scout-output.json` missing | HALT: Run trend-scout first |
| `workflow_state != "agreed"` | HALT: Complete candidate selection |
| `tips_candidates.total < 52` | HALT: Expected 52 candidates |
| No raw signals file (both sources) | WARNING: proceed without signals (~120 searches) |
| Agent returns `ok: false` | Retry once, then HALT with dimension name |
| All 4 agents fail | HALT: Check web access is enabled |
| `cogni-narrative` not installed | WARNING: skip insight summary |
| `cogni-claims` not installed | WARNING: skip verification |
| claim-work returns FAIL | Present failed claims. Do not auto-correct. |

## Integration

**Upstream:** `trend-scout` produces `trend-scout-output.json`
**Downstream:** `export-html-report`, `export-pdf-report`, `cogni-claims:claim-work`

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `report-header.md` — frontmatter + exec summary
- `report-section-{dimension}.md` — dimension sections (4 files)
- `claims-{dimension}.json` — dimension claims (4 files)
- `report-portfolio.md` — portfolio analysis
- `report-claims-registry.md` — claims table

Output files in `{PROJECT_PATH}/`:
- `tips-trend-report.md` — assembled final report
- `tips-trend-report-claims.json` — merged claims registry
- `tips-insight-summary.md` — arc-aware insight summary (Phase 2.5, if successful)

| Issue | Check |
|-------|-------|
| Agent hangs | Verify web access is enabled |
| Empty claims | Check if trends have quantitative data in trend-scout output |
| Wrong language | Verify `project_language` in trend-scout-output.json |
| Missing sections | Check `.logs/` for partial agent output |
