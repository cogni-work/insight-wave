# Publishing artifact contracts

The normative contract `scripts/validate-publishing.py` enforces. Each stage of the publishing chain is its own versioned artifact, so one stage can evolve without dragging the others with it:

```text
design-brief@1.1 ─┐
                  ├─normalize─> normalized-brief@1 ─> semantic-composition@1 ─> target-resolved-plan@1 ─> optional renderer
direct-brief@1 ───┘

normalized-brief@1 + pattern-library@1 ─compose─> semantic-composition@2 ─> (target-resolved plans that consume @2 land with the renderers)
```

Schemas: `direct-brief-v1.schema.json`, `normalized-brief-v1.schema.json`, `semantic-composition-v1.schema.json`, `semantic-composition-v2.schema.json`, `target-resolved-plan-v1.schema.json` and `pattern-contract-v1.schema.json` (for `pattern-library@1`) in this directory. The validator is the enforcer; the schemas document the same shapes for readers and tools.

## Compatibility

| Artifact | Version | Accepts upstream |
|---|---|---|
| `direct-brief` | `1` | — (authored input) |
| `design-brief` | `1.1` | — (authored input; slides target only) |
| `normalized-brief` | `1` | `direct-brief@1` or `design-brief@1.1` |
| `semantic-composition` | `1` | `normalized-brief@1` |
| `semantic-composition` | `2` | `normalized-brief@1` and `pattern-library@1` |
| `target-resolved-plan` | `1` | `semantic-composition@1` and `normalized-brief@1` |
| `pattern-library` | `1` | — (bundled reference data; a `proposed` pattern never reaches a production composition) |

Versions are exact strings; compatibility is never inferred from a prefix. A chain is rejected with `invalid-version` when any artifact carries a version this table does not list (check `artifact-version`), or when a downstream artifact pins an upstream version that differs from the one supplied or that its own version does not accept (check `version-compatibility`). A new version lands as a new row here and in the validator's `SUPPORTED`/`COMPATIBLE` maps in the same change.

`target-resolved-plan@1` consumes `semantic-composition@1` only: `validate` rejects a chain that pairs it with a `semantic-composition@2` as `invalid-version` (check `version-compatibility`, reference `semantic-composition@2`). The target-resolved plan version that consumes `@2` lands with the renderers that need it.

## Identity and references

Every artifact carries `artifact_type`, `artifact_version` and a non-empty `artifact_id`. Cross-artifact references are objects, `{"artifact_id": ..., "artifact_version": ...}`, so a reference names both *which* artifact and *which contract*:

| Artifact | Reference field | Must resolve to |
|---|---|---|
| `semantic-composition` | `normalized_brief_ref` | the supplied normalized brief; at `@2` it also carries `content_fingerprint` |
| `semantic-composition@2` | `pattern_library_ref` | the pattern library the composition was validated against |
| `target-resolved-plan` | `composition_ref` | the supplied composition |
| `target-resolved-plan` | `normalized_brief_ref` | the supplied normalized brief |

Inside the chain, ids carry the lineage:

| Holder | Field | Resolves against |
|---|---|---|
| composition unit | `copy_refs[]` | normalized `records[].id` |
| composition unit | `data_refs[]` | normalized `data[].id` |
| plan unit | `composition_unit_ref` | composition `units[].id` |
| plan unit | `copy_refs[]`, `data_refs[]` (optional) | normalized `records[].id`, `data[].id` |
| normalized data item | `record_ref` | normalized `records[].id` |
| `@2` unit binding | `bindings[].record_ref` + `field` | a normalized record and one of its bindable fields |
| `@2` unit | `data_bindings[].data_ref` | normalized `data[].id` |
| `@2` unit | `source_refs[]`, `register_refs[]` | normalized `sources[].id` |
| `@2` unit entity | `entities[].record_ref` + `field` (+ `item`) | content the unit places in its `entities` slot |
| `@2` document binding | `document_bindings[].index` | normalized `freeze.trailer_notes` |

