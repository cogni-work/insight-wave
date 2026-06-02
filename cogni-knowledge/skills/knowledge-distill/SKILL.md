---
name: knowledge-distill
description: "Phase 4.5 of the inverted pipeline (between ingest and compose). Distills the run's source claims into recurring type:concept / type:entity pages (plus, conservatively, cross-source type:summary / run-level type:learning pages), creating-or-merging them under a lock with claim-level dedup so the bound wiki compounds across runs (distilled pages get enriched, not duplicated). Also synthesizes a citable answer_claims: surface onto each type:question node from its findings' claims (Step 6.9). An optional cross-lingual pass merges DE↔EN twin claims on mixed-language bases (auto-skips otherwise). Fail-soft and optional: a distill failure never blocks compose. Use this skill whenever the user says 'distill the concepts', 'build the concept web', 'phase 4.5', 'knowledge distill', 'extract entities and concepts', 'answer the question nodes', or 'dedupe claims'. After distill, knowledge-compose reads the distilled pages as framing context."
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
# keep in sync with concept-store.py::_TYPE_DIRS (concept/entity/summary/learning)
for ptype, sub in (("concept", "concepts"), ("entity", "entities"), ("summary", "summaries"), ("learning", "learnings")):
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

If `--dry-run`: print the source count, existing distilled-page count, `SHA`, and the resume verdict, then stop.

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

`--bundle-hash "$SHA"` (the Step-1 content hash) is written into the manifest by `concept-store.py` itself — it is the single writer, so Step 3's resume check reads it back with no fragile second-process patch. Parse `data`: `created_slugs[]`, `updated_slugs[]` (disjoint), `concepts[]` (each `{slug, type, action, summary, claims_new, claims_deduped, claims_rejected, near_existing_slug, ...}`), `claims_attached_total`, `claims_deduped_total`, `claims_rejected_total`, `near_existing_total`, `near_existing_slugs[]` (`{slug, near_slug, near_title, near_type, score}`). On `success: false` → warn + exit cleanly. **If `claims_rejected_total > 0`, surface it loudly** — it means the distiller emitted malformed claim lines (e.g. dropped the `<slug> | <id> |` provenance), which would otherwise silently shrink the concept web; check the records file format. **`near_existing_total` / `near_existing_slugs[]` are the title→slug observable tripwire** — see Step 9.

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

