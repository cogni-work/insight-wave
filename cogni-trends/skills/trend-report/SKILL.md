---
name: trend-report
description: |
  Generate a strategic TIPS trend report organized around investment themes (Handlungsfelder) with inline citations and verifiable claims. The user selects a report-level narrative arc from cogni-narrative's 8 story arcs (smarter-service [recommended default for themed reports], corporate-visions, technology-futures, competitive-intelligence, strategic-foresight, industry-transformation, trend-panorama, theme-thesis) — the arc frames the executive summary, bridge paragraphs between themes, and a synthesis closing section that bind investment themes into one cohesive narrative. Each investment theme is written in one of two structural modes selected by `MICRO_ARC`: full theme-thesis arc (Why Change → Why Now → Why You → Why Pay) under flat-themes arcs, or slim 3-beat investment-case (Stake / Move / Cost-of-Inaction) under smarter-service, in both cases backed by T→I→P→S value chain evidence. Reads agreed trend candidates, enriches each with web-sourced quantitative evidence via parallel agents, assembles the report with arc-framed executive summary, bridge paragraphs, theme sections, synthesis section, and claims registry. Produces a clean draft + claims registry; verification, structural review, revision, polish, and visualization are handled by the separate `verify-trend-report` skill (auto-recommended at the end of Phase 4). Required pipeline: trend-scout → value-modeler → trend-report → verify-trend-report. Use when: (1) trend-scout and value-modeler have completed, (2) user wants a written trend report, (3) user mentions "trend report", "TIPS report", "write up trends", "summarize trends", "trend analysis document", "strategic stories", (4) preparing a deliverable from scouted trends, (5) user asks to "generate report from trends" or "create trend deliverable". Always use this skill when trend-scout output exists and the user wants any kind of written trend analysis — even if they don't use the exact phrase "trend report".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, Skill
---

# Trend Report

Generate a strategic TIPS trend report from agreed trend-scout candidates. Organizes the report around investment themes — each investment theme tells a CxO-level story backed by T→I→P value chain evidence. Dispatches 4 parallel agents to enrich trends with web-sourced quantitative evidence, then assembles a theme-first strategic report with executive summary and claims registry.

## Purpose

Transform agreed trend-scout candidates into a strategic, evidence-backed report draft:

