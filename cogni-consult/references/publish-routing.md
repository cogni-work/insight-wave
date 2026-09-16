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
**brief**. Reports and infographics hand that brief to Claude Design. Slides and
web-posters may additionally enter cogni-publishing's public local render chain
when the consultant elects it.

## Presentation Formats

The consultant chooses one of four target formats at publish time. The choice is
not fixed per deliverable type — `deliverable-types.md` records a deliverable's
format preference in its own artifact when it is produced, never in `field.json`
— so the routing below keys on the **format the consultant elects**, not on a
catalog default.

| Format | What it produces | Built by |
|---|---|---|
| `slides` | A framework-preserving direct brief; optional editable PPTX | consult-native direct brief; optional publishing render |
| `web-poster` | A framework-preserving direct brief; optional HTML page | consult-native direct brief; optional publishing render |
| `report` | A structured report-outline brief for a themed report | consult-native report-outline brief |
| `infographic` | A single-page infographic brief | consult-native infographic brief |

Every format is built **natively** as a brief. Only slides and web-poster can
continue into an elected local render, and that continuation uses public
cogni-publishing capabilities. Report and infographic remain brief-only Claude
Design handoffs.

## Routing by Format

### slides / web-poster → consult-native direct brief

Consult deliverables are **framework-shaped** (Pyramid / SCQA / MECE), not
**arc-shaped**. The arc-optimized cogni-publishing skill
(`text-to-narrative`) selects a narrative arc and builds best when the source is
a story; a WBS-addressed analytical deliverable is not a story, so re-narrating
it through `text-to-narrative` yields a weak brief and arc-ifying a
framework-shaped deliverable softens the executive/Pyramid register it is written
in. This path therefore never dispatches it.

Instead, derive a **consult-native `direct-brief@1`** directly from the
deliverable's own structure. Declare the public artifact type/version, an
artifact id, `structure.framework`, ordered `sections[]`, and `sources[]`.
Sections carry stable ids, title/body, optional role/notes/data, and
`source_refs[]`; citations and source identity are preserved. The mapping from
the deliverable's framework to the sections:

- **Pyramid answer / governing thought** → the opening (title slide or hero
  section).
- **MECE groups / SCQA movements** → one section entry each, in the
  deliverable's own order.
- **Supporting evidence and citations** → carried into the corresponding
  section body; never dropped.

Write it alongside the deliverable as
`action-fields/<field-slug>/publish/<deliverable-slug>-direct-brief.json`.

#### Optional local render

After mandatory assumption resolution, the consultant may elect this bounded
public chain:

1. `cogni-publishing:publishing-validate` — `normalize --kind direct`.
2. `cogni-publishing:design-compose` — bind frozen records to accepted patterns.
3. `cogni-publishing:design-render` — `pptx` for slides, `html` for web-poster.

These three capability calls are one elected local-render continuation in
consult lineage. Record exactly one `local-render:pptx` or `local-render:html`
entry in `publish[].route_steps`; do not expand the internal validate, compose,
and render calls into three lineage entries.

The selected publishing theme is an explicit input. If cogni-publishing or a
theme is unavailable, retain the valid direct brief and offer the Claude Design
handoff. Never re-narrate through `cogni-publishing:text-to-narrative`.

#### Optional presentation-intent layer

When local rendering is declined, the direct brief may be projected into a
companion Markdown outline for Claude Design. That companion optimizes for
**narrative completeness**, but on its own leaves the downstream renderer to
guess two things every deck needs settled up front:
the **design register**, and **what belongs on the slide vs. in the talk-track**.
That guessing turns into a clarify-then-build round before the deck can be built.

The canonical definition of this layer lives in
`cogni-publishing/references/presentation-intent.md`. The marked block below is a
synchronized copy of it, compared byte for byte by
`cogni-consult/tests/test-presentation-intent-sync.sh` — edit one copy and the
guard goes red until the other matches. The copy is kept here in full, rather
than reduced to a pointer, so this subsection stays a complete schema when
cogni-consult is installed without a cogni-workspace tree beside it.

To skip that round and let the Claude Design deck build in one pass, the author **may** layer a
thin **presentation-intent** annotation on top of the same content. It is
**optional and additive** — omit any piece and the brief still renders; the
narrative-completeness strength is never traded away. The author (not the
renderer) owns the slide-vs-notes and emphasis decisions. The five pieces:

<!-- PRESENTATION-INTENT:SHARED:START -->

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

<!-- PRESENTATION-INTENT:SHARED:END -->

