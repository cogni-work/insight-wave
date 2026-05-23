# cogni-knowledge `_archive/`

Frozen artifacts from cogni-knowledge's pre-v0.1.0 surface. Nothing here is on any live runtime path — the directory sits outside `skills/` and `scripts/` deliberately, so it is never picked up by skill discovery or by the live test glob (`tests/test_*.sh`).

## What's archived

The v0.0.x **legacy research+report chain**, retired at M11 (v0.0.27) when the v0.1.0 inverted pipeline became the only live path:

| Archived | Replaced by |
|---|---|
| `skills/knowledge-research/SKILL.md` | the inverted pipeline `knowledge-plan → knowledge-curate → knowledge-fetch → knowledge-ingest → knowledge-compose → knowledge-verify → knowledge-finalize` |
| `skills/knowledge-report/SKILL.md` | the same inverted pipeline (a finalize run reads the bound wiki and re-deposits a synthesis) |
| `scripts/lineage-stamp.py` | `knowledge-finalize` stamps `derived_from_research:` inline (v0.1.0 projects don't write `raw/research-<slug>/`, so the stamp helper has no work to do) |
| `scripts/read-project-config.py` | not needed — `knowledge-finalize` hard-codes `--report-source wiki` |
| `tests/test_read_project_config_bare.sh` | follows its script into the archive |

The two scripts were private helpers used only by the two legacy skills; they have no live caller after the archive.

## `archived: true` frontmatter

The two moved `SKILL.md` files carry an `archived: true` frontmatter key. Claude Code does not consume this field today — it is a forward-compat signal of intent for future readers and tooling, not a load-bearing contract. The unambiguous guarantee is the location: these files live outside `skills/`.

## Why a plugin-root `_archive/`

This is the first `_archive/` in the insight-wave monorepo and establishes the convention. It sits one level above `skills/` (rather than `skills/_archive/`) because `plugin.json` does not enumerate skills — discovery is a directory scan, and a sibling inside `skills/` would risk being globbed regardless of an underscore prefix. A plugin-root `_archive/` is safe no matter how the discovery glob evolves.

See `references/absorption-roadmap.md` (Phase 5, M11 row) for the milestone that retired this chain.
