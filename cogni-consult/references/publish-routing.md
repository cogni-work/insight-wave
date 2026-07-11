---
name: publish-routing
description: Canonical contract mapping a completed deliverable to a presentation format and the dispatch route that builds its brief — the single source of truth the publish path executes instead of hard-coding routing.
---

# Publish Routing

When a deliverable is complete and the consultant elects to publish it, this
file is the canonical contract for **which presentation format it becomes** and
**exactly how the corresponding brief is built**. The publish path points here
rather than restating the routing, so the contract stays auditable and cannot
drift across skills.

A publish run takes a finished deliverable artifact at
`action-fields/<field-slug>/<deliverable-slug>.md` and terminates in a clean
**brief** — the handoff the consultant takes to Claude Design (claude.ai/design)
to render in their own design system. Rendering and brand are out of plugin
scope: cogni-consult produces the brief, Claude Design produces the rendered
artifact.

## Presentation Formats

The consultant chooses one of four target formats at publish time. The choice is
not fixed per deliverable type — `deliverable-types.md` records a deliverable's
format preference in its own artifact when it is produced, never in `field.json`
— so the routing below keys on the **format the consultant elects**, not on a
catalog default.

| Format | What it produces | Built by |
|---|---|---|
| `slides` | An ordered section outline for a presentation deck | consult-native outline brief |
| `web-poster` | A single-scroll web page / poster outline | consult-native outline brief |
| `report` | A structured report-outline brief for a themed report | consult-native report-outline brief |
| `infographic` | A single-page infographic brief | consult-native infographic brief |

Every format is built **natively** as a brief — no route renders locally or
applies a theme on the standard path. The four `Built by` builders all run
inside this skill; cogni-visual is no longer dispatched as a standard route (it
remains an explicit opt-in local-render fallback only — see each route below).

## Routing by Format

### slides / web-poster → consult-native outline brief

Consult deliverables are **framework-shaped** (Pyramid / SCQA / MECE), not
**arc-shaped**. The arc-optimized cogni-visual skills (`story-to-slides`,
`story-to-web`) auto-detect a narrative arc and build best when the source is a
story; a WBS-addressed analytical deliverable is not a story, so dispatching them
directly yields a weak brief. For the same reason this path does **not**
re-narrate the deliverable through `cogni-narrative` — arc-ifying a
framework-shaped deliverable softens the executive/Pyramid register it is written
in.

Instead, derive a **consult-native outline brief** directly from the
deliverable's own structure: an ordered list of `{section_title, section_body}`
entries, citations preserved. The mapping from the deliverable's framework to the
outline:

- **Pyramid answer / governing thought** → the opening (title slide or hero
  section).
- **MECE groups / SCQA movements** → one section entry each, in the
  deliverable's own order.
- **Supporting evidence and citations** → carried into the corresponding
  section body; never dropped.

The brief is a plain title-and-description outline — exactly what Claude Design's
presentation generator consumes. Write it alongside the deliverable, e.g.
`action-fields/<field-slug>/publish/<deliverable-slug>-outline.md`.

#### Optional presentation-intent layer

The `{section_title, section_body}` outline above optimizes for **narrative
completeness** and is the only required shape — a brief with nothing more than
those entries is valid and renders. But on its own it leaves the downstream
renderer (Claude Design) to guess two things every deck needs settled up front:
the **design register**, and **what belongs on the slide vs. in the talk-track**.
That guessing turns into a clarify-then-build round before the deck can be built.

To skip that round and let the deck build in one pass, the author **may** layer a
thin **presentation-intent** annotation on top of the same content. It is
**optional and additive** — omit any piece and the brief still renders; the
narrative-completeness strength is never traded away. The author (not the
renderer) owns the slide-vs-notes and emphasis decisions. The five pieces:

