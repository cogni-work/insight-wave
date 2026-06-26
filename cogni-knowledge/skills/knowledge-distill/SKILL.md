---
name: knowledge-distill
description: "Phase 4.5 of the inverted pipeline (between ingest and compose). Distills the run's source claims into recurring type:concept / type:entity / type:person pages, creating-or-merging them under a lock with claim-level dedup so the bound wiki compounds across runs (distilled pages get enriched, not duplicated). Also synthesizes a citable answer_claims: surface onto each type:question node from its findings' claims (Step 6.1). An optional cross-lingual pass merges DE↔EN twin claims on mixed-language bases (auto-skips otherwise). Fail-soft and optional: a distill failure never blocks compose. Use this skill whenever the user says 'distill the concepts', 'build the concept web', 'phase 4.5', 'knowledge distill', 'extract entities and concepts', 'answer the question nodes', or 'dedupe claims'. After distill, knowledge-compose reads the distilled pages as framing context."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Distill

Phase 4.5 of the inverted pipeline — it sits **between** `knowledge-ingest` (Phase 4) and `knowledge-compose` (Phase 5): `plan → curate → fetch → ingest → **distill** → compose → verify → finalize`.

Phase 4 deposits one `type: source` page per fetched URL (verbatim body + `pre_extracted_claims:`). That makes the wiki a **citation store**. This phase turns those source claims into the distilled **concept/entity web** that makes a Karpathy wiki *compound* across runs: `type: concept` / `type: entity` pages that successive runs **enrich** (new claims appended, source backlinks unioned) rather than duplicate, with **claim-level dedup** at deposit and **per-run re-narration of updated summaries** (Step 6.7) so the wiki compounds *narratively* — the entry-point prose integrates new evidence — as well as structurally. The differentiation thesis's compounding loop + claims-dedup metric become real here.

**Optional + fail-soft.** A distill failure must NEVER block `knowledge-compose`. Same posture as the `knowledge-curate` Step 0.5 coverage pre-step: warn loudly, exit cleanly, let the pipeline continue. The concept/entity pages are an enrichment layer, not a correctness gate.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 4.5 — `knowledge-distill`" once to anchor on the contract.

## When to run

- `<project>/.metadata/ingest-manifest.json` exists with non-empty `ingested[]` (Phase 4 has run).
- User explicitly invokes `/cogni-knowledge:knowledge-distill`, or the pipeline reaches Phase 4.5.

## Never run when

- No `<project>/.metadata/ingest-manifest.json` or `ingested[]` empty — offer `knowledge-ingest` first (but do NOT hard-fail the pipeline; distill is optional).
- No `binding.json` at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--no-renarrate` | No | Skip Step 6.7 (summary re-narration). Default is **on** — narrative compounding is the point of Phase 4.5; this opt-out exists for byte-stable re-runs / cost control. |
| `--no-crosslingual` | No | Skip Step 6.6 (cross-lingual DE↔EN claim merge). Default is **on** but **auto-skips** with zero LLM cost when no candidate pairs exist (every single-language base); this opt-out forces it off even on a mixed-language base. |
| `--dry-run` | No | Print the resolved inputs (bundle source count, existing distilled-page count, bundle hash, resume verdict) without dispatching the distiller. |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break), byte-for-byte the probe `knowledge-ingest` uses:

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-ingest && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK=no`, warn and exit cleanly (distill is optional — do not block the pipeline).

**Resolve the cogni-wiki script dir.** Use the SAME `resolve_wiki_scripts` helper `knowledge-ingest` / `knowledge-finalize` use (shared byte-for-byte) — it picks the newest numeric version dir. `concept-store.py merge` needs this dir for `_wiki_lock` / `is_foundation_page` / `parse_frontmatter`, and Step 6 needs `backlink_audit.py` / `wiki_index_update.py` / `config_bump.py`:

```
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || { echo "⚠ cogni-wiki wiki-ingest scripts not found — skipping distill (optional)"; exit 0; }
```

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-ingest`). Read the binding via `knowledge-binding.py read --knowledge-root <knowledge_root>`. On `success: false` → warn + exit cleanly. Parse `data.binding.wiki_path` as `WIKI_ROOT`; confirm `<WIKI_ROOT>/.cogni-wiki/config.json` and `<WIKI_ROOT>/wiki/` exist and are writeable.

**Project manifests.** Read `<project_path>/.metadata/ingest-manifest.json`. If absent or `ingested[]` is empty → warn ("nothing to distill — run knowledge-ingest first") and exit cleanly. Read `<project_path>/.metadata/plan.json` for `TOPIC`, `output_language` (default `en`), and derive the **project slug** (the project directory's basename, matching what `knowledge-finalize` uses for `derived_from_research:`).

### 1. Build the claim bundle (the distiller's only evidence)

For each entry in `ingested[]`, read its `wiki/sources/<slug>.md` page and pull its `pre_extracted_claims:` via the shared parser. Write a compact, bounded bundle file so the distiller reads ONE file instead of N source pages. Pass paths via env vars so spaces/apostrophes can't break the literal:

Run the **claim bundle** subprocess in [`references/distill-bundle-builders.md`](../../references/distill-bundle-builders.md) §1 — env inputs and the verbatim code are there; it prints the count the next paragraph captures.

Capture the printed source count. If it is `0` (no source carries claims) → warn ("no source claims to distill") and exit cleanly.

Compute a **content** hash of the bundle for the resume check (Step 3). It MUST hash the bundle's bytes, not a path — `fetch-cache.py key` hashes a URL string and would make the resume check path-keyed (a changed claim set on the same path would falsely look "unchanged"), so do not use it here:

```
SHA=$(python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "<project_path>/.metadata/distill-bundle.txt")
```

### 2. Build the existing concept/entity slug index

So the distiller can reuse an existing concept's title (landing the merge on the same page = compounding) and avoid proposing a near-duplicate:

Run the **existing concept/entity slug index** subprocess in [`references/distill-bundle-builders.md`](../../references/distill-bundle-builders.md) §2 — env inputs and the verbatim code are there; it prints the count the next paragraph captures.

### 3. Resume check (idempotent no-op)

If `<project_path>/.metadata/distill-manifest.json` exists AND it records the same `bundle_hash` as `SHA` from Step 1 → the distiller already ran on this exact claim set. **Skip re-dispatch** (the LLM is the expensive part) and jump to the final summary, reporting "no-op (bundle unchanged)". `concept-store.py merge` is itself byte-stable on re-run, so skipping is purely a cost optimization, not a correctness requirement.

(The orchestrator stores `SHA` by reading it back from the manifest's `bundle_hash` field — Step 6 threads it in. On the first run the manifest has no `bundle_hash`, so the check fails and the distiller runs.)

If `--dry-run`: print the source count, existing distilled-page count, `SHA`, and the resume verdict, then stop.

### 4. Initialize distill-manifest.json

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py init --project-path <project_path>
```