This companion is not the input to `publishing-validate` and never replaces the
direct brief's lineage path.

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

**No local route.** Claude Design renders the report-outline brief. Do not map
it to HTML or PPTX through the slides/web-poster chain.

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

**No local route.** Claude Design renders the infographic brief. Do not map it
to HTML or PPTX through the slides/web-poster chain.

## Optional Voice Polish

Before building any brief, the deliverable or outline text may be polished with
`cogni-publishing:copywriter`. This step is optional and graceful-degrading —
skip it and the route still produces a valid brief.

```
Skill: cogni-publishing:copywriter
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

Every route resolves assumptions **after optional voice polish and before the
publish lineage is recorded**. Markdown routes run the resolver on the written
brief. The direct JSON route resolves the working Markdown first, then JSON-
escapes the resolved strings during serialization and rejects any serialized
artifact that still contains a placeholder. The resolver replaces each
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

This mandatory publish pass uses the resolver's default `value` mode (literal
substitution), which is unchanged. See "Link-render mode" below for the opt-in
`--mode link` capability.

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
through the **`cogni-workspace:claims`** verify round-trip, which is live and runs in three
legs. **Submit:** `scripts/submit-assumption-claim.py submit` adapts the
claim-type assumption onto the unchanged cross-plugin contract — the adapter
maps consult's flat-string coordinate to the object locator
`{type: "assumption", file: <project-relative assumptions.json path>,
field_path: assumptions[?id=="<asm-id>"].value}` — and appends an `unverified`
ClaimRecord to the workspace `cogni-claims/claims.json` (idempotent: one
assumption maps to exactly one record). **Verify:** the existing claim-verification
machinery (`cogni-workspace:claims`, verify mode) checks the claim against its
source; cogni-consult builds **no** verifier of its own. **Propagate:**
`submit-assumption-claim.py propagate` writes `status: "verified"` plus the
`citation.claim_id` back-reference onto the assumption record — and refuses
unless the referenced ClaimRecord is itself `verified`. At render time
`resolve-assumptions.py` enforces the same evidence gate: a cited claim-type
assumption at `verified` must carry a `citation.claim_id` that resolves to a
verified ClaimRecord, else the resolve fails loud. **Resolve-propagate:**
cascading deviated/resolved verdicts back onto records is wired into the
consult-design-thinking *Claims-correction cascade* step — `submit-assumption-claim.py
resolve-propagate` writes the corrected value back and demotes `verified` →
`reviewed`, then `deliverable-graph.py cascade-stale --assumption` fans the
staleness to every deliverable citing that assumption.

### Link-render mode (`--mode link`, opt-in)

The resolver carries a second render mode alongside the default literal
substitution. With `--mode link` it substitutes each `{{asm:<slug>}}` with an
Obsidian wikilink into the browsable register instead of the bare value:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/resolve-assumptions.py" \
  <engagement-dir> resolve <brief-path> --mode link [--in-place]
```

`{{asm:tam-dach-2027}}` becomes `[[assumptions#tam-dach-2027|€4.2bn]]` — the
value as the link's display text, anchored at the register's `## <slug>` heading
(`scripts/register-generator.py`). The `(prov: type/status)` provenance marker
still trails the link exactly as it trails a bare value, and the anchor slug is
the placeholder suffix (id minus the `asm-` prefix). Because the output uses
double **square** brackets, it can never match the brace-only leftover check
(`{{...asm...}}`), so the fail-loud "no placeholder may survive" contract is
unaffected. Everything else — the `used_by[]` edge write, the provenance /
verified-evidence gates, atomicity — is identical to `value` mode.

**Invocation policy is deliberately unspecified.** This mode is delivered as an
opt-in capability only. It is **not** wired into the mandatory publish pass above
(which stays on `value` mode), and there is no established precedent for a
non-publish-time render. Whether link-render fires inside `register-generator.py`,
at `consult-publish`, at `engagement-init`, and/or after every `assumptions.json`
mutation is an open question for a maintainer to settle before the automatic
wiring lands — until then, invoke `--mode link` explicitly.

## Handoff Contract

Every route terminates in a **brief file** built natively inside this skill.
Briefs are stored as **path references** — never copied into consult
state — mirroring the research storage contract: the deliverable and its
downstream brief are linked by path, so a correction upstream is visible
downstream without duplicating content.

For report and infographic, the consultant takes the brief to Claude Design.
For slides and web-poster, an elected public publishing render may add an
`artifact_path`; the brief remains the provenance source and cogni-consult still
owns no theme or renderer.
