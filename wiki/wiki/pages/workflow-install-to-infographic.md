---
id: workflow-install-to-infographic
title: "Workflow: Install to Infographic (first-run)"
type: summary
tags: [workflow, onboarding, first-run, install, infographic, mcp]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/install-to-infographic.md
status: stable
related: [plugin-cogni-workspace, concept-mcp-server-map]
---

First-run workflow with insight-wave: install the marketplace, set up your workspace, import a theme from a Claude Design bundle (or start from a preset), and render your first infographic.

## Pipeline

```
install marketplace
   ↓
cogni-workspace:manage-workspace        (initialize workspace)
   ↓
cogni-workspace:install-mcp             (install excalidraw + pencil MCPs)
   ↓
cogni-workspace:manage-themes           (import theme from a Claude Design bundle)
   ↓
cogni-workspace:story-to-infographic       (turn narrative into infographic brief)
   ↓
cogni-workspace render-infographic-...     (render via excalidraw or pencil)
```

## Duration

Roughly 30–60 minutes including MCP installation and theme setup.

## End deliverable

A themed infographic rendered as SVG (Excalidraw) or `.pen` file (Pencil), aligned with your company brand.

## How it works

The workflow is sequenced so you verify each layer before depending on it. [[plugin-cogni-workspace]] is installed first because it owns the shared workspace state the later steps read. `manage-workspace` initializes the directory structure, `install-mcp` brings up the MCP servers ([[concept-mcp-server-map]]), and `manage-themes` materializes your theme from a Claude Design bundle (Operation 10) or a theme-factory preset (Operation 5).

[[plugin-cogni-workspace]] then renders an infographic. `story-to-infographic` turns a narrative (e.g., a one-paragraph product positioning) into a structured `infographic-brief.md`. The matching render skill (Pencil for editorial, Excalidraw for sketchnote/whiteboard) then produces the visual. See [[concept-brief-based-rendering]].

## Why this is the first-run workflow

It exercises every layer of the platform — workspace foundation, MCP installation, theme inheritance ([[concept-theme-inheritance]]), brief-driven rendering — in the smallest end-to-end loop. If any layer is misconfigured, the failure surfaces here before bigger workflows hit it.

## Steps

**1 — Add the marketplace and install plugins.** `/plugin marketplace add cogni-work/insight-wave`, then `/plugin install <plugin>@insight-wave` for each. Start with cogni-workspace because this workflow's later steps read its shared workspace state. Enable auto-update under `/plugin → Marketplaces → insight-wave` so new versions arrive without repeating this step. This workflow needs only cogni-workspace; install the rest when a follow-on workflow needs them.

**2 — Initialize the workspace and install MCP servers.** `cogni-workspace:manage-workspace`, then `cogni-workspace:install-mcp`. Accept the defaults — one pass wires up Pencil, Excalidraw and claude-in-chrome. Step 4 uses Pencil and Excalidraw to render; claude-in-chrome is installed in the same pass for later workflows, and this one does not need it. Verify with `cogni-workspace:workspace-status`: every MCP should report green before continuing.

**3 — Build a theme.** `cogni-workspace:manage-themes`, then `cogni-workspace:pick-theme`. If you have a Claude Design bundle, import it (Operation 10) — the recommended path: you author the design system in Claude Design, export a handoff bundle, and the skill materializes it as a complete tiered theme. If you don't have a bundle yet, start from a theme-factory preset (Operation 5) instead. Picking the theme makes it the default for slides, infographics, dashboards and websites — see [[concept-theme-inheritance]].

**4 — Render the first infographic.** `cogni-workspace:story-to-infographic` with `--style=sketchnote`, then again with `--style=economist`. A four-to-six-sentence narrative works well as a first try. Running both presets doubles as a live check that both renderers are wired up: `sketchnote` and `whiteboard` route to Excalidraw, `economist`, `editorial`, `data-viz` and `corporate` route to Pencil. Both inherit the theme from step 3, so their colors should match.

**5 — Pick a follow-on workflow.** You now have a working workspace, a branded theme and two rendered infographics. Choose by what you want to produce next: [[workflow-research-to-report]], [[workflow-portfolio-to-pitch]], [[workflow-trends-to-solutions]], [[workflow-content-pipeline]], [[workflow-portfolio-to-website]] or [[workflow-consulting-engagement]].

## Common pitfalls

- **MCP installed but not running.** "Pencil MCP not available" almost always means the server is installed but not started. Check `/mcp`, or re-run the install for that server and restart the session.
- **Style / renderer mismatch.** The renderer dispatches off the `--style` flag. Asking for a preset whose MCP is not running can fail quietly, which is exactly why step 4 exercises both before anything downstream depends on either.
- **Workspace not initialized.** Skipping `manage-workspace` leaves `manage-themes` with nowhere to write the theme. Always run it before `manage-themes`.

**Source**: [docs/workflows/install-to-infographic.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/install-to-infographic.md)
