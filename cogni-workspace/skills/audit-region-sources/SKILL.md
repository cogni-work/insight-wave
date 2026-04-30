---
name: audit-region-sources
description: |
  Audit per-market authority-domain alignment across the insight-wave region catalogs.
  Wraps `cogni-workspace/scripts/check-region-catalogs.sh` and renders a markdown
  report covering all four drift classes: extra_keys (Class 1), trends_only /
  research_only (Class 2), dach_sources (Class 3), and authority_domain_drift
  (Class 4 — informational by default; per-market authority-domain set drift
  between cogni-research's `market-sources.json`, cogni-trends's
  `region-authority-sources.json`, and the canonical
  `cogni-workspace/references/supported-markets-registry.json`).

  Use whenever the user mentions "audit region sources", "audit authority
  sources", "check authority domain drift", "research-trends domain drift",
  "are authority sources up to date", "regional authority drift", "compare
  authority domains across plugins", "check market sources alignment", or any
  question about whether the per-plugin authority lists match the canonical
  workspace registry — even if they don't say "audit" explicitly. Also use
  proactively after editing any of `supported-markets-registry.json`,
  `cogni-research/references/market-sources.json`, or
  `cogni-trends/skills/trend-report/references/region-authority-sources.json`.
allowed-tools: Read, Glob, Grep, Bash
---

# Region Catalog Drift Audit

## Core Concept

The insight-wave monorepo has four region/market catalogs that must stay aligned:

| File | Role |
|------|------|
| `cogni-portfolio/skills/portfolio-setup/references/regions.json` | Union-of-markets source of truth (broadest catalog) |
| `cogni-research/references/market-sources.json` | Research-side: keys by source category, plus `local_query_tips` and `authority_sources[].domain` |
| `cogni-trends/skills/trend-report/references/region-authority-sources.json` | Trends-side: keys by TIPS dimension, domains embedded in `site_searches[].query` templates as `site:<domain>` |
| `cogni-workspace/references/supported-markets-registry.json` | **Canonical upstream** for cross-plugin metadata (`provenance: "canonical upstream"`); declares `consolidates: [...]` over the three per-plugin files |

`cogni-workspace/references/curated-region-sources.json` carries the small CLAUDE.md-curated DACH list used by Class 3.

The schemas are deliberately not merged: research and trends each layer plugin-specific orchestration metadata (source category + authority tier vs TIPS dimension + query template) on top of the underlying domain set. The audit detects drift in the per-market domain set; it never auto-fixes.

## Workflow

### Step 1: Resolve Paths

`cogni-workspace/scripts/check-region-catalogs.sh` walks up from `$CLAUDE_PLUGIN_ROOT/scripts/` to the monorepo root and resolves the five catalog files itself. The skill does not need to compute paths.

### Step 2: Run the Extended Check

Invoke the script. Forward any flags the user supplied:

| Flag | Effect |
|------|--------|
| *(none)* | Default. Class 1–3 hard-fail; Class 4 informational. Exit 0 on Class-4-only findings. |
| `--strict` | Escalates Class 4 findings to violations (exit 1 if any). For future CI gating. |
| `--fix-suggestions` | Adds `data.info_findings.fix_suggestions[<code>]` with paste-able JSON additions per file. |
| `--market <code>` | Restricts Class 4 to a single market (e.g. `--market dach`). Class 1–3 always run on the full catalog. |

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/check-region-catalogs.sh [flags...]
```

The script prints human-readable lines, then a single-line JSON envelope as the final line. Parse the last line as `{success, data, error}`.

### Step 3: Run Audit Checks

The script returns four classes of findings. Render each:

| Class | Severity | Source |
|-------|----------|--------|
| Class 1 — `extra_keys` | HIGH (violation) | Region keys in trends/research that aren't in portfolio |
| Class 2 — `trends_only` / `research_only` | HIGH (violation) | Region-key parity mismatch between trends and research |
| Class 3 — `dach_sources` | HIGH (violation) | cogni-trends DACH must reference all CLAUDE.md-curated DACH authorities |
| Class 4 — `authority_domain_drift` | INFO (informational) | Per-market authority-domain set drift, three-bucket triage:<br>**A.** Curated upstream (registry has authorities + market in r+t) — three-way diff<br>**B.** Downstream-only (registry empty for this market) — peer diff + `registry_unpopulated` advisory<br>**C.** Registry-only composite (no per-plugin entry) — skipped |

Class 4 finding fields per Bucket-A market:

- `domain_only_in_upstream` — in canonical registry, absent from both plugin files
- `domain_only_in_research` — research-side extension (often regional regulators / statistics offices)
- `domain_only_in_trends` — trends-side extension (often global consultancies for `digitales-fundament`)
- `domain_in_research_and_trends_but_not_upstream` — strong candidate for promotion to the registry
- `authority_disagreement[]` — best-effort categorisation mismatch (research category vs trends dimension)

Class 4 finding fields per Bucket-B market:

- `registry_unpopulated` — advisory string (registry has no authority list for this market yet)
- `domain_only_in_research`, `domain_only_in_trends` — peer-diff between the two plugin files

Bucket C: emit `bucket_c_skipped: [...]` for transparency, no per-market findings.

### Step 4: Generate Report

Render the report to stdout (do not write to file). Use this structure:

```markdown
# Region Catalog Drift Audit Report

