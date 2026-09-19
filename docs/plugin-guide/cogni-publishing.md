# cogni-publishing

Turn an approved brief into a slide deck or a branded page without losing a word, a number or a source along the way.

> For installation details and the canonical positioning, see the [cogni-publishing README](../../cogni-publishing/README.md).

---

## Overview

cogni-publishing is the boundary between what an author signed off and what a renderer lays out. You hand it a brief — either a narrative slides brief with a story arc, or a direct brief that carries its own framework (Pyramid, SCQA, MECE) — and it walks that brief through four checked stages: normalize, compose, render, verify. Each stage produces a versioned artifact, and each stage refuses to proceed when the stage before it does not hold up.

The practical effect is that copy stops drifting. Downstream artifacts reference normalized copy by id rather than carrying their own duplicate, so an edit cannot land in one copy and miss another. Citations keep their original source ids from brief to finished page, so a figure on a slide still names where it came from. And a unit that does not fit a slide fails as an explicit finding naming the unit and the limit, instead of being silently shrunk or trimmed.

The plugin also owns the theme lifecycle for the whole ecosystem — creating, auditing, importing and selecting the visual themes that every themed output draws on.

Two properties matter when you decide where to run it. The validator is Python standard library only: no Node, no model API, no rendering package, no network. And the plugin is installable on its own — it needs no other insight-wave plugin to do its job.

### Prerequisites

- **Nothing, for validation and composition.** `publishing-validate` and `design-compose` are deterministic and standalone.
- **A brief.** Either a narrative slides design brief (what `text-to-narrative` produces) or a structured direct brief that carries its own framework.
- **A theme**, for anything that renders. Use `/cogni-publishing:manage-themes` to pick or author one; bundled presets work out of the box.
- **Optional: a pinned browser runtime**, only if you want a rendered HTML page measured offline. Rendering itself does not need it.

Upstream plugins that commonly feed it: cogni-trends, cogni-portfolio, cogni-knowledge, cogni-consult and cogni-marketing all produce material that becomes a brief. Downstream, cogni-website resolves its theme and its design-variable contract through this plugin.

---

## Key Concepts

### The four artifacts

Everything in this plugin is a transformation between four versioned artifacts, and knowing which one you are holding tells you which skill to reach for next.

```text
design-brief@1.1 ─┐
                  ├─normalize─> normalized-brief@1
direct-brief@1 ───┘

normalized-brief@1 + pattern-library@1 ─compose─> semantic-composition@2 ─host render─┬─> index.html
                                                                                                          └─> deck.pptx
```

- **normalized-brief@1** — the only place copy and data live. Ordered records with stable ids, source records with their original ids, freeze guarantees, provenance.
- **semantic-composition@2** — pattern-bound units. Every record, field, note, citation, evidence label and data point bound exactly once by id and digest, plus a content fingerprint of the brief. No copy, no geometry.
- **render-provenance@1** — the audit records. What every deck object is and whether it is editable; which runtime, theme tokens, fonts and fingerprint a render was built from.

`references/artifact-contracts.md` in the plugin is the normative definition, with one JSON Schema per artifact beside it.

### Frozen copy

"Frozen" is the rule that makes the rest work: once copy is normalized, no downstream stage may alter, shorten, merge or reorder it. A composition that carries its own text is rejected. A render that changes a sentence fails its own fidelity check. When something genuinely does not fit, the answer is a finding, not a rewrite — and the fix belongs upstream in the brief, never in the artifact that failed.

This is why you will sometimes see a skill refuse rather than help. That refusal is the feature.

### Proof patterns

Between the brief and any renderer sits a small library of reusable proof patterns — answer/emphasis, comparison, sourced chart, conceptual system diagram, source register. Each carries purpose, eligibility, slots and limits, evidence needs, accessibility semantics, target capabilities, variants and validated specimens, plus a status of `accepted` or `proposed`. Composition binds each frozen unit to an accepted pattern. Only `accepted` patterns are usable in production, so an experimental pattern cannot quietly reach a client deliverable.

### Narrative briefs versus direct briefs

A narrative brief carries a story arc and is what you want for a keynote, a thought-leadership piece or an insight summary. A direct brief carries its own framework and is what you want for consult material — the plugin will not impose an arc, a BLUF slide or a narrative element count on it. Pick the adapter that matches how the material was actually written.

---

## Getting Started

The shortest useful path is validate → compose → render → verify. Each step has a skill, and each step hands the next one a file.

### Step 1 — Validate and normalize the brief

```text
Validate this publishing brief: path/to/design-brief.md
```

`publishing-validate` normalizes the brief into a `normalized-brief@1` and reports one JSON envelope with exit status 0, 1 or 2. Save the `data` of a successful `normalize` run as its own JSON file — that artifact, not the envelope around it, is what the next step consumes.

You can also call the validator directly from the plugin directory:

```bash
python3 scripts/validate-publishing.py normalize --kind narrative --input tests/fixtures/narrative-slides-v1.md
python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/direct-consult-v1.json
```

