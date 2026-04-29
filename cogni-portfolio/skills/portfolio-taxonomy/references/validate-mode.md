# Validate Mode — Check the Taxonomy Before Scan

Use this reference when the user picked `validate` in Phase 1 — they want to confirm the project-local taxonomy is structurally sound *before* dispatching a `portfolio-scan` (which would otherwise fail the same checks at Phase 0 Step 5a and abort 150+ web searches against a broken bundle).

The script (`validate-taxonomy.sh`) already exists and is the same one `portfolio-scan` runs internally. Validate mode just surfaces it as an interactive, human-readable entry point so the user can iterate on edits without driving a full scan to discover problems.

---

## Step 1 — Run the validator

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/validate-taxonomy.sh" "${PROJECT_PATH}"
```

Parse the JSON. The `data.checks[]` array contains every check's `name`, `ok`, and `detail`. The `data.summary` block reports `total / passed / failed`. The script exits 0 on full pass, 1 on any failure.

---

## Step 2 — On full pass, confirm and stop

If `success: true`, tell the user:

> All N checks passed. Your taxonomy is ready for `cogni-portfolio:portfolio-scan`.

Optionally run inspect mode for a one-line "current shape" follow-up (`{type} v{version} — D dimensions, C categories, all categories covered`) if the user wants the structural picture too. Otherwise stop — there is no further action.

---

## Step 3 — On any failure, render findings with fix hints

Print each failed check by name with its `detail` and a concrete fix hint. Use the table below as your routing guide — every check has a known set of failure modes and a clear next move.

| Check | What it enforces | Common cause of failure | Fix hint to surface |
|---|---|---|---|
| `canonical_files` | All 7 canonical files present | A file was deleted or renamed; an author/import session was interrupted before all files were written | Re-run author or import mode (the bundle scaffold is generated end-to-end), or copy the missing file from a bundled template if the user only lost one specific file |
| `template_frontmatter` | `template.md` has YAML frontmatter with `type`, `version`, `dimensions`, `categories` | Hand-edit accidentally broke frontmatter; missing one of the four required keys | Open `template.md`, restore the four keys (use `b2b-ict/template.md` as a structural reference); after edit-taxonomy.sh runs, the `dimensions` and `categories` counts are auto-synced — for hand-edits, point at inspect mode's `counts` output to fill them in |
| `categories_json` | Valid non-empty JSON array, every entry has `id`, `name`, `dimension` | JSON parse error after a hand-edit; an entry missing one of the three required keys | Run a syntax check (`python3 -m json.tool taxonomy/categories.json`); for missing keys, hand-add them or rerun `edit-taxonomy.sh` to recreate the row cleanly |
| `category_id_format` | Every id matches `^\d+\.\d+$` | Import mode passed through an external shape that uses ids like `1a`, `1-1`, or `cat.1.1` | Hand-edit `categories.json` to convert ids to dotted-number form; nothing in the rest of the bundle depends on the original id, so renumbering is safe (but if you've already scanned, downstream features may carry the old id in `taxonomy_mapping` — see `portfolio-lineage`) |
| `search_patterns_coverage` | Every category id appears at least once in `search-patterns.md` | A category was added without a matching search-pattern stub; an id was renumbered without updating the patterns; an import had partial pattern coverage | Run `edit-taxonomy.sh add-category` (which auto-appends a stub) for missing ids, or hand-edit `search-patterns.md` to add a Phase 3 block referencing each uncovered id. Inspect mode's `coverage.uncovered_category_ids` lists exactly which ones are missing |
| `portfolio_json_source_path` | `portfolio.json` has `taxonomy.source_path: "taxonomy/"` | The clone/author/import script didn't run to completion; the field was hand-removed | Hand-edit `portfolio.json` to set `"taxonomy": {"source_path": "taxonomy/"}` (the resolver needs this to pick up the project-local bundle over the bundled template) |
| `product_skeleton` | `product-template.md` declares at least one product (markdown table row, bullet, or JSON example with a kebab-case slug) | Author mode skipped Step 4; import didn't have product data and the user didn't fill the gap | Hand-edit `product-template.md` to add at least one product row matching one of your service dimensions (use `b2b-ict/product-template.md` as a reference). For new dimensions added via `add-dimension`, the script appends a starter row automatically |

---

## Step 4 — After a fix, re-run validate

After the user reports they have addressed a finding, re-run `validate-taxonomy.sh`. Loop until `success: true`. Each iteration should mention which checks moved from `false` to `true` so the user can see progress; surface any new failures (rare, but possible if a fix introduced a different problem).

---

## Notes for the calling skill

- Validate is non-destructive. It is safe to run repeatedly, and it is the natural next step after any edit, import, or hand-edit session.
- After every successful edit, `edit-taxonomy.sh` already runs the validator internally and rolls back on failure — so a clean exit from edit mode means validate would also pass right now. Re-running validate after edit is redundant for sanity, but a useful "check my work" affirmation when the user is doing a sequence of edits.
- If validate fails repeatedly on the same check after multiple fix attempts, surface that to the user and offer to re-clone or re-author the taxonomy as a fresh start. Some bundles get into states where targeted fixes are slower than scaffold-then-port.
