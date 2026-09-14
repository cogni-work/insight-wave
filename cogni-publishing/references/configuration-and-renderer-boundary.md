# Configuration and renderer boundary

## Precedence

Each key resolves independently, and the first layer that defines it wins:

1. supplied values — `--set key=value` (settable keys: `target`, `language`)
2. publishing project configuration — `--project-config <file>`
3. optional workspace preferences — `--workspace-preferences <file>`
4. bundled defaults — `target: slides`, `language: en`, `renderer: null`

`resolve-config` returns the resolved `configuration`, an `origin` map naming the layer each value came from, and the `precedence` order, so a caller can see — not infer — that an explicit value beat a preference.

A named project configuration must exist; a missing one is a runtime error (exit 2). Workspace preferences are optional: a named file that does not exist contributes nothing and never aborts resolution. The validator reads a preference file only when its path is supplied. It never searches for cogni-workspace, never reads environment variables or the home directory, and never probes a sibling plugin's private files — the contract suite runs it from a scratch directory with an empty environment and an audit hook to hold it to that.

## Renderer integration

Validation ends at `target-resolved-plan@1`. A renderer is a separate, optional runtime selected in configuration and pinned to an exact version:

```json
{"renderer": {"name": "pptx-runtime", "version": "2.4.1", "consumes": "target-resolved-plan@1"}}
```

`consumes` defaults to `target-resolved-plan@1`, the only plan version a renderer may consume today; any other value is rejected. A renderer without an exact `x.y.z` version (a range such as `^2.4`, or a bare name) is rejected as `unpinned-renderer`. The pin is checked as data only.

Ordinary installation, normalization and validation never download, provision, import, start or contact a renderer, and need no Node runtime, model API, rendering package or network access. Renderer availability is the concern of the later rendering operation that owns that dependency.

## design-render

The configured `renderer` pin above describes an external renderer and still consumes `target-resolved-plan@1`. The plugin's own `design-render` is not configured through it: it emits and validates its own `target-resolved-plan@2` and renders the HTML and PPTX targets in Python 3 stdlib, with no Node runtime, browser, network, model API or presentation library. Its PPTX writer is design-render itself, so its identity — the plugin version read at render time and the running interpreter — is recorded in each deck's `pptx-manifest@1` and provenance rather than pinned here. Its browser runtime is separate and optional — `runtime/package.json` pins `playwright-core` to an exact version and `runtime/package-lock.json` locks it with a sha512 integrity hash. It only measures a rendered page, it is provisioned only by the operator-run `runtime/provision.sh`, and design-render resolves it only from that provisioning record, never from PATH. Normalization, validation and a plain render still never install, start or contact it; [`design-render.md`](design-render.md) describes the boundary in full.
