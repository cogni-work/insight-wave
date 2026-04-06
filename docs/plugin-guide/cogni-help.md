# cogni-help

**Plugin guide** — for canonical positioning see the [cogni-help README](../../cogni-help/README.md).

---

## Overview

cogni-help is the navigation and learning layer for the insight-wave ecosystem. With 12 plugins and 70+ skills available in the marketplace, it is easy to know something exists but not know which specific skill handles a given task. cogni-help addresses this in four ways:

1. **Plugin discovery** — describe what you need, and the guide skill matches it to the right plugin and skill
2. **Structured learning** — a 12-course curriculum covers every plugin from fundamentals through advanced workflows, each course running about 45 minutes
3. **Workflow templates** — six cross-plugin pipeline playbooks show how to chain plugins into end-to-end workflows (research to slides, trends to marketing, portfolio to pitch)
4. **Diagnostics** — the troubleshoot skill checks plugin integrity, workspace health, and dependency state before problems surface as cryptic errors at runtime

cogni-help produces no content of its own — it teaches, routes, templates, and diagnoses. Think of it as the layer that makes the rest of the ecosystem learnable and navigable.

---

## Key Concepts

| Term | What it means |
|------|--------------|
| **Guide** | Task-to-plugin matching — describe what you want, get the right skill recommendation |
| **Course** | A ~45-minute interactive module: Theory → Demo → Exercise → Quiz → Recap |
| **Curriculum** | The 12-course sequence covering the full ecosystem, ordered by dependency |
| **Workflow template** | A step-by-step playbook for chaining 3–5 plugins into an end-to-end pipeline |
| **Cheatsheet** | A one-screen quick-reference card for a specific plugin's commands and concepts |
| **Troubleshoot** | Plugin-level diagnostics: integrity checks, dependency validation, known issue matching |
| **Course progress** | Per-user progress stored in `.claude/cogni-help.local.md` — persists across sessions |
| **Plugin catalog** | The index in `guide/references/plugin-catalog.md` that maps capabilities to plugins |

### The 12-course curriculum

| # | Course | Plugins covered |
|---|--------|-----------------|
| 1 | Cowork Fundamentals | cogni-help (meta) |
| 2 | Workspace and Obsidian | cogni-workspace, cogni-help:cogni-issues |
| 3 | Basic Tools | cogni-copywriting, cogni-narrative, cogni-claims |
| 4 | Trend Scouting | cogni-trends (part 1) |
| 5 | Trend Reporting | cogni-trends (part 2) |
| 6 | Portfolio Messaging | cogni-consulting, cogni-portfolio |
| 7 | Visual Deliverables | cogni-visual |
| 8 | Research Reports | cogni-research |
| 9 | B2B Marketing | cogni-marketing |
| 10 | Sales Pitches | cogni-sales |
| 11 | Consulting Orchestration | cogni-consulting |
| 12 | Documentation Pipeline | cogni-docs |

Courses are designed to be completed in order — later courses assume familiarity with earlier ones. You can jump in at any course if you know the prerequisites.

---

## Getting Started

If you are new to insight-wave, start with Course 1:

```
/teach 1
```

The teach skill introduces you to the Cowork environment, the plugin model, and how to navigate the ecosystem. From there you can continue through the curriculum at your own pace.

If you already know what you need to do but not which plugin handles it:

```
/guide "I need to analyze competitor positioning and build a messaging framework"
```

The guide skill reads your task description, consults the plugin catalog, and returns specific plugin and skill recommendations with example prompts.

---

## Capabilities

### `teach` — Interactive course delivery

The teach skill delivers any of the 12 courses interactively. It tracks your progress per course and adapts pacing based on your responses.

Start or resume a course by number:

```
/teach 1
```

Continue where you left off:

```
/teach continue
```

Check which courses you have completed:

```
/courses
```

Reset progress for a specific course if you want to retake it:

```
bash cogni-help/scripts/reset-progress.sh --course 3
```

Exercises create temporary artifacts in `_teacher-exercises/` in your project directory. These are gitignored and safe to delete after a session.

---

### `guide` — Plugin and skill discovery

The guide skill matches task descriptions to plugins. It is the starting point when you know what outcome you need but not which plugin to use.

```
/guide "create a slide deck from a research report"
```

```
/guide "verify whether my cited sources actually say what I claimed"
```

```
/guide "set up my workspace for the first time"
```

The guide reads the plugin catalog and returns: the recommended plugin, the specific skill to use, an example prompt, and pointers to related plugins for the broader workflow.

---

### `workflow` — Cross-plugin pipeline templates

The workflow skill provides step-by-step playbooks for multi-plugin pipelines. These are reference guides, not automated orchestration — for automation, see [cogni-consulting](../plugin-guide/cogni-consulting.md).

Available templates:

| Workflow | Pipeline |
|----------|---------|
| `research-to-slides` | cogni-research → cogni-narrative → cogni-visual |
| `trend-to-marketing` | cogni-trends → cogni-portfolio → cogni-marketing |
| `portfolio-to-pitch` | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| `new-engagement` | cogni-consulting phases: Discover → Define → Develop → Deliver |
| `docs-pipeline` | cogni-research → cogni-docs → cogni-narrative |
| `full-onboarding` | cogni-workspace → cogni-help courses 1–12 |

Open a specific workflow:

```
/workflow research-to-slides
```

```
How do I go from trend analysis to a marketing campaign?
```

Workflow definitions live in `cogni-help/skills/workflow/references/workflows/`.

---

### `cheatsheet` — Quick reference cards

The cheatsheet skill generates a one-screen reference card for any plugin. Faster than reading a full guide — useful when you have used a plugin before and just need a reminder of the commands and core concepts.

```
/cheatsheet cogni-trends
```

