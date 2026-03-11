---
name: trend-report
description: |
  Generate a strategic TIPS trend report organized around investment themes with inline citations and verifiable claims. When value-modeler output exists, produces a theme-first report where 3-7 strategic themes drive the narrative — each theme tells a CxO-level investment story backed by T→I→P value chain evidence. Without value-modeler, falls back to a dimensional catalog. Reads agreed trend candidates, enriches each with web-sourced quantitative evidence via parallel agents, assembles the report with strategic executive summary and portfolio analysis, generates a trend-panorama insight summary via cogni-narrative, and invokes cogni-claims:claim-work for automated verification. Recommended pipeline: trend-scout → value-modeler → trend-report. Use when: (1) trend-scout has completed and candidates are agreed, (2) user wants a written trend report, (3) user mentions "trend report", "TIPS report", "write up trends", "summarize trends", "trend analysis document", "strategic stories", (4) preparing a deliverable from scouted trends, (5) user asks to "generate report from trends" or "create trend deliverable". Always use this skill when trend-scout output exists and the user wants any kind of written trend analysis — even if they don't use the exact phrase "trend report".
---

# Trend Report

Generate a strategic TIPS trend report from agreed trend-scout candidates. When value-modeler output exists, organizes the report around strategic investment themes — each theme tells a CxO-level story backed by T→I→P value chain evidence. Dispatches 4 parallel agents to enrich trends with web-sourced quantitative evidence, then assembles either a theme-first strategic report or a dimensional catalog, plus executive summary, portfolio analysis, and claims registry.

## Purpose

Transform agreed trend-scout candidates into a strategic, evidence-backed report:

1. Detect value-modeler output and select report mode (theme-first or catalog)
2. Enrich each trend with quantitative evidence from web research
3. Assemble theme narratives with embedded evidence (or dimensional catalog as fallback)
4. Generate inline citations for every quantitative claim
5. Produce a claims registry compatible with `cogni-claims:claim-work`
6. Generate a trend-panorama narrative insight summary via cogni-narrative
7. Optionally verify claims via cogni-claims:claim-work

## Bilingual Support

Full German and English support. **Always ask the user** for the deliverable language (DE or EN) at the start of Phase 0 — do not silently inherit from `trend-scout-output.json`. Default priority for pre-filling: (1) trend-scout `project_language` from output JSON, (2) workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD), (3) `en`. User must always confirm or override. Report prose, section headers, and TIPS labels all adapt to the chosen language. Web searches run bilingually for maximum coverage. German text uses proper umlauts (never ASCII transliterations).

## Prerequisites

- `trend-scout` completed with `execution.workflow_state == "agreed"` and 60 candidates
- Web access enabled for evidence enrichment
- Optional (recommended): `value-modeler` completed — enables strategic theme report instead of dimensional catalog
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
| [$CLAUDE_PLUGIN_ROOT/references/data-model.md]($CLAUDE_PLUGIN_ROOT/references/data-model.md) | Understanding entity schemas and project structure |
| [references/report-structure.md](references/report-structure.md) | Assembling catalog-mode report (Phase 2, no value model) |
| [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) | Assembling theme-mode report (Phase 2, value model exists) |
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
   │          │          ├─ THEME MODE: strategic theme narratives + evidence weaving
   │          │          └─ CATALOG MODE: exec summary + portfolio + dimension assembly
   │          └─ 4 parallel agents: enrich trends, write sections + enriched JSONs, extract claims
   └─ Project discovery, load trend-scout + value-modeler output, validate gate
```

**Report modes:** Phase 0 detects whether `tips-value-model.json` exists. If it does and contains strategic themes, the report is organized around those themes (theme mode). Otherwise, the report follows the traditional TIPS dimensional catalog (catalog mode). The recommended pipeline is `trend-scout → value-modeler → trend-report`, but trend-report works without value-modeler.

---

### Phase 0: Project Discovery + Input Loading

#### Step 0.1: Project Discovery

> Trend-scout projects use `trend-scout-output.json` (not `sprint-log.json`), so the shared `project-picker.md` pattern does not apply.

1. If `--project-path` was provided as argument, use it directly
2. Otherwise, run `discover-projects.sh --json` to enumerate all projects
3. For each project, check if `{path}/.metadata/trend-scout-output.json` exists
4. Read the file and check `execution.workflow_state == "agreed"` and `tips_candidates.total >= 60`
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
    → Extract: tips_candidates.items (60 candidates)

OPTIONAL (value model — enables theme mode):
  {PROJECT_PATH}/tips-value-model.json
    → Check: themes[] array exists and has ≥1 entry
    → If yes: set THEME_MODE = true, extract themes[], value_chains[], solution_templates[]
    → If no (file missing or no themes): set THEME_MODE = false

OPTIONAL (raw web signals — try in order):
  1. {PROJECT_PATH}/.logs/web-research-raw.json
     → .raw_signals_before_dedup array (full field names)
  2. FALLBACK: {PROJECT_PATH}/phase1-research-summary.json
     → .items array (abbreviated fields: d→dimension, n→signal, k→keywords, u→source, f→freshness, a→authority, t→source_type, i→indicator_type, lt→lead_time)
```

