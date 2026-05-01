# Research Manifest Schema

Reference for `.metadata/trend-research-output.json` — the single artefact `trend-research` produces that downstream skills (`trend-synthesis`, `trend-booklet`) gate on.

---

## Purpose

The manifest is the **single gate** between research and downstream consumers. It provides:

1. **Existence proof** — "research has run successfully"
2. **Artefact discovery** — paths to the per-dimension `enriched-trends-*.json` and `claims-*.json` files (no globbing needed)
3. **Drift detection** — content hashes of the candidate set and value model so downstream skills can warn the user when their inputs have changed since research ran
4. **Stage metadata** — language, market region, deep-research coverage, claim counts

Downstream skills HALT when the manifest is missing and WARN when its hashes diverge from the current candidate / value-model state.

---

## Schema

```json
{
  "trend_research_complete": true,
  "trend_research_completed_at": "2026-05-01T14:32:18Z",
  "language": "de",
  "market_region": "dach",
  "candidates_total": 60,

  "dimensions_enriched": [
    "externe-effekte",
    "digitale-wertetreiber",
    "neue-horizonte",
    "digitales-fundament"
  ],

  "deep_research_trends": [
    {
      "trend_name": "EU AI Act Compliance",
      "dimension": "externe-effekte",
      "slug": "eu-ai-act-compliance",
      "artifact": ".logs/deep-research-eu-ai-act-compliance.json"
    }
  ],

  "claims_total": 84,
  "claims_by_dimension": {
    "externe-effekte": 22,
    "digitale-wertetreiber": 19,
    "neue-horizonte": 21,
    "digitales-fundament": 22
  },

  "files": {
    "enriched_trends": {
      "externe-effekte":      ".logs/enriched-trends-externe-effekte.json",
      "digitale-wertetreiber":".logs/enriched-trends-digitale-wertetreiber.json",
      "neue-horizonte":       ".logs/enriched-trends-neue-horizonte.json",
      "digitales-fundament":  ".logs/enriched-trends-digitales-fundament.json"
    },
    "claims": {
      "externe-effekte":      ".logs/claims-externe-effekte.json",
      "digitale-wertetreiber":".logs/claims-digitale-wertetreiber.json",
      "neue-horizonte":       ".logs/claims-neue-horizonte.json",
      "digitales-fundament":  ".logs/claims-digitales-fundament.json"
    },
    "sections": {
      "externe-effekte":      ".logs/section-externe-effekte.md",
      "digitale-wertetreiber":".logs/section-digitale-wertetreiber.md",
      "neue-horizonte":       ".logs/section-neue-horizonte.md",
      "digitales-fundament":  ".logs/section-digitales-fundament.md"
    }
  },

  "candidates_hash_at_research":  "sha256:abc123...",
  "value_model_hash_at_research": "sha256:def456..."
}
```

---

## Field Semantics

| Field | Type | Required | Meaning |
|---|---|---|---|
| `trend_research_complete` | bool | Yes | Always `true` when this manifest exists. Sentinel for downstream existence checks. |
| `trend_research_completed_at` | ISO-8601 string | Yes | UTC timestamp of manifest write. Informational; downstream drift detection uses hashes, not mtimes. |
| `language` | ISO 639-1 string | Yes | Output language used by Phase 1 agents. Downstream skills inherit this unless the user overrides. |
| `market_region` | string | Yes | Region code (e.g., "dach", "de", "fr"). Determines which `region-authority-sources.json` block was used. |
| `candidates_total` | int | Yes | Always 60 in the canonical pipeline (gate enforces it). |
| `dimensions_enriched[]` | string array | Yes | The 4 Smarter Service dimension slugs in TIPS order (T → I → P → S). |
| `deep_research_trends[]` | object array | Yes (may be empty) | One entry per trend that ran through `trend-deep-researcher` in Phase 0.5. Empty array when the user skipped deep research. |
| `claims_total` | int | Yes | Sum of `claims_count` across the 4 `claims-{dimension}.json` files. |
| `claims_by_dimension` | object | Yes | Per-dimension claim counts. Used by `verify-trend-report` to surface a per-dimension verification breakdown. |
| `files.enriched_trends` | object | Yes | Map dimension slug → path. Downstream skills read these instead of globbing. |
| `files.claims` | object | Yes | Map dimension slug → path. |
| `files.sections` | object | Yes | Map dimension slug → path. The section files are kept primarily as fallback evidence for `verify-trend-report`'s revisor. |
| `candidates_hash_at_research` | sha256 hex string | Yes | Hash of `tips_candidates.items` sorted by id/title. Downstream skills compare to current candidate hash to detect post-research scout-output edits. |
| `value_model_hash_at_research` | sha256 hex string | Yes | Hash of `investment_themes` + `solutions` + `blueprints` (sorted). Downstream skills compare to detect post-research value-model edits. |

---

## Hashing Recipe

Deterministic across re-runs and locales:

```python
import hashlib, json

# Candidate hash
def _key(c): return c.get('id') or c.get('title') or ''
items_sorted = sorted(scout_doc.get('tips_candidates', {}).get('items', []) or [], key=_key)
candidates_hash = 'sha256:' + hashlib.sha256(
    json.dumps(items_sorted, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
).hexdigest()

# Value-model hash (only the substantive sections)
def _sorted(seq, key):
    return sorted(seq or [], key=lambda x: (x.get(key) or '') if isinstance(x, dict) else '')
vm_payload = {
    'investment_themes': _sorted(vm_doc.get('investment_themes'), 'theme_id'),
    'solutions':         _sorted(vm_doc.get('solutions'),         'solution_id'),
    'blueprints':        _sorted(vm_doc.get('blueprints'),        'solution_id'),
}
value_model_hash = 'sha256:' + hashlib.sha256(
    json.dumps(vm_payload, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
).hexdigest()
```

**Rules:**

- Always `json.dumps(..., sort_keys=True, separators=(',', ':'), ensure_ascii=False)` — deterministic across Python versions and locales.
- Hash only candidate `items` and the three substantive value-model sections — never timestamps, mtimes, `report_*` fields, or any field this same step writes back.
- Use `id`/`title` (scout) and `theme_id`/`solution_id` (value-model) for the canonical sort. Items missing the canonical key still hash, just under the empty-string sort bucket.

---

## Drift Detection (downstream contract)

`/trend-synthesis` and `/trend-booklet` must, before their first dispatch:

1. Read `.metadata/trend-research-output.json`. If missing, HALT with `"Run /trend-research first."`.
2. Recompute the current `candidates_hash` and `value_model_hash` using the recipe above.
3. Compare to the manifest's `candidates_hash_at_research` and `value_model_hash_at_research`.
4. On mismatch, WARN — surface which set drifted (candidates, value model, or both) and offer to re-run `/trend-research`. Allow the user to proceed with stale evidence on explicit confirmation; the user owns that risk.

The warning text should name the impact:

- **Candidates drift** — "60 candidates differ from the set used at research time. Synthesis will reference candidates that may not match current evidence."
- **Value-model drift** — "Investment themes / solutions changed since research ran. Anchoring may be off; theme-cases may reference orphaned candidates."

---

## Versioning

This schema has no explicit version field; additive changes (new top-level keys, new entries in maps) must remain backward-compatible. Removing or renaming a field requires a coordinated update to all consumers (`trend-synthesis`, `trend-booklet`, `verify-trend-report`, `trends-resume` dashboard).
