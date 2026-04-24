# Pre-flight Validation & Readiness Gates

Every bridge operation runs a pre-flight check before doing any work. This catches
data gaps and industry mismatches early — before wasting time on exports or imports
that will produce poor results.

The SKILL.md Prerequisites section is a short overview; this file holds the full
gate and heuristic spec so the procedural steps stay scannable.

## Shared pre-flight (all operations)

1. **Discover projects** — Find the TIPS project (`*/tips-project.json`) and the
   portfolio project (`*/portfolio.json`). If either is missing, stop and report
   which one with a fix suggestion.
2. **Industry alignment** — Compare TIPS and portfolio industries (see heuristic
   below). The result is stored for use during market-relevance matching and
   reported in the summary.

## Industry alignment heuristic

The TIPS project targets a specific industry (e.g., manufacturing/automotive)
while the portfolio describes what you sell. Bridging across unrelated industries
is unusual and likely a mistake — but sometimes intentional (e.g., cross-selling
into a new vertical). The heuristic warns rather than blocks, so cross-industry
intent is still possible with explicit confirmation.

**How it works:**

1. Read TIPS `industry.primary` and `industry.subsector` from `tips-project.json`.
2. Read portfolio `company.industry` from `portfolio.json` (free text).
3. Collect all `segmentation.vertical_codes` from `portfolio/markets/*.json`.
4. Slugify `company.industry` (lowercase, replace non-alphanumeric with hyphens).

Match using a 4-tier heuristic:

- **exact** — Slugified `company.industry` matches `industry.primary` or
  `industry.subsector`. Example: `company.industry` "Automotive OEM" → slug
  `automotive-oem` contains `automotive` matching subsector. Proceed silently.
- **vertical** — Any market `vertical_code` matches `industry.subsector`.
  Example: market has `vertical_codes: ["automotive"]`, TIPS subsector is
  `automotive`. Proceed silently.
- **broad** — Any market `vertical_code` is a known subsector of
  `industry.primary` (use the same parent-child logic as market-relevance
  matching). Example: market has `vertical_codes: ["autonomous-vehicles"]`,
  TIPS primary is `manufacturing`. Proceed with note:
  > Portfolio markets have related verticals ({codes}) but no direct match to
  > TIPS subsector '{subsector}'. Bridge results may need manual review.
- **none** — No match found. Warn and require explicit user confirmation:
  > Industry mismatch: TIPS analyzes {primary_en}/{subsector_en} but portfolio
  > company.industry is '{company.industry}' with market verticals [{codes}].
  > Cross-industry bridging is unusual — continue anyway?

## portfolio-to-tips validation gates

Run these after shared pre-flight when executing `portfolio-to-tips` or `sync`.

**Hard gates (block execution):**

- `portfolio.json` must exist and be valid JSON.
- At least 1 product in `portfolio/products/`.
- At least 1 feature in `portfolio/features/` with a valid `product_slug`
  reference.

If any hard gate fails, stop and report the fix:

- "No products found. Create at least one product first: `/portfolio-setup`"
- "No features found. Add features to your products: `/features create`"

**Soft warnings (report and continue):**

- No propositions: "No propositions found. The exported context will lack
  IS/DOES/MEANS messaging — value-modeler Phase 2 will generate STs without
  portfolio grounding. Consider running `/propositions create` first."
- No markets: "No markets defined. The context file will have no
  market-relevance tagging. Define markets with `/portfolio-setup`."
- Features with descriptions under 15 words: "{N} features have thin
  descriptions (under 15 words). Richer descriptions improve ST-to-feature
  matching accuracy. Consider running `/features enrich` first."
- No solutions: "No solutions found. The exported context will lack pricing
  and delivery data."

## tips-to-portfolio validation gates

Run these after shared pre-flight when executing `tips-to-portfolio` or `sync`.

**Hard gates (block execution):**

- `tips-value-model.json` must exist in the TIPS project directory.
- `solution_templates` array must be non-empty.
- At least 1 ST must have `ranking_value` populated (not null) — confirms that
  value-modeler Phase 4 (ranking) has completed.

If any hard gate fails, stop and report the fix:

- "Value model not found. Run the value modeler first: `/value-model`"
- "No solution templates in value model. Complete value-modeler Phase 2:
  `/value-model solutions`"
- "Solution templates have no ranking values. Complete Phase 4 to calculate
  rankings: `/value-model rank`"

**Soft warnings (report and continue):**

- No features in portfolio: "Portfolio has no features. All Solution Templates
  will produce 'Create' actions (no enrichment possible). Consider adding
  features first with `/features create`."
- No propositions: "Portfolio has features but no propositions. Enrichment will
  create new propositions rather than refining existing ones."
- All STs have `business_relevance = null`: "No user-scored business relevance
  found. Rankings use formula-only scores. Consider running `/value-model score`
  for customer-specific prioritization."

## sync mode

`sync` runs **both** gate sets (`portfolio-to-tips` + `tips-to-portfolio`)
after the shared pre-flight and reports them together. This prevents the
common failure mode of running `portfolio-to-tips` successfully only to fail
on `tips-to-portfolio` halfway through. If any hard gate from either direction
fails, stop before executing either operation.
