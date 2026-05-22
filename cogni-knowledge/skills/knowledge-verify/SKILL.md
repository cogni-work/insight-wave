---
name: knowledge-verify
description: "Phase 6 of the v0.1.0 inverted pipeline. Reads <project>/output/draft-vN.md + <project>/.metadata/citation-manifest.json, dispatches wiki-verifier to score every citation against each cited page's pre_extracted_claims (zero network), and loops with revisor on unsupported deviations — capped at 2 iterations per references/inverted-pipeline.md Phase 6. Writes <project>/.metadata/verify-vN.json per round and (when the revisor fires) draft-v{N+1}.md plus a rewritten citation-manifest.json. The structural cost win versus cogni-claims (20–30 min verify → < 5 min). Use this skill whenever the user says 'verify the draft', 'phase 6 of the knowledge pipeline', 'knowledge verify', 'check the citations', or 'run the claim alignment'. After verify, M9 (knowledge-finalize) deposits the verified draft as a synthesis page."
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
    {"draft_position": "02:03", "wiki_slug": "eu-ai-act-article-6", "claim_id": "clm-001", "verdict": "paraphrase"}
  ],
  "deviations": [
    {"draft_position": "03:07", "wiki_slug": "bitkom-gpai-position", "claim_id": "clm-004", "verdict": "unsupported", "reason": "claim_text_misaligned", "note": "..."}
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
| `--dry-run` | No | Print the resolved inputs (WIKI_ROOT, DRAFT_VERSION, citation count, max-rounds) without dispatching the verifier. |

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
print(len(m.get("citations", [])))
'
```

If the assertion fires, abort with "citation manifest is stale — re-run knowledge-compose". The trailing print is captured as `INITIAL_CITATION_COUNT` for the final summary.

If `--dry-run`, print the resolved inputs and stop:

```
WIKI_ROOT=<wiki_root>
PROJECT_PATH=<project_path>
DRAFT_VERSION=<N>
INITIAL_CITATION_COUNT=<count>
MAX_ROUNDS=<resolved, default 2>
```

### 3. Verify-revise loop

Initialise `CURRENT_DRAFT_VERSION=N`, `REVISION_ROUND=0`. The loop body is one verifier dispatch followed by an optional revisor dispatch:

#### 3.1 Dispatch wiki-verifier (single Task call per round)

```
Task(wiki-verifier,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<CURRENT_DRAFT_VERSION>,
     REVISION_ROUND=<REVISION_ROUND>)
```

`wiki-verifier` lives at `${CLAUDE_PLUGIN_ROOT}/agents/wiki-verifier.md` — dispatched via `Task`, not `Skill`. Single-pass, zero-network — the agent reads the wiki itself and writes `verify-v{CURRENT_DRAFT_VERSION}.json`.

Parse the return envelope:

- `ok: true` → continue to 3.2.
- `ok: false, error: "manifest_mismatch"` → re-emit the stale-manifest abort message and stop (defence-in-depth; Step 2 should have caught this).
- `ok: false, error: "write_failed"` → surface verbatim; do not retry blindly (the verifier already retried once internally).

#### 3.2 Inspect deviations

`draft_position_out_of_range` deviations are filtered out before counting: the revisor can only drop those manifest entries (revisor.md Phase 1 triage) — it cannot produce a prose fix — so they should not trigger a revisor dispatch. The orchestrator handles them inline at 3.2 step b below.

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
VERIFY_PATH="<project_path>/.metadata/verify-v<CURRENT_DRAFT_VERSION>.json" \
MANIFEST_PATH="<project_path>/.metadata/citation-manifest.json" \
python3 -c '
import json, os, sys
from pathlib import Path
v = json.loads(Path(os.environ["VERIFY_PATH"]).read_text(encoding="utf-8"))
deviations = v.get("deviations", [])
# (a) Repairable unsupported: anything with verdict=unsupported except out-of-range,
#     which the revisor can only drop — handle those inline at (b), do not dispatch.
repairable = [
    d for d in deviations
    if d.get("verdict") == "unsupported"
    and d.get("reason") != "draft_position_out_of_range"
]
out_of_range = [
    d for d in deviations
    if d.get("verdict") == "unsupported"
    and d.get("reason") == "draft_position_out_of_range"
]
# (b) Prune out-of-range entries from the citation manifest inline. The revisor
#     would otherwise spend an entire dispatch just to drop these.
if out_of_range:
    manifest = Path(os.environ["MANIFEST_PATH"])
    m = json.loads(manifest.read_text(encoding="utf-8"))
    stale = {(d["draft_position"], d["wiki_slug"], d.get("claim_id")) for d in out_of_range}
    m["citations"] = [
        c for c in m.get("citations", [])
        if (c.get("draft_position"), c.get("wiki_slug"), c.get("claim_id")) not in stale
    ]
    manifest.write_text(json.dumps(m, indent=2, ensure_ascii=False), encoding="utf-8")
print(json.dumps({"repairable": len(repairable), "out_of_range": len(out_of_range)}))
'
```

The trailing print captures both counts. `UNSUPPORTED_COUNT = repairable` (the dispatch trigger); `OUT_OF_RANGE_COUNT = out_of_range` (pruned inline, surface in the final summary).

If `UNSUPPORTED_COUNT == 0` → loop terminates SUCCESS. Skip to Step 4.

If `UNSUPPORTED_COUNT > 0` AND `REVISION_ROUND >= MAX_ROUNDS` → loop terminates EXHAUSTED. Skip to Step 4 with a `⚠ Loop exhausted` warning for the final summary; the operator decides whether to ship the draft anyway or invoke M9 against the highest verify-vN.

If `UNSUPPORTED_COUNT > 0` AND `REVISION_ROUND < MAX_ROUNDS` → continue to 3.3.

#### 3.3 Dispatch revisor (single Task call per round)

```
NEW_DRAFT_VERSION=$((CURRENT_DRAFT_VERSION + 1))
Task(revisor,
     PROJECT_PATH=<project_path>,
     WIKI_ROOT=<wiki_root>,
     DRAFT_VERSION=<CURRENT_DRAFT_VERSION>,
     NEW_DRAFT_VERSION=<NEW_DRAFT_VERSION>)
```

`revisor` lives at `${CLAUDE_PLUGIN_ROOT}/agents/revisor.md` — dispatched via `Task`, not `Skill`. Forked from cogni-research's revisor (drift acceptable per `references/inverted-pipeline.md` "What is no longer in the runtime path"). Zero-network — corrections come from claims already on the wiki.

Parse the return envelope:

- `ok: true` → set `CURRENT_DRAFT_VERSION=NEW_DRAFT_VERSION`, increment `REVISION_ROUND`, loop back to 3.1.
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
if round_ > 0:
    draft = project / "output" / ("draft-v" + str(n) + ".md")
    manifest = project / ".metadata" / "citation-manifest.json"
    assert draft.exists() and draft.stat().st_size > 0, "draft missing or empty: " + str(draft)
    m = json.loads(manifest.read_text(encoding="utf-8"))
    manifest_v = m.get("draft_version")
    assert manifest_v == n, "manifest draft_version mismatch after revisor: " + repr(manifest_v) + " != " + str(n)
print(json.dumps(counts))
'
```

The trailing JSON line is captured for the final summary's verdict-count line. On any structural failure, the subprocess exits non-zero with the assertion message; surface verbatim and stop — do not auto-retry.

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
- Verdicts: verbatim=`<N>` paraphrase=`<N>` synthesis=`<N>` unsupported=`<N>` (total=`<N>`)
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

## Out of scope

- Does NOT finalize the draft as a synthesis page — Phase 7 (`knowledge-finalize`, M9).
- Does NOT modify `binding.json` — Phase 7 appends the project entry.
- Does NOT re-run any earlier phase. A stale citation manifest aborts cleanly with a "re-run knowledge-compose" message.
- Does NOT support cross-page substitute-citation search in the revisor (deferred per `references/absorption-roadmap.md` Slice 4 notes).
- Does NOT support multilingual verification, executive density, or arc-aware revision — deferred (matches M7's Slice 3 deferrals).
- Does NOT re-fetch any URL. The whole point of the inverted pipeline is that verification is zero-network — re-introducing fetches would defeat the < 5 min cost target.

## Output

- `<project_path>/.metadata/verify-v<N>.json` per round (schema 0.1.0). One file per draft version; the round number is recorded inside the file as `revision_round`.
- `<project_path>/output/draft-v<N+K>.md` per revisor round (K = 1 or 2). The latest is the verified-aligned draft M9 consumes.
- `<project_path>/.metadata/citation-manifest.json` — rewritten in place by every revisor round to track the latest `draft_version`.
- One new `## [YYYY-MM-DD] verify | …` line in `<WIKI_ROOT>/wiki/log.md`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 6 contract (max-2-iterations cap, zero-network invariant)
- `${CLAUDE_PLUGIN_ROOT}/references/claim-at-ingest.md` — verdict definitions (verbatim / paraphrase / unsupported)
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — Slice 4 deferrals (cross-page substitute, multilingual, arcs)
- `${CLAUDE_PLUGIN_ROOT}/agents/wiki-verifier.md` — dispatched agent (verifier)
- `${CLAUDE_PLUGIN_ROOT}/agents/revisor.md` — dispatched agent (revisor fork)
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
