---
name: wiki-resume
description: "Show status, activity, and recommended next action for a Karpathy-style wiki — entry count, days since last lint, recent log activity, stale drafts, and what the user should do next. Use this skill whenever the user says 'resume the wiki', 'wiki status', 'what's in my wiki', 'where was I with the wiki', 'wiki resume', 'show me the wiki overview', or asks 'what should I do next with my wiki'. Also trigger proactively after a wiki-setup or a long gap between invocations to orient the user."
allowed-tools: Read, Bash, Glob
---

# Wiki Resume

Give the user a fast, grounded status view of their wiki so they know what's inside and what the right next action is. No writing — this skill only reads.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once for new sessions. Resume is a read-only skill — it never edits the wiki.

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

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. If none, stop and offer `wiki-setup`.

### 2. Run the status script

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-resume/scripts/wiki_status.sh --wiki-root <path>`. The script emits JSON with:

- `name`, `slug`, `created`, `description` — from `config.json`
- `entries_count` — actual file count in `wiki/pages/` excluding `lint-*.md`
- `lint_count` — number of `lint-*.md` reports
- `last_lint` — ISO date of most recent lint report file
- `days_since_lint` — integer or `null`
- `recent_log` — last 10 lines of `wiki/log.md`
- `ingest_count_30d` — number of `## [YYYY-MM-DD] ingest` lines in the last 30 days
- `query_count_30d` — number of query lines in the last 30 days
- `update_count_30d` — same for updates
- `raw_file_count` — files in `raw/`
- `orphan_raw_count` — files in `raw/` not referenced by any page frontmatter (quick heuristic)

### 3. Compose the status view

Print a short prose status block to the user:

```
# Wiki: {name}
_Slug_: {slug}
_Created_: {created}
_Description_: {description}

## Activity (last 30 days)
- {N} ingests · {N} queries · {N} updates

## Inventory
- {entries_count} pages
- {raw_file_count} raw sources ({orphan_raw_count} unused)
- {lint_count} lint reports ({days_since_lint} days since last)

## Recent log (last 10 lines)
{if --verbose, print them; otherwise print the most recent 3}

## Recommended next action
{see decision tree below}
```

### 4. Recommend next action (decision tree)

Apply the first rule that matches:

1. **`entries_count == 0`** → "Drop a source in `raw/` and run `/cogni-wiki:wiki-ingest`."
2. **`orphan_raw_count > 0`** → "You have N raw sources that aren't yet in the wiki. Run `/cogni-wiki:wiki-ingest` on them."
3. **`days_since_lint == null` OR `days_since_lint > 14`** → "It's been {N} days (or never) since the last lint. Run `/cogni-wiki:wiki-lint`."
4. **`ingest_count_30d == 0 AND query_count_30d == 0 AND update_count_30d == 0`** → "The wiki hasn't been touched in 30 days. Either ingest something new or run `/cogni-wiki:wiki-query` to reactivate it."
5. **Else** → "The wiki looks healthy. Continue with whatever you were doing, or run `/cogni-wiki:wiki-dashboard` for a visual overview."

### 5. Do not write anything

This skill is strictly read-only. Do not append to the log. Do not touch `config.json`. Do not create files. The only side effect is the status printed to the user.

## Output

- A prose status block printed to the user
- Nothing written to disk

## Golden rules

1. **Read-only.** Resume never writes.
2. **Always recommend an action.** The user should leave this skill knowing what to do next.
3. **Ground the numbers in the filesystem**, not in cached config values — the script counts files directly so a stale `entries_count` in `config.json` doesn't mislead.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./scripts/wiki_status.sh` — the status collector
