---
name: knowledge-update
description: "Manually curate a single page in a cogni-knowledge base — revise an existing wiki page when knowledge has changed, showing the diff before writing, requiring a source citation for every new claim, and sweeping related pages for now-stale statements the update contradicts. This is the standalone analog of cogni-wiki:wiki-update, resolved against the bound wiki via the binding manifest so a Karpathy base is curatable with no cogni-wiki plugin installed. Use this skill whenever the user says 'update the knowledge base', 'update page X', 'revise the wiki', 'knowledge update', 'the base is out of date on X', 'fix the contradictions from the lint report', 'retire that page', or when a single-source ingest collides with an existing page (knowledge-ingest-source hands control here for diff-before-write)."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Knowledge Update

Revise one page in a bound knowledge base because knowledge has changed, a contradiction was reported, or a new source refines a claim. This is the **manual single-page curation** half of the compounding loop — the inverted pipeline *adds* (ingest → distill → compose → finalize), and `knowledge-update` *refines*. Together they keep a Karpathy base live.

This is the standalone analog of `cogni-wiki:wiki-update`, computed **natively** against the bound wiki — it resolves the wiki root from `.cogni-knowledge/binding.json` and edits the page directly with the `Edit` tool, so a base is curatable with no `cogni-wiki` plugin installed. It **does not dispatch `cogni-wiki:wiki-update`**.

Read `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` once at the start of a session so you remember the wiki-engine boundary — cogni-knowledge curates the page natively (the update logic is pure-LLM, Edit-driven; there is no engine script to resolve), it does not delegate to `cogni-wiki:wiki-update`.

## When to run

- User explicitly asks to update, revise, retire, or fix a page in the bound base
- `knowledge-ingest-source` detected that a single source collides with an existing page and handed control here for diff-before-write (the named endpoint for that cross-skill handoff)
- `knowledge-lint` reported a contradiction or `claim_drift` the user wants reconciled
- User says "the base says X but actually Y — fix it"

## Never run when

