---
name: wiki-health
description: "Run a fast, zero-LLM structural integrity check on a Karpathy-style wiki — broken [[wikilinks]], missing frontmatter fields, broken raw/wiki:// sources, id mismatches, invalid type values, stub pages, and entries_count drift between config.json and the filesystem. Use this skill whenever the user says 'health check the wiki', 'is the wiki broken', 'wiki health', 'preflight the wiki', 'check wiki structure', or as the first step before any tokenful audit. wiki-resume runs this skill automatically at session start. Cheap, deterministic, every-session."
allowed-tools: Read, Bash, Glob
---

# Wiki Health

A zero-LLM, deterministic structural integrity check. Health is to lint what `git status` is to `git log` — a free pre-flight you can run any time without thinking about token cost. Health surfaces only what's mechanically broken; the semantic interpretation belongs to `wiki-lint`.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once for new sessions.

## When to run

- Automatically by `wiki-resume` at session start (no user action needed)
- User asks "is the wiki broken", "health check the wiki", "wiki health", "preflight the wiki"
- Before every `wiki-lint` invocation as a free preflight (lint refuses to run a tokenful semantic pass while structural errors are pending)
- Before publishing or sharing the wiki

## Never run when

- There is no wiki in the working directory — offer `wiki-setup`
- The wiki is empty (`entries_count: 0`) — there is nothing structural to check

## Why this skill exists separately from `wiki-lint`

llm-wiki-agent draws a sharp boundary that cogni-wiki was missing:

| Dimension | `wiki-health` | `wiki-lint` |
|---|---|---|
| **Scope** | Structural integrity | Content quality (semantic) |
| **LLM calls** | Zero | Yes — contradictions, type drift, missing concepts |
| **Cost** | Free | Tokens |
| **Frequency** | Every session | Every 10–15 ingests |
| **Run order** | First (pre-flight) | After health passes |

> Run `health` first — linting an empty file wastes tokens.

The two payoffs:

1. A free, every-session pre-flight the user can run without thinking. Today the user has to mentally pre-commit to a tokenful `wiki-lint` to learn that an `index.md` line points to a nonexistent file.
2. Headroom for a semantic lint (contradictions, stale claims, missing concept pages) that's always tokenful — and that we no longer pay for just to find broken wikilinks.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Override the auto-detected wiki root |
| `--quiet` | No | Suppress the prose summary; emit only the script JSON. Used by `wiki-resume`. |

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. If none, stop and offer `wiki-setup`.

