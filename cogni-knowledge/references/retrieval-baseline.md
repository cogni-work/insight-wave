# Retrieval-quality baseline (hit@k / MRR)

Committed baseline artifact for the read-only retrieval harness
(`scripts/retrieval-eval.py`), addressing review finding **F5** (MINOR hygiene).
Before this, the only recorded engagement-level baseline was an N=3 prose smoke
sample living in PR/issue text — not versioned, not reproducible. This artifact
turns that into a durable, committed before/after so the deferred retrieval
redesign has a real reference point.

## Committed artifact

- **`references/retrieval-baseline.json`** — per-base and aggregate
  `hit@1 / hit@5 / MRR` at the labelled-query scale, plus per-query ranks,
  provenance (harness command, threshold, corpus paths), and run metadata.

## Headline numbers

Aggregate over **12 labelled queries** (the complete labelled corpus across the
bound bases):

| Metric | Value |
|--------|-------|
| hit@1  | 0.4166 |
| hit@5  | 0.7500 |
| MRR    | 0.5486 |

Per-base:

| Base | n | hit@1 | hit@5 | MRR |
|------|---|-------|-------|-----|
| `.alpha/eu-ai-act-sme` | 6 | 0.3333 | 0.5000 | 0.4167 |
| `.alpha/perf-cra-2`    | 3 | 0.6667 | 1.0000 | 0.7500 |
| `.alpha/perf-cra`      | 3 | 0.3333 | 1.0000 | 0.6111 |

(`eu-ai-act-sme` reproduces the previously-recorded hit@5 = 0.50, 3/6 null —
confirming harness stability.)

## Reproduction

Per base (the harness re-seeds the labelled set from each base's
`wiki/questions/*.md` `sources_answering:` ground truth):

```bash
python3 cogni-knowledge/scripts/retrieval-eval.py eval \
  --wiki-root .alpha/<base> --reseed --out /tmp/<base>.json
```

Run for `eu-ai-act-sme`, `perf-cra-2`, and `perf-cra`, then aggregate by
query-weighted mean. `threshold` is the harness default `0.2`.

## Corpus provenance and reproducibility caveat

The eval corpus is the bound alpha knowledge bases under `.alpha/`. **These are
gitignored local alpha data — they are NOT version-controlled in this repo.**
The committed numbers are therefore a *snapshot* measured against those bases;
exact reproduction requires the same `.alpha/` bases on disk. Only these three
bound bases qualify as eval corpora — they are the only ones carrying labelled
`wiki/questions/*.md` nodes with non-empty `sources_answering:` (the ground-truth
answering-page set). The other `.alpha/` bases predate the question-node feature
and yield no labels.

### OPEN QUESTION (for maintainer decision)

For a baseline that any third party can reproduce, the eval corpus must itself be
committed. The issue contemplated this ("decide and document the committed
path … or **a checked-in eval fixture**"). Two defensible options:

1. **Accept this alpha-corpus snapshot** (current artifact) — real EU-AI-Act /
   CRA retrieval quality on the live alpha bases; reproducible only by holders of
   those bases. Good enough as a private before/after for the redesign.
2. **Commit a checked-in eval fixture** — a small in-repo wiki + labelled query
   set, fully reproducible by anyone, but at fixture scale and content (validates
   the harness end-to-end rather than measuring real-corpus quality).

These serve different purposes; the choice is a maintainer call. This artifact
ships option 1; if option 2 is preferred, the fixture authoring is separate work.

## Scale note

12 labelled queries is the **complete** labelled corpus available today. The
brief aspired to ~20-50; reaching that requires *authoring held-out ground-truth
queries* (selecting valid expected source-page sets per new question — domain
expert work that would pollute the metric if fabricated). That scale-up is
tracked as a deferred follow-up issue.
