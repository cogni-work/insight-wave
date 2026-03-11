# Story Arc Registry

## Overview

This registry indexes all available story arcs for the cogni-narrative plugin. Each arc provides a different narrative framework for transforming structured content (research syntheses, analyses, reports) into compelling executive narratives.

## Quick Reference

| # | Arc ID | Elements (Short) | TIPS | Best For | Detection Priority |
|---|--------|-----------------|------|----------|--------------------|
| 1 | `corporate-visions` | Change → Now → You → Pay | - | Market research, B2B, sales | Default fallback |
| 2 | `technology-futures` | Emerging → Converging → Possible → Required | - | Innovation, R&D, tech trends | `content_type: "technology"` |
| 3 | `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | - | Competitive analysis, threats | `content_type: "competitive"` |
| 4 | `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | - | Long-range planning, scenarios | `content_type: "foresight"` |
| 5 | `industry-transformation` | Forces → Friction → Evolution → Leadership | - | Industry analysis, regulation | `content_type: "industry"` |
| 6 | `trend-panorama` | Forces → Impact → Horizons → Foundations | T→I→P→S | Trend-scout output, TIPS reports | Structural + `"smarter-service"` |

## Arc Selection Logic

1. **Explicit selection**: Caller specifies `arc_id` directly (highest priority)
2. **Structural detection**: Check for arc-specific file signatures (e.g., `trend-scout-output.json`)
3. **Content type mapping**: Automatic detection based on `content_type` or `research_type` metadata
4. **Content analysis**: Keyword density analysis of input content
5. **Fallback default**: corporate-visions

## Available Story Arcs

### 1. Corporate Visions (Default)

**Arc ID:** `corporate-visions`
**Display Name:** Corporate Visions
**Elements:** Why Change → Why Now → Why You → Why Pay

**Best For:**
- Market research
- Competitive positioning
- Sales enablement
- B2B value propositions

**Detection Signals:**
- `content_type: "generic"` or `"market"`
- Default fallback when no other arc matches

**Word Targets:**
- Hook: 150-200 words
- Why Change: 400-500 words
- Why Now: 300-400 words
- Why You: 400-500 words
- Why Pay: 200-300 words
- **Total:** 1,450-1,900 words

**Definition File:** `story-arc/corporate-visions/arc-definition.md`

---

### 2. Technology Futures

**Arc ID:** `technology-futures`
**Display Name:** Technology Futures
**Elements:** What's Emerging → What's Converging → What's Possible → What's Required

**Best For:**
- Technology trend research
- Innovation scouting
- R&D strategy
- Capability roadmapping

**Detection Signals:**
- `content_type: "technology"`
- Keywords (>=15% density): "emerging", "innovation", "capability", "technology", "R&D", "breakthrough"

**Word Targets:**
- Hook: 150-200 words
- What's Emerging: 350-450 words
- What's Converging: 350-450 words
- What's Possible: 350-450 words
- What's Required: 200-350 words
- **Total:** 1,450-1,900 words

**Definition File:** `story-arc/technology-futures/arc-definition.md`

---

### 3. Competitive Intelligence

**Arc ID:** `competitive-intelligence`
**Display Name:** Competitive Intelligence
**Elements:** Landscape → Shifts → Positioning → Implications

**Best For:**
- Competitive analysis
- Market positioning
- Threat assessment
- Strategic differentiation

**Detection Signals:**
- `content_type: "competitive"`
- Keywords (>=12% density): "competitor", "market share", "positioning", "differentiation", "threat", "rivalry"

**Word Targets:**
- Hook: 150-200 words
- Landscape: 350-450 words
- Shifts: 300-400 words
- Positioning: 400-500 words
- Implications: 250-350 words
- **Total:** 1,450-1,900 words

**Definition File:** `story-arc/competitive-intelligence/arc-definition.md`

---

### 4. Strategic Foresight

**Arc ID:** `strategic-foresight`
**Display Name:** Strategic Foresight
**Elements:** Signals → Scenarios → Strategies → Decisions

**Best For:**
- Long-range planning
- Scenario analysis
- Uncertainty navigation
- Strategic options generation