- The target directory has no `.cogni-knowledge/binding.json` — offer `knowledge-setup` instead.
- The target page does not exist — offer `knowledge-ingest-source` instead.
- The user wants to append a new claim with no source — stop and ask for the source first.
- The change is cosmetic only (a typo fix) — just `Edit` the page directly and bump its `updated:` field; you do not need this skill's full discipline.
- The target page has `foundation: true` in frontmatter (seeded by `knowledge-prefill`) and the user did **not** pass `--force`. Foundations are terminal pages — canonical textbook concepts (Porter's Five Forces, Jobs-to-be-Done, MECE, …) whose authority derives from the upstream source URL, not per-base synthesis. Stop and surface the refusal verbatim:
  > Page `{slug}` is a foundation (canonical concept seeded by `knowledge-prefill`). Updates require `--force` to preserve the terminal-page contract. Consider `knowledge-ingest-source` for a base-specific page that links into [[{slug}]] instead.

## How it relates to neighbours

- `knowledge-ingest-source` *adds* one source page (with its own diff-before-write dedup on a covering collision); `knowledge-update` *refines* an existing page. The collision handoff flows ingest-source → here.
- `knowledge-lint` *audits* hygiene (stale/drift/reverse links) and repairs the mechanical classes; `knowledge-update` is where a human-judged semantic fix (a contradiction, a refined claim) lands. Run lint to find what is stale; run update to fix what needs prose judgment.
- `knowledge-prefill` seeds the `foundation: true` pages this skill refuses to edit without `--force`.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the knowledge base. Resolves to `cogni-knowledge/<slug>/` unless `--knowledge-root` overrides. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--page` | Yes | Slug of the page to update, or a fuzzy title that resolves to one slug. |
| `--reason` | Yes | Why the update is happening: `new-source`, `contradiction`, `refinement`, `retype`, `retire`. |
| `--source` | Conditional | Required when `--reason new-source` — a URL or a path to a file the new claim is grounded in. |
| `--related-sweep` | No | `yes` (default) / `no` — whether to check related pages for stale statements the update contradicts. |
| `--force` | No | Override the `foundation: true` refusal in "Never run when". Required when the target is a foundation and the upstream canonical source has genuinely shifted. No effect on non-foundation pages. |

## Workflow

### 0. Pre-flight

No engine to resolve — the update is pure-LLM, `Edit`-driven. The only pre-flight is the binding (Step 1): the wiki root and the page both resolve from `.cogni-knowledge/binding.json`, never from a cwd walk (the divergence from `cogni-wiki:wiki-update`, which walks upward from the current directory).

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

### 2. Locate the page under the bound wiki

Resolve `--page` to an actual file under `<wiki_path>/wiki/<type>/<slug>.md` (the cogni-wiki per-type page-dir convention — `concepts/`, `entities/`, `sources/`, `syntheses/`, `questions/`, `notes/`, …). Slugs are globally unique, so `Glob` `<wiki_path>/wiki/*/<slug>.md` resolves the type directory for you. If the slug does not resolve, attempt a title match against frontmatter `title:` fields across `<wiki_path>/wiki/**/*.md`. If still no match, stop and offer `knowledge-ingest-source`.

### 3. Read the current page and the source

- Read the full page text including frontmatter.
- If `--reason new-source`, read the new source fully (URL or file).
- If `--reason contradiction`, read the lint/contradiction finding that surfaced it AND the other page involved.

### 4. Surface the proposed change BEFORE writing

State in plain prose:

1. **What is currently in the page** — quote the specific paragraph or claim being changed.
2. **What the new claim is** — with the source that supports it.
3. **What will be preserved** — the parts of the page that stay exactly as-is.
4. **What will be deleted** — if anything is being removed, say so explicitly.
5. **What the diff looks like** — show the before/after as a unified diff.

Show this to the user. For autonomous runs, still emit the synthesis in the response but proceed without waiting for explicit confirmation.

This is the **diff-before-write** discipline — the cogni-knowledge equivalent of `git diff` + manual inspection before commit.

### 5. Apply the update via Edit

Use the `Edit` tool (never `Write`) to preserve unchanged content byte-for-byte. For each planned change:

- Replace the exact `old_string` with the new `new_string`.
- Update the page's `updated:` frontmatter field to today's ISO date.
- If the update adds a source, append it to the `sources:` list — never replace existing sources unless the old source is being explicitly retracted.
- If the update changes the page `type`, say so in the diff and justify the retype.

**Citation rule**: every new factual claim the update adds must link to a source — an inline source link or a `[[wikilink]]` to another page (which in turn cites a source). If the user cannot produce a source, the update stops. Unsourced claims erode the provenance chain that distinguishes this base from unverifiable notes.

### 6. Sweep related pages (when `--related-sweep yes`)

For every page that contains a `[[wikilink]]` to the page being updated, plus every page in the updated page's `related:` frontmatter, plus every page that shares ≥2 tags with it:

1. Read the candidate page.
2. Look for claims the update directly contradicts or renders stale.
3. If found: either update the related page in the same session (through diff-before-write for each) or add a `## Stale (YYYY-MM-DD)` marker at the top of the candidate so the next `knowledge-lint` catches it.

When the update adds, removes, or reshapes `[[wikilinks]]`, honour the forward → reverse link contract — every new forward `[[B]]` should be matched by a reverse `[[A]]` on B. The sweep is the primary path; `knowledge-lint`'s `reverse_link_missing` repair is the safety net. The locked reverse-link write can be applied via the vendored `backlink_audit.py --apply-plan` that `knowledge-ingest` already calls (the locking is internal to that script); keep this lightweight — never hand-edit `<wiki_path>/wiki/index.md` or another shared-state file directly.

Never silently propagate contradictions. The sweep either resolves them or marks them.

### 7. Handle special reasons

- **`--reason retire`**: do not delete the page. Set `status: retired`, prepend a `## Retired (YYYY-MM-DD) — replaced by [[new-slug]]` note, and leave the body intact. Dangling `[[wikilinks]]` to retired pages still resolve, which is the point.
- **`--reason retype`**: change `type:` and rewrite body structure to match the new type conventions. A `note` → `concept` promotion typically condenses loose observations into a structured definition. (Per the per-type page-dir convention, a retype that changes `type:` should also move the file to the matching `<wiki_path>/wiki/<new-type>/` directory.)

### 8. Append to the log

Append one line to `<wiki_path>/wiki/log.md` (append-only — never a read-modify-write):

```
## [{YYYY-MM-DD}] update | {slug} — {reason}
```

### 9. Do NOT bump entries_count

An update is not a create. Leave `.cogni-knowledge`/`.cogni-wiki` counters untouched.

### 10. Report to the user

In ≤5 sentences: which page was updated and why, how many related pages were swept and how many were also modified, and the next recommended action (often `knowledge-lint` if this was a contradiction fix).

## Golden rules

1. **Diff before write, every time.** Show the change before applying it.
2. **Citations required.** Every new claim links to a source.
3. **No silent deletes.** Content removal is explicit and justified in the diff.
4. **Retire, don't delete.** Obsolete pages get `status: retired`, not `rm`.
5. **Sweep related pages.** A contradiction fixed in one place but not the other is a lie told twice.
6. **Update, not Write.** Use `Edit` to preserve unchanged bytes — never rewrite a page in full unless the entire body is being replaced.

## Out of scope

- Does NOT dispatch `cogni-wiki:wiki-update` — the page is curated natively via the `Edit` tool.
- Does NOT add a new source page — that is `knowledge-ingest-source`.
- Does NOT run the lint/health passes — those are `knowledge-lint` / `knowledge-health`.
- Does NOT bump `entries_count` or write the binding.

## Output

- One edited file under `<wiki_path>/wiki/<type>/` (the target page), possibly N more from the related sweep.
- One appended line in `<wiki_path>/wiki/log.md`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/delegation-contract.md` — delegation boundary (the page is curated natively, not via `cogni-wiki:wiki-update`)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help` — binding read (wiki_path resolution)
