# Canonical Workflow IDs — Reconciliation Map

**Purpose.** Single source of truth for cross-plugin workflow IDs in the
insight-wave ecosystem. Downstream surfaces — the `workflow` skill's
templates, the `teach` skill's course tracks, the `guide` skill's plugin
catalog, the `cheatsheet` skill's quick references — must align to the
canonical IDs declared here, so a user following one workflow is always
seeing the same name across surfaces.

This file is read by issues #146, #147, #148, #149, #150, and #151. It is
the foundation that lets those phase-2 / phase-3 children proceed without
re-deriving the canonical set.

## Canonical policy

`docs/workflows/` is the **canonical source** for workflow IDs and pipeline
shape. Every user-facing workflow ID in the canonical set has a one-to-one
backing file at `docs/workflows/<canonical-id>.md`. The presentation
templates in `cogni-help/skills/workflow/references/workflows/` are
operational copies — step-by-step playbooks the `workflow` skill uses at
runtime — and their filenames must align to canonical IDs.

The canonical surface is `docs/workflows/` because:

- `docs/` is the **publishing-grade** surface, generated and maintained by
  `cogni-docs` for end-user consumption.
- `cogni-help` templates are operational (commands, tips, exercises) and
  derive from the canonical pipeline shape — they should not invent new IDs.
- Three phase-2 children (#146 rename, #147 add, #148 prune), the guide
  plugin catalog (#151), and the cheatsheet workflow cross-reference (#151)
  all need to read from a single source. Without this declaration they
  drift again.

## Canonical workflow ID set

Seven canonical user-facing workflows. The set is fixed by this file; new
canonical IDs are added by adding a `docs/workflows/<id>.md` file and a
matching row to the table below.

1. `research-to-report`
2. `trends-to-solutions`
3. `portfolio-to-pitch`
4. `consulting-engagement`
5. `content-pipeline`
6. `install-to-infographic`
7. `portfolio-to-website`

Two cogni-help templates remain outside this set — they are operational
plugin maintenance pipelines, not user-facing workflows. See Table B.

## Table A — Canonical ID reconciliation

One row per canonical ID. Each row maps the canonical ID to the existing
`docs/workflows/<id>.md` file and to the legacy cogni-help template (if any),
and names the migration action that the phase-2 children must execute.

| Canonical ID | docs/workflows/ guide | cogni-help template (legacy) | Migration action | Tracked by | Notes |
|---|---|---|---|---|---|
| `research-to-report` | `docs/workflows/research-to-report.md` | `research-to-slides` → `research-to-report` | `completed by #146` | #146 | Template renamed in #146. Pipeline unchanged. |
| `trends-to-solutions` | `docs/workflows/trends-to-solutions.md` | `trend-to-marketing` → `trends-to-solutions` | `completed by #146` | #146 | Template renamed in #146. Pipeline unchanged. |
| `portfolio-to-pitch` | `docs/workflows/portfolio-to-pitch.md` | `portfolio-to-pitch` | `unchanged` | — | Already aligned on both sides. |
| `consulting-engagement` | `docs/workflows/consulting-engagement.md` | `new-engagement` → `consulting-engagement` | `completed by #146` | #146 | Template renamed in #146. Pipeline unchanged. |
| `content-pipeline` | `docs/workflows/content-pipeline.md` | — | `add` (template) | #147 | docs/ guide is canonical; cogni-help adds presentation template. |
| `install-to-infographic` | `docs/workflows/install-to-infographic.md` | — | `add` (template) | #147 | docs/ guide is canonical; cogni-help adds presentation template. |
| `portfolio-to-website` | `docs/workflows/portfolio-to-website.md` | — | `add` (template) | #147 | docs/ guide is canonical; cogni-help adds presentation template. |

Migration action vocabulary:

- `rename` — the cogni-help template exists under a non-canonical filename; rename the file to `<canonical-id>.md` and update SKILL.md and any cross-references.
- `add` — no cogni-help template exists yet; create one that walks through the canonical pipeline.
- `unchanged` — the template filename already matches the canonical ID; no migration action needed.
- `completed by #N` — the migration shipped in PR/issue N; row preserved as historical record.
- `internal` — the cogni-help template is operational-only and lives in `references/internal-workflows/`; it is not part of the canonical user-facing set and does not appear in the default `/workflow` listing (see Table B).

## Table B — Operational-only templates (out of canonical user-facing set)

Two cogni-help templates do not have a `docs/workflows/` companion and are
flagged as operational-only: they describe plugin-maintenance or onboarding
meta-pipelines, not user-facing analyst/sales/consultant workflows. They
live in `cogni-help/skills/workflow/references/internal-workflows/` (separate
from the user-facing `references/workflows/` directory) and `/workflow`
surfaces them only when the user names the ID directly.

| cogni-help template | Migration action | Notes |
|---|---|---|
| `docs-pipeline` | `internal` (completed by #148) | cogni-docs maintenance pipeline (audit → generate → sync → power → claude → hub → bridge). Lives in `references/internal-workflows/docs-pipeline.md`. Not a user-facing workflow. |
| `full-onboarding` | `internal` (completed by #148) | New-user meta-pipeline (workspace setup → courses 1-12). Lives in `references/internal-workflows/full-onboarding.md`. Not a workflow in the cross-plugin pipeline sense; it is a learning track that cogni-help already exposes via the `teach` and `courses` skills. |

Either of these graduates to the canonical set if and only if a matching
`docs/workflows/<id>.md` file lands in a future PR. At that point the row
moves from Table B to Table A, the template moves from
`references/internal-workflows/` to `references/workflows/`, and (if kept)
is renamed to match the canonical ID.

## Coverage check

- **cogni-help user-facing templates** (current contents of `cogni-help/skills/workflow/references/workflows/`):
  `consulting-engagement`, `portfolio-to-pitch`, `research-to-report`, `trends-to-solutions` — **4 templates, each appears in exactly one row of Table A**.
- **cogni-help internal templates** (current contents of `cogni-help/skills/workflow/references/internal-workflows/`):
  `docs-pipeline`, `full-onboarding` — **2 templates, each appears in exactly one row of Table B**.
- **docs/workflows/ guides** (current contents):
  `consulting-engagement`, `content-pipeline`, `install-to-infographic`, `portfolio-to-pitch`, `portfolio-to-website`, `research-to-report`, `trends-to-solutions` — **7 guides, each appears in exactly one row** (all in Table A).

No orphans on either side.

## Updating this file

When the canonical set changes (a new `docs/workflows/<id>.md` lands, or a
canonical ID is retired):

1. Update the canonical ID list above.
2. Add or remove the matching row in Table A (or Table B for
   operational-only templates).
3. Re-run the coverage check at the bottom.
4. If a template rename is implied, file or update an issue against
   `cogni-help/skills/workflow/` so the template filename and SKILL.md
   cross-reference table stay aligned.
