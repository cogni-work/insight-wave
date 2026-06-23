---
name: knowledge-index
description: "Rebuild the curated root index + per-type sub-indexes of a cogni-knowledge base on demand, migrate an EXISTING pre-0.0.8 wiki to the curated layout (control files into wiki/meta/, overview folded into the index intro, flat root split into root-map + sub-indexes, schema 0.0.7→0.0.8), or repair drifted machine-owned regions (theme-scoped ROOT-LINKS, schema lag) on a base already >= 0.0.8. Use this skill whenever the user says 'rebuild the index', 'rebuild the knowledge index', 'regenerate the wiki indexes', 'refresh the sub-indexes', 'migrate my wiki to the curated layout', 'upgrade the wiki layout', 'migrate the knowledge base structure', 'repair the knowledge index', 'regenerate the curated front door', 'fix the structural drift', or knowledge-resume / knowledge-health surfaces a schema_version < 0.0.8 migration nudge or a structural-drift verdict."
allowed-tools: Read, Bash, Glob
---

# Knowledge Index

Three related operations on a bound knowledge base, all delegating to the locked
renderers (`sub_index.py`, `root_index.py`) so index-shaping logic lives in one
place:

- **Rebuild** — deterministically (re)render the six per-type sub-indexes
  (`wiki/<type>/index.md`) and the curated root MAP (`wiki/index.md`) from
  current wiki state. Useful after manual page edits, a crashed finalize, or
  any time the indexes look stale. Idempotent: an unchanged wiki re-renders
  byte-identically.
- **Migrate** — converge an EXISTING old-structure wiki (`schema_version <
  0.0.8`) onto the curated layout `knowledge-setup` seeds for new ones:
  control files relocate into `wiki/meta/`, the `overview.md` narrative folds
  into the `index.md` intro, the flat root index splits into root-map +
  per-type sub-indexes, and the schema bumps to `0.0.8`. Dry-run first, always.
- **Repair** — on a base already on the curated layout (`schema_version >=
  0.0.8`), regenerate drifted machine-owned regions keyed on the
  structural-drift class `health.py` emits (not the version floor): a
  theme-scoped `ROOT-LINKS` span stuck on the empty-state sentinel is
  re-rendered via `root_index.py render`, and a lagging `schema_version` is
  reconciled to the current engine schema. Same dry-run-first / `--apply`
  ergonomics as migrate. Idempotent: a non-drifted, current-schema base is a
  `noop`. **Scope boundary:** the script repairs ROOT-LINKS + schema lag; a
  degraded OVERVIEW-NARRATIVE (stuck on the bootstrap placeholder) is
  re-authored by a separate orchestrator step (see 2c) — `root_index.py
  render` carries that block verbatim and never re-authors it.

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
- `knowledge-health` surfaced a `structural_drift` verdict (empty ROOT-LINKS,
  placeholder OVERVIEW-NARRATIVE) or a `schema_version_lag` on a curated base,
  and the user wants the one-command repair (`--repair`)

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
| `--repair` | No | Regenerate drifted machine-owned regions (theme-scoped ROOT-LINKS, schema lag) on an already-curated (`>= 0.0.8`) base, keyed on health's structural-drift class. Dry-run by default. Refuses a pre-0.0.8 base (run `--migrate` first). |
| `--apply` | No | With `--migrate`: actually relocate files, render, and bump the schema. With `--repair`: render the regenerated root MAP under the renderer's lock and reconcile `schema_version` to the current engine schema. Without it the run stages proposals and reports, touching nothing live. |

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
   Also derive `OUTPUT_LANGUAGE` from the binding's
   `research_defaults.output_language` (default `en` on a pre-0.1.1 binding or
   an absent key) — this base's default language, threaded to the sub-index
   render so the engine-owned per-theme lead-in fallback reads in-language on a
   non-English base:
   ```bash
   OUTPUT_LANGUAGE=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py" read \
       --knowledge-root <knowledge_root> 2>/dev/null \
     | python3 -c '
   import json, sys
   env = json.load(sys.stdin)
   data = (env.get("data") or {}) if isinstance(env, dict) else {}
   b = data.get("binding") or {}
   print((b.get("research_defaults") or {}).get("output_language") or "en")
   ' 2>/dev/null || printf en)
   ```
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

Render the six sub-indexes, then the root, then the derived perspectives overlay
(the root's count-links and the overlay's facet counts read the same theme
assignment the sub-indexes use, so order matters only for readability — all are
idempotent):

