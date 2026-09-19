# Platform rendering and measurement

`design-render` delegates artifact creation to the host capability selected by the skill. On Codex, use bundled `presentations:Presentations`; on an Anthropic host use the installed PPTX capability. HTML is authored against [layout-contract.md](layout-contract.md). Both targets enter handover only after independent [verification](design-verify.md), preservation and visual review. No built-in artifact writer or geometry plan is shipped.

## Host bridge

The skill invokes the selected capability directly. An automation that already has a host bridge can supply it to the CLI as a JSON argv array:

```bash
python3 scripts/design-render.py render --target pptx --brief brief.json --composition composition.json --theme themes/boardroom --out output --platform-command '["python3", "/path/to/host-bridge.py"]'
```

The bridge is caller-supplied executable code. The CLI never searches for it, installs it, evaluates shell text or consults a renderer registry. No bridge returns exactly `{"success": false, "error": "platform_renderer_unavailable"}` before reading inputs or creating output.

Each invocation receives `--target`, `--brief`, `--composition`, `--theme`, `--out` and `--attempt`. A repair also receives `--findings-file`, a JSON list of the previous attempt's findings. It must emit one JSON envelope, exit zero only on success, and place `index.html` or `deck.pptx` plus `provenance.json` in its supplied scratch directory. Failure findings identify the failing `unit`. The wrapper checks platform provenance and independently verifies the artifact before publishing the directory. It refuses to replace nonempty output. Host output is not claimed byte-reproducible.

`design-verify.py render-verified` accepts the same `--platform-command`, frozen inputs, fixed run identifiers, output directory and a repair budget (default 3, maximum 10). Every attempt uses the same bridge. Repairs may change presentation variants only and must pass `check-repair`; content, data, source identity and unit order remain frozen. The result records all findings and repairs. A failed attempt never publishes a deliverable.

## Inputs and themes

The normalized brief is the only source of copy and data. Its composition references records by id and digest. The theme directory name equals `design_system.name`; authoritative `tokens/*.json` supply color, typography and spacing roles. Missing roles fail closed. Shared input, theme, font and conservative measurement helpers live in `render_core.py`; it contains no writer or layout planner.

Font choices and substitutions must be explicit in provenance. A theme may ship licensed faces in `assets/fonts/faces.json` with their licenses. Use the selected theme even when a host brand capability proposes other colors. The skill's handoff contract defines copy object names, citations, native charts, speaker notes, dark surfaces and key figures. An existing deck's editability is inventoried directly from its package.

## Provenance

`check-provenance --provenance output/provenance.json --out-dir output` validates [render-provenance-v1.schema.json](render-provenance-v1.schema.json)'s platform record and evidence digests. Record renderer skill and host identity, immutable brief/composition/theme inputs, artifact digest, attempt ledger, before/after content fingerprints and ordered unit ids, preservation results, visual review and applicability evidence. A real host execution sets `live_proof: true`; offline test fixtures explicitly set it false and cannot enter a live proof manifest. Capability execution on Codex does not establish execution on another host.

## Pinned browser measurement

`check-runtime-lock` checks the exact dependency pins, lockfile integrity and ignored installation directories. Provision separately with `bash runtime/provision.sh`. `measure --html output/index.html --out output/browser-report.json` then loads the page offline and reports geometry, clipped copy, blocked/failed requests and platform fonts. Only the explicitly provisioned runtime is used; no PATH search, installer or network fallback runs. Missing provisioning produces an actionable `runtime-missing` finding.

The browser runtime remains a measurement dependency, separate from host rendering. `tests/test-browser-measurement.sh` exercises it; CI requires provisioned cases to pass instead of skipping.

## Finding response

Return composition errors to `design-compose`, theme errors to `manage-themes`, and artifact findings verbatim to the same host renderer. Repair layout or choose another admitted presentation variant; never shorten frozen copy to fit. Review all slides or units at full resolution, then the overview. A critical finding blocks delivery.
