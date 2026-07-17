---
name: projects-setup
description: |
  This skill should be used when the user wants to start a new project-portfolio
  for partner project-portfolio steering — cogni-projects models consultants,
  projects, and staffing, so new portfolio work starts here. Trigger on: "set up
  a projects portfolio", "start a project portfolio", "new cogni-projects
  portfolio", "initialize project-portfolio steering", "create a staffing
  portfolio", or any request to begin structured consultant/project/staffing
  work — even if the user does not say "setup" explicitly.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Projects Setup

Initialize a new cogni-projects portfolio: a self-contained directory holding
consultants, projects, and assignments that later skills (staffing match,
backfilling recommender, partner-meeting dashboard) read and write. This skill
is the foundation entry point — run it once per portfolio before any staffing
logic exists.

## Core concept

A **portfolio** is one `cogni-projects/<portfolio-slug>/` directory rooted by a
`projects-portfolio.json` manifest. The manifest is the source of truth for the
portfolio's identity and holds the (initially empty) `consultants[]`,
`projects[]`, and `assignments[]` entity lists that downstream skills populate.
A `.metadata/` directory carries the append-only logs those skills write to.

Setup is **idempotent**: re-running against an already-initialized portfolio
returns `{"success": false, ...}` with an "already initialized" message and
never overwrites existing data.

## Workflow

### Step 1: Gather portfolio identity

Determine two values from the user's request (ask only for what is missing):

- **Portfolio name** — the human-readable label (e.g. "Nordic Advisory 2026").
- **Portfolio slug** — a kebab-case identifier derived from the name (e.g.
  `nordic-advisory-2026`). Derive it automatically from the name unless the user
  supplies one.

### Step 2: Confirm before writing

Echo the resolved slug and name back to the user and confirm the target
directory `cogni-projects/<slug>/` before running the init script.

### Step 3: Scaffold the portfolio directory

Run the init script (resolved against `CLAUDE_PLUGIN_ROOT`, with a plugin-cache
fallback so it works whether the plugin is loaded locally or from cache):

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/*/cogni-projects/*/ 2>/dev/null | head -1)}/scripts/portfolio-init.sh" "<portfolio-slug>" "<portfolio-name>"
```

The script returns a single JSON line `{"success": bool, "data": {...},
"error": "string"}`:

- `success: true` — the portfolio was scaffolded. `data.path` is the new
  directory; `data.slug` echoes the slug.
- `success: false` with an "already initialized" error — the portfolio already
  exists; nothing was changed. This is a clean no-op, not a failure.

### Step 4: Summarize and point to next steps

Report the created directory and outline what comes next: define the data model
and author entities, then run the staffing match engine. Keep the summary short.

## Output

```
cogni-projects/<portfolio-slug>/
├── projects-portfolio.json    Root manifest (identity + consultants/projects/assignments)
├── consultants/               Consultant entity records (populated later)
├── projects/                  Project entity records (populated later)
├── assignments/               Assignment records (populated later)
└── .metadata/                 Append-only logs (execution, staffing, decisions)
```
