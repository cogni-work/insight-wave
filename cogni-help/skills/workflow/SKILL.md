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

Nine bundled templates covering the most common plugin chains:

| Canonical ID | Primary plugins | Pipeline | Use case |
|--------------|-----------------|----------|----------|
| `install-to-infographic` | cogni-workspace, cogni-visual | cogni-workspace → cogni-workspace (themes) → cogni-visual | First-run capstone — install, theme, render an infographic |
| `research-to-report` | cogni-research, cogni-narrative, cogni-visual | research → narrative → visual | Analyst producing a report-and-presentation deliverable from research |
| `trends-to-solutions` | cogni-trends, cogni-portfolio, cogni-marketing | tips → portfolio → marketing | GTM team turning trends into campaigns |
| `portfolio-to-pitch` | cogni-portfolio, cogni-narrative, cogni-sales, cogni-visual | portfolio → narrative → sales → visual | Sales creating a customer pitch deck |
| `portfolio-to-website` | cogni-portfolio, cogni-workspace, cogni-website | portfolio → workspace → website | Generate a deployable static site from the portfolio model |
| `content-pipeline` | cogni-marketing, cogni-narrative, cogni-copywriting, cogni-visual | marketing → narrative → copywriting → visual | Multi-channel marketing content production |
| `consulting-engagement` | cogni-consulting | consulting setup → 4 phases | Consultant starting a structured engagement |
| — (operational-only, docs) | cogni-docs | doc-start → audit → generate → sync → power → claude → hub → bridge | Maintainer documenting the monorepo (`docs-pipeline` template) |
| — (operational-only, onboarding) | cogni-workspace, cogni-help | workspace → help courses 1-12 | New user learning the full ecosystem (`full-onboarding` template) |

The first column is the canonical workflow ID from `docs/workflows/`; the
second lists the primary plugins involved (template files in
`references/workflows/` share the canonical ID's filename). The 7
user-facing canonical workflows are referenced by canonical ID from any
surface (`teach`, `guide`, `cheatsheet`, `docs/`). Operational-only rows
have no canonical ID and are suffixed with their context (docs vs
onboarding) — see `references/canonical-workflows.md` Table B for the
policy.

## Canonical Workflow IDs

`docs/workflows/` is the canonical source for workflow IDs and pipeline shape;
the templates in this skill are operational presentation copies that align to
those canonical IDs. The reconciliation table — every cogni-help template ID
and every `docs/workflows/<name>.md` filename mapped to a single canonical ID
with a migration action — lives at `references/canonical-workflows.md`.

When a workflow is referenced from another surface (`teach`, `guide`,
`cheatsheet`, `docs/`), use the canonical ID. The reconciliation table in
`references/canonical-workflows.md` is the source of truth for which IDs
are user-facing vs operational-only and for any pending alignment work.

## How to Present Workflows

1. **Read the matching template** from `references/workflows/`.

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

When `/workflow` is invoked with no argument, present the table above and ask
which workflow the user wants to explore.

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
