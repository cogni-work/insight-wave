# cogni-workspace

Workspace-level infrastructure for the cogni plugin ecosystem: theme management, shared conventions, MCP server installation, orchestration utilities, and Obsidian vault integration.

## Theme Infrastructure

- `pick-theme` is the entry point for theme selection across all plugins
- Themes live in `themes/` as markdown files describing visual identity
- See `references/design-variables-pattern.md` for the shared convention on producing themed HTML dashboards — any skill generating visual HTML output should follow this pattern

### Pre-PR checks for theme-touching changes

Run the umbrella backwards-compat harness before submitting any PR that
touches `themes/`, `skills/pick-theme/`, `skills/manage-themes/`, or any
consumer plugin's theme-reading surface:

```bash
bash cogni-workspace/scripts/verify-theme-backcompat.sh
```

The harness verifies the Theme System v2 contract end-to-end:

- **Tier-0 invariant.** `discover-themes.py` output for the bundled
  `_template/` theme (via a non-underscore fixture) must match the
  committed snapshot at `scripts/baselines/_template-tier0-output.json`.
  The contract from RFC #124 is "themes without manifest.json must keep
  working exactly as today" — this is the regression test.
- **Tiered invariant.** The `cogni-work` theme must surface
  `tiers.tokens` resolving to a `tokens/` directory containing
  `tokens.css`.
- **Consumer contracts.** Each known visual consumer (cogni-visual:
  render-html-slides + story-to-* siblings, cogni-portfolio:
  portfolio-dashboard, cogni-website:website-build) and voice consumer
  (cogni-narrative, cogni-sales, cogni-research, cogni-copywriting) must
  still reference the theme contract in its SKILL.md.

The harness complements the per-skill validators
(`validate-theme-manifest.py`, `check-skill-names.sh`) — those catch
local violations; this catches integration drift across plugins.

