# Portal shape decision — knowledge-finalize ↔ curated portal

Design record for how `knowledge-finalize` treats the **curated portal content**
of a bound wiki — the per-`## <theme>` lead-in paragraphs in `wiki/index.md` and
the "state of the wiki" prose in `wiki/overview.md` — when it deposits a verified
synthesis. (Naming sibling to `references/delegation-contract.md` /
`differentiation-thesis.md`.)

## The question

The Knowledge Portal turns `wiki/index.md` into a single human entry point:
beyond the auto-maintained bullet catalog, each `## <theme>` may carry a short
editorial **lead-in paragraph** framing why the theme matters and what to read
first, and `wiki/overview.md` carries an evolving "state of the wiki" narrative.
When finalize grows the base (a new synthesis under `## Syntheses`, new sources /
question nodes under their `theme_label` headings during ingest), should it
**touch** that curated prose, or leave it strictly human-owned?

Two directions were on the table:

- **4a — preserve-only.** Lead-ins stay human-owned, write-once. finalize never
  authors portal prose; the bullet catalog grows but the framing goes stale until
  a human edits it.
- **4b — auto-refresh.** finalize runs an LLM pass to (re)author per-theme
  lead-ins and refresh the overview narrative as the base grows, so the portal
  **compounds narratively** the way distilled pages already do via
  `concept-summary-narrator` → `concept-store.py renarrate`.

## Decision: 4b (auto-refresh), staged by default

4b is the compounding-narrative bet that fits cogni-knowledge's thesis — knowledge
compounds across runs, not throwaway reports. A portal whose framing never
refreshes is a portal that rots; the same argument that justified
narratively-compounding distilled-page summaries (#341) justifies a
narratively-compounding portal.

The risk 4b carries is that the engine would rewrite **human editorial framing** —
and the *protected-lead-in contract* in `wiki_index_update.py` (cogni-wiki SCHEMA
§"Protected lead-in guarantee") exists precisely to never do that. So the design's
central job is to reconcile compounding with human ownership. It does so three
ways.

### 1. Ownership sentinel — the engine only touches what it owns

The engine authors/refreshes a lead-in **only** when that lead-in is wrapped in a
`MACHINE-OWNED:PORTAL-LEADIN` sentinel:

```markdown
## <theme>
A human-curated lead-in (NO sentinel) — protected, never touched.
<!-- MACHINE-OWNED:PORTAL-LEADIN:START refreshed:2026-06-05 bullets:7 -->
Engine-authored lead-in prose. Refreshable.
<!-- MACHINE-OWNED:PORTAL-LEADIN:END -->

- [[slug-a]] — …
- [[slug-b]] — …
```

- A section whose lead-in has **no sentinel** = human-owned → never touched (the
  existing protected-lead-in contract holds unchanged).
- The engine authors a machine span **only** for a theme that has no machine span
  yet, refreshes **only** spans it previously authored, and **never converts**
  human prose to machine-managed.
- The span always sits **above the bullet block and below any human lead-in**, so
  the bullet preservation and the human-lead protection both still hold.
- Bullets are always preserved — the splice replaces only the sentineled span.

The splice primitive lives in **cogni-wiki** (`wiki_index_update.py --get-leadin`
/ `--set-leadin`), co-located with the section/lead-in model and the
protected-lead-in regression tests it extends. cogni-knowledge calls it at script
level (the M6 "call helper scripts directly" posture). cogni-wiki cannot import
cogni-knowledge's `_knowledge_lib.extract_machine_block` (the dependency direction
is one-way), so cogni-wiki carries a self-contained parallel of the sentinel
helpers; the sentinel *format* is the documented shared convention in
`wiki-setup/references/SCHEMA.md.template` §"Machine-managed lead-in".

The overview narrative uses the analogous `MACHINE-OWNED:OVERVIEW-NARRATIVE`
sentinel, spliced cogni-knowledge-side via
`_knowledge_lib.replace_machine_block` / `upsert_machine_block` (overview has no
cogni-wiki section script, and finalize already edits `overview.md` inline in the
Step 10.5 gate). It preserves the `## Recent syntheses` machine bullets and all
other prose byte-for-byte.

