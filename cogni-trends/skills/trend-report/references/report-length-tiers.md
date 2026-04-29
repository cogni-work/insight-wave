# Report Length Tiers

This reference defines the four length tiers and the budget formula the trend-report orchestrator uses to size theme prose, synthesis, and the executive summary.

## What `target_words` measures

`target_words` is **prose only** — it counts words in:

- the executive summary (`report-header.md`)
- each investment-theme section (`report-investment-theme-{id}.md`)
- bridge paragraphs between themes (`report-bridge-{N}-{N+1}.md`)
- the synthesis section (`report-synthesis.md`)

It deliberately **excludes** the claims registry / sources appendix (`report-claims-registry.md`). The registry is verifiable evidence, always rendered in full regardless of tier, and varies in size with claim count (data-driven, not author-controlled). Counting it would make tier math unstable across projects.

The reviewer in `verify-trend-report` measures prose the same way — by summing word counts of the per-section log files in `.logs/`, never reading the registry into the count.

## Tier table

Per-theme, synthesis, and exec values below are computed from the formula at `N=5` themes. The formula scales for any `N`; the 380-word per-theme floor binds when `target_words / N` is small (see "Worked examples" below).

| Tier | `target_words` (prose) | Per-theme (N=5) | Synthesis | Exec | ≈ Total with full registry | Use case |
|---|---|---|---|---|---|---|
| **standard** *(default)* | 4,000 | 664 | 520 | 160 | ~6,000 | Detailed research report — analog to cogni-research's `detailed` mode |
| **extended** | 5,500 | 913 | 715 | 220 | ~7,500 | Strategic deep dive |
| **comprehensive** | 7,000 | 1,168 | 910 | 250 | ~9,000 | Full-depth analysis |
| **maximum** | 8,000 | 1,342 | 1,040 | 250 | ~10,000 | Current pre-tier behavior — exhaustive |

The "≈ Total" column assumes a typical ~2,000-word claims registry (30–60 claims at ~50–60 words per row), plus `(N-1) × ~60` words of bridge prose (see "Bridges" below). Actual totals vary by claim volume.

## Per-element minimums (theme writer)

The writer agent applies the fixed Why-arc proportions (Hook 8% / WhyChange 25% / WhyNow 20% / WhyYou 30% / WhyPay 17%) to `THEME_TARGET_WORDS`, then clamps each element to its minimum:

| Element | Minimum |
|---|---|
| Hook | 30 |
| Why Change | 80 |
| Why Now | 80 |
| Why You | 100 |
| Why Pay | 90 |
| **Sum** | **380** |

When `THEME_TARGET_WORDS ≥ 380`, proportions dominate. When the budget is tighter (small target × many themes), the minimums dominate and the agent overshoots target slightly — this is intentional. The alternative is dropping arc elements, which would break verify-trend-report's quality gates (≥3 citations per theme, all 4 Why-* elements, specific cost estimates in Why Pay).

## Orchestrator formula

In Step 0.4e (Compute Length Budget) the orchestrator runs:

```
exec_words      = clamp(target_words * 0.04, 80, 250)
synthesis_words = clamp(target_words * 0.13, 350, 1300)
remaining       = target_words - exec_words - synthesis_words
per_theme_words = max(380, round(remaining / N))   # N = number of investment themes
```

`per_theme_words` becomes `THEME_TARGET_WORDS` for every dispatched investment-theme-writer agent. `synthesis_words` and `exec_words` are used by the orchestrator-written sections in Phase 2.

The claims registry is NOT in the formula — it is rendered separately in Step 2.5 and is excluded from word accounting.

### Bridges

Bridge paragraphs (one per consecutive theme pair, 2–4 sentences ≈ 50–80 words each — see Step 2.5b in `references/phase-2-strategic-themes.md`) are also NOT carved out of the formula. They contribute roughly `(N-1) × 60` words to total prose — about 240 words at `N=5`. The reviewer's 0.80–1.25 Completeness tolerance band is wider than the writer's per-section ±15% tolerance precisely to absorb this slack plus exec/synthesis clamp variance, so a report whose explicit budget sums to `target_words` will land slightly over but stay in-band. Treat the formula's output as a budget for the prose elements the orchestrator can directly steer; bridges sit on top within tolerance.

## Worked examples

**Default (standard, N=5):**
- target_words = 4,000
- exec = clamp(160, 80, 250) = 160
- synthesis = clamp(520, 350, 1300) = 520
- remaining = 4,000 − 160 − 520 = 3,320
- per_theme = max(380, 3,320/5) = 664
- Budgeted prose: 160 + 520 + 5 × 664 = 4,000 ✓
- + 4 bridges × ~60 = ~240 → actual prose ≈ 4,240 (ratio 1.06, within 0.80–1.25 band)

**Maximum (N=5):**
- target_words = 8,000
- exec = clamp(320, 80, 250) = 250
- synthesis = clamp(1,040, 350, 1300) = 1,040
- remaining = 8,000 − 250 − 1,040 = 6,710
- per_theme = max(380, 6,710/5) = 1,342
- Budgeted prose: 250 + 1,040 + 5 × 1,342 ≈ 7,960 ✓
- + 4 bridges × ~60 = ~240 → actual prose ≈ 8,200 (ratio 1.03, within band)

**Standard with many themes (N=7):**
- target_words = 4,000
- exec = 160, synthesis = 520, remaining = 3,320
- per_theme = max(380, 3,320/7) = 474
- Budgeted prose: 160 + 520 + 7 × 474 ≈ 3,998 ✓
- + 6 bridges × ~60 = ~360 → actual prose ≈ 4,358 (ratio 1.09, within band)

**Custom override (target_words=5,000, N=4):**
- exec = clamp(200, 80, 250) = 200
- synthesis = clamp(650, 350, 1300) = 650
- remaining = 5,000 − 200 − 650 = 4,150
- per_theme = max(380, 4,150/4) = 1,038
- Budgeted prose: 200 + 650 + 4 × 1,038 ≈ 5,002 ✓
- + 3 bridges × ~60 = ~180 → actual prose ≈ 5,182 (ratio 1.04, within band)

## Override semantics

A user can pass any integer `target_words` (within sensible bounds 2,500 ≤ target_words ≤ 12,000) to bypass tier defaults. The same formula applies. Below 2,500 the per-theme floor dominates and tier choice becomes meaningless; above 12,000 the report stops reading like a strategic narrative.

## Persistence

Tier and target are written to `tips-project.json`:

```json
{
  "report_tier": "standard",
  "report_target_words": 4000
}
```

Re-runs of `trend-report` and downstream `verify-trend-report` read these fields and skip the length question. The trend-scout output metadata also gets updated in Phase 4.1 so verify-trend-report's reviewer can read `report_target_words` from `.metadata/trend-scout-output.json`.

## Why this design

- **Per-theme word budget is the strongest single lever** — themes account for ~57% of prose in the current 10K-word reports.
- **Per-element minimums protect the Corporate Visions arc** — Why Pay can't carry "specific cost estimates and ROI ranges" below ~90 words, so we floor it instead of letting proportions silently break the gate.
- **Always render all themes** — preserves MECE coverage from value-modeler. Skipping themes would surprise users who expected "their" theme.
- **Always include the full claims registry** — verifiable evidence is non-negotiable. Excluding the registry from `target_words` keeps tier math stable across projects with different claim volumes.
- **Mirror cogni-research's API** — named tiers + `target_words` override is a familiar pattern to anyone who's used `research-report`'s `report_type` + `target_words` system.