`--help` prints a failure-mode triage table mapping each failure to the
likely upstream child issue (#126–#130). CI integration is intentionally
out of scope; manual invocation before PRs is the contract.

## MCP Server Installation

- The `install-mcp` skill is the primary entry point for end-to-end MCP setup
- It handles git-based servers (clone + build), native app detection, and Claude Desktop config patching
- `scripts/install-mcp.sh` handles clone, build, and wrapper creation into `~/.claude/mcp-servers/<name>/`
- `scripts/patch-desktop-config.py` merges MCP entries into `claude_desktop_config.json` (with backup)
- `references/mcp-git-registry.json` (v2.0) declares both git-based and native app MCPs with platform-specific paths
- `templates/mcp-wrappers/` contains wrapper scripts for MCP servers that need companion processes (e.g. canvas server)
- `manage-workspace` delegates to `install-mcp` during init/update (step 5)
- Plugin `.mcp.json` files reference installed servers via `$HOME/.claude/mcp-servers/<name>/start.sh`

## Region Catalog Drift Checks

`scripts/check-region-catalogs.sh` is the cross-plugin region-drift checker. The canonical upstream is `references/supported-markets-registry.json` (declared `provenance: "canonical upstream"`); the script audits the three downstream consumers (`cogni-portfolio` / `cogni-research` / `cogni-trends`) against it.

Four drift classes:

1. **`extra_keys`** — region keys in trends/research not in portfolio (portfolio is the union-of-markets source of truth). Hard-fail.
2. **`trends_only` / `research_only`** — region-key parity mismatch between trends and research. Hard-fail.
3. **`dach_sources`** — cogni-trends DACH must reference all CLAUDE.md-curated DACH authorities (sourced from `references/curated-region-sources.json`). Hard-fail.
4. **`authority_domain_drift`** *(informational by default)* — per-market authority-domain set drift between the canonical registry and each plugin's authority listing. Three-bucket triage: **A.** Curated upstream (registry has authorities + market in r+t) — three-way diff; **B.** Downstream-only (registry empty for this market) — peer diff + `registry_unpopulated` advisory; **C.** Registry-only composite (no per-plugin entry) — skipped. Run with `--strict` to escalate Bucket A/B drift to violations once the sets converge.

Flags: `--fix-suggestions` emits paste-able JSON additions per file; `--market <code>` restricts Class 4 to a single market; `--strict` escalates Class 4 to hard-fail; `--baseline <path>` attaches `data.info_findings.deltas_vs_baseline` (per-market additions/removals vs the agreed-intentional drift snapshot at `scripts/baselines/region-catalog-drift-baseline.json`). The baseline never changes the exit code — enforcement is the hook layer's job.

Wrap-skills:
- `audit-region-sources` — read-only inspection (markdown skill, no own scripts; invokes the audit and renders a report).
- `manage-markets` — read-write counterpart for the same domain. Use whenever you need to *change* a market catalog (add a market, sync canonical → plugins, promote agreed drift to the registry, refresh the baseline). Five sub-actions: `status` (coverage matrix + delta vs baseline), `add` (interactive new-market workflow), `sync` (canonical → plugins scaffolding via `scripts/sync-markets-to-plugins.py`; maps registry's `regional_qualifiers` → plugins' `region_qualifiers` field name), `promote` (audit `--fix-suggestions` → registry via `scripts/promote-drift-to-registry.py`; never touches per-plugin orchestration metadata; opens a PR, never auto-merges), `baseline-refresh` (regenerates the baseline file via `scripts/refresh-region-catalog-baseline.py` after intentional curation).

### Drift remediation pipeline (issue #191)

The detection/remediation loop has three pieces working together:

1. **Drift baseline ratchet** — `scripts/baselines/region-catalog-drift-baseline.json` snapshots today's agreed-intentional Bucket A/B findings (11 + 10 = 21 markets). The audit's `--baseline` flag computes deltas; `manage-markets baseline-refresh` curates the file. Humans curate this — never auto-regenerated.

2. **PostToolUse hook** — `scripts/check-region-catalogs-hook.sh` is registered in `hooks/hooks.json` for `Edit|Write|MultiEdit`. Filters silently on any path outside the three watched files (`supported-markets-registry.json`, `cogni-research/.../market-sources.json`, `cogni-trends/.../region-authority-sources.json`); exits 2 on Class 1–3 violations (course-correct signal); prints a one-line stderr advisory pointing at `/cogni-workspace:manage-markets` on Class 4 growth vs baseline; silent on unchanged or shrunk drift.

3. **Monthly promotion sweep** — `/schedule`-able routine that fires `manage-markets promote` against fresh audit findings on the first of each month. Routine prompt:

```
You are running the monthly insight-wave registry-promotion sweep for issue #191.

1. cd to the insight-wave repo root.
2. Run the audit with fix-suggestions and the baseline:
   bash cogni-workspace/scripts/check-region-catalogs.sh \
     --fix-suggestions \
     --baseline cogni-workspace/scripts/baselines/region-catalog-drift-baseline.json \
   | tail -1 > /tmp/region-audit-envelope.json
3. If `data.info_findings.fix_suggestions` is empty AND
   `data.info_findings.deltas_vs_baseline.summary.total_domains_added` is 0,
   stop with the message
   "No promotions due this month — registry and baseline are aligned."
4. Otherwise invoke /cogni-workspace:manage-markets with sub-action `promote`,
   pointed at /tmp/region-audit-envelope.json. The skill will:
     - apply only `registry_additions[]` (Bucket A
       `domain_in_research_and_trends_but_not_upstream` + Bucket B `r∩t` agreement)
       to cogni-workspace/references/supported-markets-registry.json
     - never edit cogni-research/references/market-sources.json or
       cogni-trends/skills/trend-report/references/region-authority-sources.json
     - create a feature branch `registry-promotion-sweep-$(date +%Y-%m)` and open
       a PR via gh
     - NEVER auto-merge — leave the PR open for human review
5. PR body must list each promotion with the count of plugins agreeing
   ("research+trends" = 2). Group additions by market.
6. After the PR is opened, post a one-line summary comment with the count of
   markets touched and domains promoted. Stop.

Acceptance: after the first sweep merges, /cogni-workspace:manage-markets
baseline-refresh must show 0 Bucket-A `in_r_and_t_not_upstream` and 0 Bucket-B
`r∩t` agreement.
```

The first sweep is one-time, manually triggered via `/cogni-workspace:manage-markets promote` — it shrinks the baseline by 97 promotions (53 Bucket A + 44 Bucket B). After it merges and the baseline is refreshed, the steady-state monthly sweep usually finds nothing to promote.

## Obsidian Integration

- Obsidian vault setup and updates are handled as sub-steps of `manage-workspace` (Init Mode step 6, Update Mode step 6)
- `scripts/setup-obsidian.sh` scaffolds a complete `.obsidian/` vault config with Terminal plugin and Claude Code launcher
- `scripts/update-obsidian.sh` incrementally updates terminal profiles without overwriting user customizations
- Both scripts use `bash/portability-utils.sh` for cross-platform support (macOS, Linux, WSL)
- Obsidian templates live in `templates/obsidian/`
- See `references/note-frontmatter-standard.md` for the YAML frontmatter convention used by all plugin outputs