1. Load value-modeler investment themes and validate prerequisites
2. User selects a report-level narrative arc (from cogni-narrative's 8 arcs) to frame the overall story
3. Enrich each trend with quantitative evidence from web research
4. Assemble investment theme narratives in the structural mode dictated by the chosen report arc — full theme-thesis (Why Change → Why Now → Why You → Why Pay) for flat-themes arcs, or slim investment-case (Stake / Move / Cost-of-Inaction) under smarter-service — with embedded evidence
5. Generate arc-framed executive summary, bridge paragraphs between themes, and synthesis closing section
6. Generate inline citations for every quantitative claim
7. Produce a claims registry compatible with `cogni-claims:claims`
8. Hand off to `/verify-trend-report` for the extended pipeline (verification, structural review, revision, downstream menu)

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
- Optional: `cogni-narrative` plugin for arc-aware guidance — theme-thesis arc (flat-themes flow) and smarter-service arc + macro-skeleton synthesis (smarter-service flow). Graceful fallback if absent — themes use flat structure
- Downstream: `verify-trend-report` (in this plugin) handles claim verification, cross-theme structural review, post-verification revision, and the final polish/visualize menu

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
| [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) | Phase 2 — flat-themes flow (when `REPORT_ARC_ID` is one of `corporate-visions`, `technology-futures`, `competitive-intelligence`, `strategic-foresight`, `industry-transformation`, `trend-panorama`, `theme-thesis`) |
| [references/phase-2-smarter-service.md](references/phase-2-smarter-service.md) | Phase 2 — macro-skeleton flow (when `REPORT_ARC_ID == "smarter-service"`): dimension primer, slim 3-beat theme-cases, sequential composer |
| [references/report-structure.md](references/report-structure.md) | Dimension section templates (written by Phase 1 agents) |
| [references/evidence-enrichment.md](references/evidence-enrichment.md) | Configuring agent web search strategy (Phase 1) |
| [references/claims-format.md](references/claims-format.md) | Extracting/merging claims (Phase 1-2) |
| [references/report-length-tiers.md](references/report-length-tiers.md) | Length-tier definitions, per-theme budget formula, override semantics (Phase 0.4d-e) |
| [references/i18n/labels-en.md](references/i18n/labels-en.md) | English report headings and labels |
| [references/i18n/labels-de.md](references/i18n/labels-de.md) | German report headings and labels |

## Workflow Overview

Track progress through these phases as you go:

```text
Phase 0 → Phase 0.5 → Phase 1 → Phase 2 → Phase 4
   │          │           │          │          │
   │          │           │          │          └─ Update metadata, hand off to /verify-trend-report
   │          │           │          └─ Theme narratives + exec summary + bridges + synthesis
   │          │           └─ 4 parallel agents: enrich trends, write sections, extract claims
   │          └─ Optional deep research for 3-5 high-value ACT-horizon trends
   └─ Project discovery, arc selection, load inputs, validate gate
```

Phases 2.5 (structural review), 3 (claim verification), 3.5 (executive polish), and 5 (post-verification revision) moved into the dedicated `verify-trend-report` skill — re-entrant, runs in a fresh context window, and bundles a downstream polish/visualize menu at the end.

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

The report-level arc determines how the report is structured. **Two skeleton families exist** and the user's choice routes Phase 2 down different paths:

- **Flat-themes skeleton (arcs 1–7 in `report-arc-frames.md`):** investment themes are H2 sections sequenced left-to-right; bridges between H2s carry the arc; per-theme content uses the `theme-thesis` micro-arc internally (Why Change → Why Now → Why You → Why Pay).
- **Macro skeleton (`smarter-service`, arc 8):** the 4 Smarter Service dimensions are H2 sections; investment themes are H3 cases nested under the macro element where their dominant TIPS pole lives; per-theme content uses a slim 3-beat micro-arc (Stake / Move / Cost-of-Inaction). Phase 2 dispatches a shared dimension primer + N parallel theme-case writers + 4 sequential dimension composers.

##### Step 0.4b-pre: Stale-Arc Promotion Check (re-runs on existing projects)

Before presenting the standard 4-option picker, check whether the project has a persisted arc that pre-dates the current registry recommendation. This guards against silently re-using a flat-themes arc on a project that has since become eligible for smarter-service (e.g., value-modeler ran between report runs, or smarter-service was introduced upstream after the last report).

**Predicate (all must be true):**

- `tips-project.json.report_arc_id` is set
- That arc is **not** `smarter-service`
- That arc is a **flat-themes arc** (one of: `corporate-visions`, `technology-futures`, `competitive-intelligence`, `strategic-foresight`, `industry-transformation`). Deliberately excludes `trend-panorama` (intentional theme-less framing) and `theme-thesis` (intentional single-theme deep dive) — promoting either to smarter-service silently would be wrong.
- `tips-value-model.json` exists with `investment_themes[].length >= 1`

**Drift handling:** If `.metadata/trend-scout-output.json.trend_report_arc_id` disagrees with `tips-project.json.report_arc_id`, log a one-line warning (`"Arc-Drift: tips-project.json='{a}' vs. trend-scout-output.json='{b}' — verwende tips-project.json"`) and proceed using `tips-project.json` as the user-facing source of truth. The standard 4-option picker (or the user's choice in this step) overwrites both fields after Phase 0.4d.

**If the predicate holds, present this 3-option AskUserQuestion. If not, skip directly to the standard 4-option picker below.**

```yaml
AskUserQuestion:
  question: "{ARC_PROMOTE_QUESTION}"   # interpolates {persisted_arc}
  header: "{ARC_PROMOTE_HEADER}"
  options:
    - label: "{ARC_PROMOTE_TO_SMARTER_SERVICE}"
      description: "{ARC_PROMOTE_TO_SMARTER_SERVICE_DESC}"
    - label: "{ARC_PROMOTE_KEEP_PERSISTED}"   # interpolates {persisted_arc}
      description: "{ARC_PROMOTE_KEEP_PERSISTED_DESC}"
    - label: "{ARC_PROMOTE_PICK_OTHER}"
      description: "{ARC_PROMOTE_PICK_OTHER_DESC}"
```

Routing on user choice:

- **Promote to smarter-service** → set `REPORT_ARC_ID = "smarter-service"`, skip the standard 4-option picker, continue to Step 0.4c (title).
- **Keep persisted** → set `REPORT_ARC_ID = persisted_arc`, skip the standard 4-option picker, continue to Step 0.4c.
- **Pick other** → fall through to the standard 4-option picker below (smarter-service stays first with the "Empfohlen" marker — the user can still pick it from there if they reconsider).

This step does **not** auto-promote. The user always has final say (per [report-arc-frames.md](references/report-arc-frames.md) §"Arc Selection").

##### Step 0.4b: Standard arc picker

Present 4 arcs via `AskUserQuestion`. The recommended default is **`smarter-service`** when `tips-value-model.json` exists with investment themes (the normal trend-report case) — it's the macro-skeleton variant of `trend-panorama` adapted for theme-aware reports. Auto-detect a different recommendation if the topic strongly signals another arc (e.g., sales-pitch framing → `corporate-visions`; heavily regulatory topics → `industry-transformation`).

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_ARC_QUESTION}"
  header: "{PHASE_0_ARC_HEADER}"
  options:
    - label: "{ARC_SMARTER_SERVICE}"
      description: "{ARC_SMARTER_SERVICE_DESC}"
    - label: "{ARC_CORPORATE_VISIONS}"
      description: "{ARC_CORPORATE_VISIONS_DESC}"
    - label: "{ARC_INDUSTRY_TRANSFORMATION}"
      description: "{ARC_INDUSTRY_TRANSFORMATION_DESC}"
    - label: "{ARC_TECHNOLOGY_FUTURES}"
      description: "{ARC_TECHNOLOGY_FUTURES_DESC}"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_ARC_QUESTION}"
  header: "{PHASE_0_ARC_HEADER}"
  options:
    - label: "{ARC_SMARTER_SERVICE}"
      description: "{ARC_SMARTER_SERVICE_DESC}"
    - label: "{ARC_CORPORATE_VISIONS}"
      description: "{ARC_CORPORATE_VISIONS_DESC}"
    - label: "{ARC_INDUSTRY_TRANSFORMATION}"
      description: "{ARC_INDUSTRY_TRANSFORMATION_DESC}"
    - label: "{ARC_TECHNOLOGY_FUTURES}"
      description: "{ARC_TECHNOLOGY_FUTURES_DESC}"
