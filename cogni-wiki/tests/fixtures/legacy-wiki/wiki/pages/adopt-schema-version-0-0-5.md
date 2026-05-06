---
id: adopt-schema-version-0-0-5
title: Adopt schema_version 0.0.5
type: decision
tags: [schema, migration]
created: 2026-04-01
updated: 2026-04-01
sources:
  - ../raw/decision-log.md
---

# Adopt schema_version 0.0.5

Decision: bump `schema_version` to `"0.0.5"` once per-type page directories
land. The migrator routes the bump through `config_bump.py --set-string` so
the lock contract is preserved.

References [[karpathy-pattern]] and [[per-type-directories]].