An id that resolves nowhere is a `dangling-reference`; a non-string or empty entry is a `malformed-reference`. `semantic-composition@1` units may carry only `id`, `role`, `copy_refs` and `data_refs`; `semantic-composition@2` units only `id`, `role`, `pattern`, `variant`, `bindings`, `data_bindings`, `source_refs`, `register_refs`, `entities`, `relationships` and `type_floor`; plan units only `composition_unit_ref`, `copy_refs`, `data_refs`, `layout` and `emphasis`. Any other key — a `body`, a `title`, a copied sentence — is rejected as `unexpected-field`, because downstream artifacts reference copy and never carry it. That is what keeps an edited headline from existing in two places.

## Semantic composition versus target resolution

The composition decides what goes together and in which role (`governing-thought`, `supporting-group`, …) and says nothing about a target. The target-resolved plan adds only target and design-system decisions: `target`, a pinned `design_system` (`name`, `version`, optional `token_aliases`), and per-unit `layout`/`emphasis`. It keeps referencing the composition *and* the original normalized records, so a renderer always resolves copy from the one normalized source.

## Pattern-bound composition

`semantic-composition@2` binds every frozen record, content field, note, evidence label, citation, data item and trailer note — exactly once and in authored order — to an accepted pattern from `pattern-library@1`. Each binding pins the value it saw with a digest and the composition pins the whole brief with a content fingerprint, so changed copy is caught rather than carried. It carries no copy and no target geometry. [`design-composition.md`](design-composition.md) is the normative definition of the pattern contract, the binding and coverage rules, quantitative provenance, fit and typography limits, bounded repair and the extension workflow for proposed patterns.

## Narrative adapter: `design-brief@1.1`, slides target

