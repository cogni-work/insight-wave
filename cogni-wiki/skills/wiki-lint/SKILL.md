---
name: wiki-lint
description: "Run a semantic, LLM-powered audit of a Karpathy-style wiki — contradictions across pages, type drift (a 'concept' page that's actually a 'summary'), undercited claims, missing concept pages (entities mentioned in 3+ pages but lacking their own page), plus the deterministic-but-narrative warnings (orphans, stale drafts, tag typos, reverse-link gaps, claim-drift severity from the latest resweep). As of v0.0.32, ships deterministic auto-fixers behind opt-in flags (--fix=reverse_link_missing, --fix=synthesis_no_wiki_source, --fix=entries_count_drift, --fix=frontmatter_defaults, --fix=alphabetisation, --fix=all) plus --suggest for structured proposals on prose-shaped findings, and --dry-run for plan-without-write. Calls wiki-health first as a free preflight; refuses to run while structural errors are pending. Writes a severity-tiered report to wiki/audits/lint-YYYY-MM-DD.md and always appends to wiki/log.md. Use this skill whenever the user says 'lint the wiki', 'audit my wiki', 'check the wiki for contradictions', 'wiki lint', 'find stale claims', or as a periodic maintenance pass after every ~10–15 ingests. For a fast structural-only check, use wiki-health instead."
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
| `--skip-rebuild-open-questions` | No | Skip Step 8.5 (`rebuild_open_questions.py`). Use when investigating a rebuild bug or running a literal no-side-effect lint pass. v0.0.30+. |
| `--fix=<class>` | No | Apply the deterministic auto-fix for one or more lint classes (repeatable; `--fix=all` enables every safe class). Supported: `reverse_link_missing`, `synthesis_no_wiki_source`, `entries_count_drift`, `frontmatter_defaults`, `alphabetisation`. v0.0.32+ (#222). See §"Auto-fix mode" below. |
| `--suggest` | No | Emit `data.suggestions[]` — structured proposals for prose-shaped findings (`orphan_page`, `stale_*`, `claim_drift`, `tag_typo`). Schema documented in §"Suggestion schema". v0.0.32+ (#222). |
| `--dry-run` | No | Pair with `--fix` and/or `--suggest` to compute the plan without writing. Every `data.fixed[]` entry has `applied: false`; on-disk SHA is unchanged. v0.0.32+ (#222). |

## Workflow

### 1. Locate the wiki

Walk upward to find `.cogni-wiki/config.json`. Set `wiki-root`.

### 2. Run wiki-health as preflight

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py --wiki-root <path>`. This is the same script `wiki-health` runs — by sharing the engine, lint and health stay consistent on what counts as a structural error.

If `data.stats.errors > 0` and `--ignore-health` was not passed, refuse to continue:

> wiki-health reports {N} structural errors. Fix them via /cogni-wiki:wiki-update before running a semantic lint, or pass --ignore-health to override (not recommended; reasoning about a broken wiki wastes tokens).

Log a `lint | refused (health failed)` line to `wiki/log.md` and stop. Otherwise carry the health summary forward — it goes into the lint report.

### 3. Run the deterministic warning pass (lint_wiki.py)

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/lint_wiki.py --wiki-root <path>`. The script emits JSON with the warnings/info that need narrative — `orphan_page`, `stale_draft`, `stale_page`, `tag_typo`, `reverse_link_missing`, `no_sources`, `synthesis_no_wiki_source`, `claim_drift`, plus the `info` block (page totals, by-type counts, last-resweep summary). As of v0.0.31 (#223) `data.errors` is always an empty list — every structural integrity check has been moved to `health.py`, which Step 2 already ran. No deduplication step is needed when composing the report; lint and health are now strict partitions.

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

Scan all pages for entity/concept names that recur across **3 or more** pages but have no page of their own under `wiki/<type>/`. Flag as `missing_concept_page` info items with the recurring name and the pages that mention it.

### 5. Write the lint report

Path: `<wiki-root>/wiki/audits/lint-{YYYY-MM-DD}.md`

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

### 8.5. Rebuild `wiki/open_questions.md` (v0.0.30+)

Run **once per dispatch** after Step 8. The file is the persistent backlog that compounds across sessions: lint findings that point at "data gaps" (`no_sources`, `synthesis_no_wiki_source`, `claim_drift`, `orphan_page`, `stale_page`, `stale_draft`, `reverse_link_missing`) become `- [ ]` checklist items; items that disappear from a subsequent lint flip to `- [x]` with today's date and a best-effort "closed by" attribution from `wiki/log.md`. Closed items are trimmed after 90 days. The `## [YYYY-MM-DD] lint | …` line written in Step 7 is what makes the close-attribution work — Step 8.5 must run after Step 7.

Skip this step when `--skip-rebuild-open-questions` is set.

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-lint/scripts/rebuild_open_questions.py --wiki-root <wiki-root>
```

The script invokes `lint_wiki.py` itself as a subprocess (read-only, mirrors the deterministic Step 3 output) and reconciles against the existing `wiki/open_questions.md`. The read-modify-write is wrapped in `_wikilib._wiki_lock` because two concurrent `wiki-lint` dispatches from separate sessions would otherwise trample each other's reconciliation.

**LLM-emitted findings (Step 4d's `missing_concept_page` items) are not yet wired in** — v0.0.30 ships deterministic-only. The script accepts `--findings -` (JSON on stdin) for the follow-up that will pipe a merged finding set in from this step. Until then the "Missing concept pages" section is omitted.

**Failure isolation.** A non-zero exit or malformed JSON from `rebuild_open_questions.py` MUST NOT roll back the lint run. The audit report (Step 5), index update (Step 6), log line (Step 7), and `last_lint` bump (Step 8) are already on disk. Surface the error in the Step 9 report and continue — the next lint run will reconcile.

### 9. Report to the user

Print a ≤6-line summary:
- Health snapshot from preflight (N errors, N warnings)
- Lint counts (deterministic + semantic)
- Top 3 findings across all tiers
- Token cost
- Open-questions delta from Step 8.5 (`opened`, `closed`, `trimmed`) or the failure mode if the rebuild errored — v0.0.30+
- Path to the full report

## Output

- `wiki/audits/lint-YYYY-MM-DD.md` — the lint report
- `wiki/index.md` updated with the report entry
- `wiki/log.md` appended with the lint line
- `.cogni-wiki/config.json` `last_lint` updated
- `wiki/open_questions.md` rebuilt (v0.0.30+; persistent backlog of data-gap items, ≤90-day closed retention; never blocks the lint on failure)

## Auto-fix mode (v0.0.32+, #222)

`lint_wiki.py --fix=<class>` applies the deterministic auto-fix for the named class. Composes across flags; `--fix=all` enables every supported class. Pair with `--dry-run` to preview the plan without writing — `data.fixed[]` is populated with `applied: false`, on-disk state is unchanged.

The five supported classes:

| Class | What the fixer does | Locked write target |
|---|---|---|
| `reverse_link_missing` | Backfills the missing reverse `[[link]]` per SCHEMA `R1_bidirectional_wikilink`. Appends a `## See also` section (or extends an existing one) with `- [[source-slug]]` lines. Idempotent: a re-run is a no-op once the link is present. | per-type page body via `_wikilib.atomic_write` |
| `synthesis_no_wiki_source` | For each synthesis page: scans the body for `[[slug]]` mentions whose target exists in the wiki, then adds `wiki://<slug>` entries to the frontmatter `sources:` block. Skips pages whose existing sources already cover every body slug. | per-type page body via `_wikilib.atomic_write` |
| `frontmatter_defaults` | Backfills missing `id:` (= filename stem) and normalises non-ISO `updated:` dates to `YYYY-MM-DD`. Recognised input formats: `YYYY/MM/DD`, `DD-MM-YYYY`, `DD/MM/YYYY`, `MM/DD/YYYY`, `Month DD, YYYY` (full and abbreviated), `DD Month YYYY`. Pages without frontmatter at all are left to `health.py`'s `missing_frontmatter` error. | per-type page body via `_wikilib.atomic_write` |
| `entries_count_drift` | Counts non-audit pages via `iter_pages()` and reconciles `.cogni-wiki/config.json::entries_count` to that count. Routes the write through `config_bump.py --set-int` so the locked-script convention holds. No-op when the count already matches. | `config.json` via `config_bump.py` |
| `alphabetisation` | Re-sorts every category's contiguous bullet block in `wiki/index.md` alphabetically by slug. Non-bullet content (prose, blank lines outside the bullet block) is preserved in place. Routes through `wiki_index_update.py --reflow-only`. | `wiki/index.md` via `wiki_index_update.py` |

**Locking.** The three in-process page-body fixers (`reverse_link_missing`, `synthesis_no_wiki_source`, `frontmatter_defaults`) run inside one `_wiki_lock(wiki_root)` block so they serialise against concurrent `wiki-ingest` runs. The two scripted fixers (`entries_count_drift`, `alphabetisation`) acquire their own locks via the underlying scripts, after the in-process lock is released — no recursion, no deadlock.

**Fail-soft per item.** Each fixer wraps its per-page body in `try/except`; failures land in `data.failed[]` with `{class, page, error}` instead of aborting the whole fix phase. The `data.stats` block surfaces `fixes_applied`, `fixes_planned` (dry-run), `fixes_failed`, and `suggestions_emitted` so consumers can tell wet from dry without parsing entries.

**LLM-driven fixes are explicitly out of scope.** `--fix` only applies to the deterministic classes listed above; semantic fixes (contradictions, type drift, undercited claims, missing concept pages) remain `wiki-update`'s responsibility — they require human or LLM judgement.

## Suggestion schema (v0.0.32+, #222)

`--suggest` emits `data.suggestions[]` — one structured entry per qualifying warning. The schema is fixed in this PR so `wiki-update` (or any other consumer) can adopt it on its own schedule. No consumer wires it yet.

```jsonc
{
  "class": "orphan_page",                  // mirrors data.warnings[].class
  "page": "concept-foo",                   // wiki page slug, or "*" for tag_typo (cross-page)
  "proposed_action": "link_from",          // see vocabulary table below
  "candidates": ["concept-bar", "..."],    // when proposed_action implies a target page set
  "wiki_update_args": {                    // for invoke_wiki_update; ready for direct dispatch
    "reason": "refinement",
    "slug": "concept-foo"
  },
  "from_tag": "...", "to_tag": "...",       // for rename_tag only
  "justification": "shares 3 tags with these candidates"
}
```

`proposed_action` vocabulary, by warning class:

| Warning class | `proposed_action` | Extra fields |
|---|---|---|
| `orphan_page` | `link_from` (when there's at least one tag-overlap candidate) or `tag_for_audit` (no overlap) | `candidates`: top-3 tag-overlap slugs |
| `stale_draft`, `stale_page` | `review_or_retire` | — |
| `claim_drift` | `invoke_wiki_update` | `wiki_update_args: {reason, slug}` |
| `tag_typo` | `rename_tag` | `from_tag`, `to_tag` (parsed from the warning message) |

Suggestions never write to disk. `--suggest` is purely additive on top of the existing report and does not interact with `--fix` (you can pass both in one invocation; the fix phase runs first, then suggestions are emitted from the post-fix warning set).

## Rules

1. **Auto-fix is opt-in.** Lint reports findings by default. The deterministic fixers (`--fix=*`, v0.0.32+) only run when explicitly requested; LLM-driven and semantic fixes still happen via `wiki-update` because they require diff-before-write review and judgement.
2. **Log even on clean runs.** The absence of findings is itself useful signal.
3. **Contradictions are surfaced, not resolved.** Only `wiki-update` reconciles them.
4. **Health gates lint.** A wiki with structural errors does not get a tokenful semantic pass unless the user explicitly overrides — otherwise the LLM reasons over a broken graph and produces noisy findings.
5. **Surface token cost.** Every lint run reports approximately how many tokens the semantic pass consumed. Health is free; lint is paid; the user should always know which they ran.
6. **Report date is the invocation date** — if the lint runs at 23:59 and writes past midnight, the filename uses the invocation date.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/severity-tiers.md` — tier definitions and the full health-vs-lint coverage matrix
- `./scripts/lint_wiki.py` — deterministic warning pass (orphans, stale, tag typos, reverse links, claim_drift narrative)
- `./scripts/rebuild_open_questions.py` — Step 8.5: writes `wiki/open_questions.md` (persistent data-gap backlog as of v0.0.30; reconciles against prior state; locked RMW; 90-day closed retention)
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/SKILL.md` — the structural counterpart, run as preflight
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-health/scripts/health.py` — the structural integrity engine
