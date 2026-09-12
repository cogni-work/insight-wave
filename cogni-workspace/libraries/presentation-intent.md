---
library_id: presentation-intent
version: 1.0.0
created: 2026-09-03
updated: 2026-09-03
---

# Presentation-intent vocabulary

The canonical definition of the presentation-intent layer — the annotation an
author may add on top of a narrative outline so a slide renderer does not have to
guess the design register or the on-slide-vs-notes split.

This file is canonical. `cogni-consult/references/publish-routing.md` carries a
synchronized copy of the shared block below, and
`cogni-consult/tests/test-presentation-intent-sync.sh` compares the two byte for
byte. Edit the block in one file and the guard goes red until the other matches.

The layer is **optional and additive**: omit any piece and the brief still
renders. In this plugin the layer lives in the presentation brief:
`libraries/presentation-brief-template.md` defines the `design:`, `climax:` and
`key_figures:` keys a brief author writes, and the slide renderers read them.

## The shared vocabulary

Everything between the two markers is the synchronized block. Do not edit it in
isolation — the guard compares the marker lines and the blank-line padding too, so
the two copies must match exactly.

<!-- PRESENTATION-INTENT:SHARED:START -->

1. **`design:` front-matter block** — a small block at the head of the brief
   declaring the deck's design intent, so the renderer does not ask. Fields, all
   optional with sensible defaults:
   - `register` — the visual/tonal register (e.g. `quiet-executive`, `bold`).
     Default: the deliverable's own register (executive/Pyramid).
   - `dark_slides: [...]` — slide numbers to render dark, as rhythm anchors
     (e.g. section breaks, the climax). Default: none.
   - `speaker_notes` — the speaker-notes style (e.g. `full-script`,
     `calm peer-to-peer`, `bullets`). Default: bullets.
   - `imagery` — imagery direction (e.g. `none`, `type-only`, `photographic`).
     Default: `none`.
   - `variations` — how many design variations to generate. Default: 1.
2. **Per-slide `slide_points` vs. `talk_track` split** — instead of one
   `section_body` that blends wall copy with presenter rationale, split the entry
   into `slide_points` (3–4 short on-slide lines, max) and `talk_track` (the
   reasoning the presenter speaks). This moves the on-slide-vs-notes distillation
   decision into the brief. When the split is omitted, `section_body` stands as
   before — the renderer distills it.
3. **Per-slide `type:` tag** — declares the intended visual treatment instead of
   leaving the renderer to infer it (so a quote slide is not built as bullets).
   One of: `cover`, `bluf`, `two-column`, `table`, `timeline`, `quote`, `metric`,
   `roles`. Default: inferred from the section content, as today.
4. **`key_figures:`** — a brief-level list promoting the hero numbers out of
   prose (e.g. `~25 auditors`, `8–10 shortlist`, `240 min`, `≥80% return`,
   `~30 backlog`) so the renderer can build big-number moments rather than
   burying them in body text. A promoted figure that carries a provenance
   marker keeps it (e.g. `€4.2bn (prov: claim/reviewed)`) — the marker travels
   with the value into the stat block, never stripped. Default: none (numbers
   stay inline).
5. **Climax and TBD marks** — name the point slide for emphasis (e.g.
   `climax: slide 11` — the asks), and flag genuine placeholders
   (`tbd: ["CO-1…4 staffing", "confirm exact title"]`) so the renderer treats
   them as open vs. settled copy. Default: none.

**Keep, regardless of the layer:** the meta-instruction `note:` line (e.g.
"render citations as footnotes / speaker notes") and the **"design is frozen"**
framing — both proved useful in real handoffs; favor more of that over reasoning
prose buried inside bullets.

<!-- PRESENTATION-INTENT:SHARED:END -->

## Value shapes in the emitted brief

The shared block above is vocabulary, not grammar. Where a clause spells a value
inline it is illustrative prose; the emitted brief's shape is defined by
`libraries/presentation-brief-template.md`. One divergence worth
naming: clause 5 writes `climax: slide 11`, but the emitted key is a **bare slide
integer** — `climax: 4` — as both the output template and `EXAMPLE_BRIEF.md`
show.

## Copy is frozen

The renderer reproduces the author's copy verbatim and never rewrites it. The
author owns the slide-vs-notes and emphasis decisions; the renderer owns layout,
type and imagery. A renderer that "improves" a line has changed the deliverable,
not styled it.

## Layout to type mapping

`cogni-workspace/libraries/pptx-layouts.md` defines a closed set of eleven slide
layouts. This table binds each to the `type:` tag a renderer should treat it as.

| Layout | `type:` tag | Note |
|---|---|---|
| `title-slide` | `cover` | |
| `stat-card-with-context` | `metric` | |
| `four-quadrants` | `metric` / `roles` | `metric` in stat-card mode, `roles` in text-card mode |
| `two-columns-equal` | `two-column` | |
| `is-does-means` | `table` | |
| `three-options` | `table` | |
| `timeline-steps` | `timeline` | |
| `layered-architecture` | `table` | |
| `process-flow` | `timeline` | |
| `gantt-chart` | `timeline` | |
| `closing-slide` | `bluf` | |
| references slide | `table` | Tagged by `Slide-Kind: references` — see below |

**The references row is tagged, not laid out.** The references slide is real — it is
documented as placement guidance in `pptx-layouts.md` under "Notes for
Generators", and it renders after the closing slide as an appendix — but it is
still **not** one of the eleven layouts and has no layout name of its own. What
distinguishes it is the per-slide key `Slide-Kind: references`, which the brief
grammar now emits. The row above records the type-tag treatment a renderer should
apply to that slide.

**`quote` has no layout mapping, deliberately.** It is one of the eight tags, but
no layout in the closed set renders as a pull quote. A symmetric "every tag
appears in this table" check would therefore be wrong, and none is written.

**`sources` is deliberately not in the list above.** The design brief's slides target
closes on a `sources` unit (`skills/text-to-narrative/references/design-brief-template.md`),
so the two vocabularies differ by one tag. That is intended, not drift: this chain has no
`sources` *type* because the trailing source register is not a content shape here — it is
the references slide, distinguished by the per-slide key `Slide-Kind: references` and given
the `table` tag treatment in the mapping above. The list is also byte-synchronized with
`cogni-consult/references/publish-routing.md`, so it describes what both consumers render,
not what the brief grammar emits.
