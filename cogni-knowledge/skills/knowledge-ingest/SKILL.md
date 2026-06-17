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

Read `<project_path>/.metadata/plan.json` and build a `theme_label` map keyed by sub-question id (`{"sq-01": "<theme_label>", ...}` from `plan.sub_questions[]`). Step 4's index update files each source under its **first-listed** sub-question's `theme_label` (`sub_question_refs[0]`). Note `candidate-store.py` unions `sub_question_refs[]` (existing-first) on a cross-SQ dedup, so for a source matched by several sub-questions `[0]` is the first that discovered it, not a ranked "primary" — the thematic grouping is best-effort, not authoritative. Older plans have no `theme_label`; the map is then empty and Step 4 falls back to the `"Sources"` category. (`plan.json` is also read for `TOPIC` in Step 5.) **Also capture `plan.json::market` here** (a single run-level string, e.g. `dach`) — Step 3 threads it to every `source-ingester` as `MARKET` so each source page carries a `market:` frontmatter signal for the perspectives overlay's Where facet. Older plans with no `market` leave it empty (the field is then dropped).

**Capture the phase start + initialise the ledger accumulators here** (consumed by Step 7's `run-metrics.py record`). Stamp `PHASE_START=$(date -u +%FT%TZ)` now, before any batch dispatch, and initialise the two run-level accumulators the Step 3.4 merge folds each batch into: `INGEST_COST_USD=0` (the measured ingest spend) and `MAX_DURATION_MS=0` (the slowest single `source-ingester` wall clock). They are run-level, not per-batch — set them once here so a multi-batch run accumulates across every batch.

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
        THEME_LABEL=<theme_label for sub_question_refs[0] from the Step 0 map, or empty>,
        MARKET=<plan.json market — the run-level value read in Step 0, or empty>,
        PUBLISHER=<from candidates.json>,
        TITLE_HINT=<from candidates.json>,
        BATCH_OUTPUT_PATH=<batch_path>)
   ```

   `source-ingester` lives at `${CLAUDE_PLUGIN_ROOT}/agents/source-ingester.md` — dispatched via `Task`, not `Skill`.

   Resolve `THEME_LABEL` the **same way Step 4.2 resolves `--category`** (this source's `sub_question_refs[0]` → Step 0 `theme_label` map; omit / pass empty on a legacy plan with no `theme_label`). The ingester writes it into the page's `theme_label:` frontmatter — the authoritative, frontmatter-resident membership signal `sub_index.py` reads to group the source under its theme (so a curated root index no longer needs per-page bullets to carry membership), kept consistent with the `## <theme_label>` heading Step 4.2 files its index bullet under.

   `MARKET` is the **run-level** market (`plan.json::market`, read once in Step 0 — one value for the whole run, e.g. `dach`), passed identically to every ingester in the batch. The ingester writes it into the page's `market:` frontmatter — the geography sibling of `theme_label:` that the perspectives overlay's Where facet groups by. Pass empty on a legacy plan with no `market`; the field is then dropped and the page simply does not appear in the Where grouping.

3. **One wave per batch.** Issue all sources in the batch (`--batch-size`, default 25) as `source-ingester` dispatches in a **single message with multiple tool calls** so they fan out in one wave. Claude Code self-throttles the actual concurrency inside a single-message fan-out — dispatches beyond its internal ceiling queue and run as slots free, but all of them complete and return — so a wave of 25 is safe (the calibration is in Step 1.5 and `references/fan-out-concurrency.md`). The per-batch barrier is **not** a concurrency limiter; it exists only so the Step 3.4 merge stays incremental and re-runnable (a crashed wave re-runs from `ingested[]`). This mirrors the `knowledge-curate` one-wave precedent. Per-source contention is structurally impossible inside Step 3: each ingester writes a unique `wiki/sources/<slug>.md` (Step 1.2 + 1.4 guarantee slug uniqueness within the run) and its own per-source batch JSON (unique path). The cogni-wiki helpers (`wiki_index_update.py`, `backlink_audit.py`) only run in Step 4 after all ingesters in this batch have returned. Across batches, the Step 3.4 merge runs once per batch.

