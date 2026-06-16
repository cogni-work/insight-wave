---
name: consult-publish
description: |
  This skill should be used when a consultant elects to turn a completed
  cogni-consult deliverable into presentation-ready documentation — a brief the
  consultant hands to Claude Design to render. Trigger on: "publish this
  deliverable", "turn <deliverable> into slides", "make a poster/web page from
  <deliverable>", "build a report from <deliverable>", "make an infographic
  from <deliverable>", "present this deliverable", "render-ready brief", or
  "hand this to Claude Design". Runs only when the named deliverable's
  `state` is `complete`. It is consultant-elected: invoke it explicitly — it is
  never auto-fired from the design-thinking loop.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Publish a Deliverable

Turn one completed deliverable into a **brief** — the clean handoff the
consultant takes to Claude Design (claude.ai/design) to render in their own
design system. This skill produces the brief and records its path; it never
renders and never owns brand. Rendering and brand application live in Claude
Design, by design.

The routing — which format becomes which brief, built by which route — is the
canonical contract in `$CLAUDE_PLUGIN_ROOT/references/publish-routing.md`. This
skill **executes** that contract rather than restating it, so the routing
cannot drift between the reference and the skill. Read the reference before
building any brief; the per-format detail below is an execution summary, not a
second source of truth.

## When this runs

Publishing is a consultant judgment call — which deliverables are
presentation-worthy, and which format fits each. So this skill is **elected,
not automatic**:

- It runs only when the consultant invokes it explicitly on a named deliverable.
- It runs only when that deliverable's `state` is `complete` in its field's
  `field.json` (a deliverable still in its design-thinking loop is not ready to
  present).
- It is **never** wired into the `consult-design-thinking` empathize→test loop
  as a post-test callback. The loop ends at `state: complete`; publishing is a
  separate, later, deliberate step.

## Workflow

### 1. Locate the engagement and the deliverable

Resolve the engagement root (the directory holding `consult-project.json`) and
read the named action field's `action-fields/<field-slug>/field.json`. Find the
deliverable entry by its `slug`.

**Gate on completeness.** If the deliverable's `state` is not `complete`, stop
and tell the consultant the deliverable must finish its design-thinking loop
(and ideally its persona challenge) before it can be published — name the
current `state` and `dt_stage`. Do not publish an unfinished deliverable.

The deliverable artifact is at `action-fields/<field-slug>/<deliverable-slug>.md`.
Read it — its framework structure is what the brief is built from.

### 2. Elect the format

The four target formats are `slides`, `web-poster`, `report`, and
`infographic`. The choice is the consultant's and is not fixed per deliverable
type. The deliverable artifact's frontmatter may record a format preference
(`deliverable-types.md` records it at production time); read it and offer it as
the default, but let the consultant confirm or override. A deliverable may be
published to more than one format — each published format appends its own
lineage entry (step 5), so a second format never overwrites the first.

### 3. Optional voice polish

The brief text may be polished with `cogni-copywriting:copywriter` before
handoff. This is optional and graceful-degrading — **if `cogni-copywriting` is
not installed, skip it with a one-line note**; the route still produces a valid
brief.

The polish target depends on the route, so its timing differs:

- **`report` / `infographic`** — polish the **deliverable** here, in step 3,
  before the visual route post-processes it.
- **`slides` / `web-poster`** — polish the **drafted outline** instead, after
  step 4 builds it (there is no separate brief text until then).

The dispatch invocation and the `--scope` options (`tone` / `compress` / `full`)
are the canonical ones in `$CLAUDE_PLUGIN_ROOT/references/publish-routing.md` —
see its "Optional Voice Polish" section rather than restating them here.

### 4. Build the brief by route

Resolve the elected format to its route per `publish-routing.md` — the reference
holds the exact dispatch block and per-route options; the mapping below is the
execution summary, so read the reference for each route before dispatching:

| Elected format | Route | Brief output path |
|---|---|---|
| `slides` / `web-poster` | consult-native outline brief (built here, not dispatched) | `action-fields/<field-slug>/publish/<deliverable-slug>-outline.md` |
| `report` | `cogni-visual:enrich-report` | `action-fields/<field-slug>/output/<deliverable-slug>-enriched.html` (default) |
| `infographic` | `cogni-visual:story-to-infographic` | `infographic-brief.md` (auto-rendered) |

