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

The contract boundary between authored briefs and optional renderers, and the owner of the theme lifecycle every themed output draws on. It defines four versioned artifacts — a normalized brief, a semantic composition, a target-resolved plan, and the envelope every operation answers with — and a stdlib-only validator that enforces them. Inputs arrive either as the narrative slides design brief that cogni-workspace's `text-to-narrative` produces, or as a structured direct brief that carries its own framework (Pyramid, SCQA, MECE) and never acquires a story arc. Themes — bundled presets, user themes and Claude Design imports — are selected, authored, validated and compiled here, with one canonical token representation per theme. Between the brief and any renderer sits a small library of reusable proof patterns — answer/emphasis, comparison, sourced chart, conceptual system diagram, source register — to which every frozen unit is bound by reference, before any target decides geometry.

## What it does

- **`design-compose`** — chooses an accepted proof pattern and variant for each frozen unit of a normalized brief and binds every record, field, note, citation, evidence label and dataset exactly once and in authored order; compose fills digests, the content fingerprint and citations, and the validator rejects copy or geometry in the composition, unsourced or invented chart values, content that does not fit, and any use of a proposed pattern → a target-neutral `semantic-composition@2`, exit 0 / 1 / 2.
- **`design-render`** — lays a validated `semantic-composition@2` out as a `target-resolved-plan@2` and renders its HTML target as one self-contained page in the theme's tokens: sourced bar charts, labelled system figures, side-by-side comparisons, linked citations and a closing source register, with every original string inserted as text and checked against the brief before anything is written; fonts that are not bundled resolve to a documented fallback and every substitution is recorded → `target-plan.json`, `index.html` and `provenance.json`, exit 0 / 1 / 2. An optional, lockfile-pinned browser runtime measures the page offline.
- **`publishing-validate`** — normalizes a narrative slides brief or a direct brief into a `normalized-brief@1` that keeps every headline, field, note, evidence label, citation and source exactly as authored; validates a normalized-brief → semantic-composition → target-resolved-plan chain for version compatibility, dangling or malformed references and copy smuggled into downstream units; and resolves configuration precedence with the origin of every value → one JSON envelope, exit 0 / 1 / 2.
- **`manage-themes`** — selects, recommends, creates, audits, deepens, showcases and applies visual themes, and imports Claude Design bundles; returns the `theme_path` / `theme_name` / `theme_slug` handoff every themed consumer reads, from bundled presets, the optional user theme location or an explicit path with no workspace at all. Token files are the one authoritative representation: semantic aliases stay role-to-role references in `tokens.css`, a resolved projection serves consumers that cannot evaluate `var()`, and a cycle or dangling reference fails loudly.

## What it means for you

- **Approve copy once.** Downstream artifacts reference normalized copy by id and are rejected if they carry their own, so what the author signed off is what reaches the renderer.
- **Trace every figure.** Citations and source records keep their original ids from brief to plan; a number on a slide still names the source it came from.
- **Publish consult work as it was written.** A direct brief keeps its Pyramid or MECE structure — no arc, no BLUF slide, no narrative element count imposed.
- **Show comparisons, evidence and systems the same way every time.** A reusable pattern carries the content you approved; when it does not fit, you get a finding naming the unit and the limit — never a shortened sentence, a dropped source or an invented number.
- **Swap renderers without touching the brief.** Target and design-system decisions live in their own artifact; an external renderer is a pinned, optional runtime that consumes `target-resolved-plan@1`.
- **Hand over a branded page that proves itself.** The HTML render opens offline as a single file, links every citation to its source, and ships with a provenance record of the fonts, pins and fingerprint it was built from — a changed sentence or a moved chart fails the check instead of reaching the client.
- **Validate anywhere.** Python standard library only: no Node, no model API, no rendering package, no network, and no cogni-workspace installation.
- **Keep your brand's roles, not just its colours.** A foreground that points at an ink colour stays a reference through import, storage and CSS, so a palette change moves every role that depends on it. Your existing themes keep working untouched.

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
python3 scripts/validate-publishing.py check-composition --brief tests/fixtures/narrative-slides-v1.expected.json --composition tests/fixtures/composition-narrative-v2.json
python3 scripts/design-render.py render --target html --brief tests/fixtures/narrative-slides-v1.expected.json --composition tests/fixtures/composition-narrative-v2.json --theme themes/cogni-work --out /tmp/render
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

