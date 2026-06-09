---
name: knowledge-ingest
description: "Phase 4 of the inverted pipeline. Reads fetch-manifest.json, dispatches source-ingester per fetched source to write wiki/sources/<slug>.md pages with pre_extracted_claims:, merges per-source results into ingest-manifest.json, then runs cogni-wiki's backlink_audit.py + wiki_index_update.py per new slug. The wiki becomes populated before any draft runs. Use this skill whenever the user says 'ingest the fetched sources', 'deposit fetched pages into the wiki', 'phase 4 of the knowledge pipeline', 'run the ingesters', 'knowledge ingest'. After ingest, knowledge-compose drafts the report."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Ingest

Phase 4 of the inverted pipeline. Reads `<project>/.metadata/fetch-manifest.json`, dispatches `source-ingester` per fetched source to write `wiki/sources/<slug>.md` pages, and merges per-source results into the canonical `<project>/.metadata/ingest-manifest.json`. After per-source emission, runs cogni-wiki's `backlink_audit.py` + `wiki_index_update.py` directly at script level per new slug. Then (Step 4.5) promotes each sub-question into a first-class `type: question` node at `wiki/questions/<slug>.md` whose `## Findings` body `[[links]]` the source findings that answer it, backfilling the reverse `source→question` link (SCHEMA `R1`). Finally appends one ingest summary line to `wiki/log.md`.

By the end of this phase the wiki is populated with one `type: source` page per `fetched[]` entry, each carrying `pre_extracted_claims:` in its frontmatter. The composer reads these pages; verification string-matches draft sentences against the pre-extracted claims with **zero network calls** — the structural win.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 4 — `knowledge-ingest`" and `references/claim-at-ingest.md` once to anchor on the contract.

## When to run

- `fetch-manifest.json` exists for the project (Phase 3 has run) AND either `ingest-manifest.json` does not yet exist OR the user explicitly wants to re-ingest.
- User explicitly invokes `/cogni-knowledge:knowledge-ingest`.

## Never run when

