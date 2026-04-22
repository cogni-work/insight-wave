# Author Mode — Build a New Taxonomy From Scratch

Use this reference when the user picked `author` in Phase 1 — none of the 8 bundled templates is close enough to their vertical to be worth cloning. This mode is heavier and more interactive than `clone`: you collect dimensions, categories, products, and search patterns, then scaffold the 7-file bundle into `{PROJECT_PATH}/taxonomy/`.

The bundled `b2b-ict` template is your structural reference throughout — copy its shape, replace its content.

---

## Step 1 — Name and identify

Ask the user for:

- **`type` slug** — kebab-case, e.g. `b2b-logistics`, `b2b-automotive-tier1`, `b2b-legaltech`. This is both the directory name analogue and the value written to `portfolio.json`'s `taxonomy.type`.
- **One-line description** — a sentence that tells a future reader what vertical this taxonomy serves.
- **`industry_match` patterns** — comma-separated keywords that should match this vertical during `portfolio-setup`'s detection step. Pull these from the user's own language: if they say "we do cold-chain pharma logistics", good patterns include `cold chain`, `pharma logistics`, `temperature-controlled distribution`.

---

## Step 2 — Define dimensions

**Dimension 0 is reused verbatim from any bundled template.** It is industry-agnostic: *Provider Profile Metrics* with 6 categories — Financial Scale, Workforce Capacity, Geographic Presence, Market Position, Certifications, Partnership Ecosystem. Read it from `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict/categories.json` (dimension 0 rows) and copy forward. The user should not be asked to redesign this — every vertical needs the same provider-profile signals.

For **dimensions 1–N** (the service dimensions), ask the user for:

- `dimension_name` — e.g. `Fleet & Telematics`, `Cold Chain`, `Customs & Compliance`
- `dimension_slug` — kebab-case of the name

Aim for **5–7 service dimensions**. Fewer than 4 misses coverage; more than 8 gets unwieldy and dilutes the scan's signal. If the user proposes more than 8, ask whether two can be merged or one is really a sub-dimension of another.

---

## Step 3 — Define categories per dimension

For each dimension 1–N, ask the user for **4–10 categories**:

- `id` = `{dimension}.{number}` — auto-numbered within the dimension, starting at 1 (so Dim 1 gets 1.1, 1.2, ...)
- `name` — free text, 2–5 words, title case (e.g. `Route Optimization`, `Cross-Border Customs`)

Fewer than 4 categories per dimension usually means the dimension is too narrow and should be merged. More than 10 usually means there's a sub-structure worth pulling out into its own dimension.

Dimension 0's 6 categories are fixed — do not edit them.

---

## Step 4 — Define the product skeleton

One standard product per dimension 1–N. **Dimension 0 is never a product** — it is a provider-profile dimension, not an offering.

For each dimension 1–N, ask the user for:

- `slug` — kebab-case, defaults to `dimension_slug`
- `name` — title-cased `dimension_name` usually fits
- **One-line description** — what this product means in the user's vertical

These become entries in `product-template.md`. They're the skeleton that `portfolio-scan` maps discovered offerings into.

---

## Step 5 — Generate search-pattern stubs

For each category in dimensions 1–N, auto-generate two query stubs:

- **Marketing**: `"{dimension_name}" "{category_name}" services {vertical_keyword}`
- **Technical docs**: `"{category_name}" documentation OR product page {vertical_keyword}`

Where `{vertical_keyword}` is one of the `industry_match` patterns from Step 1.

Write them into `search-patterns.md` using the section structure the bundled templates use (Phase 1 = company discovery, Phase 2 = provider profile, Phase 3 = per-category queries). Phase 1 and Phase 2 patterns are **copied verbatim from `b2b-ict`** — they are vertical-agnostic discovery patterns.

Tell the user these are **starting-point queries** — they will almost certainly want to tune them once they see the first scan results. Good tuning wisdom: if a category's scan returns too many false positives, add exclusionary terms; if it returns too few hits, drop the strictest constraint.

---

## Step 6 — Write the 7-file bundle

Write all seven files into `{PROJECT_PATH}/taxonomy/`. Structure is canonical — the validator checks for these exact filenames.

| File | How to produce |
|---|---|
| `template.md` | Frontmatter (`type`, `version: 0.1.0`, `dimensions` count, `categories` count, `industry_match`) plus a dimension/category table. Use `$CLAUDE_PLUGIN_ROOT/templates/b2b-ict/template.md` as structural reference — copy the shape, replace dimension/category rows. |
| `categories.json` | Flat array of category objects, one per id. Every entry has `{id, name, dimension}`. Include dimension 0 rows verbatim from `b2b-ict`. |
| `search-patterns.md` | Three sections: Phase 1 (copy from `b2b-ict`), Phase 2 (copy from `b2b-ict`), Phase 3 (the per-category stubs from Step 5). |
| `product-template.md` | Dimension → product table with the skeleton from Step 4. Use `b2b-ict/product-template.md` as structural reference. |
| `cross-category-rules.md` | Start empty with a comment: `# Cross-Category Rules\n\nNo rules yet. Add entries here when you find offerings that legitimately span two categories — e.g. "if offering matches X AND Y, route to category Z".` |
| `provider-unit-rules.md` | Copy from `b2b-ict/provider-unit-rules.md` and tell the user to adapt if their vertical has unusual subsidiary/BU scoping (e.g. logistics multinationals often have many regional legal entities). |
| `report-template.md` | Copy from `b2b-ict/report-template.md`. Rarely needs vertical-specific edits — the scan report shape works across verticals. |

---

## Step 7 — Update `portfolio.json`

Set three fields in the `taxonomy` block:

- `taxonomy.type` — the slug from Step 1
- `taxonomy.source_path` — `"taxonomy/"` (tells the resolver the project-local taxonomy is in use)
- `taxonomy.authored_at` — today's date (YYYY-MM-DD)

Do not set `cloned_from` — that field is only meaningful for `clone` mode.

---

After Step 7, return to SKILL.md's **Validation** section and run `validate-taxonomy.sh`. On any failing check, the user's edits should usually fix it — do not silently repair.
