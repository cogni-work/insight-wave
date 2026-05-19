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

## Skills (Phase 1)

| Skill | Role |
|---|---|
| `knowledge-setup` | Bootstrap a knowledge base. Dispatches `cogni-wiki:wiki-setup` if no wiki exists, then writes `binding.json`. |
| `knowledge-research` | Research a topic INTO the bound wiki. Dispatches `cogni-wiki:wiki-from-research --topic ...` (Mode A), then stamps lineage and appends to the binding. |
| `knowledge-resume` | Status. Reads `binding.json` and delegates to `cogni-wiki:wiki-resume` (which itself runs `wiki-health`). |

## Scripts

| Script | Purpose | LLM? |
|---|---|---|
| `knowledge-binding.py` | `--init` / `--append-project` / `--read` against `.cogni-knowledge/binding.json` | No (stdlib only) |
| `lineage-stamp.py` | Stamps `derived_from_research: <slug>` into the YAML frontmatter of deposited wiki pages | No (stdlib only) |

All scripts return `{"success": bool, "data": {...}, "error": "..."}` per the insight-wave convention (`/home/user/insight-wave/CLAUDE.md` §"Script Output Format"). Stdlib only — no pip dependencies.

## Data model — `binding.json`

```json
{
  "knowledge_slug": "<kebab-case>",
  "knowledge_title": "<human readable>",
  "wiki_path": "<absolute path to wiki root>",
  "wiki_slug": "<wiki slug from wiki-setup>",
  "research_projects": [
    {
      "slug": "<research-project-slug>",
      "deposited_at": "<YYYY-MM-DD>",
      "report_path": "<absolute path to output/report.md>",
      "report_source": "web | local | wiki | hybrid"
    }
  ],
  "topic_lineage": {
    "covered_themes": [],
    "open_themes": []
  },
  "created": "<YYYY-MM-DD>",
  "schema_version": "0.0.1"
}
```

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

- Skill names: `knowledge-*` (generic skill names like `setup`, `research`, `resume` MUST be prefixed per `/home/user/insight-wave/CLAUDE.md` §"Contributing").
- Skill frontmatter: `name`, `description`, `allowed-tools` — same shape as cogni-wiki/cogni-research skills.
- Script CLI: `python3 scripts/<name>.py --action ...`, JSON envelope output.
- Path conventions: knowledge bases default to `<cwd>/<knowledge-slug>/` (matching `cogni-wiki/{slug}/`).
- Versioning: bump patch on any skill/script change; mirror in `marketplace.json` (`/home/user/insight-wave/CLAUDE.md` §"Version Management").

## Future phases

Phase 2 lights up `knowledge-report` (wiki-roundtrip composition with cycle-guard). Phase 3 lights up `knowledge-query`, `knowledge-dashboard`, `knowledge-refresh`. Phase 4 is the internal alpha. Phase 5 graduates to v0.1.0 (Preview). Phase 6 absorbs `cogni-research`. See `references/absorption-roadmap.md`.

Do not implement Phase 2+ work in Phase 1 commits. The MVP is intentionally small.