### 2. Human diff choice-point — stage by default, apply on opt-in

4b authors prose, but a human still owns the portal. So finalize **stages** a
proposed portal diff by default and only **applies** on explicit opt-in:

- **DEFAULT (autonomous / no flag): STAGE.** finalize writes a human-readable
  `<wiki>/.cogni-wiki/portal-proposed.md` (per-theme current-vs-proposed lead-in
  + the proposed overview narrative) and does **not** write the live portal. Step
  11 surfaces `Portal: N lead-ins + overview proposed — review <path>, apply with
  --apply-portal`.
- **OPT-IN (`--apply-portal`, alias `--refresh-portal`): APPLY.** finalize calls
  `wiki_index_update.py --set-leadin` per theme + splices the overview narrative.
- **`--no-portal`** skips the whole refresh step.

Staging by default keeps an autonomous `knowledge-refresh --mode push` loop from
silently mutating editorial framing; the operator reviews the diff and applies
when satisfied. (A future interactive "apply?" confirm when finalize is run
directly by a human — distinct from inside the autonomous loop — is a listed
follow-up; it needs a loop-context signal that does not exist today.)

### 3. Staleness story — refresh only what grew, and surface drift

- finalize only proposes lead-ins for the **themes that grew this run**: the
  `theme_label`s of the run's `plan.json` sub-questions (the themes ingest filed
  sources / question nodes under) ∪ `Syntheses` (the synthesis just deposited),
  intersected with the `## <theme>` sections that actually exist on the index.
  Empty → the step skips cleanly.
- Each applied lead-in stamps `refreshed:<date> bullets:<N>` into the sentinel's
  START comment, where `<N>` is the section's bullet count at write time. **Drift**
  is then computable later as "current bullet count exceeds the stamped
  `bullets:<N>` by a threshold" — a theme that has grown materially since its
  lead-in was last refreshed. Surfacing that drift (a `knowledge-dashboard` /
  `wiki-health` "stale portal lead-ins: M themes" line) is a **follow-up**, not
  this PR; the stamp ships now so the signal is recordable from day one.
- Idempotence: the portal-narrator emits an unchanged lead-in verbatim, so a
  re-apply with no new bullets no-ops the splice (no stamp/date churn), matching
  `concept-store.py renarrate` semantics.

## Out of scope (per the issue)

Authoring the actual lead-in content for any **live base** (e.g.
`.alpha/eu-ai-act-sme`) is an editorial/ops task on data outside this repo. This
work ships the **engine + synthetic-fixture tests only** — no live-base prose.

## Architecture (mirrors the Phase-4.5 renarrate rails)

```
knowledge-finalize Step 10.5 sub-step 3.5 (after the overview-bullet refresh,
                                           before rebuild_context_brief.py)
  │
  ├─ refresh set = plan.json theme_labels ∪ {Syntheses}, ∩ existing ## sections
  │
  ├─ build bundle (per theme: --get-leadin + section bullets;
  │                + overview narrative span + ## Recent syntheses bullets)
  │      │
  │      ▼  Task(portal-narrator)  → portal-records.txt   (raw-text proposals)
  │
  ├─ DEFAULT: STAGE → <wiki>/.cogni-wiki/portal-proposed.md   (live portal unchanged)
  │
  └─ OPT-IN (--apply-portal): APPLY
        • per theme: wiki_index_update.py --set-leadin   (cogni-wiki, locked)
        • overview:  _knowledge_lib upsert MACHINE-OWNED:OVERVIEW-NARRATIVE
```

## Follow-ups (not this PR)

- `knowledge-dashboard` / `wiki-health` surfacing of portal-lead-in drift counts
  (the stamp consumer).
- Interactive "apply?" confirm when finalize is run directly by a human (needs an
  autonomous-loop signal threaded from `knowledge-refresh --mode push`).
- Richer apply affordance (apply from the dashboard; partial per-theme apply).
- Migrating the overview narrative splice into a cogni-wiki overview helper if one
  is added.
