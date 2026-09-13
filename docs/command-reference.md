# Command reference: how each plugin is invoked

The one-screen refresher for a plugin you have used before but cannot remember the exact invocation for. It answers *how to call it*; [Plugin selection](plugin-selection.md) answers *which plugin*. Each plugin's full guide under [docs/plugin-guide/](plugin-guide/) covers every skill in depth; this page carries the invocation surface only.

> Hand-maintained, guard-bound. A plugin's skills are its `skills/*/SKILL.md` directories and its slash commands are its `commands/*.md` files. `scripts/check-command-reference-sync.py` runs in CI and fails when this page and those directories disagree, so a skill or command change updates this page in the same pull request.

## Two invocation surfaces, and most plugins use only one

Skills are the primary surface across the ecosystem. A skill is invoked by its qualified name, `cogni-trends:trend-scout` for example, or simply by describing the task, since each skill's description carries its own trigger phrases. Slash commands are a thin optional wrapper that only some plugins ship.

Five of the eight plugins ship **no** commands directory at all: cogni-knowledge, cogni-consult, cogni-trends, cogni-portfolio and cogni-website are skill-invoked entirely. Expecting a slash command for one of those is the most common source of "the command does not exist" confusion. [Plugin anatomy](architecture/plugin-anatomy.md) shows how the two surfaces sit on disk.

## Slash commands, by plugin

| Plugin | Slash commands |
|---|---|
| cogni-workspace | `/claims`, `/copywrite`, `/text-to-narrative`, `/troubleshoot` |
| cogni-marketing | `/abm`, `/campaign`, `/content-calendar`, `/content-strategy`, `/demand-gen`, `/lead-gen`, `/marketing-dashboard`, `/marketing-resume`, `/marketing-setup`, `/sales-enablement`, `/thought-leadership` |
| cogni-sales | `/why-change` |
| cogni-knowledge, cogni-consult, cogni-trends, cogni-portfolio, cogni-website | none, skill-invoked |

## Skills, by plugin

**cogni-knowledge** (21) — `knowledge-setup`, `knowledge-plan`, `knowledge-curate`, `knowledge-fetch`, `knowledge-ingest`, `knowledge-ingest-source`, `knowledge-distill`, `knowledge-compose`, `knowledge-verify`, `knowledge-finalize`, `knowledge-run`, `knowledge-query`, `knowledge-refresh`, `knowledge-refresh-synthesis`, `knowledge-update`, `knowledge-index`, `knowledge-prefill`, `knowledge-lint`, `knowledge-health`, `knowledge-dashboard`, `knowledge-resume`

**cogni-consult** (9) — `consult-setup`, `consult-scope`, `consult-action-fields`, `consult-design-thinking`, `consult-personas`, `consult-project-plan`, `consult-publish`, `consult-dashboard`, `consult-resume`

**cogni-workspace** (10) — `manage-workspace`, `workspace-status`, `workspace-dashboard`, `manage-themes`, `manage-market-registry`, `install-mcp`, `claims`, `cogni-issues`, `text-to-narrative`, `copywriter`

**cogni-trends** (9) — `trend-scout`, `value-modeler`, `trend-research`, `trend-synthesis`, `trend-booklet`, `verify-trend-report`, `trends-catalog`, `trends-dashboard`, `trends-resume`

**cogni-portfolio** (21) — `portfolio-setup`, `portfolio-scan`, `portfolio-ingest`, `portfolio-taxonomy`, `products`, `features`, `markets`, `customers`, `propositions`, `solutions`, `packages`, `compete`, `portfolio-communicate`, `portfolio-consolidate`, `portfolio-architecture`, `portfolio-canvas`, `portfolio-verify`, `portfolio-lineage`, `portfolio-dashboard`, `portfolio-resume`, `trends-bridge`

**cogni-marketing** (11) — `marketing-setup`, `content-strategy`, `content-calendar`, `campaign-builder`, `demand-generation`, `lead-generation`, `thought-leadership`, `sales-enablement`, `abm`, `marketing-dashboard`, `marketing-resume`

**cogni-sales** (1) — `why-change`

**cogni-website** (6) — `website-setup`, `website-plan`, `website-build`, `website-legal`, `website-preview`, `website-resume`

## Recurring naming patterns

Once the patterns are visible, most of the table above stops needing lookup.

- **`*-setup`** bootstraps a project for that plugin. Always the first call.
- **`*-resume`** is the re-entry point across sessions. It shows progress and recommends the next step, so it is the right thing to run when you do not remember where you left off.
- **`*-dashboard`** renders a self-contained HTML view of current state.
- **`*-verify`, `*-lint`, `*-health`** are quality gates over entities that already exist, not producers.
- **`text-to-narrative`** is the one visual path: text in, an executive narrative plus one design brief for Claude Design out. There is no local renderer; Claude Design renders the brief.

## Where to read more

- [Plugin selection](plugin-selection.md) for which plugin owns a task
- [Ecosystem overview](ecosystem-overview.md) for the plugin landscape and data flow
- [Workflow guides](workflows/) for the cross-plugin pipelines