```
/cheatsheet cogni-portfolio
```

The card shows: what the plugin does in two sentences, its skills and slash commands, key concepts, and two or three example prompts.

---

### `troubleshoot` — Plugin diagnostics

The troubleshoot skill checks plugin integrity, workspace health, and dependency state. Run it when something is not working before escalating to a bug report.

```
/troubleshoot
```

```
Something is broken with cogni-portfolio — it can't find my themes
```

The skill checks: plugin file integrity, dependency availability, workspace configuration, known issues matching your symptoms, and suggests specific fixes. This complements `cogni-workspace`'s `workspace-status` skill, which focuses on infrastructure (env vars, themes, settings files). Troubleshoot focuses on plugin-level and cross-plugin issues.

---

### `cogni-issues` — GitHub issue filing

The cogni-issues skill guides you through filing a bug report or feature request against any insight-wave plugin. It uses browser automation to create the issue on GitHub directly — no personal access token or CLI setup needed, just a browser logged into GitHub.

```
/issues
```

```
I found a bug in cogni-claims — it marks claims as verified when the source 404s
```

The skill captures: issue type (bug, feature request, question), affected plugin, reproduction steps, and expected versus actual behavior. It opens GitHub in your browser and fills the issue form.

Issue state is tracked locally in `cogni-issues/issues.json` in your project directory.

---

### `course-deck` — Training slide decks

The course-deck skill generates PPTX slide decks for training sessions. Two modes:

1. **Curriculum overview** — all 12 courses at a glance, for introducing the program to a group
2. **Course introduction** — learning objectives, module breakdown, and prerequisites for a specific course

```
/course-deck curriculum
```

```
/course-deck 3
```

---

## Integration Points

### cogni-help as the meta-layer

cogni-help references every other plugin — it is the only plugin with no functional dependency on specific downstream plugins. All plugin integrations are soft:

| Skill | How it uses other plugins |
|-------|--------------------------|
| `teach` | Each course maps to 1–3 plugins; requires them installed for exercises |
| `guide` | Reads the plugin catalog to match tasks; works without plugins installed |
| `workflow` | Chains 3–5 plugins per template; requires them for live walkthroughs |
| `troubleshoot` | Checks plugin file integrity and dependencies; works even if plugins are broken |
| `cheatsheet` | Reads plugin metadata to generate cards; requires the plugin installed |

### Downstream — cogni-workspace

Before running any course involving plugin-specific work, ensure the workspace is initialized. If `workspace-status` reports issues, resolve them before starting Course 2 and beyond. See [cogni-workspace](../plugin-guide/cogni-workspace.md).

---

## Common Workflows

### Workflow 1: Onboard a new team member

Walk a new user through the full ecosystem:

1. Run `manage-workspace` from cogni-workspace to prepare the environment
2. Start `/teach 1` — Cowork Fundamentals covers the mental model and navigation
3. Continue through `/teach 2` — Workspace and Obsidian for environment setup
4. Use `/guide` to match their first real task to the right plugin
5. Run the relevant course for that plugin

For a structured onboarding plan covering the full curriculum, use `/workflow full-onboarding`.

### Workflow 2: Diagnose a broken setup

When a skill fails or behaves unexpectedly:

1. Run `/troubleshoot` and describe the symptom
2. If the issue is infrastructure-level (env vars, settings, themes), the troubleshoot skill will redirect to `workspace-status` from cogni-workspace
3. For known issues, the skill matches symptoms to the known-issues catalog and returns a specific fix
4. If the issue is a software bug, use `/issues` to file it with the right context captured

### Workflow 3: Learn a specific pipeline before running it

Before running a multi-plugin pipeline for the first time:

1. Run `/workflow <name>` to read the full step-by-step playbook
2. Run `/cheatsheet` for each plugin in the pipeline to review commands
3. Run the pipeline step by step, referring to the workflow doc as needed

For automated pipeline orchestration, see [cogni-consulting](../plugin-guide/cogni-consulting.md).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `/teach` shows no courses available | Course definition files missing from `cogni-help/skills/teach/references/courses/` | Verify the plugin is fully installed; run `bash cogni-help/scripts/health-check.sh` |
| Course progress not persisting | `.claude/cogni-help.local.md` is not writable | Check permissions on the `.claude/` directory in your project root |
| `/guide` returns incorrect plugin recommendations | The plugin-catalog.md is stale — a plugin was added or updated without updating the catalog | The catalog is at `cogni-help/skills/guide/references/plugin-catalog.md`; update it to reflect the current plugin set |
| `/troubleshoot` says workspace health is fine but skills still fail | cogni-help's diagnostics check plugin files and dependencies, not skill execution logs | Run `workspace-status` from cogni-workspace for deeper infrastructure checks |
| `/issues` cannot file an issue | Browser automation requires the user to be logged into GitHub in their browser | Log into github.com in your browser and retry |
| `/workflow` shows a workflow but the steps fail | The pipeline plugins may not be installed | Run `/guide` for each step to confirm the required plugin is available |

---

## Extending This Plugin

The highest-value contributions to cogni-help are:

- **New courses** — if a plugin exists in the ecosystem but has no dedicated course, adding one follows the Theory → Demo → Exercise → Quiz → Recap structure used by existing courses
- **New workflow templates** — if you have developed a repeatable multi-plugin pipeline not in the current six templates, document it as a new workflow definition in `workflow/references/workflows/`
- **Diagnostic checks** — the troubleshoot skill's known-issues catalog grows best when users report problems and someone encodes the resolution pattern
- **Plugin catalog updates** — whenever a new plugin or significant new skill lands in the ecosystem, `guide/references/plugin-catalog.md` needs updating

See [CONTRIBUTING.md](../../cogni-help/CONTRIBUTING.md) for guidelines.
