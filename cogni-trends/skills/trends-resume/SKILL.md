---
name: trends-resume
description: |
  Resume, continue, or check status of a TIPS trend scouting project.
  Use whenever the user mentions "continue tips", "resume tips", "resume trends",
  "where was I", "tips status", "what's next", "continue the project",
  "resume trend project", "check scan progress", "trend status",
  or opens a session that involves an existing cogni-trends project —
  even if they don't say "resume" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# TIPS Resume

Session entry point for returning to trend scouting work. This skill orients the user by showing where they left off and what to do next — the dashboard view that keeps multi-session TIPS projects on track.

## Core Concept

TIPS projects span multiple sessions and skills (trend-scout → value-modeler → trend-report → verification). Without a clear re-entry point, users lose context between sessions and waste time figuring out what they already did. This skill bridges that gap: it reads the project state, surfaces progress at a glance, and recommends the most valuable next step.

## Workflow

**Plugin root resolution.** Every bash call below resolves the plugin root inline as `${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-trends/*/ | head -1)}`. When Claude Code injects `$CLAUDE_PLUGIN_ROOT` (the normal case) the fallback never runs. If the harness fails to inject it (observed in some sessions, where `bash $CLAUDE_PLUGIN_ROOT/...` would produce `No such file or directory`), the inline fallback discovers the most recently cached plugin root automatically — no failed first call, no recovery prompt. Keep the inline form in every call; do not strip it.

### 1. Find TIPS Projects

Discover TIPS projects in the workspace using the discovery script.

**Determine the workspace root** before calling the script. The workspace root is the directory that contains the `cogni-trends/` project folder. Check in this order:
1. `$PROJECT_AGENTS_OPS_ROOT` — if set (via `settings.local.json` env block), use it
2. Otherwise, look for a `cogni-trends/` directory under the current working directory
3. If not found under `$PWD`, check if there's a `.workspace-config.json` nearby that indicates the workspace location

Pass the root explicitly with `--root`:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-trends/*/ | head -1)}/scripts/discover-projects.sh" --json --root "<workspace-root>"
```

If you cannot determine a specific root, omit `--root` and the script falls back to `$PROJECT_AGENTS_OPS_ROOT` or `$PWD`:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-trends/*/ | head -1)}/scripts/discover-projects.sh" --json
```

Returns JSON with `count` and `projects` array. Each project includes `path`, `slug`, `industry`, `subsector`, `research_topic`, `workflow_state`, `candidates_total`, and `has_report`.

The script searches:
1. The workspace root (from `--root`, `$PROJECT_AGENTS_OPS_ROOT`, or `$PWD`) for `cogni-trends/*/tips-project.json`
2. The global project registry (`~/.claude/cogni-trends-projects.json`) for projects created in other workspaces

If `count` is 0:
- First, ask the user if they have a project in a different directory (e.g., OneDrive, external workspace). If they provide a path, register it:
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-trends/*/ | head -1)}/scripts/discover-projects.sh" --register "<path>"
  ```
  Then re-run discovery.
- If no path is provided, suggest the `trend-scout` skill to start a new project.

### 2. Select Project

- One project found — use it automatically.
- Multiple projects — present them with industry + topic + status and ask which one to continue.

### 3. Run Project Status with Health Check

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-trends/*/ | head -1)}/scripts/project-status.sh" "<project-dir>" --health-check
```

The script returns JSON with `project`, `counts` (including `blueprints`, `anchored_solutions`, `avg_readiness`), `portfolio_anchors` (per-product breakdown with needs coverage and quality flags), `scoring`, `artifacts`, `portfolio_bridge`, `phase`, `next_actions`, and `stale_warnings`.

### 4. Present Status Summary

Show a concise, scannable dashboard. Lead with the project name and industry context, then the progress overview:

**Project Header:**
```
TIPS Project: {research_topic}
Industry: {industry} / {subsector}
Language: {language}
```

**Progress Table:**

