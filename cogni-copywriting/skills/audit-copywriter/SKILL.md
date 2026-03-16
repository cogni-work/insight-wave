---
name: audit-copywriter
description: |
  Audit cogni-copywriting's arc-preservation references against cogni-narrative's upstream
  arc definitions. Detects missing arcs, heading mismatches, word target drift, technique
  inconsistencies, localization gaps, and validation rule conflicts (like H2 count rules
  that would reject valid narratives). Use whenever the user mentions "audit arc sync",
  "check copywriter arcs", "narrative drift check", "compare arcs upstream", "are arcs
  up to date", "arc contract check", "will copywriter break on this arc", or any question
  about whether cogni-copywriting references match cogni-narrative definitions — even if
  they don't say "audit" explicitly. Also use proactively after cogni-narrative version bumps.
allowed-tools: Read, Glob, Grep, Bash
---

# Arc Contract Audit

## Core Concept

cogni-narrative (upstream) defines story arcs — each with 4 named elements, section proportions, technique assignments, and localized headings. cogni-copywriting (downstream) has an arc-preservation mode that polishes narratives without breaking their arc structure. The preservation mode relies on three reference files that must stay in sync with upstream definitions:

- **arc-preservation.md** — detection table mapping arc_id to 4 element headings, localized (DE) heading variants, and structural validation rules (H2 counts, heading hierarchy)
- **arc-technique-map.md** — per-arc sections with element-level technique assignments, Number Play variants, and word targets
- **00-index.md** — mode detection logic that lists which arc patterns trigger arc-aware mode

When cogni-narrative adds arcs, renames headings, adjusts proportions, changes technique assignments, or introduces new structural conventions (like message-driven headings), these downstream references drift. This skill detects that drift and produces an actionable report. It never auto-fixes — the human decides what to change.

## Upstream Sources (read from cogni-narrative)

Resolve paths relative to the monorepo root. The monorepo root is the nearest ancestor directory containing both `cogni-narrative/` and `cogni-copywriting/` as siblings.

| # | File | What it provides |
|---|------|-----------------|
| U1 | `cogni-narrative/skills/narrative/references/story-arc/arc-registry.md` | Master list of all arcs: arc_id, element short names, section proportions, detection signals |
| U2 | `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md` | Per-arc: full element headings, DE translations, word proportions, technique notes |
| U3 | `cogni-narrative/skills/narrative/references/language-templates.md` | Section "Insight Summary (Arc Element Headers)" — exact EN/DE `##` headers per arc |
| U4 | `cogni-narrative/skills/narrative/references/narrative-techniques/techniques-overview.md` | "Application by Arc Element" matrix — which techniques apply to which arc elements |

## Downstream Targets (files under audit)

| # | File | What it contains |
|---|------|-----------------|
| D1 | `cogni-copywriting/skills/copywriter/references/09-preservation-modes/arc-preservation.md` | Arc detection table, localized heading table, structure preservation rules, validation checklist |
| D2 | `cogni-copywriting/skills/copywriter/references/09-preservation-modes/arc-technique-map.md` | Per-arc `## Arc: {arc-id}` sections with technique table, element rules, word targets |
| D3 | `cogni-copywriting/skills/copywriter/references/00-index.md` | Mode detection logic — lists which arc patterns trigger arc-aware mode |

## Workflow

### Step 1: Resolve Paths

Find the monorepo root by walking up from the current working directory until you find a directory containing both `cogni-narrative/` and `cogni-copywriting/` as children. Set:

```
MONO_ROOT = <detected root>
UPSTREAM_REGISTRY = ${MONO_ROOT}/cogni-narrative/skills/narrative/references/story-arc/arc-registry.md
UPSTREAM_LANG     = ${MONO_ROOT}/cogni-narrative/skills/narrative/references/language-templates.md
UPSTREAM_TECH     = ${MONO_ROOT}/cogni-narrative/skills/narrative/references/narrative-techniques/techniques-overview.md
DOWNSTREAM_PRES   = ${MONO_ROOT}/cogni-copywriting/skills/copywriter/references/09-preservation-modes/arc-preservation.md
DOWNSTREAM_TECH   = ${MONO_ROOT}/cogni-copywriting/skills/copywriter/references/09-preservation-modes/arc-technique-map.md
DOWNSTREAM_INDEX  = ${MONO_ROOT}/cogni-copywriting/skills/copywriter/references/00-index.md
```