normalized-brief@1 + pattern-library@1 ─compose─> semantic-composition@2 ─render─> target-resolved-plan@2 ─> index.html
                                                                                     └──> render-provenance@1
```

- **normalized-brief@1** — the only place copy and data live: ordered records with stable ids, source records with their original ids, freeze guarantees, provenance.
- **semantic-composition@1** — units that group records by role through `copy_refs`/`data_refs`; no target, no text.
- **target-resolved-plan@1** — target, pinned design system and per-unit layout; references the composition and the normalized brief.
- **pattern-library@1** — the reusable proof patterns, each with purpose, eligibility, slots and limits, evidence needs, accessibility semantics, target capabilities, variants and validated specimens, and a status of `accepted` or `proposed`.
- **semantic-composition@2** — pattern-bound units: every record, field, note, citation, evidence label, data point and trailer note bound exactly once by id and digest, plus a content fingerprint of the brief; no copy, no geometry.
- **target-resolved-plan@2** — one target's layout of a `@2` composition: a canvas, a frame per unit, and per slot a box, a typography role, the face it was measured with and the composition's own content references; no copy.
- **render-provenance@1** — renderer, runtime pin and lockfile digest, design-system pin, theme token digest, content fingerprint, output digests and every font resolution of one render.

[`references/artifact-contracts.md`](references/artifact-contracts.md) is the normative definition — identities, the compatibility matrix, reference fields, preservation rules, provenance and finding codes — with one JSON Schema per artifact beside it. [`references/design-composition.md`](references/design-composition.md) defines the pattern contract and the binding rules.

## How it works

The narrative adapter reads only the slides grammar of `design-brief@1.1` — frontmatter, the Rendering Contract, numbered `## Slide N:` units with their fixed field set, trailer notes and the Sources block — and rejects anything else instead of guessing. Each normalized record keeps its exact source slice as `raw`, so fidelity is checkable without trusting the parser. The direct adapter requires ids, titles and bodies, resolves every source reference, and carries the brief's declared structure through untouched.

Chain validation checks each artifact's type and version, every cross-artifact reference and pinned version against the compatibility matrix, every unit reference against the normalized brief, and that no downstream unit carries fields outside its contract. The first violation is reported with its code, the rule it broke and the offending reference.

Composition starts from a draft that names, for each unit, an accepted pattern, a variant and the slot each record field fills. `compose` fills the mechanical fields — a digest per binding, the brief's content fingerprint, each unit's citations, the source register and the trailer-note bindings — and validates: every record and field bound once and in order, every note, evidence label and citation carried, every chart point a supplied, sourced value in one unit of measure, every slot within its limits, no geometry anywhere, and no proposed pattern in production. A repair may change pattern, variant and slot names only, and must keep the fingerprint byte for byte.

Rendering validates the brief and composition again, resolves the theme by the composition's pinned design-system name, compiles its tokens and resolves its fonts, then lays each unit out on a fixed canvas with deterministic line estimates measured in the resolved face. The HTML adapter inserts every original string through one escaping function, draws charts and system figures through one bounded SVG path generated from data only, and carries the theme's compiled token block verbatim. Before any file is written the page passes the independent fidelity checks — frozen copy, pattern semantics, citations, reading order, descriptions, portability and tokens — and `check-plan` passes the plan. The browser runtime is only for measurement; see [`references/design-render.md`](references/design-render.md).

Configuration resolves per key as supplied values, then publishing project configuration, then optional workspace preferences named by the caller, then bundled defaults; a missing preference file never aborts. See [`references/configuration-and-renderer-boundary.md`](references/configuration-and-renderer-boundary.md).

## Components