```

> **AskUserQuestion limit:** The picker supports max 4 options. The recommended arc is always first (with arrow marker). If the user selects "Other", show the remaining 4 arcs (`strategic-foresight`, `competitive-intelligence`, `trend-panorama`, `theme-thesis`) in a follow-up question.

Set `REPORT_ARC_ID` to the user's choice. This variable routes Phase 2:
- `REPORT_ARC_ID == "smarter-service"` → Phase 2 reads [references/phase-2-smarter-service.md](references/phase-2-smarter-service.md) (macro skeleton).
- All other values → Phase 2 reads [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) (flat-themes skeleton).

#### Step 0.4c: Propose Report Title

The research question (`{TOPIC}`) becomes the **subtitle**. Generate a punchy **title** (max 8 words) from `{TOPIC}`, `REPORT_ARC_ID`, `INDUSTRY`, and investment theme names (already loaded in Step 0.2). The title should:
- Be CxO-level — sharp, memorable, forward-looking
- Reflect the arc's rhetorical stance (e.g., corporate-visions → urgency/challenge; technology-futures → capability/convergence; industry-transformation → structural shift)
- NOT repeat the research question or be a generic label like "Trend Report"

The subtitle is `{TOPIC}`, optionally shortened for readability (drop redundant geographic/industry qualifiers if obvious from context).

Present via AskUserQuestion:

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_TITLE_QUESTION}\n\n**Titel:** {proposed_title}\n**Untertitel:** {proposed_subtitle}"
  header: "{PHASE_0_TITLE_HEADER}"
  options:
    - label: "{PHASE_0_TITLE_ACCEPT}"
    - label: "{PHASE_0_TITLE_EDIT}"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_TITLE_QUESTION}\n\n**Title:** {proposed_title}\n**Subtitle:** {proposed_subtitle}"
  header: "{PHASE_0_TITLE_HEADER}"
  options:
    - label: "{PHASE_0_TITLE_ACCEPT}"
    - label: "{PHASE_0_TITLE_EDIT}"
```