Display the detected mode to the user:
- Theme mode: `"{PHASE_0_THEMES_FOUND}"` (from i18n labels)
- Catalog mode: `"{PHASE_0_NO_THEMES}"`

#### Step 0.3: Validate Entry Gate

| Check | Condition | On Failure |
|-------|-----------|------------|
| Output exists | `.metadata/trend-scout-output.json` | HALT: Run trend-scout first |
| Workflow state | `== "agreed"` | HALT: Complete trend-scout selection |
| Candidate count | `>= 60` | HALT: Expected 60 agreed candidates |
| Config complete | industry, subsector, language present | HALT: Incomplete config |

#### Step 0.4: Prepare Agent Inputs

Group the 60 candidates by dimension (4 groups of 15):

| Dimension Slug | TIPS Role | Expected Count |
|----------------|-----------|----------------|
| `externe-effekte` | T (Trends) | 15 |
| `digitale-wertetreiber` | I (Implications) | 15 |
| `neue-horizonte` | P (Possibilities) | 15 |
| `digitales-fundament` | S (Solutions) | 15 |

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
      "{PROJECT_PATH}/.logs/report-theme-"*.md \
      "{PROJECT_PATH}/.logs/report-emerging-signals.md" \
      "{PROJECT_PATH}/.logs/enriched-trends-"*.json \
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
- `{PROJECT_PATH}/.logs/report-section-{dimension}.md` — narrative section (used in catalog mode assembly)
- `{PROJECT_PATH}/.logs/claims-{dimension}.json` — extracted claims
- `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` — per-trend evidence blocks keyed by candidate_ref (used in theme mode assembly)

#### Step 1.2: Collect Agent Results

Each agent returns compact JSON with `ok`, `dimension`, `trends_covered`, `claims_extracted`, signal reuse metrics, and the three output file paths (`section_file`, `claims_file`, `enriched_file`).

If an agent returns `ok: false`: retry once. If retry also fails: HALT with the dimension name. All 4 must succeed before Phase 2.

---

### Phase 2: Report Assembly

Phase 2 branches based on `THEME_MODE` set in Phase 0.

---

#### Phase 2 — Theme Mode (`THEME_MODE = true`)

Read [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) for the full workflow.

This mode assembles the report around strategic themes from the value model. Individual trends become evidence woven into each theme's strategic narrative. The report reads as a strategy document with 3-7 investment themes, not a catalog of 60 trends.

**Summary of steps** (details in the reference):

1. **Build lookups** — Read 4 `enriched-trends-{dimension}.json` + 4 `claims-{dimension}.json` → candidate_ref and claim_id lookups
2. **Strategic executive summary** — Theme overview table, headline evidence, strategic posture → `report-header.md`
3. **Theme sections** — One per theme with investment thesis, value chain walkthroughs, solution templates, strategic actions → `report-theme-{theme_id}.md`
4. **Emerging signals** — Orphan candidates not in any theme → `report-emerging-signals.md`
5. **Strategic portfolio view** — Theme-level metrics, horizon distribution, MECE validation → `report-portfolio.md`
6. **Claims registry** — All claims with theme column → `report-claims-registry.md`
7. **Assemble** — Concatenate: header + themes (ordered) + emerging signals + portfolio + claims → `tips-trend-report.md`
8. **Merge claims** — Same as catalog mode → `tips-trend-report-claims.json`

---

#### Phase 2 — Catalog Mode (`THEME_MODE = false`)

Read [references/report-structure.md](references/report-structure.md) for templates.

This is the original dimensional report — used when value-modeler hasn't run.

##### Step 2.1: Read All Section and Claims Files

Read the 4 section files and 4 claims files from `.logs/`.

##### Step 2.2: Generate Executive Summary

Write a ~500-word executive summary identifying 3-5 cross-cutting themes, highlighting the most impactful trends with evidence, noting the leading/lagging indicator balance, and summarizing strategic posture. Use the project language.

##### Step 2.3: Generate Portfolio Analysis

Create quantitative tables: horizon distribution, confidence distribution, signal intensity, leading/lagging balance, and evidence coverage — all per dimension.

