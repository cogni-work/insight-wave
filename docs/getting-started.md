# Getting Started with insight-wave

This guide walks you through installing the insight-wave marketplace, initializing your workspace, and running your first research report.

---

## Prerequisites

Before installing, confirm you have the following:

| Requirement | Notes |
|-------------|-------|
| [Claude Code CLI](https://claude.ai/code) or Claude Cowork | insight-wave plugins run inside Claude Code sessions |
| Terminal (bash / zsh) | Required for workspace initialization scripts |
| `jq` | JSON processing — used by workspace scripts |
| `python3` | Standard library only, no pip dependencies |
| `bash 3.2+` | Ships with macOS; standard on Linux |

Optional but recommended: [Obsidian](https://obsidian.md/) for browsable knowledge management. All plugin outputs write Obsidian-compatible markdown with YAML frontmatter.

---

## Step 1: Add the Marketplace

In your Claude Code session, run:

```shell
/plugin marketplace add cogni-work/insight-wave
```

This registers the insight-wave marketplace so you can install any of the 12 plugins from it.

### Install plugins

Install all plugins at once:

```shell
/plugin install cogni-workspace@insight-wave
/plugin install cogni-research@insight-wave
/plugin install cogni-claims@insight-wave
/plugin install cogni-trends@insight-wave
/plugin install cogni-portfolio@insight-wave
/plugin install cogni-consulting@insight-wave
/plugin install cogni-narrative@insight-wave
/plugin install cogni-copywriting@insight-wave
/plugin install cogni-marketing@insight-wave
/plugin install cogni-sales@insight-wave
/plugin install cogni-visual@insight-wave
/plugin install cogni-help@insight-wave
```

Or browse and select interactively: open `/plugin` and go to the **Discover** tab.

Install `cogni-workspace` first — it provides the shared foundation (environment variables, theme paths, plugin discovery) that every other plugin depends on.

---

## Step 2: Initialize Your Workspace

Navigate to the directory where you want your workspace (a project folder or your home directory for a shared workspace), then run:

```
/manage-workspace
```

The skill walks you through four steps:

1. **Dependency check** — verifies `jq`, `python3`, and `bash` are available. Reports exactly what's missing if any check fails.
2. **Plugin discovery** — scans your installed cogni-* plugins and presents them for confirmation. The list determines which environment variables get wired up.
3. **Preferences** — asks for your preferred language (EN or DE) and whether you use Obsidian.
4. **Settings generation** — creates three files in your workspace:
   - `.claude/settings.local.json` — environment variables Claude Code auto-injects at session start
   - `.workspace-env.sh` — the same variables for use outside Claude Code (Obsidian Terminal, CI)
   - `.workspace-config.json` — workspace metadata (version, language, registered plugins)

If you use Obsidian, the skill offers to scaffold the vault with a Terminal plugin and Claude Code launcher.

After initialization, run `/workspace-status` any time to check that environment variables are set correctly and all registered plugins are reachable.

---

## Step 3: Your First Report with cogni-research

Once your workspace is initialized, try a research report. Type this prompt directly:

```
Write a detailed research report on AI adoption trends in mid-market B2B software companies
```

cogni-research picks this up and runs a six-phase pipeline:

1. Decomposes your topic into 7–10 orthogonal sub-questions
2. Dispatches one research agent per sub-question in parallel, searching the web and extracting findings
3. Aggregates and deduplicates sources across all agents
4. Writes a structured report with inline citations linking every claim to its source URL
5. Runs an automated structural review (completeness, coherence, depth, clarity)
6. Optionally verifies claims against source URLs via cogni-claims (run `/verify-report` after the draft is ready)

A `detailed` report typically completes in 5–15 minutes depending on sub-question count and web response times. The output lands in a timestamped directory under your workspace:

```
{workspace}/cogni-research/data/{slug}/
  00-sub-questions/    decomposed research questions
  01-contexts/         per-sub-question findings
  02-sources/          deduplicated source registry
  report-draft.md      the compiled report
```

All files use Obsidian-compatible YAML frontmatter — if you set up the vault integration, you can browse the full research trail in Obsidian.

**Depth options:**

| Keyword | Agents | Use when |
|---------|--------|----------|
| basic | 5–7 | Quick overview, single-topic answer |
| detailed | 7–12 | Multi-section report with sourced analysis |
| deep | 15–25 | Recursive exploration, exhaustive sourcing |

---

## Step 4: What to Try Next

Once you have a report, the typical next steps are to transform it into a deliverable. Each workflow below links to a dedicated guide.

| What you want to do | Workflow guide | Key plugins |
|---------------------|---------------|-------------|
| Turn a research report into an executive narrative | [Research to Narrative](workflows/research-to-narrative.md) | cogni-research, cogni-narrative, cogni-copywriting |
| Generate a slide deck or web narrative from polished content | [Narrative to Visual](workflows/narrative-to-visual.md) | cogni-narrative, cogni-visual |
| Scout industry trends and connect them to your portfolio | [Trend Scouting Pipeline](workflows/trend-scouting.md) | cogni-trends, cogni-portfolio, cogni-marketing |
| Build a sales pitch for a named customer or segment | [Sales Pitch Pipeline](workflows/sales-pitch.md) | cogni-portfolio, cogni-research, cogni-sales |
| Produce B2B marketing content from portfolio + trends | [Marketing Content Engine](workflows/marketing-content.md) | cogni-trends, cogni-portfolio, cogni-marketing |
| Run a consulting engagement end-to-end | [Double Diamond Engagement](workflows/consulting-engagement.md) | cogni-consulting, cogni-research, cogni-portfolio, cogni-visual |

### Quick commands to explore

```
/workspace-status          check workspace health
/cheatsheet                quick-reference for all installed plugins
/courses                   start the 11-course interactive curriculum
/guide cogni-research      read the full plugin guide
```

For troubleshooting, see [cogni-help](../cogni-help/README.md) or run `/troubleshoot`.

---

## See also

- [Ecosystem Overview](ecosystem-overview.md) — how the 12 plugins fit together and how data flows between them
- [er-diagram.md](er-diagram.md) — cross-plugin entity relationship diagram
- [cogni-workspace plugin guide](plugin-guide/cogni-workspace.md)
- [cogni-research plugin guide](plugin-guide/cogni-research.md)
