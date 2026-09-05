---
id: concept-canonical-workflow-ids
title: "Canonical workflow IDs"
type: summary
tags: [workflow, canonical-ids, naming, conventions, docs]
created: 2026-08-13
updated: 2026-08-13
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/
status: stable
related: [concept-naming-conventions, workflow-docs-pipeline, workflow-full-onboarding, ecosystem-plugin-selection]
---

Cross-plugin workflows are named from a single fixed set, so a user following one workflow sees the same name on every surface that mentions it. Without the rule the same pipeline picks up a different name per surface — `research-to-slides` in one place, `research-to-report` in another — and a user cannot tell whether they are two workflows or one.

## The policy

`docs/workflows/` is the canonical source for workflow IDs and pipeline shape. Every user-facing workflow ID has a one-to-one backing file at `docs/workflows/<canonical-id>.md`. Every other surface — the `workflow` skill's playbook templates, plugin catalogs, quick references, and the pages in this wiki — aligns to those IDs and does not invent its own.

`docs/` is canonical because it is the publishing-grade surface, generated and maintained by cogni-docs for end-user consumption. Operational templates elsewhere derive from the canonical pipeline shape; they are step-by-step playbooks over a pipeline `docs/` already defines.

## The canonical set

Seven user-facing workflows. The set is fixed by the presence of the backing file: a new canonical ID exists once `docs/workflows/<id>.md` lands, and not before.

| Canonical ID | Wiki page |
|---|---|
| `research-to-report` | [[workflow-research-to-report]] |
| `trends-to-solutions` | [[workflow-trends-to-solutions]] |
| `portfolio-to-pitch` | [[workflow-portfolio-to-pitch]] |
| `consulting-engagement` | [[workflow-consulting-engagement]] |
| `content-pipeline` | [[workflow-content-pipeline]] |
| `install-to-infographic` | [[workflow-install-to-infographic]] |
| `portfolio-to-website` | [[workflow-portfolio-to-website]] |

## Operational templates sit outside the set

Two pipelines are deliberately held out. They describe plugin-maintenance and onboarding meta-work rather than an analyst, sales or consultant workflow, so they carry no canonical ID and have no `docs/workflows/` companion:

- [[workflow-docs-pipeline]] — the cogni-docs maintenance sequence
- [[workflow-full-onboarding]] — the new-user meta-pipeline that sequences the other seven

Either graduates to the canonical set only when a matching `docs/workflows/<id>.md` file lands. The gate is the file, not a judgement call — which is what keeps the boundary from being renegotiated per surface.

## Why the one-to-one rule matters

A workflow ID is a cross-surface join key. It appears in playbook filenames, in tutorial paths, in plugin catalogs, and in the `related` frontmatter of these wiki pages. Once one surface renames a workflow unilaterally, every reference that used the old name silently points at nothing — and nothing raises, because no guard checks cross-surface ID agreement. Holding `docs/workflows/` as the single naming authority is what makes drift visible: a template whose filename has no backing guide is an orphan you can see, rather than an inconsistency you discover from a user.

**Source**: [docs/workflows](https://github.com/cogni-work/insight-wave/tree/main/docs/workflows)
