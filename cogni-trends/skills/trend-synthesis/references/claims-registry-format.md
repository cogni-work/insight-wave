# Claims Registry Format

Reference for `trend-synthesis` Step 2.4 — the claims-registry table appended to the canonical TIPS report.

---

## Purpose

The claims registry is the report's verifiable evidence appendix. Every quantitative claim in the prose has a numbered row here with its source URL, dimension, and investment-theme ownership. `verify-trend-report` reads this registry as its source of truth for `cogni-claims:claims` verification.

The registry is **always rendered in full regardless of length tier** — evidence is non-negotiable. It is excluded from the prose word target (the tier formula in `report-length-tiers.md` covers prose only).

---

## Table Format

Write the registry to `{PROJECT_PATH}/.logs/report-claims-registry.md`:

```markdown
## {CLAIMS_REGISTRY_LABEL}

{CLAIMS_REGISTRY_INTRO}

| # | {CLAIM_LABEL} | {VALUE_LABEL} | {SOURCE_LABEL} | {DIMENSION_LABEL} | {INVESTMENT_THEME_LABEL} |
|---|---------------|---------------|-----------------|-------------------|--------------------------|
| 1 | {claim text} | {value + unit} | [{source title}](url) | {Forces / Impact / Horizons / Foundations} | {investment theme name or "—"} |
| 2 | ... | ... | ... | ... | ... |
```

Must end with two trailing newlines so concatenation in Step 2.6 produces clean section boundaries.

---

## Column Semantics

| Column | Source | Notes |
|---|---|---|
| `#` | Sequential 1-based row index | Stable across re-runs for the same claim set |
| `{CLAIM_LABEL}` | `claims-{dimension}.json → claims[].text` | The full sentence containing the number |
| `{VALUE_LABEL}` | `claims[].value` + `claims[].unit` | Render as e.g. `"6.9 USD bn"` or `"34 %"` — human-readable, not raw number string |
| `{SOURCE_LABEL}` | `claims[].citations[0].url` + a derived title | Markdown link `[Title](url)`. Title falls back to the source domain when no title is available |
| `{DIMENSION_LABEL}` | Localized macro-label for the dimension the claim came from | `"Forces"` / `"Impact"` / `"Horizons"` / `"Foundations"` (i18n: see `MACRO_*` keys) |
| `{INVESTMENT_THEME_LABEL}` | Walk value model to find which theme the originating candidate belongs to | Use the theme name. `"—"` for orphan candidates not assigned to any theme |

---

## Building the Theme Mapping

For each claim:

1. The claim's `id` (e.g., `claim_ee_001`) lives in `claims-{dimension}.json` for the dimension determined by the `ee` / `dw` / `nh` / `df` prefix.
2. The originating candidate appears in `enriched-trends-{dimension}.json` with `claims_refs` containing the claim id.
3. That candidate's `candidate_ref` (e.g., `"externe-effekte/act/1"`) appears in one or more `value_chains[].trend / implications / possibilities / foundation_requirements`.
4. The chain's `investment_theme_ref` resolves to the theme entry in `investment_themes[]`.
5. Render the theme's `name` in the `Investment Theme` column.

When a claim's candidate appears in **no** chain (orphan candidate), render `"—"` in the theme column. When it appears in **multiple** chains across **different** themes, pick the theme of the chain with the highest `chain_score` (or, when tied, the theme whose `investment_theme_id` sorts first alphabetically). Record the tiebreak rule in code comments — the choice must be deterministic across re-runs.

---

## i18n Labels

From `references/i18n/labels-{en,de}.md`:

```text
CLAIMS_REGISTRY_LABEL: "Claims Registry" / "Quellenregister"
CLAIMS_REGISTRY_INTRO: "All quantitative claims extracted from this report with their source URLs."
                    / "Alle quantitativen Aussagen aus diesem Bericht mit ihren Quell-URLs."
CLAIM:               "Claim"      / "Aussage"
VALUE:               "Value"      / "Wert"
SOURCE:              "Source"     / "Quelle"
DIMENSION_LABEL:     "Dimension"  / "Dimension"
INVESTMENT_THEME_LABEL: "Investment Theme" / "Handlungsfeld"
```

The macro-label localizations for the Dimension column come from the same labels file (`MACRO_FORCES`, `MACRO_IMPACT`, `MACRO_HORIZONS`, `MACRO_FOUNDATIONS`).

---

## Compatibility with `cogni-claims`

The merged claims file `tips-trend-report-claims.json` (written in Step 2.7) is the machine-readable companion to this human-readable table. Its schema is documented in `trend-research/references/claims-format.md § Merged Claims File`.

`verify-trend-report` Phase 2 invokes `cogni-claims:claims` with both files:

```
Skill("cogni-claims:claims",
      args="--file-path tips-trend-report.md \
            --claims-file tips-trend-report-claims.json \
            --verdict-mode --language {LANGUAGE}")
```

The `--claims-file` flag tells the claims skill to use the pre-extracted claims instead of running its own extraction phase. Row numbers in the markdown table align 1:1 with array indices in the JSON file (1-based markdown vs. 0-based JSON; downstream tooling handles the offset).

---

## Quality Gates

- [ ] Every claim in the prose has a corresponding registry row
- [ ] Every registry row has a non-empty `Source` URL
- [ ] Every row has either a theme name or `"—"` in the theme column — never an empty cell
- [ ] Dimension column values are localized macro labels, not the raw slug (e.g., `"Forces"` not `"externe-effekte"`)
- [ ] Row numbers are sequential and start at 1
- [ ] Two trailing newlines (`\n\n`) terminate the file
