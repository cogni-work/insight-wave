# cogni-knowledge — developer guide

Wiki-first research orchestrator. Binds a `cogni-wiki` knowledge base to N `cogni-research` projects so the work compounds across runs instead of dying in chat history. Every primitive delegates upward — there are no forked agents, no duplicated scripts, no agent definitions in this plugin.

## Architecture

```
.cogni-knowledge/binding.json   ← the only new state cogni-knowledge owns
       │
       ▼
knowledge-* skills (orchestrators)
       │
       ▼
cogni-wiki / cogni-research (delegate targets)
```

A "knowledge base" is one directory that contains both:

- `.cogni-wiki/config.json` — the wiki manifest (owned by `cogni-wiki`)
- `.cogni-knowledge/binding.json` — the binding manifest (owned by this plugin)

They live as siblings. The wiki is the substrate; the binding records which research projects have contributed.

## Skills

| Skill | Role |
|---|---|
| `knowledge-setup` | Bootstrap a knowledge base. Dispatches `cogni-wiki:wiki-setup` if no wiki exists, then writes `binding.json`. |
| `knowledge-research` | Research a topic INTO the bound wiki. Dispatches `cogni-wiki:wiki-from-research --topic ...` (Mode A), then stamps lineage and appends to the binding. Records the live `report_source` from `<project>/.metadata/project-config.json` (v0.0.7+). |
| `knowledge-report` | Compose a report BY READING the bound wiki, refuse self-citing loops via `cycle-guard.py`, then re-deposit via `cogni-wiki:wiki-from-research` Mode B with `--allow-wiki-source --cycle-guard-cleared`. Records the live `report_source` (wiki/hybrid) in the binding. Phase 2 of the absorption roadmap. |
| `knowledge-resume` | Status. Reads `binding.json` and delegates to `cogni-wiki:wiki-resume` (which itself runs `wiki-health`). |
| `knowledge-query` | Ask a question against the bound base. Resolves the wiki path from `binding.json`, dispatches `cogni-wiki:wiki-query` against it, appends a one-line knowledge-base footer. Read-only. Phase 3, v0.0.8+. |
| `knowledge-dashboard` | Render an HTML overview. Dispatches `cogni-wiki:wiki-dashboard` against the bound wiki, then writes a `knowledge-overlay.md` sidecar listing deposited projects + latest lint-audit `claim_drift` count. Phase 3, v0.0.9+. |
| `knowledge-refresh` | Self-healing loop. Pull-mode delegates to `cogni-wiki:wiki-refresh`. Push-mode lints the wiki, asks which stale topics to re-research, then sequentially dispatches `knowledge-research` + `wiki-refresh` per selected topic. Phase 3, v0.0.10+. |
| `knowledge-plan` | **v0.1.0 inverted pipeline, Phase 1.** Decomposes a topic into 3-7 sub-questions with per-sub-question `candidate_domains[]` (no web). Writes `<project>/.metadata/plan.json` schema `0.1.0`. Probes only `cogni-wiki` — the v0.1.0 path does not dispatch cogni-research. Phase 5, v0.0.17+. |
| `knowledge-curate` | **v0.1.0 inverted pipeline, Phase 2.** Reads `plan.json`, fans out one `source-curator` dispatch per sub-question (WebSearch + score, no fetch), merges per-sub-question batches into `<project>/.metadata/candidates.json` via `candidate-store.py append-batch`. Phase 5, v0.0.17+. |
| `knowledge-fetch` | **v0.1.0 inverted pipeline, Phase 3.** Reads `candidates.json`, dispatches `source-fetcher` per batch (WebFetch + cobrowse fallback), merges into `<project>/.metadata/fetch-manifest.json`. Successful bodies land in the shared `.cogni-knowledge/fetch-cache/`; unavailable URLs are negatively cached. Phase 5, v0.0.17+. |

Phase 2 closes the round-trip — `knowledge-report` reads the wiki, re-deposits via `wiki-from-research` Mode B with the opt-in flags, and `cycle-guard.py` refuses self-citing loops. The differentiation thesis (knowledge compounds across projects) holds only with this loop closed; before v0.0.6 a second research run could only deposit, never compose-and-deposit.

