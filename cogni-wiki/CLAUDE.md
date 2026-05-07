# cogni-wiki

Compile-time knowledge engine for personal and small-team knowledge work — a better-RAG alternative where Claude maintains a persistent, interlinked markdown wiki across sessions. Based on Karpathy's LLM Wiki pattern.

## Plugin Architecture

```
skills/                         12 wiki skills
  wiki-setup/                     Bootstrap a new wiki at a user-chosen root
    references/
      SCHEMA.md.template          Copied into the wiki at setup time
      directory-layout.md         raw/, per-type page dirs under wiki/, assets/, .cogni-wiki/
    scripts/
      migrate_layout.py           One-shot flat→per-type-dir layout migration (locked, idempotent, dry-run by default)
  wiki-ingest/                    Add sources → summary page → backlink audit → log
    scripts/
      backlink_audit.py           Scans pages/, proposes bidirectional [[links]]
      wiki_index_update.py        Deterministic index.md insert/update (atomic)
      batch_builder.py            Enumerates candidates for --discover (orphans, stubs, glob, research:<slug>); emits batch JSON. Materialises per-sub-question synthesis files for research mode.
      rebuild_context_brief.py    Rebuilds wiki/context_brief.md (≤8 KiB; auto-invoked by Step 8.5 of every dispatch as of v0.0.29)
    references/
      page-frontmatter.md         YAML schema (id, title, tags, type, sources, ...)
      ingest-workflow.md          Step-by-step ingest behavior
      batch-mode.md               --batch-file + --discover schema, execution model, error policy, examples
  wiki-query/                     Ask questions; answer from wiki, never from memory; optionally file the answer back as `type: synthesis`
    references/
      query-patterns.md           Read-before-answer, citation discipline, synthesis file-back walkthrough
  wiki-health/                    Zero-LLM structural integrity preflight; runs every session via wiki-resume (v0.0.27)
    scripts/
      health.py                   Broken wikilinks, missing frontmatter, broken raw/wiki:// sources, id mismatch, invalid type, stub pages, entries_count drift, index/filesystem drift, claim_drift count
    references/
      checks.md                   Canonical list of structural checks with detection logic and the lint boundary
  wiki-lint/                      Semantic, LLM-powered audit; runs wiki-health first as preflight (v0.0.27); rebuilds wiki/open_questions.md at end of every run (v0.0.30); strict partition vs wiki-health enforced in code (v0.0.31); deterministic auto-fix and structured suggestion modes (v0.0.32, --fix/--suggest/--dry-run)
    scripts/
      lint_wiki.py                Deterministic warnings (orphans, stale, tag typos, reverse links, no_sources, synthesis_no_wiki_source, claim_drift narrative); LLM semantic checks (contradictions, type drift, undercited claims, missing concept pages) run from the SKILL.md workflow. As of v0.0.31 emits zero structural errors — those moved to health.py per #223. As of v0.0.32 ships --fix=<class>, --suggest, --dry-run modes (5 fixable classes: reverse_link_missing, synthesis_no_wiki_source, entries_count_drift, frontmatter_defaults, alphabetisation) per #222.
      rebuild_open_questions.py   Rebuilds wiki/open_questions.md from data-gap warnings — locked RMW, reconciles vs prior state, 90-day closed retention (auto-invoked by Step 8.5 of every dispatch as of v0.0.30)
    references/
      severity-tiers.md           Health vs Lint coverage matrix + error/warn/info classification
  wiki-update/                    Diff-gated page revisions with stale-sweep
    references/
      update-discipline.md        Citation-required, diff-before-write rules
  wiki-resume/                    Status dashboard — entry count, last-lint age, health snapshot, next action; runs wiki-health automatically (v0.0.27); reads wiki/context_brief.md first (v0.0.29); surfaces open_questions_count (v0.0.30)
    scripts/
      wiki_status.sh              Emits {success, data, error} JSON (incl. synthesis_count_30d, health_count_30d, open_questions_count, embedded health.errors/warnings/drifts)
  wiki-dashboard/                 Self-contained HTML overview (pages, tags, backlink graph)
    scripts/
      render_dashboard.py         Reads wiki/ → writes wiki-dashboard.html (stdlib only)
  wiki-from-research/             Cold-start: chains research-setup → research-report → wiki-setup → wiki-ingest --discover research:<slug>. Mode A (--topic) or Mode B (--research-slug).
  wiki-refresh/                   Stale-page refresh loop. Pull-mode: matches lint-flagged stale pages to sub-questions of an existing cogni-research project (Jaccard token overlap), then dispatches wiki-update per match. Sequential, batch-confirmed.
    scripts/
      refresh_planner.py            Reads stale wiki pages + research entities; emits per-page match plan as JSON
  wiki-claims-resweep/            Re-verify claims embedded in existing wiki pages against their cited source URLs. Pull-mode, report-only: extracts inline-cited statements deterministically, dispatches cogni-claims:claims (submit + verify), and writes a sweep report to raw/claims-resweep-<date>/ plus a lint-bridge JSON. Never mutates the per-type page dirs.
    scripts/
      extract_page_claims.py        Deterministic claim-candidate extractor (sentences near URLs); never network-touches
      resweep_planner.py            Two-phase: materialises sweep workspace (plan), aggregates verification results (aggregate); writes lint-bridge under lock
  wiki-prefill/                   Seed a wiki with curated `foundation: true` concept pages (Porter's Five Forces, Jobs-to-be-Done, MECE, …); idempotent, locked, supports --filter consulting|product|strategy|all and --list/--dry-run. v0.0.33+.
    scripts/
      prefill_foundations.py        Locked, atomic copy of plugin-side foundations into wiki/concepts/; substitutes {{PREFILL_DATE}} and bumps entries_count via config_bump.py

foundations/                    Curated terminal concept pages (v0.0.33+)
  README.md                       Foundation contract, filter sets, contribution procedure
  *.md                            ~11 starter foundations across consulting/product/strategy
                                  (porters-five-forces, jobs-to-be-done, double-diamond, mece,
                                  pyramid-principle, ooda-loop, swot, bcg-matrix, value-chain,
                                  lean-canvas, wardley-mapping)

references/
  karpathy-pattern.md             Shared Karpathy-pattern reference, cited by all skills
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 12 | wiki-setup, wiki-ingest, wiki-query, wiki-health, wiki-lint, wiki-update, wiki-resume, wiki-dashboard, wiki-from-research, wiki-refresh, wiki-claims-resweep, wiki-prefill |
| Agents | 0 | — (wiki-ingest batch mode runs sequentially in the orchestrator's own context as of v0.0.22; the previous `ingest-worker` per-source subagent was removed because parallel fan-out broke the Karpathy-pattern invariant that source N+1 must see source N's page) |
| Commands | 0 | — (skills serve as slash commands per plugin-dev guidance) |
| Hooks | 0 | — (all bookkeeping lives inside skills) |
| Scripts | 17 | backlink_audit.py, wiki_index_update.py, batch_builder.py, config_bump.py, _wikilib.py, convert_to_md.py, rebuild_context_brief.py, health.py, lint_wiki.py, rebuild_open_questions.py, wiki_status.sh, render_dashboard.py, refresh_planner.py, extract_page_claims.py, resweep_planner.py, migrate_layout.py, prefill_foundations.py |

## Wiki Data Layout (outside the plugin)

Created by `wiki-setup` at the user-chosen root (default `cogni-wiki/{slug}/` relative to the workspace):

```
<wiki-root>/
├── SCHEMA.md                  Conventions + active wiki metadata
├── raw/                       Immutable source documents (user drops files here)
├── assets/                    Images, PDFs, attachments
├── wiki/
│   ├── index.md               LLM-maintained catalog, one-line summary per page
│   ├── log.md                 Append-only operation log
│   ├── overview.md            Evolving synthesis / "state of the wiki"
│   ├── context_brief.md       ≤8 KiB auto-rebuilt "first read" for fresh sessions (v0.0.29)
│   ├── open_questions.md      Persistent backlog of lint-derived data gaps (v0.0.30; locked RMW; 90-day closed retention)
│   ├── concepts/              type: concept
│   ├── entities/              type: entity
│   ├── summaries/             type: summary
│   ├── decisions/             type: decision
│   ├── interviews/            type: interview (incl. tag:customer-call)
│   ├── meetings/              type: meeting
│   ├── learnings/             type: learning (incl. tag:retro)
│   ├── syntheses/             type: synthesis (filed-back query answers)
│   ├── notes/                 type: note
│   └── audits/                lint-YYYY-MM-DD.md / health-YYYY-MM-DD.md (R3 exempt)
└── .cogni-wiki/
    └── config.json            { "name", "slug", "created", "entries_count", "last_lint", "schema_version" }
