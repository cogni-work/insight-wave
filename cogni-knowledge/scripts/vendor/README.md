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

# Vendored pypdf

`pypdf/` is a **verbatim copy of the pypdf 6.6.2 package source** (PyPI sdist),
vendored so the source-curator can extract a PDF's text layer on a host where the
Read tool cannot rasterize PDFs (no poppler) — instead of dropping the source as
`pdf_render_unavailable`. It is resolved by putting this `vendor/` directory on
`sys.path` and `import pypdf` (see `_knowledge_lib.pdf_extract_text`).

pypdf is pure-Python (no compiled extensions), which is what makes it vendorable
under the "no pip dependencies" convention — unlike pdfminer.six, which pulls the
compiled `cryptography` C extension and cannot be vendored as source.

`typing_extensions` is **intentionally NOT vendored**: every pypdf import of it is
behind a `sys.version_info >= (3, 10)` guard that takes the stdlib `typing` branch
on Python 3.10+, and `pdf_extract_text` wraps the import in a fail-soft try/except
so a sub-3.10 host degrades to `pdf_render_unavailable` rather than crashing.

## Do not hand-edit

Not a fork. To update, re-copy the package tree from a fresh PyPI release of pypdf
and re-stamp the version line below.

pypdf-version: 6.6.2 (PyPI sdist, BSD-3-Clause; license at pypdf/LICENSE)

That is the upstream pypdf release this tree mirrors. Re-stamp this line whenever
the tree is re-copied. The parity test (`tests/test_vendored_engine_parity.sh`)
walks only `scripts/vendor/cogni-wiki/`, so this PyPI mirror is not byte-checked
against a git origin — the version stamp is its provenance anchor.
