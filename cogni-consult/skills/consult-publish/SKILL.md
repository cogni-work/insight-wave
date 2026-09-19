---
name: consult-publish
description: |
  This skill should be used when a consultant elects to turn a completed
  cogni-consult deliverable into presentation-ready documentation — a brief or,
  for supported formats, an optional locally rendered artifact. Trigger on: "publish this
  deliverable", "turn <deliverable> into slides", "make a poster/web page from
  <deliverable>", "build a report from <deliverable>", "make an infographic
  from <deliverable>", "present this deliverable", "render-ready brief", or
  "hand this to Claude Design". Runs only when the named deliverable's
  `state` is `complete`. It is consultant-elected: invoke it explicitly — it is
  never auto-fired from the design-thinking loop.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Publish a Deliverable

Turn one completed deliverable into a **brief**. For `slides` and `web-poster`,
the consultant may additionally elect the public cogni-publishing render chain;
`report` and `infographic` remain Claude Design handoffs. The brief is always
retained and recorded, and cogni-consult never owns brand.

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

### 0. Resolve the Interaction Language

Before any user-facing output, resolve the **interaction language** — the
workspace default, overridden by the user's message language — per
`$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`, which owns the
resolution ladder. Conduct the entire conversation in the resolved language.
It is independent of the engagement's `language` field, which is the
deliverable axis. This contract holds on the default path: it does not depend
on an output style being active.

The `description` of a Bash tool call is rendered to the consultant, so it is
user copy — write it in the interaction language, outcome-shaped, at most 6
words, with no script, file, or skill names, and never derived from the
script's filename or header comment. Worked pair:
`Discover cogni-consult engagements` → `Laufende Engagements holen`.
Section (f) of the canonical ecosystem register owns these five constraints —
edit them there first, then mirror into
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md` and here.

The register that output follows has two tiers. The overlay
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md` carries this plugin's own
state lexicon, coinages and German step vocabulary, and opens with the command
that reads the canonical ecosystem register behind it — which owns scope, the
table contract, step announcements and brevity budgets, and the executive
register. Read the overlay and follow that command; table cells and headers are
user copy too, not an exemption.

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

The brief text may be polished with `cogni-publishing:copywriter` before
handoff. This is optional and graceful-degrading — **if the `copywriter` skill is
not installed, skip it with a one-line note**; the route still produces a valid
brief.

For slides/web-poster, polish a working Markdown copy of the deliverable before
mapping its frozen text into `direct-brief@1`; never run a prose editor over the
JSON artifact. For report/infographic, polish the drafted Markdown brief after
step 4 builds it. In both cases, assumption resolution remains the last content
transformation before lineage is recorded.

The dispatch invocation and the `--scope` options (`tone` / `compress` / `full`)
are the canonical ones in `$CLAUDE_PLUGIN_ROOT/references/publish-routing.md` —
see its "Optional Voice Polish" section rather than restating them here. One
hard rule regardless of scope: the polish must preserve `{{asm:id}}` placeholder
tokens **verbatim** — a reworded token no longer matches the step-4.5 resolver
and would slip past the fail-loud gate.

### 4. Build the brief by route

Resolve the elected format to its route per `publish-routing.md` — the reference
holds the exact dispatch block and per-route options; the mapping below is the
execution summary, so read the reference for each route before dispatching:

| Elected format | Route | Brief output path |
|---|---|---|
| `slides` / `web-poster` | consult-native direct brief (built here, not dispatched) | `action-fields/<field-slug>/publish/<deliverable-slug>-direct-brief.json` |
| `report` | consult-native report-outline brief (built here, not dispatched) | `action-fields/<field-slug>/publish/<deliverable-slug>-report-outline.md` |
| `infographic` | consult-native infographic brief (built here, not dispatched) | `action-fields/<field-slug>/publish/<deliverable-slug>-infographic-brief.md` |

**Building the consult-native direct brief (`slides` / `web-poster`).** This is the
one route the skill builds itself rather than dispatching. Consult deliverables
are framework-shaped (Pyramid / SCQA / MECE), not arc-shaped, so this path does
**not** re-narrate through `cogni-publishing:text-to-narrative` — arc-ifying a
framework-shaped deliverable weakens its executive register. Derive the outline directly from the
deliverable's own structure as `direct-brief@1`: declare
`artifact_type: "direct-brief"`, `artifact_version: "1"`, an artifact id,
`structure.framework`, ordered `sections[]`, and `sources[]`. Each section has
an id, title, body, optional role/notes/data, and source references. Preserve
citations and source identity — Pyramid answer / governing thought → the
opening, each MECE group / SCQA movement → one section in the deliverable's own
order, supporting evidence carried into the matching section body (never
dropped). This is the public cogni-publishing direct-input contract and it never
acquires a story arc.

When local rendering is declined and the consultant wants a Claude Design
outline handoff, the author may additionally project the same sections into a
companion Markdown outline and layer the **optional presentation-intent**
annotation on it — a `design:` front-matter block, a per-slide
`slide_points`/`talk_track` split, a per-slide `type:` tag, brief-level
`key_figures:`, and climax/TBD marks — so the deck builds in one renderer pass
instead of a clarify-then-build round. It is optional and additive: a brief
without it still renders. Build it per the **Optional presentation-intent
layer** subsection in `publish-routing.md` (the canonical schema) — do not
restate the field shape here. The companion never replaces the direct brief's
`brief_path` and is never passed to `publishing-validate`.