1. **`design:` front-matter block** — a small block at the head of the brief
   declaring the deck's design intent, so the renderer does not ask. Fields, all
   optional with sensible defaults:
   - `register` — the visual/tonal register (e.g. `quiet-executive`, `bold`).
     Default: the deliverable's own register (executive/Pyramid).
   - `dark_slides: [...]` — slide numbers to render dark, as rhythm anchors
     (e.g. section breaks, the climax). Default: none.
   - `speaker_notes` — the speaker-notes style (e.g. `full-script`,
     `calm peer-to-peer`, `bullets`). Default: bullets.
   - `imagery` — imagery direction (e.g. `none`, `type-only`, `photographic`).
     Default: `none`.
   - `variations` — how many design variations to generate. Default: 1.
2. **Per-slide `slide_points` vs. `talk_track` split** — instead of one
   `section_body` that blends wall copy with presenter rationale, split the entry
   into `slide_points` (3–4 short on-slide lines, max) and `talk_track` (the
   reasoning the presenter speaks). This moves the on-slide-vs-notes distillation
   decision into the brief. When the split is omitted, `section_body` stands as
   before — the renderer distills it.
3. **Per-slide `type:` tag** — declares the intended visual treatment instead of
   leaving the renderer to infer it (so a quote slide is not built as bullets).
   One of: `cover`, `bluf`, `two-column`, `table`, `timeline`, `quote`, `metric`,
   `roles`. Default: inferred from the section content, as today.
4. **`key_figures:`** — a brief-level list promoting the hero numbers out of
   prose (e.g. `~25 auditors`, `8–10 shortlist`, `240 min`, `≥80% return`,
   `~30 backlog`) so the renderer can build big-number moments rather than
   burying them in body text. A promoted figure that carries a provenance
   marker keeps it (e.g. `€4.2bn (prov: claim/reviewed)`) — the marker travels
   with the value into the stat block, never stripped. Default: none (numbers
   stay inline).
5. **Climax and TBD marks** — name the point slide for emphasis (e.g.
   `climax: slide 11` — the asks), and flag genuine placeholders
   (`tbd: ["CO-1…4 staffing", "confirm exact title"]`) so the renderer treats
   them as open vs. settled copy. Default: none.

**Keep, regardless of the layer:** the meta-instruction `note:` line (e.g.
"render citations as footnotes / speaker notes") and the **"design is frozen"**
framing — both proved useful in real handoffs; favor more of that over reasoning
prose buried inside bullets.

### report → consult-native report-outline brief

A report deliverable is already framework-shaped prose, so — exactly like the
slides/web-poster outline — build a **consult-native report-outline brief**
directly from its structure rather than dispatching a local renderer. It is the
outline's report-shaped sibling: an executive-summary lead (the Pyramid
governing thought / BLUF) followed by ordered `{section_title, section_body}`
entries that preserve the deliverable's MECE groups / SCQA movements in its own
order, carrying the full supporting prose and citations into each section body —
never dropped. This is exactly what Claude Design's document/report generator
consumes; Claude Design renders the themed HTML/PDF/DOCX and applies brand. Write
it alongside the deliverable, e.g.
`action-fields/<field-slug>/publish/<deliverable-slug>-report-outline.md`.

**Opt-in fallback.** When the consultant explicitly wants a locally-rendered
artifact and `cogni-visual` is installed, `cogni-visual:enrich-report`
(`source_path: action-fields/<field-slug>/<deliverable-slug>.md`) remains
available as an opt-in fallback. It is **no longer the standard path** — it
renders locally and applies a cogni-visual theme, which the brief-only contract
otherwise avoids.

### infographic → consult-native infographic brief

Build a **consult-native infographic brief** directly from the deliverable
rather than dispatching a local renderer: the Pyramid governing thought as the
headline, the key quantified facts / hero numbers pulled from the deliverable's
evidence (a hero number that carries a provenance marker keeps it — the
`(prov: type/status)` parenthetical travels with the value into its stat block,
never stripped), each MECE group as one infographic segment (a stat-or-insight
block), and a single call-to-action takeaway — citations preserved in the brief.
This is
exactly what Claude Design's infographic generator consumes; Claude Design
renders and themes it. Write it alongside the deliverable, e.g.
`action-fields/<field-slug>/publish/<deliverable-slug>-infographic-brief.md`.

