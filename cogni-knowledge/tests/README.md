# cogni-knowledge tests

Stdlib-only smoke tests for cogni-knowledge primitives. Bash 3.2 + python3
stdlib, no pytest, no pip dependencies — matches the convention used by
`cogni-wiki/tests/`.

## Layout

```
tests/
├── README.md
├── fixtures/                              Shared test fixtures
│   └── redundant-marker-386/              Agent-driven (not bash-CI) acceptance
│                                          fixture for the #386 redundant-marker
│                                          drop — see its README to re-run the
│                                          revisor + wiki-verifier by hand
├── test_knowledge_setup_probe.sh          F1 + A4: probe handles dev-repo
│                                          and marketplace cache layouts,
│                                          present in every gating knowledge-*
│                                          skill (cogni-wiki-only after M11)
├── test_binding_project_path.sh           A2: project_path field + schema
│                                          0.0.2; legacy 0.0.1 compat
└── test_cycle_guard_*.sh                  A3: 6 fixture-driven scenarios
    (direct, transitive, depth_bound,      against scripts/cycle-guard.py
     clear, dry_run, not_applicable)
```

## Run

```sh
for t in tests/test_*.sh; do bash "$t" || exit 1; done
```

Each test creates its own tempdir, sets up the fixture in isolation, runs
the script under test, asserts the documented output shape, and cleans up
via `trap rm -rf "$WORK" EXIT`.

## Convention

- bash 3.2 + python3 stdlib only (no pytest, no pip).
- `set -eu` at the top; exit non-zero on any failure.
- Color helpers `red`/`green` for human-readable output.
- `assert_grep <pattern> <description>` for contract-level SKILL.md checks.
- Real Python harness (inline `python3 - <<PY ... PY` heredoc) for
  script-level assertions.
- Fixtures are minimal — only the files the test actually exercises.

## Contract tests (SKILL.md)

For pure LLM skills, regression coverage is **SKILL.md content invariants**
— grep-based assertions that catch the most likely failure mode (a path,
flag, or step silently disappears from the contract). These do not assert
LLM-driven behaviour, only that the contract surface remains intact.

`test_skill_contracts.sh` also carries the **M11 audit-grep**: a permanent
invariant that `skills/`, `scripts/`, and `agents/` contain zero references to
the archived `knowledge-research` / `knowledge-report` chain. It fails any PR
that re-introduces the legacy chain into the live runtime surface. (The
archived chain itself lives under `_archive/`, outside the live test glob.)

Phase 4.5 (`knowledge-distill`, #336) is covered by two files: `test_concept_store.sh`
exercises the actual `concept-store.py` (create / cross-run compounding / claim-id
namespacing / byte-stable re-run / foundation + no-sentinel skips), and
`test_distill_contract.sh` is the grep-based SKILL.md + agent contract guard.
`test_knowledge_lib.sh` covers the lifted tokenization primitives + `norm_key` /
`claim_similarity` / `parse_concept_records`.

Phase 4 Step 4.5 (`knowledge-ingest` per-sub-question nodes, #407) is covered by
`test_question_store.sh`, which executes the actual `question-store.py emit` against a
synthetic wiki + plan/candidates/manifest fixtures: one `wiki/questions/<slug>.md` per
sub-question with ≥1 finding, transliterated `theme_label` slug, zero-finding skip,
idempotent merge preserving the human `## Notes` tail, cross-type `-q` disambiguation,
and the legacy-plan `sq-NN` slug fallback.

## Maintenance note

Grep patterns assert exact layout (e.g. `| `--bare` | No |` for parameter
tables). Cosmetic reformats — column swap, extra column, switching from
`|`-pipe tables to a different structure — will trip these tests even when
the underlying contract is unchanged. When reformatting any covered
SKILL.md, update the patterns in the matching test script.

CI integration is deferred (cogni-knowledge has no CI today). Tests are
expected to be run pre-PR by the human author.
