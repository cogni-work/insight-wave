---
name: design-compose
description: This skill should be used when the user wants to bind a validated publishing brief to reusable visual patterns before any renderer lays it out — "compose this brief", "design-compose", "pick visual patterns for this brief", "which pattern fits this slide", "build the semantic composition", "why was this composition rejected", "repair this composition", or "propose a new visual pattern". It binds every frozen record once, in order, to the library's accepted proof patterns as a copy-free, geometry-free semantic-composition@2, and applies whenever a normalized brief needs visual structure before HTML or PPTX rendering, even when the user does not name the skill. It fills an unpatterned metric unit's pattern from the brief's own key figures and only from accepted patterns, but never rewrites, truncates, adds, reorders or rebinds content, never overwrites a choice the draft carries, and never renders. Standalone — no model API, no renderer, no network, and no cogni-workspace installation required.
---

# Design Compose

Bind a normalized brief to the pattern library and hand on a target-neutral `semantic-composition@2`. The validator is the authority: never alter, shorten, merge or reorder content to make a composition pass — frozen copy, unit order and source lineage are exactly what it protects. When no accepted pattern fits a unit, report that to the author and stop.

## Inputs

- **A normalized brief** — the `data` of a successful `publishing-validate` `normalize` run, saved as its own JSON file. Pass the artifact itself, not the envelope around it.
- **A design-system pin** — `{name, version}` and nothing else. The name is the `theme_slug` from the `manage-themes` selection handoff. The version is the cogni-publishing `version` in `.claude-plugin/plugin.json` for a bundled theme, since bundled themes are versioned with the plugin, or the revision the user supplies for a user theme — ask when there is none. Never use the theme manifest's `schema_version`. The pin is recorded as data; the composition resolves no token.
- **The requested targets** — `html`, `pptx`, or both. Every unit's pattern must support every requested target.

## Workflow

1. Run `check-patterns` to confirm the library is valid and to see which patterns are accepted.
2. Read `${CLAUDE_PLUGIN_ROOT}/references/design-composition.md` for each pattern's eligibility, slots, limits and variants, and for the binding rules.
3. Group consecutive frozen records into units, up to the chosen pattern's `constraints.max_records`, and choose one accepted pattern and variant per unit — or, on a unit that declares metric intent, leave both out and let `compose` route it (step 5) — by slide `type` or section role, record kind and whether the records carry data. Parallel direct sections can share one comparison unit. A narrative `visual_intent` is a hint the choice may decline, never a requirement. A brief that carries sources needs one `sources` unit: the narrative source-register slide takes it, and a direct brief ends on a `sources` unit with no bindings.
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
         "id": "u-<first record>", "role": "<kebab-case role>", "pattern": "<pattern id>", "variant": "<variant id>",
         "bindings": [{"slot": "<slot>", "record_ref": "<record id>", "field": "<field>"}],
         "data_bindings": [{"slot": "series", "data_ref": "<data id>"}],
         "entities": [{"id": "e1", "record_ref": "<record id>", "field": "slide_points", "item": 0}],
         "relationships": [{"from": "e1", "to": "e2", "kind": "<relationship kind>"}]
       }
     ]
   }
   ```

   Bind every content field of every record once: slide `headline`, `slide_points`, `talk_track`, `evidence_status`; section `title`, `body`, `notes`. Include `data_bindings` only on a chart and `entities`/`relationships` only on a conceptual system. A `role` names what the unit does, never what it says: a short kebab-case token such as `governing-thought`. Leave the binding digests, the content fingerprint, `source_refs`, `register_refs` and `document_bindings` out — `compose` fills them.
5. Run `compose`. Besides the mechanical fields, it makes two choices where the draft is silent: a unit that declares metric intent — a record typed `metric`, or one whose `visual_intent` prefers a metric expression — and whose bound text carries the brief's authored key figures is given `key-figure-strip` on two or more matches, or `hero-metric` on exactly one match in a unit of at most four bound texts; and a `comparison` or `conceptual-system` unit of at most four items is given `type_floor: type.lead`. A pattern, variant or `type_floor` the draft already carries is judged, never overwritten, so leave both `pattern` and `variant` out to accept the routing and write either one to decline it. See `references/design-composition.md` for both rules. On exit 0, the envelope's `data` is the validated `semantic-composition@2` that a renderer's own target-resolved plan consumes (see Boundaries); save it only where the user asked.

## Read the result

The validator prints one JSON envelope, `{"success", "data", "error"}`: exit 0 valid, 1 a contract finding (`data.code`, `data.check`, `data.reference`), 2 a usage or runtime problem. Quote the code, check and reference, then act by class:

- **`impossible-fit`, `ineligible-pattern`, `unsupported-capability`, `typography-relaxed`, `unknown-pattern`** — choose another eligible accepted variant or pattern for that one unit. For `typography-relaxed`, remove `type_floor` or raise it; for `unknown-pattern`, name a pattern and variant the library defines. Where the fix happens depends on where the finding came from:
  - **`compose` rejected a draft** — change only that unit's `pattern`, `variant` and binding slot names in the draft and run `compose` again. The draft carries no copy, so the change is presentation-only; `check-repair` does not apply, because a rejected draft was never composed.
  - **A saved composition fails `check-composition`**, or a valid one needs another variant — keep the original, save the changed version beside it, and prove it with `check-repair --brief <normalized.json> --before <original.json> --after <new.json>`, where both files are `compose` output.

  Never shorten, split, merge, reorder or drop content, and never lower `type_floor`. If no accepted pattern fits, report the finding to the author and stop.
- **`unsourced-chart-data`, `absent-dataset`, `mismatched-unit`, `invented-value`** — the fix belongs upstream in the brief: supply the dataset, its unit or its source there. Never type a number, unit or label into the composition.
- **`unbound-content`, `duplicate-binding`, `reordered-unit`, `reference-omitted`, `reference-reassigned`, `unexpected-field`, `copy-changed`, `source-identity-changed`, `fingerprint-mismatch`** — fix the draft's bindings, never the copy; remove an `unexpected-field`, and keep `role` a kebab-case token. On a saved composition, a `copy-changed` or `fingerprint-mismatch` means the brief changed: recompose from the new brief. A draft passed to `check-repair` always fails as `fingerprint-mismatch`, because only `compose` output carries the fingerprint.
- **`invalid-repair`** — the changed composition altered more than pattern, variant and slot names. Restore everything else from the original, or compose it as a new composition and validate it with `check-composition`.
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

Pass `--patterns` only to `check-patterns`, for a library copy under review. Never pass it to `compose`, `check-composition` or `check-repair`: production compositions validate against the bundled library.

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
