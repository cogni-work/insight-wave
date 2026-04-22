---
name: portfolio-consolidate
description: |
  Roll up N cogni-portfolio scan outputs into a taxonomy-shaped coverage matrix
  across providers. Use whenever the user mentions "consolidate scans",
  "coverage matrix", "roll up research-only scans", "cross-scan matrix",
  "compare providers by taxonomy", "taxonomy coverage across companies",
  "peer coverage comparison", "portfolio consolidation", or "consolidated
  portfolio" — typically after running `portfolio-scan --mode=research-only`
  against two or more companies in the same industry taxonomy.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Portfolio Consolidate (Phase 1)

Roll up multiple `portfolio-scan` outputs — typically `research-only` scans of peer companies in the same industry — into one taxonomy-shaped coverage matrix. The output is a markdown pivot table `{company × category_id}` plus a sibling JSON so downstream tooling can reason about cross-provider coverage.

## Core Concept

Every `portfolio-scan` writes `research/.metadata/scan-output.json` plus a markdown report that tags each taxonomy category with a `[Status: X]` marker (Confirmed / Not Offered / Emerging / Extended). When you scan several companies in the same taxonomy, those per-company reports answer "what does each provider cover?" but they live in separate directories. This skill joins them into one table so the reader can see — at a glance — who covers which category and where the peer-group whitespace sits.

## Complementary boundary with `compete`

- **`compete`** — proposition/messaging level (Feature × Market). Runs after propositions exist; produces battle cards and competitive-response messaging.
- **`portfolio-consolidate`** — taxonomy/capability level (Company × Category). Runs on raw scan output; produces a provider-set coverage matrix.

If the user is asking "who offers what", use this skill. If they are asking "how do I win against provider X on proposition Y", use `compete`.

## Scope (Phase 1)

The v0.9.23 cut ships the minimum useful slice:

- Two cell states — `✓` (Confirmed; includes Emerging and Extended) and `—` (Not Offered or not reported).
- Per-category coverage rate (count of `✓` cells over the provider set).
- Hard refuse on `template_type` mismatch across inputs.
- Single output pair per invocation — `research/consolidated-{scope-slug}-portfolio.md` plus `research/.metadata/consolidated-{scope-slug}.json`.

Deferred to follow-up issues: separate `Emerging` / `Extended` cell states, per-dimension executive summary, whitespace / gap analysis by category, leaders / laggards callouts, and portfolio-dashboard integration. Do not extend the script beyond Phase 1 inside this skill — follow-up issues will track those additions.

## Workflow

### 1. Locate candidate scans

Find research-only scans already on disk so the user has a concrete pick list. The common shape is:

```bash
find . -path "*/research/.metadata/scan-output.json" -not -path "*/node_modules/*"
```

Read each discovered file with `Read` and extract `company_name`, `company_slug`, `template_type`, and `consolidation_mode`. Build a short summary (one line per scan) and decide whether there is enough material to proceed. If fewer than two scans exist, tell the user the consolidation is not meaningful yet and suggest `portfolio-scan --mode=research-only` against additional companies.

### 2. Pick the scope

Use `AskUserQuestion` to let the user select which scans to include. Group candidates by `template_type` in the question so the user cannot accidentally mix taxonomies — the script refuses mismatched templates anyway, but asking cleanly up front avoids a failed run.

Also ask for the **scope slug** used in output filenames. Default to `peer-set`, but prompt for something more descriptive (e.g., `ict-germany`, `cloud-hyperscalers`) when the user names a clear peer group.

### 3. Build the matrix

Dispatch `scripts/build-coverage-matrix.py` with the selected inputs:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/build-coverage-matrix.py" \
  --inputs <scan-output-1> <scan-output-2> [...] \
  --scope-slug <scope-slug> \
  --output-dir <project-research-dir> \
  --taxonomy-dir "$CLAUDE_PLUGIN_ROOT/templates/<template_type>"
```

The script returns the JSON service envelope `{success, data, error}`:

- On success: `data = {markdown_path, metadata_path, providers_count, categories_count, confirmed_cells, template_type}`.
- On `template_type` mismatch: `success: false` with an error naming the offenders. Surface the message verbatim — the user's next move is either to drop a mismatched scan or pick a different scope.

### 4. Present the result

Tell the user where the markdown landed (`research/consolidated-{scope-slug}-portfolio.md`) and summarise the key numbers: provider count, category count, total Confirmed cells. Do not paste the full matrix back into the chat — it is long; let the user open the file.

If the output reveals obvious gaps (one category covered by zero providers, one provider covering every category, etc.), call them out in one or two sentences. Anything deeper is a Phase 2 ask — don't inline a full gap analysis here.

### 5. Suggest a next step

Typical follow-ons from a fresh coverage matrix:

- **Extend the scope**: run `portfolio-scan --mode=research-only` against one or two more peers and re-run consolidation.
- **Deep-dive a category**: if one category is covered by everyone except the portfolio's own company, that's the strongest candidate for a `compete`-driven response or a new feature investment.
- **Wait for Phase 2**: whitespace analysis and per-dimension exec summary are follow-up issues; if the user wants those immediately, point them at issue #103's deferred section.

## Inputs and outputs

Input: one or more `research/.metadata/scan-output.json` files that share a `template_type`. The script reads `output_file` from each and parses the referenced markdown report for `[Status: X]` tags — so the report must still exist next to the metadata.

Output:
- `research/consolidated-{scope-slug}-portfolio.md` — human-readable pivot grouped by taxonomy dimension.
- `research/.metadata/consolidated-{scope-slug}.json` — machine-readable matrix + per-category counts for downstream consumers.

## Notes

- **No writes to curated state.** This skill never touches `features/`, `products/`, `propositions/`, or any other entity directory. It reads scan output and writes a summary. Safe to re-run.
- **Absent categories count as Not Offered.** If a scan report doesn't mention a category at all (e.g., the report was truncated or the taxonomy was extended after the scan), the cell renders `—`. This is intentional: absence is not evidence of presence.
- **Report discovery is path-relative.** The script assumes `output_file` is relative to the project root two directories above `research/.metadata/scan-output.json`. If a scan was moved or renamed manually, the report lookup will fail silently and every category will render `—` for that provider. Surface this to the user when provider row totals look unexpectedly low.
