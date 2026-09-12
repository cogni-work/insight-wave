# `patch-desktop-config.py` result envelope

The output contract of the config writer. This file is the single home of the shape;
`install-mcp/SKILL.md` and `manage-workspace/SKILL.md` Init step 5 (which Update step 5
defers to) both point here rather than restating it.

## The shape depends on the target

A **single-target** run (`--target cli` or `--target desktop`) reports a flat `data.action`
and `data.config_path`.

A **`--target both`** run reports neither at the top level — it returns `data.targets[]`,
one `{target, action, config_path, actions}` object per config. Branch on the target before
reading the envelope, or a `both` run parses as though nothing happened. The one exception
is a registry with no servers, which returns the flat no-op shape under every target — see
"## Shapes that yield no rows at all".

## Per-server detail lives in `actions[]`

In both shapes the per-server detail is `actions[]`. Every entry carries `server` and
`action` (`added`, `updated` or `skipped`). An `added` or `updated` entry also carries
`config_key`; only a `skipped` entry carries `reason` — so do not expect `reason` on every
entry.

The **target-level** `action` is `patched`, `noop` (nothing needed) or `dry_run`. Build
per-server summary rows from `actions[]`, never from the target-level verb: doing otherwise
collapses every server into one row and makes a `noop` read as a failure.

Take each row's action verbatim from this envelope.

## Shapes that yield no rows at all

None of these returns a usable `actions[]`. Render no rows rather than inventing them:

- **A registry whose `servers` object is empty or absent** returns `success: true` with a
  flat top-level `action: "noop"` and `message: "No servers in registry"`, and no
  `actions[]`. That check runs before the per-target loop, so this flat shape is what a
  `--target both` run returns too — the only *successful* `both` run with no
  `data.targets[]`. Nothing was written and no config was even read: fix the registry
  rather than reporting a clean no-op install.
- **A `--target both` run stops at the first target whose existing config will not parse**
  and exits non-zero with `data.target` naming it. Read the direction from that field:
  desktop is attempted first, so a desktop failure leaves cli unattempted, while a cli
  failure means desktop was already **processed** — and processed is a write only where
  that target patched. A `--dry-run` run, or one where every server was skipped (`noop`),
  returns before the write and takes no backup. On a cli failure desktop's per-server
  actions, and its backup path where one was taken, are dropped, because the exit precedes
  the success envelope. Re-invoke with `--target <the failed one>` once its config parses, and
  treat a cli-failure run's desktop result as unreported rather than as unwritten.
- **A backup, or the config write itself, that fails on permissions** exits with **no JSON
  envelope at all** — both raise outside the only handled error class, so the run ends in a
  traceback. Surface the raw error rather than waiting for a payload that never comes, and
  re-invoke per-target as above.

## Backups

A `backup` key is present only on a `patched` target. The `noop` and `dry_run` returns
carry no `backup` key at all, so omit the `Backup:` row entirely for those rather than
rendering an empty one.

On a `patched` target, a timestamped backup is created before an **existing** config is
modified. A first-ever write has nothing to back up and reports `backup: null` — omit the
`Backup:` row in that case too rather than rendering `Backup: None`.
