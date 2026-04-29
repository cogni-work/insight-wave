---
name: audit-arcs
description: |
  Audit cogni-research's local story-arc registry (`references/story-arcs.json`) against
  cogni-narrative's upstream arc definitions. Detects missing arcs (registry parity), element
  heading mismatches (EN+DE), proportion drift, and the appearance of new arcs upstream
  that haven't been mirrored downstream yet. Use whenever the user mentions "audit research
  arcs", "check research arcs", "narrative drift check", "compare research arcs upstream",
  "are research arcs up to date", "research arc contract check", "will arc-driven research
  break on this arc", or any question about whether `cogni-research/references/story-arcs.json`
  matches the cogni-narrative source of truth — even if they don't say "audit" explicitly.
  Also use proactively after cogni-narrative version bumps or after editing any per-arc
  `arc-definition.md` file in cogni-narrative.
allowed-tools: Read, Glob, Grep, Bash
---

# Research Arc Contract Audit

## Core Concept

cogni-narrative (upstream) defines story arcs — each with 4 named elements (plus an optional Hook), localized EN/DE headings, and section proportions. cogni-research (downstream) ships a local JSON registry (`references/story-arcs.json`) that subsets this upstream contract — only the arc IDs the writer can actually structure a research report around, with just the fields the writer and reviewer need (element IDs, heading_match prefixes, proportions, compatible report_types, supported languages, target_words bounds).

The local registry is duplicated — not symlinked or path-imported — for the same reason `cogni-copywriting/skills/copywriter/references/09-preservation-modes/` is duplicated: cross-plugin path lookups via `$CLAUDE_PLUGIN_ROOT/../cogni-narrative/...` are not used anywhere else in the insight-wave monorepo, and a runtime dependency between two independently-installable plugins is exactly what the marketplace abstraction is supposed to avoid. Duplication + audit is the proven pattern.

When cogni-narrative changes arc element headings, adjusts proportions, adds a new arc, or renames an existing arc, the local registry drifts. This skill detects that drift and produces an actionable report. It never auto-fixes — the human decides what to bring downstream and what to leave alone (e.g., an upstream arc may not be relevant to long-form research reports yet).

## Upstream Sources (read from cogni-narrative)

Resolve paths relative to the monorepo root. The monorepo root is the nearest ancestor directory containing both `cogni-narrative/` and `cogni-research/` as siblings.

| # | File | What it provides |
|---|------|-----------------|
| U1 | `cogni-narrative/skills/narrative/references/story-arc/arc-registry.md` | Master list of all arcs: arc_id, element short names, section proportions, detection signals |
| U2 | `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md` | Per-arc: full element headings EN+DE, word proportions, hook proportion, tolerance |

## Downstream Targets (files under audit)

| # | File | What it contains |
|---|------|-----------------|
| D1 | `cogni-research/references/story-arcs.json` | Local registry: per-arc element IDs, EN+DE headings, heading_match_prefixes, proportions, compatible report_types, supported languages, target_words bounds, upstream relpath pointer |

D1 is the only downstream file under audit — cogni-research's registry is intentionally minimal compared to cogni-copywriting's three-file footprint. Fewer files means fewer drift surfaces.

## Workflow

### Step 1: Resolve Paths

Find the monorepo root by walking up from the current working directory until you find a directory containing both `cogni-narrative/` and `cogni-research/` as children. Set:

```
MONO_ROOT = <detected root>
UPSTREAM_REGISTRY = ${MONO_ROOT}/cogni-narrative/skills/narrative/references/story-arc/arc-registry.md
UPSTREAM_ARC_DIR  = ${MONO_ROOT}/cogni-narrative/skills/narrative/references/story-arc
DOWNSTREAM_JSON   = ${MONO_ROOT}/cogni-research/references/story-arcs.json
```