- No `fetch-manifest.json` exists at `<project_path>/.metadata/` — offer `knowledge-fetch` first.
- No `binding.json` exists at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--batch-size` | No | Advisory cap on how many fetched sources one dispatch wave covers (a sub-batch of the full set). Ingesters in a wave fan out in a single message; Claude Code — not this cap — throttles actual concurrency. Default 25 (see `references/fan-out-concurrency.md`). |
| `--dry-run` | No | Print the dispatch plan (batch count, total sources, expected new pages) without running ingesters. |
| `--no-contradictor` | No | Skip the Step 4.6 ingest-time contradiction tripwire. (`--dry-run` already skips it.) Default: the tripwire runs whenever a question group has a new source and at least one other claim-bearing page to compare it against. |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break):

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

If `WIKI_OK=no`, abort with the standard missing-plugin message.

**Resolve the cogni-wiki script dir.** Source the shared `resolve_wiki_scripts` probe (one snippet, sourced by every knowledge-* flow) and call it with the `wiki-ingest` subdir — find `cogni-wiki/skills/wiki-ingest/scripts/` so Step 5 below can call `backlink_audit.py` and `wiki_index_update.py` directly:

```
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || abort "cogni-wiki wiki-ingest scripts not found"
```

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-fetch`). Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`.

Parse `data.binding.wiki_path` as `WIKI_ROOT`. Confirm `<WIKI_ROOT>/.cogni-wiki/config.json` exists; abort otherwise. Confirm `<WIKI_ROOT>/wiki/` exists and is writeable.

The binding file read here is `<binding_path>` = `<knowledge_root>/.cogni-knowledge/binding.json` — the value sub-step 4.5.1 substitutes for the `--binding <binding_path>` flag (sub-step 4.5.5, the writer, resolves the same file from `--knowledge-root <knowledge_root>`).

**Fetch manifest + candidates.** Read `<project_path>/.metadata/fetch-manifest.json`. Abort with "run knowledge-fetch first" if absent or `fetched[]` is empty.

Read `<project_path>/.metadata/candidates.json` via `candidate-store.py read --project-path <project_path>` so each fetched URL's `sub_question_refs[]`, `title`, and `publisher` are available to pass into the ingester. Keep the URL → `sub_question_refs[]` mapping around — Step 4 reuses it to pick each source's index category.

Read `<project_path>/.metadata/plan.json` and build a `theme_label` map keyed by sub-question id (`{"sq-01": "<theme_label>", ...}` from `plan.sub_questions[]`). Step 4's index update files each source under its **first-listed** sub-question's `theme_label` (`sub_question_refs[0]`). Note `candidate-store.py` unions `sub_question_refs[]` (existing-first) on a cross-SQ dedup, so for a source matched by several sub-questions `[0]` is the first that discovered it, not a ranked "primary" — the thematic grouping is best-effort, not authoritative. Older plans have no `theme_label`; the map is then empty and Step 4 falls back to the `"Sources"` category. (`plan.json` is also read for `TOPIC` in Step 5.)

### 1. Build batch plan

1. Filter `fetched[]` to entries with `cache_key` populated and a positive cache hit confirmed (skip entries whose cache file has gone missing — surface in the summary).
2. **Resolve slugs (orchestrator-owned, single pass).** Per entry, derive the final slug by calling the shared helper. Pass the candidate title via env var — never interpolate untrusted text into a Python string literal:
   ```
   KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
   CANDIDATE_TITLE="<candidate title>" \
   python3 -c '
   import os, sys
   sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
   from _knowledge_lib import slugify
   print(slugify(os.environ["CANDIDATE_TITLE"]) or "")
   '
   ```
   If the result is empty (title was non-alnum / whitespace / missing), fall back to `src-<first-12-of-sha256(normalize_url(URL))>` via `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py key --url <URL> --bare` (take the first 12 hex chars). The ingester does NOT re-derive — it only sanity-checks `[a-z0-9][a-z0-9-]{0,79}`. `slugify()` lives in `_knowledge_lib.py` alongside `normalize_url` and the `atomic_write*` helpers — single source of truth.
3. **Skip already-ingested.** Read `ingest-manifest.json` (if it exists) and drop any `fetched[]` entry whose URL appears in `ingested[]` already. This is the re-run no-op contract: a second `knowledge-ingest` run on the same project should not re-dispatch `source-ingester` / `claim-extractor` for sources already on the wiki. The agent-side slug-collision check (`agents/source-ingester.md` Phase 3) is defence-in-depth for the cross-process race; the orchestrator-side skip is what saves cost on the common re-run path.
4. **Dedupe by slug within this run.** If two not-yet-ingested URLs map to the same slug (rare; URL dedup should have caught it upstream), keep the first occurrence and surface the collision as a non-blocking warning. Continue.
5. Split into batches of size `--batch-size` (default 25). Each batch dispatches as **one wave** (Step 3), so a run with ≤ `--batch-size` sources is a single wave — one barrier, not many. The default 25 is calibrated so a wave of 25/26 ingesters runs clean; see `references/fan-out-concurrency.md`.

If `--dry-run`: print the batch count, total sources after skip-filter, expected new pages, and stop.

### 2. Initialize ingest-manifest.json

Create `<project_path>/.metadata/ingest-manifest.json` if absent:

```json
{
  "schema_version": "0.1.0",
  "ingested": [],
  "skipped": []
}
```

If it exists, leave it — the orchestrator appends to the existing arrays on a re-run.

### 3. Dispatch source-ingester per batch (one wave per batch)

For each batch:

1. Per-source batch output paths: `<project_path>/.metadata/.ingest.batch.<NNN>.<NN>.json` (batch index + per-source index inside the batch).

1b. **Persist the authoritative dispatch table for this batch** to `<project_path>/.metadata/.ingest.dispatch.<NNN>.json` as a JSON array `[{"slug": "<Step 1.2 slug>", "url": "<fetch-manifest URL>"}, ...]`, **ordered by the same per-source index `<NN>` as the batch output paths in step 1** (so dispatch entry `i` and the batch-result file `.ingest.batch.<NNN>.<i>.json` describe the same source), built from the orchestrator's own Step 1.2 slug map + fetch-manifest URL — **at dispatch time, before any agent returns**. This is the ground truth the Step 3.5 sweep verifies against: it is written from what was *dispatched*, independent of what the agents *return* (an agent-returned slug/url can itself be cross-contaminated, so it cannot be trusted as the reference). Each ingester resolves its `SLUG`/`URL` strictly from its dispatch parameters; this record captures that pairing so a post-wave check can prove the on-disk page kept it.

2. Dispatch via the `Task` tool (matches the upstream `knowledge-curate` / `knowledge-fetch` agent-dispatch convention):
   ```
   Task(source-ingester,
        KNOWLEDGE_ROOT=<knowledge_root>,
        WIKI_ROOT=<wiki_root>,
        URL=<url>,
        SLUG=<resolved slug from Step 1.2 — orchestrator-authoritative>,
        SUB_QUESTION_REFS=<comma-separated sq-NN list from candidates.json>,
        PUBLISHER=<from candidates.json>,
        TITLE_HINT=<from candidates.json>,
        BATCH_OUTPUT_PATH=<batch_path>)
   ```

   `source-ingester` lives at `${CLAUDE_PLUGIN_ROOT}/agents/source-ingester.md` — dispatched via `Task`, not `Skill`.

3. **One wave per batch.** Issue all sources in the batch (`--batch-size`, default 25) as `source-ingester` dispatches in a **single message with multiple tool calls** so they fan out in one wave. Claude Code self-throttles the actual concurrency inside a single-message fan-out — dispatches beyond its internal ceiling queue and run as slots free, but all of them complete and return — so a wave of 25 is safe (the calibration is in Step 1.5 and `references/fan-out-concurrency.md`). The per-batch barrier is **not** a concurrency limiter; it exists only so the Step 3.4 merge stays incremental and re-runnable (a crashed wave re-runs from `ingested[]`). This mirrors the `knowledge-curate` one-wave precedent. Per-source contention is structurally impossible inside Step 3: each ingester writes a unique `wiki/sources/<slug>.md` (Step 1.2 + 1.4 guarantee slug uniqueness within the run) and its own per-source batch JSON (unique path). The cogni-wiki helpers (`wiki_index_update.py`, `backlink_audit.py`) only run in Step 4 after all ingesters in this batch have returned. Across batches, the Step 3.4 merge runs once per batch.

4. After all ingesters in this batch return, merge the per-source batch JSONs into `ingest-manifest.json`:
   - For each batch JSON file: on `ok: true` append to `ingested[]`; on `ok: false` / skipped append to `skipped[]` with the `reason`.
   - Dedup within each array by URL (covers cross-run re-merges — same URL ingested twice keeps the later entry).
   - **Single atomic write per batch**, not per source. Use the shared helper rather than reinventing the mkstemp+os.replace dance. Pass paths via env vars so apostrophes / spaces in project paths cannot break the Python literal:
     ```
     KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
     MANIFEST_PATH="<project_path>/.metadata/ingest-manifest.json" \
     BATCH_PATHS="<comma-separated per-source batch JSON paths>" \
     python3 -c '
     import json, os, sys
     sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
     from pathlib import Path
     from _knowledge_lib import atomic_write
     manifest_path = Path(os.environ["MANIFEST_PATH"])
     manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
     # ... append batch entries to manifest["ingested"] / manifest["skipped"], dedup by URL ...
     atomic_write(manifest_path, manifest)
     '
     ```
     No file lock needed — sequential merge after each batch returns.

5. On a per-source dispatcher failure (no batch file written, or summary `ok: false`), record the source URL in `failed_ingesters[]` and continue with the rest of the batch. Re-runnable by re-invoking the skill (Step 1.3 skips entries already in `ingested[]`).

### 3.5. Post-wave integrity sweep (after the Step 3.4 merge, before Step 4)

The ingesters fan out in one single-message wave (Step 3.3). That wave is where two `source-ingester` dispatches can cross-talk: the agent handling source A composes its page from source B's fetched body + frontmatter, so A's on-disk `wiki/sources/<A-slug>.md` ends up carrying B's `id:`, `sources:` URL, claims, and body. This is non-deterministic LLM attention cross-talk — not a code path — so it cannot be prompted away. The in-agent pre-write assertion (`source-ingester` Phase 3) stops most of it before disk; this sweep is the deterministic, load-bearing backstop the LLM cannot defeat. It runs **per batch**, immediately after the Step 3.4 merge, so a contaminated page is caught **before** Step 4 indexes/backlinks it and before Step 4.5 builds question nodes from it (and therefore before compose/verify ever see it).

1. **Build the sweep input.** Take this batch's persisted dispatch table (`<project_path>/.metadata/.ingest.dispatch.<NNN>.json`) and keep dispatch entry `i` **iff its per-source batch-result file `.ingest.batch.<NNN>.<i>.json` reported `ok: true`** — pair the two **by per-source index `i`, never by the agent-returned `url`/`slug`**. The index is orchestrator-owned (Step 3.1b ordered the dispatch table by the same `<NN>` the orchestrator assigned to each `BATCH_OUTPUT_PATH`), so it is contamination-proof. Filtering by URL membership in `ingested[]` would be wrong: `ingested[].url` comes from the agent's batch JSON, the exact field cross-talk corrupts — a contaminated source that echoes a sibling's URL would have its own real slug filtered *out* of the sweep input and escape detection, defeating the whole point of verifying against the dispatch record. Excluding only the `ok: false` indices (a legitimately-skipped source — `cache_miss` etc. — wrote no page) avoids a false `page_missing` without trusting any agent-populated field.

2. **Run the sweep** against the authoritative dispatch record (the filtered table), piping it on stdin:
   ```
   printf '%s' "$OK_DISPATCH_JSON" | python3 "${CLAUDE_PLUGIN_ROOT}/scripts/ingest-integrity.py" sweep \
       --wiki-root <WIKI_ROOT> \
       --knowledge-root <KNOWLEDGE_ROOT> \
       --dispatch -
   ```
   The detector reads each `<WIKI_ROOT>/wiki/sources/<slug>.md`, extracts its frontmatter `id:` + first `sources:` URL, and asserts `id == <dispatched slug>` AND `normalize_url(observed_url) == normalize_url(<dispatched url>)`. With `--knowledge-root` it adds a third leg: it reads the page's frontmatter `content_hash:` and the fetch-cache entry's `content_hash` for the dispatched URL (via `fetch-cache.py fetch`) and asserts they are equal — closing the body-only variant where an ingester kept its **own** dispatched `id:`/`sources:` but emitted a sibling's body and the sibling's `content_hash:` line (both id/url legs pass, yet the page's claims belong to another source). The leg is additive and fail-safe: a cache miss or an empty hash on either side skips it, never a false positive. It is **read-only** — it never mutates the wiki; the orchestrator owns the side effects below (the established detect-in-script / act-in-orchestrator split, cf. `backlink_audit.py` audit mode). It returns `data.violations[]` with `{slug, expected_url, observed_id, observed_url, observed_content_hash, expected_content_hash, page_path, id_ok, url_ok, content_hash_ok, reason}` where `reason ∈ {id_mismatch, url_mismatch, content_hash_mismatch, page_missing}` (precedence id > url > content_hash).

3. **Quarantine each violation:**
   - `mkdir -p <project_path>/.metadata/quarantine/` and `mv <WIKI_ROOT>/wiki/sources/<slug>.md <project_path>/.metadata/quarantine/<slug>.md` — frees the slug so a re-run recreates the page, and preserves the bad file for inspection. (A `page_missing` violation has no file to move — record it only.)
   - Remove the entry from `ingested[]` and append it to `skipped[]` with `reason: integrity_mismatch` plus `observed_id` / `observed_url` / `expected_url`. Atomic re-write of `ingest-manifest.json` via the same `_knowledge_lib.atomic_write` helper Step 3.4 uses.
   - **Exclude the slug from Step 4** (backlink/index/`n_new`) and **Step 4.5** (question-node emission) — it is not a valid page this run, so it must not be indexed, backlinked, or joined into a question's finding set.
   - Because the URL is no longer in `ingested[]`, the Step 1.3 re-run skip-filter leaves it **re-dispatchable** on the next `knowledge-ingest` run.

4. Track the quarantined count for the Step 6 summary. A clean wave has zero violations and this step is a silent no-op.

### 4. Per-new-slug cogni-wiki integration (sequential, after all ingesters return)

For each entry in `ingested[]` written this run, in deterministic slug order (Step 3.5 has already dropped any integrity-quarantined slug from `ingested[]`, so a contaminated page is never indexed or backlinked here):

1. **Backlink audit + apply (de-orphans ingested sources).** First audit:
   ```
   python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" \
       --wiki-root <WIKI_ROOT> \
       --new-page <slug> \
       --top 8 \
       --min-confidence medium
   ```
   Capture `data.candidates[]` (ranked sibling pages that textually reference this source). Then **curate a write-back plan**: for each candidate you judge a genuine relation (skip weak / coincidental term matches), author one `targets[]` entry whose `sentence` mentions the new source with a bare `[[<slug>]]` wikilink — appended as a short trailer (e.g. `"See also [[<slug>]] for ..."`) so the candidate page's verbatim body is not edited mid-text. Re-invoke the same script in apply mode, piping the plan on stdin:
   ```
   printf '%s' "$PLAN_JSON" | python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" \
       --wiki-root <WIKI_ROOT> \
       --new-page <slug> \
       --apply-plan -
   ```
   The plan shape is `{"targets": [{"slug": "<target>", "sentence": "... [[<slug>]] ..."}, ...]}`; each `sentence` MUST contain `[[<slug>]]` or the script rejects that target. `apply_plan` is **idempotent** (skips a target that already links to `[[<slug>]]`) and **fail-soft per target** (per-target errors land in `data.failed[]`, never abort the batch). Writing these inbound links is what keeps an ingested-but-never-cited source from showing up as an `orphan_page` in `wiki-lint` (the synthesis only links the sources it cites; finalize de-orphans those — see `knowledge-finalize`). Surface `applied[]` / `failed[]` counts in the Step 6 summary. If you find no genuine relation for a slug, skip apply for it (write no backlink for that slug) — never invent a backlink.

2. **Index update (thematic category):**
   Resolve the category: take the source's first-listed sub-question ref `sub_question_refs[0]` (from the candidates map built in Step 0), look it up in the `theme_label` map; use that label. Fall back to `"Sources"` only when the ref is missing or the map has no `theme_label` for it (legacy plans).

   First **sanitize the ingester-authored summary** so a stray typographic substitute (U+2020 DAGGER, U+2021, or an exotic space U+00A0/U+202F/U+2009 an LLM emitted where a normal space belongs — `§†30`, `Dezember†2025`) never reaches the reader-facing `wiki/index.md` one-liner. Mirror the Step 1.2 `slugify` pattern — pass the raw value via an env var, never interpolate untrusted text into a Python literal:
   ```
   CLEAN_SUMMARY=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
   RAW_SUMMARY="<the source's one-sentence summary>" \
   python3 -c '
   import os, sys
   sys.stdout.reconfigure(encoding="utf-8")
   sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
   from _knowledge_lib import sanitize_summary
   print(sanitize_summary(os.environ["RAW_SUMMARY"]))
   ')
   ```
   Then pass `$CLEAN_SUMMARY` (not the raw value) to `--summary`:
   ```
   python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
       --wiki-root <WIKI_ROOT> \
       --slug <slug> \
       --summary "$CLEAN_SUMMARY" \
       --category "<theme_label, or Sources fallback>" \
       --max-summary 240
   ```
   `sanitize_summary` (the typographic-substitute guard) and `--max-summary 240` (the mid-word clamp) are orthogonal backstops — the first normalizes stray glyphs to regular spaces, the second clamps a run-on on a word boundary. The `--max-summary 240` is a defensive backstop: the helper clamps the one-liner on a word boundary and appends `…` **only** if the authored sentence runs long; a normal one-sentence summary passes through untouched. It guards `wiki/index.md` against a mid-word artifact — the summary itself is authored as one crisp, complete sentence (no character count), not sliced to a length.
   `wiki_index_update.py` creates a `## <theme_label>` heading in `wiki/index.md` on first use and appends to it afterwards, so sources group thematically (per sub-question) instead of under one flat `## Sources`. The first real insert also sheds the wiki-setup `## Categories` / `_No pages yet…_` seed placeholder. Both helpers are lock-wrapped at their own write sites (`_wiki_lock` on `<WIKI_ROOT>/.cogni-wiki/.lock`), so concurrent `wiki-*` invocations from other sessions are safely serialised.

   Capture the JSON envelope. When `success == true` **and** `data.action == "inserted"`, increment an in-loop counter `n_new` (initialised to `0` before the loop) — a brand-new index row means a brand-new page. When `data.action == "updated"`, a row for this slug already existed → do **not** count it (this is the re-ingest / pre-existing-page case; counting it would over-count `entries_count`).