The status JSON includes a pre-computed `stages[]` array. **Render one row per element verbatim — do not re-derive status from any other field, do not skip rows, do not invent rows.** The script has already applied every per-row decision rule against the JSON it returned, so nothing in the table requires LLM judgment.

Translate the status enum for display: `done`→Done, `pending`→Pending, `ready`→Ready, `n_a`→N/A, `skipped`→Skipped. For non-English projects, translate the status word and the details phrase to the project language. Render exactly one row per array element:

| Stage | Status | Details |
|-------|--------|---------|
| {stages[i].name} | {translated stages[i].status} | {translated stages[i].details} |

**Trust the script's pre-computed values.** `phase`, `next_actions`, and `stages[]` are derived from full state — never re-derive any of them from `workflow_state` or from raw counts, and never substitute your own next-action recommendation when `next_actions` is non-empty.

**Portfolio Anchor Health** — when the `Portfolio Anchors` row in `stages[]` has status `done`, also render this per-product summary table from `portfolio_anchors.products` after the Progress Table:

| Product | Features | Solutions | Delivered | Unmet | Quality |
|---------|----------|-----------|-----------|-------|---------|
| {portfolio_anchors.products[i].product_slug} | {portfolio_anchors.products[i].features} | {portfolio_anchors.products[i].solutions} | {portfolio_anchors.products[i].needs_delivered} | {portfolio_anchors.products[i].needs_undelivered} | OK or {portfolio_anchors.products[i].quality_issues} flags |

Render one row per element of `portfolio_anchors.products`. Coverage above 70% (delivered / total needs) indicates healthy anchoring. Products with quality flags need attention before customer-facing use — point users to `/trends-dashboard` for per-solution detail.

When the phase is `modeling` or `modeling-paths` and the Portfolio Bridge stage's status is `ready`, lead the next-action recommendation with: "Before starting the value modeler, run `/bridge portfolio-to-tips` to ground your solutions in real products." (The Portfolio Bridge details string already reflects the `(upgrade available)` annotation when context version is below 3.1; no extra LLM derivation needed.)

**Scoring Summary** (if candidates exist):
- Average score: {scoring.avg_score}
- Leading indicators: {scoring.leading_pct}%
- Confidence: {scoring.confidence_distribution.high} high, {scoring.confidence_distribution.medium} medium, {scoring.confidence_distribution.low} low

**Dimension Balance** (if candidates exist) — render one row per element of `dimension_balance[]` from the JSON:

| Dimension | ACT | PLAN | OBSERVE | Total |
|-----------|-----|------|---------|-------|
| {dimension_balance[i].dimension} | {.act} | {.plan} | {.observe} | {.total} |

The script always emits all four dimensions; if a dimension has no candidates yet, its row will show zeros. For non-English projects, translate the dimension labels to the project language.

After the tables:
- **Phase** — translate the `phase` value into plain language (see reference below)
- **Stale warnings** — if `stale_warnings` is non-empty, show them as priority actions before regular next steps
- **Artifacts** — note which log files and outputs exist

Keep the tone warm and oriented toward action — this is a welcome-back moment, not a status report.

### 5. Recommend Next Action

Present each entry from `next_actions` with the skill name and reason. Offer to proceed with the top recommendation immediately.

If the phase is `complete`, congratulate the user and present the downstream options grouped by purpose (see "Downstream Options for Completed Reports" below). Highlight the top 2-3 most impactful actions based on what hasn't been done yet. Offer to proceed with the user's choice.

## Phase Reference

Use the `phase` field returned by `project-status.sh` verbatim to look up the row below — never re-derive `phase` from `workflow_state` or from the count fields. The script already considers all of those when it sets `phase`.

