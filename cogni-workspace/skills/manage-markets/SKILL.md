---
name: manage-markets
description: >-
  Manage the canonical insight-wave market registry — add new markets,
  sync canonical scaffolding into per-plugin orchestration files, promote
  agreed-intentional drift into the registry, and refresh the drift
  baseline after curation. Use this skill whenever the user asks to "add
  a market", "sync markets", "manage markets", "promote drift", "registry
  promotion sweep", "regenerate baseline", "refresh markets baseline",
  "missing markets in research/trends", "scaffold a new region",
  "backfill registry from research and trends", or any question that
  *changes* the market catalogs — read-only inspection routes to
  audit-region-sources instead. Also triggers on "monthly registry
  sweep", on requests to "fix region drift" / "fix authority-domain
  drift" by editing the registry, when the user references issue #191
  or the region-catalog drift remediation pipeline, and when a
  PostToolUse hook advisory points the user here after detecting new
  Class 4 drift.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Manage Markets

## Why This Exists

The insight-wave monorepo has four region catalogs that must stay aligned: the canonical `cogni-workspace/references/supported-markets-registry.json`, the broader `cogni-portfolio/skills/portfolio-setup/references/regions.json`, and the two per-plugin orchestration files in `cogni-research` (search-pattern + authority-tier metadata) and `cogni-trends` (TIPS-dimension query templates).

The registry is *upstream* (`provenance: "canonical upstream"`) but the per-plugin files layer plugin-specific orchestration metadata that the registry deliberately does not carry. Drift accumulates because the four files have separate authoring loops — a maintainer adding a regional regulator to research has no obligation to round-trip it into the registry, even though the addition is agreed-intentional.

This skill is the *write* path for closing that drift. The read-only counterpart is `audit-region-sources` — use that for inspection, this skill when changing files.

The detection half of the pipeline (`check-region-catalogs.sh` Class 1–4 + the PostToolUse hook in `hooks/hooks.json`) catches drift the moment it appears. This skill provides the five remediation actions: `status`, `add`, `sync`, `promote`, `baseline-refresh`.

## Prerequisites

Resolve the repo root by walking up from `${CLAUDE_PLUGIN_ROOT}/scripts/` to two parents — same convention as `check-region-catalogs.sh`. The skill uses the bundled scripts in `cogni-workspace/scripts/`, never duplicating their logic in the prompt.

Before any write operation, confirm git state is clean (`git status --porcelain`); the skill writes diffs that the user reviews and commits, so a clean tree avoids tangling unrelated changes into the same review.

## Sub-action Router

When invoked without arguments, ask the user which action to take:

```
Which manage-markets action?
  1. status            — coverage matrix per market across registry/portfolio/research/trends
  2. add               — interactive new-market workflow (registry-first)
  3. sync              — propagate canonical → plugins (add missing market stubs)
  4. promote           — apply agreed drift findings to the registry (audit → registry)
  5. baseline-refresh  — regenerate the drift baseline after curation
```

Use AskUserQuestion. If `$ARGUMENTS` starts with one of the five sub-action names, dispatch directly without asking.

## Operations

### 1. status

Read-only coverage report. The user wants to see "what does each catalog know about each market, and what's the delta vs the agreed baseline?".

Run the audit with the baseline:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/check-region-catalogs.sh \
  --baseline $CLAUDE_PLUGIN_ROOT/scripts/baselines/region-catalog-drift-baseline.json
```

Parse the last-line JSON envelope. Render a coverage matrix:

```markdown
| Market | Registry | Portfolio | Research | Trends | Δ vs baseline |
|--------|---------|-----------|----------|--------|---------------|
| dach   | ✓ (5)   | ✓         | ✓ (28)   | ✓ (24) | 0             |
| jp     | ✓ (0)   | ✓         | —        | —      | n/a           |
```

Numbers in parentheses are the count of authority sources (registry) or domains (research/trends) for that market. The Δ column shows `total_domains_added` minus `total_domains_removed` for that market against the baseline; markets with no delta show `0`. Markets in `bucket_c_skipped` (composites with no per-plugin presence) get `n/a`.

End the report with one summary sentence — the same one the audit's `Deltas vs baseline` line emits. Read-only; never writes.

### 2. add

Interactive workflow for adding a brand-new market — one not in any catalog yet. This is the registry-first path; it always offers to scaffold plugin stubs via `sync` afterwards.

Ask the user, via AskUserQuestion (one or two questions per turn — don't quiz the user with a wall of fields):

1. **Identifier** — `code` (kebab-case, e.g., `kr` or `nordics-extended`), `name` (display string), `tier` (`primary` / `extended` / `composite` / `anglo` / `global`).
2. **Locale** — `currency` (ISO 4217 like `EUR` or the literal `MIXED` for composites), `locale` (`xx_YY` BCP-47 like `ko_KR`), `timezone` (IANA like `Asia/Seoul`), `languages_supported[]` (multiSelect from a small picklist plus an "other" override), `default_output_language` (subset of languages_supported).
3. **Composition** (only if tier is `composite`) — `composite_of[]` (multiSelect of existing market codes) and `countries[]` (ISO 3166-1 alpha-2). For non-composite markets, ask only for `countries[]`.
4. **Qualifiers** — `regional_qualifiers.local` and `regional_qualifiers.en` (two short strings, e.g., `"in DACH"` / `"in DACH region"`). Note: this is the *registry* field name; the per-plugin files use `region_qualifiers` (without the "al"). Sync handles the mapping.
5. **Authority sources** — loop until the user is done; for each source: `name` (display), `domain` (root domain, no scheme). The list MAY be empty for new composite markets; that's the Bucket B path (registry holds the metadata, downstream plugins fill in domains via curation).

Construct the new entry with `consumed_by` defaulting to `["cogni-portfolio"]` (any new market is at minimum a portfolio target; the user can edit consumed_by later).

Read the registry, append the new entry to `markets`, write the registry back with markets sorted alphabetically by code (preserving the file's leading metadata fields). Bump `last_updated` to today's ISO date if the field exists.

After writing, re-run the audit:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/check-region-catalogs.sh
```