3. On any helper failure, record in `failed_index_updates[]` and continue (do **not** increment `n_new` — a failed index update is not a new row). The page itself is already on disk; only the discoverability is incomplete.

After the loop completes, bump `entries_count` **once** by the number of newly-indexed source pages — mirroring `knowledge-finalize` Step 8's lockstep invariant (counter and on-disk page count move together; only count rows the index actually gained):

```
# Only when n_new > 0 — a clean re-run skips already-ingested URLs at Step 1.3,
# so it reaches here with n_new == 0 → no bump → no drift (the re-run no-op).
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" \
    --wiki-root "$WIKI_ROOT" \
    --key entries_count \
    --delta <n_new>
```

Same call shape and script `knowledge-finalize` Step 8 uses (`config_bump.py` already supports a signed `--delta`); lock-wrapped at its own write site. **Non-fatal on failure** — if the bump fails, the source pages are already on disk and discoverable; surface the failure in the Step 6 summary and let the operator reconcile via `wiki-lint --fix=entries_count_drift` (the same posture finalize takes). Without this bump, `wiki-health` / `wiki-resume` report an `entries_count_drift` equal to the number of ingested source pages.

**Render the sources sub-index (`wiki/sources/index.md`).** After the per-slug index/backlink loop and the `entries_count` bump, re-render the machine-owned `wiki/sources/index.md` so the curated sources sub-index reflects the pages ingested this run. Gate on `n_new > 0` (a clean re-run added no new index row → the sub-index is already current → skip). This is the per-type call-site for the deterministic spine `knowledge-setup` seeds at bootstrap and `knowledge-finalize` sub-step 3.6 applies for concepts — the generic renderer enumerates `wiki/sources/*.md` and groups each source under its **own** portal theme (`theme_via_own_slug`), so this must run **after** the per-slug `wiki_index_update.py --category` calls above have filed every new source under its `## <theme>` heading in `wiki/index.md` — otherwise a just-ingested source lands in the renderer's trailing `## Uncategorized` group. It carries any narrator-authored `MACHINE-OWNED:SOURCES-LEADIN:<theme>` lead-in forward verbatim (no clobber), so rendering here never overwrites a lead-in a later `knowledge-finalize` narrates:

```
# Only when n_new > 0 — a clean re-run indexed no new source, so the sources
# sub-index is already current (idempotent: an unchanged wiki is a no-op).
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
    --type sources \
    --wiki-root "$WIKI_ROOT" \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
```

**Fail-soft** — a renderer failure never rolls back ingest: every source page, backlink, portal row, and `entries_count` bump is already on disk. The render is lock-wrapped (`_wiki_lock`) + atomic (`atomic_write_text`) at its own write site and writes only when the proposed text differs byte-for-byte, so a forced failure leaves no partial page. `sub_index.py` is itself fail-soft (a missing wiki-scripts dir, a `_wikilib` import failure, or a non-wiki `--wiki-root` returns an error envelope rather than raising), so the orchestrator treats a non-zero result as a surfaced warning, never an abort. Surface the outcome in the Step 6 summary and continue.

### 4.5. Per-sub-question node emission (after all batches)

Runs **once**, after the Step 3/4 batch loop has fully completed (every finding is on disk). It promotes each `plan.sub_questions[]` entry into a first-class `type: question` wiki node at `wiki/questions/<slug>.md` whose body `[[links]]` the source findings that answer it, and backfills the reverse `source→question` link so the question↔finding relation joins the backlink graph (SCHEMA `R1`). The `type: question` page type requires a cogni-wiki whose `_wikilib.PAGE_TYPE_DIRS` allowlists `question` (schema_version `0.0.7`); older wikis hard-fail in `wiki-health` until upgraded — surface the error and direct the user to upgrade cogni-wiki (same posture as the `type: source` edge case below).

The inputs are all already in hand: `plan.sub_questions[]` (read in Step 0 for the `theme_label` map; re-read for `query`/`search_guidance`/`candidate_domains`), the Step 0 URL→`sub_question_refs[]` map, and the final `ingest-manifest.json` (slug per URL).

