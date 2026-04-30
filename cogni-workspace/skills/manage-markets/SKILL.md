---
name: manage-markets
description: >-
  Manage the canonical insight-wave market registry — add a new market or
  show the coverage matrix. Use whenever the user mentions "add a market",
  "manage markets", "scaffold a new region", "show market coverage",
  "market status", "missing markets in research/trends", or any question
  that *changes* the registry. Read-only inspection routes to
  `audit-region-sources`. Adding plugin-specific overlay metadata
  (research authority_metadata, trends site_searches) is plugin-side
  curation — edit the overlay file directly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Manage Markets

## Why This Exists

`cogni-workspace/references/supported-markets-registry.json` is the
canonical taxonomy that every market-aware insight-wave plugin reads
from via `cogni-workspace/scripts/get-market-config.py`. There is one
source of truth and no sync — plugin overlays carry only plugin-specific
metadata keyed against the registry's canonical domain set, and the merge
utility joins them at read time.

This skill is the *write* path for the registry itself: add a new market,
or show the coverage matrix. The read-only sibling is
`audit-region-sources`.

What this skill does **not** do (intentionally — these are gone in the
centralized model):
- No `sync` — there's no copy of shared fields to propagate.
- No `promote` — domains live in the registry only, so there's nothing
  to promote from drift findings.
- No `baseline-refresh` — there's no baseline file because there's no
  drift on shared fields.

## Sub-action Router

When invoked without arguments, ask the user which action to take:

```
Which manage-markets action?
  1. status — coverage matrix per market across registry/research/trends
  2. add    — interactive new-market workflow (registry-first)
```

Use AskUserQuestion. If `$ARGUMENTS` starts with one of the two sub-action
names, dispatch directly without asking.

## Operations

### 1. status

Read-only coverage report. Equivalent to running `audit-region-sources`
with no flags — kept here so the user finds it from the write-path entry
point too. Render the same table:

```bash
GET_MARKET="${CLAUDE_PLUGIN_ROOT}/scripts/get-market-config.py"
python3 "$GET_MARKET" --plugin portfolio --all-markets
```

Then for each registry market, report:
- Number of authority domains in registry.
- Whether `cogni-research/references/market-sources.json` curates an
  overlay entry (yes/no, count of `authority_metadata` keys).
- Whether `cogni-trends/.../region-authority-sources.json` curates an
  overlay entry (yes/no, count of `site_searches[]`).
- Any orphan overlay domains (domains in plugin overlay not in registry's
  `authority_sources[]`).

End with a one-line summary. Do not write any files.

### 2. add

Interactive workflow for adding a brand-new market to the registry.

Ask the user, via AskUserQuestion (one or two questions per turn — don't
quiz the user with a wall of fields):

1. **Identifier** — `code` (kebab-case, e.g. `kr` or `nordics-extended`),
   `name` (display string), `tier` (`primary` / `extended` / `composite` /
   `anglo` / `global`).
2. **Locale** — `currency` (ISO 4217 like `EUR`, or the literal `MIXED`
   for composites), `locale` (`xx_YY` BCP-47 like `ko_KR`), `timezone`
   (IANA like `Asia/Seoul`), `languages_supported[]` (multiSelect from
   a small picklist plus an "other" override), `default_output_language`
   (subset of `languages_supported`).
3. **Composition** (only if tier is `composite`) — `composite_of[]`
   (multiSelect of existing market codes) and `countries[]` (ISO 3166-1
   alpha-2). For non-composite markets, ask only for `countries[]`.
4. **Qualifiers** — `regional_qualifiers.local` and `regional_qualifiers.en`
   (two short strings, e.g., `"in DACH"` / `"in DACH region"`). These are
   the **narrative** format; plugins maintain their own search-query
   format under `region_qualifiers` in their overlays.
5. **Authority sources** — loop until the user is done; for each source:
   `name` (display) and `domain` (root domain, no scheme). The list MAY
   be empty for new composite markets — the registry can carry the
   metadata first and have plugins curate domains later.
6. **Regulatory bodies** — optional list of regulator display names.

Construct the new entry with `consumed_by` defaulting to
`["cogni-portfolio"]` (any new market is at minimum a portfolio target —
the user can edit `consumed_by` afterwards once research/trends curate
overlay metadata for it).

Read the registry, append the new entry to `markets`, write it back with
markets sorted alphabetically by code (preserving the file's leading
metadata fields). Bump `last_updated` to today's ISO date.

After writing, suggest:

> "Market added to the registry. To curate plugin-specific metadata,
> edit the relevant overlay:
> - Research authority metadata (search patterns, categories, tiers):
>   `cogni-research/references/market-sources.json` — add an entry under
>   `<code>.authority_metadata`.
> - Trends dimension queries (site_searches per Smarter Service dimension):
>   `cogni-trends/skills/trend-report/references/region-authority-sources.json`
>   — add an entry under `<code>.site_searches`."

The skill writes only to the registry. It does not touch plugin overlays —
those are plugin-side curation and follow their own authoring loops.

## Coexistence with audit-region-sources

`audit-region-sources` is the read-only sibling — same precedent as
`manage-workspace` ↔ `workspace-status` and `manage-themes` ↔
`pick-theme`. Use audit-region-sources whenever the goal is inspection
only; use this skill when the goal is to add a market.

## References

- `cogni-workspace/references/supported-markets-registry.json` — canonical registry
- `cogni-workspace/scripts/get-market-config.py` — merge utility (read entry point for plugins)
- `cogni-research/references/market-sources.json` — research overlay (`authority_metadata` keyed by domain)
- `cogni-trends/skills/trend-report/references/region-authority-sources.json` — trends overlay (`site_searches[]` keyed by dimension)
- `cogni-workspace/skills/audit-region-sources/SKILL.md` — read-only sibling skill