**Opt-in fallback.** When the consultant explicitly wants a locally-rendered,
auto-themed infographic and `cogni-visual` is installed,
`cogni-visual:story-to-infographic`
(`source_path: action-fields/<field-slug>/<deliverable-slug>.md`, optional
`style_preset`) remains available as an opt-in fallback. It is **no longer the
standard path** for the same reason as `report`.

## Optional Voice Polish

Before building any brief, the deliverable or outline text may be polished with
`cogni-copywriting:copywriter`. This step is optional and graceful-degrading —
skip it and the route still produces a valid brief.

```
Skill: cogni-copywriting:copywriter
  FILE_PATH=<absolute path to the deliverable or outline .md>
  --scope=tone   AUDIENCE=mixed
```

Scope guidance: `--scope=tone` for a light pass that preserves structure;
`--scope=compress` to tighten for an executive audience; `--scope=full` for a
Pyramid / BLUF restructuring before a client-facing presentation. `TARGET_LANG`
translates when the brief's language differs from the deliverable's.

One hard rule regardless of scope: the polish must preserve `{{asm:id}}`
placeholder tokens **verbatim**. Assumption resolution runs after any polish
(it is the last transformation before lineage recording), and a reworded token
no longer matches the resolver's strict form — the resolver's
malformed-placeholder check catches near-misses that still contain `asm`, but
a fully prose-ified token is unrecoverable, so instruct the copywriter to
treat `{{...}}` tokens as frozen.

## Assumption Resolution (mandatory, fail-loud)

Every route's built brief runs through the assumption resolver **after the
brief file is written (and after any optional voice polish) and before the
publish lineage is recorded** — one generic pass covers all four formats,
since every route terminates in a brief file. The resolver replaces each
`{{asm:<slug>}}` placeholder with the `value` of the `asm-<slug>` entry in the
engagement-root `assumptions.json` registry (the single source of truth for
assumption values — schema: `references/data-model.md`, Assumption Registry).
The write is atomic (temp file + rename), so a failed run never truncates the
built brief.

An in-place resolve performs a **second atomic write**: each resolved
assumption gains a `used_by[]` reference edge for the citing brief, so
re-publishing is idempotent and dry-runs record nothing (full edge semantics:
`references/dependency-model.md`, `used_by[]`). The edge is recorded
**before** the brief is rewritten: a failed edge write returns
`success: false` with `failed_check: "used_by_write_failed"` and leaves the
brief's placeholders intact — nothing was written, and the run is safely
retryable.

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/resolve-assumptions.py" \
  <engagement-dir> resolve <brief-path> --in-place
