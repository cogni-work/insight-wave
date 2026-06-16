---
name: consult-dashboard
description: |
  Generate an interactive HTML dashboard showing a cogni-consult engagement's
  status — action fields, deliverables, design-thinking stage, and persona-review
  progress. Use whenever the user mentions dashboard, engagement dashboard,
  engagement status, "show me the engagement", "visualize the engagement", WBS
  view, status overview, or wants to see the engagement in a browser — even if
  they don't say "dashboard".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# Consult Dashboard

Generate a self-contained HTML dashboard that visualizes a consulting engagement's
status — the action-field work breakdown, every deliverable's state and
design-thinking stage, acting-persona review progress, knowledge-base linkage, and
the recommended next action. The dashboard opens in the browser and is the visual
sibling of the text WBS table that `consult-resume` and `consult-action-fields`
render inline.

## Core Concept

Engagement status lives in `consult-project.json` plus one `field.json` per action
field, where each deliverable carries its own `state`, `dt_stage`, and
`persona_review`. The text WBS table is good for a quick check; this dashboard is for
visual exploration — scanning field-by-field progress, spotting which deliverables are
stuck mid-loop, and seeing persona-review coverage at a glance.

Deliverable state is the **single source of truth** (it lives only in `field.json`);
field and engagement completion are **derived at read time**, never stored. The
generator is **read-only** — it never modifies any engagement file.

## Workflow

### 1. Find the Active Engagement

Discover engagements with `scripts/discover-projects.sh` (the registry wrapper), or scan
for `consult-project.json` files under `cogni-consult/` paths. If multiple engagements
exist, ask the user which one to open. Store the resolved engagement directory path.

### 2. Pick Theme

First, check whether `<engagement-dir>/output/design-variables.json` already exists from
a previous dashboard run. If it does, ask the user: "A dashboard theme is already
configured. Reuse it, or pick a new one?" Default to reuse — most re-runs just want fresh
data with the same look.

- **If reusing**: skip directly to step 4 (Generate the Dashboard).
- **If picking new** (or no design-variables exist): use the `cogni-workspace:pick-theme`
  skill to let the user select a theme. The skill returns `theme_path`, `theme_name`, and
  `theme_slug`.

**Additional skip conditions** (auto-select without prompting): the caller already
provided a `theme_path`, or only one theme exists in the workspace.

### 3. Generate Design Variables

Read the selected `theme.md` and produce a design-variables JSON file at
`<engagement-dir>/output/design-variables.json`, following the schema at
`$CLAUDE_PLUGIN_ROOT/skills/consult-dashboard/schemas/design-variables.schema.json`. See
the example at
`$CLAUDE_PLUGIN_ROOT/skills/consult-dashboard/examples/design-variables-cogni-work.json`.

This is the same design-variables contract the rest of the ecosystem uses, so the consult
dashboard inherits the same look as the portfolio dashboard. **What the LLM adds** beyond a
raw token extraction: derive `surface2` (~4% darker than `surface`), `accent_muted` /
`accent_dark` variants from `accent`, a Google Fonts `@import` URL, dark-theme shadow
opacity, and WCAG-AA contrast between text and surfaces.

**Required fields**: `theme_name`, `colors` (13 keys), `status` (4 keys), `fonts` (3 keys).
**Optional with defaults**: `google_fonts_import` (empty), `radius` ("12px"), `shadows`.

### 4. Generate the Dashboard

```bash
python3 $CLAUDE_PLUGIN_ROOT/skills/consult-dashboard/scripts/generate-dashboard.py "<engagement-dir>" --design-variables "<engagement-dir>/output/design-variables.json"
```

The script reads `consult-project.json` and every `action-fields/<slug>/field.json` (the
same read model as `engagement-status.sh`), counts research syntheses under `scope/research/`
and `action-fields/<slug>/research/`, loads the design-variables JSON, writes a self-contained
HTML file at `<engagement-dir>/output/dashboard.html`, and prints
`{"success": true, "data": {"path": ..., "theme": ..., "completion_pct": ...}, "error": ""}`.

