# Deep Research Tree Reference

## Tree Decomposition Algorithm

Deep mode builds a 2-level research tree from the user's topic:

```
User Topic
├── Branch 1: [aspect A]
│   ├── Leaf 1.1: [sub-aspect A.1]
│   ├── Leaf 1.2: [sub-aspect A.2]
│   └── Leaf 1.3: [sub-aspect A.3]
├── Branch 2: [aspect B]
│   ├── Leaf 2.1: [sub-aspect B.1]
│   └── Leaf 2.2: [sub-aspect B.2]
└── Branch 3: [aspect C]
    ├── Leaf 3.1: [sub-aspect C.1]
    └── Leaf 3.2: [sub-aspect C.2]
```

**Branching rules**:
- Level 0 → Level 1: 3-5 top-level branches (major aspects)
- Level 1 → Level 2: 2-3 sub-branches per branch (specific angles)
- Total leaves: 8-15 typical, max 20

## Entity Tracking

Each node in the tree is a sub-question entity with `tree_path`:
- Branch 1: `tree_path: "1"`
- Leaf 1.2: `tree_path: "1.2"`
- Leaf 1.2 has `parent_ref: "[[00-sub-questions/data/sq-branch-1-...]]"`

Only leaf nodes get researched (by deep-researcher agents). Branch nodes are structural.

## Batching Strategy

With 15 leaf nodes and max 4-5 concurrent agents:

```
Batch 1: leaves 1.1, 1.2, 1.3, 2.1, 2.2  (5 agents)
Batch 2: leaves 3.1, 3.2, ...             (remaining agents)
```

Wait for each batch to complete before starting the next.

## Context Tree to Flat Report

After all deep-researchers complete:
1. Run `merge-context.py` to aggregate all contexts
2. The writer agent uses `tree_path` ordering to structure the report hierarchically
3. Branch-level sections become report headings
4. Leaf-level research becomes section content

## When to Use Deep Mode

- Topic has multiple interconnected domains
- User requests "exhaustive" or "recursive" research
- Topic would benefit from exploring sub-topics that aren't obvious upfront
- Expected report length: 8000-15000 words
