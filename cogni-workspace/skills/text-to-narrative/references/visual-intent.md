# Visual Intent

The one home of the `visual_intent` schema and its derivation. The design brief already hands the
renderer frozen copy and a content shape (`type`). Neither says **what relationship the audience
must perceive**. `visual_intent` says exactly that, and nothing else.

Visual intent is semantic, not art direction. It names the relationship and the idea that must
dominate; it never names how the renderer draws them.

## Schema

An optional indented mapping on a visual unit, in the brief's two-space grammar:

```
visual_intent:
  message_pattern: shift
  relationship: the constraint has moved from labour to signal
  focal_point: the move from labour to signal
  preferred_expression: comparison
  asset_signal: data-chart
  avoid: vendor-logo-wall
```

### Keys

| Key | Required | Value |
|-----|----------|-------|
| `message_pattern` | yes | one of the twelve below |
| `relationship` | yes | the semantic relationship, in plain language |
| `focal_point` | yes | the idea, entity or contrast that must dominate |
| `preferred_expression` | no | one of the fourteen below — a hint, never a mandate |
| `asset_signal` | no | one of the six below — a hint, never a mandate |
| `avoid` | no | a semantic anti-pattern, e.g. `vendor-logo-wall` |

`message_pattern`, `relationship` and `focal_point` are required **whenever the block is present**.
`preferred_expression` and `asset_signal` are hints the renderer may decline. `avoid` is optional.

### Closed enums

Each list is complete. A value outside it is a `visual-intent` finding.

**`message_pattern`** (12) — `comparison`, `shift`, `convergence`, `hierarchy`, `sequence`,
`positioning`, `composition`, `causality`, `distribution`, `system`, `trajectory`, `decision`.

**`preferred_expression`** (14) — `none`, `metric`, `comparison`, `timeline`, `positioning-map`,
`ecosystem-map`, `flow`, `spectrum`, `matrix`, `architecture`, `geography`, `chart`, `table`,
`quote`.

**`asset_signal`** (6) — `none`, `data-chart`, `diagram`, `geography`, `logos`, `photography`.

## Rules

- The block never specifies coordinates, left/right placement, grids, column counts, colors, fonts,
  icon styles, aspect ratios, object sizes or decorative treatments. That sentence is the one place
  in this reference where such vocabulary appears, and it appears to forbid it.
- The block encodes no new claim, number or evidence. Every number the deliverable carries is
  already in the copy, frozen, and cited there.
- Values stay short and concrete. Prefer a noun phrase naming the thing over a sentence describing
  it.
- The renderer may choose a different visual form whenever that form communicates the same
  relationship more clearly. `preferred_expression` and `asset_signal` lose to a better idea.
- **No value may contain a colon followed by a space.** The brief parser splits each mapping line on
  its first colon, so such a value is silently truncated.
- The three enum values are machine markers and stay in English on every brief, exactly as the
  `## Slide N:` kind word does. `relationship`, `focal_point` and `avoid` are written in the
  brief's own language.

## Applicability

| Target | Rule |
|--------|------|
| `slides` | **required** on every unit that carries narrative copy |
| `infographic` | optional, recommended when the relationship is not obvious from `type` |
| `web` | optional, recommended when the relationship is not obvious from `type` |
| `document` | **never** — the target carries no `type` and no unit-level visual decision |

### The trailing source-register exemption

The last slides unit is the source register: the renderer builds it from the narrative's
`**Sources**` block verbatim, so it asserts no relationship of its own and carries no
`visual_intent`.

That unit is recognisable two ways, **each sufficient on its own**:

- it carries `type: sources`, or
- it carries no `slide_points`.

The exemption is the disjunction of both. Keying it on either one alone would make the rule depend
on a brief shape that is not guaranteed, so the checker tests both.

## Worked examples

**A shift, in English.** The unit contrasts a former constraint with the current one.

```
visual_intent:
  message_pattern: shift
  relationship: the constraint has moved from labour to signal
  focal_point: the move from labour to signal
  preferred_expression: comparison
  asset_signal: data-chart
```

**A composition, in English, declining an anti-pattern.** The unit presents three positions that
matter as a set, not individually — so a wall of supplier marks would communicate the opposite.

```
visual_intent:
  message_pattern: composition
  relationship: three positions that hold together as one capability
  focal_point: the set of three rather than any one
  preferred_expression: matrix
  asset_signal: none
  avoid: vendor-logo-wall
```

**A convergence, in German.** Enum values stay English; the prose keys are German.

```
visual_intent:
  message_pattern: convergence
  relationship: drei äußere Kräfte treffen im selben Zeitfenster ein
  focal_point: das sich schließende Zeitfenster
  preferred_expression: timeline
  asset_signal: diagram
```

## How to derive one

Read the unit's copy and its `talk_track`, then answer three questions in order:

1. **What is the argument?** The answer is the `relationship`, in the brief's language.
2. **What must the eye land on first?** The answer is the `focal_point`. It is usually a contrast,
   a total, or a moment — rarely an entity.
3. **Which of the twelve patterns is that?** The answer is the `message_pattern`.

Add `preferred_expression` and `asset_signal` only when the answer is genuinely informative. `none`
is a real answer and says the relationship is carried by the copy alone.

## What the checker enforces

`scripts/check-design-brief.py`'s `visual-intent` check reports one finding for each of: a missing
required block on a copy-bearing slides unit; a non-mapping value; an unknown key; a missing or
empty required subkey; an out-of-enum `message_pattern`, `preferred_expression` or `asset_signal`;
and any `visual_intent` on the `document` target.

It cannot judge whether the named relationship is the one the evidence supports. That stays a
writer's judgment.
