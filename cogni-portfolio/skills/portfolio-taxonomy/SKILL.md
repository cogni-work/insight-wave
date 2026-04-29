---
name: portfolio-taxonomy
description: |
  Own, customize, and maintain the project-local taxonomy that classifies
  offerings for a cogni-portfolio project — clone a bundled template, author
  from scratch, import from an external reference model, inspect what's
  there, edit categories or dimensions safely, validate before scan, or
  export the customized taxonomy as a reusable template. Use whenever the
  user wants to customize the taxonomy, clone a standard taxonomy for
  editing, create a new taxonomy, override the bundled template, add or
  rename dimensions or categories, tweak search patterns, import a taxonomy
  JSON, view the current taxonomy, check if the taxonomy is valid, save the
  taxonomy for reuse in another project, or says "my industry isn't in the
  templates", "my vertical isn't supported", "rename a dimension", "show me
  my taxonomy", "is my taxonomy valid", or "save this taxonomy for another
  project". Project-local: the customized taxonomy lives inside the
  portfolio project, survives plugin updates, and overrides the bundled
  template during scan and setup resolution.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Portfolio Taxonomy

## Core Concept

**Plugin root resolution.** Bash invocations below resolve the plugin root inline as `${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}` — the first call works whether or not the harness injects `$CLAUDE_PLUGIN_ROOT`. Keep the inline form in every call; do not strip it.

`cogni-portfolio` ships 8 industry taxonomy templates — `b2b-ict`, `b2b-saas`, `b2b-fintech`, `b2b-healthtech`, `b2b-martech`, `b2b-industrial-tech`, `b2b-professional-services`, `b2b-opensource`. Each one is a 7-file bundle that drives `portfolio-scan` (search patterns, category tables) and maps discovered offerings to products and features via the product-template contract.

A taxonomy works best when it matches the industry you are scanning. Often the bundled 8 are close enough; sometimes they are not. This skill is how the user takes ownership of the taxonomy — clones a bundled one to edit, authors a new one, imports one from an external reference model, or maintains an existing project-local taxonomy through inspect, edit, validate, and export operations. The customized taxonomy lives **inside the portfolio project** at `{PROJECT_PATH}/taxonomy/` — it is not shared across projects (unless explicitly exported), it is not written back to the plugin, and it survives plugin updates because it is part of the project's own data.

**Resolver precedence** (used by `cogni-portfolio:portfolio-scan` Phase 0 and `cogni-portfolio:portfolio-setup` Step 5):

1. If `{PROJECT_PATH}/taxonomy/` exists → use it (project-local wins)
2. Else if `portfolio.json` has `taxonomy.type` → load `$CLAUDE_PLUGIN_ROOT/templates/{type}/`
3. Else run the industry-match fallback against bundled templates

Project-local ownership means the user can safely edit `{PROJECT_PATH}/taxonomy/template.md`, `categories.json`, `search-patterns.md`, and the rest without worrying about plugin updates reverting their changes.

## When NOT to use

Do not edit the bundled templates under `$CLAUDE_PLUGIN_ROOT/templates/*` directly — plugin updates will overwrite those edits. This skill exists so customization lives *inside the project*. If the user is inside the plugin directory tweaking `templates/b2b-ict/categories.json`, stop them and route to this skill instead.

Also not the right skill for: defining individual features or products (use `cogni-portfolio:features` / `cogni-portfolio:products`), or for running the scan itself (use `cogni-portfolio:portfolio-scan`).

---

## Prerequisites

A cogni-portfolio project must exist — i.e. `{PROJECT_PATH}/portfolio.json` is readable. If it does not, tell the user to run `cogni-portfolio:portfolio-setup` first and stop.

---

## Workflow

### Phase 0: Locate the Project

