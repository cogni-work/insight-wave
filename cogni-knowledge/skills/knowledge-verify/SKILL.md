---
name: knowledge-verify
description: "Phase 6 of the v0.1.0 inverted pipeline. Reads <project>/output/draft-vN.md + <project>/.metadata/citation-manifest.json, shards the citations and dispatches wiki-verifier in parallel (via verify-store.py) to score every citation against each cited page's pre_extracted_claims (zero network), then loops with revisor on unsupported deviations — capped at 2 iterations per references/inverted-pipeline.md Phase 6. Writes <project>/.metadata/verify-vN.json per round and (when the revisor fires) draft-v{N+1}.md plus a rewritten citation-manifest.json. The structural cost win versus cogni-claims (20–30 min verify → < 5 min). Use this skill whenever the user says 'verify the draft', 'phase 6 of the knowledge pipeline', 'knowledge verify', 'check the citations', or 'run the claim alignment'. After verify, M9 (knowledge-finalize) deposits the verified draft as a synthesis page."
allowed-tools: Read, Write, Bash, Task
---

# Knowledge Verify

Phase 6 of the v0.1.0 inverted pipeline. Reads `<project>/output/draft-vN.md` + `<project>/.metadata/citation-manifest.json`, dispatches `wiki-verifier` once per round to score every citation against each cited page's `pre_extracted_claims:`, and loops with `revisor` on `unsupported` deviations — capped at **2 revisor iterations** per `references/inverted-pipeline.md` Phase 6.

Verifier verdicts: `verbatim` / `paraphrase` (evidence-aligned) and `synthesis` (informational, for `claim_id: null` citations to synthesis pages) go to `verified[]`. Only `unsupported` goes to `deviations[]` — that is the revisor's trigger. The loop terminates either when `deviations[].verdict == "unsupported"` is empty OR when `revision_round == 2` is reached, whichever fires first.

This is the **zero-network claim-alignment gate**. The wiki has every source body verbatim under `wiki/sources/<slug>.md` with `pre_extracted_claims:` in frontmatter (M5/M6 wrote them at ingest time). The verifier does string-match scoring against those claims — no WebFetch, no re-extraction, no claims.json store.

`verify-vN.json` shape (written per round by `wiki-verifier`):

```json
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "revision_round": 0,
  "verified": [
    {"id": "cit-001", "draft_position": "02:03", "wiki_slug": "eu-ai-act-article-6", "claim_id": "clm-001", "verdict": "paraphrase"}
  ],
  "deviations": [
    {"id": "cit-023", "draft_position": "03:07", "wiki_slug": "bitkom-gpai-position", "claim_id": "clm-004", "verdict": "unsupported", "reason": "claim_text_misaligned", "note": "..."}
  ],
  "counts": {"verbatim": 4, "paraphrase": 28, "synthesis": 2, "unsupported": 3, "total": 37}
}
```

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 6 — `knowledge-verify`" and `references/claim-at-ingest.md` once to anchor on the contract.

## When to run

- `<project>/.metadata/citation-manifest.json` exists with non-empty `citations[]` (Phase 5 / `knowledge-compose` has run) AND a `draft-v*.md` exists at the manifest's `draft_version`.
- User explicitly invokes `/cogni-knowledge:knowledge-verify`.

## Never run when

- No `<project>/.metadata/citation-manifest.json` — offer `knowledge-compose` first.
- `citation-manifest.json::draft_version` does not match any existing `output/draft-v*.md` — the manifest is stale; offer `knowledge-compose` first.
- No `binding.json` at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--max-rounds` | No | Hard ceiling on revisor iterations. Default `2` (the Phase 6 contract). Lower values short-circuit the loop early; higher values are rejected (the 2-iteration cap is a structural property of the contract, not a tunable). |
| `--shard-size` | No | Citations per verifier shard for the Step 3.1 fan-out. Default `40` — calibrated so each shard's wall-clock lands under the 5-min C3 target (169 citations → ~5 parallel shards). A draft with ≤ `--shard-size` citations produces one shard (equivalent to single-dispatch). |
| `--dry-run` | No | Print the resolved inputs (WIKI_ROOT, DRAFT_VERSION, citation count, max-rounds, shard-size) without dispatching the verifier. |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break — no cogni-research, no cogni-claims):

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK=no`, abort with the standard missing-plugin message. The verifier itself never calls any cogni-wiki skill, but the binding integrity check requires the wiki to exist.

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-compose`). Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`.

