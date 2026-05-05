---
name: wiki-lint
description: "Run a semantic, LLM-powered audit of a Karpathy-style wiki — contradictions across pages, type drift (a 'concept' page that's actually a 'summary'), undercited claims, missing concept pages (entities mentioned in 3+ pages but lacking their own page), plus the deterministic-but-narrative warnings (orphans, stale drafts, tag typos, reverse-link gaps, claim-drift severity from the latest resweep). Calls wiki-health first as a free preflight; refuses to run while structural errors are pending. Writes a severity-tiered report to wiki/pages/lint-YYYY-MM-DD.md and always appends to wiki/log.md. Use this skill whenever the user says 'lint the wiki', 'audit my wiki', 'check the wiki for contradictions', 'wiki lint', 'find stale claims', or as a periodic maintenance pass after every ~10–15 ingests. For a fast structural-only check, use wiki-health instead."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Wiki Lint

Run a semantic, LLM-powered audit. Lint is what `wiki-health` is **not** — it's the tokenful pass that reads pages and reasons about them: contradictions, type drift, undercited claims, missing concept pages, and the narrative interpretation of `claim_drift` from the latest resweep.

The deterministic structural checks (broken wikilinks, missing frontmatter, broken sources, id mismatches, invalid types, stub pages, entries_count drift, index↔filesystem drift) live in `wiki-health`. Lint **always runs health first** as a free preflight — and refuses to run the tokenful semantic pass while structural errors are pending, because reasoning about a wiki with broken links wastes tokens and confuses the model.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start of any lint session.

## When to run

- User asks to lint, audit, contradiction-check, or content-quality-check the wiki
- `wiki-resume` reports `last_lint` is null or >14 days old
- After every ~10–15 ingests as a maintenance cadence
- Before exporting or sharing the wiki with someone else
- After a `wiki-claims-resweep` run, to narrate the drift findings

## Never run when

- The wiki is empty (`entries_count: 0`) — there is nothing to lint
- `wiki-health` reports structural errors > 0 (refuse and direct the user to fix structure first; semantic reasoning about a broken wiki wastes tokens). Override with `--ignore-health` if the user explicitly wants the semantic pass anyway, but warn loudly.
- Another `wiki-lint` is already in progress (check for a `lint-YYYY-MM-DD.md` being written in the current session)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Override the auto-detected wiki root |
| `--skip-semantic` | No | Skip the LLM-driven contradiction/type-drift/missing-concept pass. Equivalent to running `wiki-health` plus the deterministic warnings (orphans, stale, tag typos, reverse links). Use when you want a tokenless full deterministic pass. |
| `--ignore-health` | No | Run the semantic pass even when `wiki-health` reports errors. Discouraged — fix structural errors first. |
| `--semantic-page-cap` | No | Maximum number of pages sampled for the semantic pass. Default: 20. |

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. Set `wiki-root`.

### 2. Run wiki-health as preflight

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py --wiki-root <path>`. This is the same script `wiki-health` runs — by sharing the engine, lint and health stay consistent on what counts as a structural error.

If `data.stats.errors > 0` and `--ignore-health` was not passed, refuse to continue:

> wiki-health reports {N} structural errors. Fix them via /cogni-wiki:wiki-update before running a semantic lint, or pass --ignore-health to override (not recommended; reasoning about a broken wiki wastes tokens).

Log a `lint | refused (health failed)` line to `wiki/log.md` and stop. Otherwise carry the health summary forward — it goes into the lint report.

### 3. Run the deterministic warning pass (lint_wiki.py)

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py --wiki-root <path>`. The script emits JSON with the warnings/info that need narrative — orphans, stale drafts, tag typos, reverse-link gaps, synthesis-without-wiki-source, claim_drift per page. The structural errors that lint_wiki.py also emits are redundant with health (same engine semantics) and should be deduplicated against the health output when composing the report.

### 4. Run the LLM-powered semantic pass

Unless `--skip-semantic`, sample up to `--semantic-page-cap` pages (or all of them if `entries_count < cap`) and apply each of the four semantic checks below. Track token cost and surface it in the report.

#### 4a. Contradictions across pages

Group pages by overlap of `tags:` + frontmatter `type:` + most-linked targets. For each group, ask: "Do any of these pages make opposing claims about the same entity, concept, or decision?" Record findings as `contradiction` warnings with the two page slugs and a one-sentence reconciliation hint.

#### 4b. Type drift

For each sampled page, compare the declared `type:` against the body shape:

- `concept` should be a definitional/explanatory page about an idea
- `entity` should describe a person, organization, product, or thing
- `summary` should compress a single source
- `decision` should record what was chosen and why
- `learning` should distil a takeaway from experience
- `synthesis` should weave findings across multiple wiki pages

Flag mismatches as `type_drift` warnings with the suggested correct type.

#### 4c. Undercited claims

Scan page bodies for strong factual claims (numbers, named entities, dated events) that lack a citation in the surrounding sentence or in `sources:`. Flag as `undercited_claim` warnings with the sentence quoted.

