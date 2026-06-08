---
name: knowledge-prefill
description: "Seed a cogni-knowledge base with curated foundation concept pages — Porter's Five Forces, Jobs-to-be-Done, MECE, Pyramid Principle, OODA, SWOT, BCG Matrix, Value Chain, Lean Canvas, Wardley Mapping, Double Diamond. Wraps the vendored prefill_foundations.py engine (resolved vendored-first), so a Karpathy base is prefillable with no cogni-wiki plugin installed. Foundations carry `foundation: true`; knowledge-update refuses to edit them without --force. Use this skill whenever the user says 'prefill the knowledge base', 'seed canonical concepts', 'add foundations', 'knowledge prefill', 'pre-fill consulting frameworks', or wants to opt into the canonical foundation pages knowledge-setup deliberately skips."
allowed-tools: Read, Bash, AskUserQuestion
---

# Knowledge Prefill

Seed a bound knowledge base with curated `foundation: true` concept pages so canonical material like Porter's Five Forces, Jobs-to-be-Done, and MECE has a stable target slug from day one. This is the standalone analog of `cogni-wiki:wiki-prefill`, computed **natively on the vendored `prefill_foundations.py` engine** (resolved vendored-first via `resolve_wiki_scripts()`), so a Karpathy base is prefillable with no `cogni-wiki` plugin installed. It **does not dispatch `cogni-wiki:wiki-prefill`**.

**Why this is a deliberate opt-in.** `knowledge-setup` intentionally passes `--skip-prefill-prompt` to `cogni-wiki:wiki-setup` — a cogni-knowledge base has its own opinionated domain seeding (the first `knowledge-plan` → … → `knowledge-finalize` run seeds the base domain-specifically), and layering the generic canonical foundations on top would clutter it. `knowledge-prefill` is the **native opt-in** so a user who skipped foundations at setup time — or who wants the textbook concepts as stable link targets later — can add them without installing cogni-wiki.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember the wiki-engine boundary — cogni-knowledge runs the prefill on the **vendored** engine, it does not dispatch `cogni-wiki:wiki-prefill`.

## When to run

- User explicitly asks to prefill, seed, or pre-load foundations / canonical concepts / consulting frameworks into the bound base
- A base set up with `--skip-prefill-prompt` (the cogni-knowledge default) and the user now wants the canonical foundations as stable link targets
- An existing base has accumulated duplicate pages for canonical material and the user wants to establish the foundation slugs

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer `knowledge-setup` instead.
- The user wants to add a non-canonical concept — that is the inverted pipeline's / `knowledge-ingest-source`'s job; foundations are reserved for textbook material that needs no per-base synthesis.

## How it relates to neighbours

- `knowledge-setup` deliberately skips the canonical foundations (`--skip-prefill-prompt`); this skill is the opt-in that adds them later.
- `knowledge-update` refuses to edit the `foundation: true` pages this skill seeds without `--force` — they are terminal.
- `knowledge-lint` skips orphan / no-sources / staleness warnings on foundations and surfaces their count.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base to prefill. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--filter` | No | One of `all` (default), `consulting`, `product`, `strategy`. Limits the copy to foundations tagged with the matching keyword. |
| `--list` | No | Print the available foundations under the chosen `--filter` and exit. No page is written. Use to review the set before committing. |
| `--dry-run` | No | Compute the plan without writing any page or bumping `entries_count`. Pair with `--filter` to preview the subset. |

## Workflow

### 0. Pre-flight

**Required engine.** This skill runs the prefill on the **vendored** wiki-prefill engine — cogni-knowledge ships a byte-identical copy in-tree under `scripts/vendor/cogni-wiki/`, so a bound base is prefillable without cogni-wiki installed. The `cogni-wiki` install is only a fallback layout. Probe both so the skill aborts cleanly here rather than failing mid-skill:

```
# vendored-first: the in-tree wiki-prefill scripts are self-contained
test -d "${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-prefill/scripts" && WIKI_OK=yes || WIKI_OK=no

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

> cogni-knowledge's vendored wiki-prefill scripts are missing and no `cogni-wiki`
> install was found. Reinstall cogni-knowledge, then retry.