Then prompt the user:

- If the new code triggers a Class 1 violation (extra_keys in research/trends), the new market exists *only* in the registry — that's expected for a brand-new market. Print the portfolio-paste snippet (the entry shape from `cogni-portfolio/skills/portfolio-setup/references/regions.json`) so the user can mirror it there.
- Offer to run `sync` to scaffold the plugin stubs in research and trends.

The `add` workflow only writes to the registry. It does not touch portfolio (different schema, hand-curated), and it does not touch research/trends (those are sync's job).

### 3. sync

Propagate the canonical registry into the per-plugin files. This adds market keys missing from research and/or trends with explicit placeholder orchestration metadata.

**Field-name mapping (load-bearing):** the registry's `regional_qualifiers` field maps to research/trends' `region_qualifiers` field. The script handles this; do not propagate the registry name into the plugin files.

**What sync writes (placeholders the maintainer must refine later):**

| Plugin | Stub field | Placeholder value |
|--------|------------|-------------------|
| research | `authority_sources[].category` | `"unknown"` |
| research | `authority_sources[].authority` | `3` |
| research | `authority_sources[].search_pattern` | `"site:{domain} {TOPIC_LOCAL} {YEAR}"` |
| trends | `site_searches[].dimension` | `"digitales-fundament"` |
| trends | `site_searches[].query` | `"site:{domain} {SUBSECTOR_LOCAL} {CURRENT_YEAR}"` |

**What sync NEVER writes:**

- Anything for a market that already has an entry — uses `dict.setdefault` semantics. Existing entries stay byte-identical.
- Real values for `category` / `authority` / `search_pattern` / `dimension` / query templates — the maintainer must refine these placeholders. The audit's Class 4 advisory will flag the placeholder-set as Bucket A drift until it's curated.

Run the script in preview mode first:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/sync-markets-to-plugins.py
```

Show the unified diff to the user. If they approve, run with `--write`:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/sync-markets-to-plugins.py --write
```

Both modes emit a JSON envelope on the last line; surface the `summary` field to the user.

After `--write`, run the audit (`check-region-catalogs.sh`) to confirm Class 1–3 are still clean. If the new entries triggered a Class 1 (the synced market exists only in research/trends but not in portfolio), tell the user — usually that means portfolio also needs the market added.

### 4. promote

Apply the agreed-intentional drift findings to the canonical registry. This is the registry-promotion sweep from issue #191 and the action the monthly scheduled agent runs.

Two safe categories of promotion:

1. **Bucket A `domain_in_research_and_trends_but_not_upstream`** — a domain both per-plugin files reference but the registry doesn't carry. Both plugins agreeing means it's curated, not noise.
2. **Bucket B `r∩t` agreement** — a market the registry has not authored authority sources for, where both plugins independently reference the same domain.

The audit's `--fix-suggestions` envelope already lists these in `info_findings.fix_suggestions[<code>][].registry_additions[]`. The promote script applies only the `registry_additions[]` block; it ignores `research_additions` and `trends_additions` (those would inject placeholders into orchestration metadata).

Workflow:

```bash
# 1. Capture the audit envelope.
bash $CLAUDE_PLUGIN_ROOT/scripts/check-region-catalogs.sh \
  --fix-suggestions \
  --baseline $CLAUDE_PLUGIN_ROOT/scripts/baselines/region-catalog-drift-baseline.json \
  | tail -1 > /tmp/region-audit-envelope.json

# 2. Preview the promotion diff.
python3 $CLAUDE_PLUGIN_ROOT/scripts/promote-drift-to-registry.py \
  --envelope /tmp/region-audit-envelope.json

# 3. If preview looks good, apply.
python3 $CLAUDE_PLUGIN_ROOT/scripts/promote-drift-to-registry.py \
  --envelope /tmp/region-audit-envelope.json --write
```

The promote script:

- Adds new domains to each market's `authority_sources[]` using `setdefault` (never duplicates an existing domain).
- Sorts each market's `authority_sources[]` alphabetically by domain for stable diffs.
- Bumps `last_updated` to today's ISO date.
- **Never** touches `cogni-research/references/market-sources.json` or `cogni-trends/skills/trend-report/references/region-authority-sources.json`. Per-plugin orchestration metadata (`category`, `authority`, `search_pattern`, `dimension`, query templates) is human-authored.

After `--write`, the workflow continues outside the script:

```bash
# 4. Open a feature branch and PR.
DATE_TAG="$(date +%Y-%m)"
git checkout -b "registry-promotion-sweep-${DATE_TAG}"
git add cogni-workspace/references/supported-markets-registry.json
git commit -m "cogni-workspace: registry-promotion sweep ${DATE_TAG} (refs #191)"
git push -u origin "registry-promotion-sweep-${DATE_TAG}"
gh pr create --title "Registry-promotion sweep ${DATE_TAG}" --body "<body listing each promotion grouped by market with 'agreed by 2 plugin(s)' tag>"
```

**Never** auto-merge. Leave the PR open for human review.

After the PR merges, run `baseline-refresh` to shrink the agreed-drift baseline by the now-promoted entries.

### 5. baseline-refresh

Regenerate the drift baseline file after intentional curation. Use this *after*:

- A `manage-markets promote` PR merges (the registry now carries domains the baseline previously listed as drift; refresh shrinks the baseline).
- A maintainer hand-edits research or trends to add a legitimately-curated regional source (the new domain is now agreed-intentional drift; the baseline should reflect it so the PostToolUse hook stops flagging it as new).
- A `manage-markets add` adds a new market with curated authorities (the audit may surface new Bucket A/B findings for the new market that should be the new baseline).

Run the script in preview mode first:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/refresh-region-catalog-baseline.py
```

The script runs the audit internally, builds a candidate baseline, and prints a unified diff vs the current baseline. If the diff is empty (no curation has happened since the last baseline refresh), tell the user and stop.

If the user approves, apply:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/refresh-region-catalog-baseline.py --write
```

Both modes emit a JSON envelope on the last line; surface the `summary` field.

The baseline file is intentionally not auto-regenerated. The PostToolUse hook reads it as the source of truth for "agreed-intentional drift"; auto-regeneration would silently swallow new drift instead of surfacing it.

## Coexistence with audit-region-sources

`audit-region-sources` is the read-only sibling of this skill — same precedent as `manage-workspace` ↔ `workspace-status` and `manage-themes` ↔ `pick-theme`. Use audit-region-sources whenever the goal is inspection only (e.g., "show me the current drift"); use this skill when the goal is to change one of the catalog files.

The two skills share the same underlying script (`check-region-catalogs.sh`) and the same baseline file. They never modify each other's behavior; they're two different prompts over the same machinery.

## Monthly Registry-Promotion Sweep

A `/schedule`-able routine fires `manage-markets promote` against fresh audit findings on the first of each month. The verbatim agent prompt lives in `cogni-workspace/CLAUDE.md` under "Region Catalog Drift Checks → Monthly promotion sweep". The routine never auto-merges the resulting PR; humans review every promotion.

After the first sweep merges, the refreshed baseline shows zero Bucket-A `domain_in_research_and_trends_but_not_upstream` and zero Bucket-B `r∩t` agreement — the steady state.

## References

- `cogni-workspace/scripts/check-region-catalogs.sh` — the audit + baseline diff script
- `cogni-workspace/scripts/check-region-catalogs-hook.sh` — the PostToolUse hook
- `cogni-workspace/scripts/sync-markets-to-plugins.py` — canonical → plugins scaffolder
- `cogni-workspace/scripts/promote-drift-to-registry.py` — drift-to-registry promoter
- `cogni-workspace/scripts/refresh-region-catalog-baseline.py` — baseline regenerator
- `cogni-workspace/scripts/baselines/region-catalog-drift-baseline.json` — agreed-drift snapshot
- `cogni-workspace/references/supported-markets-registry.json` — canonical registry
- `cogni-workspace/references/curated-region-sources.json` — Class 3 DACH source list
- `cogni-research/references/market-sources.json` — research-side per-plugin file
- `cogni-trends/skills/trend-report/references/region-authority-sources.json` — trends-side per-plugin file
- `cogni-portfolio/skills/portfolio-setup/references/regions.json` — portfolio-side broadest catalog
- `cogni-workspace/skills/audit-region-sources/SKILL.md` — read-only sibling skill
- GitHub issue #191 — the remediation pipeline this skill closes the loop on
