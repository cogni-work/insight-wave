---
name: wiki-prefill
description: "Prefill a Karpathy-style wiki with curated foundation concept pages — Porter's Five Forces, Jobs-to-be-Done, MECE, Pyramid Principle, OODA, SWOT, BCG Matrix, Value Chain, Lean Canvas, Wardley Mapping, Double Diamond. Foundations carry `foundation: true` in frontmatter; wiki-update refuses to edit them without --force and wiki-lint skips orphan / no-sources / staleness warnings on them. Use this skill whenever the user says 'prefill the wiki', 'seed canonical concepts', 'add foundations', 'wiki prefill', 'pre-fill consulting frameworks', 'set up the textbook concepts', or wants to stop wiki-ingest from creating duplicate pages for canonical material like Porter's Five Forces. wiki-setup also offers to chain into this skill at the end of a fresh setup."
allowed-tools: Read, Bash, AskUserQuestion
---

# Wiki Prefill

Seed a fresh (or existing) wiki with curated `foundation: true` concept
pages so canonical material like Porter's Five Forces, Jobs-to-be-Done, and
MECE has a stable target slug from day one.

Without this skill, every wiki re-derives the same textbook concepts from
whatever source the user happens to drop in `raw/` first. Each derivation
takes an `entries_count` slot, dilutes the wiki's signal, and produces a
slightly-different page than the last wiki for the same framework.
Prefilling solves this once: foundations are terminal pages
(`wiki-update` refuses without `--force`, `wiki-lint` skips orphan /
no-sources / staleness warnings on them) and `wiki-ingest`'s slug-collision
check now routes a Porter's-Five-Forces source to the foundation page
instead of overwriting it.

The plugin-side library lives at `${CLAUDE_PLUGIN_ROOT}/foundations/`.
Today's curated set is documented in `${CLAUDE_PLUGIN_ROOT}/foundations/README.md`;
the community can extend it via PR.

## When to run

- User explicitly asks to prefill, seed, or pre-load foundations / canonical
  concepts / consulting frameworks
- `wiki-setup` Step 6 chained into this skill at the end of a fresh setup
- An existing wiki has accumulated duplicate pages for canonical material
  and the user wants to stop the bleeding by establishing the foundation
  slugs (existing duplicates get retired manually via `wiki-update --reason
  retire` afterwards — out of scope here)

## Never run when

- The wiki has not been set up — check for `.cogni-wiki/config.json`; if
  missing, offer `wiki-setup` first
- The user wants to add a non-canonical concept — that's `wiki-ingest`'s
  job; foundations are reserved for textbook material that does not need
  per-wiki synthesis

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Absolute or relative path to the wiki directory. Defaults to walking upward from the current working directory until a `.cogni-wiki/config.json` is found. Required when `--list` is **not** set; optional with `--list` (in which case the script just enumerates the plugin-side library). |
| `--filter` | No | One of `all` (default), `consulting`, `product`, `strategy`. Limits the copy to foundations tagged with the matching keyword — see `${CLAUDE_PLUGIN_ROOT}/foundations/README.md` §"Filter sets". |
| `--list` | No | Print the available foundations under the chosen `--filter` and exit. No wiki is touched. Use this to review the set before committing. |
| `--dry-run` | No | Compute the plan without writing any page or bumping `entries_count`. Pair with `--filter` to preview the subset. |

## Workflow

### 1. Locate the wiki

If `--wiki-root` was passed, use it. Otherwise walk upward from the current
working directory to find the nearest `.cogni-wiki/config.json`. If none
found, stop and offer to run `wiki-setup`.

`--list` mode does not require a wiki; if `--wiki-root` is also absent the
script just enumerates the plugin-side library.

### 2. Resolve the filter set

Parse `--filter`. The mapping (also documented in
`${CLAUDE_PLUGIN_ROOT}/foundations/README.md`):

| Filter | Includes |
|--------|----------|
| `all` (default) | Every file under `${CLAUDE_PLUGIN_ROOT}/foundations/*.md` |
| `consulting` | Foundations tagged `consulting` (Five Forces, MECE, Pyramid Principle, SWOT, BCG Matrix, Value Chain, Double Diamond) |
| `product` | Foundations tagged `product` (Jobs-to-be-Done, Lean Canvas, Double Diamond) |
| `strategy` | Foundations tagged `strategy` (Five Forces, OODA, SWOT, BCG Matrix, Value Chain, Wardley Mapping) |