Read the upstream registry and the downstream JSON. If `UPSTREAM_REGISTRY` is missing, abort with an error — the contract source is unavailable. If `DOWNSTREAM_JSON` is missing, flag it as a CRITICAL finding and stop (no point checking element-level drift if the file isn't there).

### Step 2: Extract Upstream Contract

From **arc-registry.md** (U1), parse the Quick Reference section to build the master arc list. List every arc directory under `${UPSTREAM_ARC_DIR}` (each arc has its own subdirectory with an `arc-definition.md`).

For each upstream arc_id, read `{arc-id}/arc-definition.md` (U2) and extract:

- **Elements** — the ordered list of element short names (e.g., `["Hook", "Why Change", "Why Now", "Why You", "Why Pay"]`). Hook is optional and treated as a non-H2 element folded into the first non-hook element's budget.
- **EN headings** — full `##` heading text per element (e.g., `Why Change: The Unconsidered Need`).
- **DE headings** — German `##` heading text per element (e.g., `Warum Veränderung: Der unberücksichtigte Bedarf`).
- **Word proportions** — per-element fractional share (e.g., `{hook: 0.10, why_change: 0.27, why_now: 0.21, why_you: 0.27, why_pay: 0.15}`). Verify they sum to 1.0 (within 0.01 floating-point tolerance).
- **Tolerance** — proportion tolerance band (e.g., `+/-10%`).

### Step 3: Extract Downstream State

From **story-arcs.json** (D1), extract per arc_id:

- The element list (from `arcs[arc_id].elements[]`) — element IDs, EN/DE headings, heading_match_prefixes, proportions, is_hook flag.
- `compatible_report_types`, `supported_languages`, `min_target_words`, `max_target_words`, `tolerance`.
- `upstream_arc_definition_relpath` (for cross-checking which upstream file this entry mirrors).
- `_last_synced_at` from the top-level metadata.

Note which arc_ids are present, which are absent, and (if any) which arc_ids the JSON declares with `dynamic_elements: true` (e.g., `standard-research`) — those are local-only entries that have no upstream counterpart and are exempt from element-level checks.

### Step 4: Run Audit Checks

Execute checks A1–A4 in order. For each finding, record:

| Field | Description |
|-------|-------------|
| check_id | A1–A4 |
| severity | CRITICAL, HIGH, MEDIUM, or INFO |
| arc_id | Affected arc |
| finding | What is wrong |
| expected | What the correct value should be (from upstream) |

#### A1: Arc Coverage (INFO when downstream is a strict subset; CRITICAL on missing-from-downstream-but-listed-upstream-and-cogni-research-explicitly-claims-it)

cogni-research intentionally ships a *subset* of upstream arcs (v1 ships only `corporate-visions` from the upstream catalog). Missing-arc findings are therefore not automatically critical — most of the time, an arc upstream that isn't downstream is a deliberate v2 candidate, not a bug.

Apply this rule:

- If an arc appears in `${UPSTREAM_ARC_DIR}` but not in the downstream JSON: **INFO** finding ("Upstream arc `<id>` is not yet mirrored in cogni-research/references/story-arcs.json. Add it to the v2 candidates list if/when long-form research reports should support it.").
- If a downstream arc has `upstream_arc_definition_relpath` set but the path doesn't exist upstream: **CRITICAL** ("Downstream arc `<id>` claims to mirror upstream path `<relpath>`, but that file no longer exists. The arc may have been renamed or removed upstream.").
- If a downstream arc has `dynamic_elements: true` (the `standard-research` exemption pattern), skip A1 entirely — it's a local-only construct.

#### A2: Element Heading Match (HIGH)

For each arc present in **both** upstream and downstream:

- Compare the 4 (or 5, including hook) element headings in the downstream JSON's `elements[]` array against the canonical headings from the upstream `arc-definition.md`.
- Match by element ID position (first non-hook element to first, second to second, etc.) — not by string equality, because the downstream JSON uses snake_case IDs (`why_change`) while upstream uses display names (`Why Change`).
- For each element, compare:
  - `heading_en` against upstream EN heading — exact string match (case- and whitespace-sensitive)
  - `heading_de` against upstream DE heading — exact string match
  - `heading_match_prefix_en` and `heading_match_prefix_de` — verify they are valid prefixes of the matching `heading_en` / `heading_de` strings (case-insensitive `startswith()`)
- Heading mismatch: **HIGH** severity. State expected vs actual. The reviewer's Arc-Structural Gate matches by `heading_match_prefix_*`, so a stale prefix means the gate would silently miss real arc-coverage failures.

#### A3: Proportion Drift (MEDIUM/HIGH)

For each arc present in both upstream and downstream:

- For each element, compute `drift = |downstream.proportion − upstream.proportion|` in absolute percentage points (e.g., upstream 0.27, downstream 0.30 → drift 0.03 = 3 percentage points).
- Apply tiered severity:
  - `drift < 0.01` (less than 1pp) → no finding
  - `0.01 ≤ drift < 0.03` (1–3pp) → **INFO** finding
  - `0.03 ≤ drift < 0.05` (3–5pp) → **MEDIUM**
  - `drift ≥ 0.05` (5pp or more) → **HIGH** — proportions this far apart change the rhetorical pacing of the arc and the reviewer's Arc-Structural Gate would either incorrectly accept (if downstream drifted too generous) or reject (if too strict) on a draft that obeys the upstream contract.
- Also verify the downstream tolerance field (`tolerance`) hasn't drifted from the upstream tolerance — same severity tiers apply (1pp INFO / 3pp MEDIUM / 5pp HIGH).

#### A4: New-arc Detection (CRITICAL when explicitly listed in downstream as missing)

Because A1 already catches missing-from-downstream as INFO, A4 specifically catches the failure mode where the downstream JSON has been *partially* updated — e.g., a developer added a new arc directory upstream and updated the registry's plumbing, but forgot to add the per-arc element block:

- For each arc_id that A1 flagged as missing-from-downstream, determine the upstream file's last-modified date via `git log -1 --format=%cs -- "${UPSTREAM_ARC_DIR}/${arc_id}/arc-definition.md"` (committer date, ISO short form `YYYY-MM-DD`). Compare against the downstream `_last_synced_at` field (same ISO short form). If the upstream date is **newer**, escalate the A1 INFO to **CRITICAL** ("Upstream arc `<id>` was added/modified on `<upstream-date>`, after the last sync `<sync-date>` — review and decide whether to mirror it before shipping"). If `git log` fails (e.g., the file is untracked or the audit runs outside a git checkout), fall back to the file's mtime via `stat -f %Sm -t %Y-%m-%d "${UPSTREAM_ARC_DIR}/${arc_id}/arc-definition.md"` on macOS or `date -r "<file>" +%Y-%m-%d` on Linux. Same comparison rule applies.
- Also flag any downstream arc whose entry has empty/null `elements[]` while its upstream counterpart has non-empty elements — that's a half-finished sync.

### Step 5: Generate Report

Output the report directly (do not write to file). Use this structure:

```markdown
# Research Arc Contract Audit Report

**Date:** {today ISO}
**cogni-narrative version:** {read from cogni-narrative/.claude-plugin/plugin.json}
**story-arcs.json _last_synced_at:** {date}
**Arcs upstream:** {count}
**Arcs downstream:** {count} ({count of dynamic_elements:true} local-only)

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {n} |
| HIGH     | {n} |
| MEDIUM   | {n} |
| INFO     | {n} |

## Findings

### A1: Arc Coverage

{Table showing each upstream arc's presence in downstream JSON, with status}

### A2-A4: {Per-check findings}

{For each finding: severity badge, arc_id, what's wrong, what it should be, the upstream relpath the diff was measured against}

## Recommended Actions

{Ordered list: CRITICAL first, then HIGH, then MEDIUM, then INFO. Each action states the JSON path to edit (e.g., `arcs.corporate-visions.elements[1].heading_de`) and the specific value to set.}
```

### Step 6: Summary Line

End with a single summary line:

```
Audit complete: X findings (Y CRITICAL, Z HIGH, W MEDIUM, V INFO)
```

If CRITICAL findings exist, add: "Immediate action recommended — arc-driven research reports may produce structurally invalid or stale-named drafts."

If only INFO findings exist (the common steady-state case), add: "All mirrored arcs are in sync. Some upstream arcs are not yet mirrored — see A1 for v2 candidates."