### 4.5. Build the answer-bundle (prerequisite for the parallel dispatch)

The `answer-distiller` (dispatched in the Step 5 fan-out wave) gives each `type: question` node
(deposited by `knowledge-ingest` Step 4.5) a **citable answer surface** — an `answer_claims:`
frontmatter block distilled from the node's findings' `pre_extracted_claims:`, exactly as
concept/entity pages got `distilled_claims:`. A question node becomes a first-class cross-source
*answer unit* the composer can later cite and the verifier can score. Its bundle reads **only**
`wiki/questions/*.md` + `wiki/sources/*.md` — disjoint from the concept-distiller's claim bundle
and dependent on no distiller output — so it is built **here**, before the fan-out, and the
answer-distiller rides the same wave as the concept-distiller. This step needs **no**
index/backlink/`entries_count` work — question nodes already exist and are indexed at ingest time;
it only prepares their answer-claim enrichment.

**Skip cleanly when** `<WIKI_ROOT>/wiki/questions/` does not exist or is empty (a base that
predates the question-node feature, or a run with no question nodes) — set `ANSWER_Q_COUNT=0` (the
Step 5 wave then dispatches only the concept-distiller) and continue.

**Build the per-question claim bundle.** For each `wiki/questions/<slug>.md`, read its
`sources_answering:` list and pull each listed source page's `pre_extracted_claims:`, emitting one
`## question: <slug> | <title>` block followed by the same 3-part `<source_slug> | <claim_id> |
<text>` claim lines the Step-1 concept bundle uses. Reuse the shared parsers — `split_frontmatter`
(the same `_wikilib` import `question-store.py emit` uses, for the inline `sources_answering:`
list) + `parse_pre_extracted_claims`:

Run the **answer bundle** subprocess in [`references/distill-bundle-builders.md`](../../references/distill-bundle-builders.md) §5 — env inputs and the verbatim code are there; it prints the count the next paragraph captures.

Capture the printed count as `ANSWER_Q_COUNT`. If it is `0` (no question node carries answerable
claims) → keep `ANSWER_Q_COUNT=0`; the Step 5 wave dispatches only the concept-distiller and Step
6.1 reports `n/a (no answerable question nodes)`.

### 5. Fan-out wave — dispatch concept-distiller + answer-distiller in parallel

The concept-distiller and the answer-distiller read **disjoint** inputs (the source-claim bundle
vs the answer-bundle, both built from already-ingested pages) and write **disjoint** targets
(`distill-records.txt` → `wiki/{concepts,entities,people}/` vs `answer-records.txt` →
`wiki/questions/` `answer_claims:`); neither consumes the other's output, and neither LLM `Task`
acquires the wiki lock (only the downstream merge scripts do). So dispatch both in **one fan-out
wave** — a single assistant message with two `Task` calls — instead of back-to-back, mirroring the
curate/ingest fan-out posture. Gate the answer-distiller leg on `ANSWER_Q_COUNT > 0` from Step 4.5
(when it is `0`, the wave carries only the concept-distiller):

```
Task(concept-distiller,
     CLAIM_BUNDLE_PATH=<project_path>/.metadata/distill-bundle.txt,
     SLUG_INDEX_PATH=<project_path>/.metadata/distill-slug-index.txt,
     RECORDS_OUTPUT_PATH=<project_path>/.metadata/distill-records.txt,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>)
Task(answer-distiller,                                   # only when ANSWER_Q_COUNT > 0
     ANSWER_BUNDLE_PATH=<project_path>/.metadata/answer-bundle.txt,
     RECORDS_OUTPUT_PATH=<project_path>/.metadata/answer-records.txt,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>)
```

Both agents live under `${CLAUDE_PLUGIN_ROOT}/agents/` (`concept-distiller.md` /
`answer-distiller.md`) — dispatched via `Task`, not `Skill`. Each is a single pass that reads its
bundle and writes its raw-text records file. **After both return**, parse each envelope
independently:

