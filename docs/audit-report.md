# Documentation Drift Report

Generated: 2026-04-15
Repo: /Users/stephandehaas/GitHub/dev/insight-wave

> **Note:** Historical drift snapshot from the date above. It predates the current 13-plugin ecosystem — cogni-research (this run's row removed), cogni-consulting, and cogni-wiki have since been retired/removed, and cogni-consult + cogni-knowledge were added. Run a fresh `doc-audit all` to regenerate against the live plugin set.

## Repository-Level

| Check | Verdict | Detail |
|-------|---------|--------|
| Root README (Check 12) | OK | All signals pass — plugin table matches marketplace (14/14), diagram + SVG present, commercial tone within zones, Security & compliance and MCP servers subsections present, all 6 workflow guides linked from root |
| Deploy Data Freshness (Check 10d) | OK | `deploy-data.json` researched 2026-04-04 (10 days ago, well under 90-day threshold); `deploy-guide.md` companion present |
| Known Issues Registry (Check 11) | OK | `known-issues.json` and `known-issues.md` both present in cogni-docs references |

## Summary (Per-Plugin)

| Plugin | Components | Architecture | Descriptions | Dependencies | plugin.json | CLAUDE.md | Messaging | docs/ | Commercial | Doc Logic | Known Issues | Maturity | Overall |
|--------|-----------|--------------|-------------|-------------|-------------|-----------|-----------|-------|------------|-----------|--------------|----------|---------|
| cogni-claims | OK | OK | OK | OK | OK | OK | WEAK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-consulting | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-copywriting | OK | OK | OK | OK | OK | OK | OK | DRIFT | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-help | OK | OK | OK | OK | OK | OK | OK | DRIFT | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-marketing | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-narrative | OK | OK | OK | OK | OK | OK | WEAK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-portfolio | OK | DRIFT | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-sales | DRIFT | DRIFT | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-trends | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-visual | OK | DRIFT | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-website | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |
| cogni-wiki | OK | OK | OK | DRIFT | OK | OK | OK | OK | OK | OK | OK | OK | NEEDS UPDATE |
| cogni-workspace | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK | OK |

**Overall: NEEDS UPDATE** — 8 of 14 plugins drifted; repository-level checks all OK.

---

## cogni-claims

### Power Messaging
- WEAK: MEANS bullet 3 ("Keep a paper trail.") has no quantifier — add a count, time unit, or before/after measure

## cogni-copywriting

### docs/
- DRIFT: Cross-plugin dependency `cogni-narrative` documented in Dependencies table but no workflow guide in `docs/workflows/` covers the cogni-copywriting ↔ cogni-narrative connection (`content-pipeline.md` and `research-to-report.md` mention cogni-copywriting but not cogni-narrative; `portfolio-to-pitch.md` mentions cogni-narrative but not cogni-copywriting)

## cogni-help

### docs/
- DRIFT: stale plugin guide — guide lists 5 skills, current count is 7 (missing: `course-deck`, `cogni-issues`)

## cogni-narrative

### Power Messaging
- WEAK: Generic IS — title paragraph opens with "A Claude Cowork plugin that..." with no named methodology or ecosystem positioning (e.g., "story arc engine for the insight-wave pipeline between research and visual delivery")

## cogni-portfolio

### Architecture Tree Drift
- DRIFT: Wrong version annotation — README architecture tree says `(v0.9.3)` but `plugin.json` version is `0.9.4`

## cogni-sales

### Component Table Drift
- DRIFT: Description stale — `pitch-review-assessor` row in Components table is truncated ("...and marketing di") and does not match agent description "Assess sales pitch quality from three stakeholder perspectives (buyer, sales, marketing)"

### Architecture Tree Drift
- DRIFT: Missing directory `skills/why-change/evals/` — exists on disk but not shown in Architecture tree
- DRIFT: Missing directory `skills/why-change/why-change-workspace/` — exists on disk but not shown in Architecture tree

## cogni-visual

### Architecture Tree Drift
- DRIFT: Wrong version annotation — README architecture tree says `Plugin manifest (v0.16.18)` but `plugin.json` version is `0.16.19`

## cogni-wiki

### Dependency Table Drift
- DRIFT: Missing `## Dependencies` section — README has no Dependencies table; auto-generated section expected even when no cross-plugin dependencies exist

---

## Recommended Next Steps

Per-plugin fixes (structural → messaging → docs), then repo-level:

1. **Fix structural drift first:**
   - `/doc-generate cogni-portfolio --section=architecture` (fix v0.9.3 → v0.9.4 annotation)
   - `/doc-generate cogni-visual --section=architecture` (fix v0.16.18 → v0.16.19 annotation)
   - `/doc-generate cogni-sales --section=components` (fix truncated `pitch-review-assessor` row)
   - `/doc-generate cogni-sales --section=architecture` (add `evals/`, `why-change-workspace/` dirs)
   - `/doc-generate cogni-wiki --section=dependencies` (add empty Dependencies section)

2. **Strengthen messaging:**
   - `/doc-power cogni-claims` (add quantifier to MEANS bullet 3)
   - `/doc-power cogni-narrative` (strengthen IS title paragraph with framework/ecosystem positioning)

3. **Generate user docs:**
   - `/doc-hub cogni-help` (regenerate plugin guide — 5 → 7 skills)
   - `/doc-hub cogni-copywriting` (add a workflow guide covering the cogni-copywriting ↔ cogni-narrative connection, or extend `content-pipeline.md` to include cogni-narrative)

Repository-level: all OK — no `/doc-readme-root`, `/doc-deploy refresh`, or `/doc-issues` remediation needed this run.
