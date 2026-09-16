# Design composition

The normative rules for binding a frozen brief to reusable visual patterns. `pattern-library-v1.json` holds the pattern data; this page explains it and owns the binding rules; `scripts/validate-publishing.py` enforces both. Finding codes are defined once, in [`artifact-contracts.md`](artifact-contracts.md).

## Position in the chain

```text
normalized-brief@1 ─┐
pattern-library@1 ──┼─compose─> semantic-composition@2 ─> (target-resolved plan, per renderer)
design-system pin ──┘
```

A `semantic-composition@2` decides, for every frozen unit of a brief, which reusable pattern carries it and which slot each piece of content fills. It says nothing about a target's geometry: coordinates, grids, sizes and pages belong to the target-resolved plan each renderer builds from it. It carries no copy: every binding names a record and field by id and pins the value it saw with a digest, so a renderer always reads copy from the one normalized source and a changed sentence is caught rather than carried.

The design-system revision is pinned as data, `design_system {name, version}`, and carries nothing else. The name is the `theme_slug` that `manage-themes` hands off. The version is the cogni-publishing `version` in `.claude-plugin/plugin.json` for a bundled theme, because bundled themes are versioned with the plugin, and the revision the user supplies for a user theme — ask when there is none. It is never the theme manifest's `schema_version`. The composition resolves no token.

## Pattern library

Patterns are data and families are code. Each pattern names one of four families, and the validator owns what a family means:

| Family | Meaning the validator enforces |
|---|---|
| `text` | content in slots, no data, no diagram structure |
| `chart` | at least one plotted point, each a supplied data item with a numeric value, a unit and a source |
| `system` | named entities over bound content, related by kinds the variant allows, with no measurements |
| `register` | every source once, in original order |

Adding a pattern is a library entry. Adding a family is a reviewed change to the validator.

Every pattern carries the same contract fields, and `check-patterns` rejects a pattern missing any of them as `invalid-pattern`:

| Field | Holds |
|---|---|
| `status` | `accepted` or `proposed` — only accepted patterns reach production |
| `family` | one of the four families above |
| `purpose` | why the pattern exists: the relationship the audience must perceive |
| `eligibility` | `when` it applies in prose, the record kinds and slide types it fits, and whether data is `required` or `forbidden` |
| `slots` | what each slot accepts (`headline`, `body`, `points`, `notes`, `evidence`, `data`), whether it is required, and its item and character limits |
| `constraints` | the minimum typography role and how many records one unit may bind |
| `evidence_needs` | citations always carried, evidence status carried when present, and for charts a sourced dataset |
| `accessibility` | the semantic role, the reading order over every slot, and the text alternative |
| `target_capabilities` | per target, the capabilities the pattern needs from it |
| `variants` | the declared presentation alternatives, each with its own limits, for systems its relationship kinds, and for a figure pattern an optional per-target `fallback` |
| `examples` | specimens proving the contract |

A variant's **`fallback`** declares that one target draws part of the variant's figure as a picture instead of native objects: `{"target", "capability", "reason"}`, nothing else. Only a figure pattern (accessibility role `figure`) may carry one; `target` must be a key of the library's `targets`, `capability` one that target offers — for pptx, `picture-fallback` — and `reason` a non-empty statement of what is flattened and what that costs the reader. `check-patterns` rejects any other shape as `invalid-pattern` (check `variants`, reference `<pattern>/<variant>`). The declaration is per variant, never per pattern: the pattern's `target_capabilities` stay what every one of its variants needs, so a sibling variant declares no picture. The field is additive inside pattern-library@1 (see [`artifact-contracts.md`](artifact-contracts.md)); a composition never names it, and the renderer reads it from the library and records it unchanged — see [`design-render.md`](design-render.md) §Fallbacks.

A **specimen** is a minimal normalized brief plus one unit, composed and validated exactly as production content is, minus the status gate and the whole-document register requirement — a single unit cannot also carry the register. An accepted pattern needs at least one, and every one must pass; a failing specimen makes the whole library invalid. Every pattern has a slot for notes and a slot for evidence status, and a notes slot carries no limit: notes are never truncated.

## Proof patterns

### `answer-emphasis`

