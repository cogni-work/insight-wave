---
name: tips-resume
description: |
  Resume, continue, or check status of a TIPS trend scouting project.
  Use whenever the user mentions "continue tips", "resume tips", "resume trends",
  "where was I", "tips status", "what's next", "continue the project",
  "resume trend project", "check scan progress", "trend status",
  or opens a session that involves an existing cogni-tips project —
  even if they don't say "resume" explicitly.
---

# TIPS Resume

Session entry point for returning to trend scouting work. This skill orients the user by showing where they left off and what to do next — the dashboard view that keeps multi-session TIPS projects on track.

## Core Concept

TIPS projects span multiple sessions and skills (trend-scout → value-modeler → trend-report → verification). Without a clear re-entry point, users lose context between sessions and waste time figuring out what they already did. This skill bridges that gap: it reads the project state, surfaces progress at a glance, and recommends the most valuable next step.

## Workflow

### 1. Find TIPS Projects

Discover TIPS projects in the workspace using the discovery script.

**Determine the workspace root** before calling the script. The workspace root is the directory that contains the `cogni-tips/` project folder. Check in this order:
1. `$PROJECT_AGENTS_OPS_ROOT` — if set (via `settings.local.json` env block), use it
2. Otherwise, look for a `cogni-tips/` directory under the current working directory
3. If not found under `$PWD`, check if there's a `.workspace-config.json` nearby that indicates the workspace location