**4.5.1. Write the question pages (deterministic, one auditable pass).** Run `question-store.py` — the stdlib script that joins the three inputs, builds each sub-question's finding set, derives a globally-unique slug (`_knowledge_lib.slugify(theme_label)`, fallback `sq-NN`), writes/merges `wiki/questions/<slug>.md` atomically, and returns a plan JSON the orchestrator consumes in sub-steps 4.5.2–4.5.4:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/question-store.py" emit \
    --wiki-root <WIKI_ROOT> \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    --plan "<project_path>/.metadata/plan.json" \
    --candidates "<project_path>/.metadata/candidates.json" \
    --ingest-manifest "<project_path>/.metadata/ingest-manifest.json" \
    --binding "<binding_path>"
```

`--binding <binding_path>` (the same `.cogni-knowledge/binding.json` resolved in the "Binding + wiki root" step) couples question-node accumulation to `topic_lineage.covered_themes[]`: a recurring research theme phrased differently across runs (a variant `theme_label` that slugifies differently) is routed by its `_knowledge_lib.theme_norm_key` to the question node a prior run already filed, so it **merges** instead of forking a second node. The flag is **read-only** — `question-store.py` never writes the binding; it returns the new themes in `theme_bindings[]` for sub-step 4.5.5 to persist. Omitting `--binding` falls back to slug-only accumulation, so a run still works against an older binding. A **pre-0.1.3 binding** (no `topic_lineage` block, or `covered_themes: []`) is handled transparently: `emit` reads an empty lineage map and produces slug-only output, and sub-step 4.5.5's `upsert-themes` creates the block on first write.

It emits `{success, data: {questions: [{slug, sub_question_id, query, sources_answering[], action}], theme_bindings: [{theme_key, question_slug, theme_label, action}], skipped_no_findings[], sources_unmapped[]}, error}`. `questions[].action` is `created` (fresh page) or `merged` (an existing `wiki/questions/<slug>.md` was enriched — its `created:` and human `## Notes` tail are preserved, the finding `[[links]]` unioned, `updated:` bumped — the v1 idempotent enrich-on-collision behaviour; a lineage match routes a variant label here too). A slug colliding with a **non-question** page (source/concept/…) is disambiguated with a `-q` suffix so a question node never shadows another page. `theme_bindings[]` carries one record per written question with a non-empty theme key (`action` ∈ `lineage_reused` | `new_theme`; first-writer-wins per theme key within a run) — sub-step 4.5.5 feeds these to the binding. Sub-questions with zero findings this run are listed in `skipped_no_findings[]` and get no page. Owns the slug logic, the `type: question` page-type contract, the lineage-resolve, and the merge/preserve semantics — the orchestrator never hand-builds the page.

Each `wiki/questions/<slug>.md` write is **unique-by-construction per slug** (atomic `_knowledge_lib.atomic_write_text`, single writer) — no `_wiki_lock` needed, same posture as the Step 3 source pages. The script imports cogni-wiki's `PAGE_TYPE_DIRS` / `split_frontmatter` from the resolved `--wiki-scripts-dir` (the same DRY posture `concept-store.py` uses for `_wiki_lock`).

**Persist the question manifest (phase handoff to `knowledge-finalize`).** Immediately after capturing the `emit` envelope above — and **unconditionally**, NOT inside sub-step 4.5.5's `theme_bindings[]`-empty skip — serialize the returned `data.questions` array to `<project_path>/.metadata/question-manifest.json` whenever it is non-empty. This is the exact "which question node did each sub-question become" mapping, known only here at emit time; `knowledge-finalize` reads it to forward-link the deposited synthesis to the research-question nodes it answers. Mirror the records-file `printf` pattern sub-step 4.5.5 uses for `theme-bindings.json`:

```
# $QUESTIONS_JSON is data.questions[] from the emit envelope above.
printf '%s' "$QUESTIONS_JSON" > "<project_path>/.metadata/question-manifest.json"
```

Skip the write only when `data.questions` is empty (every sub-question had zero findings this run) — finalize then falls through to its legacy no-manifest path. The write is a plain `.metadata/` handoff (no wiki state), so a failure here is non-fatal: the question pages are already on disk, and finalize degrades to emitting no synthesis→question links.

**4.5.2. Reverse links (R1) — `source→question`.** For each `questions[]` entry above (each has a non-empty `sources_answering[]` — zero-finding sub-questions were skipped), run `backlink_audit.py --apply-plan` exactly as Step 4.1 does, but with `--new-page <question-slug>` **and `--create-missing-heading`**. The `targets[]` are the answering source pages (one per `sources_answering[]` slug); each `sentence` inserts a bare `[[<question-slug>]]` under a `## Research questions` heading so it lands in its own section rather than mid-body:

```
printf '%s' "$PLAN_JSON" | python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" \
    --wiki-root <WIKI_ROOT> \
    --new-page <question-slug> \
    --apply-plan - \
    --create-missing-heading
```

where `$PLAN_JSON` is `{"targets": [{"slug": "<source-slug>", "sentence": "Answers research question [[<question-slug>]].", "insert_after_heading": "## Research questions"}, ...]}` — one target per answering source. `--create-missing-heading` is what makes the `## Research questions` heading **materialize** on a source page that lacks it (a freshly-ingested source page never has it): the first question that answers a given source creates the section, and a later question answering the same source finds the heading present and groups its link under it. Without the flag (the `wiki-ingest` default) `backlink_audit.py` bare-appends the sentence at end-of-body with no heading — `R1` is still satisfied and lint-clean, but the documented per-section grouping never appears. `apply_plan` rejects any `sentence` not containing `[[<question-slug>]]`, is **idempotent** (skips a source already linking the question), and is **fail-soft per target** (errors land in `data.failed[]`). The forward direction (`question→source`) already lives in the page's `## Findings` body, so both legs of `R1` are present and `wiki-lint` reports no new `reverse_link_missing` for these pairs. Surface `applied`/`failed` counts in the Step 6 summary.

**4.5.3. Index update.** File each question under its **own `theme_label` heading** — the same `## <theme_label>` section this sub-question's sources are filed under at Step 4.2 (which keys each source's heading on its *first-listed* sub-question, so a source answering several sub-questions may sit under a different heading — the co-location is best-effort, mirroring the Step 0 caveat) — so the index reads "here are the research questions, here's what answers each" instead of a separate flat `## Research questions` grouping that parallels the source sections. Resolve the category per question: look up the question's `data.questions[].sub_question_id` (from the 4.5.1 emit envelope — it carries `sub_question_id`, not `theme_label`) in the Step 0 `theme_label` map; pass that label as `--category`. Fall back to `"Research questions"` — **not** `"Sources"` — only when the map has no `theme_label` for that sub-question id (legacy plan with no `theme_label`), so a legacy base still gets one coherent question section. Sanitize the summary first via `_knowledge_lib.sanitize_summary` (the env-var `python3 -c` pattern from Step 4.2), then:

