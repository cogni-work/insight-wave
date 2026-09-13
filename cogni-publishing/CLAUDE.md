# cogni-publishing

Standalone publishing contracts and validation for insight-wave. The plugin must work without cogni-workspace — or any other insight-wave plugin — being installed or initialised.

## Architecture

The artifact chain is deliberately split so each stage evolves on its own version:

1. authored input — `direct-brief@1`, or the bounded `design-brief@1.1` slides adapter
2. `normalized-brief@1` — the only place copy and data live
3. `semantic-composition@1` — grouping and roles, by reference
4. `target-resolved-plan@1` — target and design-system decisions, by reference

Beside that chain, `design-compose` binds a normalized brief to `pattern-library@1` — the bundled `references/pattern-library-v1.json` — and emits a `semantic-composition@2`: pattern-bound units that reference content by id and digest and carry no copy and no target geometry. `target-resolved-plan@1` still consumes `@1` only; the plan that consumes `@2` lands with the renderers.

`references/artifact-contracts.md` is normative for the chain and `references/design-composition.md` for the pattern contract and binding rules; the JSON Schemas beside them document the same shapes. `scripts/validate-publishing.py` is the single enforcer.

## Conventions

- Scripts use Python 3 stdlib only and emit exactly one `{"success": bool, "data": {...}, "error": string|null}` on stdout and nothing on stderr. Exit 0 valid, 1 contract rejection, 2 usage/runtime error. A rejection's `data` is the finding (`code`, `check`, `artifact`, `reference`) and never a partial artifact.
- Never copy text into a downstream artifact. Composition and plan units reference normalized records by id; the validator rejects any other unit field as `unexpected-field`.
- Normalization never rewrites, reorders or drops a value. Narrative records keep their exact source slice as `raw`.
- The narrative adapter stays bounded to the slides grammar of `design-brief@1.1`. Widening it to another target or version is a contract change, not a parser tweak.
- A direct brief keeps its declared `structure`; never add arc, BLUF, slide-number or narrative-element requirements to it.
- Read workspace preferences only from a caller-supplied path. The validator never reads environment variables or the home directory and never probes sibling plugin paths; `pubc-16` in the suite enforces this with an audit hook.
- Resolve configuration per key: supplied values, publishing project configuration, optional workspace preferences, bundled defaults.
- Rendering stays optional and outside validation. A renderer is pinned with an exact version and consumes `target-resolved-plan@1`; validation checks the pin as data and never installs, imports or runs a renderer.
- Add a contract version only with a compatibility row in `references/artifact-contracts.md` and the matching `SUPPORTED`/`COMPATIBLE` entries in the validator, in the same change.
- Patterns are library data; families (`text`, `chart`, `system`, `register`) are validator code. Adding a pattern is a library entry with at least one passing specimen; adding a family is a reviewed code change.
- A `proposed` pattern never reaches production: the composition commands reject it as `unaccepted-pattern`. Promotion is a reviewed change that flips its `status` once `check-patterns` reports it ready.
- `compose` fills only mechanical fields — digests, the content fingerprint, citations, the register and trailer-note bindings — and never picks, splits, merges, truncates or reorders content. A repair changes only pattern, variant and slot names.
- The composition commands read the bundled library beside the script, found from the script's own location, or an explicit `--patterns` file — nothing else.

## Theme lifecycle

This plugin is the single owner of the theme lifecycle: `manage-themes` (selection, authoring, audit, showcase, application and Claude Design import), the bundled `themes/`, and the scripts, schema and references behind them. `cogni-workspace` keeps only compatibility routes — a same-name `manage-themes` skill that delegates here and four script entry points resolved through its `scripts/_publishing_delegate.py` — so never add theme behaviour there; add it here and let the routes forward it.