**Date:** {today ISO}
**Catalog files:**
- canonical registry: `cogni-workspace/references/supported-markets-registry.json` (last_updated: {value})
- cogni-research: `cogni-research/references/market-sources.json`
- cogni-trends: `cogni-trends/skills/trend-report/references/region-authority-sources.json`
- cogni-portfolio: `cogni-portfolio/skills/portfolio-setup/references/regions.json`
**Registry markets:** {summary.registry_markets_total} ({summary.registry_markets_with_authority_sources} with authority_sources populated)

## Summary

| Class | Status | Count |
|-------|--------|-------|
| 1 (extra_keys) | violation / clean | {n} |
| 2 (key parity) | violation / clean | {n} |
| 3 (DACH curated) | violation / clean | {n} |
| 4 Bucket A (curated upstream drift) | info | {bucket_a_markets_with_drift}/{markets_examined} |
| 4 Bucket B (downstream-only drift) | info | {bucket_b_markets_with_drift}/{markets_examined} |
| 4 Bucket C (skipped) | n/a | {n} |

## Findings

### Class 1–3: Violations

{Per-violation block: class, hint, detail}

### Class 4 — Bucket A: Curated Upstream Drift (INFO)

{Per-market table for each Bucket-A market with findings: domain_only_in_*, in_both_not_upstream, authority_disagreement}

### Class 4 — Bucket B: Downstream-only Drift (INFO)

{Per-market table for each Bucket-B market with: registry_unpopulated advisory, peer-diff lists}

### Class 4 — Bucket C: Skipped (composite/aggregate markets)

{Single line listing the skipped market codes — no findings expected for these}

## Recommended Actions

{Violations first (Class 1–3 hard-fixes), then info findings (Class 4) with this preamble:
"Most info findings reflect intentional plugin-specific asymmetry — review per-market entries
to confirm intent before pasting fix suggestions. Run with --fix-suggestions to emit
paste-able JSON snippets."}
```

### Step 5: Summary Line

End with a single summary line:

```
Audit complete: X violations, Y info findings (Z markets with domain drift)
```

If any Class 1–3 violations exist, add: "**Action required** — Class 1–3 are hard-failures; existing CI may break until resolved."

If only Class 4 info findings exist (the common steady-state case today), add: "All structural classes (1–3) clean. Class 4 surfaces per-market authority-domain divergence — most of it intentional. Use `--fix-suggestions` to draft paste-able registry / plugin additions."

## Acceptance Criteria Checklist

For traceability to issue #189:

- [x] Clean baseline run reports the real per-market diff baseline (Class 4)
- [x] Adding a synthetic domain catches drift in the corresponding `only_in_*` array
- [x] Schema-only differences (`local_query_tips`, `org_size_reference`, `regulatory_search`) are NOT flagged
- [x] No modifications to any authority file as part of running this audit
- [x] Cross-references in `cogni-workspace/CLAUDE.md`, `cogni-research/CLAUDE.md`, `cogni-trends/CLAUDE.md`
- [x] stdlib-only Python, JSON envelope output, exit 0 on clean state and on Class-4-only drift (informational)
