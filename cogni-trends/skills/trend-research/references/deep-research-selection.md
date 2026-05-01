# Deep Research Candidate Selection

Reference for `trend-research` Phase 0.5 — selecting 3–5 high-value ACT-horizon trends for recursive deep research before the standard evidence-enrichment pass.

---

## When to Offer Deep Research

Deep research is opt-in. Offer it when the user wants richer evidence for the most consequential trends; skip it when the user wants a fast pass or explicitly declines. The cost is ~5–10 minutes of additional wall-clock time and 3–5 extra agent dispatches.

Deep-researched trends carry stronger Stake / Move / Cost-of-Inaction beats in `trend-synthesis` because:

- **More forcing functions** — deep researchers actively look for regulatory deadlines and contract windows
- **More quantitative data** — sub-aspect decomposition surfaces ROI figures and market-size estimates the single-pass writer agent often misses
- **Source diversity** — multi-pass search picks up secondary sources that strengthen citation diversity gates

---

## Selection Criteria (auto mode)

When the user picks the auto option, apply these criteria in priority order:

1. **ACT-horizon trends** with `signal_intensity >= 4` and `confidence_tier == "high"` — sorted by composite score descending
2. If fewer than 3 qualify, include ACT-horizon trends with `confidence_tier == "medium"` and the highest scores
3. Cap at **5 trends maximum** (cost ceiling)

The ACT-horizon constraint is intentional: deep research benefits trends that drive immediate decisions. PLAN-horizon trends are usually well-served by the single-pass writer agent because their evidence is broader and less time-critical.

Reject trends that already carry rich `evidence_md` from trend-scout's web research stage — they don't need a second pass.

---

## User Prompt (auto / skip / manual)

**English:**

```text
I can perform deep research on 3-5 high-value trends before writing the report.
This adds ~5-10 minutes but produces richer evidence with quantitative data.
Would you like to:

a) Deep research top ACT-horizon trends (recommended for executive audiences)
b) Skip deep research and proceed with standard evidence enrichment
c) Select specific trends for deep research
```

**German:**

```text
Ich kann eine Tiefenrecherche für 3-5 hochwertige Trends durchführen, bevor der
Bericht geschrieben wird. Das dauert ~5-10 Minuten länger, liefert aber
reichere Evidenz mit quantitativen Daten. Möchten Sie:

a) Tiefenrecherche der wichtigsten ACT-Horizont-Trends (empfohlen für Führungskräfte-Publikum)
b) Tiefenrecherche überspringen und mit Standard-Evidenzanreicherung fortfahren
c) Spezifische Trends für Tiefenrecherche auswählen
```

## Manual Selection

If the user picks (c), present the ACT-horizon trend list (name + dimension + signal_intensity + confidence_tier) via AskUserQuestion or a free-form text prompt. Cap at 5 selections; if more requested, ask which to drop.

## Anti-patterns

- **Don't deep-research PLAN or OBSERVE-horizon trends.** They're not the load-bearing evidence in synthesis arguments and don't earn the cost.
- **Don't deep-research more than 5.** Diminishing returns: agents share search-engine throttling, parallel dispatch saturates rate limits.
- **Don't substitute deep research for trend-scout's web stage.** Deep research enriches; it does not replace.
- **Don't deep-research a trend with 0 candidate evidence.** Without seed evidence (keywords, research_hint), the deep researcher's sub-aspect decomposition cannot anchor.