If the user selects **Edit**, ask them to provide their preferred title and/or subtitle as free text. Store the final values as `{TITLE}` and `{SUBTITLE}`.

#### Step 0.4d: Select Report Length Tier

Read [references/report-length-tiers.md](references/report-length-tiers.md) for tier definitions and budget formula.

The tier controls how long the **prose** of the report is — executive summary + theme sections + bridges + synthesis. The claims registry / sources appendix is **always rendered in full** regardless of tier, and is **not counted** toward the target. The reviewer in `verify-trend-report` measures prose the same way.

**Resume rule:** Read `{PROJECT_PATH}/tips-project.json`. If it already contains a `report_tier` field (and optionally `report_target_words`), skip the question — display `"Length tier: {report_tier} (~{report_target_words} prose words)"` and continue. This keeps re-runs deterministic and lets users pre-seed the choice from automation. Re-asking only happens when the field is absent.

Otherwise present the question. Default is `standard` (4,000 prose words — the analog of cogni-research's "detailed" mode):

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_LENGTH_QUESTION}"
  header: "{PHASE_0_LENGTH_HEADER}"
  options:
    - label: "{LENGTH_TIER_STANDARD}"
      description: "{LENGTH_TIER_STANDARD_DESC}"
    - label: "{LENGTH_TIER_EXTENDED}"
      description: "{LENGTH_TIER_EXTENDED_DESC}"
    - label: "{LENGTH_TIER_COMPREHENSIVE}"
      description: "{LENGTH_TIER_COMPREHENSIVE_DESC}"
    - label: "{LENGTH_TIER_MAXIMUM}"
      description: "{LENGTH_TIER_MAXIMUM_DESC}"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "{PHASE_0_LENGTH_QUESTION}"
  header: "{PHASE_0_LENGTH_HEADER}"
  options:
    - label: "{LENGTH_TIER_STANDARD}"
      description: "{LENGTH_TIER_STANDARD_DESC}"
    - label: "{LENGTH_TIER_EXTENDED}"
      description: "{LENGTH_TIER_EXTENDED_DESC}"
    - label: "{LENGTH_TIER_COMPREHENSIVE}"
      description: "{LENGTH_TIER_COMPREHENSIVE_DESC}"
    - label: "{LENGTH_TIER_MAXIMUM}"
      description: "{LENGTH_TIER_MAXIMUM_DESC}"