**Detection Signals:**
- `content_type: "foresight"` or `"scenarios"`
- Keywords (>=10% density): "scenario", "future", "signal", "uncertainty", "planning", "foresight"

**Word Targets:**
- Hook: 150-200 words
- Signals: 300-400 words
- Scenarios: 400-500 words
- Strategies: 350-450 words
- Decisions: 250-350 words
- **Total:** 1,450-1,900 words

**Definition File:** `story-arc/strategic-foresight/arc-definition.md`

---

### 5. Industry Transformation

**Arc ID:** `industry-transformation`
**Display Name:** Industry Transformation
**Elements:** Forces → Friction → Evolution → Leadership

**Best For:**
- Industry analysis
- Sector transformation
- Regulatory impact
- Structural change analysis

**Detection Signals:**
- `content_type: "industry"`
- Keywords (>=12% density): "regulatory", "sector", "structural", "industry", "transformation", "policy"

**Word Targets:**
- Hook: 150-200 words
- Forces: 350-450 words
- Friction: 300-400 words
- Evolution: 400-500 words
- Leadership: 250-350 words
- **Total:** 1,450-1,900 words

**Definition File:** `story-arc/industry-transformation/arc-definition.md`

---

### 6. Trend Panorama

**Arc ID:** `trend-panorama`
**Display Name:** Trend Panorama
**Elements:** Forces → Impact → Horizons → Foundations (TIPS: T → I → P → S)

**Best For:**
- Trend-scout output summarization (52 trend candidates)
- TIPS trend report narratives
- Multi-horizon trend landscape overviews
- Industry-specific trend panoramas

**Detection Signals:**
- `content_type: "trend"` or `"trends"` or `"tips"`
- `research_type: "smarter-service"` (trend-scout output)
- `synthesis_format: "TIPS"` in source metadata
- Structural: presence of `trend-scout-output.json` or `tips-trend-report.md`
- Keywords (>=12% density): "trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "dimension"

**TIPS Dimension Mapping:**
- Forces = T (Externe Effekte): economy, regulation, society
- Impact = I (Digitale Wertetreiber): CX, products, processes
- Horizons = P (Neue Horizonte): strategy, leadership, governance
- Foundations = S (Digitales Fundament): culture, workforce, technology

**Horizon Cascade:** Each element applies Act → Plan → Observe progression internally.

**Word Targets:**
- Hook: 150-200 words
- Forces: 350-450 words
- Impact: 350-450 words
- Horizons: 350-450 words
- Foundations: 250-350 words
- **Total:** 1,450-1,900 words

**Definition File:** `story-arc/trend-panorama/arc-definition.md`

---

## Arc Detection Algorithm

### Step 1: Explicit Selection

If the caller provides `arc_id` directly, use it without detection.

### Step 2: Structural Detection (trend-panorama only)

Before content-type mapping, check for structural signals that uniquely identify trend-scout output:

```javascript
// Check for trend-scout structural signals (highest confidence detection)
if (fileExists(".metadata/trend-scout-output.json") || fileExists("trend-scout-output.json")) {
  detected_arc = "trend-panorama"
  detection_reason = "structural: trend-scout-output.json detected"
}
if (fileExists("tips-trend-report.md")) {
  detected_arc = "trend-panorama"
  detection_reason = "structural: tips-trend-report.md detected"
}
```

### Step 3: Content Type Mapping

```javascript
const arcMap = {
  "trend": "trend-panorama",
  "trends": "trend-panorama",
  "tips": "trend-panorama",
  "smarter-service": "trend-panorama",
  "technology": "technology-futures",
  "competitive": "competitive-intelligence",
  "foresight": "strategic-foresight",
  "scenarios": "strategic-foresight",
  "industry": "industry-transformation",
  "market": "corporate-visions",
  "generic": "corporate-visions"
}

// Also check research_type field
if (research_type === "smarter-service") {
  detected_arc = "trend-panorama"
  detection_reason = `research_type="smarter-service"`
}

if (content_type in arcMap) {
  detected_arc = arcMap[content_type]
  detection_reason = `content_type="${content_type}"`
}
```

### Step 4: Content Analysis (if no content_type match)

