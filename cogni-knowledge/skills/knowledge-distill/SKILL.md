---
name: knowledge-distill
description: "Phase 4.5 of the v0.1.0 inverted pipeline (between ingest and compose). Reads the run's source pages + their pre_extracted_claims, dispatches concept-distiller to propose recurring type:concept / type:entity pages, then runs concept-store.py to create-or-merge those pages under a lock with claim-level dedup — so the bound wiki COMPOUNDS across runs (concept pages get enriched, not duplicated) and duplicate facts merge at deposit. Fail-soft and optional: a distill failure never blocks compose. Writes wiki/concepts/*.md + wiki/entities/*.md + distill-manifest.json. Use this skill whenever the user says 'distill the concepts', 'build the concept web', 'phase 4.5', 'knowledge distill', 'extract entities and concepts', or 'dedupe claims'. After distill, knowledge-compose reads the concept/entity pages as framing context."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Distill

Phase 4.5 of the v0.1.0 inverted pipeline — it sits **between** `knowledge-ingest` (Phase 4) and `knowledge-compose` (Phase 5): `plan → curate → fetch → ingest → **distill** → compose → verify → finalize`.

Phase 4 deposits one `type: source` page per fetched URL (verbatim body + `pre_extracted_claims:`). That makes the wiki a **citation store**. This phase turns those source claims into the distilled **concept/entity web** that makes a Karpathy wiki *compound* across runs: `type: concept` / `type: entity` pages that successive runs **enrich** (new claims appended, source backlinks unioned) rather than duplicate, with **claim-level dedup** at deposit (the Finding-H fix, #336). The differentiation thesis's compounding loop + claims-dedup metric become real here.

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
| `--dry-run` | No | Print the resolved inputs (bundle source count, existing concept/entity count, bundle hash, resume verdict) without dispatching the distiller. |

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
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest) || { echo "⚠ cogni-wiki wiki-ingest scripts not found — skipping distill (optional)"; exit 0; }
```

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-ingest`). Read the binding via `knowledge-binding.py read --knowledge-root <knowledge_root>`. On `success: false` → warn + exit cleanly. Parse `data.binding.wiki_path` as `WIKI_ROOT`; confirm `<WIKI_ROOT>/.cogni-wiki/config.json` and `<WIKI_ROOT>/wiki/` exist and are writeable.

