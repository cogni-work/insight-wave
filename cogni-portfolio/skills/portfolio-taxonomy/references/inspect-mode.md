# Inspect Mode — Show the Resolved Taxonomy

Use this reference when the user picked `inspect` in Phase 1 — they want to see what the project-local taxonomy actually contains right now, before deciding whether to edit, validate, export, or leave it alone. Inspect is read-only and is the natural starting point for every other management mode.

The script does the traversal; this reference covers how to present its JSON to the user as a readable tree.

---

## Step 1 — Run the inspector

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/inspect-taxonomy.sh" "${PROJECT_PATH}"
```

Parse the JSON. On `success: false`, surface the error verbatim and stop. On success, the `data` block contains:

- `type`, `version`, `industry_match` from `template.md` frontmatter
- `dimensions[]` — one entry per dimension, each with `id`, `name`, `slug`, `is_service_dimension`, `category_count`, `has_product`, and a `categories[]` array of `{id, name, has_search_pattern}`
- `counts{}` — `dimensions`, `categories`, `service_dimensions`, `service_categories`, plus the frontmatter-declared counts so mismatches surface
- `coverage{}` — `categories_with_search_pattern`, `categories_without_search_pattern`, `uncovered_category_ids[]`, `service_dimensions_with_product`, `service_dimensions_without_product[]`
- `gaps[]` — high-signal flags (uncovered ids, dimensions without products, frontmatter count drift, dimensions or categories outside the 4–10 / 5–7 guidance)

---

## Step 2 — Print the tree

Render `dimensions[]` as a two-level tree. Mark Dimension 0 as `(reserved)` so the user knows it isn't editable. Mark each category with a coverage glyph based on `has_search_pattern`:

```
{type} v{version} — {industry_match[0]}, {industry_match[1]}, ...

  0. Provider Profile Metrics (reserved, 6 categories)
  1. Connectivity Services (8 categories, product: connectivity-services)
     ✓ 1.1  WAN Services
     ✓ 1.2  SASE & Edge Connectivity
     ...
  2. Security Services (7 categories, product: security-services)
     ✓ 2.1  Identity & Access Management
     ✗ 2.2  Endpoint Detection & Response   ← no search pattern
     ...
```

Use `✓` when `has_search_pattern` is true, `✗` when false. If the dimension's `has_product` is false, append ` (no product entry)` to the dimension header so the gap is visible inline.

Skip Dimension 0's per-category breakdown unless the user asks — those six categories are fixed and showing them every time adds noise.

---

## Step 3 — Print the gap surface

After the tree, print the `gaps[]` array as a bulleted list under a `## Gaps` heading. If the array is empty, write a single line: `No structural gaps — the taxonomy is consistent and ready to scan.` This is the single most important UX cue: green light vs amber list.

---

## Step 4 — Offer next actions

Inspect is a launchpad. Based on what `gaps[]` shows, suggest one of:

- **Empty `gaps[]`** — "Your taxonomy is clean. If you want to make changes, run portfolio-taxonomy again and pick `edit`. To save it as a reusable template, pick `export`."
- **Uncovered category ids present** — Suggest `edit` to add search patterns, or hand-edit `search-patterns.md` directly. Name a few of the uncovered ids inline so the user knows where to look.
- **Service dimensions without a product** — Suggest hand-editing `product-template.md` or rerunning author/import mode if the gap is large.
- **Frontmatter count drift** — Suggest running `validate` (which will fail) and then `edit add-category` / `remove-category` to converge — counts get auto-synced on every edit.
- **Dimension count outside 4–8** — Surface the heuristic and let the user decide. The script reports it as a gap because it usually signals a design issue, but it's not a hard error.

---

## Notes for the calling skill

- Inspect never modifies anything. It is safe to run at any point, including mid-session before a destructive operation.
- The same script is reused by Edit mode (to print a "before" snapshot) and Validate mode (to attach structural context to validator findings). When you're calling it from those modes, you can suppress the gap-surface print since the calling mode has its own framing.
- If `taxonomy/` does not exist, the script returns a clean error pointing the user at clone/author/import — handle that case in the SKILL.md workflow, not here.
