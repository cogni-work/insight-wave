# Plan: cogni-wiki #220 — persistent `wiki/open_questions.md`

**Repo**: cogni-work/insight-wave
**Branch**: `claude/plan-tier2-issue-212-Fnj60` (carries the merged #219 work; the #220 PR will branch from `main` once #225 merges, or stack on the same branch).
**Parent**: [#212](https://github.com/cogni-work/insight-wave/issues/212) Karpathy-pattern parity tracking.
**Sub-issue**: [#220](https://github.com/cogni-work/insight-wave/issues/220).
**Position**: next open Tier 2 item after #218 (per-type dirs, v0.0.28) and #219 (`context_brief.md`, v0.0.29).
**Target version**: cogni-wiki **v0.0.30**.

---

## Context

`wiki-lint` already surfaces "data gaps" (`no_sources`, `synthesis_no_wiki_source`, `claim_drift`, `orphan_page`, `stale_page`, `stale_draft`, `reverse_link_missing`), but they live in dated audit reports under `wiki/audits/lint-YYYY-MM-DD.md` that get superseded by the next run. Findings that should compound across sessions ("we still don't have a page on X — multiple pages reference it") evaporate.

This PR adds a persistent, deterministically-rebuilt checklist file `wiki/open_questions.md` that accumulates open gaps across sessions and self-marks them resolved when the gap closes. `wiki-resume` surfaces a count so users land on the next ingest target without opening the file. Pairs with the just-landed `context_brief.md` (#219): both are auto-derived end-of-skill files, both write through `_wikilib.atomic_write`, but `open_questions.md` is **read-modify-write** (reconciles with prior state) where `context_brief.md` is full overwrite — so this one needs the lock.

Two design choices were confirmed before writing this plan:
1. **Deterministic findings only in v0.0.30.** The script accepts `--findings -` on stdin from day 1, but `wiki-lint`'s SKILL.md only feeds it the `lint_wiki.py` JSON output. The LLM-emitted `missing_concept_page` items from Step 4d's semantic pass are deferred to a follow-up PR (which only needs to update Step 4d's prompt to produce structured JSON and pipe it in — the script contract is already there).
2. **Closed-item retention: 90 days.** Older `- [x]` lines are dropped on rebuild; long-term history still lives in the dated `wiki/audits/lint-*.md` reports.

## Design summary

A new `wiki/open_questions.md` is rebuilt at the end of every `wiki-lint` run by a new `rebuild_open_questions.py` script. The rebuild:

1. Parses the existing file into `{(class, key): item}` (state, opened_on, closed_on, attribution, message).
2. Builds the incoming finding set from `lint_wiki.py`'s JSON output (and, optionally, stdin findings).
3. Reconciles: still-present → unchanged; gone → flip to closed with today's date and best-effort "closed by" attribution from `wiki/log.md`; new → append as `- [ ]`.
4. Trims `- [x]` items whose `closed_on` is older than 90 days.
5. Renders sections in a stable, alphabetised order and atomically writes the file under `_wiki_lock`.

`wiki-resume` adds an `open_questions_count` field (count of `- [ ]` lines) and surfaces it in the Inventory section + a new decision-tree rule.

## Files to add / change

| File | Action | Notes |
|---|---|---|
| `cogni-wiki/skills/wiki-lint/scripts/rebuild_open_questions.py` | **NEW** | Stdlib-only. CLI: `--wiki-root <path>`; optional `--findings -` (JSON on stdin) reserved for the LLM-feed follow-up. Default: invokes `lint_wiki.py` itself as a subprocess to get the deterministic warning set. **Lock-wrapped** (`_wiki_lock`) for the read-modify-write. Atomic via `_wikilib.atomic_write`. Emits `{success, data: {path, bytes, opened, closed, retained, total}, error}`. |
| `cogni-wiki/skills/wiki-lint/SKILL.md` | edit | Insert **Step 8.5 — rebuild open_questions.md** between current Step 8 (config update, line ~184) and Step 9 (report, line ~188). New flag `--skip-rebuild-open-questions` mirrors `--skip-semantic` / `--ignore-health` (parameter table, line ~34–35). Step 9 reports `opened`/`closed` deltas. Failure isolation: a non-zero exit must NOT roll back the lint write (audit report and config bump are already on disk). |
| `cogni-wiki/skills/wiki-resume/scripts/wiki_status.sh` | edit | Add `open_questions_count` (count of `- [ ]` lines in `wiki/open_questions.md`; `0` if file absent) to the JSON output, alongside the existing 30-day counts (line ~290–305). |
| `cogni-wiki/skills/wiki-resume/SKILL.md` | edit | Inventory section of the prose template (line ~84–87): add `- {open_questions_count} open questions`. Decision tree (Step 4): new rule between current 5 and 6 — `open_questions_count > 0 AND days_since_lint <= 14` → "X open questions in the wiki — see `wiki/open_questions.md` for the next ingest target." |
| `cogni-wiki/CLAUDE.md` | edit | Add `wiki/open_questions.md` row to the Concurrency-Invariant lock table; new "open questions (v0.0.30, intra-plugin)" bullet under Cross-Plugin Integration; Scripts count 14 → 15; layout diagram updated; mention closed-retention = 90 days. |
| `cogni-wiki/.claude-plugin/plugin.json` | edit | `0.0.29` → `0.0.30`. |
| `cogni-wiki/tests/test_open_questions.sh` | **NEW** | Bash smoke modeled on `test_context_brief.sh`. Open → close → idempotent flow (see Verification below). |

## Script design (`rebuild_open_questions.py`)

### Inputs

- `--wiki-root <path>` (required). Validates `.cogni-wiki/config.json` and calls `_wikilib.fail_if_pre_migration`.
- `--findings -` (optional). Reads JSON `{"errors": [...], "warnings": [...]}` from stdin (same shape as `lint_wiki.py`'s `data.errors` / `data.warnings`). When present, **replaces** the script's own subprocess invocation of `lint_wiki.py` so the SKILL.md workflow can inject a pre-merged finding set in the follow-up PR.
- `--skip-trim` (optional, debug). Bypass the 90-day closed-retention trim.

### Stable key per item

For each finding `{class, page, message}`, `key = (class, page)`. The `page` field is reliable (`lint_wiki.py` always sets it). For the future LLM-emitted `missing_concept_page` items (out of scope for v0.0.30), the orchestrator will inject a separate `key` field naming the missing concept's slug — the SKILL.md follow-up will spec this.

### Sections (stable order, alphabetised within each section)

Map of `class` → section header. `tag_typo` (cosmetic) and `info`-class items (`last_resweep`, `total_pages`, etc.) are excluded.

| Class | Section header |
|---|---|
| `no_sources` | `## Pages without sources` |
| `synthesis_no_wiki_source` | `## Synthesis pages without wiki:// sources` |
| `orphan_page` | `## Orphan pages` |
| `stale_page` | `## Stale pages` |
| `stale_draft` | `## Stale drafts` |
| `claim_drift` | `## Claim-drift candidates` |
| `reverse_link_missing` | `## Reverse-link gaps` |

A future section `## Missing concept pages` is reserved (placeholder header omitted until the LLM-feed follow-up lands).

### Reconciliation algorithm

```
old      = parse(read("wiki/open_questions.md")) or {}    # {(class, key): {state, opened_on, closed_on, attribution, message}}
incoming = {(class, page): {message} for finding in lint_findings}

for k, v in old.items():
    if v.state == "open" and k not in incoming:
        v.state         = "closed"
        v.closed_on     = today()
        v.attribution   = best_effort_log_attribution(wiki_root, k.page)

for k, v in incoming.items():
    if k not in old or old[k].state == "closed":
        old[k] = {state: "open", opened_on: today(), message: v.message}
        # Re-opening a previously-closed item is allowed — discard close-on/attribution.

# Trim closed items older than CLOSED_RETENTION_DAYS = 90.
for k, v in list(old.items()):
    if v.state == "closed" and (today() - v.closed_on).days > 90:
        del old[k]

write(render(old))
```

### "Closed by" attribution

Walk `wiki/log.md` from the bottom up. Find the most recent line whose op ∈ {`ingest`, `re-ingest`, `update`, `synthesis`} and whose post-`|` text contains the resolved page slug. Render attribution as `closed YYYY-MM-DD by {op}`. If no match: `closed YYYY-MM-DD`.

Log line shape (per `wiki-ingest/SKILL.md` Step 7 and `wiki_status.sh` lines 158–177): `## [YYYY-MM-DD] op | detail`. Helper kept private in `rebuild_open_questions.py` (no `_wikilib` extraction in this PR — single consumer).

### File layout (canonical)

```markdown
<!-- AUTOGENERATED by skills/wiki-lint/scripts/rebuild_open_questions.py.
     Hand-edits are dropped on rebuild. Closed items >90 days old are trimmed.
     See skills/wiki-lint/SKILL.md §"Step 8.5". -->

# Open questions

_Generated_: <ISO-UTC>
_Open_: N  ·  _Closed (last 90 d)_: N

## Pages without sources

- [ ] `slug-a` — message verbatim from lint
- [x] ~~`slug-b` — message~~ — closed 2026-05-01 by update

## Synthesis pages without wiki:// sources
…
```

Items within each section are sorted: open items first (alphabetical by page slug), then closed items (most recent close first).

### Lock semantics

```python
# Subprocess-out to lint runs OUTSIDE the lock so the lock duration stays minimal.
findings = stdin_or_subprocess_lint(wiki_root)

with _wiki_lock(wiki_root):
    old   = parse_open_questions(wiki_root)
    new   = reconcile(old, findings, today())
    text  = render(new)
    atomic_write(wiki_root / "wiki" / "open_questions.md", text)
```

### Reused helpers (from `_wikilib.py`, post-#219)

- `_wiki_lock(wiki_root)` — wrap the read-modify-write critical section. (`cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py:64`)
- `atomic_write(path, text)` — final write. (line 225)
- `emit_json(success, data, error)` — JSON contract. (line 250)
- `fail_if_pre_migration(wiki_root)` — guard at script start. (line 120)
- `build_slug_index(wiki_root)` — confirm slug existence when computing "did the gap close" attributions. (line 204)

### Subprocess pattern (mirror of `rebuild_context_brief.py::_build_health_snapshot`)

`rebuild_context_brief.py` lines 221–262 are the proven template for invoking `lint_wiki.py` as a subprocess (`subprocess.run` with `timeout=30`, parse last non-empty stdout line as JSON, fall through gracefully on each failure mode). Reuse the same skeleton in `rebuild_open_questions.py::_load_findings`.

## Verification (test plan)

Primary smoke: `cogni-wiki/tests/test_open_questions.sh` (NEW, bash 3.2 + python3 stdlib).

1. **Fixture prep.** Copy `tests/fixtures/legacy-wiki` → tempdir; run `migrate_layout.py --apply` to land on per-type dirs. Hand-edit one fixture page to drop its `sources:` frontmatter list (the easiest way to trigger a deterministic `no_sources` warning without authoring a new fixture).
2. **First rebuild.** Invoke `rebuild_open_questions.py --wiki-root <tmp>`. Assert: success JSON, file exists, contains `## Pages without sources`, contains `- [ ]` line for the doctored page, `data.opened == 1`, `data.closed == 0`.
3. **Resolve the gap.** Restore the `sources:` line on the doctored page, append a synthetic `## [today] update | <slug> — restored sources` line to `wiki/log.md`.
4. **Second rebuild.** Re-invoke. Assert: same `- [ ]` line is now `- [x] ~~…~~ — closed YYYY-MM-DD by update`, `data.opened == 0`, `data.closed == 1`.
5. **Idempotent third run.** Re-invoke without changes. Assert byte-for-byte identical file (sort + canonical-form rendering enforces this).
6. **Pre-migration probe.** Invoke against the un-migrated fixture; assert standard `success: false` + "pre-migration" error message.
7. **Trim test (skipped via `--skip-trim`, then exercised).** Hand-edit a closed item to a `closed_on` 100 days ago; re-run with `--skip-trim` (assert retained); re-run without (assert dropped); confirm `data.retained` reflects the trim.

Regression checks (must still pass):
- `bash cogni-wiki/tests/test_context_brief.sh` — no-op for #219.
- `bash cogni-wiki/tests/test_migrate_and_smoke.sh` — no-op for #218.

Manual against a real wiki:
- Run `wiki-lint`. Inspect `wiki/open_questions.md`. Confirm headers, items, generated-stamp, closed retention banner.
- Resolve one gap (e.g. ingest the missing source for a flagged page). Re-run `wiki-lint`. Confirm the item flips to `- [x]` with correct close-date and attribution.
- Run `wiki-resume`. Confirm `{N} open questions` line surfaces in Inventory and the new decision-tree rule fires when N > 0.

## Out of scope (explicit)

- LLM-emitted `missing_concept_page` items (Step 4d feed). Deferred to a follow-up PR; the `--findings -` stdin contract is in place from day 1 to make that follow-up minimal.
- Hand-edit preservation. The file is autogenerated; the canonical comment header at the top warns the user.
- A `wiki-questions` standalone skill for manual rebuild — `wiki-lint --skip-semantic --skip-rebuild-open-questions=false` already covers it; ship a dedicated entry-point only when someone asks.
- Cross-wiki shared open-questions backlog. Per-wiki only.

## Suggested PR shape

Single PR titled `cogni-wiki: persistent open_questions.md (v0.0.30, #220)`, scoped to:

1. New `rebuild_open_questions.py` (the bulk).
2. Step 8.5 + parameter additions in `wiki-lint/SKILL.md`.
3. `wiki_status.sh` count + `wiki-resume/SKILL.md` Inventory + decision-tree edits.
4. `plugin.json` 0.0.29 → 0.0.30, `CLAUDE.md` lock table + version note.
5. New bash test + minimal fixture extension.

## Open follow-ups (post-merge)

- **LLM-feed wiring**: extend `wiki-lint/SKILL.md` Step 4d's prompt to produce structured JSON (`{class: "missing_concept_page", key: "<slug>", page: "<page>", message: "<msg>"}` items); pipe it into `rebuild_open_questions.py --findings -` from Step 8.5. No script changes needed.
- **Lift-and-shift `ok()`/`fail()` inlines** across all wiki scripts to use `_wikilib.emit_json`. The helper has been live since v0.0.29 but existing inlines are unchanged. Pair with a similar lift-and-shift for `tempfile + os.replace` → `_wikilib.atomic_write`.
- **Lint-cache writer** (referenced from #219's deferred follow-up): have `lint_wiki.py` write `.cogni-wiki/last_lint.json` on every run so `rebuild_context_brief.py`'s "Open lints (cached)" section stops always rendering the "no cached lint" placeholder. Independent of #220 but conceptually adjacent (both close lint-output feedback loops).
