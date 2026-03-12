---
name: trend-report
description: |
  Generate a strategic TIPS trend report organized around investment themes with inline citations and verifiable claims. Produces a theme-first report where 3-7 strategic themes drive the narrative — each theme tells a CxO-level investment story backed by T→I→P value chain evidence. Reads agreed trend candidates, enriches each with web-sourced quantitative evidence via parallel agents, assembles the report with strategic executive summary and portfolio analysis, generates a trend-panorama insight summary via cogni-narrative, invokes cogni-claims:claim-work for automated verification, and polishes the final prose for executive readability via cogni-copywriting. Required pipeline: trend-scout → value-modeler → trend-report. Use when: (1) trend-scout and value-modeler have completed, (2) user wants a written trend report, (3) user mentions "trend report", "TIPS report", "write up trends", "summarize trends", "trend analysis document", "strategic stories", (4) preparing a deliverable from scouted trends, (5) user asks to "generate report from trends" or "create trend deliverable". Always use this skill when trend-scout output exists and the user wants any kind of written trend analysis — even if they don't use the exact phrase "trend report".
---

# Trend Report

Generate a strategic TIPS trend report from agreed trend-scout candidates. Organizes the report around strategic investment themes — each theme tells a CxO-level story backed by T→I→P value chain evidence. Dispatches 4 parallel agents to enrich trends with web-sourced quantitative evidence, then assembles a theme-first strategic report with executive summary, portfolio analysis, and claims registry.

## Purpose

Transform agreed trend-scout candidates into a strategic, evidence-backed report:

1. Load value-modeler strategic themes and validate prerequisites
2. Enrich each trend with quantitative evidence from web research
3. Assemble theme narratives with embedded evidence
4. Generate inline citations for every quantitative claim
5. Produce a claims registry compatible with `cogni-claims:claim-work`
6. Generate a trend-panorama narrative insight summary via cogni-narrative
7. Optionally verify claims via cogni-claims:claim-work
8. Polish report prose for executive readability via cogni-copywriting

## Bilingual Support

Full German and English support. **Always ask the user** for the deliverable language (DE or EN) at the start of Phase 0 — do not silently inherit from `trend-scout-output.json`. Default priority for pre-filling: (1) trend-scout `project_language` from output JSON, (2) workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD), (3) `en`. User must always confirm or override. Report prose, section headers, and TIPS labels all adapt to the chosen language. Web searches run bilingually for maximum coverage. German text uses proper umlauts (never ASCII transliterations).

## Prerequisites

- `trend-scout` completed with `execution.workflow_state == "agreed"` and 60 candidates
- `value-modeler` completed with `tips-value-model.json` containing strategic themes
- Web access enabled for evidence enrichment
- Optional: `cogni-narrative` plugin for insight summary (graceful fallback if absent)
- Optional: `cogni-claims` plugin for claim verification
- Optional: `cogni-copywriting` plugin for executive polish (graceful fallback if absent)

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
| [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) | Assembling the strategic theme report (Phase 2) |
| [references/report-structure.md](references/report-structure.md) | Dimension section templates (written by Phase 1 agents) |
| [references/evidence-enrichment.md](references/evidence-enrichment.md) | Configuring agent web search strategy (Phase 1) |
| [references/claims-format.md](references/claims-format.md) | Extracting/merging claims (Phase 1-2) |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English report headings and labels |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German report headings and labels |
| [references/phase-2.5-insight-summary.md](references/phase-2.5-insight-summary.md) | Generating arc-aware insight summary (Phase 2.5) |

## Workflow Overview

Track progress through these phases as you go:

```text
Phase 0 → Phase 1 → Phase 2 → Phase 2.5 → Phase 3 → Phase 3.5 → Phase 4
   │          │          │         │            │          │           │
   │          │          │         │            │          │           └─ Update metadata, display summary
   │          │          │         │            │          └─ Executive polish via cogni-copywriting
   │          │          │         │            └─ Optional claim-work verification
   │          │          │         └─ trend-panorama narrative via cogni-narrative
   │          │          └─ Strategic theme narratives + evidence weaving
   │          └─ 4 parallel agents: enrich trends, write sections + enriched JSONs, extract claims
   └─ Project discovery, load trend-scout + value-modeler output, validate gate
```

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