| Phase | Meaning | What to do |
|-------|---------|------------|
| `scouting` | No candidates yet | Run `trend-scout` |
| `researching` | Web research in progress | Re-invoke `trend-scout` to continue |
| `generating` | Candidate generation in progress | Re-invoke `trend-scout` to continue |
| `selecting` | Candidates presented, finalizing | Re-invoke `trend-scout` to finalize |
| `modeling` | Candidates agreed, value model not yet built | Run `/bridge portfolio-to-tips` if portfolio exists, then `value-modeler` |
| `modeling-paths` | Relationship networks built, solutions pending | Continue `value-modeler` |
| `modeling-scoring` | Solutions generated, BR scoring pending | Continue `value-modeler` |
| `modeling-curating` | Ranked solutions complete, curation pending | Continue `value-modeler` for optional catalog curation |
| `modeling-complete` | Value model complete with ranked solutions | Run `trend-report`, or `/trends-catalog import` |
| `reporting` | Value model complete, report not yet generated | Run `trend-report` |
| `verification` | Report done, claims pending verification | Run `cogni-claims:claims` |
| `revision` | Claims verified and resolved, report revision pending | Run `trend-report` Phase 5 (revision) |
| `complete` | All stages finished | Report complete — choose from downstream options below |

**Stale Blueprints:** When `stale_warnings` contains a `stale_blueprints` entry (portfolio context
was updated after blueprints were generated), prepend a re-anchor recommendation to the next actions
for phases `modeling-scoring`, `modeling-curating`, `modeling-complete`, `reporting`, and `complete`:
> "Portfolio context has changed since blueprints were generated. Run 're-anchor solutions' via
> the value-modeler to update solution mappings with current portfolio data."

This is automatically handled by `project-status.sh --health-check`, which prepends the re-anchor
action to `next_actions` when the condition is detected.

### Downstream Options for Completed Reports

When `phase` is `complete`, the `next_actions` array from `project-status.sh` contains the full set of downstream options. Present them grouped by purpose:

**Polish & Verify**
- `cogni-copywriting:copywrite` — Polish report prose for executive readability (tone scope)
- `cogni-claims:claims` — Verify extracted claims against cited sources
- `trend-report` Phase 5 — Revise report after claims resolution (apply corrections, remove unverifiable claims)

**Visualize**
- `cogni-visual:story-to-infographic` + `/render-infographic` — Create an editorial infographic from the trend report (optional, for premium Pencil-rendered visual header in enriched HTML)
- `cogni-visual:enrich-report` — Themed HTML with Chart.js visualizations and concept diagrams (detects and reuses existing infographic if story-to-infographic was run first)
- `cogni-visual:story-to-slides` — PowerPoint presentation brief
- `cogni-visual:story-to-web` — Scrollable web landing page
- `cogni-visual:story-to-storyboard` — Multi-poster print storyboard

**Accumulate**
- `cogni-trends:trends-catalog` — Import to industry catalog for cross-pursuit reuse

**Dashboard**
- `cogni-trends:trends-dashboard` — Interactive HTML dashboard of full project lifecycle

Only show actions that appear in `next_actions` (e.g., skip copywriting if already applied, skip enrich-report if already done, skip dashboard if already generated). Present the top 2-3 as recommended and the rest as "also available". Offer to proceed with the user's choice immediately.

All visualization skills (`story-to-*`) consume `tips-trend-report.md` directly — no intermediary step (like cogni-narrative) is needed. Pass the report path as `source_path` and extract `arc_id` from the report's YAML frontmatter to pass as the `arc_id` parameter — this ensures correct arc propagation even if frontmatter parsing is inconsistent.

## Multi-Session Design

This skill is the recommended re-entry point after heavy sessions. TIPS work naturally spans multiple sessions — web research, candidate generation, candidate review, value modeling, and report writing each consume significant context. Other TIPS skills proactively recommend `/trends-resume` when they detect a heavy session (Phase 1 web research, Phase 2 generation, or report assembly completed).

When presenting the status summary, acknowledge what the user accomplished in previous sessions if recent timestamps suggest productive recent work. This continuity helps users feel their work persists and builds confidence in the multi-session workflow.

## Language Support

This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

- **Communication Language**: Read workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD) first. If not found, fall back to project language from `tips-project.json` or `trend-scout-output.json`. Communicate with the user in this language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no language is found anywhere, default to English.
