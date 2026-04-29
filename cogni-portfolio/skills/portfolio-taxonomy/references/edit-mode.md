# Edit Mode — Structural Edits With a Safety Net

Use this reference when the user picked `edit` in Phase 1 — they want to add, rename, split, or remove a category, or add or rename a service dimension, on a taxonomy that already exists. Hand-editing the four bundled files in sync is fragile (any mismatch breaks the next scan), so this mode goes through `edit-taxonomy.sh`, which treats every edit as a transaction: snapshot → apply → validate → restore-on-failure.

The script does the synchronized writes; this reference covers what each verb means, what the user has to provide, and what to tell them after each edit.

---

## The transaction contract

Every edit goes through the same four-step pipeline:

1. **Snapshot** `{PROJECT_PATH}/taxonomy/` to `{PROJECT_PATH}/taxonomy.bak/` (replacing any prior backup so the contract stays one-step).
2. **Apply** the canonical edit to `categories.json`, then mechanically sync `template.md` frontmatter counts, append search-pattern stubs for new ids, and (for new dimensions) append a product-template row.
3. **Validate** the post-edit taxonomy via `validate-taxonomy.sh`.
4. **On any failure** (Python error, validator failure), restore `taxonomy/` from the snapshot and return the error to the user. The user's project never lands in a half-edited state.

Tell the user this contract up front when they pick edit mode — it is what makes edit safe to use.

---

## Step 1 — Pick the verb and gather inputs

Use `AskUserQuestion` to route the user to one of the six verbs. Most users coming in want `add-category`; the others are less common but the same machinery serves them.

| Verb | Inputs the user must provide | Effect |
|---|---|---|
| `add-category` | `<dimension>` (1–N), `<name>` | Appends a new category in the named dimension; auto-numbers the id; appends a search-pattern stub |
| `rename-category` | `<category_id>` (e.g. `1.3`), `<new_name>` | Updates `name` in `categories.json`; leaves the id and all markdown alone |
| `split-category` | `<category_id>`, `<new_name>` | Creates a sibling category in the same dimension; original is kept; appends a stub |
| `remove-category` | `<category_id>` | Removes the row from `categories.json`; strips matching search-pattern lines |
| `add-dimension` | `<name>` | Appends a new service dimension with one placeholder category; appends a product-template row; user is expected to follow up with `add-category` to flesh it out |
| `rename-dimension` | `<dimension>`, `<new_name>` | Updates `dimension_name` and `dimension_slug` for every category in that dimension; replaces slug occurrences in `product-template.md` |

**Dimension 0 is reserved.** All six verbs refuse Dimension 0 — it is fixed by design (Provider Profile Metrics is industry-agnostic and shared across all taxonomies). If the user asks to edit it, route them to author or import mode if they really need to start over, otherwise explain the constraint.

---

## Step 2 — Run the script

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/edit-taxonomy.sh" "${PROJECT_PATH}" "${VERB}" "${ARGS[@]}"
```

Parse the JSON output. On `success: false`, the taxonomy was already restored — surface the error verbatim, mention that the snapshot at `taxonomy.bak/` is intact for reference, and let the user retry with corrected inputs. On success, the `data.edit` block contains the verb-specific payload (new ids, renamed counts, etc.) and `data.snapshot` points at the backup directory.

---

## Step 3 — Tell the user what happened and what to look at

Each verb has a follow-up the user should know about — none of them are silently "all done":

- **`add-category`** — A search-pattern stub was appended in `search-patterns.md` under a "Stubs added by edit-taxonomy.sh" heading. Tell the user the auto-stubs are starting points and almost always need tuning after the first scan ("if a category returns false positives, add exclusionary terms; if too few hits, drop the strictest constraint" — same wisdom as author mode Step 5).
- **`rename-category`** — `categories.json` is updated, but `template.md`'s prose tables and `search-patterns.md` may still display the old name. The id is unchanged, so nothing breaks, but the user may want to grep-and-update the prose for cosmetic alignment.
- **`split-category`** — Same as `add-category`. The original category was kept; if the user actually meant "rename and forget the old", they should follow up with `remove-category` on the source id.
- **`remove-category`** — Lines containing the removed id token were stripped from `search-patterns.md`. If the id appeared inside prose paragraphs (rare), those would have been removed too; recommend the user spot-check `search-patterns.md` for orphaned section headers.
- **`add-dimension`** — A placeholder category was created so `validate-taxonomy.sh` doesn't choke on a dimension with zero categories. The next user move should be 4–10 follow-up `add-category` calls under the new dimension. The product-template row is a starter — the user should rewrite the description in their own vertical's language.
- **`rename-dimension`** — All categories in the dimension now reflect the new `dimension_name` / `dimension_slug`. Slug occurrences in `product-template.md` were replaced; the dimension's prose intro in `template.md` (if any) was left alone since substring-replacing free text is risky. Tell the user to spot-check `template.md` for the old name.

---

## Step 4 — Always run inspect after a non-trivial edit

Edit's success payload is terse on purpose. After any edit, run `inspect-taxonomy.sh` and re-render the tree so the user sees the after-state — especially the new id, updated counts, and any new gap that the edit might have surfaced (a renamed dimension whose categories now don't match a hand-tuned search pattern, for example). Inspect is cheap; running it after every edit keeps the user oriented.

---

## What edit deliberately does NOT do

- It does not rewrite `cross-category-rules.md` or `provider-unit-rules.md` — those are user-authored prose and out of scope for mechanical synchronization. Tell the user to revisit them if a removed/renamed category appears in either file.
- It does not migrate already-discovered features whose `taxonomy_mapping` references a renamed/removed category id. That is a downstream concern handled by `portfolio-lineage` (entity-level drift) rather than this script. If the user has run `portfolio-scan` already, warn them that a structural taxonomy edit may invalidate previously-mapped features, and recommend re-running scan to refresh.
- It does not delete the snapshot. `taxonomy.bak/` stays in place after a successful edit so the user has a one-step undo (`rm -rf taxonomy/ && mv taxonomy.bak/ taxonomy/`). Mention this once, the first time edit runs in a session.