- **Why:** lead with the governing answer so the audience holds one idea before any support.
- **When:** a decision, recommendation, headline figure, quote or call to action — slide types `bluf`, `cover`, `quote`, `metric`, or any direct section. Data is forbidden.
- **Slots:** `answer` (the headline, required, one item of at most 140 characters), `support` (points or body, at most 240 characters per item), `evidence`, `notes`.
- **Variants:** `statement` holds at most three supporting lines; `statement-with-support` holds up to five.
- **Evidence:** every citation of the bound record; evidence status when present.
- **Accessibility:** a statement, read answer → support → evidence → notes, with the copy as its own text alternative.
- **Targets:** html `text-flow`, `aside-notes`; pptx `text-frame`, `speaker-notes`.

### `comparison`

- **Why:** set options, states or positions side by side so the difference is perceived, not read as a list.
- **When:** before and after, us and them, or parallel options on one axis — slide types `two-column`, `table`, `metric`, or one to four direct sections. Data is forbidden.
- **Slots:** `claim` (the headline, optional), `items` (points, headlines or bodies, required, two to eight items of at most 240 characters), `evidence`, `notes`.
- **Variants:** `parallel` compares up to six items; `tabular` reads up to eight as rows.
- **Evidence:** every citation; evidence status when present.
- **Accessibility:** a table, read claim → items → evidence → notes.
- **Targets:** html `text-flow`, `aside-notes`; pptx `text-frame`, `editable-shapes`, `speaker-notes`.

### `hero-metric`

- **Why:** give one figure the whole unit, so the audience leaves with a number rather than a bullet.
- **When:** a unit turns on a single headline number — a share, a count, a sum or a span — with at most a few lines of setting. Slide types `metric`, `bluf`, `cover`, or one direct section. Data is forbidden.
- **Slots:** `claim` (the headline or body, optional), `figure` (a point, headline or body, required, exactly one item of at most 120 characters), `context` (points or body, up to three items of at most 240 characters), `evidence`, `notes`.
- **Variants:** `figure-first` sets the figure alone under its claim, with at most one line of setting; `figure-with-context` allows up to three.
- **Evidence:** every citation; evidence status when present.
- **Accessibility:** a statement, read claim → figure → context → evidence → notes.
- **Targets:** html `text-flow`, `aside-notes`; pptx `text-frame`, `speaker-notes`.
- **Type:** the unit sits at `type.lead` or above, and the `figure` slot starts at the display role — the same default `answer` takes.

### `key-figure-strip`

- **Why:** set two to four figures in one row so they read as one measured picture, each keeping its own weight.
- **When:** several headline numbers of equal standing belong together and none should dominate — slide types `metric`, `two-column`, `table`, or up to four direct sections. Data is forbidden.
- **Slots:** `claim` (the headline, optional), `items` (points, headlines or bodies, required, two to four items of at most 160 characters), `evidence`, `notes`.
- **Variants:** `four-up` sets three or four figures across one row; `two-up` sets exactly two, each taking half the row.
- **Evidence:** every citation; evidence status when present.
- **Accessibility:** a list, read claim → items → evidence → notes.
- **Targets:** html `text-flow`, `aside-notes`; pptx `text-frame`, `editable-shapes`, `speaker-notes`.

### `sourced-chart`

- **Why:** show supplied quantities so their magnitude and proportion are seen, with every plotted value traceable.
- **When:** the unit carries a supplied dataset of comparable values in one unit of measure — slide types `metric`, `table`, `two-column`, or direct sections with data. Data is required.
- **Slots:** `claim` (the headline, required), `context` (points or body, at most three items), `series` (data items, required, one to twelve points), `evidence`, `notes`.
- **Variants:** `bar` plots two to twelve values; `single-value` shows exactly one.
- **Evidence:** a supplied dataset, and a source on every point.
- **Accessibility:** a figure, read claim → series → context → evidence → notes, with a data table as its text alternative.
- **Targets:** html `data-chart`, `hyperlink`, `aside-notes`; pptx `native-chart`, `hyperlink`, `speaker-notes`.

### `conceptual-system`

- **Why:** show how named parts relate as one system; it asserts relationships, never measurements.
- **When:** parts that hold together, depend on each other, converge or follow one another — slide types `roles`, `timeline`, `two-column`, or up to three direct sections. Data is forbidden.
- **Slots:** `claim` (the headline, required), `entities` (points, headlines or bodies, required, two to eight items of at most 90 characters), `evidence`, `notes`.
- **Variants:** `cluster` draws `part-of`, `depends-on`, `enables` and `contrasts-with`; `sequence` holds up to six entities and draws `precedes`, `converges-with` and `causes`; `feedback-loop` holds three to six entities that feed one another in a closed loop, draws `causes`, `enables` and `precedes`, and declares a pptx `fallback` with the capability `picture-fallback` for the loop's return track.
- **Evidence:** every citation; evidence status when present; no dataset and no number.
- **Accessibility:** a figure, read claim → entities → evidence → notes, with an entity list as its text alternative.
- **Targets:** html `svg-figure`, `aside-notes`; pptx `editable-shapes`, `speaker-notes`, plus `picture-fallback` for the `feedback-loop` variant alone.

