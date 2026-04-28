# Tour: Install to Infographic

**Duration**: 45 minutes | **Modules**: 5 | **Track**: Workflow-tour
**Pipeline**: cogni-workspace → cogni-workspace (themes) → cogni-visual
**Prerequisites**: None — this is the first-run capstone. For deeper plugin context use `/cogni-help:cheatsheet cogni-workspace` or `/cogni-help:cheatsheet cogni-visual`, or read `docs/plugin-guide/cogni-workspace.md` and `docs/plugin-guide/cogni-visual.md`.
**Audience**: First-time installers — verify the toolchain end-to-end by rendering an infographic

---

This tour is the first-run capstone for the insight-wave ecosystem. You install
plugins, initialize the workspace, install MCP servers, build a theme from your
company website (or pick a preset), and render your first infographic. By the
end, the toolchain is wired up and you've shipped a real deliverable.

If you've already run `install-to-infographic` once, this tour is the refresher
showing the chain end-to-end. The exercises confirm the chain is healthy.

## Module 1: Install the Marketplace and Plugins

### Theory (5 min)

insight-wave is a 13-plugin Claude Code marketplace. Plugins are installed via
`/plugin marketplace add cogni-work/insight-wave` followed by
`/plugin install <plugin>@insight-wave` for each desired plugin.

For this tour you minimally need `cogni-workspace` and `cogni-visual`. Install
the rest when you reach a follow-on workflow that needs them.

Auto-update: enable inside `/plugin → Marketplaces → insight-wave` so new
versions arrive without re-running install. Plugin versions live in
`plugin.json` and are mirrored in the marketplace manifest — auto-update
detects new versions via marketplace.json.

The 13 plugins span four tiers:
- Foundation: cogni-workspace, cogni-help, cogni-claims, cogni-wiki
- Content production: cogni-research, cogni-narrative, cogni-copywriting, cogni-visual
- Domain pipelines: cogni-trends, cogni-portfolio, cogni-sales, cogni-marketing, cogni-website
- Meta: cogni-consulting (orchestrates the rest)

### Demo

Install the foundation:
1. Run `/plugin marketplace add cogni-work/insight-wave`.
2. Install cogni-workspace: `/plugin install cogni-workspace@insight-wave`.
3. Install cogni-visual: `/plugin install cogni-visual@insight-wave`.
4. Confirm via `/plugin` — both should appear as installed.
5. Show how to enable auto-update.

### Exercise

For the learner's actual setup, confirm the marketplace is added and the two
foundation plugins are installed. If they want to install more for follow-on
workflows, do it now in the same step.

### Quiz

1. **Multiple choice**: To run the `research-to-report` workflow, which plugins
   beyond `cogni-workspace` and `cogni-visual` are needed?
   - a) cogni-research, cogni-narrative — b) cogni-research only —
     c) cogni-narrative, cogni-portfolio — d) cogni-trends, cogni-narrative
   **Answer**: a (research-to-report chains research → narrative → visual)

2. Why does insight-wave use a marketplace pattern rather than per-plugin installs?
   **Answer**: Centralized version detection, shared dependencies (themes, MCP
   servers), and atomic updates across the ecosystem.

### Recap

- 13-plugin marketplace; install via `/plugin marketplace add` + per-plugin install
- For this tour: cogni-workspace + cogni-visual minimum
- Auto-update via marketplace; marketplace.json mirrors plugin.json versions
- Install other plugins when reaching follow-on workflows

---

## Module 2: Initialize the Workspace and Install MCP Servers

### Theory (6 min)

`cogni-workspace` is the foundation every other plugin depends on — it owns
shared state: themes, environment variables, MCP server configuration, and
workspace health diagnostics.

`/manage-workspace` initializes the workspace folder structure on disk —
themes/ directory, design-variables defaults, project-config templates.
`/install-mcp` then installs three MCP servers in one pass:
- **claude-in-chrome** — browser automation (theme extraction, website preview, claims verification)
- **excalidraw** — diagram rendering (infographics, concept diagrams, architecture diagrams)
- **pencil** — editorial visual rendering (Economist-style infographics, slides, posters)