```
python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
    --wiki-root <WIKI_ROOT> \
    --slug <question-slug> \
    --summary "$CLEAN_SUMMARY" \
    --category "<theme_label, or Research questions fallback>" \
    --max-summary 240
```

Because Step 4.5 runs after every source batch, the `## <theme_label>` heading already exists, so the helper hits **Case B** (insert alphabetised by slug into the existing section) — the question bullet sorts among the source bullets (the question is *not* pinned to the top; pinning would need a locked-script lead-line capability and is an explicit non-goal). A sub-question whose answering sources all failed this run hits **Case C** (creates `## <theme_label>` with just the question bullet) — still coherent. Use the sub-question `query` as the summary source. As in Step 4.2, count `n_new_q` only when `data.action == "inserted"` (a merged re-run returns `updated` → not counted; both Case B and Case C return `inserted`, so counting is unchanged). Record helper failures in `failed_index_updates[]` and continue.

**4.5.4. Counts.** After the loop, bump once by the number of newly-inserted question rows:

```
# Only when n_new_q > 0 — a clean re-run merges in place (action == updated) and reaches here with n_new_q == 0.
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" \
    --wiki-root "$WIKI_ROOT" \
    --key entries_count \
    --delta <n_new_q>
```

**Non-fatal on failure**, same posture as Step 4 — the pages are already on disk; the operator reconciles any drift via `wiki-lint --fix=entries_count_drift`.

**4.5.5. Record theme lineage.** Persist the `theme_bindings[]` from sub-step 4.5.1 into the binding's `topic_lineage.covered_themes[]` so the *next* run's `question-store.py emit --binding …` routes a recurring theme to this run's node instead of forking a new one. Serialize the returned array to a small records file and call the **single binding writer**:

```
# $THEME_BINDINGS_JSON is data.theme_bindings[] from sub-step 4.5.1's envelope.
printf '%s' "$THEME_BINDINGS_JSON" > "<project_path>/.metadata/theme-bindings.json"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py" upsert-themes \
    --knowledge-root "<knowledge_root>" \
    --records "<project_path>/.metadata/theme-bindings.json"
```

`upsert-themes` merges each record by `theme_key` (union `labels[]`, bump `last_seen`, freeze `first_seen`, refresh `question_slug`) or appends a fresh `{theme_key, question_slug, labels, first_seen, last_seen}` entry, and returns `{themes_added, themes_updated, covered_themes_count}`. It bumps the binding schema to `0.1.3` on write (additive — defines the entry shape). `question-store.py` only **reads** the binding; this is the only writer of `covered_themes[]`, preserving the single-writer principle. **Fail-soft** (same posture as the index/count sub-steps — the question pages are already on disk; a binding-write hiccup is reconciled on the next run, which re-emits the same bindings). Skip entirely when `theme_bindings[]` is empty (legacy plans with no `theme_label`). Surface `themes_added`/`themes_updated` in the Step 6 summary.

### 4.6. Ingest-time contradiction tripwire (after Step 4.5, before Step 5)

Score the sources ingested this run against the related pages the base already holds — at the point of entry, before any of them feeds a draft. This is the literal "contradictions surface at ingest" check from `references/differentiation-thesis.md` Pillar 2, the ingest-time sibling of the synthesis-write-time `wiki-contradictor`. **Pure observability** — it never gates ingest, never rolls back a page, never changes any downstream behaviour. The pages already landed at Step 3; a failure here surfaces in the Step 6 summary and nothing else.

**Skip conditions.** Skip silently on `--dry-run`. On `--no-contradictor`, log one line (`Contradiction tripwire skipped (--no-contradictor).`) and continue. Skip when `<project_path>/.metadata/question-manifest.json` is absent (no sub-question had findings this run) or when no question group qualifies (below).

**4.6.1. Build the groups.** Read `<project_path>/.metadata/question-manifest.json` (the `data.questions[]` array Step 4.5.1 persisted). Each entry carries `slug` (the question node) and `sources_answering[]` — the **cross-run union** of every source answering that sub-question (`question-store.py emit` unions prior-run sources into this run's findings on a merge, so this set already spans runs; no need to re-parse the page's `## Findings` block). For each entry, split `sources_answering[]` using the set of source slugs **newly ingested this run** (the same per-new-slug set Step 4 iterated):

- **NEW** = `sources_answering[] ∩ {new-this-run source slugs}` — the freshly-ingested sources.
- **PRIOR-PEERS** = `sources_answering[] − NEW` — the prior-run source pages.
- **PEER_SLUGS** = PRIOR-PEERS **plus the question node's own slug** (`slug`) — the full set the agent compares NEW against. The question node carries citable `answer_claims:` only on run 2+ (after a prior distill); the agent resolves it if present and contributes nothing if not.

A group **qualifies** when `len(NEW) ≥ 2` **OR** (`len(NEW) ≥ 1` AND there is ≥1 PRIOR-PEER) — i.e. there is at least one real claim-vs-claim pair to score. The question node is **always** passed in `PEER_SLUGS` (so its `answer_claims:` are used when present) but does **NOT** count toward this threshold: `answer_claims:` only exist when prior answering sources exist, so a claim-bearing question node always co-occurs with a qualifying PRIOR-PEER — excluding the node from the count loses no real comparison while avoiding a wasted dispatch on a first run, where a single-new-source sub-question would otherwise dispatch an agent that can only no-op (1 NEW vs a claim-less node → 0 pairs). Cap PRIOR-PEERS at 20 (truncate the prior-run source list, keeping the question node; surface the truncation in the Step 6 summary). Drop groups that do not qualify.

**4.6.2. Dispatch (one fan-out wave).** Dispatch one `source-contradictor` per qualifying group in a **single-message fan-out wave** (the Step 3 / Step 4.5 fan-out precedent), threading per group: `WIKI_ROOT`, `PROJECT_PATH`, `QUESTION_SLUG=<slug>`, `NEW_SOURCE_SLUGS=<csv of NEW>`, `PEER_SLUGS=<csv of PEER, may be empty>`, `OUTPUT_LANGUAGE=<plan.output_language>`, and `OUT_PATH=<project_path>/.metadata/.contradiction-ingest.<slug>.json`. Each agent scores each NEW claim against each PEER claim and each other NEW claim, writing its own per-group fragment.