```

> **AskUserQuestion limit:** The picker supports max 4 options, so the four tiers fill it. Power users wanting an exact custom integer can pre-seed `report_tier: "custom"` and `report_target_words: <int>` in `tips-project.json` before running this skill — the resume rule above will pick that up and skip the question.

Map the user's choice to `{REPORT_TIER, REPORT_TARGET_WORDS}` per `report-length-tiers.md`:

| Tier | `report_target_words` |
|---|---|
| standard | 4000 |
| extended | 5500 |
| comprehensive | 7000 |
| maximum | 8000 |

If `report_tier == "custom"` (only reachable via pre-seeded config):

1. **Presence check** — if `report_target_words` is missing, `null`, or not an integer: HALT before any further processing. Display `LENGTH_TIER_CUSTOM_DESC` (which documents the bounds) followed by `"Set \"report_target_words\" in tips-project.json to an integer in [2500, 12000] and re-run."` Do not fall through to the formula; downstream agents would otherwise receive `NaN`.
2. **Range check** — if present and integer, validate `2500 ≤ report_target_words ≤ 12000`. Outside that range: HALT with the bounds and ask the user to correct the config — do not silently clamp.

Persist the choice by updating `{PROJECT_PATH}/tips-project.json`:

```json
{
  "report_tier": "{tier}",
  "report_target_words": {N}
}
```

Re-runs and `verify-trend-report` will read these fields directly without re-asking.

#### Step 0.4e: Compute Length Budget

The orchestrator now has `REPORT_TARGET_WORDS` and the investment-theme count `N` (from the value model loaded in Step 0.2). The budget formula **branches on `REPORT_ARC_ID`** because the smarter-service arc has a fundamentally different prose layout (4 dimension narratives + slim theme-cases vs. N theme sections + bridges).

**If `REPORT_ARC_ID != "smarter-service"` (legacy flat-themes):**

```text
exec_words      = clamp(REPORT_TARGET_WORDS * 0.04, 80, 250)
synthesis_words = clamp(REPORT_TARGET_WORDS * 0.13, 350, 1300)
remaining       = REPORT_TARGET_WORDS - exec_words - synthesis_words
per_theme_words = max(380, round(remaining / N))
```

The 380 floor is the sum of the writer agent's per-element minimums (Hook 30 + WhyChange 80 + WhyNow 80 + WhyYou 100 + WhyPay 90) — it protects the Why-* arc from collapsing at small budgets. When the floor binds, the agent overshoots target slightly; this is intentional.

Set:
- `THEME_TARGET_WORDS = per_theme_words`
- `SYNTHESIS_TARGET_WORDS = synthesis_words`
- `EXEC_TARGET_WORDS = exec_words`

**If `REPORT_ARC_ID == "smarter-service"` (macro skeleton):**

```text
exec_words              = clamp(REPORT_TARGET_WORDS * 0.10, 200, 350)
synthesis_words         = clamp(REPORT_TARGET_WORDS * 0.08, 300, 800)
dim_narrative_words     = clamp(REPORT_TARGET_WORDS * 0.12, 250, 600)   # PER dimension
theme_cases_total       = REPORT_TARGET_WORDS - exec_words - synthesis_words - 4 * dim_narrative_words
per_theme_case_words    = max(290, round(theme_cases_total / N))
```

The 290 floor is the sum of the slim-mode minimums (Stake 80 + Move 130 + Cost 80). The 250 dimension-narrative floor protects the macro framing.

Set:
- `THEME_CASE_TARGET_WORDS = per_theme_case_words` — passed to each theme-case writer
- `DIMENSION_NARRATIVE_TARGET_WORDS = dim_narrative_words` — passed to each of 4 composer agents
- `SYNTHESIS_TARGET_WORDS = synthesis_words`
- `EXEC_TARGET_WORDS = exec_words`
- `THEME_TARGET_WORDS = per_theme_case_words` (alias for backward compat with reporting)

The claims registry is NOT in either formula — it is data-driven and rendered separately in Phase 2. It is excluded from word accounting at every stage.

`REPORT_TARGET_WORDS` is passed to the reviewer in `verify-trend-report` regardless of arc.

Display:
- Legacy: `"Budget computed: ~{REPORT_TARGET_WORDS} prose words across {N} themes (~{THEME_TARGET_WORDS} per theme)"`.
- Smarter-service: `"Budget computed: ~{REPORT_TARGET_WORDS} prose words across 4 dimensions + {N} theme-cases (~{DIMENSION_NARRATIVE_TARGET_WORDS} per dimension narrative, ~{THEME_CASE_TARGET_WORDS} per theme-case)"`.

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
      "{PROJECT_PATH}/.logs/report-theme-case-"*.md \
      "{PROJECT_PATH}/.logs/report-macro-section-"*.md \
      "{PROJECT_PATH}/.logs/report-shared-primer.md" \
      "{PROJECT_PATH}/.logs/report-theme-anchors.json" \
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

The cleanup glob covers both Phase-2 modes — switching `REPORT_ARC_ID` between runs (e.g., from `corporate-visions` to `smarter-service`) will purge stale artefacts from either mode so resume logic doesn't mix them.

---

### Phase 0.5: Deep Research Selection (Optional)

**When to run:** Offer this phase when the user wants deeper evidence for high-value trends. Skip if the user wants a fast report or explicitly declines.

**Purpose:** Select 3-5 high-value ACT-horizon trends for recursive deep research before standard evidence enrichment. Deep-researched trends get richer evidence (quantitative data, forcing functions, ROI figures) that makes the Why Change / Why Pay investment theme arguments substantially more credible.

**Step 0.5.1: Select Trends for Deep Research**

Ask the user via AskUserQuestion:

```text
EN: "I can perform deep research on 3-5 high-value trends before writing the report. This adds ~5-10 minutes but produces richer evidence with quantitative data. Would you like to:
a) Deep research top ACT-horizon trends (recommended for executive audiences)
b) Skip deep research and proceed with standard evidence enrichment
c) Select specific trends for deep research"