4. After all ingesters in this batch return, merge the per-source batch JSONs into `ingest-manifest.json`:
   - For each batch JSON file: on `ok: true` append to `ingested[]`; on `ok: false` / skipped append to `skipped[]` with the `reason`.
   - **Populate `sub_question_refs` on every `ingested[]` entry.** Prefer the envelope's own `sub_question_refs` when present; when absent (an older agent or a partial envelope), backfill from the Step 0 URL → `sub_question_refs[]` map (the `candidates.json` read kept around for Step 4). This field is load-bearing: `knowledge-compose`'s `coverage_report` filters `ingested[]` on it per sub-question, so an entry without it makes its source invisible to every sub-question's coverage — never append an `ingested[]` entry that lacks it.
   - **Retain the ingester-authored `summary`** on every `ingested[]` entry (append the full batch entry, which already carries it). Step 4's orchestrator reads `summary` from `ingest-manifest.json` (sanitizing it via `_knowledge_lib.sanitize_summary` before `wiki_index_update.py --summary`), so a dropped `summary` would leave the source's `wiki/index.md` one-liner empty — never strip it from the appended entry.
   - Dedup within each array by URL (covers cross-run re-merges — same URL ingested twice keeps the later entry).
   - **Accumulate the phase cost + slowest-agent duration as you read the batch JSONs** (for the Step 7 ledger record). Carry the two run-level accumulators initialised to 0 in the Step 0 pre-flight across all batches: `INGEST_COST_USD` += each batch result's `cost_estimate.estimated_usd` (every result, `ok: true` and skip — each ingester's `cost_estimate` now already bundles its `claim-extractor` sub-call's cost, so this single sum is the measured ingest spend, no separate extractor term), and `MAX_DURATION_MS` = `max(MAX_DURATION_MS, each result's duration_ms)` (the slowest single `source-ingester` wall clock across the whole phase). A pre-`duration_ms` / pre-bundled-cost envelope (older agent) contributes `0` to each — fail-soft, never abort the merge.
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
     # ... append batch entries to manifest["ingested"] / manifest["skipped"], dedup by URL;
     #     set entry["sub_question_refs"] on every ingested entry (envelope value,
     #     else the Step 0 URL -> sub_question_refs[] map from candidates.json) ...
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

### 4. Per-new-slug wiki integration (first-party orchestrator)

The deterministic downstream of ingest — applying curated backlinks, the per-slug
thematic index rows, the `entries_count` bumps, the question-node emission + reverse
links, the theme-lineage record, and the two sub-index renders — runs as **one
first-party orchestrator call**, not a model-managed shell loop. The orchestrator
(`scripts/knowledge-ingest-postprocess.py`) batches the existing vendored
subprocess calls from one parent; each child still takes `_wiki_lock` in its own
process and runs serially — **no deadlock, no vendored-engine edit** (the
acquire-once-then-shell-out shape is NOT used). It owns env-var passing internally
(slugs + summaries are read from `ingest-manifest.json`, never interpolated into a
command line) and computes `n_new` / `n_new_q` authoritatively in one place
(`action == "inserted"` only), removing the two fragility footguns the model loop
carried. The post-processing script budget is small (≈2.2s across ~21 slugs); the
dominant per-slug cost is the LLM backlink **curation** in Step 4.1 below, which
stays here in `SKILL.md` by design and cannot move into a stdlib script.

The orchestrator produces **byte-identical wiki output** vs the prior per-slug shell
loop on the same inputs — the same vendored scripts, in the same order, with the
same arguments.

#### 4.1. Per-new-slug backlink audit + curation (stays in `SKILL.md` — LLM-mediated)

For each entry in `ingested[]` written this run, in deterministic slug order (Step
3.5 has already dropped any integrity-quarantined slug from `ingested[]`, so a
contaminated page is never backlinked here):

1. **Audit.** Run the read-only audit to find sibling pages that textually reference
   this source:
   ```
   python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" \
       --wiki-root <WIKI_ROOT> \
       --new-page <slug> \
       --top 8 \
       --min-confidence medium
   ```
   Capture `data.candidates[]` (ranked sibling pages that textually reference this
   source).

2. **Curate a write-back plan.** For each candidate you judge a genuine relation
   (skip weak / coincidental term matches), author one `targets[]` entry whose
   `sentence` mentions the new source with a bare `[[<slug>]]` wikilink — appended as
   a short trailer (e.g. `"See also [[<slug>]] for ..."`) so the candidate page's
   verbatim body is not edited mid-text. The plan shape is
   `{"targets": [{"slug": "<target>", "sentence": "... [[<slug>]] ..."}, ...]}`; each
   `sentence` MUST contain `[[<slug>]]` or the apply step rejects that target. If you
   find no genuine relation for a slug, write **no plan file** for it (never invent a
   backlink).

3. **Persist the curated plan** to `<project_path>/.metadata/.backlink-plan.<slug>.json`
   (a plain `.metadata/` handoff, exactly the plan JSON above). The orchestrator
   reads these by convention and applies them with `backlink_audit.py --apply-plan -`
   (idempotent — skips a target already linking `[[<slug>]]`; fail-soft per target —
   per-target errors land in `data.failed[]`). A missing plan file means "no genuine
   relation found for this slug" and the orchestrator skips apply for it.

This audit→curate→persist step is the only per-slug work that stays model-driven —
the apply, index, count, and render are all the orchestrator's.

#### 4.2. Build the this-run slug list

Write the source slugs ingested **this run** (the per-new-slug set Step 4.1 iterated,
in deterministic order) to `<project_path>/.metadata/.ingest-new-slugs.json` as a
JSON array of slug strings. This is the structured hand-off that replaces the old
env-var-interpolated loop — the orchestrator reads each slug's summary +
`sub_question_refs[]` from `ingest-manifest.json` and resolves its index category
(`sub_question_refs[0]` → the Step 0 `theme_label` map, fallback `"Sources"`)
internally, so untrusted summary/slug text never reaches a command line.

#### 4.3. Run the orchestrator (one call)

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-ingest-postprocess.py" \
    --project-path "<project_path>" \
    --wiki-root "<WIKI_ROOT>" \
    --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS" \
    --knowledge-scripts-dir "${CLAUDE_PLUGIN_ROOT}/scripts" \
    --binding "<binding_path>" \
    --knowledge-root "<knowledge_root>" \
    --new-slugs "<project_path>/.metadata/.ingest-new-slugs.json" \
    --output-language "<plan.output_language>"
```

