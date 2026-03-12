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

TIPS projects span multiple sessions and skills (trend-scout → trend-report → verification). Without a clear re-entry point, users lose context between sessions and waste time figuring out what they already did. This skill bridges that gap: it reads the project state, surfaces progress at a glance, and recommends the most valuable next step.

## Workflow

### 1. Find TIPS Projects

Discover TIPS projects in the workspace using the discovery script:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

Returns JSON with `count` and `projects` array. Each project includes `path`, `slug`, `industry`, `subsector`, `research_topic`, `workflow_state`, `candidates_total`, and `has_report`.

The script searches:
1. The current workspace (`$COGNI_WORKSPACE_ROOT` or `$PWD`) for `cogni-tips/*/tips-project.json`
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

The script returns JSON with `project`, `counts`, `scoring`, `artifacts`, `phase`, `next_actions`, and `stale_warnings`.

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
| Trend Report | Done / Pending | {report_sections}/4 sections |
| Claims Registry | Done / Pending | {claims_total} claims extracted |
| Insight Summary | Done / Skipped | |
| Claim Verification | Done / Pending / Skipped | {verdict}: {passed} passed, {failed} failed |
| Executive Polish | Done / Skipped | tone (cogni-copywriting) |

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
| `reporting` | Candidates agreed, report not yet generated | Run `trend-report` |
| `verification` | Report done, claims pending verification | Run `cogni-claims:claim-work` |
| `modeling` | Report done, value model not yet built | Run `value-modeler` |
| `modeling-paths` | Relationship networks built, solutions pending | Continue `value-modeler` |
| `modeling-scoring` | Solutions generated, BR scoring pending | Continue `value-modeler` |
| `modeling-curating` | Ranked solutions complete, curation pending | Continue `value-modeler` for optional catalog curation |
| `modeling-complete` | Value model complete with ranked solutions | Run `/tips-catalog import` or export/visualize Big Block |
| `complete` | All stages finished | Export or visualize results |

## Multi-Session Design

This skill is the recommended re-entry point after heavy sessions. TIPS work naturally spans multiple sessions — web research, candidate generation, candidate review, and report writing each consume significant context. Other TIPS skills proactively recommend `/tips-resume` when they detect a heavy session (Phase 1 web research, Phase 2 generation, or report assembly completed).

When presenting the status summary, acknowledge what the user accomplished in previous sessions if recent timestamps suggest productive recent work. This continuity helps users feel their work persists and builds confidence in the multi-session workflow.

## Language

- **Communication Language**: Read the project language from `tips-project.json` or `trend-scout-output.json`. If a language is found, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no language is found, default to English.