**4.6.3. Merge.** After the wave returns, merge the per-group fragments into one canonical artifact:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/contradiction-ingest-store.py" merge \
    --shards "<project_path>/.metadata/.contradiction-ingest.*.json" \
    --out "<project_path>/.metadata/contradiction-ingest.json" \
    --output-language <plan.output_language>
```

`merge` re-ids every finding globally (`ctr-001..`), recomputes the aggregate `counts`, asserts the count invariants, records one `groups_compared[]` row per fragment, and overwrites the canonical file (idempotent on re-ingest — the same posture `knowledge-finalize` uses overwriting `contradictor-vN.json`). A malformed / unreadable / schema-mismatched fragment is skipped fail-soft (recorded in the envelope's `skipped_shards[]`), never aborting the merge.

**Fail-soft, explicit.** A Task failure, schema mismatch, or malformed envelope at any sub-step **never rolls back any ingested page** — it surfaces in Step 6 and nothing else. Capture the merge envelope's `counts` for the Step 6 line.

### 5. Append wiki/log.md

Append one summary line (Bash `>>` append; `wiki/log.md` is append-only by cogni-wiki convention — see `cogni-wiki/CLAUDE.md` §"Key Conventions"):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_INGESTED=<len(ingested[]) written this run>
N_CLAIMS=<sum of claims_extracted across this-run ingested[]>
LOG_PATH=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/control-path.py" log --wiki-root "${WIKI_ROOT}")
echo "## [${DATE_STAMP}] ingest | project=${TOPIC} sources=${N_INGESTED} claims=${N_CLAIMS}" >> "${LOG_PATH}"
```

The `ingest` prefix is already in cogni-wiki's log-format enum (see `cogni-wiki/CLAUDE.md`). `control-path.py log` resolves the canonical `log.md` location (legacy `wiki/log.md` today, `wiki/meta/log.md` once the layout flip lands) so no flow hardcodes the path — see `scripts/control-path.py`.

### 6. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Batches: `<count>` dispatched (failed: `<failed_count>`)
- Ingested: `<count>` new pages (`<total_claims>` total claims extracted)
- Skipped: `<count>` (reason breakdown: `cache_miss=<n>, unavailable=<n>, slug_collision=<n>, integrity_mismatch=<n>`)
- `⚠ Integrity: <n> contaminated page(s) quarantined (re-run knowledge-ingest to re-ingest)` — **print only when `n > 0`** (the count of Step 3.5 violations quarantined this run); a clean run omits this line.
- Backlinks written: `<n_applied>` applied, `<n_failed>` failed (across new slugs; de-orphans ingested sources)
- `⚠ Unmapped sources: <n> ingested source(s) mapped to no sub-question (URL diverged from candidate — redirect / PDF canonicalization); see sources_unmapped[]` — **print only when `len(data.sources_unmapped) > 0`** (from the Step 4.5.1 `emit` envelope); a clean run omits this line. The source pages are on disk and discoverable — they simply join no question node this run.
- `⚠ Ingest contradictions: <n> detected (<h> high) — observability-only; see contradiction-ingest.json` — **print only when `counts.total > 0`** (from the Step 4.6.3 merge envelope), where `<n>` is `counts.total` and `<h>` is `counts.high`; a clean run (or a `--no-contradictor` / `--dry-run` run) omits this line. The contradictions are surfaced, never resolved — they do not gate ingest. Append `(peers truncated at 20 for <m> group(s))` when any group hit the PEER cap.
- Wiki entries_count: `+<n_new>` (or `⚠ entries_count bump failed — run wiki-lint --fix=entries_count_drift`; or `unchanged` when `n_new == 0` on a re-run)
- Sources sub-index: `✓ wiki/sources/index.md rendered` (or `⚠ sources sub-index render failed — <reason>; source pages on disk`; or `unchanged` when `n_new == 0`) — from the Step 4 render call
- Theme lineage: `<themes_added>` new, `<themes_updated>` updated in `topic_lineage.covered_themes` (Step 4.5.5; omit the line when `theme_bindings[]` was empty)
- Cost: `$X.XX` (sum of `cost_estimate.estimated_usd` across ingester + claim-extractor)
- Next: `knowledge-compose` reads the populated `wiki/sources/*.md` + `ingest-manifest.json` to draft the report.

If `len(ingested) == 0` and `len(skipped) > 0`, emit a warning: "no new pages written this run — every fetched source was already in ingest-manifest.json or skipped; check the skipped breakdown".

## Edge cases

- **Re-ingest of an existing project.** `ingest-manifest.json` already exists; the orchestrator skips entries already in `ingested[]` (URL-keyed). Manual cleanup (delete page + remove from manifest) is the path to force a re-ingest of a specific URL.
- **Cache file gone missing between fetch and ingest.** Surface in `skipped[]` with `reason: cache_miss` and continue. The user can re-run `knowledge-fetch` to repopulate.
- **Slug collision across batches.** Step 1.3 dedupes before dispatch; defence-in-depth check inside `source-ingester` refuses to overwrite an existing page. Surfaces as `reason: slug_collision` in `skipped[]`.
- **Cross-contaminated page (ingest-wave attention cross-talk).** A page that lands on disk carrying another source's `id:` / `sources:` URL (one `source-ingester` composed its page from a sibling's fetched body in the same fan-out wave) is caught by the Step 3.5 sweep against the dispatch record, moved to `<project_path>/.metadata/quarantine/<slug>.md`, dropped from `ingested[]`, and recorded in `skipped[]` with `reason: integrity_mismatch`. The freed slug + the URL's absence from `ingested[]` leave it re-dispatchable — a plain `knowledge-ingest` re-run re-ingests it. The quarantined file is kept (not deleted) for inspection.
- **First ingest into an empty wiki.** `wiki/index.md` may exist with only the wiki-setup header + the `## Categories` / `_No pages yet…_` seed placeholder. The first `wiki_index_update.py` call creates the first `## <theme_label>` category and sheds the seed placeholder; subsequent calls append. On a brand-new base the backlink apply step has few or no sibling pages to link from — that's expected; the synthesis (finalize) and later ingests fill the graph in.
- **Wiki schema with `type: source` / `type: question` not yet allowlisted.** A current cogni-wiki `_wikilib.PAGE_TYPE_DIRS` includes `"source": "sources"` and `"question": "questions"`; older wikis hard-fail in `wiki-health` until upgraded. The skill does not auto-migrate; surface the error and direct the user to upgrade cogni-wiki. `question-store.py` `mkdir -p`'s `wiki/questions/` on demand.
- **Step 4.5 legacy plan with no `theme_label`.** `question-store.py` falls back to the `sq-NN` slug, and the Step 4.5.3 index category falls back to `## Research questions` **only when `theme_label` is absent** for that sub-question (otherwise the question files under its `## <theme_label>` heading alongside its answering sources), so a pre-`theme_label` plan still produces well-named question nodes under one coherent question section.
- **Step 4.5 cross-type slug collision.** When `slugify(theme_label)` resolves to an existing page of a different type (e.g. a `wiki/sources/<slug>.md` that already owns the slug), `question-store.py` appends a `-q` (`-q-2`, …) disambiguator so a question node never overwrites or shadows a non-question page. A collision with an existing *question* page is an intentional merge (enrich-on-collision).
- **Step 4.5 re-run idempotency.** A second run merges each question page in place (`action: merged`): the human-owned `## Notes` tail is preserved verbatim, the `## Findings` `[[links]]` are unioned, `created:` is preserved, `updated:` bumps. No duplicate index rows (the index update returns `updated`, not counted), and `entries_count` is unchanged on a pure re-run.