The orchestrator runs, in order, the deterministic Steps the per-slug loop used to:

- **apply** each `.backlink-plan.<slug>.json` (`backlink_audit.py --apply-plan -`);
- **index** each source under its `sub_question_refs[0]` `theme_label` heading
  (`wiki_index_update.py --summary <sanitize_summary(...)> --category <theme_label|Sources>
  --max-summary 240`), counting `n_new` on `action == "inserted"`;
- **bump** `entries_count` once by `n_new` (`config_bump.py`, gated on `n_new > 0`);
- **render** `wiki/sources/index.md` (`sub_index.py render --type sources`, gated on `n_new > 0`);
- **emit** the per-sub-question `type: question` nodes (`question-store.py emit
  --binding <binding>`) and persist `<project_path>/.metadata/question-manifest.json`
  (the phase handoff `knowledge-finalize` reads), capturing `questions[]`,
  `theme_bindings[]`, `skipped_no_findings[]`, `sources_unmapped[]`;
- **reverse-link** each question (`backlink_audit.py --apply-plan - --new-page
  <question-slug> --create-missing-heading`, the `## Research questions` heading on
  each answering source);
- **index** each question under its own `theme_label` heading (fallback
  `"Research questions"`), counting `n_new_q`; **bump** `entries_count` by `n_new_q`;
- **record** theme lineage (`knowledge-binding.py upsert-themes`, the single writer of
  `topic_lineage.covered_themes[]`, gated on a non-empty `theme_bindings[]`);
- **render** `wiki/questions/index.md` (`sub_index.py render --type questions`, gated
  on `n_new_q > 0`).

Each step is **fail-soft** exactly as the prior loop was — a helper failure never
rolls back an ingested page; the page, its claims, and any already-applied
backlink/index row are on disk. The orchestrator surfaces every per-step outcome in
its `data` envelope. The cogni-wiki `type: question` allowlist (schema_version
`0.0.7`) is required as before; an older wiki hard-fails in `wiki-health` until
upgraded.