Read all 7 main files (U1, U3, U4, D1, D2, D3 plus per-arc U2 definitions). If any upstream file is missing, abort with an error — the contract source is unavailable. If a downstream file is missing, flag it as a CRITICAL finding and continue with remaining checks.

### Step 2: Extract Upstream Contract

From **arc-registry.md** (U1), parse the Quick Reference table to build the master arc list:

```
For each row: arc_id, element_short_names[4], section_proportions
```

For each arc_id, read `{arc-id}/arc-definition.md` (U2) and extract:
- Full element headings (EN) — the exact `##` header text
- Section proportions (if they differ from registry, prefer arc-definition as more detailed)

From **language-templates.md** (U3), find the "Insight Summary (Arc Element Headers)" section. For each arc, extract the EN/DE heading table. These are the canonical heading strings.

From **techniques-overview.md** (U4), find the "Application by Arc Element" table. For each technique row, note which arc elements it applies to.

### Step 3: Extract Downstream State

From **arc-preservation.md** (D1), extract:
- The H2 heading detection table (the markdown table mapping arc_id to 4 element columns)
- The localized headings table (DE translations)
- Note which arc_ids are present

From **arc-technique-map.md** (D2), extract:
- Which `## Arc: {arc-id}` sections exist
- For each section, the technique table: Element | Heading | Primary Technique | Number Play Variant | Word Target
- Whether the "Word Target" column uses absolute ranges (e.g., "400-500") or proportional percentages (e.g., "27%")
- The Post-Polish Validation section's tolerance rules (e.g., "+/-50 words" vs "+/-10% of proportional midpoint")

From **00-index.md** (D3), extract:
- The list of arc patterns that trigger arc-aware mode (look for the enumeration of arc IDs in the mode detection logic)

### Step 4: Run Audit Checks

Execute checks C1-C8 in order. For each finding, record:

| Field | Description |
|-------|-------------|
| check_id | C1-C8 |
| severity | CRITICAL, HIGH, MEDIUM, or INFO |
| file_to_fix | Downstream file path (relative to monorepo root) |
| finding | What is wrong |
| expected | What the correct value should be (from upstream) |

#### C1: Arc Coverage (CRITICAL)

For each arc_id in the upstream registry:
- Check if it appears in arc-preservation.md's detection table (D1). If missing: CRITICAL.
- Check if arc-technique-map.md has a `## Arc: {arc-id}` section (D2). If missing: CRITICAL.
- Check if 00-index.md's mode detection list includes this arc (D3). If missing: HIGH.

This is the most important check. A missing arc means the copywriter will either skip arc-aware mode entirely (if it cannot detect the arc) or polish without element-specific technique guidance (if detection works but no technique section exists). A missing entry in 00-index.md means the mode detection routing won't even consider this arc.

#### C2: Element Heading Match (HIGH)

For each arc present in both upstream and downstream:
- Compare the 4 element heading names in arc-preservation.md's detection table against the canonical headings from language-templates.md (U3).
- Element names must match. The detection table uses short names (e.g., "Why Change") while language-templates uses full headings (e.g., "Why Change: Unconsidered Needs"). Both forms are valid for detection — but the detection table must contain the correct short-name prefix.
- If a heading mismatch is found: HIGH severity. State expected vs actual.

#### C3: Localized Heading Match (HIGH)

For each arc present in the upstream language-templates.md:
- Check if arc-preservation.md has DE heading entries for this arc.
- If the DE headings are missing for an arc: HIGH.
- If DE headings exist but don't match language-templates.md: HIGH.

#### C4: Word Target Consistency (MEDIUM)

**Paradigm check first:** Determine whether the upstream arc-definitions use absolute word counts or proportional percentages. If upstream has migrated to proportional percentages (e.g., "27% of target") but the downstream technique map still uses absolute ranges (e.g., "400-500"), flag this as a systemic MEDIUM finding — the entire word target paradigm has shifted and all downstream targets are expressed in the old format, even if the numeric ranges happen to overlap. Also check if the Post-Polish Validation tolerance rule has changed (e.g., from "+/-50 words" to "+/-10% of proportional midpoint").

