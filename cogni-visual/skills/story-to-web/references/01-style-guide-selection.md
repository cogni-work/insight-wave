# Style Guide Selection

## Role & Context

You are executing **Step 3** of the story-to-web skill. Your job is to select a Pencil MCP style guide that provides the visual direction for a scrollable web narrative.

**What you have at this point:**
- The narrative's arc type (from Step 2)
- The governing thought and tone
- The theme.md file (loaded in Step 1)
- Industry and audience context from metadata

**What you must produce:**
- A single style guide name to store in the brief's `style_guide` frontmatter field

**How this fits in the pipeline:**
The selected style guide drives the renderer's visual atmosphere (composition, imagery style, color mood). It does NOT override theme.md variables -- theme tokens always win for specific color and font values. The style guide is aesthetic direction; the theme is brand enforcement.

---

## Tag Scoring Algorithm

Score each candidate style guide by weighting four dimensions:

| Dimension | Weight | Source |
|-----------|--------|--------|
| Theme fit | 0.30 | Match against theme.md colors, industry, and tone |
| Tone match | 0.30 | Narrative arc tone (corporate, bold, warm, technical) |
| Industry relevance | 0.20 | Industry-specific tags (manufacturing, healthcare, etc.) |
| Arc alignment | 0.20 | Arc type (why-change prefers bold/dark, report prefers clean/minimal) |

### Scoring Process

Follow these steps in order. At each step, produce the specified output before moving to the next.

```
Step 3a: Retrieve available tags
  ACTION: Call get_style_guide_tags() via Pencil MCP
  OUTPUT: Full list of available tags (store internally for step 3b)

Step 3b: Select 5-10 tags
  ACTION: Think step by step through each dimension:
    - What tags match the theme's industry and color mood?
    - What tags match the narrative's tone?
    - What tags align with the arc type?
    - Which tags from the available list best cover these needs?
  CONSTRAINT: Always include "website" as the first tag
  OUTPUT: Ordered list of 5-10 tags with a 1-word rationale per tag

Step 3c: Retrieve candidate style guides
  ACTION: Call get_style_guide(tags) via Pencil MCP
  OUTPUT: List of candidate style guides returned by the API

Step 3d: Score each candidate
  ACTION: For each candidate, score all four dimensions (see detailed
          scoring instructions below), then compute weighted total
  OUTPUT: Ranked list of candidates with per-dimension scores and totals

Step 3e: Present or auto-select
  ACTION: If interactive, present top 2-3 to user. If not, select top scorer.
  OUTPUT: Selected style guide name
```

### Detailed Scoring Instructions (Step 3d)

Before scoring, reason through each candidate explicitly.

<reasoning>
For each candidate style guide, think through these questions:

1. THEME FIT (weight 0.30):
   - Does this guide's color palette harmonize with the theme's primary/accent colors?
   - Does the guide's visual density match the theme's industry context?
   - Score 0.0-1.0 where 1.0 = perfect theme harmony

2. TONE MATCH (weight 0.30):
   - Does the guide's mood (e.g., bold, minimal, warm) match the narrative's voice?
   - Would the narrative's governing thought feel natural in this visual context?
   - Score 0.0-1.0 where 1.0 = perfect tonal alignment

3. INDUSTRY RELEVANCE (weight 0.20):
   - Does the guide reference or suit the narrative's industry?
   - Would the audience recognize this as appropriate for their sector?
   - Score 0.0-1.0 where 1.0 = explicitly designed for this industry

4. ARC ALIGNMENT (weight 0.20):
   - Does the guide's visual energy match the arc's purpose?
   - A why-change arc needs urgency and contrast; a report arc needs clarity
   - Score 0.0-1.0 where 1.0 = ideal visual energy for this arc type

Weighted total = (theme_fit x 0.30) + (tone_match x 0.30) + (industry x 0.20) + (arc x 0.20)
</reasoning>

### Worked Example: Manufacturing Why-Change Narrative

> **Note:** Style guide names in examples (e.g., "Corporate Tech", "Bold Enterprise") are illustrative. Actual available guides are returned by `get_style_guide(tags)` at runtime and may have different names.

This example shows the complete scoring process for a B2B manufacturing narrative about predictive maintenance, using the smarter-service theme (corporate blue/cyan, professional tone).