| Component | Type | Purpose |
|---|---|---|
| `publishing-validate` | Skill | Normalize briefs, validate artifact chains, resolve configuration |
| `design-compose` | Skill | Bind a normalized brief to reusable proof patterns as a semantic composition |
| `design-render` | Skill | Lay a composition out and render its branded HTML target with provenance |
| `manage-themes` | Skill | Select, author, audit, import and apply themes |
| `scripts/validate-publishing.py` | Script | Deterministic, stdlib-only validator with the standard JSON envelope, including the composition and plan commands |
| `scripts/design-render.py`, `render_core.py`, `html_adapter.py`, `render_checks.py` | Script | The stdlib render wrapper, its target-neutral core, the HTML adapter and the independent fidelity checks |
| `runtime/` | Runtime | The optional measurement runtime: exact-pinned manifest, lockfile, measurement script and operator-run provisioning |
| `scripts/discover-themes.py`, `select-theme.py` | Script | Theme discovery and the three-field selection handoff |
| `scripts/generate-tokens-css.py` | Script | Token compiler: aliases, `tokens.css` and the resolved projection |
| `scripts/validate-theme-manifest.py` | Script | Theme System v2 manifest and token-graph validator |
| `scripts/import-claude-design-bundle.py` | Script | Optional Claude Design bundle importer |
| `themes/` | Asset | Bundled themes: `cogni-work`, four archetype presets, `_template` |
| `references/theme-artifact-contract.md`, `token-subset.md` | Reference | The saved-theme contract and the supported token subset |
| `references/artifact-contracts.md` | Reference | Normative artifact, reference and compatibility contract |
| `references/pattern-library-v1.json` | Reference | The bundled proof-pattern library |
| `references/design-composition.md` | Reference | Pattern contract, binding, provenance, fit, repair and extension rules |
| `references/design-render.md`, `font-fallbacks-v1.json` | Reference | Render operations, plan and provenance shapes, font resolution, fidelity rules and the runtime boundary |
| `references/configuration-and-renderer-boundary.md` | Reference | Configuration precedence and the renderer pin |
| `references/*.schema.json` | Reference | One JSON Schema per artifact version, and the pattern contract |
| `tests/test-publishing-contracts.sh` | Test | Contract suite, discovered by the repository test runner |
| `tests/test-design-compose.sh` | Test | Composition suite: library contract, binding fidelity, provenance, fit, repair, status gate |
| `tests/test-design-render.sh` | Test | Render suite: outputs, frozen copy, pattern semantics, tokens, citations, portability, accessibility, fonts, comparator, runtime pin and boundary |
| `tests/test-theme-lifecycle.sh`, `test-semantic-tokens.sh`, `test-theme-backcompat.sh`, `test-bundled-presets.sh`, `test-check-contrast.sh` | Test | Theme selection, aliases, backwards compatibility, presets and contrast |

## Architecture

```text
cogni-publishing/
├── .claude-plugin/plugin.json
├── skills/
│   ├── publishing-validate/SKILL.md
│   ├── design-compose/SKILL.md
│   ├── design-render/SKILL.md
│   └── manage-themes/                  # SKILL.md, references/, evals/
├── scripts/
│   ├── validate-publishing.py
│   ├── design-render.py, render_core.py, html_adapter.py, render_checks.py
│   ├── discover-themes.py, select-theme.py, inspect-themes.py, check-theme-drift.py
│   ├── generate-tokens-css.py, validate-theme-manifest.py, import-claude-design-bundle.py
│   ├── sanitize-theme.py, load-theme-component.py, check-contrast.py
│   ├── verify-theme-backcompat.sh, verify-claude-design-importer.sh
│   └── baselines/                      # tier-0 discovery snapshot
├── runtime/                            # package.json, package-lock.json, measure.mjs, provision.sh
├── themes/                             # _template, boardroom, clean-slate, cogni-work, editorial, signal
├── references/
│   ├── artifact-contracts.md, design-composition.md, pattern-library-v1.json
│   ├── design-render.md, font-fallbacks-v1.json
│   ├── configuration-and-renderer-boundary.md
│   ├── *-v1.schema.json, semantic-composition-v2.schema.json, target-resolved-plan-v2.schema.json
│   ├── render-provenance-v1.schema.json, pattern-contract-v1.schema.json
│   ├── theme-artifact-contract.md, token-subset.md, theme-manifest.md, theme-manifest.schema.json
│   └── claude-design-bundle-mapping.md, theme-component-loader.md, design-variables-pattern.md
├── docs/theme-system-v2-migration.md
└── tests/
    ├── test-publishing-contracts.sh, test-design-compose.sh, test-design-render.sh
    ├── test-theme-lifecycle.sh, test-semantic-tokens.sh
    ├── test-theme-backcompat.sh, test-bundled-presets.sh, test-check-contrast.sh
    └── fixtures/
```

