---
name: wiki-resume
description: "Show status, activity, health snapshot, and recommended next action for a Karpathy-style wiki — entry count, days since last lint, recent log activity, stale drafts, structural-integrity errors from wiki-health (run automatically every session), and what the user should do next. Use this skill whenever the user says 'resume the wiki', 'wiki status', 'what's in my wiki', 'where was I with the wiki', 'wiki resume', 'show me the wiki overview', or asks 'what should I do next with my wiki'. Also trigger proactively after a wiki-setup or a long gap between invocations to orient the user."
allowed-tools: Read, Bash, Glob
---

# Wiki Resume

Give the user a fast, grounded status view of their wiki so they know what's inside and what the right next action is. As of v0.0.27, resume also runs `wiki-health` automatically as part of every status call — a free, zero-LLM structural pre-flight that surfaces broken wikilinks, missing frontmatter, and other mechanical issues without the user having to think about it. No writing to wiki pages — this skill is read-only against the wiki itself; it only logs the health invocation it dispatches.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once for new sessions.

## When to run

- User asks for status, overview, or "where was I" on the wiki
- User returns after a gap and wants orientation
- `wiki-setup` just finished and the user needs guidance on the first action
- Proactively after any long idle period between wiki invocations

## Never run when

- There is no wiki in the working directory — offer `wiki-setup`

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Override the auto-detected wiki root |
| `--verbose` | No | Include the last 10 log entries verbatim, not just counts |
| `--skip-health` | No | Skip the automatic `wiki-health` preflight. Use only when health.py is broken or you want a literal no-side-effect read. |

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. If none, stop and offer `wiki-setup`.

### 2. Run the status script (which now also runs wiki-health)

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-resume/scripts/wiki_status.sh --wiki-root <path>`. Unless `--skip-health` is passed, the script shells out to `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py` once and folds the result into its JSON output. If the script exits non-zero or returns malformed JSON, fall back to reading `config.json` and `wiki/log.md` directly — report what you can, note that the full status script failed, and suggest the user check `wiki_status.sh` manually.

The script emits JSON with:

- `name`, `slug`, `created`, `description` — from `config.json`
- `entries_count` — actual file count in the per-type page dirs excluding `lint-*.md` and `health-*.md`
- `lint_count` — number of `lint-*.md` reports
- `last_lint` — ISO date of most recent lint report file
- `days_since_lint` — integer or `null`
- `recent_log` — last 10 lines of `wiki/log.md`
- `ingest_count_30d` — number of `## [YYYY-MM-DD] ingest` lines in the last 30 days
- `query_count_30d` — number of `query` lines in the last 30 days (un-filed reads)
- `synthesis_count_30d` — number of `synthesis` lines (filed-back query answers) in the last 30 days; introduced in v0.0.23
- `update_count_30d` — same for updates
- `health_count_30d` — number of `health` lines (introduced in v0.0.27); a healthy session-start cadence puts this at one or more per active day
- `raw_file_count` — files in `raw/`
- `orphan_raw_count` — files in `raw/` not referenced by any page frontmatter (quick heuristic)
- `schema_version` — value of `schema_version` in `.cogni-wiki/config.json`, or `null` if absent. Used by Step 3's Schema section to surface a migration nudge when the wiki predates the most recent SCHEMA.md additions.
- `health` — a sub-object with `available`, `errors`, `warnings`, `entries_count_drift`, `claim_drift_count`, `claim_drift_date`. `available: false` when the health.py invocation failed; the rest of the status block still works.

### 3. Compose the status view

Print a short prose status block to the user:

```
# Wiki: {name}
_Slug_: {slug}
_Created_: {created}
_Description_: {description}

## Health (preflight, every session)
{if health.available is false:
- "⚠ wiki-health did not run cleanly — see wiki_status.sh logs. Status below uses cached counts only."
else:
- {N} errors, {N} warnings
- {if health.entries_count_drift != 0: "entries_count drift: {drift:+d} (config vs filesystem)"}
- {if health.claim_drift_count > 0: "{N} pages flagged by last resweep ({date})"}
}

## Activity (last 30 days)
- {N} ingests · {N} queries · {N} syntheses · {N} updates · {N} health

## Inventory
- {entries_count} pages
- {raw_file_count} raw sources ({orphan_raw_count} unused)
- {lint_count} lint reports ({days_since_lint} days since last)

## Schema
- schema_version: {schema_version}
{if schema_version is null OR schema_version < "0.0.4":
- "Older than v0.0.4 — the SCHEMA.md shipped with this wiki is missing one or both of the following sections, depending on how old the wiki is. Apply the missing pieces from `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/references/SCHEMA.md.template`, then bump `schema_version` to `"0.0.4"` in `.cogni-wiki/config.json`. The migration is offline-safe and idempotent — lint and health work either way; the SCHEMA changes only ensure the contract is auditable when reading the wiki on its own.
  - If schema_version < 0.0.3: append the `## Forward → reverse link contract` section between the existing `## Linking` and `## Log format` sections.
  - If schema_version < 0.0.4: broaden the `## Log format` operation enum to `{ingest|query|synthesis|lint|health|update|setup}`, and rename the `R3_lint_report` row in the forward→reverse contract table to `R3_audit_report` covering both `[[lint-YYYY-MM-DD]]` and `[[health-YYYY-MM-DD]]` filenames. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/SKILL.md` §"Migration for existing wikis" for the full step-by-step."
}

## Recent log (last 10 lines)
{if --verbose, print them; otherwise print the most recent 3}

## Recommended next action
{see decision tree below}
```

