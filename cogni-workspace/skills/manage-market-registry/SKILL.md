---
name: manage-market-registry
description: >-
  Single entry point for the canonical insight-wave market registry — a read
  path that reports coverage and orphan overlay domains, and a write path that
  adds markets. Use whenever the user mentions "add a market", "manage
  markets", "market status", "scaffold a new region", "show market coverage",
  "missing markets in research/trends", "audit region sources", "audit
  authority sources", "are authority sources up to date", "compare authority
  domains across plugins", or "check market sources alignment". Curating
  plugin-specific overlay metadata (research authority_metadata, trends
  site_searches) is plugin-side work — edit the overlay file directly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Manage Market Registry

## Why This Exists

`${CLAUDE_PLUGIN_ROOT}/references/supported-markets-registry.json` is the
canonical taxonomy that every market-aware insight-wave plugin reads
through `${CLAUDE_PLUGIN_ROOT}/scripts/get-market-config.py`. There is one
source of truth and no sync — plugin overlays carry only plugin-specific
metadata keyed against the registry's canonical domain set, and the merge
utility joins them at read time.

This skill owns both directions over that one registry: the read path
reports what the taxonomy holds and where an overlay has drifted from it,
and the write path adds a market. They were two skills once, and the split
cost a routing decision on every market question while giving the host
router no tiebreaker — the read skill's report was reachable from the write
skill as well, so one was a superset of the other in all but name.

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
Which manage-market-registry action?
  1. status — coverage matrix per market across registry/research/trends, plus orphan overlay domains
  2. add    — interactive new-market workflow (registry-first)
```

Use AskUserQuestion. If `$ARGUMENTS` starts with one of the two sub-action
names, dispatch directly without asking.

## Operations

### 1. status

Read-only coverage and drift report. Write nothing.

The set arithmetic behind this report is not done in prose — it is
computed by a script and read back. That matters for the orphan check
specifically: it was described here for a long time and computed nowhere,
so nothing ever proved it could fire.

```bash
ORPHANS="${CLAUDE_PLUGIN_ROOT}/scripts/check-market-orphans.py"
python3 "$ORPHANS"
```

The script returns the standard envelope, and everything the report needs
is in `data`:

- `data.matrix[]` — one row per registry market, already joined. Each row
  carries `market`, `name`, `tier`, `registry_domains`, `output_language`,
  and one cell per consuming plugin: `research`, `trends`, `portfolio`.
- `data.orphans[]` — every overlay domain the registry does not carry,
  each naming its `plugin`, `market`, `domain`, the `field` that carried
  it, and `market_in_registry`.
- `data.markets_canonical` and `data.plugins.<name>.curated_markets[]` —
  the counts the summary line needs.

If the script exits non-zero, do **not** render a report. A failure envelope
here means the overlay cascade could not be loaded at all, so nothing read an
overlay and a "0 orphans" report would be a clean audit over nothing. Show the
`error` string instead. A plugin whose overlay merely does not resolve is a
different and expected state: it comes back inside a successful envelope, as
`curated: false`, and belongs in the report.

#### Render the coverage matrix

One row per registry market, with a column for each of the three
consuming plugins:

| Column | Source |
|--------|--------|
| Market | row `market` |
| Name | row `name` |
| Domains (registry) | row `registry_domains` |
| Research overlay | row `research`, or `—` when null |
| Trends overlay | row `trends`, or `—` when null |
| Portfolio | row `portfolio` |
| Output language | row `output_language` |

A `null` research or trends cell renders `—`: that plugin does not curate
this market today and its pipelines fall back to default behaviour. This
is information, not drift.

A cell reading `not-scanned` is a different statement and renders `n/a`:
that plugin's overlay was never opened, so nothing is being claimed about
what it curates. It cannot appear on this skill's path, which always scans
every plugin — only a `--plugin`-narrowed run produces it.

cogni-portfolio is a column even though it curates no overlay. It reads
the registry directly through the merge utility, so its cell is the
canonical domain count — dropping the column would report a plugin that
consumes the registry as one that consumes no markets at all.

#### Report the orphans

Orphans are the one real drift signal, and the only thing this report must
never omit. An orphan means an overlay carries metadata for a domain the
canonical registry does not hold: either the registry needs the domain, or
the overlay entry is stale.

List each entry in `data.orphans[]` with its plugin, market, domain and
carrying field. When `market_in_registry` is false, say so — the whole
market is uncanonical, not just the one domain, and adding domains to a
market the registry does not carry would not fix it.

#### Summary line

End with a single line:

```
Registry: {markets_canonical} markets canonical, {R} curated by research, {T} curated by trends, {orphan_count} orphan domain(s)
```

If `orphan_count > 0`, append: "**Action required** — orphan overlays
reference domains the canonical registry doesn't carry. Run
`/cogni-workspace:manage-market-registry add` to add the market or its
domains, or remove the overlay entry."

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

After writing, run the status operation's script once more and report the
new market's row, so the user sees the registry as it now stands rather
than being told it worked.

Then suggest:

> "Market added to the registry. To curate plugin-specific metadata,
> edit the relevant overlay:
> - Research authority metadata (search patterns, categories, tiers):
>   `cogni-research/references/market-sources.json` — add an entry under
>   `<code>.authority_metadata`.
> - Trends dimension queries (site_searches per Smarter Service dimension):
>   `cogni-trends/skills/trend-research/references/region-authority-sources.json`
>   — add an entry under `<code>.site_searches`."

The skill writes only to the registry. It does not touch plugin overlays —
those are plugin-side curation and follow their own authoring loops.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/supported-markets-registry.json` — canonical registry
- `${CLAUDE_PLUGIN_ROOT}/scripts/get-market-config.py` — merge utility (read entry point for plugins)
- `${CLAUDE_PLUGIN_ROOT}/scripts/check-market-orphans.py` — orphan and coverage computation behind the status report
- `${CLAUDE_PLUGIN_ROOT}/tests/test-check-market-orphans.sh` — proves the orphan check discriminates
- `cogni-research/references/market-sources.json` — research overlay (`authority_metadata` keyed by domain)
- `cogni-trends/skills/trend-research/references/region-authority-sources.json` — trends overlay (`site_searches[]` keyed by dimension)

## Evaluations

`evals/evals.json` holds this skill's trigger and behaviour prompts — reference material for verifying the skill still fires on the phrasings it claims, not loaded at runtime.