```
CONTEXT:
  Arc type: why-change
  Industry: manufacturing / B2B
  Theme: smarter-service (primary: #009BDC cyan blue, accent: #FF6600 orange)
  Tone: professional, data-driven, urgency-oriented
  Governing thought: "Predictive Maintenance reduces unplanned downtime by 73%"

STEP 3a: Retrieved 200+ tags from get_style_guide_tags()

STEP 3b: Tag selection reasoning:
  - "website"       -> required first tag
  - "corporate"     -> smarter-service is a corporate consulting theme
  - "technology"    -> predictive maintenance is a technology topic
  - "blue"          -> matches the #009BDC primary color
  - "dark-hero"     -> why-change arcs benefit from bold dark hero sections
  - "modern"        -> manufacturing innovation narrative
  - "data-driven"   -> 52 data points in the source narrative
  Selected tags: [website, corporate, technology, blue, dark-hero, modern, data-driven]

STEP 3c: get_style_guide(tags) returned 3 candidates:
  - "Corporate Tech"
  - "Bold Enterprise"
  - "Clean Analytics"

STEP 3d: Scoring each candidate:

  CANDIDATE 1: "Corporate Tech"
    Theme fit:    0.90 (blue-toned, corporate density, matches cyan primary)
    Tone match:   0.85 (professional + tech-forward, suits data-driven voice)
    Industry:     0.70 (generic tech, not manufacturing-specific)
    Arc alignment: 0.80 (has dark hero patterns, supports contrast/urgency)
    TOTAL: (0.90 x 0.30) + (0.85 x 0.30) + (0.70 x 0.20) + (0.80 x 0.20)
         = 0.270 + 0.255 + 0.140 + 0.160
         = 0.825

  CANDIDATE 2: "Bold Enterprise"
    Theme fit:    0.70 (bold dark palette, somewhat matches but more aggressive)
    Tone match:   0.75 (bolder than the narrative's measured professional tone)
    Industry:     0.60 (enterprise-generic, not industry-specific)
    Arc alignment: 0.90 (excellent for why-change: high contrast, urgency visuals)
    TOTAL: (0.70 x 0.30) + (0.75 x 0.30) + (0.60 x 0.20) + (0.90 x 0.20)
         = 0.210 + 0.225 + 0.120 + 0.180
         = 0.735

  CANDIDATE 3: "Clean Analytics"
    Theme fit:    0.75 (clean/minimal, light palette, partial color match)
    Tone match:   0.65 (too restrained for a why-change urgency narrative)
    Industry:     0.80 (data-focused, good for stat-heavy content)
    Arc alignment: 0.40 (too calm for why-change; better for report arcs)
    TOTAL: (0.75 x 0.30) + (0.65 x 0.30) + (0.80 x 0.20) + (0.40 x 0.20)
         = 0.225 + 0.195 + 0.160 + 0.080
         = 0.660

  RANKING:
    1. Corporate Tech   -> 0.825
    2. Bold Enterprise  -> 0.735
    3. Clean Analytics  -> 0.660

STEP 3e: Present top 2-3 to user (interactive mode)
```

### Worked Example: Healthcare Report Narrative

A shorter example showing how a different arc type shifts the scoring:

```
CONTEXT:
  Arc type: report
  Industry: healthcare
  Theme: clinical-trust (primary: #0066CC blue, accent: #00A86B green)
  Tone: trustworthy, precise, evidence-based

STEP 3b: Tags: [website, healthcare, clean, minimal, trustworthy, clinical, data-driven]

STEP 3d: (abbreviated)
  "Clinical Clarity" -> theme 0.95, tone 0.90, industry 0.95, arc 0.85 = 0.915
  "Corporate Tech"   -> theme 0.60, tone 0.65, industry 0.30, arc 0.50 = 0.535
  Winner: Clinical Clarity (0.915) -- strong industry + arc match
```

### Web Guide Filtering

Web narratives require website-appropriate style guides. Follow these rules:

1. **Always include `website` as the first tag** in your tag selection
2. **Filter by prefix:** Prefer guides with `web-*` prefix in their name
3. **Reject mobile guides:** Exclude any style guide with `mobile-*` in the name -- these are designed for mobile app screens, not web pages
4. **Cache known good guides:** If the first `get_style_guide` call returns a suitable web guide, use it without further queries
5. **Max 2 queries:** Do not call `get_style_guide` more than twice. If the second call also fails to return a web-appropriate guide, proceed with the best available option

---

## Theme-to-Tag Mapping

Map common theme characteristics to style guide tags. Think through each theme characteristic you observe in theme.md before selecting tags.

<reasoning>
Before selecting tags, answer these questions about the theme:

1. What is the theme's primary color family? (blue, green, red, orange, purple, neutral)
   -> Map to color tags: "blue", "green", "warm", etc.

2. What industry or sector does the theme serve?
   -> Map to industry tags from the table below

3. What is the overall visual density -- minimal and airy, or rich and detailed?
   -> Map to density tags: "minimal", "clean" vs. "rich", "detailed", "bold"

4. Does the theme use dark or light backgrounds primarily?
   -> Map to mood tags: "dark-hero", "contrast" vs. "light", "airy"

5. What emotional register does the theme suggest?
   -> Map to tone tags: "corporate", "warm", "approachable", "technical"
</reasoning>

| Theme Characteristic | Suggested Tags |
|---------------------|---------------|
| Corporate/professional | `corporate`, `professional`, `clean` |
| Technology/digital | `technology`, `digital`, `modern` |
| Dark hero section | `dark-hero`, `bold`, `contrast` |
| Warm/consulting | `warm`, `consulting`, `approachable` |
| Manufacturing/industrial | `industrial`, `engineering`, `precision` |
| Healthcare | `healthcare`, `trustworthy`, `clinical` |
| Finance | `finance`, `conservative`, `data-driven` |

### Arc-to-Tag Mapping

The arc type determines the visual energy level. Think about what the arc is trying to accomplish emotionally before mapping to tags.