**Legacy fallback**: the script also accepts `--theme <path-to-theme.md>` (best-effort
markdown parse) for CI/automated runs. Precedence: `--design-variables` > `--theme` >
built-in default.

### 5. Open in Browser

```bash
open "<engagement-dir>/output/dashboard.html"
```

Tell the user the dashboard is open. To refresh after working on deliverables, just rerun the
script (re-running overwrites the previous `output/dashboard.html`), or let the
`consult-dashboard-refresher` agent regenerate it at a milestone — see Milestone Dashboard below.

## Milestone Dashboard

The dashboard is also a checkpoint tool, not just a capstone. Once an engagement has a theme
configured (`output/design-variables.json`), the engagement skills offer a fresh dashboard at
natural milestones — `consult-design-thinking` after a deliverable reaches `complete` (or its
persona review closes), `consult-action-fields` after the WBS structure changes, and
`consult-resume` at re-entry. At those checkpoints the skill delegates to the
`consult-dashboard-refresher` agent (`engagement_dir`, `plugin_root: $CLAUDE_PLUGIN_ROOT`), which
runs the read-only generator and opens the HTML without a theme prompt. When no theme is
configured yet, the skills point the consultant back here to set one up first.

## Dashboard Sections

The generated HTML is a single self-contained page with these sections:

1. **Header** — engagement name, SMART key question, engagement-state badge, scope-state
   badge, language, last updated.
2. **Progress** — derived overall completion % (deliverables complete / total), with stat
   cards for action fields, deliverables, persona reviews done, and research syntheses, plus a
   progress bar and a complete/in-progress/pending breakdown.
3. **Action fields — work breakdown** — one card per action field showing the field title,
   framing, derived state, and a `done/total` count; each deliverable row shows its title, a
   state badge, a five-step design-thinking indicator (empathize→define→ideate→prototype→test
   with the current stage highlighted), and its persona-review status. A deliverable that an
   upstream change has invalidated (`lineage_status.status: "stale"`) carries a **stale badge**
   next to its state, and a deliverable with declared dependencies shows a **`⤴ depends on`**
   hint listing the upstream deliverables to refresh first. A deliverable that has been published
   via `consult-publish` shows a **`📤` publish sub-row** — one chip per published format naming
   the format, the brief path, and the publish date, with a **`→ render in Claude Design`** pointer
   (hand the brief to claude.ai/design to render). An unpublished deliverable shows no sub-row.
4. **Knowledge base** — the bound knowledge-base slug and the count of research synthesis files
   across scope and action fields.
5. **Next action** — a single recommended next step derived from scope state and deliverable
   states. Stale deliverables take precedence: when any exist, the recommendation is to refresh
   them upstream-first (the layer-0 deliverable in the topological refresh order) before any
   pending or in-progress work; otherwise it falls through to finish scoping / continue an
   in-progress deliverable / start the next one / — once everything is complete — publish a
   complete-but-unpublished deliverable with `consult-publish`, or (when all are published) hand
   the briefs to Claude Design to render.
6. **Refresh order** — appears when deliverables are stale: the stale set grouped into
   topological layers (layer 0 first — safe to refresh now, since nothing else stale depends on
   it; deeper layers become reliable once the layer above is refreshed). When nothing is stale it
   shows a "current" note; when the dependency-graph engine is unavailable the section is omitted
   entirely and the rest of the dashboard still renders (graceful degradation).

A **Warnings** card appears only when a `field.json` is unreadable (surfaced, never conflated
with "pending").

## Important Notes

- The dashboard is **read-only** — it visualizes engagement state, it does not modify any file.
- The HTML file is fully self-contained (inline CSS, no external dependencies beyond an optional
  Google Fonts import).
- Re-running the script overwrites the previous dashboard at `output/dashboard.html`.
- **Interaction language**: communicate with the user (status messages, instructions,
  recommendations, questions) in the resolved interaction language — the workspace default,
  overridden by the user's message language — not the engagement's `language` field, which is
  the deliverable axis (it controls the dashboard document's `<html lang>` and the language
  badge, not how you address the user). Technical terms, skill names, and CLI commands remain in
  English. See `$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`.
