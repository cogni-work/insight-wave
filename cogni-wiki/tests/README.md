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
