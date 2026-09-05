---
id: workflow-docs-pipeline
title: "Workflow: Documentation Pipeline (cogni-docs, maintainer)"
type: summary
tags: [workflow, docs-pipeline, cogni-docs, internal, maintainer, documentation]
created: 2026-08-13
updated: 2026-08-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/contributing/plugin-development.md
status: stable
related: [concept-canonical-workflow-ids, concept-readme-convention, ecosystem-overview]
---

An operational pipeline, not a user-facing one — the sequence a maintainer runs to document the monorepo or repair drifted plugin documentation. It carries no canonical workflow ID and no `docs/workflows/` companion; see [[concept-canonical-workflow-ids]] for why that distinction is enforced.

cogni-docs is hosted in a different marketplace from the eight plugins this wiki otherwise covers, so it has no plugin page here.

## Pipeline

```
doc-resume     → status dashboard + recommended next action
doc-audit      → drift report
doc-generate   → rebuild structural README sections
doc-sync       → align descriptions across manifests
doc-power      → strengthen IS/DOES/MEANS messaging
doc-claude     → developer guides for complex plugins
doc-hub        → the docs/ directory
doc-readme-root → journey-based root README
```

## Duration

30–90 minutes, depending on how many plugins are in scope.

## End deliverable

Plugin READMEs that match what is actually on disk, manifests whose descriptions agree with them, and a `docs/` tree regenerated from the current state.

## Steps

**0 — Entry point.** `doc-resume`. Takes a repo path, returns a status dashboard and the single highest-priority next action. Start here when you do not know what needs work; skip straight to a specific skill when you do.

**1 — Audit.** `doc-audit`, optionally scoped to one plugin. Produces a drift report of per-plugin checks — components, architecture, descriptions, dependencies, plugin.json, CLAUDE.md, messaging, docs coverage, commercial tone — plus repo-level checks. Run it across all plugins first for the full picture. The summary table shows OK / DRIFT / MISSING / WEAK per category; DRIFT and MISSING are the impactful fixes.

**2 — Generate.** `doc-generate`, per plugin or across all. Rebuilds the auto-generatable README sections from actual disk contents. Hand-written messaging is preserved; new plugins get scaffolded IS/DOES/MEANS placeholders. Review before committing — structural accuracy is automated, voice is not.

**3 — Sync.** `doc-sync`. Unifies descriptions across README, `plugin.json` and `marketplace.json`. README is canonical; the two manifests are derived. Skip when the audit reported no alignment drift.

**4 — Power messaging.** `doc-power`. Drafts messaging for the hand-written sections — title, problem table, identity, benefits — on plugins the audit flagged WEAK. Shows side-by-side comparisons and never overwrites without approval. `--polish` brings in `cogni-workspace:copywriter`.

**5 — Developer guide.** `doc-claude`. Writes CLAUDE.md — architecture, component inventory, design principles, data model — for complex plugins only. The audit flags which ones qualify; simple plugins do not need one.

**6 — Hub.** `doc-hub`. Generates the `docs/` directory: plugin guides, workflow guides, getting-started, architecture docs. Transforms README pitch voice into tutorial voice and discovers cross-plugin workflows. Run it after messaging is final, because it reads the current README state.

**7 — Root README.** `doc-readme-root`. Reads everything else and produces the journey-based root README, grouping plugins by workflow stage and preserving hand-written sections. Run last.

## Not every step is required

Most sessions use two or three skills, not all eight:

| Goal | Subset |
|---|---|
| Quick health check | `doc-resume` → `doc-audit` |
| Fix stale docs | `doc-audit` → `doc-generate` → `doc-sync` |
| Improve messaging | `doc-audit` → `doc-power` |
| Full overhaul | every step, in order |

`doc-resume` recommends the subset based on what it finds.

## Common pitfalls

- **Running `doc-hub` before messaging is settled.** It reads current README state, so it bakes in whatever `doc-power` has not yet fixed.
- **Running `doc-readme-root` early.** It aggregates everything downstream of it and has to be redone.
- **Committing `doc-generate` output unreviewed.** It gets structure right and voice wrong; the hand-written sections are hand-written for a reason.

**Source**: [plugin development guide](https://github.com/cogni-work/insight-wave/blob/main/docs/contributing/plugin-development.md)