**Per-element check:** For each arc present in arc-technique-map.md:
- Compare the "Word Target" column values against arc-definition.md's section proportions.
- Compute expected word range: `proportion * default_total` (default_total = 1675 unless arc-definition specifies otherwise).
- If the technique map's word target range doesn't overlap with the expected range (allowing +/-50 tolerance): MEDIUM.
- Even if ranges overlap, note the paradigm mismatch if the upstream uses proportional and downstream uses absolute.

#### C5: Technique Assignment Consistency (MEDIUM)

For each arc present in arc-technique-map.md:
- Compare the "Primary Technique" per element against the "Application by Arc Element" matrix from techniques-overview.md.
- If the matrix assigns a technique to an element but the technique map doesn't mention it: MEDIUM.
- If the technique map assigns a technique that contradicts the matrix: HIGH.

#### C6: Section Proportion Consistency (MEDIUM)

For each arc in arc-technique-map.md:
- Derive implied proportions from word targets (word_target / sum_of_all_word_targets).
- Compare against arc-definition.md stated proportions.
- If any element drifts more than 5 percentage points: MEDIUM.

#### C7: Version Alignment (INFO)

- Read cogni-narrative's `.claude-plugin/plugin.json` for current version.
- Read arc-technique-map.md's frontmatter `last_updated` date.
- Run: `git log --oneline --since="{last_updated}" -- cogni-narrative/skills/narrative/references/story-arc/`
- If commits exist after the last_updated date: INFO. List the commits so the user can assess impact.

#### C8: Validation Rule Compatibility (HIGH)

Check whether the downstream validation rules in arc-preservation.md and arc-technique-map.md are structurally compatible with all upstream arcs — including arcs that may use different conventions than the original 5.

Specific checks:
- **H2 count rule:** arc-preservation.md may specify "H2 count — exactly 6 total (subtitle + 4 elements + bridge)." For each upstream arc, check if this rule holds. Some arcs (e.g., theme-thesis) use message-driven headings where H2/H3 usage differs from the standard pattern. If an arc's heading convention is incompatible with the downstream validation rule: HIGH. State which rule conflicts and what the arc actually produces.
- **Heading immutability rule:** arc-preservation.md requires "exact character match" for element heading texts. If an upstream arc uses dynamic/message-driven headings (where headings are content-derived, not static arc element labels), this validation rule would incorrectly flag valid documents as violations. If such a conflict exists: HIGH.
- **Word count tolerance rule:** arc-technique-map.md's Post-Polish Validation may specify "+/-50 words." If upstream has shifted to proportional tolerances (e.g., "+/-10% of proportional midpoint"), flag the mismatch: MEDIUM.

The point of this check is to catch cases where the downstream validation logic would *reject* a correctly-produced narrative — a false negative that breaks the polish pipeline silently.

### Step 5: Generate Report

Output the report directly (do not write to file). Use this structure:

```markdown
# Arc Contract Audit Report

**Date:** {today ISO}
**cogni-narrative version:** {version}
**arc-technique-map.md last_updated:** {date}
**Arcs in upstream registry:** {count}
**Arcs in downstream technique map:** {count}

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {n} |
| HIGH     | {n} |
| MEDIUM   | {n} |
| INFO     | {n} |

## Findings

### C1: Arc Coverage

{Table showing each arc's presence in all three downstream files (D1, D2, D3)}

### C2-C8: {Per-check findings}

{For each finding: severity badge, file to fix, what's wrong, what it should be}

## Recommended Actions

{Ordered list: CRITICAL first, then HIGH, then MEDIUM. Each action states the file to edit and the specific change to make.}
```

### Step 6: Summary Line

End with a single summary line:

```
Audit complete: X findings (Y CRITICAL, Z HIGH, W MEDIUM, V INFO)
```

If CRITICAL findings exist, add: "Immediate action recommended — missing arcs mean the copywriter cannot apply arc-aware polish for those narratives."