**Project manifests.** Read `<project_path>/.metadata/ingest-manifest.json`. If absent or `ingested[]` is empty → warn ("nothing to distill — run knowledge-ingest first") and exit cleanly. Read `<project_path>/.metadata/plan.json` for `TOPIC`, `output_language` (default `en`), and derive the **project slug** (the project directory's basename, matching what `knowledge-finalize` uses for `derived_from_research:`).

### 1. Build the claim bundle (the distiller's only evidence)

For each entry in `ingested[]`, read its `wiki/sources/<slug>.md` page and pull its `pre_extracted_claims:` via the shared parser. Write a compact, bounded bundle file so the distiller reads ONE file instead of N source pages. Pass paths via env vars so spaces/apostrophes can't break the literal:

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<WIKI_ROOT>" \
MANIFEST_PATH="<project_path>/.metadata/ingest-manifest.json" \
BUNDLE_PATH="<project_path>/.metadata/distill-bundle.txt" \
python3 -c '
import json, os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import parse_pre_extracted_claims
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki" / "sources"
man = json.loads(Path(os.environ["MANIFEST_PATH"]).read_text(encoding="utf-8"))
lines = []
for e in man.get("ingested", []):
    slug = e.get("slug", "")
    page = wiki / (slug + ".md")
    if not slug or not page.is_file():
        continue
    title = e.get("title", "") or slug
    claims = parse_pre_extracted_claims(page.read_text(encoding="utf-8"))
    if not claims:
        continue
    lines.append("## source: " + slug + " | " + title)
    for c in claims:
        cid = c.get("id", "")
        text = " ".join(str(c.get("text", "")).split())
        if cid and text:
            # Emit the FULL 3-part provenance per claim line (`<slug> | <id> | <text>`)
            # so the distiller copies the triple VERBATIM into its records — no
            # per-line slug reconstruction from the `## source:` header (a verbatim
            # copy of a 2-part line would parse to an empty claim_id and be dropped).
            lines.append(slug + " | " + cid + " | " + text)
    lines.append("")
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(lines) + "\n", encoding="utf-8")
print(len([l for l in lines if l.startswith("## source:")]))
'
```

Capture the printed source count. If it is `0` (no source carries claims) → warn ("no source claims to distill") and exit cleanly.

Compute a **content** hash of the bundle for the resume check (Step 3). It MUST hash the bundle's bytes, not a path — `fetch-cache.py key` hashes a URL string and would make the resume check path-keyed (a changed claim set on the same path would falsely look "unchanged"), so do not use it here:

```
SHA=$(python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "<project_path>/.metadata/distill-bundle.txt")
```

### 2. Build the existing concept/entity slug index

So the distiller can reuse an existing concept's title (landing the merge on the same page = compounding) and avoid proposing a near-duplicate:

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<WIKI_ROOT>" \
INDEX_PATH="<project_path>/.metadata/distill-slug-index.txt" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import _FRONTMATTER_RE, _unquote_scalar
import re
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki"
title_re = re.compile(r"^title[ \t]*:[ \t]*(.+?)[ \t]*$")
out = []
for ptype, sub in (("concept", "concepts"), ("entity", "entities")):
    d = wiki / sub
    if not d.is_dir():
        continue
    for p in sorted(d.glob("*.md")):
        m = _FRONTMATTER_RE.match(p.read_text(encoding="utf-8"))
        title = p.stem
        if m:
            for line in m.group(1).splitlines():
                tm = title_re.match(line)
                if tm:
                    title = _unquote_scalar(tm.group(1).strip()); break
        out.append(p.stem + " | " + ptype + " | " + title)
Path(os.environ["INDEX_PATH"]).write_text("\n".join(out) + ("\n" if out else ""), encoding="utf-8")
print(len(out))
'
```

### 3. Resume check (idempotent no-op)

If `<project_path>/.metadata/distill-manifest.json` exists AND it records the same `bundle_hash` as `SHA` from Step 1 → the distiller already ran on this exact claim set. **Skip re-dispatch** (the LLM is the expensive part) and jump to the final summary, reporting "no-op (bundle unchanged)". `concept-store.py merge` is itself byte-stable on re-run, so skipping is purely a cost optimization, not a correctness requirement.

