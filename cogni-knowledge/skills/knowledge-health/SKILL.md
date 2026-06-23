---
name: knowledge-health
description: "Run a read-only structural health check on a cogni-knowledge base — page/link/schema integrity plus entries-count and claim drift for the bound wiki. Use this skill whenever the user says 'check knowledge health', 'knowledge health', 'is my knowledge base healthy', 'audit the knowledge base structure', 'knowledge integrity check', 'health-check the wiki', or wants a structural verdict on a bound base without running the research pipeline."
allowed-tools: Read, Bash, Glob
---

# Knowledge Health

Give the user a fast, grounded **structural health verdict** for a cogni-knowledge base — the page/link/schema integrity of the bound wiki, plus entries-count drift and claim drift. This is the standalone analog of `cogni-wiki:wiki-health`, computed **natively on the vendored `health.py` engine** (resolved vendored-first via `resolve_wiki_scripts()`), so a Karpathy base is health-checkable with no `cogni-wiki` plugin installed.

This skill is **fully read-only** — `health.py` writes nothing (it emits JSON to stdout only). The health-check log line the retired `cogni-wiki:wiki-health` dispatch used to append was a workflow step of that skill, not of the engine; the native path has no append step.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember the wiki-engine boundary — cogni-knowledge computes the health verdict on the **vendored** wiki-health engine, it does not dispatch `cogni-wiki:wiki-health`.

## When to run

- User asks for a health check, integrity check, or structural verdict on a knowledge base
- Right after a bulk `knowledge-ingest` or a `knowledge-finalize` run, to confirm the base is still structurally sound
- Before sharing or publishing a base, as a pre-flight gate
- Proactively when a session opens in a directory containing `.cogni-knowledge/binding.json` and the user asks "is everything OK?"

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer `knowledge-setup` instead.

## How it relates to neighbours

- `knowledge-resume` runs the **same** `health.py` engine for its one-line verdict but layers a full status overlay (deposited projects, next action). Use `knowledge-health` when you want the structural detail *only*, without the binding overlay.
- `knowledge-lint` is the **semantic** pass (stale pages, claim drift, reverse-link repair with `--fix`). `knowledge-health` is the cheap structural gate; `knowledge-lint` is the tokenful curation pass. Run health first; reach for lint when health flags drift you want to fix.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base to check. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |

## Workflow

### 0. Pre-flight

**Required engine.** This skill computes the health verdict on the **vendored** wiki-health engine — cogni-knowledge ships a byte-identical copy in-tree under `scripts/vendor/cogni-wiki/`, so a bound base shows its health without cogni-wiki installed. The `cogni-wiki` install is only a fallback layout. Probe both so the skill aborts cleanly here rather than failing mid-skill:

```
# vendored-first: the in-tree wiki-health scripts are self-contained
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-health/scripts" && WIKI_OK=yes || WIKI_OK=no

# fallback: an installed cogni-wiki sibling / marketplace cache (legacy layout)
if [ "$WIKI_OK" = "no" ]; then
  probe_plugin() {
    local plugin="$1" skill="$2"
    test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
    for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
      [ -f "$d" ] && return 0
    done
    return 1
  }
  probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
fi
```

If `WIKI_OK` is `no`, abort:

> cogni-knowledge's vendored wiki-health scripts are missing and no `cogni-wiki`
> install was found. Reinstall cogni-knowledge, then retry.

This probe is the early-abort gate only — Step 2's `resolve_wiki_scripts` is the authoritative resolver for the actual `health.py` path; keep the two vendored-first precedences in sync.

### 1. Resolve the knowledge root and read the binding

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract from the binding: `knowledge_slug`, `knowledge_title`, `wiki_path`. Note that `wiki_path` is read straight from the binding here and **not pre-validated** at this step — `health.py` in Step 2 is the authoritative validator of `wiki_path` / `config.json` (it is what surfaces a missing or broken wiki path, per the Edge-cases section below).

4. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. Mismatch → abort.

### 2. Run the health check natively (vendored `health.py`)

Resolve the vendored `wiki-health` scripts dir vendored-first (the same `resolve_wiki_scripts` posture `knowledge-resume` / `knowledge-dashboard` use), then invoke `health.py` directly — no `Skill` dispatch:

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_HEALTH_SCRIPTS=$(resolve_wiki_scripts wiki-health health.py) \
  || abort "cogni-wiki wiki-health scripts not found (vendored copy missing)"
