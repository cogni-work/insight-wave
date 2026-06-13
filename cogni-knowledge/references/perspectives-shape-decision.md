# Perspectives overlay shape decision — wiki/perspectives.md (5W1H derived view)

Design record for how the bound wiki exposes a **5W1H perspective view**
(Who / What / When / Where / Why / How) over its pages — the derived overlay
rendered at `wiki/perspectives.md` — and why this is a *re-projection* of the
canonical type-first layout rather than a restructuring of it. The 5W1H sibling
of `references/portal-shape-decision.md` and `references/concepts-shape-decision.md`;
read those first for the curated-portal and concept-map versions of the same
renderer/narrator argument.

## The question

The wiki's canonical layout is **type-first**: every page lives in its type
directory (`wiki/concepts/`, `wiki/entities/`, `wiki/people/`, `wiki/sources/`,
`wiki/questions/`, `wiki/syntheses/`), each with a machine-owned sub-index, and
the root portal groups those types by theme. That layout is deterministic,
byte-stable, and load-bearing for every renderer and lint pass.

A reader, though, often arrives with a *question shape* rather than a type:
"who is involved here?", "what does this base actually claim?", "why was this
researched?". The 5W1H framing answers that. The shape question:

- **Do we restructure the wiki into 5W1H, or overlay it?** A full canonical
  restructure (pages re-homed under who/what/where/when/why/how) vs. a single
  derived page that re-projects the existing type-first layout.
- **If an overlay, who owns its structure, and how does it stay idempotent?**
  A deterministic renderer vs. an LLM authoring the page; how the byte-identical
  re-render contract every other renderer holds is preserved here.

## Decision

### 1. Stay canonical — overlay, never restructure

The canonical type-first layout is **unchanged**. `wiki/perspectives.md` is a
**derived overlay**: it re-projects the same pages by perspective without moving
or re-homing a single one. Every page keeps its real home in its type directory;
the overlay is a second way in, not a new home.

A full 5W1H *canonical* restructure was rejected, for reasons recorded here so
the decision is not relitigated:

- **Pages multi-classify.** A single page is frequently *Who* and *What* at once
  (an organization that is also the subject of a claim), or *Why* and *How*. A
  type directory has one home per page; a 5W1H home does not — so a canonical
  5W1H layout forces a subjective single-facet assignment the type layout never
  needed.
- **Facet assignment is subjective; type assignment is not.** "Is this a concept
  or an entity?" has a determinate answer the distiller already makes. "Is this
  Why or How?" does not. Baking subjectivity into the canonical layout would make
  the deterministic, byte-identical renderer contract impossible to hold.
- **Blast radius.** A canonical restructure would touch 7+ renderer/store scripts
  and all seven phase skills, and break `test_vendored_engine_parity.sh`'s
  byte-identity guard. The overlay touches one new script + additive wiring and
  leaves the vendored engine untouched.

The overlay gets the navigational benefit of 5W1H with none of the canonical
cost: the type layout stays the single source of truth, and the perspective view
is a deterministic projection of it.

### 2. Deterministic renderer owns structure; counts derive from the sub-indexes

`scripts/perspectives_index.py render` owns the page structure — the same
renderer discipline `sub_index.py` / `root_index.py` / `concepts_index.py` hold:

- It lays down a fixed set of `## <Facet>` sections (Who / What / Why / When /
  Where / How) and, under each, a count-link line for that facet's backing types.
  **When** and **Where** are the two exceptions — each renders a custom derived
  body instead of a count-link (When a log-derived timeline, §4; Where a
  market grouping, §5).
- The counts come from `sub_index.theme_counts` — the **same** theme-assignment
  code that decides which pages each type's sub-index lists — summed across
  themes for the cross-base total. So `People (n)` on the overlay can never drift
  from the people sub-index, exactly as the root MAP's per-theme counts can't.
- Re-rendering an unchanged wiki is a **byte-identical no-op** (counts are
  deterministic from disk; carried spans are preserved). The cross-theme link the
  root portal gains is a constant preamble line (no `- [[slug]]` bullet, no extra
  `## ` heading), so it stays a fixpoint of the Step 10.5 `lint --fix=all`
  reflow/collapse passes — `test_root_index.sh` stays green.

The Tier-1 facet→type mapping:

| Facet | Backing types | Rationale |
|---|---|---|
| **Who** | people + entities | the named subjects |
| **What** | concepts + sources | the definitions and the primary evidence |
| **Why** | questions + syntheses | the inquiry drivers and the conclusions |
| **When** | `wiki/log.md` | a log-derived timeline (v1; grouped by month) |
| **Where** | source `market:` | sources grouped by market (v1; `geo:` is v2) |
| **How** | *(none yet)* | its former backing types were retired (see §4) |

### 3. Narrated facet lead-ins under MACHINE-OWNED sentinels — human work untouchable

Ownership is enforced by two nested sentinels, the same posture
`portal-shape-decision.md` §1 and `concepts-shape-decision.md` §3 establish:

- A page-level `MACHINE-OWNED:PERSPECTIVES-INDEX` marker. A hand-authored
  `wiki/perspectives.md` carrying **no** marker is never touched — a human who
  wants to own the whole page simply omits it (`skipped_human_page`).