Analyze the input content for keyword density:

```javascript
keyword_sets = {
  "trend-panorama": ["trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "dimension"],
  "technology-futures": ["emerging", "innovation", "capability", "technology", "R&D", "breakthrough"],
  "competitive-intelligence": ["competitor", "market share", "positioning", "differentiation", "threat", "rivalry"],
  "strategic-foresight": ["scenario", "future", "signal", "uncertainty", "planning", "foresight"],
  "industry-transformation": ["regulatory", "sector", "structural", "industry", "transformation", "policy"]
}

thresholds = {
  "trend-panorama": 0.12,
  "technology-futures": 0.15,
  "competitive-intelligence": 0.12,
  "strategic-foresight": 0.10,
  "industry-transformation": 0.12
}
```

### Step 5: Fallback Default

```javascript
if (!detected_arc) {
  detected_arc = "corporate-visions"
  detection_reason = "default (no specific signals detected)"
}
```

## Arc Directory Structure

Each arc follows this structure:

```
story-arc/{arc-id}/
├── arc-definition.md          # Metadata, elements, detection signals, translations
├── {element1}-patterns.md     # Element 1 transformation patterns
├── {element2}-patterns.md     # Element 2 transformation patterns
├── {element3}-patterns.md     # Element 3 transformation patterns
└── {element4}-patterns.md     # Element 4 transformation patterns
```

## Interactive Selection Format

When presenting arc selection to users:

```
Auto-detected: {arc_display_name} ({detection_reason})

Please select story arc:

Option 1: {Detected Arc} (Recommended)
  Elements: {element1} → {element2} → {element3} → {element4}
  Best for: {use_case_summary}

Option 2: {Alternative Arc 1}
  Elements: {element1} → {element2} → {element3} → {element4}
  Best for: {use_case_summary}

[... remaining options ...]
```

## Extension Guidelines

### Adding New Arcs

1. Choose unique `arc_id` (lowercase, hyphens, descriptive)
2. Create directory: `story-arc/{arc-id}/`
3. Create 5 files:
   - `arc-definition.md` -- metadata, elements, detection, translations, quality gates
   - `{element1}-patterns.md` -- transformation patterns for element 1
   - `{element2}-patterns.md` -- transformation patterns for element 2
   - `{element3}-patterns.md` -- transformation patterns for element 3
   - `{element4}-patterns.md` -- transformation patterns for element 4
4. Add entry to this registry (both summary table and detailed section)
5. Update detection algorithm:
   - Add `content_type` mapping in Step 3
   - Add keyword set and threshold in Step 4
   - Add structural detection in Step 2 (if arc has unique file signatures)
6. Add arc-specific workflow: `phase-workflows/phase-4b-synthesis-{arc-id}.md`
7. Update `language-templates.md` with localized `##` headers (en/de)
8. Update `techniques-overview.md` application matrix with new arc column
9. Update `SKILL.md`:
   - Increment arc count in Purpose section
   - Add arc to Available Story Arcs table
   - Add `arc_id` to Phase 3 valid values list

### Quality Standards for New Arcs

**Structural:**
- Total word target: 1,450-1,900 words
- EXACTLY 4 elements (consistent with all arcs)
- Each element has distinct purpose (no overlap)
- Clear detection signals (content_type + keywords + optional structural)

**Content:**
- arc-definition.md includes: metadata, TIPS mapping (if applicable), word targets, detection config, element definitions, narrative flow, citation requirements, quality gates, common pitfalls, language variations
- Each pattern file includes: element purpose, source content mapping, transformation patterns (3-5), techniques checklist, quality checkpoints, common mistakes with good/bad examples, language variations
- Phase-4b workflow includes: evidence loading, output template, extended thinking sub-steps, validation gates

**Localization:**
- German translations for all element headers
- German header text added to `language-templates.md`
- German examples in pattern files
- Umlaut rules enforced (no ASCII fallbacks in body text)

**Cross-references:**
- Technique application matrix updated in `techniques-overview.md`
- Arc registry quick reference table updated
- SKILL.md arc table updated
- Pattern files cross-reference related patterns in other elements
