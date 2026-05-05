# cogni-wiki

Compile-time knowledge engine for personal and small-team knowledge work — a better-RAG alternative where Claude maintains a persistent, interlinked markdown wiki across sessions. Based on Karpathy's LLM Wiki pattern.

## Plugin Architecture

```
skills/                         11 wiki skills
  wiki-setup/                     Bootstrap a new wiki at a user-chosen root
    references/
      SCHEMA.md.template          Copied into the wiki at setup time
      directory-layout.md         raw/, wiki/pages/, assets/, .cogni-wiki/
  wiki-ingest/                    Add sources → summary page → backlink audit → log
    scripts/
      backlink_audit.py           Scans pages/, proposes bidirectional [[links]]
      wiki_index_update.py        Deterministic index.md insert/update (atomic)
      batch_builder.py            Enumerates candidates for --discover (orphans, stubs, glob, research:<slug>); emits batch JSON. Materialises per-sub-question synthesis files for research mode.
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
  wiki-lint/                      Semantic, LLM-powered audit; runs wiki-health first as preflight (v0.0.27)
    scripts/
      lint_wiki.py                Deterministic warnings (orphans, stale, tag typos, reverse links, claim_drift narrative); the LLM-powered semantic checks (contradictions, type drift, undercited claims, missing concept pages) run from the SKILL.md workflow
    references/
      severity-tiers.md           Health vs Lint coverage matrix + error/warn/info classification
  wiki-update/                    Diff-gated page revisions with stale-sweep
    references/
      update-discipline.md        Citation-required, diff-before-write rules
  wiki-resume/                    Status dashboard — entry count, last-lint age, health snapshot, next action; runs wiki-health automatically (v0.0.27)
    scripts/
      wiki_status.sh              Emits {success, data, error} JSON (incl. synthesis_count_30d, health_count_30d, embedded health.errors/warnings/drifts)
  wiki-dashboard/                 Self-contained HTML overview (pages, tags, backlink graph)
    scripts/
      render_dashboard.py         Reads wiki/ → writes wiki-dashboard.html (stdlib only)
  wiki-from-research/             Cold-start: chains research-setup → research-report → wiki-setup → wiki-ingest --discover research:<slug>. Mode A (--topic) or Mode B (--research-slug).
  wiki-refresh/                   Stale-page refresh loop. Pull-mode: matches lint-flagged stale pages to sub-questions of an existing cogni-research project (Jaccard token overlap), then dispatches wiki-update per match. Sequential, batch-confirmed.
    scripts/
      refresh_planner.py            Reads stale wiki pages + research entities; emits per-page match plan as JSON
  wiki-claims-resweep/            Re-verify claims embedded in existing wiki pages against their cited source URLs. Pull-mode, report-only: extracts inline-cited statements deterministically, dispatches cogni-claims:claims (submit + verify), and writes a sweep report to raw/claims-resweep-<date>/ plus a lint-bridge JSON. Never mutates wiki/pages/.
    scripts/
      extract_page_claims.py        Deterministic claim-candidate extractor (sentences near URLs); never network-touches
      resweep_planner.py            Two-phase: materialises sweep workspace (plan), aggregates verification results (aggregate); writes lint-bridge under lock

references/
  karpathy-pattern.md             Shared Karpathy-pattern reference, cited by all skills
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 11 | wiki-setup, wiki-ingest, wiki-query, wiki-health, wiki-lint, wiki-update, wiki-resume, wiki-dashboard, wiki-from-research, wiki-refresh, wiki-claims-resweep |
| Agents | 0 | — (wiki-ingest batch mode runs sequentially in the orchestrator's own context as of v0.0.22; the previous `ingest-worker` per-source subagent was removed because parallel fan-out broke the Karpathy-pattern invariant that source N+1 must see source N's page) |
| Commands | 0 | — (skills serve as slash commands per plugin-dev guidance) |
| Hooks | 0 | — (all bookkeeping lives inside skills) |
| Scripts | 11 | backlink_audit.py, wiki_index_update.py, batch_builder.py, health.py, lint_wiki.py, wiki_status.sh, render_dashboard.py, refresh_planner.py, extract_page_claims.py, resweep_planner.py, convert_to_md.py |

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
│   └── pages/                 Flat, slug-named markdown with YAML frontmatter
└── .cogni-wiki/
    └── config.json            { "name", "slug", "created", "entries_count", "last_lint" }
```