DE: "Ich kann eine Tiefenrecherche für 3-5 hochwertige Trends durchführen, bevor der Bericht geschrieben wird. Das dauert ~5-10 Minuten länger, liefert aber reichere Evidenz mit quantitativen Daten. Möchten Sie:
a) Tiefenrecherche der wichtigsten ACT-Horizont-Trends (empfohlen für Führungskräfte-Publikum)
b) Tiefenrecherche überspringen und mit Standard-Evidenzanreicherung fortfahren
c) Spezifische Trends für Tiefenrecherche auswählen"
```

**Step 0.5.2: Auto-Select or User-Select**

If user chose (a), auto-select using these criteria (in priority order):
1. ACT-horizon trends with `signal_intensity >= 4` and `confidence_tier == "high"` — sorted by composite score descending
2. If fewer than 3 qualify, include ACT-horizon trends with `confidence_tier == "medium"` and highest scores
3. Cap at 5 trends maximum

If user chose (c), present the ACT-horizon trend list and let them pick.

**Step 0.5.3: Dispatch Deep Researchers (Parallel)**

Dispatch one `trend-deep-researcher` agent per selected trend, all in parallel:

```yaml
Task:
  subagent_type: "cogni-trends:trend-deep-researcher"
  description: "Deep research: {TREND_NAME}"
  prompt: |
    Perform deep research on this trend candidate.

    PROJECT_PATH: {{PROJECT_PATH}}
    TREND_NAME: {{TREND_NAME}}
    TREND_KEYWORDS: {{KEYWORDS}}
    DIMENSION: {{DIMENSION}}
    HORIZON: act
    SUBSECTOR_EN: {{SUBSECTOR_EN}}
    SUBSECTOR_DE: {{SUBSECTOR_DE}}
    SUBSECTOR_LOCAL: {{SUBSECTOR_LOCAL}}
    RESEARCH_HINT: {{RESEARCH_HINT}}
    MARKET_REGION: {{MARKET_REGION}}
