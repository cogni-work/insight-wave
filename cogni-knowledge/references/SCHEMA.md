---
schema_version: "1.0"
purpose: >-
  Canonical, machine-readable definition of the six cogni-knowledge wiki page
  types. This file is the single source of truth for what each type *is*; the
  per-type `definition` and `stage` strings in `scripts/sub_index.py`'s REGISTRY
  mirror the values below verbatim and are read at render time to stamp a
  definition preamble + population cue onto every `wiki/<type>/index.md`.
types:
  - type_key: concepts
    plural_label: Concepts
    stage: distill
    listing_order: alpha-slug
    definition: >-
      A concept is a recurring idea, theme, or abstraction distilled from
      multiple sources — the durable "what it means" of the knowledge base,
      independent of any single document.
  - type_key: entities
    plural_label: Entities
    stage: distill
    listing_order: alpha-slug
    definition: >-
      An entity is a named organization, system, product, standard, or other
      non-person actor the sources refer to — the concrete "who/what" the
      knowledge base tracks.
  - type_key: people
    plural_label: People
    stage: distill
    listing_order: alpha-slug
    definition: >-
      A person is a named individual referenced across the sources — an author,
      official, researcher, or other human actor whose statements or roles the
      knowledge base tracks.
  - type_key: sources
    plural_label: Sources
    stage: ingest
    listing_order: alpha-slug
    definition: >-
      A source is a single ingested document (article, report, page, or
      dataset) with its extracted claims — the primary evidence the rest of the
      wiki is grounded in.
  - type_key: questions
    plural_label: Research questions
    stage: ingest
    listing_order: alpha-slug
    definition: >-
      A research question is a sub-question the knowledge base set out to
      answer, paired with the claims from sources that address it — the "what we
      asked" spine of a research run.
  - type_key: syntheses
    plural_label: Syntheses
    stage: compose
    listing_order: alpha-slug
    definition: >-
      A synthesis is a composed, verified report deposited back into the wiki —
      the cross-source narrative answer that cites the sources, concepts, and
      questions it draws on.
---

# Wiki page-type schema

cogni-knowledge stores every distilled and ingested page under one of **six page
types**. This document is the canonical, machine-readable definition of those
types — what each one *is*, which pipeline stage produces its instances, and the
order its sub-index lists them in.

The renderer (`scripts/sub_index.py`) carries a verbatim copy of each type's
`definition` and `stage` in its `REGISTRY`, and stamps them — together with a
deterministic population cue — onto the machine-owned head of every
`wiki/<type>/index.md`. When this schema changes, update the matching REGISTRY
entry in the same change so the two surfaces never drift.

| Type | Label | Stage | Listing order | What it is |
|------|-------|-------|---------------|-----------|
| `concepts` | Concepts | distill | alpha-slug | A recurring idea, theme, or abstraction distilled from multiple sources — the durable "what it means" of the knowledge base. |
| `entities` | Entities | distill | alpha-slug | A named organization, system, product, or standard the sources refer to — the concrete "who/what" the base tracks. |
| `people` | People | distill | alpha-slug | A named individual referenced across the sources — an author, official, or researcher whose statements or roles the base tracks. |
| `sources` | Sources | ingest | alpha-slug | A single ingested document with its extracted claims — the primary evidence the rest of the wiki is grounded in. |
| `questions` | Research questions | ingest | alpha-slug | A sub-question the base set out to answer, paired with the claims that address it — the "what we asked" spine of a run. |
| `syntheses` | Syntheses | compose | alpha-slug | A composed, verified report deposited back into the wiki — the cross-source narrative answer that cites its evidence. |

## Fields

- **`type_key`** — the REGISTRY key and the `wiki/<type>/` directory name.
- **`plural_label`** — the page H1 heading text (without the leading `# `).
- **`stage`** — the pipeline phase that produces instances of this type:
  `ingest` (deposited per-source at ingest time), `distill` (clustered from
  source claims at distill time), or `compose` (written by the composer and
  deposited at finalize).
- **`listing_order`** — how the sub-index orders pages within each theme.
  `alpha-slug` means ascending by page slug (the order all six types use today).
- **`definition`** — a one- or two-sentence prose definition of what a single
  instance of the type *is*. Written to be **instance-free**: a reader can state
  what the type means without opening any instance page, and the text carries no
  `[[wikilink]]` to a specific instance.