Pages stay flat under `wiki/pages/`; the `type:` frontmatter field carries the semantic distinction (concept / entity / summary / decision / interview / meeting / learning / synthesis / note). Per-type directories are explicitly deferred — see the parent tracking issue for the Karpathy-pattern parity work.

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
- **Append-only log.** Every ingest, query, synthesis, lint, update, and (as of v0.0.27) health run writes a line to `wiki/log.md` with an ISO date prefix. The `synthesis` operation prefix (v0.0.23+) distinguishes filed-back query answers from un-filed `query` reads; the `health` operation prefix (v0.0.27+) distinguishes free zero-LLM preflights from tokenful `lint` runs. All five are surfaced separately in `wiki-resume` and `wiki-dashboard`.
- **Bidirectional links.** `[[wikilinks]]` are audited after every ingest; related pages get backlink updates. The forward → reverse contract is codified in each wiki's `SCHEMA.md` (added in v0.0.26) under "Forward → reverse link contract" — every audit candidate carries a stable `rule_id` (today: `R1_bidirectional_wikilink`), and `wiki-lint`'s `reverse_link_missing` warning enforces it for hand-edited or imported pages. Existing wikis with `schema_version < "0.0.3"` get a migration nudge from `wiki-resume`'s status block; the lint check works either way, so the migration is offline-safe.
- **Queries can compound.** `wiki-query --file-back yes` writes the answer to `wiki/pages/<slug>.md` as `type: synthesis` with `wiki://<source-slug>` references in `sources:`, so explorations enrich the wiki rather than evaporate. `wiki-health` validates each `wiki://` target slug exists (`broken_wiki_source` error) and `wiki-lint` warns when a synthesis page lacks any `wiki://` source (`synthesis_no_wiki_source` warn).
- **Health vs lint split.** `wiki-health` (v0.0.27+) is the zero-LLM, every-session structural preflight (broken links, missing frontmatter, broken sources, stub pages, drift counts). `wiki-lint` is the periodic, tokenful semantic pass (contradictions, type drift, undercited claims, missing concept pages, plus the deterministic warnings that need narrative — orphans, stale dates, tag typos, reverse-link gaps, claim-drift severity). `wiki-resume` runs health automatically; lint refuses to run while health reports errors > 0 (override with `--ignore-health`). The full per-check ownership matrix lives in `skills/wiki-lint/references/severity-tiers.md`.
- **Diff before write.** `wiki-update` shows the planned change before modifying a page and requires a source citation for any new claim.
- **Stdlib-only scripts.** bash 3.2 + python3 stdlib, no pip or npm dependencies. JSON output format `{success, data, error}`.
- **No hooks.** All index/log maintenance lives inside the skills for debuggability.

## Concurrency Invariant (defence-in-depth lock)

As of v0.0.22, `wiki-ingest` is **sequential** within any single dispatch — both single-source and batch/discover modes process one source at a time in the orchestrator's own context. The earlier per-source subagent fan-out (and its `batch_size` chunking) was removed because it broke the Karpathy-pattern invariant that source N+1 must see source N's just-written page; see `skills/wiki-ingest/references/batch-mode.md` §"Execution model" for the full history.

The advisory lock at `<wiki-root>/.cogni-wiki/.lock` is **retained as defence-in-depth** for the case where the user runs two `wiki-ingest` invocations against the same wiki from separate sessions (two terminals, two Claude Code windows, a script + an interactive session). With sequential intra-skill execution, that's the only remaining concurrency hazard — and it's exactly the one that originally motivated issue #84's fix in v0.0.12.

**Rule.** Any script that performs a read-modify-write on a file shared across `wiki-ingest` invocations MUST wrap the critical section in `_wiki_lock(wiki_root)`, a `fcntl.flock(LOCK_EX)` context manager on `<wiki-root>/.cogni-wiki/.lock`. Per-source output paths that are unique by construction (e.g. `wiki/pages/{new-slug}.md` for a freshly computed slug) do not need the lock.

