# Research Routing Rule

When research is needed anywhere in a cogni-consult engagement — scoping
evidence for a dimension, empathize/define inputs for a deliverable, or a
consultant request to "look into X" — **always dispatch the cogni-knowledge
inverted pipeline against the engagement's bound knowledge base**. Never use
raw WebSearch for engagement research. cogni-knowledge deposits structured,
citable syntheses into one base that **compounds across the whole
engagement**: every deliverable's research builds on what earlier
deliverables already established instead of dying as a throwaway per-session
report, and deliverable artifacts cite the base via their `sources[]`
`kb_ref` entries so claim corrections cascade.

This file is the canonical rule. The deliverable-producing skills
(`consult-scope`, `consult-design-thinking`, `consult-action-fields`) point
here rather than restating the routing, so the contract cannot drift across
skills.

## One Base Per Engagement

The base is bound once, at setup: `consult-setup` dispatches
`cogni-knowledge:knowledge-setup` and records the slug in
`consult-project.json` → `plugin_refs.knowledge_base`. Every later research
run, in any skill, binds to that base by passing the same
`--knowledge-slug <plugin_refs.knowledge_base>` — never a fresh slug, never
a second base. If `plugin_refs.knowledge_base` is missing, route the
consultant through `consult-setup` rather than improvising a binding.

## Pipeline Rungs

Pick the rung that matches what the base already holds:

- **New topic** (the base has no coverage yet): run the full inverted
  pipeline — `knowledge-plan` → `knowledge-curate` → `knowledge-fetch` →
  `knowledge-ingest` → `knowledge-compose` → `knowledge-verify` →
  `knowledge-finalize`.
- **Re-run on a populated base** (the topic is already covered; the angle or
  framing is new): `knowledge-plan` → `knowledge-compose --source wiki` →
  `knowledge-verify` → `knowledge-finalize` — skips the web crawl and
  composes from what the base already holds.
- **Quick gap-check** (just need what the base already knows):
  `cogni-knowledge:knowledge-query --knowledge-slug <slug> --question "..."`
  — the shallow read rung, no web crawl, no new project. When the answer
  shows a gap, escalate to one of the two rungs above rather than filling
  the gap from model memory or ad-hoc search.

### Gap-Check Recording

Record every gap-check by appending one entry to
`.metadata/decision-log.json`'s `decisions[]` array tagged
`"kind": "gap-check"`, carrying the **verbatim** question exactly as passed
(`question`), the theme label or `null` (`theme_label`), the returned
coverage verdict (`verdict`: `covered` / `partial` / `uncovered`), the
top-ranked page slug or `null` (`top_hit`), its overlap score or `null`
(`top_score`), plus the standard `id`, `action_field`, `deliverable`, and
`timestamp` fields (entry shape: `references/data-model.md`). The verbatim
query is the load-bearing field — a reconstructed query returns a different
ranking score, so re-running the routing decision bit-for-bit requires the
exact string, never a paraphrase. The `kind` discriminator keeps gap-check
records distinguishable from the locked-spec decision entries sharing the
same array.

## Depth Framing

Frame the run's depth when dispatching `knowledge-plan`:

- **Focused single-topic dive** → `--target-words 3000` with 3–4
  sub-questions, `--prose-density standard`
- **Broad multi-angle** → `--target-words 4000` with 5–7 sub-questions
- **Exhaustive** (e.g. a market or transformation landscape) →
  `--target-words 6000+` (or split into two plans),
  `--prose-density executive`

## Storage Contract

After `knowledge-finalize`, copy the finalized synthesis
`wiki/syntheses/<slug>.md` into the engagement's action-field directory so
the producing deliverable finds it at a stable path:

```
action-fields/<field-slug>/research/<topic-slug>.md
```

One file per research topic, named by a descriptive kebab-case slug.
Research requested during iteration re-entry lands in the same `research/`
directory alongside the existing syntheses — a new run, not an overwrite.
Deliverable artifacts reference these via `sources[]` entries whose `kb_ref`
points back at the knowledge-base page, preserving the lineage triple for
claim-correction cascades. Scoping-stage research (before action fields
exist) lands in `scope/research/<topic-slug>.md` and moves nothing when the
fields are derived — later deliverables cite it where it is.

## The Only Exception

A quick fact-check during conversation (confirming a date, a name, a number)
is fine as a single WebSearch. Anything requiring multiple queries, or
producing content that feeds an engagement artifact, must go through
cogni-knowledge.
