# Import Mode — Load a Taxonomy From External Input

Use this reference when the user picked `import` in Phase 1 — they have a structured taxonomy definition in hand (JSON, spreadsheet, markdown table, consultancy reference model) and want to load it rather than clone or author from scratch.

The goal is to normalize whatever shape the user provides into the canonical 7-file bundle, filling gaps interactively where the input is missing fields.

---

## Step 1 — Accept the input source

Ask the user for a **local file path**. Supported shapes:

- **JSON** — the richest input. May have `dimensions[]`, `categories[]`, `products[]`, `search_patterns{}`, `industry_match[]`. Read with `Read`; parse with `python3 -c "import json; ..."` if needed.
- **CSV** — typically one row per category with columns like `dimension,category,product,search_query`. Read with `Read`.
- **Markdown table** — similar to CSV. Read with `Read`; parse the rows by splitting on `|`.

If the user hands you a URL or a cloud-drive link, ask them to save it locally first and give you the path — this skill does not fetch remote inputs.

---

## Step 2 — Normalize into the internal shape

Whatever the input format, produce an in-memory structure matching:

```
{
  "type": "<slug>",
  "description": "<one line>",
  "industry_match": ["<keyword>", ...],
  "dimensions": [{"id": <n>, "name": "<string>", "slug": "<kebab>"}, ...],
  "categories": [{"id": "<dim>.<num>", "name": "<string>", "dimension": <n>}, ...],
  "products": [{"slug": "<kebab>", "name": "<string>", "description": "<line>", "dimension": <n>}, ...],  // may be empty
  "search_patterns": {"<category_id>": ["<query>", ...]}  // may be empty
}
```

**Dimension 0 is fixed** — if the input has its own dimension-0, discard it and substitute the canonical Provider Profile Metrics dimension from `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict/categories.json` (rows where `dimension: 0`). Every taxonomy in this plugin uses the same dimension 0.

If the input uses different field names (e.g. `segments` instead of `dimensions`, `topics` instead of `categories`), map them during normalization and tell the user what you mapped from/to so they can confirm.

---

## Step 3 — Fill gaps for missing products

If the input has no `products[]` (or fewer products than dimensions), prompt the user for each missing dimension 1–N. Ask for the same fields as author mode Step 4:

- `slug` — kebab-case, defaults to `dimension_slug`
- `name` — title-cased `dimension_name` usually fits
- One-line description

Do not invent products — ask the user, because product names encode the user's own vertical language.

---

## Step 4 — Fill gaps for missing search patterns

If the input has no `search_patterns{}` (or coverage gaps — not every `category_id` has at least one query), generate stubs using the author-mode template:

- **Marketing**: `"{dimension_name}" "{category_name}" services {vertical_keyword}`
- **Technical docs**: `"{category_name}" documentation OR product page {vertical_keyword}`

Flag the generated stubs to the user so they know which queries came from them versus which were auto-stubbed. The validator checks coverage (every category has ≥1 pattern) but does not judge quality — the user should tune stubs after the first scan.

---

## Step 5 — Write the 7-file bundle

Write all seven canonical files into `{PROJECT_PATH}/taxonomy/`. This step is identical to author mode Step 6 — follow that file list exactly.

One detail specific to import: if the input lacked `cross-category-rules` or `provider-unit-rules`, copy them from `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict/` as starter content. Tell the user these are generic fallbacks and may need vertical-specific adaptation.

---

## Step 6 — Update `portfolio.json`

Set in the `taxonomy` block:

- `taxonomy.type` — the slug from the input (or from Step 2 if you had to invent one)
- `taxonomy.source_path` — `"taxonomy/"`
- `taxonomy.imported_at` — today's date (YYYY-MM-DD)
- `taxonomy.imported_from` — the original input file path, so the user has a provenance record

Do not set `authored_at` or `cloned_from` — those belong to the other modes.

---

After Step 6, return to SKILL.md's **Validation** section and run `validate-taxonomy.sh`. Import mode tends to hit the `search_patterns_coverage` check most often (incomplete inputs) — fix by regenerating stubs for the missing category ids.
