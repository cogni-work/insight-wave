---
id: workflow-consulting-engagement
title: "Workflow: Consulting Engagement (cogni-consult, knowledge-backed)"
type: summary
tags: [workflow, consulting-engagement, consult, knowledge, action-fields, design-thinking, personas]
created: 2026-08-13
updated: 2026-08-13
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/consulting-engagement.md
status: stable
related: [plugin-cogni-consult, plugin-cogni-knowledge, concept-orchestrator-pattern]
---

A structured consulting engagement whose research compounds instead of restarting per deliverable. This replaces the former Double Diamond playbook — the cogni-consulting plugin was removed and its source lives only in git history.

## Pipeline

```
consult-setup      → engagement scaffold + bound cogni-knowledge base
consult-scope      → one SMART key question + 3–6 action fields (the WBS)
consult-action-fields → planned deliverable set per field
consult-design-thinking → per-deliverable loop: empathize → define → ideate → prototype → test
consult-personas   → acting personas challenge the deliverable
                     ↑ loop back per deliverable until the WBS is complete
consult-resume     → re-entry point, any session
```

## Duration

Days to weeks, depending on engagement scope and the number of action fields.

## End deliverable

A set of Obsidian-browsable deliverables organized by action field, each carrying `sources[]` lineage on every evidence-backed claim and a decision log from its design-thinking loop.

## Steps

**1 — Setup.** `cogni-consult:consult-setup`. Takes engagement name, client, desired outcome, market and language; scaffolds `scope/`, `action-fields/`, `personas/` and `.metadata/` with `consult-project.json`, and binds a cogni-knowledge base. The binding is the high-leverage step — every deliverable's research compounds through it. One base per engagement, always: running `knowledge-setup` a second time creates a base research will not route through. Setup also registers the engagement so `consult-resume` finds it from any directory.

**2 — Scope.** `cogni-consult:consult-scope`, dispatching to cogni-knowledge when a dimension needs market or regulatory evidence. Produces one SMART key question at `scope/key-question.md` and 3–6 named action fields — the work-breakdown structure. Walk all five dimensions: strategic context, scope, stakeholder, constraints and barriers, success factors. Route research gaps through the bound base rather than raw web search; syntheses land in `scope/research/`. Six fields is the ceiling — merge closely related themes while scoping.

**3 — Plan the WBS.** `cogni-consult:consult-action-fields`. Produces the fields × deliverables dashboard, a planned deliverable set per field in `field.json`, and a recommended next deliverable. For empty fields it proposes one to three deliverables from the deliverable-types catalog by field-type affinity. Fields can be added, split or merged at any point; each deliverable lives in exactly one field, and several fields may be in progress at once.

**4 — Run the design-thinking loop.** `cogni-consult:consult-design-thinking`, dispatching to cogni-knowledge — `knowledge-query` first, and the full research pipeline only when the base is silent. Five stages per deliverable: empathize → define → ideate → prototype → test. At empathize, query the base before commissioning new research; prior deliverables' syntheses are reusable. Finalized syntheses are copied to `action-fields/{field}/research/{topic}.md` for stable paths. The loop scales — simple deliverables converge in one pass — but do not skip it, because the decision log is what makes the deliverable defensible.

**5 — Challenge with acting personas.** `cogni-consult:consult-personas`. Challenges are recorded in the deliverable's Persona Challenges section and the persona's work log. Shipped defaults are a consulting partner (frameworks, commercial defensibility) and a project manager (delivery realism). Three modes: define (seed client-side personas from the stakeholder dimension), enrich (build an empathy map from engagement evidence), challenge. Enrich before challenging — an unenriched persona pushes back with generic frameworks. Challenges inform, never block; the consultant dispositions each as accepted, revised, or rejected with a reason.

**6 — Resume.** `cogni-consult:consult-resume`. Read-only: it never edits engagement state. Returns the WBS dashboard plus exactly one recommended next action — one recommendation, not a menu — and on confirmation dispatches the named skill with the engagement path handed off.

## Common pitfalls

- **Skipping the knowledge-base binding.** Without it every deliverable's research starts cold. The binding happens at setup and cannot be retrofitted cleanly.
- **Deriving more than six action fields.** Thinner deliverable sets per field and an unreadable WBS dashboard.
- **Challenging unenriched personas.** Even one or two enriched empathy-map quadrants sharpen the feedback considerably.
- **Treating the engagement as linear.** Deliverables track independently; the WBS is built for parallel progress across fields.

## Why this order

The key question gates the action fields, and the action fields gate the deliverables — so scoping errors are cheap to fix and deliverable errors are not. The knowledge base is bound before any of it because retrofitting a research spine means re-running every deliverable's evidence gathering.

**Source**: [consulting-engagement workflow guide](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/consulting-engagement.md)