### `sources`

- **Why:** close on the complete source register so every citation resolves to a record the audience can check.
- **When:** the narrative `sources` slide, or a register with no record of its own for a direct brief. Data is forbidden.
- **Slots:** `heading` (the headline, optional), `evidence`, `notes`.
- **Variants:** `register` lists every source once, in its original order.
- **Evidence:** the register itself; its `register_refs` equal the brief's source ids in order.
- **Accessibility:** a register, read heading → evidence → notes.
- **Targets:** html `text-flow`, `hyperlink`, `aside-notes`; pptx `text-frame`, `hyperlink`, `speaker-notes`.

## Choosing a pattern

A narrative brief's `visual_intent.message_pattern` suggests a starting point. It is a hint the choice may decline, and a form that communicates the same relationship more clearly wins. Only one part of `visual_intent` is read mechanically — `preferred_expression`, which `compose` uses as one of the two metric triggers below; `message_pattern` stays advisory:

| `message_pattern` | Suggested pattern |
|---|---|
| `decision` | answer-emphasis |
| a unit whose figures `compose` routes | hero-metric or key-figure-strip — see Metric routing |
| `comparison`, `shift`, `positioning` | comparison |
| `distribution`, `trajectory` | sourced-chart when a dataset is supplied, otherwise comparison |
| `system`, `composition`, `hierarchy`, `sequence`, `convergence`, `causality` | conceptual-system |

The source-register slide takes `sources`. A direct brief has no visual intent: choose by each section's role and whether it carries data.

## Composition shape

Top level: `artifact_type`, `artifact_version` (`"2"`), `artifact_id`, `normalized_brief_ref` (with `content_fingerprint`), `pattern_library_ref`, `design_system`, `targets`, `document_bindings`, `units`. Nothing else.

A unit carries `id`, optional `role`, `pattern`, `variant`, `bindings`, `source_refs`, and by family `data_bindings` (chart), `entities` and `relationships` (system) or `register_refs` (register), plus an optional `type_floor`. Nothing else — a copied headline, a coordinate or a layout choice is a finding. A `role` names what the unit does, never what it says: a short kebab-case token such as `governing-thought`, never copy.

Bindable content per record kind:

| Record | Field | Kind |
|---|---|---|
| slide | `headline` | headline |
| slide | `slide_points` | points |
| slide | `talk_track` | notes |
| slide | `evidence_status` | evidence |
| section | `title` | headline |
| section | `body` | body |
| section | `notes` | notes |
| data item | — | data (through `data_bindings`) |

`type`, `element` and `visual_intent` are presentation hints and are not bindable.

## Binding rules

- Every record is bound by exactly one unit, and every content field of it exactly once.
- Record order across all bindings, data order across all chart points, and entity order within a unit never decrease: units keep the authored order.
- Each binding carries `digest`, `sha256:` plus the hex SHA-256 of the field value's canonical JSON — `json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))`, UTF-8 encoded.
- `normalized_brief_ref.content_fingerprint` is the same digest taken over the object of the brief's `document`, `structure`, `records`, `data`, `sources` and `freeze`.
- A unit's `source_refs` equal the first-seen citations of its bound records, followed by those of its bound data items — nothing dropped, added or reordered.
- A brief that carries sources needs exactly one register unit, and the register lists every source in its original order.
- Every trailer note is bound once in `document_bindings`.

`compose` fills the mechanical fields a draft leaves out — digests, the fingerprint, citations, the register and the trailer-note bindings — then applies the two routing rules below, then validates. It never splits, merges, truncates or reorders content, and never rebinds: routing chooses a pattern for a unit the draft left unpatterned, it does not move content between slots. A value the draft already carries — a pattern, a variant or a `type_floor` alike — is judged, never overwritten.

### Metric routing

A unit declares **metric intent** when a record it binds is typed `metric`, or when that record's `visual_intent` carries `preferred_expression: metric`. For such a unit, and only when the draft left both `pattern` and `variant` out, `compose` reads the brief's authored `metadata.key_figures`:

