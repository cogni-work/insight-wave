# Publishing artifact contracts

The normative contract `scripts/validate-publishing.py` enforces. Each stage of the publishing chain is its own versioned artifact, so one stage can evolve without dragging the others with it:

```text
design-brief@1.1 ─┐
                  ├─normalize─> normalized-brief@1 ─> semantic-composition@1 ─> target-resolved-plan@1 ─> optional renderer
direct-brief@1 ───┘
```

Schemas: `direct-brief-v1.schema.json`, `normalized-brief-v1.schema.json`, `semantic-composition-v1.schema.json`, `target-resolved-plan-v1.schema.json` in this directory. The validator is the enforcer; the schemas document the same shapes for readers and tools.

## Compatibility

| Artifact | Version | Accepts upstream |
|---|---|---|
| `direct-brief` | `1` | — (authored input) |
| `design-brief` | `1.1` | — (authored input; slides target only) |
| `normalized-brief` | `1` | `direct-brief@1` or `design-brief@1.1` |
| `semantic-composition` | `1` | `normalized-brief@1` |
| `target-resolved-plan` | `1` | `semantic-composition@1` and `normalized-brief@1` |

Versions are exact strings; compatibility is never inferred from a prefix. A chain is rejected with `invalid-version` when any artifact carries a version this table does not list (check `artifact-version`), or when a downstream artifact pins an upstream version that differs from the one supplied or that its own version does not accept (check `version-compatibility`). A new version lands as a new row here and in the validator's `SUPPORTED`/`COMPATIBLE` maps in the same change.

## Identity and references

Every artifact carries `artifact_type`, `artifact_version` and a non-empty `artifact_id`. Cross-artifact references are objects, `{"artifact_id": ..., "artifact_version": ...}`, so a reference names both *which* artifact and *which contract*:

| Artifact | Reference field | Must resolve to |
|---|---|---|
| `semantic-composition` | `normalized_brief_ref` | the supplied normalized brief |
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

An id that resolves nowhere is a `dangling-reference`; a non-string or empty entry is a `malformed-reference`. Composition units may carry only `id`, `role`, `copy_refs` and `data_refs`; plan units only `composition_unit_ref`, `copy_refs`, `data_refs`, `layout` and `emphasis`. Any other key — a `body`, a `title`, a copied sentence — is rejected as `unexpected-field`, because downstream artifacts reference copy and never carry it. That is what keeps an edited headline from existing in two places.

## Semantic composition versus target resolution

The composition decides what goes together and in which role (`governing-thought`, `supporting-group`, …) and says nothing about a target. The target-resolved plan adds only target and design-system decisions: `target`, a pinned `design_system` (`name`, `version`, optional `token_aliases`), and per-unit `layout`/`emphasis`. It keeps referencing the composition *and* the original normalized records, so a renderer always resolves copy from the one normalized source.

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

A rejected input emits no downstream artifact: the finding is the whole of `data`. Finding codes:

| Code | Meaning |
|---|---|
| `invalid-version` | unsupported artifact version, or an incompatible version pin between artifacts |
| `dangling-reference` | an id or artifact reference that resolves to nothing in the supplied input |
| `malformed-reference` | a reference that is not a well-formed id or `{artifact_id, artifact_version}` object |
| `unexpected-field` | a downstream unit carries a field outside its contract, typically copied text |
| `unsupported-target` | a narrative brief for a target other than slides |
| `invalid-brief` | a brief outside its grammar (missing frontmatter, gaps in unit numbering, unknown field, …) |
| `invalid-artifact` | a chain artifact missing, of the wrong type, or structurally incomplete |
| `invalid-config` | a configuration file that is not a JSON object |
| `unpinned-renderer` | a renderer without an exact `x.y.z` version |