### Step 2 — Bind the brief to visual patterns

```text
Compose this normalized brief against the pattern library
```

`design-compose` chooses an accepted pattern and variant for each frozen unit and binds every record, field, note, citation, evidence label and dataset exactly once, in authored order. It fills the digests, the content fingerprint and the citations itself. It does not render, and it does not decide geometry.

When no accepted pattern fits a unit, it reports that and stops. That is the point at which to change the brief, not the composition.

### Step 3 — Render a target

```text
Render this composition as an editable PPTX
```

`design-render` passes the validated composition and frozen brief to the selected host capability. HTML follows the DOM contract; PPTX uses the host presentation skill. Both require independent verification and visual review before handover.

### Step 4 — Verify before handover

```text
Verify this deliverable against the frozen brief before handover
```

`design-verify` checks the delivered file again, independently, against the frozen inputs. Rendering already runs its own fidelity checks; this adds what a render-time check cannot hold — per-family content preservation, object-level editability, declared accessibility, the critical visual classes, and a persisted visual review record.

### Try it

To see the refusal behaviour before you trust it with real material, run the bundled dangling-reference fixture from the plugin directory:

```bash
python3 scripts/validate-publishing.py validate --input tests/fixtures/dangling-reference.json
```

```json
{"success": false, "data": {"code": "dangling-reference", "check": "copy_refs", "artifact": "semantic_composition", "reference": "procurement"}, "error": "unit support-process.copy_refs names procurement, which nothing declares"}
```

Exit status 1: the composition references a record the normalized brief does not carry, so no downstream artifact is produced.

---

## Capabilities

Seven skills ship with this plugin. Two of them — `copywrite` and `text-to-narrative` — also have slash commands, so they work under a bare slash; the other five are invoked as `/cogni-publishing:<skill>`.

The plugin also ships one agent — `copywriter` (opus) — which the `/copywrite` command dispatches to perform the polish pass itself; no other skill in this plugin dispatches an agent.

### text-to-narrative — turn source material into an arc-driven narrative and a frozen brief

Transforms text into one of 15 arc-governed executive narratives, validates it, and selects frozen copy into a self-contained design brief. It then routes normally through normalize → compose → render for slides, documents, infographics or web output. A handoff to Claude Design is optional, never required — the local route is the default.

> "Turn this research summary into an executive narrative and a design brief"

### copywriter — polish, translate, compress or review a document

Polishes, rewrites or creates business documents using seven messaging frameworks (BLUF, McKinsey Pyramid, SCQA, STAR, PSB, FAB, inverted pyramid) plus persuasion technique. It handles German documents in the Wolf Schneider tradition, preserves story arcs when a document carries an `arc_id`, does EN/DE-pivot translation across seven languages, measures readability deterministically, and can read a document back through parallel stakeholder personas instead of rewriting it. It needs no renderer and no workspace setup.

> "/copywrite quarterly-review.md --scope=review"

### design-compose — bind a normalized brief to the pattern library

Binds every frozen record, field, note, citation, evidence label and dataset of a normalized brief to the library's accepted proof patterns, exactly once and in authored order, producing a copy-free, geometry-free `semantic-composition@2`. It fills an unpatterned metric unit's pattern from the brief's own key figures, never overwrites a choice the draft already carries, and never renders. The validator rejects copy or geometry in the composition, unsourced or invented chart values, content that does not fit, and any use of a `proposed` pattern.

> "Compose this normalized brief and tell me why any unit was rejected"

### design-render — lay the composition out and write the deliverable

Resolves the theme by the composition's pinned design-system name, compiles its tokens, resolves its fonts, and lays each unit out on a fixed canvas. The HTML target writes one self-contained page with sourced bar charts, labelled system figures, side-by-side comparisons, linked citations and a closing source register. The PPTX target writes an editable deck: native text frames, system diagrams as editable shapes and connectors, the sourced chart as a native chart backed by an embedded workbook, speaker notes on notes slides, and citations as hyperlinks whose targets equal the source URLs byte for byte.

Host-generated decks are non-reproducible. A fit failure returns to the same host capability for a bounded presentation repair; frozen copy never changes. Creation runs `design-verify` before reporting success.

> "/cogni-publishing:design-render — render this composition as HTML with the cogni-work theme"

### design-verify — check a deliverable independently before handover

Checks a delivered page or deck against its frozen brief and composition, family by family: copy, dataset values, source URLs, evidence status, notes and unit order. It proves deck editability with text and chart edit witnesses, grades accessibility against each target's declared capabilities (reading order, text alternatives, contrast from the brand's tokens, non-colour cues), and scans the critical visual classes — clipping, overlap, missing glyphs, unreadable text, misleading figure encodings. Any open finding fails the verdict; there is no pass rate. Its repair loop tries other variants of a failing unit's pattern within a finite budget and never rewrites content.

> "/cogni-publishing:design-verify — audit this rendered page for accessibility before I send it"

### publishing-validate — check, normalize and resolve configuration

