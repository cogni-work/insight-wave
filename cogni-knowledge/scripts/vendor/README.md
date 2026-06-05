# Vendored cogni-wiki engine

This tree is a **verbatim, byte-for-byte mirror** of the cogni-wiki runtime engine
that cogni-knowledge depends on. It exists so cogni-knowledge is self-contained on
the wiki engine — `resolve_wiki_scripts()` resolves this vendored copy first, and
the external cogni-wiki install is only a fallback.

## What is here

A structure-preserving subset of `cogni-wiki/`:

```
vendor/cogni-wiki/
  skills/wiki-ingest/scripts/   _wikilib.py, backlink_audit.py, config_bump.py,
                                wiki_index_update.py, rebuild_context_brief.py
  skills/wiki-lint/scripts/     lint_wiki.py, rebuild_open_questions.py
  skills/wiki-health/scripts/   health.py
  foundations/                  the 11 foundation pages + README.md
```

The `skills/<skill>/scripts/` depth is preserved deliberately: several scripts
reach a sibling via `Path(__file__).resolve().parents[2] / "<other-skill>" / "scripts"`
(e.g. `rebuild_context_brief.py` → `wiki-health/scripts/health.py`,
`rebuild_open_questions.py` → `wiki-lint/scripts/lint_wiki.py`, `lint_wiki.py` →
`wiki-ingest/scripts/`). Mirroring the structure lets every one of those paths
resolve **inside** this vendored tree with no edits to the scripts — which is what
keeps the copies byte-identical to their origins.

## Do not hand-edit

These files are not a fork. cogni-wiki remains the source of truth. To update the
vendored engine, re-copy from `cogni-wiki/` and let `tests/test_vendored_engine_parity.sh`
enforce byte-identity in CI — it fails if any vendored file drifts from its origin.

Only the runtime subset the knowledge-* skills actually invoke is vendored here;
the remaining cogni-wiki scripts are re-homed with the standalone surface in a
later phase.