All three are Node-based; install handles dependency setup. The three MCP servers
together unlock the full visual rendering capability — Excalidraw for hand-drawn
sketchnote/whiteboard styles, Pencil for editorial styles, claude-in-chrome for
live web extraction.

### Demo

Initialize the workspace:
1. Run `/manage-workspace`.
2. Choose a target directory.
3. Show the produced folder structure.
4. Run `/install-mcp` (accept defaults to install all three).
5. Run `/workspace-status` — every MCP should report green.

If a MCP install fails, show the diagnostic path (`/workspace-status` reports
red, `/install-mcp <name>` retries the specific server, restart Claude session
for MCP to reattach).

### Exercise

For the learner's setup, run `/manage-workspace` and `/install-mcp`. Confirm via
`/workspace-status` that all three MCPs are green. If any are red, troubleshoot
before continuing.

### Quiz

1. Why does the toolchain need three MCP servers rather than one?
   **Answer**: Each handles a different rendering style — Excalidraw for hand-drawn,
   Pencil for editorial, claude-in-chrome for browser-based extraction. They're
   complementary, not redundant.

2. **Hands-on**: Run `/workspace-status` and identify one component that's not
   yet configured. Decide whether to fix it now or defer.

### Recap

- `/manage-workspace` initializes folder structure
- `/install-mcp` installs claude-in-chrome, excalidraw, pencil
- `/workspace-status` is the health check — all MCPs should be green
- MCP servers complement: hand-drawn (Excalidraw), editorial (Pencil), browser (chrome)

---

## Module 3: Build a Theme

### Theory (6 min)

A theme is the visual contract every plugin honors. `cogni-workspace` owns themes:
the active theme drives colors, fonts, and design variables across slides,
infographics, dashboards, and websites.

Three ways to build a theme:
- **Extract from a live website** — `/manage-themes extract https://your-company.com`
  reads the site via claude-in-chrome MCP and pulls colors, fonts, logo
- **Import from a PowerPoint template** — `/manage-themes import` reads a .pptx
  template and extracts the slide-master theme
- **Pick a preset** — `/manage-themes presets` lists curated themes (Economist,
  Bauhaus, Cogni Default, etc.)

For sites behind a login wall, the extractor can't read them — pass a PowerPoint
template or pick a preset instead.

`/pick-theme` makes a theme the active default for every visual plugin. Theme
switches are deliberately global — re-render any deliverable and it picks up
the new theme.

### Demo

Build a theme:
1. Pick the source: live website, PowerPoint template, or preset.
2. For live extraction: `/manage-themes extract https://example.com`.
3. Watch the extraction phases (claude-in-chrome reads → colors/fonts/logo parsed → theme stored).
4. Run `/pick-theme` to make it the active default.
5. Show the design variables the theme defines.

### Exercise

Extract a theme from your own company URL (or pick a preset if the site is
inaccessible). Make it the active theme via `/pick-theme`. Confirm the design
variables match your brand.

### Quiz

1. Why is theme switching deliberately global?
   **Answer**: Visual consistency across deliverables. Per-deliverable theming
   produces drift; global switching forces deliberate brand decisions.

2. **Hands-on**: Run `/manage-themes` and find one design variable (e.g. primary
   color hex) that would change if your brand updated.

### Recap

- Themes drive colors, fonts, design variables across all visual plugins
- Three sources: extract from URL, import from PPTX, pick a preset
- `/pick-theme` makes a theme global; switches reskin everything
- Sites behind login walls: use PPTX or preset instead of extraction

---

## Module 4: Render the First Infographic

### Theory (6 min)

`cogni-visual` produces visual deliverables. For first-run verification, the
ideal test is rendering an infographic in two presets — one Excalidraw-backed
(sketchnote or whiteboard), one Pencil-backed (economist or editorial). If both
render successfully, both MCP servers are wired correctly.

Style → renderer mapping:
- `sketchnote` / `whiteboard` → Excalidraw
- `economist` / `editorial` / `data-viz` / `corporate` → Pencil

The user provides a short narrative paragraph (a 4-6 sentence story works well as
the first try). The renderer extracts hero numbers, key claims, and the story
arc, then assembles the infographic.