```

**Process results:** Each agent writes a `.logs/deep-research-{slug}.json` artifact. Log success/failure counts. These artifacts are consumed by Phase 1 trend-report-writer agents — trends with deep research artifacts skip their own WebSearch and use the richer findings directly.

---

### Phase 1: Evidence Enrichment + Section Generation (PARALLEL)

Read [references/evidence-enrichment.md](references/evidence-enrichment.md) for web search strategy.
Read [references/claims-format.md](references/claims-format.md) for claims extraction schema.

**Deep research integration:** Before each trend-report-writer agent runs its evidence enrichment, it checks for `{PROJECT_PATH}/.logs/deep-research-{trend-slug}.json`. If a deep research artifact exists for a trend in its dimension, the writer uses the artifact's `synthesis` and `sources` instead of running its own WebSearch for that trend. This is a fourth evidence status alongside `signal_sufficient`, `signal_partial`, and `signal_none`: **`deep_research_available`** — richest evidence tier, no additional search needed.

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
    Subsector Local: {SUBSECTOR_LOCAL}
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

### Phase 2: Report Assembly — TWO FLOWS

Phase 2 branches on `REPORT_ARC_ID`. Read the matching reference file before starting any work.

| `REPORT_ARC_ID` value | Reference to read | Skeleton |
|---|---|---|
| `smarter-service` | [references/phase-2-smarter-service.md](references/phase-2-smarter-service.md) | Macro skeleton: 4 H2 dimensions, themes nested as H3 cases |
| Anything else (`corporate-visions`, `technology-futures`, `competitive-intelligence`, `strategic-foresight`, `industry-transformation`, `trend-panorama`, `theme-thesis`) | [references/phase-2-strategic-themes.md](references/phase-2-strategic-themes.md) | Flat-themes skeleton: themes as H2 sequenced left-to-right |

**Both flows share** the principle that the report is organized by **investment themes** from `tips-value-model.json`, NOT by TIPS dimension. Do NOT simply concatenate the dimension section files from Phase 1 — those are intermediate enrichment artefacts, never the final report structure.

**Both flows share** the agent-assisted writing model: agents self-load evidence from disk, the orchestrator passes only small scalars and keeps its own context lean.

The flows differ in: H2 layout, number and shape of agent dispatches, presence of a shared dimension primer, presence of a sequential composer, presence of inter-theme bridges, and the budget split. Read the matching reference before dispatching anything.

#### Flow A: Flat-themes (default for non-smarter-service arcs)

**Summary of steps** (details in [phase-2-strategic-themes.md](references/phase-2-strategic-themes.md)):

1. **Read value model** — Read `.logs/phase2-value-model.json` for investment themes, value chains, solution templates, orphan candidates, coverage data.
2. **Dispatch investment theme agents (parallel)** — For each investment theme, dispatch a `cogni-trends:trend-report-investment-theme-writer` agent with `MICRO_ARC: "theme-thesis"` (default), `MARKET_REGION: {MARKET_REGION}`, and `REPORT_ARC_ID: {REPORT_ARC_ID}` in the prompt. All agents in a single message (parallel). Each writes `report-investment-theme-{investment_theme_id}.md`.
3. **Collect agent results** — Validate `ok: true`. Retry once on failure.
4. **Write executive summary** — Read ALL `report-investment-theme-*.md` files. Use `REPORT_ARC_ID` to select arc-specific opener/closer patterns from `report-arc-frames.md`. Write `report-header.md`.
5. **Write bridge paragraphs** — For each consecutive theme pair, generate a 2–4 sentence bridge using the arc's bridge pattern. Write `report-bridge-{N}-{N+1}.md` files.
6. **Write synthesis section** — Generate a 300–500 word closing section using the arc's synthesis frame. Write `report-synthesis.md`.
7. **Write claims registry** — Read 4 `claims-{dimension}.json` files, map claims to investment themes via the value model, write `report-claims-registry.md`.
8. **Assemble** — Concatenate: header + (theme1 + bridge-1-2 + theme2 + bridge-2-3 + ... + themeN) + synthesis + claims → `tips-trend-report.md`.
9. **Merge claims** → `tips-trend-report-claims.json`.

**Resume logic (Flow A):** Before dispatching an agent for an investment theme, check if `report-investment-theme-{investment_theme_id}.md` already exists and is >1000 bytes. If so, skip — display `"{PHASE_2_INVESTMENT_THEME_AGENT_SKIP_RESUME}"`. Re-runs only dispatch for missing investment themes.

#### Flow B: Smarter-service macro skeleton

**Summary of steps** (details in [phase-2-smarter-service.md](references/phase-2-smarter-service.md)):

1. **Read value model** — Same as Flow A.
2. **Step 2.0a — Compute theme anchoring** — For each theme, compute `anchor_dimension` (highest `candidate_ref` count per pole; tiebreak on highest single-candidate composite score; final tiebreak T > I > P > S). Persist to `.logs/report-theme-anchors.json`. Skip if file exists with all themes mapped.
3. **Step 2.0b — Write shared dimension primer (orchestrator)** — Read all 4 `.logs/enriched-trends-{dimension}.json` files and the value model. Write 4 paragraphs (~120 words each, ~480 total) to `.logs/report-shared-primer.md` — one per Smarter Service dimension, each ending with the anchor pivot sentence naming themes anchored there. Skip if primer file exists and is >800 bytes.
4. **Step 2.1 — Dispatch theme-case writers (parallel)** — For each theme, dispatch a `cogni-trends:trend-report-investment-theme-writer` agent with `MICRO_ARC: "investment-case"`, `ANCHOR_DIMENSION`, `SECONDARY_POLES`, `SHARED_PRIMER_PATH`, `THEME_CASE_TARGET_WORDS`. All in a single parallel message. Each writes `report-theme-case-{theme_id}.md` (slim 3-beat). Resume: skip if file exists and is >600 bytes.
5. **Step 2.2 — Dispatch dimension composers (sequential, 4 calls)** — For each dimension in TIPS order (`externe-effekte` → `digitale-wertetreiber` → `neue-horizonte` → `digitales-fundament`), dispatch one `cogni-trends:trend-report-composer` agent. **Sequential, NOT parallel** — voice consistency depends on this. Each composer writes `report-macro-section-{dimension}.md` (= H2 heading + dimension narrative + concatenated theme-cases anchored here + secondary callouts). Resume per dimension: skip if file exists and is >800 bytes.
6. **Step 2.3 — Write executive summary** — Read primer and all 4 macro section files. Use `report-arc-frames.md § 8` for the smarter-service exec opener/closer. Write `report-header.md`. The exec summary's numbered list iterates over the **4 dimensions** (not over themes), naming anchored themes within each dimension entry.
7. **Step 2.4 — Write claims registry** — Same as Flow A but with a `dimension` column added.
8. **Step 2.5 — Write synthesis section ("The Capability Imperative")** — Foundations-anchored, aggregates *across* themes. Write `report-synthesis.md`.
9. **Step 2.6 — Assemble** — Concatenate: header + macro-section-externe-effekte + macro-section-digitale-wertetreiber + macro-section-neue-horizonte + macro-section-digitales-fundament + synthesis + claims → `tips-trend-report.md`. **No bridge files** — bridges between macro sections live inside the dimension narratives.
10. **Step 2.7 — Merge claims** — Same as Flow A.

**Hard ordering constraints (Flow B):**
- Step 2.0b must complete before Step 2.1 (theme writers need the primer).
- Step 2.1 must complete (all themes) before Step 2.2 (composers concatenate theme-cases).
- Step 2.2 must run sequentially across the 4 dimensions, not in parallel — voice consistency.

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
  "trend_report_mode": "{strategic-themes | smarter-service-themed}",
  "trend_report_arc_id": "{REPORT_ARC_ID}",
  "trend_report_investment_theme_count": N,
  "trend_report_generated_at": "ISO-8601",
  "report_tier": "{REPORT_TIER}",
  "report_target_words": {REPORT_TARGET_WORDS}
}
```

