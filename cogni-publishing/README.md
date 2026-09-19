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

The canonical editorial subsystem lives here: `text-to-narrative`, `copywriter`, their agent, scripts, fixtures, arc and language contracts, and the frozen design-brief route. Workspace exposes temporary delegates and pointers only.

The contract boundary between authored briefs and optional renderers, and the owner of the theme lifecycle every themed output draws on. It defines four versioned artifacts — a normalized brief, a semantic composition, a target-resolved plan, and the envelope every operation answers with — and a stdlib-only validator that enforces them. Inputs arrive either as the narrative slides design brief that cogni-workspace's `text-to-narrative` produces, or as a structured direct brief that carries its own framework (Pyramid, SCQA, MECE) and never acquires a story arc. Themes — bundled presets, user themes and Claude Design imports — are selected, authored, validated and compiled here, with one canonical token representation per theme. Between the brief and any renderer sits a library of reusable proof patterns — `answer-emphasis`, `comparison`, `hero-metric`, `key-figure-strip`, `sourced-chart`, `conceptual-system` and `sources`, the accepted set of [`references/pattern-library-v1.json`](references/pattern-library-v1.json), which stays the authority as the library grows — to which every frozen unit is bound by reference, before any target decides geometry.

## What it does

- **`text-to-narrative`** — transforms source material into one of 15 arc-governed executive narratives, validates it, selects frozen copy into a self-contained design brief, then routes normally through normalize → design-compose → design-render while keeping Claude Design optional.
- **`copywriter`** — polishes, translates, compresses or reviews business documents with seven messaging frameworks, arc preservation, EN/DE-pivot translation across seven languages, deterministic readability measurement and stakeholder personas; it works without renderer or workspace setup.

- **`design-compose`** — binds a normalized brief's frozen records to the library's accepted proof patterns as a copy-free, geometry-free composition: every record, field, note, citation, evidence label and dataset bound exactly once and in authored order, one accepted pattern and variant per unit, and the mechanical fields — digests, the content fingerprint and citations — filled by compose itself. It fills an unpatterned metric unit's pattern from the brief's own key figures and only from accepted patterns, never overwrites a choice the draft carries, and never renders; the validator rejects copy or geometry in the composition, unsourced or invented chart values, content that does not fit, and any use of a proposed pattern → a target-neutral `semantic-composition@2`, exit 0 / 1 / 2.
- **`design-render`** — creates a branded HTML page or editable PPTX through the host platform route, then requires independent verification, preservation and visual review. The CLI accepts an explicit host bridge; missing capability returns `platform_renderer_unavailable` with no output. Browser measurement is a separate pinned operation.
- **`design-verify`** — checks a delivered page or deck again, independently, against its frozen brief and composition, and renders with a bounded repair loop. What it checks:
  - **Content**, family by family: copy, dataset values, source URLs, evidence status, notes and unit order. A family the brief does not carry is `not-carried`, never passed.
  - **Deck editability**: native text frames and native charts with embedded data, proved by text and chart edit witnesses.
  - **Accessibility**, graded against each target's declared capabilities: reading order, text alternatives, contrast from the brand's tokens, and non-colour cues. An unsupported capability is reported as unsupported.
  - **The critical classes**: clipping, overlap, missing glyphs, unreadable text and misleading figure encodings. Any open finding fails the verdict, with no pass rate.
  - **The persisted records**: the visual review record, the specimen index and the proof manifest.

  `render-verified` tries the other variants of a failing unit's pattern within a finite budget and never rewrites content. Output: `verification.json`, or a bounded failure with its repair history; exit 0 / 1 / 2.