(The orchestrator stores `SHA` by reading it back from the manifest's `bundle_hash` field — Step 6 threads it in. On the first run the manifest has no `bundle_hash`, so the check fails and the distiller runs.)

If `--dry-run`: print the source count, existing concept/entity count, `SHA`, and the resume verdict, then stop.

### 4. Initialize distill-manifest.json

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py init --project-path <project_path>
```

### 5. Dispatch concept-distiller (single Task call)

```
Task(concept-distiller,
     CLAIM_BUNDLE_PATH=<project_path>/.metadata/distill-bundle.txt,
     SLUG_INDEX_PATH=<project_path>/.metadata/distill-slug-index.txt,
     RECORDS_OUTPUT_PATH=<project_path>/.metadata/distill-records.txt,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>)
```

`concept-distiller` lives at `${CLAUDE_PLUGIN_ROOT}/agents/concept-distiller.md` — dispatched via `Task`, not `Skill`. Single pass: it reads the bundle + index and writes the raw-text records file. Parse the return envelope:

- `ok: true` → continue to Step 6.
- `ok: true, concepts_proposed: 0` → nothing to distill; jump to the summary.
- `ok: false` → warn (surface the error) and exit cleanly (distill is optional).

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

`--bundle-hash "$SHA"` (the Step-1 content hash) is written into the manifest by `concept-store.py` itself — it is the single writer, so Step 3's resume check reads it back with no fragile second-process patch. Parse `data`: `created_slugs[]`, `updated_slugs[]` (disjoint), `concepts[]` (each `{slug, type, action, summary, claims_new, claims_deduped, claims_rejected, near_existing_slug, ...}`), `claims_attached_total`, `claims_deduped_total`, `claims_rejected_total`, `near_existing_total`, `near_existing_slugs[]` (`{slug, near_slug, near_title, near_type, score}`). On `success: false` → warn + exit cleanly. **If `claims_rejected_total > 0`, surface it loudly** — it means the distiller emitted malformed claim lines (e.g. dropped the `<slug> | <id> |` provenance), which would otherwise silently shrink the concept web; check the records file format. **`near_existing_total` / `near_existing_slugs[]` are the #340 observable tripwire** — see Step 9.

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

2. **Index update (thematic category).** File the page under the category matching its `type` (from the merge result): `--category "Concepts"` for `type: concept`, `--category "Entities"` for `type: entity`. Use the merge result's `summary` (always non-empty — `concept-store.py` falls back to the title). Every flag is on a continued line (trailing `\`); do not put a shell comment on an argument line, or `--max-summary` is dropped and the #324 mid-word clamp is lost:
   ```
   python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" --wiki-root <WIKI_ROOT> --slug <slug> \
       --summary "<the concept's summary from the merge result>" \
       --category "<Concepts|Entities per the merge result's type>" \
       --max-summary 240
   ```
   Capture the envelope. When `success == true` **and** `data.action == "inserted"`, increment `n_new` (init `0` before the loop). `data.action == "updated"` (a row already existed) does NOT count — same lockstep as `knowledge-ingest` Step 4.

3. On any helper failure, record in `failed_index_updates[]` and continue — the page is on disk; only discoverability is incomplete.

After the loop, bump `entries_count` once by the count of newly-indexed pages (only when `n_new > 0`), exactly as `knowledge-ingest` Step 4 / `knowledge-finalize` Step 8:

```
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" --wiki-root "$WIKI_ROOT" --key entries_count --delta <n_new>
```

Non-fatal on failure (reconcile via `wiki-lint --fix=entries_count_drift`). **Do NOT** run `lint_wiki.py --fix=all` / `health.py` here — `knowledge-finalize` Step 10.5 runs the whole-run conformance gate once, at the end, over the page set that now includes these distilled pages.

### 8. Append wiki/log.md

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_CONCEPTS=<len(created_slugs) + len(updated_slugs)>
N_ATTACHED=<claims_attached_total>
N_DEDUPED=<claims_deduped_total>
echo "## [${DATE_STAMP}] distill | project=${TOPIC} concepts=${N_CONCEPTS} claims=${N_ATTACHED} deduped=${N_DEDUPED}" >> "${WIKI_ROOT}/wiki/log.md"
```

The `distill` prefix is additive-safe — cogni-wiki readers bucket an unknown prefix in their catch-all without crashing (same posture `compose`/`verify`/`finalize` had before cogni-wiki v0.0.45 formalized them).

### 9. Final summary

Print ≤ 12 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Concepts created: `<n>` / updated: `<n>` / unchanged: `<n>` / skipped: `<n>` (reasons: `foundation_collision`/`no_sentinels_human_page`/`slug_type_collision`/`empty_slug`)
- Claims attached: `<claims_attached_total>` (deduped: `<claims_deduped_total>` → dedup ratio `<deduped/attached>`); if `claims_rejected_total > 0`, add `⚠ <claims_rejected_total> claim lines rejected as malformed — check the distiller's records format`
- **#340 title→slug tripwire** — if `near_existing_total > 0`, surface a warning block:
  - Header: `⚠ <near_existing_total> concepts created near an existing slug — check title stability (#340)`
  - One line per entry from `near_existing_slugs[]` (deterministic order, score-sorted desc): `  <slug> ~ <near_slug> (<near_type>, score=<score>)`
  - Subline: `If these are the same concept, the run forked a near-duplicate page; rename the proposal in the next run, or merge manually via the wiki.`
  - When `near_existing_total == 0` print nothing (no false-alarm noise on clean runs).
- Wiki entries_count: `+<n_new>` (or `⚠ bump failed — run wiki-lint --fix=entries_count_drift`; or `unchanged` when `n_new == 0`)
- Cost: `$X.XXX` (from the distiller return)
- Next: `knowledge-compose` reads the concept/entity pages as framing context (not citable evidence).

The dedup ratio is the Finding-H success metric (`differentiation-thesis.md`): of the new facts proposed this run, the fraction that merged into an existing claim instead of adding a duplicate line.

The #340 tripwire is **pure observability** — it never blocks the pipeline, never auto-merges, never skips a write. A `near_existing_slug` warning means `claim_similarity(new_title, existing_title) >= 0.65` on the symmetric weighted-Jaccard primitive; titles in that band MAY be a silent slug-fork (e.g. `"Hochrisiko-Klassifizierung"` vs `"Einstufung als hochriskant"` — different slugs, same concept) but may also be genuinely-distinct neighbours. Human judgment owns the disposition.

## Edge cases

- **Fresh base (run 1).** Every concept/entity is `created`; `claims_deduped_total` may be 0 (nothing prior to dedup against — same-run near-dupes still merge). Compounding shows from run 2 onward.
- **Re-run on the same claim set.** Step 3 skips re-dispatch when `bundle_hash` is unchanged; even without the skip, `concept-store.py merge` is byte-stable (re-merge → all `unchanged`, `n_new == 0`, no bump).
- **A concept slug collides with a `foundation: true` page.** `concept-store.py` refuses to merge (`skipped`, `reason: foundation_collision`) — never overwrites a curated foundation.
- **A concept slug collides with a hand-authored page (no MACHINE-OWNED sentinels).** `concept-store.py` skips it (`reason: no_sentinels_human_page`) and leaves the page untouched — we never clobber a page we did not author.
- **Distiller proposed a concept but every claim was a re-run duplicate.** The page is `unchanged`; no index churn, no `entries_count` bump.
- **Empty / claim-less sources.** Sources with no `pre_extracted_claims:` are omitted from the bundle; if the whole bundle is empty, the phase no-ops cleanly.

## Out of scope

- Does NOT compose the draft — that is Phase 5 (`knowledge-compose`).
- Does NOT re-narrate concept summaries across runs — Phase-1 is first-writer-wins on the `## Summary` body; only the claim/source/related lists grow (full body re-synthesis deferred).
- Does NOT emit `summary` / `learning` page types — Phase-1 ships `concept` + `entity` only.
- Does NOT run the `lint_wiki.py --fix=all` / `health.py` conformance gate — `knowledge-finalize` Step 10.5 covers the whole run once.
- Does NOT modify `binding.json` — Phase 7 (`knowledge-finalize`) appends the project entry.
- Does NOT block the pipeline — every failure path warns and exits cleanly.

## Output

- `<WIKI_ROOT>/wiki/concepts/<slug>.md` / `<WIKI_ROOT>/wiki/entities/<slug>.md` — created or enriched, with `distilled_claims:` frontmatter, MACHINE-OWNED body sentinels, and bare `[[<source-slug>]]` backlinks. A human `## Notes` region is preserved byte-for-byte across runs.
- `<WIKI_ROOT>/wiki/index.md` — each page filed under `## Concepts` / `## Entities`.
- Existing pages gain curated `[[<slug>]]` inbound backlinks (via `backlink_audit.py --apply-plan`).
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by `<n_new>`.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] distill | …` line.
- `<project_path>/.metadata/distill-manifest.json` (schema 0.1.1) + intermediate `distill-bundle.txt` / `distill-slug-index.txt` / `distill-records.txt`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 4.5 contract
- `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` — the compounding loop + claims-dedup metric this phase realizes
- `${CLAUDE_PLUGIN_ROOT}/agents/concept-distiller.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py --help` — locked create-or-merge + claim-dedup engine
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