A foundation can belong to multiple sets via its `tags:` field — `Porter's
Five Forces` appears in both `consulting` and `strategy` for example.

### 3. Surface the plan to the user

Run with `--list --filter <set>` and show the user:

- The number of foundations in the chosen set
- The slugs and titles
- Whether each one already exists in the target wiki (the script returns
  `skipped_existing: [...]` on the apply pass; in list mode you can grep
  `wiki/concepts/` directly)

For autonomous runs (the user said "just prefill the consulting set"), skip
the confirmation and proceed to Step 4.

### 4. Apply the prefill

Invoke:

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-prefill/scripts/prefill_foundations.py \
    --wiki-root <wiki-root> \
    --filter <set>
```

The script:

- Walks `${CLAUDE_PLUGIN_ROOT}/foundations/*.md`, filtered by tag.
- For each foundation whose slug does not already exist under
  `<wiki-root>/wiki/concepts/`, atomically writes the page with the
  literal `{{PREFILL_DATE}}` placeholder substituted with today's ISO date.
- Existing-slug pages are silently skipped (idempotent re-run).
- The existence-check + write loop runs inside `_wiki_lock(wiki_root)` so a
  concurrent `wiki-ingest` from a separate session can't sneak the same
  slug in between the check and the write.
- After the loop, bumps `.cogni-wiki/config.json::entries_count` by the
  number of pages copied via the locked `config_bump.py --delta N`. A
  bump failure does **not** unwind the page writes — the pages are on
  disk and reconcilable via `wiki-lint --fix=entries_count_drift`.

Surface `data.copied[]`, `data.skipped_existing[]`, `data.failed[]`, and
`data.entries_count_delta` to the user.

### 5. Append to `wiki/log.md`

```
## [{YYYY-MM-DD}] prefill   | filter={set} — copied N foundations
```

The `prefill` operation prefix parallels the existing verb grammar
(`ingest`, `update`, `lint`, `health`, `synthesis`, `migrate`) and keeps
the log greppable by operation type. SCHEMA.md's log-format enum will
broaden to include `prefill` at the next schema bump; until then,
existing wikis treat the prefix as informational and `wiki-lint` does
not flag unknown verbs.

### 6. Report to the user

In ≤5 sentences:
- Which foundations were copied and how many were skipped (already
  existed)
- Where the pages live (`wiki/concepts/<slug>.md`)
- Reminder: `wiki-update` refuses to edit `foundation: true` pages
  without `--force`, and `wiki-lint` skips orphan / no-sources /
  staleness warnings on them — they are terminal by design
- Suggested next action: drop a real source in `raw/` and run
  `wiki-ingest` to add domain-specific knowledge that links into the
  foundations

## Output

- N new files under `<wiki-root>/wiki/concepts/` (one per copied
  foundation)
- One appended line in `wiki/log.md`
- `.cogni-wiki/config.json::entries_count` bumped by N (locked)

## Failure modes

- **Pre-migration wiki** — the script hard-fails with the standard
  migration nudge. Run `migrate_layout.py --apply` first.
- **Foundations dir missing** — only happens for plugin packagers; the
  shipped plugin always includes the dir.
- **Slug collision with a non-foundation page** — the slug is silently
  skipped, no overwrite. The user can retire the duplicate via
  `wiki-update --reason retire` and re-run prefill.
- **`config_bump.py` failure** — the page writes stay; `entries_count`
  drift is reconcilable via `wiki-lint --fix=entries_count_drift`.

## Foundation contract

Every file under `${CLAUDE_PLUGIN_ROOT}/foundations/`:
- `type: concept`
- `foundation: true` in frontmatter
- 200–500 char body with a "When to reach for it" line
- One authoritative external URL in `sources:`
- No `[[wikilinks]]` in the body — foundations are terminal; cross-refs
  live on the pages that link into them
- `created:` / `updated:` use the `{{PREFILL_DATE}}` placeholder so the
  staleness clock starts at prefill time

See `${CLAUDE_PLUGIN_ROOT}/foundations/README.md` for the full contract
and the procedure for adding a new foundation.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `${CLAUDE_PLUGIN_ROOT}/foundations/README.md` — foundation contract,
  filter sets, and how to extend the library
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-prefill/scripts/prefill_foundations.py`
  — the locked, idempotent copy script
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-update/SKILL.md` — the
  `foundation: true` refusal contract on the update side
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py` — the
  orphan / no-sources / staleness skip on the lint side