- **`publishing-validate`** — normalizes a narrative slides brief or a direct brief into a `normalized-brief@1` that keeps every headline, field, note, evidence label, citation and source exactly as authored; validates a normalized-brief → semantic-composition → target-resolved-plan chain for version compatibility, dangling or malformed references and copy smuggled into downstream units; and resolves configuration precedence with the origin of every value → one JSON envelope, exit 0 / 1 / 2.
- **`manage-themes`** — selects, recommends, creates, audits, deepens, showcases and applies visual themes, and imports Claude Design bundles; returns the `theme_path` / `theme_name` / `theme_slug` handoff every themed consumer reads, from bundled presets, the optional user theme location or an explicit path with no workspace at all. Token files are the one authoritative representation: semantic aliases stay role-to-role references in `tokens.css`, a resolved projection serves consumers that cannot evaluate `var()`, and a cycle or dangling reference fails loudly.

## What it means for you

- **Approve copy once.** Downstream artifacts reference normalized copy by id and are rejected if they carry their own, so what the author signed off is what reaches the renderer.
- **Trace every figure.** Citations and source records keep their original ids from brief to plan; a number on a slide still names the source it came from.
- **Publish consult work as it was written.** A direct brief keeps its Pyramid or MECE structure — no arc, no BLUF slide, no narrative element count imposed.
- **Show comparisons, evidence and systems the same way every time.** A reusable pattern carries the content you approved; when it does not fit, you get a finding naming the unit and the limit — never a shortened sentence, a dropped source or an invented number.
- **Swap renderers without touching the brief.** Target and design-system decisions live in their own artifact; an external renderer is a pinned, optional runtime that consumes `target-resolved-plan@1`.
- **Hand over a deck the client can edit.** The PPTX render gives every headline, point and label as real text, every diagram as native shapes and connectors, and the chart with its data one Edit Data away — nothing flattened into a picture unless the pattern library declares that picture for the variant (today only a feedback loop's return track, beside its native shapes), nothing shrunk to fit, and independent package-level editability checks.
- **Hand over a branded page that proves itself.** The HTML render opens offline as a single file, links every citation to its source, and ships with a provenance record of the fonts, pins and fingerprint it was built from — a changed sentence or a moved chart fails the check instead of reaching the client.
- **Know what you are handing over.** Every output is checked against the brief it came from and inspected unit by unit. A clipped line, a lost source link or a chart that became a picture fails the check instead of reaching the client. The two-brand proof in [`docs/design-verify-proof.md`](docs/design-verify-proof.md) shows the whole path working, with its evidence.
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
python3 scripts/design-verify.py check-proof --manifest docs/design-verify-proof/proof-manifest.json
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

normalized-brief@1 + pattern-library@1 ─compose─> semantic-composition@2 ─host render─┬─> index.html
                                                                                     │                    └─> deck.pptx
                                                                                     └──> render-provenance@1
```

- **normalized-brief@1** — the only place copy and data live: ordered records with stable ids, source records with their original ids, freeze guarantees, provenance.
- **semantic-composition@1** — units that group records by role through `copy_refs`/`data_refs`; no target, no text.
- **target-resolved-plan@1** — target, pinned design system and per-unit layout; references the composition and the normalized brief.
- **pattern-library@1** — the reusable proof patterns, each with purpose, eligibility, slots and limits, evidence needs, accessibility semantics, target capabilities, variants and validated specimens, and a status of `accepted` or `proposed`.
- **semantic-composition@2** — pattern-bound units: every record, field, note, citation, evidence label, data point and trailer note bound exactly once by id and digest, plus a content fingerprint of the brief; no copy, no geometry.
- **render-provenance@1** — renderer, runtime pin and lockfile digest, design-system pin, theme token digest, content fingerprint, output digests and every font resolution of one render.

[`references/artifact-contracts.md`](references/artifact-contracts.md) is the normative definition — identities, the compatibility matrix, reference fields, preservation rules, provenance and finding codes — with one JSON Schema per artifact beside it. [`references/design-composition.md`](references/design-composition.md) defines the pattern contract and the binding rules.

## How it works

The narrative adapter reads only the slides grammar of `design-brief@1.1` — frontmatter, the Rendering Contract, numbered `## Slide N:` units with their fixed field set, trailer notes and the Sources block — and rejects anything else instead of guessing. Each normalized record keeps its exact source slice as `raw`, so fidelity is checkable without trusting the parser. The direct adapter requires ids, titles and bodies, resolves every source reference, and carries the brief's declared structure through untouched.

Chain validation checks each artifact's type and version, every cross-artifact reference and pinned version against the compatibility matrix, every unit reference against the normalized brief, and that no downstream unit carries fields outside its contract. The first violation is reported with its code, the rule it broke and the offending reference.

Composition starts from a draft that names, for each unit, an accepted pattern, a variant and the slot each record field fills — with one deliberate exception: a unit that declares metric intent whose bound text repeats one of the brief's key figures leaves its pattern and variant out for `compose` to route. `compose` fills the mechanical fields — a digest per binding, the brief's content fingerprint, each unit's citations, the source register and the trailer-note bindings — and then routes: a unit declaring metric intent whose bound text carries the brief's authored key figures gets `hero-metric` or `key-figure-strip`, and a `comparison` or `conceptual-system` unit of at most four items gets a `type_floor` of `type.lead`. Both arms fill only where the draft is silent — a pattern, variant or type floor the draft carries is judged, never overwritten — and neither splits, merges, truncates, reorders or rebinds content; a unit routing declines stays patternless and is rejected as `unknown-pattern`. It then validates: every record and field bound once and in order, every note, evidence label and citation carried, every chart point a supplied, sourced value in one unit of measure, every slot within its limits, no geometry anywhere, and no proposed pattern in production. A repair may change pattern, variant and slot names only, and must keep the fingerprint byte for byte.

Rendering validates the brief and composition, then passes frozen inputs and the authoritative theme to the host capability. Independent artifact checks and visual review gate handover; bounded repairs preserve all content and sources. See [references/design-render.md](references/design-render.md) for the explicit bridge and separate browser measurement contract.

Configuration resolves per key as supplied values, then publishing project configuration, then optional workspace preferences named by the caller, then bundled defaults; a missing preference file never aborts. See [`references/configuration-and-renderer-boundary.md`](references/configuration-and-renderer-boundary.md).

## Components

| Component | Type | Purpose |
|---|---|---|
| `publishing-validate` | Skill | Normalize briefs, validate artifact chains, resolve configuration |
| `design-compose` | Skill | Bind a normalized brief to reusable proof patterns as a semantic composition |
| `design-render` | Skill | Lay a composition out and render its branded HTML page or editable PPTX deck with provenance |
| `design-verify` | Skill | Verify a rendered page or deck against its frozen inputs, review it at full resolution, and repair within a budget |
| `manage-themes` | Skill | Select, author, audit, import and apply themes |
| `scripts/validate-publishing.py` | Script | Deterministic, stdlib-only validator with the standard JSON envelope, including the composition and plan commands |
| `scripts/design-render.py`, `render_core.py` | Script | Explicit host bridge, pinned browser measurement and shared verification helpers |
| `scripts/design-verify.py`, `verify_checks.py` | Script | The stdlib verification wrapper, with `render-verified` and its repair budget, and the checks behind it |
| `runtime/` | Runtime | The optional measurement runtime: exact-pinned manifest, lockfile, measurement script and operator-run provisioning |
| `scripts/discover-themes.py`, `select-theme.py` | Script | Theme discovery and the three-field selection handoff |
| `scripts/generate-tokens-css.py` | Script | Token compiler: aliases, `tokens.css` and the resolved projection |
| `scripts/derive-theme-tokens.py` | Script | Tier-0 derivation: a `theme.md`'s palette, fonts, type scale and spacing, verbatim, into `tokens/*.json` |
| `scripts/validate-theme-manifest.py` | Script | Theme System v2 manifest and token-graph validator |
| `scripts/import-claude-design-bundle.py` | Script | Optional Claude Design bundle importer |
| `themes/` | Asset | Bundled themes: `cogni-work`, four archetype presets, `_template`; every bundled theme ships tokens, so each one renders |
| `references/theme-artifact-contract.md`, `token-subset.md` | Reference | The saved-theme contract and the supported token subset |
| `references/artifact-contracts.md` | Reference | Normative artifact, reference and compatibility contract |
| `references/pattern-library-v1.json` | Reference | The bundled proof-pattern library |
| `references/design-composition.md` | Reference | Pattern contract, binding, provenance, fit, repair and extension rules |
| `references/design-render.md`, `font-fallbacks-v1.json` | Reference | Host bridge, provenance admission, shared font resolution and browser measurement boundary |
| `references/design-verify.md`, `verify-capabilities.json` | Reference | Verification: families, critical classes, the report, the review record, specimen index, proof manifest and repair budget; each target's declared accessibility capabilities |
| `references/configuration-and-renderer-boundary.md` | Reference | Configuration precedence and the renderer pin |
| `references/*.schema.json` | Reference | One JSON Schema per artifact version, and the pattern contract |
| `tests/test-publishing-contracts.sh` | Test | Contract suite, discovered by the repository test runner |
| `tests/test-design-compose.sh` | Test | Composition suite: library contract, binding fidelity, provenance, fit, repair, status gate |
| `tests/test-design-verify.sh` | Test | Verification suite: preservation per family, corruption cases for clipping, source-link loss and frozen copy, editability and witnesses, accessibility, the verdict, the review record, specimens, the proof manifest, the repair budget and standalone isolation |
| `docs/design-verify-proof.md`, `docs/design-verify-proof/` | Doc | The two-brand html and pptx proof: reproduce commands, outputs, verification reports, review record, specimen index, repair record and isolated run |
| `tests/test-theme-lifecycle.sh`, `test-semantic-tokens.sh`, `test-theme-backcompat.sh`, `test-bundled-presets.sh`, `test-check-contrast.sh` | Test | Theme selection, aliases, backwards compatibility, presets and contrast |
| `tests/test-derive-theme-tokens.sh` | Test | Tier-0 derivation: re-derived preset tokens byte-compared, verbatim literals, shared theme/font resolution per bundled theme, missing roles and refused overwrites |

## Architecture

```text
cogni-publishing/
├── .claude-plugin/plugin.json
├── skills/
│   ├── publishing-validate/SKILL.md
│   ├── design-compose/SKILL.md
│   ├── design-render/SKILL.md
│   ├── design-verify/SKILL.md
│   └── manage-themes/                  # SKILL.md, references/, evals/
├── scripts/
│   ├── validate-publishing.py
│   ├── design-render.py, render_core.py
│   ├── design-verify.py, verify_checks.py
│   ├── discover-themes.py, select-theme.py, inspect-themes.py, check-theme-drift.py
│   ├── generate-tokens-css.py, derive-theme-tokens.py, validate-theme-manifest.py, import-claude-design-bundle.py
│   ├── sanitize-theme.py, load-theme-component.py, check-contrast.py
│   ├── verify-theme-backcompat.sh, verify-claude-design-importer.sh
│   └── baselines/                      # tier-0 discovery snapshot
├── runtime/                            # package.json, package-lock.json, measure.mjs, provision.sh
├── themes/                             # _template, boardroom, clean-slate, cogni-work, editorial, signal
├── references/
│   ├── artifact-contracts.md, design-composition.md, pattern-library-v1.json
│   ├── design-render.md, font-fallbacks-v1.json
│   ├── design-verify.md, verify-capabilities.json
│   ├── configuration-and-renderer-boundary.md
│   ├── *-v1.schema.json, semantic-composition-v2.schema.json
│   ├── render-provenance-v1.schema.json, pattern-contract-v1.schema.json
│   ├── theme-artifact-contract.md, token-subset.md, theme-manifest.md, theme-manifest.schema.json
│   └── claude-design-bundle-mapping.md, theme-component-loader.md, design-variables-pattern.md
├── docs/
│   ├── theme-system-v2-migration.md, design-verify-proof.md
│   └── design-verify-proof/            # host outputs, frozen inputs, reports, reviews and provenance
└── tests/
    ├── test-publishing-contracts.sh, test-design-compose.sh, test-browser-measurement.sh
    ├── test-design-verify.sh
    ├── test-theme-lifecycle.sh, test-semantic-tokens.sh
    ├── test-theme-backcompat.sh, test-bundled-presets.sh, test-check-contrast.sh
    ├── test-derive-theme-tokens.sh
    └── fixtures/                       # verify/: the proof brief, its two brand compositions, the unfit fixture
```

## Dependencies

Validation and independent verification need only Python 3 standard library and a POSIX shell. Rendering requires the host presentation skill or an explicit host bridge. The separately configured external renderer for the older artifact chain remains optional. Browser measurement requires the pinned runtime, provisioned by the operator with `bash runtime/provision.sh`; validation and rendering install nothing.

| Plugin | Required | Purpose |
|---|---|---|
| cogni-workspace | No | Keeps temporary same-name editorial delegates and optional preferences; publishing owns the narrative and copywriter implementations. Its `manage-themes` is also a same-name route that delegates here, and its `COGNI_WORKSPACE_ROOT/themes` directory is read, never written, as an optional user theme location |

## Development

```bash
bash tests/test-publishing-contracts.sh
bash tests/test-design-compose.sh
bash tests/test-design-verify.sh
python3 ../scripts/run-plugin-tests.py --filter cogni-publishing
python3 scripts/design-verify.py check-proof --manifest docs/design-verify-proof/proof-manifest.json
```

The platform proof is independently rechecked with `check-proof`; actual host execution, frozen inputs, artifact digests and visual review are recorded in [docs/design-verify-proof.md](docs/design-verify-proof.md). Static historical outputs are regression inputs, not a reproducible rendering route.

The suite prints one `PASS:`/`FAIL:` line per case, addressed by a stable `pubc-NN-…` id. Six guards carry recorded mutation checks, run from the repository root against the installed managed-service cogni-service harness. The recipe shape — `--root` the repository, `--file` the mutated file relative to it, a single-quoted `perl -0pi` expression, and `--case` equal to the label the suite prints — follows rule 5 of `skills/service-gatekeeper/references/review-plan-spec.md` in the cogni-service plugin:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return artifact_version in supported_versions/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-04-invalid-version
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return reference_id in available_ids/return True/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-05-dangling-reference
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return subtitle\[1:-1\]/return subtitle/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-24-subtitle-emphasis-strip
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/frontmatter\[key\] = items if saw_item else \(mapping if saw_pair else None\)/frontmatter[key] = items if items else mapping/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-31-key-figures-empty-block
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/if field in declared and declared\[field\] is None:/if False:/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-32-design-field-declared-empty
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/if subtitle\[0\] in subtitle\[1:-1\]:/if False:/' --test 'bash cogni-publishing/tests/test-publishing-contracts.sh' --case pubc-33-subtitle-two-spans-unchanged
```

A fourth recipe proves that dropping semantic-alias retention in the bundle importer fails the alias suite's exact case:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/import-claude-design-bundle.py --expr 's/return ALIAS_VAR\.fullmatch\(value\) is not None/return False/' --test 'bash cogni-publishing/tests/test-semantic-tokens.sh' --case stok-04-alias-retained
```

Nine prove the composition guards, one fewer than the suite header records. The first two disable the unit-order and quantitative-provenance checks, the third lets a proposed pattern into production, and the fourth removes the skill's routing rule for proposed patterns. The next five hold the metric routing: the fifth removes the type floor a small comparison or conceptual-system unit is given, the sixth disables the hero arm for a single key-figure match, the seventh drops the guard that keeps routing off a pattern or variant the draft already carries, the eighth flips the skill's never-overwrite clause, and the ninth lowers the hero ceiling so a unit at full capacity no longer routes. Each fails its exact `dcmp` case:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return positions == sorted\(positions\)/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-10-reordered-unit
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return len\(source_refs\) > 0/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-25-unsourced-chart-data
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/return pattern\.get\("status"\) == "accepted"/return True/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-45-unaccepted-pattern
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-compose/SKILL.md --expr 's/Never route a proposed pattern into a production composition/Route any pattern into a composition/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-49-skill-proposed-routing
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/unit\["type_floor"\] = "type\.lead"/pass/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-72-type-floor-four-items
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/elif matched == 1 and len\(corpus\) <= HERO_MAX_ITEMS:/elif False:/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-69-route-hero-one-match
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/if figures and "pattern" not in unit and "variant" not in unit and declares_metric\(unit, index\):/if figures and declares_metric(unit, index):/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-77-route-authored-pattern-kept
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-compose/SKILL.md --expr 's/is judged, never overwritten/is replaced/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-78-skill-metric-routing
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/validate-publishing.py --expr 's/HERO_MAX_ITEMS = 4/HERO_MAX_ITEMS = 3/' --test 'bash cogni-publishing/tests/test-design-compose.sh' --case dcmp-79-hero-context-full-capacity
```

One more proves the tier-0 derivation. It renames the role key the renderer reads the page ground from, so re-deriving a preset no longer reproduces its committed tokens, and `dtt-03-rederive-boardroom` must fail:

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/derive-theme-tokens.py --expr 's/"Background": "bg"/"Background": "background"/' --test 'bash cogni-publishing/tests/test-derive-theme-tokens.sh' --case dtt-03-rederive-boardroom
```

Fourteen more prove the verification guards; the `dver` suite needs no runtime, so none of its cases prints `SKIP:`.

- **The four executable guards.** The first three relax the frozen-copy, source-link and clipping checks, so `dver-11-frozen-copy`, `dver-12-source-link-loss` and `dver-13-clipping` must fail. The fourth lets the repair loop ignore its budget, and `dver-25-repair-budget-zero` must fail.
- **The ten prose recipes.** Nine each delete one anchored rule: six from the `design-verify` skill (the five review rules and the repair budget) and three from `design-render` (verify then report, repair within the budget and report a bounded failure, never rewrite copy). The tenth deletes only the verdict clause from the post-render line, so `dver-34-render-wiring` must fail on it too. A prose rule can only be held by its shape, so those cases are anchored checks backed by these mutations, not behavioral tests.

```bash
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/verify_checks.py --expr 's/return found_text == frozen_text/return True/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-11-frozen-copy
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/verify_checks.py --expr 's/return target_url == source_url/return True/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-12-source-link-loss
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/verify_checks.py --expr 's/return needed_px > available_px \+ CLIP_TOLERANCE_PX/return False/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-13-clipping
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/design-verify.py --expr 's/return used < budget/return True/' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-25-repair-budget-zero
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^Inspect every unit at full resolution[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-29-skill-full-resolution
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^Review one deck overview per brand and target[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-30-skill-deck-overview
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^An open critical finding blocks success[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-31-skill-critical-blocks
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^Never record an unqualified quality verdict[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-32-skill-qualified-verdict
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^A repair never alters frozen content[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-33-skill-frozen-content
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-verify/SKILL.md --expr 's/^The repair budget defaults to 3[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-42-skill-repair-budget
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/^After every render, run design-verify[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-34-render-wiring
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/^When verification fails, repair within the budget[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-40-render-repair-report
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/^Never rewrite, shorten, add, drop or reorder copy[^\n]*\n//m' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-41-render-frozen-copy
bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/skills/design-render/SKILL.md --expr 's/ and report success only when its verdict passes//' --test 'bash cogni-publishing/tests/test-design-verify.sh' --case dver-34-render-wiring
```

Each disables one guard, expects its case red, restores the file and expects it green.

## Custom development

Need a renderer integration, a house design system, or a publishing pipeline tailored to your brand? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for consulting and communication teams.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