Pass the root explicitly with `--root`:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json --root "<workspace-root>"
```

If you cannot determine a specific root, omit `--root` and the script falls back to `$PROJECT_AGENTS_OPS_ROOT` or `$PWD`:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

Returns JSON with `count` and `projects` array. Each project includes `path`, `slug`, `industry`, `subsector`, `research_topic`, `workflow_state`, `candidates_total`, and `has_report`.

The script searches:
1. The workspace root (from `--root`, `$PROJECT_AGENTS_OPS_ROOT`, or `$PWD`) for `cogni-tips/*/tips-project.json`
2. The global project registry (`~/.claude/cogni-tips-projects.json`) for projects created in other workspaces

If `count` is 0:
- First, ask the user if they have a project in a different directory (e.g., OneDrive, external workspace). If they provide a path, register it:
  ```bash
  bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --register "<path>"
  ```
  Then re-run discovery.
- If no path is provided, suggest the `trend-scout` skill to start a new project.

### 2. Select Project

- One project found — use it automatically.
- Multiple projects — present them with industry + topic + status and ask which one to continue.

### 3. Run Project Status with Health Check

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/project-status.sh "<project-dir>" --health-check
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

| Stage | Status | Details |
|-------|--------|---------|
| Web Research | Done / Pending | {web_research_status}, {candidates_web} signals found |
| Candidate Generation | Done / Pending | 60 generated |
| Candidate Selection | Done / Pending | {candidates_total}/60 agreed |
| Portfolio Bridge | Done / Ready / N/A | v{context_version} context, {features_count} features |
| Value Chains & Themes | Done / Pending | {themes_count} strategic themes |
| Solution Templates | Done / Pending | {solutions_count} solutions generated |
| BR Scoring & Ranking | Done / Pending | {ranked_count} solutions ranked |
| Solution Blueprints | Done / Pending / N/A | {blueprints}/{solutions_count} blueprinted, avg readiness {avg_readiness}, {anchored_solutions} portfolio-anchored |
| Portfolio Anchors | Done / N/A | {products_count} products, {features_count} features, {delivered}/{unmet} needs, {quality_issues} quality flags |
| Trend Report | Done / Pending | {report_sections}/4 sections |
| Claims Registry | Done / Pending | {claims_total} claims extracted |
| Insight Summary | Done / Skipped | |
| Claim Verification | Done / Pending / Skipped | {verdict}: {passed} passed, {failed} failed |
| Executive Polish | Done / Skipped | tone (cogni-copywriting) |
| Dashboard | Done / Skipped | interactive HTML visualization |

**Solution Blueprints row** — derived from `counts.blueprints`, `counts.anchored_solutions`, `counts.avg_readiness`:
- **Done**: `blueprints` > 0 — show blueprint count, average readiness score, and anchored count
- **Pending**: `solutions_count` > 0 but `blueprints` = 0 — solutions exist but no blueprints generated yet
- **N/A**: `solutions_count` = 0 — no solutions generated yet

**Portfolio Anchors row** — derived from `portfolio_anchors` in status JSON:
- **Done**: `portfolio_anchors.total` > 0 — show product count, feature count, delivered/unmet needs, and quality flag count
- **N/A**: `portfolio_anchors.total` = 0 — no portfolio-anchored solutions exist

**Portfolio Anchor Health** (show when `portfolio_anchors.total` > 0, after the Progress Table):

Render a per-product summary table from `portfolio_anchors.products`:

| Product | Features | Solutions | Delivered | Unmet | Quality |
|---------|----------|-----------|-----------|-------|---------|
| {product_slug} | {features} | {solutions} | {needs_delivered} | {needs_undelivered} | OK or {quality_issues} flags |

Coverage above 70% (delivered / total needs) indicates healthy anchoring. Products with quality flags need attention before customer-facing use — point users to `/tips-dashboard` for per-solution detail.

**Portfolio Bridge row** — derived from `portfolio_bridge` in status JSON:
- **Done**: `context_file` is true — show version and features count
- **Ready**: `portfolio_project_found` is true but `context_file` is false — recommend running `/bridge portfolio-to-tips` before value-modeler
- **N/A**: `portfolio_project_found` is false — no portfolio project in workspace

When the phase is `modeling` or `modeling-paths` and the Portfolio Bridge status is **Ready**, lead the next action recommendation with: "Before starting the value modeler, run `/bridge portfolio-to-tips` to ground your solutions in real products."

**Scoring Summary** (if candidates exist):
- Average score: {avg_score}
- Leading indicators: {leading_pct}%
- Confidence: {high} high, {medium} medium, {low} low

**Dimension Balance** (if candidates exist):

| Dimension | ACT | PLAN | OBSERVE | Total |
|-----------|-----|------|---------|-------|
| Externe Effekte | N | N | N | N |
| Neue Horizonte | N | N | N | N |
| Digitale Wertetreiber | N | N | N | N |
| Digitales Fundament | N | N | N | N |

After the tables:
- **Phase** — translate the `phase` value into plain language (see reference below)
- **Stale warnings** — if `stale_warnings` is non-empty, show them as priority actions before regular next steps
- **Artifacts** — note which log files and outputs exist

Keep the tone warm and oriented toward action — this is a welcome-back moment, not a status report.

### 5. Recommend Next Action

Present each entry from `next_actions` with the skill name and reason. Offer to proceed with the top recommendation immediately.

If the phase is `complete`, congratulate the user and suggest exporting or visualizing the report.

## Phase Reference

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
| `modeling-complete` | Value model complete with ranked solutions | Run `trend-report`, or `/tips-catalog import` |
| `reporting` | Value model complete, report not yet generated | Run `trend-report` |
| `verification` | Report done, claims pending verification | Run `cogni-claims:claim-work` |
| `complete` | All stages finished | Export, visualize with `/tips-dashboard`, or run `/tips-catalog import` |

**Stale Blueprints:** When `stale_warnings` contains a `stale_blueprints` entry (portfolio context
was updated after blueprints were generated), prepend a re-anchor recommendation to the next actions
for phases `modeling-scoring`, `modeling-curating`, `modeling-complete`, `reporting`, and `complete`:
> "Portfolio context has changed since blueprints were generated. Run 're-anchor solutions' via
> the value-modeler to update solution mappings with current portfolio data."

This is automatically handled by `project-status.sh --health-check`, which prepends the re-anchor
action to `next_actions` when the condition is detected.

## Multi-Session Design

This skill is the recommended re-entry point after heavy sessions. TIPS work naturally spans multiple sessions — web research, candidate generation, candidate review, value modeling, and report writing each consume significant context. Other TIPS skills proactively recommend `/tips-resume` when they detect a heavy session (Phase 1 web research, Phase 2 generation, or report assembly completed).

When presenting the status summary, acknowledge what the user accomplished in previous sessions if recent timestamps suggest productive recent work. This continuity helps users feel their work persists and builds confidence in the multi-session workflow.

## Language Support

This skill follows the shared language resolution pattern — see [$CLAUDE_PLUGIN_ROOT/references/language-resolution.md]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md).

- **Communication Language**: Read workspace language from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD) first. If not found, fall back to project language from `tips-project.json` or `trend-scout-output.json`. Communicate with the user in this language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no language is found anywhere, default to English.
