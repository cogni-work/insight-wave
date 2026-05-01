# Candidate → Theme Back-Reference Algorithm

Reference for the `build-booklet-index.sh` value-model walk that produces the `theme_backrefs[]` array per candidate.

---

## Goal

For each `candidate_ref` in the trend-scout output, compute every `(theme_id, theme_name, role)` triple where the candidate participates in one of the theme's value chains. A candidate may appear under multiple themes; preserve all entries.

When the resulting list is empty, the candidate is an **orphan** and is rendered in the dimension's appendix.

---

## Walk

```text
for each chain in tips-value-model.json -> value_chains[]:
    theme_id = chain.investment_theme_ref || chain.theme_id
    theme_name = lookup investment_themes[*] where theme_id matches -> .name

    if chain.trend.candidate_ref is set:
        emit (chain.trend.candidate_ref, theme_id, theme_name, role="trend")

    for each entry in chain.implications[]:
        if entry.candidate_ref is set:
            emit (entry.candidate_ref, theme_id, theme_name, role="implication")

    for each entry in chain.possibilities[]:
        if entry.candidate_ref is set:
            emit (entry.candidate_ref, theme_id, theme_name, role="possibility")

    for each entry in chain.foundation_requirements[] (may be absent):
        if entry.candidate_ref is set:
            emit (entry.candidate_ref, theme_id, theme_name, role="foundation")
```

Then invert: group emitted triples by `candidate_ref` and attach the resulting list as `theme_backrefs[]` on each entry in the booklet index.

---

## Edge Cases

| Case | Handling |
|---|---|
| Theme entry uses `investment_theme_id` instead of `theme_id` | Match either key when building `themes_by_id` |
| Chain references `investment_theme_ref` not in `investment_themes[]` | Fall back to `theme_name = theme_id` |
| Candidate appears in two roles within the same chain | Emit both triples (e.g., a candidate that is both the `trend` and a `foundation_requirement`) |
| Candidate appears in two chains under the same theme | Emit both triples (preserves the multiple-role visibility); deduplication is the formatter's choice |
| Candidate has zero references after the walk | Becomes an orphan; lands in the dimension's appendix bucket |
| Value model has `orphan_candidates[]` array | Merge those into the index too — `build-booklet-index.sh` does this in a second pass to catch candidates value-modeler tracked separately |

---

## Role Localization

The formatter agent renders role labels using the synthesis i18n keys (`TREND`, `IMPLICATION`, `POSSIBILITY`, `FOUNDATION`) so the booklet and the canonical report use consistent vocabulary. The booklet's own i18n labels (in `references/i18n/labels-{en,de}.md`) carry the *headers* (`ENTRY_THEMES_HEADER`); the role *labels* are reused from the synthesis labels.

---

## Determinism

The walk is deterministic when `value_chains[]` is iterated in source order and `investment_themes[]` is iterated by `theme_id` ascending. The script preserves this order by not sorting except where explicitly noted.

Row ordering inside `theme_backrefs[]` follows emission order: a candidate's primary role (where it appears in `chain.trend`) typically appears first, with implication / possibility / foundation roles after. This matches reader expectation — "this is primarily a Trend in Theme X" should lead.
