---
name: wiki-lint
description: "Audit a Karpathy-style wiki for health problems — broken [[wikilinks]], orphan pages with no inbound links, stale dates, missing frontmatter fields, contradictions between pages, tag typos, and sources that no longer exist in raw/. Writes a severity-tiered report to wiki/pages/lint-YYYY-MM-DD.md and always appends to wiki/log.md. Use this skill whenever the user says 'lint the wiki', 'check the wiki', 'audit my wiki', 'health check the wiki', 'wiki lint', 'find broken links in the wiki', 'is my wiki healthy', 'anything broken in the wiki', or after every ~5–10 ingests as a maintenance pass. Also trigger when `wiki-resume` reports the wiki has not been linted in a while."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Wiki Lint

Run a severity-tiered health audit over the wiki. Mechanical issues (broken links, missing frontmatter, orphan pages, stale dates, missing sources) are found by the `lint_wiki.py` script. Semantic issues (contradictions between pages, type drift, weak writing) are found by Claude reading the wiki with the script's output as a starting point.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start of any lint session.

## When to run

- User explicitly asks to lint, audit, or health-check the wiki
- `wiki-resume` reports `last_lint` is null or >14 days old
- After every ~5–10 ingests as a maintenance cadence
- Before exporting or sharing the wiki with someone else

## Never run when

- The wiki is empty (`entries_count: 0`) — there is nothing to lint
- Another `wiki-lint` is already in progress (check for a `lint-YYYY-MM-DD.md` being written in the current session)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Override the auto-detected wiki root |
| `--skip-semantic` | No | Skip the Claude-driven contradiction and type-drift pass. Fast mechanical-only mode. |

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. Set `wiki-root`.

### 2. Run the mechanical lint script

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py --wiki-root <path>`. The script emits JSON with three severity tiers: `errors`, `warnings`, `info`. If the script exits non-zero or returns malformed JSON, report the raw error to the user and stop — do not write a partial lint report.

### 3. Read the script output

The script categorizes findings into three severity tiers — see `./references/severity-tiers.md` for the full classification. In brief: **Errors** (broken structural contracts like dead wikilinks or missing frontmatter), **Warnings** (accumulating debt like orphan pages, stale drafts, tag typos, missing reverse links per the SCHEMA forward→reverse contract), **Info** (descriptive statistics like page counts and tag distribution).

The `reverse_link_missing` warning class enforces the wiki's SCHEMA `R1_bidirectional_wikilink` rule (page A contains `[[B]]` ⇒ page B should contain `[[A]]`). Surface these grouped by target page so the user can address them via a single `wiki-update` per page.

### 4. Read contradicted pages (semantic pass)

Unless `--skip-semantic`, sample up to 20 pages (or all of them if `entries_count < 20`) and look for:

- **Contradictions**: two pages making opposing claims about the same entity or concept
- **Type drift**: a page tagged `concept` whose body is actually a `summary` (or vice versa)
- **Undercited claims**: strong claims in page bodies that have no source citation

The semantic pass is best-effort. It never rewrites pages — it only records findings in the report.

### 5. Write the lint report

Path: `<wiki-root>/wiki/pages/lint-{YYYY-MM-DD}.md`

The lint report is itself a wiki page with frontmatter:

```yaml
---
id: lint-{YYYY-MM-DD}
title: Lint Report — {YYYY-MM-DD}
type: note
tags: [lint, maintenance]
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
---
```

Body structure:

```markdown
# Lint Report — {date}

## Summary

- 🔴 Errors: {N}
- 🟡 Warnings: {N}
- 🔵 Info points: {N}
- Pages audited: {N}
- Semantic pass: {yes/skipped}

## 🔴 Errors

### Broken wikilinks
- `[[non-existent-page]]` in `[[page-a]]`, line 12
- ...

### Missing frontmatter fields
- `[[page-b]]` — missing `type`
- ...

## 🟡 Warnings

### Orphan pages
- `[[page-c]]` — no inbound links
- ...

### Stale drafts
- `[[page-d]]` — `updated: 2025-08-01`, 255 days old, status: draft

### Probable tag typos
- `mashine-learning` (3 uses) vs `machine-learning` (17 uses)

### Contradictions (semantic)
- `[[page-e]]` claims X. `[[page-f]]` claims ¬X. Reconcile via `wiki-update`.

## 🔵 Info

- Total pages: 47
- By type: 18 concept, 12 summary, 8 learning, 5 entity, 3 decision, 1 note
- Average sources per page: 1.8
- Log entries in last 30 days: 12 ingests, 24 queries, 1 lint (previous)
- Most-linked pages: [[llm-wiki-pattern]] (8), [[compounding-knowledge]] (6), ...

## Next actions

{A short prose section recommending what to fix first — errors always first, then stale drafts, then contradictions.}
```

### 6. Update the index

Add the lint report to `wiki/index.md` under a `## Maintenance` category (create the heading if it doesn't exist). Entry format:

```
- [[lint-2026-04-12]] — Lint report: 2 errors, 5 warnings
```

### 7. Append to the log — unconditionally

```
## [{YYYY-MM-DD}] lint | {N} errors, {N} warnings
```

Even when the wiki is clean (zero findings), log the lint run. The log is the audit trail.

### 8. Update `.cogni-wiki/config.json`

Set `last_lint` to today's ISO date. Leave `entries_count` untouched (the lint report itself is a page, so increment accordingly — it counts as one page).

### 9. Report to the user

Print a ≤5-line summary:
- Severity counts
- Top 3 findings across all tiers
- Path to the full report
- Recommended next action

## Output

- `wiki/pages/lint-YYYY-MM-DD.md` — the lint report
- `wiki/index.md` updated with the report entry
- `wiki/log.md` appended with the lint line
- `.cogni-wiki/config.json` `last_lint` updated

## Rules

1. **Never auto-fix findings.** Lint only reports because auto-fixing bypasses the diff-before-write review that catches unintended changes. Fixes happen via `wiki-update`.
2. **Log even on clean runs.** The absence of findings is itself useful signal.
3. **Contradictions are surfaced, not resolved.** Only `wiki-update` reconciles them.
4. **Report date is the invocation date** — if the lint runs at 23:59 and writes past midnight, the filename uses the invocation date.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/severity-tiers.md` — tier definitions
- `./scripts/lint_wiki.py` — mechanical lint pass