**Shared files covered today** (must always be lock-wrapped on write):

| File | Write operation | Locked call site |
|------|-----------------|------------------|
| `wiki/index.md` | Insert/update entry line | `wiki_index_update.py::update_index` (line 335) |
| `wiki/pages/<target>.md` | Backlink append into an *existing* page | `backlink_audit.py::apply_plan` (lines 489, 590) |
| `.cogni-wiki/config.json` | `entries_count` bump (and any future counters) | `config_bump.py::main` (line 105) |
| `.cogni-wiki/last-resweep.json` | Sweep summary write at end of `wiki-claims-resweep` aggregate phase | `resweep_planner.py::phase_aggregate` |

**When adding a new shared-state file**, the author MUST:

1. Add a row to the table above.
2. Wrap every read-modify-write call site in `with _wiki_lock(wiki_root): ...`.
3. Prefer routing the mutation through an existing locked script (e.g. `config_bump.py`) rather than inlining the write in a new code path — each inlined write is a new place the invariant can be missed.
4. Never edit any file in the table by hand from a SKILL.md workflow step; always go through the locked script. Hand-edits bypass the lock.

**Note for `wiki-query` file-back (v0.0.23):** the synthesis file-back path writes `wiki/pages/<new-slug>.md` (unique by construction — no lock needed), and routes its `entries_count` bump through `config_bump.py` (locked). It does not need to add a new shared file to the table.

**Note for `wiki-health` (v0.0.27):** `health.py` is read-only against `wiki/pages/`, `wiki/index.md`, and `.cogni-wiki/`. It writes nothing directly — the `## [YYYY-MM-DD] health | ...` log line is appended by the SKILL workflow via the same path every other operation log line uses, and `wiki/log.md` is treated as append-only (no read-modify-write), so it does not need a lock entry.

**Known tech debt.** `_wiki_lock` is currently duplicated across three scripts (`backlink_audit.py`, `wiki_index_update.py`, `config_bump.py`). A future consolidation into a shared `cogni-wiki/skills/wiki-ingest/scripts/_wikilock.py` helper would remove the drift risk, but is a non-urgent refactor — the three copies are byte-identical today.

**Do NOT rely on:** `os.replace` atomicity alone (it guarantees atomic file replacement, not correctness of the read-modify-write), or Python's GIL (cross-process invocations from separate sessions are not protected by it). The `batch_size` config key referenced in `wiki-ingest` versions ≤0.0.21 is no longer read; legacy wikis with the key are harmless.

## Distinction from Auto-Memory

insight-wave already uses Claude Code's auto-memory system at `~/.claude/projects/.../memory/` for **Claude's learning about the user** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **the user's learning about their domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Cross-Plugin Integration

