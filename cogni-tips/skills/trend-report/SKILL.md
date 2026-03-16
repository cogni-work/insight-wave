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

## Language Support

Full German and English support. This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

**Two language concepts:**

1. **Interaction language** — how the skill communicates with the user (prompts, status, questions). Determined by workspace `.workspace-config.json` language setting. All Phase 0 prompts, status messages, and error messages use this language.
2. **Output language** — what language the report is written in. Default priority: (1) trend-scout `project_language`, (2) workspace language, (3) `en`. **Always ask the user** to confirm or override at the start of Phase 0.

Report prose, section headers, and TIPS labels all adapt to the chosen output language. Web searches run bilingually for maximum coverage. German text uses proper umlauts (never ASCII transliterations).

## Prerequisites

- `trend-scout` completed with `execution.workflow_state == "agreed"` and 60 candidates
- `value-modeler` completed with `tips-value-model.json` containing strategic themes
- Web access enabled for evidence enrichment
- Optional: `cogni-narrative` plugin for insight summary (graceful fallback if absent)
- Optional: `cogni-claims` plugin for claim verification
- Optional: `cogni-copywriting` plugin for executive polish (graceful fallback if absent)

## Context Independence

This skill reads ALL required state from project files — it does not depend on prior conversation context. The tips-resume dashboard, earlier questions, and any preceding chat are not inputs to the report pipeline. This means **context compaction is safe and recommended** before starting.

**Before executing Phase 0**, run `/compact` to free working memory. Phase 2 delegates theme section writing to parallel agents (reducing orchestrator context from ~69% to ~25-35%), but the orchestrator still reads the value model and claims files for assembly sections. Compacting early ensures headroom.

If `/compact` is unavailable (e.g., non-interactive mode), proceed without it — Phase 2's agent-based architecture is designed to stay within context limits.

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-tips` |
| `PROJECT_AGENTS_OPS_ROOT` | Workspace root where projects live (optional, set by cogni-workspace) | User's workspace directory |

`CLAUDE_PLUGIN_ROOT` is injected automatically from `settings.local.json`. `PROJECT_AGENTS_OPS_ROOT` is set by cogni-workspace — if not present, scripts fall back to `$PWD`.

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
| [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md) | Language detection and resolution pattern |
| [$CLAUDE_PLUGIN_ROOT/references/data-model.md]($CLAUDE_PLUGIN_ROOT/references/data-model.md) | Understanding entity schemas and project structure |
| [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) | Assembling the strategic theme report (Phase 2) |
| [references/report-structure.md](references/report-structure.md) | Dimension section templates (written by Phase 1 agents) |
| [references/evidence-enrichment.md](references/evidence-enrichment.md) | Configuring agent web search strategy (Phase 1) |
| [references/claims-format.md](references/claims-format.md) | Extracting/merging claims (Phase 1-2) |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English report headings and labels |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German report headings and labels |
| [references/phase-2.5-insight-summary.md](references/phase-2.5-insight-summary.md) | Generating arc-aware insight summary (Phase 2.5) |
| [references/phase-3-claim-verification.md](references/phase-3-claim-verification.md) | Running claim verification (Phase 3) |
| [references/phase-3.5-executive-polish.md](references/phase-3.5-executive-polish.md) | Polishing report prose (Phase 3.5) |

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

#### Step 0.0: Detect Interaction Language

Read [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md). Detect workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD). Set `INTERACTION_LANGUAGE` — use this for all user-facing messages, prompts, and status updates from this point on.

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
REQUIRED (validate only — do NOT hold candidates or signals in context):
  {PROJECT_PATH}/.metadata/trend-scout-output.json
    → Extract: config.industry, config.research_topic
    → Extract: project_language (top-level, NOT config.language)
    → Validate: tips_candidates.total >= 60, execution.workflow_state == "agreed"
    → Do NOT extract tips_candidates.items — agents read these themselves

REQUIRED (value model — keep in context for Phase 2):
  {PROJECT_PATH}/tips-value-model.json
    → Check: themes[] array exists and has ≥1 entry
    → Extract: themes[], value_chains[], solution_templates[]

NOTE: Raw web signals (web-research-raw.json) are NOT loaded by the orchestrator.
Phase 1 agents read and filter signals themselves — see trend-report-writer agent.
```

Display to the user: `"{PHASE_0_THEMES_FOUND}"` (from i18n labels)

#### Step 0.2b: Extract Phase 2 Value-Model Subset

The full `tips-value-model.json` contains scoring matrices, blueprints, and reanchor logs that Phase 2 does not need. To reduce context pressure, extract only the fields Phase 2 uses and write a pruned subset.

Read `tips-value-model.json` (already loaded in Step 0.2). Write `{PROJECT_PATH}/.logs/phase2-value-model.json` containing ONLY these top-level keys:

```json
{
  "themes": [],
  "value_chains": [],
  "orphan_candidates": [],
  "coverage": {},
  "mece_validation": {},
  "solution_templates": [
    { "st_id": "...", "name": "...", "category": "...", "enabler_type": "...", "theme_ref": "..." }
  ]
}
```

- Copy `themes`, `value_chains`, `orphan_candidates`, `coverage`, `mece_validation` in full
- For each `solution_templates[]` entry, keep ONLY: `st_id`, `name`, `category`, `enabler_type`, `theme_ref` — omit `solution_blueprint`, `portfolio_grounding`, `description`, and all other fields
- Omit all other top-level keys (`reanchor_log`, `solution_process_improvements`, `metrics`, `collaterals`, `portfolio_gaps`, etc.)

#### Step 0.3: Validate Entry Gate

| Check | Condition | On Failure |
|-------|-----------|------------|
| Output exists | `.metadata/trend-scout-output.json` | HALT: Run trend-scout first |
| Workflow state | `== "agreed"` | HALT: Complete trend-scout selection |
| Candidate count | `>= 60` | HALT: Expected 60 agreed candidates |
| Value model exists | `tips-value-model.json` with themes[] | HALT: Run value-modeler first |
| Config complete | industry, subsector, language present | HALT: Incomplete config |

#### Step 0.4: Ask User for Deliverable Language

The `project_language` from trend-scout-output.json is the **default** (falling back to workspace language if not set). Always confirm with the user. Present the question in the `INTERACTION_LANGUAGE`:

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "In welcher Sprache soll der Report erstellt werden? trend-scout hat '{project_language}' verwendet."
  header: "Report-Sprache"
  options:
    - label: "Deutsch (DE) ← Standard"
    - label: "English (EN)"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "Report language? trend-scout used '{project_language}'. Keep or change?"
  header: "Report language"
  options:
    - label: "English (EN) ← Default"
    - label: "Deutsch (DE)"
```

The option matching the current default gets the arrow marker. Set `LANGUAGE` to the user's choice. Update `project_language` in trend-scout-output.json if changed.

#### Step 0.5: Load i18n Labels

Read the labels file matching the chosen language:
- English: [references/i18n/labels-en.md](references/i18n/labels-en.md)
- German: [references/i18n/labels-de.md](references/i18n/labels-de.md)

#### Step 0.6: Clean Up Stale Output Files

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
      "{PROJECT_PATH}/.logs/phase2-value-model.json" \
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
    Labels: {relevant i18n labels}
```

Agents self-load candidates and raw signals from disk using `PROJECT_PATH` — no need to pass data in the prompt. This keeps the orchestrator context lean for Phase 2.

Dimensions: `externe-effekte` (T), `digitale-wertetreiber` (I), `neue-horizonte` (P), `digitales-fundament` (S).

Each agent writes:
- `{PROJECT_PATH}/.logs/report-section-{dimension}.md` — narrative section (dimension-level prose)
- `{PROJECT_PATH}/.logs/claims-{dimension}.json` — extracted claims
- `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` — per-trend evidence blocks keyed by candidate_ref; `actions_md` uses semicolon-separated keywords (used in theme assembly)

#### Step 1.2: Collect Agent Results

Each agent returns compact JSON with `ok`, `dimension`, `trends_covered`, `claims_extracted`, signal reuse metrics, and the three output file paths (`section_file`, `claims_file`, `enriched_file`).

If an agent returns `ok: false`: retry once. If retry also fails: HALT with the dimension name. All 4 must succeed before Phase 2.

#### Step 1.3: Validate Agent Output Files

After all 4 agents complete, verify that all 12 expected files exist:

```
For each dimension in [externe-effekte, digitale-wertetreiber, neue-horizonte, digitales-fundament]:
  ✓ {PROJECT_PATH}/.logs/report-section-{dimension}.md    — narrative section (required for Phase 2.5)
  ✓ {PROJECT_PATH}/.logs/claims-{dimension}.json           — extracted claims
  ✓ {PROJECT_PATH}/.logs/enriched-trends-{dimension}.json  — per-trend evidence blocks (required for Phase 2)
```

If any `report-section-{dimension}.md` file is missing, log a WARNING. Phase 2 can proceed (it uses enriched-trends), but Phase 2.5 will be degraded without the section files.

---

### Phase 2: Report Assembly — THEME-FIRST (NOT BY DIMENSION)

**CRITICAL:** You MUST read [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) before starting Phase 2. The report is organized by **strategic themes** from `tips-value-model.json`, NOT by TIPS dimension. Do NOT simply concatenate the dimension section files from Phase 1 — those are intermediate artifacts for Phase 2.5, not the final report structure.

**EXECUTION — Agent-assisted theme writing + orchestrator assembly.** Phase 2 delegates the context-heavy theme section writing to parallel `trend-report-theme-writer` agents (one per theme), then the orchestrator writes the remaining lightweight sections (executive summary, emerging signals, portfolio, claims registry) and concatenates the final report.