```

The invocation emits a single `{"success": bool, "data": {...}, "error": str}`
envelope. Failure contract — deliberately the inverse of the optional voice
polish's graceful degradation:

- **Unknown placeholder id** → `success: false`, exit 1,
  `data.failed_check: "unknown_assumption_id"`, `data.ids[]` listing **every**
  unresolved id (not just the first). The publish run stops; nothing is
  recorded in `field.json`.
- **Malformed placeholder** — a `{{...asm...}}` token that does not match the
  strict `{{asm:<kebab-slug>}}` form (uppercase, underscores, stray spaces) →
  `success: false`, exit 1, `failed_check: "malformed_placeholder"`,
  `data.tokens[]` listing every offender. Typos fail loud instead of shipping
  verbatim.
- **Placeholder remaining after substitution** — a registry value that itself
  embeds (or re-forms) a placeholder → `success: false`, exit 1,
  `failed_check: "unresolved_after_substitution"`; nothing is written.
- **Defective registry entry** — missing/malformed `id`
  (`invalid_assumption_id`), missing or `null` `value`
  (`missing_assumption_value`), or **duplicate id**
  (`duplicate_assumption_id`) → `success: false`, exit 1, listing every
  offender. Same stop.
- **Missing/unreadable registry while placeholders exist** →
  `success: false`, exit 1 (`registry_missing` / `registry_unreadable`).
  Re-running `engagement-init.sh` backfills an empty registry on engagements
  that predate it.
- **Provenance-cap violation** — a provenance-typed entry whose `status`
  exceeds its `provenance_type` cap (`status_cap_exceeded`; includes a
  hand-authored `verified`, which is reserved for the verify path), a typed
  entry missing its `status` partner or vice versa (`incomplete_provenance`),
  or an out-of-vocabulary `provenance_type` / `status`
  (`invalid_provenance_type` / `invalid_status`) → `success: false`, exit 1,
  listing every offender. A guess can never be authored with a verified
  confidence — the cap is enforced before any brief is written. These checks
  are **scoped to the assumptions the brief actually cites** (unlike the
  registry-integrity checks above, which fail on any malformed entry): because
  provenance typing is opt-in and per-value, a mis-typed *uncited* assumption
  never blocks an unrelated deliverable's publish.
- **No placeholders in the brief** → `success: true` no-op
  (`placeholders_found: 0`); registry absence is then not an error, so
  engagements predating the registry publish unchanged.

A placeholder is never silently left in the handoff and never silently
dropped — an unresolvable assumption is a data error the consultant fixes in
`assumptions.json` (or in the placeholder), not a rendering detail.

### Per-number provenance marker

When an assumption carries `provenance_type` + `status` (see
`references/data-model.md`, Assumption Registry), the resolver renders a
confidence marker immediately after the substituted value — e.g.
`€4.2bn (prov: claim/reviewed)` — so a reader of the published brief sees each
number's provenance inline and a guess is visually distinct from a verified
figure. Untyped (legacy) entries render bare. The marker is a **parenthetical,
not a `[...]` span**, so it can never form a spurious Markdown inline link when
a template writes `(` right after the placeholder, and it is brace-free so it
can never re-form a `{{asm:…}}` placeholder or trip the
`unresolved_after_substitution` check on a re-resolve. Because every publish
route delegates to this single resolution pass, the marker surfaces in all four
formats (slides / web-poster / report / infographic) with no per-route change.
The marker wording is **settled**: the raw `(prov: type/status)` parenthetical is
the finalized form — compact, link-safe, brace-free, and format-agnostic, so it
reads the same inline and when a number is promoted to a hero figure. When a
route lifts a number out of prose into a standalone hero figure (the
`key_figures:` list for slides / web-poster, or an infographic hero number), the
marker **travels with the promoted value** — rendered immediately after it, never
stripped — so a hero stat carries its provenance just as an inline number does.

### Verify path — reuse by contract, no new verifier

`verified` is the only status the consultant cannot hand-author; it is earned
through the **cogni-claims** verify round-trip, which is live and runs in three
legs. **Submit:** `scripts/submit-assumption-claim.py submit` adapts the
claim-type assumption onto the unchanged cross-plugin contract — the adapter
maps consult's flat-string coordinate to the object locator
`{type: "assumption", file: <project-relative assumptions.json path>,
field_path: assumptions[?id=="<asm-id>"].value}` — and appends an `unverified`
ClaimRecord to the workspace `cogni-claims/claims.json` (idempotent: one
assumption maps to exactly one record). **Verify:** the existing cogni-claims
machinery (`cogni-claims:claims`, verify mode) checks the claim against its
source; cogni-consult builds **no** verifier of its own. **Propagate:**
`submit-assumption-claim.py propagate` writes `status: "verified"` plus the
`citation.claim_id` back-reference onto the assumption record — and refuses
unless the referenced ClaimRecord is itself `verified`. At render time
`resolve-assumptions.py` enforces the same evidence gate: a cited claim-type
assumption at `verified` must carry a `citation.claim_id` that resolves to a
verified ClaimRecord, else the resolve fails loud. Cascading deviated/resolved
verdicts back onto records (the broader corrections wrapper) remains a separate
follow-up surface.

## Handoff Contract

Every route terminates in a **brief file** built natively inside this skill —
no standard route renders locally or owns a theme — and the brief's path *is*
the handoff. Briefs are stored as **path references** — never copied into consult
state — mirroring the research storage contract: the deliverable and its
downstream brief are linked by path, so a correction upstream is visible
downstream without duplicating content.

The consultant takes the brief to Claude Design (claude.ai/design) and renders it
in their own design system. cogni-consult never renders and never owns brand —
its output stops at the brief.