```

Pages live under per-type subdirectories (v0.0.28+, schema_version `0.0.5`); the `type:` frontmatter field MUST match the directory the page is in. `wiki-health`'s `type_directory_mismatch` error catches drift. The migration from the v0.0.27 flat `wiki/pages/` layout is one-shot via `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/scripts/migrate_layout.py --apply`; every other `wiki-*` skill hard-fails on the legacy layout, and `wiki-resume` surfaces `schema_migration_pending: true` to nudge the user.

## Page Frontmatter

```yaml
---
id: <slug>
title: <human-readable>
type: concept | entity | summary | decision | interview | meeting | learning | synthesis | note
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [../raw/paper-xyz.pdf, https://..., wiki://other-slug]
---
```

The `synthesis` type (introduced in v0.0.23) is reserved for LLM-derived answers that `wiki-query --file-back yes` files back into the wiki. Synthesis pages cite their wiki provenance via `wiki://<slug>` entries in `sources:` rather than `../raw/` paths; `wiki-lint` enforces this contract.

The `interview` and `meeting` types (introduced in v0.0.24) carry the consulting-domain shapes that drive `wiki-ingest`'s body-template dispatch. `customer-call` and `retro` are deliberately **not** distinct types — they are scaffold variants distinguished by the `tags:` field (`tag:customer-call` swaps `interview.md` → `customer-call.md`; `tag:retro` swaps `learning.md` → `retro.md`), so the enum stays small while `wiki-query` can still slice by use case. See `skills/wiki-ingest/references/page-frontmatter.md` for the full schema and `skills/wiki-ingest/references/templates/README.md` for the type→template map.

## Key Conventions

- **Wiki is LLM-maintained, human-curated sources.** The user drops documents in `raw/`; Claude does all the summarising, linking, and bookkeeping.
- **Always read the wiki for queries — never answer from memory.** Skills enforce this discipline in every SKILL.md.
- **Append-only log.** Every ingest, query, synthesis, lint, update, prefill, and (as of v0.0.27) health run writes a line to `wiki/log.md` with an ISO date prefix. Operation prefixes today: `ingest`, `query`, `synthesis` (v0.0.23+, filed-back query answers vs un-filed `query` reads), `lint`, `health` (v0.0.27+, free zero-LLM preflights vs tokenful `lint` runs), `update`, `setup`, `migrate` (v0.0.28+, one-shot layout migrations), `prefill` (v0.0.33+, foundation seeding from the plugin's `foundations/` library). The full enum is in each wiki's `SCHEMA.md` "Log format" block. All prefixes are surfaced separately in `wiki-resume` and `wiki-dashboard`.
- **Bidirectional links.** `[[wikilinks]]` are audited after every ingest; related pages get backlink updates. The forward → reverse contract is codified in each wiki's `SCHEMA.md` (added in v0.0.26) under "Forward → reverse link contract" — every audit candidate carries a stable `rule_id` (today: `R1_bidirectional_wikilink`), and `wiki-lint`'s `reverse_link_missing` warning enforces it for hand-edited or imported pages. Existing wikis with `schema_version < "0.0.3"` get a migration nudge from `wiki-resume`'s status block; the lint check works either way, so the migration is offline-safe.
- **Queries can compound.** `wiki-query --file-back yes` writes the answer to `wiki/syntheses/<slug>.md` as `type: synthesis` with `wiki://<source-slug>` references in `sources:`, so explorations enrich the wiki rather than evaporate. `wiki-health` validates each `wiki://` target slug exists (`broken_wiki_source` error) and `wiki-lint` warns when a synthesis page lacks any `wiki://` source (`synthesis_no_wiki_source` warn).
- **Health vs lint split.** `wiki-health` (v0.0.27+) is the zero-LLM, every-session structural preflight (broken links, missing frontmatter, broken sources, stub pages, drift counts). `wiki-lint` is the periodic, tokenful semantic pass (contradictions, type drift, undercited claims, missing concept pages, plus the deterministic warnings that need narrative — orphans, stale dates, tag typos, reverse-link gaps, claim-drift severity). `wiki-resume` runs health automatically; lint refuses to run while health reports errors > 0 (override with `--ignore-health`). The full per-check ownership matrix lives in `skills/wiki-lint/references/severity-tiers.md`.
- **Diff before write.** `wiki-update` shows the planned change before modifying a page and requires a source citation for any new claim.
- **Stdlib-only scripts.** bash 3.2 + python3 stdlib, no pip or npm dependencies. JSON output format `{success, data, error}`.
- **No hooks.** All index/log maintenance lives inside the skills for debuggability.

## Concurrency Invariant (defence-in-depth lock)

As of v0.0.22, `wiki-ingest` is **sequential** within any single dispatch — both single-source and batch/discover modes process one source at a time in the orchestrator's own context. The earlier per-source subagent fan-out (and its `batch_size` chunking) was removed because it broke the Karpathy-pattern invariant that source N+1 must see source N's just-written page; see `skills/wiki-ingest/references/batch-mode.md` §"Execution model" for the full history.

The advisory lock at `<wiki-root>/.cogni-wiki/.lock` is **retained as defence-in-depth** for the case where the user runs two `wiki-ingest` invocations against the same wiki from separate sessions (two terminals, two Claude Code windows, a script + an interactive session). With sequential intra-skill execution, that's the only remaining concurrency hazard — and it's exactly the one that originally motivated issue #84's fix in v0.0.12.

**Rule.** Any script that performs a read-modify-write on a file shared across `wiki-ingest` invocations MUST wrap the critical section in `_wiki_lock(wiki_root)` from `skills/wiki-ingest/scripts/_wikilib.py` — a `fcntl.flock(LOCK_EX)` context manager on `<wiki-root>/.cogni-wiki/.lock`. Per-source output paths that are unique by construction (e.g. `wiki/<type>/{new-slug}.md` for a freshly computed slug + resolved type) do not need the lock.

**Shared files covered today** (must always be lock-wrapped on write):

| File | Write operation | Locked call site |
|------|-----------------|------------------|
| `wiki/index.md` | Insert/update entry line | `wiki_index_update.py::update_index` (line 335) |
| `wiki/<type>/<target>.md` | Backlink append into an *existing* page (slug → path resolved via `_wikilib.build_slug_index`) | `backlink_audit.py::apply_plan` |
| `.cogni-wiki/config.json` | `entries_count` bump (and any future counters) | `config_bump.py::main` (line 105) |
| `.cogni-wiki/last-resweep.json` | Sweep summary write at end of `wiki-claims-resweep` aggregate phase | `resweep_planner.py::phase_aggregate` |
| `wiki/open_questions.md` | Reconcile checklist (parse → flip closed/open → trim → atomic replace) | `rebuild_open_questions.py::main` (v0.0.30) |

**When adding a new shared-state file**, the author MUST:

1. Add a row to the table above.
2. Wrap every read-modify-write call site in `with _wiki_lock(wiki_root): ...`.
3. Prefer routing the mutation through an existing locked script (e.g. `config_bump.py`) rather than inlining the write in a new code path — each inlined write is a new place the invariant can be missed.
4. Never edit any file in the table by hand from a SKILL.md workflow step; always go through the locked script. Hand-edits bypass the lock.

**Note for `wiki-query` file-back (v0.0.23):** the synthesis file-back path writes `wiki/syntheses/<new-slug>.md` (unique by construction — no lock needed), and routes its `entries_count` bump through `config_bump.py` (locked). It does not need to add a new shared file to the table.

**Note for `wiki-health` (v0.0.27):** `health.py` is read-only against the per-type page dirs, `wiki/index.md`, and `.cogni-wiki/`. It writes nothing directly — the `## [YYYY-MM-DD] health | ...` log line is appended by the SKILL workflow via the same path every other operation log line uses, and `wiki/log.md` is treated as append-only (no read-modify-write), so it does not need a lock entry.

**Note for `rebuild_context_brief.py` (v0.0.29):** the script writes `wiki/context_brief.md` (unique-by-construction; single writer) and runs `health.py` as a read-only subprocess. The atomic `tempfile + os.replace` write goes through `_wikilib.atomic_write`. Reads of `wiki/log.md`, `wiki/index.md`, and per-type page bodies are snapshot-only — no read-modify-write. **No new shared-state file** added to the table; concurrent `wiki-ingest` invocations from separate sessions are still serialised because every other Step 1–8 mutation goes through the existing locked scripts before Step 8.5 runs.

**Note for `rebuild_open_questions.py` (v0.0.30):** the script writes `wiki/open_questions.md` and IS a true read-modify-write — it parses the existing checklist, reconciles items against the current `lint_wiki.py` finding set, flips newly-resolved items to `- [x]`, and trims closed items older than 90 days. Wraps the parse + reconcile + render + write in `with _wikilib._wiki_lock(wiki_root):` so concurrent `wiki-lint` dispatches from separate sessions can't trample each other's reconciliation. The `lint_wiki.py` subprocess invocation runs **outside** the lock to keep the critical section small. Final write goes through `_wikilib.atomic_write`. Adds one new shared-state row to the table above.

**Lock helper consolidated (v0.0.28).** `_wiki_lock` lives in `skills/wiki-ingest/scripts/_wikilib.py` alongside the per-type-directory traversal helpers (`PAGE_TYPE_DIRS`, `iter_pages`, `build_slug_index`, `fail_if_pre_migration`). The previously duplicated copies in `backlink_audit.py`, `wiki_index_update.py`, and `config_bump.py` have been removed and replaced with `from _wikilib import _wiki_lock`. New shared-state writers MUST import from `_wikilib` rather than re-inline the lock context manager. As of v0.0.29, `_wikilib` also exports `atomic_write` and `emit_json` — extracted from the byte-for-byte-duplicated patterns in every wiki script. As of v0.0.33, `_wikilib` also exports `is_foundation_page(fm)` — the canonical predicate that decides whether a parsed-frontmatter dict marks a foundation page (`foundation: true`). `lint_wiki.py` consumes it from there; future LLM-side consumers (wiki-update / wiki-ingest SKILL.md) reference the helper as the contract. New writers consume them from `_wikilib`; existing inlines stay (lift-and-shift in a follow-up PR if desired).

**Do NOT rely on:** `os.replace` atomicity alone (it guarantees atomic file replacement, not correctness of the read-modify-write), or Python's GIL (cross-process invocations from separate sessions are not protected by it). The `batch_size` config key referenced in `wiki-ingest` versions ≤0.0.21 is no longer read; legacy wikis with the key are harmless.

## Distinction from Auto-Memory

insight-wave already uses Claude Code's auto-memory system at `~/.claude/projects/.../memory/` for **Claude's learning about the user** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **the user's learning about their domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Cross-Plugin Integration

- **cogni-research → cogni-wiki** (v0.0.17, sub-question-centric — Option B). `wiki-ingest --discover research:<project-slug>` enumerates one batch entry per sub-question of a completed cogni-research project, materialises per-sub-question synthesis files under `<wiki-root>/raw/research-<slug>/sq-NN-<short>.md`, and feeds them through the standard batch-mode pipeline (Steps 1–8 per source). The synthesis bundles findings (from contexts), verified claims (filtered to `verification_status: verified`), and source URLs. Materialisation is the one deviation from the discovery-is-read-only rule and is unavoidable: cogni-research spreads each sub-question's evidence across four entity types, and the per-source ingest-worker reads one file. Materialisation is deterministic and idempotent. See `skills/wiki-ingest/references/batch-mode.md` §"Discovery → research" for the full contract. The reverse path (`wiki-researcher` agent reading a wiki as a RAG source for a research project) is owned by cogni-research and pre-dates this integration.
- **wiki-from-research cold-start** (v0.0.18). The `wiki-from-research` skill chains `cogni-research:research-setup` → `cogni-research:research-report` (auto-chained internally) → `cogni-wiki:wiki-setup` → `cogni-wiki:wiki-ingest --discover research:<slug>` in one dispatch. Mode A starts from a free-text `--topic`; Mode B starts from an existing `--research-slug`. The skill is a pure orchestrator — it writes nothing directly; every artefact comes from its sub-skills' contracts. Pre-flight is fail-fast: wiki-target collisions are detected before any cogni-research dispatch (so an unusable target never burns research budget). Mode B verifies `output/report.md` exists, refuses `report_source ∈ {wiki, hybrid}` projects (circular-evidence risk), and nudges the user to run `verify-report` first if zero claims are verified.
- **wiki-refresh stale-page loop** (v0.0.19, pull-mode only). The `wiki-refresh` skill closes the *update* loop — stale wiki pages get fresh evidence from a completed cogni-research project. Calls `lint_wiki.py` directly to enumerate `stale_page` (>365d) and `stale_draft` (>180d) findings, runs `refresh_planner.py` to match each stale page to the highest-scoring sub-question via Jaccard token overlap on `(title + tags + type)` vs `(query + parent_topic)`, prints a batch plan for one user confirmation, then materialises one synthesis file per match under `<wiki-root>/raw/refresh-<research-slug>-<YYYY-MM-DD>/<page-slug>.md` and dispatches `wiki-update` sequentially per page. Default match threshold `0.30`, tunable via `--match-threshold` or interactively via the `refine` action in the plan-review prompt. Push-mode auto-research per stale page is deferred (cost-prohibitive at scale). The entity-loading helpers in `refresh_planner.py` mirror those in `batch_builder.py` — known tech debt, parallel to the `_wiki_lock` duplication noted in §"Concurrency Invariant".
- **wiki-claims-resweep citation re-verify** (v0.0.20, pull-mode only). The `wiki-claims-resweep` skill closes the *citation-drift* loop — existing wiki pages have their cited source URLs re-checked against current content. `extract_page_claims.py` walks every per-type page dir and yields one claim candidate per sentence containing an inline `[text](http(s)://...)` link or bare URL (deterministic, no LLM, no network). The orchestrator runs `resweep_planner.py --phase plan` to materialise per-page claim manifests under `<wiki-root>/raw/claims-resweep-<YYYY-MM-DD>/`, batch-confirms with the user, then dispatches `cogni-claims:claims` (`submit` then `verify`) sequentially per page. The cogni-claims source-cache (`cogni-claims/sources/{url-hash}.json`) keeps repeat WebFetches free across pages within one sweep. After verification, `resweep_planner.py --phase aggregate` writes `report.md` to the workspace and `last-resweep.json` (lock-wrapped) to `.cogni-wiki/`. **Report-only**: this skill never modifies any per-type page dir. Stale-marker decisions go through `wiki-update` manually. Circular sources (URLs pointing back into the wiki tree) are skipped per claim and counted, mirroring the `report_source ∈ {wiki, hybrid}` refusal pattern from `wiki-from-research`/`wiki-refresh`. As of v0.0.21, `wiki-lint` reads `last-resweep.json` and surfaces flagged pages via the `claim_drift` warning class plus a `last_resweep` info line; as of v0.0.27, `wiki-health` additionally exposes the *count* of flagged pages so it surfaces in `wiki-resume`'s status block without needing a tokenful lint run.
- **wiki-health ↔ wiki-lint boundary** (v0.0.27, intra-plugin). The split formalises the llm-wiki-agent "Health vs Lint Boundary": `wiki-health` owns deterministic structural integrity (zero LLM, every session, sub-second on 100-page wikis); `wiki-lint` owns semantic content quality (LLM-powered, periodic, refuses to run while health is broken). `wiki-resume` invokes `health.py` automatically as part of its session-start status, so the user gets a structural preflight without thinking about it. The full per-check ownership matrix is in `skills/wiki-lint/references/severity-tiers.md`. The two skills share the `{success, data, error}` JSON contract and the same severity vocabulary so the lint report can include health's findings verbatim. **No new shared-state files** — `health.py` is read-only against the per-type page dirs, `wiki/index.md`, and `.cogni-wiki/`; the only side effect is the `## [YYYY-MM-DD] health | ...` log line, which is append-only and needs no lock.
- **per-type page directories** (v0.0.28, intra-plugin, schema_version `0.0.5`). Pages are now stored under per-type subdirectories (`wiki/concepts/`, `wiki/decisions/`, `wiki/syntheses/`, …) instead of flat `wiki/pages/`. Audit reports (`lint-*.md`, `health-*.md`) live under `wiki/audits/`. The traversal contract is owned by `_wikilib.iter_pages()` / `build_slug_index()` so consumers no longer hard-code paths. Existing wikis must run `wiki-setup/scripts/migrate_layout.py --apply` once; every other skill hard-fails on the legacy flat layout via `_wikilib.fail_if_pre_migration`, and `wiki-resume`'s `wiki_status.sh` surfaces `schema_migration_pending: true` to nudge the user (without hard-failing — the resume path is exactly where the user reads the nudge from). `[[wikilink]]` syntax is unchanged — slugs remain globally unique and address pages without paths. Closes #212 Tier 2 item #1.
- **context brief** (v0.0.29, intra-plugin). Every `wiki-ingest` dispatch ends with `rebuild_context_brief.py` (Step 8.5), which writes `wiki/context_brief.md` — a deterministic ≤ 8 KiB file summarising type counts, top entities by inbound backlinks, the last 30 days of activity, cached open lints (read from `.cogni-wiki/last_lint.json` if present and ≤ 24 h old), and a fresh `health.py` snapshot. `wiki-resume`'s Step 1 reads the brief before any other status work, so a fresh Claude Code session orients from one file instead of a 3+ file scan. Failure to rebuild the brief never rolls back the ingest — the brief is a derived artefact, regenerated on the next dispatch. The lint section degrades gracefully when no cache is present; the lint-cache writer hook is a deliberate follow-up. Closes #212 Tier 2 item #2 (#219).
- **open questions** (v0.0.30, intra-plugin). Every `wiki-lint` dispatch ends with `rebuild_open_questions.py` (Step 8.5), which maintains `wiki/open_questions.md` as a persistent checklist of data-gap warnings (`no_sources`, `synthesis_no_wiki_source`, `claim_drift`, `orphan_page`, `stale_page`, `stale_draft`, `reverse_link_missing`). Unlike the context brief, this is a **read-modify-write**: items disappearing from the current lint output flip to `- [x]` with a best-effort "closed by" attribution from `wiki/log.md`; new findings append as `- [ ]`; closed items >90 days old are trimmed. `wiki-resume` adds a `{N} open questions` Inventory line plus a new decision-tree rule that fires when the count is non-zero and lint is fresh. Failure to rebuild never rolls back the lint — the audit report and `last_lint` bump are already on disk. v0.0.30 ships deterministic-only; the `--findings -` stdin contract is in place from day 1 for the LLM-feed follow-up that pipes Step 4d's `missing_concept_page` items in. Closes #212 Tier 2 item #3 (#220).
- **lint–health code partition** (v0.0.31, intra-plugin). The Health-vs-Lint contract from v0.0.27 (`severity-tiers.md`) is now enforced in code: `lint_wiki.py` no longer runs `broken_wikilink`, `missing_frontmatter`, `id_mismatch`, `invalid_type`, `missing_source`, `broken_wiki_source`, or `read_error` — every structural-integrity check has been moved to `health.py`. `data.errors` from `lint_wiki.py` is now always an empty list (preserved for consumer compatibility). The `wiki-lint` SKILL.md drops its old "deduplicate against health" step. `wiki-refresh` is unaffected — `stale_page`/`stale_draft` are explicitly retained in the lint surface and `refresh_planner.py` consumes them unchanged. New `tests/test_lint_health_partition.sh` plants two structural defects and asserts lint emits no health-owned class while health catches both. Closes #212 Tier 2 item #6 (#223); deferred from #217.
- **lint auto-fix and suggestion modes** (v0.0.32, intra-plugin). `lint_wiki.py` gains three opt-in flags: `--fix=<class>` (apply deterministic auto-fixers), `--suggest` (emit structured proposals for prose-shaped findings), and `--dry-run` (plan without writing). Five `--fix` classes ship: `reverse_link_missing` (backfill the missing reverse `[[link]]` per SCHEMA `R1_bidirectional_wikilink`), `synthesis_no_wiki_source` (add `wiki://<slug>` source entries when the body cites in-wiki slugs), `entries_count_drift` (reconcile `.cogni-wiki/config.json::entries_count` to the filesystem-counted truth via `config_bump.py --set-int`), `frontmatter_defaults` (backfill missing `id:` and normalise non-ISO `updated:` dates), and `alphabetisation` (re-sort `wiki/index.md` bullets within each category via `wiki_index_update.py --reflow-only`). The three in-process page-body fixers run inside one `_wiki_lock(wiki_root)` block; the two scripted fixers acquire their own locks via the underlying scripts after the in-process lock is released. Each fixer is fail-soft per item — exceptions land in `data.failed[]` instead of aborting the fix phase. The `--suggest` schema is fixed in this PR (`{class, page, proposed_action, candidates?, wiki_update_args?, from_tag?, to_tag?, justification}`); no consumer wires it yet, the schema ships first so `wiki-update` can adopt it on its own schedule. LLM-driven and semantic fixes remain `wiki-update`'s responsibility. Two locked-write helpers gain new modes: `config_bump.py --set-int N` (symmetric to `--set-string`, used by `entries_count_drift`) and `wiki_index_update.py --reflow-only` (re-sort categories, no insert/update; pure function `reflow_categories(text) -> (text, changed)` for in-process callers). New `tests/test_lint_fix.sh` plants one defect per fixable class and asserts plan-vs-write semantics, idempotency, and `--suggest` schema. Closes #212 Tier 2 item #7 (#222); deferred fixers from #213, #216, and #217 finally land.
- **foundations + wiki-prefill** (v0.0.33, intra-plugin). New plugin-side `foundations/` library of curated `type: concept` pages with `foundation: true` frontmatter (Porter's Five Forces, Jobs-to-be-Done, MECE, Pyramid Principle, OODA, SWOT, BCG Matrix, Value Chain, Lean Canvas, Wardley Mapping, Double Diamond — 11 starter entries; community can extend via PR). New `wiki-prefill` skill copies a tag-filtered subset (`consulting` / `product` / `strategy` / `all`) into `wiki/concepts/`, idempotently and under `_wiki_lock`; `{{PREFILL_DATE}}` placeholders substitute to today's ISO date so the staleness clock starts at prefill time and never thereafter. `entries_count` bump goes through the locked `config_bump.py --delta N` (no new shared-state file added — pages are unique-by-construction). `wiki-update` refuses to edit `foundation: true` pages without `--force`, `wiki-lint` skips `orphan_page` / `no_sources` / `stale_page` / `stale_draft` warnings on them and surfaces `stats.foundation_count`, and `wiki-ingest`'s Step 1 detects foundation slug-collisions and routes the user to "ingest as a related page (different slug)" rather than overwriting (analogous to the re-ingest warning, but stricter). `wiki-setup` Step 6 prompts the user to prefill the consulting subset by default; the prompt is suppressed deterministically via `wiki-setup --skip-prefill-prompt`, which `wiki-from-research`'s Step 2 dispatch always passes (cold-start from a research project is already a domain-specific seeding path; layering canonical foundations on top would clutter the user's wiki). Detection of foundation pages is owned by `_wikilib.is_foundation_page(fm)` so every consumer reads the same source of truth. New `tests/test_prefill.sh` exercises `--list`, `--dry-run`, wet apply with `entries_count` correctness, idempotent re-run, lint skip-foundations, and the pre-migration probe. Closes #212 Tier 2 item #4 (#224); 6 of 7 Tier 2 items now landed (graph layer #221 remains).

## Future Integration Points

Deferred to post-MVP, documented here so the contract stays visible:

- **cogni-narrative ← cogni-wiki** — narrative skill reads wiki pages as structured input
- **cogni-consulting → cogni-wiki** — engagement knowledge (interviews, decisions, constraints) persists beyond the engagement slug
- **cogni-claims ↔ cogni-wiki** — initial direction live as of v0.0.20 via `wiki-claims-resweep` (re-verifies inline-cited claims in existing wiki pages against their source URLs). Reverse direction — propagating cogni-claims resolutions back into wiki pages — remains deferred

## Pipeline Position

```
raw sources (user-curated) ──→ cogni-wiki (LLM-maintained pages) ──→ downstream plugins
```

Standalone in v0.0.x. Integration contracts land in v0.1.x.