1. Find the target project. If the user did not name one, resolve the active project the same way other project-scoped skills do — `find . -path "*/cogni-portfolio/*/portfolio.json" -type f`, and if multiple match, ask via `AskUserQuestion`.
2. Set `PROJECT_PATH` to the directory containing `portfolio.json`.
3. Read `portfolio.json`. Note whether `taxonomy.type` is set and whether `{PROJECT_PATH}/taxonomy/` already exists — both affect the mode choice.

### Phase 1: Select Mode

Present the seven modes via `AskUserQuestion`, including the current state so the user knows what they are working against. The first three are creation modes (used when there is no project-local taxonomy yet, or when the user is starting over); the next four are management modes (used on an existing project-local taxonomy). If `{PROJECT_PATH}/taxonomy/` does not exist, the management modes are unavailable — only offer them when the bundle is present.

| Mode | When to pick | What it does |
|---|---|---|
| `clone` | "I want the `b2b-ict` taxonomy but with a few categories of my own" — the closest bundled template is good enough to start from | Copies one bundled template into `{PROJECT_PATH}/taxonomy/`, updates `portfolio.json` to reference the clone, and tells the user exactly which files to edit |
| `author` | "None of the 8 bundled templates is close — I want to define mine from scratch" | Interactively collects dimensions, categories, product skeleton, and search patterns, scaffolds the 7-file bundle directly into `{PROJECT_PATH}/taxonomy/` |
| `import` | "I already have a taxonomy definition (JSON, spreadsheet, consultancy model) — load it in" | Accepts an external structured input, validates against the template schema, scaffolds into the 7-file shape |
| `inspect` | "Show me what my taxonomy looks like right now" — read-only, the natural starting point for any management session | Pretty-prints the resolved taxonomy as a tree (dimensions → categories), reports counts and search-pattern coverage, and surfaces structural gaps |
| `edit` | "Add a category", "rename this dimension", "remove a category" — synchronized structural edits | Snapshots the bundle, applies the canonical edit to `categories.json` + frontmatter + search patterns + product template in one transaction, runs validation, and rolls back on any failure |
| `validate` | "Is my taxonomy ready for scan?" | Runs the same validator that `portfolio-scan` Phase 0 runs — six structural checks — and surfaces failures with concrete fix hints, no scan dispatched |
| `export` | "Save my taxonomy as a reusable template" — for another project, a colleague, or a contribution back to the plugin | Packages the 7-file bundle into a portable folder shaped like `cogni-portfolio/templates/{type}/`, stripping project-local provenance |

If `{PROJECT_PATH}/taxonomy/` **already exists** and the user picks `clone` / `author` / `import`, warn that the existing project-local taxonomy will be replaced (use `--force` on `clone-taxonomy.sh`, or scaffold-and-overwrite for the other two) — and offer `inspect` first so the user sees what is at stake.

### Phase 2a: Clone a Bundled Template

This is the most common path and is short enough to keep inline.

1. **Pick the base template.** List the 8 bundled templates by reading `$CLAUDE_PLUGIN_ROOT/templates/*/template.md` frontmatter — present `type`, short description, dimension count, and category count. Use `AskUserQuestion` with the list.