**The `report` and `infographic` routes** are built here too, not dispatched —
derive a consult-native brief directly from the deliverable's framework (a
report-outline brief, or an infographic brief of headline + hero facts + MECE
segments + takeaway), citations preserved. `publish-routing.md` holds the
per-route brief recipe and output path — follow it rather than restating them
here, so the skill and the reference cannot drift.

`report` and `infographic` stop at the brief and go to Claude Design. For
`slides` and `web-poster`, continue after step 4.5 only when the consultant
elects local rendering and cogni-publishing is installed; otherwise retain the
brief as the complete handoff. A missing publishing plugin degrades to the brief
without failing the publish.

### 4.5 Resolve assumption placeholders (mandatory)

After the route content is drafted — and after any optional step-3 polish, so
resolution is unambiguously the last content transformation before step 5 —
resolve every `{{asm:id}}` placeholder against the engagement's `assumptions.json` registry
(the single source of truth for assumption values — schema in
`$CLAUDE_PLUGIN_ROOT/references/data-model.md`). Unlike the step-3 polish,
this pass is **mandatory and fail-loud**, not optional and graceful-degrading:
a placeholder that cannot be resolved must stop the publish, never ship as a
literal `{{asm:...}}` in a client-facing brief and never be silently dropped.

For Markdown briefs, run the resolver on the built brief in place. For the
direct JSON route, resolve the working Markdown before JSON serialization,
serialize the resolved strings with proper JSON escaping, and reject the
artifact if any placeholder remains. The exact failure contract is canonical in
`$CLAUDE_PLUGIN_ROOT/references/publish-routing.md` (Assumption Resolution
section) — read it rather than restating it here. On
`success: false`, stop the publish, tell the consultant which assumption ids
are unknown (the envelope lists all of them), and do **not** proceed to step 5
— the engagement's registry (or the deliverable's placeholder) needs fixing
first. A brief with no placeholders passes trivially.

### 4.6 Optional local render for supported formats

Only `slides` and `web-poster` have a local route. After assumption resolution,
and only when the consultant elects it, run the public capabilities in order:

1. `cogni-publishing:publishing-validate` with `normalize --kind direct`.
2. `cogni-publishing:design-compose`, preserving every frozen record and source.
3. `cogni-publishing:design-render` with target `pptx` for `slides`, or `html`
   for `web-poster`, using the elected publishing theme. PPTX uses the host presentation
   skill; HTML follows the publishing DOM contract. Missing host capability returns
   `platform_renderer_unavailable`; keep the validated brief and report the unavailable route.

Never route the direct brief through `cogni-publishing:text-to-narrative` and
never substitute a different renderer. Record the rendered artifact's
project-relative path in step 5. `report` and `infographic` are unsupported by
this local chain: hand their briefs to Claude Design and do not improvise a
local target.

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
    "brief_path": "action-fields/<field-slug>/publish/<deliverable-slug>-direct-brief.json",
    "artifact_path": "action-fields/<field-slug>/publish/<deliverable-slug>/deck.pptx",
    "route_steps": ["consult-native-direct-brief", "copywriter:tone", "local-render:pptx"],
    "source_deliverable": "<deliverable-slug>",
    "published_at": "<ISO-8601 timestamp>"
  }
]
```

`brief_path` is the route's output path — the direct brief for slides/web-poster, the
`<deliverable-slug>-report-outline.md` for report, or the
`<deliverable-slug>-infographic-brief.md` for infographic (all under
`publish/`). `route_steps` records the build chain actually run, named for the
native builder: `consult-native-direct-brief` (slides/web-poster),
`consult-native-report-outline` (report), or `consult-native-infographic-brief`
(infographic), plus any `copywriter:<scope>` polish (or a skipped polish, noted
as such). A successful elected publishing validate → compose → render
continuation is recorded as exactly one `local-render:pptx` or
`local-render:html` lineage step; the three public capability calls remain
execution detail rather than three lineage entries. `artifact_path` is additive
and optional: include it only after a
successful local render, pointing to `deck.pptx` for slides or `index.html` for
web-poster. Because `publish` is an array, publishing a second format **appends**
a new entry rather than overwriting the first.

### 6. Print the handoff

End by printing the brief path and, when present, the rendered artifact path.
For report and infographic (and for a declined or unavailable local route),
give the one-line Claude Design handoff. For a successful local route, name the
PPTX or HTML artifact and keep the brief path visible as its provenance source.

If multiple formats were produced in this session, list each brief path.

## Important Notes

- **Elected, never automatic.** This skill runs only on explicit consultant
  invocation against a `complete` deliverable. It must never be auto-fired from
  the `consult-design-thinking` loop or any other skill's close step — those may
  *point* to it, but the consultant elects it.
- **Path reference, not content copy.** The brief is stored as a `brief_path` in
  `field.json`; brief content is never duplicated into consult state. The link
  is the path, so corrections cascade without drift.
- **Local rendering is elected and bounded.** Slides may render to PPTX and
  web-poster to HTML through public cogni-publishing capabilities. Reports and
  infographics remain Claude Design handoffs. A missing publishing plugin leaves
  a valid brief rather than failing the run.
- **Assumption resolution is fail-loud, not graceful-degrading.** The step-4.5
  `{{asm:id}}` pass is the one mandatory gate between building a brief and
  handing it off — a missing polish degrades style, but an unresolved
  assumption ships a wrong or placeholder number to a client.
- **Framework-shaped, not arc-shaped.** All four routes build the brief directly
  from the deliverable's framework (Pyramid/MECE/SCQA). None arc-ifies and none
  dispatches the arc-optimized cogni-publishing story skill on the standard path —
  that is a deliberate quality choice, not an omission.
