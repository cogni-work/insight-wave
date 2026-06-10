---
name: knowledge-index
description: "Rebuild the curated root index + per-type sub-indexes of a cogni-knowledge base on demand, or migrate an EXISTING pre-0.0.8 wiki to the curated layout (control files into wiki/meta/, overview folded into the index intro, flat root split into root-map + sub-indexes, schema 0.0.7→0.0.8). Use this skill whenever the user says 'rebuild the index', 'rebuild the knowledge index', 'regenerate the wiki indexes', 'refresh the sub-indexes', 'migrate my wiki to the curated layout', 'upgrade the wiki layout', 'migrate the knowledge base structure', or knowledge-resume surfaces a schema_version < 0.0.8 migration nudge."
allowed-tools: Read, Bash, Glob
---

# Knowledge Index

Two related operations on a bound knowledge base, both delegating to the locked
renderers (`sub_index.py`, `root_index.py`) so index-shaping logic lives in one
place:

- **Rebuild** — deterministically (re)render the seven per-type sub-indexes
  (`wiki/<type>/index.md`) and the curated root MAP (`wiki/index.md`) from
  current wiki state. Useful after manual page edits, a crashed finalize, or
  any time the indexes look stale. Idempotent: an unchanged wiki re-renders
  byte-identically.
- **Migrate** — converge an EXISTING old-structure wiki (`schema_version <
  0.0.8`) onto the curated layout `knowledge-setup` seeds for new ones:
  control files relocate into `wiki/meta/`, the `overview.md` narrative folds
  into the `index.md` intro, the flat root index splits into root-map +
  per-type sub-indexes, and the schema bumps to `0.0.8`. Dry-run first, always.

The migrate split is the lossy transform — human content could be dropped when
the flat root becomes a MAP. It is delegated to `root_index.py render`, which
carries every `MACHINE-OWNED:PORTAL-LEADIN` span and every human
(non-sentineled) lead-in verbatim and drops only the per-page bullets (they
relocate into the sub-indexes). The migrator never re-implements the split.

## When to run

- The user asks to rebuild, regenerate, or refresh the wiki indexes
- `knowledge-resume` surfaced a `schema_version < 0.0.8` migration nudge
- A base predates the curated layout and the user wants the new structure
- After hand-editing wiki pages, to re-derive the indexes from disk

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer
  `knowledge-setup` instead.
- Mid-pipeline (a `knowledge-finalize` run is active) — finalize renders the
  same indexes itself; a concurrent rebuild just churns the lock.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--migrate` | No | Run the layout migration instead of a plain rebuild. Dry-run by default. |
| `--apply` | No | With `--migrate`: actually relocate files, render, and bump the schema. Without it the migrator stages proposals and reports, touching nothing live. |

## Workflow

### 1. Resolve the base

1. Resolve `knowledge_root`: `--knowledge-root` if set, else
   `cogni-knowledge/<knowledge-slug>/` relative to the working directory.
2. Read the binding:
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.
3. Extract `wiki_path` from the binding. Read
   `<wiki_path>/.cogni-wiki/config.json` for `schema_version` (abort with the
   config error when unreadable — the wiki is the authoritative validator).
4. Resolve the wiki-engine scripts dir (vendored-first):
   ```bash
   . "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
   WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest config_bump.py) \
     || abort "cogni-wiki wiki-ingest scripts not found (vendored copy missing)"
   ```

### 2a. Rebuild mode (default)

Requires `schema_version >= 0.0.8` — on an older base, say so and route to
`--migrate` instead (a rebuild against a flat layout would render sub-indexes
the old root never links to).

Render the seven sub-indexes, then the root (the root's count-links read the
same theme assignment the sub-indexes use, so order matters only for
readability — both are idempotent):

```bash
for t in concepts entities learnings questions sources summaries syntheses; do
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
    --type "$t" --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
done
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/root_index.py" render \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

Each call returns the standard envelope. Collect per-type `changed` /
`theme_count` from `data` and report one summary line per type plus the root:
`<type>: <n> theme(s), <changed|unchanged>`. Any `success: false` → surface
the error and stop (the remaining renders are independent; report what landed).

### 2b. Migrate mode (`--migrate`)

**Dry-run first, always.** Run the migrator without `--apply`:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-layout.py" \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

- `action: noop` / `reason: already_migrated` → tell the user the base is
  already on the curated layout; offer a plain rebuild if indexes look stale.
- Otherwise present the preview: the planned control-file moves
  (`data.control_files[].action`), the overview-fold verdict
  (`data.overview_fold.action`), and the staged proposal paths
  (`data.staged[].path` — `.cogni-wiki/*-proposed.md`). These staged files are
  the **content diff surface**: point the user at the staged root MAP so they
  can diff it against the live `wiki/index.md` before committing.

Then, only when the user passed `--apply` (or confirms after the preview):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-layout.py" \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" --apply
```

Report from the envelope: control files moved, the overview fold, the rendered
indexes, and `schema_after: 0.0.8`. A second `--apply` is a clean no-op, so
re-running after an interruption is safe.

### 3. Summary

End with a compact block: base title + wiki path, the mode that ran, per-type
render results (or the migration actions), and the schema version. For a
migrate dry-run, the last line names the apply command so the user can execute
the preview.

## Edge cases

- **Wiki path broken in the binding** — the config read in Step 1.3 surfaces
  it; abort with the error rather than guessing at a wiki root.
- **Partial prior migration** (control files already under `wiki/meta/`, or a
  manual move) — the migrator converges: already-relocated files report
  `skip_already_migrated`, everything else proceeds.
- **Pre-0.0.5 base** — the migrator refuses (`schema_version` predates the
  per-type-dirs layout); route to cogni-wiki's own `migrate_layout.py` first.
- **No themes / empty base** — renders header-only indexes; harmless and
  idempotent.
