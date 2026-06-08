# Concepts outline shape decision — knowledge-finalize ↔ curated concept map

Design record for how the bound wiki exposes its **distilled concept web** as a
human entry point — the grouped-by-theme outline rendered at
`wiki/concepts/index.md` — and how `knowledge-finalize` keeps that outline's
framing prose compounding without overwriting human editorial work. The concepts
sibling of `references/portal-shape-decision.md`; read that first for the
curated-portal (`wiki/index.md`) version of the same argument.

## The question

Phase 4.5 distillation grows a web of `concept` / `entity` pages under
`wiki/concepts/`. On their own they are a flat bag of slugs — discoverable by
search, but not *navigable* as a domain map. The `/concepts` roadmap asked for a
single curated outline that turns that bag into a progressive-disclosure entry
point: one page, grouped by theme, each theme framed by a short lead-in that says
why it matters and what to read first.

Two shape questions had to be answered together:

- **Where does the outline live, and who owns its structure?** A standalone page
  vs. a section grafted onto the existing Knowledge Portal (`wiki/index.md`); a
  deterministic renderer vs. an LLM that authors the whole page.
- **Does finalize touch the framing prose as the base grows, or leave it
  write-once?** The same preserve-only vs. auto-refresh tension
  `portal-shape-decision.md` resolved for portal lead-ins.

## Decision

### 1. Standalone page, grouped by theme

The concept map is its own page at `wiki/concepts/index.md`, not a section inside
`wiki/index.md`. The portal is the *wiki-wide* entry point (themes, syntheses,
recent activity); the concepts outline is a *domain-map* view of the distilled
concept web specifically. Keeping them separate lets each evolve on its own
cadence and keeps the portal from ballooning every time the concept web grows.

Concepts are grouped under `## <theme>` headings, one bullet per concept (a
one-line summary + `[[slug]]` wikilink). Theme membership comes from the
distilled pages themselves, so the grouping is derived, never hand-maintained.

### 2. Deterministic renderer owns structure; the engine only narrates

The split that makes this safe mirrors the portal's renderer/narrator split:

- **`concepts_index.py render` owns the structure** — it groups concept pages by
  theme, emits the per-concept bullets, and lays down an empty placeholder
  `MACHINE-OWNED:CONCEPTS-LEADIN:<theme-slug>` lead-in span under each `## <theme>`
  heading. It **never** writes lead-in prose, never reorders or invents bullets,
  and carries any existing lead-in forward verbatim on every re-render. The
  deterministic renderer is the single source of truth for what concepts exist
  and how they are grouped.
- **The `concepts-outliner` agent only narrates** — it fills (or refreshes) the
  lead-in prose inside those engine-owned spans, never the bullets and never the
  page structure. It is the concepts analog of the `portal-narrator`.

### 3. Narrated lead-ins under MACHINE-OWNED sentinels — human work is untouchable

Ownership is enforced by two nested sentinels, the same posture
`portal-shape-decision.md` §1 establishes for portal lead-ins:

- A page-level `MACHINE-OWNED:CONCEPTS-INDEX` marker. A hand-authored
  `wiki/concepts/index.md` that carries **no** marker is never touched by the
  engine — a human who wants to own the whole page simply omits the marker.
- A per-theme `MACHINE-OWNED:CONCEPTS-LEADIN:<theme-slug>` span. Within a
  machine-owned page, the engine authors a lead-in only where the renderer seeded
  a span, and refreshes only a span it previously authored. A lead-in a human
  writes outside a sentinel is protected the same way the portal's
  protected-lead-in guarantee protects curated portal framing.

This is the central reconciliation: the outline **compounds narratively** (the
same compounding bet that justifies `concept-summary-narrator` re-narrating
distilled-page summaries) while human editorial framing stays write-once and
engine-untouchable.

### 4. Stage by default; apply behind an explicit flag

`knowledge-finalize`'s concepts-outline refresh **stages** a proposed diff to
`<wiki>/.cogni-wiki/concepts-index-proposed.md` by default and leaves the live
outline untouched. `--apply-concepts` (alias `--refresh-concepts`) applies it;
`--no-concepts` skips the sub-step entirely; `--no-concepts-prompt` makes the
autonomous `knowledge-refresh --mode push` loop stage silently. This mirrors the
portal refresh's `--apply-portal` / `--no-portal` / `--no-portal-prompt` triad
exactly, so the two curated surfaces have one mental model.

The refresh is **fail-soft**: a narrator miss, a parse error, or a per-theme
write failure never rolls back the synthesis — the synthesis page and every other
finalize sub-step are already on disk. Failures surface loudly in the finalize
Step 11 report and the run continues.

## Cross-references

- `references/portal-shape-decision.md` — the curated-portal (`wiki/index.md`)
  version of this decision; the source of the renderer/narrator split, the
  MACHINE-OWNED sentinel posture, and the stage-by-default auto-refresh contract
  this note re-applies to the concept map.
- `agents/concepts-outliner.md` — the narrator that fills the engine-owned
  lead-in spans.
- `scripts/concepts_index.py` — the deterministic renderer that owns structure
  and seeds the lead-in spans.
- `skills/knowledge-finalize/SKILL.md` (Step 10.5 sub-step 3.6) — the
  concepts-outline auto-refresh sub-step.