| Arc Type | Visual Energy | Suggested Tags |
|----------|--------------|---------------|
| why-change | High (urgency, contrast, call to action) | `bold`, `dark-hero`, `contrast`, `urgency` |
| problem-solution | Medium (structured, clear progression) | `clean`, `professional`, `structured` |
| journey | Medium (warm, narrative flow) | `storytelling`, `warm`, `progressive` |
| argument | Medium-high (evidence-based, analytical) | `data-driven`, `structured`, `analytical` |
| report | Low (calm, authoritative, minimal) | `minimal`, `clean`, `corporate` |

---

## Edge Cases & Fallback Strategies

Handle these situations explicitly:

### No Good Tag Matches

If fewer than 3 tags from the available set match your theme/arc analysis:
1. Broaden to adjacent categories (e.g., "manufacturing" not available -- try "industrial" or "engineering")
2. Prioritize arc-alignment tags over industry tags (visual energy matters more than sector specificity)
3. Always keep "website" and at least one color/mood tag

### No Suitable Candidates Returned

If `get_style_guide(tags)` returns no candidates or only mobile/non-web guides:
1. Retry with broader tags: drop the most specific tag, add a more general one (e.g., drop "manufacturing", add "professional")
2. If the second call also fails, use a safe default approach:
   - For dark arcs (why-change, argument): search with `[website, corporate, dark-hero, bold]`
   - For light arcs (report, journey): search with `[website, clean, minimal, professional]`
   - For mixed arcs (problem-solution): search with `[website, corporate, modern, clean]`
3. After the max 2 queries, select the best available option and note the compromise in transformation_notes

### Unusual or Niche Theme

If the theme.md describes a highly specific aesthetic (e.g., a gaming brand, a children's education platform, a luxury fashion house):
1. Map the theme's core visual attributes to the closest available tags (e.g., luxury -> "elegant", "minimal", "contrast")
2. Score with extra weight on Theme fit (mentally increase its importance) since the niche theme makes harmony harder to achieve
3. In the interactive proposal, explain the mapping rationale to the user so they can override if the approximation is poor

### All Candidates Score Below 0.5

If every candidate scores below 0.5 weighted total:
1. This means no guide is a strong fit -- do NOT silently pick the least-bad option without informing the user
2. In interactive mode: present the options with an explicit note: "None of these are a strong match for your theme and arc. The top option scores {score}. Would you like to proceed, or try different visual direction?"
3. In non-interactive mode: select the top scorer but add a warning to transformation_notes: "Style guide '{name}' selected with low confidence ({score}). Manual review recommended."

---

## Interactive Proposal Format

When `interactive: true`, present style guide options to the user using this exact structure:

```
Based on your narrative's {arc_type} arc and {industry} context, here are my top style guide recommendations:

1. **{style_guide_name}** (score: {score})
   Tags: {tag1}, {tag2}, {tag3}
   Why: {1-sentence reasoning based on theme + tone + industry}

2. **{style_guide_name}** (score: {score})
   Tags: {tag1}, {tag2}, {tag3}
   Why: {1-sentence reasoning}

3. **{style_guide_name}** (score: {score})
   Tags: {tag1}, {tag2}, {tag3}
   Why: {1-sentence reasoning}

Which style guide do you prefer, or would you like a different visual direction?
```

Use AskUserQuestion with the top 3 (or top 2 if only 2 viable candidates) as options.

**Output format requirements:**
- Scores are displayed as decimals to 2 places (e.g., 0.83, not 83%)
- Tags are the actual tags used in the query, not generic descriptions
- The "Why" sentence must reference at least two of the four scoring dimensions
- If any candidate scored below 0.5, add a note after the list (see edge cases above)

---

## Non-Interactive Mode

When `interactive: false` (agent delegation), auto-select the top-scoring style guide. Produce this internal log entry (do not show to user):

```
[Style Guide Selection] Auto-selected "{name}" (score: {score})
  Theme fit: {score}, Tone: {score}, Industry: {score}, Arc: {score}
  Tags used: {tag1}, {tag2}, ...
```

Store the selected name in the brief frontmatter. If the score is below 0.5, add a warning line to `transformation_notes`.

---

## Style Guide Application

The selected style guide name is stored in the brief frontmatter as `style_guide`. The renderer agent:

1. Calls `get_style_guide(name="{style_guide_name}")` to load the guide
2. Uses the guide's color palette, typography, and layout patterns as visual direction
3. Combines with theme.md tokens for consistency

**Important:** The style guide provides *aesthetic direction*, not hard constraints. Theme.md variables (defined as `--primary`, referenced as `$--primary`, etc.) always take precedence for color and font values. The style guide influences composition, imagery style, and visual atmosphere.

**Precedence rule (when guide and theme conflict):**
- Color values: theme.md wins (via design tokens)
- Font families: theme.md wins (via `--font-primary`, `--font-body`)
- Layout composition: style guide wins (section arrangements, whitespace patterns)
- Imagery mood: style guide wins (photography style, illustration approach)
- Visual atmosphere: style guide wins (dark/light bias, contrast level)