#### 4d. Missing concept pages

Scan all pages for entity/concept names that recur across **3 or more** pages but have no page of their own under `wiki/pages/`. Flag as `missing_concept_page` info items with the recurring name and the pages that mention it.

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

- Health: 🔴 {N} errors · 🟡 {N} warnings (from wiki-health preflight)
- Lint:   🟡 {N} warnings · 🔵 {N} info (deterministic + semantic)
- Pages audited: {N}
- Semantic pass: {yes / skipped / N pages sampled}
- Token cost (semantic pass): ~{N} input + {N} output tokens

## 🔴 Errors (from wiki-health)

{Listed verbatim from health.data.errors. If empty, say "None — health is clean."}

## 🟡 Warnings — deterministic

### Orphan pages
- `[[page-c]]` — no inbound links
- ...

### Stale drafts / pages
- `[[page-d]]` — `updated: 2025-08-01`, 255 days old, status: draft

### Probable tag typos
- `mashine-learning` (3 uses) vs `machine-learning` (17 uses)

### Reverse-link gaps (SCHEMA R1)
- `[[page-e]]` is linked from `[[page-f]]` but does not link back

### Synthesis pages without wiki:// source
- `[[synthesis-x]]` — `type: synthesis` but no `wiki://` entry in sources

### Claim drift (from last resweep, {date})
- `[[page-g]]` — 2 claims deviated, 1 source unavailable; see `raw/claims-resweep-{date}/report.md`

## 🟡 Warnings — semantic (LLM)

### Contradictions
- `[[page-h]]` claims X. `[[page-i]]` claims ¬X. Reconcile via `wiki-update`.

### Type drift
- `[[page-j]]` declared `concept` but body is a `summary` of one source. Suggest retype.

### Undercited claims
- `[[page-k]]`: "Revenue grew 47% YoY in 2025" — no citation in sources or sentence.

## 🔵 Info

- Total pages: 47
- By type: 18 concept, 12 summary, 8 learning, 5 entity, 3 decision, 1 note
- Average sources per page: 1.8
- Log entries in last 30 days: 12 ingests, 24 queries, 1 lint (previous), 7 health
- Most-linked pages: [[llm-wiki-pattern]] (8), [[compounding-knowledge]] (6), ...
- Missing concept pages (mentioned in ≥3 pages, no own page):
  - "Constitutional AI" — mentioned in [[bai-2022]], [[anthropic-overview]], [[rlhf-survey]]

## Next actions

{A short prose section recommending what to fix first — health errors always first, then contradictions, then stale drafts, then deterministic warnings.}
```

### 6. Update the index

Add the lint report to `wiki/index.md` under a `## Maintenance` category (create the heading if it doesn't exist). Entry format:

```
- [[lint-2026-04-12]] — Lint report: {N} health errors, {N} lint warnings
```

### 7. Append to the log — unconditionally

```
## [{YYYY-MM-DD}] lint | {N} health errors, {N} lint warnings, ~{N} tokens
```

Even when the wiki is clean (zero findings), log the lint run. The log is the audit trail. The token-cost annotation is what makes lint visibly different from `health` in the log — health is free and runs every session; lint is paid and runs periodically.

### 8. Update `.cogni-wiki/config.json`

Set `last_lint` to today's ISO date. Leave `entries_count` untouched (the lint report itself is a page, so increment accordingly — it counts as one page).

### 9. Report to the user

Print a ≤5-line summary:
- Health snapshot from preflight (N errors, N warnings)
- Lint counts (deterministic + semantic)
- Top 3 findings across all tiers
- Token cost
- Path to the full report

## Output

- `wiki/pages/lint-YYYY-MM-DD.md` — the lint report
- `wiki/index.md` updated with the report entry
- `wiki/log.md` appended with the lint line
- `.cogni-wiki/config.json` `last_lint` updated

## Rules

1. **Never auto-fix findings.** Lint only reports because auto-fixing bypasses the diff-before-write review that catches unintended changes. Fixes happen via `wiki-update`.
2. **Log even on clean runs.** The absence of findings is itself useful signal.
3. **Contradictions are surfaced, not resolved.** Only `wiki-update` reconciles them.
4. **Health gates lint.** A wiki with structural errors does not get a tokenful semantic pass unless the user explicitly overrides — otherwise the LLM reasons over a broken graph and produces noisy findings.
5. **Surface token cost.** Every lint run reports approximately how many tokens the semantic pass consumed. Health is free; lint is paid; the user should always know which they ran.
6. **Report date is the invocation date** — if the lint runs at 23:59 and writes past midnight, the filename uses the invocation date.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/severity-tiers.md` — tier definitions and the full health-vs-lint coverage matrix
- `./scripts/lint_wiki.py` — deterministic warning pass (orphans, stale, tag typos, reverse links, claim_drift narrative)
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/SKILL.md` — the structural counterpart, run as preflight
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py` — the structural integrity engine
