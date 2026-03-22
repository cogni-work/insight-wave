---
name: Affinity Clustering
phase: define
type: convergent
inputs: [discovery-synthesis, research-findings, trend-candidates]
outputs: [theme-clusters, insight-statements]
duration_estimate: "30-60 min with consultant"
requires_plugins: []
---

# Affinity Clustering

Group discovery findings into meaningful theme clusters to identify patterns and focus areas.

## When to Use

- After Discovery produces multiple sources of insight (research, trends, competitive data)
- Essential for: strategic-options, digital-transformation, innovation-portfolio
- Useful whenever the discovery synthesis has 10+ distinct themes or findings

## Guided Prompt Sequence

### Step 1: Extract Individual Findings
Read `discover/synthesis.md` and all discovery source files. Extract individual findings as discrete items:
- Each finding should be a single, self-contained insight
- Include the source (research, trends, competitive, stakeholder)
- Aim for 15-40 items — fewer means Discovery was too shallow, more can be grouped

Present the items to the consultant for review: "Here are N findings from Discovery. Any to add, remove, or reframe?"

### Step 2: Propose Initial Clusters
Group findings by thematic similarity. Propose 5-8 initial clusters, each with:
- A working label (2-4 words)
- The findings it contains
- Why these belong together

Present: "I've grouped these into N clusters. Review and adjust — merge, split, or relabel as you see fit."

### Step 3: Iterate with Consultant
The consultant will likely want to:
- Merge similar clusters
- Split clusters that contain distinct themes
- Relabel clusters with more meaningful names
- Move individual findings between clusters
- Add findings that weren't captured

Iterate until the consultant is satisfied with the groupings.

### Step 4: Prioritize
Rank the final clusters by relevance to the engagement vision:
1. Which clusters are most directly related to the desired outcome?
2. Which contain the most surprising or challenging findings?
3. Which represent the biggest gaps between current state and desired state?

### Step 5: Write Insight Statements
For each top-priority cluster, draft a one-sentence insight statement:
- "Despite strong market growth, [client] is losing share in the mid-market segment because [reason]"
- "The shift to hybrid cloud creates an opportunity for [client] to differentiate through [capability]"

## Output Format

Save as `define/theme-clusters.md`:

```markdown
# Theme Clusters

## Priority 1: [Cluster Name]
**Insight**: [one-sentence insight statement]
- Finding 1 (source: research)
- Finding 2 (source: trends)
- ...

## Priority 2: [Cluster Name]
...
```