Parse `data.binding.wiki_path` as `WIKI_ROOT`. Confirm `<WIKI_ROOT>/.cogni-wiki/config.json` exists; abort otherwise. Confirm `<WIKI_ROOT>/wiki/` exists.

**Project manifests.** Confirm both files exist; abort with the relevant offer otherwise:

- `<project_path>/.metadata/citation-manifest.json` — "no citation manifest — run knowledge-compose first"
- At least one `<project_path>/output/draft-v*.md` — "no draft on disk — run knowledge-compose first"

### 0.5 Resolve MAX_ROUNDS

Default `2`. If `--max-rounds` is passed:

- Integer 0–2 → use as-is.
- Integer ≥ 3 → abort with `"max-rounds capped at 2 — the structural contract is fixed; lower the value or remove the flag"`.
- Non-integer / negative → abort with `"max-rounds must be a non-negative integer ≤ 2"`.

`MAX_ROUNDS` is then referenced by Step 3.2's loop-termination decision. The 2-iteration cap is a structural property of `references/inverted-pipeline.md` Phase 6, not a tunable — higher values would silently blow the < 5 min cost target.

### 1. Resolve current draft version N

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PROJECT_PATH="<project_path>" \
python3 -c '
import os, re
from pathlib import Path
out = Path(os.environ["PROJECT_PATH"]) / "output"
existing = sorted(int(m.group(1)) for p in out.glob("draft-v*.md")
                  for m in [re.match(r"draft-v(\d+)\.md$", p.name)] if m)
print(existing[-1] if existing else 0)
'
```

N is the highest existing `draft-v*.md` integer. If the result is `0`, abort with "no draft on disk".

### 2. Confirm citation-manifest matches current draft

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
MANIFEST_PATH="<project_path>/.metadata/citation-manifest.json" \
EXPECTED_VERSION=<N> \
python3 -c '
import json, os, sys
from pathlib import Path
m = json.loads(Path(os.environ["MANIFEST_PATH"]).read_text(encoding="utf-8"))
schema = m.get("schema_version")
assert schema == "0.1.0", "bad schema: " + repr(schema)
manifest_v = m.get("draft_version")
expected_v = int(os.environ["EXPECTED_VERSION"])
assert manifest_v == expected_v, (
    "manifest draft_version=" + repr(manifest_v)
    + " but draft on disk is v" + str(expected_v)
)
# F22/#291: id + draft_sentence are required per entry since v0.0.28 but the
# schema_version stayed 0.1.0 (additive), so a pre-0.0.28 manifest slips the
# schema assert above. Reject it here rather than mass-drop every citation.
citations = m.get("citations", [])
stale = [i for i, c in enumerate(citations)
         if not isinstance(c, dict) or "id" not in c or "draft_sentence" not in c]
assert not stale, (
    "citation-manifest predates v0.0.28 (entries missing id/draft_sentence) "
    "— re-run knowledge-compose"
)
n_cites = len(citations)
assert n_cites > 0, "citation manifest has zero citations — nothing to verify"
print(n_cites)
'
```

If the schema/version assertion fires, abort with "citation manifest is stale — re-run knowledge-compose". If the pre-0.0.28 guard fires (entries missing `id`/`draft_sentence`), abort with "manifest predates v0.0.28 — re-run knowledge-compose". If the zero-citations assertion fires, abort with "the draft has no sourced citations — nothing to verify" (consistent with the non-empty-`citations[]` precondition in "When to run"; a zero-citation manifest would otherwise shard into nothing). The trailing print is captured as `INITIAL_CITATION_COUNT` for the final summary.

If `--dry-run`, print the resolved inputs and stop:

```
WIKI_ROOT=<wiki_root>
PROJECT_PATH=<project_path>
DRAFT_VERSION=<N>
INITIAL_CITATION_COUNT=<count>
MAX_ROUNDS=<resolved, default 2>
SHARD_SIZE=<resolved, default 40>
```

### 3. Verify-revise loop

