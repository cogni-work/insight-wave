# Theme Backcompat Baselines

These JSON snapshots are reference outputs that
`verify-theme-backcompat.sh` diffs against on every run.

## Files

- `_template-tier0-output.json` — `discover-themes.py --no-include-tiers`
  output for the bundled tier-0 `_template/` theme, run against a temporary
  fixture (the script filters underscore-prefixed entries, so the harness
  copies `themes/_template/theme.md` into a non-underscored fixture before
  invoking discover).

## Normalization

Two fields vary per machine and per checkout — the harness rewrites them to
fixed placeholders before diffing, and the committed baseline stores the
placeholders directly:

| Field  | Placeholder             | Why                                                          |
|--------|-------------------------|--------------------------------------------------------------|
| `path` | `<THEME_PATH>`          | Absolute path to the fixture's `theme.md`. Always varies.    |
| `mtime`| `0`                     | Filesystem mtime. Always varies; not part of the contract.   |
| `slug` | `<NORMALIZED_SLUG>`     | Fixture dir name. Harness uses a stable name; placeholder    |
|        |                         | keeps the baseline robust if the fixture name ever changes.  |

All other fields (`name`, `description`, `primary`, `accent`, `background`,
`font`, `source`) are part of the **tier-0 contract** and any change to them
indicates a real regression — the harness will fail loudly until the
baseline is intentionally regenerated.

## Regenerating

Only regenerate when an *intentional* schema change ships (e.g. a new
top-level field is added to discover output across the board, and the
contract change has been reviewed). To regenerate:

```bash
bash cogni-workspace/scripts/verify-theme-backcompat.sh --regenerate-baseline
```

The `--regenerate-baseline` flag rewrites the file in place using the
current `discover-themes.py` output (with the same normalization rules
applied). Commit the result alongside the schema change.

## Adding new baselines

If a future theme is added to `cogni-workspace/themes/` and needs its own
backcompat snapshot, add a parallel baseline file here (e.g.
`cogni-work-tiered-output.json`) and extend the harness to diff against it.
Tier-0 themes live behind the underscore-prefix filter, so each one needs
its own non-underscored fixture in the harness.
