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

Vendored-from: e356c998e2e14b9c4ead4979c187509b061a228f (2026-06-05)

That is the cogni-wiki revision this tree mirrors — the last commit to touch the
vendored origins (`cogni-wiki/skills/{wiki-ingest,wiki-lint,wiki-health}/scripts`
and `cogni-wiki/foundations`). Re-stamp this line whenever the tree is re-copied.
It is the durable provenance marker once cogni-wiki is archived and the parity
test's origin comparisons skip silently.

Only the runtime subset the knowledge-* skills actually invoke is vendored here;
the remaining cogni-wiki scripts are re-homed with the standalone surface in a
later phase.

## What is NOT vendored

`pypdf` is **not** vendored. The source-curator's text-layer PDF fallback treats
it as an **optional dependency** (`_knowledge_lib.load_pypdf`): imported from the
host's site-packages, or from a workspace venv pointed to by
`COGNI_WORKSPACE_PYTHON_VENV`, and degrades to the honest `pdf_render_unavailable`
outcome when absent. See cogni-knowledge `README.md` §"Optional dependencies".
Vendoring is reserved for the first-party cogni-wiki engine above (which a byte-for-byte
parity test guards); a third-party package belongs behind the optional-dependency +
graceful-degradation convention, not in this tree.