## Agents (v0.1.0 inverted pipeline)

Starting at v0.0.17, cogni-knowledge has an `agents/` directory. v0.0.x had none by design (everything delegated to upstream cogni-research agents); the v0.1.0 clean break forks agents locally so the runtime path is 0% cogni-research. The v0.0.x "What about `agents/`?" paragraph in `references/delegation-contract.md` is the legacy contract — `references/inverted-pipeline.md` is the v0.1.0 source of truth.

| Agent | Role |
|---|---|
| `source-curator` | Phase 2. Forked from `cogni-research/agents/source-curator.md` (point-in-time copy; drift acceptable). Per-sub-question WebSearch + scoring. Emits a batch JSON array for merge into `candidates.json`. v0.0.17+. |
| `source-fetcher` | Phase 3. NEW (no upstream). Per-URL WebFetch with `claude-in-chrome` cobrowse fallback; reads/writes through `fetch-cache.py`. Emits per-batch `{fetched[], unavailable[]}` for merge into `fetch-manifest.json`. v0.0.17+. |

## Scripts

| Script | Purpose | LLM? |
|---|---|---|
| `knowledge-binding.py` | `init` / `append-project` / `read` subcommands against `.cogni-knowledge/binding.json` | No (stdlib only) |
| `lineage-stamp.py` | Stamps `derived_from_research: <slug>` into the YAML frontmatter of deposited wiki pages | No (stdlib only) |
| `cycle-guard.py` | Detects direct self-cycles before a wiki-mode re-deposit: walks the candidate project's `02-sources/data/src-*.md` for `wiki://<bound-slug>/<page-id>` citations and checks each resolved page's frontmatter for `derived_from_research: <candidate-slug>`. Exit 1 on `cycle_detected`, exit 0 on `clear` or `not_applicable` (web/local mode). | No (stdlib only) |
| `fetch-cache.py` | **v0.1.0 inverted pipeline.** Content-addressed URL→body cache at `.cogni-knowledge/fetch-cache/<sha256>.json`. Subcommands `store` / `fetch` (with `--max-age-days` staleness gate) / `evict` / `stat` / `key`. Negative caching for unavailable URLs; freshness symmetric with positive entries. Atomic temp+rename per entry. v0.0.16-foundation (shipped via PR #269, no version bump); consumed by `source-fetcher` at v0.0.17. | No (stdlib only) |
| `candidate-store.py` | **v0.1.0 inverted pipeline.** File-locked (`fcntl.flock`) merge of parallel `source-curator` output batches into `<project>/.metadata/candidates.json`. Subcommands `init` / `append-batch` / `read`. Dedup key URL-normalized (lowercase scheme+host, trailing-slash-stripped, common tracking params dropped). On collision: higher score wins, earliest `discovered_at` wins, `sub_question_refs[]` unioned, `tier` + `fetch_priority` recomputed. Posix-only. v0.0.17+. | No (stdlib only) |

All scripts return `{"success": bool, "data": {...}, "error": "..."}` per the insight-wave convention (`../CLAUDE.md` §"Script Output Format"). Stdlib only — no pip dependencies.

## Data model — `binding.json`

```json
{
  "knowledge_slug": "<kebab-case>",
  "knowledge_title": "<human readable>",
  "wiki_path": "<absolute path to wiki root>",
  "research_projects": [
    {
      "slug": "<research-project-slug>",
      "deposited_at": "<YYYY-MM-DD>",
      "report_path": "<absolute path to output/report.md>",
      "report_source": "web | local | wiki | hybrid",
      "project_path": "<absolute path to project root>"
    }
  ],
  "topic_lineage": {
    "covered_themes": [],
    "open_themes": []
  },
  "curator_defaults": {
    "max_candidates_per_sq": 12,
    "score_threshold": 0.5,
    "fetch_cache_max_age_days": 30
  },
  "created": "<YYYY-MM-DD>",
  "schema_version": "0.0.3"
}
```

`curator_defaults` (added at schema 0.0.3) configures the inverted pipeline's `knowledge-curate` and `knowledge-fetch` phases — see `references/inverted-pipeline.md` and `references/fetch-cache-design.md`. The fetch-cache itself lives at `<knowledge-root>/.cogni-knowledge/fetch-cache/` by convention; the path is derivable from the knowledge root and is therefore not echoed into the binding.

Schema bumps mirror the data shape, not the plugin tag. The schema goes `0.0.1 → 0.0.2 → 0.0.3` for additive field adds; the next jump to `0.1.0` aligns with the `plugin.json` v0.1.0 maturity-flip at M12. Consumers that need v0.0.3 fields on a pre-v0.0.3 binding MUST `.get(..., DEFAULT)` — `cmd_read` returns the binding as-is and does not auto-migrate.

The file is small (< 4 KiB even at 20+ deposited projects). It is *not* a database — it is a narrative manifest that records what the user has chosen to bind together. Search across the wiki itself for content; consult the binding only for "what projects fed this base".

## Delegation contract

The hard rule: **no logic that already exists upstream**. If you find yourself writing code that duplicates a `cogni-wiki` script or a `cogni-research` agent, stop and re-delegate. The full mapping lives in `references/delegation-contract.md`.

A few specifics:

- `knowledge-setup` does NOT re-implement `wiki-setup`. It only handles the `binding.json` half.
- `knowledge-research` does NOT call `cogni-research:research-setup` directly — that already happens transitively inside `cogni-wiki:wiki-from-research`. Going one level lower would re-implement the same orchestration.
- `knowledge-resume` does NOT compute wiki health. `wiki-resume` already calls `wiki-health` automatically as of cogni-wiki v0.0.27.

## Lineage stamping

`cogni-wiki:wiki-ingest --discover research:<slug>` deposits per-sub-question pages and creates the directory `<wiki-root>/raw/research-<slug>/`. The directory itself records the lineage implicitly (which raw files seeded which page), but Phase 2's cycle-guard needs a queryable `derived_from_research: <slug>` field in the page YAML frontmatter to detect circular evidence without a filesystem walk. `lineage-stamp.py` adds that field, idempotently.

The script:

1. Globs `<wiki-root>/wiki/**/*.md`.
2. For each page, reads the YAML `sources:` field. If any `sources[]` entry path contains `raw/research-<slug>/`, the page is derived from that research project.
3. If the page already has `derived_from_research: <slug>`, skip (idempotent). Otherwise, insert the field into the frontmatter.

Only the frontmatter changes — page bodies are never touched.

## Conventions

- Skill names: `knowledge-*` (generic skill names like `setup`, `research`, `resume` MUST be prefixed per `../CLAUDE.md` §"Contributing").
- Skill frontmatter: `name`, `description`, `allowed-tools` — same shape as cogni-wiki/cogni-research skills.
- Script CLI: `python3 scripts/<name>.py --action ...`, JSON envelope output.
- Path conventions: knowledge bases default to `<cwd>/<knowledge-slug>/` (matching `cogni-wiki/{slug}/`).
- Versioning: bump patch on any skill/script change; mirror in `marketplace.json` (`../CLAUDE.md` §"Version Management").

## Future phases

Phases 1-3 shipped (v0.0.1 → v0.0.11), 2/3 follow-up debt cleared at v0.0.13, Phase 4 alpha completed at v0.0.15 with a **GO** recommendation. **Phase 5 is in flight as one big v0.1.0 inverted-pipeline clean break** — see `references/absorption-roadmap.md` for the canonical 12-milestone (M1–M12) table and current status. The plugin stays at `0.0.x`/maturity `incubating` until M12 ships the alpha re-run + version bump to 0.1.0 + maturity flip in a single landing. Phase 6 (cogni-research deprecation cleanup) follows Phase 5.

Inverted-pipeline progress: M1 (plumbing) + M2-script (fetch-cache.py) shipped at PR #269 with no version bump. M2-finish (`source-fetcher` agent) + M3 (`source-curator` fork) + M4 (`knowledge-plan` / `knowledge-curate` / `knowledge-fetch` skills + `candidate-store.py`) ship at v0.0.17. Next slice: M5 (`claim-extractor` fork + `source-ingester` agent) + M6 (`knowledge-ingest` skill; unblocked by cogni-wiki 0.0.44's `type: source` allowlist).