This probe is the early-abort gate only — Step 2's `resolve_wiki_scripts` is the authoritative resolver for the actual `prefill_foundations.py` path; keep the two vendored-first precedences in sync.

### 1. Resolve the knowledge root and read the binding

1. Resolve `knowledge_root`:
   - If `--knowledge-root` is set, use it.
   - Otherwise, `knowledge_root = cogni-knowledge/<knowledge-slug>/` (relative to the current working directory).

2. Read the binding:
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
       --knowledge-root <knowledge_root>
   ```
   On `success: false`, abort and offer `knowledge-setup`. Do not auto-create.

3. Extract from the binding: `knowledge_slug`, `knowledge_title`, `wiki_path`.

4. Validate the binding's `knowledge_slug` matches `--knowledge-slug`. Mismatch → abort.

(`--list` mode is the only exception — it touches no wiki, so the binding read is informational. You may still run it to confirm the base before listing.)

### 2. Run the prefill natively (vendored `prefill_foundations.py`)

Resolve the vendored `wiki-prefill` scripts dir vendored-first (the same `resolve_wiki_scripts` posture `knowledge-lint` / `knowledge-health` use), then invoke `prefill_foundations.py` directly — no `Skill` dispatch:

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_PREFILL_SCRIPTS=$(resolve_wiki_scripts wiki-prefill prefill_foundations.py) \
  || abort "cogni-knowledge's vendored wiki-prefill scripts are missing and no cogni-wiki install was found. Reinstall cogni-knowledge, then retry."
```

The vendored engine derives its `FOUNDATIONS_DIR` and `CONFIG_BUMP_SCRIPT` from its own in-tree location, so no `--foundations-dir` override is needed — the foundations library ships alongside the vendored scripts.

Build the invocation from the parameters. **Default is a wet apply** (idempotent — existing foundation slugs are skipped):

```bash
python3 "${WIKI_PREFILL_SCRIPTS}/prefill_foundations.py" --wiki-root "<wiki_path>" --filter <filter>
```

Map the user's flags through verbatim:

- `--filter=<all|consulting|product|strategy>` → pass `--filter <value>` (the engine validates the choice; `all` copies every foundation).
- `--list` → pass `--list` (read-only; enumerates the plugin-side library without touching the wiki).
- `--dry-run` → pass `--dry-run` (computes the plan without writing or bumping `entries_count`).

Parse the JSON envelope `{success, data, error}`. On `success: false`, surface `error` and stop. Otherwise capture `data.available[]`, `data.copied[]`, `data.skipped_existing[]`, `data.failed[]`, and `data.entries_count_delta`.

### 3. Append to the log

On a wet apply (not `--list` / `--dry-run`), append one line to `<wiki_path>/wiki/log.md`:

```
## [{YYYY-MM-DD}] prefill   | filter={filter} — copied N foundations
```

### 4. Report to the user

In ≤5 sentences:

- Which foundations were copied and how many were skipped (already existed).
- Where the pages live (`<wiki_path>/wiki/concepts/<slug>.md`).
- Reminder: `knowledge-update` refuses to edit `foundation: true` pages without `--force` — they are terminal by design.
- Suggested next action: run the inverted pipeline (`knowledge-plan` → …) to add domain-specific knowledge that links into the foundations.

## Edge cases

- **`--list` with no wiki.** The engine enumerates the plugin-side library without a wiki root; the binding read is informational in this mode.
- **`config_bump.py` failure.** The page writes stay on disk; `entries_count` drift is reconcilable via `knowledge-lint --fix=entries_count_drift`.
- **Slug collision with a non-foundation page.** The slug is silently skipped, no overwrite.

## Out of scope

- Does NOT dispatch `cogni-wiki:wiki-prefill` — the prefill is computed natively on the vendored engine.
- Does NOT add domain-specific pages — that is the inverted pipeline / `knowledge-ingest-source`.
- Does NOT write to the binding.

## Output

- N new files under `<wiki_path>/wiki/concepts/` (one per copied foundation), one appended `wiki/log.md` line, and a locked `entries_count` bump (on a wet apply). Read-only under `--list` / `--dry-run`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — delegation boundary (prefill computed natively on the vendored engine)
- `${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/wiki-prefill/scripts/prefill_foundations.py` — the vendored prefill engine invoked in Step 2
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
