# Report Length Tiers

This reference defines the four length tiers and the budget formula the trend-report orchestrator uses to size theme prose, synthesis, and the executive summary. Two formulas exist, one per Phase-2 flow:

- **Legacy flow** (`REPORT_ARC_ID ≠ smarter-service`): per-theme prose dominates; budget split is exec / themes / synthesis.
- **Smarter-service flow** (`REPORT_ARC_ID == smarter-service`): macro skeleton dominates; budget split is exec / dimension narratives / theme cases / synthesis (plus a small primer overhead).

The original tier table (`standard` / `extended` / `comprehensive` / `maximum`) and `target_words` override apply identically in both flows.

## What `target_words` measures

`target_words` is **prose only** — it counts words in:

**Legacy flow:**
- the executive summary (`report-header.md`)
- each investment-theme section (`report-investment-theme-{id}.md`)
- bridge paragraphs between themes (`report-bridge-{N}-{N+1}.md`)
- the synthesis section (`report-synthesis.md`)

**Smarter-service flow:**
- the executive summary (`report-header.md`)
- each macro section (`report-macro-section-{dimension}.md`) — includes both the dimension narrative AND the nested theme-case files concatenated by the composer
- the synthesis section (`report-synthesis.md`)
- the shared primer (`report-shared-primer.md`) is **internal** and excluded from the prose budget — it's never assembled into the final report

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

## Per-element minimums (legacy flow — theme writer)

The writer agent (in legacy `MICRO_ARC` mode) applies the fixed Why-arc proportions (Hook 8% / WhyChange 25% / WhyNow 20% / WhyYou 30% / WhyPay 17%) to `THEME_TARGET_WORDS`, then clamps each element to its minimum:

| Element | Minimum |
|---|---|
| Hook | 30 |
| Why Change | 80 |
| Why Now | 80 |
| Why You | 100 |
| Why Pay | 90 |
| **Sum** | **380** |

When `THEME_TARGET_WORDS ≥ 380`, proportions dominate. When the budget is tighter (small target × many themes), the minimums dominate and the agent overshoots target slightly — this is intentional. The alternative is dropping arc elements, which would break verify-trend-report's quality gates (≥3 citations per theme, all 4 Why-* elements, specific cost estimates in Why Pay).

## Per-element minimums (smarter-service flow — slim 3-beat theme case)

When the writer agent runs in `MICRO_ARC = "investment-case"` mode it produces three beats with these proportions and minimums applied to `THEME_CASE_TARGET_WORDS`:

| Beat | Proportion | Minimum |
|---|---|---|
| Stake | 25% | 80 |
| Move | 50% | 130 |
| Cost-of-Inaction | 25% | 80 |
| **Sum** | **100%** | **290** |

The dimension composer separately enforces a **per-dimension narrative floor of 250 words**. The composer also writes the H2 macro heading and any secondary-pole callouts, which are not budgeted (negligible word count).

## Orchestrator formula

### Legacy flow (default — non-smarter-service arcs)

In Step 0.4e (Compute Length Budget) the orchestrator runs:

```
exec_words      = clamp(target_words * 0.04, 80, 250)
synthesis_words = clamp(target_words * 0.13, 350, 1300)
remaining       = target_words - exec_words - synthesis_words
per_theme_words = max(380, round(remaining / N))   # N = number of investment themes
```

`per_theme_words` becomes `THEME_TARGET_WORDS` for every dispatched investment-theme-writer agent. `synthesis_words` and `exec_words` are used by the orchestrator-written sections in Phase 2.

### Smarter-service flow

When `REPORT_ARC_ID == "smarter-service"`, the orchestrator runs a different split — the macro skeleton needs more weight in the dimension narratives and theme cases share less budget per case (because the macro narrative carries the framing they used to repeat):

```
exec_words              = clamp(target_words * 0.10, 200, 350)
synthesis_words         = clamp(target_words * 0.08, 300, 800)
dim_narrative_words     = clamp(target_words * 0.12, 250, 600)   # PER dimension; 4 dimensions total
theme_cases_total       = target_words - exec_words - synthesis_words - 4 * dim_narrative_words
per_theme_case_words    = max(290, round(theme_cases_total / N))  # N = number of investment themes
```

