---
name: workflow
description: >-
  Cross-plugin workflow templates for common multi-plugin pipelines. Use this skill
  whenever the user asks about workflows, pipelines, end-to-end processes, "how do I
  go from X to Y", "what's the process for", "show me the steps", "workflow for",
  "pipeline from research to a report", "install to first infographic", "portfolio to
  website", "marketing content pipeline", "multi-channel content production", "how do
  these plugins work together", or wants guidance on chaining multiple insight-wave
  plugins. Also trigger when a user describes a multi-step task that spans plugins —
  even if they don't say "workflow" explicitly.
version: 0.1.0
allowed-tools: Read, Glob
---

# workflow: Cross-Plugin Pipeline Templates

Provide step-by-step playbooks for common multi-plugin workflows. These are guided
reference templates — not automated orchestration (that's cogni-consulting's job).

## Language

Read the workspace language from `.workspace-config.json` in the workspace root
(`language` field — `"en"` or `"de"`). Explain pipeline steps, use cases, and
guidance in that language.

If the file is missing or unreadable, detect the user's language from their message.
If still unclear, default to English.

Keep in English regardless of language setting:
- Plugin names (`cogni-trends`, `cogni-narrative`, etc.)
- Command names (`/workflow`, `/consult`, etc.)
- Canonical workflow IDs (`research-to-report`, `trends-to-solutions`, etc.)
- Technical terms, file paths, code snippets

## Available Workflows

Seven bundled user-facing templates cover the most common plugin chains. See §Internal / Operational Workflows below for maintainer pipelines.

| Canonical ID | Reference file | Pipeline | Use case |
|--------------|----------------|----------|----------|
| `install-to-infographic` | `references/workflows/install-to-infographic.md` | cogni-workspace → cogni-workspace (themes) → cogni-visual | First-run capstone — install, theme, render an infographic |
| `research-to-report` | `references/workflows/research-to-report.md` | research → narrative → visual | Analyst producing a report-and-presentation deliverable from research |
| `trends-to-solutions` | `references/workflows/trends-to-solutions.md` | tips → portfolio → marketing | GTM team turning trends into campaigns |
| `portfolio-to-pitch` | `references/workflows/portfolio-to-pitch.md` | portfolio → narrative → sales → visual | Sales creating a customer pitch deck |
| `portfolio-to-website` | `references/workflows/portfolio-to-website.md` | portfolio → workspace → website | Generate a deployable static site from the portfolio model |
| `content-pipeline` | `references/workflows/content-pipeline.md` | marketing → narrative (long-form) → copywriting → visual | Multi-channel marketing content production |
| `consulting-engagement` | `references/workflows/consulting-engagement.md` | consulting setup → 4 phases | Consultant starting a structured engagement |

These are the canonical user-facing workflows — every entry has a one-to-one
backing guide at `docs/workflows/<canonical-id>.md`. Reference them by
canonical ID from any surface (`teach`, `guide`, `cheatsheet`, `docs/`).
The reconciliation table at `references/canonical-workflows.md` is the
source of truth.

## Internal / Operational Workflows

Two templates live alongside the user-facing set but are operational rather
than user-facing — they describe maintainer pipelines, not analyst /
sales / consultant workflows. They live in `references/internal-workflows/`
and `/workflow` surfaces them only when the user explicitly asks for them by
ID.

| Internal ID | Pipeline | Use case |
|-------------|----------|----------|
| `docs-pipeline` | doc-start → audit → generate → sync → power → claude → hub → bridge | Maintainer documenting the monorepo |
| `full-onboarding` | workspace → help courses 1-12 | New user learning the full ecosystem |

These do not appear in the default `/workflow` listing (no-args invocation),
do not carry canonical IDs, and are not part of the docs/workflows 1:1 set —
see `references/canonical-workflows.md` Table B for the policy.

## Canonical Workflow IDs

Canonical IDs come from `docs/workflows/`; the templates in this skill are operational copies aligned to them. `references/canonical-workflows.md` is the source of truth for the reconciliation table and the user-facing-vs-internal classification.

## How to Present Workflows

1. **Read the matching template** from `references/workflows/` (user-facing)
   or `references/internal-workflows/` (operational, only when the user names
   the ID directly).

2. **Present the pipeline visually** — use the Mermaid diagram or ASCII flow from
   the template so the user can see the full chain at a glance.

3. **Walk through each step** with:
   - The plugin and command to use
   - What input it needs (and where it comes from)
   - What output it produces (and where it goes next)
   - Common pitfalls or tips

4. **Adapt to context** — if the user already has some steps done ("I have my
   portfolio data, now what?"), skip to the relevant step in the pipeline.

## Listing Workflows

When `/workflow` is invoked with no argument, present **only** the
user-facing "Available Workflows" table above and ask which one the user
wants to explore. Do not list `docs-pipeline` or `full-onboarding` in the
default listing — they are operational and surface only when the user names
the ID explicitly (e.g., `/workflow docs-pipeline`). When that happens, open
the template and prepend the exact banner below so the user sees the
framing:

```
> **Internal / operational workflow** — not part of the default `/workflow`
> listing. This template describes a maintainer pipeline.
```

## docs/ Workflow Guides

The `docs/workflows/` directory contains user-facing workflow tutorials generated by
cogni-docs. These complement the bundled templates above — the templates here are
step-by-step playbooks with commands and tips; the docs/ guides are narrative tutorials
with context and variations.

| Canonical workflow (`docs/workflows/<id>.md`) | cogni-help template | Notes |
|-----------------------------------------------|---------------------|-------|
| `install-to-infographic` | `install-to-infographic` | Same first-run pipeline, docs version covers platform-specific Claude Code setup |
| `research-to-report` | `research-to-report` | Same pipeline, docs version focuses on the report |
| `trends-to-solutions` | `trends-to-solutions` | Same starting point, different end goal |
| `portfolio-to-pitch` | `portfolio-to-pitch` | Same pipeline |
| `portfolio-to-website` | `portfolio-to-website` | Same pipeline, docs version includes deployment hints and prerequisite matrix |
| `content-pipeline` | `content-pipeline` | Same pipeline, docs version covers campaign orchestration and content-calendar scheduling |
| `consulting-engagement` | `consulting-engagement` | Same pipeline |

When presenting a workflow, mention the corresponding docs/ guide if it exists:
"For a narrative walkthrough with more context, see `docs/workflows/<name>.md`."

## Custom Workflows

If a user describes a pipeline that doesn't match any template, compose one on
the fly using the plugin catalog from the guide skill (`../guide/references/plugin-catalog.md`).
Explain the reasoning for each plugin choice.