- A per-facet `MACHINE-OWNED:PERSPECTIVES-FACET:<slug>` lead-in span. Within a
  machine-owned page, the engine seeds a deterministic default lead-in for each
  facet and carries any authored lead-in forward verbatim on every re-render. A
  future facet narrator (the analog of `portal-narrator` / `concepts-outliner`)
  fills those spans; Tier 1 ships the deterministic defaults, leaving the spans
  ready for narration without changing the renderer contract.

### 4. When (v1) — log-derived timeline

The **When** facet renders a deterministic timeline of how the base grew,
derived from data that **already exists** — no new ingest-time capture. The v1
source is the append-only control log (`wiki/log.md`, resolved meta-first via
`_knowledge_lib.log_path` so the curated-layout `wiki/meta/log.md` is found
too): each `## [YYYY-MM-DD] <op> | <details>` operation heading is parsed,
grouped by month (`YYYY-MM`, newest first), and rendered as one row per month
with the operation count and the distinct operation types. The parse is stable
because the log is append-only; the render is byte-identical on an unchanged
wiki, the same contract every other facet holds. An absent / empty / unreadable
log renders an honest `_(no timeline yet)_` line — When **never fabricates** a
timeline.

Per-page `created:`/`updated:` frontmatter is available as a corroborating
signal (`frontmatter_scalar`) but the v1 timeline derives from the log alone —
the purpose-built, richer source — to avoid over-engineering. **Claim-level
event-date extraction is explicitly deferred to When v2** (it is fuzzy and would
couple the deterministic renderer to claim-text NLP); see Out of scope below.

### 5. Where (v1) — market grouping

The **Where** facet groups source pages by the **market** they were researched
for. The curator already knows each research run's market (`plan.json::market`,
a single run-level value like `dach`), but it was never persisted — so v1's only
new cost is capturing it. `knowledge-ingest` threads the run-level `MARKET` to
every `source-ingester` (exactly as it threads `THEME_LABEL`), and the ingester
writes `market: "<MARKET>"` frontmatter on each source page — the geography
sibling of the `theme_label:` membership signal, quoted via `json.dumps` and
emitted only when set. The render (`_build_where_grouping`) scans
`wiki/sources/*.md`, groups non-empty `market:` values alphabetically with
per-market counts, and renders the honest `_(no pages in this facet yet)_` line
on a base whose sources carry no `market:` (legacy / not-yet-tagged) — it
**never fabricates** a grouping.

Why `market:` and not a render-time domain heuristic: the curator's ingest-time
knowledge is authoritative and richer than guessing geography from a publisher
domain, and persisting it mirrors the established `theme_label:` pattern (a
frontmatter-resident membership signal the renderer reads).

**`geo:` (finer-grained per-source geography) is deferred to Where v2** — there
is **no per-source geo signal** at ingest today (only the run-level market), so
implementing it now would fabricate data. Recorded here, mirroring the When
v1/v2 honest split; see Out of scope below.

### 6. Honest-empty How

One facet still renders **honestly empty** at Tier 1 — a `## How` heading, an
engine-owned lead-in explaining why, and a `_(no pages in this facet yet)_` line:

- **How** has no backing types *by decision*. Its former candidates — the
  cross-source `summary` and the run-level `learning` page types — were retired
  as dead vocabulary (zero pages across the production wikis, actively
  discouraged by the distiller). Rather than re-project a cut type, How renders
  empty and awaits a future process/method page type.

Honest-empty is a feature, not a gap: the overlay is *complete* (all six facets
present) and *truthful* (it never fabricates a projection for a facet with no
backing data), and the empty slot advertises exactly what a future child will
fill.

## Out of scope (Tier 1)

- **When v2** — claim-level event-date extraction (temporal dates mined from
  claim text). Deferred from When v1: it is fuzzy and would couple the
  deterministic renderer to claim-text NLP. The v1 log-derived timeline ships here.
- **Where v2** — finer-grained per-source `geo:` geography (a sub-market /
  region signal mined or captured per source). Deferred from Where v1: no
  per-source geo signal exists at ingest today, only the run-level market that
  v1 ships. Recorded here rather than filed, since no data source yet makes it
  actionable.
- A **facet narrator** agent that authors the `PERSPECTIVES-FACET` lead-ins from
  the projected pages (the analog of `portal-narrator`). Tier 1 ships the
  deterministic default lead-ins; the spans are ready for it.
- **knowledge-setup new-wiki seeding** of `wiki/perspectives.md`. Not required for
  correctness — the overlay renders idempotently on the first `knowledge-finalize`
  or `knowledge-index` run regardless — so it is left out of Tier 1; a parity pass
  may add it alongside the sub-index seeds.

## Cross-references

- `references/portal-shape-decision.md` — the curated-portal version of the
  renderer/narrator split, the MACHINE-OWNED sentinel posture, and the
  byte-idempotent contract this overlay re-applies.
- `references/concepts-shape-decision.md` — the concept-map version of the same
  argument (standalone derived page, deterministic structure, narrated lead-ins).
- `scripts/perspectives_index.py` — the deterministic overlay renderer.
- `skills/knowledge-finalize/SKILL.md` (Step 10.5 sub-step 3.8) — the overlay
  render sub-step.
- `skills/knowledge-index/SKILL.md` (rebuild mode) — the overlay render in the
  curated-index rebuild loop.
