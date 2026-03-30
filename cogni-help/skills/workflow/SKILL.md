---
name: workflow
description: >-
  Cross-plugin workflow templates for common multi-plugin pipelines. Use this skill
  whenever the user asks about workflows, pipelines, end-to-end processes, "how do I
  go from X to Y", "what's the process for", "show me the steps", "workflow for",
  "pipeline from research to slides", "how do these plugins work together", or wants
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
- Workflow IDs (`research-to-slides`, `trend-to-marketing`, etc.)
- Technical terms, file paths, code snippets

## Available Workflows

Six bundled templates covering the most common plugin chains:

| Workflow | Pipeline | Use case |
|----------|----------|----------|
| `research-to-slides` | research → narrative → visual | Analyst producing a presentation from research |
| `trend-to-marketing` | tips → portfolio → marketing | GTM team turning trends into campaigns |
| `portfolio-to-pitch` | portfolio → narrative → sales → visual | Sales creating a customer pitch deck |
| `docs-pipeline` | doc-start → audit → generate → sync → power → claude → hub → bridge | Maintainer documenting the monorepo |
| `new-engagement` | consulting setup → 4 phases | Consultant starting a structured engagement |
| `full-onboarding` | workspace → help courses 1-11 | New user learning the full ecosystem |

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

## Custom Workflows

If a user describes a pipeline that doesn't match any template, compose one on
the fly using the plugin catalog from the guide skill (`../guide/references/plugin-catalog.md`).
Explain the reasoning for each plugin choice.