Normalizes a narrative slides brief or a framework-shaped direct brief into a provenance-preserving `normalized-brief@1`, validates an artifact chain for version compatibility and dangling references, and resolves publishing configuration precedence while naming the origin of every value. Deterministic and standalone: no model call, no renderer, no network. It never writes briefs.

> "/cogni-publishing:publishing-validate — why was this brief rejected?"

### manage-themes — own the visual identity every themed output draws on

Creates, audits, improves, selects and applies visual design themes, sourced from Claude Design bundles or from bundled presets. Audits cover contrast, palette harmony, typography pairing and completeness. A foreground that points at an ink colour stays a reference through import, storage and CSS, so changing a palette moves every role that depends on it — and existing themes keep working untouched.

Operation 11 (Select Theme) is the contract other visual plugins resolve a theme through; it returns `theme_path`, `theme_name` and `theme_slug`.

> "/cogni-publishing:manage-themes — check my theme's contrast and tell me what to fix"

---

## Integration Points

### Upstream inputs

Any plugin that produces material worth publishing can feed this one. In practice cogni-trends (trend reports), cogni-portfolio (propositions and customer narratives), cogni-knowledge (research syntheses), cogni-consult (engagement deliverables) and cogni-marketing (long-form content) are the common sources. The material arrives either as text for `text-to-narrative` to shape, or as a direct brief that already carries its framework.

### Downstream consumers

cogni-website resolves its theme and the public design-variables contract through `manage-themes` Operation 11. cogni-marketing's long-form pipeline routes through `text-to-narrative` before `copywriter` polish, so that `insight-summary.md` carries an `arc_id` the polish pass reads.

### Migration note

`cogni-workspace` exposes a same-name route that delegates to this plugin's `manage-themes` for a declared migration window closing 2026-12-15. New work should call the cogni-publishing skill directly. See [the publishing migration note](../publishing-migration.md) for what changes and when.

### Related guides

- [Content Pipeline workflow](../workflows/content-pipeline.md) — where narrative and polish sit in the marketing sequence
- [Trends to Solutions workflow](../workflows/trends-to-solutions.md) — the upstream pipeline that most often ends here
- [cogni-website guide](cogni-website.md) — the site generator that inherits this plugin's theme and design-variable contract
- [cogni-workspace guide](cogni-workspace.md) — the shared workspace state the ecosystem's plugins draw on

---

## Common Workflows

### Publishing a trend report as a client deck

Run the trends pipeline to a finished report, hand the report to `text-to-narrative` to pick an arc and freeze a brief, then walk normalize → compose → render with `--target pptx` and finish with `design-verify`. The [Trends to Solutions workflow](../workflows/trends-to-solutions.md) covers the upstream half.

### Polishing long-form marketing content

For thought leadership, whitepapers and keynote abstracts, `text-to-narrative` sits between content generation and `copywriter` polish. Short-form formats skip the narrative step entirely. The [Content Pipeline workflow](../workflows/content-pipeline.md) has the full sequence.

### Reviewing a document without rewriting it

`/copywrite <file> --scope=review` reads the document back through parallel stakeholder personas and reports what each one would push back on. Nothing is rewritten — you get findings, and you decide.

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| `dangling-reference` from `validate` | The composition names a record the normalized brief does not carry | Fix the brief or the composition draft — never delete the check |
| A unit is rejected with no fitting pattern | No `accepted` pattern matches the unit's shape | Change the brief so the unit fits an accepted pattern; a `proposed` pattern cannot be used in production |
| `fit-overflow` on a PPTX render | The unit's content exceeds the slide's fixed canvas | Shorten the content in the brief and re-normalize; the renderer will not shrink text to fit |
| Composition rejected for carrying copy | Text was written into the composition instead of referenced by id | Remove the text; bind to the normalized brief's record ids |
| `design-verify` fails on contrast | The theme's tokens do not clear the contrast gate | Run `/cogni-publishing:manage-themes` audit and fix the palette, not the rendered file |
| A font was substituted in the output | The theme's face is not licensed for embedding | Check `render-provenance@1` — every substitution is recorded with its reason |
| Normalize rejects a narrative brief outright | The brief does not match the slides grammar of `design-brief@1.1` | The adapter refuses rather than guesses; correct the frontmatter, Rendering Contract or `## Slide N:` units |
| A theme call resolves to the old workspace name | Legacy delegate still in use | Call `/cogni-publishing:manage-themes` directly; see [the migration note](../publishing-migration.md) |

---

## Extending This Plugin

The pattern library is the natural extension point: a new proof pattern needs purpose, eligibility, slots and limits, evidence needs, accessibility semantics, target capabilities, variants and a validated specimen, and it enters as `proposed` before it is accepted. New themes, new story arcs for `text-to-narrative` and additional messaging frameworks for `copywriter` are all welcome too.

Additional targets must preserve frozen content, declare their capabilities and provide independently readable output for verification.

See [../contributing/plugin-development.md](../contributing/plugin-development.md) and [../../CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

