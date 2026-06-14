# Concise structure — Key Takeaways + takeaway headers for executive density

Authoring rubric for the `wiki-composer` agent's `PROSE_DENSITY=executive` path. It
explains *why* an executive synthesis is structured the way it is, so the agent
front-loads the conclusion and makes the document scannable in seconds — defeating the
"too long; didn't read" problem that mere shortening does not.

> **Authoring-only.** This file is not read at compose time by any skill or agent. It
> is reference material for developers and for the executive-density instructions in
> `agents/wiki-composer.md`. There is **no runtime dependency** on cogni-copywriting —
> the relevant rubric is summarised here so the agent never has to load another
> plugin's reference at runtime.

## Source rubric

The Pyramid + answer-first discipline below is adapted at the reference level from
cogni-copywriting's Pyramid Principle (McKinsey) framework:
`cogni-copywriting/skills/copywriter/references/02-messaging-frameworks/pyramid-framework.md`.
That file is the canonical treatment; this is the cogni-knowledge-scoped subset the
composer applies, with the citation discipline the inverted pipeline's Phase 6
verifier requires.

## The two structural moves

Executive density already applies BLUF + Minto Pyramid *within* each section. Two
document-level moves make the whole synthesis scannable:

### 1. The Key Takeaways block

Open the draft — before the first topical H2 — with a `## Key Takeaways` block:

- **3–5 BLUF bullets.** Each bullet is one bottom-line finding, the substance a busy
  stakeholder needs if they read nothing else. Together the bullets are the
  document's answer layer (Pyramid Layer 1).
- **One citation per bullet.** Every bullet carries exactly one inline citation
  marker (the same `<sup>[N](url)</sup>` / `<sup>[N]</sup>` shape used in the body,
  one source per claim). The takeaway must paraphrase a claim that already exists on
  a cited page — never assert a takeaway you cannot ground.
- **Recorded like any cited sentence.** Append one `citations` entry per bullet whose
  `draft_sentence` is the bullet copied verbatim (including its `[N]` marker), so the
  zero-network Phase 6 verifier scores it exactly as it scores body prose. The block
  needs no change to the verifier, the revisor, or the citation store — the citation
  contract is location-agnostic.
- **Counts toward the word ceiling.** The block (~150 words) is part of the draft
  body; reserve it an `index: "00"` outline slot and tally it against `TARGET_WORDS`.

### 2. Takeaway-style H2 headers

Every **topical** H2 heading states the section's *conclusion*, not its *topic* — the
section's BLUF rendered in title form.

| Topic-stating (avoid) | Takeaway-stating (prefer) |
|---|---|
| `## AI Act Risk Classification` | `## AI Act Mandates a Two-Stage Risk Classification` |
| `## Adoption Barriers` | `## Adoption Stalls on Integration Cost, Not Capability` |
| `## Market Size` | `## The Addressable Market Triples by 2030` |

Structural headings — `## Key Takeaways`, `## References` (and their localized
equivalents) — are exempt and keep their plain names.

## Boundaries

- **Single pass.** These moves shape one compose pass. They add no loop, no expansion
  trigger, and no second LLM call.
- **Executive only.** Under `standard` density the composer drafts conventionally —
  no Key Takeaways block, topic-stating headers are fine. The behaviour is gated
  strictly on `PROSE_DENSITY=executive`, so the standard path is byte-unchanged.
- **Composition time, before verification.** The structure is authored as the draft is
  written, ahead of Phase 6. This is deliberate: a downstream polish pass would stale
  the verifier's `draft_sentence` anchors, and a narrative arc would impose a
  persuasion structure on objective research and risk dropping citations.
