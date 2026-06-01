# Fixture: redundant-marker drop (#386)

Manual, agent-driven acceptance fixture for the **redundant-marker drop** precondition
added to `agents/revisor.md` (Phase 0/1/2) at v0.1.46 (#386), with the same-source
identical-marker doc clause at v0.1.47 (#404).

Unlike the other `tests/` files, this fixture is **not run by bash CI** — exercising it
requires dispatching the `revisor` and `wiki-verifier` LLM agents, which a stdlib bash
test cannot do. The committed CI guard for #386/#404 is the grep block in
`tests/test_verify_contract.sh`. This fixture is the *behavioral* counterpart: a
self-contained, re-runnable reproduction of the bug the precondition fixes, for use in
release bake-ins or when revisiting the revisor.

## The scenario

The body has two sentences:

| Sentence | Citations | Verifier verdict (round 0) |
|---|---|---|
| **S1** "…fines even without a preceding security incident… governance structures." | `cit-001` activeMind `clm-003` **+** `cit-002` BSI `clm-004` | `cit-001` **paraphrase (aligned)**, `cit-002` **unsupported** (`claim_not_found`) |
| **S2** "Essential and important entities across eighteen regulated sectors…" | `cit-003` BSI `clm-001` | `cit-003` **paraphrase (aligned)** (control) |

`cit-002` is a **redundant** second marker on S1 — the sentence is already covered by the
aligned sibling `cit-001`. The BSI page (`bsi-nis2-pflichten`) carries a deliberate
**near-miss repoint trap**, `clm-005` ("sanctions and penalties are set by national
authorities") — topically adjacent to S1's "fines" but **non-covering**. The pre-#386
revisor repointed the surplus marker into such a near-miss (and missed again), leaving a
residual `unsupported` at the 2-round cap (the NIS2 German bake-in capped at 98.9%).

S1 and S2 both cite the BSI page, so `cit-002` (S1) and `cit-003` (S2) render the
**byte-identical** marker `<sup>[2](https://www.bsi.bund.de/nis2-pflichten)</sup>` — this
also exercises the #404 same-source identical-marker handling (the drop must remove only
the S1 occurrence, via a sentence-level `Edit`).

## Expected behavior (with the precondition)

1. **Revisor** detects that S1's `cit-002` has an aligned same-sentence sibling
   (`cit-001 ∈ aligned_ids`) → **drops** the surplus marker rather than repointing into
   `clm-005`:
   - `fixes_summary: {repoint: 0, rephrase: 0, drop: 1, skip: 0}`
   - S1 keeps `[1]`; the surplus `[2]` is removed from S1 only; S2's `[2]` is untouched.
   - S1 prose is **not** rewritten as non-evidence-based (it stays evidenced via `cit-001`).
   - **Surviving-sibling bookkeeping:** `cit-001`'s `draft_sentence` is updated to the
     marker-removed text (else the next verify round prunes the sentence's only valid
     citation).
2. **Re-verify** of `draft-v2` reaches **0 unsupported** within the round cap
   (`{verbatim/paraphrase = 2, unsupported = 0, total = 2}`).

## Files (inputs only)

```
kb/wiki/sources/activemind-nis2.md      aligned page (clm-003 covers S1)
kb/wiki/sources/bsi-nis2-pflichten.md   scope/registration + clm-005 near-miss trap
project/output/draft-v1.md              the draft (S1 with two markers, S2 control)
project/.metadata/citation-manifest.json  draft_version 1, 3 citations
project/.metadata/verify-v1.json        round-0 verdicts (cit-002 unsupported)
```

The v2 artifacts (`draft-v2.md`, `citation-records-v2.txt`, `citation-manifest.json`
@ draft_version 2, `verify-v2.json`) are **generated** by the run — they are not committed.

> The two `project/.metadata/*.json` inputs are committed via `git add -f` — the repo
> `.gitignore` has a broad `**/.metadata/` rule for live run state, which this fixture's
> *template* inputs are deliberately exempt from. Re-runs happen in a scratch copy (below),
> so the committed copies are never mutated in place.

## How to re-run

Run against a **scratch copy** so the committed fixture stays pristine
(`.alpha/` is gitignored):

```bash
cd <repo-root>
SCRATCH=.alpha/redundant-marker-386
rm -rf "$SCRATCH" && mkdir -p "$SCRATCH"
cp -R cogni-knowledge/tests/fixtures/redundant-marker-386/* "$SCRATCH"/
PROJ="$PWD/$SCRATCH/project"
KB="$PWD/$SCRATCH/kb"

# Orchestrator pre-creates draft-v2 as a verbatim copy of draft-v1 (patch-in-place).
cp "$PROJ/output/draft-v1.md" "$PROJ/output/draft-v2.md"
```

Then dispatch the two agents (via the `Agent` tool / `subagent_type`), in order:

1. `cogni-knowledge:revisor` with
   `PROJECT_PATH=$PROJ  WIKI_ROOT=$KB  DRAFT_VERSION=1  NEW_DRAFT_VERSION=2`
   → expect `fixes_summary.drop == 1`, `repoint == 0`.

2. Rebuild the manifest from the revisor's records (orchestrator step):
   ```bash
   python3 cogni-knowledge/scripts/citation-store.py build \
     --records "$PROJ/.metadata/citation-records-v2.txt" \
     --draft   "$PROJ/output/draft-v2.md" \
     --out     "$PROJ/.metadata/citation-manifest.json" \
     --draft-version 2
   ```

3. `cogni-knowledge:wiki-verifier` with
   `PROJECT_PATH=$PROJ  WIKI_ROOT=$KB  DRAFT_VERSION=2`
   → expect `counts.unsupported == 0`.

Last validated: 2026-06-01, cogni-knowledge v0.1.46 (precondition) / v0.1.47 (#404 doc).
Result: revisor `drop=1 repoint=0`; re-verify `{verbatim:1, paraphrase:1, unsupported:0}`.
