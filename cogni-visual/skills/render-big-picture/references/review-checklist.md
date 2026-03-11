# Scene Review Checklist

## Purpose

Quality gates for the zone-reviewer agents. Evaluate a rendered big picture zone against these criteria using element counting and optional screenshots. Score each gate pass/warn/fail.

**v4.2:** Updated for inline station numbers (no circles), opacity-aware contrast checks (min #888 dark mode). Reading Flow Clarity (Gate 7) now checks accent text elements, not ellipses. Thresholds reflect 200+ elements per station.

---

## Gate 1: Station Element Density

**Target:** Each station object should contain 200+ graphical elements (excluding text and number text elements).

| Score | Criterion |
|-------|-----------|
| PASS | All stations in zone have 200+ graphical elements |
| WARN | 1-2 stations have 150-199 elements |
| FAIL | Any station has fewer than 150 elements |

**How to check:** Use `describe_scene` or `query_elements` to count elements per station group. Station groups should contain structure (130-160) + enrichment (100-130) elements. Stations are rendered in Phase 3/3.5.

> **Sketch-aware stations:** Stations that used DENSIFY mode (sketch anchor provided) have a lower combined target of 170+ elements instead of 200+. The zone reviewer receives a `DENSIFY_STATIONS` list to identify these.

**Fix:** Add detail elements — surface textures, micro-details, environmental integration elements. Focus on areas that appear sparse. Add in batches of 10-20, targeting the most visually empty regions of the station object.

---

## Gate 2: Visual Recognizability

**Target:** Each station object should be recognizable as what it represents.

| Score | Criterion |
|-------|-----------|
| PASS | Objects have clear silhouettes with dense internal detail and distinctive features |
| WARN | 1-2 objects have good silhouettes but lack fine detail |
| FAIL | Objects look like abstract shapes with no connection to their names |

**How to check:** Screenshot review (if browser available) or structural analysis via `describe_scene`. For each station, assess: does the element distribution suggest a recognizable form? Are there detail elements (small shapes 5-20px) indicating features like windows, panels, lights?

**Fix:** Add recognition cues — the distinctive elements that define the object. Add surface details (panel lines, window grids, equipment shapes) that create visual texture.

---

## Gate 3: Text Readability

**Target:** All text elements must be readable against the background.

| Score | Criterion |
|-------|-----------|
| PASS | All headlines and body text have sufficient contrast, text glow backgrounds are visible |
| WARN | Some text partially overlaps with nearby objects but is still legible |
| FAIL | Text is obscured by objects, or text glow backgrounds are missing/too small |

**How to check:** Screenshot review or query text elements and their nearby glow rectangles. Focus on:
- Headline text (largest, most important)
- Hero numbers (should be bold and prominent)
- Body text (smallest, most vulnerable to occlusion)

**Fix:** Resize text glow backgrounds, adjust text positions, or move overlapping station elements.

---

## Gate 4: Color/Contrast Visibility

**Target:** All station elements must be visible against the canvas background.

| Score | Criterion |
|-------|-----------|
| PASS | All sampled station elements have luminance_diff >= 40 vs canvas background |
| WARN | 1-2 elements with luminance_diff 20-39 |
| FAIL | Any elements near-invisible (luminance_diff < 20) |

**How to check:** Sample 5-10 representative station fill colors. Parse hex to RGB. Compute `luminance = 0.299*R + 0.587*G + 0.114*B` for both element and canvas background. Use **opacity-aware** contrast: `effective_contrast = luminance_diff * (opacity / 100)`. Must be >= 25. Critical on dark mode canvases where grey station elements may blend into dark backgrounds.

**Fix:** Use `update_element` to shift fill colors toward higher contrast. In dark mode: lighten elements toward #FFFFFF (min fill #888888). In light mode: darken elements toward #000000. For low-opacity elements, raise base color to #999999 minimum.

---

## Gate 5: Dark Mode Compliance

**Target:** All visual elements must be adapted to the active color mode (dark or light).

| Score | Criterion |
|-------|-----------|
| PASS | No white glow rectangles on dark canvas; no large light fills on dark background. Auto-PASS on light mode. |
| WARN | Minor adaptation issues (1-2 small elements with wrong mode colors) |
| FAIL | White `#FFFFFF*` rectangles visible as glow backgrounds on dark canvas, or footer uses light-mode colors |

**How to check:** Only evaluated when `COLOR_MODE = "dark"`. Scan for rectangles with `backgroundColor` matching `#FFFFFF*` or `#F5F5F5`. Check text glow backgrounds, footer background, and any large filled shapes. On light mode, auto-PASS.

**Fix:** Update offending elements:
1. Text glow backgrounds: `backgroundColor` → `{CANVAS_FRAME_BG}D9`
2. Footer background: → `palette.footer_bg`
3. Footer text: strokeColor → `palette.footer_text`
4. Any remaining white fills → darker palette equivalent

---

## Gate 6: No Overlapping Stations

**Target:** Station objects and their text areas must not overlap each other.

| Score | Criterion |
|-------|-----------|
| PASS | All stations in zone have clear separation (50+ px between bounding boxes) |
| WARN | Some stations are close (20-50px) but not overlapping |
| FAIL | Station objects or text areas overlap |

**How to check:** Compare bounding boxes from station artist responses within this zone.

**Fix:** Shift overlapping stations apart. Prioritize maintaining the journey path flow direction.

---

## Gate 7: Reading Flow Clarity

**Target:** Station number text elements are visible and correctly positioned inline LEFT of the headline text at each station.

| Score | Criterion |
|-------|-----------|
| PASS | All station numbers in zone are visible, accent-colored, and inline with their headline text (LEFT of headline, same y-baseline) |
| WARN | Numbers visible but slightly misaligned from headline (>20px off baseline) |
| FAIL | Numbers missing, hidden behind station details, or positioned far from headline text |

**How to check:** Query for text elements with IDs matching "number-{N}" pattern within the zone. Verify each number is positioned to the LEFT of its station's headline text, with the correct gap (12px for A0/A1, 10px for A2, 8px for A3). Check that numbers use accent color and are not occluded by station detail elements.

**Fix:** Reposition misaligned numbers using `update_element` to place them at `headline_x - number_width - gap` horizontally, same y as headline. If numbers are hidden, they may need z-order adjustment (delete and recreate on top).

---

## Gate 8: Title Banner and Footer

**Target:** Title banner is solid and readable, footer contains metadata.

| Score | Criterion |
|-------|-----------|
| PASS | Dark banner with white title, subtitle, governing thought. Footer with customer/provider and date. |
| WARN | Present but one element is misaligned or missing |
| FAIL | Missing entirely |

**How to check:** Query elements at canvas top/bottom areas. Only evaluate if this zone includes the top or bottom edge.

**Fix:** Re-create missing elements using batch_create_elements.

---

## Gate 9: Style Consistency

**Target:** All elements use the same roughness, consistent stroke widths, harmonious colors.

| Score | Criterion |
|-------|-----------|
| PASS | Uniform roughness, consistent line weight, palette coherent |
| WARN | Minor inconsistency in 1-2 element groups |
| FAIL | Mixed roughness values, wildly different styles between elements |

**How to check:** Sample elements across the zone and compare roughness, strokeWidth, and color palette.

**Fix:** Update inconsistent elements to match the global roughness and stroke width.

---

## Scoring Summary

| Result | Condition |
|--------|-----------|
| **PASS** (score >= 8) | All gates PASS |
| **ACCEPTABLE** (score 6-7) | No FAIL gates, up to 3 WARN gates |
| **NEEDS CORRECTION** (score < 6) | Any FAIL gate, or 4+ WARN gates |

**Score calculation:** PASS = 1 point, WARN = 0.5 points, FAIL = 0 points. Total out of 9.

---

## Zone-Based Review Methodology

### Review Zones

The canvas is divided into 4 review zones:

| Review Zone | Horizontal Range | Covers |
|-------------|-----------------|--------|
| Zone A (left) | 0% - 25% of canvas width | Left-side stations |
| Zone B (center-left) | 25% - 50% | Center-left stations |
| Zone C (center-right) | 50% - 75% | Center-right stations |
| Zone D (right) | 75% - 100% | Right-side stations |

### Per-Zone Review Focus

Each zone reviewer evaluates:
1. **All 9 gates** for elements within their zone
2. **Station density** — stations in this zone meet the 200+ element target
3. **Color/contrast visibility** — all elements visible against canvas background
4. **Dark mode compliance** — palette correctly applied (if dark mode)

### Zone-Level Corrections

- Maximum **30 elements added** per zone review pass
- Maximum **10 element updates** (position/style adjustments) per zone
- If a gate requires more corrections than limits allow, score as WARN and note remaining work

---

## Correction Priority

When corrections are needed, fix in this order:

1. **FAIL gates first** — These are showstoppers
2. **Gate 6 (overlaps)** — Most disruptive visual issue
3. **Gate 4 (contrast visibility)** — Elements must be visible against background
4. **Gate 2 (recognizability)** — Core purpose of the illustration
5. **Gate 3 (text readability)** — Users need to read the content
6. **Gate 5 (dark mode compliance)** — Theme consistency
7. **Gate 1 (element density)** — Sparse objects look unfinished
8. **Remaining WARN gates** — Polish and refinement

---

## Aggregate Scoring

After all 4 zone reviewers complete, the orchestrator computes:

```
overall_score = min(zone_a_score, zone_b_score, zone_c_score, zone_d_score)
```

The overall score equals the LOWEST zone score (weakest link). This ensures no zone is left below quality threshold.

If any zone scores below 6 (NEEDS CORRECTION), a second review pass is triggered for that zone only.