## Dependencies

None at validation or render time: Python 3 standard library and a POSIX shell. An external renderer is a separate, optional runtime pinned in configuration as `{"name", "version", "consumes": "target-resolved-plan@1"}` with an exact version; ordinary install and validation never download, import or run it. `design-render`'s own browser runtime is optional too: it needs Node 20 or later, is pinned by `runtime/package-lock.json`, is used only to measure a rendered page, and is provisioned once, by an operator, with `bash runtime/provision.sh`.

| Plugin | Required | Purpose |
|---|---|---|
| cogni-workspace | No | Produces narrative design briefs via `text-to-narrative`; its preferences are read only when a caller names the file. Its `manage-themes` is a same-name route that delegates here, and its `COGNI_WORKSPACE_ROOT/themes` directory is read, never written, as an optional user theme location |

## Development

```bash
bash tests/test-publishing-contracts.sh
bash tests/test-design-compose.sh
bash tests/test-design-render.sh
python3 ../scripts/run-plugin-tests.py --filter cogni-publishing
```

The suite prints one `PASS:`/`FAIL:` line per case, addressed by a stable `pubc-NN-…` id. Two guards carry recorded mutation checks, run from the repository root against the installed managed-service cogni-service harness. The recipe shape — `--root` the repository, `--file` the mutated file relative to it, a single-quoted `perl -0pi` expression, and `--case` equal to the label the suite prints — follows rule 5 of `skills/service-gatekeeper/references/review-plan-spec.md` in the cogni-service plugin:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return artifact_version in supported_versions/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-04-invalid-version
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return reference_id in available_ids/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-05-dangling-reference
```

A third recipe proves that dropping semantic-alias retention in the bundle importer fails the alias suite's exact case:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/import-claude-design-bundle.py --expr 's/return ALIAS_VAR\.fullmatch\(value\) is not None/return False/' --test 'bash cogni-publishing/tests/test-semantic-tokens.sh' --case stok-04-alias-retained
```

Four more prove the composition guards. The first two disable the unit-order and quantitative-provenance checks, the third lets a proposed pattern into production, and the fourth removes the skill's routing rule for proposed patterns; each fails its exact `dcmp` case:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return positions == sorted\(positions\)/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-10-reordered-unit
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return len\(source_refs\) > 0/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-25-unsourced-chart-data
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return pattern\.get\("status"\) == "accepted"/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-45-unaccepted-pattern
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-compose/SKILL.md --expr 's/Never route a proposed pattern into a production composition/Route any pattern into a composition/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-49-skill-proposed-routing
```

Two more prove the render's guards. The first damages the adapter's single insertion function, and `drnd-10-frozen-copy` must fail. The second makes the portability scan read copy text, so prose that names a path is refused, and `drnd-37-prose-paths-render` must fail. Without a provisioned runtime the two browser cases of that suite print `SKIP:` and never pass.

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/html_adapter.py --expr 's/return escape\(value, quote=True\)/return escape(value.upper(), quote=True)/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-10-frozen-copy
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/render_checks.py --expr 's/if node\.tag == "style":/if True:/' --test 'bash cogni-publishing/tests/test-design-render.sh' --case drnd-37-prose-paths-render
```

Each disables one guard, expects its case red, restores the file and expects it green.

## Custom development

Need a renderer integration, a house design system, or a publishing pipeline tailored to your brand? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for consulting and communication teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