REQUIRED (value model):
  {PROJECT_PATH}/tips-value-model.json
    → Check: themes[] array exists and has ≥1 entry
    → Extract: themes[], value_chains[], solution_templates[]

OPTIONAL (raw web signals — try in order):
  1. {PROJECT_PATH}/.logs/web-research-raw.json
     → .raw_signals_before_dedup array (full field names)
  2. FALLBACK: {PROJECT_PATH}/phase1-research-summary.json
     → .items array (abbreviated fields: d→dimension, n→signal, k→keywords, u→source, f→freshness, a→authority, t→source_type, i→indicator_type, lt→lead_time)
```

Display to the user: `"{PHASE_0_THEMES_FOUND}"` (from i18n labels)

#### Step 0.3: Validate Entry Gate

| Check | Condition | On Failure |
|-------|-----------|------------|
| Output exists | `.metadata/trend-scout-output.json` | HALT: Run trend-scout first |
| Workflow state | `== "agreed"` | HALT: Complete trend-scout selection |
| Candidate count | `>= 60` | HALT: Expected 60 agreed candidates |
| Value model exists | `tips-value-model.json` with themes[] | HALT: Run value-modeler first |
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
- `{PROJECT_PATH}/.logs/report-section-{dimension}.md` — narrative section (dimension-level prose)
- `{PROJECT_PATH}/.logs/claims-{dimension}.json` — extracted claims
- `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` — per-trend evidence blocks keyed by candidate_ref (used in theme assembly)

#### Step 1.2: Collect Agent Results

Each agent returns compact JSON with `ok`, `dimension`, `trends_covered`, `claims_extracted`, signal reuse metrics, and the three output file paths (`section_file`, `claims_file`, `enriched_file`).

If an agent returns `ok: false`: retry once. If retry also fails: HALT with the dimension name. All 4 must succeed before Phase 2.

---

### Phase 2: Report Assembly

Read [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) for the full workflow.

Assembles the report around strategic themes from the value model. Individual trends become evidence woven into each theme's strategic narrative. The report reads as a strategy document with 3-7 investment themes, not a catalog of 60 trends.

**Summary of steps** (details in the reference):

1. **Build lookups** — Read 4 `enriched-trends-{dimension}.json` + 4 `claims-{dimension}.json` → candidate_ref and claim_id lookups
2. **Strategic executive summary** — Theme overview table, headline evidence, strategic posture → `report-header.md`
3. **Theme sections** — One per theme with investment thesis, value chain walkthroughs, solution templates, strategic actions → `report-theme-{theme_id}.md`
4. **Emerging signals** — Orphan candidates not in any theme → `report-emerging-signals.md`
5. **Strategic portfolio view** — Theme-level metrics, horizon distribution, MECE validation → `report-portfolio.md`
6. **Claims registry** — All claims with theme column → `report-claims-registry.md`
7. **Assemble** — Concatenate: header + themes (ordered) + emerging signals + portfolio + claims → `tips-trend-report.md`
8. **Merge claims** → `tips-trend-report-claims.json`

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

### Phase 3.5: Executive Polish via cogni-copywriting

Polish the assembled trend report for executive readability. Runs after claim verification so citations and claim references remain stable during extraction and verification. The copywriter preserves all inline citations, German characters, and protected content (diagram placeholders, figure references, kanban tables).

#### Step 3.5.1: Check Availability

If `cogni-copywriting` plugin is not installed, display a warning and skip to Phase 4 — do not halt.

#### Step 3.5.2: Invoke Copywriter

```yaml
Skill:
  skill: "cogni-copywriting:copywriter"
  args: "FILE_PATH={PROJECT_PATH}/tips-trend-report.md SCOPE=tone STAKEHOLDERS=executive REVIEW_MODE=automated"
