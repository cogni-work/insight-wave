# cogni-publishing

> **Incubating** (v0.0.x) — skills may change or be removed at any time.

Turns narrative and direct briefs into versioned, provenance-preserving publishing artifacts with standalone validation and explicit renderer boundaries.

## Why this exists

A brief is the last point where copy, evidence and sources are still under the author's control. Everything after it — composition, layout, rendering — is where they quietly drift:

| Problem | What happens | Impact |
|---|---|---|
| One renderer-shaped interchange | Content, structure and layout decisions live in one blob tied to a single output format | Changing the renderer means rewriting the brief; editable PPTX and HTML pull in opposite directions |
| Copy duplicated downstream | Plans carry their own copies of headlines and notes | An edit lands in one copy and not the other; the deck no longer says what the author approved |
| Lost lineage | Source ids are renumbered or dropped between stages | A figure on a slide can no longer be traced to its source |
| Narrative rules forced on everything | Framework-shaped consult material is pushed through story-arc tooling | Pyramid and MECE deliverables come out re-narrated and softened |
| Hidden workspace coupling | Publishing only works where a sibling plugin is installed and initialised | A user with a brief and a brand cannot publish on their own |

## What it is

The contract boundary between authored briefs and optional renderers. It defines four versioned artifacts — a normalized brief, a semantic composition, a target-resolved plan, and the envelope every operation answers with — and a stdlib-only validator that enforces them. Inputs arrive either as the narrative slides design brief that cogni-workspace's `text-to-narrative` produces, or as a structured direct brief that carries its own framework (Pyramid, SCQA, MECE) and never acquires a story arc.

## What it does

- **`publishing-validate`** — normalizes a narrative slides brief or a direct brief into a `normalized-brief@1` that keeps every headline, field, note, evidence label, citation and source exactly as authored; validates a normalized-brief → semantic-composition → target-resolved-plan chain for version compatibility, dangling or malformed references and copy smuggled into downstream units; and resolves configuration precedence with the origin of every value → one JSON envelope, exit 0 / 1 / 2.

## What it means for you

- **Approve copy once.** Downstream artifacts reference normalized copy by id and are rejected if they carry their own, so what the author signed off is what reaches the renderer.
- **Trace every figure.** Citations and source records keep their original ids from brief to plan; a number on a slide still names the source it came from.
- **Publish consult work as it was written.** A direct brief keeps its Pyramid or MECE structure — no arc, no BLUF slide, no narrative element count imposed.
- **Swap renderers without touching the brief.** Target and design-system decisions live in their own artifact; a renderer is a pinned, optional runtime that consumes `target-resolved-plan@1`.
- **Validate anywhere.** Python standard library only: no Node, no model API, no rendering package, no network, and no cogni-workspace installation.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md). It is installable on its own and needs no other insight-wave plugin.

## Quick start

```text
Validate this publishing brief: path/to/design-brief.md
```

Or call the validator directly from the plugin directory:

```bash
python3 scripts/validate-publishing.py normalize --kind narrative --input tests/fixtures/narrative-slides-v1.md
python3 scripts/validate-publishing.py normalize --kind direct --input tests/fixtures/direct-consult-v1.json
python3 scripts/validate-publishing.py validate --input tests/fixtures/contract-chain-v1.json
python3 scripts/validate-publishing.py resolve-config --project-config publishing.json --set target=slides
```

## Try it

```bash
python3 scripts/validate-publishing.py validate --input tests/fixtures/dangling-reference.json
```

```json
{"success": false, "data": {"code": "dangling-reference", "check": "copy_refs", "artifact": "semantic_composition", "reference": "procurement"}, "error": "unit support-process.copy_refs names procurement, which nothing declares"}
```

Exit status 1: the composition references a record the normalized brief does not carry, so no downstream artifact is produced.

## Data model

```text
design-brief@1.1 ─┐
                  ├─normalize─> normalized-brief@1 ─> semantic-composition@1 ─> target-resolved-plan@1
direct-brief@1 ───┘
```

