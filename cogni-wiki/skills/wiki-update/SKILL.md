---
name: wiki-update
description: "Revise an existing Karpathy-style wiki page when knowledge has changed — shows the diff before writing, requires a source citation for every new claim, and sweeps related pages for now-stale statements that the update contradicts. Use this skill whenever the user says 'update the wiki', 'update page X', 'revise my wiki', 'wiki update', 'the wiki is out of date on X', 'fix the contradictions from the lint report', or when a new source ingest would collide with an existing page (wiki-ingest hands control here). Also trigger when wiki-lint reports a contradiction and the user asks to reconcile it."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Wiki Update

Revise a page in `wiki/pages/` because knowledge has changed, because a contradiction was reported, or because a new source refines a claim. This is the other half of the compounding loop — ingests add, updates refine. Together they keep the wiki live.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once per session to re-anchor on the diff-before-write and citation discipline.

## When to run

- User explicitly asks to update, revise, or fix a page
- `wiki-ingest` detected that the source collides with an existing page and handed control here
- `wiki-lint` reported a contradiction the user wants reconciled
- User says "the wiki says X but actually Y — fix it"

## Never run when

- The target page does not exist — offer `wiki-ingest` instead
- The user wants to append a new claim with no source — stop and ask for the source first
- The change is cosmetic only (typo fix) — just Edit the page directly without going through this skill, and note the edit in the page's `updated:` field

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--page` | Yes | Slug of the page to update, or a fuzzy title that resolves to one slug |
| `--reason` | Yes | Why the update is happening: `new-source`, `contradiction`, `refinement`, `retype`, `retire` |
| `--source` | Conditional | Required when `--reason new-source` — path to a file in `raw/` or URL |
| `--related-sweep` | No | `yes` (default) / `no` — whether to check related pages for stale statements the update contradicts |

## Workflow

### 1. Locate the wiki and the page

Walk upward to find `.cogni-wiki/config.json`. Resolve `--page` to an actual file in `wiki/pages/`. If the slug doesn't exist, attempt a title match against frontmatter `title:` fields across all pages. If still no match, stop.

### 2. Read the current page and the source

- Read the full page text including frontmatter
- If `--reason new-source`, read the new source fully (file, URL, or paste — persist pastes to `raw/` first)
- If `--reason contradiction`, read the lint report that surfaced the contradiction AND the other page involved

### 3. Surface the proposed change BEFORE writing

State in plain prose:

1. **What is currently in the page** — quote the specific paragraph or claim being changed
2. **What the new claim is** — with the source that supports it
3. **What will be preserved** — the parts of the page that stay exactly as-is
4. **What will be deleted** — if anything is being removed, say so explicitly
5. **What the diff looks like** — show the before/after side-by-side or as a unified diff

Show this to the user. For autonomous runs, still emit the synthesis in the response but proceed without waiting for explicit confirmation.

This is the diff-before-write discipline. It is the cogni-wiki equivalent of `git diff` + manual inspection before commit.

### 4. Apply the update via Edit

Use the Edit tool (not Write) to preserve unchanged content byte-for-byte. For each planned change:

- Replace the exact `old_string` with the new `new_string`
- Update the page's `updated:` frontmatter field to today's ISO date
- If the update adds a source, append it to the `sources:` list — never replace existing sources unless the old source is being explicitly retracted
- If the update changes the page `type`, say so in the diff and justify the retype

**Citation rule**: every new factual claim the update adds must link to a source. Either an inline `[../raw/file.pdf]` reference or a `[[wikilink]]` to another page (which in turn must cite a source). If the user cannot produce a source, the update stops. Unsourced claims erode the provenance chain that distinguishes this wiki from unverifiable notes — every page traces to raw/, and that contract holds only when updates also cite their evidence.

### 5. Sweep related pages (when `--related-sweep yes`)

When the update adds, removes, or reshapes `[[wikilinks]]`, honour the SCHEMA `R1_bidirectional_wikilink` rule — every new forward `[[B]]` added on this page should be matched by a reverse `[[A]]` on B. The sweep step is the natural place to apply that: when updating page A introduces `[[B]]`, the candidate page B is included in the sweep below, and the diff-before-write pass adds the reverse sentence on B in the same session. `wiki-lint`'s `reverse_link_missing` check is the safety net for omissions; the in-skill sweep is the primary path. See `<wiki-root>/SCHEMA.md` §"Forward → reverse link contract".

For every page that contains a `[[wikilink]]` to the page being updated, plus every page in the updated page's `related:` frontmatter field, plus every page that shares ≥2 tags with the updated page:

1. Read the candidate page
2. Look for claims that the update directly contradicts or renders stale
3. If found: either update the related page in the same session (going through diff-before-write for each) or add a `## Stale (YYYY-MM-DD)` marker at the top of the candidate so the next `wiki-lint` catches it

Never silently propagate contradictions. The sweep either resolves them or marks them for future resolution.

### 6. Handle special reasons

- **`--reason retire`**: do not delete the page. Instead, set `status: retired`, prepend a `## Retired (YYYY-MM-DD) — replaced by [[new-slug]]` note, and leave the body intact. Dangling `[[wikilinks]]` to retired pages still resolve, which is the point.
- **`--reason retype`**: change `type:` and rewrite body structure to match the new type conventions. A `note` → `concept` promotion typically means condensing loose observations into a structured definition.

### 7. Append to the log

```
## [{YYYY-MM-DD}] update | {slug} — {reason}
```

### 8. Update `.cogni-wiki/config.json`

Do not increment `entries_count` (update is not a create). Leave `last_lint` untouched.

### 9. Report to the user

Tell the user, in ≤5 sentences:
- Which page was updated and why
- How many related pages were swept, and how many were also modified
- What the next recommended action is (often: `wiki-lint` if this was a contradiction fix)

## Output

- One edited file in `wiki/pages/` (the target page)
- Possibly N additional edited files (from the related sweep)
- One appended line in `wiki/log.md`
- `.cogni-wiki/config.json` date fields updated if applicable

## Golden rules

1. **Diff before write, every time.** Show the change before applying it.
2. **Citations required.** Every new claim links to a source.
3. **No silent deletes.** Content removal is explicit and justified in the diff.
4. **Retire, don't delete.** Pages that become obsolete get `status: retired`, not `rm`.
5. **Sweep related pages.** A contradiction fixed in one place but not the other is a lie told twice.
6. **Update, not Write.** Use the Edit tool to preserve unchanged bytes — never rewrite a page in full unless the entire body is being replaced.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/update-discipline.md` — worked example of a contradiction fix