Parse the orchestrator's JSON envelope and carry its `data` forward for Step 6's
summary (`n_new`, `n_new_q`, `backlinks_applied`/`backlinks_failed`,
`reverse_links_applied`/`reverse_links_failed`, `failed_index_updates`,
`sources_subindex`, `questions_subindex`, `themes_added`/`themes_updated`,
`sources_unmapped`, `skipped_no_findings`, `warnings`) and for Step 7's run-metrics.
On a structural `success: false` (missing manifest / unreadable JSON) the
post-processing could not run at all — surface the error; the ingested pages are
still on disk and a re-run re-attempts the integration.

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
- Questions sub-index: `✓ wiki/questions/index.md rendered` (or `⚠ questions sub-index render failed — <reason>; question nodes on disk`; or `unchanged` when `n_new_q == 0`) — from the Step 4.5.6 render call
- Theme lineage: `<themes_added>` new, `<themes_updated>` updated in `topic_lineage.covered_themes` (Step 4.5.5; omit the line when `theme_bindings[]` was empty)
- Cost: `$X.XX` (measured `INGEST_COST_USD` — sum of each ingester's `cost_estimate.estimated_usd`, which now bundles its `claim-extractor` sub-call)
- Max agent duration: `<MAX_DURATION_MS / 1000>s` (slowest single `source-ingester` wall clock — with the phase elapsed it makes the orchestrator serial tail directly readable in the run-metrics ledger)
- Next: `knowledge-compose` reads the populated `wiki/sources/*.md` + `ingest-manifest.json` to draft the report.

If `len(ingested) == 0` and `len(skipped) > 0`, emit a warning: "no new pages written this run — every fetched source was already in ingest-manifest.json or skipped; check the skipped breakdown".

### 7. Record run metrics (phase-exit ledger)

Persist this phase's timing + cost to `<project_path>/.metadata/run-metrics.json` so the run leaves a durable per-phase ledger (read by `knowledge-resume` / `knowledge-dashboard` / a perf study). Capture `PHASE_START=$(date -u +%FT%TZ)` at the top of this skill's run (Step 0); then at exit:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" record \
    --project-path "<project_path>" --phase ingest \
    --started-at "$PHASE_START" --ended-at "$(date -u +%FT%TZ)" \
    --agent-count <source-ingesters dispatched (+ any source-contradictors)> \
    --cost-usd <INGEST_COST_USD — the measured sum accumulated in Step 3.4> \
    --max-agent-duration-ms <MAX_DURATION_MS — the slowest source-ingester duration from Step 3.4>
```

`--cost-usd` is now the **measured** ingest spend (each ingester self-reports a `cost_estimate` that bundles its `claim-extractor` sub-call), not an orchestrator estimate; `--max-agent-duration-ms` lets `run-metrics.py report` show the serial tail directly (`serial_tail ≈ elapsed_s − max_agent_duration_ms/1000`). **Scope note:** `MAX_DURATION_MS` reflects the `source-ingester` wave only (the dominant ingest cost — the only agents that self-report `duration_ms`), while `--agent-count` is the full dispatch count **including** any Step 4.6 `source-contradictor`s; so on a run with a slow contradictor wave the recorded `max_agent_duration_ms` is a lower bound on the slowest agent, and the derived serial tail is correspondingly an upper bound. Fail-soft — a record failure never blocks the phase. Full contract: `${CLAUDE_PLUGIN_ROOT}/references/run-metrics-wiring.md`.

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

- `<WIKI_ROOT>/wiki/sources/<slug>.md` per fetched source (one file per `ingested[]` entry) — each now carrying its own authoritative `theme_label:` frontmatter (the resolved `THEME_LABEL`), the membership signal `sub_index.py` reads to group the source under its theme, plus (when `MARKET` resolved) a `market:` frontmatter signal (the run-level `plan.json::market`) the perspectives overlay's Where facet groups by.
- `<WIKI_ROOT>/wiki/questions/<slug>.md` per sub-question with ≥1 finding this run (Step 4.5) — `type: question`, body `## Findings` listing `- [[<source-slug>]]` per answering source. Requires the cogni-wiki `type: question` allowlist (schema_version `0.0.7`).
- `<WIKI_ROOT>/wiki/index.md` updated — each source filed under its sub-question's `## <theme_label>` category (falls back to `## Sources` for legacy plans); each question node filed under its sub-question's same `## <theme_label>` category alongside its answering sources (falls back to `## Research questions` when the plan has no `theme_label`); the wiki-setup seed placeholder is shed on the first real insert.
- `<WIKI_ROOT>/wiki/sources/index.md` re-rendered (Step 4, when `n_new > 0`) — the machine-owned sources sub-index, grouped by portal theme via `sub_index.py render --type sources`; narrator-authored `SOURCES-LEADIN` spans are carried forward verbatim.
- `<WIKI_ROOT>/wiki/questions/index.md` re-rendered (Step 4.5.6, when `n_new_q > 0`) — the machine-owned questions sub-index, grouped by `theme_label:` frontmatter via `sub_index.py render --type questions`; narrator-authored `QUESTIONS-LEADIN` spans are carried forward verbatim.
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