Initialise `CURRENT_DRAFT_VERSION=N`, `REVISION_ROUND=0`, `TOTAL_PRUNED=0`. The loop body is one verifier dispatch followed by an optional revisor dispatch:

#### 3.1 Verify (pre-filter → fan out → parallel dispatch → merge)

Verification is embarrassingly parallel — each citation's verdict reads one cited page's `pre_extracted_claims` and one `draft_sentence`, with no cross-citation dependency. The pass has four stages: a deterministic substring **pre-filter** (zero LLM), then **shard** the remainder, dispatch one `wiki-verifier` per shard **in parallel**, then **merge**. (The composer and revisor stay single-dispatch — they need whole-draft coherence; only the verifier shards.)

**Round split (#305).** Re-verify is incremental after the first round:

- **Round 0** (`REVISION_ROUND == 0`): the candidate id-set is the **full** manifest. Merge with `--manifest` only.
- **Round ≥1**: the candidate id-set is `DELTA_IDS` — the ids the revisor actually changed, captured from its return in Step 3.3 (`action ∈ {rephrase, repoint}`). Drops were removed from the manifest and skips are byte-identical, so neither needs re-scoring. Merge with `--manifest` **and** `--carry-forward-from` so untouched verdicts fold in and the canonical file stays complete. This is sound because patch-in-place (revisor #305) keeps untouched `(draft_sentence, claim_id)` pairs byte-identical, so their verdict is guaranteed-identical.

Set `CANDIDATE_IDS` accordingly (round 0 → all; round ≥1 → `DELTA_IDS`). The `--only-ids <csv>` arguments below take the comma-joined `CANDIDATE_IDS`.

**(a) Pre-filter the candidates (deterministic, zero LLM).**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/verify-store.py prefilter \
    --manifest "<project_path>/.metadata/citation-manifest.json" \
    --wiki-root "<wiki_root>" \
    --draft-version <CURRENT_DRAFT_VERSION> \
    --out-dir "<project_path>/.metadata/verify-shards" \
    [--only-ids <CANDIDATE_IDS>]    # round ≥1 only; omit on round 0 (full manifest)
```

Omit `--only-ids` on round 0; pass it on round ≥1 (a rephrased sentence often becomes an exact substring match against the claim it was aligned to). Capture `data.matched_ids` (classified `verbatim` without a model call, written to the `verify-shard-prefilter-v<N>.json` fragment) and `data.remaining_ids`. The pre-filter is **fail-safe** — any page it cannot parse leaves its citations in `remaining_ids` (they fall through to the LLM), and it never emits a deviation or a drop. **If `remaining_ids` is empty**, skip (b) and (c) entirely and go straight to (d) merge — the prefilter fragment carries every verdict this round needs.

**(b) Shard the remaining ids.**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/verify-store.py shard \
    --manifest "<project_path>/.metadata/citation-manifest.json" \
    --draft-version <CURRENT_DRAFT_VERSION> \
    --shard-size <SHARD_SIZE> \
    --only-ids <remaining_ids from (a)> \
    --out-dir "<project_path>/.metadata/verify-shards"
```

`shard` runs **after** `prefilter` and preserves the prefilter fragment (its cleanup is scoped to numbered fragments). Capture `data.shard_count` and the `data.shards[]` rows — each carries a `citations_path` (hand to the verifier as `CITATIONS_PATH`) and a `verify_out_path` (hand it as `VERIFY_OUT_PATH`).

**(c) Dispatch N verifiers in parallel.** Emit **one assistant message containing all N `Task(wiki-verifier, …)` calls** (this is what makes them run concurrently — the whole point of the fan-out). For each row in `data.shards[]`:

```
Task(wiki-verifier,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<CURRENT_DRAFT_VERSION>,
     REVISION_ROUND=<REVISION_ROUND>,
     CITATIONS_PATH=<shards[i].citations_path>,
     VERIFY_OUT_PATH=<shards[i].verify_out_path>)
```

`wiki-verifier` lives at `${CLAUDE_PLUGIN_ROOT}/agents/wiki-verifier.md` — dispatched via `Task`, not `Skill`. Single-pass, zero-network — each instance reads the wiki and writes its own fragment to `VERIFY_OUT_PATH`. Parse each return envelope:

- `ok: true` → fragment written; proceed once all shards return.
- `ok: false, error: "manifest_mismatch"` → re-emit the stale-manifest abort message and stop (defence-in-depth; Step 2 should have caught this).
- `ok: false, error: "write_failed"` → surface verbatim; do not retry blindly (the verifier already retried once internally).

**(d) Merge into the canonical `verify-vN.json`.**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/verify-store.py merge \
    --shard-dir "<project_path>/.metadata/verify-shards" \
    --draft-version <CURRENT_DRAFT_VERSION> \
    --revision-round <REVISION_ROUND> \
    --manifest "<project_path>/.metadata/citation-manifest.json" \
    [--carry-forward-from "<project_path>/.metadata/verify-v<CURRENT_DRAFT_VERSION minus 1>.json"]  # round ≥1 only \
    --out "<project_path>/.metadata/verify-v<CURRENT_DRAFT_VERSION>.json"
```

`--manifest` is passed every round so conservation is against the **current manifest id-set** (the prefilter fragment + LLM fragments + — on round ≥1 — carry-forward must reconstruct exactly the manifest). On round ≥1 also pass `--carry-forward-from` pointing at the **prior** round's `verify-v<N-1>.json` so untouched verdicts fold in; the merged `verify-v<N>.json` is therefore **complete** (the shards shrank to the delta, the canonical file did not — `knowledge-finalize` Step 2 reads `counts`). `merge` errors if a shard fragment is missing or if a manifest id has no verdict; surface verbatim and **stop** rather than proceeding on partial verification. Then continue to 3.2 against the merged file. (A single-shard or prefilter-only round still goes through merge — one uniform code path.)

**C3 baseline:** the < 5 min target is **per-shard wall-clock** (max over shards), and incremental rounds shard only the delta, so round ≥1 is strictly cheaper than round 0.

#### 3.2 Inspect deviations

`sentence_not_in_draft` deviations are filtered out before counting: the revisor can only drop those manifest entries (revisor.md Phase 1 triage) — it cannot produce a prose fix — so they should not trigger a revisor dispatch. The orchestrator handles them inline at 3.2 step b below. Pruning keys on the stable `id` (the verifier echoes each manifest entry's `id` into its verdict), not on `draft_position` — which is now a best-effort locator and not safe to match on.

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
VERIFY_PATH="<project_path>/.metadata/verify-v<CURRENT_DRAFT_VERSION>.json" \
MANIFEST_PATH="<project_path>/.metadata/citation-manifest.json" \
python3 -c '
import json, os, sys
from pathlib import Path
v = json.loads(Path(os.environ["VERIFY_PATH"]).read_text(encoding="utf-8"))
deviations = v.get("deviations", [])
# (a) Repairable unsupported: anything with verdict=unsupported except
#     sentence_not_in_draft, which the revisor can only drop — handle those
#     inline at (b), do not dispatch.
repairable = [
    d for d in deviations
    if d.get("verdict") == "unsupported"
    and d.get("reason") != "sentence_not_in_draft"
]
stale_sentence = [
    d for d in deviations
    if d.get("verdict") == "unsupported"
    and d.get("reason") == "sentence_not_in_draft"
]
# (b) Prune stale-sentence entries from the citation manifest inline, by id.
#     The revisor would otherwise spend an entire dispatch just to drop these.
# Drop None ids first: a deviation that omitted its id would otherwise put
# None in the set and prune EVERY citation that also lacks an id.
stale_ids = {d.get("id") for d in stale_sentence if d.get("id") is not None}
if stale_ids:
    manifest = Path(os.environ["MANIFEST_PATH"])
    m = json.loads(manifest.read_text(encoding="utf-8"))
    m["citations"] = [c for c in m.get("citations", []) if c.get("id") not in stale_ids]
    # Atomic rewrite (temp + os.replace) — matches the rest of the pipeline;
    # an interrupted write must not truncate the canonical manifest.
    tmp = manifest.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(m, indent=2, ensure_ascii=False), encoding="utf-8")
    os.replace(tmp, manifest)
print(json.dumps({"repairable": len(repairable), "stale_sentence": len(stale_sentence)}))
'
```

The trailing print captures both counts. `UNSUPPORTED_COUNT = repairable` (the dispatch trigger); `STALE_SENTENCE_COUNT = stale_sentence` (pruned inline). **Now accumulate it:** `TOTAL_PRUNED = TOTAL_PRUNED + STALE_SENTENCE_COUNT` (it was initialised to 0 at Step 3, and this prune step runs every round before the termination check, so the running total is correct whether the loop ends at round 0 or after revising). The §6 summary surfaces `TOTAL_PRUNED` so the operator can see why the authoritative manifest count shrank.

If `UNSUPPORTED_COUNT == 0` → loop terminates SUCCESS. Skip to Step 4.

If `UNSUPPORTED_COUNT > 0` AND `REVISION_ROUND >= MAX_ROUNDS` → loop terminates EXHAUSTED. Skip to Step 4 with a `⚠ Loop exhausted` warning for the final summary; the operator decides whether to ship the draft anyway or invoke M9 against the highest verify-vN.

If `UNSUPPORTED_COUNT > 0` AND `REVISION_ROUND < MAX_ROUNDS` → continue to 3.3.

#### 3.3 Dispatch revisor (single Task call per round)

**Pre-create the draft substrate (#305).** The revisor now **patches in place** rather than regenerating the draft, so the orchestrator first copies the verified draft to the new version:

```
NEW_DRAFT_VERSION=$((CURRENT_DRAFT_VERSION + 1))
cp "<project_path>/output/draft-v<CURRENT_DRAFT_VERSION>.md" \
   "<project_path>/output/draft-v<NEW_DRAFT_VERSION>.md"
```

This `cp` is what guarantees every sentence the revisor does **not** touch is byte-identical across versions — the precondition for Step 3.1's round-≥1 carry-forward. Then dispatch:

```
Task(revisor,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<CURRENT_DRAFT_VERSION>,
     NEW_DRAFT_VERSION=<NEW_DRAFT_VERSION>)
```

`revisor` lives at `${CLAUDE_PLUGIN_ROOT}/agents/revisor.md` — dispatched via `Task`, not `Skill`. Forked from cogni-research's revisor (drift acceptable per `references/inverted-pipeline.md` "What is no longer in the runtime path"). Zero-network — corrections come from claims already on the wiki. It `Edit`s only the changed sentences in the pre-created `draft-v<NEW_DRAFT_VERSION>.md`.

Parse the return envelope:

- `ok: true` → **derive `DELTA_IDS`** = the `id`s in `fixes_applied[]` whose `action ∈ {rephrase, repoint}` (drops are already removed from the manifest; skips are byte-identical — neither is re-scored). Set `CURRENT_DRAFT_VERSION=NEW_DRAFT_VERSION`, increment `REVISION_ROUND`, loop back to 3.1 (which will pre-filter + shard only `DELTA_IDS` and carry the rest forward).
- `ok: false, error: "verify_input_missing"` → surface verbatim; this is a defence-in-depth check, should not fire if 3.1 succeeded.
- `ok: false, error: "write_failed"` → surface verbatim and stop. The previous verify-vN.json is still the latest valid audit trail for the operator.

### 4. Verify outputs on disk

One Python subprocess validates the latest verify-vN.json (and, if the revisor ran, the latest draft + rewritten manifest). Paths go via env vars so spaces / apostrophes in project paths cannot break the Python literal:

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PROJECT_PATH="<project_path>" \
CURRENT_DRAFT_VERSION=<CURRENT_DRAFT_VERSION> \
REVISION_ROUND=<REVISION_ROUND> \
python3 -c '
import json, os, sys
from pathlib import Path
project = Path(os.environ["PROJECT_PATH"])
n = int(os.environ["CURRENT_DRAFT_VERSION"])
round_ = int(os.environ["REVISION_ROUND"])
verify = project / ".metadata" / ("verify-v" + str(n) + ".json")
assert verify.exists() and verify.stat().st_size > 0, "verify missing or empty: " + str(verify)
v = json.loads(verify.read_text(encoding="utf-8"))
verify_schema = v.get("schema_version")
assert verify_schema == "0.1.0", "bad verify schema: " + repr(verify_schema)
verify_v = v.get("draft_version")
assert verify_v == n, "verify draft_version mismatch: " + repr(verify_v) + " != " + str(n)
counts = v.get("counts", {})
total = counts.get("total")
expected = len(v.get("verified", [])) + len(v.get("deviations", []))
assert total == expected, "counts.total=" + repr(total) + " != verified+deviations=" + str(expected)
# Authoritative citation count (F24): len of the post-verify citation manifest for
# this draft version. counts.total is verdicts scored for draft-vN at the round
# start (before the §3.2 sentence_not_in_draft prune + any revisor drop), which is
# NOT the citation count — read the manifest itself for the pin.
manifest = project / ".metadata" / "citation-manifest.json"
m = json.loads(manifest.read_text(encoding="utf-8"))
manifest_citations = len(m.get("citations", []))
if round_ > 0:
    draft = project / "output" / ("draft-v" + str(n) + ".md")
    assert draft.exists() and draft.stat().st_size > 0, "draft missing or empty: " + str(draft)
    manifest_v = m.get("draft_version")
    assert manifest_v == n, "manifest draft_version mismatch after revisor: " + repr(manifest_v) + " != " + str(n)
print(json.dumps({"counts": counts, "manifest_citations": manifest_citations}))
'
```

The trailing JSON line is captured for the final summary: `counts` feeds the verdict-count line and `manifest_citations` feeds the authoritative citation count. On any structural failure, the subprocess exits non-zero with the assertion message; surface verbatim and stop — do not auto-retry.

### 5. Append wiki/log.md

Append one summary line (Bash `>>` append; `wiki/log.md` is append-only by cogni-wiki convention):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_VERBATIM=<counts.verbatim from final verify>
N_PARAPHRASE=<counts.paraphrase from final verify>
N_UNSUPPORTED=<counts.unsupported from final verify>
echo "## [${DATE_STAMP}] verify | project=${TOPIC} draft=v${CURRENT_DRAFT_VERSION} round=${REVISION_ROUND} verbatim=${N_VERBATIM} paraphrase=${N_PARAPHRASE} unsupported=${N_UNSUPPORTED}" >> "${WIKI_ROOT}/wiki/log.md"
```

Note on the `verify` prefix: cogni-wiki's log-format enum (per `cogni-wiki/CLAUDE.md` §"Key Conventions") does not yet list `verify`, but the same paragraph notes that "pre-v0.0.35 readers count unknown prefixes in their catch-all bucket without crashing" — `verify` is additive and safe. Same additive-prefix posture as M7's `compose` line. Formalising both prefixes lands in Slice 5/M9 when the dashboard gets rebuilt on the new manifests.

### 6. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Draft: `output/draft-v<CURRENT_DRAFT_VERSION>.md` (revisor rounds: `<REVISION_ROUND>` of `<MAX_ROUNDS>`)
- Citations: `<manifest_citations>` (authoritative count = `len(citation-manifest.json::citations)` for draft-v`<CURRENT_DRAFT_VERSION>`; `<TOTAL_PRUNED>` pruned as `sentence_not_in_draft`)
- Verdicts scored on draft-v`<CURRENT_DRAFT_VERSION>` (round `<REVISION_ROUND>`): verbatim=`<N>` paraphrase=`<N>` synthesis=`<N>` unsupported=`<N>` (total scored=`<N>`) — a per-round verdict tally, not the citation count
- Latest verify: `.metadata/verify-v<CURRENT_DRAFT_VERSION>.json`
- Cost: `$X.XXX` (sum of `cost_estimate.estimated_usd` across all verifier + revisor dispatches)
- Next: M9 (`knowledge-finalize`) deposits the verified draft as `wiki/syntheses/<slug>.md`. For v0.0.23, end here — `verify-v<N>.json` + an aligned draft is this slice's deliverable.

If the loop terminated EXHAUSTED (`UNSUPPORTED_COUNT > 0` AND `REVISION_ROUND == MAX_ROUNDS`), surface a `⚠ Loop exhausted — <N> unsupported citations remain after <MAX_ROUNDS> revisor rounds` warning line. Do not block — the operator decides whether to ship the partial draft, re-ingest more sources, or hand-edit.

If the verifier surfaced `missing_pages[]`, surface `⚠ Missing pages: <slug1>, <slug2>, …` so the operator knows the wiki was modified between compose and verify.

## Edge cases

- **Zero deviations on first verifier pass.** Loop terminates immediately after `REVISION_ROUND=0`. `CURRENT_DRAFT_VERSION` stays at N; the draft on disk is unchanged. `verify-vN.json` records the clean verdict for M9 to consume.
- **Verifier reports `manifest_mismatch`.** Step 3.1's error branch fires. The most common cause is the user editing the draft by hand between compose and verify (or running compose, then deleting + re-creating draft-vN.md). Direct the user to re-run `knowledge-compose`.
- **Revisor returns `fixes_summary.skip > 0`.** Some deviations were misclassified or had no fix path. Surface in the summary as `⚠ <N> deviations skipped by revisor — see verify-v<N>.json for details`. The next round's verifier will re-score; if those deviations persist, the operator gets a clean signal.
- **`--max-rounds 0`.** Operator wants verifier output only, no revision attempt. Loop runs Step 3.1 once, skips 3.3 unconditionally, terminates as EXHAUSTED if `UNSUPPORTED_COUNT > 0` or SUCCESS if `0`. Surface the value in the summary so it's clear no revision was attempted.
- **Concurrent edits.** Another session writing to `draft-vN.md` or the manifest mid-run isn't guarded against. Same posture as M7 — single-user-per-project assumption holds at v0.0.23.
- **Missing prior `verify-v<N-1>.json` on an incremental round (#305).** Round ≥1's `merge --carry-forward-from` needs the previous round's file. If it was manually deleted (so untouched verdicts cannot be carried), fall back to a **full re-shard** for that round: run Step 3.1 (a) `prefilter` over the **full** manifest (omit `--only-ids`), shard the remainder, dispatch, and `merge --manifest` **without** `--carry-forward-from`. Correctness is unchanged — only the wall-clock saving is forfeited for that one round.

## Out of scope

- Does NOT finalize the draft as a synthesis page — Phase 7 (`knowledge-finalize`, M9).
- Does NOT modify `binding.json` — Phase 7 appends the project entry.
- Does NOT re-run any earlier phase. A stale citation manifest aborts cleanly with a "re-run knowledge-compose" message.
- Does NOT support cross-page substitute-citation search in the revisor (deferred per `references/absorption-roadmap.md` Slice 4 notes).
- Does NOT support multilingual verification, executive density, or arc-aware revision — deferred (matches M7's Slice 3 deferrals).
- Does NOT re-fetch any URL. The whole point of the inverted pipeline is that verification is zero-network — re-introducing fetches would defeat the < 5 min cost target.

## Output

- `<project_path>/.metadata/verify-v<N>.json` per round (schema 0.1.0), assembled by `verify-store.py merge`. One file per draft version; the round number is recorded inside the file as `revision_round`.
- `<project_path>/.metadata/verify-shards/` — per-round shard inputs (`shard-NN-v<N>.json`), verifier fragments (`verify-shard-NN-v<N>.json`), and the deterministic pre-filter fragment (`verify-shard-prefilter-v<N>.json`). Intermediate fan-out artifacts; the merged `verify-v<N>.json` is the canonical output.
- `<project_path>/output/draft-v<N+K>.md` per revisor round (K = 1 or 2). The latest is the verified-aligned draft M9 consumes.
- `<project_path>/.metadata/citation-manifest.json` — rewritten in place by every revisor round to track the latest `draft_version`.
- One new `## [YYYY-MM-DD] verify | …` line in `<WIKI_ROOT>/wiki/log.md`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 6 contract (max-2-iterations cap, zero-network invariant)
- `${CLAUDE_PLUGIN_ROOT}/references/claim-at-ingest.md` — verdict definitions (verbatim / paraphrase / unsupported)
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — Slice 4 deferrals (cross-page substitute, multilingual, arcs)
- `${CLAUDE_PLUGIN_ROOT}/agents/wiki-verifier.md` — dispatched agent (verifier; sharded via `CITATIONS_PATH` / `VERIFY_OUT_PATH`)
- `${CLAUDE_PLUGIN_ROOT}/agents/revisor.md` — dispatched agent (revisor fork; repoint-before-drop)
- `${CLAUDE_PLUGIN_ROOT}/scripts/verify-store.py --help` — `shard` / `prefilter` / `merge` fan-out plumbing (incremental re-verify via `shard --only-ids` + `merge --manifest --carry-forward-from`, #305)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
