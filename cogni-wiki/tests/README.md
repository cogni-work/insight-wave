# cogni-wiki tests

Stdlib-only smoke tests for the per-type-directory migration introduced in v0.0.28.

## Layout

```
tests/
├── README.md
├── test_migrate_and_smoke.sh    End-to-end migrator + every-consumer smoke
└── fixtures/
    └── legacy-wiki/             Flat wiki/pages/ fixture (schema_version 0.0.4)
        ├── SCHEMA.md
        ├── raw/decision-log.md
        ├── wiki/
        │   ├── index.md
        │   ├── log.md
        │   ├── overview.md
        │   └── pages/
        │       ├── karpathy-pattern.md          type: concept
        │       ├── per-type-directories.md      type: concept
        │       ├── adopt-schema-version-0-0-5.md  type: decision
        │       └── lint-2026-04-15.md           audit report (R3 exempt)
        └── .cogni-wiki/config.json
```

## Run

```sh
bash tests/test_migrate_and_smoke.sh
```

The runner copies the legacy fixture to a temp directory, asserts every
consumer hard-fails on the legacy layout, runs `migrate_layout.py --apply`,
asserts pages landed in the right per-type dirs and audit reports under
`wiki/audits/`, asserts `schema_version` was bumped to `0.0.5`, asserts the
re-run is idempotent, and finally runs health / lint / dashboard / status /
backlink / extract against the migrated wiki and checks each emits
`success: true`.

stdlib-only — no pytest, no pip. Bash 3.2 + Python 3.8+.

CI integration is deferred (cogni-wiki has no CI today).

## Contract tests

For pure LLM skills (no scripts to execute), regression coverage is limited to **SKILL.md content invariants** — grep-based assertions that catch the most likely failure mode (a path or flag silently disappears from the contract) without pretending to verify LLM behaviour.

| Test | Asserts |
|------|---------|
| `test_wiki_from_research_flags.sh` | The `--allow-wiki-source` / `--cycle-guard-cleared` flag pair lifts the `report_source ∈ {wiki, hybrid}` abort at Step 0(3) and Step 1d (v0.0.40); project-config read path is `.metadata/project-config.json` (post-v0.0.40, not the stale bare-filename form). |
| `test_wiki_query_wiki_root.sh` | `--wiki-root` flag exists in the parameter table; Step 1 skips the upward cwd walk and verifies `<wiki-root>/.cogni-wiki/config.json` when the flag is set (v0.0.41). |

```sh
bash tests/test_wiki_from_research_flags.sh
bash tests/test_wiki_query_wiki_root.sh
```

These do not assert anything about LLM-driven behaviour — only that the contract surface that orchestrators (`cogni-knowledge:knowledge-report` / `cogni-knowledge:knowledge-query`) depend on remains intact in SKILL.md.
