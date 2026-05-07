# Graph renderer contract (v0.0.34, #221)

This document fixes the contract between `build_graph.py` and the inline canvas renderer it embeds. Read once before invoking the `--graph` flag from `wiki-dashboard`'s SKILL.md.

## Why a custom renderer

The reference llm-wiki-agent implementation uses [vis-network](https://github.com/visjs/vis-network) loaded from a CDN. cogni-wiki's `wiki-dashboard` constraint explicitly precludes external CSS / CDN / fonts / JS libraries (see SKILL.md §"Constraints"), and bundling a minified vis-network UMD inline adds ~600 KB to every dashboard — a regression in shareability and load time when the dashboard's existing pattern is "open offline, share as a single file."

A custom canvas renderer (~300 LOC inline JS) gets us:

- Zero external resources, zero CDN.
- Tight HTML (a 100-page wiki produces ~50 KB of HTML; even 1 000 pages stays under 1 MB).
- A force-directed layout, click-to-explore neighbours, search filtering, pan + zoom.

What we lose: faithful Louvain communities, smooth physics with thousands of nodes, advanced visualisation features (clustering hierarchies, edge bundling). These are documented as deferred to a follow-up PR; if a user genuinely needs them, the right swap is `--graph-renderer=embed-vis` (NOT yet implemented) which would inline the 600 KB UMD. Until then, the canvas renderer is the only option.

## Cache schema

```
<wiki-root>/.cogni-wiki/graph-cache/<sha256(slug_a|slug_b)>.json
```

Each file:

```json
{
  "pair_id": "<sha256 of sorted-slug pair>",
  "slug_a": "<slug, lower in sort order>",
  "slug_b": "<slug, higher in sort order>",
  "page_a_hash": "<sha256 of page_a content at evaluation time>",
  "page_b_hash": "<sha256 of page_b content at evaluation time>",
  "model_id": "<model used for the judgement (e.g. sonnet, opus)>",
  "judgement": "related" | "unrelated",
  "confidence": 0.0,
  "relationship": "<short phrase describing the relationship, '' if unrelated>",
  "evaluated_at": "YYYY-MM-DDTHH:MM:SS"
}
```

**Hit rule.** A cached entry counts as a fresh hit (skipped from re-enumeration, used as-is during build) only when *all three* of `model_id`, `page_a_hash`, `page_b_hash` match the current values. A model rotation (sonnet→opus), a content edit on either side, or an entirely new pair invalidates the entry. Stale entries stay on disk — re-running with the original model and unedited pages reuses them naturally.

**Filename rule.** Filename is `sha256(slug_a|slug_b)` *only* — not parameterised by model. Rotating the model swaps the *content* of the file (overwrite via `atomic_write`); it does not orphan files.

**Concurrency.** Each cache file is unique-by-construction per pair (one writer per `record-judgement` call). `atomic_write` ensures crash-safety. No `_wiki_lock` needed for the cache itself; the cache directory is *not* a shared-state file in the sense of `CLAUDE.md`'s lock table.

## Edge types

| Type | Source | Confidence | Color | Rendered weight |
|---|---|---|---|---|
| `EXTRACTED` | Pass 1: `[[wikilink]]` resolved against the slug index | `1.0` | `#555555` (dark grey) | thicker (1.0px) |
| `INFERRED` | Pass 2 cache, `judgement=related`, `confidence ≥ 0.7` | as cached | `#FF5722` (orange) | medium (0.7px) |
| `AMBIGUOUS` | Pass 2 cache, `judgement=related`, `confidence < 0.7` | as cached | `#BDBDBD` (light grey) | medium (0.7px) |

`unrelated` cache entries produce **no** edge; they exist only to suppress re-evaluation of the same pair until either page changes.

## Communities

`build_graph.py` runs a deterministic **Label Propagation Algorithm** over the union of Pass 1 + Pass 2 edges:

```
labels[n] = i for i, n in enumerate(sorted(nodes))
repeat (max 30 iterations):
    for each n in sorted(nodes):
        labels[n] = most-common label among adj[n], with lower-label-id breaking ties
    if no change: stop
remap labels to 0..K-1 in deterministic order
```

LPA is ~60 LOC and stdlib-only. It produces good-enough colour clusters for visualisation without the modularity-optimisation complexity of faithful Louvain. **Upgrade path**: replace `label_propagation()` in `build_graph.py` with a Clauset–Newman–Moore Louvain or a Leiden refinement once a use-case demands tighter community quality. The function signature `(node_ids, adj) -> {node_id: community_id}` is the contract; everything downstream (palette assignment, isolation count, the test fixture's `communities >= 2` assertion) reads from that map.

## Inline data shape

The `<script>const GRAPH = {...};</script>` block in the rendered HTML carries:

```jsonc
{
  "nodes": [
    {
      "id": "<slug>",
      "label": "<frontmatter title>",
      "type": "<frontmatter type>",
      "tags": ["..."],         // sorted
      "preview": "<≤220 char body excerpt>",
      "community": <int>,
      "color": "hsl(...)",     // pre-baked from palette
      "foundation": <bool>,    // marks v0.0.33 foundation pages with a yellow ring
      "degree": <int>          // |neighbours|, used for node-sizing
    }
  ],
  "edges": [
    {
      "from": "<slug>",
      "to": "<slug>",
      "type": "EXTRACTED" | "INFERRED" | "AMBIGUOUS",
      "color": "<#hex>",
      "confidence": <float>,
      "relationship": "<short phrase>"
    }
  ],
  "community_count": <int>
}
```

**What's deliberately NOT inlined**: full markdown bodies (would balloon a 200-page wiki to 5–10 MB); raw frontmatter; per-page log history; in/out edge lists per node (rebuilt on page-load by the renderer's `neighbours` map).

## Interaction model

- **Click node** → highlight neighbours, dim everything else, open the side panel with title, type, tags, preview, in/out edge lists. Clicking an edge label in the panel jumps to that node.
- **Drag node** → pin it (the user-positioned node is excluded from physics until the next page load).
- **Drag background** → pan.
- **Scroll wheel** → zoom about the cursor.
- **Search box** → filters visible nodes by id / label / any tag (substring); direct neighbours of matches are kept visible so the matched subgraph stays connected.

## Future work (deferred from #221)

- `--graph-renderer=embed-vis` flag that inlines vis-network for users who need clustering hierarchies / edge bundling.
- Faithful Louvain or Leiden community detection.
- "Phantom hub" and "graph-health" reports — surface nodes the LLM keeps inferring relationships *to* without an explicit `[[wikilink]]` (signals a missing concept page). Wire into `wiki-resume`'s status block.
- Auto-rebuild graph on every `wiki-ingest` dispatch (cost-prohibitive at current Pass-2 budgets; defer until a non-LLM heuristic is good enough).
