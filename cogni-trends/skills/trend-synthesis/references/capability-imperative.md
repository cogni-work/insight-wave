# The Capability Imperative — Synthesis Pattern

Reference for `trend-synthesis` Step 2.5 — the closing synthesis section of the canonical TIPS report.

---

## Purpose

The synthesis section closes the report on a Foundations-anchored note: it aggregates capability requirements **across** the N investment themes and identifies the shared foundations that unlock multiple themes. It answers the implicit CxO question: "What do I have to build first to capture *any* of these opportunities?"

Unlike the per-theme Cost-of-Inaction beats (which sum costs per theme), the Capability Imperative computes the **shared denominator** — capabilities (culture, workforce, technology) that more than one theme requires, sequenced so investing once unlocks many.

---

## Section Heading

- English: **"The Capability Imperative"** (i18n key `SYNTHESIS_HEADING_SMARTER_SERVICE`)
- German: **"Der Fähigkeitsimperativ"**

---

## Structure

```markdown
## {SYNTHESIS_HEADING_SMARTER_SERVICE}

{Opening: 2 sentences. Pattern: "Identifying trends is necessary but insufficient.
These [N] investment themes share [M] foundation requirements. Without them,
opportunities remain theoretical."}

{Body: ~60% of SYNTHESIS_TARGET_WORDS}

- Aggregate the strongest capability evidence across all themes (culture / workforce / technology)
- Identify *shared* foundations that unlock multiple themes ("invest once, unlock many")
- Sequence the build order: culture → workforce → technology → outcome
- Combined cost-of-inaction across all themes (sum of individual ratios where they share denominators); combined proactive investment

### {UNIFIED_CAPABILITY_ROADMAP_LABEL}

1. **{Calendar timeframe — e.g., "Q3 2026"}**: {Cross-theme action; names which themes it enables}
2. **{Calendar timeframe}**: {Cross-theme action}
3. **{Calendar timeframe}**: {Cross-theme action}
4. **{Calendar timeframe}**: {Cross-theme action}

{Closing: 1-2 sentences. Pattern: "The trend panorama shows what's changing;
the investment themes show where to bet; the capability imperative shows what
to build first."}
```

---

## Length

Target `SYNTHESIS_TARGET_WORDS ± 15%` (computed in Phase 1). Typical values:

| Tier | Target |
|---|---|
| standard | ~320 words |
| extended | ~440 words |
| comprehensive | ~560 words |
| maximum | ~640 words |

The Unified Capability Roadmap stays at 3–4 bullets regardless of tier — longer roadmaps lose the "build first" focus and become indistinguishable from the per-theme "Nächste Schritte" content.

---

## Quality Gates

- [ ] **Opening matches the pattern.** "Identifying trends is necessary but insufficient. These [N] investment themes share [M] foundation requirements. Without them, opportunities remain theoretical." — the [N] and [M] must be specific integers pulled from the value model and the synthesis itself.
- [ ] **Aggregates across themes, not within one.** Cross-references at least 3 different themes by name in the body. A synthesis that names only one or two themes has fallen back to per-theme summary.
- [ ] **Names shared foundations explicitly.** Phrases like "culture → workforce → technology" or named capability blocks ("data platform", "governance model", "talent uplift") that appear in multiple theme-cases.
- [ ] **Combined cost-of-inaction figure.** A single number that aggregates the per-theme ratios (sum of individual ratios where they share denominators) and a single combined proactive investment number. Generic phrases ("costs add up") fail the gate.
- [ ] **Roadmap entries are calendar-specific.** "Q3 2026", "H1 2027" — not "short-term / medium-term". Each entry names which themes the action enables.
- [ ] **Closing matches the pattern.** "The trend panorama shows what's changing; the investment themes show where to bet; the capability imperative shows what to build first." — verbatim or near-verbatim, in the report language.

---

## Anti-patterns

- **Per-theme Cost-of-Inaction restatement.** Those live in the theme-case Cost beats. The synthesis aggregates *across* themes; if a sentence belongs in one theme's Cost beat, it belongs there, not here.
- **Generic capability lists.** "Companies need data, talent, and governance" without naming which specific themes each unlocks fails the shared-foundations gate.
- **Roadmap with vague horizons.** "Short-term: pilot AI. Medium-term: scale." — these miss the synthesis-skill point. The roadmap is the cross-theme orchestration layer; calendar dates anchor it to the forcing functions cited in the macro Forces section.
- **Closing without the rhetorical triplet.** Skipping "trend panorama / investment themes / capability imperative" loses the report's signature close — readers who have skimmed to the bottom rely on it for the takeaway.