```
CAND_JSON="<project_path>/.metadata/xlingual-candidates.json" \
BUNDLE_PATH="<project_path>/.metadata/xlingual-candidates.txt" \
python3 -c '
import json, os
from pathlib import Path
d = json.loads(Path(os.environ["CAND_JSON"]).read_text(encoding="utf-8"))
cands = d.get("data", {}).get("candidates", []) if d.get("success") else []
out = []
for c in cands:
    out.append("## candidate: " + c.get("slug", ""))
    out.append("a_id: " + c.get("a_id", ""))
    out.append("a_text: " + " ".join(str(c.get("a_text", "")).split()))
    out.append("b_id: " + c.get("b_id", ""))
    out.append("b_text: " + " ".join(str(c.get("b_text", "")).split()))
    out.append("shared_anchors: " + ", ".join(c.get("shared_anchors", [])))
    out.append("")
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(out) + ("\n" if out else ""), encoding="utf-8")
print(len(cands))
'
```

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

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<WIKI_ROOT>" \
UPDATED_SLUGS="<space-separated updated_slugs from Step 6>" \
BUNDLE_PATH="<project_path>/.metadata/renarrate-bundle.txt" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import extract_machine_block, parse_distilled_claims
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki"
out = []
for slug in os.environ["UPDATED_SLUGS"].split():
    page = None
    # keep in sync with concept-store.py::_TYPE_DIRS (concept/entity/summary/learning)
    for sub in ("concepts", "entities", "summaries", "learnings"):
        cand = wiki / sub / (slug + ".md")
        if cand.is_file():
            page = cand; break
    if page is None:
        continue
    text = page.read_text(encoding="utf-8")
    inner = extract_machine_block(text, "SUMMARY") or ""
    # Drop the leading `## Summary` heading + blank line — the bundle wants prose only.
    prose_lines = [ln for ln in inner.splitlines() if ln.strip() != "## Summary"]
    while prose_lines and not prose_lines[0].strip():
        prose_lines.pop(0)
    claims = parse_distilled_claims(text)
    out.append("## slug: " + slug)
    out.append("### current-summary")
    out.append("\n".join(prose_lines) if prose_lines else "_No summary yet._")
    out.append("### claims")
    for c in claims:
        t = " ".join(str(c.get("text", "")).split())
        if t:
            out.append("- " + t)
    out.append("")
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(out) + "\n", encoding="utf-8")
print(len([l for l in out if l.startswith("## slug:")]))
'
```

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

### 6.9. Answer-claim synthesis for question nodes (default-on, fail-soft)

Gives each `type: question` node (deposited by `knowledge-ingest` Step 4.5) a
**citable answer surface** — an `answer_claims:` frontmatter block distilled from the
node's findings' `pre_extracted_claims:`, exactly as concept/entity pages got
`distilled_claims:`. A question node becomes a first-class cross-source
*answer unit* the composer can later cite and the verifier can score. This step
needs **no** index/backlink/`entries_count` work — question nodes already exist and are
indexed at ingest time; it only enriches their frontmatter.

**Skip cleanly when** `<WIKI_ROOT>/wiki/questions/` does not exist or is empty (a base
that predates the question-node feature, or a run with no question nodes) — jump to Step 7.

**a. Build the per-question claim bundle.** For each `wiki/questions/<slug>.md`, read its
`sources_answering:` list and pull each listed source page's `pre_extracted_claims:`,
emitting one `## question: <slug> | <title>` block followed by the same 3-part
`<source_slug> | <claim_id> | <text>` claim lines the Step-1 concept bundle uses. Reuse
the shared parsers — `split_frontmatter` (the same `_wikilib` import `question-store.py
emit` uses, for the inline `sources_answering:` list) + `parse_pre_extracted_claims`:

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_SCRIPTS="$WIKI_INGEST_SCRIPTS" \
WIKI_ROOT="<WIKI_ROOT>" \
BUNDLE_PATH="<project_path>/.metadata/answer-bundle.txt" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
sys.path.insert(0, os.environ["WIKI_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import parse_pre_extracted_claims
from _wikilib import split_frontmatter
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki"
qdir = wiki / "questions"
lines = []
n_q = 0
for page in sorted(qdir.glob("*.md")) if qdir.is_dir() else []:
    fm, _body = split_frontmatter(page.read_text(encoding="utf-8"))
    answering = fm.get("sources_answering") or []
    if not answering:
        continue
    title = fm.get("title", "") or page.stem
    block = ["## question: " + page.stem + " | " + str(title)]
    for src in answering:
        sp = wiki / "sources" / (str(src) + ".md")
        if not sp.is_file():
            continue
        for c in parse_pre_extracted_claims(sp.read_text(encoding="utf-8")):
            cid = c.get("id", "")
            text = " ".join(str(c.get("text", "")).split())
            if cid and text:
                # FULL 3-part provenance per line — the distiller copies it verbatim.
                block.append(str(src) + " | " + cid + " | " + text)
    if len(block) > 1:  # the question has at least one answering claim
        lines.extend(block); lines.append(""); n_q += 1
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
print(n_q)
'
```

If the printed question count is `0` (no question node carries answerable claims) → skip
cleanly to Step 7 (report `n/a (no answerable question nodes)`).

**b. Dispatch the answer-distiller (single Task call).**

```
Task(answer-distiller,
     ANSWER_BUNDLE_PATH=<project_path>/.metadata/answer-bundle.txt,
     RECORDS_OUTPUT_PATH=<project_path>/.metadata/answer-records.txt,
     OUTPUT_LANGUAGE=<plan.json::output_language, default en>)
```

`answer-distiller` lives at `${CLAUDE_PLUGIN_ROOT}/agents/answer-distiller.md` —
dispatched via `Task`, not `Skill`. Single pass: it selects each question's answering
claims and writes the raw-text records file. Parse the return: `ok: true` → continue to
6.9c; `ok: true, questions_proposed: 0` or `ok: false` → **warn (surface the error) and
jump to Step 7** (answer synthesis never blocks the pipeline).

**c. Merge into each question node's `answer_claims:` block (locked, claim-dedup).**

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
Step 7. **If `claims_rejected_total > 0`, surface it loudly** (the distiller emitted
malformed claim lines — check the records format). Capture the counts for Step 9.

**Note on the emit interaction (no code change to `emit`).** A *later* run's ingest Step
4.5 (`question-store.py emit`) re-renders a question node's frontmatter from its fixed
template, which does **not** carry `answer_claims:` — so it drops the block until *that*
run's Step 6.9 re-adds it. Within a run the order is always ingest → distill, so the
surface is restored each run; if distill is skipped (it is optional), the node reverts to
framing-only — exactly this phase's fail-soft contract, identical downstream to today.

**Fail-soft at every hop.** A bundle-build error, a distiller `ok:false`, a
missing/empty records file, or a non-zero `answer-merge` exit must each **warn and
continue** to Step 7 with the question nodes intact (framing-only). This pass is
enrichment, never a gate.

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

2. **Index update (thematic category).** File the page under the category matching its `type` (from the merge result): `--category "Concepts"` for `type: concept`, `--category "Entities"` for `type: entity`, `--category "Summaries"` for `type: summary`, `--category "Learnings"` for `type: learning`. Use the merge result's `summary` (always non-empty — `concept-store.py` falls back to the title), but first **sanitize it** so a stray typographic substitute (U+2020 DAGGER, U+2021, or an exotic space U+00A0/U+202F/U+2009) never reaches the reader-facing `wiki/index.md` one-liner — same guard `knowledge-ingest` Step 4.2 applies, pass the raw value via an env var:
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
       --category "<Concepts|Entities|Summaries|Learnings per the merge result's type>" \
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

The `distill` prefix is additive-safe — cogni-wiki readers bucket an unknown prefix in their catch-all without crashing (same posture `compose`/`verify`/`finalize` had before cogni-wiki formalized them).

### 9. Final summary

Print ≤ 12 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Distilled pages created: `<n>` / updated: `<n>` / unchanged: `<n>` / skipped: `<n>` (reasons: `foundation_collision`/`no_sentinels_human_page`/`slug_type_collision`/`empty_slug`)
  - By type (created): concepts `<c>` / entities `<e>` / summaries `<s>` / learnings `<l>` — count each from the merge result's per-slug `type` (omit a type's tally when it is `0`)
- Claims attached: `<claims_attached_total>` (deduped: `<claims_deduped_total>` → dedup ratio `<deduped/attached>`); if `claims_rejected_total > 0`, add `⚠ <claims_rejected_total> claim lines rejected as malformed — check the distiller's records format`
- Cross-lingual merges: `<n_merged>` (`<n_skipped>` skipped) — or `skipped (--no-crosslingual)` / `n/a (no cross-lingual candidates)` when Step 6.6 did not fire (the single-language norm — no DE↔EN twins to merge)
- Summaries re-narrated: `<n_renarrated>` (`<n_unchanged>` unchanged, `<n_skipped>` skipped) — or `skipped (--no-renarrate)` / `n/a (no updated pages)` when Step 6.7 did not run
- Question nodes answered: `<n with answer_claims created/updated>` (claims attached `<claims_attached_total>`, deduped `<claims_deduped_total>`) — or `n/a (no answerable question nodes)` when Step 6.9 did not fire; if `claims_rejected_total > 0`, add `⚠ <n> answer-claim lines rejected as malformed — check the answer-distiller's records format`
- **title→slug tripwire** — if `near_existing_total > 0`, surface a warning block:
  - Header: `⚠ <near_existing_total> concepts created near an existing slug — check title stability`
  - One line per entry from `near_existing_slugs[]` (deterministic order, score-sorted desc): `  <slug> ~ <near_slug> (<near_type>, score=<score>)`
  - Subline: `If these are the same concept, the run forked a near-duplicate page; rename the proposal in the next run, or merge manually via the wiki.`
  - When `near_existing_total == 0` print nothing (no false-alarm noise on clean runs).
- Wiki entries_count: `+<n_new>` (or `⚠ bump failed — run wiki-lint --fix=entries_count_drift`; or `unchanged` when `n_new == 0`)
- Cost: `$X.XXX` (from the distiller return)
- Next: `knowledge-compose` reads the distilled pages (concept/entity/summary/learning) as framing context (not citable evidence).

The dedup ratio is the compounding success metric (`differentiation-thesis.md`): of the new facts proposed this run, the fraction that merged into an existing claim instead of adding a duplicate line.

The title→slug tripwire is **pure observability** — it never blocks the pipeline, never auto-merges, never skips a write. A `near_existing_slug` warning means `claim_similarity(new_title, existing_title) >= 0.65` on the symmetric weighted-Jaccard primitive; titles in that band MAY be a silent slug-fork (e.g. `"Hochrisiko-Klassifizierung"` vs `"Einstufung als hochriskant"` — different slugs, same concept) but may also be genuinely-distinct neighbours. Human judgment owns the disposition.

## Edge cases

- **Fresh base (run 1).** Every concept/entity is `created`; `claims_deduped_total` may be 0 (nothing prior to dedup against — same-run near-dupes still merge). Compounding shows from run 2 onward.
- **Re-run on the same claim set.** Step 3 skips re-dispatch when `bundle_hash` is unchanged; even without the skip, `concept-store.py merge` is byte-stable (re-merge → all `unchanged`, `n_new == 0`, no bump); `updated_slugs[]` is then empty, so Step 6.7 re-narration also no-ops.
- **A concept slug collides with a `foundation: true` page.** `concept-store.py` refuses to merge (`skipped`, `reason: foundation_collision`) — never overwrites a curated foundation.
- **A concept slug collides with a hand-authored page (no MACHINE-OWNED sentinels).** `concept-store.py` skips it (`reason: no_sentinels_human_page`) and leaves the page untouched — we never clobber a page we did not author.
- **Distiller proposed a concept but every claim was a re-run duplicate.** The page is `unchanged`; no index churn, no `entries_count` bump.
- **Empty / claim-less sources.** Sources with no `pre_extracted_claims:` are omitted from the bundle; if the whole bundle is empty, the phase no-ops cleanly.
- **No question nodes / base predates the question-node feature.** Step 6.9 finds no `wiki/questions/` dir (or no node with answerable claims) and self-skips cleanly (`n/a (no answerable question nodes)`) — no `answer_claims:` work, no error.
- **Distill skipped entirely.** Question nodes keep only their `## Findings` + `## Notes` (framing-only) — byte-identical to behavior before the answer surface existed; the composer reads them framing-only either way (the citable path is a later activation step).
- **Re-ingest before re-distill.** A later run's ingest `emit` re-renders the question frontmatter without `answer_claims:` (it has no such template field); Step 6.9 re-adds it the same run. Transiently framing-only between ingest and distill, restored by distill — never a lost-data state for a completed run.
- **Single-language base (the norm).** Step 6.6's `xlingual-candidates` finds no pairs (same-language twins already collapsed in Step 6), so the cross-lingual pass self-skips with zero LLM cost — `n/a (no cross-lingual candidates)`. The feature only does work on a mixed DE↔EN base.

## Out of scope

- Does NOT compose the draft — that is Phase 5 (`knowledge-compose`).
- Re-narrates the `## Summary` body of **updated** distilled pages (any of the four types) from the merged claims (Step 6.7, default-on, fail-soft; `--no-renarrate` opts out). `created` pages keep the distiller's fresh summary; pure re-runs touch nothing. It does NOT re-synthesize any other block, and it does NOT add a contradiction pass.
- Merges **cross-lingual (DE↔EN) twin claims** on a mixed-language base (Step 6.6, default-on, fail-soft, auto-skip; `--no-crosslingual` opts out). An LLM only **confirms** pairs the script flagged (shared article-number anchor + low overlap); `concept-store.py crossmerge` re-validates the gate and UNIONs provenance onto the survivor — **never dropping a fact**. It does NOT touch single-language dedup (Step 6's job), and it explicitly does NOT use embedding/vector similarity (approach (c), rejected by the differentiation thesis).
- Emits four page types — `concept` / `entity` plus, conservatively, the cross-source `summary` and run-level `learning`; the distiller defaults to `concept`/`entity` and reaches for the new types only when a cluster fits neither. It does NOT emit any other cogni-wiki page type (sources are Phase 4, syntheses are Phase 7).
- Does NOT run the `lint_wiki.py --fix=all` / `health.py` conformance gate — `knowledge-finalize` Step 10.5 covers the whole run once.
- Does NOT modify `binding.json` — Phase 7 (`knowledge-finalize`) appends the project entry.
- Does NOT block the pipeline — every failure path warns and exits cleanly.

## Output

- `<WIKI_ROOT>/wiki/{concepts,entities,summaries,learnings}/<slug>.md` — created or enriched per the proposal's `type:`, with `distilled_claims:` frontmatter, MACHINE-OWNED body sentinels, and bare `[[<source-slug>]]` backlinks. A human `## Notes` region is preserved byte-for-byte across runs.
- `<WIKI_ROOT>/wiki/index.md` — each page filed under `## Concepts` / `## Entities` / `## Summaries` / `## Learnings`.
- Existing pages gain curated `[[<slug>]]` inbound backlinks (via `backlink_audit.py --apply-plan`).
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by `<n_new>`.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] distill | …` line.
- `<project_path>/.metadata/distill-manifest.json` (schema 0.1.1) + intermediate `distill-bundle.txt` / `distill-slug-index.txt` / `distill-records.txt`; plus (when Step 6.6 fires) `xlingual-candidates.json` / `xlingual-candidates.txt` / `xlingual-records.txt`; plus (when Step 6.7 runs) `renarrate-bundle.txt` / `renarrate-records.txt`.
- Updated distilled pages (any of the four types) get their `## Summary` body re-narrated from the merged claims (Step 6.7); all other machine blocks + the `## Notes` tail stay byte-identical.
- `<WIKI_ROOT>/wiki/questions/<slug>.md` — each `type: question` node gains/enriches an `answer_claims:` frontmatter block (Step 6.9, `acl-NNN` ids, claim-deduped, with `backlinks[]`/`source_claim_refs[]` provenance); the `## Findings` block and the human `## Notes` tail stay byte-identical. Intermediate `answer-bundle.txt` / `answer-records.txt`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 4.5 contract
- `${CLAUDE_PLUGIN_ROOT}/references/differentiation-thesis.md` — the compounding loop + claims-dedup metric this phase realizes
- `${CLAUDE_PLUGIN_ROOT}/agents/concept-distiller.md` — dispatched agent (Phase 1 proposals)
- `${CLAUDE_PLUGIN_ROOT}/agents/concept-summary-narrator.md` — dispatched agent (Step 6.7 summary re-narration)
- `${CLAUDE_PLUGIN_ROOT}/agents/cross-lingual-claim-merger.md` — dispatched agent (Step 6.6 cross-lingual DE↔EN claim merge)
- `${CLAUDE_PLUGIN_ROOT}/agents/answer-distiller.md` — dispatched agent (Step 6.9 answer-claim synthesis for question nodes)
- `${CLAUDE_PLUGIN_ROOT}/scripts/concept-store.py --help` — locked create-or-merge + claim-dedup engine (incl. `xlingual-candidates` / `crossmerge`)
- `${CLAUDE_PLUGIN_ROOT}/scripts/question-store.py --help` — `answer-merge` (Step 6.9 locked answer_claims: splice) + `emit` (Phase 4 question nodes)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
