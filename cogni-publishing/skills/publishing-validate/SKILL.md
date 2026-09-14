---
name: publishing-validate
description: This skill should be used when the user wants to check or normalize a brief before anything renders it — "validate this publishing brief", "normalize this design brief", "check the artifact references", "is this brief ready to publish", "validate the composition and target plan", "check the render plan", "why was this brief rejected", or "which configuration value wins". It normalizes a narrative slides design brief or a framework-shaped direct brief (Pyramid, SCQA, MECE) into a provenance-preserving normalized brief, validates a normalized-brief@1 → semantic-composition@1 → target-resolved-plan@1 chain, or a renderer's target-resolved-plan@2, for version compatibility and dangling references, and resolves publishing configuration precedence. Deterministic and standalone — no model call, no renderer, no network, and no cogni-workspace installation required. It does not write, compose or render briefs; pattern-bound semantic-composition@2 work belongs to design-compose.
---

# Publishing Validate

Run the deterministic publishing validator on a brief or an artifact chain, and report its verdict. The validator is the authority: never repair, reword or reorder an input to make it pass, because frozen copy and source lineage are exactly what it protects.

## Pick the operation

| The user has… | Operation |
|---|---|
| a narrative design brief (`type: design-brief`, `version: "1.1"`, `target: slides`) | `normalize --kind narrative` |
| a structured JSON brief with `artifact_type: direct-brief` — consult material, Pyramid/SCQA/MECE sections | `normalize --kind direct` |
| a JSON object holding `normalized_brief`, `semantic_composition` and `target_resolved_plan` | `validate` |
| a question about which target, language or renderer applies | `resolve-config` |
| a pattern-bound `semantic-composition@2`, a repair pair, a pattern-library question, or a request to choose visual patterns for a brief | the `design-compose` skill (`compose`, `check-composition`, `check-repair`, `check-patterns`) |
| a renderer's `target-resolved-plan@2` together with its brief and composition | `check-plan` |
| a request to render a composition, or a question about a rendered page | the `design-render` skill |

`validate` grades a `target-resolved-plan@1` chain and rejects one that pairs `target-resolved-plan@1` with a `semantic-composition@2` as `invalid-version`. A chain whose plan is `target-resolved-plan@2` is routed to the same checks `check-plan` runs, against the bundled pattern library.

Only the slides target of a narrative brief is supported. A document, infographic or web design brief is rejected as `unsupported-target`; say so rather than converting it.

## Run it

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" normalize --kind narrative --input <design-brief.md>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" normalize --kind direct --input <direct-brief.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" validate --input <artifact-chain.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" check-plan --brief <normalized.json> --composition <composition.json> --plan <target-plan.json>
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/validate-publishing.py" resolve-config \
  --project-config <publishing.json> --workspace-preferences <preferences.json> --set target=slides
```

Pass `--workspace-preferences` only for a file the user named. Never go looking for a cogni-workspace installation or its settings; the validator is deliberately blind to them, and a missing preference file simply falls back to the bundled defaults.

## Read the result

The script prints one JSON envelope, `{"success", "data", "error"}`, and its exit status is the verdict:

- **Exit 0** — valid. For `normalize`, `data` is the normalized brief; summarise its record count, sources and any `evidence_status` labels, and save it only if the user asked. For `validate`, `data` lists the three artifacts — with their counts for a `target-resolved-plan@1` chain, and with the `check-plan` summary (`valid`, `artifact_id`, `target`, `content_fingerprint`, `units`, `slots`) for a `target-resolved-plan@2` chain. For `check-plan`, `data` names the plan, its target, the content fingerprint and its unit and slot counts. For `resolve-config`, report `configuration` together with `origin`, which names the layer each value came from.
- **Exit 1** — the input breaks a publishing contract. `data.code` names the failure, `data.check` the rule, and `data.reference` the offending id or version. Quote those three, explain the fix in the author's terms (for example "section `people` cites `destatis-2031`, which the sources list does not declare"), and stop — no downstream artifact exists for a rejected input.
- **Exit 2** — a usage or runtime problem (a missing file, a mistyped flag). Fix the invocation and run it again.

`${CLAUDE_PLUGIN_ROOT}/references/artifact-contracts.md` defines every artifact, reference field, compatibility rule and finding code — read it when a finding needs explaining or when the user asks how the chain fits together. `${CLAUDE_PLUGIN_ROOT}/references/configuration-and-renderer-boundary.md` covers configuration precedence and how a renderer is pinned; read it for any configuration or renderer question. `${CLAUDE_PLUGIN_ROOT}/references/design-render.md` §target-resolved-plan@2 holds the plan@2 layout rules — slot reading order, typography roles and measured faces; read it when a `check-plan` finding such as `reordered-unit` or `typography-relaxed` needs explaining.

## Boundaries

- Normalization preserves copy, notes, evidence labels, citations, sources and order exactly; it adds ids and provenance and nothing else.
- A direct brief keeps its own framework structure; never add a story arc, a BLUF opening, slide numbering or narrative elements to it.
- Composition and target plans reference normalized copy by id; a unit that carries its own copy is a finding, not a shortcut.
- Validation never installs or runs a renderer and never touches the network.
