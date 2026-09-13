---
name: design-compose
description: This skill should be used when the user wants to bind a validated publishing brief to reusable visual patterns before any renderer lays it out — "compose this brief", "design-compose", "pick visual patterns for this brief", "which pattern fits this slide", "build the semantic composition", "why was this composition rejected", "repair this composition", or "propose a new visual pattern". It chooses accepted proof patterns (answer/emphasis, comparison, sourced quantitative chart, conceptual system diagram, source register) and binds every frozen record, field, note, citation, evidence label and dataset exactly once and in order into a semantic-composition@2 that carries no copy and no HTML or PPTX geometry, then runs the deterministic validator. It never rewrites, truncates, adds or reorders content, never routes a proposed pattern into production, and never renders. Standalone — no model API, no renderer, no network, and no cogni-workspace installation required.
---

# Design Compose

Bind a normalized brief to the pattern library and hand on a target-neutral `semantic-composition@2`. The validator is the authority: never alter, shorten, merge or reorder content to make a composition pass — frozen copy, unit order and source lineage are exactly what it protects. When no accepted pattern fits a unit, report that to the author and stop.

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file. Pass the artifact itself, not the envelope around it.
- **A design-system pin** — `{name, version}`: the `theme_slug` from the `manage-themes` selection handoff plus the version its design system declares. It is recorded as data; the composition resolves no token.
- **The requested targets** — `html`, `pptx`, or both. Every unit's pattern must support every requested target.

## Workflow

1. Run `check-patterns` to confirm the library is valid and to see which patterns are accepted.
2. Read `${CLAUDE_PLUGIN_ROOT}/references/design-composition.md` for each pattern's eligibility, slots, limits and variants, and for the binding rules.
3. Choose one accepted pattern and variant per frozen record — by slide `type` or section role, record kind and whether the record carries data. A narrative `visual_intent` is a hint the choice may decline, never a requirement. The source-register slide takes `sources`; a direct brief ends on a `sources` unit with no bindings.
4. Write a draft that binds content by reference only:

   ```json
   {
     "artifact_type": "semantic-composition",
     "artifact_version": "2",
     "artifact_id": "composition:<brief-id>",
     "normalized_brief_ref": {"artifact_id": "<normalized artifact_id>", "artifact_version": "1"},
     "pattern_library_ref": {"artifact_id": "cogni-publishing/pattern-library", "artifact_version": "1"},
     "design_system": {"name": "<theme slug>", "version": "<design-system version>"},
     "targets": ["html", "pptx"],
     "units": [
       {
         "id": "u-<record>", "role": "<role>", "pattern": "<pattern id>", "variant": "<variant id>",
         "bindings": [{"slot": "<slot>", "record_ref": "<record id>", "field": "<field>"}],
         "data_bindings": [{"slot": "series", "data_ref": "<data id>"}],
         "entities": [{"id": "e1", "record_ref": "<record id>", "field": "slide_points", "item": 0}],
         "relationships": [{"from": "e1", "to": "e2", "kind": "<relationship kind>"}]
       }
     ]
   }
   ```

   Bind every content field of every record once: slide `headline`, `slide_points`, `talk_track`, `evidence_status`; section `title`, `body`, `notes`. Include `data_bindings` only on a chart and `entities`/`relationships` only on a conceptual system. Leave the binding digests, the content fingerprint, `source_refs`, `register_refs` and `document_bindings` out — `compose` fills them.
5. Run `compose`. On exit 0, the envelope's `data` is the composition to hand to a renderer; save it only where the user asked.

## Read the result

The validator prints one JSON envelope, `{"success", "data", "error"}`: exit 0 valid, 1 a contract finding (`data.code`, `data.check`, `data.reference`), 2 a usage or runtime problem. Quote the code, check and reference, then act by class:

- **`impossible-fit`, `ineligible-pattern`, `unsupported-capability`** — choose another eligible accepted variant or pattern for that one unit, then prove the change with `check-repair --before <failed> --after <new>`. Never shorten, split, merge, reorder or drop content, and never lower `type_floor`. If no accepted pattern fits, report the finding to the author and stop.
- **`unsourced-chart-data`, `absent-dataset`, `mismatched-unit`, `invented-value`** — the fix belongs upstream in the brief: supply the dataset, its unit or its source there. Never type a number, unit or label into the composition.
- **`unbound-content`, `duplicate-binding`, `reordered-unit`, `reference-omitted`, `reference-reassigned`, `copy-changed`, `source-identity-changed`, `fingerprint-mismatch`** — fix the draft's bindings, never the copy. A `copy-changed` or `fingerprint-mismatch` on an unchanged draft means the brief changed: recompose from the new brief.
- **`target-geometry`** — remove the coordinate, size or layout value; geometry belongs to the target-resolved plan.

Every finding code is defined in `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md`.

## Proposed patterns

Never route a proposed pattern into a production composition: a pattern is usable only after its `status` is `accepted` and `check-patterns` passes its specimens.

To extend the library, draft the new pattern with `status: proposed` in a copy of `${CLAUDE_PLUGIN_ROOT}/references/pattern-library-v1.json` — any model or person may draft it, and no provider or API is required. Give it every contract field and at least one specimen: a minimal brief plus one unit that binds all of it. Run `check-patterns --patterns <copy>`; the pattern appears under `proposed` with `ready_for_acceptance: true` once its specimens pass. Acceptance is a reviewed change that flips `status` in the bundled library. Until then, `compose` and `check-composition` reject any unit using it as `unaccepted-pattern`. A pattern that needs a family the validator does not know is a code change, not a library entry.

## Commands

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-patterns [--patterns <library.json>]
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" compose --brief <normalized.json> --composition <draft.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-composition --brief <normalized.json> --composition <composition.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-repair --brief <normalized.json> --before <before.json> --after <after.json>
```

`--patterns` defaults to the bundled library; pass it only for a library copy under review.

## Resources

| File | Read it when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/design-composition.md` | choosing a pattern, binding content, explaining a finding, or extending the library |
| `${CLAUDE_PLUGIN_ROOT}/references/pattern-library-v1.json` | checking a pattern's exact slots, limits, variants or target capabilities |
| `${CLAUDE_PLUGIN_ROOT}/references/pattern-contract-v1.schema.json` | drafting a new pattern entry |
| `${CLAUDE_PLUGIN_ROOT}/references/semantic-composition-v2.schema.json` | checking the composition's exact shape |
| `${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md` | the version compatibility matrix and every finding code |

## Boundaries

- A composition references content and never carries it: no headline, sentence, number or label of its own.
- No coordinates, grids, sizes or pages — target geometry belongs to the renderer's target-resolved plan.
- `target-resolved-plan@1` consumes `semantic-composition@1` only; the plans that consume `@2` belong to the renderers.
- No rendering, no network, and no cogni-workspace installation needed.