- **cogni-research → cogni-wiki** (v0.0.17, sub-question-centric — Option B). `wiki-ingest --discover research:<project-slug>` enumerates one batch entry per sub-question of a completed cogni-research project, materialises per-sub-question synthesis files under `<wiki-root>/raw/research-<slug>/sq-NN-<short>.md`, and feeds them through the standard batch-mode pipeline (Steps 1–8 per source). The synthesis bundles findings (from contexts), verified claims (filtered to `verification_status: verified`), and source URLs. Materialisation is the one deviation from the discovery-is-read-only rule and is unavoidable: cogni-research spreads each sub-question's evidence across four entity types, and the per-source ingest-worker reads one file. Materialisation is deterministic and idempotent. See `skills/wiki-ingest/references/batch-mode.md` §"Discovery → research" for the full contract. The reverse path (`wiki-researcher` agent reading a wiki as a RAG source for a research project) is owned by cogni-research and pre-dates this integration.
- **wiki-from-research cold-start** (v0.0.18). The `wiki-from-research` skill chains `cogni-research:research-setup` → `cogni-research:research-report` (auto-chained internally) → `cogni-wiki:wiki-setup` → `cogni-wiki:wiki-ingest --discover research:<slug>` in one dispatch. Mode A starts from a free-text `--topic`; Mode B starts from an existing `--research-slug`. The skill is a pure orchestrator — it writes nothing directly; every artefact comes from its sub-skills' contracts. Pre-flight is fail-fast: wiki-target collisions are detected before any cogni-research dispatch (so an unusable target never burns research budget). Mode B verifies `output/report.md` exists, refuses `report_source ∈ {wiki, hybrid}` projects (circular-evidence risk), and nudges the user to run `verify-report` first if zero claims are verified.
- **wiki-refresh stale-page loop** (v0.0.19, pull-mode only). The `wiki-refresh` skill closes the *update* loop — stale wiki pages get fresh evidence from a completed cogni-research project. Calls `lint_wiki.py` directly to enumerate `stale_page` (>365d) and `stale_draft` (>180d) findings, runs `refresh_planner.py` to match each stale page to the highest-scoring sub-question via Jaccard token overlap on `(title + tags + type)` vs `(query + parent_topic)`, prints a batch plan for one user confirmation, then materialises one synthesis file per match under `<wiki-root>/raw/refresh-<research-slug>-<YYYY-MM-DD>/<page-slug>.md` and dispatches `wiki-update` sequentially per page. Default match threshold `0.30`, tunable via `--match-threshold` or interactively via the `refine` action in the plan-review prompt. Push-mode auto-research per stale page is deferred (cost-prohibitive at scale). The entity-loading helpers in `refresh_planner.py` mirror those in `batch_builder.py` — known tech debt, parallel to the `_wiki_lock` duplication noted in §"Concurrency Invariant".
- **wiki-claims-resweep citation re-verify** (v0.0.20, pull-mode only). The `wiki-claims-resweep` skill closes the *citation-drift* loop — existing wiki pages have their cited source URLs re-checked against current content. `extract_page_claims.py` walks `wiki/pages/` and yields one claim candidate per sentence containing an inline `[text](http(s)://...)` link or bare URL (deterministic, no LLM, no network). The orchestrator runs `resweep_planner.py --phase plan` to materialise per-page claim manifests under `<wiki-root>/raw/claims-resweep-<YYYY-MM-DD>/`, batch-confirms with the user, then dispatches `cogni-claims:claims` (`submit` then `verify`) sequentially per page. The cogni-claims source-cache (`cogni-claims/sources/{url-hash}.json`) keeps repeat WebFetches free across pages within one sweep. After verification, `resweep_planner.py --phase aggregate` writes `report.md` to the workspace and `last-resweep.json` (lock-wrapped) to `.cogni-wiki/`. **Report-only**: this skill never modifies `wiki/pages/`. Stale-marker decisions go through `wiki-update` manually. Circular sources (URLs pointing back into the wiki tree) are skipped per claim and counted, mirroring the `report_source ∈ {wiki, hybrid}` refusal pattern from `wiki-from-research`/`wiki-refresh`. As of v0.0.21, `wiki-lint` reads `last-resweep.json` and surfaces flagged pages via the `claim_drift` warning class plus a `last_resweep` info line; as of v0.0.27, `wiki-health` additionally exposes the *count* of flagged pages so it surfaces in `wiki-resume`'s status block without needing a tokenful lint run.
- **wiki-health ↔ wiki-lint boundary** (v0.0.27, intra-plugin). The split formalises the llm-wiki-agent "Health vs Lint Boundary": `wiki-health` owns deterministic structural integrity (zero LLM, every session, sub-second on 100-page wikis); `wiki-lint` owns semantic content quality (LLM-powered, periodic, refuses to run while health is broken). `wiki-resume` invokes `health.py` automatically as part of its session-start status, so the user gets a structural preflight without thinking about it. The full per-check ownership matrix is in `skills/wiki-lint/references/severity-tiers.md`. The two skills share the `{success, data, error}` JSON contract and the same severity vocabulary so the lint report can include health's findings verbatim. **No new shared-state files** — `health.py` is read-only against `wiki/pages/`, `wiki/index.md`, and `.cogni-wiki/`; the only side effect is the `## [YYYY-MM-DD] health | ...` log line, which is append-only and needs no lock.

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