```bash
for t in concepts entities people questions sources syntheses; do
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
    --type "$t" --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    --lang "$OUTPUT_LANGUAGE"
done
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/root_index.py" render \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/perspectives_index.py" render \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

Each call returns the standard envelope. Collect per-type `changed` /
`theme_count` from `data` and report one summary line per type, the root, and the
perspectives overlay (`facet_count` instead of `theme_count`):
`<type>: <n> theme(s), <changed|unchanged>` / `perspectives: <changed|unchanged>`.
Any `success: false` → surface the error and stop (the remaining renders are
independent; report what landed). The perspectives overlay (`wiki/perspectives.md`)
re-projects the same pages by 5W1H perspective without changing the canonical
layout; it carries forward narrator-authored facet lead-ins and never clobbers a
hand-authored page.

### 2b. Migrate mode (`--migrate`)

**Dry-run first, always.** Run the migrator without `--apply`:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-layout.py" \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

- `action: noop` / `reason: already_migrated` → tell the user the base is
  already on the curated layout; offer a plain rebuild if indexes look stale.
- `action: dry_run` / `reason: relocate_pending` → the base is already curated
  but carries curated-layout repairs (reappeared flat-root control files,
  a missing `wiki/meta/`, or an unfolded overview narrative — see
  `data.conflicts` / `data.meta_missing` / `data.overview_fold_pending`);
  `--apply` runs the relocate-only repair, never the full migration.
- `action: relocated` (after `--apply` on a curated base) → the repair landed;
  report the moved files / recreated meta / fold from the envelope.
- `success: false` with `action: conflicts` → a control file exists at BOTH
  the flat `wiki/` root and `wiki/meta/`; surface the named files — the user
  must compare and remove one copy manually (the engine never auto-clobbers).
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

### 2c. Repair mode (`--repair`)

For a base **already** on the curated layout (`schema_version >= 0.0.8`) whose
machine-owned regions have drifted — the case `knowledge-health` flags as
`structural_drift` / `schema_version_lag` but the `--migrate` path (version-floored)
never reaches. The script repairs two regions; a third (OVERVIEW-NARRATIVE) is an
orchestrator step, below.

**Dry-run first, always.** Run the repair without `--apply`:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-layout.py" \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" --repair
```

- `success: false` (pre-0.0.8 base) → the base is not curated; route to
  `--migrate` first (the error names it). Do not `--apply`.
- `action: noop` / `reason: no_drift_detected` → the curated front door is
  healthy and the schema is current; nothing to repair. Offer a plain rebuild
  if the indexes merely look stale.
- `action: dry_run` / `reason: repair_pending` → present the preview from the
  envelope: `data.drifted_regions[]` (e.g. `ROOT-LINKS`), `data.schema_lagging`,
  and the staged proposal path (`data.staged[].path` — e.g.
  `.cogni-wiki/root-index-proposed.md`). That staged root MAP is the
  **content diff surface**: point the user at it so
  they can diff it against the live `wiki/index.md` before committing.

Then, only when the user passed `--apply` (or confirms after the preview):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-layout.py" \
  --wiki-root "<wiki_path>" --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" --repair --apply
```

Report from the envelope: `data.rendered` (the regenerated ROOT-LINKS region) and
`schema_after` (reconciled to the current engine schema when it lagged). A
non-drifted, current-schema base reaches `action: noop`; a second `--apply` is a
clean no-op, so re-running after an interruption is safe.

**OVERVIEW-NARRATIVE drift is an orchestrator step, not a script flag.**
`health.py` emits **two** `structural_drift` classes: an empty ROOT-LINKS span
(script-repairable here) and an OVERVIEW-NARRATIVE block stuck on the bootstrap
placeholder (`_Overview pending — authored on the first knowledge-finalize
run._`). `--repair` resolves the first; it deliberately does **not** touch the
second, because `root_index.py render` carries the OVERVIEW-NARRATIVE block
verbatim and re-authoring real narrative is an LLM task. When health flags the
OVERVIEW-NARRATIVE region, dispatch the `portal-narrator` agent and splice its
output with `overview_update.py narrative-splice --target-file index.md` (the
same path `knowledge-finalize` Step 10.5 sub-step 3.5 / 3.5.1 uses) **before**
the `--repair --apply` call — so the one run lands both the re-authored narrative
and the regenerated ROOT-LINKS, leaving health clean.

### 2d. SCHEMA.md truth-up (all modes, idempotent)

After a rebuild render, a migrate `--apply`, or a repair `--apply` (never on a
dry run), truth-up
the base's self-describing contract. `SCHEMA.md` is not a locked shared-state
file, so this is an orchestrator-side check-then-overwrite, not a
`migrate-layout.py` phase. Detect by the **positive provenance sentinel** the
knowledge-native seed carries in its subtitle — never by grepping for the
generic dir names, which the seed itself mentions in its intentionally-absent
paragraph and would therefore self-match:

```bash
if [ ! -f "<wiki_path>/SCHEMA.md" ]; then echo "missing"
elif grep -qF 'knowledge-native contract (seeded by cogni-knowledge)' "<wiki_path>/SCHEMA.md"; then echo "current"
else echo "generic"; fi
```

- **`generic`** — the base still carries the generic wiki-setup template
  (declaring `decisions/`/`meetings/`/`notes/` the knowledge pipeline never
  writes, omitting `sources/`/`questions/`/`people/`): overwrite
  `<wiki_path>/SCHEMA.md` with the **knowledge-native seed defined in
  `knowledge-setup` Step 3.5 sub-step (b)** — read that heredoc block and
  apply it with this base's title (`binding.json` `knowledge_title`, read in
  Step 1) and today's date (single canonical copy; never fork the seed text
  here, or the two sites drift and the migrate path converges bases onto a
  stale schema).
- **`current`** — the base is already knowledge-native (a hand-extended
  knowledge-native `SCHEMA.md` still carries the sentinel, so user additions
  are never clobbered): clean no-op.
- **`missing`** — report `no-SCHEMA-found` and seed it the same way as
  `generic`.

### 3. Summary

End with a compact block: base title + wiki path, the mode that ran, per-type
render results (or the migration actions), the schema version, and the
SCHEMA.md truth-up outcome (`overwritten` / `already-current` /
`no-SCHEMA-found → seeded`, or `skipped — dry run` when 2d did not run). For a
migrate or repair dry-run, the last line names the apply command so the user can
execute the preview.

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
