# cogni-publishing

Standalone publishing contracts and validation for insight-wave. The plugin must work without cogni-workspace — or any other insight-wave plugin — being installed or initialised.

## Architecture

The artifact chain is deliberately split so each stage evolves on its own version:

1. authored input — `direct-brief@1`, or the bounded `design-brief@1.1` slides adapter
2. `normalized-brief@1` — the only place copy and data live
3. `semantic-composition@1` — grouping and roles, by reference
4. `target-resolved-plan@1` — target and design-system decisions, by reference

`references/artifact-contracts.md` is normative; the four JSON Schemas beside it document the same shapes. `scripts/validate-publishing.py` is the single enforcer.

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

## Tests

`tests/test-publishing-contracts.sh` is discovered by `scripts/run-plugin-tests.py`. Case ids are `pubc-NN-<discriminator>`, allocated once and never renumbered — the mutation recipes in the suite header and README record `pubc-04-invalid-version` and `pubc-05-dangling-reference`. The two predicates those recipes mutate, `version_supported` and `reference_resolves`, must keep their exact one-line bodies, or the recorded `--expr` stops matching.

The narrative fixture is cogni-workspace's green `slides-en.md` design brief plus one `evidence_status` line on slides 2–6; its expected normalized output is frozen in `narrative-slides-v1.expected.json`. When the adapter's output shape changes on purpose, regenerate that file and confirm `pubc-02` — the independent slicing oracle — still passes before committing it.

```bash
python3 scripts/validate-publishing.py normalize --kind narrative --input tests/fixtures/narrative-slides-v1.md
python3 scripts/validate-publishing.py validate --input tests/fixtures/contract-chain-v1.json
bash tests/test-publishing-contracts.sh
```