2. **Run the clone script:**

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/clone-taxonomy.sh" "${PROJECT_PATH}" "${BASE_TYPE}"
   ```

   The script copies `$CLAUDE_PLUGIN_ROOT/templates/{BASE_TYPE}/*` into `{PROJECT_PATH}/taxonomy/` and updates `portfolio.json`'s `taxonomy` block with `source_path: "taxonomy/"`, `cloned_from: "{BASE_TYPE}"`, and `cloned_at: <today>`. It refuses to overwrite an existing project-local taxonomy unless `--force` is appended — offer that explicitly before passing it.

3. **Parse the script's JSON output.** On `success: false`, surface the error verbatim and stop. On success, report the file count and the destination path.

4. **Guide the edit.** The user now owns the taxonomy. Tell them which files they typically edit:

   | File | What to change |
   |---|---|
   | `template.md` | Dimension names (frontmatter), industry_match patterns, tone of the intro copy |
   | `categories.json` | Add/rename/remove categories; keep `id` in `dimension.number` format |
   | `search-patterns.md` | Tweak web search queries per category (the scan engine reads this verbatim) |
   | `product-template.md` | If you renamed a dimension, update the matching product slug + description here |
   | `cross-category-rules.md` | Add rules for offerings that legitimately span two categories |
   | `provider-unit-rules.md` | Who counts as an in-scope subsidiary/BU for scans |
   | `report-template.md` | Rarely needs editing — the scan report shape is usually fine as-is |

   **Keep categories.json and template.md consistent** — every category id that appears in one must appear in the other. A mismatch will confuse the scan's Phase 3 search and Phase 5 status assignment. If the user wants safe synchronized edits later, route them back to this skill and pick `edit` mode rather than hand-editing all four files.

5. **Close the loop.** Tell the user: "Taxonomy cloned to `{PROJECT_PATH}/taxonomy/`. Edit the files above, then run `cogni-portfolio:portfolio-scan` — it will now use your customized taxonomy."

### Phase 2b: Author a New Taxonomy From Scratch

Author mode is heavier and more interactive than clone — it collects dimensions, categories, products, and search patterns, then scaffolds the 7-file bundle. The full step-by-step is in a reference file so this SKILL.md stays scannable.

**Read `references/author-mode.md` and follow its 7 steps.** It covers: naming the taxonomy, defining dimensions (including why Dimension 0 is reused verbatim), defining categories per dimension, building the product skeleton, auto-generating search-pattern stubs, writing the 7-file bundle using `b2b-ict` as structural reference, and updating `portfolio.json`. When done, return here for the Validation section below.

### Phase 2c: Import From External JSON

Import mode accepts a structured taxonomy definition (JSON, CSV, markdown table) and normalizes it into the canonical 7-file bundle, filling gaps (missing products, missing search patterns) interactively.

**Read `references/import-mode.md` and follow its 6 steps.** It covers: accepting the input source, normalizing into the internal shape (including why dimension 0 is substituted from the bundled template), filling gaps for missing products and search patterns, writing the bundle, and updating `portfolio.json` with provenance. When done, return here for the Validation section below.

### Phase 2d: Inspect the Resolved Taxonomy

Inspect is read-only and is the natural starting point for any management session — it shows the user exactly what they own before they decide whether to edit, validate, or export.

**Read `references/inspect-mode.md` and follow its 4 steps.** It covers: running `inspect-taxonomy.sh` against the project, rendering the dimension/category tree with search-pattern coverage glyphs, surfacing structural gaps, and offering the next action based on what the gap surface shows. Inspect is safe to run at any time and is reused by edit and validate modes for "before/after" framing.

### Phase 2e: Edit the Taxonomy Safely

Edit mode performs synchronized structural changes (add / rename / split / remove a category, add or rename a service dimension) through a transaction: snapshot → apply → validate → restore-on-failure. The user never lands in a half-edited state, even if the validator catches a problem the script didn't anticipate.

**Read `references/edit-mode.md` and follow its 4 steps.** It covers: the six edit verbs and their inputs, running `edit-taxonomy.sh` with the right arguments, parsing the verb-specific success payload, and the per-verb follow-up the user should know about (auto-stub tuning, where the snapshot lives, what edit deliberately does not do). After edit completes, run inspect mode to render the after-state.

### Phase 2f: Validate Before Scan

Validate mode surfaces `validate-taxonomy.sh` as a standalone, human-readable entry point — the same script `portfolio-scan` Phase 0 runs internally, but interactive instead of scan-blocking.

**Read `references/validate-mode.md` and follow its 4 steps.** It covers: running the validator, rendering the success path, mapping each failed check to a concrete fix hint, and the iterate-until-clean loop after the user makes corrections. Validate is non-destructive and safe to run repeatedly.

### Phase 2g: Export as a Reusable Template

Export packages the project-local bundle into a portable folder shaped like `cogni-portfolio/templates/{type}/`, ready to drop into another project's `taxonomy/` directory or contribute back to the plugin's bundled set.

**Read `references/export-mode.md` and follow its 4 steps.** It covers: choosing the output directory, deciding whether to override the type slug, running `export-taxonomy.sh` (which validates the source first and refuses to export a broken bundle), and tailoring the closing message to whether the user is reusing, contributing back, or archiving. Export is read-only on the source — the project's own taxonomy is never touched.

---

## Validation

After any of the three creation modes (clone / author / import) completes — and after any edit mode session — run the validation script:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/validate-taxonomy.sh" "${PROJECT_PATH}"
```

The script returns JSON `{"success": bool, "data": {...}}` and exits 0 on full pass, 1 on any failure. It enforces six checks — parse the output and surface results to the user:

| Check | What it enforces |
|---|---|
| `canonical_files` | All 7 canonical files present (`template.md`, `categories.json`, `search-patterns.md`, `product-template.md`, `cross-category-rules.md`, `provider-unit-rules.md`, `report-template.md`) |
| `template_frontmatter` | `template.md` has YAML frontmatter with `type`, `version`, `dimensions`, `categories` fields |
| `categories_json` | `categories.json` parses as a non-empty array where every entry has `id`, `name`, `dimension` |
| `search_patterns_coverage` | Every category id in `categories.json` appears at least once in `search-patterns.md` (catches mismatches that would silently drop search coverage) |
| `portfolio_json_source_path` | `portfolio.json` has `taxonomy.source_path: "taxonomy/"` so the resolver picks up the project-local taxonomy |
| `product_skeleton` | `product-template.md` declares at least one product (markdown table, bullet list, or JSON example with a kebab-case slug) |

On any failure: report the failing check's `detail` verbatim to the user and suggest which file to fix — `references/validate-mode.md` has a fix-hint table you can quote from. Do not silently repair — the user's edit intent might differ from the fix. Offer to re-run the script after the user confirms edits.

On success: confirm with the user and tell them the taxonomy is ready for `cogni-portfolio:portfolio-scan`.

Note: `edit-taxonomy.sh` already runs the validator after every edit and rolls back on failure, so an edit that returned success is also validation-clean. This Validation section applies to creation modes and to manual hand-edits.

---

## What Happens Next

Once the project-local taxonomy is in place:

- `cogni-portfolio:portfolio-setup` Step 5 — if re-run, will pick up the project-local taxonomy and skip the bundled-template match.
- `cogni-portfolio:portfolio-scan` Phase 0 Step 5 — resolves to `{PROJECT_PATH}/taxonomy/` first (see [portfolio-scan SKILL.md](../portfolio-scan/SKILL.md) for the resolver order).
- `portfolio-web-researcher` agent — reads `{PROJECT_PATH}/taxonomy/search-patterns.md` instead of the plugin-bundled file.
- `cogni-portfolio:portfolio-dashboard` and `cogni-portfolio:portfolio-communicate` — group features by the user's custom dimensions automatically because they read from `portfolio.json` + discovered features, which already carry the right `taxonomy_mapping`.

No code changes in the downstream consumers are needed — they already resolve the template from a single path, and that path now points project-local.

---

## Variables Reference

| Variable | Description | Example |
|---|---|---|
| `PROJECT_PATH` | Absolute path to the portfolio project directory | `/Users/me/work/cogni-portfolio/acme-corp` |
| `BASE_TYPE` | Slug of the bundled template used for `clone` mode | `b2b-ict` |
| `TYPE` | Slug of the user's taxonomy (`clone` keeps BASE_TYPE; `author`/`import` is user-chosen) | `b2b-logistics` |
| `OUTPUT_DIR` | Absolute path where `export` mode writes the portable bundle | `~/work/colleague-project/taxonomy-export` |