A blank file on render usually means the MCP server isn't running. Run `/mcp` to
check status; re-run `/install-mcp <name>` if needed and restart the session for
the MCP to reattach.

### Demo

Render two infographics:
1. Provide a short narrative (4-6 sentences) — a real one from your work, or a
   sample about a recent industry development.
2. Run `/story-to-infographic --style=sketchnote` — produces a hand-drawn
   `.excalidraw` file.
3. Run `/story-to-infographic --style=economist` — produces an editorial
   `.pen` file.
4. Open both. Confirm the theme from Module 3 is applied (colors should match
   your brand).

### Exercise

For the rendered files, switch the workspace theme via `/pick-theme` and re-render.
Confirm the theme switch propagates to both the Excalidraw and Pencil outputs.

### Quiz

1. Why render two presets rather than one for the verification test?
   **Answer**: Two presets confirm both MCP servers are working — Excalidraw for
   sketchnote, Pencil for economist. One preset only confirms one MCP.

2. **Hands-on**: Run `/story-to-infographic --style=whiteboard`. The output
   should be a different visual style but the same theme. Confirm.

### Recap

- Two presets verify both MCPs: sketchnote/whiteboard (Excalidraw), economist/editorial (Pencil)
- A short narrative (4-6 sentences) is enough to test rendering
- Both presets inherit the active workspace theme
- Blank file = MCP not running; check `/mcp`, reinstall, restart

---

## Module 5: Pick a Follow-On Workflow

### Theory (5 min)

Install-to-infographic is the bootstrap workflow. By the end of Module 4, the
toolchain is verified end-to-end — workspace, MCPs, theme, and rendering all work.
From here, every other workflow in insight-wave builds on this foundation.

Six follow-on workflows cover the most-used paths:

| If you want to... | Run the workflow |
|-------------------|------------------|
| Research a topic with verified sources | `tour-research-to-report` |
| Position a product for a market | `tour-portfolio-to-pitch` |
| Scout industry trends | `tour-trends-to-solutions` |
| Build multi-channel marketing content | `tour-content-pipeline` |
| Generate a website from your portfolio | `tour-portfolio-to-website` |
| Run a structured consulting engagement | `tour-consulting-engagement` |

Each tour assumes you've completed install-to-infographic — they don't re-explain
workspace setup, MCP installation, or theme management. They focus on the
plugin-specific chain.

### Demo

Show the follow-on tour map:
1. Open `cogni-help/skills/workflow/references/workflows/` — show all 7 templates.
2. Open `cogni-help/skills/teach/references/courses/tours/` — show all 7 tour courses.
3. Run `/teach courses` to see the full curriculum.
4. Pick the most relevant follow-on for the team's actual next deliverable.

### Exercise

Have the learner identify the deliverable they need next quarter. Pick the
matching follow-on tour. Read its Prerequisites line and confirm the learner is
either comfortable with the named plugins (cheatsheets and `docs/plugin-guide/<plugin>.md`
files cover them) or accepts the inline-summary fallback.

### Quiz

1. Why does install-to-infographic come first regardless of the team's eventual goal?
   **Answer**: Every other workflow depends on the workspace + theme + MCP
   foundation. Skipping the bootstrap leads to broken renders and missing themes
   downstream.

2. **Hands-on**: Pick a follow-on tour and read its Prerequisites line. Is the
   learner comfortable with the named plugins? If not, what's the path —
   cheatsheet, plugin-guide, or inline-summary fallback?

### Recap

- install-to-infographic is the bootstrap; every other workflow builds on it
- Six follow-on tours cover the most-used pipelines
- Each follow-on assumes workspace + MCP + theme are already set up
- Pick the follow-on that matches the team's actual next deliverable

---

## Tour Complete

Next steps:
- Pick a follow-on tour and run it against a real engagement
- Iterate on the theme as the brand evolves (`/manage-themes` for new extractions)
- Install additional plugins when a follow-on workflow needs them
- See the canonical playbook: `cogni-help/skills/workflow/references/workflows/install-to-infographic.md`
- See the narrative tutorial: `docs/workflows/install-to-infographic.md`