## Out of scope

- Does NOT compose the draft — that is Phase 5 (`knowledge-compose`).
- Does NOT verify claims — Phase 6 (`knowledge-verify`).
- Does NOT auto-select backlink targets — `backlink_audit.py` never invents links; the orchestrator curates the `targets[]` plan from the audit candidates and only then applies it.
- Records **question-node theme lineage** into `binding.json::topic_lineage.covered_themes[]` (Step 4.5.5) — the one binding field this skill writes, via `knowledge-binding.py upsert-themes`. `research_projects[]` remains Phase 7 (`knowledge-finalize`)'s job.
- Does NOT re-run fetch — that is `knowledge-fetch`.

## Output

- `<WIKI_ROOT>/wiki/sources/<slug>.md` per fetched source (one file per `ingested[]` entry).
- `<WIKI_ROOT>/wiki/questions/<slug>.md` per sub-question with ≥1 finding this run (Step 4.5) — `type: question`, body `## Findings` listing `- [[<source-slug>]]` per answering source. Requires the cogni-wiki `type: question` allowlist (schema_version `0.0.7`).
- `<WIKI_ROOT>/wiki/index.md` updated — each source filed under its sub-question's `## <theme_label>` category (falls back to `## Sources` for legacy plans); each question node filed under its sub-question's same `## <theme_label>` category alongside its answering sources (falls back to `## Research questions` when the plan has no `theme_label`); the wiki-setup seed placeholder is shed on the first real insert.
- `<WIKI_ROOT>/wiki/sources/index.md` re-rendered (Step 4, when `n_new > 0`) — the machine-owned sources sub-index, grouped by portal theme via `sub_index.py render --type sources`; narrator-authored `SOURCES-LEADIN` spans are carried forward verbatim.
- Existing `wiki/<type>/<target>.md` pages gain a curated `[[<slug>]]` backlink to each new source (via `backlink_audit.py --apply-plan`), so ingested sources are not orphans. Each answering `wiki/sources/<slug>.md` additionally gains a `[[<question-slug>]]` reverse link under a `## Research questions` heading (Step 4.5), satisfying SCHEMA `R1` for the sq↔finding pair.
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by `<n_new>` source pages (Step 4) plus `<n_new_q>` question pages (Step 4.5).
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] ingest | …` line.
- `<project_path>/.metadata/ingest-manifest.json` (schema 0.1.0).
- `<project_path>/.metadata/.ingest.batch.<NNN>.<NN>.json` per ingester dispatch (intermediate; kept for debugging).
- `<project_path>/.metadata/.ingest.dispatch.<NNN>.json` per batch — the authoritative `[{slug, url}]` dispatch record the Step 3.5 sweep verifies against (intermediate; kept for debugging).
- `<project_path>/.metadata/quarantine/<slug>.md` per Step 3.5 integrity violation — the contaminated page, moved off the wiki and preserved for inspection; the slug is freed and the URL stays re-dispatchable.
- `<project_path>/.metadata/theme-bindings.json` — the Step 4.5.1 `theme_bindings[]` serialized for the Step 4.5.5 `upsert-themes` call (intermediate; kept for debugging).
- `<project_path>/.metadata/question-manifest.json` — the Step 4.5.1 `data.questions[]` array serialized as the phase handoff `knowledge-finalize` reads to forward-link the deposited synthesis to the research-question nodes it answers (written whenever any sub-question had findings this run).
- `<project_path>/.metadata/contradiction-ingest.json` — the Step 4.6 ingest-time contradiction findings, merged from the per-group fragments (schema 0.1.0; observability-only; overwritten on re-ingest). Absent on a `--no-contradictor` / `--dry-run` run or when no group qualified.
- `<project_path>/.metadata/.contradiction-ingest.<question-slug>.json` per qualifying group — the Step 4.6 per-group `source-contradictor` fragment (intermediate; kept for debugging).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 4 contract
- `${CLAUDE_PLUGIN_ROOT}/references/fan-out-concurrency.md` — why `--batch-size` defaults to 25; the cross-phase fan-out posture
- `${CLAUDE_PLUGIN_ROOT}/references/claim-at-ingest.md` — why claims at ingest, claim shape
- `${CLAUDE_PLUGIN_ROOT}/agents/source-ingester.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/agents/claim-extractor.md` — dispatched by source-ingester
- `${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/question-store.py --help` — Step 4.5 per-sub-question node emitter
- `${CLAUDE_PLUGIN_ROOT}/scripts/ingest-integrity.py --help` — Step 3.5 post-wave integrity sweep
- `${CLAUDE_PLUGIN_ROOT}/scripts/contradiction-ingest-store.py --help` — Step 4.6 per-group fragment merge
- `${CLAUDE_PLUGIN_ROOT}/agents/source-contradictor.md` — Step 4.6 dispatched agent (ingest-time contradiction scorer)
