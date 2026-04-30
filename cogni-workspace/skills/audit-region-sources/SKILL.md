---
name: audit-region-sources
description: |
  Read-only inspection of the canonical market registry and per-plugin
  overlays. Shows the registry's market set with authority-domain count
  per market, plus how each plugin (cogni-research, cogni-trends) curates
  its overlay against the canonical domain set. Use whenever the user
  mentions "audit region sources", "audit authority sources", "are
  authority sources up to date", "compare authority domains across
  plugins", "check market sources alignment", "show market coverage", or
  any read-only question about market/region taxonomy. The read-write
  sibling is `manage-markets` — use it for adding markets or updating
  overlay metadata.
allowed-tools: Read, Glob, Grep, Bash
---

# Region Catalog Audit (Read-Only)

## Core Concept

There is one canonical market taxonomy:
`cogni-workspace/references/supported-markets-registry.json` — codes,
names, locales, currencies, languages, regional qualifiers, regulatory
bodies, and the authority-domain set per market.

Two plugins layer plugin-specific operational metadata on top via
overlays:
- `cogni-research/references/market-sources.json` — per-market
  `vocabulary_hints`, `local_query_tips`, `region_qualifiers` (search-query
  format), `local_language`, plus `authority_metadata{}` keyed by domain
  (category, authority tier, search pattern).
- `cogni-trends/skills/trend-report/references/region-authority-sources.json`
  — per-market `site_searches[]` keyed by Smarter Service dimension,
  `regulatory_search`, `org_size_reference`, plus `region_qualifiers`,
  `local_language`, `regulatory_bodies`.

Drift between registry and overlays is structurally impossible: overlays
carry only plugin-specific metadata keyed against registry domains. The
single soft check is "did an overlay add metadata for a domain not in the
registry?" — which would be an orphan. This audit reports it.

## Workflow

### Step 1: Pull merged configs

Run the merge utility for all three plugins. Resolve cogni-workspace's
plugin root via the standard sibling-or-monorepo fallback.

```bash
GET_MARKET="${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/ | head -1)}/scripts/get-market-config.py"

python3 "$GET_MARKET" --plugin portfolio --all-markets > /tmp/audit-portfolio.json
python3 "$GET_MARKET" --plugin research  --all-markets > /tmp/audit-research.json
python3 "$GET_MARKET" --plugin trends    --all-markets > /tmp/audit-trends.json
```

### Step 2: Render coverage matrix

Produce a markdown table — one row per registry market — with these columns:

| Column | Source |
|--------|--------|
| Market | registry key |
| Name | registry `name` |
| Domains (registry) | `len(registry.authority_sources)` |
| Research overlay | `len(research.authority_metadata)` if curated, else `—` |
| Trends overlay | `len(trends.site_searches)` if curated, else `—` |
| Output language | registry `default_output_language` |

Markets where research/trends have no overlay entry render `—` in their
column. That means the plugin doesn't curate this market today; pipelines
fall back to default behavior. This is information, not drift.

### Step 3: Orphan check (the only real drift)

For each plugin overlay, list any domain in `authority_metadata` (research)
or any `site:DOMAIN` reference in `site_searches[].query` (trends) that
is **not** in the registry's `authority_sources[].domain` for that market.

Orphans are the one thing this audit must surface. They mean an overlay
was hand-edited to add metadata for a domain the canonical registry
doesn't carry — either the registry needs the domain (run `manage-markets`
to add it) or the overlay entry is stale (delete it).

### Step 4: Summary line

End with a single line:

```
Audit complete: {N} markets canonical, {R} curated by research, {T} curated by trends, {O} orphan domain(s)
```

If `O > 0`, append: "**Action required** — orphan overlays reference
domains the canonical registry doesn't carry. Run `/cogni-workspace:manage-markets add-domain` to promote, or remove the overlay entry."

## Output

Render the report to stdout. Do not write files. The skill is read-only.