- **concept-distiller** — `ok: true` → its records feed Step 6; `ok: true, concepts_proposed: 0` →
  nothing to distill (skip Step 6's merge); `ok: false` → warn (surface the error) and treat the
  concept path as empty (distill is optional).
- **answer-distiller** (dispatched only when `ANSWER_Q_COUNT > 0`) — parse like the concept leg so
  a legitimate no-op is not surfaced as an error: `ok: true` → its records feed Step 6.1; `ok:
  true, questions_proposed: 0` → benign **n/a skip** (no question had an answerable claim), Step
  6.1 reports `n/a`; `ok: false` → **warn (surface the error)** and skip Step 6.1's answer-merge.
  Answer synthesis never blocks the pipeline.

If the concept leg proposed nothing **and** the answer leg was skipped/empty/`ok: false`, jump
straight to the final summary. Otherwise continue to Step 6 (concept merge) then Step 6.1
(answer-merge).

### 6. Merge proposals into concept/entity pages (locked, claim-dedup)

`concept-store.py merge` parses the records, derives each slug via `slugify(title)`, and under cogni-wiki's `_wiki_lock` creates-or-merges each page with claim-level dedup. It owns all serialization + the created-vs-updated decision + a pre-write round-trip self-check:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py merge \
    --records <project_path>/.metadata/distill-records.txt \
    --wiki-root <WIKI_ROOT> \
    --project-path <project_path> \
    --project-slug <project-slug> \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    --bundle-hash "$SHA"
```

`--bundle-hash "$SHA"` (the Step-1 content hash) is written into the manifest by `concept-store.py` itself — it is the single writer, so Step 3's resume check reads it back with no fragile second-process patch. Parse `data`: `created_slugs[]`, `updated_slugs[]` (disjoint), `concepts[]` (each `{slug, type, action, summary, claims_new, claims_deduped, claims_rejected, near_existing_slug, ...}`), `claims_attached_total`, `claims_deduped_total`, `claims_rejected_total`, `near_existing_total`, `near_existing_slugs[]` (`{slug, near_slug, near_title, near_type, score}`). On `success: false` → warn + exit cleanly. **If `claims_rejected_total > 0`, surface it loudly** — it means the distiller emitted malformed claim lines (e.g. dropped the `<slug> | <id> |` provenance), which would otherwise silently shrink the concept web; check the records file format. **`near_existing_total` / `near_existing_slugs[]` are the title→slug observable tripwire** — see Step 9.

### 6.1. Merge answer claims into each question node (locked, claim-dedup, serialized after Step 6)

The two distiller merges share cogni-wiki's `_wiki_lock`, so they run **serialized** —
`concept-store.py merge` (Step 6) first, then this `question-store.py answer-merge` immediately
after, before the cross-lingual (6.6) and re-narrate (6.7) passes. The two agents already ran
concurrently in the Step 5 wave; only their merges serialize here. **Skip cleanly when**
`ANSWER_Q_COUNT == 0` from Step 4.5, the answer-distiller was not dispatched, or its Step-5 envelope
was `questions_proposed: 0` / `ok: false` — report `n/a (no answerable question nodes)` and jump to
Step 6.6.

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/question-store.py answer-merge \
    --records <project_path>/.metadata/answer-records.txt \
    --wiki-root <WIKI_ROOT> \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

`answer-merge` parses the records and, under cogni-wiki's `_wiki_lock` (a question node is
a shared-state read-modify-write of an existing page), splices a deduped `answer_claims:`
block into each node's frontmatter — claim-level dedup keyed on `<source_slug>#<claim_id>`
(exact `norm_key` → `claim_similarity ≥ 0.85`, **fail-safe keep-both**; union
`backlinks[]` + `source_claim_refs[]`, never drop a provenance ref), minting `acl-NNN`
ids, with a pre-write round-trip self-check. It **preserves every other frontmatter key,
the `## Findings` block, and the human `## Notes` tail byte-for-byte**, and operates only
on `type: question` pages (refusing `foundation: true`). Parse `data`: `questions[]` (each
`{slug, action ∈ created_block|updated|unchanged|skipped|write_failed, reason,
claims_new, claims_deduped, claims_rejected}`), `claims_attached_total`,
`claims_deduped_total`, `claims_rejected_total`. On `success: false` → warn + continue to
Step 6.6. **If `claims_rejected_total > 0`, surface it loudly** (the distiller emitted
malformed claim lines — check the records format). Capture the counts for Step 9.

**Note on the emit interaction (no code change to `emit`).** A *later* run's ingest Step
4.5 (`question-store.py emit`) re-renders a question node's frontmatter from its fixed
template, which does **not** carry `answer_claims:` — so it drops the block until *that*
run's distill re-adds it. Within a run the order is always ingest → distill, so the
surface is restored each run; if distill is skipped (it is optional), the node reverts to
framing-only — exactly this phase's fail-soft contract, identical downstream to today.

**Fail-soft at every hop.** A distiller `ok:false`, a missing/empty records file, or a
non-zero `answer-merge` exit must each **warn and continue** to Step 6.6 with the question
nodes intact (framing-only). This pass is enrichment, never a gate.

### 6.6. Cross-lingual claim merge (DE↔EN, default-on, fail-soft, auto-skip)

Phase-1 dedup (Step 6) deliberately **under-merges across languages**: the only deterministic DE↔EN bridge is the article-number digit anchor (×3.0), so a German claim and its English twin survive as two `distilled_claims[]` entries. That is the **safe** direction (a wrong cross-language merge silently destroys a distinct fact and is unrecoverable) but on a **mixed-language base** (EN+DE sources) it is lossy — a concept page lists each fact twice and the dedup ratio under-reports the real overlap. This step has an LLM confirm which **script-flagged** candidate pairs are the *same fact stated in two languages*, then unions them. **It NEVER fires on a single-language base** — the candidate generator emits nothing there (same-language twins already collapsed in Step 6), so this step self-skips with zero LLM cost (the auto-skip).

**Skip cleanly when:** `--no-crosslingual` was passed, OR `created_slugs[] + updated_slugs[]` (from Step 6) is empty. Jump to Step 6.7.

**a. Generate candidates (deterministic, read-only).** `xlingual-candidates` pairs each touched page's `distilled_claims[]` and flags those that share an article-number digit anchor but did NOT auto-merge (low overlap) — the signature of a DE↔EN twin. Save the envelope, then transform it into the agent's bundle:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py xlingual-candidates \
    --wiki-root <WIKI_ROOT> \
    --slugs "<comma-separated created_slugs + updated_slugs>" \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    > <project_path>/.metadata/xlingual-candidates.json
```

On `success: false` → warn + continue to Step 6.7 (this step never blocks). Otherwise build the per-pair bundle (env-var paths so quotes can't break the literal):

Run the **cross-lingual candidate bundle** subprocess in [`references/distill-bundle-builders.md`](../../references/distill-bundle-builders.md) §3 — env inputs and the verbatim code are there; it prints the count the next paragraph captures.

**If the printed candidate count is `0` → skip cleanly to Step 6.7** (the auto-skip; report `n/a (no cross-lingual candidates)`).

**b. Dispatch the merger (single Task call).**

```
Task(cross-lingual-claim-merger,
     CANDIDATES_PATH=<project_path>/.metadata/xlingual-candidates.txt,
     RECORDS_OUTPUT_PATH=<project_path>/.metadata/xlingual-records.txt,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>)
```

`cross-lingual-claim-merger` lives at `${CLAUDE_PLUGIN_ROOT}/agents/cross-lingual-claim-merger.md` — dispatched via `Task`, not `Skill`. It judges each candidate "same fact, two languages?" and writes a raw-text `merge: <slug> | <survivor> | <absorbed>` line per confirmed twin. Parse the return: `ok: true` → continue to 6.6c; `ok: false` or `pairs_confirmed: 0` → warn/continue to Step 6.7 (no unions to apply).

**c. Apply the unions (locked, fail-safe).**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py crossmerge \
    --records <project_path>/.metadata/xlingual-records.txt \
    --wiki-root <WIKI_ROOT> \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

`crossmerge` parses the records and, under the SAME `_wiki_lock` as `merge`, **re-validates the candidate gate server-side for every record** (both ids must still be on the page AND the pair must still satisfy the deterministic candidate predicate — so the LLM can never widen scope) and UNIONs the absorbed claim's `backlinks` + `source_claim_refs` onto its survivor — **never dropping a provenance ref**, only removing the duplicate dcl-id. Parse `data`: `merged[]` (`{slug, survivor_id, absorbed_id}`), `merged_slugs[]`, `skipped[]` (`{slug, reason}`; reasons `page_not_found`/`no_sentinels_human_page`/`claim_not_found`/`not_a_candidate`/`claims_round_trip_mismatch`), `n_merged`, `n_skipped`, `claims_crossmerged_total`. On `success: false` → warn + continue to Step 6.7.

**Fold `merged_slugs[]` into `updated_slugs[]`** so Step 6.7 re-narrates the now-shorter claim list and Step 7's wiki integration covers the page. Capture `n_merged` / `n_skipped` for Step 9.

**Fail-soft at every hop.** A failed candidate scan, a merger `ok:false`, a missing/empty records file, or a non-zero `crossmerge` exit must each **warn and continue** to Step 6.7 with claims intact. This pass is enrichment, never a gate. (Re-running on the same claim set is byte-stable: an already-absorbed `dcl` id is gone, so the record re-validates to `claim_not_found` and the page is untouched.)

### 6.7. Re-narrate updated summaries (default-on, fail-soft)

Phase 4.5 compounds the `## Claims` / `## Related` / `## Sources` blocks across runs, but `concept-store.py merge` keeps the `## Summary` block **first-writer-wins** on update — so an `updated` page can list 20 distilled claims under prose that still reflects only run 1's framing. This step re-narrates the summary of each **updated** page from its *merged* claims so the wiki compounds **narratively**, not just structurally. **Summary-only**: every other machine block + the human `## Notes` tail stay byte-identical.

**Skip cleanly when:** `--no-renarrate` was passed, OR `updated_slugs[]` (from Step 6, **possibly grown by Step 6.6's `merged_slugs[]` fold** so crossmerged pages get re-narrated too) is empty (`created` pages already carry a fresh distiller summary; pure re-runs have no updated pages). In either case jump straight to Step 7 — re-narration is purely additive enrichment.

Otherwise:

**a. Build the per-slug bundle.** For each slug in `updated_slugs[]`, read its on-disk page, pull the existing `## Summary` inner (stripping the `## Summary` heading line) + the merged `distilled_claims[].text`, and append a block to `renarrate-bundle.txt`. Reuse the shared parsers — no new block parsing:

Run the **re-narrate bundle** subprocess in [`references/distill-bundle-builders.md`](../../references/distill-bundle-builders.md) §4 — env inputs and the verbatim code are there; it prints the count the next paragraph captures.

If the printed slug count is `0` → skip to Step 7 (nothing to re-narrate).

**b. Dispatch the narrator (single Task call).**

```
Task(concept-summary-narrator,
     RENARRATE_BUNDLE_PATH=<project_path>/.metadata/renarrate-bundle.txt,
     RECORDS_OUTPUT_PATH=<project_path>/.metadata/renarrate-records.txt,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>)
```

`concept-summary-narrator` lives at `${CLAUDE_PLUGIN_ROOT}/agents/concept-summary-narrator.md` — dispatched via `Task`, not `Skill`. Parse the return envelope: `ok: true` → continue to Step 6.7c; `ok: false` → **warn (surface the error) and jump to Step 7 with summaries unchanged** (re-narration never blocks the pipeline).

**c. Apply the re-narration (locked, summary-only).**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py renarrate \
    --records <project_path>/.metadata/renarrate-records.txt \
    --wiki-root <WIKI_ROOT> \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

`renarrate` parses the records, and under the SAME `_wiki_lock` as `merge` replaces **only** the SUMMARY machine block of each named page (every other block + `## Notes` byte-identical), bumping `updated:` only when the prose actually changed. Parse `data`: `renarrated[]`, `unchanged[]`, `skipped[]` (each `{slug, reason}`; reasons `page_not_found` / `no_summary_sentinel`). On `success: false` (e.g. `records_not_found`, or a `--wiki-scripts-dir` import failure) → warn + continue to Step 7. Capture `n_renarrated` / `n_unchanged` / `n_skipped` for the Step 9 summary. (Unlike Step 6's `merge`, `renarrate` needs neither `--project-path` nor `--project-slug` — it accepts them for call-site symmetry but ignores them, so the omission here is deliberate.)

**Fail-soft at every hop.** A narrator `ok:false`, a missing/empty records file, or a non-zero `renarrate` exit must each **warn and continue** to Step 7 with the existing summaries intact. Re-narration is enrichment, never a gate. (Note: because this runs only for `updated_slugs[]` and `merge` already bumped those pages' `updated:` to today in Step 6, a re-narration date bump lands on the same date — no extra churn.) The two parsed envelopes use different success keys by design: the **agent** returns `ok` (agent convention, like `concept-distiller`), while the **`concept-store.py renarrate` script** returns `success` (the insight-wave script-output convention) — so the dual-key handling above is intentional, not a bug.

### 7. Per-new/updated-slug cogni-wiki integration (sequential, after merge)

For each slug in `created_slugs[] + updated_slugs[]`, in deterministic order (skip `skipped`/`write_failed`/`unchanged` slugs — they need no index/backlink work):

1. **Backlink audit + apply (forms concept↔source / concept↔concept edges).** Identical mechanism to `knowledge-ingest` Step 4.1 — audit, curate a `targets[]` plan from genuine relations only, apply:
   ```
   python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" --wiki-root <WIKI_ROOT> --new-page <slug> --top 8 --min-confidence medium
   ```
   Curate `{"targets": [{"slug": "<target>", "sentence": "... [[<slug>]] ..."}]}` from genuine relations (skip weak matches; each `sentence` MUST contain `[[<slug>]]`), then:
   ```
   printf '%s' "$PLAN_JSON" | python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" --wiki-root <WIKI_ROOT> --new-page <slug> --apply-plan -
   ```
   `apply_plan` is idempotent + fail-soft per target. If no genuine relation, skip apply for that slug (never invent a backlink). The concept page already carries bare `[[<source-slug>]]` links in its `## Sources` block (written by `concept-store.py`), so its concept→source edges exist; this step adds the inbound source→concept / concept→concept edges.

2. **Index update (thematic category).** File the page under the category matching its `type` (from the merge result): `--category "Concepts"` for `type: concept`, `--category "Entities"` for `type: entity`, `--category "People"` for `type: person`. Use the merge result's `summary` (always non-empty — `concept-store.py` falls back to the title), but first **sanitize it** so a stray typographic substitute (U+2020 DAGGER, U+2021, or an exotic space U+00A0/U+202F/U+2009) never reaches the reader-facing `wiki/index.md` one-liner — same guard `knowledge-ingest` Step 4.2 applies, pass the raw value via an env var:
   ```
   CLEAN_SUMMARY=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
   RAW_SUMMARY="<the page's summary from the merge result>" \
   python3 -c '
   import os, sys
   sys.stdout.reconfigure(encoding="utf-8")
   sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
   from _knowledge_lib import sanitize_summary
   print(sanitize_summary(os.environ["RAW_SUMMARY"]))
   ')
   ```
   Then pass `$CLEAN_SUMMARY` to `--summary`. Every flag is on a continued line (trailing `\`); do not put a shell comment on an argument line, or `--max-summary` is dropped and the mid-word clamp is lost:
   ```
   python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" --wiki-root <WIKI_ROOT> --slug <slug> \
       --summary "$CLEAN_SUMMARY" \
       --category "<Concepts|Entities|People per the merge result's type>" \
       --max-summary 240
   ```
   Capture the envelope. When `success == true` **and** `data.action == "inserted"`, increment `n_new` (init `0` before the loop). `data.action == "updated"` (a row already existed) does NOT count — same lockstep as `knowledge-ingest` Step 4. In the same `inserted` branch, also increment the **per-type** insert counter for this page's type — `n_new_entities` / `n_new_people` (each init `0` before the loop), keyed off the merge result's `type` (`entity` / `person`). Step 7.1 below gates each sub-index render on its own per-type counter. (There is no `n_new_concepts` render counter here: `wiki/concepts/index.md` is rendered by its dedicated `concepts_index.py` at `knowledge-finalize` Step 10.5 sub-step 3.6, not by `sub_index.py`. The total `n_new` still counts every type — concepts included — so the `entries_count` bump below is unchanged.)

3. On any helper failure, record in `failed_index_updates[]` and continue — the page is on disk; only discoverability is incomplete.

After the loop, bump `entries_count` once by the count of newly-indexed pages (only when `n_new > 0`), exactly as `knowledge-ingest` Step 4 / `knowledge-finalize` Step 8:

```
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" --wiki-root "$WIKI_ROOT" --key entries_count --delta <n_new>
```

Non-fatal on failure (reconcile via `wiki-lint --fix=entries_count_drift`). **Do NOT** run the *full* `lint_wiki.py --fix=all` / `health.py` conformance gate here — that stays in `knowledge-finalize` Step 10.5, which runs it once, at the end, over the page set that now includes these distilled pages. The **bounded** `--fix=reverse_link_missing` de-orphan gate in Step 7.2 below is the deliberate exception.

### 7.1. Render the distilled sub-indexes (`wiki/{entities,people}/index.md`)

After the per-slug index/backlink loop and the `entries_count` bump, re-render the machine-owned per-type sub-indexes for the two `sub_index.py`-owned distilled types (entities, people) so each reflects the pages filed this run. This is the distill-phase sibling of the `knowledge-ingest` Step 4 sources render and Step 4.5.6 questions render — the same generic deterministic renderer `knowledge-setup` seeds at bootstrap. **Concepts are deliberately excluded:** `wiki/concepts/index.md` is owned by the dedicated `concepts_index.py` renderer (with `CONCEPTS-LEADIN` narration) at `knowledge-finalize` Step 10.5 sub-step 3.6, not by `sub_index.py`.

Run **one render per type, each gated on its own per-type counter** (`n_new_entities` / `n_new_people` from Step 7 sub-step 2) — a clean re-run that merged every page in place added no new index row for that type, so its sub-index is already current and the render is skipped (idempotent: an unchanged wiki is a no-op). Each render must run **after** the per-slug `wiki_index_update.py --category` calls above (which file every new distilled page under its `## <theme>` heading in `wiki/index.md`) — otherwise a just-written page lands in the renderer's trailing `## Uncategorized` group. The generic renderer groups each page under its own portal theme (`theme_via_own_slug`, same as the sources render) and carries any narrator-authored `MACHINE-OWNED:ENTITIES-LEADIN:<theme>` / `PEOPLE-LEADIN:<theme>` lead-in forward verbatim (no clobber), so rendering here never overwrites a lead-in a later run narrates:

```
# Derive the base's output language so the engine-owned per-theme lead-in
# fallback reads in-language on a non-English base (default en; the narrator
# overwrites it on a later run regardless):
OUTPUT_LANGUAGE=$(python3 -c '
import json, sys
try:
    print((json.load(open(sys.argv[1])).get("output_language")) or "en")
except Exception:
    print("en")
' "<project_path>/.metadata/plan.json")
# One block per type; run only when that type's per-type counter > 0.
# entities:
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
    --type entities \
    --wiki-root "$WIKI_ROOT" \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    --lang "$OUTPUT_LANGUAGE"
# people:
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
    --type people \
    --wiki-root "$WIKI_ROOT" \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    --lang "$OUTPUT_LANGUAGE"
```

**Fail-soft** — a renderer failure never rolls back distill: every distilled page, backlink, index row, and `entries_count` bump is already on disk. The render is lock-wrapped (`_wiki_lock`) + atomic (`atomic_write_text`) at its own write site and writes only when the proposed text differs byte-for-byte, so a forced failure leaves no partial page. `sub_index.py` is itself fail-soft (a missing wiki-scripts dir, a `_wikilib` import failure, or a non-wiki `--wiki-root` returns an error envelope rather than raising), so the orchestrator treats a non-zero result as a surfaced warning, never an abort. Surface each per-type outcome in the Step 9 summary and continue.

### 7.2. Bounded de-orphan gate (reverse_link_missing)

The distilled pages just written carry forward `[[<source-slug>]]` edges (concept→source) in their `## Sources` block, but the source pages do not yet hold the reverse `[[<concept-slug>]]` link — so a **standalone** distill (run later on an already-finalized base, with no `knowledge-compose` → `knowledge-finalize` to follow) would leave every page this phase wrote as an `orphan_page` with a `reverse_link_missing` gap until some future finalize that may never come. `knowledge-ingest` does not have this problem because it de-orphans its own pages inline (Steps 4.1 / 4.5.2); distill mirrors that posture here with a **bounded, idempotent** gate — not the whole-run conformance gate, only the one load-bearing reverse-link backfill.

Resolve the cogni-wiki `wiki-lint` scripts dir with the SAME `resolve_wiki_scripts` helper used at the top of this skill — **fail-soft**: on a miss, warn and continue (the base self-heals on the next `knowledge-finalize` / `knowledge-lint`), exactly as the `wiki-ingest` resolution does:

```
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_LINT_SCRIPTS=$(resolve_wiki_scripts wiki-lint lint_wiki.py) || { echo "⚠ cogni-wiki wiki-lint scripts not found — skipping the bounded de-orphan gate (run knowledge-finalize or knowledge-lint to reconcile)"; WIKI_LINT_SCRIPTS=""; }
```

When resolved, run the single bounded fix class. It mirrors every distilled page's `## Sources` `[[<source-slug>]]` edge back onto the source (and onto any cited `wiki/questions/<slug>.md` node), giving each page this phase wrote an inbound link. It is idempotent — a no-op on an already-clean base — and writes nothing else (`--fix=all`'s other four classes stay in finalize):

```
[ -n "$WIKI_LINT_SCRIPTS" ] && python3 "$WIKI_LINT_SCRIPTS/lint_wiki.py" \
    --wiki-root "$WIKI_ROOT" \
    --fix=reverse_link_missing
```

Capture the envelope; surface `data.fixed[]` / `data.failed[]` counts in the Step 9 summary. **Non-fatal per item** — a per-page fix failure lands in `data.failed[]` and never blocks the phase. (`orphan_page` is a lint warning, not a `--fix` class; 0 orphans comes from the inbound links this reverse-link backfill writes, never from `--fix` directly.)

### 8. Append wiki/log.md

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_CONCEPTS=<len(created_slugs) + len(updated_slugs)>
N_ATTACHED=<claims_attached_total>
N_DEDUPED=<claims_deduped_total>
LOG_PATH=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/control-path.py" log --wiki-root "${WIKI_ROOT}")
echo "## [${DATE_STAMP}] distill | project=${TOPIC} concepts=${N_CONCEPTS} claims=${N_ATTACHED} deduped=${N_DEDUPED}" >> "${LOG_PATH}"
```

The `distill` prefix is additive-safe — cogni-wiki readers bucket an unknown prefix in their catch-all without crashing (same posture `compose`/`verify`/`finalize` had before cogni-wiki formalized them).

### 9. Final summary

Print ≤ 12 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Distilled pages created: `<n>` / updated: `<n>` / unchanged: `<n>` / skipped: `<n>` (reasons: `foundation_collision`/`no_sentinels_human_page`/`slug_type_collision`/`empty_slug`)
  - By type (created): concepts `<c>` / entities `<e>` / people `<p>` — count each from the merge result's per-slug `type` (omit a type's tally when it is `0`)
- Claims attached: `<claims_attached_total>` (deduped: `<claims_deduped_total>` → dedup ratio `<deduped/attached>`); if `claims_rejected_total > 0`, add `⚠ <claims_rejected_total> claim lines rejected as malformed — check the distiller's records format`
- Cross-lingual merges: `<n_merged>` (`<n_skipped>` skipped) — or `skipped (--no-crosslingual)` / `n/a (no cross-lingual candidates)` when Step 6.6 did not fire (the single-language norm — no DE↔EN twins to merge)
- Summaries re-narrated: `<n_renarrated>` (`<n_unchanged>` unchanged, `<n_skipped>` skipped) — or `skipped (--no-renarrate)` / `n/a (no updated pages)` when Step 6.7 did not run
- Question nodes answered: `<n with answer_claims created/updated>` (claims attached `<answer_claims_attached_total>`, deduped `<answer_claims_deduped_total>` — these are the **answer-merge** envelope's `claims_attached_total`/`claims_deduped_total`/`claims_rejected_total`, distinct from the Step-6 concept-store counts above) — or `n/a (no answerable question nodes)` when Step 6.1 did not fire; if the answer-merge `claims_rejected_total > 0`, add `⚠ <n> answer-claim lines rejected as malformed — check the answer-distiller's records format`
- **title→slug tripwire** — if `near_existing_total > 0`, surface a warning block:
  - Header: `⚠ <near_existing_total> concepts created near an existing slug — check title stability`
  - One line per entry from `near_existing_slugs[]` (deterministic order, score-sorted desc): `  <slug> ~ <near_slug> (<near_type>, score=<score>)`
  - Subline: `If these are the same concept, the run forked a near-duplicate page; rename the proposal in the next run, or merge manually via the wiki.`
  - When `near_existing_total == 0` print nothing (no false-alarm noise on clean runs).
- Wiki entries_count: `+<n_new>` (or `⚠ bump failed — run wiki-lint --fix=entries_count_drift`; or `unchanged` when `n_new == 0`)
- Sub-indexes rendered (Step 7.1): `entities` / `people` — per type, `re-rendered` (counter `> 0`), `skipped (no new rows)` (counter `== 0`), or `⚠ render failed — <reason>` (fail-soft); concepts are rendered separately by `knowledge-finalize` sub-step 3.6
- Reverse-link backfill (Step 7.2): `<n_fixed>` link(s) added (`<n_failed>` failed) — or `0 (already clean)` / `skipped (wiki-lint scripts not found)` when the bounded de-orphan gate found nothing to do or could not resolve its scripts dir
- Cost: `$X.XXX` (from the distiller return)
- Next: `knowledge-compose` reads the distilled pages (concept/entity today; person joins the compose read surface when its compose/verify wiring lands) as framing context (not citable evidence).

The dedup ratio is the compounding success metric (`differentiation-thesis.md`): of the new facts proposed this run, the fraction that merged into an existing claim instead of adding a duplicate line.

The title→slug tripwire is **pure observability** — it never blocks the pipeline, never auto-merges, never skips a write. A `near_existing_slug` warning means `claim_similarity(new_title, existing_title) >= 0.65` on the symmetric weighted-Jaccard primitive; titles in that band MAY be a silent slug-fork (e.g. `"Hochrisiko-Klassifizierung"` vs `"Einstufung als hochriskant"` — different slugs, same concept) but may also be genuinely-distinct neighbours. Human judgment owns the disposition.

## Edge cases

- **Fresh base (run 1).** Every concept/entity is `created`; `claims_deduped_total` may be 0 (nothing prior to dedup against — same-run near-dupes still merge). Compounding shows from run 2 onward.
- **Re-run on the same claim set.** Step 3 skips re-dispatch when `bundle_hash` is unchanged; even without the skip, `concept-store.py merge` is byte-stable (re-merge → all `unchanged`, `n_new == 0`, no bump); `updated_slugs[]` is then empty, so Step 6.7 re-narration also no-ops.
- **A concept slug collides with a `foundation: true` page.** `concept-store.py` refuses to merge (`skipped`, `reason: foundation_collision`) — never overwrites a curated foundation.
- **A concept slug collides with a hand-authored page (no MACHINE-OWNED sentinels).** `concept-store.py` skips it (`reason: no_sentinels_human_page`) and leaves the page untouched — we never clobber a page we did not author.
- **Distiller proposed a concept but every claim was a re-run duplicate.** The page is `unchanged`; no index churn, no `entries_count` bump.
- **Empty / claim-less sources.** Sources with no `pre_extracted_claims:` are omitted from the bundle; if the whole bundle is empty, the phase no-ops cleanly.
- **No question nodes / base predates the question-node feature.** Step 4.5 finds no `wiki/questions/` dir (or no node with answerable claims), so `ANSWER_Q_COUNT=0` — the Step 5 wave drops the answer-distiller leg and Step 6.1 self-skips cleanly (`n/a (no answerable question nodes)`) — no `answer_claims:` work, no error.
- **Distill skipped entirely.** Question nodes keep only their `## Findings` + `## Notes` (framing-only) — byte-identical to behavior before the answer surface existed; the composer reads them framing-only either way (the citable path is a later activation step).
- **Re-ingest before re-distill.** A later run's ingest `emit` re-renders the question frontmatter without `answer_claims:` (it has no such template field); the same run's distill (Step 6.1) re-adds it. Transiently framing-only between ingest and distill, restored by distill — never a lost-data state for a completed run.
- **Single-language base (the norm).** Step 6.6's `xlingual-candidates` finds no pairs (same-language twins already collapsed in Step 6), so the cross-lingual pass self-skips with zero LLM cost — `n/a (no cross-lingual candidates)`. The feature only does work on a mixed DE↔EN base.

## Out of scope

- Does NOT compose the draft — that is Phase 5 (`knowledge-compose`).
- Re-narrates the `## Summary` body of **updated** distilled pages (any of the three types — concept / entity / person) from the merged claims (Step 6.7, default-on, fail-soft; `--no-renarrate` opts out). `created` pages keep the distiller's fresh summary; pure re-runs touch nothing. It does NOT re-synthesize any other block, and it does NOT add a contradiction pass.
- Merges **cross-lingual (DE↔EN) twin claims** on a mixed-language base (Step 6.6, default-on, fail-soft, auto-skip; `--no-crosslingual` opts out). An LLM only **confirms** pairs the script flagged (shared article-number anchor + low overlap); `concept-store.py crossmerge` re-validates the gate and UNIONs provenance onto the survivor — **never dropping a fact**. It does NOT touch single-language dedup (Step 6's job), and it explicitly does NOT use embedding/vector similarity (approach (c), rejected by the differentiation thesis).
- Emits three page types — `concept` / `entity` / `person` (named humans, split out of entity). It does NOT emit any other cogni-wiki page type (sources are Phase 4, syntheses are Phase 7).
- Does NOT run the **full** `lint_wiki.py --fix=all` / `health.py` whole-run conformance gate — `knowledge-finalize` Step 10.5 covers the whole run once. It DOES run a **bounded** `--fix=reverse_link_missing` de-orphan gate inline (Step 7.2) so a standalone distill leaves the base structurally clean (0 orphans, 0 reverse-link gaps), mirroring `knowledge-ingest`'s inline posture.
- Does NOT modify `binding.json` — Phase 7 (`knowledge-finalize`) appends the project entry.
- Does NOT block the pipeline — every failure path warns and exits cleanly.

## Output

- `<WIKI_ROOT>/wiki/{concepts,entities,people}/<slug>.md` — created or enriched per the proposal's `type:`, with `distilled_claims:` frontmatter, MACHINE-OWNED body sentinels, and bare `[[<source-slug>]]` backlinks. A human `## Notes` region is preserved byte-for-byte across runs.
- `<WIKI_ROOT>/wiki/index.md` — each page filed under `## Concepts` / `## Entities` / `## People`.
- `<WIKI_ROOT>/wiki/entities/index.md` — re-rendered (Step 7.1, when `n_new_entities > 0`) — the machine-owned entities sub-index, grouped by portal theme via `sub_index.py render --type entities`; narrator-authored `ENTITIES-LEADIN` spans are carried forward verbatim.
- `<WIKI_ROOT>/wiki/people/index.md` — re-rendered (Step 7.1, when `n_new_people > 0`) — the machine-owned people sub-index, grouped by portal theme via `sub_index.py render --type people`; narrator-authored `PEOPLE-LEADIN` spans are carried forward verbatim.
- Existing pages gain curated `[[<slug>]]` inbound backlinks (via `backlink_audit.py --apply-plan`).
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by `<n_new>`.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] distill | …` line.
- `<project_path>/.metadata/distill-manifest.json` (schema 0.1.1) + intermediate `distill-bundle.txt` / `distill-slug-index.txt` / `distill-records.txt`; plus (when Step 6.6 fires) `xlingual-candidates.json` / `xlingual-candidates.txt` / `xlingual-records.txt`; plus (when Step 6.7 runs) `renarrate-bundle.txt` / `renarrate-records.txt`; plus (when the answer path runs — Step 4.5 build + Step 6.1 merge) `answer-bundle.txt` / `answer-records.txt`.
- Updated distilled pages (any of the three types — concept / entity / person) get their `## Summary` body re-narrated from the merged claims (Step 6.7); all other machine blocks + the `## Notes` tail stay byte-identical.
- `<WIKI_ROOT>/wiki/questions/<slug>.md` — each `type: question` node gains/enriches an `answer_claims:` frontmatter block (Step 6.1, `acl-NNN` ids, claim-deduped, with `backlinks[]`/`source_claim_refs[]` provenance); the `## Findings` block and the human `## Notes` tail stay byte-identical.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 4.5 contract
- `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` — the compounding loop + claims-dedup metric this phase realizes
- `${CLAUDE_PLUGIN_ROOT}/agents/concept-distiller.md` — dispatched agent (Phase 1 proposals)
- `${CLAUDE_PLUGIN_ROOT}/agents/concept-summary-narrator.md` — dispatched agent (Step 6.7 summary re-narration)
- `${CLAUDE_PLUGIN_ROOT}/agents/cross-lingual-claim-merger.md` — dispatched agent (Step 6.6 cross-lingual DE↔EN claim merge)
- `${CLAUDE_PLUGIN_ROOT}/agents/answer-distiller.md` — dispatched agent (Step 5 fan-out wave answer-claim synthesis for question nodes)
- `${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py --help` — locked create-or-merge + claim-dedup engine (incl. `xlingual-candidates` / `crossmerge`)
- `${CLAUDE_PLUGIN_ROOT}/scripts/question-store.py --help` — `answer-merge` (Step 6.1 locked answer_claims: splice) + `emit` (Phase 4 question nodes)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