- **Roots come from the script's own location.** The theme scripts find the bundled `themes/` as `<plugin>/themes` relative to themselves, with `--plugin-root` as an explicit override. They never read `$CLAUDE_PLUGIN_ROOT` for it: a caller in another plugin — or a delegate — runs with that variable naming a plugin that ships no themes.
- **User themes are input, never output of a read.** The optional user location resolves `--user-themes` > `--workspace-root`/themes > `$COGNI_WORKSPACE_ROOT/themes` > legacy auto-discovery (`discover-themes.py` only), and a user theme shadows a bundled one of the same slug. No read moves, rewrites or creates anything there; only the write operations of `manage-themes` do.
- **The selection handoff is `theme_path` / `theme_name` / `theme_slug`**, emitted by `scripts/select-theme.py` and defined in `references/theme-artifact-contract.md`. Its explicit-path mode reads no environment and nothing under `$HOME`.
- **Legacy output shapes are part of the contract.** `discover-themes.py` prints a bare JSON array with `standard`/`workspace` source labels, and its tier-0 output is snapshotted in `scripts/baselines/`; `inspect-themes.py` and `check-theme-drift.py` keep their envelopes. The envelope-only, nothing-on-stderr rule above binds the contract scripts and `select-theme.py`; the legacy theme scripts keep their existing stderr hints.
- **`tokens/*.json` is the one authoritative token representation.** `generate-tokens-css.py` compiles it to `tokens.css` (aliases stay `var()` references) and, when an alias exists, `tokens.resolved.json`. Both are projections: regenerate them, never edit them. The token header line and flat-map output are frozen, because every saved `tokens.css` is parity-checked against them. The accepted input shapes are `references/token-subset.md`; a `$type` added to the compiler's `SUPPORTED_TYPES` must be added to that page's `**Supported $type values:**` line in the same change, which `stok-19` pins.
- **The importer never writes around a broken graph.** A bundle alias cycle or unresolved reference aborts before the target is touched; unsupported alias forms are reported in `aliases_dropped`, never dropped silently. Re-import replaces only the files the sidecar's `managed_files` lists.

## Tests

`tests/test-publishing-contracts.sh` is discovered by `scripts/run-plugin-tests.py`. Case ids are `pubc-NN-<discriminator>`, allocated once and never renumbered — the mutation recipes in the suite header and README record `pubc-04-invalid-version` and `pubc-05-dangling-reference`. The two predicates those recipes mutate, `version_supported` and `reference_resolves`, must keep their exact one-line bodies, or the recorded `--expr` stops matching.

`tests/test-design-compose.sh` grades the composition layer with `dcmp-NN-<discriminator>` ids under the same allocate-once rule. Its recorded recipes mutate `order_preserved`, `provenance_present` and `pattern_accepted` in the validator, which must keep their exact one-line bodies — `return positions == sorted(positions)`, `return len(source_refs) > 0` and `return pattern.get("status") == "accepted"` — the register guard in `validate_composition`, which must stay the single line `if require_register and index.source_ids and not state.register_units:` — and the routing sentence in `skills/design-compose/SKILL.md` that begins "Never route a proposed pattern into a production composition", which must occur exactly once. `pubc-16` also audits the four composition commands for standalone isolation. The two composition fixtures are frozen `compose` output: regenerate them with `compose` from a stripped draft, never by typing a digest.

The narrative fixture is cogni-workspace's green `slides-en.md` design brief plus one `evidence_status` line on slides 2–6; its expected normalized output is frozen in `narrative-slides-v1.expected.json`. When the adapter's output shape changes on purpose, regenerate that file and confirm `pubc-02` — the independent slicing oracle — still passes before committing it.

The theme suites follow the same id discipline: `test-theme-lifecycle.sh` (`thl-NN-…`), `test-semantic-tokens.sh` (`stok-NN-…`), and the moved `test-theme-backcompat.sh` (`tbc…`), `test-bundled-presets.sh` (`bp-…`) and `test-check-contrast.sh` (`cc…`). The alias recipe in the `test-semantic-tokens.sh` header mutates `retains_alias` in the importer, so that function must keep its exact one-line body, `return ALIAS_VAR.fullmatch(value) is not None`.

```bash
python3 scripts/validate-publishing.py normalize --kind narrative --input tests/fixtures/narrative-slides-v1.md
python3 scripts/validate-publishing.py validate --input tests/fixtures/contract-chain-v1.json
python3 scripts/validate-publishing.py check-composition --brief tests/fixtures/narrative-slides-v1.expected.json --composition tests/fixtures/composition-narrative-v2.json
bash tests/test-publishing-contracts.sh
bash tests/test-design-compose.sh
```