### 2. Run the health script

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py --wiki-root <path>`. The script emits JSON with the `{success, data, error}` contract. On `success: false`, surface the raw error and stop — do not attempt a partial summary.

The script's `data` payload contains:

```
{
  "errors":   [{"class": "...", "page": "...", "message": "..."}, ...],
  "warnings": [{"class": "...", "page": "...", "message": "..."}, ...],
  "stats": {
    "pages_audited":         <int>,
    "errors":                <int>,
    "warnings":              <int>,
    "entries_count_config":  <int>,    // value from .cogni-wiki/config.json
    "entries_count_actual":  <int>,    // file count under wiki/pages/ excl. lint-*
    "entries_count_drift":   <int>,    // actual - config
    "claim_drift_count":     <int>,    // 0 when no last-resweep.json present
    "claim_drift_date":      <ISO>     // null when no last-resweep.json present
  }
}
```

Error classes: `broken_wikilink`, `missing_frontmatter`, `id_mismatch`, `invalid_type`, `missing_source`, `broken_wiki_source`, `read_error`.

Warning classes (structural debt only — semantic warnings live in `wiki-lint`): `stub_page`, `entries_count_drift`, `index_filesystem_drift`.

### 3. Append to `wiki/log.md`

Unconditionally — even on a clean run — append:

```
## [{YYYY-MM-DD}] health | {N} errors, {N} warnings
```

The log line has a dedicated `health` operation prefix so `wiki-resume` and `wiki-dashboard` can count health runs separately from lint runs. Health runs are expected to be frequent (every session); their log entries are the cheapest possible record that the pre-flight happened.

### 4. Report to the user

Unless `--quiet`, print a ≤5-line summary:

```
Health: {N} errors, {N} warnings ({pages_audited} pages audited)
{If errors > 0: list the first 3 errors with page slugs}
{If entries_count_drift != 0: "⚠ entries_count says {config} but filesystem has {actual}"}
{If claim_drift_count > 0: "⚠ {N} pages flagged by last resweep ({date})"}
Next: {recommendation — see decision tree below}
```

#### Recommendation decision tree

Apply the first rule that matches:

1. **`errors > 0`** → "Fix the {N} structural errors via `/cogni-wiki:wiki-update` before running anything else. Errors block reliable reads."
2. **`entries_count_drift != 0`** → "`entries_count` is out of sync with the filesystem. Run `/cogni-wiki:wiki-ingest` to bump the counter, or hand-edit `.cogni-wiki/config.json` to match (it should be {actual})."
3. **`warnings > 0` AND `claim_drift_count > 0`** → "{N} structural warnings + {M} claim drifts from the last resweep. Run `/cogni-wiki:wiki-lint` for a semantic pass that narrates the drifts."
4. **`warnings > 0`** → "{N} structural warnings (stubs / drift). Address via `/cogni-wiki:wiki-update`, or run `/cogni-wiki:wiki-lint` for a full semantic pass."
5. **Else** → "Clean health. The wiki is structurally sound — proceed with whatever you were doing."

### 5. Do not write anything to wiki pages

This skill is **report-only**. It writes the log line and nothing else. Auto-fixes are explicitly not in scope — the same Karpathy-pattern discipline that keeps `wiki-lint` from auto-fixing applies to health: fixes happen via `wiki-update`, with diff-before-write review.

## Output

- Stdout: prose summary (omitted if `--quiet`)
- `wiki/log.md` appended with the `health` line
- Nothing written to `wiki/pages/` or `.cogni-wiki/config.json`

## Golden rules

1. **Zero LLM calls.** Health is structural integrity only. Any check that needs reasoning belongs in `wiki-lint`.
2. **Always log, even on clean runs.** The log is the audit trail; absence of health runs is itself a smell.
3. **Never auto-fix.** Findings are reported; fixes go through `wiki-update`.
4. **Cheap enough to run every session.** If a check would push the script past ~1 second on a 100-page wiki, it belongs in `wiki-lint`, not here.
5. **Same `{success, data, error}` JSON contract** as every other cogni-wiki script.

## Boundary with `wiki-lint`

| Check | Owner | Why |
|-------|-------|-----|
| Broken `[[wikilink]]` | `wiki-health` | Structural — file either exists or doesn't |
| Missing required frontmatter | `wiki-health` | Schema check — deterministic |
| Invalid `type:` value | `wiki-health` | Schema check — deterministic |
| Filename / `id:` mismatch | `wiki-health` | Schema check — deterministic |
| Missing `../raw/` source file | `wiki-health` | Filesystem check — deterministic |
| Broken `wiki://` source | `wiki-health` | Structural — target page either exists or doesn't |
| Stub page (body < 50 chars) | `wiki-health` | Length check — deterministic |
| `entries_count` drift | `wiki-health` | Counter vs filesystem — deterministic |
| `index.md` ↔ filesystem drift | `wiki-health` | Set difference — deterministic |
| Claim-drift **count** from last resweep | `wiki-health` | Counter — deterministic |
| Orphan page | `wiki-lint` | Reportable but rarely urgent — debt, not breakage |
| Stale draft / stale page | `wiki-lint` | Date math + judgement on what "stale" means in context |
| Tag typo | `wiki-lint` | Edit-distance + ratio heuristic, often false-positive |
| Reverse-link missing | `wiki-lint` | SCHEMA contract violation — needs narrative + fix path |
| Synthesis page without `wiki://` source | `wiki-lint` | Bridge to file-back discipline; better narrated |
| Claim-drift **narrative** (per page) | `wiki-lint` | Reading the resweep report and explaining severity |
| **Contradictions across pages** | `wiki-lint` (LLM) | Semantic — needs reading |
| **Type drift** (concept page that's actually a summary) | `wiki-lint` (LLM) | Semantic — needs reading |
| **Undercited claims** | `wiki-lint` (LLM) | Semantic — needs reading |
| **Missing concept pages** (entity in 3+ pages, no own page) | `wiki-lint` (LLM) | Semantic — needs reading |

Rule of thumb: if a check needs `Read` on more than its own targets to decide, it goes to lint.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/checks.md` — the full list of structural checks with detection logic
- `./scripts/health.py` — the deterministic check engine
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/SKILL.md` — the semantic counterpart
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/references/severity-tiers.md` — the full health-vs-lint boundary table
