# Export Mode — Package the Taxonomy as a Reusable Template

Use this reference when the user picked `export` in Phase 1 — they have a project-local taxonomy they're proud of and want to reuse in another project, share with a colleague, or contribute back as a new bundled template. Export packages the 7-file bundle into a portable folder shaped exactly like `cogni-portfolio/templates/{type}/`, so a downstream `clone-taxonomy.sh` or a hand-copy into another project's `taxonomy/` directory consumes it without any further translation.

The script does the copy and the strip-and-rewrite of provenance fields; this reference covers what gets stripped, what gets preserved, and where the user typically points the output.

---

## Step 1 — Pick the output directory

Ask the user where they want the portable bundle to land. Common answers:

- **A staging folder for another project** — e.g. `~/work/colleague-project/taxonomy-export/`. They will copy it into the colleague's `cogni-portfolio/{slug}/taxonomy/` directly.
- **A pull-request branch of cogni-portfolio** — e.g. `~/insight-wave/cogni-portfolio/templates/b2b-logistics/`, if they're contributing a new bundled template back to the plugin. In that case, also ask for the type slug (next step) since this is the directory name the plugin's resolver will use.
- **A shared workspace** — e.g. `~/Library/CloudStorage/.../taxonomy-archive/{slug}/`, for personal reuse across multiple projects.

If the output directory already exists, the script refuses without `--force`. Surface that explicitly and ask the user before passing `--force`.

---

## Step 2 — Decide whether to override the type slug

The exported `template.md` keeps whatever `type:` slug was already declared in the project's bundle, which is usually correct. Override the slug when:

- The user is contributing back as a new bundled template and the existing slug collides with one of the 8 already shipped (`b2b-ict`, `b2b-saas`, `b2b-fintech`, `b2b-healthtech`, `b2b-martech`, `b2b-industrial-tech`, `b2b-professional-services`, `b2b-opensource`).
- The original project cloned from a bundled template and never renamed it — so the bundle still carries the parent's slug, which would shadow the original on a downstream consumer's `clone-taxonomy.sh` lookup.

Pass `--type <slug>` to rewrite only the `template.md` frontmatter; the script does not rewrite occurrences of the slug elsewhere in the bundle (`product-template.md`, `search-patterns.md`) because those are user-authored prose and substring-replacing them is risky. If the slug appears as label text inside those files, the user should grep-and-update after export.

---

## Step 3 — Run the script

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/export-taxonomy.sh" "${PROJECT_PATH}" "${OUTPUT_DIR}" [--type <slug>] [--force]
```

The script first runs `validate-taxonomy.sh` against the source taxonomy. **A broken taxonomy refuses to export** — that is intentional: the user would otherwise ship a bundle that fails validation in the next consumer's project. If validation fails, surface the validator's findings the same way validate mode does and route the user to fix the issues first.

On a clean validation, the script copies the 7 canonical files, strips provenance fields from the exported `template.md` frontmatter, optionally rewrites the type slug, and reports the output directory + exported type back as JSON.

---

## What gets stripped

The script removes these frontmatter keys from the exported `template.md` so the bundle is portable — they make sense only inside the project that produced the export:

- `cloned_from` — points at the bundled template the source project cloned from
- `cloned_at`, `authored_at`, `imported_at` — project-specific timestamps
- `imported_from` — local file path to the original input source

Everything else in `template.md` (type, version, dimensions count, categories count, industry_match, the prose intro, dimension/category tables) is preserved verbatim.

The other six files (`categories.json`, `search-patterns.md`, `product-template.md`, `cross-category-rules.md`, `provider-unit-rules.md`, `report-template.md`) are copied byte-for-byte. If the user wants to scrub them — e.g. removing the company name from a search-pattern that was tuned against the project's own scan — that is a manual post-export step.

---

## Step 4 — Tell the user what to do with the bundle

Tailor the closing message to the answer in Step 1:

- **Reuse in another project** — Tell the user to copy the output directory into the destination project's root, renaming it from `<output_dir>` to `taxonomy/`. Then run `cogni-portfolio:portfolio-taxonomy` in the destination project — pick `keep existing`, run `validate`, and they're scan-ready.
- **Contribute back as a bundled template** — The output directory is already shaped like `cogni-portfolio/templates/{type}/`. The user opens a PR adding the directory plus a one-line entry in any docs that enumerate the bundled set. The plugin's resolver picks it up automatically.
- **Personal archive** — No further action — the bundle is portable and can be cloned into any future project via the workflow above.

---

## Notes for the calling skill

- Export is read-only on the source. The project's `taxonomy/` directory is never touched.
- Export is independent of the snapshot/restore machinery in edit mode. `taxonomy.bak/` is not exported (the script copies only the 7 canonical files, ignoring the backup directory).
- The script's `--force` flag overwrites the output directory but never the source. If the user re-exports with `--force` to update a previously-shared bundle, the new copy is byte-identical to the source taxonomy (minus the stripped frontmatter keys) — there is no merge or diff machinery built in. Diffing is a future capability (see plan G5).
