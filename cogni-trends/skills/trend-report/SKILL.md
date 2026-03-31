---
name: trend-report
description: |
  Generate a strategic TIPS trend report organized around investment themes (Handlungsfelder) with inline citations and verifiable claims. The user selects a report-level narrative arc from cogni-narrative's 7 story arcs (corporate-visions, technology-futures, competitive-intelligence, strategic-foresight, industry-transformation, trend-panorama, theme-thesis) — the arc frames the executive summary, bridge paragraphs between themes, and a synthesis closing section that bind investment themes into one cohesive narrative. Each investment theme internally uses the theme-thesis arc (Why Change → Why Now → Why You → Why Pay) backed by T→I→P→S value chain evidence. Reads agreed trend candidates, enriches each with web-sourced quantitative evidence via parallel agents, assembles the report with arc-framed executive summary, bridge paragraphs, theme sections, synthesis section, and claims registry. Invokes cogni-claims:claim-work for automated verification and polishes the final prose via cogni-copywriting. Required pipeline: trend-scout → value-modeler → trend-report. Use when: (1) trend-scout and value-modeler have completed, (2) user wants a written trend report, (3) user mentions "trend report", "TIPS report", "write up trends", "summarize trends", "trend analysis document", "strategic stories", (4) preparing a deliverable from scouted trends, (5) user asks to "generate report from trends" or "create trend deliverable". Always use this skill when trend-scout output exists and the user wants any kind of written trend analysis — even if they don't use the exact phrase "trend report".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, Skill
---

# Trend Report

Generate a strategic TIPS trend report from agreed trend-scout candidates. Organizes the report around investment themes — each investment theme tells a CxO-level story backed by T→I→P value chain evidence. Dispatches 4 parallel agents to enrich trends with web-sourced quantitative evidence, then assembles a theme-first strategic report with executive summary and claims registry.

## Purpose

Transform agreed trend-scout candidates into a strategic, evidence-backed report:

1. Load value-modeler investment themes and validate prerequisites
2. User selects a report-level narrative arc (from cogni-narrative's 7 arcs) to frame the overall story
3. Enrich each trend with quantitative evidence from web research
4. Assemble investment theme narratives using theme-thesis arc (Why Change → Why Now → Why You → Why Pay) with embedded evidence
5. Generate arc-framed executive summary, bridge paragraphs between themes, and synthesis closing section
6. Generate inline citations for every quantitative claim
7. Produce a claims registry compatible with `cogni-claims:claim-work`
8. Optionally verify claims via cogni-claims:claim-work
9. Polish report prose for executive readability via cogni-copywriting
10. Optionally generate themed HTML with interactive charts and diagrams via cogni-visual:enrich-report

## Language Support

Full German and English support. This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

**Two language concepts:**

1. **Interaction language** — how the skill communicates with the user (prompts, status, questions). Determined by workspace `.workspace-config.json` language setting. All Phase 0 prompts, status messages, and error messages use this language.
2. **Output language** — what language the report is written in. Default priority: (1) trend-scout `project_language`, (2) workspace language, (3) `en`. **Always ask the user** to confirm or override at the start of Phase 0.

Report prose, section headers, and TIPS labels all adapt to the chosen output language. Web searches run bilingually for maximum coverage. German text uses proper umlauts (never ASCII transliterations).

## Prerequisites

- `trend-scout` completed with `execution.workflow_state == "agreed"` and 60 candidates
- `value-modeler` completed with `tips-value-model.json` containing investment themes
- Web access enabled for evidence enrichment
- Optional: `cogni-narrative` plugin for theme-thesis arc guidance (graceful fallback if absent — investment themes use flat structure)
- Optional: `cogni-claims` plugin for claim verification
- Optional: `cogni-copywriting` plugin for executive polish (graceful fallback if absent)

## Context Independence

This skill reads ALL required state from project files — it does not depend on prior conversation context. The trends-resume dashboard, earlier questions, and any preceding chat are not inputs to the report pipeline. This means **context compaction is safe and recommended** before starting.

**Before executing Phase 0**, run `/compact` to free working memory. Phase 2 delegates investment theme section writing to parallel agents (reducing orchestrator context from ~69% to ~25-35%), but the orchestrator still reads the value model and claims files for assembly sections. Compacting early ensures headroom.

If `/compact` is unavailable (e.g., non-interactive mode), proceed without it — Phase 2's agent-based architecture is designed to stay within context limits.

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-trends` |
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
| [references/report-arc-frames.md](references/report-arc-frames.md) | Arc-specific framing templates for exec summary, bridges, synthesis (Phase 0.4b + Phase 2) |
| [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) | Assembling the investment theme report (Phase 2) |
| [references/report-structure.md](references/report-structure.md) | Dimension section templates (written by Phase 1 agents) |
| [references/evidence-enrichment.md](references/evidence-enrichment.md) | Configuring agent web search strategy (Phase 1) |
| [references/claims-format.md](references/claims-format.md) | Extracting/merging claims (Phase 1-2) |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English report headings and labels |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German report headings and labels |
| [references/phase-3-claim-verification.md](references/phase-3-claim-verification.md) | Running claim verification (Phase 3) |
| [references/phase-3.5-executive-polish.md](references/phase-3.5-executive-polish.md) | Polishing report prose (Phase 3.5) |

## Workflow Overview

Track progress through these phases as you go:

```text
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 3.5 → Phase 4
   │          │          │         │          │           │
   │          │          │         │          │           └─ Update metadata, display summary
   │          │          │         │          └─ Executive polish via cogni-copywriting
   │          │          │         └─ Optional claim-work verification
   │          │          └─ Theme narratives + arc-framed exec summary + bridges + synthesis
   │          └─ 4 parallel agents: enrich trends, write sections + enriched JSONs, extract claims
   └─ Project discovery, arc selection, load trend-scout + value-modeler output, validate gate
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
    → Extract: config.market_region (default: "dach" if absent — older projects pre-regionalization)
    → Extract: project_language (top-level, NOT config.language)
    → Validate: tips_candidates.total >= 60, execution.workflow_state == "agreed"
    → Do NOT extract tips_candidates.items — agents read these themselves

REQUIRED (value model — keep in context for Phase 2):
  {PROJECT_PATH}/tips-value-model.json
    → Check: investment_themes[] array exists and has ≥1 entry
    → Extract: investment_themes[], value_chains[], solution_templates[]

NOTE: Raw web signals (web-research-raw.json) are NOT loaded by the orchestrator.
Phase 1 agents read and filter signals themselves — see trend-report-writer agent.
```

Display to the user: `"{PHASE_0_INVESTMENT_THEMES_FOUND}"` (from i18n labels)

#### Step 0.2b: Extract Phase 2 Value-Model Subset

The full `tips-value-model.json` contains scoring matrices, blueprints, and reanchor logs that Phase 2 does not need. To reduce context pressure, extract only the fields Phase 2 uses and write a pruned subset.

Read `tips-value-model.json` (already loaded in Step 0.2). Write `{PROJECT_PATH}/.logs/phase2-value-model.json` containing ONLY these top-level keys:

```json
{
  "investment_themes": [],
  "value_chains": [],
  "orphan_candidates": [],
  "coverage": {},
  "mece_validation": {},
  "solution_templates": [
    { "st_id": "...", "name": "...", "category": "...", "enabler_type": "...", "investment_theme_ref": "...", "portfolio_grounding": [...] }
  ]
}
```

- Copy `investment_themes`, `value_chains`, `orphan_candidates`, `coverage`, `mece_validation` in full
- For each `solution_templates[]` entry, keep ONLY: `st_id`, `name`, `category`, `enabler_type`, `investment_theme_ref`, `portfolio_grounding` — omit `solution_blueprint`, `description`, and all other fields. `portfolio_grounding` is needed for Phase 2 portfolio close (product names and links)
- Omit all other top-level keys (`reanchor_log`, `solution_process_improvements`, `metrics`, `collaterals`, `portfolio_gaps`, etc.)

#### Step 0.3: Validate Entry Gate

| Check | Condition | On Failure |
|-------|-----------|------------|
| Output exists | `.metadata/trend-scout-output.json` | HALT: Run trend-scout first |
| Workflow state | `== "agreed"` | HALT: Complete trend-scout selection |
| Candidate count | `>= 60` | HALT: Expected 60 agreed candidates |
| Value model exists | `tips-value-model.json` with investment_themes[] | HALT: Run value-modeler first |
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

#### Step 0.4b: Select Report-Level Narrative Arc

Read [references/report-arc-frames.md](references/report-arc-frames.md) for the full arc frame definitions.

The report-level arc determines how investment themes connect into one cohesive narrative — the executive summary voice, bridge paragraphs between themes, and the synthesis closing section. It does NOT change how individual theme sections are written internally (those always use the `theme-thesis` arc).

Present the 7 available arcs via `AskUserQuestion`. The recommended default is `corporate-visions` (the proven B2B persuasion frame). Auto-detect a different recommendation if the topic strongly signals another arc (e.g., heavily regulatory topics → `industry-transformation`).

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_ARC_QUESTION}"
  header: "{PHASE_0_ARC_HEADER}"
  options:
    - label: "{ARC_CORPORATE_VISIONS}"
      description: "{ARC_CORPORATE_VISIONS_DESC}"
    - label: "{ARC_TECHNOLOGY_FUTURES}"
      description: "{ARC_TECHNOLOGY_FUTURES_DESC}"
    - label: "{ARC_INDUSTRY_TRANSFORMATION}"
      description: "{ARC_INDUSTRY_TRANSFORMATION_DESC}"
    - label: "{ARC_STRATEGIC_FORESIGHT}"
      description: "{ARC_STRATEGIC_FORESIGHT_DESC}"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_ARC_QUESTION}"
  header: "{PHASE_0_ARC_HEADER}"
  options:
    - label: "{ARC_CORPORATE_VISIONS}"
      description: "{ARC_CORPORATE_VISIONS_DESC}"
    - label: "{ARC_TECHNOLOGY_FUTURES}"
      description: "{ARC_TECHNOLOGY_FUTURES_DESC}"
    - label: "{ARC_INDUSTRY_TRANSFORMATION}"
      description: "{ARC_INDUSTRY_TRANSFORMATION_DESC}"
    - label: "{ARC_STRATEGIC_FORESIGHT}"
      description: "{ARC_STRATEGIC_FORESIGHT_DESC}"
```

> **AskUserQuestion limit:** The picker supports max 4 options. Present the 4 most relevant arcs based on the topic. The recommended arc is always first (with arrow marker). If the user selects "Other", show the remaining 3 arcs (`competitive-intelligence`, `trend-panorama`, `theme-thesis`) in a follow-up question.

Set `REPORT_ARC_ID` to the user's choice (e.g., `corporate-visions`, `technology-futures`). This variable is passed to Phase 2 for arc-aware assembly.

#### Step 0.5: Load i18n Labels

Read the labels file matching the chosen language:
- English: [references/i18n/labels-en.md](references/i18n/labels-en.md)
- German: [references/i18n/labels-de.md](references/i18n/labels-de.md)

#### Step 0.6: Clean Up Stale Output Files

On re-runs, remove stale files to prevent mixing old and new content:

```bash
rm -f "{PROJECT_PATH}/.logs/report-header.md" \
      "{PROJECT_PATH}/.logs/report-section-"*.md \
      "{PROJECT_PATH}/.logs/report-investment-theme-"*.md \
      "{PROJECT_PATH}/.logs/report-bridge-"*.md \
      "{PROJECT_PATH}/.logs/report-synthesis.md" \
      "{PROJECT_PATH}/.logs/enriched-trends-"*.json \
      "{PROJECT_PATH}/.logs/claims-"*.json \
      "{PROJECT_PATH}/.logs/report-claims-registry.md" \
      "{PROJECT_PATH}/tips-trend-report.md" \
      "{PROJECT_PATH}/.logs/phase2-value-model.json" \
      "{PROJECT_PATH}/tips-trend-report-claims.json" \
      "{PROJECT_PATH}/tips-insight-summary.md"
```

---

### Phase 1: Evidence Enrichment + Section Generation (PARALLEL)

Read [references/evidence-enrichment.md](references/evidence-enrichment.md) for web search strategy.
Read [references/claims-format.md](references/claims-format.md) for claims extraction schema.

#### Step 1.1: Dispatch 4 Agents

Dispatch all 4 agents in a single message (parallel tool calls) so they run concurrently:

```yaml
Per agent:
  subagent_type: "cogni-trends:trend-report-writer"
  model: sonnet
  prompt: |
    Dimension: {DIMENSION}
    TIPS Role: {TIPS_ROLE}
    Project Path: {PROJECT_PATH}
    Language: {LANGUAGE}
    Market Region: {MARKET_REGION}
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
- `{PROJECT_PATH}/.logs/enriched-trends-{dimension}.json` — per-trend evidence blocks keyed by candidate_ref; `actions_md` uses semicolon-separated keywords (used in investment theme assembly)

#### Step 1.2: Collect Agent Results

Each agent returns compact JSON with `ok`, `dimension`, `trends_covered`, `claims_extracted`, signal reuse metrics, and the three output file paths (`section_file`, `claims_file`, `enriched_file`).

If an agent returns `ok: false`: retry once. If retry also fails: HALT with the dimension name. All 4 must succeed before Phase 2.

#### Step 1.3: Validate Agent Output Files

After all 4 agents complete, verify that all 12 expected files exist:

```
For each dimension in [externe-effekte, digitale-wertetreiber, neue-horizonte, digitales-fundament]:
  ✓ {PROJECT_PATH}/.logs/report-section-{dimension}.md    — narrative section (intermediate artifact)
  ✓ {PROJECT_PATH}/.logs/claims-{dimension}.json           — extracted claims
  ✓ {PROJECT_PATH}/.logs/enriched-trends-{dimension}.json  — per-trend evidence blocks (required for Phase 2)
```

If any `report-section-{dimension}.md` file is missing, log a WARNING. Phase 2 can proceed (it uses enriched-trends).

---

### Phase 2: Report Assembly — THEME-FIRST (NOT BY DIMENSION)

**CRITICAL:** You MUST read [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) before starting Phase 2. The report is organized by **investment themes** from `tips-value-model.json`, NOT by TIPS dimension. Do NOT simply concatenate the dimension section files from Phase 1 — those are intermediate artifacts, not the final report structure.

**EXECUTION — Agent-assisted investment theme writing + orchestrator assembly.** Phase 2 delegates the context-heavy investment theme section writing to parallel `trend-report-investment-theme-writer` agents (one per investment theme), then the orchestrator writes the remaining lightweight sections (executive summary, claims registry) and concatenates the final report.

- **Investment theme sections → agents.** Each investment-theme-writer agent self-loads enriched-trends and claims from disk, filtered to its own candidate_refs. The orchestrator passes only small scalars (investment theme definition, value chains, labels). This keeps the orchestrator's context lean.
- **No Python scripts.** Do not write scripts to generate report sections. The agents and orchestrator write strategic prose directly.
- **No intermediate analysis steps.** Do not generate lookup documentation or enriched statistics. Agents go straight from reading data to writing prose.

**Summary of steps** (details in the reference):

1. **Read value model** — Read `.logs/phase2-value-model.json` for investment themes, value chains, solution templates, orphan candidates, coverage data
2. **Dispatch investment theme agents** — For each investment theme, dispatch a `cogni-trends:trend-report-investment-theme-writer` agent with `MARKET_REGION: {MARKET_REGION}` and `REPORT_ARC_ID: {REPORT_ARC_ID}` in the prompt. All agents in a single message (parallel). Each agent self-loads evidence from disk, writes `report-investment-theme-{investment_theme_id}.md`, and returns compact JSON with word count, citation count, quality gate status, and top claims.
3. **Collect agent results** — Validate all agents returned `ok: true` and quality gates passed. Retry once on failure.
4. **Write executive summary** — Read ALL `report-investment-theme-{investment_theme_id}.md` files. Use `REPORT_ARC_ID` to select the arc-specific opener and closer patterns from `report-arc-frames.md`. Write `report-header.md`.
5. **Write bridge paragraphs** — For each consecutive theme pair, generate a 2-4 sentence bridge using the arc's bridge pattern. Write `report-bridge-{N}-{N+1}.md` files.
6. **Write synthesis section** — Generate a 300-500 word closing section using the arc's synthesis frame. Aggregates evidence across all themes. Write `report-synthesis.md`.
7. **Write claims registry** — Read 4 `claims-{dimension}.json` files once, map claims to investment themes via value model, write `report-claims-registry.md`
8. **Assemble** — Concatenate: header + (theme1 + bridge-1-2 + theme2 + bridge-2-3 + ... + themeN) + synthesis + claims → `tips-trend-report.md`
9. **Merge claims** → `tips-trend-report-claims.json`

**Resume logic:** Before dispatching an agent for an investment theme, check if `report-investment-theme-{investment_theme_id}.md` already exists and is >1000 bytes. If so, skip that agent — display `"{PHASE_2_INVESTMENT_THEME_AGENT_SKIP_RESUME}"` and continue. This means re-runs only dispatch for missing investment themes.

---

### Phase 3: Claim Verification (Optional)

Read [references/phase-3-claim-verification.md](references/phase-3-claim-verification.md) for the full workflow. Asks the user whether to verify extracted claims via `cogni-claims:claim-work`. If the plugin is not installed, skip with a warning.

---

### Phase 3.5: Executive Polish via cogni-copywriting (Optional)

Read [references/phase-3.5-executive-polish.md](references/phase-3.5-executive-polish.md) for the full workflow. Polishes report prose via `cogni-copywriting:copywriter` with `SCOPE=tone`. Validates citations and structure are preserved; reverts on failure.

---

### Phase 3.7: Visual Enrichment via cogni-visual (Optional)

Ask the user whether to generate a themed HTML version of the report with interactive charts and diagrams. This transforms the markdown report into a polished, presentation-ready HTML deliverable.

1. Check whether `cogni-visual:enrich-report` is available. If not installed, display a warning and skip to Phase 4.
2. Ask the user: `"Generate themed HTML with interactive charts and diagrams? (cogni-visual:enrich-report)"`
3. If the user declines, skip to Phase 4.
4. If yes, invoke the `cogni-visual:enrich-report` skill with `source_path` pointing to `{PROJECT_PATH}/tips-trend-report.md`. The enrich-report skill handles theme selection, enrichment planning, and interactive review — do not duplicate that logic here.
5. Record the result for the Phase 4 summary.

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
  "trend_report_investment_theme_count": N,
  "trend_report_generated_at": "ISO-8601",
  "copywriter_applied": true,
  "copywriter_scope": "tone or null",
  "enrich_report_applied": true,
  "enrich_report_path": "output/tips-trend-report-enriched.html or null"
}
```

#### Step 4.2: Display Summary

```
Trend Report Complete (Investment Themes)
─────────────────────────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Themes:       {N} investment themes (Corporate Visions arc)
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json
Trends:       60 across {N} investment themes
Claims:       {total_claims} quantitative claims extracted
Verification: {verdict or "skipped"}
Polish:       {copywriter_applied ? "tone (cogni-copywriting)" : "skipped"}
Enrichment:   {enrich_report_applied ? "themed HTML (cogni-visual)" : "skipped"}

Recommended next steps:
  1. export-pdf-report — Generate formal PDF report
  2. cogni-claims:claim-work — Verify claims (if skipped)

Use /trends-resume in your next session to pick up where you left off.
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `trend-scout-output.json` missing | HALT: Run trend-scout first |
| `workflow_state != "agreed"` | HALT: Complete candidate selection |
| `tips_candidates.total < 60` | HALT: Expected 60 candidates |
| `tips-value-model.json` missing or no investment themes | HALT: Run value-modeler first |
| `tips-value-model.json` has investment themes but no value chains | HALT: value-modeler Phase 1 incomplete |
| No raw signals file (both sources) | WARNING: proceed without signals (~120 searches) |
| Phase 1 agent returns `ok: false` | Retry once, then HALT with dimension name |
| All 4 Phase 1 agents fail | HALT: Check web access is enabled |
| enriched-trends JSON missing | HALT: Phase 1 agent failed to produce enriched output |
| Investment theme agent returns `ok: false` | Retry once, then HALT with investment theme name |
| Investment theme agent quality gate fails | WARNING: continue (section written but may be thin) |
| Investment theme references unknown candidate_ref | WARNING: agent skips that candidate in investment theme narrative |
| `cogni-narrative` not installed | WARNING: investment-theme-writer uses flat structure (no arc guidance) |
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

**Optional cross-plugin:** `cogni-narrative` theme-thesis arc (Phase 2 investment theme writer guidance), `cogni-claims:claim-work` (Phase 3), `cogni-copywriting:copywriter` (Phase 3.5), `cogni-visual:enrich-report` (Phase 3.7 themed HTML with charts and diagrams)

**Downstream:** `export-pdf-report`

## Debugging

Log files in `{PROJECT_PATH}/.logs/`:
- `report-header.md` — frontmatter + exec summary
- `report-section-{dimension}.md` — dimension sections (4 files, written by agents)
- `phase2-value-model.json` — pruned value-model subset for Phase 2
- `enriched-trends-{dimension}.json` — per-trend evidence blocks (4 files, used in investment theme assembly)
- `report-investment-theme-{investment_theme_id}.md` — investment theme sections (3-7 files, written by investment theme agents)
- `claims-{dimension}.json` — dimension claims (4 files)
- `report-claims-registry.md` — claims table

Output files in `{PROJECT_PATH}/`:
- `tips-trend-report.md` — assembled final report
- `tips-trend-report-claims.json` — merged claims registry
- `tips-insight-summary.md` — legacy artifact (no longer generated; cleaned up on re-runs)

| Issue | Check |
|-------|-------|
| Phase 1 agent hangs | Verify web access is enabled |
| Investment theme agent hangs | Check enriched-trends files exist in .logs/ |
| Empty claims | Check if trends have quantitative data in trend-scout output |
| Wrong language | Verify `project_language` in trend-scout-output.json |
| Missing sections | Check `.logs/` for partial agent output |