```

**Parameter choices:**
- `SCOPE=tone` — the report structure is already defined by the theme assembly (Phase 2). Only polish prose clarity, paragraph flow, bold anchoring, and sentence rhythm. Do not restructure sections or reorder themes.
- `STAKEHOLDERS=executive` — the primary audience is CxO-level decision makers.
- `REVIEW_MODE=automated` — lightweight review pass without interactive feedback.

#### Step 3.5.3: Validate Output

After the copywriter returns:

| Check | Condition | On Failure |
|-------|-----------|------------|
| Citation count | polished >= original | REVERT: restore from `.tips-trend-report.md` backup |
| Frontmatter intact | YAML frontmatter unchanged | REVERT |
| Theme structure | Same H2/H3 heading count and text | REVERT |
| Claims registry | Claims table rows unchanged | REVERT |

If any check fails, revert to the backup the copywriter created (`.tips-trend-report.md` in the same directory) and log the failure reason. Partial polish failure does not block Phase 4.

#### Step 3.5.4: Update Metadata

If polish succeeded, note it for the finalization summary:

```json
{ "copywriter_applied": true, "copywriter_scope": "tone" }
```

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
  "trend_report_mode": "strategic-themes",
  "trend_report_theme_count": N,
  "trend_report_generated_at": "ISO-8601",
  "insight_summary_path": "tips-insight-summary.md or null",
  "insight_summary_arc": "trend-panorama or null",
  "copywriter_applied": true,
  "copywriter_scope": "tone or null"
}
```

#### Step 4.2: Display Summary

```
Trend Report Complete (Strategic Themes)
────────────────────────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Themes:       {N} strategic themes from value model
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json
Insight:      {PROJECT_PATH}/tips-insight-summary.md (or "skipped")
Trends:       60 across {N} themes ({orphan_count} emerging signals)
Claims:       {total_claims} quantitative claims extracted
Verification: {verdict or "skipped"}
Polish:       {copywriter_applied ? "tone (cogni-copywriting)" : "skipped"}

Recommended next steps:
  1. export-html-report — Generate interactive HTML report
  2. export-pdf-report — Generate formal PDF report
  3. cogni-claims:claim-work — Verify claims (if skipped)

Use /tips-resume in your next session to pick up where you left off.
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `trend-scout-output.json` missing | HALT: Run trend-scout first |
| `workflow_state != "agreed"` | HALT: Complete candidate selection |
| `tips_candidates.total < 60` | HALT: Expected 60 candidates |
| `tips-value-model.json` missing or no themes | HALT: Run value-modeler first |
| `tips-value-model.json` has themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| No raw signals file (both sources) | WARNING: proceed without signals (~120 searches) |
| Agent returns `ok: false` | Retry once, then HALT with dimension name |
| All 4 agents fail | HALT: Check web access is enabled |
| enriched-trends JSON missing | HALT: Phase 1 agent failed to produce enriched output |
| Theme references unknown candidate_ref | WARNING: skip that candidate in theme narrative |
| `cogni-narrative` not installed | WARNING: skip insight summary |
| `cogni-claims` not installed | WARNING: skip verification |
| claim-work returns FAIL | Present failed claims. Do not auto-correct. |
| `cogni-copywriting` not installed | WARNING: skip executive polish |
| Copywriter drops citations | REVERT to backup, log failure, continue to Phase 4 |
| Copywriter alters headings/structure | REVERT to backup, log failure, continue to Phase 4 |

## Integration

**Upstream:**
- `trend-scout` produces `trend-scout-output.json` (required)
- `value-modeler` produces `tips-value-model.json` (required)

**Pipeline:** `trend-scout → value-modeler → trend-report`

**Optional cross-plugin:** `cogni-narrative:narrative-writer` (Phase 2.5), `cogni-claims:claim-work` (Phase 3), `cogni-copywriting:copywriter` (Phase 3.5)

**Downstream:** `export-html-report`, `export-pdf-report`

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `report-header.md` — frontmatter + exec summary
- `report-section-{dimension}.md` — dimension sections (4 files, written by agents)
- `enriched-trends-{dimension}.json` — per-trend evidence blocks (4 files, used in theme assembly)
- `report-theme-{theme_id}.md` — theme sections (3-7 files)
- `report-emerging-signals.md` — orphan candidates
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
