---
name: publish-routing
description: Canonical contract mapping a completed deliverable to a presentation format and the dispatch route that builds its brief — the single source of truth the publish path executes instead of hard-coding routing.
---

# Publish Routing

When a deliverable is complete and the consultant elects to publish it, this
file is the canonical contract for **which presentation format it becomes** and
**exactly how the corresponding brief is built**. The publish path points here
rather than restating the routing, so the contract stays auditable and cannot
drift across skills.

A publish run takes a finished deliverable artifact at
`action-fields/<field-slug>/<deliverable-slug>.md` and terminates in a clean
**brief** — the handoff the consultant takes to Claude Design (claude.ai/design)
to render in their own design system. Rendering and brand are out of plugin
scope: cogni-consult produces the brief, Claude Design produces the rendered
artifact.

## Presentation Formats

The consultant chooses one of four target formats at publish time. The choice is
not fixed per deliverable type — `deliverable-types.md` records a deliverable's
format preference in its own artifact when it is produced, never in `field.json`
— so the routing below keys on the **format the consultant elects**, not on a
catalog default.

| Format | What it produces | Built by |
|---|---|---|
| `slides` | An ordered section outline for a presentation deck | consult-native outline brief |
| `web-poster` | A single-scroll web page / poster outline | consult-native outline brief |
| `report` | A structured report-outline brief for a themed report | consult-native report-outline brief |
| `infographic` | A single-page infographic brief | consult-native infographic brief |

Every format is built **natively** as a brief — no route renders locally or
applies a theme on the standard path. The four `Built by` builders all run
inside this skill; cogni-visual is no longer dispatched as a standard route (it
remains an explicit opt-in local-render fallback only — see each route below).

## Routing by Format

### slides / web-poster → consult-native outline brief

Consult deliverables are **framework-shaped** (Pyramid / SCQA / MECE), not
**arc-shaped**. The arc-optimized cogni-visual skills (`story-to-slides`,
`story-to-web`) auto-detect a narrative arc and build best when the source is a
story; a WBS-addressed analytical deliverable is not a story, so dispatching them
directly yields a weak brief. For the same reason this path does **not**
re-narrate the deliverable through `cogni-narrative` — arc-ifying a
framework-shaped deliverable softens the executive/Pyramid register it is written
in.

Instead, derive a **consult-native outline brief** directly from the
deliverable's own structure: an ordered list of `{section_title, section_body}`
entries, citations preserved. The mapping from the deliverable's framework to the
outline:

- **Pyramid answer / governing thought** → the opening (title slide or hero
  section).
- **MECE groups / SCQA movements** → one section entry each, in the
  deliverable's own order.
- **Supporting evidence and citations** → carried into the corresponding
  section body; never dropped.

The brief is a plain title-and-description outline — exactly what Claude Design's
presentation generator consumes. Write it alongside the deliverable, e.g.
`action-fields/<field-slug>/publish/<deliverable-slug>-outline.md`.

### report → consult-native report-outline brief

A report deliverable is already framework-shaped prose, so — exactly like the
slides/web-poster outline — build a **consult-native report-outline brief**
directly from its structure rather than dispatching a local renderer. It is the
outline's report-shaped sibling: an executive-summary lead (the Pyramid
governing thought / BLUF) followed by ordered `{section_title, section_body}`
entries that preserve the deliverable's MECE groups / SCQA movements in its own
order, carrying the full supporting prose and citations into each section body —
never dropped. This is exactly what Claude Design's document/report generator
consumes; Claude Design renders the themed HTML/PDF/DOCX and applies brand. Write
it alongside the deliverable, e.g.
`action-fields/<field-slug>/publish/<deliverable-slug>-report-outline.md`.

**Opt-in fallback.** When the consultant explicitly wants a locally-rendered
artifact and `cogni-visual` is installed, `cogni-visual:enrich-report`
(`source_path: action-fields/<field-slug>/<deliverable-slug>.md`) remains
available as an opt-in fallback. It is **no longer the standard path** — it
renders locally and applies a cogni-visual theme, which the brief-only contract
otherwise avoids.

### infographic → consult-native infographic brief

Build a **consult-native infographic brief** directly from the deliverable
rather than dispatching a local renderer: the Pyramid governing thought as the
headline, the key quantified facts / hero numbers pulled from the deliverable's
evidence, each MECE group as one infographic segment (a stat-or-insight block),
and a single call-to-action takeaway — citations preserved in the brief. This is
exactly what Claude Design's infographic generator consumes; Claude Design
renders and themes it. Write it alongside the deliverable, e.g.
`action-fields/<field-slug>/publish/<deliverable-slug>-infographic-brief.md`.

**Opt-in fallback.** When the consultant explicitly wants a locally-rendered,
auto-themed infographic and `cogni-visual` is installed,
`cogni-visual:story-to-infographic`
(`source_path: action-fields/<field-slug>/<deliverable-slug>.md`, optional
`style_preset`) remains available as an opt-in fallback. It is **no longer the
standard path** for the same reason as `report`.

## Optional Voice Polish

Before building any brief, the deliverable or outline text may be polished with
`cogni-copywriting:copywriter`. This step is optional and graceful-degrading —
skip it and the route still produces a valid brief.

```
Skill: cogni-copywriting:copywriter
  FILE_PATH=<absolute path to the deliverable or outline .md>
  --scope=tone   AUDIENCE=mixed
```

Scope guidance: `--scope=tone` for a light pass that preserves structure;
`--scope=compress` to tighten for an executive audience; `--scope=full` for a
Pyramid / BLUF restructuring before a client-facing presentation. `TARGET_LANG`
translates when the brief's language differs from the deliverable's.

## Handoff Contract

Every route terminates in a **brief file** built natively inside this skill —
no standard route renders locally or owns a theme — and the brief's path *is*
the handoff. Briefs are stored as **path references** — never copied into consult
state — mirroring the research storage contract: the deliverable and its
downstream brief are linked by path, so a correction upstream is visible
downstream without duplicating content.

The consultant takes the brief to Claude Design (claude.ai/design) and renders it
in their own design system. cogni-consult never renders and never owns brand —
its output stops at the brief.