- **normalized-brief@1** — the only place copy and data live: ordered records with stable ids, source records with their original ids, freeze guarantees, provenance.
- **semantic-composition@1** — units that group records by role through `copy_refs`/`data_refs`; no target, no text.
- **target-resolved-plan@1** — target, pinned design system and per-unit layout; references the composition and the normalized brief.

[`references/artifact-contracts.md`](references/artifact-contracts.md) is the normative definition — identities, the compatibility matrix, reference fields, preservation rules, provenance and finding codes — with one JSON Schema per artifact beside it.

## How it works

The narrative adapter reads only the slides grammar of `design-brief@1.1` — frontmatter, the Rendering Contract, numbered `## Slide N:` units with their fixed field set, trailer notes and the Sources block — and rejects anything else instead of guessing. Each normalized record keeps its exact source slice as `raw`, so fidelity is checkable without trusting the parser. The direct adapter requires ids, titles and bodies, resolves every source reference, and carries the brief's declared structure through untouched.

Chain validation checks each artifact's type and version, every cross-artifact reference and pinned version against the compatibility matrix, every unit reference against the normalized brief, and that no downstream unit carries fields outside its contract. The first violation is reported with its code, the rule it broke and the offending reference.

Configuration resolves per key as supplied values, then publishing project configuration, then optional workspace preferences named by the caller, then bundled defaults; a missing preference file never aborts. See [`references/configuration-and-renderer-boundary.md`](references/configuration-and-renderer-boundary.md).

## Components

| Component | Type | Purpose |
|---|---|---|
| `publishing-validate` | Skill | Normalize briefs, validate artifact chains, resolve configuration |
| `scripts/validate-publishing.py` | Script | Deterministic, stdlib-only validator with the standard JSON envelope |
| `references/artifact-contracts.md` | Reference | Normative artifact, reference and compatibility contract |
| `references/configuration-and-renderer-boundary.md` | Reference | Configuration precedence and the renderer pin |
| `references/*-v1.schema.json` | Reference | One JSON Schema per artifact |
| `tests/test-publishing-contracts.sh` | Test | Contract suite, discovered by the repository test runner |

## Architecture

```text
cogni-publishing/
├── .claude-plugin/plugin.json
├── skills/publishing-validate/SKILL.md
├── scripts/validate-publishing.py
├── references/
│   ├── artifact-contracts.md
│   ├── configuration-and-renderer-boundary.md
│   ├── direct-brief-v1.schema.json
│   ├── normalized-brief-v1.schema.json
│   ├── semantic-composition-v1.schema.json
│   └── target-resolved-plan-v1.schema.json
└── tests/
    ├── test-publishing-contracts.sh
    └── fixtures/
```

## Dependencies

None at validation time: Python 3 standard library and a POSIX shell. Rendering is a separate, optional runtime pinned in configuration as `{"name", "version", "consumes": "target-resolved-plan@1"}` with an exact version; ordinary install and validation never download, import or run it.

| Plugin | Required | Purpose |
|---|---|---|
| cogni-workspace | No | Produces narrative design briefs via `text-to-narrative`; its preferences are read only when a caller names the file |

## Development

```bash
bash tests/test-publishing-contracts.sh
python3 ../scripts/run-plugin-tests.py --filter cogni-publishing
```

The suite prints one `PASS:`/`FAIL:` line per case, addressed by a stable `pubc-NN-…` id. Two guards carry recorded mutation checks, run from the repository root against the installed managed-service cogni-service harness. The recipe shape — `--root` the repository, `--file` the mutated file relative to it, a single-quoted `perl -0pi` expression, and `--case` equal to the label the suite prints — follows rule 5 of `skills/service-gatekeeper/references/review-plan-spec.md` in the cogni-service plugin:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return artifact_version in supported_versions/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-04-invalid-version
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return reference_id in available_ids/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-05-dangling-reference
```

Each disables one guard, expects its case red, restores the file and expects it green.

## Custom development

Need a renderer integration, a house design system, or a publishing pipeline tailored to your brand? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for consulting and communication teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