- `exec_words` → executive summary (`report-header.md`)
- `synthesis_words` → "Capability Imperative" synthesis section
- `dim_narrative_words` → `DIMENSION_NARRATIVE_TARGET_WORDS` for each of 4 composer agents
- `per_theme_case_words` → `THEME_CASE_TARGET_WORDS` for each theme-case agent

The shared primer (~480 words) is internal and not budgeted. The claims registry is excluded from the formula.

### Bridges (legacy flow only)

In the legacy flow, bridge paragraphs (one per consecutive theme pair, 2–4 sentences ≈ 50–80 words each — see Step 2.5b in `references/phase-2-strategic-themes.md`) are also NOT carved out of the formula. They contribute roughly `(N-1) × 60` words to total prose — about 240 words at `N=5`. The reviewer's 0.80–1.25 Completeness tolerance band is wider than the writer's per-section ±15% tolerance precisely to absorb this slack plus exec/synthesis clamp variance, so a report whose explicit budget sums to `target_words` will land slightly over but stay in-band. Treat the formula's output as a budget for the prose elements the orchestrator can directly steer; bridges sit on top within tolerance.

In the smarter-service flow there are no inter-theme bridges (theme-cases nest under macro elements rather than sequence), so the formula's output sums to ~`target_words` with no slack. The composer's macro-section bridge sentences (Forces→Impact, etc.) are part of the dimension narrative budget.

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

## Worked examples — smarter-service flow

**Standard (N=5, smarter-service):**
- target_words = 4,000
- exec = clamp(400, 200, 350) = 350
- synthesis = clamp(320, 300, 800) = 320
- dim_narrative = clamp(480, 250, 600) = 480 per dimension
- 4 dimension narratives = 1,920
- theme_cases_total = 4,000 − 350 − 320 − 1,920 = 1,410
- per_theme_case = max(290, 1,410/5) = 290 (floor binds)
- Budgeted prose: 350 + 1,920 + 5 × 290 + 320 = 4,040 ✓ (slight overshoot from floor)

**Extended (N=5, smarter-service):**
- target_words = 5,500
- exec = clamp(550, 200, 350) = 350
- synthesis = clamp(440, 300, 800) = 440
- dim_narrative = clamp(660, 250, 600) = 600 per dimension
- 4 dimension narratives = 2,400
- theme_cases_total = 5,500 − 350 − 440 − 2,400 = 2,310
- per_theme_case = max(290, 2,310/5) = 462
- Budgeted prose: 350 + 2,400 + 5 × 462 + 440 = 5,500 ✓

**Maximum (N=5, smarter-service):**
- target_words = 8,000
- exec = clamp(800, 200, 350) = 350
- synthesis = clamp(640, 300, 800) = 640
- dim_narrative = clamp(960, 250, 600) = 600 per dimension (clamped)
- 4 dimension narratives = 2,400
- theme_cases_total = 8,000 − 350 − 640 − 2,400 = 4,610
- per_theme_case = max(290, 4,610/5) = 922
- Budgeted prose: 350 + 2,400 + 5 × 922 + 640 = 8,000 ✓

**Standard with many themes (N=7, smarter-service):**
- target_words = 4,000
- exec = 350, synthesis = 320, 4 × dim_narrative = 1,920
- theme_cases_total = 4,000 − 350 − 320 − 1,920 = 1,410
- per_theme_case = max(290, 1,410/7) = 290 (floor binds, total 7×290 = 2,030 > theme_cases_total)
- Actual prose ≈ 350 + 1,920 + 7 × 290 + 320 = 4,620 (ratio 1.16, within 0.80–1.25 band)
- Note: at N=7 with `standard` tier, the floor-overshoot is ~620 words. Acceptable — alternative is to drop content. If a project consistently has N≥7, recommend `extended` tier.

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
