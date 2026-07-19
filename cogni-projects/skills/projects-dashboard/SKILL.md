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
  for that project names a matching role. The dashboard shows filled-vs-open
  plus a health flag derived deterministically from (roles filled, roles listed,
  project status):

  | Flag | Condition |
  |------|-----------|
  | `closed` | `status` is `closed` |
  | `staffing unknown` | the project declares no `open_roles` at all (key absent, or present with no value) — fill status cannot be derived |
  | `no open roles` | `open_roles` is present but empty |
  | `fully staffed` | every listed role is covered |
  | `unstaffed` | an **active** project has zero roles covered |
  | `<open>/<total> roles open` | otherwise — the leading number is the count of roles **still open** (not filled), the trailing number the total |

- **Portfolio value**: projects grouped by `strategic_impact` (1–5), so the
  high-impact work is visible at a glance.
- **Utilization**: `data.avg_allocation`, the average of consultant
  `allocation_pct`, plus `data.fully_allocated`, the count of consultants at or
  above 100%. Consultants with no `allocation_pct`, or a non-numeric one (each
  surfaced as a warning), are **excluded** from the average rather than counted
  as zero, so a thinly authored portfolio is not made to look under-allocated.
  When no consultant has a usable `allocation_pct`, `data.avg_allocation` is
  `null` — report it as unknown, not `0%`.

Role labels are free strings, so when a project lists `open_roles`, a label an
assignment names that no entry matches is surfaced as a warning rather than
silently mis-counted (a project with absent or empty `open_roles` yields no such
warning). Any
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
python3 "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/render-dashboard.py" "<portfolio-dir>"
```

The script writes a self-contained `output/dashboard.html` inside the portfolio
directory and prints a `{"success", "data", "error"}` envelope whose `data.path`
is the written file.

**When `success` is `true`:** if `data.partial` is `true`, `data.warnings` lists
what was missing or mismatched — relay those so the user knows the snapshot is
incomplete and which records to fix. Note that `partial` is set by *any*
warning, including a non-substantive one such as an unreadable
`--design-variables` file, so check what the warnings actually say before
describing the portfolio data itself as incomplete.

**When `success` is `false`:** the render did not run at all — read `error`. This
is the environment-level failure branch (missing portfolio directory, missing
`projects-portfolio.json`, unwritable `output/`), distinct from the per-entity
degradation above. A missing `projects-portfolio.json` means the directory is
not an initialized portfolio: point the user at `projects-setup` rather than
retrying the render.

### Step 3: Open it

Report `data.path` as the deliverable, then offer to open it as a convenience:

```bash
open "<data.path>"      # macOS
xdg-open "<data.path>"  # Linux
```

A failure here is cosmetic — the dashboard is already written to `data.path`.

## Notes

- **Read-only.** The renderer never writes `projects-portfolio.json` (only
  `projects-entities` does, via `register-entity.py`) and never touches
  `.metadata/`. Re-running only rewrites `output/dashboard.html`.
- **Partial snapshots are expected mid-authoring.** A project without a
  `strategic_impact`, a project that omits `open_roles`, an assignment whose
  `role` does not match any `open_roles` label, or an entity file that cannot be
  read or decoded is reported in the warnings list, not treated as an error. One
  bad record never costs the rest of the portfolio.
- **Theming is optional.** The dashboard renders with a built-in palette;
  pass `--design-variables <path.json>` to override colors when a themed look is
  wanted.
