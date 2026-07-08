# Empathize Source-Material Intake Rung

The pre-gap-check intake contract for the design-thinking Empathize stage:
gathering consultant-supplied files, pasted text, and URLs before any coverage
check runs, choosing the sink for each item, and staying idempotent on
re-entry. The design-thinking loop points here; the contract below is
authoritative.

**Interactive mode — input material first.** Before the gap-check, ask the
consultant whether additional source material is available to ground this
deliverable — file paths (drop files in the engagement's `sources/` inbox, or
give any path), pasted text, or URLs (internal reports, the full LOI,
architecture specs, interview transcripts, prior board/decision notes). This
intake runs before the gap-check so the evidence base is as complete as the
consultant can make it before any coverage check runs; it matters most on a
first-party internal diagnostic, where the bound base is empty and external web
research is inappropriate, so the loop would otherwise begin drafting on
whatever the scoping conversation happened to capture. For each item supplied,
choose the sink:

- **Ingest into the bound base** (the item is reusable evidence later
  deliverables should also find): dispatch
  `Skill(cogni-knowledge:knowledge-ingest-source, --file <path>|--url <url>|--paste <tmpfile>, --knowledge-slug <plugin_refs.knowledge_base>, --title "<material title>", --theme "Consulting Deliverables")`
  — the same deposit signature Step 8 reuses; the material lands as a
  `type: source` page so this gap-check and every later research run find it.
- **Read directly into the deliverable's evidence base** (the consultant
  prefers not to deposit, or the material is deliverable-local): `Read` the
  file and carry it as a `sources[]` entry on the deliverable artifact with a
  `file://<abspath>` provenance URI and `evidence_class: first-party` — no
  `kb_ref`, no knowledge-base page written (the read-direct first-party
  `sources[]` shape in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`).

When no additional material is offered, proceed. **Idempotency (the loop may
re-enter Empathize):** `knowledge-ingest-source` runs its own diff-before-write
dedup gate, so re-ingesting a covering source is a no-op; for the read-direct
sink, before appending scan the deliverable's `sources[]` for an entry with the
same `file://` URI and append only when none exists — so a re-entry neither
re-prompts settled material nor double-records it. **In auto-walk mode, skip
this prompt** and proceed directly to the gap-check on the scope-time material.
