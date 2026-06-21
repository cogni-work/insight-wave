# Retrieval-quality baseline (hit@k / MRR)

Committed baseline artifact for the read-only retrieval harness
(`scripts/retrieval-eval.py`), addressing review finding **F5** (MINOR hygiene)
and its scale-up follow-up. Before this, the only recorded engagement-level
baseline was an N=3 prose smoke sample living in PR/issue text — not versioned,
not reproducible. This artifact turns that into a durable, committed before/after
so the deferred retrieval redesign has a real reference point — now at a
statistically firmer **31 labelled queries**.

## Committed artifact

- **`references/retrieval-baseline.json`** — per-base and aggregate
  `hit@1 / hit@5 / MRR` at the labelled-query scale, plus per-query ranks,
  provenance (harness command, threshold, corpus paths), and run metadata.
- **`references/retrieval-eval-set-<base>.json`** — the committed labelled query
  set per base (the ground-truth that makes the baseline reproducible against the
  bases). Each holds the question-node-seeded queries plus the authored held-out
  queries with hand-validated `expected_slugs`.

## Headline numbers

Aggregate over **31 labelled queries** (12 question-node-seeded + 19 authored
held-out), query-weighted mean across the bound bases:

| Metric | Value |
|--------|-------|
| hit@1  | 0.5806 |
| hit@5  | 0.8065 |
| MRR    | 0.6909 |

Per-base:

| Base | n (seeded+authored) | hit@1 | hit@5 | MRR |
|------|---------------------|-------|-------|-----|
| `.alpha/eu-ai-act-sme` | 15 (6+9) | 0.6000 | 0.7333 | 0.6667 |
| `.alpha/perf-cra-2`    | 8 (3+5)  | 0.6250 | 0.8750 | 0.7396 |
| `.alpha/perf-cra`      | 8 (3+5)  | 0.5000 | 0.8750 | 0.6875 |

The 12-query seeded subset reproduces the prior baseline (e.g. `eu-ai-act-sme`
still 3/6 null on hit@5, the previously-recorded hit@5 = 0.50) — confirming
harness stability across the scale-up. The authored held-out queries shifted the
aggregate up because they target single-article facts (e.g. "prohibited practices
under Article 5", "Article 3 definitions") whose answering page is sharply
named, whereas the broad question-node themes span 10–12 expected sources and
rank less cleanly.

## Reproduction

Per base (the harness loads the committed labelled set; no `--reseed` needed):

```bash
python3 cogni-knowledge/scripts/retrieval-eval.py eval \
  --wiki-root .alpha/<base> \
  --eval-set cogni-knowledge/references/retrieval-eval-set-<base>.json \
  --out /tmp/<base>.json
```

Run for `eu-ai-act-sme`, `perf-cra-2`, and `perf-cra`, then aggregate by
query-weighted mean. `threshold` is the harness default `0.2`.

## Ground-truth authoring (held-out queries)

The 19 authored queries are **hand-authored, not fabricated**: each is a natural
question answerable from the bound base, and its `expected_slugs` were validated
against the corpus's descriptive, article-specific source titles (e.g. "Article
14: Human Oversight", "Artikel 99: Sanktionen") — the answering pages a domain
reader would expect retrieval to surface. The builder asserts every
`expected_slug` exists as a `wiki/sources/*.md` page before committing, so a
typo'd ground-truth slug fails loudly rather than silently scoring as a miss.
Genuine misses (e.g. the German "Sanktionen und Bußgelder" query ranks no
Article-99 page in the passing set) are kept as real signal, not patched away.

## Corpus provenance and reproducibility (resolved: Option 1)

The eval corpus is the bound alpha knowledge bases under `.alpha/`. **These are
gitignored local alpha data — they are NOT version-controlled in this repo.** The
committed numbers are therefore a *snapshot* measured against those bases; exact
reproduction requires the same `.alpha/` bases on disk.

The fixture-vs-snapshot decision the prior artifact deferred is now **settled as
Option 1 — accept the alpha-corpus snapshot** (maintainer decision, recorded on
PR #917). The two options were:

1. **Accept the alpha-corpus snapshot** (this artifact) — real EU-AI-Act / CRA
   retrieval quality on the live alpha bases; reproducible by holders of those
   bases. The committed `retrieval-eval-set-<base>.json` files document the
   labelled queries + ground truth so the *measurement* is inspectable in-repo
   even though the *corpus* is not.
2. **Commit a checked-in eval fixture** — a small in-repo wiki + labelled query
   set, fully reproducible by anyone, but at fixture scale and content (validates
   the harness end-to-end rather than measuring real-corpus quality).

Option 1 was chosen because the baseline's purpose is to detect regressions in
the *real* corpus across the redesign; a synthetic fixture would measure the
harness, not the quality the redesign aims to move. If a fully third-party-
reproducible fixture is wanted later, that authoring is separate work.

## Scale note

31 labelled queries meets the brief's aspired ~20-50 range, scaled up from the
prior complete-but-small 12-query corpus. Further scaling would mean authoring
additional held-out queries against the same bases (the source corpora hold
57 / 20 / 25 pages respectively, so headroom remains) or adding new bound bases
with labelled question nodes.
