---
name: workflow
description: >-
  Cross-plugin workflow templates for common multi-plugin pipelines. Use this skill
  whenever the user asks about workflows, pipelines, end-to-end processes, "how do I
  go from X to Y", "what's the process for", "show me the steps", "workflow for",
  "pipeline from research to a report", "how do these plugins work together", or wants
  guidance on chaining multiple insight-wave plugins. Also trigger when a user describes
  a multi-step task that spans plugins — even if they don't say "workflow" explicitly.
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

Four bundled user-facing templates covering the most common plugin chains (two additional internal/operational templates are documented in the next section):

| Canonical ID | Template file | Pipeline | Use case |
|--------------|---------------|----------|----------|
| `research-to-report` | `research-to-report` | research → narrative → visual | Analyst producing a report-and-presentation deliverable from research |
| `trends-to-solutions` | `trends-to-solutions` | tips → portfolio → marketing | GTM team turning trends into campaigns |
| `portfolio-to-pitch` | `portfolio-to-pitch` | portfolio → narrative → sales → visual | Sales creating a customer pitch deck |
| `consulting-engagement` | `consulting-engagement` | consulting setup → 4 phases | Consultant starting a structured engagement |

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
| `full-onboarding` | workspace → help courses 1-11 | New user learning the full ecosystem |

These do not appear in the default `/workflow` listing (no-args invocation),
do not carry canonical IDs, and are not part of the docs/workflows 1:1 set —
see `references/canonical-workflows.md` Table B for the policy.

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
the template and prepend an "Internal / operational workflow" banner so the
user sees the framing.

## docs/ Workflow Guides

The `docs/workflows/` directory contains user-facing workflow tutorials generated by
cogni-docs. These complement the bundled templates above — the templates here are
step-by-step playbooks with commands and tips; the docs/ guides are narrative tutorials
with context and variations.

| Canonical workflow (`docs/workflows/<id>.md`) | cogni-help template | Notes |
|-----------------------------------------------|---------------------|-------|
| `research-to-report` | `research-to-report` | Same pipeline, docs version focuses on the report |
| `trends-to-solutions` | `trends-to-solutions` | Same starting point, different end goal |
| `portfolio-to-pitch` | `portfolio-to-pitch` | Same pipeline |
| `consulting-engagement` | `consulting-engagement` | Same pipeline |
| `content-pipeline` | — (no template yet) | Marketing pipeline from trends to campaign assets — refer the user to `docs/workflows/content-pipeline.md` |
| `install-to-infographic` | — (no template yet) | Install-to-deliverable pipeline — refer the user to `docs/workflows/install-to-infographic.md` |
| `portfolio-to-website` | — (no template yet) | Portfolio rendered as a static website — refer the user to `docs/workflows/portfolio-to-website.md` |

When presenting a workflow, mention the corresponding docs/ guide if it exists:
"For a narrative walkthrough with more context, see `docs/workflows/<name>.md`."

## Custom Workflows

If a user describes a pipeline that doesn't match any template, compose one on
the fly using the plugin catalog from the guide skill (`../guide/references/plugin-catalog.md`).
Explain the reasoning for each plugin choice.