The `syntheses` count surfaces filed-back query answers — a non-zero number is a signal that the wiki is compounding, not just accumulating raw sources. A wiki with high ingest count but zero syntheses suggests the user isn't asking the wiki questions yet; rule 5 below nudges toward `wiki-query` in that case. The `health` count is the new v0.0.27 signal: zero in the last 30 days means session-start preflight isn't happening, and the user should be encouraged to invoke `wiki-resume` (which runs health) more often.

### 4. Recommend next action (decision tree)

Apply the first rule that matches:

1. **`health.available AND health.errors > 0`** → "wiki-health flagged {N} structural errors. Fix them via `/cogni-wiki:wiki-update` before anything else — errors block reliable reads. The errors are listed above."
2. **`health.available AND health.entries_count_drift != 0`** → "`entries_count` is out of sync with the filesystem (drift={drift:+d}). Run `/cogni-wiki:wiki-ingest` to bump the counter, or hand-edit `.cogni-wiki/config.json` to match."
3. **`health.available AND health.claim_drift_count > 0 AND days_since_lint > 14`** → "{N} pages flagged by the last resweep ({date}) and lint hasn't run in {days} days. Run `/cogni-wiki:wiki-lint` for the semantic narrative."
4. **`entries_count == 0`** → "Drop a source in `raw/` and run `/cogni-wiki:wiki-ingest`."
5. **`orphan_raw_count > 0`** → "You have {N} raw sources that aren't yet in the wiki. Run `/cogni-wiki:wiki-ingest --discover orphans --discover-dry-run` to review them, then drop `--discover-dry-run` to ingest. No need to hand-craft a batch file — the skill enumerates the orphans for you."
6. **`days_since_lint == null` OR `days_since_lint > 14`** → "It's been {N} days (or never) since the last lint. Run `/cogni-wiki:wiki-lint`."
7. **`ingest_count_30d == 0 AND query_count_30d == 0 AND synthesis_count_30d == 0 AND update_count_30d == 0`** → "The wiki hasn't been touched in 30 days. Either ingest something new or run `/cogni-wiki:wiki-query` to reactivate it."
8. **`entries_count >= 5 AND query_count_30d == 0 AND synthesis_count_30d == 0`** → "You have {entries_count} pages but haven't asked the wiki anything in 30 days. Run `/cogni-wiki:wiki-query --question '...' --file-back yes` to compound a synthesis page."
9. **Else** → "The wiki looks healthy. Continue with whatever you were doing, or run `/cogni-wiki:wiki-dashboard` for a visual overview."

Rules 1–3 are new in v0.0.27 — they fire on the freshly-collected health snapshot so structural problems surface before any other recommendation. The deterministic split lets resume make a confident statement about what is broken without burning lint tokens. Rule 5's concrete `--discover` command is deliberate: the older prose-only recommendation ("run wiki-ingest on them") left Claude (and by extension the user) to figure out how to enumerate the orphans, which in practice meant asking the user to type them out. Rule 8 surfaces the "the wiki is a vault, but you haven't asked it anything" anti-pattern that file-back synthesis pages were built to fix.

### 5. Side effects

This skill is read-only against `wiki/<type>/` and `.cogni-wiki/config.json` — it never edits them. The one side effect introduced in v0.0.27 is that the dispatched `wiki-health` invocation appends a `## [YYYY-MM-DD] health | N errors, N warnings` line to `wiki/log.md`. That's intentional: every health pre-flight should be on the audit trail, and resume is the canonical session-start trigger. Use `--skip-health` if you genuinely want zero side effects.

## Output

- A prose status block printed to the user (with a Health section)
- One `health` line appended to `wiki/log.md` (skip with `--skip-health`)

## Golden rules

1. **Read-only against wiki pages.** Resume never modifies `wiki/<type>/`, `wiki/index.md`, or `.cogni-wiki/config.json`.
2. **Health is automatic.** The user shouldn't have to remember to preflight — resume does it for them.
3. **Always recommend an action.** The user should leave this skill knowing what to do next.
4. **Ground the numbers in the filesystem**, not in cached config values — the script counts files directly so a stale `entries_count` in `config.json` doesn't mislead.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./scripts/wiki_status.sh` — the status collector (now also dispatches health.py)
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/SKILL.md` — the structural pre-flight skill
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py` — the deterministic check engine