##### Step 2.4: Write Component Files

Write these three files (each ending with two trailing newlines for clean concatenation):

| File | Content |
|------|---------|
| `.logs/report-header.md` | YAML frontmatter + H1 title + executive summary |
| `.logs/report-portfolio.md` | Portfolio analysis H2 + all tables |
| `.logs/report-claims-registry.md` | Claims registry H2 + markdown table of all claims |

For the claims registry, read all 4 `.logs/claims-{dimension}.json` files and transform each claim into a table row: `| # | claim text | value + unit | [title](url) | dimension |`.

##### Step 2.5: Assemble Final Report

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

##### Step 2.6: Merge Claims

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

Update `{PROJECT_PATH}/tips-project.json` with current timestamp:
```json
{ "updated": "ISO-8601" }
```

Add to `{PROJECT_PATH}/.metadata/trend-scout-output.json`:

```json
{
  "trend_report_complete": true,
  "trend_report_path": "tips-trend-report.md",
  "trend_report_claims_path": "tips-trend-report-claims.json",
  "trend_report_mode": "strategic-themes or catalog",
  "trend_report_theme_count": "N or null",
  "trend_report_generated_at": "ISO-8601",
  "insight_summary_path": "tips-insight-summary.md or null",
  "insight_summary_arc": "trend-panorama or null"
}
```

#### Step 4.2: Display Summary

**Theme mode:**

```
Trend Report Complete (Strategic Themes)
────────────────────────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Mode:         Strategic themes ({N} themes from value model)
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json
Insight:      {PROJECT_PATH}/tips-insight-summary.md (or "skipped")
Trends:       60 across {N} themes ({orphan_count} emerging signals)
Claims:       {total_claims} quantitative claims extracted
Verification: {verdict or "skipped"}

Recommended next steps:
  1. export-html-report — Generate interactive HTML report
  2. export-pdf-report — Generate formal PDF report
  3. cogni-claims:claim-work — Verify claims (if skipped)

Use /resume-tips in your next session to pick up where you left off.
```

**Catalog mode:**

```
Trend Report Complete (Dimensional Catalog)
───────────────────────────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Mode:         Dimensional catalog (no value model)
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json
Insight:      {PROJECT_PATH}/tips-insight-summary.md (or "skipped")
Trends:       60 across 4 dimensions
Claims:       {total_claims} quantitative claims extracted
Verification: {verdict or "skipped"}

Recommended next steps:
  1. value-modeler — Build strategic themes for a theme-organized report
  2. export-html-report — Generate interactive HTML report
  3. export-pdf-report — Generate formal PDF report
  4. cogni-claims:claim-work — Verify claims (if skipped)

Use /resume-tips in your next session to pick up where you left off.
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `trend-scout-output.json` missing | HALT: Run trend-scout first |
| `workflow_state != "agreed"` | HALT: Complete candidate selection |
| `tips_candidates.total < 60` | HALT: Expected 60 candidates |
| `tips-value-model.json` missing or no themes | WARNING: use catalog mode (not an error) |
| `tips-value-model.json` has themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| No raw signals file (both sources) | WARNING: proceed without signals (~120 searches) |
| Agent returns `ok: false` | Retry once, then HALT with dimension name |
| All 4 agents fail | HALT: Check web access is enabled |
| enriched-trends JSON missing (theme mode) | Fall back to catalog mode |
| Theme references unknown candidate_ref | WARNING: skip that candidate in theme narrative |
| `cogni-narrative` not installed | WARNING: skip insight summary |
| `cogni-claims` not installed | WARNING: skip verification |
| claim-work returns FAIL | Present failed claims. Do not auto-correct. |

## Integration

**Upstream:**
- `trend-scout` produces `trend-scout-output.json` (required)
- `value-modeler` produces `tips-value-model.json` (optional, enables theme mode)

**Recommended pipeline:** `trend-scout → value-modeler → trend-report`
Running value-modeler first means the report tells strategic stories organized by investment themes rather than producing a flat trend catalog. Trend-report works without value-modeler but defaults to the less impactful catalog format.

**Downstream:** `export-html-report`, `export-pdf-report`, `cogni-claims:claim-work`

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `report-header.md` — frontmatter + exec summary
- `report-section-{dimension}.md` — dimension sections (4 files, catalog mode assembly)
- `enriched-trends-{dimension}.json` — per-trend evidence blocks (4 files, theme mode assembly)
- `report-theme-{theme_id}.md` — theme sections (theme mode only, 3-7 files)
- `report-emerging-signals.md` — orphan candidates (theme mode only)
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