**Building the consult-native outline (`slides` / `web-poster`).** This is the
one route the skill builds itself rather than dispatching. Consult deliverables
are framework-shaped (Pyramid / SCQA / MECE), not arc-shaped, so this path does
**not** dispatch `cogni-visual:story-to-slides` / `story-to-web` and does **not**
re-narrate through `cogni-narrative` — arc-ifying a framework-shaped deliverable
weakens its executive register. Derive the outline directly from the
deliverable's own structure: an ordered list of `{section_title, section_body}`
entries with citations preserved — Pyramid answer / governing thought → the
opening, each MECE group / SCQA movement → one section in the deliverable's own
order, supporting evidence carried into the matching section body (never
dropped). The plain title-and-description outline is exactly what Claude
Design's presentation generator consumes.

**The `report` and `infographic` routes** dispatch the named cogni-visual skill;
the exact dispatch block, required inputs, and style options (e.g.
`story-to-infographic`'s `style_preset`) live in `publish-routing.md` — follow
it rather than restating them here, so the skill and the reference cannot drift.

**Graceful degradation.** When `cogni-visual` is not installed, the `report`
and `infographic` routes cannot run — skip the dispatch with a one-line note
naming the absent plugin, and offer the consult-native outline brief instead so
the consultant still leaves with a usable artifact. Never fail the run because a
downstream plugin is missing.

### 5. Record the publish lineage in field.json

Store the brief as a **path reference plus lineage** on the deliverable entry —
never copy brief content into consult state. Mirroring the source-lineage
contract, the deliverable and its downstream brief are linked by path, so an
upstream correction stays visible downstream without duplication.

Add (append) one entry to the deliverable's `publish` array in
`action-fields/<field-slug>/field.json` via a direct `Edit` — the field.json
seam needs no script (`engagement-status.sh` passes every deliverable field
through verbatim). Shape:

```json
"publish": [
  {
    "format": "slides",
    "brief_path": "action-fields/<field-slug>/publish/<deliverable-slug>-outline.md",
    "route_steps": ["consult-native-outline", "copywriter:tone"],
    "source_deliverable": "<deliverable-slug>",
    "published_at": "<ISO-8601 timestamp>"
  }
]
```

`brief_path` is the route's output path (the outline for slides/web-poster, or
the enriched/infographic output path for the visual routes). `route_steps`
records the dispatch chain actually run (including a skipped polish, noted as
such). Because `publish` is an array, publishing a second format **appends** a
new entry rather than overwriting the first.

### 6. Print the Claude Design handoff

End by pointing the consultant at the handoff: the brief's path **is** the
handoff. Print the brief path and the one-line instruction — hand the brief to
Claude Design (claude.ai/design) to render it in your design system. cogni-consult
stops at the brief; Claude Design renders and applies brand.

If multiple formats were produced in this session, list each brief path.

## Important Notes

- **Elected, never automatic.** This skill runs only on explicit consultant
  invocation against a `complete` deliverable. It must never be auto-fired from
  the `consult-design-thinking` loop or any other skill's close step — those may
  *point* to it, but the consultant elects it.
- **Path reference, not content copy.** The brief is stored as a `brief_path` in
  `field.json`; brief content is never duplicated into consult state. The link
  is the path, so corrections cascade without drift.
- **The plugin's responsibility ends at the brief.** Rendering and brand
  application happen in Claude Design. This skill produces no rendered artifact
  and owns no theme.
- **Graceful degradation.** When `cogni-visual` is absent, the report and
  infographic routes are skipped (offer the consult-native outline instead);
  when `cogni-copywriting` is absent, the polish step is skipped. Either way the
  run still produces a valid brief — a missing downstream plugin degrades the
  output, it never fails the run.
- **Framework-shaped, not arc-shaped.** The slides/web-poster route builds the
  outline directly from the deliverable's framework (Pyramid/MECE/SCQA). It does
  not arc-ify and does not dispatch the arc-optimized cogni-visual story skills —
  that is a deliberate quality choice, not an omission.
