---
name: projects-dashboard
description: |
  This skill should be used when a partner or consultant wants a readable
  snapshot of a cogni-projects portfolio for a partner meeting — staffing
  coverage per project, at-risk projects, and portfolio value by strategic
  impact — rather than reading raw entity files. Trigger on: "projects
  dashboard", "portfolio dashboard", "partner-meeting dashboard", "show me the
  project portfolio", "portfolio health", "staffing coverage", "which projects
  are at risk", or any request to review the project portfolio at a glance —
  even if the user does not say "dashboard" explicitly.
allowed-tools: Read, Bash, Glob, Grep
---

# Projects Dashboard

Render a partner-meeting snapshot of a cogni-projects portfolio: every project
with its staffing coverage and a health flag, plus an aggregate view of
portfolio value by strategic impact. The dashboard is a **read-only** view over
the consultant, project, and assignment records that `projects-setup` and
`projects-entities` produce — it never changes portfolio state.

## Core concept

The dashboard reads a **portfolio** — one `cogni-projects/<portfolio-slug>/`
directory rooted by `projects-portfolio.json` — and derives, from the entity
records:

- **Staffing coverage** per project: a project lists the roles it still needs in
  `open_roles`; a role counts as *filled* when a planned or active assignment
  for that project names a matching role. The dashboard shows filled-vs-open and
  a health flag (fully staffed / partially staffed / unstaffed / closed).
- **Portfolio value**: projects grouped by `strategic_impact` (1–5), so the
  high-impact work is visible at a glance.
- **Utilization**: a simple average of consultant `allocation_pct`.

Role labels are free strings, so a label an assignment names that no `open_roles`
entry matches is surfaced as a warning rather than silently mis-counted. Any
missing or malformed field produces a **partial snapshot with a warning**, never
a hard failure — a portfolio mid-authoring still renders.

## Workflow

### Step 1: Find the portfolio

Locate the target `cogni-projects/<portfolio-slug>/` directory (the one holding
`projects-portfolio.json`). If the user named a portfolio, use it; if only one
portfolio exists, use it; otherwise list the candidates and ask which one.

### Step 2: Render the dashboard

Run the renderer against the portfolio directory:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/render-dashboard.py" <portfolio-dir>
```

The script writes a self-contained `output/dashboard.html` inside the portfolio
directory and prints a `{"success", "data", "error"}` envelope whose `data.path`
is the written file. When `data.partial` is `true`, `data.warnings` lists what
was missing or mismatched — relay those to the user so they know the snapshot is
incomplete and which records to fix.

### Step 3: Open it

Open the generated dashboard in a browser:

```bash
open "<portfolio-dir>/output/dashboard.html"
```

## Notes

- **Read-only.** The renderer never writes `projects-portfolio.json` (only
  `projects-entities` does, via `register-entity.py`) and never touches
  `.metadata/`. Re-running only rewrites `output/dashboard.html`.
- **Partial snapshots are expected mid-authoring.** A project without a
  `strategic_impact`, or an assignment whose `role` does not match any
  `open_roles` label, is reported in the warnings list, not treated as an error.
- **Theming is optional.** The dashboard renders with a built-in palette;
  pass `--design-variables <path.json>` to override colors when a themed look is
  wanted.