- A bound text **matches** when one of those key figures, trimmed, is a **substring** of it. Nothing stronger can match: `normalize` has already resolved the authored `(src: [N])` suffix off each key figure, while a slide point keeps its bare `[N]` marker. Only slots other than `notes` and `evidence` are read — those carry commentary and status, never figures.
- **Two or more matches** route the unit to `key-figure-strip`.
- **Exactly one match**, in a unit of at most four bound texts, routes it to `hero-metric`.
- **Anything else is left unrouted**, and a unit that stays patternless is rejected as `unknown-pattern` rather than guessed at. Metric intent alone routes nothing, and a matching figure in a unit that declares no metric intent routes nothing either.

The variant is then the first the candidate declares whose limits admit exactly what the draft bound. A candidate whose slots or limits the draft does not satisfy is declined rather than written: a rejection `compose` caused itself would be indistinguishable to the author from one their own draft caused.

### The small-unit type floor

A `comparison` unit whose `items` slot binds at most four items, or a `conceptual-system` unit whose `entities` slot binds at most four, is given `type_floor: type.lead` — four items on a slide is a reading size, not a density problem. The floor is written only where the draft is silent, and never below the minimum the pattern and its variant already set, so the raise can never read as a relaxation.

## Coverage

On success, `check-composition` reports expected and bound counts for records, content fields, notes (talk tracks, section notes and trailer notes), citations (each record–source and data–source pair), evidence status, data, trailer notes and sources (the brief's source ids against the register's entries). Every bound count is measured from the recorded bindings, and `omissions` lists the rows whose counts differ — empty on every success. Validation fails fast on the first gap: an unbound record, field or data item is `unbound-content`; an unbound note, evidence label, trailer note or citation is `reference-omitted`, and so is a brief whose sources no unit registers (check `register`); one moved to where it does not belong is `reference-reassigned`.

## Quantitative provenance

Every chart point references a supplied data item with a numeric `value`, a `unit` and at least one source that resolves. A point carries only `slot` and `data_ref` — a number, unit or label of its own is `invented-value`. One chart plots one unit of measure (`mismatched-unit`). A point naming no supplied item is `absent-dataset`; one whose item names no source is `unsourced-chart-data`. A conceptual system diagram carries no measurement at all: its only numbers are the indices of the list items its entities name.

## Fit and typography

Slot and variant limits are hard. Content that exceeds them fails as `impossible-fit`, naming the unit, the pattern and variant, the limit and the actual count, and advising another eligible variant or pattern — the content itself is never shortened, split or dropped, and no unit is added. A unit may set `type_floor` to raise the pattern's minimum typography role; lowering it is `typography-relaxed`.

## Target neutrality

A composition carries semantic relationships only. The keys `x`, `y`, `left`, `top`, `right`, `bottom`, `width`, `height`, `size`, `position`, `coordinates`, `bounds`, `bbox`, `grid`, `column`, `columns`, `row`, `rows`, `span`, `layout`, `margin`, `padding`, `offset`, `z_index`, `font_size`, `px`, `pt`, `emu`, `slide_number` and `page`, anywhere in it, and any value that is a bare dimension such as `960px` or `12pt`, are `target-geometry`. Every requested target must be one every unit's pattern declares capabilities for (`unsupported-capability`).

## Repair

A repair changes presentation choices only. `check-repair` accepts a change of `pattern`, `variant` and binding slot names, and nothing else: the same units in the same order, the same records, fields, digests, data points, entities, relationships and citations, the same top-level references, and a content fingerprint that equals the brief's in both compositions. The repaired composition is then fully validated. A different fingerprint is `fingerprint-mismatch`; any other change is `invalid-repair`. A change of family that needs new entities or relationships is a new composition, validated with `check-composition`, not a repair.

## Extension workflow

A new pattern starts as `proposed`. Any author — a person, or a model on any provider — drafts a pattern entry with `status: proposed` in a copy of the library; no provider or API is required. The entry carries every contract field and at least one specimen. `check-patterns --patterns <copy>` then reports it under `proposed` with `ready_for_acceptance: true` once its specimens pass, or `false` with the blocking finding.

A proposed pattern never reaches production: `compose`, `check-composition` and `check-repair` reject any unit that uses it as `unaccepted-pattern`, however well it validates. Promotion to `accepted` is a reviewed change to `pattern-library-v1.json` that flips the status; from then on its specimens are held to the same bar as every other accepted pattern. A pattern that needs a family the validator does not know is a code change, reviewed as one.