The adapter reads the slides grammar of the narrative design brief (`cogni-workspace` text-to-narrative's design-brief template) and nothing wider. It is not a general Markdown parser:

- frontmatter `type: design-brief`, `version: "1.1"`, `target: slides` — any other target is `unsupported-target`, any other version `invalid-version`;
- a `# Rendering Contract` (or `# Rendering-Vertrag`) heading with its `- ` clauses;
- `## Slide N: {headline}` units numbered from 1 without gaps;
- inside a unit, only the column-0 fields `type`, `evidence_status`, `element`, `visual_intent`, `slide_points`, `talk_track` — a scalar, a `- ` list, an indented `key: value` block, or a prose block running to the next field;
- `type` from the slides content-shape enum and `evidence_status` from `direct | triangulated | proxy | interpretation | mixed`;
- trailing `note:` lines, then the `**Sources**` block of `[N] …` entries.

Anything outside that grammar is rejected as `invalid-brief`, never guessed at.

## Preservation and freeze

Normalization selects and labels; it never rewrites. For a narrative brief it preserves, byte for byte and in order: every unit heading and headline, every field in its authored order and its exact value (slide points line by line, the talk track as the full prose block including paragraph breaks), `evidence_status`, every `[N]` citation (as `source_refs`, first-seen order), every Sources entry (as `id`, `marker`, `file`, `url` and the verbatim `raw` line), the Rendering Contract clauses and the trailer notes. Each record also keeps `raw`, the exact source slice, so a consumer can prove fidelity without trusting the parser.

`freeze` records the guarantees a renderer must honour: `copy`, `notes` and `order` are always `true`; narrative briefs add the contract heading, its clauses and the trailer notes verbatim.

## Direct adapter: `direct-brief@1`

A direct brief owns its own structural contract. It declares `structure.framework` (for example `pyramid`, `scqa`, `mece`) and ordered `sections`, each with an `id`, `title` and `body`, optional `role`, `notes`, `data[]` (each item with its own `id`) and `source_refs[]` naming `sources[].id`. It never acquires `arc_id`, a BLUF opening, slide numbering, narrative elements or density rules; the structure it declares travels verbatim into `normalized-brief.structure`. Section order, section and data ids, copy, notes and source records survive unchanged.

A malformed or dangling reference in a direct brief — on a section or on a data item — rejects the whole brief; nothing is dropped or repaired.

## Provenance

`normalized-brief.provenance` names the input artifact's type, version, id and file name. Records keep `source_refs`; sources keep their original ids and locators and are never renumbered. Composition and plan add references, never replace them, so lineage runs unbroken from a rendered unit back to the authored line and its source.

## Result envelope and findings

Every command writes exactly one JSON object to stdout and nothing to stderr:

```json
{"success": true, "data": {"...": "the normalized brief, chain summary, or resolved configuration"}, "error": null}
```

| Exit | `success` | `data` |
|---|---|---|
| `0` | `true` | the result |
| `1` | `false` | one finding: `code`, `check`, and where known `artifact` and `reference` |
| `2` | `false` | `{"code": "usage-error"}` or `{"code": "runtime-error"}` |

A rejected input emits no downstream artifact: the finding is the whole of `data`. On success the composition commands answer with:

| Command | `data` on exit 0 |
|---|---|
| `check-patterns` | the library identity, its targets, the `accepted` pattern ids, and each `proposed` pattern with `ready_for_acceptance` and the finding blocking it |
| `compose` | the draft with its mechanical fields filled — the validated `semantic-composition@2` |
| `check-composition` | `valid`, the content fingerprint, pattern counts and a coverage report of expected and bound counts, with no omissions |
| `check-repair` | `valid`, the preserved content fingerprint, the repaired units with their before and after pattern/variant, and the unchanged units |

Finding codes:

| Code | Meaning |
|---|---|
| `invalid-version` | unsupported artifact version, or an incompatible version pin between artifacts |
| `dangling-reference` | an id or artifact reference that resolves to nothing in the supplied input |
| `malformed-reference` | a reference that is not a well-formed id or `{artifact_id, artifact_version}` object |
| `unexpected-field` | a downstream unit carries a field outside its contract, typically copied text — including a `semantic-composition@1` or `@2` unit `role` that is not a short kebab-case token, or a `design_system` key other than `name` and `version` |
| `unsupported-target` | a narrative brief for a target other than slides |
| `invalid-brief` | a brief outside its grammar (missing frontmatter, gaps in unit numbering, unknown field, …) |
| `invalid-artifact` | a chain artifact missing, of the wrong type, or structurally incomplete, including a normalized brief whose record `kind` or `source_refs` is malformed |
| `invalid-config` | a configuration file that is not a JSON object |
| `unpinned-renderer` | a renderer without an exact `x.y.z` version |
| `invalid-pattern` | a library pattern missing a contract field, holding a value its family does not admit, or whose accepted specimen fails |
| `unknown-pattern` | a unit naming a pattern or variant the library does not define |
| `unaccepted-pattern` | a production unit using a `proposed` pattern |
| `ineligible-pattern` | content bound to a pattern, slot or structure it does not fit — wrong record kind, slide type, data rule, slot or relationship kind |
| `unsupported-capability` | a requested target the library does not know, or a pattern that declares no capabilities for it |
| `impossible-fit` | content that exceeds a slot, variant or record limit; nothing is truncated, split or dropped to make it fit |
| `typography-relaxed` | a `type_floor` below the pattern's or variant's minimum typography role |
| `target-geometry` | a coordinate, size, grid or page key, or a bare dimension value, anywhere in a composition |
| `unbound-content` | a record, content field, data item or entity item the composition binds nowhere |
| `duplicate-binding` | content, a record, a data point, a citation or a register bound more than once |
| `reordered-unit` | bindings, data points or entities out of authored order |
| `copy-changed` | a bound value that no longer matches the digest it was bound with |
| `source-identity-changed` | a citation or register naming an unknown source, or sources out of their original order |
| `reference-omitted` | a note, evidence label, trailer note or citation the composition drops, or the source register of a brief that carries sources |
| `reference-reassigned` | a note, evidence label, citation or data point moved to a unit or slot that does not carry it |
| `invented-value` | a chart point or diagram element carrying its own number, unit or label |
| `mismatched-unit` | one chart plotting values in more than one unit of measure |
| `absent-dataset` | a chart without supplied data, or a point naming no supplied numeric data item |
| `unsourced-chart-data` | a plotted data item that names no source |
| `fingerprint-mismatch` | a composition bound to content other than the brief supplied |
| `invalid-repair` | a repair that changes anything beyond pattern, variant and slot names |
