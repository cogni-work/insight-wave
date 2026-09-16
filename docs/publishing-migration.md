# Publishing migration guide

Publishing capabilities moved from `cogni-workspace` to `cogni-publishing`. Your
saved themes and workspace configuration are untouched by the move, and the old
names keep working until the migration window closes.

**If you do nothing:** everything continues to work until **2026-12-15**. After
that, the old `cogni-workspace` names for narrative, copywriting and theme work
are removed and you call the `cogni-publishing` names instead.

---

## What moved

| Capability | Now owned by | Was |
|---|---|---|
| Narrative composition — story arcs, executive narratives, the frozen brief | `cogni-publishing` | `cogni-workspace` |
| Copywriting — messaging frameworks, translate-then-polish, stakeholder review | `cogni-publishing` | `cogni-workspace` |
| Theme lifecycle — authoring, import, validation, selection, token compilation | `cogni-publishing` | `cogni-workspace` |
| Composition, rendering and verification of a brief | `cogni-publishing` | did not exist |

## What stayed

`cogni-workspace` remains the horizontal layer and keeps everything that is not
publishing: workspace preferences and generated settings, language delivery,
plugin and optional-tool discovery, MCP installation, the supported-markets
registry, shared project discovery, claim verification, workspace health and
diagnostics, Obsidian integration, issue reporting, and the user-facing output
register. None of these moved, and none is planned to.

---

## Install

`cogni-publishing` is standalone. It needs no `cogni-workspace` installation, no
workspace initialisation, no credential, no network access, no Node and no
browser to normalize, compose, render and verify a brief. Its render path is
Python 3 standard library only.

```
/plugin marketplace add cogni-work/insight-wave
/plugin install cogni-publishing
```

Installing it alongside `cogni-workspace` is the ordinary case and needs no
special handling — the two coexist, and the old names route to the new ones for
the duration of the window below.

---

## Migrate

Point new work at the canonical names. Both spellings resolve today; only the
left column resolves after the window closes.

| Old name | Canonical name |
|---|---|
| `cogni-workspace:text-to-narrative` | `cogni-publishing:text-to-narrative` |
| `/text-to-narrative` (workspace) | `/text-to-narrative` (publishing) |
| `cogni-workspace:copywriter` | `cogni-publishing:copywriter` |
| `/copywrite` (workspace) | `/copywrite` (publishing) |
| `cogni-workspace:manage-themes` | `cogni-publishing:manage-themes` |
| `/manage-themes` (workspace) | `/manage-themes` (publishing) |
| `cogni-workspace/skills/text-to-narrative/references/**` (arc and language contracts) | the public publishing editorial contract |
| `cogni-workspace/references/design-variables-pattern.md` | the canonical copy in `cogni-publishing` |

The skill, command and agent names are **identical** on both sides. Nothing was
renamed; only the owning plugin changed, so a migration is a one-word edit at
each call site.

### The migration window

**The window closes 2026-12-15.**

Until then the `cogni-workspace` routes forward every request and its arguments
unchanged and hand the result straight back, including the
`theme_path` / `theme_name` / `theme_slug` handoff. They add no behaviour of
their own and never run a reduced workflow: with `cogni-publishing` absent, a
route fails with installation guidance rather than degrading silently.

After the window closes, the routes are removed. Nothing else changes: the
capabilities themselves are unaffected, because they already live in
`cogni-publishing` today.

---

## Optional workspace enrichment

`cogni-workspace` is **optional** for publishing, in both directions:

- **Preferences are read, never required.** Publishing reads a workspace
  preference only from a path a caller supplies. It never reads environment
  variables, never probes your home directory, and never probes sibling plugin
  paths to find one. Resolution order per key is: an explicit value you pass,
  then publishing project configuration, then an optional workspace preference,
  then the bundled default.
- **Your themes are read in place.** Saved user themes stay exactly where they
  are — typically `{workspace}/cogni-workspace/themes/`. Publishing reads them
  from that location and a user theme shadows a bundled one of the same slug. No
  read operation moves, rewrites, overwrites or creates anything there.

If `cogni-workspace` is not installed at all, publishing still runs: it falls
back to its bundled defaults and its own bundled themes.

---

## Supported capabilities

From one composition, `cogni-publishing` produces:

- **Portable branded HTML** — a self-contained page whose component CSS reaches
  the theme through custom properties only, with licensed font faces embedded
  from the theme that ships them.
- **Editable PPTX** — a real deck written straight from the layout plan, with
  every object's editability recorded. Text stays text, charts stay native
  charts, and a picture may appear only as a fallback the pattern library
  declares for that unit, recorded as such.
- **Independent verification** — `design-verify` grades the rendered output
  against the frozen brief: copy preserved verbatim, order preserved, source
  links preserved, nothing clipped or hidden.

Copy and order are frozen by digest before anything renders. Rendering may
change presentation only — it never rewrites, shortens, adds, drops or reorders
your copy.

Claude Design remains available as an **optional handoff** for a brief. It is no
longer the only way to render one.

---

## Rollback

### Inside the window

Nothing to undo. Both the old and the canonical names resolve, so reverting a
call site to the old spelling restores the previous behaviour immediately. The
routes are argument-transparent, so no call site needs its arguments changed in
either direction.

### Your files are never rewritten

The migration does not move, rewrite or overwrite:

- your saved themes under `{workspace}/cogni-workspace/themes/`
- `.workspace-config.json`
- `.workspace-env.sh`
- `.claude/settings.local.json`
- anything under `{working_dir}/cogni-claims/`

### Dry-run walkthrough

To confirm this on your own workspace before migrating any call site:

1. Record the current state of the files that matter:

   ```
   shasum -a 256 .workspace-config.json .claude/settings.local.json > /tmp/pre-migration.txt
   find cogni-workspace/themes -type f | sort | xargs shasum -a 256 >> /tmp/pre-migration.txt
   ```

2. Install `cogni-publishing` and run a theme selection through the canonical
   name (`cogni-publishing:manage-themes`, Operation 11), then a render.

3. Re-record and compare:

   ```
   shasum -a 256 .workspace-config.json .claude/settings.local.json > /tmp/post-migration.txt
   find cogni-workspace/themes -type f | sort | xargs shasum -a 256 >> /tmp/post-migration.txt
   diff /tmp/pre-migration.txt /tmp/post-migration.txt
   ```

   The diff is empty. Reads never write, so a selection and a render leave every
   one of those files byte-identical. Only an explicit write operation of
   `manage-themes` — authoring, importing or overwriting a theme you asked it to
   change — modifies anything under `themes/`.

If the diff is **not** empty, stop and file an issue with the diff attached:
that is a defect, not expected behaviour.

---

## Where the decisions live

This guide is the user-facing surface. The decision record — the row-by-row
ownership inventory, each compatibility route's measured exit condition, and the
declared window — is
[`architecture/publishing-transition.md`](architecture/publishing-transition.md).
