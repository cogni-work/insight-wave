# From Install to Infographic

Your first-run workflow with insight-wave — the step-3 capstone of the [root README install sequence](../../README.md#install). Starting from an installed, authenticated Claude Code, you add the insight-wave marketplace, set up your workspace, extract a theme from your company website, and render your first infographic. Along the way you verify that Pencil MCP and Excalidraw MCP are wired up — so later visual work doesn't stall on a missing dependency.

## Prerequisites

This guide assumes you have already completed steps 1 and — if your firm requires it — step 2 of the [root README `## Install` sequence](../../README.md#install). You are in the right place when Claude Code is installed and signed in.

Before starting, confirm:

- [ ] **Claude Code installed and authenticated** — `/status` reports `subscription`. See [`../claude-code-desktop.md`](../claude-code-desktop.md) for the platform-specific setup (macOS, Windows, authentication, troubleshooting) if you haven't done this yet.
- [ ] **Enterprise configuration applied, if your firm requires it** — GDPR, SSO, managed settings, MDM / Group Policy. See [`../deployment-guide.md`](../deployment-guide.md). Skip on a personal laptop.
- [ ] **Core requirements on the host** — terminal access (macOS, Linux, or WSL); `bash` 3.2+, `python3` (stdlib only), `jq`; optional [Obsidian](https://obsidian.md/) for browsable knowledge management.

## Step 1: Add the Marketplace

Open the Claude Code desktop app, then open its built-in **Terminal** pane — the right-panel selector at the top of the window switches between Preview / Diff / **Terminal** / Tasks / Plan. In the Terminal pane, start a Claude Code session:

```
claude
```

The rest of the commands in this guide are slash commands — type each one into the `claude` prompt inside the Terminal pane and press Enter.

The insight-wave marketplace lives at [`cogni-work/insight-wave`](https://github.com/cogni-work/insight-wave). Register it:

```
/plugin marketplace add cogni-work/insight-wave
```

**Enable automatic marketplace updates** so new plugin versions arrive without you re-running this command. Open the interactive plugin manager:

```
/plugin
```

Pick **Marketplaces → insight-wave** and switch on the auto-update option. Claude Code refreshes the marketplace at session start from then on. You can also refresh on demand:

```
/plugin marketplace update insight-wave
```

Install the plugins this workflow needs — at minimum `cogni-workspace` and `cogni-visual`:

```
/plugin install cogni-workspace@insight-wave
/plugin install cogni-visual@insight-wave
```

Or browse the **Discover** tab interactively inside `/plugin`.

## Step 2: Initialize Your Workspace

cogni-workspace is the shared foundation — it sets up the directories, themes, and MCP servers that every other plugin relies on.

```
/manage-workspace
```

This creates your workspace folder structure and walks you through initial settings. Next, install the MCP servers that visual rendering needs:

```
/install-mcp
```

Accept the defaults. When it finishes you should have Pencil MCP, Excalidraw MCP, and claude-in-chrome MCP installed — Step 3 uses claude-in-chrome to read your company website, and Step 4 uses both Pencil and Excalidraw to render infographics.

**What success looks like:** `/workspace-status` reports all MCPs as green, and your workspace directory exists on disk.

## Step 3: Build Your First Theme

Extract a visual theme from your company website so every visual output — infographics, slides, websites — automatically uses your colors, fonts, and logo. The rest of this workflow will use this theme.

```
/manage-themes extract https://your-company.com
```

Replace `your-company.com` with your actual website. The skill reads the live site via claude-in-chrome MCP, extracts the color palette and typography, and stores a new theme in your workspace themes directory.

When it finishes, browse and set your new theme as the default:

```
/pick-theme
```

**What success looks like:** `/pick-theme` lists your company theme in the available themes, the palette swatches match your website, and you can select it as the default.

**If this step fails:** the most common cause is claude-in-chrome MCP not running. Re-run `/install-mcp` or see the [cogni-workspace plugin guide](../plugin-guide/cogni-workspace.md) for manual setup. If the site is behind a login wall, `/manage-themes` also accepts a PowerPoint template or a preset — see the skill docs for alternatives.

## Step 4: Render Your First Infographic

Turn a short narrative into a one-page infographic via `/story-to-infographic`. This skill produces an infographic-brief.md first, then renders it in one of two style families: hand-drawn (via Excalidraw MCP) or editorial (via Pencil MCP). Running one of each doubles as a live check that both MCPs are wired up.

Start with the sample narrative below — it's a self-contained paragraph you can paste into the chat exactly as-is:

> In 2025, our services team delivered 47 projects across 12 industries. Roughly half touched AI transformation — a three-fold jump from 2024. Client NPS climbed to 68, and 84% of engagements led to follow-on work. The shift: clients now ask us to redesign workflows, not just ship software.

With that narrative in the chat, run the hand-drawn preset first:

```
/story-to-infographic --style=sketchnote
```

This produces an infographic-brief, then renders it via **Excalidraw MCP** into an `.excalidraw` file you can open in the Excalidraw editor. You should see a one-page visual summary of the narrative with hand-drawn styling.

Now try the editorial preset:

```
/story-to-infographic --style=economist
```

Same narrative, but this time rendered via **Pencil MCP** into a `.pen` file — a clean editorial data page in the style of The Economist. Open it in the Pencil editor to compare.

**What success looks like:** two infographics side by side, both themed with your company colors from Step 3, one sketchnote and one editorial.

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Pencil MCP not available" | Pencil MCP not installed or not running | Run `/install-mcp pencil`, then restart your Claude session |
| "Excalidraw MCP not available" | Excalidraw MCP not installed or not running | Run `/install-mcp excalidraw`, then restart your Claude session |
| Rendering hangs with no output | MCP is installed but the server isn't started | Run `/mcp` to see MCP status; restart any stopped servers |
| Output file opens blank | Style preset mismatched the renderer | `sketchnote`/`whiteboard` → Excalidraw; `economist`/`editorial`/`data-viz`/`corporate` → Pencil |

If one renderer works and the other doesn't, you've pinpointed exactly which MCP to repair — the working one tells you your workspace is fine, and the failing one tells you which `/install-mcp` target to re-run.

## Step 5: What to Try Next

You now have a working insight-wave workspace, a branded theme, and two rendered infographics. Pick a follow-on workflow based on what you want to produce:

| If you want to... | Try this workflow | Guide |
|-------------------|------------------|-------|
| Research a topic with verified sources | Research → Report → Verify | [research-to-report](research-to-report.md) |
| Position a product for a market | Portfolio → Propositions → Pitch | [portfolio-to-pitch](portfolio-to-pitch.md) |
| Scout industry trends and model solutions | Trends → Value Model → Report | [trends-to-solutions](trends-to-solutions.md) |
| Build a full marketing content pipeline | Marketing → Narrative → Visual | [content-pipeline](content-pipeline.md) |
| Run a full consulting engagement | Double Diamond orchestration | [consulting-engagement](consulting-engagement.md) |

For a deeper reference on any plugin, browse the [plugin guides](../plugin-guide/).