```

Run the vendored `health.py` against the bound wiki (it resolves `_wikilib` itself; fully read-only — JSON to stdout, no file writes):

```bash
python3 "${WIKI_HEALTH_SCRIPTS}/health.py" --wiki-root "<wiki_path>"
```

On a curated-layout base (`schema_version >= 0.0.8`) the engine additionally asserts the layout shape:

- `curated_layout_violation` (error) — a control file (`log.md` / `context_brief.md` / `open_questions.md`) at the flat `wiki/` root, a missing `wiki/meta/`, or an `overview.md` still carrying the narrative machine block. Repair: `knowledge-lint --fix=misplaced_control_files`.
- `missing_subindex` (warning) — a sub-indexed type dir with pages but no `index.md`. Repair: `knowledge-index`.
- `schema_version_lag` (warning) — the base's `config.json` `schema_version` trails the engine's current expected structure (`ENGINE_SCHEMA`), so it predates a curated-layout contract the engine now produces. Repair: `knowledge-index --migrate`.
- `structural_drift` (warning) — a machine-owned curated front-door region a completed phase should have populated is still on its bootstrap state: the `index.md` `OVERVIEW-NARRATIVE` block still carries the finalize placeholder, or a `ROOT-LINKS` span has no theme-scoped deep links. Repair: re-run `knowledge-finalize` (or `knowledge-index`) to regenerate the front door. These two structural-drift classes are read-only and fail-soft, never fire on a pre-0.0.8 base, and move the verdict `OK -> WARN` (never a hard error).
- `render_engine_lag` (warning) — the base's curated indexes were rendered by an engine version behind the installed one (its stamped `last_rendered_engine_version` trails `ENGINE_RENDER_VERSION`), or carry no engine stamp at all, so a shipped index-renderer upgrade has not been re-rendered into this base. Repair: run `knowledge-index` to rebuild the indexes (which re-stamps the engine version). Read-only and fail-soft, same posture as `schema_version_lag`; never fires on a pre-0.0.8 base.
- Per-type sub-indexes themselves are exempt from `entries_count` and the page walk; pre-0.0.8 bases are untouched by these assertions.

Parse the JSON envelope `{success, data, error}`. On `success: false` (e.g. `<wiki_path>/.cogni-wiki/config.json` absent), surface `error` and stop. Otherwise capture `data.errors`, `data.warnings`, and `data.stats` (`pages_audited`, `entries_count_config`, `entries_count_actual`, `entries_count_drift`, `claim_drift_count`).

### 3. Compose the health verdict

Print a compact verdict block:

- **Header.** `<knowledge_title>` (`<knowledge_slug>`) — `<wiki_path>`
- **Verdict.** **OK** when `data.errors` is empty, else `<N> error(s) — <first error class(es)>`.
- **Stats.** One line: `<pages_audited> pages audited · entries config/actual <config>/<actual>` + ` · entries drift <±N>` when `entries_count_drift != 0` + ` · claim drift <N>` when `claim_drift_count > 0`.
- **Errors.** When `data.errors` is non-empty, list each (cap 20, "and N more" for the rest) — each as its class + the affected page/link.
- **Warnings.** When `data.warnings` is non-empty, list each the same way (cap 10).
- **Next action.** One line by state:
  - Verdict OK, no drift → "Structurally sound. Run `knowledge-lint --knowledge-slug <slug>` for the semantic pass (stale pages, claim drift) when you want it."
  - Entries/claim drift present, no hard errors → "Drift detected — run `knowledge-lint --knowledge-slug <slug> --fix=all` to reconcile, then re-run health."
  - Hard errors → "Fix the structural errors above before composing or sharing. `knowledge-lint --knowledge-slug <slug> --fix=all` repairs the mechanical classes; the rest need a manual look." A `curated_layout_violation` repairs via `knowledge-lint --knowledge-slug <slug> --fix=misplaced_control_files`.
  - `missing_subindex` warning present (any verdict state) → "Re-render the per-type sub-indexes via `knowledge-index`."
  - `schema_version_lag` warning present → "Schema behind the engine — run `knowledge-index --migrate` to converge the curated layout."
  - `structural_drift` warning present → "Curated front door degraded (placeholder overview / empty root-links) — re-run `knowledge-finalize` (or `knowledge-index`) to regenerate it."

## Edge cases

- **Binding exists but `wiki_path` no longer does.** `health.py` returns `success: false` (missing `.cogni-wiki/config.json`). Surface its error and stop with a clear message.
- **`health.py` fails for another reason.** Surface its `error` verbatim; do not fabricate a verdict.

## Out of scope

- Does NOT run the semantic `wiki-lint` pass — that is `knowledge-lint`, a deliberate tokenful pass the user invokes separately.
- Does NOT dispatch `cogni-wiki:wiki-health` — the verdict is computed natively on the vendored engine.
- Does NOT write to the binding or the wiki — fully read-only (`health.py` emits JSON to stdout, nothing else).

## Output

A health verdict block printed to the user. No files written.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — delegation boundary (wiki health computed natively on the vendored engine)
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-health/scripts/health.py` — the vendored health engine invoked in Step 2
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