`trend_report_mode` is `"smarter-service-themed"` when `REPORT_ARC_ID == "smarter-service"`, else `"strategic-themes"` (legacy value preserved for verify-trend-report and downstream consumers that already key off this field).

`report_tier` and `report_target_words` are mirrored into trend-scout-output.json so `verify-trend-report` can read the prose-word target without re-loading `tips-project.json` — the reviewer uses it for tier-aware Completeness scoring.

#### Step 4.2: Display Summary

```
Trend Report Draft Complete (Investment Themes)
───────────────────────────────────────────────
Report:       {PROJECT_PATH}/tips-trend-report.md
Themes:       {N} investment themes ({REPORT_ARC_ID} arc)
Length tier:  {REPORT_TIER} (~{REPORT_TARGET_WORDS} prose words target; registry excluded)
Claims:       {PROJECT_PATH}/tips-trend-report-claims.json
Trends:       60 across {N} investment themes
Claims:       {total_claims} quantitative claims extracted

Next step → Run /verify-trend-report to verify claims against sources, run
cross-theme structural review, apply corrections, and pick a downstream path
(executive polish or themed-HTML visualization).

Then /trends-resume shows the full option set (slides, web, storyboard,
catalog, dashboard).
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

## Integration

**Upstream:**
- `trend-scout` produces `trend-scout-output.json` (required)
- `value-modeler` produces `tips-value-model.json` (required)

**Pipeline:** `trend-scout → value-modeler → trend-report → verify-trend-report`

**Optional cross-plugin:** `cogni-narrative` theme-thesis arc (flat-themes flow) and smarter-service arc (macro-skeleton flow) — Phase 2 investment theme writer / composer guidance

**Downstream (via `/verify-trend-report`):** claim verification (`cogni-claims:claims`), cross-theme structural review, post-verification revision, executive polish (`cogni-copywriting:copywriter`), themed HTML (`cogni-visual:enrich-report`)

**Further downstream (via `/trends-resume`):** `cogni-visual:story-to-slides` (presentation), `cogni-visual:story-to-web` (landing page), `cogni-visual:story-to-storyboard` (print posters), `trends-catalog import`, `trends-dashboard`

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
