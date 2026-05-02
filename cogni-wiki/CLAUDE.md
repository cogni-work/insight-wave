# cogni-wiki

Compile-time knowledge engine for personal and small-team knowledge work — a better-RAG alternative where Claude maintains a persistent, interlinked markdown wiki across sessions. Based on Karpathy's LLM Wiki pattern.

## Plugin Architecture

```
agents/                         1 agent (fan-out worker)
  ingest-worker.md                Per-source subagent for wiki-ingest batch mode (Steps 1–8)
skills/                         8 wiki skills
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
  wiki-query/                     Ask questions; answer from wiki, never from memory
    references/
      query-patterns.md           Read-before-answer, citation discipline
  wiki-lint/                      Severity-tiered health audit
    scripts/
      lint_wiki.py                Orphans, broken links, stale dates, frontmatter check
    references/
      severity-tiers.md           Error / warn / info classification
  wiki-update/                    Diff-gated page revisions with stale-sweep
    references/
      update-discipline.md        Citation-required, diff-before-write rules
  wiki-resume/                    Status dashboard — entry count, last-lint age, next action
    scripts/
      wiki_status.sh              Emits {success, data, error} JSON
  wiki-dashboard/                 Self-contained HTML overview (pages, tags, backlink graph)
    scripts/
      render_dashboard.py         Reads wiki/ → writes wiki-dashboard.html (stdlib only)
  wiki-from-research/             Cold-start: chains research-setup → research-report → wiki-setup → wiki-ingest --discover research:<slug>. Mode A (--topic) or Mode B (--research-slug).

references/
  karpathy-pattern.md             Shared Karpathy-pattern reference, cited by all skills
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 8 | wiki-setup, wiki-ingest, wiki-query, wiki-lint, wiki-update, wiki-resume, wiki-dashboard, wiki-from-research |
| Agents | 1 | ingest-worker (per-source fan-out worker for wiki-ingest batch mode; not directly dispatchable) |
| Commands | 0 | — (skills serve as slash commands per plugin-dev guidance) |
| Hooks | 0 | — (all bookkeeping lives inside skills) |
| Scripts | 6 | backlink_audit.py, wiki_index_update.py, batch_builder.py, lint_wiki.py, wiki_status.sh, render_dashboard.py |

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

## Page Frontmatter

```yaml
---
id: <slug>
title: <human-readable>
type: concept | entity | summary | decision | learning | note
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [../raw/paper-xyz.pdf, https://...]
---
```

## Key Conventions

- **Wiki is LLM-maintained, human-curated sources.** The user drops documents in `raw/`; Claude does all the summarising, linking, and bookkeeping.
- **Always read the wiki for queries — never answer from memory.** Skills enforce this discipline in every SKILL.md.
- **Append-only log.** Every ingest, query, lint, and update writes a line to `wiki/log.md` with an ISO date prefix.
- **Bidirectional links.** `[[wikilinks]]` are audited after every ingest; related pages get backlink updates.
- **Diff before write.** `wiki-update` shows the planned change before modifying a page and requires a source citation for any new claim.
- **Stdlib-only scripts.** bash 3.2 + python3 stdlib, no pip or npm dependencies. JSON output format `{success, data, error}`.
- **No hooks.** All index/log maintenance lives inside the skills for debuggability.

## Concurrency Invariant (batch-mode safety)

`wiki-ingest` runs per-source workers concurrently in batch mode, so any shared file that is read-modified-written by more than one worker **must** be protected by the advisory lock. This invariant is load-bearing — it is what closed issue #84 (silent data loss from concurrent writes to `index.md`, backlink targets, and `config.json.entries_count`).

**Rule.** Any script that performs a read-modify-write on a file shared across concurrent ingest workers MUST wrap the critical section in `_wiki_lock(wiki_root)`, a `fcntl.flock(LOCK_EX)` context manager on `<wiki-root>/.cogni-wiki/.lock`. Parallel writes to **distinct** per-source output paths (e.g. `wiki/pages/{new-slug}.md` where the slug is freshly computed for that worker) do not need the lock.

**Shared files covered today** (must always be lock-wrapped on write):

| File | Write operation | Locked call site |
|------|-----------------|------------------|
| `wiki/index.md` | Insert/update entry line | `wiki_index_update.py::update_index` (line 335) |
| `wiki/pages/<target>.md` | Backlink append into an *existing* page | `backlink_audit.py::apply_plan` (lines 489, 590) |
| `.cogni-wiki/config.json` | `entries_count` bump (and any future counters) | `config_bump.py::main` (line 105) |

**When adding a new shared-state file**, the author MUST:

1. Add a row to the table above.
2. Wrap every read-modify-write call site in `with _wiki_lock(wiki_root): ...`.
3. Prefer routing the mutation through an existing locked script (e.g. `config_bump.py`) rather than inlining the write in a new code path — each inlined write is a new place the invariant can be missed.
4. Never edit any file in the table by hand from a SKILL.md workflow step; always go through the locked script. Hand-edits bypass the lock.

**Known tech debt.** `_wiki_lock` is currently duplicated across three scripts (`backlink_audit.py`, `wiki_index_update.py`, `config_bump.py`). A future consolidation into a shared `cogni-wiki/skills/wiki-ingest/scripts/_wikilock.py` helper would remove the drift risk, but is a non-urgent refactor — the three copies are byte-identical today.

**Do NOT rely on:** `os.replace` atomicity alone (it guarantees atomic file replacement, not correctness of the read-modify-write), per-worker output path uniqueness (workers share index/config even when output slugs differ), or Python's GIL (workers are separate subagent processes, not threads).

## Distinction from Auto-Memory

insight-wave already uses Claude Code's auto-memory system at `~/.claude/projects/.../memory/` for **Claude's learning about the user** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **the user's learning about their domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Cross-Plugin Integration

- **cogni-research → cogni-wiki** (v0.0.17, sub-question-centric — Option B). `wiki-ingest --discover research:<project-slug>` enumerates one batch entry per sub-question of a completed cogni-research project, materialises per-sub-question synthesis files under `<wiki-root>/raw/research-<slug>/sq-NN-<short>.md`, and feeds them through the standard batch-mode pipeline (Steps 1–8 per source). The synthesis bundles findings (from contexts), verified claims (filtered to `verification_status: verified`), and source URLs. Materialisation is the one deviation from the discovery-is-read-only rule and is unavoidable: cogni-research spreads each sub-question's evidence across four entity types, and the per-source ingest-worker reads one file. Materialisation is deterministic and idempotent. See `skills/wiki-ingest/references/batch-mode.md` §"Discovery → research" for the full contract. The reverse path (`wiki-researcher` agent reading a wiki as a RAG source for a research project) is owned by cogni-research and pre-dates this integration.
- **wiki-from-research cold-start** (v0.0.18). The `wiki-from-research` skill chains `cogni-research:research-setup` → `cogni-research:research-report` (auto-chained internally) → `cogni-wiki:wiki-setup` → `cogni-wiki:wiki-ingest --discover research:<slug>` in one dispatch. Mode A starts from a free-text `--topic`; Mode B starts from an existing `--research-slug`. The skill is a pure orchestrator — it writes nothing directly; every artefact comes from its sub-skills' contracts. Pre-flight is fail-fast: wiki-target collisions are detected before any cogni-research dispatch (so an unusable target never burns research budget). Mode B verifies `output/report.md` exists, refuses `report_source ∈ {wiki, hybrid}` projects (circular-evidence risk), and nudges the user to run `verify-report` first if zero claims are verified.

## Future Integration Points

Deferred to post-MVP, documented here so the contract stays visible:

- **cogni-narrative ← cogni-wiki** — narrative skill reads wiki pages as structured input
- **cogni-consulting → cogni-wiki** — engagement knowledge (interviews, decisions, constraints) persists beyond the engagement slug
- **cogni-claims ↔ cogni-wiki** — wiki claim extraction and verification via cogni-claims (today only one direction: verified claims from cogni-research arrive via the research deposit pipeline above)

## Pipeline Position

```
raw sources (user-curated) ──→ cogni-wiki (LLM-maintained pages) ──→ downstream plugins
```

Standalone in v0.0.x. Integration contracts land in v0.1.x.