- **Theme sections → agents.** Each theme-writer agent self-loads enriched-trends and claims from disk, filtered to its own candidate_refs. The orchestrator passes only small scalars (theme definition, value chains, labels). This keeps the orchestrator's context lean.
- **No Python scripts.** Do not write scripts to generate report sections. The agents and orchestrator write strategic prose directly.
- **No intermediate analysis steps.** Do not generate lookup documentation or enriched statistics. Agents go straight from reading data to writing prose.

**Summary of steps** (details in the reference):

1. **Read value model** — Read `.logs/phase2-value-model.json` for themes, value chains, solution templates, orphan candidates, coverage data
2. **Dispatch theme agents** — For each theme, dispatch a `cogni-tips:trend-report-theme-writer` agent. All agents in a single message (parallel). Each agent self-loads evidence from disk, writes `report-theme-{theme_id}.md`, and returns compact JSON with word count, citation count, quality gate status, and top claims.
3. **Write executive summary** — Using value model themes + agent-returned `top_claims` for headline evidence, write `report-header.md`
4. **Write emerging signals** — Using orphan candidates from value model + filtered enriched-trends evidence, write `report-emerging-signals.md`
5. **Collect agent results** — Validate all agents returned `ok: true` and quality gates passed. Retry once on failure.
6. **Write portfolio view** — Using value model + agent-reported counts, write `report-portfolio.md`
7. **Write claims registry** — Read 4 `claims-{dimension}.json` files once, map claims to themes via value model, write `report-claims-registry.md`
8. **Assemble** — Concatenate with cat: header + themes (ordered) + emerging signals + portfolio + claims → `tips-trend-report.md`
9. **Merge claims** → `tips-trend-report-claims.json`

**Resume logic:** Before dispatching an agent for a theme, check if `report-theme-{theme_id}.md` already exists and is >1000 bytes. If so, skip that agent — display `"{PHASE_2_THEME_AGENT_SKIP_RESUME}"` and continue. This means re-runs only dispatch for missing themes.

---

### Phase 2.5: Insight Summary (trend-panorama) — DEFAULT ON

**This phase runs by default.** Only skip if the user explicitly requests it (e.g., "skip insight summary", "skip narrative"). If the user said "skip verification and copywriting", that does NOT mean skip Phase 2.5 — those are separate phases (3 and 3.5).

Read [references/phase-2.5-insight-summary.md](references/phase-2.5-insight-summary.md) for the full workflow.

Verify `tips-trend-report.md` exists and that the 4 dimension section files (`report-section-{dimension}.md`) exist in `.logs/`, then invoke `cogni-narrative:narrative` skill with arc_id `trend-panorama`. This arc maps TIPS dimensions to narrative elements (Forces → Impact → Horizons → Foundations).

All failures in this phase are non-blocking — the insight summary enhances the report but isn't required for downstream consumers.

---

### Phase 3: Claim Verification (Optional)

Read [references/phase-3-claim-verification.md](references/phase-3-claim-verification.md) for the full workflow. Asks the user whether to verify extracted claims via `cogni-claims:claim-work`. If the plugin is not installed, skip with a warning.

---

### Phase 3.5: Executive Polish via cogni-copywriting (Optional)

Read [references/phase-3.5-executive-polish.md](references/phase-3.5-executive-polish.md) for the full workflow. Polishes report prose via `cogni-copywriting:copywriter` with `SCOPE=tone`. Validates citations and structure are preserved; reverts on failure.

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
| Phase 1 agent returns `ok: false` | Retry once, then HALT with dimension name |
| All 4 Phase 1 agents fail | HALT: Check web access is enabled |
| enriched-trends JSON missing | HALT: Phase 1 agent failed to produce enriched output |
| Theme agent returns `ok: false` | Retry once, then HALT with theme name |
| Theme agent quality gate fails | WARNING: continue (section written but may be thin) |
| Theme references unknown candidate_ref | WARNING: agent skips that candidate in theme narrative |
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

**Optional cross-plugin:** `cogni-narrative:narrative` skill (Phase 2.5), `cogni-claims:claim-work` (Phase 3), `cogni-copywriting:copywriter` (Phase 3.5)

**Downstream:** `export-html-report`, `export-pdf-report`

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `report-header.md` — frontmatter + exec summary
- `report-section-{dimension}.md` — dimension sections (4 files, written by agents)
- `phase2-value-model.json` — pruned value-model subset for Phase 2
- `enriched-trends-{dimension}.json` — per-trend evidence blocks (4 files, used in theme assembly)
- `report-theme-{theme_id}.md` — theme sections (3-7 files, written by theme agents)
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
| Phase 1 agent hangs | Verify web access is enabled |
| Theme agent hangs | Check enriched-trends files exist in .logs/ |
| Empty claims | Check if trends have quantitative data in trend-scout output |
| Wrong language | Verify `project_language` in trend-scout-output.json |
| Missing sections | Check `.logs/` for partial agent output |
